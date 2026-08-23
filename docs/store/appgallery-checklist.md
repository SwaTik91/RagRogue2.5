# AppGallery — чеклист сабмита RagRogue (RU/CIS)

Пакет: `com.swatik.ragrogue` · Версия: `0.1.0` (versionCode 1) · Ориентация: landscape

Статусы: ✅ готово в репо · ⚠️ нужно действие вне кода · ❌ блокер

---

## 1. Бинарь

| Пункт | Статус | Где |
|-------|--------|-----|
| Debug APK собирается | ✅ / ⚠️ | `build/RagRogue-debug.apk` (gitignore); артефакт агента |
| Release / upload keystore | ⚠️ | Свой keystore для AGC, не коммитить |
| AAB при необходимости AGC | ⚠️ | `gradle_build/export_format` в `export_presets.cfg` |
| Unique name совпадает с AGC | ⚠️ | `com.swatik.ragrogue` — сверить publisher ID |

Экспорт:

```bash
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export ANDROID_HOME=$HOME/android-sdk
godot --headless --path . --install-android-build-template
godot --headless --path . --export-debug "Android" build/RagRogue-debug.apk
```

## 2. Листинг (AGC)

| Поле | Статус | Источник |
|------|--------|----------|
| Название | ✅ | `docs/store/listing-ru.md` → RagRogue |
| Краткое описание | ✅ | там же (проверить лимит в консоли) |
| Полное описание | ✅ | там же |
| Категория / возраст | ⚠️ | анкета AGC, ориентир 12+ |
| Рынки RU+СНГ | ⚠️ | выбрать в консоли |
| EN fallback | ⚠️ | опционально |

## 3. Медиа

| Ассет | Статус | Путь |
|-------|--------|------|
| Иконка 512 / adaptive | ✅ | `assets/branding/icon.png`, `icon-192.png`, adaptive fg/bg |
| Скриншот 1 | ✅ | `assets/screenshots/shot-1.png` |
| Скриншот 2 | ✅ | `assets/screenshots/shot-2.png` |
| Скриншот 3 | ✅ | `assets/screenshots/shot-3.png` |
| Feature / promo graphic | ⚠️ | при требовании формы AGC |
| Видео геймплея | ✅ | `assets/screenshots/combat-loop.mp4` (+ `.gif` превью) |

Скриншоты — альбом; не загружать портрет.

## 4. Политика и поддержка

| Пункт | Статус | Заметка |
|-------|--------|---------|
| Текст политики | ✅ | `docs/store/privacy-mvp.md` |
| HTTPS URL политики | ❌ | разместить текст, вставить URL в AGC |
| Email поддержки | ❌ | рабочий ящик для ревью |

Без HTTPS-политики и email сабмит обычно режут.

## 5. Соответствие билду

| Пункт | Статус |
|-------|--------|
| Нет аккаунта / облака | ✅ |
| Нет рекламы / IAP в MVP | ✅ (монетизация TBD в листинге) |
| Локальный сейв | ✅ |
| Главное меню → хаб → данж | ✅ |
| Настройки (громкость, язык) | ✅ |
| Разрешения минимальны | ✅ сверить манифест после export |

## 6. Юридическое

| Пункт | Статус |
|-------|--------|
| Формулировка «в духе Ragnarok» | ⚠️ юрист / убрать TM при риске |
| Нет чужих ассетов Gravity | ✅ (Ludo / свои) |

## Порядок перед upload

1. Закрыть ❌: HTTPS privacy + support email.
2. Собрать **signed release** своим keystore.
3. Залить иконку + 3 landscape shots (+ video optional).
4. Вставить тексты из `listing-ru.md`.
5. Пройти age questionnaire.
6. Внутренний тест на Huawei-устройстве / Emulator без GMS.
7. Submit на ревью.

Связанные файлы: `export_presets.cfg`, `docs/store/listing-ru.md`, `docs/store/privacy-mvp.md`, `docs/store/ludo-ai-briefs.md`.
