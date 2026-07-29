--[=[
	@within RoundManager
	@interface Events
	.OnPhaseChanged (oldPhase: Phase, newPhase: Phase)
	.OnPlayerAdded (player: Player)
	.OnPlayerRemoving (player: Player, state: PlayerRoundState? | nil)
	.OnWinConditionMet (outcome: WinOutcome)
	.OnRoundReset ()
]=]

local Core = require(script.Parent.Parent.Types.Core)
export type RoundManager = Core.RoundManager

local GlobalMetricRegistry = require(script.Parent.Parent.Registries.GlobalMetricRegistry)
local PlayerStateRegistry = require(script.Parent.Parent.Registries.PlayerStateRegistry)
local PlayerRoundState = require(script.Parent.PlayerRoundState)
local RoundEventBus = require(script.Parent.Parent.Systems.RoundEventBus)
local Context = require(script.Parent.Parent.Systems.Context)
local WinCondition = require(script.Parent.WinCondition)
local ReconnectionPolicy = require(script.Parent.ReconnectionPolicy)

local Players = game:GetService("Players")

-- xpcall wrapper that returns the error stack trace
local function Try(fn, ...)
	local args = table.pack(...)

	return xpcall(function()
		return fn(table.unpack(args, 1, args.n))
	end, function(err)
		warn(debug.traceback(err, 2))
		return err
	end)
end

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
		StaleStateTimeout = config.StaleStateTimeout or 30,
		PlayerStates = PlayerStateRegistry.new(),
		GlobalMetrics = setmetatable({}, GlobalMetricRegistry),
		WinCondition = WinCondition.Resolve(config.WinCondition),
		ReconnectionPolicy = config.ReconnectionPolicy and ReconnectionPolicy.Resolve(config.ReconnectionPolicy) or nil,
		EventBus = RoundEventBus.new(),
		_context = nil,
		_phaseElapsed = 0,
		_winCheckElapsed = 0,
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

	if self.Config.AutoWirePlayers then
		self._playerAddedConn = Players.PlayerAdded:Connect(function(player)
			self:OnPlayerAdded(player)
		end)
		self._playerRemovingConn = Players.PlayerRemoving:Connect(function(player)
			self:OnPlayerRemoving(player)
		end)

		for _, player in ipairs(Players:GetPlayers()) do
			self:OnPlayerAdded(player)
		end
	end

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
		-- resolves the current phase allowed transitions and triggers OnExit
		local ctx = self:BuildContext()
		local allowed = self:ResolveAllowedTransitions(self.CurrentPhase, ctx)
		if not table.find(allowed, phaseName) then
			self._transitioning = false
			return false
		end
		if self.CurrentPhase.OnExit then
			Try(self.CurrentPhase.OnExit, ctx)
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

	self.EventBus:Fire("OnPhaseChanged", oldPhase, nextPhase)
	self._transitioning = false

	if nextPhase.OnEnter then
		Try(nextPhase.OnEnter, self:BuildContext())
	end

	return true
end

--- Updates the round manager state, evaluates the current phase state, if it should transition, the win condition and manages stale player states.
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

	-- checks if the phase has a defined duration and if the elapsed time is past the duration.
	if phase.Duration and self._phaseElapsed >= phase.Duration then
		-- transitions to the resolved allowed transitions for the phase
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

	-- Evaluates the CanTransitionTo function, resolves the allowed transitions and tries to transition to the first one.
	if phase.CanTransitionTo then
		local ctx = self:BuildContext()
		local allowed = self:ResolveAllowedTransitions(phase, ctx)
		for _, targetName in ipairs(allowed) do
			local ok, result = Try(phase.CanTransitionTo, ctx, targetName)
			if ok and result then
   				 self:TransitionTo(targetName)
    			return
			end
		end
	end

	if phase.EvaluateWinCondition and (phase.EvaluateWinConditionInterval or 1) then
		self._winCheckElapsed += dt
		if self._winCheckElapsed >= (phase.EvaluateWinConditionInterval or 1) then
			self._winCheckElapsed = 0
			self:CheckWinCondition()
		end
	end

	if self.StaleStateTimeout then
		local now = os.clock()
		for userId, state in self.PlayerStates:GetAllPlayerStates() do
			if
				not state.Connected
				and state.DisconnectedTime
				and now - state.DisconnectedTime >= self.StaleStateTimeout
			then
				self.PlayerStates:RemovePlayerState(userId)
			end
		end
	end
end

--- Checks the win condition and fires the OnWinConditionMet event if it is met.
--- Fires 'OnWinConditionMet' if the win condition is met.
--- @return WinOutcome?
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
	if not self._context then
		self._context = Context.new(self)
	end

	return self._context
end

--- Evaluates the win condition and returns the outcome.
--- @return WinOutcome?
function RoundManager:EvaluateWinCondition()
	if not self.WinCondition then
		return nil
	end

	local ok, outcome = Try(self.WinCondition.Evaluate, self.WinCondition, self:BuildContext())
	return ok and outcome or nil
end

--- Resolves the allowed transitions for the given phase.
--- @param phase Phase
--- @param ctx Context
--- @return {string}
function RoundManager:ResolveAllowedTransitions(phase, ctx)
	local allowed = phase.AllowedTransitions
	if type(allowed) == "function" then
		local ok, resolved = Try(allowed, ctx)
		if not ok then
    		return {}
		end
		assert(type(resolved) == "table", "RoundKit phase '" .. phase.Name .. "'s AllowedTransitions function must return a table")
		return resolved
	end
	return allowed
end

--- Detects when a player is added to the game.
--- If the player already has round state (reconnection), triggers the reconnection policy.
--- Otherwise, fires the 'OnPlayerJoined' event for the developer to handle.
--- :::caution
--- You must connect this to Players.PlayerAdded (or similar) or set AutoWirePlayers to true for it to work.
--- :::
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

--- Connects a callback to the OnPlayerJoined event.
--- :::caution
--- You must connect :OnPlayerAdded to Players.PlayerAdded (or similar) or set AutoWirePlayers to true for it to work.
--- :::
--- @param callback (context: Context, player: Player) -> ()
function RoundManager:OnPlayerJoined(callback)
	return self.EventBus:Connect("OnPlayerJoined", callback)
end

--- Detects when a player is leaving the game.
--- If the player has a round state, marks them as disconnected
--- Fires the 'OnPlayerLeft' event for the developer to handle.
--- :::caution
--- You must connect this to Players.PlayerRemoving (or similar) or set AutoWirePlayers to true for it to work.
--- :::
--- :::caution
--- The player round state is not removed from the registry, it is only marked as disconnected. This allows for reconnection policies to handle the player if they rejoin.
--- Player's round state will be removed from the registry if it is considered stale (disconnected for longer than StaleStateTimeout seconds).
--- :::
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

	if self._playerAddedConn then
		self._playerAddedConn:Disconnect()
	end
	if self._playerRemovingConn then
		self._playerRemovingConn:Disconnect()
	end
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
