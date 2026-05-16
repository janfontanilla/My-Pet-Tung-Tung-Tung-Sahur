# Reference 01 — Name Modal (first spawn)

**When shown:** once, on the player's first ever spawn (`PetService` detects no DataStore record).

## Layout
- Full-screen dimmed background (ModalEnabled = true).
- Centered title: **"Name Your Rock!"** → in our reskin: **"Name Your Tung Tung Tung Sahur!"**
  - Cartoon white text with thick black stroke, bold/round font.
- White rounded TextBox below, placeholder text "Name…" (light gray).
- Green rounded button with bold white "OK!" label + hand-pointer cursor icon.

## Behavior
- Blocks gameplay until OK is pressed.
- Validation: 1–20 chars, run through `TextService:FilterStringAsync`.
- Pressing OK fires `Remotes.SetName` then closes the modal.

## Implementation target
`src/StarterPlayer/StarterPlayerScripts/UI/NameModal.lua`
