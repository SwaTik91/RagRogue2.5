# Ludo animation frames

Generated via `scripts/art/ludo_batch_animate.py` → Ludo `animateSprite` (**forge** model, **16** frames, 384px).

Layout: `{actor}/{animation}/frame_00.webp` … `frame_15.webp` + `sheet.webp` + `ludo_meta.json`

Actors: `mage`, `swordman`, `archer`, `cave_slime`, `stone_beetle`, `vault_warden`

Animations: `idle`, `walk`, `attack`; heroes also `skill`.

Motion prompts emphasize leg cycles on walk and arm/weapon motion on attack.

Wired in Godot via `SpriteFramesFactory` (normalized frame canvas, no runtime `get_image()` baking).

Regenerate: `python3 scripts/art/ludo_batch_animate.py swordman --force --backup`
