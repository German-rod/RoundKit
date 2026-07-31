return function()
    local WinCondition = require(script.Parent.WinCondition)

    describe("new", function()
        it("should create a condition with the given name", function()
            local condition = WinCondition.new("TestCondition_New", function() end)
            expect(condition.Name).to.equal("TestCondition_New")
        end)

        it("should error when the name is already registered", function()
            WinCondition.new("TestCondition_Dupe", function() end)
            expect(function()
                WinCondition.new("TestCondition_Dupe", function() end)
            end).to.throw()
        end)
    end)

    describe("Evaluate", function()
        it("should call the evaluator with the given context and return its result", function()
            local receivedCtx
            local condition = WinCondition.new("TestCondition_Evaluate", function(ctx)
                receivedCtx = ctx
                return "Winner"
            end)

            local ctx = {}
            local result = condition:Evaluate(ctx)

            expect(receivedCtx).to.equal(ctx)
            expect(result).to.equal("Winner")
        end)
    end)

    describe("Resolve", function()
        it("should return the registered instance for a known name", function()
            local condition = WinCondition.new("TestCondition_Resolve", function() end)
            expect(WinCondition.Resolve("TestCondition_Resolve")).to.equal(condition)
        end)

        it("should error for an unregistered name", function()
            expect(function()
                WinCondition.Resolve("TestCondition_DoesNotExist")
            end).to.throw()
        end)

        it("should return a raw table instance unchanged", function()
            local raw = { Name = "Raw", Evaluate = function() end }
            expect(WinCondition.Resolve(raw)).to.equal(raw)
        end)
    end)
end