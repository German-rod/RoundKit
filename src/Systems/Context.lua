local Core = require(script.Parent.Parent.Types.Core)
export type Context = Core.Context

--- @class Context
--- Provides a context for the round manager, allowing access to player states, global metrics, and event bus.
local Context = {} :: Context
Context.__index = Context

--- @param roundManager RoundManager
--- @return Context
--- Constructor method for a new context
function Context.new(roundManager)
	return setmetatable({
		RoundManager = roundManager,
		EventBus = roundManager.EventBus,
		Config = roundManager.Config,
	}, Context)
end

--- @return table
--- Returns all entities that have a player state in the round
function Context:GetEntities()
	local entities = {}
	for _, state in pairs(self.RoundManager.PlayerStates:GetAllPlayerStates()) do
		table.insert(entities, state.Player)
	end
	return entities
end

--- @param entity Player
--- @param key string
--- @return any
--- Returns the requested metric for the given entity
function Context:GetMetric(entity, key)
	local state = self.RoundManager.PlayerStates:GetPlayerState(entity.UserId)
	return state and state:GetMetric(key) or 0
end

--- @return number
--- Returns the total number of players ready in the round
function Context:GetReadyPlayerCount()
	local count = 0
	for _, state in pairs(self.RoundManager.PlayerStates:GetAllPlayerStates()) do
		if state.Ready then
			count += 1
		end
	end
	return count
end

--- @return number
--- Returns the round phase elapsed time
function Context:GetElapsedTime()
	return self.RoundManager._phaseElapsed or 0
end

--// Delegated from PlayerStateRegistry

--- @param player Player
--- @return PlayerRoundState
--- Adds a player state to the registry
function Context:AddPlayerState(player)
	return self.RoundManager.PlayerStates:AddPlayerState(player)
end

--- @param userId number
--- Removes a player state from the registry
function Context:RemovePlayerState(userId)
	return self.RoundManager.PlayerStates:RemovePlayerState(userId)
end

--- @param userId number
--- @return PlayerRoundState?
--- Gets a player state from the registry
function Context:GetPlayerState(userId)
	return self.RoundManager.PlayerStates:GetPlayerState(userId)
end

--// Delegated from GlobalMetricsRegistry

--- @param key string
--- @return any
--- Gets a value from the registry
function Context:GetGlobalMetric(key)
	return self.RoundManager.GlobalMetrics:Get(key)
end

--- @param key string
--- @param value any
--- @return ()
--- Sets a value in the registry
function Context:SetGlobalMetric(key, value)
	self.RoundManager.GlobalMetrics:Set(key, value)
end

--- @param key string
--- @param delta number
--- @return ()
--- Applies a delta to a value in the registry
function Context:ApplyGlobalMetric(key, delta)
	self.RoundManager.GlobalMetrics:Apply(key, delta)
end

--// Delegated from RoundsManager

--- Evaluates whetever the current phase can transition to the given phase
--- Fires 'OnPhaseChanged' if the transition is successful.
--- @param phaseName string
--- @return boolean
function Context:TransitionTo(phaseName)
	return self.RoundManager:TransitionTo(phaseName)
end

--- Checks the win condition and fires the OnWinConditionMet event if it is met.
--- Fires 'OnWinConditionMet' if the win condition is met.
--- @return WinOutcome?
function Context:CheckWinCondition()
	return self.RoundManager:CheckWinCondition()
end

--- Returns the current phase from the round manager
--- @return Phase
function Context:GetCurrentPhase()
	return self.RoundManager.CurrentPhase
end

--// Delegated from EventBus

--- Connects to an event on the event bus, if it does not exist it will be created.
--- @param eventName string
--- @param callback any
--- @return RBXScriptConnection
function Context:Connect(eventName, callback)
	local connection = self.EventBus:Connect(eventName, callback)
	table.insert(self.RoundManager._phaseConnections, connection)
	return connection
end

--- Fires an event on the event bus.
--- @param eventName string
--- @param ... any
function Context:Fire(eventName, ...)
	self.EventBus:Fire(eventName, ...)
end

return Context
