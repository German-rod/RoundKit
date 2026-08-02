---
sidebar_position: 3
---

# Defining Phases

A phase is a plain Lua table. Pass a table of named phases to `RoundKit.new()` through the `Phases` field.

```lua
local Phases = {
    Lobby = {
        Name = "Lobby",
        AllowedTransitions = { "Countdown" },
    },
}
```

## Transition

### `Name`

The phase name. This should match its key in the `Phases` table. RoundKit uses it in events and diagnostics.

### `AllowedTransitions`

Defines which phases this phase can transition to.

This can be either:

* A list of phase names.
* A function `(context) -> {string}` that returns the allowed phase names dynamically.

```lua
AllowedTransitions = function(context)
    if context:GetGlobalMetric("OvertimeEnabled") then
        return { "Overtime", "Results" }
    end

    return { "Results" }
end,
```

`RoundManager:TransitionTo(phaseName)` succeeds only if `phaseName` appears in the resolved transition list.

### `Duration`

An optional duration, in seconds. After it elapses, RoundKit attempts a transition.

* If `CanTransitionTo` is defined, `Duration` controls when transition checks begin.
* Otherwise, `AllowedTransitions` must resolve to exactly one phase, which RoundKit enters automatically.

### `CanTransitionTo`

```lua
CanTransitionTo = function(context, targetPhase)
    if targetPhase == "Countdown" then
        return context:GetReadyPlayerCount() >= context.Config.MinPlayers
    end
end,
```

Called once per update for each candidate returned by `AllowedTransitions`, in order. The first target that returns `true` becomes the next active phase.

## Lifecycle

### `OnEnter` / `OnExit`

```lua
OnEnter = function(context)
    print("Entered countdown phase")
end,

OnExit = function(context)
    print("Leaving countdown phase")
end,
```

Called once after entering or leaving the phase.

Use `OnEnter` to initialize phase-specific state, and `OnExit` to clean it up.

Connections created with `context:Connect(...)` during `OnEnter` are automatically disconnected when the phase exits.

### `OnUpdate`

```lua
OnUpdate = function(context, dt)
    -- Runs every update while this phase is active.
end,
```

Called every update while the phase is active. Use it for continuous behavior rather than one-time setup or cleanup.

## Win Conditions

### `EvaluateWinCondition`

### `EvaluateWinConditionInterval`

```lua
Active = {
    Name = "Active",
    EvaluateWinCondition = true,
    EvaluateWinConditionInterval = 1, -- Default: 1 second
    ...
},
```

When `EvaluateWinCondition` is enabled, RoundKit evaluates the configured win condition every `EvaluateWinConditionInterval` seconds while the phase is active. If a winner is found, it fires `OnWinConditionMet`.

See [Win Conditions](./win-conditions.md) for details.

## Runtime Behavior

### Error handling

Every phase callback runs inside a protected call:

* `AllowedTransitions` (function form)
* `CanTransitionTo`
* `OnEnter`
* `OnUpdate`
* `OnExit`

If a callback errors, RoundKit logs the error and stack trace, then continues running. Errors inside phase callbacks do not stop the round.

### Update loop

By default, `RoundManager` updates itself with `task.wait(UpdateInterval)`. `UpdateInterval` defaults to one second.

To use a custom update source, provide a `Driver` signal:

```lua
RoundKit.new({
    Phases = Phases,
    InitialPhase = "Lobby",
    WinCondition = "LastAlive",
    Driver = game:GetService("RunService").Heartbeat,
})
```

The next section covers [Win Conditions](./win-conditions.md), which determine when a round ends and who wins.
