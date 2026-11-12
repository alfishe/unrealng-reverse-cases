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
- Erbe's tapes are another build (standard ROM blocks, the code shifted, the POKEs 24 lower) whose levels 2 and 5
  differ from side B (8 and 64 bytes); side B's level 5 addresses the table at `$7B8F` that side A's code uses, Erbe's
  `$7B7E`, so the Micro Style sides belong together;
- the other TAPs and TZXs are re-saves with new BASICs (one packed), the zxart files are hacks and crack intros.

The table is in the README. No SkoolKit disassembly or other reverse is known (GitHub searched).

Side A is a BASIC, a 256-byte block at `$FF00` and two headerless blocks the ROM cannot read: their checksums XOR to
`$FF`, not `$00`. The loader at `$FF00` is encrypted (XOR `$5C` from `$FF0B`); decrypted, it is a copy of LD-BYTES that
shifts each bit in from the top (`LD L,$80`, `RR L`), so every byte on the tape is stored bit-reversed. Reversing the
blocks' bytes gives the screen and the code exactly as `c1` holds them at the entry (0 bytes differ), and the same for
side B's level blocks at `$A800` ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block),
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
  map builder `$88F3-$8949`, the scroll `$796F-$7993`, the RAM 1 calls (`DI` at `$7A7F`; called from the main code,
  interrupts come back at the next wait's `EI`) and the level loader (`$847C`, the tape). An interrupt that falls in
  one of those windows is lost (the 128K's INT lasts 36 T): `c1` takes 4863 interrupts in 18 910 frames (the load runs
  with them off), `controls-keyboard` 2333 in 2340, `load-l4` 3404 in 26 600 (the tape), and the RZX level 5 replay
  `rzx-l5-full` 20 404 in 26 257: 22 % of its frames lose their interrupt, so the frame counter and the music run slow
  when many sprites are on screen (the L1's `replay.interrupts`).
- **The main loop.** `$7D2D-$7E1B`, no HALT: the quit key (`$724A`), the pause (`$71C0`), the music switch, then
  `LD C,$02` and `CALL $7A53`, the frame wait: `EI`, loop until the counter `$7A60` reaches C, clear it (`$7A5B`). So a
  pass takes two frames or more. After the wait come the cell drawer `$76D4`, the section change, the moving parts, the
  scroll up or down (`$7905`, `$78A5`, whose steps wait a frame each, `LD C,$01`) and the death test (`$9B9B`, lives
  `$8B3B`). The other callers of `$7A53` are the menus and the texts (C = 1, 10, 15 and 20). A level starts at `$7CC5`:
  when the level wanted (`$7EF1`) is not the one in memory (`$C20C`) it is read from tape (`$840C`) and decrypted
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
  pass equal): a section set-up or the boss's end, to name in stage 2. The section numbers are `$9B93` at frame 250
  of the matching recording (`tools/rec_state.py`).

## 2. Static pass over the medium

- `python3 tools/tzxblocks.py list` on each side: every block standard speed; the BASIC, the loader header and block,
  two headerless blocks on side A, five on side B
  ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)).
- `python3 tools/image.py OUT [--level N]`: the 64 K as the tape leaves it, the bit-reversed blocks turned back (the
  screen at `$4000`, the code at `$6000-$FEFD`, the decrypted loader at `$FF00`), with side B's block N at `$A800`
  when a level is named. `case.json` runs it for the image every later comparison starts from.
- `python3 tools/level_map.py` and `tools/sprite_sheet.py`: the five levels' sections and sprites drawn from the level
  blocks ([doc 2, 2.2](docs/02-architecture.md#22-the-level-maps), [2.3](docs/02-architecture.md#23-the-sprites)).

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
    counter beside it (`$7EF1-$7EF2`), the score (`$7F19-$7F21`), the view (`$88CF-$88D2`), the ammunition, the
    detonators and their neighbours (`$8B3C-$8B41`), the objects' and enemies' fields (`$8ECF-$9160`, `$93CD`,
    `$9F4D`), Rick's record and the two after it (his shot and detonator, to confirm) and the section
    (`$9B8D-$9BC2`);
  - the IM 2 table `$FD00-$FE00` and the handler's page `$FEFE-$FFFF` (the stack);
  - the RZX run's own level loader (`$846A-$8510`, 165 bytes: its TAP version); `$8311-$831F` and `$840D-$840E`
    change in every level (to name in stage 2).
  The level data at `$A800-$FCFF` does not change in play (but for level 3's 3 bytes): the maps' last 768 bytes are
  decrypted once when the level starts (without `--decrypted`, those 768 bytes differ too).
- **The state variables** found: the level `$7EF1` (1-5), the lives `$8B3B`, the ammunition `$8B3C`, the detonators
  `$8B3D`, the score `$7F1D-$7F22` (six digits), the section `$9B93`, Rick's record `$9BAB` (+1 x, +2 y, +4 the
  sprite, +6 bit 7 the mirror), the death flag `$9B9B`, the view's top row `$88CF`, the control method `$7252`
  ([doc 2, 2.1](docs/02-architecture.md#21-the-memory-map)).

## 3. The stages and the packers

No packer. The stages: the BASIC, the 256-byte loader at `$FF00` that decrypts itself (XOR `$5C`) and reads two
bit-reversed blocks, the entry `$7B8F` (the 128K test, the music to RAM 1, the IM 2 set-up), the title and the menus,
play. A level other than the first is read from side B by the level loader and its maps' tail decrypted by `$894E`
([doc 3](docs/03-build-and-load.md)). The level loads are recorded at ROM speed in `load-l2` ... `load-l5`
([6.0](#60-the-recordings)).

## 4. The medium from source

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
| `rzx-lL-NNNNN-poke` (59: level 1 15, level 2 13, level 3 6, level 4 11, level 5 14) | `work/stage1/rec/rzx-lL-NNNNN-poke/session.ttd` | the RZX run's saved state at its frame NNNNN (`work/stage1/rzx/lL/atNNNNN.szx`, `start.szx` for 0; someone else's play) | `tests/inputs/rzx-lL-NNNNN-poke.txt` (`tools/rzx_script.py`: the RZX's port reads as held keys) | 2000 each, the last of a level shorter | the RZX run in pieces through each level, level 1 to its end (level 2 starts in `rzx-l1-26000-poke`), the Fat Guy and the ending text: four POKEs at frame 0, said so (infinite lives `$8A30`, immune to enemies `$8C67`, to moving objects `$A475`, to the bomb blast `$93B4`) |
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

Not reached: the 48K path (no music, `$7A76` = `$FF`); the "CONGRATULATIONS" end (`$8754`, level 4 completed in a game
that did not complete four levels); the sections of the maps that `$9B93` never shows (level 2 sections 10-12, level 3
3-5 and 7-9, level 4 1-2 and 10-12, level 5 5) may lie between the samples; which tune and which effect each
recording plays is stage 2's (the tunes start at `$7AAD`, the effects at `$7A97`; every recording here is a 128K with
the music on).

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
| the ending | [ending.png](docs/img/play/ending.png) | `rzx-l5-24000-poke` 250 |

The level maps and the sprite sheets drawn from the data are in [doc 2](docs/02-architecture.md#22-the-level-maps).

## 7. Review
