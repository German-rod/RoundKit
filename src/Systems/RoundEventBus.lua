local Signal = require(script.Parent.Parent.Classes.Signal) -- Sleitnick's Signal

--- @class RoundEventBus
--- Provides an event bus for the round manager, allowing for event-driven communication between different parts of the system with Sleitnick's signal.
local RoundEventBus = {}
RoundEventBus.__index = RoundEventBus

--- Constructor method for a new RoundEventBus
--- @return RoundEventBus
function RoundEventBus.new()
	return setmetatable({
		_signals = {},
	}, RoundEventBus)
end

--- Gets an event from the event bus, if it does not exist it will be created.
--- @param eventName string
--- @return signal Signal
function RoundEventBus:Get(eventName)
	local signal = self._signals[eventName]
	if not signal then
		signal = Signal.new()
		self._signals[eventName] = signal
	end
	return signal
end

--- Connects to an event on the event bus, if it does not exist it will be created.
--- @param eventName string
--- @param callback any
--- @return RBXScriptConnection
function RoundEventBus:Connect(eventName, callback)
	return self:Get(eventName):Connect(callback)
end

--- Fires an event on the event bus.
--- @param eventName string
--- @param ... any
function RoundEventBus:Fire(eventName, ...)
	local signal = self._signals[eventName]
	if signal then
		signal:Fire(...)
	end
end

function RoundEventBus:Destroy()
	for _, signal in pairs(self._signals) do
		signal:Destroy()
	end
	self._signals = {}
	setmetatable(self, nil)
	self = nil
end

return RoundEventBus
