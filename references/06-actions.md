# Reference 06 — Actions Panel

## Layout
- Two large square tiles side-by-side, each with an image + cartoon-styled label:
  1. **WALK** — player walking the pet on a leash thumbnail
  2. **CARRY** — player holding the pet to chest thumbnail

## Behavior
- **WALK** (toggle): pet follows owner using `PathfindingService` at `PetConfig.WalkSpeed`. Server-side, runs as a per-pet state machine. Re-click to stop.
- **CARRY** (toggle): pet welds to owner's `RightHand` via `Motor6D`; pet's Humanoid is disabled. Re-click to drop in place.

## Mutual exclusion
- WALK and CARRY are mutually exclusive — toggling one cancels the other.

## Remotes
- `Remotes.DoAction(actionId)` where `actionId ∈ {"walk", "carry", "idle"}`.

## Implementation target
`src/StarterPlayer/StarterPlayerScripts/UI/ActionsPanel.lua`
+ server: `src/ServerScriptService/ActionService.lua`
