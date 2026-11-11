# 3. Build and load

What this covers: the medium block by block, the BASIC loader, the 128K setup, the source build. The recordings it
rests on: `c1` (power-on, the original tape at ROM speed on the 128K; [WALKTHROUGH 6.0](../WALKTHROUGH.md#60-the-recordings)).

<!-- Figures this document needs (GUIDE.md 4.2), remove each line when it is in: -->
<!-- - an animation of every unpack (`kit/memanim.py`) -->
<!-- - the build (mermaid) -->

## 3.1 The tape block by block

`orig/Terramex.tzx` holds five standard-speed blocks (TZX block `$10`), read by `tools/tzxblocks.py`. Durations are
the pulses at ROM timing (3.5 MHz), the frames 48K frames of 69 888 T; the whole tape plays in 430.1 s without the
pauses, 464.2 s with them.

| Block | Bytes (with flag and checksum) | Seconds | Pause after | Frames | Contents | Loaded to |
| ---: | ---: | ---: | ---: | ---: | --- | --- |
| 1 | 19 | 5.09 | 989 ms | 255 | header: Program "TERRAMEX", 302 bytes, LINE 0, variables at 58 | |
| 2 | 304 | 3.66 | 1703 ms | 183 | the BASIC line 0 and, in its variables area, the loader (3.2) | `$5CCB` (PROG) |
| 3 | 6 914 | 35.80 | 1150 ms | 1793 | the loading screen ([picture](img/play/loading-screen.png)) | `$4000-$5AFF` |
| 4 | 38 650 | 187.91 | 7777 ms | 9411 | the explorer selector `$6000-$71FF`, the 128K setup at `$7200`, the five explorer data sets `$9CF8-$F6F7` (`$1200` bytes each) | `$6000-$F6F7` |
| 5 | 36 354 | 197.66 | 22 475 ms | 9899 | the game: data `$7200-$8EFF`, code from GameEntry `$8F00`, room and tile data to `$FFFF` | `$7200-$FFFF` |

Blocks 3-5 are headerless; the loader gives their addresses and lengths to LD-BYTES `$0556`. Block 5 loads over the
upper part of block 4 (`$7200-$F6F7`), so what stays of block 4 in the 64 K is `$6000-$71FF`; on a 128K the setup at
`$7200` has copied what it needs to the other RAM pages first (3.3). No packer and no protection beyond the hidden
loader. The image of this case (`tools/image.py`) lays the blocks the same way; at the game entry it equals the
recording `c1` in `$4000-$5AFF` and `$6000-$FFFF`.

## 3.2 The BASIC loader

The program is one line, line 0, whose stated length (`$FF36`) runs past the end of the program, so a LIST shows a
single `RANDOMIZE USR (3 + PEEK 23627 + 256 * PEEK 23628)`: VARS + 3. The machine code (241 bytes,
`work/stage1/blocks/ldr.bin`) sits in the variables area and runs at `$5D08` in `c1` (L1 arrival at frame 696 from
`$34BB`, the ROM's USR). It is position independent: every address of its own comes from BC, the USR address.

| Step | Code | What |
| --- | --- | --- |
| 1 | `DI`, `LD SP,$5FE6`, push BC + 123, `LD ($5C3D),SP` | ERR_SP points at an error handler of its own: BREAK during a load clears the screen, sets the attributes to `$0F` and prints "User pressed break-reload!" |
| 2 | clear `$4000-$5AFF`, border 0, `LD ($5FFE),HL` with HL = 0 | the 128K flag `$5FFE` starts 0 |
| 3 | `LD A,($8000)`, `CP $C9` | `$5B03` = 1 when `$8000` holds `$C9`, else 0 |
| 4 | LD-BYTES `$4000`, `$1B00` | block 3, the screen |
| 5 | LD-BYTES `$6000`, `$96F8` | block 4 |
| 6 | `LD BC,$7200`, `CALL $7200` | the 128K setup and the selector (3.3) |
| 7 | a loop: border = C, `INC C` while a key is held | waits for the keys to be released |
| 8 | LD-BYTES `$7200`, `$8E00` | block 5 |
| 9 | `JP $8F00` | GameEntry: in `c1` at frame 21597 t 67875 |

## 3.3 The 128K setup at `$7200`

`$7200` (in block 4) writes `$AA` and `$55` at `$C000` with two RAM pages in turn and reads them back. On a 128K it
copies `$7200-$A0DF` (`$2EE0` bytes) to RAM 1 at `$C000` (the music player and the rest), the five explorer data sets
to RAM 4 (`$C000`, `$D200`, `$E400`: explorers 0-2) and RAM 3 (`$C000`, `$D200`: explorers 3-4), sets `$5FFE` = `$11`,
copies the selector `$6000-$71FF` to RAM 6 and jumps to it at `$C000` (L1 arrival at frame 11841 t 26159 from
`$72A7`; the copy written by `$7243`). When the player picks an explorer, its set is copied to `$6000-$71FF` (the
index in `$5B70`) and the selector returns to the loader, which loads block 5. The 48K path (the tape stopped by the
TZX `$2A` block of some dumps, the selector run in place) is not recorded yet
([WALKTHROUGH 6.0](../WALKTHROUGH.md#60-the-recordings)).

The stages of `c1` from the L1 arrivals (`$RS stages`):

| Arrival | Frame, T in frame | From | What |
| --- | --- | --- | --- |
| `$5B00` | 53, 45129 | `$0068` | the 128K ROM's paging routines copied to `$5B00-$5B57` |
| `$5D08` | 696, 29832 | `$34BB` | the loader (3.2) |
| `$C000` | 11841, 26159 | `$72A7` | the selector in RAM 6 |
| `$5FE6` | 11841, 42590 | `$C0F9` | an `OUT (C),A`, `RET` written there by `$C0EF` |
| `$8F00` | 21597, 67875 | the loader's `JP` | GameEntry (found with `time_travel find_last`, access execute) |
| `$5F5F` | 21599, 1866 | the interrupt, in `$93B9` | the first IM 2 interrupt, on the menu |
