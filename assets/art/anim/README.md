# Ludo animation frames (4-way top-down)

Generated via `scripts/art/ludo_batch_animate.py` → Ludo `animateSprite` (**forge**, **16** frames).

## Layout (directional)

```
assets/art/anim/{actor}/{facing}/{anim}/frame_00.webp … frame_15.webp
```

- **facing:** `down` (к камере), `up` (спиной), `right`, `left`
- **anim:** `idle`, `walk`, `attack`; герои также `skill`

Godot animation names: `walk_down`, `attack_left`, `idle_up`, …

## Legacy flat folders (`{actor}/walk/`) still load as `walk_down` only.

Regenerate swordman all directions:

```bash
python3 scripts/art/ludo_batch_animate.py swordman --force --backup --workers 1
```

All heroes:

```bash
python3 scripts/art/ludo_batch_animate.py mage swordman archer --force --backup --workers 1
```
