return function()
	local RoundKit = require(script.Parent.Parent)
	local RoundManager = require(script.Parent.RoundManager)
	local Signal = require(script.Parent.Signal)

	beforeEach(function(context)
		context.DriverSignal = Signal.new()
	end)

	afterEach(function(context)
		context.DriverSignal:Destroy()

		RoundKit.WinCondition.remove("TestWinCondition")
	end)

	describe("Start", function()
			it("should transition into Config.InitialPhase on Start", function(context)
			local manager = RoundManager.new({
				Driver = context.DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = {
						Name = "Waiting",
					},
				},
			})
	
			manager:Start()
			expect(manager.CurrentPhase.Name).to.equal("Waiting")
		end)
	end)

	describe("Pause and Resume", function()
		it("should not advance phase state while paused", function(context)
			local manager = RoundManager.new({
				Driver = context.DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = {
						Name = "Waiting",
						Duration = 5,
						CanTransitionTo = function()
							return true
						end,
						AllowedTransitions = { "Playing" },
					},
					Playing = {
						Name = "Playing",
					},
				},
			})

			manager:Start()
			context.DriverSignal:Fire(1)
			expect(manager.CurrentPhase.Name).to.equal("Waiting")
			manager:Pause()
			context.DriverSignal:Fire(5)
			expect(manager.CurrentPhase.Name).to.equal("Waiting")
		end)

		it("should resume ticking after Resume is called", function(context)
			local manager = RoundManager.new({
				Driver = context.DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = {
						Name = "Waiting",
						Duration = 5,
						CanTransitionTo = function()
							return true
						end,
						AllowedTransitions = { "Playing" },
					},
					Playing = {
						Name = "Playing",
					},
				},
			})

			manager:Start()
			context.DriverSignal:Fire(1)
			expect(manager.CurrentPhase.Name).to.equal("Waiting")

			manager:Pause()
			context.DriverSignal:Fire(5)
			expect(manager.CurrentPhase.Name).to.equal("Waiting")

			manager:Resume()
			context.DriverSignal:Fire(5)
			expect(manager.CurrentPhase.Name).to.equal("Playing")
		end)

		
		
	end)

	describe("Reset", function()
		it("should properly reset the round manager on Reset", function(context)
			local manager = RoundManager.new({
				Driver = context.DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = {
						Name = "Waiting",
						Duration = 5,
						CanTransitionTo = function()
							return true
						end,
						AllowedTransitions = { "Playing" },
					},
					Playing = {
						Name = "Playing",
					},
				},
			})

			manager:Start()
			context.DriverSignal:Fire(5)
			expect(manager.CurrentPhase.Name).to.equal("Playing")

			manager:Reset()
			expect(manager.CurrentPhase.Name).to.equal("Waiting")
		end)
	end)

	describe("CanTransitionTo", function()
		it("should not transition when CanTransitionTo returns false", function(context)
			local manager = RoundManager.new({
				Driver = context.DriverSignal,
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
			context.DriverSignal:Fire()

			expect(manager.CurrentPhase.Name).to.equal("Waiting")
		end)

		it("should transition when CanTransitionTo returns true", function(context)
			local manager = RoundManager.new({
				Driver = context.DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = {
						Name = "Waiting",
						CanTransitionTo = function()
							return true
						end,
						AllowedTransitions = { "Playing" },
					},
					Playing = {
						Name = "Playing",
					},
				},
			})

			manager:Start()
			context.DriverSignal:Fire()

			expect(manager.CurrentPhase.Name).to.equal("Playing")
		end)

		it("should treat a thrown error as false and not transition", function(context)
			local manager = RoundManager.new({
				Driver = context.DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = {
						Name = "Waiting",
						CanTransitionTo = function()
							error("This is an error")
						end,
						AllowedTransitions = { "Playing" },
					},
					Playing = {
						Name = "Playing",
					},
				},
			})

			manager:Start()
			context.DriverSignal:Fire()

			expect(manager.CurrentPhase.Name).to.equal("Waiting")
		end)

	end)

	describe("AllowedTransitions (function)", function()
		it("should transition when the function returns a table containing the target", function(context)
			local manager = RoundManager.new({
				Driver = context.DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = {
						Name = "Waiting",
						CanTransitionTo = function()
							return true
						end,
						AllowedTransitions = function()
							return { "Playing" }
						end,
					},
					Playing = {
						Name = "Playing",
					},
				},
			})

			manager:Start()
			context.DriverSignal:Fire()

			expect(manager.CurrentPhase.Name).to.equal("Playing")
		end)

		it("should not transition when AllowedTransitions resolves to zero targets", function(context)
			local manager = RoundManager.new({
				Driver = context.DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = {
						Name = "Waiting",
						CanTransitionTo = function()
							return true
						end,
						AllowedTransitions = function()
							return {}
						end,
					},
					Playing = {
						Name = "Playing",
					},
				},
			})

			manager:Start()
			context.DriverSignal:Fire()

			expect(manager.CurrentPhase.Name).to.equal("Waiting")
		end)

		it("should call the function with the current context", function(context)
			local manager = RoundManager.new({
				Driver = context.DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = {
						Name = "Waiting",
						CanTransitionTo = function()
							return true
						end,
						AllowedTransitions = function(ctx)
							expect(ctx).to.be.ok()
							return { "Playing" }
						end,
					},
					Playing = {
						Name = "Playing",
					},
				},
			})

			manager:Start()
			context.DriverSignal:Fire()

			expect(manager.CurrentPhase.Name).to.equal("Playing")
		end)

		it("should fall back to an empty table when the function throws", function(context)
			local manager = RoundManager.new({
				Driver = context.DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = {
						Name = "Waiting",
						CanTransitionTo = function()
							return true
						end,
						AllowedTransitions = function()
							error("This is an error")
						end,
					},
					Playing = {
						Name = "Playing",
					},
				},
			})

			manager:Start()
			context.DriverSignal:Fire()

			expect(manager.CurrentPhase.Name).to.equal("Waiting")
		end)
	end)

	describe("Duration-based auto transition", function()
		it("should not transition before Duration has elapsed", function(context)
			local manager = RoundManager.new({
				Driver = DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = {
						Name = "Waiting",
						Duration = 5,
						CanTransitionTo = function()
							return true
						end,
						AllowedTransitions = { "Playing" },
					},
					Playing = {
						Name = "Playing",
					},
				},
			})

			manager:Start()
			context.DriverSignal:Fire(1)

			expect(manager.CurrentPhase.Name).to.equal("Waiting")
		end)

		it("should transition after Duration has elapsed", function(context)
			local manager = RoundManager.new({
				Driver = context.DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = {
						Name = "Waiting",
						Duration = 5,
						CanTransitionTo = function()
							return true
						end,
						AllowedTransitions = { "Playing" },
					},
					Playing = {
						Name = "Playing",
					},
				},
			})

			manager:Start()

			-- Simulate a second.
			context.DriverSignal:Fire(1)
			expect(manager.CurrentPhase.Name).to.equal("Waiting")

			-- Simulate 4 more seconds, duration should now be elapsed.
			context.DriverSignal:Fire(4)
			expect(manager.CurrentPhase.Name).to.equal("Playing")
		end)

		it("should error at Duration when AllowedTransitions has no CanTransitionTo and resolves to zero targets", function(context)
			local manager = RoundManager.new({
				Driver = context.DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = {
						Name = "Waiting",
						Duration = 5,
						AllowedTransitions = function() return {} end,
					},
					Playing = { Name = "Playing" },
				},
			})

			manager:Start()
			expect(function()
				manager:Update(5) -- Calling the driverSignal directly will not throw because it will be caught by the GoodSignal implementation.
			end).to.throw()
		end)
		
	end)

	describe("TransitionTo", function()
		it("should error when transitioning to an unregistered phase name", function(context)
			local manager = RoundManager.new({
				Driver = context.DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = { Name = "Waiting" },
				},
			})
			manager:Start()

			expect(function()
				manager:TransitionTo("NonExistentPhase")
			end).to.throw()
		end)
		it("should fire OnExit on the outgoing phase before OnEnter on the incoming phase", function(context)
			local callOrder = {}
			local manager
		
			manager = RoundManager.new({
				Driver = context.DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = {
						Name = "Waiting",
						AllowedTransitions = { "Playing" },
						OnExit = function()
							table.insert(callOrder, { hook = "OnExit", currentPhase = manager.CurrentPhase.Name })
						end,
					},
					Playing = {
						Name = "Playing",
						OnEnter = function()
							table.insert(callOrder, { hook = "OnEnter", currentPhase = manager.CurrentPhase.Name })
						end,
					},
				},
			})
		
			manager:Start()
			manager:TransitionTo("Playing")
		
			expect(#callOrder).to.equal(2)
			expect(callOrder[1].hook).to.equal("OnExit")
			expect(callOrder[1].currentPhase).to.equal("Waiting")
			expect(callOrder[2].hook).to.equal("OnEnter")
			expect(callOrder[2].currentPhase).to.equal("Playing")
		end)

		it("should pass the current context to OnExit and OnEnter", function(context)
			local manager = RoundManager.new({
				Driver = context.DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = {
						Name = "Waiting",
						AllowedTransitions = { "Playing" },
						OnExit = function(ctx)
							expect(ctx).to.be.ok()
							expect(ctx:GetCurrentPhase().Name).to.equal("Waiting")
						end,
					},
					Playing = {
						Name = "Playing",
						OnEnter = function(ctx)
							expect(ctx).to.be.ok()
							expect(ctx:GetCurrentPhase().Name).to.equal("Playing")
						end,
					},
				},
			})
		
			manager:Start()
			manager:TransitionTo("Playing")
		end)
	end)

	describe("Reentrant TransitionTo", function()
		it("should allow TransitionTo called synchronously from within OnEnter", function(context)
			local manager = RoundManager.new({
				Driver = context.DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = {
						Name = "Waiting",
						CanTransitionTo = function()
							return true
						end,
						AllowedTransitions = { "Playing" },
					},
					Playing = {
						Name = "Playing",
						CanTransitionTo = function()
							return true
						end,
						AllowedTransitions = { "Finished" },
						OnEnter = function(ctx)
							ctx:TransitionTo("Finished")
						end,
					},
					Finished = {
						Name = "Finished",
					},
				},
			})

			manager:Start()
			manager:TransitionTo("Playing")
			context.DriverSignal:Fire(1)
			
			expect(manager.CurrentPhase.Name).to.equal("Finished")
		end)

		it("should fire OnPhaseChanged events in chronological order across a reentrant chain", function(context)
			local manager = RoundManager.new({
				Driver = context.DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = {
						Name = "Waiting",
						CanTransitionTo = function()
								return true
						end,
						AllowedTransitions = { "Playing" },
					},
					Playing = {
						Name = "Playing",
						CanTransitionTo = function()
							return true
						end,
						AllowedTransitions = { "Finished" },
						OnEnter = function(ctx)
							ctx:TransitionTo("Finished")
						end,
					},
					Finished = {
						Name = "Finished",
					},
				},
		    })

			local phaseChanges = {}
			local ignoreFirstTransition = true
			manager.EventBus:Connect("OnPhaseChanged", function(oldPhase, nextPhase)
				if ignoreFirstTransition then
					ignoreFirstTransition = false
					return
				end

				table.insert(phaseChanges, { from = oldPhase.Name, to = nextPhase.Name })
			end)

			manager:Start()
			manager:TransitionTo("Playing")
			context.DriverSignal:Fire(1)

			expect(#phaseChanges).to.equal(2)
			expect(phaseChanges[1].from).to.equal("Waiting")
			expect(phaseChanges[1].to).to.equal("Playing")
			expect(phaseChanges[2].from).to.equal("Playing")
			expect(phaseChanges[2].to).to.equal("Finished")
		end)
	end)

	describe("Error containment", function()
		it("should not leave the manager stuck when a callback throws mid-transition", function(context)
			local manager = RoundManager.new({
				Driver = context.DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = {
						Name = "Waiting",
						CanTransitionTo = function()
							return true
						end,
						AllowedTransitions = { "Playing" },
					},
					Playing = {
						Name = "Playing",
						CanTransitionTo = function()
							return true
						end,
						AllowedTransitions = { "Finished" },
						OnEnter = function()
							error("This is an error")
						end,
					},
					Finished = {
						Name = "Finished",
					},
				},
			})

			manager:Start()
			expect(function()
				manager:TransitionTo("Playing")
				context.DriverSignal:Fire(1)

				expect(manager.CurrentPhase.Name).to.equal("Finished")
			end).to.never.throw()
		end)
	end)

	describe("EvaluateWinCondition", function()
		it("should not declare a win while the win condition returns nil", function(context)
			local winCondition = RoundKit.WinCondition.new('TestWinCondition', function()
				return nil
			end)

			local manager = RoundManager.new({
				Driver = context.DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = {
						Name = "Waiting",
						EvaluateWinCondition = true,
						EvaluateWinConditionInterval = 1,
						CanTransitionTo = function()
							return false
						end,
						AllowedTransitions = { "Playing" },
					},
					Playing = {
						Name = "Playing",
					},
				},
				WinCondition = winCondition,
			})

			manager:Start()
			context.DriverSignal:Fire(1)

			expect(manager:CheckWinCondition()).to.equal(nil)
			expect(manager.CurrentPhase.Name).to.equal("Waiting")
		end)

		it("should declare a win when the win condition returns a real outcome", function(context)
			local winCondition = RoundKit.WinCondition.new('TestWinCondition', function()
				return { Type = "Players", Winners = { "Player1" } }
			end)

			local manager = RoundManager.new({
				Driver = context.DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = {
						Name = "Waiting",
						EvaluateWinCondition = true,
						EvaluateWinConditionInterval = 1,
						CanTransitionTo = function()
							return false
						end,
						AllowedTransitions = { "Finished" },
					},
					Finished = {
						Name = "Finished",
					},
				},
				WinCondition = winCondition,
			})

			manager:Start()
			manager:BuildContext():Connect("OnWinConditionMet", function(outcome)
				expect(outcome).to.be.ok()
				expect(outcome.Type).to.equal("Players")
				expect(outcome.Winners[1]).to.equal("Player1")
			end)

			context.DriverSignal:Fire(1)

			expect(manager:CheckWinCondition()).to.be.ok()
		end)

		it("should fall back to nil and not declare a win when Evaluate throws", function(context)
			local winCondition = RoundKit.WinCondition.new('TestWinCondition', function()
				error("This is an error")
			end)

			local manager = RoundManager.new({
				Driver = context.DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = {
						Name = "Waiting",
						EvaluateWinCondition = true,
						EvaluateWinConditionInterval = 1,
						CanTransitionTo = function()
							return false
						end,
						AllowedTransitions = { "Playing" },
					},
					Playing = {
						Name = "Playing",
					},
				},
				WinCondition = winCondition,
			})

			manager:Start()
			manager:BuildContext():Connect("OnWinConditionMet", function(outcome)
				expect(outcome).to.never.be.ok()
			end)
			context.DriverSignal:Fire(1)

			expect(manager:CheckWinCondition()).to.equal(nil)
		end)
	end)

	describe("Destroy", function()
		it("should properly destroy the round manager and disconnect all connections", function(context)
			local manager = RoundManager.new({
				Driver = context.DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = {
						Name = "Waiting",
					},
				},
			})

			manager:Start()
			manager:Destroy()

			expect(manager._destroyed).to.equal(true)
			expect(manager._running).to.equal(false)
			expect(manager._driverConn).to.equal(nil)
			expect(manager._playerAddedConnection).to.equal(nil)
			expect(manager._playerRemovingConnection).to.equal(nil)
			expect(manager.CurrentPhase).to.equal(nil)

			expect(manager.PlayerStates).to.equal(nil)
			expect(manager.EventBus).to.equal(nil)
		end)
	end)

	describe("OnUpdate", function()
		it("should call OnUpdate on the current phase during a tick", function(context)
			local called = false
			local manager = RoundManager.new({
				Driver = context.DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = {
						Name = "Waiting",
						OnUpdate = function()
							called = true
						end,
					},
				},
			})
	
			manager:Start()
			context.DriverSignal:Fire(1)
	
			expect(called).to.equal(true)
		end)
	
		it("should pass the current context and dt to OnUpdate", function(context)
			local receivedCtx, receivedDt
			local manager = RoundManager.new({
				Driver = context.DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = {
						Name = "Waiting",
						OnUpdate = function(ctx, dt)
							receivedCtx, receivedDt = ctx, dt
						end,
					},
				},
			})
	
			manager:Start()
			context.DriverSignal:Fire(0.5)
	
			expect(receivedCtx).never.to.equal(nil)
			expect(receivedDt).to.equal(0.5)
		end)
	
		it("should not error when the current phase has no OnUpdate", function(context)
			local manager = RoundManager.new({
				Driver = context.DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = { Name = "Waiting" },
				},
			})
	
			manager:Start()
	
			expect(function()
				context.DriverSignal:Fire(1)
			end).to.never.throw()
		end)
	
		it("should not call OnUpdate while paused", function(context)
			local called = false
			local manager = RoundManager.new({
				Driver = context.DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = {
						Name = "Waiting",
						OnUpdate = function()
							called = true
						end,
					},
				},
			})
	
			manager:Start()
			manager:Pause()
			context.DriverSignal:Fire(1)
	
			expect(called).to.equal(false)
		end)
	
		it("should not call OnUpdate when there is no current phase", function()
			-- Update() is called directly here, before Start(), since Start()
			-- both connects the Driver and immediately transitions into
			-- InitialPhase - there's no way to reach "driver connected but no
			-- current phase" through the public Start()/Driver flow.
			local called = false
			local manager = RoundManager.new({
				Driver = { Connect = function() return { Disconnect = function() end } end },
				Phases = {
					Waiting = {
						Name = "Waiting",
						OnUpdate = function()
							called = true
						end,
					},
				},
			})
	
			manager:Update(1)
	
			expect(called).to.equal(false)
		end)
	
		it("should call OnUpdate once per driver tick", function(context)
			local callCount = 0
			local manager = RoundManager.new({
				Driver = context.DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = {
						Name = "Waiting",
						OnUpdate = function()
							callCount += 1
						end,
					},
				},
			})
	
			manager:Start()
			context.DriverSignal:Fire(1)
			context.DriverSignal:Fire(1)
			context.DriverSignal:Fire(1)
	
			expect(callCount).to.equal(3)
		end)
	
		it("should call the new phase's OnUpdate, not the old one's, after a transition", function(context)
			local waitingCalls, playingCalls = 0, 0
			local manager = RoundManager.new({
				Driver = context.DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = {
						Name = "Waiting",
						OnUpdate = function()
							waitingCalls += 1
						end,
						AllowedTransitions = { "Playing" },
					},
					Playing = {
						Name = "Playing",
						OnUpdate = function()
							playingCalls += 1
						end,
					},
				},
			})
	
			manager:Start()
			context.DriverSignal:Fire(1)
			manager:TransitionTo("Playing")
			context.DriverSignal:Fire(1)
	
			expect(waitingCalls).to.equal(1)
			expect(playingCalls).to.equal(1)
		end)
	
		it("should not leave the manager stuck when OnUpdate throws", function(context)
			local manager = RoundManager.new({
				Driver = context.DriverSignal,
				InitialPhase = "Waiting",
				Phases = {
					Waiting = {
						Name = "Waiting",
						OnUpdate = function()
							error("This is an error")
						end,
					},
				},
			})
	
			manager:Start()
	
			expect(function()
				context.DriverSignal:Fire(1)
				context.DriverSignal:Fire(1)
			end).to.never.throw()
		end)
	end)
end
