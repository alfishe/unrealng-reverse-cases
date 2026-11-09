# 2. Architecture

What this covers:

- the machine budget: the 48K, the interrupt, the stack (2.1);
- the memory map, as a table and a figure (2.2);
- the three images, as loaded, at the entry and in play, and what changes between them (2.3).

Still to come: the stages from the tape to play, the main loop's call graph, the module map.

<!-- Figures this document needs (GUIDE.md 4.2), remove each line when it is in: -->
<!-- - the stages from power-on to play (mermaid) -->

The recordings it rests on ([Terms](README.md#terms)), all on the 48K, each with an input script (WALKTHROUGH 6.0
has the table):

- `c1`: power-on, the load through the fast LD-BYTES trap, then 16 000 frames of random play (`work/c1`);
- `a1`, `g1`, `t1`, `p2`, `h1`: the menus, the hold, the tune toggle, the abort, GAME OVER, the tape save and load,
  two players, the hi-score entry (`work/runs/NAME`), from `work/snaps/entry.z80`, a snapshot of `c1` at the game's
  entry (frame 256, T 58 497);
- `i1`, `i2`: the whole Beginner and the whole Champion course, from the clone `work/snaps/immune.z80` (the kill
  entry `$A7DD` patched to `RET`);
- `h2`: the all-time hi-score entry, from the clone `work/snaps/g1-3700-score60000.z80` (`g1` frame 3700 with the
  score set to 60000).

The clones are exploration only: they reach the code, and every claim below is about the code they ran.

## 2.1 The machine budget

- **The 48K, the beeper**: the only `OUT` instructions in the code are to port `$FE` (`$906B`, `$A60A`); the tune
  goes through the ROM's BEEPER `$03B5` (called from the tune player `$7F47`).
- **Interrupts on, IM 2 in play**: SetIm2 `$A7D4` (`DI`, `I` = `$3A`, `IM 2`, `EI`) ends each life start (`$9132`).
  The vector is the word at `$3AFF` in the ROM, `$FFFF`; the byte there is a `JR` back to `$FFF4`, which jumps to the
  handler `$7F14`. The menus, the death, the hold and the bonus screen run in IM 1 (SetIm1 `$A7CB`). The handler counts FRAMES,
  plays the tune and keeps the time; WALKTHROUGH 1 has the witnesses.
- **The stack is the BASIC's**: the game keeps the SP that `USR` gave it (`$C338` at the entry, `c1` frame 256) and
  saves it at `$B25D` (`$8000`); the course switch reloads SP from `$B25F` (`$BB1D`). In play it reaches `$C2FC`,
  60 bytes down, inside the interrupt handler's frame (2.3).
- **The game never returns to BASIC**: the abort (`$AABF`) jumps to `$8004`, and the error handler `$82F3`, hooked
  into ERR_SP, catches the ROM's reports during the tape operations (`t1`).

## 2.2 The memory map

![The image fills 6132-FFFF: code in the middle, graphics on both sides, the courses and variables at B212-BEF7, 359 free bytes below the stack](img/arch/memmap.png)

How to read the figure:

- **One row** is 256 bytes, from `$4000` at the top to `$FFFF` at the bottom; each square is one byte.
- **The colour** is what the eight recordings together did with the byte (the union of their L1 builds): green
  executed, blue read as data, orange written and read, yellow written only, dark never touched.
- **The brackets** on the right are the regions of the table below.
- **The point**: the image is compact and static. Code fills `$7F14-$B211` and `$FD80-$FFFF`, graphics, fonts and plot tables
  fill both ends, and play writes only the screen, the printer buffer, the variables at `$B212`, the object list at
  `$BEF8` and the stack. Nothing is built at run time: the image runs as loaded.

```bash
python3 tools/fig_memmap.py --out docs/img/arch/memmap.png work/runs/{a1,g1,t1,p2,i1,i2,h1,h2}/l1.json
python3 work/stage1/regcounts.py      # the byte counts of the table, per region of tools/memmap-regions.txt
```

The byte counts are the union of the same eight L1 builds: X executed (as an opcode or operand), R read only, W
written (with or without reads), - never touched.

| Range | Bytes | What | X | R | W | - | Witness |
| --- | ---: | --- | ---: | ---: | ---: | ---: | --- |
| `$4000-$5AFF` | 6912 | the screen | | | 6912 | | cleared by `$9044` from `$8000` |
| `$5B00-$5B74` | 117 | the printer buffer; 21 bytes of `$9681` copied to `$5B60` at each life start | | | 117 | | `$90D3` |
| `$5B75-$60F7` | 1411 | the system variables and the BASIC; FRAMES `$5C78` counted by the handler | | 8 | 24 | 1379 | `$7F14` |
| `$60F8-$6131` | 58 | leftovers of the build: a copy of the tape header "MOON" at `$611D` | | | | 58 | |
| `$6132-$7F00` | 7631 | graphics A; the rows of 128 bytes at `$6500-$7572` are read in part | | 6902 | 15 | 714 | |
| `$7F01-$7F13` | 19 | the build date `03:35 30/10/84` at `$7F05` | | | | 19 | |
| `$7F14-$7FBE` | 171 | the interrupt handler `$7F14`, the tune player `$7F47`, the clock `$7F98` | 164 | | | 7 | 25 747 entries in `i1` |
| `$7FBF-$7FFF` | 65 | Atari's copyright text | | | | 65 | |
| `$8000-$8F0F` | 3856 | the entry, the title, the options, the score table, the demo, the hi-scores, the tape code | 1974 | 1171 | 357 | 354 | `a1`, `t1`, `h1`, `h2` |
| `$8F10-$9695` | 1926 | the game start `$8F10`, the player swap `$9022`, the life start `$90D3`, the HUD | 1328 | 563 | | 35 | `p2` |
| `$9696-$A4ED` | 3672 | the main loop `$9696`, the course interpreter `$9751`, the object handlers | 3524 | 67 | | 81 | `i1`, `i2` |
| `$A4EE-$A7CA` | 733 | the sector bonus screen `$A4EE`, its texts from `$A6A0` | 408 | 206 | | 119 | `i1`, the sector ends |
| `$A7CB-$B211` | 2631 | the play code: SetIm1, SetIm2, the kill `$A7DD`, the abort `$AABF`, the hold `$AECE`, the tune toggle `$AF15` | 2229 | 358 | | 44 | `a1` |
| `$B212-$B2C1` | 176 | the variables; the player record `$B271` (27 bytes), the other player's `$B28C`, the swap buffer `$B2A7` | | 5 | 168 | 3 | 2.3 |
| `$B2C2-$B7E7` | 1318 | tables, the tune `$B4E6` | | 1243 | | 75 | |
| `$B7E8-$BB23` | 828 | the Beginner course script, ending in the code `$BB07` (on to Champion) | 29 | 789 | 10 | | `i1` frame 29680 |
| `$BB24-$BEF7` | 980 | the Champion course script, ending in the code `$BED4` (back to Beginner) | 28 | 934 | 10 | 8 | `i2` frame 30694 |
| `$BEF8-$C194` | 669 | the object list | | | 669 | | zero in the image |
| `$C195-$C2FB` | 359 | **free**: zero in the image, never touched | | | | 359 | `memory_at`, 2.3 |
| `$C2FC-$C34F` | 84 | the stack: the game's `$C2FC-$C337`, the BASIC's from `$C338` | | | 40 | 44 | 2.3 |
| `$C350-$EFFF` | 11440 | graphics B; the rows of 128 bytes at `$C3D0-$D5AF` are read in part | | 9931 | 5 | 1504 | |
| `$F000-$F0EF` | 240 | the print variables (`$F0A2` set to 8 at `$8000`) | | 41 | 43 | 156 | |
| `$F0F0-$F9FF` | 2320 | a small routine `$F0F0-$F0FC`, then three fonts (FontSmall `$F100`, FontBold `$F400`, FontPlain `$F700`), read in part | 13 | 841 | | 1466 | |
| `$FA00-$FD7F` | 896 | the plot tables: PixelTable `$FA00` (column and mask of each x), ScreenLineTable `$FC00` (address of each pixel line) | | 896 | | | |
| `$FD80-$FFFF` | 640 | the print code (`$FFD0` prints a text), the IM 2 jump `$FFF4`, the vector byte `$FFFF` | 568 | | | 72 | |

Notes on the table:

- The 10 bytes written in each course script are five words, the last word of each sector-end record (Beginner
  `$B884`, `$B925`, `$B9AE`, `$BA51`, `$BB03`; Champion `$BBC7`, `$BC95`, `$BD42`, `$BDF0`, `$BED0`). `$A4EE` loads
  that word into `$B243` and prints it on the bonus screen, so it reads as the best time of the sector, kept in the
  script. The writer is for stage 2.
- The L1 write counters see only `$C312-$C337` and `$C34C-$C34D` of the stack; the bytes `$C2FC-$C311`, written while
  the interrupt handler runs, show only in `memory_at` (2.3). The stack row of the table and the figure are therefore short of
  writes, and its bounds come from `memory_at`.
- Never touched besides the above: the tape error texts `$8716-$87AB` (they need a tape with bad data),
  `$A72C-$A7CA`, `$B32A-$B349`, `$BEF0-$BEF7`.

## 2.3 The three images

`tools/images.py` keeps three 64 KB images in `work/images/`:

- `loaded-252-0.bin`: `c1` frame 252, T 0, after the ROM loaded the code block;
- `entry-256-58497.bin`: `c1` at the game's first instruction, `$8000`;
- `play-8000-0.bin`: `c1` frame 8000, in play.

```bash
python3 tools/images.py     # the diff ranges are kept in work/stage1/images-diff.txt
```

What changes inside the image `$60F8-$FFFF`:

- **loaded to entry**: 26 bytes in `$C330-$C34F`, the BASIC's stack (the return of `USR` and the calculator's
  frames). The image held zeros there.
