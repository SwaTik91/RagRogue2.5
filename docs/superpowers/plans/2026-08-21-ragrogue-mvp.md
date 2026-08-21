# RagRogue MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a playable Android-landscape MVP of RagRogue: three class heroes, hub → dungeon floors, manual move + auto combat, permanent level/gear, run-only upgrades, local save — ready for AppGallery RU/CIS packaging.

**Architecture:** Godot 4.3+ project. Pure domain logic lives in `scripts/domain/` (RefCounted, no Node deps) so it can be tested headless. Scenes under `scenes/` wire input, camera, UI, and spawn enemies. Content (skills, gear, monsters) is JSON under `data/`. Save file is `user://ragrogue_save.json`.

**Tech Stack:** Godot 4.3+, GDScript, JSON data files, headless `godot --headless -s` test runner, Android export (landscape), no monetization SDK in MVP.

## Global Constraints

- Spec: `docs/superpowers/specs/2026-08-21-ragrogue-design.md`
- Store name: RagRogue; markets: RU/CIS only; no mainland China
- Orientation: landscape only
- Control: player movement only; attacks + skills auto
- Permanent: level + gear; temporary: run upgrades
- Three hero slots: Swordman, Mage, Archer; brand face: Mage
- Save: local only in MVP; no login/cloud
- Monetization: out of scope (do not add ads/IAP)
- IP: original names for skills/monsters/items — do not use official Ragnarok trademarks as asset/IDs
- YAGNI: one dungeon act (3–5 floors + boss); no multiplayer/guilds/seasons/cutscenes

## File map (create)

```
project.godot
export_presets.cfg                 # Android landscape (later task)
scripts/
  domain/
    enums.gd                       # ClassId, Rarity, RoomType
    hero.gd                        # Hero state
    gear_item.gd                   # Gear definition + instance
    skill_def.gd                   # Skill definition
    combat_stats.gd                # ATK/DEF/HP helpers
    auto_combat.gd                 # Target + skill priority + tick
    run_state.gd                   # Floor, room, run modifiers
    floor_gen.gd                   # Room sequence for a floor
    save_game.gd                   # Load/save account + heroes
    reward_resolver.gd             # XP/loot on room clear / death / boss
  app/
    game_session.gd                # Autoload: current hero, run, save
  tests/
    run_tests.gd                   # Headless test entry
    test_auto_combat.gd
    test_save_game.gd
    test_floor_gen.gd
    test_reward_resolver.gd
    test_run_state.gd
scenes/
  boot.tscn
  hub/hub.tscn
  dungeon/dungeon.tscn
  dungeon/player.tscn
  dungeon/enemy.tscn
  ui/virtual_stick.tscn
  ui/upgrade_pick.tscn
data/
  skills.json
  gear.json
  monsters.json
  run_upgrades.json
docs/store/
  listing-ru.md                    # Store copy draft from spec
```

---

### Task 1: Godot project scaffold + headless test runner

**Files:**
- Create: `project.godot`
- Create: `scripts/tests/run_tests.gd`
- Create: `scripts/domain/enums.gd`
- Create: `README.md` (replace stub with run/test instructions)

**Interfaces:**
- Consumes: none
- Produces: runnable Godot project; `run_tests.gd` exits 0 if all registered tests pass

- [ ] **Step 1: Create `project.godot`**

```ini
; project.godot
config_version=5

[application]
config/name="RagRogue"
run/main_scene="res://scenes/boot.tscn"
config/features=PackedStringArray("4.3")

[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"
window/handheld/orientation=4

[autoload]
GameSession="*res://scripts/app/game_session.gd"
```

Note: `boot.tscn` and `game_session.gd` are added as empty stubs in this task so the project opens; wire real hub in Task 6.

- [ ] **Step 2: Create enums + stub autoload + minimal boot scene**

`scripts/domain/enums.gd`:

```gdscript
class_name ClassId
enum { SWORDMAN, MAGE, ARCHER }

class_name Rarity
enum { N, R, SR }

class_name RoomType
enum { COMBAT, EVENT, LOOT, BOSS }
```

Godot allows one `class_name` per file — split into three files instead:

- `scripts/domain/class_id.gd` → `class_name ClassId` with `enum Value { SWORDMAN, MAGE, ARCHER }`
- `scripts/domain/rarity.gd` → `class_name Rarity` with `enum Value { N, R, SR }`
- `scripts/domain/room_type.gd` → `class_name RoomType` with `enum Value { COMBAT, EVENT, LOOT, BOSS }`

