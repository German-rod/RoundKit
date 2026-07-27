export type RoundEventBus = {
	Get: (self: RoundEventBus, eventName: string) -> any, -- Sleitnick Signal instance
	Connect: (self: RoundEventBus, eventName: string, callback: (...any) -> ()) -> any,
	Fire: (self: RoundEventBus, eventName: string, ...any) -> (),
	Destroy: (self: RoundEventBus) -> (),
}

return {}