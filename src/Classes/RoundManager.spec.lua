return function()
	local RoundManager = require(script.Parent.RoundManager)
	local DriverSignal = require(script.Parent.Signal).new()

	describe("CanTransitionTo", function()
		it("should not transition when CanTransitionTo returns false", function()
			local manager = RoundManager.new({
				Driver = DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = {
						Name = "Waiting",
						CanTransitionTo = function()
							return false
						end,
						AllowedTransitions = { "Playing" },
					},
					Playing = {
						Name = "Playing",
					},
				},
			})

			manager:Start()
			DriverSignal:Fire()

			expect(manager.CurrentPhase.Name).to.equal("Waiting")
		end)
	end)
end
