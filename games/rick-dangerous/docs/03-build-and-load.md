# 3. Build and load

What this covers: the medium block by block, loaders, packers and their formats, the unpack animations, the source build. The recordings it rests on: `c1` (power-on, the original TZX at ROM speed on the 128K).

<!-- Figures this document needs (GUIDE.md 4.2), remove each line when it is in: -->
<!-- - an animation of every unpack (`kit/memanim.py`) -->
<!-- - the build (mermaid) -->

## 3.1 The tape block by block

`orig/RickDangerous.tzx.zip`: `Rick Dangerous.tzx`, 217 TZX blocks (0-216), 198 of them data. Listed with
`python3 tools/tzxblocks.py list` (`work/stage1/media/zxdb-RickDangerous.tzx/Rick Dangerous.tzx.list.txt`); the
times are the TZX's own pulses and pauses, 382.6 s in all (19 129 frames at 50 Hz). The game is entered at frame
19 010 of `c1` (frame 0 is power-on; the 128 menu's Tape Loader taken with ENTER, ROM speed).

| TZX blocks | What | Size (data +2) | Loads at | Time |
| --- | --- | ---: | --- | ---: |
| 0 | text "Created with Ramsoft MakeTZX" | | | |
| 1-2 | Program "Rick", LINE 10, standard speed | 19, 183 | BASIC | 5.1 + 2.9 s |
| 3-4 | Bytes "Rick1", standard speed: the first loader stage | 19, 514 | `$CD00` (512 bytes) | 5.1 + 4.9 s |
| 5-58 | group 1 "Bleepload Group 1": a 2.88 s pure tone, then 48 turbo blocks | 268-275 each | `$C900`, `$CF00-$FB00`, `$5D00`, `$FF0E`, by the block's own address | 83.8 s of blocks |
| 59-204 | group 2 "Bleepload Group 2": a 2.88 s pure tone, then 140 turbo blocks | 267 each | `$6E00-$F9FF`, 256 bytes a block | 240.7 s of blocks |
| 205-216 | group 3 "Bleepload Group 3": a 2.88 s pure tone, then 6 turbo blocks | 267 each | `$4000-$45FF` (the top third of the screen bitmap) | 10.2 s of blocks |

The BASIC (`tools/basic_list.py`): `10 REM RICK DANGEROUS v.2/89`, `20 CLEAR 50000`, `30 BORDER 0: PAPER 0: INK 0:
CLS`, `40 PRINT AT 1,8; PAPER 1; INK 7;" RICK DANGEROUS "`, `50 LOAD "Rick1" CODE 52480`, `60 RANDOMIZE USR 52480`.

The turbo blocks (pilot 2165 T, sync 667 and 735 T, bits 856 and 1712 T, about 249 pilot pulses each) load at
`$FE00` with flag `$FF`. A block's layout there:

| Offset | Address | What |
| --- | --- | --- |
| 0 | `$FE00` | the group's marker: `$64` (group 1), `$34` (group 2), `$35` (group 3) |
| 1-256 | `$FE01-$FF00` | 256 bytes of payload, enciphered |
| 257 | `$FF01` | the block's number in its group (`$00-$2F`, `$00-$8B`, `$00-$05`) |
| 258-259 | `$FF02-$FF03` | where the payload goes |
| 260 on | `$FF04` on | a code tail the loader runs (`JP (HL)`), 5 to 13 bytes, then the checksum |

The payload is enciphered, so the game image is not cut from the tape: `tools/image.py` lets SkoolKit's tap2sna.py
simulate the whole load on a 128K and stops at the entry `$AB4D` (`DI`, `LD SP,0`, `CALL $A043`). Its image matches
`c1` at frame 19 010, T-state 70 580, except 39 bytes of `$5B89-$5BDD`.
