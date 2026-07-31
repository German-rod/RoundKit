return function()
    local AllOf = require(script.Parent.AllOf)

    local function condition(outcome)
        return {
            Name = "Fake",
            Evaluate = function()
                return outcome
            end,
        }
    end

    describe("AllOf combinator", function()
        it("should return nil when any child returns nil", function()
            local combined = AllOf({ condition("WinnerA"), condition(nil) })
            expect(combined.Evaluate({})).to.equal(nil)
        end)

        it("should return the first outcome when every child agrees", function()
            local combined = AllOf({ condition("WinnerA"), condition("WinnerA") })
            expect(combined.Evaluate({})).to.equal("WinnerA")
        end)

        it("should not evaluate remaining children once one returns nil", function()
            local calledThird = false
            local combined = AllOf({
                condition(nil),
                {
                    Name = "Fake",
                    Evaluate = function()
                        calledThird = true
                        return "WinnerA"
                    end,
                },
            })

            combined.Evaluate({})

            expect(calledThird).to.equal(false)
        end)
    end)
end