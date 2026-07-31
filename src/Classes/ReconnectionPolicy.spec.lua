return function()
    local ReconnectionPolicy = require(script.Parent.ReconnectionPolicy)

    describe("new", function()
        it("should create a policy with the given name", function()
            local policy = ReconnectionPolicy.new("TestPolicy_New", function() end)
            expect(policy.Name).to.equal("TestPolicy_New")
        end)

        it("should error when the name is already registered", function()
            ReconnectionPolicy.new("TestPolicy_Dupe", function() end)
            expect(function()
                ReconnectionPolicy.new("TestPolicy_Dupe", function() end)
            end).to.throw()
        end)
    end)

    describe("Resolve", function()
        it("should return the registered instance for a known name", function()
            local policy = ReconnectionPolicy.new("TestPolicy_Resolve", function() end)
            expect(ReconnectionPolicy.Resolve("TestPolicy_Resolve")).to.equal(policy)
        end)

        it("should error for an unregistered name", function()
            expect(function()
                ReconnectionPolicy.Resolve("TestPolicy_DoesNotExist")
            end).to.throw()
        end)

        it("should return the instance unchanged when passed one directly", function()
            local policy = ReconnectionPolicy.new("TestPolicy_PassThrough", function() end)
            expect(ReconnectionPolicy.Resolve(policy)).to.equal(policy)
        end)
    end)

    describe("Handle", function()
        it("should invoke the handler with the given arguments", function()
            local receivedCtx, receivedPlayer, receivedState
            local policy = ReconnectionPolicy.new("TestPolicy_Handle", function(ctx, player, previousState)
                receivedCtx, receivedPlayer, receivedState = ctx, player, previousState
            end)

            local ctx, player, previousState = {}, {}, {}
            policy:Handle(ctx, player, previousState)

            expect(receivedCtx).to.equal(ctx)
            expect(receivedPlayer).to.equal(player)
            expect(receivedState).to.equal(previousState)
        end)
    end)
end