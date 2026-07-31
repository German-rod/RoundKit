return function()
    local PlayerStateRegistry = require(script.Parent.PlayerStateRegistry)

    local function fakePlayer(userId)
        return { UserId = userId }
    end

    describe("AddPlayerState", function()
        it("should create and store a state for the given player", function()
            local registry = PlayerStateRegistry.new()
            local state = registry:AddPlayerState(fakePlayer(1))

            expect(state.UserId).to.equal(1)
            expect(registry:GetPlayerState(1)).to.equal(state)
        end)
    end)

    describe("GetPlayerState", function()
        it("should return nil for a userId that was never added", function()
            local registry = PlayerStateRegistry.new()
            expect(registry:GetPlayerState(999)).to.equal(nil)
        end)
    end)

    describe("RemovePlayerState", function()
        it("should remove the state and mark it destroyed", function()
            local registry = PlayerStateRegistry.new()
            local state = registry:AddPlayerState(fakePlayer(2))

            registry:RemovePlayerState(2)

            expect(registry:GetPlayerState(2)).to.equal(nil)
            expect(state._destroyed).to.equal(true)
        end)

        it("should not error when removing a userId that was never added", function()
            local registry = PlayerStateRegistry.new()
            expect(function()
                registry:RemovePlayerState(999)
            end).never.to.throw()
        end)
    end)

    describe("GetAllPlayerStates", function()
        it("should return every added state keyed by userId", function()
            local registry = PlayerStateRegistry.new()
            local stateA = registry:AddPlayerState(fakePlayer(1))
            local stateB = registry:AddPlayerState(fakePlayer(2))

            local all = registry:GetAllPlayerStates()

            expect(all[1]).to.equal(stateA)
            expect(all[2]).to.equal(stateB)
        end)
    end)

    describe("Clear", function()
        it("should remove and destroy every state", function()
            local registry = PlayerStateRegistry.new()
            local state = registry:AddPlayerState(fakePlayer(1))

            registry:Clear()

            expect(registry:GetPlayerState(1)).to.equal(nil)
            expect(state._destroyed).to.equal(true)
        end)
    end)
end