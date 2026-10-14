--!strict
-- Server entry point: creates remotes, then Init()s every service in order, then Start()s them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)

Remotes.init()

local Services = script.Services

-- Order matters: a service may only use services listed above it during Init.
local services: { Types.Service } = {
	require(Services.DataService),
	require(Services.RemoteGuard),
	require(Services.RewardService),
	require(Services.DevCommands),
}

for _, service in services do
	service:Init()
end

for _, service in services do
	-- Spawned so one slow Start can't hold up the others.
	task.spawn(function()
		service:Start()
	end)
end
