--[[
	RoundManager Class
	Orchestrates round lifecycles, phase transitions, and state management.

	Public Event Bus Signals (manager.EventBus)
	* "OnPhaseChanged"  (oldPhase: Phase, newPhase: Phase)
		Fired when the round phase changes
	* "OnPlayerAdded"  (player: Player)
		Fired when a player is added to the round
	* "OnPlayerRemoving"  (player: Player)
		Fired when a player is removed from the round
	* "OnWinConditionMet"  (outcome: WinOutcome)
	 	Fired when a win condition is met
	* "OnRoundReset"
		Fired when the round is reset
]]

local Core = require(script.Parent.Parent.Types.Core)
export type RoundManager = Core.RoundManager

local GlobalMetricRegistry = require(script.Parent.Parent.Registries.GlobalMetricRegistry)
local PlayerStateRegistry = require(script.Parent.Parent.Registries.PlayerStateRegistry)
local PlayerRoundState = require(script.Parent.PlayerRoundState)
local RoundEventBus = require(script.Parent.Parent.Systems.RoundEventBus)
local Context = require(script.Parent.Parent.Systems.Context)
local WinCondition = require(script.Parent.WinCondition)
local ReconnectionPolicy = require(script.Parent.ReconnectionPolicy)

local RunService = game:GetService("RunService")

--- @class RoundManager
--- Orchestrates round lifecycles, phase transitions, and state management.
local RoundManager = {} :: RoundManager
RoundManager.__index = RoundManager

--- @within RoundManager
--- @param config RoundConfig
--- @return RoundManager
--- Constructs a new RoundManager.
function RoundManager.new(config): RoundManager
	local self = setmetatable({
		Config = config,
		Phases = config.Phases,
		CurrentPhase = nil,
		PlayerStates = PlayerStateRegistry.new(),
		GlobalMetrics = setmetatable({}, GlobalMetricRegistry),
		WinCondition = WinCondition.Resolve(config.WinCondition),
		ReconnectionPolicy = config.ReconnectionPolicy and ReconnectionPolicy.Resolve(config.ReconnectionPolicy) or nil,
		EventBus = RoundEventBus.new(),
		_phaseElapsed = 0,
		_winCheckElapsed = 0,
		_canTransitionElapsed = 0,
		_phaseConnections = {},
		_paused = true,
		_started = false,
		_destroyed = false,
	}, RoundManager)

	return self
end

--- Starts the manager loop and initializes the first phase
function RoundManager:Start()
	if self._started then
		warn("RoundKit Start() called but the round manager is already started")
		return
	end
	self._started = true
	self._paused = false

	local lastTime = os.clock()
	local function tick()
		local now = os.clock()
		local dt = now - lastTime
		lastTime = now
		self:Update(dt)
	end

	if self.Config.Driver then
		self._driverConn = self.Config.Driver:Connect(tick)
	else
		local interval = self.Config.UpdateInterval or 1
		self._running = true

		task.spawn(function()
			while self._running do
				task.wait(interval)
				if not self._running then
					break
				end
				tick()
			end
		end)
	end

	self:TransitionTo(self.Config.InitialPhase)
end

--- Stops the manager from updating.
function RoundManager:Pause()
	self._paused = true
end

--- Resumes the manager loop.
function RoundManager:Resume()
	if not self._started then
		warn("RoundKit Resume() called before Start()")
		return
	end
	self._paused = false
end

--- Evaluates whetever the current phase can transition to the given phase
--- Fires 'OnPhaseChanged' if the transition is successful.
--- @param phaseName string
--- @return boolean
function RoundManager:TransitionTo(phaseName)
	if self._transitioning then
		warn("RoundKit TransitionTo('" .. phaseName .. "') called while already transitioning")
		return false
	end
	self._transitioning = true

	local nextPhase = self.Phases[phaseName]
	assert(nextPhase, "RoundKit no phase registered under name '" .. phaseName .. "'")

	if self.CurrentPhase then
		local ctx = self:BuildContext()
		local allowed = self:ResolveAllowedTransitions(self.CurrentPhase, ctx)
		if not table.find(allowed, phaseName) then
			self._transitioning = false
			return false
		end
		if self.CurrentPhase.OnExit then
			self.CurrentPhase.OnExit(ctx)
		end
	end

	for _, connection in ipairs(self._phaseConnections) do
		connection:Disconnect()
	end
	self._phaseConnections = {}

	local oldPhase = self.CurrentPhase
	self.CurrentPhase = nextPhase
	self._phaseElapsed = 0
	self._winCheckElapsed = 0
	self._canTransitionElapsed = 0

	if nextPhase.OnEnter then
		nextPhase.OnEnter(self:BuildContext())
	end

	self.EventBus:Fire("OnPhaseChanged", oldPhase, nextPhase)
	self._transitioning = false
	return true
end

