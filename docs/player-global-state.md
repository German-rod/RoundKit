---
sidebar_position: 6
---

# Player & Global State

RoundKit provides two registries for round state:

* `PlayerStateRegistry` stores state for individual players.
* `GlobalMetricRegistry` stores state shared by the entire round.

Use these instead of loose variables or `Player` attributes.

## Player state

Each tracked player has a `PlayerRoundState`. A state is created explicitly with `context:AddPlayerState()`, or indirectly through your own player management code.

```lua
manager:OnPlayerJoined(function(context, player)
    local state = context:AddPlayerState(player)
    state:SetReady(true)
end)
```

A `PlayerRoundState` contains:

* `Player` - the associated `Player`.
* `UserId` - the player's user ID.
* `Connected` - whether the player is currently connected.
* `Ready` - used by helper methods such as `context:GetReadyPlayerCount()`.
* `Metrics` - a key/value store for game-specific data.

```lua
state:SetMetric("Kills", 0)
state:SetMetric("Alive", true)

local kills = state:GetMetric("Kills")
```

Most game code accesses player state through `Context` rather than holding a `PlayerRoundState` directly.

```lua
context:GetMetric(player, "Kills")
context:GetPlayerState(player.UserId)
context:GetPlayers()
context:GetReadyPlayerCount()
```

Use `context:RemovePlayerState(userId)` to stop tracking a player completely. This removes the player's state from the round. It does not mark them as disconnected.

### `AutoWirePlayers`

```lua
RoundKit.new({
    ...
    AutoWirePlayers = true,
})
```

When enabled, RoundKit connects to `Players.PlayerAdded` and `Players.PlayerRemoving` automatically, forwarding those events to the round manager.

`AutoWirePlayers` does **not** create player states automatically. It only invokes the corresponding round callbacks, allowing your game to decide which players should be tracked.

If disabled, call `manager:OnPlayerAdded(player)` and `manager:OnPlayerRemoving(player)` yourself.

## Global state

`GlobalMetricRegistry` stores key/value pairs shared by the current round.

```lua
context:SetGlobalMetric("RedTeamScore", 0)

context:SetGlobalMetric(
    "RedTeamScore",
    context:GetGlobalMetric("RedTeamScore") + 1
)
```

Unlike player state, global metrics do not require explicit creation. They are available for the lifetime of the round.

## Cleanup

Both registries are scoped to the current round.

### `RoundManager:ClearRoundState()`

Clears all player states and fires `OnRoundReset`. The current phase is unchanged.

### `RoundManager:Reset()`

Clears all player states, then transitions back to `InitialPhase`, bypassing normal transition rules.

### Disconnected players

Disconnected players are retained until they have been disconnected longer than `StaleStateTimeout` (30 seconds by default). This allows reconnection policies to reclaim their state.

Global metrics are cleared automatically by `RoundManager:ClearRoundState()`.

The next section covers [Reconnection](./reconnection.md), which determines how disconnected players are handled.
