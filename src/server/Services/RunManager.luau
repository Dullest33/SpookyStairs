--!strict
-- One Run per player (solo until M9): current floor, hearts, and the rooms that exist.
-- Opening the current room's door advances the floor. Only Config.MaxRoomsLoaded rooms exist at once:
-- one behind, the current room and the next one.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Trove = require(ReplicatedStorage.Shared.Util.Trove)
local Types = require(ReplicatedStorage.Shared.Types)
local DataService = require(script.Parent.DataService)
local FloorGenerator = require(script.Parent.FloorGenerator)
local RemoteGuard = require(script.Parent.RemoteGuard)

type Run = Types.Run

local runs: { [Player]: Run } = {}
local usedSlots: { [number]: boolean } = {}
local seedRandom = Random.new()

local RunManager = {}

local function takeSlot(): number
	local slot = 1
	while usedSlots[slot] do
		slot += 1
	end
	usedSlots[slot] = true
	return slot
end

-- Lanes alternate either side of the run area so they stay near the origin: slot 1 -> 0, 2 -> +1, 3 -> -1, ...
local function laneOrigin(slot: number): CFrame
	local index = slot // 2
	local side = if slot % 2 == 0 then 1 else -1
	return CFrame.new(
		Config.Floors.RunAreaOrigin + Vector3.new(index * side * Config.Floors.LaneSpacing, 0, 0)
	)
end

local function syncState(run: Run)
	local profile = DataService:GetProfile(run.player)
	local view: Types.PlayerView = {
		hearts = run.hearts,
		floor = run.floor,
		candy = if profile then profile.candy else 0,
		battery = Config.Flashlight.MaxBattery,
		partyIds = { run.player.UserId },
	}
	Remotes.get("StateSync"):FireClient(run.player, view)
end

local function placeCharacter(run: Run)
	local character = run.player.Character
	local room = run.rooms[run.floor]
	if not character or not room then
		return
	end
	local target = room.entrance.CFrame * CFrame.new(Config.Floors.SpawnOffset)
	-- Make sure the room has streamed to the client before the player lands in it.
	pcall(function()
		run.player:RequestStreamAroundAsync(target.Position)
	end)
	if run.player.Character == character and character.Parent then
		character:PivotTo(target)
	end
end

-- Removes rooms that are too far behind, seals the oldest one, and builds the next one.
local function updateRooms(run: Run)
	local oldestKept = run.floor - (Config.MaxRoomsLoaded - 2)
	for floor, room in run.rooms do
		if floor < oldestKept then
			FloorGenerator:DestroyRoom(room)
			run.rooms[floor] = nil
		end
	end

	local oldest = run.rooms[math.max(oldestKept, Config.Floors.StartFloor)]
	if oldest then
		FloorGenerator:SealEntrance(oldest)
	end

	local nextFloor = run.floor + 1
	if nextFloor <= Config.MaxFloor and not run.rooms[nextFloor] then
		run.rooms[nextFloor] = FloorGenerator:BuildRoom(run.layout, nextFloor, run.folder)
	end
end

local function advanceFloor(run: Run): boolean
	local room = run.rooms[run.floor]
	if not room or room.doorState ~= "closed" or run.floor >= Config.MaxFloor then
		return false
	end
	FloorGenerator:OpenDoor(room)
	run.floor += 1
	updateRooms(run)

	DataService:Update(run.player, function(profile)
		profile.bestFloor = math.max(profile.bestFloor, run.floor)
		profile.stats.floorsCleared += 1
	end)
	Remotes.get("FloorChanged"):FireClient(run.player, run.floor, run.rooms[run.floor].templateId)
	syncState(run)
	return true
end

local function startRun(player: Player)
	if runs[player] or not DataService:IsLoaded(player) then
		return
	end
	if not FloorGenerator:HasTemplates() then
		warn("[RunManager] no room templates, so no run started")
		return
	end

	local slot = takeSlot()
	local trove = Trove.new()
	trove:Add(function()
		usedSlots[slot] = nil
	end)
	local folder = trove:Add(Instance.new("Folder"))
	folder.Name = "Run_" .. tostring(player.UserId)
	folder.Parent = Workspace

	local seed = seedRandom:NextInteger(1, Config.Floors.MaxSeed)
	local run: Run = {
		player = player,
		floor = Config.Floors.StartFloor,
		hearts = Config.StartingHearts,
		slot = slot,
		layout = FloorGenerator:NewLayout(seed, laneOrigin(slot)),
		rooms = {},
		folder = folder,
		trove = trove,
	}
	runs[player] = run

	run.rooms[run.floor] = FloorGenerator:BuildRoom(run.layout, run.floor, folder)
	updateRooms(run)

	DataService:Update(player, function(profile)
		profile.stats.runs += 1
	end)

	trove:Connect(player.CharacterAdded, function(character: Model)
		-- Let the default spawn finish first, then move the player into their current room.
		character:WaitForChild("HumanoidRootPart")
		task.defer(placeCharacter, run)
	end)
	task.spawn(placeCharacter, run)

	print(string.format("[RunManager] %s started a run (seed %d, lane %d)", player.Name, seed, slot))
	Remotes.get("FloorChanged"):FireClient(player, run.floor, run.rooms[run.floor].templateId)
	syncState(run)
end

local function endRun(player: Player)
	local run = runs[player]
	if not run then
		return
	end
	runs[player] = nil
	run.trove:Destroy()
end

local function validateOpenDoor(player: Player, ...: any): boolean
	if select("#", ...) ~= 0 then
		return false
	end
	local run = runs[player]
	if not run or run.floor >= Config.MaxFloor then
		return false
	end
	local room = run.rooms[run.floor]
	if not room or room.doorState ~= "closed" then
		return false
	end
	local panel = room.door.PrimaryPart
	return panel ~= nil
		and RemoteGuard.Check.withinDistance(player, panel.Position, Config.Distances.OpenDoor)
end

function RunManager:GetRun(player: Player): Run?
	return runs[player]
end

-- Studio test helper (/skip): opens the current door without the distance check.
function RunManager:DebugAdvance(player: Player): boolean
	local run = runs[player]
	return run ~= nil and advanceFloor(run)
end

function RunManager:Init()
	RemoteGuard.wrap("RequestOpenDoor", Config.RateLimits.RequestOpenDoor, validateOpenDoor, function(player)
		local run = runs[player]
		if run then
			advanceFloor(run)
		end
	end)
end

function RunManager:Start()
	DataService.ProfileLoaded:Connect(startRun)
	DataService.ProfileChanged:Connect(function(player)
		local run = runs[player]
		if run then
			syncState(run)
		end
	end)
	Players.PlayerRemoving:Connect(endRun)
	-- Profiles that finished loading before this Start ran.
	for _, player in Players:GetPlayers() do
		task.spawn(startRun, player)
	end
end

return RunManager
