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

The level format was found from the code ([doc 2, 2.7](docs/02-architecture.md#27-the-levels-in-memory)): `$891A` takes
135 bytes from `$B000 + $87 x $81FF` into the grid `$FD23`, `$8960` and `$8A09` draw it. `tools/level_maps.py` runs
`$891A` in SkoolKit's simulator for each of the 61 slots and draws the buffers it fills: the
[first map of the levels](docs/img/maps/all.png) (`docs/img/maps/level-NN.png`, `levels.json` with each level's
address and bytes). `tools/tile_sheet.py` draws every cell code from the table `$8200` and the characters
`$D700` / `$DF00` ([the tile sheet](docs/img/sprites/tiles.png)); `tools/gfx_sheet.py` the font at `$D200` (code 32 first), the
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

All on unreal-ng's 48K, muted, port bases 37480 and 37485; each keeps its `session.ttd` in its folder (`c1g` is a
window of `c1`'s). A snapshot start is a state saved by `work/stage1/drive.py`, `tools/rzx_dump.py`, `tools/lab.py` or
the stage 2 level bot; the POKEs are said where used. Every command runs from the case folder after `. work/env.sh`.

| Name | Folder | Start | Inputs | Frames | What it reached |
| --- | --- | --- | --- | --- | --- |
| `c1` | `work/stage1/c1` | power-on, `--record-load`, the 10 Mega Games tape at ROM timing ([1](#1-one-recording-from-power-on)) | `tests/inputs/c1.txt` | 20 560 | the load and every loader stage, the title, the options panel (3, 4, 2, 1, 7), level 1 with the keyboard: cursor moves, mirrors turned |
| `c1g` | `work/stage1/c1g` | a build of `c1` from frame 15 752 T 33 930 (the entry `$8382`) | as `c1` | 4808 | the game window of `c1` |
| `menu` | `work/stage1/menu` | `work/stage1/probe/menu.szx` (the title after the same ROM-timing load, frame 17 000) | `tests/inputs/menu.txt` | 9000 | the title and its tune for 3000 frames, the options, 5 DEMO (the demo shows levels 14, 23, 37, 55, 59: [screen 4500](docs/img/play/demo.png)), SPACE ends it, 6 PRACTICE pressed, but it did not take: [screen 7750](docs/img/play/practice.png) shows LEVEL 01, U + G aborts, the title |
| `controls` | `work/stage1/controls` | `menu.szx` | `tests/inputs/controls.txt` | 7000 | 1 KEYBOARD (`$987B` 317 times), P pauses ("INTERMISSION ... PRESS ENTER FOR MORE ACTION", `$973F`), the pause's tune, ENTER goes on (`$97C0`), U + G "GAME ABORTED" ([screen 2000](docs/img/play/game-aborted.png)); 4 PROTEK-AGF (`$98E7` 276); 2 SINCLAIR (`$98AD`); the 3 KEMPSTON pick did not take (pressed while the title was still up) |
| `kempston` | `work/stage1/kempston` | `menu.szx` | `tests/inputs/kempston.txt` | 2000 | 3 KEMPSTON: the joystick read at `$98D2` 301 times, the cursor and a mirror turned |
| `energy` | `work/stage1/energy` | `menu.szx` | `tests/inputs/energy.txt` | 18 500 | level 1 with no key (Sinclair, the default): messages `$A104` 01 CHARGING LASER (frame 500), `$0A` ENERGY LOW (5000), `$0C` CRITICAL (5750), `$17` ENERGY DRAINED with `$8ED3` = `$FF` and lives 3 to 2 (6450), again at 12 550 (lives 1); `tools/ttd_watch.py` every 50 frames |
| `mine` | `work/stage1/mine` | `work/stage1/probe/mine.szx`: `game0.szx` (level 1 in play) with POKEs `$A50A` = `$54B8`, `$54B8`/`$55B8`/`$56B8` = `$FE`, `$8ED4` = `$FF` (the beam on a mine) | `tests/inputs/mine.txt` | 1500 | "MINE ALERT" (`$A689` once), the bar full (`$A6EE` three times): three lives lost in a row, since the poked bar stays full after each restart, "BOOM BOOM BOOM" ([screen 500](docs/img/play/life-lost.png)), game over, the title |
| `overload` | `work/stage1/overload` | `work/stage1/probe/overload.szx`: as `mine.szx` with `$8ED5` = `$FF` (the beam back in the laser) instead of `$8ED4` | `tests/inputs/overload.txt` | 1500 | "OVERLOAD" (`$A6BB` three times, `$A6A6` 129), three lives lost, game over |
| `gameover` | `work/stage1/gameover` | `work/stage1/probe/gameover.szx`: the POKEs of `mine.szx` and lives `$837D` = 1 | `tests/inputs/gameover.txt` | 4000 | the last life lost (`$86A6` once), game over, the title |
| `rzx-NNNNNN` (60) | `work/stage1/rzx/rNNNNNN` | `work/stage1/rzx/snap-NNNNNN.z80`, the RZX archive's run at frame NNNNNN, the frame where the level `$81FF` changed (`tools/rzx_dump.py --snap-on-change 81FF`; someone else's play) | `tests/inputs/rzx-NNNNNN.txt` (`tools/rzx_script.py`: the RZX's port reads as held keys, to 100 frames after the next level change) | 1252 to 9454, 341 171 in all | every level from 2 to 60 and the ending; 18 levels completed in our replay, the others drift from the RZX's course (table in 6.1) |
| `energy-out` | `work/stage2/rec/energy-out` | `menu.szx` | `tests/inputs/energy-out.txt` | 21 000 | SPACE, 7, then no key: ENERGY DRAINED three times (`$A66F` 3 runs, LoseLife 3), GAME OVER from the energy alone, HallOfFame `$9BC0` with score 0 (place 7, no entry), the title |
| `L01` ... `L59` (20) | `work/stage2/rec/LNN` | the bot's level-start state `LNN.szx` (`work/stage2/levels`, `lv`, `lv2`) | the bot's own keys `LNN.txt` beside it | 1542 to 3171 | levels 1, 3, 5, 6, 9, 10, 12, 15, 20, 22, 25, 30, 31, 35, 39, 42, 45, 51, 55, 59 completed by the case's bot (LevelComplete `$87D4` ran; `work/stage2/check_recs.py`). The bot's clones skipped 34 other levels by a POKE of LevelDone `$8ED2` (said in each script's first line; from level 38 on Lives was also poked back to 3), so every bot recording after `L01` starts on a clone. Levels 19, 24, 34, 40, 49 and 54 the bot finished live, but their replays (`work/stage2/rec/L19` ...) do not reach the receiver: no witness |
| `hof` | `work/stage2/rec/hof` | `work/stage2/hof/start.szx` = the bot's `lv/L06.szx` (a clone: levels 2 and 4 were skipped by the LevelDone POKE), score 019980 | `tests/inputs/hof.txt` | 17 750 | no key to GAME OVER, then the name AGENT and ENTER: RankScore `$9E1F` place 6, AGENT 021940 in the hall of fame, CopyFullScreen `$9DD6` ([`hof` 17160](docs/img/play/hof-017160-name.png)) |
| `ending` | `work/stage2/rec/ending` | `work/stage2/lv2/L61.szx`: the state at level 60's CONTACT! on the bot's clone (level 60 finished by the LevelDone POKE), score 238 670 | `work/stage2/ending/inputs.txt` (no key) | 3000 | TheEnd `$8885`, EndingScreen `$A8CE`: the plug, the kettle, THE TEA WILL BE READY IN FIVE MINUTES!, PRESS ANY KEY held to the end ([`ending` 1000](docs/img/play/ending-001000.png)) |
| `cheat` | `work/stage2/rec/cheat` | `work/stage2/cheat/cheat.szx`: `game0.szx` with the POKE `$982F-$9831` = 0 (the jump over the dormant W / S cheat removed; `work/stage2/cheat/make.py`) | `tests/inputs/cheat.txt` | 1900 | W, W, S: Level `$81FF` 0, 1, 2, 1, each a restart (case.json witness_builds, not read_builds) |
| `practice` | `work/docs/dfA/rec/practice` | `menu.szx` | `work/docs/dfA/practice.txt` | 2500 | SPACE, 6 PRACTICE, then P1 with the Sinclair keys: NewGame's practice branch `$8424` and SetUpLevel's `$84DA` once, the practice line `$8A6E` 615 times, slot 60 read ([`practice` 1750](docs/img/play/practice-001750.png)) |
| `nameedit` | `work/docs/integrate/rec/nameedit` | `work/stage2/hof/start.szx` (the clone `hof` starts from) | `tests/inputs/nameedit.txt` | 17 800 | as `hof` to the name entry, then A, G, DELETE (0), SPACE, E, N, T, X, ENTER: DELETE `$9D15` and SPACE `$9D5A` once each, EraseNameCursor `$9DF5` twice, the full name refusing X (`$9D7E`); the hall of fame shows A ENT 021940 ([`nameedit` 17250](docs/img/hud/name-entry-edit.png)) |
| `corner` | `work/docs/integrate/rec/corner` | `work/docs/integrate/corner/corner.szx`: `game0.szx` with the beam's start `$8376-$8378` POKEd to x 10, y 16, direction 10 (`work/docs/integrate/corner/make.py`; a clone) | `tests/inputs/corner.txt` (no key) | 1500 | every pass starts a diagonal beam at the reflecting wall beside the laser: ReflectInCorner `$93F2` and InCornerTable `$8100` 342 times, the beam turned a quarter to direction 14 ([`corner` 750](docs/img/logic/reflect-in-corner.png); case.json witness_builds) |

How they were made (from C after `. work/env.sh`; port base 37480 or 37485):

```sh
python3 $RS capture --work FOLDER --snapshot START --inputs INPUTS --ranges 4000-FFFF --port-base 37480 --model 48K --binary $BIN
python3 $RS stop --work FOLDER
python3 $RS open --work work/docs/dfA/NAME --ttd FOLDER/session.ttd   # the writers' reopen for their figures
```

Stage 1's by `work/stage1/own_capture.sh` and `work/stage1/rzx_capture_all.sh`, the levels by
`sh work/stage2/capture_levels.sh work/stage2/lv work/stage2/lv2`, `hof` after `python3 work/stage2/hof/make.py`,
`cheat` after `python3 work/stage2/cheat/make.py`, `corner` after `python3 work/docs/integrate/corner/make.py`; `c1`
with `--record-load` from the tape. The writers reopened `work/docs/dfA/L01`, `L03`, `c1`, `hof`, ...

The RZX segments start exactly on the RZX's state but drift: in our replay 18 of the 59 levels are completed (the
receiver reached, `$8FA9` in the L1), 26 lose lives (`$86A6`, 36 in all) and 15 are still in play at the end, while
the RZX player never loses a life (`$837D` = 3 from RZX frame 566 to the end, `work/stage1/rzx/watch.json`). The
game's randomness (the turning blocks, the gremlins) seems to depend on timing that differs between Spectaculator and
unreal-ng; stage 2 is to find the source (`LD A,R` at `$FD12` seeds R before the entry). Every level is still
reached at its start and played for its length; their completion is the RZX's own (someone else's run, said so):
`$81FF` takes every value from 0 to 60 in the RZX (`work/stage1/rzx/watch.json`).

What stage 1 did not reach, stage 2 and the documents added: levels completed by our own play (the bot's 20, with
level 1 among them), game over by energy alone (`energy-out`), CONTACT! checked by an address (it is the beam in the
receiver, LevelComplete `$87D4`, message `$18`, not a gremlin's touch: the gremlins only turn mirrors; doc 10), a
hall-of-fame entry from our own play (`hof`, `nameedit`, on a clone), the W / S cheat on a clone (`cheat`), practice
(`practice`) and the diagonal bounce in the incoming pass on a clone (`corner`). Still known only from the code (each
document's last section): practice levels P2 and P3 (slot 63 is never set up), the Y + T level drop `$983E`, the 150-step stop of the
trace, FibreNoPartner `$9059`, the cell codes no level holds, the gremlin delay `$FF`, a gremlin killed by our own
fire (only in RZX segments) and on a mirror it is turning, beam glyphs 28 and 36.

### 6.1 Screens and levels

Every screen as captured (`tools/scr_png.py` from a recording's `screens/NNNNNN.scr`, the frame of the recording):

- the title: [`c1` screen 250](docs/img/play/title.png), and after an abort in magenta: [`menu` screen 8500](docs/img/play/title-after-abort.png);
- the options panel and the hall of fame: [`c1` screen 500](docs/img/play/options.png), [`menu` screen 3250](docs/img/play/options-menu.png);
- the demo: [`menu` screen 4500](docs/img/play/demo.png); the `menu` recording after key 6, which did not take (level 1, no practice line): [`menu` screen 7750](docs/img/play/practice.png);
- a life lost (the red screen): [`mine` screen 500](docs/img/play/life-lost.png); GAME ABORTED: [`controls` screen 2000](docs/img/play/game-aborted.png);
- the ending and the hall of fame with the RZX player's entry: [`rzx-344752` screen 750](docs/img/play/ending.png), [screen 1250](docs/img/play/hall-of-fame.png).
- level 1 played by the bot (`L01`): [the charge, 100](docs/img/play/l01-000100-charging.png), [OVERLOAD, 262](docs/img/play/l01-000262-overload.png), [a cell burns, 395](docs/img/play/l01-000395-burn.png), [mid level, 1000](docs/img/play/l01-001000-play.png), [MINE ALERT, 1346](docs/img/play/l01-001346-mine.png), [the door, 1425](docs/img/play/l01-001425-door.png), [CONTACT!, 1560](docs/img/play/l01-001560-contact.png), [the bonus, 1610](docs/img/play/l01-001610-bonus.png);
- a gremlin (`L03`): [1180](docs/img/play/l03-001180-gremlin.png), [1300](docs/img/play/l03-001300-gremlin-mirror.png);
- the energy (`energy`): [ENERGY LOW, 5000](docs/img/play/energy-005000-low.png), [CRITICAL, 5760](docs/img/play/energy-005760-critical.png), [DRAINED, 6460](docs/img/play/energy-006460-drained.png);
- the pause: [`controls` 1500](docs/img/play/controls-001500-intermission.png); a life lost and game over: [`gameover` 100](docs/img/play/gameover-000100.png), [150](docs/img/play/gameover-000150.png);
- practice P1: [`practice` 1750](docs/img/play/practice-001750.png);
- the name entry: [`hof` 17160](docs/img/play/hof-017160-name.png) (AGENT), [`nameedit` 17250](docs/img/hud/name-entry-edit.png) (A ENT, after DELETE and SPACE);
- the ending on our own clone: [`ending` 1000](docs/img/play/ending-001000.png);
- the diagonal bounce on the clone: [`corner` 750](docs/img/logic/reflect-in-corner.png).

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

The levels drawn from the data, without the beam: the contact sheets of [doc 1, 1.6](docs/01-game-design.md#16-the-60-levels).

### 6.2 The animations

| File | Document | Recording | Frames |
| --- | --- | --- | --- |
| [loading-screen.gif](docs/img/load/loading-screen.gif) | [doc 3](docs/03-build-and-load.md) | c1 | 1000-15 700, every 100th |
| [decipher.gif](docs/img/load/decipher.gif) | doc 3 | c1 | 15 638-15 756, every 5th |
| [MainLoop.gif](docs/img/routines/MainLoop.gif) | [doc 4](docs/04-game-loop.md) | L01 | 1003-1008 |
| [TraceBeam.gif](docs/img/routines/TraceBeam.gif) | doc 4 | L01 | 1000-1003 |
| [TurnMirror.gif](docs/img/routines/TurnMirror.gif) | [doc 5](docs/05-controls.md) | L01 | 1494-1514 |
| [l01-turn.gif](docs/img/play/l01-turn.gif) | doc 5 | L01 | 1490-1522 |
| [BuildLevel.gif](docs/img/routines/BuildLevel.gif) | [doc 6](docs/06-rendering.md) | L01 | 24-30 |
| [CopyPlayArea.gif](docs/img/routines/CopyPlayArea.gif) | doc 6 | L01 | 1003-1004 |
| [TraceBeam-draw.gif](docs/img/routines/TraceBeam-draw.gif) | doc 6 | L01 | 245-249 |
| [WipeInPlayArea.gif](docs/img/routines/WipeInPlayArea.gif) | doc 6 | L01 | 26-64 |
| [BuildLevel-grid.gif](docs/img/objects/BuildLevel-grid.gif) | [doc 7](docs/07-objects.md) | L01 | 23-24 |
| [UpdateGremlins.gif](docs/img/objects/UpdateGremlins.gif) | doc 7 | L03 | 1176-1194 |
| [AddScore.gif](docs/img/hud/AddScore.gif) | [doc 8](docs/08-hud-and-text.md) | L01 | 1598-1614 |
| [name-entry.gif](docs/img/hud/name-entry.gif) | doc 8 | hof | 16 890-17 200, every 5th |
| [PlaySweep-port.gif](docs/img/routines/PlaySweep-port.gif) | [doc 9](docs/09-sound.md) | none (SkoolKit's simulator, `tools/sound_render.py anim`) | GremlinSound's 150 509 T |
| [level-01-solve.gif](docs/img/play/level-01-solve.gif) | [doc 1](docs/01-game-design.md) | L01 | 200-1620, every 10th |
| [trace-overload.gif](docs/img/logic/trace-overload.gif) | [doc 10](docs/10-gameplay-logic.md) | L01 (a dump replayed by `tools/fig_trace.py`) | 256 |
| [trace-burn.gif](docs/img/logic/trace-burn.gif) | doc 10 | L01 (a dump replayed) | 377 |
| [trace-contact.gif](docs/img/logic/trace-contact.gif) | doc 10 | L01 (a dump replayed) | 1514 |
| [PassEnd-burn.gif](docs/img/logic/PassEnd-burn.gif) | doc 10 | L01 | 377-411 |
| [UpdateOverload.gif](docs/img/logic/UpdateOverload.gif) | doc 10 | L01 | 1325-1352 |
| [gremlins.gif](docs/img/logic/gremlins.gif) | doc 10 | L03 | 1150-1330, every 3rd |
| [level-complete.gif](docs/img/logic/level-complete.gif) | doc 10 | L01 | 1508-1645, every 3rd |

## 7. Review