`scripts/app/game_session.gd`:

```gdscript
extends Node
# Filled in Task 5–6
var ready_for_play: bool = false
```

Create `scenes/boot.tscn` as a Node2D with a Label "RagRogue" (editor or minimal tscn text).

- [ ] **Step 3: Write failing test runner that expects at least one test module**

`scripts/tests/run_tests.gd`:

```gdscript
extends SceneTree

func _init() -> void:
	var failed := 0
	failed += _run("res://scripts/tests/test_smoke.gd")
	quit(1 if failed > 0 else 0)

func _run(path: String) -> int:
	var script: GDScript = load(path)
	if script == null:
		push_error("Missing test: " + path)
		return 1
	var inst = script.new()
	if inst.has_method("run"):
		var errs: Array = inst.run()
		for e in errs:
			push_error(str(e))
		return errs.size()
	push_error("No run() in " + path)
	return 1
```

`scripts/tests/test_smoke.gd` (will pass once ClassId exists):

```gdscript
extends RefCounted

func run() -> Array:
	var errors: Array = []
	if ClassId.Value.MAGE != 1:
		errors.append("MAGE ordinal expected 1")
	return errors
```

- [ ] **Step 4: Run tests (expect FAIL until ClassId files exist, then PASS)**

```bash
godot --headless -s res://scripts/tests/run_tests.gd
```

Expected first run without domain files: FAIL missing ClassId. After Step 2 files exist: exit code 0.

- [ ] **Step 5: Commit**

```bash
git add project.godot scripts/ scenes/boot.tscn README.md
git commit -m "chore: scaffold Godot RagRogue project and headless tests"
```

---

### Task 2: Hero, gear, skills domain models

**Files:**
- Create: `scripts/domain/gear_item.gd`
- Create: `scripts/domain/skill_def.gd`
- Create: `scripts/domain/hero.gd`
- Create: `scripts/domain/combat_stats.gd`
- Create: `scripts/tests/test_hero.gd`
- Modify: `scripts/tests/run_tests.gd` (register `test_hero.gd`)

**Interfaces:**
- Consumes: `ClassId`, `Rarity`
- Produces:
  - `Hero.new(class_id: int) -> Hero` with `level: int`, `xp: int`, `hp_max`, gear slots, `skill_ids: Array[String]`
  - `Hero.add_xp(amount: int) -> void` (level-ups using 100 * level XP curve)
  - `CombatStats.from_hero(hero: Hero) -> Dictionary` keys `atk`, `def`, `hp_max`, `move_speed`
  - `GearItem` fields: `id`, `name`, `slot` (`weapon|armor|accessory`), `rarity`, `atk_bonus`, `def_bonus`, `hp_bonus`
  - `SkillDef` fields: `id`, `name`, `class_id`, `cooldown`, `power`, `kind` (`single|aoe|heal`)

- [ ] **Step 1: Write failing tests**

`scripts/tests/test_hero.gd`:

```gdscript
extends RefCounted

func run() -> Array:
	var errors: Array = []
	var h := Hero.new(ClassId.Value.MAGE)
	if h.level != 1:
		errors.append("new hero level should be 1")
	h.add_xp(100)
	if h.level != 2:
		errors.append("100 xp should level 1->2")
	var stats := CombatStats.from_hero(h)
	if int(stats.atk) < 1:
		errors.append("atk should be positive")
	var gear := GearItem.from_dict({
		"id": "staff_n",
		"name": "Apprentice Staff",
		"slot": "weapon",
		"rarity": Rarity.Value.N,
		"atk_bonus": 3,
		"def_bonus": 0,
		"hp_bonus": 0
	})
	h.equip(gear)
	var stats2 := CombatStats.from_hero(h)
	if int(stats2.atk) <= int(stats.atk):
		errors.append("weapon should increase atk")
	return errors
```

- [ ] **Step 2: Run test — expect FAIL (Hero not found)**

```bash
godot --headless -s res://scripts/tests/run_tests.gd
```

- [ ] **Step 3: Implement domain files**

`hero.gd` — `add_xp`: while `xp >= 100 * level`: `xp -= 100 * level`; `level += 1`. Base stats by class (Mage: atk 4 def 2 hp 40; Swordman: atk 5 def 4 hp 55; Archer: atk 5 def 2 hp 45) + gear bonuses. `equip(item)` replaces slot.

`gear_item.gd` / `skill_def.gd` — `from_dict` / `to_dict`.

`combat_stats.gd` — sum base + equipped bonuses into `{atk, def, hp_max, move_speed}` (`move_speed` default 120.0).

