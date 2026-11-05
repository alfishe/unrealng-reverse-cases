# 5. Controls

This document covers the keys and devices of both releases as the recordings show them: the intros, the '98 menu,
the '99 start-up menu, its text pages, LOAD MAP, REDEFINE, and play. Play itself takes Nether Earth's controls (the
nether-earth case); only what ZS Edition changes is named here. The menus and screens are described in
[01](01-game-design.md), how they are drawn in [06](06-rendering.md).

The recordings (unreal-ng, muted; their input scripts beside them; figures by `tools/fig_screens.py` and
`tools/fig_compare.py`):

| Recording | Machine | The keys it presses |
| --- | --- | --- |
| `r98` (`work/stage1/r98`) | Pentagon 128 + TR-DOS | `RUN "NEZSEd"`, SPACE in the intro, 0 START |
| `x98` (`work/stage2/texts/x98`, `inputs/x98.txt`) | Pentagon 128 + TR-DOS | as `r98`, then 5 LOAD NEW LEVEL!, 0 START |
| `r99` (`work/stage1/r99`) | Pentagon 128 + TR-DOS | SPACE in the intro; Q A O P and SPACE on every menu item; A in the text pages; LOAD MAP; START |
| `x99` (`work/stage2/texts/x99`, `inputs/x99.txt`) | Pentagon 128 + TR-DOS | REDEFINE (seven keys), LOAD MAP with A / Q, START, ABORT |

## 5.1 The intros

| Release | Key | What it does |
| --- | --- | --- |
| '98 | any key | leaves the intro for the game's menu |
| '99 | ENTER | pauses the scroller |
| '99 | SPACE | goes on: the wipe, then the load of the rest ("System checking") |

The '99 scroller names these keys itself ([texts/scroller99.md](texts/scroller99.md)).

## 5.2 The '98 menu

Nether Earth's menu and keys, retitled ([01, 1.5](01-game-design.md#15-the-98-menu)):

| Key | Item |
| --- | --- |
| 0 | START GAME |
| 1 | KEYBOARD |
| 2 | KEMPSTON J/S |
| 3 | INTERFACE 2 |
| 4 | REDEFINE KEYS |
| 5 | LOAD NEW LEVEL! (Nether Earth: LOAD SAVED GAME). Reads no disk; START after it crashes (`x98` 5600) |

![Nether Earth, ZS'98 and ZS'99 menus](img/compare/menu.png)

*The menus: Nether Earth (`ne-play` 12750), ZS'98 (`r98` 4703), ZS'99 (`r99` 3002).*

## 5.3 The '99 start-up menu

A pointer, moved by keys, never by a number:

| Key | What it does |
| --- | --- |
| Q, A | pointer up, down |
| O, P | pointer left, right |
| SPACE | select the item under the pointer: a setting of LEVEL or CONTROL, a toggle of UPGRADING, or an action |

![The '99 start-up menu](img/screens/99-menu.png)

*The start-up menu as it comes up (`r99` 3002).*

CONTROL picks the device for play: KEYBOARD, KEMPSTON, INTERFACE (Sinclair) or REDEFINE.

## 5.4 REDEFINE

REDEFINE asks for seven keys, one at a time: UP, DOWN, LEFT, RIGHT, FIRE, PAUSE, ABORT. Nether Earth's redefine also
asks for SAVE; ZS Edition has no save, so it is gone.

![REDEFINE](img/screens/99-redefine.png)

*REDEFINE (`x99` 3477).*

## 5.5 Text pages and LOAD MAP

| Screen | Key | What it does |
| --- | --- | --- |
| DESCRIPTION, ADVICES, GREETS, ABOUT ZS NE | A | scroll the text on |
| | SPACE | back to the start-up menu |
| LOAD MAP | A | highlight the next map |
| | Q | highlight the previous map |
| | SPACE | load the highlighted map, back to the start-up menu |

| ![](img/screens/99-load-map.png) | ![](img/screens/99-load-map-nelev06.png) |
| --- | --- |
| LOAD MAP (`r99` 5452) | the highlight moved to `NELEV_06` (`x99` 4127) |

## 5.6 Play

Nether Earth's play keys (or the chosen joystick), with ABORT: in the '99 it returns to the start-up menu (`x99`
5302), where a new map or level can be chosen before the next START.

![ABORT back to the start-up menu](img/screens/99-abort-to-menu.png)

*After ABORT (`x99` 5302).*
