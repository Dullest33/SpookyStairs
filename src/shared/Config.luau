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

	Floors = {
		StartFloor = 1,
		-- Each solo run gets its own lane; lanes sit side by side along X, away from the lobby.
		RunAreaOrigin = Vector3.new(0, 500, -1000),
		LaneSpacing = 1200,
		-- A lane may wander this far sideways (studs) before the generator steers it back.
		MaxLateralDrift = 400,
		-- An exit counts as "heading outwards" when its facing has more than this much sideways component.
		OutwardDot = 0.5,
		-- Reject a room whose exit would face more backwards than this (dot with the lane's forward).
		MinForwardDot = -0.5,
		-- New rooms are checked for overlap against this many previous rooms (plan §5).
		OverlapCheckRooms = 2,
		-- Neighbouring rooms touch at the doorway; boxes are shrunk by this much before testing.
		OverlapTolerance = 1,
		FallbackTemplateId = "StraightHall",
		DefaultRoomWeight = 1,
		MaxSeed = 2147483646,
		-- Template walls are this thick and sit inside the room's bounds (see tools/BuildGreyboxRooms.luau).
		WallThickness = 1,
		DoorSize = Vector3.new(8, 12, 1),
		DoorOpenSeconds = 0.4,
		-- Prompt range is a bit shorter than the server check (Distances.OpenDoor) to allow for lag.
		DoorPromptDistance = 8,
		DoorLightBrightness = 1.5,
		DoorLightRange = 12,
		DoorNumberPixelsPerStud = 50,
		-- Where a player appears in a room, relative to its Entrance (up, then forward).
		SpawnOffset = Vector3.new(0, 3, -6),
	},

	Interact = {
		-- ProximityPrompts carry this attribute so InteractController knows which intent to send.
		Attribute = "Interact",
		Door = "Door",
	},

	-- Colour language (spec §5): orange = go/exit, purple = danger, green = safe, gold = rare.
	Colors = {
		Exit = Color3.fromRGB(255, 140, 40),
		Danger = Color3.fromRGB(150, 70, 220),
		Safe = Color3.fromRGB(80, 200, 120),
		Rare = Color3.fromRGB(255, 200, 40),
		Wall = Color3.fromRGB(74, 52, 110),
		HudPanel = Color3.fromRGB(45, 30, 70),
		HudText = Color3.fromRGB(255, 255, 255),
	},

	UI = {
		-- Screen size (shortest side, px) at which the HUD is drawn at scale 1.
		ReferenceSize = 720,
		MinScale = 0.6,
		MaxScale = 1.6,
		-- Nothing important within this fraction of the screen edges (notches).
		EdgeMargin = 0.1,
		FloorBadgeSize = Vector2.new(150, 90),
		CornerRadius = 16,
		StrokeThickness = 3,
		-- Fraction of a label's height left empty above and below its text.
		TextPadding = 0.12,
	},

	Flashlight = {
		MaxBattery = 100,
	},

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

	-- Studio-only helpers (/candy, /skip); never active on live servers.
	Debug = {
		TestCommandsEnabled = true,
		TestCandyAmount = 10,
	},
}

return deepFreeze(Config)
