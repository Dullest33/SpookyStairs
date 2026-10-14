--!strict
-- One-off Studio helper: builds the M2 greybox room templates in ServerStorage.RoomTemplates.
-- Run it in EDIT mode (not during Play): paste the whole file into View > Command Bar and press Enter.
-- Needs Rojo synced first (it reads ReplicatedStorage.Shared.Config).
-- It never replaces or deletes anything: a template that already exists is skipped.
-- After it runs, the templates are ordinary Studio models: move, recolour or rebuild them by hand.
--
-- Room template contract (plan §1), local space of every room:
--   Entrance at (0, 0, 0) on the floor surface, facing into the room (-Z = forward, +X = right).
--   Exit on the floor surface in the far doorway, facing out of the room.
--   Walls are Config.Floors.WallThickness thick and sit INSIDE the room's bounds.
--   Doorways are Config.Floors.DoorSize wide/high, centred on Entrance and Exit.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local DOOR = Config.Floors.DoorSize
local WALL = Config.Floors.WallThickness
local HEIGHT = 20

local STRAIGHT_WIDTH = 24
local STRAIGHT_LENGTH = 60

local L_SIZE = 40 -- the L rooms are a 40 x 40 square with the L cut out of it
local L_CORRIDOR_HALF = 9 -- the entrance corridor is 18 studs wide
local L_TURN_DEPTH = 22 -- where the turn corridor starts (studs from the entrance)
local L_EXIT_Z = -31 -- exit doorway centre along the side wall

local COLORS = {
	Floor = Color3.fromRGB(96, 66, 52),
	Wall = Config.Colors.Wall,
	Trim = Color3.fromRGB(40, 110, 120),
	Ceiling = Color3.fromRGB(52, 40, 72),
	Filler = Color3.fromRGB(60, 42, 90),
	Lamp = Color3.fromRGB(255, 190, 120),
}

