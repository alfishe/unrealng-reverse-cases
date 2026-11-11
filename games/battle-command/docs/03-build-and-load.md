# 3. Build and load

What this covers: the medium block by block, loaders, packers and their formats, the unpack animations, the source
build. The recordings it rests on: c1 (power-on, side 1 at signal speed, the ROM's own loader for the BASIC and the
game's SpeedLock 7 loader for the rest; play pressed at frame 208; then side 2 read by the game), search, m2ocean and
m2erbe ([WALKTHROUGH 6.0](../WALKTHROUGH.md#60-the-recordings)).

<!-- Figures this document needs (GUIDE.md 4.2), remove each line when it is in: -->
<!-- - an animation of every unpack (`kit/memanim.py`) -->
<!-- - the build (mermaid) -->

## 3.1 The tape block by block

### Side 1: the program

`python3 tools/tzxblocks.py list work/stage1/media/side1.tzx` lists 45 TZX blocks, 484.1 s with the pauses. The
frames are c1's (tape played at frame 208), the start of each block from the TZX timings, and the destination from
`time_travel memory_at` of every bank every 250 frames over the load (`work/stage1/loadscan.py`): the bank whose bytes
change while the block plays.

| TZX blocks | Kind | Data bytes | c1 frames | Destination |
| --- | --- | --- | --- | --- |
| 0 | text "Created with Ramsoft MakeTZX" | | | |
| 1, 2 | standard header "BATTLE" (Program, 4917 bytes, `LINE 0`) and its data | 4917 | 208-1999 | the BASIC area `$5CCB-$6FFF` (bank 5), by the ROM's `LD-BYTES` (`$05AE` writes it, stage 1 below) |
| 3-8 | group "Speedlock 7 Block 1": pure tone 2165 T x 1579, sync pulses, a 1-byte block (`$E8`), a 196-byte block (zero 714 T, one 1428 T) | 196 | 2002-2050 | `$BF0D-$BFD0` (bank 2): the loader's next stage, run at `$BF0D` (stage 22) |
| 9-13 | group "Speedlock 7 Block 2": tone, pulses, `$E8`, the screen | 6144 | 2099-3609 | `$4000-$57FF` (bank 5): the loading screen's bitmap |
| 14, 15 | mark `07 FF 00`, then data | 768 | 3659-3865 | the attributes `$5800-$5AFF` |
| 16-21 | three marks and three short blocks | 2, 4, 75 | 3866-3887 | control bytes for the loader (stage 2 reads them) |
| 22, 23 | mark, data | 9472 | 3888-6150 | bank 5 `$5B00-$7FFF`, rewritten in place at frame 23974 |
| 24, 25 | mark, data | 16 384 | 6151-10158 | bank 0 |
| 26, 27 | mark, data | 15 615 | 10158-13981 | bank 1 `$C301-$FFFF`: a staging copy of `$8301-$BFFF` |
| 28, 29 | mark, data | 5120 | 13982-15236 | bank 3 `$C000-$D3FF` |
| 30, 31 | mark, data | 3584 | 15237-16111 | bank 4 `$C000-$CDFF` |
| 32, 33 | mark, data | 14 848 | 16112-19771 | bank 6 `$C000-$F9FF` |
| 34, 35 | mark, data | 16 384 | 19772-23804 | bank 7 |
| 36-43 | four marks and four short blocks | 115, 15, 54, 15 | 23805-23856 | control bytes, the last read before the jump |

Every mark is the 3 bytes `07 FF 00` at zero 875 T / one 1750 T, every data block zero 714 T / one 1428 T with the
last byte's bits given in the TZX (5 for the marks, 6 for the 1-byte blocks). No data block is found in memory as it
is on the tape (`work/stage1/findblocks.py entry` finds none of them in the eight banks at the entry): the loader
deciphers as it loads. The Erbe re-release's unprotected blocks are the deciphered ones: its ROM-speed blocks sit
byte for byte at bank 5 `$5B00` (9472), bank 0 (16 384), bank 3 (5120), bank 4 (3584), bank 6 (14 848) and bank 7
(16 384) of c1 at the entry (`findblocks.py entry` with the Erbe side 1).

![The banks filled during the load of side 1 in c1](img/load/load-timeline.png)

*Drawn by `tools/fig_load_timeline.py` from `work/stage1/loadscan.json`: each bar is the bytes a bank gained in 250
frames, each tape block above it at its time. Zero bytes of a block do not show (bank 0 gains 7087 non-zero bytes
from its 16 384).*

### The stages

`re_session.py stages` over c1's L1 (the code arrivals: a byte written, then executed):

| Stage | Entry | c1 frame | Written by | Entered from | What it is |
| --- | --- | --- | --- | --- | --- |
| 0 | `$5B00` | 53 | ROM 0 `$014A` | `$0068` | the 128K ROM's paging routine in the system variables |
| 1 | `$5D06` | 2028 | ROM 1 `$05AE` (LD-BYTES) | ROM `$34BB` (USR) | the machine code inside the BASIC: line 0 is `RANDOMIZE USR (PEEK 23635+256*PEEK 23636)+59`, PROG `$5CCB` + 59 |
| 2 | `$AC38` | 2033 | `$5D27` | `$5D29` | the stage-1 code moves `$AC38-$BF0C` out of the program and jumps there |
| 3-21 | `$AC5D` ... `$B844` | 2037-2288 | the instruction before each entry | the instruction before each entry | 19 layers, each rewriting the rest of `$ACxx-$BF0C` and running into it: a decryption chain |
| 22 | `$BF0D` | 2484 | `$BDA1` | `$BF0B` | the 196-byte SpeedLock block, loaded by the loader's byte store `$BDA1` and run |
| 23 | `$68F4` | 23974 | `$BE66` (`$5C3C-$7FFF`) | `$8043` | the game's entry, after the bootstrap at `$8000` |

The bootstrap at `$8000` (bank 2 of the image at the entry, `work/stage1/dis.sh work/mkgame/original.bin 8000 8044`):

```
$8000 LD HL,$2758 / EXX / LD SP,$8200 / LD IY,$5C3A / RES 4,(IY+1)
$800F three loads (HL, DE, BC; then HL, DE, BC again) with no use before they are loaded anew
$8021 LD BC,$7FFD / LD A,$11 / OUT (C),A          ; bank 1 at $C000, ROM 1
$8028 LD HL,$C301 / LD DE,$8301 / LD BC,$3CFF / LDIR   ; the 15 615 staged bytes to $8301-$BFFF
$8033 LD BC,$7FFD / LD A,$10 / OUT (C),A          ; bank 0 at $C000
$803A LD HL,$68F4 / LD DE,$8000 / XOR A / LD B,$44 / JP (HL)   ; $8043: into the game
```

Worked through on c1: at frame 23724 bank 2 still holds the loader; at 23974 10 838 of its bytes differ and 47 of its
256-byte pages equal bank 1's at the same offset. Bank 1 never changes again (the menu recording's L1 has no read and
no write of it). The loader cannot load bank 2's game code into the bank it runs from, so it stages the code in bank 1
and the bootstrap copies it over the loader. Stages 24-33 are the game's first calls into the banks it pages at
`$C000` and its self-modifying code (`$7256`, `$9DB2`, `$9E40`, `$D4B8`); stage 31 (`$E381`, frame 32222) is code that
came with the mission block from side 2.

The game image of the case is the eight banks at the jump to `$68F4` (c1 frame 23974, t 30350): `tools/image.py`
reads them from c1 (`case.json`). Ciphered blocks and a decryption chain mean the image cannot yet be cut from the
tape directly; that is stage 2's.

### Side 2: the mission tape

`python3 tools/tzxblocks.py list work/stage1/media/side2.tzx`: 43 blocks, 620.3 s, all at ROM speed with standard
timings. The game reads them with its own routine: the catalogue lands at `$CB64` in bank 4 while its header says
`$8904`.

| TZX blocks | Contents | Data bytes | Where the game puts it |
| --- | --- | --- | --- |
| 1, 2 | header `\x03DIRECTORY:` (Bytes, length `$1BD4` = 7124, start `$8904`), data | 7124 | bank 4 `$CB64-$E737` (c1: bank 4 +`0B64`-`2737` changes between frames 24508 and 28827) |
| 3-6 | stop, text "Blast Em Mission", a 17-byte block `\x03MISSHDR:1:` + length `$1F7A`, data | 8058 | bank 0 `$DBC5-$FB3E` (c1: bank 0 +`1BC5`-`3B3E` changes between frames 28827 and 31954) |
| 7-10 | stop, "Missile Battery", `MISSHDR:2:` length `$1906` = 6406, data | **6384** | see m2ocean in [WALKTHROUGH 0.2](../WALKTHROUGH.md#02-the-release-check) |
| 11-14 | "Hostage Rescue", `MISSHDR:3:` | 6769 | as mission 1 |
| 15-18 | "Railway Ambush", `MISSHDR:4:` | 6418 | |
| 19-22 | "Night Moves", `MISSHDR:5:` | 7534 | |
| 23-26 | "Escort Duty", `MISSHDR:6:` | 7716 | |
| 27-30 | "Satellite Search", `MISSHDR:7:` | 7748 | |
| 31-34 | "River Raid", `MISSHDR:8:` | 6204 | |
| 35-38 | "Hideout", `MISSHDR:9:` | 6709 | |
| 39-42 | "Grand Finale", `MISSHDR:::` (the character after `9`) | 7014 | |

The mission header is 17 bytes: `$03`, the 10 characters `MISSHDR:n:`, the length word, four zero bytes. SEARCH
reads the tape up to the next mission header, whichever mission it is, and lights that mission's box on the clipboard
(the search recording); SELECT then loads the block after it. A player winds the tape to the mission wanted; the
recordings seek the tape to its header.
