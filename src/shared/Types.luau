--!strict
-- Shared type definitions. Every module takes its types from here.

local SeededRandom = require(script.Parent.Util.SeededRandom)
local Trove = require(script.Parent.Util.Trove)

export type CardEntry = {
	normal: boolean,
	golden: boolean,
}

export type ProfileSettings = {
	lessSpooky: boolean,
}

export type ProfileStats = {
	runs: number,
	floorsCleared: number,
	timesScared: number,
}

export type Profile = {
	version: number,
	candy: number,
	bestFloor: number,
	checkpointFloor: number,
	flashlightLevel: number,
	perks: { [string]: boolean },
	cards: { [string]: CardEntry },
	cosmetics: { [string]: boolean },
	midnightUnlocked: boolean,
	settings: ProfileSettings,
	stats: ProfileStats,
}

-- What is actually written to the DataStore: the profile plus its session lock.
export type StoredRecord = {
	profile: Profile,
	lockJobId: string?,
	lockTime: number?,
}

-- Everything the client is allowed to know about its own player (sent via StateSync).
export type PlayerView = {
	hearts: number,
	floor: number,
	candy: number,
	battery: number,
	partyIds: { number },
}

-- Per-template data that is not part of the Studio model (shared/RoomDefs.luau).
export type RoomDef = {
	weight: number,
}

-- A room template read from ServerStorage.RoomTemplates, with its geometry measured from the Entrance.
export type RoomTemplate = {
	templateId: string,
	model: Model,
	minFloor: number,
	maxFloor: number,
	weight: number,
	entranceToExit: CFrame,
	entranceToBox: CFrame,
	boxSize: Vector3,
}

-- World-space axis-aligned box, already shrunk by Config.Floors.OverlapTolerance.
export type Box = {
	min: Vector3,
	max: Vector3,
}

-- The generator's memory for one run: where the next room goes and what came before.
export type Layout = {
	rng: SeededRandom.SeededRandom,
	origin: CFrame,
	nextAnchor: CFrame,
	lastTemplateId: string?,
	recentBoxes: { Box },
}

export type DoorState = "closed" | "opening" | "open"

export type Room = {
	floor: number,
	templateId: string,
	model: Model,
	entrance: BasePart,
	exit: BasePart,
	door: Model,
	doorState: DoorState,
	sealed: boolean,
	trove: Trove.Trove,
}

export type Run = {
	player: Player,
	floor: number,
	hearts: number,
	slot: number,
	layout: Layout,
	rooms: { [number]: Room },
	folder: Folder,
	trove: Trove.Trove,
}

export type RewardKind = "candy" | "card" | "golden" | "badge"

export type MonsterPhase = "signal" | "act" | "leave"

export type ClientRemoteName =
	"RequestOpenDoor"
	| "RequestHide"
	| "RequestUnhide"
	| "SetFlashlight"
	| "RequestCollect"
	| "RequestRevive"
	| "SubmitPuzzle"
	| "SetCrouch"
	| "RequestPurchase"
	| "SetSetting"
	| "RequestQueue"
	| "LeaveQueue"

export type ServerRemoteName =
	"StateSync"
	| "FloorChanged"
	| "MonsterEvent"
	| "RewardGranted"
	| "PlayerScared"

export type RemoteName = ClientRemoteName | ServerRemoteName

-- Shape shared by every server service and client controller.
export type Service = {
	Init: (self: any) -> (),
	Start: (self: any) -> (),
}

return {}
