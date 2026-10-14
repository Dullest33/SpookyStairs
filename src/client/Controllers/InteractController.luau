--!strict
-- Turns ProximityPrompt use into intents for the server. Prompts are tagged by the server with
-- the Config.Interact.Attribute attribute; the server re-checks everything (distance, room, state).

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local InteractController = {}

function InteractController:Init() end

function InteractController:Start()
	local openDoor = Remotes.get("RequestOpenDoor")

	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt)
		local kind = prompt:GetAttribute(Config.Interact.Attribute)
		if kind == Config.Interact.Door then
			openDoor:FireServer()
		end
	end)
end

return InteractController
