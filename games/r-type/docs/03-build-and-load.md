# 3. Build and load

What this covers: the medium block by block, the SpeedLock 7 loader and its decryption layers, the level loader, the
source build. The recordings it rests on: c1 (power-on, the original at signal speed, 48K: the whole SpeedLock load,
the entry at frame 11 700, the level 1 load) and l2-l8 (each level's load by the game's own loader); see
[WALKTHROUGH 6.0](../WALKTHROUGH.md#60-the-recordings).

<!-- Figures this document needs (GUIDE.md 4.2), remove each line when it is in: -->
<!-- - an animation of every unpack (`kit/memanim.py`) -->
<!-- - the build (mermaid) -->

## 3.1 The tape block by block

`orig/R-Type.tzx.zip` holds one file, `R-Type.tzx` (138 996 bytes). The table is `tools/tape_table.py`'s output;
"Emu" is the block number unreal-ng's tape API counts (it skips the TZX's archive info, group and text blocks), the
bytes are the block's as on the tape (the flag and, for the ROM and turbo blocks, the checksum included), the times
at 3.5 MHz without the pauses. "Loads to" is from the c1 recording: the 64 K view sampled every 25 frames through
the load (`tools/load_timeline.py`, `work/stage1/load-timeline.txt`) and the code arrivals of c1's L1 build
(`kit/rs.py stages`); the frames are c1's (the tape started at frame 234).

