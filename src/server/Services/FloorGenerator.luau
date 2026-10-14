--!strict
-- Builds rooms from the hand-built templates in ServerStorage.RoomTemplates (room template contract, plan §1).
-- Each new room's Entrance is snapped onto the previous room's Exit. A template is rejected (try the next) when
-- it would overlap the previous rooms, turn back on itself, or drift too far sideways; the fallback straight
-- hallway is used if nothing else fits.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local RoomDefs = require(ReplicatedStorage.Shared.RoomDefs)
local SeededRandom = require(ReplicatedStorage.Shared.Util.SeededRandom)
local Trove = require(ReplicatedStorage.Shared.Util.Trove)
local Types = require(ReplicatedStorage.Shared.Types)

type Box = Types.Box
type Layout = Types.Layout
type Room = Types.Room
type RoomTemplate = Types.RoomTemplate

local TEMPLATE_FOLDER = "RoomTemplates"

local templates: { RoomTemplate } = {}
local templatesById: { [string]: RoomTemplate } = {}

local FloorGenerator = {}

local function readTemplate(instance: Instance): (RoomTemplate?, string?)
	if not instance:IsA("Model") then
		return nil, "is not a Model"
	end
	local model = instance :: Model
	local entrance = model.PrimaryPart
	if not entrance or entrance.Name ~= "Entrance" then
		return nil, "PrimaryPart must be the part named Entrance"
	end
	local exit = model:FindFirstChild("Exit")
	if not (exit and exit:IsA("BasePart")) then
		return nil, "has no Exit part"
	end
	local sockets = model:FindFirstChild("Sockets")
	if not (sockets and sockets:IsA("Folder")) then
		return nil, "has no Sockets folder"
	end
	local templateId = model:GetAttribute("TemplateId")
	if type(templateId) ~= "string" or templateId == "" then
		return nil, "has no TemplateId attribute"
	end
	local minFloor = model:GetAttribute("MinFloor")
	local maxFloor = model:GetAttribute("MaxFloor")
	if type(minFloor) ~= "number" or type(maxFloor) ~= "number" or minFloor > maxFloor then
		return nil, "needs number attributes MinFloor <= MaxFloor"
	end

	local def = RoomDefs[templateId]
	if not def then
		warn(string.format("[FloorGenerator] %s has no RoomDefs entry; using default weight", templateId))
	end

	local boxCFrame, boxSize = model:GetBoundingBox()
	local exitPart = exit :: BasePart
	return {
		templateId = templateId,
		model = model,
		minFloor = minFloor,
		maxFloor = maxFloor,
		weight = if def then def.weight else Config.Floors.DefaultRoomWeight,
		entranceToExit = entrance.CFrame:ToObjectSpace(exitPart.CFrame),
		entranceToBox = entrance.CFrame:ToObjectSpace(boxCFrame),
		boxSize = boxSize,
	},
		nil
end

-- Axis-aligned world box around an oriented box, shrunk so rooms that only touch don't count as overlapping.
local function worldBox(boxCFrame: CFrame, size: Vector3): Box
	local half = size / 2
	local minCorner = Vector3.one * math.huge
	local maxCorner = -Vector3.one * math.huge
	for _, sx in { -1, 1 } do
		for _, sy in { -1, 1 } do
			for _, sz in { -1, 1 } do
				local corner = boxCFrame:PointToWorldSpace(Vector3.new(half.X * sx, half.Y * sy, half.Z * sz))
				minCorner = minCorner:Min(corner)
				maxCorner = maxCorner:Max(corner)
			end
		end
	end
	local shrink = Vector3.one * Config.Floors.OverlapTolerance
	return { min = minCorner + shrink, max = maxCorner - shrink }
end

local function overlaps(a: Box, b: Box): boolean
	return a.min.X < b.max.X
		and a.max.X > b.min.X
		and a.min.Y < b.max.Y
		and a.max.Y > b.min.Y
		and a.min.Z < b.max.Z
		and a.max.Z > b.min.Z
end