- [ ] **Step 4: Run tests — expect PASS**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat: hero, gear, and combat stats domain models"
```

---

### Task 3: Auto-combat resolver

**Files:**
- Create: `scripts/domain/auto_combat.gd`
- Create: `scripts/tests/test_auto_combat.gd`
- Modify: `scripts/tests/run_tests.gd`

**Interfaces:**
- Consumes: `SkillDef`, combatant dictionaries
- Produces:
  - `AutoCombat.pick_target(self_pos: Vector2, enemies: Array) -> int` index of nearest alive enemy (`hp > 0`), or `-1`
  - `AutoCombat.pick_skill(skills: Array, cds: Dictionary, self_hp: float, self_hp_max: float, enemy_count_in_aoe: int) -> String` skill id or `""` for basic attack
  - Priority: if `self_hp / self_hp_max < 0.35` prefer `heal` off CD; else if `enemy_count_in_aoe >= 3` prefer `aoe`; else prefer highest `power` `single` off CD; else `""`
  - `AutoCombat.basic_damage(atk: int, target_def: int) -> int` = `max(1, atk - target_def / 2)`
  - `AutoCombat.skill_damage(power: int, atk: int, target_def: int) -> int` = `max(1, power + atk - target_def / 2)`

- [ ] **Step 1: Write failing tests** in `test_auto_combat.gd` covering nearest target, heal-when-low, aoe-when-crowded, basic_damage floor at 1

- [ ] **Step 2: Run — FAIL**

- [ ] **Step 3: Implement `auto_combat.gd` as `class_name AutoCombat` with static funcs**

- [ ] **Step 4: Run — PASS**

- [ ] **Step 5: Commit** `feat: auto-combat target and skill priority`

---

### Task 4: Floor generation + run state + upgrades

**Files:**
- Create: `scripts/domain/floor_gen.gd`
- Create: `scripts/domain/run_state.gd`
- Create: `data/run_upgrades.json`
- Create: `scripts/tests/test_floor_gen.gd`
- Create: `scripts/tests/test_run_state.gd`
- Modify: `scripts/tests/run_tests.gd`

**Interfaces:**
- `FloorGen.make_floor(floor_index: int, rng: RandomNumberGenerator) -> Array` of room dicts `{type, monster_ids, cleared}`
  - Floors 0–3 (or 0–4): mostly COMBAT, one LOOT, optional EVENT; last floor ends with BOSS room
  - Exactly one BOSS on the final floor of the act (`act_floor_count = 4` → indices 0..3)
- `RunState` fields: `floor_index`, `rooms`, `room_index`, `modifiers: Array[String]`, `alive: bool`
- `RunState.start_act(rng) -> void`
- `RunState.apply_upgrade(upgrade_id: String) -> void` (append modifier; unknown id ignored)
- `RunState.on_room_cleared() -> void` advances `room_index` or floor

`data/run_upgrades.json`:

```json
[
  {"id": "atk_up", "name": "Sharpened Focus", "atk_bonus": 2},
  {"id": "hp_up", "name": "Vital Charm", "hp_bonus": 10},
  {"id": "cdr", "name": "Quick Chant", "cdr_bonus": 0.1}
]
```

- [ ] **Step 1: Failing tests** — floor has ≥3 rooms; final floor has a BOSS; upgrade adds modifier; clearing last room increments floor

- [ ] **Step 2: Run — FAIL**

- [ ] **Step 3: Implement**

- [ ] **Step 4: Run — PASS**

- [ ] **Step 5: Commit** `feat: floor generation and run state`

---

### Task 5: Save game + reward resolver

**Files:**
- Create: `scripts/domain/save_game.gd`
- Create: `scripts/domain/reward_resolver.gd`
- Create: `scripts/tests/test_save_game.gd`
- Create: `scripts/tests/test_reward_resolver.gd`
- Modify: `scripts/tests/run_tests.gd`
- Modify: `scripts/app/game_session.gd`

**Interfaces:**
- `SaveGame` account shape:
  ```gdscript
  {
    "version": 1,
    "heroes": [Hero.to_dict(), Hero.to_dict(), Hero.to_dict()] # indices = ClassId
  }
  ```
- `SaveGame.load_or_create(path: String) -> Dictionary`
- `SaveGame.write(path: String, data: Dictionary) -> void`
- For tests use `user://test_save.json` or absolute temp path passed in
- `RewardResolver.xp_for_monster(monster_tier: int) -> int` = `10 * monster_tier`
- `RewardResolver.apply_room_clear(hero: Hero, monster_tier: int) -> void` adds XP
- On death: run modifiers cleared by `RunState`; hero level/gear unchanged (already on hero object)
- On boss clear: grant one random gear from pool N/R (SR later)