--- Updates the round manager state, evaluates the current phase state, if it should transition and the win condition.
--- @param dt number
function RoundManager:Update(dt)
	if self._paused then
		return
	end

	local phase = self.CurrentPhase
	if not phase then
		return
	end

	self._phaseElapsed += dt

	if phase.Duration and self._phaseElapsed >= phase.Duration then
		local ctx = self:BuildContext()
		local allowed = self:ResolveAllowedTransitions(phase, ctx)
		assert(
			#allowed == 1,
			"RoundKit phase '"
				.. phase.Name
				.. "' has a Duration but its resolved AllowedTransitions has more than one entry"
		)
		self:TransitionTo(allowed[1])
		return
	end

	if phase.CanTransitionTo then
		self._canTransitionElapsed += dt
		local interval = phase.CanTransitionInterval or 1
		if self._canTransitionElapsed >= interval then
			self._canTransitionElapsed = 0
			local ctx = self:BuildContext()
			local allowed = self:ResolveAllowedTransitions(phase, ctx)
			for _, targetName in ipairs(allowed) do
				if phase.CanTransitionTo(ctx, targetName) then
					self:TransitionTo(targetName)
					return
				end
			end
		end
	end

	if phase.EvaluateWinCondition and phase.EvaluateWinConditionInterval then
		self._winCheckElapsed += dt
		if self._winCheckElapsed >= phase.EvaluateWinConditionInterval then
			self._winCheckElapsed = 0
			self:CheckWinCondition()
		end
	end
end

--- Checks the win condition and fires the OnWinConditionMet event if it is met.
--- Fires 'OnWinConditionMet' if the win condition is met.
--- @return WinConditionOutcome?
function RoundManager:CheckWinCondition()
	local phase = self.CurrentPhase
	if not phase or not phase.EvaluateWinCondition then
		return nil
	end

	local outcome = self:EvaluateWinCondition()
	if outcome then
		self.EventBus:Fire("OnWinConditionMet", outcome)
	end
	return outcome
end

--- Builds a new context for the current state of the round manager.
--- @return Context
function RoundManager:BuildContext()
	return Context.new(self)
end

--- Evaluates the win condition and returns the outcome.
--- @return WinConditionOutcome?
function RoundManager:EvaluateWinCondition()
	if not self.WinCondition then
		return nil
	end

	return self.WinCondition:Evaluate(self:BuildContext())
end

--- Resolves the allowed transitions for the given phase.
--- @param phase Phase
--- @param ctx Context
--- @return {string}
function RoundManager:ResolveAllowedTransitions(phase, ctx)
	local allowed = phase.AllowedTransitions
	if type(allowed) == "function" then
		local resolved = allowed(ctx)
		assert(
			type(resolved) == "table",
			"RoundKit phase '" .. phase.Name .. "'s AllowedTransitions function must return a table"
		)
		return resolved
	end
	return allowed
end

--- Handles the addition of a new player, if the player was already in the game, it will be handled by the reconnection policy and fires the OnPlayerJoined event.
--- Fires 'OnPlayerJoined' if the player was not already in the game.
--- @param player Player
function RoundManager:OnPlayerAdded(player)
	local ctx = self:BuildContext()
	local existing = self.PlayerStates:GetPlayerState(player.UserId)

	if existing then
		if self.ReconnectionPolicy then
			self.ReconnectionPolicy:Handle(ctx, player, existing)
		else
			self.PlayerStates:RemovePlayerState(player.UserId)
		end
		return
	end

	self.EventBus:Fire("OnPlayerJoined", ctx, player)
end

--- Handles the removal of a player, fires the OnPlayerLeft event, the state is purposefully left in the round state for the reconnection policy to handle.
--- Fires 'OnPlayerLeft' when the player is removed.
--- @param player Player
function RoundManager:OnPlayerRemoving(player)
	local state = self.PlayerStates:GetPlayerState(player.UserId)
	if state then
		state:SetConnected(false)
	end

	self.EventBus:Fire("OnPlayerLeft", player, state)
end

--- Clears the round state, fires the OnRoundReset event.
--- Fires 'OnRoundReset' when the round state is cleared.
function RoundManager:ClearRoundState()
	self.PlayerStates:Clear()
	self.EventBus:Fire("OnRoundReset")
end

--- Resets the round state and transitions to the initial phase.
function RoundManager:Reset()
	self:ClearRoundState()
	self:TransitionTo(self.Config.InitialPhase)
end

--- Destroys the round manager, clears the round state, disconnects all connections, and destroys the event bus.
function RoundManager:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true

	self._running = false -- stops the main loop

	if self._driverConn then
		self._driverConn:Disconnect()
	end

	for _, connection in ipairs(self._phaseConnections) do
		connection:Disconnect()
	end
	self._phaseConnections = {}

	self.PlayerStates:Destroy()
	self.EventBus:Destroy()
end

return RoundManager
