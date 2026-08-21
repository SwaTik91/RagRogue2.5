# RagRogue

Landscape action-rogue for Huawei AppGallery (RU/CIS). Built with Godot 4.3.

## Requirements

- Godot 4.3 stable (`godot` on `PATH`)

## Run the game

Open `project.godot` in the Godot 4.3 editor, or from the project root:

```bash
godot --path .
```

The current main scene is `scenes/boot.tscn` (a placeholder until the hub lands).

## Run tests

From the project root:

```bash
godot --headless -s res://scripts/tests/run_tests.gd
```

Exit code `0` means every registered test passed.

If `class_name` types such as `ClassId` are not found (fresh machine without `.godot/global_script_class_cache.cfg`), import once, then rerun tests:

```bash
godot --headless --path . --import
godot --headless -s res://scripts/tests/run_tests.gd
```

## Layout

- `scripts/domain/` — headless-testable game logic
- `scripts/app/` — autoloads (`GameSession`)
- `scripts/tests/` — headless runner and cases
- `scenes/` — Godot scenes
