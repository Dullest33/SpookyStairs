--!strict
-- Studio-only test commands. They are never created on live servers.
-- /candy  -> grants Config.Debug.TestCandyAmount candy through RewardService.
-- Works with both chat systems; the typed text is only compared to the command, never shown or stored.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)
local RewardService = require(script.Parent.RewardService)

type CommandHandler = (player: Player) -> ()

local DevCommands = {}

local commands: { [string]: CommandHandler } = {}

local function run(alias: string, player: Player)
	local handler = commands[alias]
	if not handler then
		return
	end
	print(string.format("[DevCommands] %s used %s", player.Name, alias))
	handler(player)
end

-- New chat (TextChatService): a TextChatCommand per alias.
local function listenTextChat()
	for alias in commands do
		local command = Instance.new("TextChatCommand")
		command.Name = "Dev" .. alias:sub(2)
		command.PrimaryAlias = alias
		command.Triggered:Connect(function(source: TextSource, _text: string)
			local player = Players:GetPlayerByUserId(source.UserId)
			if player then
				run(alias, player)
			end
		end)
		command.Parent = TextChatService
	end
end

-- Legacy chat: match the whole message against the aliases.
local function listenLegacyChat()
	local function watch(player: Player)
		player.Chatted:Connect(function(message: string)
			run(string.lower(message), player)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
end

function DevCommands:Init() end

function DevCommands:Start()
	if not (RunService:IsStudio() and Config.Debug.TestCommandsEnabled) then
		return
	end

	commands["/candy"] = function(player)
		if not DataService:IsLoaded(player) then
			warn("[DevCommands] /candy ignored: profile not loaded yet")
			return
		end
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
	end

	local chatVersion = TextChatService.ChatVersion
	if chatVersion == Enum.ChatVersion.TextChatService then
		listenTextChat()
	else
		listenLegacyChat()
	end
	print(string.format("[DevCommands] ready - type /candy in chat (chat: %s)", chatVersion.Name))
end

return DevCommands
