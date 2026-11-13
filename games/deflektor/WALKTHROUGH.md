# Deflektor: walkthrough

How the reverse was done, step by step, and which unreal-ng call answered each question. Terms:
[docs/README.md](docs/README.md). Recipes: `../recipes/`.

Every recording is named with its load (ROM speed or the fast LD-BYTES trap) beside every frame number.

## 0. The medium

The case starts from ZXDB 1327 (Deflektor, Gremlin Graphics, 1987; Costa Panayi; music Ben Daglish and John
O'Brien). ZXDB lists the Gremlin tape, the Spanish Erbe re-release, a re-saved TAP, a +3 disk, the compilations
(10 Mega Games Volume One, Load 'n' Run 48, ZX-Spectrum Vega), an RZX run, a POKE file and the AY rip. The original
is `orig/Deflektor.tzx.zip` from ZXDB's `pub/sinclair/games/d/` (hashes in the [README](README.md)).

The release check (`tools/media_compare.py`, `work/stage1/media-compare.txt`): the Erbe TZX has the same header and
BASIC and a turbo block that differs in 32 bytes from offset 306; the TOSEC 2020 TZX and TAP differ from ZXDB's in the
turbo block's last byte only (the bits after the last used ones) and are written at standard timing; the 10 Mega Games
tape holds the three blocks byte for byte with the same timing. Every other copy the collection index lists was copied
unchanged into `work/candidates/<source>/` (`tools/fetch_copies.py`, `work/stage1/fetch-copies.txt`) and scored by
the share of the game it holds in 256-byte pieces (`tools/copy_compare.py`, `work/stage1/copy-compare.tsv`). Since the
turbo block is in the loader's own code, the reference is the game in memory from `c1`: `$6000-$DFFF` at the entry
`$8382` (frame 15 752). The tape hacks hold 84 to 116 of the 128 pieces; the ZXDB TAP (a re-save with a 23 266-byte DEFL.CDE at
`$6000`) is packed. The disk and Microdrive conversions and the translations are listed in one line and not studied
(the owner's rule for non-standard versions). The table is in the README.

The tape is three blocks: a Program header "DEFLEKTOR", a 384-byte BASIC whose machine code (at `$5D05`) moves the
loader to `$B626`, and one turbo block of 58 316 bytes (flag `$19`, 296.74 s) that the loader reads in its own pulse
code ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)). The loader (D.G. Cooke 1987, "[Search
Loader]" in TOSEC) loads a second stage over its own end that runs as it arrives, then the game; a mover at `$5C00`,
a decrypting stage at `$7B52` and a second mover at `$FD00` lead to the entry `$8382`.

The original TZX does not load in unreal-ng. Its turbo block is the last block of the tape with pause 0; the loader
waits for an edge after the last pulse, which never comes. In `work/stage1/probe/orig.log` (`work/stage1/probe_tape.py`,
port base 37480, ROM timing) the load runs to IX = `$9DF0`, the tape ends near frame 15 640, the loader times out and
jumps to `$0000`. The 10 Mega Games tape (`work/media/mega/mega-games-1.tzx`: the same three blocks byte for byte, the
same timing, then a 16 561 ms pause and the next game) loads (`work/stage1/probe/mega.log`), and so does the TOSEC
standard-timing dump (`work/stage1/probe/tosec.log`). `c1` loads the 10 Mega Games copy: the pulses the loader reads
are the original's. The gap is in "For the lead (kit)", `work/stage1/NOTES.md`.

Other sources: the RZX archive's `deflektor.rzx` (Roman Rugalenko, recorded with rollback; someone else's run through
all 60 levels), ZXDB's instructions, map and POKE file (`work/candidates/zxdb-*`). No SkoolKit disassembly exists on
GitHub (one search, `work/stage1/NOTES.md`).

## 1. One recording from power-on

