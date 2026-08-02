return function()
    local Context = require(script.Parent.Context)
    local PlayerRoundState = require(script.Parent.Parent.Classes.PlayerRoundState)

    local function fakePlayer(userId)
        return { UserId = userId }
    end

    local function makeFakeRoundManager()
        local playerStates = {}
        local connectCalls = {}
        local fireCalls = {}
        local transitionCalls = {}
        local checkWinConditionCalls = 0

        local fake = {
            Config = { Example = true },
            _phaseElapsed = 42,
            _phaseConnections = {},
            CurrentPhase = { Name = "Waiting" },

            EventBus = {
                Connect = function(_, eventName, callback)
                    table.insert(connectCalls, { eventName = eventName, callback = callback })
                    return { Disconnect = function() end }
                end,
                Fire = function(_, eventName, ...)
                    table.insert(fireCalls, { eventName = eventName, ... })
                end,
            },

            PlayerStates = {
                AddPlayerState = function(_, player)
                    local state = PlayerRoundState.new(player)
                    playerStates[player.UserId] = state
                    return state
                end,
                RemovePlayerState = function(_, userId)
                    playerStates[userId] = nil
                end,
                GetPlayerState = function(_, userId)
                    return playerStates[userId]
                end,
                GetAllPlayerStates = function(_)
                    return playerStates
                end,
            },

            GlobalMetrics = {
                _data = {},
                Get = function(self, key)
                    return self._data[key]
                end,
                Set = function(self, key, value)
                    self._data[key] = value
                end,
            },

            TransitionTo = function(_, phaseName)
                table.insert(transitionCalls, phaseName)
                return true
            end,

            CheckWinCondition = function(_)
                checkWinConditionCalls += 1
                return "FakeOutcome"
            end,
        }

        return fake, {
            connectCalls = connectCalls,
            fireCalls = fireCalls,
            transitionCalls = transitionCalls,
            getCheckWinConditionCalls = function()
                return checkWinConditionCalls
            end,
        }
    end

    describe("GetPlayers", function()
        it("should return the Player of every stored state", function()
            local roundManager = makeFakeRoundManager()
            local ctx = Context.new(roundManager)
            local playerA, playerB = fakePlayer(1), fakePlayer(2)
            ctx:AddPlayerState(playerA)
            ctx:AddPlayerState(playerB)

            local players = ctx:GetPlayers()

            expect(#players).to.equal(2)
        end)
    end)

    describe("GetMetric", function()
        it("should return the player's metric value", function()
            local roundManager = makeFakeRoundManager()
            local ctx = Context.new(roundManager)
            local player = fakePlayer(1)
            local state = ctx:AddPlayerState(player)
            state:SetMetric("Kills", 3)

            expect(ctx:GetMetric(player, "Kills")).to.equal(3)
        end)

        it("should return 0 when the player has no state", function()
            local roundManager = makeFakeRoundManager()
            local ctx = Context.new(roundManager)
            expect(ctx:GetMetric(fakePlayer(999), "Kills")).to.equal(0)
        end)

        it("should return 0 when the player has state but no such metric", function()
            local roundManager = makeFakeRoundManager()
            local ctx = Context.new(roundManager)
            local player = fakePlayer(1)
            ctx:AddPlayerState(player)

            expect(ctx:GetMetric(player, "Kills")).to.equal(0)
        end)
    end)

    describe("SetMetric", function()
        it("should set the metric on the player's state", function()
            local roundManager = makeFakeRoundManager()
            local ctx = Context.new(roundManager)
            local player = fakePlayer(1)
            ctx:AddPlayerState(player)

            ctx:SetMetric(player, "Eliminated", true)

            expect(ctx:GetMetric(player, "Eliminated")).to.equal(true)
        end)

        it("should overwrite an existing metric value", function()
            local roundManager = makeFakeRoundManager()
            local ctx = Context.new(roundManager)
            local player = fakePlayer(1)
            ctx:AddPlayerState(player)
            ctx:SetMetric(player, "Kills", 1)

            ctx:SetMetric(player, "Kills", 2)

            expect(ctx:GetMetric(player, "Kills")).to.equal(2)
        end)

        it("should not error when the player has no state", function()
            local roundManager = makeFakeRoundManager()
            local ctx = Context.new(roundManager)

            expect(function()
                ctx:SetMetric(fakePlayer(999), "Eliminated", true)
            end).never.to.throw()
        end)

        it("should not affect a different player's metric", function()
            local roundManager = makeFakeRoundManager()
            local ctx = Context.new(roundManager)
            local playerA, playerB = fakePlayer(1), fakePlayer(2)
            ctx:AddPlayerState(playerA)
            ctx:AddPlayerState(playerB)

            ctx:SetMetric(playerA, "Eliminated", true)

            expect(ctx:GetMetric(playerB, "Eliminated")).to.equal(0)
        end)
    end)

    describe("GetReadyPlayerCount", function()
        it("should count only players marked Ready", function()
            local roundManager = makeFakeRoundManager()
            local ctx = Context.new(roundManager)
            local stateA = ctx:AddPlayerState(fakePlayer(1))
            ctx:AddPlayerState(fakePlayer(2))
            stateA:SetReady(true)

            expect(ctx:GetReadyPlayerCount()).to.equal(1)
        end)
    end)

    describe("GetElapsedTime", function()
        it("should return the round manager's phase elapsed time", function()
            local roundManager = makeFakeRoundManager()
            local ctx = Context.new(roundManager)
            expect(ctx:GetElapsedTime()).to.equal(42)
        end)
    end)

    describe("Player state delegation", function()
        it("should add, get, and remove player state via the round manager", function()
            local roundManager = makeFakeRoundManager()
            local ctx = Context.new(roundManager)
            local player = fakePlayer(1)

            ctx:AddPlayerState(player)
            expect(ctx:GetPlayerState(1)).never.to.equal(nil)

            ctx:RemovePlayerState(1)
            expect(ctx:GetPlayerState(1)).to.equal(nil)
        end)
    end)

    describe("Global metric delegation", function()
        it("should set and get via the round manager's GlobalMetrics", function()
            local roundManager = makeFakeRoundManager()
            local ctx = Context.new(roundManager)

            ctx:SetGlobalMetric("ContextSpecKey", "Value")

            expect(ctx:GetGlobalMetric("ContextSpecKey")).to.equal("Value")
        end)
    end)

    describe("TransitionTo", function()
        it("should delegate to the round manager and return its result", function()
            local roundManager, spies = makeFakeRoundManager()
            local ctx = Context.new(roundManager)

            local result = ctx:TransitionTo("Playing")

            expect(result).to.equal(true)
            expect(spies.transitionCalls[1]).to.equal("Playing")
        end)
    end)

    describe("CheckWinCondition", function()
        it("should delegate to the round manager and return its result", function()
            local roundManager, spies = makeFakeRoundManager()
            local ctx = Context.new(roundManager)

            local result = ctx:CheckWinCondition()

            expect(result).to.equal("FakeOutcome")
            expect(spies.getCheckWinConditionCalls()).to.equal(1)
        end)
    end)

    describe("GetCurrentPhase", function()
        it("should return the round manager's current phase", function()
            local roundManager = makeFakeRoundManager()
            local ctx = Context.new(roundManager)
            expect(ctx:GetCurrentPhase().Name).to.equal("Waiting")
        end)
    end)

    describe("Connect", function()
        it("should connect via the event bus and register the connection for phase cleanup", function()
            local roundManager, spies = makeFakeRoundManager()
            local ctx = Context.new(roundManager)

            ctx:Connect("Foo", function() end)

            expect(spies.connectCalls[1].eventName).to.equal("Foo")
            expect(#roundManager._phaseConnections).to.equal(1)
        end)
    end)

    describe("Fire", function()
        it("should fire via the event bus with the given arguments", function()
            local roundManager, spies = makeFakeRoundManager()
            local ctx = Context.new(roundManager)

            ctx:Fire("Foo", 1, 2)

            expect(spies.fireCalls[1].eventName).to.equal("Foo")
            expect(spies.fireCalls[1][1]).to.equal(1)
            expect(spies.fireCalls[1][2]).to.equal(2)
        end)
    end)
end