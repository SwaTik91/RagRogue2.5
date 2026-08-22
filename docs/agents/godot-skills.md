# Godot Agent Skills (RagRogue)

Установлены в `.agents/skills/` для Cursor / Cloud Agent (`npx skills`).

Проект: Godot **4.3**, 2D roguelike, mobile (Huawei AppGallery), GDScript.

## Хаб и качество кода

| Skill | Источник | Зачем |
|-------|----------|--------|
| **godot-master** | [thedivergentai/gd-agentic-skills](https://github.com/thedivergentai/gd-agentic-skills) | Архитектура, «кто владеет данными», маршрутизация к ~99 domain-skills |
| **godot-best-practices** | [jwynia/agent-skills](https://github.com/jwynia/agent-skills) | GDScript 4.x, сцены, FSM, saves, code review |

## UI / HUD / меню

| Skill | Источник | Зачем |
|-------|----------|--------|
| **godot-ui** | [zate/cc-godot](https://github.com/zate/cc-godot) | Control, anchors, themes, игровые UI-паттерны |
| **godot-ui-control** | [gamedev-skills/awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills) | Container, Theme, focus (геймпад/клавиатура) |
| **godot-ui-containers** | gd-agentic-skills | Layout recipes, inventory grid, responsive HUD |

## Анимация и движение

| Skill | Источник | Зачем |
|-------|----------|--------|
| **godot-animation** | awesome-gamedev-agent-skills | AnimationPlayer / AnimationTree / Tween |
| **godot-2d-animation** | gd-agentic-skills | AnimatedSprite2D, sprite sheets, 2D cycles |
| **godot-characterbody-2d** | gd-agentic-skills | CharacterBody2D, move_and_slide, джойстик |

## Геймплей RagRogue

| Skill | Источник | Зачем |
|-------|----------|--------|
| **godot-combat-system** | gd-agentic-skills | Автобой, cooldowns, combat events |
| **godot-genre-roguelike** | gd-agentic-skills | Run state, rooms, meta-progression |

## Mobile и релиз

| Skill | Источник | Зачем |
|-------|----------|--------|
| **godot-adapt-desktop-to-mobile** | gd-agentic-skills | Touch, safe area, virtual joystick, battery |
| **godot-export-builds** | gd-agentic-skills | Android APK/AAB, CI, headless export |

## Не ставили (почему)

- **godot-animation** vs **godot-2d-animation** — оба: первый про AnimationTree, второй про 2D спрайты (наш `ActorAnimator`).
- **godot-ui** vs **godot-ui-control** — пересекаются; для меню/HUD держим оба + `godot-ui-containers`.
- Остальные ~80 skills из gd-agentic — через **godot-master** при необходимости.

## Обновление

```bash
npx skills update godot-master godot-ui godot-animation godot-ui-control
# domain skills:
npx skills add https://github.com/thedivergentai/gd-agentic-skills --skill godot-combat-system --yes
```

Ревизии зафиксированы в `skills-lock.json`.
