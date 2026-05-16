# Onboarding — My Pet Tung Tung Tung Sahur

Welcome. This doc gets a new contributor (human or AI) productive in ~5 minutes.

## What this project is

A Roblox experience that reskins the popular game *My Pet Rock* so the pet is **Tung Tung Tung Sahur** (the Italian brainrot wooden-bat character).

As of 2026-05-15 it's a playable game on the user's Roblox account. The 6 phases of PLAN.md all shipped. What's left is asset-import grunt work and a few optional polish items — see [progress.md](progress.md) for the current state.

GitHub: https://github.com/janfontanilla/My-Pet-Tung-Tung-Tung-Sahur

## Where things are

- **[PLAN.md](PLAN.md)** — the original implementation plan. Source of truth for *intent*; some details (Faces, Name tile, HIDE button) were dropped after the plan was approved. See progress.md for what actually shipped.
- **[progress.md](progress.md)** — running status log. **Read this first.** It tells you what was decided, what works, what's blocked.
- **`references/`** — markdown cards + 6 PNGs describing the reference *My Pet Rock* screenshots.
- **`default.project.json`** — Rojo project descriptor. Uses `$ignoreUnknownInstances` on Workspace/ServerStorage/StarterGui so Rojo doesn't fight the Suburban Streets template.
- **`src/`** — Rojo-style source tree.

## Project shape (current)

```
src/
├── ReplicatedStorage/
│   ├── Shared/
│   │   ├── Catalog.lua      — colors (10), faces (14, unused), hats (12 wired + 5 placeholder),
│   │   │                       admin abilities (4), AdminProductId (TODO)
│   │   ├── PetConfig.lua    — pet mesh id (138151705692565), spawn offset, walk speed,
│   │   │                       steal-time tuning, etc.
│   │   └── Remotes.lua      — lazy event/function bootstrap
│   └── Assets/
│       └── Hats/            — Toolbox hat models live here, renamed to catalog ids
│                              (chef imported; rest TODO)
├── ServerScriptService/
│   ├── PetService.server.lua        — DataStore + Tool + spawn + visuals + age billboard
│   ├── ActionService.server.lua     — walk (LinearVelocity), carry (Motor6D), steal time
│   └── AdminService.server.lua      — ProcessReceipt, four admin abilities
└── StarterPlayer/StarterPlayerScripts/
    ├── HideOwnStealPrompt.client.lua — disables your own pet's steal prompt
    └── UI/
        ├── PanelController.lua      — pub/sub for single-panel-open behavior
        ├── PanelBase.lua            — shared panel builder
        ├── PetMenu.client.lua       — right-side 4-tile menu (Color / Actions / Admin / Hats)
        ├── NameModal.client.lua     — first-join naming popup
        ├── NameColorPanel.client.lua — Color panel (Name was removed; file kept name)
        ├── ActionsPanel.client.lua  — WALK / CARRY tiles
        ├── AdminPanel.client.lua    — four ability tiles
        └── HatsPanel.client.lua     — hat grid with rbxthumb thumbnails
```

## How to develop

1. **Install Rojo** (the user has it already).
2. From the project folder: `rojo serve`
3. In Studio: with the user's "My Pet Tung Tung Tung Sahur" place open, click the Rojo plugin → **Connect**. Files on disk hot-sync into Studio.
4. **Window → Explorer** to see the live tree. Window → Output for runtime warnings.
5. Press **Play** to test.

## Important Studio menus (Studio's UI changed recently)

- **Game Settings** lives under `File → Game Settings…` (not the ribbon).
- **Explorer / Properties / Output / Toolbox** toggles are under the top-bar **Window** menu (NOT the View tab in the ribbon).
- **Studio API access** must be enabled (Game Settings → Security) for DataStores to work in playtests. The user has done this.

## Core mechanics worth knowing

