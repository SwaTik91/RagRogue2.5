# RagRogue — Design Spec (GDD-lite + AppGallery)

**Date:** 2026-08-21  
**Status:** Approved — implementation plan: `docs/superpowers/plans/2026-08-21-ragrogue-mvp.md`  
**Platform target:** Huawei AppGallery, markets RU/CIS only  
**Working title / store name:** RagRogue  

---

## 1. Passport

| Field | Value |
|--------|--------|
| Name | RagRogue |
| Type | Game (AppGallery) |
| Genre (AGC) | Role-playing → Adventure / ARPG (confirm exact tag in AGC form) |
| Orientation | Landscape (album) |
| Devices | Phone first; tablet if layout allows |
| Binary | Android APK/AAB for Huawei; HarmonyOS later if needed |
| Markets v1 | Russia + CIS only (no mainland China) |
| Listing languages | RU required; EN fallback |
| Save | Local in MVP; cloud later |
| Network | Not required for core play in MVP |
| Monetization | TBD (deferred) |
| Age tone | Classic Ragnarok-like combat, ~12+ |
| Face of brand | Mage |

---

## 2. Pitch & USP

**One-liner (RU, draft ≤80 chars):**  
«Ходи сам — бей авто. Roguelike в духе Ragnarok.»

**Pitch:**  
RagRogue is a midcore dungeon RPG for AppGallery: procedural floors with a Ragnarok Origin–inspired look and skill fantasy. The player **controls movement only**; **attacks and skills fire automatically**. Permanent progression keeps **level and gear**; run modifiers are temporary.

**Why players return (pillars):**
1. Meta power — feel stronger between runs (level + gear)
2. Builds / skills — synergies and loadout choices
3. Atmosphere — nostalgia adjacent to RO, without copying IP

**Audience:** Broad AppGallery RU/CIS; core = midcore 18–35 who know RO / MMORPG.

**USP:** Manual positioning + auto combat + permanent loot in short 3–5 minute runs, with deeper “mini-Ragnarok” systems than a pure idle auto-runner.

---

## 3. Design approach (locked)

**Chosen direction:** Approach 2 — “mini-Ragnarok with floors”, with control rule:

- Player **walks** (virtual stick / tap-to-move)
- **Skills and basic attacks are automatic** (CD + priority rules)
- Dungeon floors are the main content; no open world in v1

**Rejected / not for v1:**
- Pure idle “watch only” auto-battle (Approach 1 as whole product)
- Hardcore full wipe of level/gear on death (Approach 3)
- Multiplayer, guilds, seasons, story cutscenes, mainland China release

---

## 4. Core gameplay

### 4.1 Loop

1. Hub: pick one of three heroes → equip → enter dungeon  
2. On floor: explore rooms by walking; combat resolves automatically  
3. Between rooms / after clear: choose a **run-only** upgrade  
4. Death or boss clear → XP/loot into **permanent** progress → next short run  

**Target session:** 3–5 minutes (one floor slice or short dive). Systems stay deeper than hyper-casual.

### 4.2 Movement & camera

- Landscape camera, top-down / slight ortho (RO Origin vibe)
- Input: virtual stick and/or tap on ground — **movement only**
- Entering enemy range engages combat AI for attacks/skills

### 4.3 Auto combat

- Auto-attack nearest / priority target in range  
- 2–4 skill slots cast automatically on cooldown using simple priorities (e.g. AoE if clustered, heal if low HP, single-target otherwise)  
- Player skill expression = **positioning** (kite, chokepoints, keep Mage/Archer at range, Swordman holds aggro)

### 4.4 Classes (MVP)

Three **separate hero slots** (one per class):

| Class | Auto role | Positioning fantasy |
|--------|-----------|---------------------|
| Swordman | Melee tank / sustained | Hold line, block paths |
| Mage | AoE / burst | Stay at range, avoid packs |
| Archer | Single-target / kite | Angles, backpedal |

**Store face:** Mage on icon and first screenshot.

### 4.5 Failure

Death on a floor ends the run. Permanent level/gear already on the account remain. Run buffs and run consumables are lost. Exact “loot extracted this run” rules can be tuned in implementation; baseline: XP and gear drops that were picked up before death are kept (no full extract-only mode unless later design says otherwise).

---

## 5. Progression & MVP content

### 5.1 Permanent

- Character level (XP from monsters/bosses)  
- Gear: weapon, armor, accessory (simple slots)  
- Class skills unlocked by level  
- Three hero slots (Swordman / Mage / Archer)

