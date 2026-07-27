# RoundKit

RoundKit is a framework for building round-based games on Roblox.

It models a round as a collection of phases, allowing you to define how a match progresses while keeping your game logic separate from the round flow.

## Example

```lua
local RoundKit = require(game.ReplicatedStorage.RoundKit)

local manager = RoundKit.new({
    Phases = Phases,
    InitialPhase = "Lobby",
    WinCondition = "LastAlive",
})

manager:Start()
```

## Documentation

The full documentation, API reference, and guides are available here:

https://german-rod.github.io/RoundKit/

## License

RoundKit is licensed under the MIT License.