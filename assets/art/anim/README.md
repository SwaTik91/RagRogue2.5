# Ludo animation frames

Generated via `scripts/art/ludo_batch_animate.py` → Ludo `animateSprite` (Eagle model, 9 frames).

Layout: `{actor}/{animation}/frame_00.webp` … `frame_08.webp` + `sheet.webp` + `ludo_meta.json`

Actors: `mage`, `swordman`, `archer`, `cave_slime`, `stone_beetle`, `vault_warden`

Animations: `idle`, `walk`, `attack`; heroes also `skill`.

Wired in Godot via `SpriteFramesFactory` (no runtime `get_image()` baking).