local function makePart(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Anchored = true
	part.Parent = parent
	return part
end

-- Solid block between two opposite corners.
local function block(parent: Instance, name: string, a: Vector3, b: Vector3, color: Color3): Part
	local low, high = a:Min(b), a:Max(b)
	return makePart(parent, name, high - low, CFrame.new((low + high) / 2), color)
end

-- Invisible, non-colliding 1-stud marker (Entrance, Exit, sockets).
local function marker(parent: Instance, name: string, cframe: CFrame): Part
	local part = makePart(parent, name, Vector3.one, cframe, COLORS.Trim)
	part.Transparency = 1
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	return part
end

local function socket(sockets: Folder, name: string, position: Vector3)
	local part = marker(sockets, name, CFrame.new(position))
	local attachment = Instance.new("Attachment")
	attachment.Name = "Socket"
	attachment.Parent = part
end

-- Wall running along X (between x0 and x1), spanning zA..zB in thickness, with an optional doorway.
local function wallAlongX(
	parent: Instance,
	name: string,
	x0: number,
	x1: number,
	zA: number,
	zB: number,
	doorX: number?
)
	if not doorX then
		block(parent, name, Vector3.new(x0, 0, zA), Vector3.new(x1, HEIGHT, zB), COLORS.Wall)
		return
	end
	local half = DOOR.X / 2
	block(parent, name .. "A", Vector3.new(x0, 0, zA), Vector3.new(doorX - half, HEIGHT, zB), COLORS.Wall)
	block(parent, name .. "B", Vector3.new(doorX + half, 0, zA), Vector3.new(x1, HEIGHT, zB), COLORS.Wall)
	block(
		parent,
		name .. "Top",
		Vector3.new(doorX - half, DOOR.Y, zA),
		Vector3.new(doorX + half, HEIGHT, zB),
		COLORS.Trim
	)
end

-- Wall running along Z (between z0 and z1), spanning xA..xB in thickness, with an optional doorway.
local function wallAlongZ(
	parent: Instance,
	name: string,
	z0: number,
	z1: number,
	xA: number,
	xB: number,
	doorZ: number?
)
	if not doorZ then
		block(parent, name, Vector3.new(xA, 0, z0), Vector3.new(xB, HEIGHT, z1), COLORS.Wall)
		return
	end
	local half = DOOR.X / 2
	block(parent, name .. "A", Vector3.new(xA, 0, z0), Vector3.new(xB, HEIGHT, doorZ + half), COLORS.Wall)
	block(parent, name .. "B", Vector3.new(xA, 0, doorZ - half), Vector3.new(xB, HEIGHT, z1), COLORS.Wall)
	block(
		parent,
		name .. "Top",
		Vector3.new(xA, DOOR.Y, doorZ + half),
		Vector3.new(xB, HEIGHT, doorZ - half),
		COLORS.Trim
	)
end

local function floorAndCeiling(parent: Instance, x0: number, x1: number, z0: number, z1: number)
	block(parent, "Floor", Vector3.new(x0, -1, z0), Vector3.new(x1, 0, z1), COLORS.Floor)
	block(parent, "Ceiling", Vector3.new(x0, HEIGHT, z0), Vector3.new(x1, HEIGHT + 1, z1), COLORS.Ceiling)
end

-- Warm hanging lamp so rooms are never pitch black (spec §10).
local function lamp(parent: Instance, position: Vector3)
	local part = makePart(parent, "Lamp", Vector3.new(2, 0.5, 2), CFrame.new(position), COLORS.Lamp)
	part.Material = Enum.Material.Neon
	part.CanCollide = false
	local light = Instance.new("PointLight")
	light.Color = COLORS.Lamp
	light.Range = 32
	light.Brightness = 1.2
	light.Parent = part
end

local function newTemplate(templateId: string): (Model, Folder, Folder)
	local model = Instance.new("Model")
	model.Name = templateId
	model:SetAttribute("TemplateId", templateId)
	model:SetAttribute("MinFloor", 1)
	model:SetAttribute("MaxFloor", Config.MaxFloor)
	local geometry = Instance.new("Folder")
	geometry.Name = "Geometry"
	geometry.Parent = model
	local sockets = Instance.new("Folder")
	sockets.Name = "Sockets"
	sockets.Parent = model
	return model, geometry, sockets
end

local function finish(model: Model, exitCFrame: CFrame, parent: Instance)
	local entrance = marker(model, "Entrance", CFrame.new())
	marker(model, "Exit", exitCFrame)
	model.PrimaryPart = entrance
	model.Parent = parent
end

local function buildStraightHall(parent: Instance)
	local model, geo, sockets = newTemplate("StraightHall")
	local w, l = STRAIGHT_WIDTH / 2, STRAIGHT_LENGTH

	floorAndCeiling(geo, -w, w, 0, -l)
	wallAlongZ(geo, "WallLeft", 0, -l, -w, -w + WALL)
	wallAlongZ(geo, "WallRight", 0, -l, w - WALL, w)
	wallAlongX(geo, "WallBack", -w + WALL, w - WALL, 0, -WALL, 0)
	wallAlongX(geo, "WallFront", -w + WALL, w - WALL, -l + WALL, -l, 0)
	lamp(geo, Vector3.new(0, HEIGHT - 0.5, -l * 0.2))
	lamp(geo, Vector3.new(0, HEIGHT - 0.5, -l * 0.5))
	lamp(geo, Vector3.new(0, HEIGHT - 0.5, -l * 0.8))

	for index, z in { -10, -20, -30, -40, -50 } do
		socket(sockets, "Candy", Vector3.new(if index % 2 == 0 then 6 else -6, 2, z))
	end
	socket(sockets, "Hide", Vector3.new(-w + 2.5, 0.5, -26))
	socket(sockets, "Hide", Vector3.new(w - 2.5, 0.5, -42))
	socket(sockets, "MonsterSpawn", Vector3.new(0, 0.5, -30))

	finish(model, CFrame.new(0, 0, -l), parent)
end

-- side = 1 turns right, side = -1 turns left (everything is mirrored on X).
local function buildLHall(parent: Instance, templateId: string, side: number)
	local model, geo, sockets = newTemplate(templateId)
	local s, h = L_SIZE, L_SIZE / 2
	local function v(x: number, y: number, z: number): Vector3
		return Vector3.new(x * side, y, z)
	end

	block(geo, "Floor", v(-h, -1, 0), v(h, 0, -s), COLORS.Floor)
	block(geo, "Ceiling", v(-h, HEIGHT, 0), v(h, HEIGHT + 1, -s), COLORS.Ceiling)
	-- Back wall with the entrance doorway, plain front wall and outer side wall.
	block(geo, "WallBackA", v(-h, 0, 0), v(-DOOR.X / 2, HEIGHT, -WALL), COLORS.Wall)
	block(geo, "WallBackB", v(DOOR.X / 2, 0, 0), v(h, HEIGHT, -WALL), COLORS.Wall)
	block(geo, "WallBackTop", v(-DOOR.X / 2, DOOR.Y, 0), v(DOOR.X / 2, HEIGHT, -WALL), COLORS.Trim)
	block(geo, "WallFront", v(-h, 0, -s + WALL), v(h, HEIGHT, -s), COLORS.Wall)
	block(geo, "WallOuter", v(-h, 0, -WALL), v(-h + WALL, HEIGHT, -s + WALL), COLORS.Wall)
	-- Turn-side wall with the exit doorway.
	local half = DOOR.X / 2
	block(geo, "WallTurnA", v(h - WALL, 0, -WALL), v(h, HEIGHT, L_EXIT_Z + half), COLORS.Wall)
	block(geo, "WallTurnB", v(h - WALL, 0, L_EXIT_Z - half), v(h, HEIGHT, -s + WALL), COLORS.Wall)
	block(
		geo,
		"WallTurnTop",
		v(h - WALL, DOOR.Y, L_EXIT_Z + half),
		v(h, HEIGHT, L_EXIT_Z - half),
		COLORS.Trim
	)
	-- Solid fillers that cut the square into an L.
	block(geo, "FillerInner", v(L_CORRIDOR_HALF, 0, -WALL), v(h - WALL, HEIGHT, -L_TURN_DEPTH), COLORS.Filler)
	block(geo, "FillerOuter", v(-h + WALL, 0, -WALL), v(-L_CORRIDOR_HALF, HEIGHT, -s + WALL), COLORS.Filler)
	lamp(geo, v(0, HEIGHT - 0.5, -12))
	lamp(geo, v(8, HEIGHT - 0.5, L_EXIT_Z))

	socket(sockets, "Candy", v(0, 2, -8))
	socket(sockets, "Candy", v(0, 2, -18))
	socket(sockets, "Candy", v(4, 2, L_EXIT_Z))
	socket(sockets, "Candy", v(14, 2, L_EXIT_Z))
	socket(sockets, "Hide", v(-L_CORRIDOR_HALF + 2.5, 0.5, -34))
	socket(sockets, "MonsterSpawn", v(0, 0.5, L_EXIT_Z))

	local exitPosition = v(h, 0, L_EXIT_Z)
	finish(model, CFrame.lookAt(exitPosition, exitPosition + v(1, 0, 0)), parent)
end

local folder = ServerStorage:FindFirstChild("RoomTemplates")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "RoomTemplates"
	folder.Parent = ServerStorage
end
assert(folder, "RoomTemplates folder missing")

local builders: { [string]: (Instance) -> () } = {
	StraightHall = buildStraightHall,
	LHallLeft = function(parent)
		buildLHall(parent, "LHallLeft", -1)
	end,
	LHallRight = function(parent)
		buildLHall(parent, "LHallRight", 1)
	end,
}

for templateId, build in builders do
	if folder:FindFirstChild(templateId) then
		print("[BuildGreyboxRooms] " .. templateId .. " already exists, skipped")
	else
		build(folder)
		print("[BuildGreyboxRooms] built " .. templateId)
	end
end
print("[BuildGreyboxRooms] done - save the place (Ctrl+S) to keep the templates")
