return function()
    local PlayerRoundState = require(script.Parent.PlayerRoundState)

    local function fakePlayer(userId)
        return { UserId = userId }
    end

    describe("new", function()
        it("should initialize with the correct defaults", function()
            local player = fakePlayer(1)
            local state = PlayerRoundState.new(player)

            expect(state.Player).to.equal(player)
            expect(state.UserId).to.equal(1)
            expect(state.Connected).to.equal(true)
            expect(state.Ready).to.equal(false)
        end)
    end)

    describe("SetConnected", function()
        it("should reset Ready and stamp DisconnectedTime when disconnecting", function()
            local state = PlayerRoundState.new(fakePlayer(1))
            state:SetReady(true)

            state:SetConnected(false)

            expect(state.Connected).to.equal(false)
            expect(state.Ready).to.equal(false)
            expect(state.DisconnectedTime).to.be.a("number")
        end)

        it("should not reset Ready when reconnecting", function()
            local state = PlayerRoundState.new(fakePlayer(1))
            state:SetConnected(false)
            state:SetReady(true)

            state:SetConnected(true)

            expect(state.Connected).to.equal(true)
            expect(state.Ready).to.equal(true)
        end)
    end)

    describe("Rebind", function()
        it("should update Player and set Connected to true", function()
            local state = PlayerRoundState.new(fakePlayer(1))
            state:SetConnected(false)
            local newPlayer = fakePlayer(1)

            state:Rebind(newPlayer)

            expect(state.Player).to.equal(newPlayer)
            expect(state.Connected).to.equal(true)
        end)

        it("should not reset Ready", function()
            local state = PlayerRoundState.new(fakePlayer(1))
            state:SetReady(true)

            state:Rebind(fakePlayer(1))

            expect(state.Ready).to.equal(true)
        end)
    end)

    describe("Metrics", function()
        it("should round-trip a value through SetMetric/GetMetric", function()
            local state = PlayerRoundState.new(fakePlayer(1))
            state:SetMetric("Kills", 5)
            expect(state:GetMetric("Kills")).to.equal(5)
        end)

        it("should return nil for a metric that was never set", function()
            local state = PlayerRoundState.new(fakePlayer(1))
            expect(state:GetMetric("Kills")).to.equal(nil)
        end)
    end)

    describe("Destroy", function()
        it("should mark the state as destroyed", function()
            local state = PlayerRoundState.new(fakePlayer(1))
            state:Destroy()
            expect(state._destroyed).to.equal(true)
        end)

        it("should be safe to call twice", function()
            local state = PlayerRoundState.new(fakePlayer(1))
            state:Destroy()
            expect(function()
                state:Destroy()
            end).never.to.throw()
        end)
    end)
end