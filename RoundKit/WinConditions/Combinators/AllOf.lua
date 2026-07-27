local WinCondition = require(script.Parent.Parent.Parent.Classes.WinCondition)

-- Fires only once every child agrees a win condition is met. Assumes children
-- agree on the winner when composed this way
local function AllOf(children)
	local resolved = {}
	for i, child in ipairs(children) do
		resolved[i] = WinCondition.Resolve(child)
	end

	return {
		Name = "AllOf",
		Evaluate = function(context)
			local firstOutcome = nil
			for _, condition in ipairs(resolved) do
				local outcome = condition:Evaluate(context)
				if not outcome then
					return nil
				end
				firstOutcome = firstOutcome or outcome
			end
			return firstOutcome
		end,
	}
end

return AllOf