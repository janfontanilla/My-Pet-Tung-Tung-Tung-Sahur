# Progress — My Pet Tung Tung Tung Sahur

Live status log for the Roblox reskin of *My Pet Rock*. Update this file at the end of every working session: tick off what landed, note blockers, and write the next concrete step so the next session can pick up cold.

Plan reference: [PLAN.md](PLAN.md)
Onboarding for new contributors / future Claude sessions: [ONBOARDING.md](ONBOARDING.md)

---

## Status snapshot

- **Current phase:** Phase A — Project skeleton
- **Last updated:** 2026-05-15
- **Next action:** Scaffold `default.project.json`, `src/` tree, and the 8 `references/*.md` cards.

## Phase checklist

- [ ] **Phase A — Project skeleton**
  - [x] Create folder on Desktop
  - [x] Copy PLAN.md into project
  - [x] Create progress.md + ONBOARDING.md
  - [ ] Write `default.project.json`
  - [ ] Create `src/` tree (ReplicatedStorage, ServerScriptService, StarterPlayer)
  - [ ] Write 8 `references/NN-*.md` screenshot cards
  - [ ] Stub `Catalog.lua`, `Remotes.lua`, `PetConfig.lua`
- [ ] **Phase B — Pet spawn + persistence (with offline aging)**
  - [ ] `PetService.lua` with DataStore + first-spawn name flow
  - [ ] Wall-clock Age: `Age = (os.time() - bornAtUnix) + bonusSeconds` — accrues while offline
  - [ ] Autosave loop (60s) + flush on `PlayerRemoving`
  - [ ] Age `BillboardGui` ticking via Heartbeat
  - [ ] `TODO_TUNG_MESH_ID` placeholder wired
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
- Next: scaffold the source tree and screenshot reference cards.
