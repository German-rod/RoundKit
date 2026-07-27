local WinCondition = require(script.Parent.Parent.Parent.Classes.WinCondition)

-- Returns the first child's outcome that isn't nil. Order matters if children
-- could disagree on a winner, first match wins.
local function AnyOf(children)
	local resolved = {}
	for i, child in ipairs(children) do
		resolved[i] = WinCondition.Resolve(child)
	end

	return {
		Name = "AnyOf",
		Evaluate = function(context)
			for _, condition in ipairs(resolved) do
				local outcome = condition:Evaluate(context)
				if outcome then
					return outcome
				end
			end
			return nil
		end,
	}
end

return AnyOf