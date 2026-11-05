# 1. Game design

What this covers: the game as a player meets it on the GS disk, and what differs from the 48K tape. The frames are
real emulator frames: the GS ones from `work/stage1/screens/` and `work/stage2/menu/`, the 48K ones from the 48K
case's captures; the figures are made by `tools/fig_compare.py`.

## 1.1 The game

Zynaps (Dominic Robinson, graphics Steve Crow; Hewson, 1987) is a horizontally scrolling shooter: 12 levels, enemy
waves on paths, weapon pods that light the panel's next item (speed, laser, plasma, homing missiles, seeker) and big
enemies. The GS disk plays the same game: the code is Zynaps's, at Zynaps's addresses, with the levels, the
graphics, the rules and the scoring of the 48K tape. The 48K case ([../zynaps/](../../zynaps/README.md)) describes
them; this case's own source holds every byte of them ([2](02-architecture.md), [12](12-routine-reference.md)).

## 1.2 What the GS conversion adds

The conversion (Mike Blum, ZX-Masters, 1997; music and FX mixed by John Underwood and Dangerous) replaces the
beeper with a General Sound card:

- a ProTracker module for every level and one for the title pages, 13 in all;
- 22 sampled effects: the start jingle with PREPARE FOR COMBAT, 10 in-game effects for the 48K's beeper sounds,
  the explosions, the ship's death and the weapons, and 11 more for events the 48K was silent on (bounces, dives, big enemies hit, the
  turns of some formations) in effects-only mode ([9.4](09-sound.md#94-where-the-game-makes-a-sound));
- an options menu before the game ([5](05-controls.md)): music and effects or effects only, infinite rounds, the
  turbo loader, the Saturn sound, the shot's sound, the effects timer, and the hidden infinite life and level
  select.

## 1.3 Start-up and menus, GS against 48K

| Figure | What differs |
| --- | --- |
| [start.png](img/compare/start.png) | The disk stops at the options menu; the tape goes straight into the title pages. |
| [menu-hidden.png](img/compare/menu-hidden.png) | Key 0 shows the hidden items. |
| [credits.png](img/compare/credits.png) | "MUSIC STEVE TURNER" became "PRESS 1,2,3 & FIRE". |
| [hiscore.png](img/compare/hiscore.png) | The high-score page is the same. |
| [title-picture.png](img/compare/title-picture.png) | The loading screen comes back between the title pages. |
| [select-level.png](img/compare/select-level.png) | SELECT LEVEL starts on the level chosen. |

The loading screen itself is the 48K tape's, byte for byte (`src/res/screen/loading.png` against the 48K case's
`loading.scr`); the GS boot fades it in.

## 1.4 Modes and cards

Music mode plays the level's module and the 10 in-game effects; effects-only mode has no music in play and all 21
effects. Both need a 128K machine with TR-DOS and a GS. A 512 KB card keeps all effects loaded in effects-only mode;
a 128 KB card gets everything again at every level change, and all of it fits ([9.5](09-sound.md#95-card-sizes)).
