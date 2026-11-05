# 1. Game design

This document covers Nether Earth ZS Edition as a player meets it, in both releases: the start-up from the disk,
the intros, the menus, the difficulty and upgrade settings, the maps, and play, each with the frames of the
recordings it shows. What the game is underneath (Nether Earth's rules, robots, factories) is Nether Earth's; this
chapter names only what the player sees change. The keys are in [05](05-controls.md), what is drawn and how in
[06](06-rendering.md), the long texts in [texts/](texts/README.md).

The recordings (unreal-ng, muted; screenshots by `python3 tools/fig_screens.py`, the side-by-side figures by
`python3 tools/fig_compare.py`, both on their own instance; every caption names the recording and the frame):

| Recording | Machine | What it holds |
| --- | --- | --- |
| `r98` (`work/stage1/r98`) | Pentagon 128 + TR-DOS | '98: power-on, `RUN "NEZSEd"`, the intro, SPACE, the menu, 0 START, play (frames 103-5903) |
| `x98` (`work/stage2/texts/x98`) | Pentagon 128 + TR-DOS | '98: as `r98`, but the menu's 5 LOAD NEW LEVEL, then 0 START (frames 102-6202; script `work/stage2/texts/inputs/x98.txt`) |
| `r99` (`work/stage1/r99`) | Pentagon 128 + TR-DOS | '99: autostart, the intro, SPACE, "System checking", the start-up menu, every text page, LOAD MAP (`NELEV_00`), HARD, PHASERS, START, play (frames 2-6462) |
| `x99` (`work/stage2/texts/x99`) | Pentagon 128 + TR-DOS | '99: autostart, REDEFINE, LOAD MAP with the highlight moved to `NELEV_06`, START, play, ABORT back to the start-up menu (frames 2-5302; script `work/stage2/texts/inputs/x99.txt`) |
| `r99-48` (`work/stage1/r99-48`) | Pentagon, "48 BASIC" (paging locked) | '99 on the 48 K path: "System checking" with 56Kb, then `0 OK` (frames 101-7201) |
| `s99` (`work/stage2/scorpion/s99`) | Scorpion ZS-256 + TR-DOS | '99: "System checking" with 256Kb, the start-up menu, START with no map loaded, play (frames 2-4802) |
| `ne-play` (`games/nether-earth/work/play`) | 48K | Nether Earth itself, the tape load, the menu, play (the comparison figures) |

## 1.1 Two releases

| | '98 (`NEZSED98.SCL`) | '99 (`NEZSED.SCL`) |
| --- | --- | --- |
| on the disk | one file, `NEZSEd.B` | the game `NEZSEd99.B`, four menu texts, a readme, twelve maps `NELEV_00`-`11` |
| before the game | "ZS'98 Presents", an intro with a scroller | an intro (photo, logo, scroller, music), "System checking" |
| menu | Nether Earth's, retitled "ZS EDITION'98", 5 LOAD NEW LEVEL! | a start-up menu with a pointer: level, upgrades, control, maps, four texts (128 K) |
| difficulty | one, harder than Nether Earth (the scroller's claims) | EASY, MEDIUM, HARD, CRITICAL; daily enemy upgrades to a minimum the player sets |
| maps | the one in the game | the built-in one (its walls spell `ЗАГРУЗИСЬ`, "load up") and twelve on the disk |
| author's date | 23.12.1998 | 28-30.01.1999 |

## 1.2 Start-up, '98

`RUN "NEZSEd"` from TR-DOS (`r98` frame 1903). The screen goes black and "ZS'98 Presents: NETHER EARTH ZS EDITION"
appears letter by letter (frame 2060), then the intro: a coloured "ZS" logo, a robot in a frame and a one-line
scroller along the middle, the music playing ([text](texts/scroller98.md)). Any key leaves it for the menu.

| ![](img/screens/98-trdos-run.png) | ![](img/screens/98-presents.png) | ![](img/screens/98-intro.png) |
| --- | --- | --- |
| `RUN "NEZSEd"` (`r98` 1903) | "ZS'98 Presents" (`r98` 2060) | the intro (`r98` 3000) |

![The '98 intro scroller, r98 frames 2400-2700, every 3rd frame](img/screens/98-intro-scroller.gif)

*The '98 intro: `r98` frames 2400-2700, every third frame.*

## 1.3 Start-up, '99

The disk autostarts (`r99` frame 102: TR-DOS's title). The intro unpacks its pictures into the screen column by
column (frame 652), then shows the author's photo, the logo "NETHER EARTH ZS EDITION 1999" in a frame, a vertical
scroller under the logo and the colour line "You wanted new levels? Take its!" under both (frame 1002). ENTER
pauses the scroll, SPACE goes on with the load; a diagonal wipe clears the picture (frame 1552)
([text](texts/scroller99.md)).

| ![](img/screens/99-trdos-boot.png) | ![](img/screens/99-intro-unpack.png) | ![](img/screens/99-intro.png) | ![](img/screens/99-intro-wipe.png) |
| --- | --- | --- | --- |
| TR-DOS (`r99` 102) | the pictures unpack (`r99` 652) | the intro (`r99` 1002) | the wipe after SPACE (`r99` 1552) |

![The '99 intro scroller, r99 frames 900-1300, every 4th frame](img/screens/99-intro-scroller.gif)

*The '99 intro: `r99` frames 900-1300, every fourth frame.*

Then "System checking": the loader names the computer, the memory it found and the TR-DOS version, and ticks off
what it loads (Game, Drivers, Menus, RAM-Disk). The memory line depends on the machine:

![System checking on three machines](img/screens/system-checking.png)

*"System checking": Pentagon 128, "Memory 128Kb" (`r99` 2652); Scorpion ZS-256, "Memory 256Kb", TR-DOS 5.03
(`s99` 2252); Pentagon in 48 BASIC, paging locked, "Memory 56Kb" (`r99-48` 5651).*

| ![](img/screens/99-system-checking.png) | ![](img/screens/99-system-checking-scorpion.png) | ![](img/screens/99-48-system-checking.png) | ![](img/screens/99-48-end.png) |
| --- | --- | --- | --- |
| Pentagon 128 (`r99` 2652) | Scorpion ZS-256 (`s99` 2252) | 48 BASIC (`r99-48` 5651) | 48 BASIC: `0 OK` (`r99-48` 6501) |

On 128 K the start-up menu follows. On the 48 K path (`r99-48`) the load ends in BASIC with `0 OK`
(frame 6501): no recording reaches a 48 K game ([03](03-build-and-load.md)).

## 1.4 The '99 start-up menu

One screen with a pointer (Q A O P, SPACE: [05](05-controls.md)). Three columns of settings and six actions; the
chosen setting of each group is white, the others coloured; the title changes colour every few frames.

| ![](img/screens/99-menu.png) | ![](img/screens/99-menu-hard-phasers.png) |
| --- | --- |
| as it comes up: EASY, KEYBOARD, upgrades ELECTRONIC and ANTI-GRAVS (`r99` 3002) | after HARD and PHASERS (`r99` 6052) |

| Item | What it does |
| --- | --- |
| LEVEL: EASY, MEDIUM, HARD, CRITICAL | the difficulty (1.6) |
| UPGRADING: ELECTRONIC, NUCLEAR, PHASERS, MISSILES, CANNON, ANTI-GRAVS | toggles: the parts every enemy robot is given each day (1.6) |
| CONTROL: KEYBOARD, KEMPSTON, INTERFACE, REDEFINE | the device; REDEFINE asks for seven keys ([05](05-controls.md)) |
| START | play on the current map |
| LOAD MAP | the disk's catalogue of `.N` maps; the chosen one replaces the current map (1.7) |
| DESCRIPTION, ADVICES, GREETS, ABOUT ZS NE | the four texts, one page each, scrolled with A |

![The four text pages](img/screens/99-text-pages.png)

*The text pages: DESCRIPTION (`r99` 4152), ADVICES (4552), GREETS (4852), ABOUT ZS NE (5152). Their texts in full
with translations: [NEdescri](texts/NEdescri.md), [NEadvice](texts/NEadvice.md), [NEgreets](texts/NEgreets.md),
[NEabout](texts/NEabout.md).*

ABORT in play returns here (`x99` 5302), not to Nether Earth's menu.

## 1.5 The '98 menu

Nether Earth's menu with the title "ZS EDITION'98" in cycling colours. Items 0-4 are Nether Earth's; 5 LOAD SAVED
GAME became 5 LOAD NEW LEVEL!. Pressing 5 changes nothing on the screen (`x98` 5000); START after it crashes: the
screen fills with garbage and the game hangs (`x98` 5600). Stage 1 found why: key 5 copies 500 bytes from `$DD00`,
inside the intro's scroller text, as if they were a map ([03](03-build-and-load.md)).

| ![](img/screens/98-menu.png) | ![](img/screens/98-load-new-level.png) | ![](img/screens/98-load-new-level-start.png) |
| --- | --- | --- |
| the menu (`r98` 4703) | after 5 (`x98` 5000) | 0 START after 5 (`x98` 5600) |

![Nether Earth, ZS'98 and ZS'99 menus](img/compare/menu.png)

*The menus: Nether Earth (`ne-play` 12750), ZS'98 (`r98` 4703), ZS'99 (`r99` 3002). The '98 only renames the
title and item 5; the '99 replaces the menu by its own screen.*

## 1.6 Difficulty and upgrades ('99)

The author's account ([NEabout](texts/NEabout.md), [NEZSEd99](texts/NEZSEd99.md), [NEdescri](texts/NEdescri.md)):
four levels, EASY to CRITICAL, even EASY "an order of magnitude harder than the original"; only on EASY does the
enemy depend on the factories and bases it holds; UPGRADING makes every enemy robot be built up each day to at least
the parts the player marked, on every level but CRITICAL, which uses the author's own setting. Stage 1 found the
level choice patching five places of the game from a table at `$D980` (`$B87E`, `$D2C8`, `$AE41`, `$A5E7`,
`$A5E5`); what each does is the game agents' (1.10).

The '98 has no choice: its scroller ([text](texts/scroller98.md)) claims unlimited enemy money, more money for the
player, enemy upgrades of robots already built and a map that favours the enemy.

## 1.7 Maps

LOAD MAP shows the disk's catalogue of `.N` files, four to a row, the current one highlighted; A moves to the next,
Q back, SPACE loads it and returns to the menu ([05](05-controls.md)). The twelve maps of the disk are 512 bytes
each and hold up to 28 bases (stage 1); the readme claims up to 96 maps a disk.

| ![](img/screens/99-load-map.png) | ![](img/screens/99-load-map-nelev06.png) |
| --- | --- |
| LOAD MAP, `NELEV_00` highlighted (`r99` 5452) | moved to `NELEV_06` (`x99` 4127) |

The map built into the game is a joke: its walls spell `ЗАГРУЗИСЬ` ("load up!") across the radar, so START without
LOAD MAP tells the player to load a map.

| ![](img/screens/99-play-builtin-scorpion.png) | ![](img/screens/99-play-nelev00.png) | ![](img/screens/99-play-nelev06.png) |
| --- | --- | --- |
| the built-in map, Scorpion (`s99` 3302) | `NELEV_00` (`r99` 6402) | `NELEV_06` (`x99` 4602) |

## 1.8 Play

Play is Nether Earth's: the isometric view, the status panel, the resources, the radar. The panel shows what
changed: the enemy's robot count is hidden ('98: blank; '99: `??`), GENERAL starts at 99 instead of 20, the frame
of the view is cyan instead of white, the ground is non-bright yellow, and a '99 map can have more war bases
(`NELEV_06`: 4 each side; `NELEV_00`: 3 each side).

![Nether Earth, ZS'98 and ZS'99 at the start of play](img/compare/play.png)

*The start of play: Nether Earth (`ne-play` 12900), ZS'98 (`r98` 5000), ZS'99 on `NELEV_00` (`r99` 6150). ZS
hides the enemy's robot count, gives 99 GENERAL and draws the view's frame cyan.*

![Nether Earth, ZS'98 and ZS'99 while loading](img/compare/loading.png)

*What the player watches while the game loads: Nether Earth's tape border (`ne-play` 5000), the '98 intro
(`r98` 3000), the '99 intro (`r99` 1002), which loads the rest when SPACE is pressed.*

No recording reaches the end of a game (a win or a loss), so the end screens are not shown here.

## 1.9 What the player sees that Nether Earth does not have

- '98: "ZS'98 Presents", the intro with its scroller and music, the retitled menu, LOAD NEW LEVEL! (broken).
- '99: the photo intro with its scroller, "System checking", the start-up menu with LEVEL, UPGRADING, CONTROL,
  LOAD MAP and four texts, the REDEFINE screen without the SAVE key, the twelve maps and the `ЗАГРУЗИСЬ` map.
- Both: `??` / blank enemy robot count, 99 GENERAL.

## 1.10 The author's claims against the code

filled from the game agents' tables
