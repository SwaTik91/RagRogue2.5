# Ludo AI media drop points

Store art is produced via **Ludo.ai**. Do not generate it in-repo until asked. Do not use official Ragnarok trademarks, logos, or copyrighted character designs.

Briefs: [`docs/store/ludo-ai-briefs.md`](../../docs/store/ludo-ai-briefs.md) (copied from spec §7).

## Drop targets

| Asset | Drop here | Notes |
|--------|-----------|--------|
| Icon | `assets/branding/icon.png` | Mage portrait; brand face. Readable at small size. |
| Shot 1 | `assets/screenshots/shot-1.png` | Mage on dungeon floor, virtual stick, auto-combat VFX — 1-second hook |
| Shot 2 | `assets/screenshots/shot-2.png` | Three heroes / class select (Swordman, Mage, Archer) |
| Shot 3 | `assets/screenshots/shot-3.png` | Loot / equip screen with N/R/SR gear |
| Optional video | `assets/screenshots/combat-loop.mp4` | Short landscape combat loop (movement + auto skills) |

`assets/branding/` and `assets/screenshots/` are empty until a drop lands. Album (landscape) orientation only. Real gameplay framing. No competitor store logos.

## Integration hook (project icon)

When `assets/branding/icon.png` exists, set in `project.godot` under `[application]`:

```ini
config/icon="res://assets/branding/icon.png"
```

Do not enable that line while the file is missing (Godot will warn). Android launcher icons in `export_presets.cfg` stay empty until a sized 192 / adaptive 432 pack is derived from the same icon.
