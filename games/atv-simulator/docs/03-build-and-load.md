# 3. Build and load

What this covers: the medium block by block, loaders, packers and their formats, the unpack animations, the source build. The recordings it rests on: (name each, with its load).

<!-- Figures this document needs (GUIDE.md 4.2), remove each line when it is in: -->
<!-- - an animation of every unpack (`kit/memanim.py`) -->
<!-- - the build (mermaid) -->

## 3.1 The tape block by block

`orig/ATVSimulator.tzx.zip` holds one file, `ATV Simulator.tzx` (TZX 1.20, 47 124 bytes): eight standard-speed
blocks (TZX id `10`), all at the ROM's timings (pilot 2168 T, bits 855 / 1710 T), listed by
`python3 ../../kit/tapblocks.py list "work/media/ATV Simulator.tzx"`. The times are at signal speed; "Ends at" adds
the pauses.

| # | Kind | Bytes (with flag and checksum) | Flag | Time (s) | Pause (ms) | Ends at (s) | Loads to |
| ---: | --- | ---: | --- | ---: | ---: | ---: | --- |
| 0 | ROM header, Program "ATV", LINE 10 | 19 | `00` | 5.08 | 1007 | 6.09 | |
| 1 | ROM data: the BASIC loader | 46 | `FF` | 2.24 | 1885 | 10.21 | PROG `$5CCB` |
| 2 | ROM header, Bytes "", 34 at 65500 | 19 | `00` | 5.08 | 1003 | 16.30 | |
| 3 | ROM data: the machine-code loader | 36 | `FF` | 2.21 | 1777 | 20.29 | `$FFDC-$FFFD` |
| 4 | ROM header, Bytes "", 6912 at 50000 | 19 | `00` | 5.08 | 1008 | 26.38 | read by no one |
| 5 | headerless: the loading screen | 6914 | `FF` | 37.63 | 2197 | 66.20 | `$4000-$5AFF` |
| 6 | ROM header, Bytes "", 40000 at 25400 | 19 | `00` | 5.08 | 1009 | 72.29 | read by no one |
| 7 | headerless: the game | 40002 | `FF` | 209.62 | 0 | 281.91 | `$6338-$FF77` |

The blocks alone (pauses not included) play 272.0 s, 13 601 frames; with the pauses 281.9 s, 14 096 frames. Recording c1 (power-on, the tape at signal speed) runs the game's
entry at frame 14 114; the tape stops at frame 14 182.

## 3.2 The loaders

Block 1 is three lines of BASIC (`work/stage1/media/b1.bin`):

```basic
10 CLEAR 25400
20 LOAD ""CODE
30 RANDOMIZE USR 65500
```

`CLEAR 25400` puts RAMTOP at `$6338`, the first byte of the game. `LOAD ""CODE` loads block 3 to its header's
address, `$FFDC`. The machine-code loader there (34 bytes, `python3 tools/z80dis.py work/stage1/media/tape64.bin FFDC FFFE`):

```z80
FFDC  POP AF            ; drop the return address into BASIC
FFDD  LD IX,$4000       ; the screen
      LD DE,$1B00
      LD A,$FF          ; flag $FF: a data block
      SCF               ; load, not verify
      CALL $0556        ; LD-BYTES
      JR NC,$FFDD       ; a block that fails (the header of block 4) is read again
FFEC  LD IX,$6338       ; the game, 40000 bytes
      LD DE,$9C40
      LD A,$FF
      SCF
      CALL $0556
      JR NC,$FFEC       ; the header of block 6 fails the same way
FFFB  JP $D6B0          ; the game's entry
```

Blocks 4 and 6 are standard headers that no one reads: LD-BYTES asks for flag `$FF`, a header's flag is `$00`, so
the ROM returns with carry clear and the loader asks again; the next block is the data. Their fields (6912 at 50000,
40000 at 25400) are what a header-reading loader would want; the copies without them load the same
([README](../README.md#other-releases-and-copies)). The game's 40000 bytes end at `$FF77`, below the loader at
`$FFDC`: the loader is not overwritten while it runs. No protection, no packer: the image at the jump to `$D6B0` is
blocks 5 and 7 as they are on the tape.
