# RagRogue

Landscape action-rogue for Huawei AppGallery (RU/CIS). Built with Godot 4.3.

## Requirements

- Godot 4.3 stable (`godot` on `PATH`)

## Run the game

Open `project.godot` in the Godot 4.3 editor, or from the project root:

```bash
godot --path .
```

The current main scene is `scenes/main_menu/main_menu.tscn` (Играть / Герои / Настройки).

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
| Store drafts | `docs/store/listing-ru.md`, `docs/store/privacy-mvp.md`, `docs/store/appgallery-checklist.md` |

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

### Blocker in this environment (historical, 2026-08-21)

Early Cloud Agent VMs lacked export templates / Android SDK / JDK paths. Current setup uses Godot 4.3 templates under `~/.local/share/godot/export_templates/4.3.stable/`, JDK 17, and `$HOME/android-sdk`. See **Debug APK (cloud / CI)** below.

## Layout

- `scripts/domain/` — headless-testable game logic
- `scripts/app/` — autoloads (`GameSession`, `AppSettings`)
- `scripts/tests/` — headless runner and cases
- `scenes/` — Godot scenes (`main_menu`, `hub`, `settings`, `dungeon`)
- `docs/store/` — AppGallery listing, privacy, checklist, Ludo AI media briefs
- `assets/` — branding + screenshot drop points (`assets/placeholders/README.md`)
- `export_presets.cfg` — Android landscape export preset

## Debug APK (cloud / CI)

Prerequisites: Godot 4.3, export templates, Android SDK, **JDK 17** (not 21), ETC2/ASTC enabled in project.

```bash
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export ANDROID_HOME=$HOME/android-sdk
godot --headless --path . --install-android-build-template
mkdir -p build
godot --headless --path . --export-debug "Android" build/RagRogue-debug.apk
```

Package: `com.swatik.ragrogue`. APK is gitignored; successful builds may be copied to artifacts.
