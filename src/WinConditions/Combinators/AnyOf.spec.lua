return function()
    local AnyOf = require(script.Parent.AnyOf)

    local function condition(outcome)
        return {
            Name = "Fake",
            Evaluate = function()
                return outcome
            end,
        }
    end

    describe("AnyOf combinator", function()
        it("should return nil when no child has an outcome", function()
            local combined = AnyOf({ condition(nil), condition(nil) })
            expect(combined.Evaluate({})).to.equal(nil)
        end)

        it("should return the first non-nil child outcome", function()
            local combined = AnyOf({ condition(nil), condition("WinnerB") })
            expect(combined.Evaluate({})).to.equal("WinnerB")
        end)

        it("should not evaluate children after the first match", function()
            local calledSecond = false
            local combined = AnyOf({
                condition("WinnerA"),
                {
                    Name = "Fake",
                    Evaluate = function()
                        calledSecond = true
                        return "WinnerB"
                    end,
                },
            })

            combined.Evaluate({})

            expect(calledSecond).to.equal(false)
        end)
    end)
end