`c1`: the 48K from power-on, `LOAD ""` typed, the 10 Mega Games tape at ROM timing (`tools/rs_capture.py
--record-load --load-frames 15700`, port base 37485, fast and turbo tape off), then `tests/inputs/c1.txt`: the title,
SPACE, the options panel (3, 4, 2, 1, then 7 START GAME), level 1 with the cursor moved and mirrors turned. 20 560
frames. The stages (`$RS stages --work work/stage1/c1`): the BASIC's code `$5D05` at frame 771, the loader `$B65B` at
771 T 61 700, its second stage `$B856` at 1006 T 38 026, `$5B00` at 15 635 T 27 704, `$5C00` at 15 640 T 44 028,
`$7B52` at 15 651, the game's entry `$8382` at 15 752 T 33 930 ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)).
`c1g` is `c1`'s game window, built from frame 15 752 T 33 930 (`$RS build --from-frame 15752 --from-tinframe 33930 --into work/stage1/c1g`): 4808 frames, 52 routines.

The interrupts and the timing, a first look:

- **IM mode and handler.** The load runs in IM 1 with interrupts off (the loader's `DI` at `$B67D`). The game sets
  IM 2 at `$A2FA`: `JP $A32A` at `$FDFD` (`LD A,$C3; LD ($FDFD),A; LD HL,$A32A; LD ($FDFE),HL`), the table `$FE00-$FF00` filled with `$FD` (`$A311-$A31B`), `I` = `$FE`, `IM 2` (`$A320`); `$A323` goes
  back to IM 1 with `I` = `$3E`. The handler `$A32A` pushes HL, DE, BC, AF; when `$A103` is set it takes the path at
  `$A459`; otherwise it counts `$A506` (the energy tick) and `$837F` (a frame counter), scrolls the COMPUTER line's
  message (`$A10D-$A110`) and calls `$A8A7` (`$RS interrupts`: in `c1g` 4473 entries in 4808 frames, 3377 T an entry,
  4.5 % of the CPU; in the RZX segment `rzx-004833` 7019 entries in 7019 frames, 3344 T, 4.8 %).
- **DI and EI.** `DI` at `$8408` (new game) to `EI` at `$843B`, `$973F`-`$97B7` and `$97C0`-`$97EE` (the pause),
  `$9BC0`-`$9CB7` (the menu's set-up), `$A735`, `$A757`-`$A774`, `$A802`, `$AAB6`-`$AAB7`, `$AD79`-`$ADA5`, and `$8885`
  (the ending), `$9DD2` (from `work/stage1/dis/e4.txt`, the entry image). In play every frame takes its interrupt:
  the RZX segments' L1s count as many interrupts as frames (`rzx-004833`: 7019 in 7019).
- **The main loop.** `$843C` sets up the level (the LEVEL digits from `$88B0`, the flags `$96C3`, `$96C4`, `$8ED2`
  cleared); the pass runs from `$854A`: `$97F0` (the keys), `$999F`, `$8960` (the grid drawn into the buffers), then
  the level-complete test (`$A509`, `$8ED2`: `$81FF` + 1, `JP $843C`, or `JP $840C` after level 60), the beam, the
  bars (`$A683` the overload), and back to `$854A` (`$865D`, `$8B58`). No HALT in the pass: the HALTs are at `$82FE`,
  `$8302`, `$8788` and `$9F77`, outside it.
- **Frames per pass.** The pass reads the keyboard once at `$97F6` (port `$DFFE`). In the RZX run (SkoolKit's
  simulator, `tools/rzx_dump.py --pc-log 97F6`, `work/stage1/rzx-pass/pclog.json`) it is read 67 414 times between
  RZX frames 630 and 344 704; leaving out the 60 gaps of more than 50 frames (the level changes), 67 354 passes take
  326 855 frames: 4.85 frames a pass. The gaps are 2 frames 1845 times, 3: 11 338, 4: 16 861, 5: 16 789, 6: 11 726,
  7: 5519, 8: 2127, 9: 832, 10-17: 257, and 23-25 frames 60 times, the first pass of each level (RZX frames 786,
  5237, 12 130, ...: about 400 frames after each `$81FF` change). On our instance the L1s of the RZX segments give
  the same order: `rzx-004833` 7019 frames, 1247 passes (`$854A`), 5.63 frames a pass; `rzx-011752` 5.15;
  `rzx-017741` 3.38; `rzx-024486` 3.76; `c1g` (menu and level 1) 4.61.
- **The heaviest frame.** The pass never waits for the frame, so every frame in play is full; the heaviest pass is
  the first of each level, 23 to 25 frames (above).

## 2. Static pass over the medium

The tape's blocks were cut by `tools/tzxblocks.py` (`work/stage1/blocks/`): the BASIC (`basic.bin`, listed by
`tools/basic_list.py`), its machine code (`code5d05.bin`), the loader as moved to `$B626` (`ldr_b626.bin`) and the
second stage as loaded (`ldr2.bin`). The game itself was read from memory, not from the tape: the entry image
`work/stage1/images/entry.cpu.bin` (`tools/ttd_dump.py`, `c1` frame 15 752 T 33 930) disassembled with z80dasm
(`work/stage1/dis/e4.txt`, `$8000-$AFFF`).

The level format was found from the code ([doc 2, 2.1](docs/02-architecture.md#21-the-memory-map)): `$891A` takes
135 bytes from `$B000 + $87 x $81FF` into the grid `$FD23`, `$8960` and `$8A09` draw it. `tools/level_maps.py` runs
`$891A` in SkoolKit's simulator for each of the 61 slots and draws the buffers it fills: the
[first map of the levels](docs/img/maps/all.png) (`docs/img/maps/level-NN.png`, `levels.json` with each level's
address and bytes). `tools/tile_sheet.py` draws every cell code from the table `$8200` and the characters
`$D700` / `$DF00` ([the tile sheet](docs/img/sprites/tiles.png)); `tools/gfx_sheet.py` the font at `$D100`, the
cursor at `$9A37` and the LEVEL digits at `$88B0` ([the font sheet](docs/img/sprites/font.png)).

## 3. The stages and the packers

The stages of `c1` are in [doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block). Stage 2 of the reverse
proves each one against the recording byte for byte; for now the image in `case.json` is `c1`'s memory at the entry
(`tools/image.py`).

The images and what changes between them (`work/stage1/images/`, compared byte by byte from `$4000`):

| Image | Where from | Changed from the one before |
| --- | --- | --- |
| as loaded: `loaded.cpu.bin` | `c1` frame 15 635 T 27 704, the loader's last jump (`$5B00`) | - |
| at the entry: `entry.cpu.bin` | `c1` frame 15 752 T 33 930, `JP $8382` | 42 240 bytes, all of `$5B00-$FFFF` that changed: the movers and the decrypting stage rewrite the whole block |
| at the title: `menu.bin` | `work/stage1/probe/menu.szx`: the same ROM-timing load in a probe, frame 17 000 | 14 084 bytes: the screen `$4000-$5ADF`, a few variables (`$8E34-$8E39`, `$9B84-$9B89`, `$A103-$A111`), the buffers `$E201-$FCFB`, `$FDFD-$FF00` (the IM 2 jump and table), the stack `$FFF5-$FFFE` |
| in play, level 1: `play0.bin` | `work/stage1/probe/game0.szx`: the probe after 7 START GAME | 14 639 bytes: the screen, the variables `$8374-$8380`, `$8913-$8917`, `$8C78-$8C94`, `$8EBF-$8ECE`, `$9B4E-$9B7D`, `$A103-$A111`, `$A506-$A50B` (the bars), `$A63C` (the level's energy rate), `$AB63-$AB96`, the buffers `$E001-$E87F` and `$E900-$FDFA` (the level grid), the stack |

Between the entry and play the game image (`$8200-$DFFF`) changes only in its variables and in one operand: the
level set-up `$84CD` writes the level's energy rate from the table `$8385` into `$A63C`, the operand of `CP $64` at
`$A63B` (self-modifying code; the other byte goes to `$AB95`). The levels at `$B000-$D1BF` are read only (`$891A` copies them to `$FD23`).

## 4. The medium from source

## 5. Tool gaps found and fixed in unreal-ng

| Gap | Fix | unreal-ng commit |
| --- | --- | --- |
| A TZX turbo block that is the last on the tape with pause 0 gives no final edge: `orig/Deflektor.tzx` loads to IX = `$9DF0` and the loader jumps to `$0000` (WALKTHROUGH 0) | none yet: `c1` loads the 10 Mega Games copy (the same blocks and timing); reported in `work/stage1/NOTES.md` "For the lead (kit)" | - |

## 6. The game

Deflektor as it plays (seen in the recordings below): a cursor (the 16 x 16 square at `$9A37`) moves over a field of
15 x 9 cells; holding fire on a mirror and pushing left or right turns it. The laser starts with "CHARGING LASER";
its beam bounces off mirrors, passes the cyan blocks one way, is turned by the yellow ones and must burn every cell
(the round `$40`) before the receiver opens. The beam back into the laser ("OVERLOAD", a step a pass) or onto a mine ("MINE ALERT", four steps a pass)
fills the OVERLOAD bar; the ENERGY bar runs down with time ("ENERGY LOW", "ENERGY LEVEL CRITICAL", "ENERGY DRAINED"); a full
overload or no energy costs a life (the screen turns red, "BOOM BOOM BOOM") and the level starts again. Three lives;
60 levels; after level 60 the ending ("CONGRATULATIONS, YOU ARE TRULY A MASTER DEFLEKTOR, THE CIRCUIT IS NOW COMPLETE,
THE TEA WILL BE READY IN FIVE MINUTES!") and a name for the hall of fame. The options panel: 1 KEYBOARD, 2 SINCLAIR,
3 KEMPSTON, 4 PROTEK-AGF, 5 DEMO, 6 PRACTICE, 7 START GAME, beside the HALL OF FAME (MEGA 090000 to AWFUL 015000).

### 6.0 The recordings

All on unreal-ng's 48K, muted, port bases 37480 and 37485; each keeps its `session.ttd` in its folder. A snapshot
start is a state saved by `work/stage1/drive.py` or `tools/rzx_dump.py`; the POKEs are said where used.

| Name | Folder | Start | Inputs | Frames | What it reached |
| --- | --- | --- | --- | --- | --- |
| `c1` | `work/stage1/c1` | power-on, `--record-load`, the 10 Mega Games tape at ROM timing ([1](#1-one-recording-from-power-on)) | `tests/inputs/c1.txt` | 20 560 | the load and every loader stage, the title, the options panel (3, 4, 2, 1, 7), level 1 with the keyboard: cursor moves, mirrors turned |
| `c1g` | `work/stage1/c1g` | a build of `c1` from frame 15 752 T 33 930 (the entry `$8382`) | as `c1` | 4808 | the game window of `c1` |
| `menu` | `work/stage1/menu` | `work/stage1/probe/menu.szx` (the title after the same ROM-timing load, frame 17 000) | `tests/inputs/menu.txt` | 9000 | the title and its tune for 3000 frames, the options, 5 DEMO (the demo shows levels 14, 23, 37, 55, 59: [screen 4500](docs/img/play/demo.png)), SPACE ends it, 6 PRACTICE ([screen 7750](docs/img/play/practice.png)), U + G aborts, the title |
| `controls` | `work/stage1/controls` | `menu.szx` | `tests/inputs/controls.txt` | 7000 | 1 KEYBOARD (`$987B` 317 times), P pauses ("INTERMISSION ... PRESS ENTER FOR MORE ACTION", `$973F`), the pause's tune, ENTER goes on (`$97C0`), U + G "GAME ABORTED" ([screen 2000](docs/img/play/game-aborted.png)); 4 PROTEK-AGF (`$98E7` 276); 2 SINCLAIR (`$98AD`); the 3 KEMPSTON pick did not take (pressed while the title was still up) |
| `kempston` | `work/stage1/kempston` | `menu.szx` | `tests/inputs/kempston.txt` | 2000 | 3 KEMPSTON: the joystick read at `$98D2` 301 times, the cursor and a mirror turned |
| `energy` | `work/stage1/energy` | `menu.szx` | `tests/inputs/energy.txt` | 18 500 | level 1 with no key (Sinclair, the default): messages `$A104` 01 CHARGING LASER (frame 500), `$0A` ENERGY LOW (5000), `$0C` CRITICAL (5750), `$17` ENERGY DRAINED with `$8ED3` = `$FF` and lives 3 to 2 (6450), again at 12 550 (lives 1); `tools/ttd_watch.py` every 50 frames |
| `mine` | `work/stage1/mine` | `work/stage1/probe/mine.szx`: `game0.szx` (level 1 in play) with POKEs `$A50A` = `$54B8`, `$54B8`/`$55B8`/`$56B8` = `$FE`, `$8ED4` = `$FF` (the beam on a mine) | `tests/inputs/mine.txt` | 1500 | "MINE ALERT" (`$A689` once), the bar full (`$A6EE` three times): three lives lost in a row, since the poked bar stays full after each restart, "BOOM BOOM BOOM" ([screen 500](docs/img/play/life-lost.png)), game over, the title |
| `overload` | `work/stage1/overload` | `work/stage1/probe/overload.szx`: as `mine.szx` with `$8ED5` = `$FF` (the beam back in the laser) instead of `$8ED4` | `tests/inputs/overload.txt` | 1500 | "OVERLOAD" (`$A6BB` three times, `$A6A6` 129), three lives lost, game over |
| `gameover` | `work/stage1/gameover` | `work/stage1/probe/gameover.szx`: the POKEs of `mine.szx` and lives `$837D` = 1 | `tests/inputs/gameover.txt` | 4000 | the last life lost (`$86A6` once), game over, the title |
| `rzx-NNNNNN` (60) | `work/stage1/rzx/rNNNNNN` | `work/stage1/rzx/snap-NNNNNN.z80`, the RZX archive's run at frame NNNNNN, the frame where the level `$81FF` changed (`tools/rzx_dump.py --snap-on-change 81FF`; someone else's play) | `tests/inputs/rzx-NNNNNN.txt` (`tools/rzx_script.py`: the RZX's port reads as held keys, to 100 frames after the next level change) | 1252 to 9454, 341 171 in all | every level from 2 to 60 and the ending; 18 levels completed in our replay, the others drift from the RZX's course (table in 6.1) |

How they were made: `$RS capture --snapshot ... --model 48K --inputs ... --ranges 4000-FFFF --port-base 37480`
(`work/stage1/own_capture.sh`, `work/stage1/rzx_capture_all.sh`), each instance stopped after its capture.

The RZX segments start exactly on the RZX's state but drift: in our replay 18 of the 59 levels are completed (the
receiver reached, `$8FA9` in the L1), 26 lose lives (`$86A6`, 36 in all) and 15 are still in play at the end, while
the RZX player never loses a life (`$837D` = 3 from RZX frame 566 to the end, `work/stage1/rzx/watch.json`). The
game's randomness (the turning blocks, the gremlins) seems to depend on timing that differs between Spectaculator and
unreal-ng; stage 2 is to find the source (`LD A,R` at `$FD12` seeds R before the entry). Every level is still
reached at its start and played for its length; their completion is the RZX's own (someone else's run, said so):
`$81FF` takes every value from 0 to 60 in the RZX (`work/stage1/rzx/watch.json`).

Not reached by our recordings: a level completed by our own play (the RZX completes all 60, our replay 18); level 1
completed (the RZX's first segment, from its title, was not replayed: the title drifted at once); game over by energy
alone (`energy` stops after two of three lives, 6100 frames a life); the gremlins' contact ("CONTACT!", "BEWARE OF THE
GREMLINS!") checked by an address; a hall-of-fame entry from our own score (the RZX's last segment shows it: name R,
274 920); the dormant W / S level cheat at `$9832` (no jump reaches it).

### 6.1 Screens and levels

Every screen as captured (`tools/scr_png.py` from a recording's `screens/NNNNNN.scr`, the frame of the recording):

- the title: [`c1` screen 250](docs/img/play/title.png), and after an abort in magenta: [`menu` screen 8500](docs/img/play/title-after-abort.png);
- the options panel and the hall of fame: [`c1` screen 500](docs/img/play/options.png), [`menu` screen 3250](docs/img/play/options-menu.png);
- the demo: [`menu` screen 4500](docs/img/play/demo.png); practice: [`menu` screen 7750](docs/img/play/practice.png);
- a life lost (the red screen): [`mine` screen 500](docs/img/play/life-lost.png); GAME ABORTED: [`controls` screen 2000](docs/img/play/game-aborted.png);
- the ending and the hall of fame with the RZX player's entry: [`rzx-344752` screen 750](docs/img/play/ending.png), [screen 1250](docs/img/play/hall-of-fame.png).

Every level in play (level 1 from `c1` screen 4750, the others from their RZX segment's screen 1500, or 750 where the
segment is shorter), with its address and how its segment ended:

| Level | Address | Recording | Frames | In our replay | Screen |
| --- | --- | --- | --- | --- | --- |
| 1 | `$B000` | `c1` | 20 560 | played, not completed | [`c1` screen 4750](docs/img/play/level-01.png) |
| 2 | `$B087` | `rzx-004833` | 7019 | completed (`$8FA9`) | [frame 1500](docs/img/play/level-02.png) |
| 3 | `$B10E` | `rzx-011752` | 6089 | completed (`$8FA9`) | [frame 1500](docs/img/play/level-03.png) |
| 4 | `$B195` | `rzx-017741` | 6845 | not completed in our replay, still in play at the end | [frame 1500](docs/img/play/level-04.png) |
| 5 | `$B21C` | `rzx-024486` | 4533 | not completed in our replay: 2 lives lost (`$86A6`) | [frame 1500](docs/img/play/level-05.png) |
| 6 | `$B2A3` | `rzx-028919` | 5023 | completed (`$8FA9`) | [frame 1500](docs/img/play/level-06.png) |
| 7 | `$B32A` | `rzx-033842` | 6352 | not completed in our replay: 1 life lost (`$86A6`) | [frame 1500](docs/img/play/level-07.png) |
| 8 | `$B3B1` | `rzx-040094` | 5901 | completed (`$8FA9`) | [frame 1500](docs/img/play/level-08.png) |
| 9 | `$B438` | `rzx-045895` | 4111 | completed (`$8FA9`) | [frame 1500](docs/img/play/level-09.png) |
| 10 | `$B4BF` | `rzx-049906` | 4106 | not completed in our replay, still in play at the end | [frame 1500](docs/img/play/level-10.png) |
| 11 | `$B546` | `rzx-053912` | 6337 | not completed in our replay: 1 life lost (`$86A6`) | [frame 1500](docs/img/play/level-11.png) |
| 12 | `$B5CD` | `rzx-060149` | 3860 | completed (`$8FA9`) | [frame 1500](docs/img/play/level-12.png) |
| 13 | `$B654` | `rzx-063909` | 5611 | not completed in our replay, still in play at the end | [frame 1500](docs/img/play/level-13.png) |
| 14 | `$B6DB` | `rzx-069420` | 8608 | not completed in our replay, still in play at the end | [frame 1500](docs/img/play/level-14.png) |
| 15 | `$B762` | `rzx-077928` | 4229 | not completed in our replay, still in play at the end | [frame 1500](docs/img/play/level-15.png) |
| 16 | `$B7E9` | `rzx-082057` | 4419 | not completed in our replay: 1 life lost (`$86A6`) | [frame 1500](docs/img/play/level-16.png) |
| 17 | `$B870` | `rzx-086376` | 4355 | completed (`$8FA9`) | [frame 1500](docs/img/play/level-17.png) |
| 18 | `$B8F7` | `rzx-090631` | 5842 | completed (`$8FA9`) | [frame 1500](docs/img/play/level-18.png) |
| 19 | `$B97E` | `rzx-096373` | 7632 | not completed in our replay: 2 lives lost (`$86A6`) | [frame 1500](docs/img/play/level-19.png) |
| 20 | `$BA05` | `rzx-103905` | 3692 | not completed in our replay, still in play at the end | [frame 1500](docs/img/play/level-20.png) |
| 21 | `$BA8C` | `rzx-107497` | 7416 | not completed in our replay, still in play at the end | [frame 1500](docs/img/play/level-21.png) |
| 22 | `$BB13` | `rzx-114813` | 3416 | completed (`$8FA9`) | [frame 1500](docs/img/play/level-22.png) |
| 23 | `$BB9A` | `rzx-118129` | 6041 | not completed in our replay, still in play at the end | [frame 1500](docs/img/play/level-23.png) |
| 24 | `$BC21` | `rzx-124070` | 6558 | not completed in our replay: 1 life lost (`$86A6`) | [frame 1500](docs/img/play/level-24.png) |
| 25 | `$BCA8` | `rzx-130528` | 5738 | not completed in our replay: 1 life lost (`$86A6`) | [frame 1500](docs/img/play/level-25.png) |
| 26 | `$BD2F` | `rzx-136166` | 5812 | completed (`$8FA9`) | [frame 1500](docs/img/play/level-26.png) |
| 27 | `$BDB6` | `rzx-141878` | 4408 | completed (`$8FA9`) | [frame 1500](docs/img/play/level-27.png) |
| 28 | `$BE3D` | `rzx-146186` | 8207 | not completed in our replay: 1 life lost (`$86A6`) | [frame 1500](docs/img/play/level-28.png) |
| 29 | `$BEC4` | `rzx-154293` | 9454 | not completed in our replay: 1 life lost (`$86A6`) | [frame 1500](docs/img/play/level-29.png) |
| 30 | `$BF4B` | `rzx-163647` | 3265 | not completed in our replay: 1 life lost (`$86A6`) | [frame 1500](docs/img/play/level-30.png) |
| 31 | `$BFD2` | `rzx-166812` | 5771 | not completed in our replay: 2 lives lost (`$86A6`) | [frame 1500](docs/img/play/level-31.png) |
| 32 | `$C059` | `rzx-172483` | 7333 | completed (`$8FA9`) | [frame 1500](docs/img/play/level-32.png) |
| 33 | `$C0E0` | `rzx-179716` | 3924 | completed (`$8FA9`) | [frame 1500](docs/img/play/level-33.png) |
| 34 | `$C167` | `rzx-183540` | 9298 | not completed in our replay: 2 lives lost (`$86A6`) | [frame 1500](docs/img/play/level-34.png) |
| 35 | `$C1EE` | `rzx-192738` | 4212 | not completed in our replay: 1 life lost (`$86A6`) | [frame 1500](docs/img/play/level-35.png) |
| 36 | `$C275` | `rzx-196850` | 7547 | not completed in our replay: 2 lives lost (`$86A6`) | [frame 1500](docs/img/play/level-36.png) |
| 37 | `$C2FC` | `rzx-204297` | 6126 | not completed in our replay: 1 life lost (`$86A6`) | [frame 1500](docs/img/play/level-37.png) |
| 38 | `$C383` | `rzx-210323` | 5104 | not completed in our replay: 2 lives lost (`$86A6`) | [frame 1500](docs/img/play/level-38.png) |
| 39 | `$C40A` | `rzx-215327` | 8194 | not completed in our replay, still in play at the end | [frame 1500](docs/img/play/level-39.png) |
| 40 | `$C491` | `rzx-223421` | 4365 | completed (`$8FA9`) | [frame 1500](docs/img/play/level-40.png) |
| 41 | `$C518` | `rzx-227686` | 6980 | not completed in our replay: 1 life lost (`$86A6`) | [frame 1500](docs/img/play/level-41.png) |
| 42 | `$C59F` | `rzx-234566` | 5337 | not completed in our replay, still in play at the end | [frame 1500](docs/img/play/level-42.png) |
| 43 | `$C626` | `rzx-239803` | 7274 | not completed in our replay: 1 life lost (`$86A6`) | [frame 1500](docs/img/play/level-43.png) |
| 44 | `$C6AD` | `rzx-246977` | 8062 | not completed in our replay: 1 life lost (`$86A6`) | [frame 1500](docs/img/play/level-44.png) |
| 45 | `$C734` | `rzx-254939` | 4778 | not completed in our replay, still in play at the end | [frame 1500](docs/img/play/level-45.png) |
| 46 | `$C7BB` | `rzx-259617` | 3626 | not completed in our replay: 1 life lost (`$86A6`) | [frame 1500](docs/img/play/level-46.png) |
| 47 | `$C842` | `rzx-263143` | 5184 | completed (`$8FA9`) | [frame 1500](docs/img/play/level-47.png) |
| 48 | `$C8C9` | `rzx-268227` | 6151 | not completed in our replay: 2 lives lost (`$86A6`) | [frame 1500](docs/img/play/level-48.png) |
| 49 | `$C950` | `rzx-274278` | 7329 | not completed in our replay: 1 life lost (`$86A6`) | [frame 1500](docs/img/play/level-49.png) |
| 50 | `$C9D7` | `rzx-281507` | 5389 | not completed in our replay: 2 lives lost (`$86A6`) | [frame 1500](docs/img/play/level-50.png) |
| 51 | `$CA5E` | `rzx-286796` | 5588 | completed (`$8FA9`) | [frame 1500](docs/img/play/level-51.png) |
| 52 | `$CAE5` | `rzx-292284` | 3145 | not completed in our replay, still in play at the end | [frame 1500](docs/img/play/level-52.png) |
| 53 | `$CB6C` | `rzx-295329` | 4895 | not completed in our replay, still in play at the end | [frame 1500](docs/img/play/level-53.png) |
| 54 | `$CBF3` | `rzx-300124` | 7564 | not completed in our replay, still in play at the end | [frame 1500](docs/img/play/level-54.png) |
| 55 | `$CC7A` | `rzx-307588` | 4264 | not completed in our replay: 2 lives lost (`$86A6`) | [frame 1500](docs/img/play/level-55.png) |
| 56 | `$CD01` | `rzx-311752` | 8045 | completed (`$8FA9`) | [frame 1500](docs/img/play/level-56.png) |
| 57 | `$CD88` | `rzx-319697` | 7995 | not completed in our replay: 2 lives lost (`$86A6`) | [frame 1500](docs/img/play/level-57.png) |
| 58 | `$CE0F` | `rzx-327592` | 8118 | not completed in our replay, still in play at the end | [frame 1500](docs/img/play/level-58.png) |
| 59 | `$CE96` | `rzx-335610` | 4703 | not completed in our replay: 1 life lost (`$86A6`) | [frame 1500](docs/img/play/level-59.png) |
| 60 | `$CF1D` | `rzx-340213` | 4639 | completed (`$8FA9`) | [frame 1500](docs/img/play/level-60.png) |
| ending | - | `rzx-344752` | 1252 | the ending (`$8885`), the name entry, the hall of fame | [ending, frame 750](docs/img/play/ending.png), [hall of fame, frame 1250](docs/img/play/hall-of-fame.png) |

The levels drawn from the data, without the beam: [doc 2, 2.3](docs/02-architecture.md#23-the-levels).

## 7. Review
