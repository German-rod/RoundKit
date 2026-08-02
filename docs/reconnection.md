---
sidebar_position: 7
---
# Reconnection

RoundKit separates reconnection behavior from phase logic. When a tracked player disconnects, their state remains available for a configurable period, allowing a `ReconnectionPolicy` to restore it if they rejoin.

## Disconnect behavior

When `AutoWirePlayers` is enabled, or when `manager:OnPlayerRemoving()` is called manually, the player's `PlayerRoundState` is updated as follows:

* `Connected` is set to `false`.
* `Ready` is set to `false`.
* The state remains in the `PlayerStateRegistry`.
* The state is removed automatically after `StaleStateTimeout` seconds (30 by default).

This grace period allows a reconnection policy to reclaim the existing state instead of creating a new one.

## Defining a reconnection policy

Register a policy with `ReconnectionPolicy.new(name, handler)`:

```lua id="0qvgg8"
RoundKit.ReconnectionPolicy.new("RestoreSpectator", function(context, player, previousState)
    previousState:Rebind(player)

    if context:GetCurrentPhase().Name == "Active" then
        previousState:SetMetric("Spectating", true)
    end
end)
```

The handler is called when a player rejoins before their previous state expires.

`previousState` is the existing `PlayerRoundState`. Call `previousState:Rebind(player)` to associate it with the new `Player` instance and mark it as connected again.

Register each reconnection policy once, typically when your game starts.

## Using a reconnection policy

Assign a registered policy in the round configuration.

```lua id="p2qv1l"
RoundKit.new({
    Phases = Phases,
    InitialPhase = "Lobby",
    WinCondition = "LastAlive",
    ReconnectionPolicy = "RestoreSpectator",
    AutoWirePlayers = true,
})
```

If no reconnection policy is configured, a returning player is treated as a new join and their previous state is discarded.

## Phase-specific behavior

A reconnection policy is invoked only when an existing `PlayerRoundState` is available.

Players joining for the first time always follow the normal `OnPlayerJoined` flow.

If reconnection behavior depends on the current phase, inspect `context:GetCurrentPhase()` inside the policy rather than registering multiple policies.

The next section introduces [Events](./events.md), which power `Context:Connect()` and the built-in round events.
