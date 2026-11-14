# Bumpy: walkthrough

How the reverse was done, step by step, and which unreal-ng call answered each question. Terms:
[docs/README.md](docs/README.md). Recipes: `../recipes/`.

Every recording is named with its load (ROM speed or the fast LD-BYTES trap) beside every frame number.

## 0. The medium

1. **Which game.** The owner wrote "BAMPY". The collection index (`index/zx-image-locations.tsv`) and ZXDB have no
   game of that name; Bumpy (ZXDB 763, Loriciels 1989, "ZX-Spectrum 48K", Arcade Game: Platform, up to 2 players) is
   the only match. Spectrum conversion by Luis Jorge Garcia and J250 (ZXDB; the loading screen and the menu say the
   same). Two releases: Loriciels 1989 and Proein Soft Line 1989 (Spain, tape and +3 disk).
2. **The original.** ZXDB's file for the Loriciels release is `pub/sinclair/games/b/Bumpy.tap.zip` (the share's
   `software/zxdb/files`); it went unchanged into `orig/`. Its `BUMPY.TAP` has the same three data blocks byte for
   byte as the Proein TZX, which is a real dump (irregular pauses, the archive info naming Loriciels, Proein and the
   two converters). The TAP is a transfer of that tape (pauses not kept), the only file ZXDB lists for release 0.
3. **The other copies.** `tools/fetch_copies.py` copied every indexed copy into `work/candidates/<source>/` (SHA-256
   checked, `work/stage1/fetch-copies.txt`); `tools/copy_compare.py` scored each by the 256-byte pieces of the
   original's blocks it holds (`work/stage1/copy-compare.tsv`). The table with what differs is in the
   [README](README.md#other-releases-and-copies): the +3 disk is another build from `$AB7D` on; TOSEC's "(FR)(en)"
   TAP/TZX is a transfer without the loading screen (the code plus 300 zero bytes); the rest are translations, hacks
   and packed TR-DOS or Microdrive conversions.
4. **The blocks.** `kit/tapblocks.py list`: six standard blocks, the BASIC, the screen at `$4000` and one 38 700-byte
   code block at `$61A8` ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)); no turbo, no packer,
   no protection.
5. **Helpers found.** ZXDB lists an RZX of the whole game (xmikex and Jamie Angus, SPIN 0.5, 150 437 frames,
   recorded with rollback), a POKE file, and a known-errors note on the Kempston port (5). GitHub has no SkoolKit
   disassembly (searched once: repositories "bumpy zx spectrum", "bumpy disassembly", code `*.skool`).

## 1. One recording from power-on

**c1** (`tools/record.py c1`, input `tests/inputs/c1.txt`, `work/stage1/c1/`: `session.ttd`, `l1.json`, `screens/`):
a 48K at power-on, `LOAD ""` typed, the original `BUMPY.TAP` at ROM speed, 18 186 frames.

