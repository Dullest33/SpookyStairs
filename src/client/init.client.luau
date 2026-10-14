--!strict
-- Client entry point: Init()s every controller in order, then Start()s them.
-- Controllers only render and send intents; the server decides everything.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)

-- Controllers are added here as their milestones land (HUDController and FeedbackController in M3, ...).
local controllers: { Types.Service } = {}

for _, controller in controllers do
	controller:Init()
end

for _, controller in controllers do
	task.spawn(function()
		controller:Start()
	end)
end
