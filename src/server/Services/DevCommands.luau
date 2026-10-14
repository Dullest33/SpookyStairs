--!strict
-- Studio-only test commands. They are never created on live servers.
-- /candy  -> grants Config.Debug.TestCandyAmount candy through RewardService.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)
local RewardService = require(script.Parent.RewardService)

local DevCommands = {}

local function makeCommand(name: string, alias: string, onTriggered: (player: Player) -> ())
	local command = Instance.new("TextChatCommand")
	command.Name = name
	command.PrimaryAlias = alias
	-- The typed text is ignored on purpose: no player-written text is ever used.
	command.Triggered:Connect(function(source: TextSource, _text: string)
		local player = Players:GetPlayerByUserId(source.UserId)
		if player then
			onTriggered(player)
		end
	end)
	command.Parent = TextChatService
end

function DevCommands:Init() end

function DevCommands:Start()
	if not (RunService:IsStudio() and Config.Debug.TestCommandsEnabled) then
		return
	end

	makeCommand("DevCandyCommand", "/candy", function(player)
		if RewardService:GrantCandy(player, Config.Debug.TestCandyAmount) then
			local profile = DataService:GetProfile(player)
			print(
				string.format(
					"[DevCommands] %s now has %d candy",
					player.Name,
					profile and profile.candy or -1
				)
			)
		end
	end)
end

return DevCommands
