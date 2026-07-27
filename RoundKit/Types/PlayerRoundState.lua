--[=[
	@interface PlayerRoundState
	@within PlayerRoundState
	.Player (Player),
	.UserId (number),
	.Connected (boolean),
	.Ready (boolean),
	.Metrics ({ [string]: string | number }),
]=]

export type PlayerRoundState = {
	Player: Player,
	UserId: number,
	Connected: boolean,
	Ready: boolean,
	Metrics: { [string]: string | number },

	GetMetric: (self: PlayerRoundState, key: string) -> string | number,
	SetMetric: (self: PlayerRoundState, key: string, value: string | number) -> (),
	Eliminate: (self: PlayerRoundState) -> (),
	SetConnected: (self: PlayerRoundState, connected: boolean) -> (),
	SetReady: (self: PlayerRoundState, ready: boolean) -> (),
	Rebind: (self: PlayerRoundState, newPlayer: Player) -> (),
	Destroy: (self: PlayerRoundState) -> (),
}

return {}
