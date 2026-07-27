--- @class GlobalMetricRegistry
--- Used to store global metrics for the round
local GlobalMetricRegistry = {}
GlobalMetricRegistry.__index = GlobalMetricRegistry

--- @param key string
--- @return any
--- Gets a value from the registry
function GlobalMetricRegistry:Get(key)
	return self[key]
end

--- @param key string
--- @param value any
--- @return ()
--- Sets a value in the registry
function GlobalMetricRegistry:Set(key, value)
	self[key] = value
end

--- @param key string
--- @param delta number
--- @return ()
--- Applies a delta to a value in the registry
function GlobalMetricRegistry:Apply(key, delta)
	self[key] = (self[key] or 0) + delta
end

--- @return ()
--- Clears all values from the registry
function GlobalMetricRegistry:Clear()
	for key in pairs(self) do
		if type(key) == "string" then
			self[key] = nil
		end
	end
end

return GlobalMetricRegistry
