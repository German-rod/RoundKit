---
sidebar_position: 1
---

# Introduction

RoundKit is a framework for building round-based games on Roblox.
The framework takes care of the round flow so you can focus on implementing your game's mechanics.

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

-- Define the phases that make up the round.
local Phases = {
    Lobby = {
        Name = "Lobby",
        AllowedTransitions = { "Countdown" },
        CanTransitionTo = function(context, phase)
            if phase == "Countdown" then
                local playerReadyCount = context:GetReadyPlayerCount()
		        local minPlayers = context.Config.MinPlayers
		
		        return playerReadyCount >= minPlayers
            end
        end,
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
        EvaluateWinCondition = true,
        EvaluateWinConditionInterval = 1,

        OnEnter = function(context)
            print("Entered active phase.")

            context:Connect("OnWinConditionMet", function(outcome)
                print("Round ended!", outcome)
                context:TransitionTo("Lobby")
            end)
        end,
    },
}

-- Register a custom win condition.
RoundKit.WinCondition.new("TimeLimit", function(context)
    if context:GetElapsedTime() >= 60 then
        return {
            Type = "Player",
            Winners = context:GetEntities(),
        }
    end
end)

-- Create and configure the round manager.
local manager = RoundKit.new({
    Phases = Phases,
    InitialPhase = "Lobby",
    WinCondition = "TimeLimit",
    AutoWirePlayers = true, -- Connects the players OnAdded and OnRemoving automatically.
    MinPlayers = 4,
})

-- Set up the logic for player joining
manager:OnPlayerJoined(function(context, player)
	local phase = context:GetCurrentPhase()
	if phase.Name == "Lobby" then
		context:AddPlayerState(player):SetReady(true)
	elseif phase.Name == "Active" then
		local state = context:AddPlayerState(player)
		state.Spectating = true
	end
end)

-- Start the round.
manager:Start()
```

Continue with the API reference to learn more about the `RoundManager`, `Context`, `WinCondition`, `ReconnectionPolicy`, and the rest of RoundKit's API.