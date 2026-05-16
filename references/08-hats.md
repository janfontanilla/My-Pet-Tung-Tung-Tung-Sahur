# Reference 08 — Hats Panel

## Layout
- Header banner "HATS".
- Vertical `ScrollingFrame`, 2-column grid of ImageButtons of rocks wearing each hat.

## Catalog (Catalog.Hats) — ~14 entries
1. `none` — no hat (used to remove)
2. `cowboy`
3. `santa`
4. `viking`
5. `red_cap`
6. `glasses_3d`
7. `shutter_shades`
8. `pirate`
9. `crown`
10. `headphones`
11. `nerd_glasses`
12. `burger`
13. `ny_cap`
14. `banana`

Each entry: `{ id, name, accessoryAssetId, attachmentOffset = CFrame.new(0, height, 0) }`.

## Behavior
- Click → `Remotes.SetHat:FireServer(hatId)`.
- Server validates id, clears existing `Accessory` under the pet, clones the new accessory from `Assets/Hats/<id>` to the pet model at `HatAttachment`.

## Implementation target
`src/StarterPlayer/StarterPlayerScripts/UI/HatsPanel.lua`
