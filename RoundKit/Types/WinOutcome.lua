--[=[
	@interface WinOutcome
	@within WinCondition
	.Type (Player | Team | "Draw" | "None"),
	.Winners { Player | Team }

]=]
export type WinOutcome = {
	Type: "Player" | "Team" | "Draw" | "None",
	Winners: { Player | Team },
}

return {}
