--!strict
-- Single list of every RemoteEvent. The server creates them; everyone fetches them by name.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Types = require(script.Parent.Types)

type RemoteName = Types.RemoteName

-- Lives outside ReplicatedStorage.Shared so Rojo never touches it.
local FOLDER_NAME = "Remotes"

local NAMES: { RemoteName } = {
	-- client -> server
	"RequestOpenDoor",
	"RequestHide",
	"RequestUnhide",
	"SetFlashlight",
	"RequestCollect",
	"RequestRevive",
	"SubmitPuzzle",
	"SetCrouch",
	"RequestPurchase",
	"SetSetting",
	"RequestQueue",
	"LeaveQueue",
	-- server -> client
	"StateSync",
	"FloorChanged",
	"MonsterEvent",
	"RewardGranted",
	"PlayerScared",
}

local cache: { [string]: RemoteEvent } = {}

local Remotes = {}

-- Server only: create the folder and every remote. Call once before any service Init.
function Remotes.init()
	assert(RunService:IsServer(), "Remotes.init is server-only")

	local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if not folder then
		local newFolder = Instance.new("Folder")
		newFolder.Name = FOLDER_NAME
		newFolder.Parent = ReplicatedStorage
		folder = newFolder
	end
	assert(folder, "Remotes folder missing")

	for _, name in NAMES do
		local existing = folder:FindFirstChild(name)
		local remote: RemoteEvent
		if existing and existing:IsA("RemoteEvent") then
			remote = existing :: RemoteEvent
		else
			remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
		cache[name] = remote
	end
end

function Remotes.get(name: RemoteName): RemoteEvent
	local cached = cache[name]
	if cached then
		return cached
	end
	assert(not RunService:IsServer(), "Remotes.get called on the server before Remotes.init")

	local folder = ReplicatedStorage:WaitForChild(FOLDER_NAME)
	local remote = folder:WaitForChild(name) :: RemoteEvent
	cache[name] = remote
	return remote
end

return Remotes