| TZX | Emu | Kind | Timings (T) | Bytes | Flag | Loads to | Time (s) |
| ---: | ---: | --- | --- | ---: | --- | --- | ---: |
| 0 |  | archive info |  |  |  |  | 0.00 |
| 1 | 0 | standard | ROM | 19 | `$00` | header: Program "R-TYPE", LINE 0, 4933 bytes | 5.09 |
| 2 | 1 | standard | ROM | 4935 | `$FF` | the BASIC at PROG `$5CCB-$700F`, code in it (entry `$5D06`) | 30.84 |
| 3 |  | group start | 'Speedlock 7 Block 1' |  |  |  | 0.00 |
| 4 | 2 | pure tone | tone 2165 x 1530 |  |  |  | 0.95 |
| 5 | 3 | pulses | 16 pulses |  |  |  | 0.01 |
| 6 | 4 | pure data | bits 714/1428 | 1 | `$E8` |  | 0.00 |
| 7 | 5 | pure data | bits 714/1428 | 233 | `$5F` | `$9000` area (c1 frames 2550-2600), read by the code at `$FEE8` | 1.14 |
| 8 |  | group end |  |  |  |  | 0.00 |
| 9 |  | group start | 'Speedlock 7 Block 2' |  |  |  | 0.00 |
| 10 | 6 | pure tone | tone 2165 x 1525 |  |  |  | 0.94 |
| 11 | 7 | pulses | 16 pulses |  |  |  | 0.01 |
| 12 | 8 | pure data | bits 714/1428 | 1 | `$E8` |  | 0.00 |
| 13 | 9 | pure data | bits 714/1428 | 6144 | `$C1` | `$4000-$57FF`, the loading screen (frames 2675-4200) | 30.54 |
| 14 | 10 | pure data | bits 875/1750 | 3 | `$07` |  | 0.02 |
| 15 | 11 | pure data | bits 714/1428 | 768 | `$F1` | `$8000-$82FF`, then copied to `$5800` (frame 4400) | 3.86 |
| 16 | 12 | pure data | bits 875/1750 | 3 | `$07` |  | 0.02 |
| 17 | 13 | pure data | bits 714/1428 | 11678 | `$50` | `$9710-$C4AD`, encrypted (frames 4400-7075), decrypted in place at frame 11700 | 53.42 |
| 18 | 14 | pure data | bits 875/1750 | 3 | `$07` |  | 0.02 |
| 19 | 15 | pure data | bits 714/1428 | 2 | `$EC` |  | 0.01 |
| 20 | 16 | pure data | bits 875/1750 | 3 | `$07` |  | 0.02 |
| 21 | 17 | pure data | bits 714/1428 | 4 | `$AB` |  | 0.02 |
| 22 | 18 | pure data | bits 875/1750 | 3 | `$07` |  | 0.02 |
| 23 | 19 | pure data | bits 714/1428 | 55 | `$69` | about `$FD80-$FDB6` (frame 7075) | 0.27 |
| 24 | 20 | pure data | bits 875/1750 | 3 | `$07` |  | 0.02 |
| 25 | 21 | pure data | bits 714/1428 | 10000 | `$07` | `$7000-$970F`, encrypted (frames 7100-9450), decrypted in place at frame 11700 | 46.93 |
| 26 | 22 | pure data | bits 875/1750 | 3 | `$07` |  | 0.02 |
| 27 | 23 | pure data | bits 714/1428 | 8841 | `$69` | `$C545-$E7CD` (frames 9475-11625), moved to `$DD18-$FFA0` at `$61BD` | 43.78 |
| 28 | 24 | pure data | bits 875/1750 | 3 | `$07` |  | 0.02 |
| 29 | 25 | pure data | bits 714/1428 | 115 | `$96` | `$FE40-$FEB2` (frame 11650): LoadLevel `$FE03` and the level loader | 0.56 |
| 30 | 26 | pure data | bits 875/1750 | 3 | `$07` |  | 0.02 |
| 31 | 27 | pure data | bits 714/1428 | 49 | `$AF` | `$61A8-$61D8` (frames 11675-11700): the last code, `JP $85FD` at `$61C6` | 0.24 |
| 32 | 28 | pure data | bits 875/1750 | 3 | `$07` |  | 0.02 |
| 33 | 29 | pure data | bits 714/1428 | 33 | `$96` |  | 0.16 |
| 34 | 30 | pure data | bits 875/1750 | 3 | `$07` |  | 0.02 |
| 35 | 31 | pure data | bits 714/1428 | 15 | `$18` |  | 0.07 |
| 36 |  | group end |  |  |  |  | 0.00 |
| 37 | 32 | stop the tape |  |  |  |  | 0.00 |
| 38 |  | text | 'Level 1' |  |  |  | 0.00 |
| 39 | 33 | turbo | pilot 2165 x 3251, sync 714/714, bits 583/1166 | 20 | `$E6` | header to `$6000` (18 bytes: the level digit at `$600D`, the length at `$6010`) | 2.08 |
| 40 | 34 | turbo | pilot 2165 x 3251, sync 714/714, bits 583/1166 | 13230 | `$E6` | the level at `$C4AE` (LoadLevel `$FE03`) | 50.24 |
| 41 | 35 | stop the tape |  |  |  |  | 0.00 |
| 42 |  | text | 'Level 2' |  |  |  | 0.00 |
| 43 | 36 | turbo | pilot 2165 x 3251, sync 714/714, bits 583/1166 | 20 | `$E6` | header to `$6000` (18 bytes: the level digit at `$600D`, the length at `$6010`) | 2.08 |
| 44 | 37 | turbo | pilot 2165 x 3251, sync 714/714, bits 583/1166 | 12858 | `$E6` | the level at `$C4AE` (LoadLevel `$FE03`) | 48.81 |
| 45 | 38 | stop the tape |  |  |  |  | 0.00 |
| 46 |  | text | 'Level 3' |  |  |  | 0.00 |
| 47 | 39 | turbo | pilot 2165 x 3251, sync 714/714, bits 583/1166 | 20 | `$E6` | header to `$6000` (18 bytes: the level digit at `$600D`, the length at `$6010`) | 2.08 |
| 48 | 40 | turbo | pilot 2165 x 3251, sync 714/714, bits 583/1166 | 13076 | `$E6` | the level at `$C4AE` (LoadLevel `$FE03`) | 49.65 |
| 49 | 41 | stop the tape |  |  |  |  | 0.00 |
| 50 |  | text | 'Level 4' |  |  |  | 0.00 |
| 51 | 42 | turbo | pilot 2165 x 3251, sync 714/714, bits 583/1166 | 20 | `$E6` | header to `$6000` (18 bytes: the level digit at `$600D`, the length at `$6010`) | 2.08 |
| 52 | 43 | turbo | pilot 2165 x 3251, sync 714/714, bits 583/1166 | 13000 | `$E6` | the level at `$C4AE` (LoadLevel `$FE03`) | 48.96 |
| 53 | 44 | stop the tape |  |  |  |  | 0.00 |
| 54 |  | text | 'Level 5' |  |  |  | 0.00 |
| 55 | 45 | turbo | pilot 2165 x 3251, sync 714/714, bits 583/1166 | 20 | `$E6` | header to `$6000` (18 bytes: the level digit at `$600D`, the length at `$6010`) | 2.08 |
| 56 | 46 | turbo | pilot 2165 x 3251, sync 714/714, bits 583/1166 | 8906 | `$E6` | the level at `$C4AE` (LoadLevel `$FE03`) | 33.95 |
| 57 | 47 | stop the tape |  |  |  |  | 0.00 |
| 58 |  | text | 'Level 6' |  |  |  | 0.00 |
| 59 | 48 | turbo | pilot 2165 x 3251, sync 714/714, bits 583/1166 | 20 | `$E6` | header to `$6000` (18 bytes: the level digit at `$600D`, the length at `$6010`) | 2.08 |
| 60 | 49 | turbo | pilot 2165 x 3251, sync 714/714, bits 583/1166 | 8851 | `$E6` | the level at `$C4AE` (LoadLevel `$FE03`) | 32.88 |
| 61 | 50 | stop the tape |  |  |  |  | 0.00 |
| 62 |  | text | 'Level 7' |  |  |  | 0.00 |
| 63 | 51 | turbo | pilot 2165 x 3251, sync 714/714, bits 583/1166 | 20 | `$E6` | header to `$6000` (18 bytes: the level digit at `$600D`, the length at `$6010`) | 2.08 |
| 64 | 52 | turbo | pilot 2165 x 3251, sync 714/714, bits 583/1166 | 12999 | `$E6` | the level at `$C4AE` (LoadLevel `$FE03`) | 48.48 |
| 65 | 53 | stop the tape |  |  |  |  | 0.00 |
| 66 |  | text | 'Level 8' |  |  |  | 0.00 |
| 67 | 54 | turbo | pilot 2165 x 3251, sync 714/714, bits 583/1166 | 20 | `$E6` | header to `$6000` (18 bytes: the level digit at `$600D`, the length at `$6010`) | 2.08 |
| 68 | 55 | turbo | pilot 2165 x 3251, sync 714/714, bits 583/1166 | 11982 | `$E6` | the level at `$C4AE` (LoadLevel `$FE03`) | 44.33 |

