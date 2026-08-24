# Archer 3D (Ludo)

Generated via `scripts/art/ludo_archer_3d_batch.py`:

1. `create3DModel` from `assets/art/game/archer-idle.png`
2. `rigModel` (humanoid_template_hands)
3. `animate3DModelPreset` per move

| File | Ludo preset |
|------|-------------|
| `anims/idle.glb` | idle_combat |
| `anims/walk.glb` | walk_forward (in_place, loop) |
| `anims/attack.glb` | Ludo `animate3DModel` — Drawn Bow (string to cheek) |
| `anims/skill.glb` | bow_shot_sky |
| `anims/hit.glb` | hit_front_heavy |

Runtime: `scenes/dungeon/archer_ludo_visual_3d.tscn` (hub → pick Archer).
