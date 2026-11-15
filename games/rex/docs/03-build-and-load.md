# 3. Build and load

What this covers: the medium block by block, loaders, packers and their formats, the unpack animations, the source
build. The recordings it rests on: `c1` (power-on, side 1 at ROM speed on the 128K, [WALKTHROUGH 6.0](../WALKTHROUGH.md#60-the-recordings)).

<!-- Figures this document needs (GUIDE.md 4.2), remove each line when it is in: -->
<!-- - the tape as a picture (blocks, times) -->
<!-- - an animation of every unpack (`kit/memanim.py`), or one line: there is none -->
<!-- - the build (mermaid) -->

## 3.1 The tape block by block

`orig/Rex.tzx.zip` holds two files, one a side of the cassette. Every data block is a standard ROM block (TZX `$10`:
pilot 2168 T, syncs 667 and 735 T, zero 855 T, one 1710 T); the times are at 3.5 MHz, from `tools/tzxblocks.py list`,
and the bytes are the block's as it is on the tape, the flag and the checksum included (the data + 2). Block 0 of each
file is a TZX text block, "Created with Ramsoft MakeTZX".

**Side 1** (`Rex - Side 1.tzx`): two programs, REX 1 (part 1, level 1) and then REX 2 (part 2, level 2).

| Block | Bytes | Flag | What it is | Loads to | Time | Pause after |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 19 | `$00` | Program header "REX 1", length 151, LINE 1 | | 5.09 s | 1012 ms |
| 2 | 153 | `$FF` | the BASIC of REX 1 (151 bytes, listed below) | the BASIC area | 2.77 s | 4196 ms |
| 3 | 19 | `$00` | Bytes header "ds", length 6912, start 40000 (`$9C40`) | | 5.09 s | 1013 ms |
| 4 | 6914 | `$FF` | the loading screen of REX 1 | `$4000` (`LOAD "" SCREEN$` ignores the header's start) | 33.62 s | 5275 ms |
| 5 | 19 | `$00` | Bytes header "ds", length 40930, start 24600 (`$6018`) | | 5.09 s | 1014 ms |
| 6 | 40 932 | `$FF` | the code of REX 1 | `$6018-$FFF9` | 217.43 s | 23 072 ms |
| 7 | 19 | `$00` | Program header "REX 2", length 151, LINE 1 | | 5.09 s | 1017 ms |
| 8 | 153 | `$FF` | the BASIC of REX 2 | the BASIC area | 2.77 s | 4404 ms |
| 9 | 19 | `$00` | Bytes header "ds", length 6912, start 40000 | | 5.09 s | 1017 ms |
| 10 | 6914 | `$FF` | the loading screen of REX 2 (142 bytes differ from REX 1's, from offset 2147) | `$4000` | 33.54 s | 5147 ms |
| 11 | 19 | `$00` | Bytes header "ds", length 40530, start 25000 (`$61A8`) | | 5.09 s | 1015 ms |
| 12 | 40 532 | `$FF` | the code of REX 2 | `$61A8-$FFF9` | 214.80 s | 42 693 ms |

Side 1 plays 535.47 s, 26 816 frames of 69 888 T, without its pauses (90.9 s of pauses on the tape); REX 1 alone
(blocks 1-6) 269.1 s, 13 478 frames.

**Side 2** (`Rex - Side 2.tzx`): DEMO, the "Tutor Mode" of the instructions.

| Block | Bytes | Flag | What it is | Loads to | Time | Pause after |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 19 | `$00` | Program header "DEMO", length 150, LINE 1 | | 5.08 s | 1016 ms |
| 2 | 152 | `$FF` | the BASIC of DEMO | the BASIC area | 2.77 s | 3804 ms |
| 3 | 19 | `$00` | Bytes header "ds", length 6912, start 40000 | | 5.09 s | 1015 ms |
| 4 | 6914 | `$FF` | the loading screen of DEMO (97 bytes differ from REX 2's) | `$4000` | 33.52 s | 3960 ms |
| 5 | 19 | `$00` | Bytes header "ds", length 40530, start 25000 (`$61A8`) | | 5.09 s | 1011 ms |
| 6 | 40 532 | `$FF` | the code of DEMO: REX 2's layout (the same length and address), 34 535 bytes different from REX 2's code; byte for byte the Your Sinclair covertape demo (ZXDB `RexDemo.tap`) | `$61A8-$FFF9` | 207.89 s | 0 |

Side 2 plays 259.44 s, 12 993 frames, without its pauses.

The point: there is no custom loader and no protection. Each part is a BASIC that loads a screen and one code block
with the ROM and runs it; the two parts are two programs on the same side, and side 2 holds the demo.

### The BASIC

The three programs differ only in their `CLEAR` and their entry (`tools/basic_list.py` on the blocks' data):

| Line | REX 1 | REX 2 | DEMO |
| --- | --- | --- | --- |
| 10 | `PAPER 0: INK 0: BORDER 0: CLS` | the same | the same |
| 20 | `CLEAR 24599` (`$6017`) | `CLEAR 24999` (`$61A7`) | `CLEAR 24999` |
| 30 | `LOAD "" SCREEN$` | the same | the same |
| 40 | `PRINT AT 0,0;` | the same | the same |
| 50 | `LOAD "" CODE` | the same | the same |
| 60 | `RANDOMIZE USR 38010` (`$947A`) | `RANDOMIZE USR 38000` (`$9470`) | `RANDOMIZE USR 35460` (`$8A84`) |
| 999 | `SAVE "t:": SAVE "REX 1" LINE 1: LOAD "a:": LOAD "make1"` | the same with "REX 2", "make2" | the same with "DEMO", "maked" |

Line 999 never runs (the program starts at line 1 and line 60 does not return). It is the authors' mastering line:
`SAVE "t:"` and `LOAD "a:"` select a tape and a disk drive in the syntax of a disk interface, so the parts were
put together from a disk ("make1", "make2", "maked") and saved to tape with `SAVE ... LINE 1` (known only from the
BASIC's text; no recording runs it; which interface is not known).

The entries were checked in the code: REX 1's `$947A` starts with `DI` and clears the game's variables
(`work/stage1/zdis.py` on block 6).
