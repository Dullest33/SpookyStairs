--!strict
-- Tiny signal class for events between modules on the same machine.

export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
}

export type Signal<T...> = {
	Connect: (self: Signal<T...>, handler: (T...) -> ()) -> Connection,
	Once: (self: Signal<T...>, handler: (T...) -> ()) -> Connection,
	Wait: (self: Signal<T...>) -> T...,
	Fire: (self: Signal<T...>, T...) -> (),
	DisconnectAll: (self: Signal<T...>) -> (),
}

type ConnectionRecord = {
	Connected: boolean,
	Disconnect: (self: ConnectionRecord) -> (),
	handler: (...any) -> (),
}

local Signal = {}

function Signal.new<T...>(): Signal<T...>
	local records: { ConnectionRecord } = {}
	local signal = {}

	local function disconnect(record: ConnectionRecord)
		if not record.Connected then
			return
		end
		record.Connected = false
		local index = table.find(records, record)
		if index then
			table.remove(records, index)
		end
	end

	function signal.Connect(_self: any, handler: (...any) -> ()): ConnectionRecord
		local record: ConnectionRecord = {
			Connected = true,
			Disconnect = disconnect,
			handler = handler,
		}
		table.insert(records, record)
		return record
	end

	function signal.Once(self: any, handler: (...any) -> ()): ConnectionRecord
		local record: ConnectionRecord
		record = signal.Connect(self, function(...)
			disconnect(record)
			handler(...)
		end)
		return record
	end

	function signal.Wait(self: any): ...any
		local thread = coroutine.running()
		signal.Once(self, function(...)
			task.spawn(thread, ...)
		end)
		return coroutine.yield()
	end

	function signal.Fire(_self: any, ...: any)
		-- Copy so handlers can connect/disconnect while we iterate.
		for _, record in table.clone(records) do
			if record.Connected then
				task.spawn(record.handler, ...)
			end
		end
	end

	function signal.DisconnectAll(_self: any)
		for _, record in table.clone(records) do
			disconnect(record)
		end
	end

	return (signal :: any) :: Signal<T...>
end

return Signal
