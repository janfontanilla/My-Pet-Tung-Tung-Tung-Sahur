# Reference 02 — Main HUD

## Layout
- **Top-left:**
  - Burger menu icon (Roblox default), chat icon, and a "My Rock" pill button showing the pet's name.
  - In our reskin: pet pill shows owner-defined name; default placeholder "My Tung".
- **World-space:**
  - Pet model in the road/sidewalk environment with a `BillboardGui` showing `Age: DD:HH:MM:SS` + clock icon, and the owner's username below.
- **Right side — vertical menu** (6 tiles, each ~150×150 with white cartoon label + thumbnail):
  1. **Faces >** — small rock with smile decal
  2. **Name >** — rock with pencil
  3. **Color >** — yellow + red rocks
  4. **Actions >** — player walking pet thumbnail
  5. **Admin >** — red-eyed demon rock
  6. **Hats >** — rock with party hat

## Behavior
- Tile click → opens corresponding panel and closes others (single-panel-at-a-time controller).
- Menu visible at all times except when the Name Modal is up.

## Implementation target
`src/StarterPlayer/StarterPlayerScripts/UI/PetMenu.lua`
