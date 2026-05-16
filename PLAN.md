# Plan: "My Pet Tung Tung Tung Sahur" — Roblox reskin of *My Pet Rock*

## Context

The user wants to build a Roblox game that is a feature-for-feature reskin of *My Pet Rock*, but where the pet is **Tung Tung Tung Sahur** (the Italian brainrot wooden-bat character) instead of a rock. They shared 8 screenshots of the reference game; this plan captures every UI/feature visible in those shots and lays out how to implement them in a fresh Roblox project at `c:\Users\janfo\OneDrive\Desktop\My Pet Tung Tung Tung Sahur`.

The folder is currently empty. Target platform is Roblox (Luau), full feature parity including the paid Admin pack.

> Note on screenshots: I cannot write the original image bytes from the chat into the folder. Instead I will create `references/NN-<name>.md` text cards describing each screenshot, and the user can drag the actual PNGs into `references/` afterward.

---

## Screenshot-by-screenshot analysis

| # | Screen | Key elements |
|---|--------|---|
| 1 | **Name modal** (first spawn) | "Name Your Rock!" title, white text input ("Name…" placeholder), green "OK!" button. Modal-blocking; appears once per new pet. |
| 2 | **Main HUD** | Top-left: burger menu + chat icon + pet pill ("My Rock"). Right side vertical menu (6 entries, each with thumbnail): **Faces**, **Name**, **Color**, **Actions**, **Admin**, **Hats**. Pet has floating `Age: DD:HH:MM:SS` BillboardGui + owner username label. |
| 3 | **Pet close-up** | Big stone mesh with smiley face decal, Age timer (`107:22:30:12`), owner name. This is the model we replace with Tung Tung Tung Sahur. |
| 4 | **Faces panel** | Scrolling grid, ~14 faces: smile, blush, blue-eyed, clown/red-nose, anime pink-eyes, scared/open-mouth, doofy, wide-eyed shock, smug, evil, cat, wink-blush, tongue-out heart, pirate eyepatch. |
| 5 | **Name + Color panel** | Name text field re-edit, 2×5 color swatches (white, yellow, orange, red, purple / pink, cyan, blue, green, gray) + "HIDE" toggle (hides name billboard). |
| 6 | **Actions panel** | Two big tiles: **WALK** (pet follows owner) and **CARRY** (owner picks pet up). |
| 7 | **Admin panel (paywall)** | Items: **Invisible**, **+10 Speed**, **Pull Out All** (spawn clones), **Steal All…** (AOE version of the base Steal mechanic — drains Age from every nearby pet at once). Gated behind a Robux developer-product purchase ("ADMIN PACK — 9,999 R$"). |
| 8 | **Hats panel** | Scrolling grid of cosmetic hats: cowboy, santa, viking, red cap, 3D glasses, shutter shades, pirate, crown, headphones, nerd glasses, burger, NY cap, banana, … |

---

## Project structure (Rojo-style)

```
My Pet Tung Tung Tung Sahur/
├── default.project.json
├── README.md
├── references/
│   ├── 01-name-modal.md
│   ├── 02-main-hud.md
│   ├── 03-pet-closeup.md
│   ├── 04-faces.md
│   ├── 05-name-color.md
│   ├── 06-actions.md
│   ├── 07-admin.md
│   └── 08-hats.md
└── src/
    ├── ReplicatedStorage/
    │   ├── Shared/
    │   │   ├── Catalog.lua          -- face IDs, hat IDs, color list, dev-product IDs
    │   │   ├── Remotes.lua          -- RemoteEvent/Function definitions
    │   │   └── PetConfig.lua        -- model name, scale, walk speed, age tick rate
    │   └── Assets/
    │       ├── PetModel/            -- Tung Tung Tung Sahur rig (MeshPart + face Decal slot + Attachments for hats)
    │       ├── Faces/               -- 14 face image assets
    │       └── Hats/                -- ~14 hat accessories
    ├── ServerScriptService/
    │   ├── PetService.lua           -- spawn/despawn, persistence (DataStore), Age tracking
    │   ├── CustomizationService.lua -- name/color/face/hat handlers (validates + replicates)
    │   ├── ActionService.lua        -- Walk (pathfind to owner) / Carry (weld to owner)
    │   └── AdminService.lua         -- handles ProcessReceipt for Admin Pack dev-product, grants abilities
    └── StarterPlayer/
        └── StarterPlayerScripts/
            └── UI/
                ├── PetMenu.lua          -- right-side 6-button column
                ├── NameModal.lua        -- first-spawn name prompt
                ├── FacesPanel.lua
                ├── NameColorPanel.lua   -- includes HIDE toggle
                ├── ActionsPanel.lua     -- WALK / CARRY tiles
                ├── AdminPanel.lua       -- prompts MarketplaceService purchase if not owned
                └── HatsPanel.lua
```

