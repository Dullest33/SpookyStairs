--!strict
-- Wrapper around Random.new(seed) so a run's floors can be rebuilt from its seed.

local SeededRandom = {}
SeededRandom.__index = SeededRandom

type SeededRandomData = {
	seed: number,
	_random: Random,
}

export type SeededRandom = typeof(setmetatable({} :: SeededRandomData, SeededRandom))

function SeededRandom.new(seed: number): SeededRandom
	return setmetatable({ seed = seed, _random = Random.new(seed) } :: SeededRandomData, SeededRandom)
end

-- Inclusive on both ends.
function SeededRandom.Integer(self: SeededRandom, min: number, max: number): number
	return self._random:NextInteger(min, max)
end

function SeededRandom.Number(self: SeededRandom, min: number?, max: number?): number
	return self._random:NextNumber(min or 0, max or 1)
end

-- True with probability `chance` (0..1).
function SeededRandom.Chance(self: SeededRandom, chance: number): boolean
	return self._random:NextNumber() < chance
end

function SeededRandom.Pick<T>(self: SeededRandom, list: { T }): T
	assert(#list > 0, "SeededRandom.Pick on empty list")
	return list[self._random:NextInteger(1, #list)]
end

-- Picks from `entries` where each entry's chance is proportional to weightOf(entry).
function SeededRandom.WeightedPick<T>(self: SeededRandom, entries: { T }, weightOf: (T) -> number): T
	assert(#entries > 0, "SeededRandom.WeightedPick on empty list")
	local total = 0
	for _, entry in entries do
		total += math.max(weightOf(entry), 0)
	end
	if total <= 0 then
		return self:Pick(entries)
	end
	local roll = self._random:NextNumber() * total
	for _, entry in entries do
		roll -= math.max(weightOf(entry), 0)
		if roll < 0 then
			return entry
		end
	end
	return entries[#entries]
end

-- Returns a shuffled copy; the input list is not changed.
function SeededRandom.Shuffle<T>(self: SeededRandom, list: { T }): { T }
	local copy = table.clone(list)
	for index = #copy, 2, -1 do
		local swap = self._random:NextInteger(1, index)
		copy[index], copy[swap] = copy[swap], copy[index]
	end
	return copy
end

return SeededRandom
