# PixelLab — Sniper1: дорисовать анимации

**Не генерировать нового character и не запускать `full-pixflux` / `--generate-anims`.**  
Работаем только с твоим mannequin **Sniper1**.

| Поле | Значение |
|------|----------|
| Tag | `Sniper1` |
| Character ID | `059aaa76-7fb1-4113-8df3-4367c9a4bbce` |
| Prompt | Sniper class chat with flying falcon |
| State | `Idle` (mannequin) |

## Уже готово (south → в игре `down`)

| Анимация в игре | PixelLab / ZIP | Направление | Кадров |
|-----------------|----------------|-------------|--------|
| idle_down | rotations + Breathing_Idle | south | 4–9 |
| idle_up / left / right | rotations (статичные) | north, west, east | 1→9 копий |
| walk_down | `walking` | south | 6 |
| attack_down | `attack` / skill-копия | south | 9 |
| skill_down | `skill` | south | 9 |

Портрет в игре: `assets/art/game/archer-idle.png` (из south rotation).

## Нужно дорисовать в PixelLab UI

В mannequin **Sniper1**, state **Idle**, для каждой анимации добавить **3 направления** (south уже есть):

| # | Анимация в PixelLab | В игре | north (up) | west (left) | east (right) |
|---|---------------------|--------|------------|-------------|--------------|
| 1 | **Walking** | walk | ❌ TODO | ❌ TODO | ❌ TODO |
| 2 | **Attack** (лук / выстрел) | attack | ❌ TODO | ❌ TODO | ❌ TODO |
| 3 | **Skill** (falcon / volley) | skill | ❌ TODO | ❌ TODO | ❌ TODO |

Опционально (качество idle):

| # | Анимация | north | west | east |
|---|----------|-------|------|------|
| 4 | **Breathing_Idle** (живой idle, не статичный rotation) | ❌ | ❌ | частично east в ZIP |

### Соответствие направлений

| PixelLab | RagRogue папка |
|----------|----------------|
| south | `down` |
| north | `up` |
| west | `left` |
| east | `right` |

### Промпты (если UI просит описание)

- **Walk:** top-down roguelike, sniper archer with falcon on shoulder, walk cycle, tan tunic, fur collar, metal pauldrons, wooden bow
- **Attack:** draws bowstring, releases arrow forward, falcon wings optional, same outfit as idle
- **Skill:** raises bow overhead, falcon swoops, dramatic volley, hooded scout sniper style

## После генерации в PixelLab

Импорт **без** новых API-генераций:

```bash
python3 scripts/art/pixellab_batch.py archer --import-tag Sniper1
```

Проверка превью: `assets/art/pixellab/archer/preview_sheet.png`

## Что удалено из игры

- Character `8c3a8142-…` (full-pixflux «зелёный плащ») — **удалён**
- Все ассеты archer пересобраны только из ZIP **Sniper1** (`059aaa76-…`)

## Не запускать

```bash
# создаёт ДРУГОГО лучника — не использовать для Sniper1
python3 scripts/art/pixellab_batch.py archer --phase full-pixflux
python3 scripts/art/pixellab_batch.py archer --import-tag Sniper1 --generate-anims
python3 scripts/art/pixellab_batch.py archer --rotate-anims
```

Rotate API — только если сознательно хочешь «крутить south» вместо ручной генерации в UI.
