export type Context = {
	RoundManager: any,
	EventBus: any,
	Config: any,

	GetEntities: (self: Context) -> { any },
	GetMetric: (self: Context, entity: any, key: string) -> number,
	GetReadyPlayerCount: (self: Context) -> number,
	GetElapsedTime: (self: Context) -> number,
	GetCurrentPhase: (self: Context) -> any,

	AddPlayerState: (self: Context, player: Player) -> any,
	RemovePlayerState: (self: Context, userId: number) -> (),
	GetPlayerState: (self: Context, userId: number) -> any,

	GetGlobalMetric: (self: Context, key: string) -> any,
	SetGlobalMetric: (self: Context, key: string, value: any) -> (),
	ApplyGlobalMetric: (self: Context, key: string, delta: number) -> (),

	TransitionTo: (self: Context, phaseName: string) -> boolean,
	EvaluateWinCondition: (self: Context) -> any,

	Connect: (self: Context, eventName: string, callback: (...any) -> ()) -> any,
}

return {}
