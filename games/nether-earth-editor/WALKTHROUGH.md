# Nether Earth Editor: how the reverse was done

The case came after [Nether Earth](../nether-earth/WALKTHROUGH.md) was finished, and leans on it: every name of the
game (`Map`, `Robots`, `Warbases`, `SaveGame`, ...) is Nether Earth's, and the game's image is built from Nether Earth's
source. Two agents worked in parallel on 2026-11-04, about 35 minutes each: edA on the tape, the edition and the
levels, edB on the editor program. Their command logs, with what each command proved, are `work/edA/NOTES.md` and
`work/edB/NOTES.md` (local).

## 0. The medium

The ZXDB download of entry 17113 was already in the local collection
(`software/zxdb/files/pub/sinclair/utils/n/NetherEarthEditor.tzx.zip`). Its TZX has 28 data blocks and 10 text blocks
that name the parts (`tools/tzx_blocks.py orig/NETHER.TZX`):

| Blocks | Text block | What |
| --- | --- | --- |
| 0-5 | "Nether Earth (game)" | a BASIC with 70 bytes of loader code in a REM, and four headerless blocks |
| 6-19 | "Levels by V.O.software (loading as "saved game")" | seven pairs of a 2-byte and a 9425-byte block, flag `$00` |
| 20-27 | "Nether Earth Editor by V.O.software" | BASIC "NE Editor ", CODE "nee.mix" (2244 at 50000), BASIC "nee.bas", one more saved game |

The 9425 bytes matched Nether Earth's saved game ([its 3.6](../nether-earth/docs/03-build-and-load.md#36-the-saved-game)):
`$24D1` bytes from `$D92B`. That gave the plan before any emulator ran.

## 1. The edition: a snapshot

**Used:** `tools/zxbasic.py list` on block 1, the loader code read by hand (70 bytes), an own instance loading the
tape, TTD `memory_at` frame by frame.

- The BASIC's line 20 runs the REM code at `$5CD0`. It loads blocks 2-4 with LD-BYTES, takes registers from a frame at
  `$410E`, loads block 5 over its own BASIC and returns to `$4002`: a trampoline in the screen that restores IX, AF', SP,
  R, IM 2 and returns into the menu tune at `$C4C3`.
- The four blocks laid out as the loader does (`work/edA/mkimg.py`) were compared with Nether Earth's block: from
  `$5B00` up they are the same bytes. Every difference is state: the tune's self-modified operands, the menu
  variables, N1's leftovers, the IM 2 table, the ROM's stack. So the edition is the original game, snapshotted in its
  menu ([3.5](docs/03-build-and-load.md#35-the-image-against-nether-earths)).
- `src/edition/edition.asm` builds blocks 1-5 from Nether Earth's own `game.bin` and `loader.bin` plus those state
  bytes, each with its reason.

## 2. The saved game, recorded

**Used:** `tools/level_session.py` (an own instance: load the edition, key 5, play the level tape, play, save), TTD
`memory_at` and `find_last`.

Nether Earth's case had read `SaveGame` and `LoadGameBlocks` from the code only; no recording ran them. Here they ran:

- frame 677: the sum block is in `$5B00`;
- frames 3024-3025: `$D92B-$FDFB` equals block 7 with no difference;
- frame 3025: the two `LDIR`s at `$C25B` / `$C263` copy the staged shots and buildings back;
- the save: SA-BYTES returns at `$C2FB` (frame 3465) and `$C30A` (frame 5586), the same layout.

Found on the way: `LoadGameBlocks` enters LD-BYTES at `$0562`, past the address the emulator's fast-load trap watches,
so a saved game loads at signal speed, about 2600 frames. Nether Earth's doc 3.6 now cites this recording.

## 3. The levels

**Used:** `tools/levels.py` (block ↔ text, render), all eight loaded from a menu snapshot and played 400 frames
(`tools/level_session.py levels`).

Each saved game became a text file (`src/res/levels/*.txt`): the map as rows of cells, the bases, the robots, the
resources, the variables; `levels.py` builds the block and its sum back, 8 of 8 identical. The maps were compared
with the original's: Break Through and Double Frontline are the original map with the bases moved, The Chase reuses
parts of it, the rest are new; The Slogan spells a slogan against the Insignians across the map in tall blocks
([1.3](docs/01-game-design.md#13-the-levels)).

The editor removes a capture point by setting it to `$80` (destroyed) and leaves its door. Nether Earth's case had
proved that a robot standing 144 turns on a destroyed base's door takes it as a warbase; these levels carry 20-26
such doors ([10.3](docs/10-gameplay-logic.md#103-out-of-play-capture-points)). Read from the code and that
experiment, not recorded on the levels.

## 4. The editor

**Used:** an input script touring every menu (`work/edB/inputs/editor-tour.txt`), its recording (18429 frames) and
an L1 build from frame 2700 (after the tape, so the loaded code is not taken as data), `find_event` on keys and
memory, `kit/mkgame.py` for `nee.mix`.

- **BASIC.** `tools/zxbasic.py` detokenises and tokenises; numbers the ROM stores inexactly (`.5` as `7F 7F FF FF FF`)
  come out of the ROM's own DEC-TO-FP run in SkoolKit's simulator. Both programs rebuild byte for byte from commented
  listings (`src/basic/`).
- **`nee.mix`.** A small mkgame case (`src/mix/mix.ann`): 217 instructions, 216 ran in the tour (only `DoorUnknown`
  did not), every routine named and commented, tiles and font as PNG.
- **The address mapping.** The editor keeps the game's block at `$9C40-$C110`: game address = editor address +
  `$3CEB`; the sum word at `$9858` stands for the game's `$5B00`. Every variable of the save got its Nether Earth name.
- **Quirks.** NE Editor's `POKE 23739,111` silences channel S during the load, nee.bas's `CLS` restores it; an error
  trap in a REM sends BREAK and any error to line 146; one loop walks 55 of the 56 building records; the enemy's
  warbases get no pad record; the editor saves with the ROM's standard pilot, the game with a short one.

## 5. The whole tape from source

`tools/build.sh` builds the edition (from Nether Earth's source and `edition.asm`), the eight levels (from text) and
the editor (BASIC listings, `nee.mix` from its source and PNGs) and writes the TZX from a manifest with the text
blocks and pauses: `build/edition/NETHER.TZX: identical to orig/NETHER.TZX`.

## 6. Tool gaps

| Gap | Seen | State |
| --- | --- | --- |
| `time_travel find_event {find: "exec"}` over a wide window returns empty-text hits that differ per call and misses real ones (`SaveChecksum` at 14013+26190 found only with a narrow from/to) | edB | open in unreal-ng |
| The tape trap loads header-driven LOADs fast; direct calls into LD-BYTES past its start (`$0562`, `$0802`) run at signal speed | edA, edB | noted; the recordings simply take longer |
| The main checkout's unreal-qt had no `analysis` MCP tool | edA, edB | the agents used the `scratch/wt-access-trace` build |

## 7. Review

- **Not recorded:** a load of the edition at ROM speed with the traps off; a robot taking an out-of-play `$80` door on
  these levels (from the code and Nether Earth's experiment).
- **Not run:** `DoorUnknown` in `nee.mix`.
- The game checks only the sum of a save, so the counts, the map marks and the robot records are the level
  author's job. All eight saves keep the counts consistent; two carry stray anchor marks
  ([10.2](docs/10-gameplay-logic.md#102-what-the-game-checks-the-sum-nothing-else)).
