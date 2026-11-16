# 3. Build and load

What this covers: the medium block by block, loaders, packers and their formats, the unpack animations, the source build. The recordings it rests on: c1 (the TOSEC `[SpeedLock 2]` copy of the tape on a 48K, played at signal speed from power-on: the ROM's own LOAD for the two BASIC blocks, SpeedLock 2's loader for the rest) and m128 (the same on a 128K); [WALKTHROUGH 6.0](../WALKTHROUGH.md#60-the-recordings).

<!-- Figures this document needs (GUIDE.md 4.2), remove each line when it is in: -->
<!-- - an animation of every unpack (`kit/memanim.py`) -->
<!-- - the build (mermaid) -->
<!-- - the tape's blocks in time (the loader stages) -->

## 3.1 The tape block by block

`orig/EnduroRacer.tzx.zip` holds one file, `Enduro Racer.tzx` (TZX 1.20, 51 505 bytes). Its 160 TZX blocks are
17 data blocks and the tone, pulse and pause blocks between them. The table gives each data block, the TZX blocks
from its first lead-in block to the block itself, and the times at signal speed. Witness: `tools/tape_table.py
"work/media/Enduro Racer.tzx"` (the table is its output, the kinds named by hand) and `tools/tzxblocks.py list` for
each TZX block.

| # | TZX blocks | Kind | Bytes (flag + data + check) | Flag | Bit 0 / 1 (T) | Lead-in (s) | Data (s) | Pause (ms) | Ends at (s) |
| ---: | --- | --- | ---: | --- | --- | ---: | ---: | ---: | ---: |
| 1 | 0 | ROM header, Program "enduro", 205 bytes, LINE 0 | 19 | `00` | 855 / 1710 | 4.99 | 0.10 | 846 | 5.09 |
| 2 | 1 | ROM data: the first BASIC | 207 | `FF` | 855 / 1710 | 2.00 | 1.17 | 1763 | 9.10 |
| 3 | 2 | ROM header, Program "end2", 1770 bytes, LINE 0 | 19 | `00` | 855 / 1710 | 4.99 | 0.10 | 871 | 15.95 |
| 4 | 3 | ROM data: the second BASIC | 1772 | `FF` | 855 / 1710 | 2.00 | 9.99 | 3710 | 28.81 |
| 5 | 5-69 | pure data (the TZX group "SpeedLock 2 Block 1") | 18 | `CE` | 565 / 1130 | 4.45 | 0.07 | 1537 | 37.03 |
| 6 | 72-136 | pure data: the loading screen | 6912 | `6C` | 565 / 1130 | 4.44 | 27.19 | 0 | 70.20 |
| 7 | 137-138 | pure data | 4608 | `8B` | 565 / 1130 | 0.02 | 18.30 | 0 | 88.51 |
| 8 | 139-140 | pure data | 4096 | `39` | 565 / 1130 | 0.02 | 16.28 | 0 | 104.81 |
| 9 | 141-142 | pure data | 2 | `AB` | 565 / 1130 | 0.02 | 0.01 | 0 | 104.83 |
| 10 | 143-144 | pure data | 4 | `34` | 565 / 1130 | 0.02 | 0.02 | 0 | 104.87 |
| 11 | 145-146 | pure data | 5376 | `92` | 565 / 1130 | 0.02 | 21.30 | 0 | 126.18 |
| 12 | 147-148 | pure data | 23 | `28` | 565 / 1130 | 0.02 | 0.09 | 0 | 126.29 |
| 13 | 149-150 | pure data | 18 776 | `AD` | 565 / 1130 | 0.02 | 75.85 | 0 | 202.16 |
| 14 | 151-152 | pure data | 13 | `C1` | 565 / 1130 | 0.02 | 0.05 | 0 | 202.23 |
| 15 | 153-154 | pure data | 64 | `01` | 565 / 1130 | 0.02 | 0.25 | 0 | 202.49 |
| 16 | 155-156 | pure data | 4096 | `11` | 565 / 1130 | 0.02 | 15.71 | 0 | 218.21 |
| 17 | 157-158 | pure data | 3585 | `FF` | 565 / 1130 | 0.02 | 13.89 | 0 | 232.12 |

The tape plays 232.1 s, 11 606 frames at 50 Hz; TZX block 159 is a text block. Between data blocks 6 and 17 each
gap is one pulse block of 875 / 1750 T pulses (`tools/tzxblocks.py list`, TZX id `13`), SpeedLock 2's marks that join
the blocks into one stream with no pause. The flag bytes of the pure-data blocks are not `FF` and their XOR check
does not come out at zero: the loader reads and checks the blocks its own way (stage 2).

The data blocks 6 to 17 hold 41 555 bytes. None of them appears unchanged in the loaded memory: 16-byte samples at
eight offsets of each block, searched in the 64K dump `work/stage1/probe2/loaded.bin`, find nothing (block 6, the
loading screen, included, since the game has drawn over it by then), so the loader decodes or moves what it loads.
The data blocks are byte for byte those of the TOSEC `[SpeedLock 2]` and Proein copies (`tools/media_compare.py`,
[README](../README.md#other-releases-and-copies)).

## 3.2 The loader, first look

1. The first BASIC (`enduro`, data block 2) is one line with the line number 65 280 and a false line length of
   13 568; `tools/basic_list.py work/media/b1.bin` lists it as `PAPER 0: INK 0: BORDER 0: CLS : PRINT USR 6746931:
   LOAD ""` (with colour codes that hide it on screen). The number's text says 6 746 931; the five-byte form after it
   holds 23 829 (`$5D15`), which is what `USR` runs: an address 74 bytes into the program, inside the same line. The
   code there sets `R` and `I` (`LD R,A` and `LD I,A`, program offsets `$7D` and `$88`) and loops over the bytes
   after it.
2. `LOAD ""` loads the second BASIC (`end2`, data block 4, 1770 bytes): a `REM` line "Protected by SPEEDLOCK" with
   the false length 32 768, then about 1600 bytes in which the only readable fragments are "33+256", "ff),", "YOURS"
   and, at the end, "sanity!" (`strings` on `work/media/b3.bin`): encoded code.
3. SpeedLock 2's own loader reads data block 5, then the loading screen (block 6; c1's screen at frame 882 shows it
   being drawn), then the rest without stops. The game's credits screen follows the tape's end.

The code arrivals of m128 (`kit/rs.py stages`, the 128K recording from power-on) give the order the stages run:

| Stage | Entry | Frame (m128) | Written | By | Entered from |
| --- | --- | ---: | --- | --- | --- |
| 0 | `$5B00` | 53 | `$5B00-$5B57` | `$014A` | `$0068` (the 128K ROM's own code in the printer buffer, not the game's) |
| 1 | `$5D15` | 618 | `$5CCB-$5D97` | `$05AE` (ROM LD-BYTES) | `$34BB` (`USR`): the first BASIC's code |
| 2 | `$FCA3` | 1532 | `$FCA3-$FFBF` | `$62B8` | `$62BA` |
| 3 | `$FCD1` | 1533 | `$FCD1-$FFBF` | `$FCCB` | `$FCCD` |
| 4 | `$FF37` | 1577 | `$FD2C-$FFBF` | `$FCE5` | `$FD1D`: the tape loader proper, until the tape's end |
| 5 | `$8000` | 11 457 | `$61A4-$FFFF` | `$5B09` | `$5B0E`: the game's entry |

Stages 2 to 4 decode one another in place at the top of memory (each writes the bytes the next runs); stage 5's
code was written by a routine at `$5B09` in the printer buffer, so the loader leaves a mover there before it jumps
to `$8000`. After stage 5 the list goes on with the game's own self-modifying code (one-byte writes into its
routines followed by entries there, from frame 12 204), not with more loader stages. The loader's keys and the
decoding are stage 2's (recipe 02).
