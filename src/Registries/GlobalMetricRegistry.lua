--- @class GlobalMetricRegistry
--- Used to store global metrics for the round
local GlobalMetricRegistry = {}
GlobalMetricRegistry.__index = GlobalMetricRegistry
GlobalMetricRegistry._data = {}

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
	for key in pairs(self._data) do
		if type(key) == "string" then
			self._data[key] = nil
		end
	end
end

return GlobalMetricRegistry
