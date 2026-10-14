--!strict
-- Profile load/save with session locking. The ONLY module that touches DataStores.
-- Rules (plan §2): pcall + retries on every call, never play on a profile that failed to load,
-- autosave, save on leave and on shutdown, migrate on every load, clamp candy on every write.

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)
local Types = require(ReplicatedStorage.Shared.Types)

type Profile = Types.Profile

type Session = {
	profile: Profile,
	-- Set once the final (lock-releasing) save has started; no more edits or saves after that.
	releasing: boolean,
}

type LoadStatus = "ok" | "locked" | "corrupt" | "tooNew"

-- JobId is empty in Studio, so every server makes its own id for the session lock.
local SESSION_ID = HttpService:GenerateGUID(false)

local store: DataStore? = nil
local sessions: { [Player]: Session } = {}
local pendingSaves = 0

local DataService = {}

DataService.ProfileLoaded = Signal.new() :: Signal.Signal<Player, Profile>
DataService.ProfileChanged = Signal.new() :: Signal.Signal<Player, Profile>

local function keyFor(userId: number): string
	return Config.Data.KeyPrefix .. tostring(userId)
end

local function deepCopy<T>(value: T): T
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, child in value :: any do
		copy[key] = deepCopy(child)
	end
	return (copy :: any) :: T
end

-- Fills every field an older save is missing (or has the wrong type for) with its default.
local function fillMissing(target: { [any]: any }, defaults: { [any]: any })
	for key, default in defaults do
		local current = target[key]
		if type(current) ~= type(default) then
			target[key] = deepCopy(default)
		elseif type(default) == "table" then
			fillMissing(current, default)
		end
	end
end

local function migrate(raw: { [any]: any }): Profile
	-- Per-version steps go here when the schema changes, e.g. `if raw.version < 2 then ... end`.
	fillMissing(raw, Config.DefaultProfile :: any)
	raw.version = Config.Data.SchemaVersion
	return (raw :: any) :: Profile
end

local function clampProfile(profile: Profile)
	local candy = profile.candy
	if candy ~= candy then -- NaN
		candy = 0
	end
	profile.candy = math.clamp(math.floor(candy), 0, Config.MaxCandy)
end

-- Runs `attempt` in pcall, retrying with backoff. Returns ok, result.
local function withRetries<T>(label: string, attempt: () -> T): (boolean, T?)
	local delays = Config.Data.RetryDelays
	for try = 1, #delays + 1 do
		local ok, result = pcall(attempt)
		if ok then
			return true, result
		end
		warn(string.format("[DataService] %s failed (try %d): %s", label, try, tostring(result)))
		local delay = delays[try]
		if delay then
			task.wait(delay)
		end
	end
	return false, nil
end

type LoadResult = { status: LoadStatus, profile: Profile? }

-- One UpdateAsync that reads the record and claims its lock in the same step.
local function tryClaim(dataStore: DataStore, key: string): LoadResult
	local result: LoadResult = { status = "ok", profile = nil }

	dataStore:UpdateAsync(key, function(old: any): Types.StoredRecord?
		-- Roblox may run this transform more than once, so reset the result each time.
		result.status = "ok"
		result.profile = nil
		local now = os.time()

		local raw: { [any]: any }
		if old == nil then
			raw = deepCopy(Config.DefaultProfile :: any)
		elseif type(old) ~= "table" or type(old.profile) ~= "table" then
			result.status = "corrupt"
			return nil
		else
			local lockedByOther = type(old.lockJobId) == "string" and old.lockJobId ~= SESSION_ID
			local lockFresh = type(old.lockTime) == "number"
				and now - old.lockTime < Config.Data.LockStealSeconds
			if lockedByOther and lockFresh then
				result.status = "locked"
				return nil
			end
			raw = old.profile
		end

		-- Saved by a newer server version (e.g. after a rollback); never downgrade it.
		if type(raw.version) == "number" and raw.version > Config.Data.SchemaVersion then
			result.status = "tooNew"
			return nil
		end

		local profile = migrate(raw)
		clampProfile(profile)
		result.profile = profile
		return { profile = profile, lockJobId = SESSION_ID, lockTime = now }
	end)

	return result
end

