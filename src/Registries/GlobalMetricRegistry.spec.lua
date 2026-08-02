return function()
    local GlobalMetricRegistry = require(script.Parent.GlobalMetricRegistry)

    describe("Get and Set", function()
        it("should round-trip a value through Set/Get", function()
            local registry = GlobalMetricRegistry.new()
            registry:Set("Score", 100)
            expect(registry:Get("Score")).to.equal(100)
        end)

        it("should return nil for a key that was never set", function()
            local registry = GlobalMetricRegistry.new()
            expect(registry:Get("DoesNotExist")).to.equal(nil)
        end)

        it("should overwrite an existing value on a second Set", function()
            local registry = GlobalMetricRegistry.new()
            registry:Set("Score", 100)
            registry:Set("Score", 200)
            expect(registry:Get("Score")).to.equal(200)
        end)
    end)

    describe("new", function()
        it("should give each instance its own independent data", function()
            local registryA = GlobalMetricRegistry.new()
            local registryB = GlobalMetricRegistry.new()

            registryA:Set("Score", 100)

            expect(registryB:Get("Score")).to.equal(nil)
        end)
    end)

    describe("Clear", function()
        it("should remove a string-keyed value", function()
            local registry = GlobalMetricRegistry.new()
            registry:Set("Score", 100)

            registry:Clear()

            expect(registry:Get("Score")).to.equal(nil)
        end)

        it("should remove a non-string-keyed value", function()
            local registry = GlobalMetricRegistry.new()
            registry:Set(1, "IndexedValue")

            registry:Clear()

            expect(registry:Get(1)).to.equal(nil)
        end)

        it("should be safe to call on an already-empty registry", function()
            local registry = GlobalMetricRegistry.new()
            expect(function()
                registry:Clear()
            end).never.to.throw()
        end)

        it("should not affect a different instance's data", function()
            local registryA = GlobalMetricRegistry.new()
            local registryB = GlobalMetricRegistry.new()
            registryA:Set("Score", 100)
            registryB:Set("Score", 200)

            registryA:Clear()

            expect(registryB:Get("Score")).to.equal(200)
        end)
    end)

    describe("Destroy", function()
        it("should clear all data", function()
            local registry = GlobalMetricRegistry.new()
            registry:Set("Score", 100)

            registry:Destroy()

            -- Get can't be called through : after Destroy (see test below),
            -- so this reaches into _data directly to confirm it was cleared.
            expect(rawget(registry, "_data")["Score"]).to.equal(nil)
        end)

        it("should strip the metatable so methods can no longer be called", function()
            local registry = GlobalMetricRegistry.new()

            registry:Destroy()

            expect(function()
                registry:Get("Score")
            end).to.throw()
        end)

        it("should error if called a second time", function()
            local registry = GlobalMetricRegistry.new()
            registry:Destroy()

            expect(function()
                registry:Destroy()
            end).to.throw()
        end)

        it("should not affect a different instance's data", function()
            local registryA = GlobalMetricRegistry.new()
            local registryB = GlobalMetricRegistry.new()
            registryB:Set("Score", 200)

            registryA:Destroy()

            expect(registryB:Get("Score")).to.equal(200)
        end)
    end)
end