--!strict
-- HUD. M2: floor number badge (top centre). M3 adds hearts, candy and the battery ring.
-- Everything is drawn at a reference size and scaled with UIScale; nothing important sits inside
-- the Config.UI.EdgeMargin band at the screen edges.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)

local HUDController = {}

local screenGui: ScreenGui
local uiScale: UIScale
local floorLabel: TextLabel

local function updateScale()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local viewport = camera.ViewportSize
	local shortest = math.min(viewport.X, viewport.Y)
	uiScale.Scale = math.clamp(shortest / Config.UI.ReferenceSize, Config.UI.MinScale, Config.UI.MaxScale)
end

local function setFloor(floor: number)
	floorLabel.Text = tostring(floor)
end

function HUDController:Init()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HUD"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	uiScale = Instance.new("UIScale")
	uiScale.Parent = screenGui

	local size = Config.UI.FloorBadgeSize
	local badge = Instance.new("Frame")
	badge.Name = "FloorBadge"
	badge.AnchorPoint = Vector2.new(0.5, 0)
	badge.Position = UDim2.fromScale(0.5, Config.UI.EdgeMargin)
	badge.Size = UDim2.fromOffset(size.X, size.Y)
	badge.BackgroundColor3 = Config.Colors.HudPanel
	badge.Parent = screenGui

	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = size.X / size.Y
	aspect.Parent = badge

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Config.UI.CornerRadius)
	corner.Parent = badge

	local stroke = Instance.new("UIStroke")
	stroke.Color = Config.Colors.Exit
	stroke.Thickness = Config.UI.StrokeThickness
	stroke.Parent = badge

	floorLabel = Instance.new("TextLabel")
	floorLabel.Name = "Floor"
	floorLabel.BackgroundTransparency = 1
	floorLabel.Size = UDim2.fromScale(1, 1)
	floorLabel.Font = Enum.Font.FredokaOne
	floorLabel.TextScaled = true
	floorLabel.TextColor3 = Config.Colors.HudText
	floorLabel.Text = ""
	floorLabel.Parent = badge

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(Config.UI.TextPadding, 0)
	padding.PaddingBottom = UDim.new(Config.UI.TextPadding, 0)
	padding.Parent = floorLabel
end

function HUDController:Start()
	local player = Players.LocalPlayer
	screenGui.Parent = player:WaitForChild("PlayerGui")

	updateScale()
	local camera = Workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
	end

	Remotes.get("FloorChanged").OnClientEvent:Connect(function(floor: number)
		setFloor(floor)
	end)
	Remotes.get("StateSync").OnClientEvent:Connect(function(view: Types.PlayerView)
		setFloor(view.floor)
	end)
end

return HUDController
