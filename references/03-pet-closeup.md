# Reference 03 — Pet Close-up

## Layout
- Large stone MeshPart (rounded boulder shape) with a face Decal on the front face.
- BillboardGui above: bold cartoon text `Age: 107:22:30:12` + red clock icon. Format: `DD:HH:MM:SS`.
- Small owner username text (e.g. "xiaodd12") near the base.

## Reskin notes
- Replace mesh + texture with **Tung Tung Tung Sahur** (wooden-bat character).
  - Mesh asset ID → `PetConfig.PetMeshId` (TODO until uploaded).
  - Texture → `PetConfig.PetTextureId`.
- Face decal slot stays — just decals authored to fit the new mesh's "head" area.

## Age formatting
- `Age = (os.time() - bornAtUnix) + bonusSeconds`
- Format `DD:HH:MM:SS` zero-padded, capped at 999 days display-only (no game cap).