-- Returns the room's box if `template` can go at `anchor`, or nil if it must be rejected.
local function tryFit(layout: Layout, template: RoomTemplate, anchor: CFrame): Box?
	local exitCFrame = anchor * template.entranceToExit
	local origin = layout.origin

	if exitCFrame.LookVector:Dot(origin.LookVector) < Config.Floors.MinForwardDot then
		return nil
	end

	local right = origin.RightVector
	-- Past the drift limit, only rooms whose exit points back in (or straight ahead) are allowed.
	-- Turns still shift sideways a little, so judge by where the exit faces, not where it ends up.
	local drift = (exitCFrame.Position - origin.Position):Dot(right)
	local headingOut = exitCFrame.LookVector:Dot(right) * math.sign(drift)
	if math.abs(drift) > Config.Floors.MaxLateralDrift and headingOut > Config.Floors.OutwardDot then
		return nil
	end

	local box = worldBox(anchor * template.entranceToBox, template.boxSize)
	for _, previous in layout.recentBoxes do
		if overlaps(box, previous) then
			return nil
		end
	end
	return box
end

local function pickTemplate(layout: Layout, floor: number, anchor: CFrame): (RoomTemplate, Box)
	local candidates = {}
	for _, template in templates do
		if
			floor >= template.minFloor
			and floor <= template.maxFloor
			and template.templateId ~= layout.lastTemplateId
		then
			table.insert(candidates, template)
		end
	end

	while #candidates > 0 do
		local choice = layout.rng:WeightedPick(candidates, function(template: RoomTemplate)
			return template.weight
		end)
		local box = tryFit(layout, choice, anchor)
		if box then
			return choice, box
		end
		table.remove(candidates, table.find(candidates, choice) :: number)
	end

	local fallback = templatesById[Config.Floors.FallbackTemplateId] or templates[1]
	warn(string.format("[FloorGenerator] floor %d: nothing fit, using %s", floor, fallback.templateId))
	return fallback, worldBox(anchor * fallback.entranceToBox, fallback.boxSize)
end

local function makeDoor(exitCFrame: CFrame, nextFloor: number): Model
	local size = Config.Floors.DoorSize
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local custom = assets and assets:FindFirstChild("Door")

	local door: Model
	if custom and custom:IsA("Model") and (custom :: Model).PrimaryPart then
		door = (custom :: Model):Clone()
	else
		-- Greybox door until ReplicatedStorage.Assets.Door is built by hand.
		door = Instance.new("Model")
		local slab = Instance.new("Part")
		slab.Name = "Slab"
		slab.Size = size
		slab.Color = Config.Colors.Exit
		slab.Material = Enum.Material.SmoothPlastic
		slab.Anchored = true
		slab.Parent = door
		door.PrimaryPart = slab
	end
	door.Name = "Door"

	-- The door fills the doorway in the room's front wall, which sits just inside the Exit.
	door:PivotTo(exitCFrame * CFrame.new(0, size.Y / 2, Config.Floors.WallThickness / 2))

	local panel = door.PrimaryPart :: BasePart
	local light = Instance.new("PointLight")
	light.Color = Config.Colors.Exit
	light.Brightness = Config.Floors.DoorLightBrightness
	light.Range = Config.Floors.DoorLightRange
	light.Parent = panel

	-- Floor number on the side facing the player.
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Back
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = Config.Floors.DoorNumberPixelsPerStud
	surface.Parent = panel
	local number = Instance.new("TextLabel")
	number.BackgroundTransparency = 1
	number.AnchorPoint = Vector2.new(0.5, 0)
	number.Position = UDim2.fromScale(0.5, 0.1)
	number.Size = UDim2.fromScale(0.7, 0.25)
	number.Font = Enum.Font.FredokaOne
	number.TextScaled = true
	number.TextColor3 = Config.Colors.HudText
	number.Text = tostring(nextFloor)
	number.Parent = surface

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Open"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Config.Floors.DoorPromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Enabled = nextFloor <= Config.MaxFloor
	prompt:SetAttribute(Config.Interact.Attribute, Config.Interact.Door)
	prompt.Parent = panel

	return door
end

function FloorGenerator:HasTemplates(): boolean
	return #templates > 0
end

