# RoundKit

RoundKit is a framework for building round-based games on Roblox. It models a round as a collection of **phases**, so you can define how a match progresses: lobby, countdown, active play and results without tangling that flow into your gameplay code.

## Why this exists

I built RoundKit while working on my own round-based games, after rewriting the same phase/state-machine logic from scratch too many times. It started as an internal tool and portfolio piece. I'm publishing it because the architecture may be useful to other Roblox developers.

If your game has rounds: lobby → countdown → play → results, or similar. RoundKit gives you:

- **Phases** as data.
- **Win conditions** decoupled from phase logic, including composable `AnyOf` / `AllOf` combinators.
- **Reconnection handling** as a pluggable policy.
- **Per-player and global round state** (`PlayerStateRegistry`, `GlobalMetricRegistry`) that gets cleaned up automatically instead of leaking across rounds.
- **An event bus** (`Context:Connect`) so phases, win conditions, and your own game code can react to round events without direct references to each other.

If your game only has one or two simple states, or you're already happy with a hand-rolled state machine, RoundKit is probably more structure than you need.

## Example

```lua
local RoundKit = require(game.ReplicatedStorage.RoundKit)

local Phases = {
    Lobby = {
        Name = "Lobby",
        AllowedTransitions = { "Countdown" },
        CanTransitionTo = function(context)
            return context:GetReadyPlayerCount() >= context.Config.MinPlayers
        end,
    },

    Countdown = {
        Name = "Countdown",
        AllowedTransitions = { "Active" },
        Duration = 5,
    },

    Active = {
        Name = "Active",
        AllowedTransitions = { "Lobby" },
        EvaluateWinCondition = true,

        OnEnter = function(context)
            context:Connect("OnWinConditionMet", function(outcome)
                context:TransitionTo("Lobby")
            end)
        end,
    },
}

local manager = RoundKit.new({
    Phases = Phases,
    InitialPhase = "Lobby",
    WinCondition = "LastAlive",
    AutoWirePlayers = true,
    MinPlayers = 4,
})

manager:Start()
```

See the [documentation](https://german-rod.github.io/RoundKit/) for the full guide and API reference, including custom win conditions, reconnection policies, and the event bus.

## Installation

Wally
```toml
[dependencies]
RoundKit = "german-rod/roundkit@0.1.0"
```

Alternatively you can find an updated roblox studio file containing the module in the repository releases.

## Documentation

Full documentation, guides, and API reference: **https://german-rod.github.io/RoundKit/**

## Project Status

RoundKit is provided **as-is**, with no guaranteed maintenance, feature requests, or support timeline. It was built for my own projects and shared publicly in case it's useful to others.

- **Docs:** the link above is the extent of available guidance.

## License

RoundKit is licensed under the [MIT License](LICENSE).
