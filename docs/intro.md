---
sidebar_position: 1
---

# Introduction

RoundKit is a modular, server-authoritative framework for building round-based game modes on Roblox. Rather than centering your game around a large controller script, RoundKit models a match as a collection of **phases**, each with its own lifecycle, transition rules, and behavior.

## Features

- **Phase-based architecture** for modelling round lifecycles.
- **Configurable phase transitions** with static or dynamic transition rules.
- **Pluggable win conditions** for implementing custom logic.
- **Context API** for safely interacting with the current round state.

## Concepts

A RoundKit game consists of a few simple building blocks:

- **RoundManager** — Owns the round, updates phases, evaluates win conditions, and coordinates transitions.
- **Phases** — Represent the different stages of a round (Lobby, Countdown, Active, Results, etc.).
- **Context** — Provides a controlled interface for interacting with the current round.
- **Win Conditions** — Determine when a round has been won and by whom.
- **Reconnection Policies** — Define how players are handled after disconnecting and rejoining.

## Example Usage

```lua
local RoundKit = require(game.ReplicatedStorage.RoundKit)

local Phases = {
    Lobby = {
        Name = "Lobby",
        AllowedTransitions = { "Countdown" },
    },

    Countdown = {
        Name = "Countdown",
        AllowedTransitions = { "Active" },
        Duration = 5,

        OnEnter = function()
            print("Entered countdown phase")
        end,

        OnExit = function()
            print("Leaving countdown phase")
        end,
    },

    Active = {
        Name = "Active",
        AllowedTransitions = { "Lobby" },
        CheckWinCondition = true,
        WinCheckInterval = 1,

        OnEnter = function(context)
            print("Entered active phase.")

            context:Connect("OnWinConditionMet", function(outcome)
                print("Round ended!", outcome)
                context:TransitionTo("Lobby")
            end)
        end,
    },
}

RoundKit.WinCondition.new("TimeLimit", function(context)
    if context:GetElapsedTime() >= 60 then
        return {
            Type = "Player",
            Winners = context:GetEntities(),
        }
    end
end)

local manager = RoundKit.new({
    Phases = Phases,
    InitialPhase = "Lobby",
    WinCondition = "TimeLimit",
})

manager:Start()
```

Continue with the API reference to learn more about the `RoundManager`, `Context`, `WinCondition`, `ReconnectionPolicy`, and the rest of RoundKit's API.