- **Age is wall-clock and offline-accruing.** `Age = (os.time() - bornAtUnix) + bonusSeconds`. `bornAtUnix` is set once at first spawn; only `bonusSeconds` mutates (used by Steal Time). We never run "tick + save" loops that could lose time.
- **Steal Time** is a core PvP mechanic, not paywalled. ProximityPrompt on every pet body. Server-authoritative `ActionService.tryTransfer`. Per-victim cooldown. Works on offline victims via `PetService.applyAgeDeltaOffline` (DataStore `UpdateAsync`).
- The Admin Pack's **Steal All…** is just the AOE version of `tryTransfer` — same code path, broader target set.
- **Pet is a hotbar Tool.** Equip = spawn + auto-walk. Unequip = despawn. Age keeps ticking regardless.
- **Tung is a single MeshPart, not a rig.** Locomotion uses `LinearVelocity` + `AlignOrientation`, not a Humanoid. Stepping animation is a CFrame oscillation (nod/sway). Don't try to play keyframe animations on him.
- **Color tinting** uses a `Highlight` instance, not `BasePart.Color`, because the Tung MeshPart has a TextureID that overrides Color.
- **Cross-server-script wiring** uses `_G.PetService` and `_G.ActionService` because `.server.lua` files become Scripts (not ModuleScripts) and can't be required.

## How hats work

Hats live in `ReplicatedStorage.Assets.Hats.<catalog_id>` as imported Toolbox models. `PetService:applyVisuals` looks up the template by the pet record's `hatId`, finds the first MeshPart inside, clones + welds it to the pet's `HatAttachment`.

We tried `InsertService:LoadAsset` first but it throws "User is not authorized to access Asset" for most Toolbox tiles, because the user doesn't own those uploads. Importing them into the place file is the workaround — once imported, they replicate to every joining player, no auth check.

To add a hat:
1. Window → Explorer, expand `ReplicatedStorage.Assets.Hats`, click the folder.
2. Toolbox → search for the hat → click the tile.
3. Find the inserted model in Workspace, drag it into `Hats`.
4. Right-click → Rename → exact catalog id (`top_hat`, `cowboy`, etc).
5. Ctrl+S to persist into the place file.

The catalog id list is in `Catalog.Hats` in `src/ReplicatedStorage/Shared/Catalog.lua`.

## Required external setup (one-time, what user has and hasn't done)

✅ Done:
- Place created from Suburban Streets template, saved as "My Pet Tung Tung Tung Sahur".
- Studio API access enabled.
- Pet mesh asset id wired (`PetConfig.PetMeshId = "rbxassetid://138151705692565"`).
- 12 hat catalog entries with asset ids.
- One hat (Chef) imported into `ReplicatedStorage.Assets.Hats.chef`.

❌ TODO:
- Import remaining 11 hats (see progress.md for the rename map).
- Create the Admin Pack Developer Product in `File → Game Settings → Monetization → Developer Products`, paste its product id into `Catalog.AdminProductId`.
- Publish the place if friends should be able to join.

## Conventions

- All client→server traffic goes through `RemoteEvent`s defined in `Remotes.lua`. Never trust client-supplied state on the server — always validate against `Catalog`.
- Server is the only authority for: name, color, hat, hide-state, walk/carry mode, admin ownership, age changes.
- `Catalog.lua` is the single source of truth for every list. Adding an item = edit `Catalog.lua` + drop the asset into `Assets/`.
- One LocalScript per right-side panel. They all listen to `PanelController` so opening one closes the others.
- Studio's File → Open should open the place; never start a new Baseplate or you'll lose the map.

## Working with Claude on this repo

- Start each session by reading `progress.md` first — it tells you the current state and tomorrow's next action.
- Commit and push at the end of each meaningful change. **The user explicitly asked: commit after every phase.** Use `git push origin main`.
- progress.md gets updated at end-of-session with what landed + what's next.
- PLAN.md is the *historical* contract. progress.md is what's *actually* shipped. If they disagree, trust progress.md and update PLAN.md to match if it matters.
- The user types Roblox asset IDs in chat one at a time. 9–12 digits are valid asset IDs. 14–15 digit numbers are usually catalog IDs that `InsertService` can't load.
- When asked to do Studio-side work (insert from Toolbox, click menus, drag in Explorer), Claude cannot do this remotely. Walk the user through with explicit step-by-step instructions and screenshots if available.

## Useful links

- Roblox Luau docs: https://create.roblox.com/docs
- Rojo docs: https://rojo.space/docs/
- Reference *My Pet Rock* on Roblox (search the catalog).

## First task for a fresh session

Read `progress.md` → check the **Tomorrow's next action** line → do that. If unclear, ask the user before scaffolding new files.
