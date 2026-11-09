# 3. Build and load

What this covers: the medium block by block, the loaders, the source build. The recordings it rests on: `c1` (from
power-on, `Video Pool.tzx`; the ROM blocks through the fast LD-BYTES trap, the turbo block at signal speed through
the loader at `$F000`; WALKTHROUGH 1).

<!-- Figures this document needs (GUIDE.md 4.2), remove each line when it is in: -->
<!-- - the tape as a picture (blocks, times, where they land) -->
<!-- - the loader's flowchart and its animation (`kit/memanim.py`) -->
<!-- - the build (mermaid) -->

## 3.1 The tape, block by block

The original release (`orig/VideoPool.tzx.zip`, `Video Pool.tzx`) holds an archive-info block and five data blocks:
four standard ROM blocks and one turbo block (TZX block id `$11`). The game itself is the turbo block. The Paxman
re-release holds the same five data blocks byte for byte (other pauses, a text block in place of the archive info).

| Block | Kind | Data (+2 on tape) | Loads at | Time on tape | Pause after |
| ---: | --- | ---: | --- | ---: | ---: |
| 0 | archive info: "Video Pool", Oxford Computer Publishing, James Hutchby, 1985, "Original", "TZXed by Andrew Barker For Tony Barnett" | | | | |
| 1 | header: Program "VIDEO POOL", LINE 10 | 17 | | 5.09 s | 986 ms |
| 2 | the BASIC loader | 44 | the BASIC area | 2.24 s | 1849 ms |
| 3 | header: Bytes "VIDEO POOL", start 61440, length 256 | 17 | | 5.09 s | 990 ms |
| 4 | the turbo loader | 256 | `$F000-$F0FF` | 3.42 s | 2 ms |
| 5 | turbo, no header: the game | 25 000 | `$8000-$E1A7` | 105.23 s | 39 620 ms |

Blocks 1-4 have the ROM's timings (pilot 2168 T, zero 855 T, one 1710 T). Block 5 has the loader's: 3240 pilot
pulses of 2165 T, two sync pulses of 714 T, zero 660 T, one 1320 T. Its first byte is the flag `$FF` and its last is
an XOR checksum, as in a ROM block. The tape lasts 121.07 s without the pauses, 6063 frames of the 48K (69 888 T a
frame). With the pauses between the blocks, and without the 39.6 s of silence at the end, it lasts 124.9 s (6255
frames).

In `c1` the ROM blocks go through the fast LD-BYTES trap and block 5 at signal speed: the loader at `$F000` starts at
frame 250, the turbo block loads from frame 300 to 5529, and the game is entered at `$8000` at frame 5556 (T 25 555).

The BASIC loader (block 2, 44 bytes):

```basic
10 CLEAR 32767
20 LOAD "" CODE
30 RANDOMIZE USR 61440
```

- Line 10 puts RAMTOP at `$7FFF`, below the game.
- Line 20 loads block 4 at the address in its header, `$F000`.
- Line 30 runs it.

The loader at `$F000` (block 4) is a copy of the ROM's LD-BYTES with its own timing constants. It:

1. writes 0 into the two bytes at ERR_SP's address (`LD HL,($5C3D)`), so a BASIC error would go to address 0, a
   reset;
2. loads 25 000 bytes at `$8000` with flag `$FF` (`IX` = `$8000`, `DE` = `$61A8`) through its own edge loop, which
   jumps into the ROM's LD-SAMPLE at `$05EC` for each edge, and returns through SA/LD-RET `$053F`; a load error
   jumps to 0;
3. adds the 25 000 bytes into a 16-bit sum and compares it with the word at `$F03C`, `$2E3F`; a mismatch jumps
   to 0;
4. jumps to the game at `$8000`.

`tools/image.py` checks the same sum on the tape's bytes. The loader's flowchart, its timing constants against the
ROM's and its animation are stage 2's work.

The point: one turbo block holds the whole game. The protection is the turbo timing and the sum; nothing is
encrypted or packed, so the game's bytes on the tape are the image at `$8000`.

### The conversion, for comparison

`VIDPOOL.TAP` in `orig/VideoPool.tap.zip` is not the original. It holds a 162-byte BASIC ("Modify by JANSOFT 1985",
`CLEAR 32767`, `LOAD "" CODE`, `RANDOMIZE USR 32768`) and the 25 000 bytes as a standard block at `$8000`
(149.1 s at ROM speed, 7467 frames). Against the original turbo block 207 bytes differ, in 25 runs, every one a byte
the original holds as zero or a table the game fills at run time (`$869E-$86C0`, `$8A89-$8AE9`, `$9F4B-$9F66`,
`$CFC0-$CFFF` and smaller ones), and the key names at `$B668` (`'z' right='x' fire=' '` where the original has
blanks). The TAP's code was saved from a game that had run.

Commands (WALKTHROUGH 0): `python3 tools/tzxblocks.py list "work/media/tzx/Video Pool.tzx"`,
`python3 ../../kit/tapblocks.py list work/media/tap/VIDPOOL.TAP`.
