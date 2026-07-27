--- @class WinCondition
--- Used to evaluate win conditions
local WinCondition = {}
WinCondition.__index = WinCondition

local registry = {}

--- @param name string
--- @param evaluator (context: Context) -> (WinOutcome)
--- @return WinCondition
--- Constructor method for a new win condition
function WinCondition.new(name, evaluator)
	assert(not registry[name], "RoundKit: a WinCondition named '" .. name .. "' is already registered")

	local self = setmetatable({
		Name = name,
		_evaluator = evaluator,
	}, WinCondition)

	registry[name] = self
	return self
end

--- @param context Context
--- @return WinOutcome
--- Evaluates the win condition using the provided context
function WinCondition:Evaluate(context)
	return self._evaluator(context)
end

--- @param nameOrInstance string | WinCondition
--- @return WinCondition
--- Resolves a string name to a WinCondition instance or returns the provided instance
function WinCondition.Resolve(nameOrInstance)
	if type(nameOrInstance) == "string" then
		local found = registry[nameOrInstance]
		assert(found, "RoundKit: no WinCondition registered under name '" .. nameOrInstance .. "'")
		return found
	end
	return nameOrInstance
end

return WinCondition
