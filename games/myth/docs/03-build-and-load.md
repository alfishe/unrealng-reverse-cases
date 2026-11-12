# 3. Build and load

What this covers: the medium block by block, the Speedlock 7 loader and its stages, the multiload of the five stage
blocks. The recordings it rests on: c1 (`work/stage1/c1`, a 48K from power-on, the original tape at signal speed by
its own loader, `fast_tape` and `turbo_tape` off) and the RZX run's snapshots (`work/stage1/rzx/snap0-5.z80`).

<!-- Figures this document needs (GUIDE.md 4.2), remove each line when it is in: -->
<!-- - an animation of every unpack (`kit/memanim.py`) -->
<!-- - the build (mermaid) -->

## 3.1 The tape block by block

`python3 tools/tzxblocks.py list work/stage1/media/myth.tzx` (the TZX unpacked from `orig/`); the data of every block
with its flag and checksum is in `work/stage1/blocks/bNN.bin`. Times are the TZX's own (pulses plus the pause);
c1 frames are where the recording's tape reached the block (frame 234: PLAY pressed once after `LOAD ""`).

| TZX block | Kind | Bytes (flag) | Where it goes | Time | c1 |
| --- | --- | --- | --- | ---: | --- |
| 0 | archive info | | "Speedlock 7", "Original", "TZXed by Andrew Barker" | | |
| 1 | standard header | 17 (`$00`) | Program "MYTH", 4514 bytes, LINE 0 | 5.08 s | from 234 |
| 2 | standard data | 4514 (`$FF`) | the BASIC at PROG `$5CCB-$6E6C` (ROM LD-BYTES) | 28.49 s | entered at 1963 |
| 3-8 | group "Speedlock 7 Block 1": tone, sync pulses, a 1-byte `$E8` piece, 171 bytes (`$5F`) | 169 | read by the Speedlock loader `$FF26` | 1.79 s + 2.5 s pause | from 2387 |
| 9-36 | group "Speedlock 7 Block 2": tone, sync, `$E8`, then 6144 (`$2E`), 768 (`$F1`), 1152 (`$BB`), 2, 4, 55, 768 (`$D9`), 2176 (`$83`), 115, 15, 33, 15-byte pieces, each after a 3-byte `$07` piece at another bit length | 11 216 | read by `$FF26`; ends with the jump to `$F040` after copying `$E000-$FFFF` (frame 5166, writer `$5B1F`) | 55.4 s + 3.3 s pause | to 5166 |
| 37 | turbo data (pilot 2165, zero 583, one 1166) | 15 360 (`$56`) | the main block: `$6C3F-$A83E`, the logo, the credits and the menu; entered at `$7800` | 49.39 s + 4.2 s pause | 5167-7826 |
| 38 | pause 0 (stop the tape) | | | | 7734 |
| 39-40 | text "Stage 1: The Road To Hell", turbo data | 33 792 (`$56`) | stage 1 over `$6C3F-$F03E` | 122.03 s + 3.5 s | 8626-14976 |
| 41 | pause 0 | | | | 14976 |
| 42-43 | text "Stage 2: Greece 400 BC", turbo data | 33 792 (`$56`) | stage 2 over `$6C3F-$F03E` | 122.10 s + 3.8 s | RZX |
| 44 | pause 0 | | | | |
| 45-46 | text "Stage 3: Scandinavia 500 AD", turbo data | 33 792 (`$56`) | stage 3 over `$6C3F-$F03E` | 122.21 s + 4.5 s | RZX |
| 47 | pause 0 | | | | |
| 48-49 | text "Stage 4: Egypt 3000 BC", turbo data | 33 792 (`$56`) | stage 4 over `$6C3F-$F03E` | 120.71 s + 4.4 s | RZX |
| 50 | pause 0 | | | | |
| 51-52 | text "Stage 5: Duel With Dameron", turbo data | 33 792 (`$56`) | stage 5 over `$6C3F-$F03E` | 109.38 s + 44.6 s | RZX |

The whole tape: 815.9 s with the pauses (40 797 frames). The emulator's tape counts blocks its own way (the group
markers and the text blocks are not blocks to it): the main block is its block 32, the stop after it 33, stage 1 is 34.

Where the blocks land is measured, not read from a header:

- The main block equals the memory at `$6C3F` for all 15 360 bytes in the RZX run's first snapshot (`snap0`, the menu,
  PC `$F9B5`), and each stage block equals the memory at `$6C3F` for all 33 792 bytes in the snapshot taken when that
  stage was loaded (`snap1` to `snap5`, PC `$FEFE`). c1's L1 names the writer: `$FF02` (`LD (IX),L` in the turbo
  loader) wrote `$6C3F-$A83E` before the entry `$7800` at frame 7826.
- The stage block replaces the main block whole: the two share only their first 965 bytes and 320 bytes at `$76C0`
  (`work/stage1/blocks/b37.bin` against `b40.bin`), so each stage block carries its own copy of the game's code. What
  stays is the resident part `$F03F-$FFFF` put there by the Speedlock loader: the stage loader and its texts, the IM 2
  handler, the AY driver, the key readers, the score and the turbo loader ([doc 2](02-architecture.md#22-the-memory-map)).
- The stage blocks are not enciphered: every hack and re-save carries them byte for byte under its own loader
  (README, Other releases).

## 3.2 The Speedlock 7 loader, its stages in c1

`python3 ../../kit/rs.py stages --work work/stage1/c1` (c1's L1, 16 658 frames):

| Stage | Entry | Frame | Written | By | What it is |
| --- | --- | ---: | --- | --- | --- |
| 0 | `$5D06` | 1963 | `$5CCB-$6E6C` | the ROM `$05AE` | the BASIC's machine code: line 0 is `RANDOMIZE USR ((PEEK 23635+256*PEEK 23636)+10)` with the hidden number 59, so PROG + 59 = `$5D06`; its stated length (14 080) runs past the program |
| 1 | `$EDE4` | 1967 | `$EDE4-$FF25` | `$5D27` | the block copied up from the BASIC |
| 2-31 | `$EE11` ... `$F9CA` | 1971-2189 | each `$xxxx-$FF25` | the layer before | 30 decryption layers, each decoding the rest of the block up to `$FF25` and running into it |
| 32 | `$FF26` | 2387 | `$FF26-$FFCF` | `$FDBA` | the Speedlock loader proper: reads TZX blocks 3-36 |
| 33 | `$F040` | 5166 | `$E000-$FFFF` | `$5B1F` | the resident code, copied to `$E000-$FFFF` and entered |
| 34 | `$FEFE` | 5167 | `$FEFE` | `$F638` | the IM 2 vector's `JP` written by SetIm2 `$F635` |
| 35 | `$7800` | 7826 | `$6C3F-$A83E` | `$FF02` | the main block, loaded by the turbo loader called from `$F08D` |
| 37 | stage 1 | 15079 | `$7F23-$F03E` | `$FF02` | stage 1, loaded the same way |

The stages after 37 are code of the stage block entered for the first time (L1 counts a stretch run first after a
load as an arrival) and the self-modified copy loop `$9B09` ([doc 2](02-architecture.md#22-the-memory-map)).
Reimplementing the 31 layers and finding where TZX blocks 3-36 land is stage 2's work.
