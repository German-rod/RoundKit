--- @class GlobalMetricRegistry
--- Used to store global metrics for the round
local GlobalMetricRegistry = {}
GlobalMetricRegistry.__index = GlobalMetricRegistry


--- @return GlobalMetricRegistry
--- Constructs a new GlobalMetricRegistry.
function GlobalMetricRegistry.new()
	local self = setmetatable({_data = {}}, GlobalMetricRegistry)

	return self
end

--- @param key string
--- @return any
--- Gets a value from the registry
function GlobalMetricRegistry:Get(key)
	return self._data[key]
end

--- @param key string
--- @param value any
--- @return ()
--- Sets a value in the registry
function GlobalMetricRegistry:Set(key, value)
	self._data[key] = value
end

--- @return ()
--- Clears all values from the registry
function GlobalMetricRegistry:Clear()
	for i,_ in pairs(self._data) do
		self._data[i] = nil
	end

	self._data = {}
end


--- @return ()
--- Destroys the global metric registry
function GlobalMetricRegistry:Destroy()
	self:Clear()
	setmetatable(self, nil)
end

return GlobalMetricRegistry
