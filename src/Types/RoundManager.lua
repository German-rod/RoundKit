export type RoundManager = {
	Config: any,
	Phases: any,
	CurrentPhase: any,
	PlayerStates: any,
	GlobalMetrics: any,
	WinCondition: any,
	ReconnectionPolicy: any,
	EventBus: any,

	Start: (self: RoundManager) -> (),
	Pause: (self: RoundManager) -> (),
	Resume: (self: RoundManager) -> (),

	TransitionTo: (self: RoundManager, phaseName: string) -> boolean,
	Update: (self: RoundManager, dt: number) -> (),

	CheckWinCondition: (self: RoundManager) -> any,
	EvaluateWinCondition: (self: RoundManager) -> any,

	BuildContext: (self: RoundManager) -> any,

	OnPlayerAdded: (self: RoundManager, player: Player) -> (),
	OnPlayerRemoving: (self: RoundManager, player: Player) -> (),

	ClearRoundState: (self: RoundManager) -> (),
	Reset: (self: RoundManager) -> (),
	Destroy: (self: RoundManager) -> (),
}

return {}