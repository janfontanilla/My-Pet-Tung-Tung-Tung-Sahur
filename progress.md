# Progress — My Pet Tung Tung Tung Sahur

Live status log for the Roblox reskin of *My Pet Rock*. Update this file at the end of every working session: tick off what landed, note blockers, and write the next concrete step so the next session can pick up cold.

Plan reference: [PLAN.md](PLAN.md)
Onboarding for new contributors / future Claude sessions: [ONBOARDING.md](ONBOARDING.md)
GitHub: https://github.com/janfontanilla/My-Pet-Tung-Tung-Tung-Sahur

---

## Status snapshot

- **Current phase:** Hat import + polish
- **Last updated:** 2026-05-15 (end of session)
- **Tomorrow's next action:** in Studio, import the remaining 11 hats into `ReplicatedStorage.Assets.Hats` (rename each one to the catalog id). Verify HatAttachment offset (`(0.3, body.Size.Y/2 - 0.4, 0)`) looks right on Chef; tweak in PetService if not.
- **Map:** Suburban Streets template, saved as "My Pet Tung Tung Tung Sahur" on the user's Roblox account.
- **Pet mesh:** Tung Tung Tung Sahur, asset id `138151705692565`, loaded via `InsertService:LoadAsset` (works because the user can load it — public/free).

## What's working in-game

- Hotbar Tool "Tung Tung Tung Sahur" (press 1 = spawn, press 1 again = despawn).
- Wall-clock age billboard above Tung; accrues offline; persists via DataStore key `pet_<userId>`.
- Name modal on every server join, prefilled with current name. **Note:** Name *tile* on the right-side menu was removed per user request, but the modal flow still fires on join. Server still handles `SetName` remote. Removing the modal too is a TODO if we don't want any naming at all.
- Right-side menu — **4 tiles** (Color / Actions / Admin / Hats). Single-panel-open behavior, active highlight.
- Color panel — 10 swatches. Tints Tung via a `Highlight` instance (semitransparent fill) since MeshPart.TextureID overrides Color. White swatch disables the tint.
- Actions panel — WALK auto-engages on equip; CARRY toggle.
- Walk: LinearVelocity + AlignOrientation drive Tung toward a "heel" position (2 right, 3 behind owner). Stepping animation (nod ~10°, sway ~6°) + step sound on each downbeat. Leash beam from owner's RightHand to Tung's head.
- Carry: Motor6D anchored to player's HumanoidRootPart (not RightHand — hand twists with animation). Sits 1.5 right of HRP, slightly above shoulder, facing forward.
- Steal Time: ProximityPrompt on every pet body. Owner's prompt is hidden client-side. Server-side ignores self-triggers. Per-victim cooldown. Offline-victim support via `applyAgeDeltaOffline` (DataStore UpdateAsync).
- Admin panel — clicking any ability prompts purchase if `hasAdmin` is false. ProcessReceipt sets `hasAdmin=true`. Four abilities: invisible, +10 speed, pull_out_all (5 clones), steal_all (AOE).

## What's NOT yet working / needs your action

- **Hats** — code complete. Currently only **Chef Hat** is imported into `ReplicatedStorage.Assets.Hats.chef`. Need to import the other 11 (top_hat, party_hat, cowboy, fedora, pirate, cone, chicken, king, money, ice_cream, squid).
  - Recipe: Window → Explorer; click `ReplicatedStorage.Assets.Hats` in Explorer; click hat tile in Toolbox; drag from Workspace to `Hats` folder if needed; right-click → Rename → exact catalog id; Ctrl+S.
- **HatAttachment offset** — Chef sits slightly left + a bit high. Latest commit nudges `+0.3` X and `-0.4` Y. Verify next session and tune further if needed.
- **Admin Pack purchase** — `Catalog.AdminProductId = 0`. Need to create the Developer Product in **File → Game Settings → Monetization → Developer Products → Create New** (Admin Pack, price 9999), then paste the product id into Catalog.
- **Steal Time visual feedback** — silent right now. Could add a floating "+1:00" / "-1:00" text tween above both pets when a steal lands.
- **Custom "tung tung tung" SFX** — currently using Roblox's `impact_water.mp3` placeholder. Find or upload a real tung-tung-tung sound and set `body.StepSound.SoundId` in PetService (or wherever it's created in ActionService.startWalk).
- **Publish for friends to play** — File → Publish to Roblox.

## Decisions made this session

