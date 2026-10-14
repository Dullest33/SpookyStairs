--!strict
-- Per-template data that does not live on the Studio model. Keyed by the template's TemplateId attribute.
-- Floor range (MinFloor/MaxFloor) lives on the model itself (room template contract, plan §1).
-- weight = how often the generator picks this template compared to the others.

local Types = require(script.Parent.Types)

local RoomDefs: { [string]: Types.RoomDef } = {
	-- Greybox test rooms for M2 (tools/BuildGreyboxRooms.luau).
	StraightHall = { weight = 2 },
	LHallLeft = { weight = 1 },
	LHallRight = { weight = 1 },
}

return table.freeze(RoomDefs)
