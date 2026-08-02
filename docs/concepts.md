---
sidebar_position: 2
---

# Core Concepts

RoundKit is built around four core concepts. Understanding how they fit together makes the rest of the API straightforward.

## A round is a state machine, not a script

Many round systems evolve into if phase == "X" checks spread across multiple scripts, where phases, player state, timers, and win logic become tightly coupled. RoundKit separates those responsibilities into four pieces.

- **`RoundManager`**: owns the round lifecycle, updates the active phase, and coordinates transitions.
- **`Phases`**: define each stage of the round, its allowed transitions, and its enter, update, and exit behavior.
- **`Context`**: the API exposed to phases, win conditions, and game code.
- **`WinCondition`**: evaluates whether a phase should end and returns the outcome.

Supporting systems:
- **`PlayerStateRegistry` / `RoundMetricRegistry`**: store round-scoped player and shared state.
- **`RoundEventBus`**: provides event-based communication between round systems.

## How they fit together

<img width="1200" height="600" alt="Untitled diagram-2026-08-01-004944" src="https://github.com/user-attachments/assets/57d0f984-bc0a-4749-a498-f67e601c5b30" />

A few things worth noticing in this diagram:

Game code interacts with the round through `Context`, not `RoundManager`. Win conditions report a `WinOutcome`; phases decide how to respond. Player state is scoped to the current round and is cleared when the round ends. Systems that don't belong in a phase hook can communicate through `RoundEventBus`.

## Why it's structured this way

The split exists because these three questions tend to change independently of each other in a real game:

1. **What stages does a round go through?** (phases)
2. **When has someone won?** (win conditions)
3. **What happens to a player mid-round who disconnects?** (reconnection policies, covered later)

Phases, win conditions, and reconnection policies solve different problems and tend to change independently. Keeping them separate lets you replace a win condition without modifying phase definitions, or add phases without rewriting game logic.

RoundKit doesn't introduce concepts you couldn't build yourself. It provides a structure that keeps those concepts independent as your game grows.

The following sections introduce each component in more detail.