Wire `GameSession`:
- `account`, `active_class: int`, `run: RunState`
- `func active_hero() -> Hero`
- `func persist() -> void` writes save

- [ ] **Step 1: Failing tests** — round-trip save; XP grant levels hero; death does not reset level

- [ ] **Step 2–4: Implement until PASS**

- [ ] **Step 5: Commit** `feat: local save and reward resolver`

---

### Task 6: Hub scene (three heroes, enter dungeon)

**Files:**
- Create: `scenes/hub/hub.tscn`
- Create: `scripts/ui/hub_controller.gd`
- Modify: `scenes/boot.tscn` → change to hub or go to hub on ready
- Modify: `scripts/app/game_session.gd`
- Create: `data/skills.json` (minimal 3 skills per class)
- Create: `data/gear.json` (starter weapons)

**Interfaces:**
- Hub UI (landscape): three buttons Swordman / Mage / Archer; show level; button «В подземелье»
- Selecting class sets `GameSession.active_class` and `persist()`
- Enter dungeon → `GameSession.start_run()` then `get_tree().change_scene_to_file("res://scenes/dungeon/dungeon.tscn")`

`data/skills.json` example entries with original names (not RO trademarks):

```json
[
  {"id": "flame_spark", "name": "Flame Spark", "class_id": 1, "cooldown": 3.0, "power": 8, "kind": "single"},
  {"id": "cinder_wave", "name": "Cinder Wave", "class_id": 1, "cooldown": 6.0, "power": 6, "kind": "aoe"},
  {"id": "ember_soothe", "name": "Ember Soothe", "class_id": 1, "cooldown": 8.0, "power": 12, "kind": "heal"}
]
```

Add Swordman/Archer triplets similarly.

- [ ] **Step 1: Manual test checklist as automated smoke** — optional UI test skipped; instead unit-test `GameSession.start_run()` sets `run.alive == true`

- [ ] **Step 2: Implement hub + data JSON**

- [ ] **Step 3: Run headless tests PASS; open editor play hub, select Mage, see level 1**

- [ ] **Step 4: Commit** `feat: hub with three class heroes`

---

### Task 7: Dungeon — player movement + virtual stick

**Files:**
- Create: `scenes/dungeon/player.tscn`
- Create: `scenes/dungeon/dungeon.tscn`
- Create: `scripts/dungeon/player_controller.gd`
- Create: `scripts/ui/virtual_stick.gd`
- Create: `scenes/ui/virtual_stick.tscn`

**Interfaces:**
- `PlayerController` reads stick vector; moves `CharacterBody2D`; speed from `CombatStats.from_hero(...).move_speed`
- Camera2D current, smoothed, landscape
- No attack input handlers

- [ ] **Step 1: Implement stick + player movement**

- [ ] **Step 2: Playtest** — character moves in all directions on desktop (WASD mapped to same move vector for editor convenience; mobile uses stick only). WASD is editor-only debug and must not fire skills.

- [ ] **Step 3: Commit** `feat: landscape dungeon movement and virtual stick`

---

### Task 8: Enemies + auto-combat in dungeon

**Files:**
- Create: `scenes/dungeon/enemy.tscn`
- Create: `scripts/dungeon/enemy_actor.gd`
- Create: `scripts/dungeon/dungeon_controller.gd`
- Create: `data/monsters.json`
- Create: `scripts/dungeon/combat_director.gd`

**Interfaces:**
- `CombatDirector._physics_process`: for player and each enemy in range, tick CDs; use `AutoCombat` to pick target/skill; apply damage; show simple Label floating text optional
- Enemy aggro radius 180px; player basic attack range 90 (melee) / 160 (mage/archer) by class
- On all enemies in room dead → pause → show upgrade pick (Task 9) or advance

`monsters.json`:

```json
[
  {"id": "cave_slime", "name": "Cave Slime", "tier": 1, "hp": 20, "atk": 3, "def": 0},
  {"id": "stone_beetle", "name": "Stone Beetle", "tier": 2, "hp": 35, "atk": 5, "def": 2},
  {"id": "act_boss", "name": "Vault Warden", "tier": 5, "hp": 120, "atk": 8, "def": 3}
]
```

- [ ] **Step 1: Implement spawn from current `RunState` room monster_ids**

