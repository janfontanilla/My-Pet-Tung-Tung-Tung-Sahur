# Onboarding — My Pet Tung Tung Tung Sahur

Welcome. This doc gets a new contributor (human or AI) productive in ~5 minutes.

## What this project is

A Roblox experience that reskins the popular game *My Pet Rock* so the pet is **Tung Tung Tung Sahur** (the Italian brainrot wooden-bat character). It targets full feature parity with the reference game: pet naming, faces, name + colors, walk/carry actions, an Admin pack paywall, and hats.

Reference screenshots from the original game live in `references/` and are summarized in [PLAN.md](PLAN.md).

## Where things are

- **[PLAN.md](PLAN.md)** — the approved implementation plan. Source of truth for scope and structure.
- **[progress.md](progress.md)** — running status log. Update it every session.
- **`references/`** — one markdown card per reference screenshot (UI element inventory).
- **`src/`** — Rojo-style source tree:
  - `ReplicatedStorage/Shared/` — `Catalog.lua`, `Remotes.lua`, `PetConfig.lua`
  - `ReplicatedStorage/Assets/` — pet model, face decals, hat accessories
  - `ServerScriptService/` — `PetService`, `CustomizationService`, `ActionService`, `AdminService`
  - `StarterPlayer/StarterPlayerScripts/UI/` — one LocalScript per panel
- **`default.project.json`** — Rojo project descriptor.

## How to develop

1. Install [Rojo](https://rojo.space/) (`rojo` CLI + Roblox Studio plugin).
2. From the project root: `rojo serve`
3. In Studio: connect the Rojo plugin → start editing. Saves on disk hot-sync into Studio.
4. To test: press Play in Studio. The first spawn should show the **Name Your Tung Tung Tung Sahur!** modal.

If you don't use Rojo, you can paste each `.lua` file into the matching service folder in Studio manually — the tree mirrors Roblox's hierarchy.

## Required external setup (one-time)

These can't be done from code — the user has to do them in Studio / on the Roblox site:

0. **Create the place from the Suburban Streets template.** Roblox Studio → File → New → "Suburban Streets" → File → Save to Roblox As… → name it **"My Pet Tung Tung Tung Sahur"**. This is the map (roads, sidewalks, houses, pine trees) that matches the reference game's environment. The map lives on Roblox's servers; Rojo only syncs the scripts under `src/` into the existing services. `default.project.json` uses `$ignoreUnknownInstances` on Workspace/ServerStorage/StarterGui so the template's contents are safe from Rojo overwrites.
1. **Upload assets** and paste their IDs into `src/ReplicatedStorage/Shared/Catalog.lua`:
   - Tung Tung Tung Sahur mesh + texture
   - 14 face decals
   - ~14 hat accessory models
2. **Create a Developer Product** "Admin Pack" on the place; copy its product ID into `Catalog.AdminProductId`.
3. **Enable Studio API access** for DataStores (Game Settings → Security → "Enable Studio Access to API Services").

## Core mechanics worth knowing

- **Age is wall-clock and offline-accruing.** A pet's age is computed as `(os.time() - bornAtUnix) + bonusSeconds`. The pet keeps aging even when the owner is offline or the server is down — we never run a "tick + save" loop that could lose time. Only `bonusSeconds` is mutable (used by Steal Time); `bornAtUnix` is set once at first spawn.
- **Steal Time** is a core player-vs-player mechanic, not a paid feature. Any player can hold a `ProximityPrompt` on another player's pet to transfer `PetConfig.StealPerTick` seconds (default 60s) from victim to attacker. Server-authoritative via `PetService:TransferAge`. Per-victim cooldown prevents griefing. Works on offline victims by writing through `DataStore:UpdateAsync` on the victim's key.
- The Admin Pack's **Steal All…** is just the AOE version of `TransferAge` — same code path, broader target set.

## Conventions

- All client→server traffic goes through `RemoteEvent`s defined in `Remotes.lua`. Never trust client-supplied state on the server — always validate against `Catalog`.
- Server is the only authority for: name, color, face, hat, hide-state, walk/carry mode, admin ownership, and accumulated Age.
- `Catalog.lua` is the single source of truth for every list (colors, faces, hats, admin abilities, product IDs). Adding an item = edit `Catalog.lua` + drop the asset into `Assets/`.
- One LocalScript per right-side panel. They all listen to a shared `PanelController` event so opening one closes the others.

## Working with Claude on this repo

- Start each session by reading `progress.md` first — it tells you what phase we're in and what the next action is.
- After finishing a step, tick it off in `progress.md` and append a dated session-log entry.
- PLAN.md is the contract — don't redesign mid-implementation. If scope needs to change, propose an edit to PLAN.md and confirm before implementing.
- The user's name conventions: "Tung Tung Tung Sahur" (full) in UI titles; "Tung" is fine as a short-form in pills/labels.

## Useful links

- Reference game (My Pet Rock) — search Roblox catalog.
- Roblox Luau docs: https://create.roblox.com/docs
- Rojo docs: https://rojo.space/docs/

## First task for a fresh session

Open `progress.md`, read the **Next action**, and do that. If unclear, ask the user before scaffolding new files.