`default.project.json` wires the four service folders so this can be synced with Rojo or pasted into Studio.

---

## Implementation plan (phased)

### Phase A — Project skeleton (no gameplay yet)
1. Create the folder tree above.
2. Write `default.project.json`, a short `README.md`, and the 8 `references/*.md` cards summarizing each screenshot.
3. Stub `Catalog.lua`, `Remotes.lua`, `PetConfig.lua` with the lists/IDs from the screenshots (10 colors, 14 face slots, 14 hat slots, 4 admin abilities).

### Phase B — Pet spawn + persistence (with offline-aging)
4. `PetService.lua`: on `PlayerAdded`, load DataStore key `pet_<userId>` → if first time, fire `RequestName` remote to client to show the name modal (screenshot #1). Persist `{name, color, faceId, hatId, bornAtUnix, bonusSeconds, hideName}`.
   - **Age is wall-clock and accrues offline.** `Age = (os.time() - bornAtUnix) + bonusSeconds`. `bonusSeconds` is the bucket that Steal-Time adds/subtracts (see Phase E.b) so we never have to rewrite `bornAtUnix`.
   - On `PlayerRemoving` and on autosave (every 60s), flush the record back to DataStore so a server crash never erases age.
5. Spawn `Assets.PetModel` near the player, parent to `workspace.Pets`. Attach `BillboardGui` with `Age: DD:HH:MM:SS` (driven by a single server `Heartbeat` loop that reads the live `os.time()` formula above), owner-name TextLabel, and clock icon.
6. Replace the rock MeshPart with a placeholder Tung Tung Tung Sahur mesh (asset ID to be filled in by user — leave a `TODO_TUNG_MESH_ID` constant in `PetConfig.lua`).

### Phase C — Right-side menu (screenshot #2)
7. `PetMenu.lua` builds a `ScreenGui` with a `UIListLayout` Frame on the right edge, 6 TextButton tiles (Faces / Name / Color / Actions / Admin / Hats) each with an `ImageLabel` thumbnail. Clicking a tile opens the matching panel and closes others.

### Phase D — Customization panels
8. **NameModal** (screenshot #1) — only on first spawn, blocks input until OK pressed; validates ≤20 chars, no profanity (Roblox `TextService:FilterStringAsync`), fires `SetName`.
9. **FacesPanel** (screenshot #4) — grid `ScrollingFrame`, one ImageButton per face in `Catalog.Faces`; click → `SetFace` remote → server updates `Decal.Texture` on pet head.
10. **NameColorPanel** (screenshot #5) — TextBox for rename + 2×5 color swatch grid + HIDE toggle button; remotes `SetName`, `SetColor`, `ToggleHideName`. Color tints the pet's `BodyColor` and tones the mesh.
11. **HatsPanel** (screenshot #8) — vertical scrolling list of hat ImageButtons; `SetHat` remote attaches the chosen `Accessory` to a `HatAttachment` on the pet.

### Phase E — Actions (screenshot #6) + Steal Time (core mechanic)
12. **ActionsPanel** with WALK and CARRY tiles.
13. `ActionService.Walk`: uses `PathfindingService` so the pet follows its owner at `PetConfig.WalkSpeed` until toggled off.
14. `ActionService.Carry`: welds the pet model to the owner's `RightHand` via a `Motor6D`, disables Humanoid movement on the pet; toggling again unwelds and drops.

**E.b — Steal Time (any player, not paywalled):**
15. While carrying or touching another player's pet, a `StealTime` prompt appears (ProximityPrompt, ~2s hold).
16. On completion, server runs `PetService:TransferAge(fromUserId, toUserId, seconds)`:
    - Reads both pet records; decrements victim's `bonusSeconds` by `seconds` (clamped so `Age >= 0`); increments attacker's `bonusSeconds` by the same amount.
    - `seconds` is config: `PetConfig.StealPerTick = 60` per successful steal, with a per-victim cooldown (`PetConfig.StealCooldown = 30s`) to prevent griefing loops.
    - **Server is the only authority.** Client only sends "I want to steal from userId X"; server validates proximity, cooldown, and that the victim's pet exists.
    - Works even if the victim is offline: their record is persisted in DataStore, so the server reads/writes via `UpdateAsync` on the victim's key (no live player object needed).
17. Floating "+1:00" / "-1:00" text shows above both pets when a steal lands (BillboardGui tween).
18. The Admin Pack's **Steal All…** button is the AOE version: calls `TransferAge` against every pet within `PetConfig.StealAllRadius` in one shot (still cooldown-gated per-victim).

### Phase F — Admin pack (screenshot #7)
15. Create a Roblox **Developer Product** "Admin Pack" (id stored in `Catalog.AdminProductId`).
16. `AdminPanel.lua`: if `AdminService:HasAdmin(player)` is false → clicking any ability calls `MarketplaceService:PromptProductPurchase`. If owned → ability buttons are active.
17. `AdminService.lua` implements `ProcessReceipt`, then provides: **Invisible** (toggle `LocalTransparencyModifier`/server transparency), **+10 Speed** (raise Humanoid.WalkSpeed), **Pull Out All** (spawn N clones of pet for the owner), **Steal All…** (re-parent other players' pets to caller — server-validated, owner-only on their own pet of course; for the reskin we mirror the source game's behavior).
18. **Important**: server must never trust the client for admin state — `HasAdmin` is the only gate.

### Phase G — Polish to match the brainrot theme
19. Replace pet mesh + sounds with Tung Tung Tung Sahur (wooden-bat character, signature "tung tung tung" SFX on Walk action).
20. Rename UI strings: "Name Your Rock!" → "Name Your Tung Tung Tung Sahur!", "My Rock" pill → "My Tung", etc.
21. Faces and Hats can keep the same slot count; just author Tung-shaped variants.

---

## Critical files to create

- `c:\Users\janfo\OneDrive\Desktop\My Pet Tung Tung Tung Sahur\default.project.json`
- `…\src\ReplicatedStorage\Shared\Catalog.lua` — single source of truth for colors/faces/hats/dev-product IDs
- `…\src\ReplicatedStorage\Shared\Remotes.lua` — `SetName`, `SetColor`, `SetFace`, `SetHat`, `ToggleHideName`, `DoAction`, `RequestName`
- `…\src\ServerScriptService\PetService.lua` — spawn + DataStore + Age timer
- `…\src\ServerScriptService\AdminService.lua` — ProcessReceipt + ability impls
- `…\src\StarterPlayer\StarterPlayerScripts\UI\PetMenu.lua` — right-side column
- `…\references\01..08-*.md` — screenshot reference cards

No existing utilities to reuse (empty project).

---

## Verification

End-to-end smoke test after Phase B–E land:
1. Open the project in Roblox Studio (or Rojo-sync), press Play.
2. Confirm first-spawn modal appears → enter "Testy" → OK → pet spawns with that name floating above it and Age starts ticking from 00:00:00:00.
2b. **Offline-age check:** rejoin 5 minutes later → Age reads ≈00:00:05:00 (not 00:00:00:00). Stop the server entirely, wait 2 min, start it back up → Age has advanced by the full elapsed wall time.
2c. **Steal-time check:** with two test clients, have player B hold the Steal prompt on player A's pet → A's Age drops by 60s, B's Age rises by 60s, cooldown blocks an immediate second steal, and the values survive a rejoin of either player.
3. Click each of the 6 right-side tiles in turn:
   - **Faces**: pick 3 different faces, confirm decal swaps and persists across rejoin.
   - **Name**: rename to "Renamed", confirm billboard updates; toggle HIDE, confirm billboard hides.
   - **Color**: click each of the 10 swatches, confirm tint changes.
   - **Actions**: WALK — walk around the map, pet follows; CARRY — pet welds to right hand, drops on toggle.
   - **Hats**: pick 3 hats, confirm attachment + persistence.
4. **Admin**: as a test user without the product, click "Invisible" → Robux purchase prompt appears. Use Studio's "Test Purchase" to grant → abilities become usable, and `ProcessReceipt` is exercised.
5. Rejoin the place — name, color, face, hat, hide-state, accumulated age, and admin-ownership all persist.
6. Run a second client — confirm pets are visible to other players and Age is per-pet.

Automated checks (optional): a small `TestEZ` spec for `Catalog.lua` (counts: 10 colors, 14 faces, 14 hats, 4 admin abilities) and for `AdminService.HasAdmin` returning false until ProcessReceipt fires.