- **Map**: Suburban Streets template (not Modern City / Village).
- **Pet summon model**: hotbar Tool, not auto-spawn on respawn. Equip = spawn, unequip = despawn. Age keeps ticking either way.
- **Name modal**: shows on every server join, prefilled. (Later: Name *tile* was removed from the right-side menu; the join-modal still fires. Open question for tomorrow: do we want any naming at all, or remove the modal too?)
- **Faces feature**: dropped entirely.
- **HIDE billboard button**: dropped.
- **Color tinting**: Highlight overlay (semitransparent fill) instead of BasePart.Color, because MeshPart.TextureID overrides Color.
- **Walk default**: WALK starts automatically when the tool is equipped (no need to open the Actions panel each spawn).
- **Hat loading**: prefer pre-imported templates in `ReplicatedStorage.Assets.Hats.<id>` over `InsertService:LoadAsset`, because Toolbox tiles are usually other people's uploads which fail with "User is not authorized to access Asset".

## Phase checklist

- [x] **Phase A — Project skeleton** ✅
- [x] **Phase B — Pet spawn + persistence + wall-clock offline age** ✅
- [x] **Phase B.5 — Hotbar Tool + name modal on every join** ✅
- [x] **Phase C — Right-side menu** ✅ (4 tiles after Faces and Name were dropped)
- [x] **Phase D — Customization panels** ✅ (Color + Hats; Faces dropped)
- [x] **Phase E — Actions + Steal Time** ✅
- [x] **Phase F — Admin pack** ✅ (code complete; needs Developer Product setup in Studio)
- [x] **Phase G — Tung mesh swap** ✅
- [x] **Polish — walk leash, carry pose, steal prompt hide, step animation, color highlight** ✅
- [ ] **Hat import** — Chef imported. 11 more to go.
- [ ] **Optional: Admin Pack product, custom SFX, steal visual feedback, publish**

## Session log

### 2026-05-15

Marathon session. Started with empty desktop folder, ended with a fully playable game on the user's account.

- Approved PLAN.md.
- Phase A: project skeleton, references, shared stubs (commit `9ebf837`).
- Phase B: PetService + DataStore + wall-clock offline aging + first-spawn name modal (commit `551af3d`).
- Phase B.5: pet became a hotbar Tool (`8fe7b9b`); name modal fires every join (`3a244f0`).
- Decision: Suburban Streets template, saved as the user's place.
- Phases C–F + most of G in one block (commit `ee81633`): right-side menu, Faces/NameColor/Hats/Actions/Admin panels, walk + carry + steal time, admin abilities.
- Phase G mesh wired (`fbaa0f8`); ran into NotAccessible capability error, switched to AssetService (`6f13119`), then realized user copied Asset ID (not Mesh ID) and switched to InsertService (`283b04c`). Mesh appeared.
- Polish: walk leash visual, carry-on-hand pose, hide own steal prompt (`187c3a3`).
- Locomotion swap: Tung is a single MeshPart not an R15 rig, so Humanoid.MoveTo was spinning him. Replaced with LinearVelocity + AlignOrientation. Auto-walk on equip. Carry uses Motor6D from HRP (`3511e66`).
- Step animation + footstep sound (`b2be880`); lowered spawn (`38496d7`).
- Hat attachment code + 9 hat asset IDs (`37010bf`). Tested Toolbox tile IDs — most worked, the 14–15 digit ones did not (those are catalog IDs, not asset IDs).
- 3 more hat IDs added (`acc9e14`).
- Hat thumbnails on buttons via `rbxthumb://`, carry refactored to use HRP, surfaced LoadAsset errors to Output (`8b92234`).
- Faces feature dropped (`92d2d02`).
- Discovered Toolbox-hat assets throw "User is not authorized to access Asset". Switched to template-first lookup (`ReplicatedStorage.Assets.Hats.<id>`) (`3f66840`).
- Name feature dropped, Color tint fixed via Highlight overlay, HIDE button dropped (`b5f16b3`, `cbc909c`).
- HatAttachment nudged to better fit Tung (`7af859b`).
- Chef Hat manually imported by user — appears on Tung's head, slightly off-center (user reports).
- **Stopped here.** 11 hats left to import. Other unfinished items: dev product setup, custom SFX, steal feedback, publish.

### 2026-05-16 (planned)

- Verify Chef Hat now sits correctly with the latest attachment nudge.
- Import the remaining 11 hats.
- Decide: keep name modal or remove it entirely.
- Stretch: Admin Pack dev product setup; custom tung SFX; steal feedback; publish.