### 5.2 Run-only

- Room/floor upgrade choices (buffs, skill modifiers, consumables)  
- Temporary synergies until death or exit  

### 5.3 Content slice v1

- Hub menu: heroes, equip, skills, enter dungeon  
- One dungeon act: **3–5 floors** + end boss  
- Per floor: several rooms (combat / event / loot), procedural layout  
- Per class: 3 starter skills + 2–3 more unlocked by level  
- Gear pool: ~15–25 items, rarities N / R / SR  

### 5.4 Out of scope for v1

Multiplayer, guilds, open world, cinematic story, battle pass/seasons, cloud save, China compliance pack, pay systems (until monetization TBD is resolved).

---

## 6. AppGallery listing draft

### 6.1 Texts

- **Title:** RagRogue  
- **Brief (RU draft):** Ходи сам — бей авто. Roguelike в духе Ragnarok.  
- **Full description structure (≤8000):**
  1. What it is  
  2. How to play (move yourself, auto skills)  
  3. Three classes  
  4. Permanent gear & level  
  5. Short runs, offline-friendly MVP  
  6. Honest note on monetization when decided  

Confirm character limits in current AGC form before submit (Huawei docs; non-CN limits often cited as title ≤30, brief ≤80 — **verify in AGC**).

### 6.2 Classification & rating

- App type: Game  
- Category: Role-playing / Adventure or ARPG tag  
- Content: fantasy combat, light blood/impact, no gore focus → expect ~12+ after questionnaire  

### 6.3 Privacy & review

- MVP: local save only → privacy policy must match (no account/cloud claims)  
- HTTPS privacy URL + support email required for review  
- Reviewer notes: how to finish tutorial, where combat is, no login in MVP  

### 6.4 Technical notes for store

- Prefer HMS-ready path if any Google-dependent SDK is avoided later  
- No GMS-only ads/billing assumptions until monetization is designed  
- Screenshots must match landscape gameplay  

---

## 7. Media brief (Ludo AI / Higgsfield)

All marketing and concept art for the listing is produced via **Ludo AI (Higgsfield)**. Do not use official Ragnarok trademarks, logos, or copyrighted character designs — **inspired by** tone only; original names for skills/monsters/items.

| Asset | Brief |
|--------|--------|
| Icon | Portrait of Mage, readable at small size, fantasy mobile RPG, landscape-game brand mark |
| Shot 1 | Mage on dungeon floor, virtual stick visible, auto combat VFX — 1-second hook |
| Shot 2 | Three heroes / class select (Swordman, Mage, Archer) |
| Shot 3 | Loot / equip screen with N/R/SR gear |
| Optional video | Short landscape combat loop, movement + auto skills |

Rules: real gameplay framing, no competitor store logos, album orientation.

---

## 8. IP & naming rules

- Visual and system **inspiration**: Ragnarok Origin–like jobs, skills, cute-fantasy combat  
- Must ship as **original IP**: world name, monster names, skill names, UI copy — not Gravity / official RO assets or names  
- Store copy may say “в духе Ragnarok” only if legal review allows; safer long-term: describe fantasy without trademarked title in official listing if counsel objects  

---

## 9. Risks

1. **IP risk** if art/names too close to official RO.  
2. **Boring idle** if positioning does not matter — combat AI and enemy design must punish standing still.  
3. **Scope creep** of “mini-Ragnarok” vs 3–5 min runs — keep one act, three classes, limited gear.  
4. **Monetization TBD** blocks final store honesty on IAP/ads.  
5. **AGC field limits / ads / IAP policy** — re-check Huawei docs at submission time.

---

## 10. TBD (explicit)

- Monetization model (ads / IAP / hybrid; pay-to-win stance)  
- Final world, skill, and item naming (original)  
- Engine / tech stack (Unity, Godot, other)  
- Cloud save & HMS kits after MVP  
- Exact AGC content-rating answers  
- Whether “inspired by Ragnarok” wording is allowed in RU listing  

---

## 11. Success criteria for MVP

- Player can create/open three class heroes, equip gear, enter a dungeon  
- Landscape movement works; attacks/skills fire automatically  
- At least one full act (3–5 floors + boss) is completable  
- Level and gear persist across death  
- Run upgrades clear on death  
- AppGallery listing package drafted (texts + Ludo AI asset list) for RU/CIS  

---

## 12. Next step after this spec

User reviews this file. On approval, create an implementation plan via the writing-plans skill (not started in this document).
