# 3. Build and load

What this covers: the medium block by block, the loader and its bit-reversed blocks, the level loads from side B,
the source build. The recordings it rests on: `c1` (128K, power-on, side A at ROM speed) and the level loads of
[WALKTHROUGH 6.0](../WALKTHROUGH.md#60-the-recordings) (side B at ROM speed).

<!-- Figures this document needs (GUIDE.md 4.2), remove each line when it is in: -->
<!-- - an animation of every load (`kit/memanim.py`) -->
<!-- - the build (mermaid) -->

## 3.1 The tape block by block

`orig/RickDangerous2.tzx.zip` holds two TZX files, one a tape side, every block a standard-speed TZX block `$10`
(pilot 2168, sync 667 and 735, bits 855 and 1710 T-states): `tools/tzxblocks.py list` on each. The times are the
blocks' own, with the pause after each in the last column.

| Side, TZX block | Kind | Bytes | Loaded at | Read by | Time | Pause |
| --- | --- | --- | --- | --- | --- | --- |
| A 1 | header, Program "RICK-II" | 17 | | the 128K's Tape Loader (ROM) | 5.09 s | 0.40 s |
| A 2 | BASIC: `10 PAPER 0: INK 0: BORDER 0`, `20 CLEAR 65279`, `30 LOAD ""CODE`, `40 RANDOMIZE USR 65280` | 75 | the program area | ROM LD-BYTES | 2.39 s | 4.51 s |
| A 3 | header, Bytes "loader", 256 bytes at 65280 | 17 | | ROM LD-BYTES | 5.09 s | 0.98 s |
| A 4 | the loader, encrypted ([3.2](#32-the-loader-at-ff00)) | 256 | `$FF00-$FFFF` | ROM LD-BYTES | 3.50 s | 6.32 s |
| A 5 | headerless, bit-reversed: the loading screen | 6912 | `$4000-$5AFF` | the loader `$FF2D` | 37.70 s | 6.20 s |
| A 6 | headerless, bit-reversed: the game | 40 702 | `$6000-$FEFD` | the loader `$FF2D` | 221.39 s | 3.60 s |
| B 1 | headerless, bit-reversed: level 1, Hyde Park London | 21 760 | `$A800-$FCFF` | the level loader (`$846A` area) | 116.39 s | 11.42 s |
| B 2 | the same: level 2, the Ice Caverns of Freezia | 21 760 | `$A800-$FCFF` | the same | 115.22 s | 10.39 s |
| B 3 | the same: level 3, the Forests of Vegetablia | 21 760 | `$A800-$FCFF` | the same | 115.58 s | 10.81 s |
| B 4 | the same: level 4, the Atomic Mud Mines | 21 760 | `$A800-$FCFF` | the same | 116.84 s | 9.38 s |
| B 5 | the same: level 5, the Fat Guy's headquarters | 21 760 | `$A800-$FCFF` | the same | 117.33 s | 58.58 s |

Side A takes 297.2 s with its pauses (14 859 frames), side B 682.0 s (34 098 frames). The level names are the Kixx
side B's TZX names and the level menu's strings (`$7FE1-$8063`).

A bit-reversed block is a standard block whose every byte, the flag and the checksum included, is stored with its
bits in the opposite order; its checksum byte is chosen so that the XOR of all its bytes is `$FF`, where the ROM's is
`$00`. The ROM cannot read one: `tools/image.py` turns them back (a table of the 256 reversed bytes). Witnesses: the
image `tools/image.py` writes equals the memory of `c1` at the entry (`$7B8F`, frame 13 998, T 9477; `$6000-$FEFD`
and the screen, 0 bytes differ: `tools/ttd_dump.py`, `work/stage1/images/entry.cpu.bin`), and side B's block 2 equals
`$A800-$A800+21759` after the level 2 load (`work/stage1/lab/dump-e6-end`, 0 bytes differ; the other four blocks
differ in 15 069 to 16 331 bytes there).

On a 128K level 1 is part of block A 6: at the entry `$A800-$FCFF` holds side B's block 1 but for 762 bytes at
offsets `$426E-$456C` (`$EA6E-$ED6C`), so level 1 starts with no tape. Those bytes are the last 768 of the level's
maps, encrypted in every side B block and decrypted by `$894E` when a level starts; side A holds level 1 decrypted
([doc 2, 2.2](02-architecture.md#22-the-level-maps)). Any other level asks "START TAPE ON SIDE TWO" (`$843A`), reads
side B from its first block and skips the blocks before the wanted one, then "STOP TAPE AND PRESS FIRE" (`$8451`).
The level menu (`$7F44`) lists level 5 only when `$8065` is set, after four levels completed in one game (`$7DA8`):
from the menu after side A it lists 1-4, so `load-l5` sets `$8065` by a POKE, said so. Started at a later block, the
count is wrong and the machine resets (lab run `work/stage1/lab/e4`, `e5`: the © 1982 Sinclair screen).

## 3.2 The loader at `$FF00`

The BASIC clears to 65 279, loads the 256 bytes at `$FF00` and calls them. The block is encrypted from `$FF0B`: its
first instructions XOR every byte from `$FF0B` to `$FFFF` with IYH (`$5C`, the ROM's IY = `$5C3A`), running while D
is not 0. The first byte decrypted is the operand of the loop's own `JR NZ` at `$FF0A` (`$AB` XOR `$5C` = `$F7`, the
jump back), so the loop decrypts itself as it runs. `c1`: the loader at frame 1110 T 65 924, `$FF0C` (after the
decryption) at frame 1111 (`re_session.py stages`).

Then it sets SP to 0 and reads two headerless blocks with flag `$FF` through its own copy of the ROM's LD-BYTES
(`$FF2D`): the screen to `$4000` (6912 bytes) and the game to `$6000` (`$9EFE` bytes), then `EI` and `JP $7B8F`. The
copy keeps the ROM's timings (the edge loop's 22, the pilot and sync limits 156, 198, 201 and 212) and differs in
three places:

| | ROM LD-BYTES | the loader |
| --- | --- | --- |
| a byte's bits | `LD L,$01` and `RL L`: the first bit read is bit 7 | `LD L,$80` (`$FF9A`) and `RR L` (`$FFA3`): the first bit read is bit 0 |
| the checksum test | `LD A,H; CP 1` (H = 0 when good) | `LD A,H; CPL; CP 1` (`$FFB1`): H = `$FF` when good |
| a failed block | returns with carry clear | returns to `$FFD8`, pushed at `$FF35`: `JP NC,0`, the machine resets |

The tail `$FFDF-$FFFF` holds fragments the stack later overwrites (SP = 0 grows down into it); the Kixx copy differs
there only (32 bytes from offset 223, [README](../README.md#other-releases-and-copies)).
