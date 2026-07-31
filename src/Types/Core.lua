local PlayerRoundStateType = require(script.Parent.PlayerRoundState)
local PlayerStateRegistryType = require(script.Parent.PlayerStateRegistry)
local GlobalMetricRegistryType = require(script.Parent.GlobalMetricRegistry)
local RoundEventBusType = require(script.Parent.RoundEventBus)
local WinOutcomeType = require(script.Parent.WinOutcome)

type PlayerRoundState = PlayerRoundStateType.PlayerRoundState
type PlayerStateRegistry = PlayerStateRegistryType.PlayerStateRegistry
type GlobalMetricRegistry = GlobalMetricRegistryType.GlobalMetricRegistry
type RoundEventBus = RoundEventBusType.RoundEventBus
type WinOutcome = WinOutcomeType.WinOutcome

export type Context = {
	RoundManager: RoundManager,
	EventBus: RoundEventBus,
	Config: RoundConfig,

	GetPlayers: (self: Context) -> { Player },
	GetMetric: (self: Context, entity: Player, key: string) -> number,
	GetReadyPlayerCount: (self: Context) -> number,
	GetElapsedTime: (self: Context) -> number,
	GetCurrentPhase: (self: Context) -> Phase?,

	AddPlayerState: (self: Context, player: Player) -> PlayerRoundState,
	RemovePlayerState: (self: Context, userId: number) -> (),
	GetPlayerState: (self: Context, userId: number) -> PlayerRoundState?,

	GetGlobalMetric: (self: Context, key: string) -> any,
	SetGlobalMetric: (self: Context, key: string, value: any) -> (),
	ApplyGlobalMetric: (self: Context, key: string, delta: number) -> (),

	TransitionTo: (self: Context, phaseName: string) -> boolean,
	CheckWinCondition: (self: Context) -> WinOutcome?,

	Connect: (self: Context, eventName: string, callback: (...any) -> ()) -> any,
}


--[=[
	@interface Phase
	@within RoundManager
	.Name string -- The name of the phase
	.AllowedTransitions {[string]} | (ctx: Context) -> {[string]} -- A list of phase names that this phase can transition to, or a function that returns such a list
	.Duration number? -- Optional; the duration of this phase in seconds (default nil, meaning no automatic transition)
	.CanTransitionTo (ctx: Context, targetPhase: string) -> boolean? -- Optional; a function that determines if the round can transition to the target phase (default nil, meaning always true)
	.EvaluateWinCondition boolean? -- Optional; if true, the win condition will be evaluated at 'EvaluateWinConditionInterval' (defaults false)
	.EvaluateWinConditionInterval number? -- Optional; the interval in seconds at which to evaluate the win condition (default 1)
	.OnEnter (ctx: Context) -> ()? -- Optional; a function that is called when the round enters this phase
	.OnExit (ctx: Context) -> ()? -- Optional; a function that is called when the round exits this phase
	.OnUpdate (ctx: Context, dt: number) -> ()? -- Optional; a function that is called every update tick while in this phase
]=]
export type Phase = {
	Name: string,
	AllowedTransitions: { string } | (ctx: Context) -> { string },
	Duration: number?,
	CanTransitionTo: ((ctx: Context, targetPhase: string) -> boolean)?,
	EvaluateWinCondition: boolean?,
	EvaluateWinConditionInterval: number?,
	OnEnter: ((ctx: Context) -> ())?,
	OnExit: ((ctx: Context) -> ())?,
	OnUpdate: (ctx: Context, dt: number) -> ()?,
}

export type WinCondition = {
	Name: string,
	Evaluate: (self: WinCondition, context: Context) -> WinOutcome?,
}

export type ReconnectionPolicy = {
	Name: string,
	Handle: (self: ReconnectionPolicy, ctx: Context, player: Player, previousState: PlayerRoundState) -> (),
}

--[=[
	@interface RoundConfig
	@within RoundManager
	.Phases {[string]: Phase} -- Table of phase definitions, keyed by name
	.InitialPhase string -- Which key in Phases to enter on Start()
	.WinCondition string | WinCondition -- A registered name or a raw WinCondition instance
	.ReconnectionPolicy string | ReconnectionPolicy? -- Optional; a registered name or raw instance
	.Driver RBXScriptSignal? -- Optional; overrides the default polling loop
	.UpdateInterval number? -- Optional; seconds between ticks when no Driver is set (default 1)
	.AutoWirePlayers boolean? -- Optional; if true, automatically connects to Players.PlayerAdded and Players.PlayerRemoving (default false)
	.StaleStateTimeout number? -- Optional; seconds before a disconnected player's state is considered stale (default 30)

	The configuration table passed to `RoundKit.new()`.
]=]
export type RoundConfig = {
	Phases: { [string]: Phase },
	InitialPhase: string,
	WinCondition: string | WinCondition,
	ReconnectionPolicy: (string | ReconnectionPolicy)?,
	Driver: RBXScriptSignal?,
	UpdateInterval: number?,
	AutoWirePlayers: boolean?,
	StaleStateTimeout: number?,

	[string]: any,
}

export type RoundManager = {
	Config: RoundConfig,
	Phases: { [string]: Phase },
	CurrentPhase: Phase?,
	PlayerStates: PlayerStateRegistry,
	GlobalMetrics: GlobalMetricRegistry,
	WinCondition: WinCondition,
	ReconnectionPolicy: ReconnectionPolicy?,
	EventBus: RoundEventBus,

	Start: (self: RoundManager) -> (),
	Pause: (self: RoundManager) -> (),
	Resume: (self: RoundManager) -> (),

	TransitionTo: (self: RoundManager, phaseName: string) -> boolean,
	Update: (self: RoundManager, dt: number) -> (),

	CheckWinCondition: (self: RoundManager) -> WinOutcome?,
	EvaluateWinCondition: (self: RoundManager) -> WinOutcome?,

	BuildContext: (self: RoundManager) -> Context,

	OnPlayerAdded: (self: RoundManager, player: Player) -> (),
	OnPlayerRemoving: (self: RoundManager, player: Player) -> (),

	ClearRoundState: (self: RoundManager) -> (),
	Reset: (self: RoundManager) -> (),
	Destroy: (self: RoundManager) -> (),
}

export type WinConditionModule = {
	new: (name: string, evaluator: (context: Context) -> WinOutcome?) -> WinCondition,
	remove: (name: string) -> (),
	Resolve: (nameOrInstance: string | WinCondition) -> WinCondition,
	AnyOf: (children: { string | WinCondition }) -> WinCondition,
	AllOf: (children: { string | WinCondition }) -> WinCondition,
}

export type ReconnectionPolicyModule = {
	new: (
		name: string,
		handler: (ctx: Context, player: Player, previousState: PlayerRoundState) -> ()
	) -> ReconnectionPolicy,
	Resolve: (nameOrInstance: string | ReconnectionPolicy) -> ReconnectionPolicy,
}

export type RoundKit = {
	new: (config: RoundConfig) -> RoundManager,
	WinCondition: WinConditionModule,
	ReconnectionPolicy: ReconnectionPolicyModule,
}

return {}
