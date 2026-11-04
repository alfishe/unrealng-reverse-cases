# 08. The HUD and the texts

The HUD is NE's (the view, the status panel, the radar), with the labels translated; every text of the game is
NE's text entry with Russian letters in the same place and length ([10](10-gameplay-logic.md) 1 lists the bytes).

## 1. The letters

ANE's game font draws Russian letters on NE's codes (`tools/game_text.py`):

| Code | Letter | Code | Letter | Code | Letter |
| --- | --- | --- | --- | --- | --- |
| `A` `$41` | А | `K` `$4B` | К | `U` `$55` | Ю |
| `B` `$42` | В | `L` `$4C` | Л | `V` `$56` | Ч |
| `C` `$43` | С | `M` `$4D` | М | `W` `$57` | П |
| `D` `$44` | Д | `N` `$4E` | Ш | `X` `$58` | Х |
| `E` `$45` | Е | `O` `$4F` | О | `Y` `$59` | У |
| `F` `$46` | Ф | `P` `$50` | Р | `Z` `$5A` | Ц |
| `G` `$47` | Г | `Q` `$51` | Ы | `[` `$5B` | Б |
| `H` `$48` | Н | `R` `$52` | Ь | `#` `$23` | Щ |
| `I` `$49` | И (also Й) | `S` `$53` | Я | `$24` | Э |
| `J` `$4A` | Ж | `T` `$54` | Т | `3` `$33` | З (and the digit) |

There is no Ъ; Ё is written Е. So NE's code for "START GAME" spelt `CTAPT IGPQ` shows as СТАРТ ИГРЫ.

## 2. The texts

| NE text | ANE |
| --- | --- |
| main menu: START GAME, KEYBOARD, KEMPSTON J/S, INTERFACE 2, REDEFINE KEYS, LOAD SAVED GAME | СТАРТ ИГРЫ, КЛАВИШИ, КЕМПСТОН ДЖ., ИНТЕРФЕЙС 2, ЗАДАТЬ КЛАВ., ЗАГРУЗКА |
| play screen: DAY, TIME, RADAR | ДЕНЬ, ЧАС, РАДАР |
| status panel: BASES, ELECTRONICS, NUCLEAR, PHASERS, MISSILES, CANNON ... | БАЗЫ, ЭЛЕКТР., А-БОМБЫ, ФАЗОРЫ, РАКЕТЫ, ПУШК... |
| robot menu: DIRECT CONTROL, GIVE ORDERS, COMBAT MODE, LEAVE ROBOT | ПРЯМОЕ УПРАВЛ., ОТДАТЬ ПРИКАЗ, БОЕВОЙ РЕЖИМ, ОСТАВИТЬ РОБОТА |
| STRENGTH | СИЛА |
| key names: SPACE ... | ПРОБЕЛ ... |

The full list, each with its address and its letters, is the text part of `src/game/ane-patches.asm`. The
strings keep NE's lengths and control codes, so no layout changed. The texts outside the game (the help, the
scroller, Final Cut, the disk module) are in [12](12-claims.md) and `src/res/text/`.