| Frame | What |
| --- | --- |
| 150 | the ROM's copyright, `LOAD ""` typed |
| 682-13 682 | the BASIC, the loading screen ([shot](docs/img/play/c1-010182-loading.png)), the code; the tape ends at 13 682 |
| 13 357 (T 19 678) | the first fetch of `$AB7C`, the entry (the image as loaded, [doc 2, 2.2](docs/02-architecture.md#22-the-images)) |
| 13 782 | the menu ([shot](docs/img/play/c1-013782-menu.png)); 1 twice, 2 (keyboard), 0 (game) |
| 14 018 | READY? ([shot](docs/img/play/c1-014018-ready.png)), the timer at 1000 |
| 14 082 | play on level 0: O P Q A SPACE in turn for about 1000 frames (a drop at 14 162, a key at 14 990, [shot](docs/img/play/c1-015086-play.png)) |
| 15 436-18 186 | no key: the timer runs down to 0 and stays there; the ball keeps bouncing ([shot](docs/img/play/c1-018186-timer-zero.png)) |

**Interrupts.** IM 1 all the time: the handler is the ROM's `$0038` (`$02BF`, the keyboard scan), which the game does
not need (it reads the ports itself at `$B418`). An IM 2 setup exists at `$F343` and `$F388` (I = `$FE`, vectors at
`$FDFD`) but no recording ever executes it (the L1 of every recording, [doc 2, 2.6](docs/02-architecture.md#26-the-memory-map)).
Interrupts are off most of the time: the input routine `$B418` begins with `DI` and, with no stick moved (the low five
bits of port `$DF` all 1), returns by `RET Z` at `$B431` before its `EI` at `$B434`. They come back on only at the
waits, each an `EI: HALT`: the frame wait `$B6E9`, and `$B35A`, `$B7BE`, `$C4DF`. c1 takes 4534 interrupts in 18 186
frames (911 T an entry); `rzx/l00` 902 in 1097.

**The main loop** `$ACC8`, one pass:

1. the work: `$BB32`, `$BB05`, `$BE94`, `$BFF3`, `$C19D`, `$C43E`, `$BBCD`, `$BC30`, `$BD21`, `$B7D1` (the timer),
   `$BA60`;
2. the keys: R (`$2B`) to `$B7B2` (back to the menu), D (`$32`) to `$ADDF` (a `RET`: a disabled cheat), the pause key
   (slot 6 of `$F084`, H) to `$B440` unless in the demo (`$ABA6`), S (`$31`, `$AE7A`) loses a life (`$BA71`);
3. the frame wait: `$AD0C` calls `$B87E`, which calls `$B6E4`: `$E58B`, then `EI` (`$B6E9`), `HALT`, `$B6EB`;
4. the state dispatch on `$AA00 & 15` through the table `$AD29` (`$AE5F`, `$AEDB`, `$AF55`, `$AFCF`, `$B064`, `$B11A`,
   `$B14A`, `$B20A`, `$B2C2`).

**Frames per pass, measured.** `tools/rzx_passes.py` replays the whole RZX (SkoolKit `rzxplay`, frames 172-150 434, all
100 levels, `work/stage1/passes.tsv`) and logs every fetch of `$B6E9` and `$B6EB`: 75 591 passes. A pass in play
(75 475 of them, 96 804 frames) takes:

| Frames | Passes | Share |
| --- | --- | --- |
| 1 | 59 952 | 79.4 % |
| 2 | 11 686 | 15.5 % |
| 3 | 2127 | 2.8 % |
| 4 | 1459 | 1.9 % |
| 5 | 244 | 0.3 % |
| 6-7 | 7 | |

1.28 frames a pass on average; the work between the `HALT` and the next wait is 35 367 T in the median pass and
140 254 T at the 95th percentile. The game runs at 50 passes a second most of the time and slows down when much is
redrawn. The heaviest pass in play is at RZX frame 125 362 (level 83): 457 406 T of work, 7 frames. The other 116
passes are not play: 16 of 40 frames (the pause when an extra life is given, at RZX frames 7801, 8798, ... 132 556),
and the level ends, 114 to 1285 frames each, where the timer left is counted into the score a point a step (`$B35F`,
an `EI: HALT` and the tick `$F4F9` a step).

## 2. Static pass over the medium

`kit/tapblocks.py list` cut the tape; `tools/image.py` writes the game image `work/mkgame/original.bin` (the code
block at `$61A8`, as LD-BYTES leaves it), the image `case.json` names. Stage 2 merged five region fragments
(`work/stage2/ann/`) into `src/game/game.ann`; `kit/mkgame.py` walked the code from the entry `$AB7C` and from every
recording's L1 and wrote the 14 modules ([stage 2 NOTES](work/stage2/NOTES.md)). The level format was read from
BuildLevel `$CF2E` ([doc 2, 2.5](docs/02-architecture.md#25-the-levels-as-data)); `tools/fig_levels.py` draws the 100
levels from `src/res/levels/levels.txt` alone.

## 3. The stages and the packers

There are none: the code runs where `LD-BYTES` put it ([doc 3, 3.2](docs/03-build-and-load.md#32-the-loader)).

## 4. The medium from source

`tools/build.sh` assembles the BASIC (`src/tape/basic.ann`), the loading screen (`src/screen/screen.ann`) and the game
(`src/game/game.ann`, 15 module files, 60 resources in `src/res/`) and writes `build/BUMPY.TAP`, identical to
`orig/Bumpy.tap.zip`'s `BUMPY.TAP` byte for byte ([doc 3, 3.3](docs/03-build-and-load.md#33-the-source-build));
`tools/res_formats.py check` converts each of the 44 editable resources back to its bytes (0 bad).

## 5. Tool gaps found and fixed in unreal-ng

| Gap | Fix | unreal-ng commit |
| --- | --- | --- |
| The game reads its Kempston stick with `IN A,($DF)` at `$B42B`; A still holds the last keyboard row ORed with `$E0`, `$FF` with no key held, so the port is `$FFDF`. unreal-ng fits a Kempston mouse on every model (`[INPUT] Mouse=`, no runtime switch), and the mouse answers `$FFDF` with its Y counter (85 at reset): the low five bits `$15` are not `$1F`, so the game stores their complement `$EA` at `$B43E` as a stick held, and its "wait for no key" `$B401` never ends at READY? | none in unreal-ng yet. Workaround in `tools/lab.py` `quiet_mouse`: `POST /mouse/counters {"x":0,"y":0}`, which reads as an idle stick (the game stores `$FF`). Counters of 255 were tried first and are not enough: the game rewrites `$B43E` only when the five bits are not `$1F`, so a value left by an earlier read (the demo left `$EA`) stays and READY? hangs (the first `menu` recording). The RZX replays set `$B43E` = `$FF` once at their start (SPIN left another value there) | |

## 6. The game

### 6.0 The recordings

All on unreal-ng's 48K, muted, each on a port base of its own (37510, 37515, 37600); each keeps its `session.ttd`,
`l1.json`, `record.json` (the plan, the moments, the state at each, the POKEs) and `screens/` in its folder, and its
input script in `tests/inputs/`. A snapshot start is said; every POKE is said in the recording's `record.json` and
here. Every command runs from the case folder after `. work/env.sh`.

| Name | Folder | Start | Frames | What it reached |
| --- | --- | --- | --- | --- |
| `c1` | `work/stage1/c1` | power-on, `LOAD ""`, the original tape at ROM speed | 18 186 | section 1: the load, the menu, keyboard play on level 0, the timer at 0 |
| `menu` | `work/stage1/menu` | a snapshot after a fast load (`work/stage1/probe/load-fast-nokemp/end.szx`, the LD-BYTES trap), Kempston fitted, the mouse quiet (section 5) | 12 760 | 4000 frames idle, SPACE, then options 2, 3 and 4 each with moves, H, H, R; two players; R, 1, 2, then 0 with R, SPACE and V held: the demo (levels 10 and 11, frames 250-4000; [shot](docs/img/play/menu-001500-demo.png)) and back to the menu (4204); keyboard play (5352-6228) with the pause (H at 5756, the timer held to 5924; [shot](docs/img/play/menu-005820-pause.png)) and R back to the menu; Sinclair (6376-7252); option 4, Kempston: the stick reads nothing (the card does not answer port `$DF`, section 5), READY? stays up until H (7400-7972; [shot](docs/img/play/menu-007604-kempston.png)); two players (8320, [shot](docs/img/play/menu-008320-two-players.png)): player 1 bouncing in place with no key through 12 300; the cheat (12 656: water, keys, hammers and lives 99, "PLAYER 1 READY?"; [shot](docs/img/play/menu-012656-cheat.png)) |
| `gameover` | `work/stage1/gameover` | the same snapshot | 6444 | game 0, keyboard, moves, then S three times with SPACE at each READY?; game 1, the score `$AAFB` POKEd to 2000, S three times, then B U M ENTER: lives 2 to 1 at 602 ([shot](docs/img/play/gameover-000602-life-lost.png)) and 1 to 0 at 1080, game over after the third S (1458), the menu (2072); game 1: the hall of fame (4618, [shot](docs/img/play/gameover-004618-hall-of-fame.png)) with a fourth entry of 2000 replacing POP's 1700; the name stayed "@..": the letters are stepped by right and left and fixed by fire or up, not typed (EnterName `$ECC0`, [doc 8, 8.9](docs/08-hud-and-text.md#89-the-name-entry)) |
| `rzx/l00`-`rzx/l99` | `work/stage1/rzx/lNN` | the RZX's own state at each level's play start (`tools/rzx_levels.py`, `work/stage1/rzx/levels/play-F.z80`), `$B43E` POKEd to `$FF` once | 405-3999 each, 110 790 in all | the RZX player's keys for that level (`tools/rzx_keys.py`) frame by frame: 88 reach the next level as the RZX does; `l99` reaches the wrap to level 0 (frame 1154, [shot](docs/img/play/rzx-l99-001154-level-99-end.png), [level 0 again](docs/img/play/rzx-l99-001685-level-0-again.png)); 12 drift from the RZX and stop on their own level (`l10`, `l35`, `l36`, `l45`, `l51`, `l56`, `l59`, `l68`, `l83`, `l96`, `l97`, `l98`): a key the RZX's player pressed between two of the game's reads of one frame ([stage 2 NOTES](work/stage2/NOTES.md), leftover 1); their deaths are the deaths of the drifting replays |
| `rec/l10` ... `rec/l98` (12) | `work/stage2/rec/lNN` | the same play-start states, `$B43E` POKEd to `$FF` | 653-1819 | the 12 lost levels finished by the `events` plan (l10, l35, l36, l45, l51, l68, l83, l97) or the `passes` plan (l56, l59, l96, l98): the RZX player's decisions looked up by the game's own progress; inputs `tests/inputs/solve-lNN.txt`; with stage 1's 88 every level 0-99 has a recording of being finished |
| `fire` | `work/stage2/rec/fire` | level 38's play start, `$B43E` = `$FF` and Water `$AAFD` POKEd to 0 | 300 | left (Sinclair 6) onto cell 31, platform 9: LeftFireDeath `$CA7A` at frame 41, Lives 10 → 9 ([shot](docs/img/play/fire-000070-burst.png)) |
| `twoname` | `work/stage2/rec/twoname` | `load-fast-nokemp/end.szx` | 6021 | two players to the end, turns passed by S; the score POKEd to 2000 (frame 2118) and 2100 (frame 3711) before each last life; B U M and Z A P entered by right, left and fire ([shot](docs/img/play/twoname-003300-name.png), [the hall](docs/img/play/twoname-005300-hall.png)) |
| `scoreloop` | `work/docs/integrate/rec/scoreloop` | level 87's play start (`play-130843.z80`), `$B43E` = `$FF` | 1552 | the points loop: the RZX player's keys numbered by the timer for the first 330 passes (six prizes and the bottle), then S, three times; score 36 081 → 36 171 → 36 261 → 36 351, lives 16 → 17 → 16 each round ([before S](docs/img/play/scoreloop-000400-before-s.png), [after S](docs/img/play/scoreloop-000484-after-s.png)) |
| `rightspike` | `work/docs/integrate/rec/rightspike` | level 75's play start (`play-113295.z80`), `$B43E` = `$FF` | 220 | right (Sinclair 7) from cell 30 onto the spikes of cell 31: RightSpikeDeath `$CCB8` once, Lives 15 → 14 ([shot](docs/img/play/rightspike-000066-burst.png)) |
| `exitbelow` | `work/docs/integrate/rec/exitbelow` | `load-fast-nokemp/end.szx`; level 0's record POKEd before the game: start cell (`$8C60`) 21, prizes (`$8C61`) 1, exit cell (`$8C62`) 15 | 375 | 2, 0, SPACE; right to cell 22 (the prize, frame 215: the exit opens on cell 15), left back to 21, up: the ball rises into the exit (UpStep5 `$CDD9` once) and level 1 starts at frame 275 ([below the exit](docs/img/play/exitbelow-000243-below-exit.png), [in it](docs/img/play/exitbelow-000275-in-exit.png)) |

The `work/docs/bmA/<name>` and `work/docs/bm/twoname` folders are no recordings: they are the docs writer's trace
windows over the recordings above (`c1`, `fire`, `rzx/l01`, `rzx/l21`, `rzx/l68`, `rec/l83`, `twoname`), opened
from their `session.ttd` with `python3 R/kit/rs.py open --work W --ttd REC/session.ttd --model 48K --ranges 4000-FFFF`;
the animations name them (6.2).

How they were made (port base 37510 unless said):

```sh
python3 tools/record.py c1 --work work/stage1/c1
python3 tools/record.py menu --start work/stage1/probe/load-fast-nokemp/end.szx --work work/stage1/menu
python3 tools/record.py gameover --start work/stage1/probe/load-fast-nokemp/end.szx --work work/stage1/gameover --port-base 37515
python3 tools/record.py rzx --rzx N N --work work/stage1/rzx/lNN                  # N = 0 ... 99
work/stage2/run-lost.sh 37510 10 35 36 45 51 68 83 97                             # tools/record.py events
PLAN=passes work/stage2/run-lost.sh 37510 56 59 96 98
python3 tools/record.py fire --rzx 38 38 --work work/stage2/rec/fire --port-base 37515
python3 tools/record.py twoname --start work/stage1/probe/load-fast-nokemp/end.szx --work work/stage2/rec/twoname
python3 tools/record.py scoreloop --rzx 87 87 --work work/docs/integrate/rec/scoreloop --port-base 37600
python3 tools/record.py rightspike --rzx 75 75 --work work/docs/integrate/rec/rightspike --port-base 37600
python3 tools/record.py exitbelow --start work/stage1/probe/load-fast-nokemp/end.szx --work work/docs/integrate/rec/exitbelow --port-base 37600
```

The RZX is someone else's play (xmikex and Jamie Angus, SPIN 0.5, recorded with rollback) and is a witness only of
the levels' layouts and of the order of play. Its own run never loses a life: its Lives only rise, 2 to 18, with its
16 bottles (`work/stage2/rzx-states.tsv`); the lives lost under `work/stage1/rzx/` are the drifting replays'.

### 6.1 The screens

Every screen the documents link, in `docs/img/play/` (a recording's `screens/` file, or drawn from its `session.ttd`):

| Recording, frame | Screen |
| --- | --- |
| c1 10 182 | [the loading screen](docs/img/play/c1-010182-loading.png) |
| c1 13 700 | [the menu as it first appears](docs/img/play/c1-013700-entry.png) |
| c1 13 782 | [the menu](docs/img/play/c1-013782-menu.png) |
| c1 14 018 | [READY?](docs/img/play/c1-014018-ready.png) |
| c1 14 130 | [a water drop taken](docs/img/play/c1-014130-water.png) |
| c1 14 200 | [the spring](docs/img/play/c1-014200-spring.png) |
| c1 15 086 | [level 0 in play](docs/img/play/c1-015086-play.png) |
| c1 18 186 | [the timer at 0, play goes on](docs/img/play/c1-018186-timer-zero.png) |
| `menu` 1500 | [the demo](docs/img/play/menu-001500-demo.png) |
| `menu` 5820 | [the pause](docs/img/play/menu-005820-pause.png) |
| `menu` 7604 | [Kempston: READY? stays](docs/img/play/menu-007604-kempston.png) |
| `menu` 8320 | [two players](docs/img/play/menu-008320-two-players.png) |
| `menu` 12 656 | [the cheat: 99 of everything](docs/img/play/menu-012656-cheat.png) |
| `gameover` 602 | [a life lost by S](docs/img/play/gameover-000602-life-lost.png) |
| `gameover` 4618 | [the hall of fame](docs/img/play/gameover-004618-hall-of-fame.png) |
| `rzx/l00` 971 | [every prize taken, the exit open](docs/img/play/rzx-l00-000971-exit-open.png) |
| `rzx/l01` 100, 700 | [the locks](docs/img/play/l01-000100-locks.png), [opened](docs/img/play/l01-000700-locks-open.png) |
| `rzx/l68` 700, 932 | [the fall out](docs/img/play/l68-000700-fall.png), [the burst on spikes](docs/img/play/l68-000932-burst.png) |
| `rec/l83` 100, 400, 540, 650 | [play](docs/img/play/l83-000100-play.png), [the exit open](docs/img/play/l83-000400-exit-open.png), [the sink](docs/img/play/l83-000540-sink.png), [the count](docs/img/play/l83-000650-count.png) |
| `rzx/l99` 1154 | [the end of level 99](docs/img/play/rzx-l99-001154-level-99-end.png) |
| `rzx/l99` 1685 | [level 0 again, the score kept](docs/img/play/rzx-l99-001685-level-0-again.png) |
| `fire` 30, 70 | [before the fire](docs/img/play/fire-000030-before.png), [the burst](docs/img/play/fire-000070-burst.png) |
| `twoname` 200, 2300, 3300, 5300 | [two players, READY?](docs/img/play/twoname-000200-two-ready.png), [the name entry starts](docs/img/play/twoname-002300-name-start.png), [the name](docs/img/play/twoname-003300-name.png), [the hall of fame](docs/img/play/twoname-005300-hall.png) |
| `scoreloop` 400, 484, 934 | [before S](docs/img/play/scoreloop-000400-before-s.png), [after S](docs/img/play/scoreloop-000484-after-s.png), [the second round](docs/img/play/scoreloop-000934-before-s.png) |
| `rightspike` 66 | [the right spike death](docs/img/play/rightspike-000066-burst.png) |
| `exitbelow` 243, 275 | [below the open exit](docs/img/play/exitbelow-000243-below-exit.png), [in it](docs/img/play/exitbelow-000275-in-exit.png) |
| every screen | [the contact sheet](docs/img/play/screens.png) |

Every level's start screen, from the RZX: [0-24](docs/img/maps/levels-00-24.png),
[25-49](docs/img/maps/levels-25-49.png), [50-74](docs/img/maps/levels-50-74.png),
[75-99](docs/img/maps/levels-75-99.png); the same drawn from the data in
[doc 2, 2.5](docs/02-architecture.md#25-the-levels-as-data).

### 6.2 The animations

| File | Document | Recording | Frames |
| --- | --- | --- | --- |
| [tape-load.gif](docs/img/load/tape-load.gif) | [doc 3](docs/03-build-and-load.md) | c1 | 600-13 800, every 240th |
| [MainLoop.gif](docs/img/routines/MainLoop.gif) | [doc 4](docs/04-game-loop.md) | `rec/l83` | 349 (T 1800 to 38 700) |
| [BuildLevel.gif](docs/img/routines/BuildLevel.gif) | doc 4, [doc 6](docs/06-rendering.md) | `rzx/l21` | 1534-1539 |
| [BallRight.gif](docs/img/routines/BallRight.gif) | doc 4, [doc 10](docs/10-gameplay-logic.md) | `rec/l83` | 349-378 |
| [OpenExit.gif](docs/img/routines/OpenExit.gif) | doc 4 | `rec/l83` | 341-347 |
| [LevelEnd.gif](docs/img/routines/LevelEnd.gif) | doc 4 | `rec/l83` | 518-530 |
| [level-end-l21.gif](docs/img/play/level-end-l21.gif) | doc 4 | `rzx/l21` | 1384-1542, every 2nd |
| [ChooseNextState.gif](docs/img/routines/ChooseNextState.gif) | [doc 1](docs/01-game-design.md), [doc 5](docs/05-controls.md) | c1 | 14 082-14 138 |
| [BrickStep.gif](docs/img/routines/BrickStep.gif) | doc 6, [doc 7](docs/07-objects.md) | `rzx/l01` | 147-157 |
| [BuildLevel-record.gif](docs/img/routines/BuildLevel-record.gif) | doc 7 | `rzx/l21` | 1534-1535 |
| [PlatformChangeStep.gif](docs/img/routines/PlatformChangeStep.gif) | doc 7, doc 10 | `rzx/l01` | 484-495 |
| [WallStep.gif](docs/img/routines/WallStep.gif) | doc 7 | `rzx/l01` | 586-625 |
| [DrawHud.gif](docs/img/routines/DrawHud.gif) | doc 7, [doc 8](docs/08-hud-and-text.md), doc 10 | c1 | 14 127-14 130 |
| [PrintText.gif](docs/img/routines/PrintText.gif) | doc 8 | c1 | 13 926 (T 35 900 to 52 100) |
| [EnterName.gif](docs/img/routines/EnterName.gif) | doc 8, doc 4 | `twoname` | 3030-3300 |
| [BallBounce.gif](docs/img/routines/BallBounce.gif) | doc 10 | c1 | 14 082-14 138 |
| [LeftFireDeath.gif](docs/img/routines/LeftFireDeath.gif) | doc 10 | `fire` | 40-85 |
| [BallBurst.gif](docs/img/routines/BallBurst.gif) | doc 10 | `rzx/l68` | 920-947 |
| [BallFallOut.gif](docs/img/routines/BallFallOut.gif) | doc 10 | `rzx/l68` | 682-715 |

## 7. Review

Docs 01-10 written (one writer, `work/docs/bm-*`), integrated (sources, docs 11 and 12, the three integration
recordings); in review. Open points for the reviewers: `work/review/open-from-writers.md`.
