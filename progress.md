# Progress — My Pet Tung Tung Tung Sahur

Live status log for the Roblox reskin of *My Pet Rock*. Update this file at the end of every working session: tick off what landed, note blockers, and write the next concrete step so the next session can pick up cold.

Plan reference: [PLAN.md](PLAN.md)
Onboarding for new contributors / future Claude sessions: [ONBOARDING.md](ONBOARDING.md)

---

## Status snapshot

- **Current phase:** Phase C — Right-side 6-tile PetMenu UI
- **Last updated:** 2026-05-15
- **Verified in Studio:** Phase B works end-to-end. Pet "Chi Chai" spawned, age timer ticking.
- **Phase B.5 (in this commit):** pet is now a hotbar Tool ("Pet"). Press 1 to equip → pet spawns. Unequip → pet despawns. Age (wall-clock) keeps ticking regardless.
- **Next action:** Build `PetMenu.client.lua` (the right-edge column with Faces / Name / Color / Actions / Admin / Hats tiles + the single-panel-open controller).
- **GitHub:** https://github.com/janfontanilla/My-Pet-Tung-Tung-Tung-Sahur — push at end of every phase.
- **Map:** Suburban Streets preset. Create the place via Studio → File → New → Suburban Streets → Save to Roblox As… "My Pet Tung Tung Tung Sahur". Rojo's `default.project.json` uses `$ignoreUnknownInstances` so syncing won't disturb the map.

## Phase checklist

- [x] **Phase A — Project skeleton** ✅ committed `9ebf837`, pushed to `origin/main`
  - [x] Create folder on Desktop
  - [x] Copy PLAN.md into project
  - [x] Create progress.md + ONBOARDING.md
  - [x] Write `default.project.json`
  - [x] Create `src/` tree (ReplicatedStorage, ServerScriptService, StarterPlayer)
  - [x] Write 8 `references/NN-*.md` screenshot cards + 6 PNGs under `references/screenshots/`
  - [x] Stub `Catalog.lua`, `Remotes.lua`, `PetConfig.lua`
  - [x] `.gitignore` + git init + GitHub remote set up
- [x] **Phase B — Pet spawn + persistence (with offline aging)**
  - [x] `PetService.server.lua` with DataStore + first-spawn name flow
  - [x] Wall-clock Age: `Age = (os.time() - bornAtUnix) + bonusSeconds` — accrues while offline
  - [x] Autosave loop (60s) + `BindToClose` flush + `PlayerRemoving` flush
  - [x] Age `BillboardGui` ticking via Heartbeat (1Hz)
  - [x] Placeholder pet model (gray Slate Part) until Tung mesh ID is uploaded
  - [x] `NameModal.client.lua` — first-spawn popup
  - [x] `SetName` remote + `GetPetState` remote-function
  - [x] `applyAgeDeltaOffline` helper (used by Phase E.b Steal Time on offline victims)
- [ ] **Phase C — Right-side menu (6 tiles)**
- [ ] **Phase D — Customization panels (Faces / Name+Color+Hide / Hats)**
- [ ] **Phase E — Actions (Walk + Carry) + Steal Time**
  - [ ] WALK (pathfind follow)
  - [ ] CARRY (Motor6D weld to RightHand)
  - [ ] **Steal Time** core mechanic: ProximityPrompt on other players' pets → transfers `StealPerTick` seconds via server-authoritative `PetService:TransferAge`, with per-victim cooldown, works even on offline victims via DataStore `UpdateAsync`
- [ ] **Phase F — Admin pack (paywall + 4 abilities)**
  - [ ] Invisible / +10 Speed / Pull Out All / **Steal All…** (AOE wrapper around `TransferAge`)
- [ ] **Phase G — Tung Tung Tung Sahur theming pass**

## Open questions / blockers

- Roblox asset IDs for the Tung Tung Tung Sahur mesh, face decals, and hat accessories — user needs to upload these and paste IDs into `Catalog.lua`.
- Developer Product ID for the Admin Pack — created via Studio after the place is published.

## Session log

### 2026-05-15
- Approved PLAN.md.
- Copied plan into project folder; created progress.md and ONBOARDING.md.
- Added two mechanics to the spec: **wall-clock offline aging** (pet keeps aging while server/owner is offline) and **Steal Time** (any player can drain seconds from another player's pet; the Admin "Steal All…" button is the AOE version). Re-synced PLAN.md.
- Phase A scaffold landed (commit `9ebf837`, pushed). 27 files: project descriptor, plan docs, 8 reference cards + 6 PNGs, three shared Lua modules.
- Decided to use the **Suburban Streets** Studio template as the map. Switched `default.project.json` to `$ignoreUnknownInstances` on Workspace/ServerStorage/StarterGui so Rojo won't fight the template's contents.
- Phase B landed: `PetService.server.lua` (DataStore load/save, autosave, offline aging via `bornAtUnix + bonusSeconds`, `applyAgeDeltaOffline` for offline-victim steals, placeholder pet model + Age billboard ticking once per second) and `NameModal.client.lua` (first-spawn popup wired to `RequestName` / `SetName`).
- Next: Phase C — `PetMenu.client.lua` (right-side 6-tile column with single-panel-open controller).
