# 3. Build and load

What this covers: the medium block by block, loaders, packers and their formats, the unpack animations, the source
build. The recording it rests on: `c1`, from power-on with `Chuckie Egg.tzx` on the 48K: the BASIC block through the
fast LD-BYTES trap, the two headerless blocks at signal speed through the loader's own calls of LD-BYTES
(WALKTHROUGH 1).

<!-- Figures this document needs (GUIDE.md 4.2), remove each line when it is in: -->
<!-- - the tape as a picture (blocks, times, where each lands) -->
<!-- - the loading picture as the loader draws it (`kit/screen_anim.py`) -->
<!-- - the build (mermaid) -->

## 3.1 The tape, block by block

The original release (`orig/ChuckieEgg.tzx.zip`, `Chuckie Egg.tzx`) holds a text block and four standard ROM blocks
(TZX block id `$10`). There is no turbo block, no packer and no cipher: the game arrives as plain bytes. The Pick &
Choose re-release holds the same four data blocks byte for byte (README).

| Block | Kind | Data (+2 on tape) | Loads at | Time on tape | Pause after |
| ---: | --- | ---: | --- | ---: | ---: |
| 0 | text: "Created with Ramsoft MakeTZX" | | | | |
| 1 | header: Program "CHUCKIE", length 1624, LINE 10, program 18 bytes (the rest is the variables area) | 17 | | 5.09 s | 984 ms |
| 2 | the BASIC program and its variables area: line 10 `RANDOMIZE USR 24307`, then the loader's graphics, code and picture text | 1624 | PROG `$5CCB-$6322` | 10.71 s | 995 ms |
| 3 | headerless: `01 00` | 2 | ERR_SP `$5C3D-$5C3E` | 2.02 s | 1001 ms |
| 4 | headerless: the game | 18 900 | `$8214-$CBE7` | 97.47 s | 19 798 ms |

- Every block has the ROM's timings: pilot 2168 T (8063 pulses for the header, 3223 for data), sync 667 / 735 T,
  zero 855 T, one 1710 T. Each block starts with its flag (`$00` the header, `$FF` the data) and ends with the XOR
  checksum; all four check.
- The signal lasts 115.29 s, which is 5774 frames of the 48K (69 888 T a frame). With the three pauses between the
  blocks (2.98 s) the tape lasts 118.27 s; the 19.8 s of silence after the game is left out.
- Block 2 is 1624 bytes, but the header says the program is only 18 bytes: line 10 (`RANDOMIZE USR 24307`, 14 bytes
  of text plus the line's number and length). The other 1606 bytes are the variables area, which BASIC never reads.
  It holds, in this order:
  - `$5CE3-$5EF2`: 66 characters of 8 x 8 graphics for the loading picture;
  - `$5EF3-$601B`: the loader, entered by `USR 24307` (`$5EF3`);
  - `$601C-$631B`: the loading picture as 24 rows of 32 character codes, codes below `$5F` drawn from the ROM font,
    codes `$60` and up from the graphics at `$5CE3`;
  - `$631C-$6322`: seven bytes past the picture.
- The loader, as `z80dasm` gives it from the block (doc 3.2 will list it):
  - sets ATTR_T `$5C48` to 7, clears the screen and its attributes, sets the border black;
  - draws the picture (`$5FC9` prints one character), paints the attribute bands;
  - loads block 3 with the ROM's LD-BYTES (`CALL $0556`, IX `$5C3D`, DE 2, flag `$FF`);
  - loads block 4 the same way (IX `$8214`, DE `$49D4` = 18 900);
  - sets STKBOT and STKEND (`$5C63`, `$5C65`) to `$5DC0` and jumps to the game at `$A410` (`$5FC1`).
- Block 3 puts `$0001` into ERR_SP, where the ROM keeps the address of its error return. The game's main loop starts
  by reading it (`$9858`: `LD HL,($5C3D); DEC HL; LD A,H; OR L; JR NZ,$985E`, and `$985E` is a `JR NZ` to itself), so
  any other value hangs the game in a two-byte loop; with `$0001` the loop falls through. A copy that loads the game
  without block 3 does not run. In `c1` the read at `$9858` ran 312 001 times in the game window (L1 of `work/game`).
- The picture's text gives the keys: "USE FOUR DIRECTION KEYS WITH A JUMP KEY TO GUIDE YOUR MAN AND COLLECT A DOZEN
  EGGS. YOU MAY CHANGE THE DIRECTION AND JUMP KEYS. THERE ARE ALSO THE FOLLOWING FIXED KEYS: CAPS SHIFT & H ...
  HOLD, CAPS SHIFT & A ... ABORT".

```bash
python3 tools/tzxblocks.py list "work/media/tzx6194/Chuckie Egg.tzx"      # the blocks, timings, checksums
python3 tools/image.py work/mkgame/original.bin                            # blocks 2-4 where the loader puts them
```

**The point**: a plain ROM-speed tape. The only trick on it is block 3: two bytes that make ERR_SP `$0001`, which the
game's main loop tests on every pass.
