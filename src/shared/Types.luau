--!strict
-- Shared type definitions. Every module takes its types from here.

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
