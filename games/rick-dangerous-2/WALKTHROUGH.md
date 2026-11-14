# Rick Dangerous 2: walkthrough

How the reverse was done, step by step, and which unreal-ng call answered each question. Terms:
[docs/README.md](docs/README.md). Recipes: `../recipes/`.

Every recording is named with its load (ROM speed or the fast LD-BYTES trap) beside every frame number.

## 0. The medium

The case starts from ZXDB 4137 (Rick Dangerous 2, Micro Style, 1990; Core Design). The original is
`orig/RickDangerous2.tzx.zip` from ZXDB's `pub/sinclair/games/r/`, its md5 the one ZXDB lists (hashes in the
[README](README.md)): two TZX files, side A (the BASIC, the loader, the screen and the game) and side B (five level
blocks). The archive info block of each names Micro Style, CORE Design, 1990 and "Original".

The release check. `tools/fetch_copies.py` copied every copy the collection index lists into
`work/candidates/<source>/` (`work/stage1/fetch-copies.txt`: 33 files from ZXDB, zxart and TOSEC); the RZX archive's
run, ZXDB's instructions, maps and POKE file were added by hand. `tools/tape_compare.py` compared every tape block by
block with sides A and B (`work/stage1/tape-compare.txt`):

- the Kixx sides equal the original but for 32 bytes of the loader block's tail, which the stack overwrites;
- ZXDB's `Rick Dangerous 2.tap` is the Micro Style tape decoded to plain bit order, with a new BASIC that patches the
  loader and 13 other bytes in the level loader (`$8479-$8485`); its level blocks are Erbe's;
- Erbe's tapes are another build (standard ROM blocks, the code shifted by region: from about `$7E30` on 24 lower, so
  most POKEs are 24 lower; the entry and object tables 17-20 lower) whose levels 2 and 5 differ from side B (8 and
  64 bytes); side B's level 5 addresses the table at `$7B8F` that side A's code uses, Erbe's `$7B7E`, so the Micro
  Style sides belong together;
- the other TAPs and TZXs are re-saves with new BASICs (one packed), the zxart files are hacks and crack intros.

The table is in the README. No SkoolKit disassembly or other reverse is known (GitHub searched).

Side A is a BASIC, a 256-byte block at `$FF00` and two headerless blocks the ROM cannot read: their checksums XOR to
`$FF`, not `$00`. The loader at `$FF00` is encrypted (XOR `$5C` from `$FF0B`); decrypted, it is a copy of LD-BYTES that
shifts each bit in from the top (`LD L,$80`, `RR L`), so every byte on the tape is stored bit-reversed. Reversing the
blocks' bytes gives the screen and the code exactly as `c1` holds them at the entry (0 bytes differ), and the same for
side B's level blocks at `$A800` ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-as-a-picture),
[3.2](docs/03-build-and-load.md#32-the-loader-at-ff00)). `tools/image.py` writes the image `case.json` names.

Other sources: the RZX archive's `rick2-1.rzx` ... `rick2-5.rzx` (Jim Waterman's run, one file a level, to the
ending), ZXDB's Kixx instructions, the World of Spectrum maps and the POKE file (`work/candidates/zxdb-*`,
`work/candidates/rzxarchive/`).

## 1. One recording from power-on