- [ ] **Step 2: Playtest** — walk into pack; skills fire without tapping attack; Mage dies if standing in pack (validates positioning)

- [ ] **Step 3: On player hp ≤ 0 → `run.alive = false`; apply nothing to permanent gear; return to hub with «Поражение» toast; `persist()`

- [ ] **Step 4: Commit** `feat: dungeon auto-combat and defeat flow`

---

### Task 9: Room clear upgrades + act clear

**Files:**
- Create: `scenes/ui/upgrade_pick.tscn`
- Create: `scripts/ui/upgrade_pick.gd`
- Modify: `scripts/dungeon/dungeon_controller.gd`
- Modify: `scripts/domain/reward_resolver.gd` if needed

**Interfaces:**
- After COMBAT clear: offer 3 random upgrades from `run_upgrades.json`; on pick `run.apply_upgrade`; load next room
- After BOSS clear: `RewardResolver.grant_boss_loot(hero, gear_pool, rng)`; `persist()`; return hub with victory

- [ ] **Step 1: Implement UI modal (three buttons)**

- [ ] **Step 2: Playtest full act** (can temporarily set `act_floor_count = 1` with 1 combat + boss via debug flag `GameSession.debug_short_act` for QA, default false)

- [ ] **Step 3: Commit** `feat: run upgrades and boss clear rewards`

---

### Task 10: Content fill for three classes + gear pool

**Files:**
- Modify: `data/skills.json` (3 starters + 2 unlocks each class; unlock levels 3 and 5)
- Modify: `data/gear.json` (~15–25 items across slots/rarities)
- Modify: `scripts/domain/hero.gd` — `unlocked_skill_ids()` filters by level
- Create: `scripts/tests/test_skill_unlock.gd`

- [ ] **Step 1: Failing test** — Mage level 1 has 3 skills; level 5 has 5

- [ ] **Step 2: Implement data + filter**

- [ ] **Step 3: PASS + commit** `feat: class skill unlocks and gear pool`

---

### Task 11: AppGallery packaging docs + Android export preset

**Files:**
- Create: `docs/store/listing-ru.md` (copy brief/full description from spec; note monetization TBD)
- Create: `docs/store/privacy-mvp.md` (local save only; no account)
- Create: `export_presets.cfg` Android landscape, package `com.swatik.ragrogue` (adjust if publisher ID differs)
- Modify: `README.md` with export steps

- [ ] **Step 1: Write listing + privacy drafts from spec (Russian)**

- [ ] **Step 2: Add Android export preset orientation landscape; min SDK per Godot default**

- [ ] **Step 3: Export debug APK locally if SDK present; if SDK missing, document blocker in README without failing the task**

- [ ] **Step 4: Commit** `docs: AppGallery listing drafts and Android export preset`

---

### Task 12: Ludo AI asset placeholders + integration hooks

**Files:**
- Create: `assets/placeholders/README.md` — drop targets for icon + 3 screenshots from Ludo AI
- Create: `docs/store/ludo-ai-briefs.md` — copy briefs from spec §7
- Modify: `project.godot` icon path when `assets/branding/icon.png` appears

- [ ] **Step 1: Add briefs and empty dirs `assets/branding/`, `assets/screenshots/`**

- [ ] **Step 2: Commit** `docs: Ludo AI media drop points`

Do **not** call Ludo/Higgsfield in this task unless the user asks to generate art now.

---

## Spec coverage (self-review)

| Spec requirement | Task |
|------------------|------|
| Landscape + AppGallery MVP | 1, 11 |
| Move only / auto skills | 3, 7, 8 |
| Three class slots | 2, 5, 6, 10 |
| Permanent level + gear | 2, 5, 9 |
| Run-only upgrades | 4, 9 |
| 3–5 floors + boss act | 4, 8, 9 |
| Local save | 5 |
| Mage as face / store drafts | 11, 12 |
| Original IP names | 6, 8, 10 data |
| Monetization TBD | skipped (constraint) |
| Cloud/HMS later | skipped |

**Placeholder scan:** none intentional; `debug_short_act` is an explicit QA flag defaulting false.  
**Type consistency:** `ClassId.Value.*`, `Hero`, `RunState`, `AutoCombat` static API reused across tasks.

---

## Execution handoff

Plan complete and saved to `docs/superpowers/plans/2026-08-21-ragrogue-mvp.md`.

**Two execution options:**

1. **Subagent-Driven (recommended)** — fresh subagent per task, review between tasks  
2. **Inline Execution** — execute in this session with executing-plans checkpoints  

Which approach?
