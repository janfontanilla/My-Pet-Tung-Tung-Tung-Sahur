# Reference 07 — Admin Panel (paywall)

## Layout
- Header banner "ADMIN".
- Stack of large ability tiles (each ~full panel width):
  1. **INVISIBLE** — potion-bottle icon
  2. **+10 SPEED** — player sprinting icon
  3. **PULL OUT ALL** — three clones of player icon
  4. **STEAL ALL…** — red-eyed evil pet (AOE Steal Time)
- Tapping a tile while not owned → opens Robux purchase prompt overlay ("Buy Robux and item — ADMIN PACK — 9,999 R$") for the developer product.

## Ownership model
- One-time developer-product purchase grants persistent `hasAdmin = true` in DataStore.
- `AdminService.lua` implements `MarketplaceService.ProcessReceipt`.
- Server is the only authority for `hasAdmin`. Client never decides.

## Abilities
| ID | Effect |
|---|---|
| `invisible` | Toggle pet `Transparency` and disable collisions while invisible. |
| `speed_boost` | Pet `Humanoid.WalkSpeed += 10` (stacks once; toggle off resets). |
| `pull_out_all` | Spawn N clones (`PetConfig.PullOutAllCount`, default 5) of owner's pet around them; clones are cosmetic, no DataStore. |
| `steal_all` | Calls `PetService:TransferAge` against every pet within `PetConfig.StealAllRadius` (default 60 studs), respecting per-victim cooldown. |

## Remotes
- `Remotes.DoAdminAbility(abilityId)` — server checks `hasAdmin` first.

## Implementation target
`src/StarterPlayer/StarterPlayerScripts/UI/AdminPanel.lua`
+ server: `src/ServerScriptService/AdminService.lua`
