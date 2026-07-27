local PlayerRoundStateType = require(script.Parent.PlayerRoundState)
type PlayerRoundState = PlayerRoundStateType.PlayerRoundState

export type PlayerStateRegistry = {
	AddPlayerState: (self: PlayerStateRegistry, player: Player) -> PlayerRoundState,
	RemovePlayerState: (self: PlayerStateRegistry, userId: number) -> (),
	GetPlayerState: (self: PlayerStateRegistry, userId: number) -> PlayerRoundState?,
	GetAllPlayerStates: (self: PlayerStateRegistry) -> { [number]: PlayerRoundState },
	Clear: (self: PlayerStateRegistry) -> (),
	Destroy: (self: PlayerStateRegistry) -> (),
}

return {}