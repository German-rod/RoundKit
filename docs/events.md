---
sidebar_position: 8
---

# Events

Each round owns a `RoundEventBus`. Phases, win conditions, and game code use it to communicate without direct dependencies.

## Connecting and firing

Use `Context` to subscribe to or fire events:

```lua
context:Connect("PlayerScored", function(player, amount)
    print(player.Name, "scored", amount)
end)

context:Fire("PlayerScored", somePlayer, 10)
```

Connections created with `context:Connect()` are tied to the active phase. They are disconnected automatically when the phase exits.

To create a connection that persists across multiple phases, connect directly to the event bus:

```lua
manager.EventBus:Connect("PlayerScored", function(player, amount)
    print(player.Name, "scored", amount)
end)
```

Connections made directly to `RoundEventBus` are not managed automatically and must be disconnected manually.

## Built-in events

RoundKit fires the following events automatically.

| Event               | Arguments            | Description                                                 |
| ------------------- | -------------------- | ----------------------------------------------------------- |
| `OnPhaseChanged`    | `oldPhase, newPhase` | Fired after a phase transition completes.                   |
| `OnWinConditionMet` | `outcome`            | Fired when a win condition returns a `WinOutcome`.          |
| `OnPlayerJoined`    | `context, player`    | Fired when a player joins the round without existing state. |
| `OnPlayerLeft`      | `player, state`      | Fired when a tracked player leaves. `state` may be `nil`.   |
| `OnRoundReset`      | None                 | Fired by `ClearRoundState()` and `Reset()`.                 |

## Custom events

Custom event names may be used for game-specific behavior.

```lua
context:Fire("BombPlanted", site)
context:Fire("RoundOvertimeStarted")
```

Use events when multiple systems need to react to the same occurrence, such as gameplay, UI, analytics, or effects. If only one system needs the information, a direct function call is usually simpler.

---

This concludes the core concepts of RoundKit. For additional patterns, see the full [API reference](/api/RoundManager).
