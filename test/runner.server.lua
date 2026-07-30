local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestService = game:GetService("TestService")

local TestEZ = require(TestService:WaitForChild("TestEZ"))

local results = TestEZ.TestBootstrap:run({ ReplicatedStorage.RoundKit })

if results.failureCount > 0 then
	error("Tests failed! Total failures: " .. results.failureCount)
else
	print("All tests passed successfully!")
end
