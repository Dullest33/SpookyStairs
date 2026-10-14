--!strict
-- Every client->server remote is connected through RemoteGuard.wrap (plan §3):
-- per-player rate limit, profile-loaded check, validator (types, distance, ownership), then the handler.
-- Bad calls are dropped and logged once per player per remote.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require(script.Parent.DataService)

type Validator = (player: Player, ...any) -> boolean
type Handler = (player: Player, ...any) -> ()

type Bucket = {
	tokens: number,
	updatedAt: number,
}

local buckets: { [Player]: { [string]: Bucket } } = {}
local warned: { [Player]: { [string]: boolean } } = {}

local RemoteGuard = {}

local function warnOnce(player: Player, remoteName: string, reason: string)
	local playerWarned = warned[player]
	if not playerWarned then
		playerWarned = {}
		warned[player] = playerWarned
	end
	local warnKey = remoteName .. ":" .. reason
	if playerWarned[warnKey] then
		return
	end
	playerWarned[warnKey] = true
	warn(
		string.format(
			"[RemoteGuard] dropped %s from %s (%d): %s",
			remoteName,
			player.Name,
			player.UserId,
			reason
		)
	)
end

-- Token bucket: refills at `ratePerSec`, holds at most one second's worth.
local function takeToken(player: Player, remoteName: string, ratePerSec: number): boolean
	local playerBuckets = buckets[player]
	if not playerBuckets then
		playerBuckets = {}
		buckets[player] = playerBuckets
	end
	local now = os.clock()
	local bucket = playerBuckets[remoteName]
	if not bucket then
		bucket = { tokens = ratePerSec, updatedAt = now }
		playerBuckets[remoteName] = bucket
	end
	bucket.tokens = math.min(ratePerSec, bucket.tokens + (now - bucket.updatedAt) * ratePerSec)
	bucket.updatedAt = now
	if bucket.tokens < 1 then
		return false
	end
	bucket.tokens -= 1
	return true
end

function RemoteGuard.wrap(
	remoteName: Types.ClientRemoteName,
	ratePerSec: number,
	validator: Validator,
	handler: Handler
): RBXScriptConnection
	local remote = Remotes.get(remoteName)
	return remote.OnServerEvent:Connect(function(player: Player, ...: any)
		if not takeToken(player, remoteName, ratePerSec) then
			warnOnce(player, remoteName, "rate limit")
			return
		end
		if not DataService:IsLoaded(player) then
			warnOnce(player, remoteName, "profile not loaded")
			return
		end
		local validOk, valid = pcall(validator, player, ...)
		if not validOk or valid ~= true then
			warnOnce(player, remoteName, "validation failed")
			return
		end
		local ok, err = pcall(handler, player, ...)
		if not ok then
			warn(string.format("[RemoteGuard] %s handler error: %s", remoteName, tostring(err)))
		end
	end)
end

-- Validator helpers. Each returns true only for well-formed values.
local Check = {}

function Check.isBoolean(value: unknown): boolean
	return type(value) == "boolean"
end

function Check.isString(value: unknown): boolean
	return type(value) == "string" and #value > 0 and #value <= Config.Remote.MaxStringLength
end

function Check.isFiniteNumber(value: unknown): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

function Check.isInteger(value: unknown): boolean
	return Check.isFiniteNumber(value) and math.floor(value :: number) == value
end

-- Plain array of integers, at most `maxLength` long (puzzle answers).
function Check.isIntegerArray(value: unknown, maxLength: number): boolean
	if type(value) ~= "table" then
		return false
	end
	local list = value :: { [any]: any }
	local count = 0
	for key, item in list do
		count += 1
		if type(key) ~= "number" or not Check.isInteger(item) then
			return false
		end
	end
	return count <= maxLength and count == #list
end

function Check.getRootPart(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

function Check.withinDistance(player: Player, position: Vector3, maxStuds: number): boolean
	local root = Check.getRootPart(player)
	return root ~= nil and (root.Position - position).Magnitude <= maxStuds
end

RemoteGuard.Check = Check

function RemoteGuard:Init() end

function RemoteGuard:Start()
	Players.PlayerRemoving:Connect(function(player)
		buckets[player] = nil
		warned[player] = nil
	end)
end

return RemoteGuard
