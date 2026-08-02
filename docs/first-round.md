---
sidebar_position: 5
---

# Making Your First Round

This page builds a complete round from scratch using the concepts introduced so far. Later sections add player state, reconnection, and custom events to the same round.

## Setup

Require RoundKit like any other module.

```lua
local RoundKit = require(game.ReplicatedStorage.RoundKit)
```

We'll build the round one phase at a time, then put everything together at the end.

## The lobby

Every round starts with a `Phases` table and an `InitialPhase`.

```lua
local Phases = {
    Lobby = {
        Name = "Lobby",
        AllowedTransitions = {},
    },
}

local manager = RoundKit.new({
    Phases = Phases,
    InitialPhase = "Lobby",
    WinCondition = "TimeLimit",
})

manager:Start()
```

At this point the round starts and remains in `Lobby`. There are no valid transitions yet, and the `TimeLimit` win condition has not been registered.

## Adding a countdown

Add a `Countdown` phase that transitions automatically after five seconds.

```lua
Phases.Countdown = {
    Name = "Countdown",
    AllowedTransitions = { "Active" },
    Duration = 5,

    OnEnter = function(context)
        print("Countdown started")
    end,
}
```

Now allow `Lobby` to transition into it.

```lua
Phases.Lobby = {
    Name = "Lobby",
    AllowedTransitions = { "Countdown" },

    CanTransitionTo = function(context)
        return context:GetReadyPlayerCount() >= 2
    end,
}
```

`GetReadyPlayerCount()` reads from the player registry. Until players are added to the round, it always returns `0`, so the round remains in `Lobby`.

For simplicity, this example uses the hardcoded value `2`. In a real game, it's usually better to expose this as part of your round configuration:

```lua
local manager = RoundKit.new({
    Phases = Phases,
    InitialPhase = "Lobby",
    WinCondition = "TimeLimit",
    MinimumPlayers = 2,
})
```

Then reference it through `context.Config`:

```lua
CanTransitionTo = function(context)
    return context:GetReadyPlayerCount() >= context.Config.MinimumPlayers
end
```


## Adding a win condition

Register a win condition that ends the round after 30 seconds.

```lua
RoundKit.WinCondition.new("TimeLimit", function(context)
    if context:GetElapsedTime() >= 30 then
        return {
            Type = "Draw",
            Winners = {},
        }
    end

    return nil
end)
```

## Adding the active phase

The `Active` phase evaluates the win condition and returns the round to `Lobby` once a winner is reported.

```lua
Phases.Active = {
    Name = "Active",
    AllowedTransitions = { "Lobby" },
    EvaluateWinCondition = true,

    OnEnter = function(context)
        context:Connect("OnWinConditionMet", function(outcome)
            print("Round ended:", outcome.Type)
            context:TransitionTo("Lobby")
        end)
    end,
}
```

## Putting it together

```lua
local RoundKit = require(game.ReplicatedStorage.RoundKit)

RoundKit.WinCondition.new("TimeLimit", function(context)
    if context:GetElapsedTime() >= 30 then
        return {
            Type = "Draw",
            Winners = {},
        }
    end

    return nil
end)

local Phases = {
    Lobby = {
        Name = "Lobby",
        AllowedTransitions = { "Countdown" },

        CanTransitionTo = function(context)
            return context:GetReadyPlayerCount() >= 2
        end,
    },

    Countdown = {
        Name = "Countdown",
        AllowedTransitions = { "Active" },
        Duration = 5,

        OnEnter = function(context)
            print("Countdown started")
        end,
    },

    Active = {
        Name = "Active",
        AllowedTransitions = { "Lobby" },
        EvaluateWinCondition = true,

        OnEnter = function(context)
            context:Connect("OnWinConditionMet", function(outcome)
                print("Round ended:", outcome.Type)
                context:TransitionTo("Lobby")
            end)
        end,
    },
}

local manager = RoundKit.new({
    Phases = Phases,
    InitialPhase = "Lobby",
    WinCondition = "TimeLimit",
    AutoWirePlayers = true,
})

manager:Start()
```

This round starts in `Lobby`, waits for two ready players, enters a five-second countdown, runs the active phase, then returns to `Lobby` after thirty seconds.

The round still doesn't track players, so `GetReadyPlayerCount()` always returns `0`. The next section adds player state, allowing the lobby to transition as intended.

## Next steps

The next section, [Player & Global State](./player-global-state.md), introduces `context:AddPlayerState()` and `state:SetReady()`, which complete this round. Later sections cover reconnection and custom events.
