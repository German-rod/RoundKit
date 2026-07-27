
local RoundManager = require(script.Classes.RoundManager)
local WinCondition = require(script.Classes.WinCondition)
local ReconnectionPolicy = require(script.Classes.ReconnectionPolicy)
local AnyOf = require(script.WinConditions.Combinators.AnyOf)
local AllOf = require(script.WinConditions.Combinators.AllOf)

WinCondition.AnyOf = AnyOf
WinCondition.AllOf = AllOf

local Core = require(script.Types.Core)
export type RoundKit = Core.RoundKit

local RoundKit = {} :: RoundKit
RoundKit.WinCondition = WinCondition
RoundKit.ReconnectionPolicy = ReconnectionPolicy

function RoundKit.new(config)
	assert(type(config) == "table")
	assert(type(config.Phases) == "table")
	assert(type(config.InitialPhase) == "string")
	assert(config.WinCondition ~= nil)

	return RoundManager.new(config)
end

return RoundKit