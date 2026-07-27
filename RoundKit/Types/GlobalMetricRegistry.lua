export type GlobalMetricRegistry = {
	Get: (self: GlobalMetricRegistry, key: string) -> any,
	Set: (self: GlobalMetricRegistry, key: string, value: any) -> (),
	Apply: (self: GlobalMetricRegistry, key: string, delta: number) -> (),
	Clear: (self: GlobalMetricRegistry) -> (),
}

return {}