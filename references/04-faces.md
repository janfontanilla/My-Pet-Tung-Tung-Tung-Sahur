# Reference 04 — Faces Panel

## Layout
- Header banner "FACES" (white text, green/yellow striped strip).
- Vertical `ScrollingFrame` with 2-column grid of ImageButtons (~14 visible).

## Catalog (Catalog.Faces)
1. `smile_basic` — classic black smile + dot eyes
2. `smile_blush` — smile with pink cheeks
3. `eyes_blue` — eyeshadow / blue lined eyes
4. `clown` — red nose + smile
5. `anime_pink` — sparkly pink anime eyes
6. `scared` — wide eyes, open mouth
7. `derp` — uneven big eyes, doofy smile
8. `shock` — huge round eyes, small mouth
9. `smug` — half-lid, smirk
10. `evil` — angry eyebrows, sharp grin
11. `cat` — cat eyes + whiskers
12. `wink_blush` — winking with blush
13. `tongue_heart` — tongue out + heart
14. `pirate` — eyepatch + smile

Each entry: `{ id, name, decalAssetId }`. Asset IDs TODO until decals uploaded.

## Behavior
- Click ImageButton → `Remotes.SetFace:FireServer(faceId)`.
- Server validates `faceId` exists in `Catalog.Faces`, updates pet record, replicates new `Decal.Texture` on the pet model's face attachment.

## Implementation target
`src/StarterPlayer/StarterPlayerScripts/UI/FacesPanel.lua`
