--!strict
-- The ONLY place candy and cards are granted. M1 has candy only; cards and golden rolls arrive in M8.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)

local RewardService = {}

-- Adds `amount` candy (a positive whole number). Returns false if nothing was granted.
function RewardService:GrantCandy(player: Player, amount: number): boolean
	if amount <= 0 or math.floor(amount) ~= amount then
		warn(string.format("[RewardService] bad candy amount %s for %s", tostring(amount), player.Name))
		return false
	end
	local granted = DataService:Update(player, function(profile)
		profile.candy += amount
	end)
	if granted then
		Remotes.get("RewardGranted"):FireClient(player, "candy", amount)
	end
	return granted
end

function RewardService:Init() end

function RewardService:Start() end

return RewardService
