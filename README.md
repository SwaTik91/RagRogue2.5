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

## Export Android (AppGallery)

Landscape APK for Huawei AppGallery (RU/CIS). Preset `Android` in `export_presets.cfg`.

| Field | Value |
|--------|--------|
| Package / unique name | `com.swatik.ragrogue` (change if the AGC publisher ID differs) |
| Orientation | Landscape — `project.godot` `[display] window/handheld/orientation=4` (`SCREEN_SENSOR_LANDSCAPE`) |
| Min SDK | Godot 4.3 default (`gradle_build/min_sdk` left empty) |
| Store drafts | `docs/store/listing-ru.md`, `docs/store/privacy-mvp.md` |

### Prerequisites

1. Godot **4.3** Android **export templates** at `~/.local/share/godot/export_templates/4.3.stable/` (Editor → Editor Settings is not enough; download templates for 4.3.stable).
2. **Android SDK** (command-line tools + platform-tools + a build-tools package). Point the editor at it: `export/android/android_sdk_path`.
3. Debug keystore (Godot can create one). Release/AppGallery upload needs your own upload keystore — do not commit it.

### Export debug APK

From the project root:

```bash
mkdir -p build
godot --headless --path . --export-debug Android build/ragrogue-debug.apk
```

`*.apk` / `*.aab` are gitignored.

### Blocker in this environment (2026-08-21)

A debug APK **cannot** be produced on this Cloud Agent VM. Headless export was attempted and failed (`EXIT:1`) with Godot’s own checklist:

```text
godot --headless --path . --export-debug Android /tmp/ragrogue-export/ragrogue-debug.apk

ERROR: Cannot export project with preset "Android" due to configuration errors:
No export template found at the expected path:
/home/ubuntu/.local/share/godot/export_templates/4.3.stable/android_debug.apk
No export template found at the expected path:
/home/ubuntu/.local/share/godot/export_templates/4.3.stable/android_release.apk
Debug keystore not configured in the Editor Settings nor in the preset.
A valid Java SDK path is required in Editor Settings.
A valid Android SDK path is required in Editor Settings.
ERROR: Project export for preset "Android" failed.
```

`ANDROID_HOME` / `ANDROID_SDK_ROOT` are unset; Editor Settings `export/android/android_sdk_path` and `export/android/java_sdk_path` are empty. `~/.local/share/godot/export_templates/` has no `4.3.stable` pack.

Install the 4.3.stable Android export templates, a JDK, and an Android SDK on a machine that has them; set the editor SDK paths and a debug keystore; then rerun the export command. This gap does not block the listing drafts or the preset file.

## Layout

- `scripts/domain/` — headless-testable game logic
- `scripts/app/` — autoloads (`GameSession`)
- `scripts/tests/` — headless runner and cases
- `scenes/` — Godot scenes
- `docs/store/` — AppGallery listing, privacy, and Ludo AI media briefs
- `assets/` — branding + screenshot drop points (`assets/placeholders/README.md`)
- `export_presets.cfg` — Android landscape export preset
