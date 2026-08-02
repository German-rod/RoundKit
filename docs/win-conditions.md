---
sidebar_position: 4
---

# Win Conditions

A win condition is a reusable rule that inspects the round's `Context` and determines whether the round has been won. Phases decide **when** to evaluate a win condition. The win condition decides **whether** a winner exists.

## Defining a win condition

Register a win condition with `WinCondition.new(name, evaluator)`:

```lua
RoundKit.WinCondition.new("LastAlive", function(context)
    local players = context:GetPlayers()
    local alive = {}

    for _, player in ipairs(players) do 
        -- This metric should ideally be set by having an player.Character.Humanoid.Died event inside a phase.
        if context:GetMetric(player, "Alive") ~= false then
            table.insert(alive, player)
        end
    end

    if #alive == 1 then
        return {
            Type = "Player",
            Winners = alive,
        }
    end

    return nil
end)
```

The evaluator receives the current `Context` and returns either:

* `nil` if the round should continue.
* A `WinOutcome` if a winner has been determined.

```lua
export type WinOutcome = {
    Type: "Player" | "Team" | "Draw" | "None",
    Winners: { Player | Team },
}
```

Register each win condition once, typically when your game starts. Registering the same name more than once raises an error.

## Using a win condition

Reference a registered win condition by name, or pass a `WinCondition` instance directly.

```lua
RoundKit.new({
    Phases = Phases,
    InitialPhase = "Lobby",
    WinCondition = "LastAlive",
})
```

Win conditions are evaluated only while the active phase has `EvaluateWinCondition = true` (see [Defining Phases](./defining-phases.md)).

When the evaluator returns a `WinOutcome`, RoundKit fires the `OnWinConditionMet` event.

```lua
Active = {
    Name = "Active",
    EvaluateWinCondition = true,

    OnEnter = function(context)
        context:Connect("OnWinConditionMet", function(outcome)
            context:SetGlobalMetric("LastOutcome", outcome)
            context:TransitionTo("Results")
        end)
    end,
}
```

A win condition never transitions phases directly. The phase decides how to respond to the outcome.

## Combining win conditions

Multiple win conditions can be combined with `AnyOf` and `AllOf`.

```lua
RoundKit.WinCondition.new("TimeLimit", function(context)
    if context:GetElapsedTime() >= 120 then
        return {
            Type = "Draw",
            Winners = {},
        }
    end

    return nil
end)

RoundKit.new({
    Phases = Phases,
    InitialPhase = "Lobby",
    WinCondition = RoundKit.WinCondition.AnyOf({
        "LastAlive",
        "TimeLimit",
    }),
})
```

### `AnyOf`

Evaluates each child condition in order and returns the first non `nil` `WinOutcome`.

Use it when any condition should end the round.

### `AllOf`

Evaluates every child condition and returns a `WinOutcome` only after all of them succeed.

`AllOf` assumes every child agrees on the outcome. It returns the first successful `WinOutcome`; it does not merge multiple outcomes.

Both combinators accept registered condition names or `WinCondition` instances, and can be nested to build more complex logic.

The next section covers [Player & Global State](./player-global-state.md), which stores the data accessed through `Context`.
