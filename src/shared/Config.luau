--!strict
-- Every tuning number lives here. Services and controllers never hard-code numbers.

local Types = require(script.Parent.Types)

local function deepFreeze<T>(value: T): T
	if type(value) == "table" then
		for _, child in value :: any do
			deepFreeze(child)
		end
		table.freeze(value :: any)
	end
	return value
end

local DefaultProfile: Types.Profile = {
	version = 1,
	candy = 0,
	bestFloor = 0,
	checkpointFloor = 0,
	flashlightLevel = 1,
	perks = {},
	cards = {},
	cosmetics = {},
	midnightUnlocked = false,
	settings = { lessSpooky = false },
	stats = { runs = 0, floorsCleared = 0, timesScared = 0 },
}

local Config = {
	-- Game rules (spec §3, §8, §11)
	MaxCandy = 999999,
	StartingHearts = 3,
	CheckpointEvery = 10,
	MaxFloor = 50,
	MaxRoomsLoaded = 3,
	MinSignalSeconds = 2,

	Data = {
		StoreName = "SpookyStairs_v1",
		KeyPrefix = "Player_",
		SchemaVersion = 1,
		-- Wait before each retry of a failed DataStore call (3 retries after the first try).
		RetryDelays = { 1, 2, 4 },
		-- A lock older than this is from a crashed server and may be taken over.
		LockStealSeconds = 300,
		-- Rejoining quickly can find the old server still saving; wait for it this many times.
		LockWaitAttempts = 5,
		LockWaitSeconds = 3,
		AutosaveSeconds = 60,
		ShutdownWaitSeconds = 25,
	},

	DefaultProfile = DefaultProfile,

	-- Calls per second per player, per remote (plan §3).
	RateLimits = {
		RequestOpenDoor = 2,
		RequestHide = 4,
		RequestUnhide = 4,
		SetFlashlight = 5,
		RequestCollect = 15,
		RequestRevive = 2,
		SubmitPuzzle = 2,
		SetCrouch = 5,
		RequestPurchase = 2,
		SetSetting = 2,
		RequestQueue = 2,
		LeaveQueue = 2,
	},

	-- Max distance in studs between a player and the thing they interact with (plan §3).
	Distances = {
		OpenDoor = 10,
		Hide = 6,
		Collect = 8,
		Revive = 8,
	},

	Remote = {
		MaxStringLength = 64,
	},

	Text = {
		LoadFailed = "Oops! Your save didn't open. Please rejoin in a minute - your candy is safe!",
	},

	-- Studio-only helpers; never active on live servers.
	Debug = {
		TestCommandsEnabled = true,
		TestCandyAmount = 10,
	},
}

return deepFreeze(Config)
