# Progress — My Pet Tung Tung Tung Sahur

Live status log for the Roblox reskin of *My Pet Rock*. Update this file at the end of every working session: tick off what landed, note blockers, and write the next concrete step so the next session can pick up cold.

Plan reference: [PLAN.md](PLAN.md)
Onboarding for new contributors / future Claude sessions: [ONBOARDING.md](ONBOARDING.md)

---

## Status snapshot

- **Current phase:** Phase G — awaiting Tung Tung Tung Sahur mesh asset ID
- **Last updated:** 2026-05-15
- **Verified in Studio:** Phase B (Chi Chai pet spawning, age ticking, persistence). Phases C–F not yet verified; sync and playtest.
- **Phase G remaining step (user action):** find a Tung Tung Tung Sahur model on the Roblox Toolbox (Studio → Toolbox → Models → search "Tung Tung Tung Sahur"). Insert it into Workspace, right-click the MeshPart → Save to Roblox → copy the asset ID. Paste it into `src/ReplicatedStorage/Shared/PetConfig.lua` as `PetMeshId = "rbxassetid://<id>"`. Optional: same for texture. The pet swaps automatically next time you press Play.
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
- [x] **Phase C — Right-side menu (6 tiles)** ✅
- [x] **Phase D — Customization panels (Faces / Name+Color+Hide / Hats)** ✅
- [x] **Phase E — Actions (Walk + Carry) + Steal Time** ✅
  - [x] WALK (PathfindingService follow)
  - [x] CARRY (WeldConstraint to RightHand, humanoid disabled)
  - [x] **Steal Time** via ProximityPrompt on each pet → `ActionService.tryTransfer` with per-victim cooldown, offline-victim support via `applyAgeDeltaOffline`
- [x] **Phase F — Admin pack** ✅
  - [x] `ProcessReceipt` for `AdminProductId` grants persistent `hasAdmin`
  - [x] Invisible / +10 Speed / Pull Out All / **Steal All…** (AOE wrapper)
- [ ] **Phase G — Tung Tung Tung Sahur theming pass**
  - [x] Tool renamed to "Tung Tung Tung Sahur"
  - [x] Name modal title says "Name Your Tung Tung Tung Sahur!"
  - [x] `PetService` auto-uses MeshPart when `PetMeshId` is filled in, falls back to Slate placeholder otherwise
  - [ ] **You:** find a Tung Tung Tung Sahur model on Roblox Toolbox, copy its asset ID into `PetConfig.PetMeshId`

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
- Phase B.5 + name-modal-every-join pushed.
- **Phases C–F + most of G landed in one block:**
  - C: `PanelController`, `PanelBase`, `PetMenu.client.lua` (6 right-side tiles with single-open behavior + active highlight).
  - D: `FacesPanel`, `NameColorPanel` (with HIDE toggle), `HatsPanel`. Server `PetService` now handles `SetColor`/`SetFace`/`SetHat`/`ToggleHideName` with Catalog validation.
  - E: `ActionService.server.lua` — Walk (PathfindingService), Carry (WeldConstraint), Steal Time via ProximityPrompt on every pet, offline-victim support, per-victim cooldown. `ActionsPanel.client.lua`. Pet model now has Humanoid + HumanoidRootPart + StealPrompt.
  - F: `AdminService.server.lua` — `ProcessReceipt` for `AdminProductId`, four abilities (Invisible / SpeedBoost / PullOutAll / StealAll). `AdminPanel.client.lua` fires `DoAdminAbility`; server prompts purchase if not owned.
  - G partial: tool renamed, modal title themed, `buildPlaceholderModel` switches to MeshPart automatically when `PetConfig.PetMeshId` is set.
- Next: user uploads/finds Tung mesh ID → 1-line PetConfig edit → done.