function FloorGenerator:NewLayout(seed: number, origin: CFrame): Layout
	return {
		rng = SeededRandom.new(seed),
		origin = origin,
		nextAnchor = origin,
		lastTemplateId = nil,
		recentBoxes = {},
	}
end

-- Builds the next room of `layout` for `floor` under `parent`. Rooms must be built in floor order.
function FloorGenerator:BuildRoom(layout: Layout, floor: number, parent: Instance): Room
	local anchor = layout.nextAnchor
	local template, box = pickTemplate(layout, floor, anchor)

	local model = template.model:Clone()
	model.Name = string.format("Floor%02d_%s", floor, template.templateId)
	-- Stream the room in and out as one piece so players never see half a room.
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	local entrance = model.PrimaryPart :: BasePart
	local pivotFromEntrance = entrance.CFrame:ToObjectSpace(model:GetPivot())
	model:PivotTo(anchor * pivotFromEntrance)

	local exit = model:FindFirstChild("Exit") :: BasePart
	local door = makeDoor(exit.CFrame, floor + 1)
	door.Parent = model

	local trove = Trove.new()
	trove:Add(model)
	model.Parent = parent

	layout.nextAnchor = exit.CFrame
	layout.lastTemplateId = template.templateId
	table.insert(layout.recentBoxes, box)
	while #layout.recentBoxes > Config.Floors.OverlapCheckRooms do
		table.remove(layout.recentBoxes, 1)
	end

	return {
		floor = floor,
		templateId = template.templateId,
		model = model,
		entrance = entrance,
		exit = exit,
		door = door,
		doorState = "closed",
		sealed = false,
		trove = trove,
	}
end

function FloorGenerator:OpenDoor(room: Room)
	if room.doorState ~= "closed" then
		return
	end
	room.doorState = "opening"
	local door = room.door
	local tweenInfo = TweenInfo.new(Config.Floors.DoorOpenSeconds)
	for _, descendant in door:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			TweenService:Create(descendant, tweenInfo, { Transparency = 1 }):Play()
		elseif descendant:IsA("ProximityPrompt") then
			descendant.Enabled = false
		end
	end
	task.delay(Config.Floors.DoorOpenSeconds, function()
		room.doorState = "open"
		door:Destroy()
	end)
end

-- Fills the doorway behind the oldest room so nobody walks back into the void where older rooms were.
function FloorGenerator:SealEntrance(room: Room)
	if room.sealed then
		return
	end
	room.sealed = true
	local size = Config.Floors.DoorSize
	local wall = Instance.new("Part")
	wall.Name = "EntranceSeal"
	wall.Size = size
	wall.Color = Config.Colors.Wall
	wall.Material = Enum.Material.SmoothPlastic
	wall.Anchored = true
	wall.CFrame = room.entrance.CFrame * CFrame.new(0, size.Y / 2, -Config.Floors.WallThickness / 2)
	wall.Parent = room.model
end

function FloorGenerator:DestroyRoom(room: Room)
	room.trove:Destroy()
end

function FloorGenerator:Init()
	local folder = ServerStorage:FindFirstChild(TEMPLATE_FOLDER)
	if not folder then
		warn(
			"[FloorGenerator] ServerStorage.RoomTemplates is missing. "
				.. "Run tools/BuildGreyboxRooms.luau in the Studio Command Bar."
		)
		return
	end
	for _, child in folder:GetChildren() do
		local template, problem = readTemplate(child)
		if template then
			if templatesById[template.templateId] then
				warn(string.format("[FloorGenerator] duplicate TemplateId %s skipped", template.templateId))
			else
				table.insert(templates, template)
				templatesById[template.templateId] = template
			end
		else
			warn(string.format("[FloorGenerator] template %s skipped: %s", child.Name, tostring(problem)))
		end
	end
	-- Sorted so the same seed always gives the same floors.
	table.sort(templates, function(a, b)
		return a.templateId < b.templateId
	end)
	if not templatesById[Config.Floors.FallbackTemplateId] then
		warn(
			string.format(
				"[FloorGenerator] fallback template %s is missing",
				Config.Floors.FallbackTemplateId
			)
		)
	end
	print(string.format("[FloorGenerator] %d room templates ready", #templates))
end

function FloorGenerator:Start() end

return FloorGenerator
