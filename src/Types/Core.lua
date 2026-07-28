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

	GetEntities: (self: Context) -> { Player },
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

export type Phase = {
	Name: string,
	AllowedTransitions: { string } | (ctx: Context) -> { string },
	Duration: number?,
	CanTransitionTo: ((ctx: Context, targetPhase: string) -> boolean)?,
	CheckWinCondition: boolean?,
	EvaluateWinConditionInterval: number?,
	OnEnter: ((ctx: Context) -> ())?,
	OnUpdate: ((ctx: Context, dt: number) -> ())?,
	OnExit: ((ctx: Context) -> ())?,
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