`c1`: a 128K from power-on, side A at ROM speed through the 128's Tape Loader (`tools/capture.py` record-load,
14 700 load frames, port base 37500), then `tests/inputs/c1.txt`: the control menu (2, 3, 4, 1 in turn), 0, the level
menu, 1 (Hyde Park, in memory: no tape), keyboard play in the first rooms (X, Z, O, K, SPACE with each direction),
P twice, E. 18 910 frames, `work/stage1/c1/session.ttd`. The stages (`re_session.py stages` and the L1's arrivals):
the loader `$FF00` at frame 1110 (t 65 924), decrypted by frame 1111, the entry `$7B8F` at frame 13 998 (t 9477), the
set-up to `IM 2` (`$7C36`) done by frame 14 007, the control menu at about 15 000, play from about 15 800
(`work/stage1/c1shots-sheet.png`).

The interrupts and the timing, a first look:

- **IM mode and handler.** The ROM's IM 1 until the entry. `$7B8F` runs `DI`, sets `SP` = 0, finds RAM 1, fills
  `$FD00-$FE00` with `$FE`, sets `I` = `$FD` and `IM 2` (`$7C36`), so every vector is `$FEFE`: `DI`, all registers
  pushed, `INC ($7A60)` (the frame counter), `CALL $81D4`, `CALL $7254` (the controls into `$7253`), `CALL $7AB6`
  (the music player: `$7A77` pages RAM 1 in, calls HL = `$CAAF`, pages RAM 0 back), the registers popped, `EI` at
  `$FF1F`, `RET`. In `c1` it ran 4706 times. `$7A77` is also the way in for the tune starts (`$7AAD`: `$CA27`) and the
  effects (`$7A97`: `$CCC8`); on a 48K (`$7A76` = `$FF`) it returns at once.
- **DI and EI in play.** Besides the handler, these run with interrupts off (the L1's `F3` and `FB`, the same pairs in
  every recording): the sprite blitter `$7442-$74B5` and the cell drawer `$75DC-$76D2` (both move SP to pop data), the
  map builder `$88F3-$8949`, the HUD clear in `DrawHud` (`$796F-$7993`), the RAM 1 calls (`DI` at `$7A7F`; called
  from the main code, interrupts come back at the next wait's `EI`) and the level loader (`$847C`, the tape). An
  interrupt that falls in one of those windows is lost (the 128K's INT lasts 36 T): `c1` takes 4863 interrupts in 18 910 frames (the load runs
  with them off), `controls-keyboard` 2333 in 2340, `load-l4` 3404 in 26 600 (the tape), and the RZX level 5 replay
  `rzx-l5-full` 20 404 in 26 257: 22 % of its frames lose their interrupt, so the frame counter and the music run slow
  when many sprites are on screen (the L1's `replay.interrupts`).
- **The main loop.** `$7D2D-$7E1B`, no HALT: the quit key (`$724A`), the cheat chords (`$71C0`, `$71DC`), the pause (`$7242`), then
  `LD C,$02` and `CALL $7A53`, the frame wait: `EI`, loop until the counter `$7A60` reaches C, clear it (`$7A5B`). So a
  pass takes two frames or more. After the wait come the cell drawer `$76D4`, the section change, the moving parts, the
  scroll up or down (`$7905`, `$78A5`, whose steps wait a frame each, `LD C,$01`) and the death test (`$9B9B`, lives
  `$8B3B`). The other callers of `$7A53` are the menus and the texts (C = 1) and the end tally (C = 10
  `TallyBullets` `$8701`, 15 `TallyDetonators` `$8722`, 20 `TallyLives` `$8743`). A level starts at `$7CC5`: when
  the level wanted (`$7EF1`) is not the one in memory (`$C20C`) it is read from tape (`$840C`) and decrypted
  (`$894E`); a life is added up to 6, the ammunition and the detonators set to 6.
- **Frames per pass**, measured on our instance (`tools/passes.py`: from each RZX state, 300 passes from one exit of
  the frame wait (`$7A5B`) to the next, the work being the part up to the next entry of `$7A53`; `/skip_until`, timed
  by `/video/beam`, 70 908 T a frame; no key held, so Rick stands while the enemies move;
  `work/stage1/passes.json`):

| State (RZX run) | Section | Median pass, T | Frames | Median work, T | Frames | Heaviest pass, T | Frames |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| level 1, frame 6000 | 6 | 212 717 | 3.00 | 94 997 | 1.34 | 212 759 (pass 2) | 3.00 |
| level 2, frame 10 000 | 3 | 184 769 | 2.61 | 162 488 | 2.29 | 217 445 (pass 36) | 3.07 |
| level 3, frame 6000 | 1 | 141 816 | 2.00 | 97 327 | 1.37 | 283 632 (pass 0) | 4.00 |
| level 4, frame 10 000 | 3 | 141 816 | 2.00 | 43 071 | 0.61 | 141 882 (pass 1) | 2.00 |
| level 5, frame 12 000 | 4 | 212 714 | 3.00 | 152 396 | 2.15 | 212 745 (pass 74) | 3.00 |
| level 5, frame 22 000 (the Fat Guy) | 7 | 212 724 | 3.00 | 155 274 | 2.19 | 955 192 (pass 85) | 13.47 |

  A pass takes whole frames: 2 when its work fits in about one frame, 3 when it does not (level 2's median 2.61 mixes
  the two): the wait asks for two counts of `$7A60`, and an interrupt lost in a DI window (above) costs the pass a third
  frame even where the work is 1.34 frames (level 1). So play runs at 25 or 16.7 passes a second, by the screen's
  load. The heaviest pass measured, 955 192 T (13.47 frames) in the Fat Guy's room, holds no wait at all (work and
  pass equal): a section entry (`CheckSectionExit` `$8993` and the section set-up: [doc 4, 4.5](docs/04-game-loop.md#45-the-heaviest-pass-entering-a-section)). The section numbers are `$9B93` at frame 250
  of the matching recording (`tools/rec_state.py`).

## 2. Static pass over the medium

- `python3 tools/tzxblocks.py list` on each side: every block standard speed; the BASIC, the loader header and block,
  two headerless blocks on side A, five on side B
  ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-as-a-picture)).
- `python3 tools/image.py OUT [--level N]`: the 64 K as the tape leaves it, the bit-reversed blocks turned back (the
  screen at `$4000`, the code at `$6000-$FEFD`, the decrypted loader at `$FF00`), with side B's block N at `$A800`
  when a level is named. `case.json` runs it for the image every later comparison starts from.
- `python3 tools/level_map.py` and `tools/sprite_sheet.py`: the five levels' sections and sprites drawn from the level
  blocks ([doc 1, 1.7](docs/01-game-design.md#17-the-levels), [doc 6, 6.4](docs/06-rendering.md#64-the-sprites)).

The images and what changes between them:

- **As loaded and at the entry.** `c1`'s memory when the loader jumps to `$7B8F` (frame 13 998, t 9477,
  `work/stage1/images/entry.cpu.bin`) and after the last tape byte (`loaded.cpu.bin`) are the same, and both equal
  the image in `$4000-$FEFD`: 0 bytes differ (`tools/ttd_dump.py`, `cmp`).
- **In play, per level.** `python3 tools/image_diff.py N --decrypted` compares the level's image with the RZX run's
  memory 250 frames into level N (`work/stage1/images/diff-lN.txt`): 4476 to 5302 bytes differ, all of them below
  `$A000` or in `$FD00-$FFFF` but for 3 bytes of level 3 (`$ED80-$ED90`). What changes:
  - the work areas: `$5B00-$6177` (the composed cells and the cell lists), `$6500-$707F` (the music's area on the
    tape, now the bit-reverse table and the view's cell buffers);
  - the entry code `$7B8F-$7C7C`, now the object tables;
  - code that stores into itself: the SP saves of the blitter, the cell drawer and the map builder (`$7485`,
    `$749F-$74B4`, `$761F`, `$76B2-$76D1`, `$8947`), the RAM 1 call's operands (`$7A81-$7A8E`);
  - the state: the control method and the controls (`$7252-$7253`), the frame counter (`$7A60`), the level and a
    counter beside it (`$7EF1-$7EF2`), the countdown bonus's digits 2-4 and the score (`$7F19-$7F21`: `TimeBonus`
    `$7F19-$7F1B`, `Score` from `$7F1D`), the view (`$88CF-$88D2`), the ammunition, the detonators and their neighbours
    (`$8B3C-$8B41`), the objects' and enemies' fields (`$8ECF-$9160`, `$93CD`, `$9F4D`), Rick's record and the two
    after it (`BulletRecord` `$9BB4`, `DetonatorRecord` `$9BBD`) and the section (`$9B8D-$9BC2`);
  - the IM 2 table `$FD00-$FE00` and the handler's page `$FEFE-$FFFF` (the stack);
  - the RZX run's own build: its level loader (`$846A-$8510`, 167 bytes: its TAP version), `$840D-$840E`, and the
    page bytes at `$7A81` and `$7AC6` (`LD A,$16`: its RAM 1 calls page RAM 6), found against `build/game.bin` by
    the docs writer (`rzx-l1-06000-poke` frame 0); `$8311-$831F` change in every level.
  The level data at `$A800-$FCFF` does not change in play (but for level 3's 3 bytes): the maps' last 768 bytes are
  decrypted once when the level starts (without `--decrypted`, those 768 bytes differ too).
- **The state variables** found: the level `$7EF1` (1-5), the lives `$8B3B`, the ammunition `$8B3C`, the detonators
  `$8B3D`, the score `$7F1D-$7F22` (six digits), the section `$9B93`, Rick's record `$9BAB` (+1 x, +2 y, +4 the
  sprite, +6 bit 7 the mirror), the death fall's end `DeathFallOver` `$9B9B` (`RickDying` `$9B9C`), the view's top row `$88CF`, the control method `$7252`
  ([doc 2, 2.3](docs/02-architecture.md#23-the-memory-map)).

## 3. The stages and the packers

No packer. The stages: the BASIC, the 256-byte loader at `$FF00` that decrypts itself (XOR `$5C`) and reads two
bit-reversed blocks, the entry `$7B8F` (the 128K test, the music to RAM 1, the IM 2 set-up), the title and the menus,
play. A level other than the first is read from side B by the level loader and its maps' tail decrypted by `$894E`
([doc 3](docs/03-build-and-load.md)). The level loads are recorded at ROM speed in `load-l2` ... `load-l5`
([6.0](#60-the-recordings)).

## 4. The medium from source

Stage 2 wrote the source ([doc 3, 3.6](docs/03-build-and-load.md#36-the-build), `work/stage2/NOTES.md`):

```sh
sh tools/mkasm_all.sh --fix-witness      # every .asm from its .ann (kit/mkgame.py), each assembled and compared
python3 tools/res_formats.py check       # every resource in src/res converts back to its bytes
sh tools/build.sh $SJASMPLUS             # build/side-a.tzx and side-b.tzx: identical to orig/RickDangerous2.tzx.zip
python3 ../../kit/refdocs.py --case .    # docs 11 and 12
```

The parts: the game (`src/game/game.ann`, 18 modules), the AY music (`src/music`), the five levels (`src/levels`,
one `@piece` a level), the loader at `$FF00`, the loading screen and the tape's BASIC; `tools/mktape.py` writes the
blocks in the loader's bit-reversed form and enciphers the maps' last 768 bytes of each level.

## 5. Tool gaps found and fixed in unreal-ng

| Gap | Fix | unreal-ng commit |
| --- | --- | --- |

## 6. The game

### 6.0 The recordings

Every recording keeps its `session.ttd` beside its `l1.json` and `screens/` (one screen every 250 frames) in the
folder named; all are 128K, made with `tools/capture.py` (`--ranges 4000-FFFF`, ports 37500 and 37505). Loads: `c1`
at ROM speed from power-on; the level loads at ROM speed from side B; the rest start from a saved state (no load).

| Name | Session | Start (load) | Inputs | Frames | Reached |
| --- | --- | --- | --- | ---: | --- |
| `c1` | `work/stage1/c1/session.ttd` | power-on, side A at ROM speed | `tests/inputs/c1.txt` | 18 910 | the loader, the entry, the control menu (2, 3, 4, 1), level 1, keyboard play (the ray gun `$959F`, a detonator `$9B41`), P, deaths (`$93D0`), E and GAME OVER (`$7E1E`) |
| `controls-kempston`, `controls-cursor`, `controls-sinclair`, `controls-keyboard` | `work/stage1/controls-*/session.ttd` | `work/stage1/lab/e1-end.szx`, the control menu after side A at ROM speed | `tests/inputs/controls-*.txt` | 1310 each, the keyboard 2340 | each method picked (`$7252` = 1, 2, 3, 0 in the samples), level 1, walking, a jump, fire with up, right and down (the ray gun `$959F` and a detonator `$9B41` once in each, the same play under every method), a death; the keyboard one also P and E (GAME OVER) |
| `load-l2` ... `load-l5` | `work/stage1/load-lN/session.ttd` | `work/stage1/lab/e1-end.szx`; side B inserted at frame 370 and played at ROM speed | `tests/inputs/load-lN.txt` | 13 901, 20 200, 26 600, 32 901 | "START TAPE ON SIDE TWO", the blocks before the level skipped, "STOP TAPE AND PRESS FIRE", the level's first section (`$7EF1` = N). `load-l5` uses a POKE, said so: `$8065` = `$FF` at frame 0, which opens level 5 in the level menu (without it the menu lists levels 1-4) |
| `rzx-lL-NNNNN-poke` (58: level 1 14, level 2 13, level 3 6, level 4 11, level 5 14) | `work/stage1/rec/rzx-lL-NNNNN-poke/session.ttd` | the RZX run's saved state at its frame NNNNN (`work/stage1/rzx/lL/atNNNNN.szx`, `start.szx` for 0; someone else's play) | `tests/inputs/rzx-lL-NNNNN-poke.txt` (`tools/rzx_script.py`: the RZX's port reads as held keys) | 2000 each, the last of a level shorter | the RZX run in pieces through each level, level 1 to its end (level 2 starts in `rzx-l1-26000-poke`), the Fat Guy and the ending text: four POKEs at frame 0, said so (infinite lives `$8A30`, immune to enemies `$8C67`, to moving objects `$A475`, to the bomb blast `$93B4`) |
| `rzx-l5-full` | `work/stage1/rec/rzx-l5-full/session.ttd` | the RZX's level 5 start state | `tests/inputs/rzx-l5-full.txt` | 26 257 | no POKE: level 5 section 0, deaths, two GAME OVERs, the control menu, the level menu with five levels, a new game |
| `rzx-l1-full-poke`, `rzx-l5-full-poke` | `work/stage1/rec/rzx-lL-full-poke/session.ttd` | the RZX's level start states | `tests/inputs/rzx-lL-full-poke.txt` | 26 687, 26 257 | the first tries: whole levels with the POKEs, off the run's course after a few hundred frames (Rick stuck in level 1 sections 0-3 and level 5 section 0) |
| `rzx-l5-23000` | `work/stage1/rec/rzx-l5-23000/session.ttd` | the RZX's level 5 state at 23 000 | `tests/inputs/rzx-l5-23000.txt` | 3257 | no POKE: the end of the lives tally (`$874E`) and the ending text, "AND SO RICK SAVES THE DAY BY DEFEATING THE FAT GUY AND HIS FLEET OF ROBOT STARSHIPS ... WHAT WILL RICK DO NEXT", letter by letter (frames 250-1000), then held |

`python3 tools/rzx_segment.sh L FROM TO PORT_BASE [poke]` makes one piece: the script from the RZX's reads, the
capture, `tools/rzx_match.py` (the screen every 250 frames against the RZX's own, `match.txt`), the instance
stopped. The pieces stay on the RZX's course 250-500 frames: the replay feeds the reads as keys held per frame, not
per instruction, and the enemies move on other passes (NOTES "For the lead"). After that each piece plays on from
where the RZX player stood with the same keys, so every piece starts in the RZX's place. The sections seen (`$9B93`,
`tools/rec_state.py --summary`): level 1 0-7, level 2 0-9, level 3 0-2 and 6, level 4 0 and 3-9, level 5 0-4, 6 and
7.

Stage 2 and the integration added these recordings (all with `--ranges 4000-FFFF` and their `session.ttd`; the
`sec-*` ones by `sh work/stage2/runsec.sh 37500 NAME ...`, the others by the `tools/capture.py` line below):

```sh
python3 tools/capture.py --work work/stage2/rec/NAME --snapshot START --model 128K --inputs tests/inputs/NAME.txt \
    --ranges 4000-FFFF --port-base 37500 --binary $BIN       # then: python3 $RS stop --work work/stage2/rec/NAME
```

| Name | Session | Start (load) | Inputs | Frames | Reached |
| --- | --- | --- | --- | ---: | --- |
| `c48` | `work/stage2/rec/c48/session.ttd` | power-on 48K, side A at ROM speed (`LOAD ""` typed, `--media A --model 48K --record-load`) | `tests/inputs/c48.txt` | 19 571 (15 401 of load, then 4170) | the 48K path: the bank test fails, `Machine48K` `$7A76` = `$FF`, no music; `PlayBeeperStep` `$7B66` 1206 runs; the menus, level 1, gun, detonator, punch, pause, quit ([doc 9, 9.11](docs/09-sound.md#911-the-48k-beeper)) |
| `cheats` | `work/stage2/rec/cheats/session.ttd` | `work/stage1/rzx/l5/at002000.szx` (no load) | `tests/inputs/cheats.txt` | 800 | both chords: C+S+3 at frame 50 (`CheatInfinite` `$8066` on, off, on at 54, 56, 60), SPACE+N+ENTER+J+Y at 200 (`CheatExits` `$8067` = `$FF` at 204) ([doc 5, 5.7](docs/05-controls.md#57-the-cheat-chords)) |
| `end-congrats` | `work/stage2/rec/end-congrats/session.ttd` | `work/stage1/rzx/l4/at020000.szx` | `tests/inputs/end-congrats.txt`: POKE `$7EF2` = 0 and the immunity POKEs, said so | 2600 | the CONGRATULATIONS ending `$8754` |
| `long-l4` | `work/stage2/rec/long-l4/session.ttd` | `work/stage1/rzx/l4/at020000.szx` | `tests/inputs/long-l4.txt`: POKE `$8067` = `$FF` and the immunity POKEs | 1200 | level 4 section 7's level-end exit becomes the passage to section 10 (`$89E0`) |
| `sec-lL-sS` (18: level 1 section 8; level 2 sections 7, 10-12; level 3 3-5, 7-9; level 4 1, 2, 6, 11, 12; level 5 3, 5) | `work/stage2/rec/sec-lL-sS/session.ttd` | `work/stage1/lab/e1-end.szx` (level 1), else `work/stage1/rzx/lL/start.szx` | `tests/inputs/sec-lL-sS.txt` (written by `work/stage2/mksections.py`): POKE `LevelStarts` (`$7C8F` + 6 (L - 1)) and the immunity POKEs | 1190 (level 1), 2470 | every section the other recordings never entered, so every section of every level is read by `SetupSection` in at least one recording |
| `life-up` | `work/docs/rec/life-up/session.ttd` | `work/stage1/rzx/l5/start.szx` (level 5's "STOP TAPE AND PRESS FIRE") | `tests/inputs/life-up.txt`: POKE `Lives` `$8B3B` = 3, said so | 350 | `AddLife` `$7CEE` (1 run): the level starts with 4 lives |
| `box-shot` | `work/docs/rec/box-shot/session.ttd` | `work/stage1/lab/e1-end.szx` | `tests/inputs/box-shot.txt`: POKE `LevelStarts` = level 1 section 3, x 96, y 227, and the immunity POKEs | 906 | an ammunition box shot: `PickupShot` `$A5E4` 1 run, `PickupBurst` `$A53A` 10 runs |
| `fatguy-hits` | `work/docs/rec/fatguy-hits/session.ttd` | `work/stage1/rzx/l5/at021000.szx` (the Fat Guy at 20 hits) | `tests/inputs/fatguy-hits.txt`: the immunity POKEs (the Fat Guy's own tests are not POKEd) | 900 | his touch kills Rick (`$F946` jumps, frames 196-198) and a bullet from the left ledge hits him (`$F922`, the count 20 -> 19 in frames 822-824) ([doc 10, 10.12](docs/10-gameplay-logic.md#1012-the-fat-guy)) |

`life-up`, `box-shot` and `fatguy-hits` were made at the integration for what the docs writer listed as known only
from the code; each POKE is in its script's header and named where the recording is a witness. `case.json` counts
all three in `read_builds` and `code_builds`. `c48` and the tape loads (`c1`, `load-lN`) are in `code_builds` only:
the ROM's RAM test and the tape loaders read every byte, which would make every unexecuted byte "data" for the
static walk.

Not reached: the end of both endings (`EndTextExit` `$8794`, after 2500 frames or fire), `BonusTally` `$86E0`'s
bullet and detonator loops, the countdown bonus running out (`BonusRunOut` `$917C`), a pickup box burst by the blast
(`$A5F7`), a detonator thrown left that stops, level 1's weak jump (`$9799`), and the Fat Guy's shot aimed right
(`$FA46-$FA64`): [doc 10, 10.16](docs/10-gameplay-logic.md#1016-what-no-recording-reached) lists them with the code
that shows each.

### 6.1 Screens and levels

Every screen reached, from the recordings at the frames named:

| Screen | Picture | Recording, frame |
| --- | --- | --- |
| the loading screen | [loading-screen.png](docs/img/play/loading-screen.png) | the image `$4000-$5AFF` (`tools/image.py`) |
| the control menu | [control-menu.png](docs/img/play/control-menu.png) | `rzx-l5-full` 11 750 |
| the level menu (five levels: after the RZX run reached level 5) | [level-menu.png](docs/img/play/level-menu.png) | `rzx-l5-full` 12 750 |
| "START TAPE ON SIDE TWO" | [tape-start-side-two.png](docs/img/play/tape-start-side-two.png) | `load-l3` 1000 |
| "STOP TAPE AND PRESS FIRE" | [tape-stop-press-fire.png](docs/img/play/tape-stop-press-fire.png) | `load-l3` 18 000 |
| level 1, Hyde Park London, the start | [level1-start.png](docs/img/play/level1-start.png) | `c1` 16 200 |
| level 1, sections 6 and 7 | [level1-section6.png](docs/img/play/level1-section6.png), [level1-section7.png](docs/img/play/level1-section7.png) | `rzx-l1-06000-poke` 250, `rzx-l1-14000-poke` 250 |
| level 2, the Ice Caverns of Freezia, the start and section 6 | [level2-start.png](docs/img/play/level2-start.png), [level2-section6.png](docs/img/play/level2-section6.png) | `load-l2` 13 750, `rzx-l2-20000-poke` 250 |
| level 3, the Forests of Vegetablia, the start and the spikes of section 1 | [level3-start.png](docs/img/play/level3-start.png), [level3-section1-spikes.png](docs/img/play/level3-section1-spikes.png) | `load-l3` 20 000, `rzx-l3-06000-poke` 250 |
| level 4, the Atomic Mud Mines, the start and section 3 | [level4-start.png](docs/img/play/level4-start.png), [level4-section3.png](docs/img/play/level4-section3.png) | `load-l4` 26 500, `rzx-l4-10000-poke` 250 |
| level 5, the Fat Guy's headquarters, the start and section 4 | [level5-start.png](docs/img/play/level5-start.png), [level5-section4.png](docs/img/play/level5-section4.png) | `rzx-l5-full` 250, `rzx-l5-12000-poke` 250 |
| the Fat Guy | [level5-fat-guy.png](docs/img/play/level5-fat-guy.png) | `rzx-l5-22000-poke` 250 |
| GAME OVER | [game-over.png](docs/img/play/game-over.png) | `rzx-l5-full` 11 500 |
| the ending | [ending.png](docs/img/play/ending.png) | `rzx-l5-24000-poke` 250 (the same screen as `rzx-l5-23000` from 1250 on) |

The level maps drawn from the data are in [doc 1, 1.7](docs/01-game-design.md#17-the-levels), the sprite sheets in
[doc 6, 6.4](docs/06-rendering.md#64-the-sprites) and `src/res/levels/levelN/level/sprites.png`.

Sheets of the screens: [design/screens.png](docs/img/design/screens.png) (the screenshots above on one sheet, doc 1)
and [design/moments.png](docs/img/design/moments.png) (ten key moments of the RZX run from its own screens,
`work/stage1/rzx/lN/screens.bin`, doc 1).

### 6.2 Animations

30 animations, each drawn from a recording by the command in its caption (`kit/routine_anim.py`,
`kit/screen_anim.py`, `kit/memanim.py` or the case's `tools/fig_play.py`, `fig_hud.py`, `fig_objects.py`); the
writer's working sessions (`work/docs/wr/<name>`) are the recordings named, opened with `re_session.py open`.

| Animation | Document | Recording | Frames |
| --- | --- | --- | --- |
| [`load-side-a.gif`](docs/img/play/load-side-a.gif) | [doc 03](docs/03-build-and-load.md) | `c1` | 1100-14 100 |
| [`Decipher.gif`](docs/img/routines/Decipher.gif) | [doc 03](docs/03-build-and-load.md) | `c1` | 1110-1111 |
| [`DecryptMaps.gif`](docs/img/routines/DecryptMaps.gif) | [doc 03](docs/03-build-and-load.md) | `load-l2` | 13 071 |
| [`MainLoop.gif`](docs/img/routines/MainLoop.gif) | [doc 04](docs/04-game-loop.md) | `rzx-l1-06000-poke` | 103-105 |
| [`Im2Handler.gif`](docs/img/routines/Im2Handler.gif) | [doc 04](docs/04-game-loop.md) | `rzx-l1-06000-poke` | 104 |
| [`control-menu-pointer.gif`](docs/img/play/control-menu-pointer.gif) | [doc 05](docs/05-controls.md) | `c1` | 15 090-15 400 |
| [`rick-keys.gif`](docs/img/play/rick-keys.gif) | [doc 05](docs/05-controls.md) | `controls-keyboard` | 626-1170 |
| [`ReadControls.gif`](docs/img/routines/ReadControls.gif) | [doc 05](docs/05-controls.md) | `controls-keyboard` | 630 |
| [`UpdateRick.gif`](docs/img/routines/UpdateRick.gif) | [doc 05](docs/05-controls.md) | `controls-keyboard` | 630 |
| [`ComposeSprite.gif`](docs/img/routines/ComposeSprite.gif) | [doc 06](docs/06-rendering.md) | `rzx-l1-06000-poke` | 103 |
| [`DrawChangedCells.gif`](docs/img/routines/DrawChangedCells.gif) | [doc 06](docs/06-rendering.md) | `rzx-l1-06000-poke` | 103 |
| [`scroll-up.gif`](docs/img/play/scroll-up.gif) | [doc 06](docs/06-rendering.md) | `rzx-l1-04000-poke` | 108-131 |
| [`ScrollUp.gif`](docs/img/routines/ScrollUp.gif) | [doc 06](docs/06-rendering.md) | `rzx-l1-04000-poke` | 111-127 |
| [`objects-l1.gif`](docs/img/play/objects-l1.gif) | [doc 07](docs/07-objects.md) | `rzx-l1-06000-poke` | 0-118 |
| [`ScanMapObjects.gif`](docs/img/routines/ScanMapObjects.gif) | [doc 07](docs/07-objects.md) | `rzx-l1-06000-poke` | 118 |
| [`UpdateTrap.gif`](docs/img/routines/UpdateTrap.gif) | [doc 07](docs/07-objects.md) | `rzx-l1-06000-poke` | 105 |
| [`UpdateEnemy.gif`](docs/img/routines/UpdateEnemy.gif) | [doc 07](docs/07-objects.md) | `rzx-l1-06000-poke` | 105 |
| [`AddScore.gif`](docs/img/routines/AddScore.gif) | [doc 08](docs/08-hud-and-text.md) | `rzx-l1-06000-poke` | 259 |
| [`letters.gif`](docs/img/play/letters.gif) | [doc 08](docs/08-hud-and-text.md) | `controls-keyboard` | 112-328 |
| [`MoveLetters.gif`](docs/img/routines/MoveLetters.gif) | [doc 08](docs/08-hud-and-text.md) | `controls-keyboard` | 172 |
| [`game-over-letters.gif`](docs/img/play/game-over-letters.gif) | [doc 08](docs/08-hud-and-text.md) | `controls-keyboard` | 1430-1600 |
| [`MusicFrame.gif`](docs/img/routines/MusicFrame.gif) | [doc 09](docs/09-sound.md) | `c1` | 17 440-17 539 |
| [`UpdateVoices.gif`](docs/img/routines/UpdateVoices.gif) | [doc 09](docs/09-sound.md) | `c1` | 17 456 |
| [`death-l5-full.gif`](docs/img/play/death-l5-full.gif) | [doc 01](docs/01-game-design.md) | `rzx-l5-full` | 2196-2340 |
| [`jump.gif`](docs/img/play/jump.gif) | [doc 10](docs/10-gameplay-logic.md) | `controls-keyboard` | 706-766 |
| [`shot.gif`](docs/img/play/shot.gif) | [doc 10](docs/10-gameplay-logic.md) | `c1` | 16 586-16 656 |
| [`blast.gif`](docs/img/play/blast.gif) | [doc 10](docs/10-gameplay-logic.md) | `c1` | 16 676-16 870 |
| [`BurnFuse.gif`](docs/img/routines/BurnFuse.gif) | [doc 10](docs/10-gameplay-logic.md) | `c1` | 16 789 |
| [`trap-death.gif`](docs/img/play/trap-death.gif) | [doc 10](docs/10-gameplay-logic.md) | `c1` | 17 466-17 580 |
| [`KillRick.gif`](docs/img/routines/KillRick.gif) | [doc 10](docs/10-gameplay-logic.md) | `c1` | 17 505 |

## 7. Review

Docs 01-10 written; integrated (the source changes the writer asked for applied, docs 11 and 12 generated, three
recordings added: 6.0). The review rounds are next (`work/review/`; the writers' open points:
`work/review/open-from-writers.md`).
