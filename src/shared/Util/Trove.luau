--!strict
-- Collects things that must be cleaned up together (per floor, per run) and cleans them in one call.
-- Accepts Instances, connections, functions, threads and objects with Destroy/Disconnect.

local Trove = {}
Trove.__index = Trove

type TroveData = {
	_items: { any },
	_cleaning: boolean,
}

export type Trove = typeof(setmetatable({} :: TroveData, Trove))

local function cleanItem(item: any)
	local kind = typeof(item)
	if kind == "Instance" then
		item:Destroy()
	elseif kind == "RBXScriptConnection" then
		item:Disconnect()
	elseif kind == "function" then
		item()
	elseif kind == "thread" then
		-- A thread cannot cancel itself; skip it if it is the one cleaning.
		if coroutine.running() ~= item then
			pcall(task.cancel, item)
		end
	elseif kind == "table" then
		if type(item.Destroy) == "function" then
			item:Destroy()
		elseif type(item.Disconnect) == "function" then
			item:Disconnect()
		end
	end
end

function Trove.new(): Trove
	return setmetatable({ _items = {}, _cleaning = false } :: TroveData, Trove)
end

function Trove.Add<T>(self: Trove, item: T): T
	if self._cleaning then
		-- Something added during cleanup would leak; clean it straight away.
		cleanItem(item)
		return item
	end
	table.insert(self._items, item)
	return item
end

function Trove.Connect(self: Trove, signal: RBXScriptSignal, handler: (...any) -> ()): RBXScriptConnection
	return self:Add(signal:Connect(handler))
end

-- Makes a child trove that is cleaned when this one is.
function Trove.Extend(self: Trove): Trove
	return self:Add(Trove.new())
end

function Trove.Clean(self: Trove)
	if self._cleaning then
		return
	end
	self._cleaning = true
	local items = self._items
	self._items = {}
	-- Reverse order: things created last are usually built on things created first.
	for index = #items, 1, -1 do
		local ok, err = pcall(cleanItem, items[index])
		if not ok then
			warn("[Trove] cleanup error: " .. tostring(err))
		end
	end
	self._cleaning = false
end

Trove.Destroy = Trove.Clean

return Trove
