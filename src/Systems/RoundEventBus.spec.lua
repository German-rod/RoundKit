return function()
    local RoundEventBus = require(script.Parent.RoundEventBus)

    describe("Get", function()
        it("should return the same signal on repeated calls for the same event", function()
            local bus = RoundEventBus.new()
            expect(bus:Get("Foo")).to.equal(bus:Get("Foo"))
        end)
    end)

    describe("Connect and Fire", function()
        it("should invoke a connected callback with the fired arguments", function()
            local bus = RoundEventBus.new()
            local received
            bus:Connect("Foo", function(a, b)
                received = { a, b }
            end)

            bus:Fire("Foo", 1, 2)

            expect(received[1]).to.equal(1)
            expect(received[2]).to.equal(2)
        end)

        it("should not error when firing an event with no listeners", function()
            local bus = RoundEventBus.new()
            expect(function()
                bus:Fire("NoListeners")
            end).never.to.throw()
        end)

        it("should not let an error in one listener stop other listeners from running", function()
            local bus = RoundEventBus.new()
            local secondRan = false

            bus:Connect("Foo", function()
                error("boom")
            end)
            bus:Connect("Foo", function()
                secondRan = true
            end)

            bus:Fire("Foo")

            expect(secondRan).to.equal(true)
        end)
    end)

    describe("Destroy", function()
        it("should stop previously connected callbacks from firing", function()
            local bus = RoundEventBus.new()
            local callCount = 0
            bus:Connect("Foo", function()
                callCount += 1
            end)

            bus:Destroy()
            bus:Fire("Foo")

            expect(callCount).to.equal(0)
        end)
    end)
end