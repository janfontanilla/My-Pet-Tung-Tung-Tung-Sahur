# Reference 05 — Name + Color Panel

## Layout
- White rounded TextBox at top, placeholder "Name…", for renaming.
- 2×5 grid of colored swatch buttons (rounded squares):
  - Row 1: white, yellow, orange, red, purple
  - Row 2: pink, cyan, blue, green, gray
- Right side: large "HIDE" toggle button (eye-slash icon) — toggles owner-name + Age billboard visibility.

## Catalog (Catalog.Colors)
```
white   Color3.fromRGB(255, 255, 255)
yellow  Color3.fromRGB(255, 220, 60)
orange  Color3.fromRGB(255, 140, 30)
red     Color3.fromRGB(230, 50, 50)
purple  Color3.fromRGB(170, 110, 220)
pink    Color3.fromRGB(255, 110, 220)
cyan    Color3.fromRGB(70, 190, 255)
blue    Color3.fromRGB(40, 90, 230)
green   Color3.fromRGB(70, 210, 80)
gray    Color3.fromRGB(110, 110, 110)
```

## Remotes
- `Remotes.SetName(name)` — server filters via `TextService:FilterStringAsync`.
- `Remotes.SetColor(colorId)` — server validates id, applies tint to pet mesh.
- `Remotes.ToggleHideName()` — server flips `hideName` flag; client mirrors `BillboardGui.Enabled`.

## Implementation target
`src/StarterPlayer/StarterPlayerScripts/UI/NameColorPanel.lua`