Total 592.9 s (29647 frames at 50 Hz), pauses not included.

The tape holds three parts:

- **The BASIC** (Emu 0-1): a ROM-speed program "R-TYPE" with LINE 0, whose one line is `RANDOMIZE USR
  ((PEEK 23635+256*PEEK 23636)+10)` with the hidden number 59 behind the visible 10 (`tools/basic_list.py`): the
  code at PROG + 59 = `$5D06` (c1 stage 0: `$5D06` entered at frame 2081 from the ROM's `$34BB`). The block is
  4935 bytes: the code of the first SpeedLock stage lives in the program area after the line.
- **The SpeedLock 7 part** (Emu 2-31): pure-data blocks at 714/1428 T a bit (and 875/1750 T for the 3-byte `$07`
  markers), read by SpeedLock's own edge loop. Before the first byte is read, the code at `$5D06` copies itself to
  `$EC00` and runs 26 decryption layers, each decrypting the rest of `$EC00-$FEE7` and jumping into it (c1 stages
  1-26, frames 2083-2398: `$EC00`, `$EC34`, `$EDAF`, ... `$FB7E`); the last writes the loader at `$FEE8-$FFCF` (stage
  27, entered at frame 2599). The screen and its attributes load in the clear; the two code blocks (11 678 and 10 000
  bytes) load encrypted and are decrypted in place in one sweep at frame 11 700 (`$7000-$C4AD`, 21 678 bytes changed
  between the samples of frames 11 675 and 11 700, writer `$FE49`). The last small block puts the tail at
  `$61A8-$61D8`, which ends the load: `LD SP,$6FFE`, `DI`, `LDDR` of 8850 bytes (`$E7CD` down to `$FFA1`: the
  8841-byte block to `$DD18-$FFA0`), `LD A,$30: LD BC,$7FFD: OUT (C),A` (on a 128K this locks the paging in the 48K
  layout; on the 48K the write reaches no device), `JP $85FD` at `$61C6` (c1 stage 28: `$85FD` entered at frame
  11 700 T 1379 from `$61C6`). Which code reads Emu 5 and the small blocks (2, 4, 55, 33 and 15 bytes) and where each
  of those lands is left to stage 2 (the samples cannot tell a block that is all zeros).
- **The levels** (Emu 32-55): eight levels, each behind a "stop the tape" block (Emu 32, 35, ... 53) and a TZX text
  block "Level N", each a turbo pair (pilot 2165 T x 3251, syncs 714/714, bits 583/1166 T, flag `$E6`): an 18-byte
  header and the level. The header's bytes 0-12 are `00 00 AA 00 AA 00 AA 00 AA 00 AA 00 00`, byte 13 the level as an
  ASCII digit (`'1'`-`'8'`), bytes 14-15 zero, bytes 16-17 the level's length. The levels are 13 228, 12 856, 13 074,
  12 998, 8904, 8849, 12 997 and 11 980 bytes. They are not encrypted: their bodies are in memory byte for byte at
  `$C4AE` (`work/stage1/media-levels.txt`; the copies of other publishers hold them unchanged).

## 3.2 The level loader

The game's entry `$85FD` sets `SP` to `$FFFE`, builds a bit-reverse table at `$5D00`, sets `I = $84` and `IM 2`
(the table `$8400-$8500`, every byte `$83`; `$8383` holds `JP $BE23`), and calls LoadLevel `$FE03` before the title
(the code at `$8624-$8646` in the image at the entry, `work/stage1/images/entry.cpu.bin`). LoadLevel:

- adds 1 to the level digit `$719C` (in "R TYPE LEVEL 1" at `$7196`) and prints SEARCHING FOR and LOADING with that
  string on the bottom row;
- reads the 18-byte header to `$6000` through its own edge loop (`$8F1F`, `IN A,($FE)` at `$8F32` and `$8FA7`), and
  skips any level whose digit `$600D` is not `$719C` (so a tape wound too far back still finds the level);
- reads the level to `$C4AE` with the length `($6010)` through the same routine, with interrupts off: `$8F1F` starts
  with `DI` and pushes `$FEC0`, so every return of the edge loop lands on `EI; RET C` at `$FEC0` (carry clear there
  drops the caller's return address and prints ERROR IN LOADING); in c1 `$8F1F` and `$FEC0` each ran twice, header
  and body (`work/stage1/c1/l1.json`);
- prints ERROR IN LOADING on a bad checksum: a key held during the load gives it (the first probe chain, stage 1
  notes); STOP TAPE THEN PRESS ANY KEY after a good one.

A level ends when its attack-wave script reaches its end record: `$90E7` stores `$41` in the countdown `$7A9B`, and
the level-end step `$C25E` (called every pass) then calls LoadLevel through `$C2A3`. At digit `'8'` it does not:
`$C276` turns the digit to `'9'`, writes `RET` to `$91F5` and play goes on with level 8's boss on screen; at the next
end `$C28B` sets `'0'` and LoadLevel shows REWIND SIDE 2 THEN PRESS ANY KEY (the string at `$7280`, `$FE1D-$FE29`),
then turns the digit to `'1'` and searches for level 1 (recording ending: `$C28B`, `$C290` and `$C2A3` once each; l8:
`$C276` once, `$C2A3` never; l7: `$C2A3` once). The tape is at its end then. Level 8's object table holds a closing
text at `$CAFF` (THANKS TO YOUR BRAVE FIGHTING ... THE PROGRAMMER., [the level 8 sheet](img/sprites/objects-level-8.png));
no recording reads those bytes, so what shows it is open (stage 2).

The MCM re-release keeps the same code but for `$8F1F-$8FBA` (153 bytes differ from the image at the entry), the
edge loops: its levels are standard ROM-speed blocks (README).

## 3.3 The image

The image of this case is the 64 K view at the entry, frame 11 700 T 1379 of c1 (`tools/ttd_dump.py`,
`work/stage1/images/entry.cpu.bin`): `$7000-$C4AD` (the two code blocks, decrypted) and `$DD18-$FFA0` (the 8841-byte
block) plus the SpeedLock leftovers. The MCM side A blocks `$DD18` (8841 bytes) equal it byte for byte; its `$7000`
block (21 678 bytes) differs only at `$8F1F-$8FBA`. Stage 2 rebuilds it from the tape by undoing the SpeedLock
layers in `tools/`.
