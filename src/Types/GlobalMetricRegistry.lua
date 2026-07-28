export type GlobalMetricRegistry = {
	Get: (self: GlobalMetricRegistry, key: string) -> any,
	Set: (self: GlobalMetricRegistry, key: string, value: any) -> (),
	Clear: (self: GlobalMetricRegistry) -> (),
}

return {}
