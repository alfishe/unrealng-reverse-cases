# 3. Build and load

What this covers: the medium block by block, the loader, the bootstrap, the source build. The recordings it rests
on: c1 (power-on on a 128K, the 128K menu's Tape Loader, the tape at signal speed: fast and turbo tape off).

<!-- Figures this document needs (GUIDE.md 4.2), remove each line when it is in: -->
<!-- - an animation of the load (`kit/memanim.py`) -->
<!-- - the build (mermaid) -->

## 3.1 The tape block by block

`orig/Switchblade.tzx.zip` holds `Switch Blade.tzx` (README). `python3 tools/tzxblocks.py list work/stage1/media/switchblade.tzx`
lists seven blocks, all standard ROM-timed (block id `$10`: pilot 2168, sync
667/735, zero 855, one 1710):

| Block | Kind | Data | Pause | Time | Loaded by | Where |
| ---: | --- | ---: | ---: | ---: | --- | --- |
| 0 | text "Created with Ramsoft MakeTZX" | | | | | |
| 1 | header, Program "( Switch )", LINE 0 | 17 | 2048 ms | 5.09 s | the ROM | |
| 2 | the BASIC | 361 | 2051 ms | 4.07 s | the ROM | PROG `$5CCB` |
| 3 | headerless | 2060 | 6159 ms | 12.81 s | the loader at `$FF02`, from `$FFEE` | `$609C-$68A7` |
| 4 | headerless | 37 537 | 4104 ms | 205.61 s | the loader at `$FF00`, from `$612F` | `$6B5C-$FDFC` |
| 5 | headerless | 4497 | 2059 ms | 27.20 s | the same | `$4000-$5190` |
| 6 | headerless | 8441 | 16 029 ms | 49.01 s | the same, on a 128K only | bank 4 `$C000-$E0F8` |

The tape runs 336.2 s with its pauses (16 812 frames). `tools/image.py` cuts the image from these blocks; checked
against c1 with `time_travel memory_at` at frame 15 503, T 66 911 (the `JP $4000`): bank 4 is the same byte for byte;
the 64 K view differs only where the image leaves zeros or the loader rewrites its own data (the system variables,
the BASIC's stack area `$5D0D-$5D36`, `$5E34-$5E5C`, `$620B`, `$670B-$68A7` and `$FFFD-$FFFF`).

**The BASIC.** `python3 tools/basic_list.py` shows one line, number 0: `LET X=PEEK 23635+256*PEEK 23636: LET
x=x+60: RANDOMIZE USR x`. The listing shows 87 where the hidden binary value is 60 (it prints "87{=60}"), so the
address is PROG + 60 = `$5D07`; the rest of the 361 bytes is machine code behind the line.

**The code at `$5D07`** (`sna2skool.py -H -o 0 -s 0x5D07 -e 0x5D37` over `work/mkgame/original.bin`):

| Address | What it does |
| --- | --- |
| `$5D07` | `DI`; `$10` to `$7FFD` (bank 0 at `$C000`, the 48K BASIC ROM); border black; the screen cleared (`LDIR` over `$4000-$5AFF`) |
| `$5D1E` | `LD SP,$0000` / `CALL $0555`: `$0555` is a `RET` in the 48K ROM (`data/rom/48for128.rom` of unreal-ng holds `$C9` there), so the call leaves its return address `$5D24` at `$FFFE`; `DEC SP` twice and `POP HL` read it back: the code finds where it was loaded |
| `$5D27` | `HL` + `$13` = `$5D37`, `SP` set there, then 253 bytes (`LD BC,$00FD`) copied from `$5D37` to `$FF00-$FFFC`; `JP $FFEE` |
| `$FFEE` | `LD A,$FF` / `LD IX,$609C` / `LD DE,$080C` / `CALL $FF02` / `JP $609C`: block 3, 2060 bytes, to `$609C` |

**The loader at `$FF00`** is a copy of the ROM's LD-BYTES with two changes: the border colours come from `AND $02`
(black and red stripes), and a load error goes to its own routine `$FFB2`, which fills the attributes with `$47` and
prints "TAPE LOADING ERROR", then stops. There is no protection: no cipher, no packer, no timing check. The TAP copy
(ZXDB 31611) shows it: there the BASIC's `IN A,($FE) / RRA` (offset 123 of the block) is replaced with `JP $0562`,
the ROM's own edge loop, and the blocks load unchanged.

**Stage 2 at `$609C`** (block 3): `CALL $61B2` (attributes filled), `CALL $612F`, `JP $4000` (at `$60A2`). `$612F`:

1. loads block 4 (37 537 bytes) to `$6B5C`;
2. clears the attributes, then loads block 5 (4497 bytes) to `$4000`: the game's start code goes into the screen;
3. `$618E` tests the paging: it writes the complement of a byte to `$C000` with bank 4 paged, reads it back with
   bank 0 paged, and stores the result as a flag at `$4052` (inside the code just loaded);
4. on a 128K: `$616A` swaps `$8000-$A0F8` with bank 4 `$C000`, the loader reads block 6 (8441 bytes) to `$8000`,
   `$617B` swaps back: block 6 ends in bank 4 and the main program at `$8000` is whole again. On a 48K the block is
   not read (the tape runs on with nothing listening).

`$60A5-$612E` is never run on a load: a tape writer (headers built at `$FE00`, `$FE4D`, `$FECC`, `$FECE`, a header
template at `$68A8`), left from mastering (NOTES, doc 10).

**The bootstrap at `$4000`** (block 5, in the screen):

1. `DI`, `SP` = `$5C00`; if the flag at `$4052` is set, bank 4 (`$14` to `$7FFD`) is paged for its set-up, then `$10`;
2. `I` = `$FE`, `IM 2`, `$FE00-$FEFD` filled with `$FD` (the vector table), `$FDFD` = `JP $8456` (the handler,
   [WALKTHROUGH 1](../WALKTHROUGH.md#1-interrupts-and-timing));
3. `$4146` copied to `$5C00` (`$0F4D` bytes, over the system variables and the BASIC) and `$5093` to `$FF01` (`$FE`
   bytes, over the loader);
4. on a 128K: three-byte hooks written at `$5CFD`, `$A6EF`, `$A76F`, `$A75C` and `$5C9A` (calls to `$859E`, `$85B3`,
   `$85C5`), and 162 bytes copied from `$40A4` to `$853F`: the glue to the AY music in bank 4;
5. `JP $5CFA`: `CALL $6A7B`, the title.

**c1's timeline** (frames from power-on, the Tape Loader started at frame 200, signal speed):

| Frame | Event |
| ---: | --- |
| 710 | the BASIC's code runs (`$5D07`) |
| 713 | `$FFEE`: block 3 |
| 1345 | `$609C`, stage 2: block 4 |
| 13 070 | `$618E`, the paging test (after block 5) |
| 15 503 | `JP $4000` (T 66 911) |
| 15 505 | `$5CFA`, the game |
| 15 508 | `$6A7F`, the title |
| 16 008 | the menu on screen |

## 3.2 The build

Stage 4. `tools/image.py` already rebuilds the image from the original blocks (`case.json`).