- **entry to play**: 174 bytes in 39 ranges, all of them state:
  - `$B212-$B2C1`: the game's variables and the player records;
  - `$BEF8-$BF11`: the first objects of the object list;
  - `$C302-$C337`: the game's stack, below the entry SP `$C338`;
  - `$F000-$F02D` and `$F0A2`: the print variables.
- No table is built at start: no changed range is longer than 33 bytes.

The stack against `CLEAR 49999`: RAMTOP is `$C34F`, inside the image, so the BASIC's stack and the game's live on the
loaded bytes. The whole of `$BEF8-$C353` is zero in the loaded image (`loaded-252-0.bin`), so the stack overwrites
only zeros: no code or data is lost.

How deep it goes: nothing clears `$C195-$C337`, so the lowest non-zero byte there at the last frame of a recording is
the stack's low mark (`work/stage1/stacklow.py`, `memory_at`):

| Recording | Last frame | Low mark |
| --- | ---: | --- |
| `a1` | 21 614 | `$C300` |
| `g1` | 10 760 | `$C2FE` |
| `t1` | 3490 | `$C31A` |
| `p2` | 24 020 | `$C2FE` |
| `h1` | 7584 | `$C2FE` |
| `i1` | 30 440 | `$C2FC` |
| `i2` | 33 820 | `$C2FC` |
| `h2` | 4200 | `$C2FC` |
| `c1` | 8000 (`play-8000-0.bin`) | `$C302` |

- The stack reaches `$C2FC`, 60 bytes below the entry SP `$C338`. The bytes below `$C312` are the handler's: the
  return addresses `$7F37` (the handler's call of the tune player) and `$7F8D` (the tune player's call of BEEPER) and
  `$5C3A`, the IY it pushes (`i1` frame 10000, `$C2FC-$C311`). The L1 counters miss these writes, maybe the
  interrupt's own push and the ROM's; which, and whether interrupts nest after BEEPER's `EI`, is for stage 2.
- `$C195-$C2FB`, 359 bytes, stay free in all nine recordings.