local function loadProfile(userId: number): Profile?
	local dataStore = store
	if not dataStore then
		return nil
	end
	local key = keyFor(userId)

	for lockTry = 1, Config.Data.LockWaitAttempts do
		local ok, result = withRetries("load " .. key, function()
			return tryClaim(dataStore, key)
		end)
		if not ok or not result then
			return nil
		end
		if result.status == "ok" then
			return result.profile
		elseif result.status == "locked" then
			warn(string.format("[DataService] %s is locked by another server (wait %d)", key, lockTry))
			task.wait(Config.Data.LockWaitSeconds)
		else
			warn(string.format("[DataService] %s refused: %s", key, result.status))
			return nil
		end
	end
	return nil
end

-- Writes the profile if we still own the lock. `release` clears the lock (player left / shutdown).
-- Pass `session` for routine saves so they cancel if the releasing save has already started.
local function writeProfile(userId: number, profile: Profile, release: boolean, session: Session?): boolean
	local dataStore = store
	if not dataStore then
		return false
	end
	clampProfile(profile)
	local key = keyFor(userId)

	pendingSaves += 1
	local ok = withRetries("save " .. key, function()
		dataStore:UpdateAsync(key, function(old: any): Types.StoredRecord?
			if session and session.releasing then
				-- An autosave arriving after the final save would lock the profile again.
				return nil
			end
			if type(old) == "table" and type(old.lockJobId) == "string" and old.lockJobId ~= SESSION_ID then
				-- Our lock went stale and another server took over; its copy is newer. Don't overwrite.
				warn(string.format("[DataService] %s lock lost to another server; save skipped", key))
				return nil
			end
			return {
				profile = profile,
				lockJobId = if release then nil else SESSION_ID,
				lockTime = if release then nil else os.time(),
			}
		end)
		return true
	end)
	pendingSaves -= 1
	return ok
end

local function onPlayerAdded(player: Player)
	local profile = loadProfile(player.UserId)

	if not profile then
		if player.Parent == Players then
			player:Kick(Config.Text.LoadFailed)
		end
		return
	end

	if player.Parent ~= Players then
		-- Left while loading: hand the lock back straight away.
		writeProfile(player.UserId, profile, true)
		return
	end

	sessions[player] = { profile = profile, releasing = false }
	print(string.format("[DataService] loaded %s candy=%d", keyFor(player.UserId), profile.candy))
	DataService.ProfileLoaded:Fire(player, profile)
end

local function releaseSession(player: Player)
	local session = sessions[player]
	if not session or session.releasing then
		return
	end
	session.releasing = true
	writeProfile(player.UserId, session.profile, true)
	sessions[player] = nil
end

local function autosaveLoop()
	while true do
		task.wait(Config.Data.AutosaveSeconds)
		for player, session in sessions do
			if not session.releasing then
				task.spawn(writeProfile, player.UserId, session.profile, false, session)
			end
		end
	end
end

-- Read-only view of a loaded profile. Change it only through DataService:Update.
function DataService:GetProfile(player: Player): Profile?
	local session = sessions[player]
	return if session then session.profile else nil
end

function DataService:IsLoaded(player: Player): boolean
	local session = sessions[player]
	return session ~= nil and not session.releasing
end

-- Applies `mutator` to the player's profile. Returns false if there is no usable profile.
function DataService:Update(player: Player, mutator: (Profile) -> ()): boolean
	local session = sessions[player]
	if not session or session.releasing then
		return false
	end
	mutator(session.profile)
	clampProfile(session.profile)
	DataService.ProfileChanged:Fire(player, session.profile)
	return true
end

-- Saves immediately (checkpoints, purchases). Yields.
function DataService:SaveNow(player: Player): boolean
	local session = sessions[player]
	if not session or session.releasing then
		return false
	end
	return writeProfile(player.UserId, session.profile, false, session)
end

function DataService:Init()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.Data.StoreName)
	end)
	if ok then
		store = result
	else
		warn(
			"[DataService] DataStores unavailable (in Studio: publish the place, then enable "
				.. "Game Settings > Security > 'Studio Access to API Services'): "
				.. tostring(result)
		)
	end
end

function DataService:Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerRemoving:Connect(releaseSession)

	game:BindToClose(function()
		for player in sessions do
			task.spawn(releaseSession, player)
		end
		local started = os.clock()
		while pendingSaves > 0 and os.clock() - started < Config.Data.ShutdownWaitSeconds do
			task.wait()
		end
	end)

	task.spawn(autosaveLoop)
end

return DataService
