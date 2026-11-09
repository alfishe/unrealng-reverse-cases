# 3. Build and load

What this covers: the medium block by block, loaders, packers and their formats, the unpack animations, the source build. The recordings it rests on: (name each, with its load).

<!-- Figures this document needs (GUIDE.md 4.2), remove each line when it is in: -->
<!-- - an animation of every unpack (`kit/memanim.py`) -->
<!-- - the build (mermaid) -->

## 3.1 The tape, block by block

The TAP and the TZX in `orig/` (ZXDB 3266) hold the same four standard blocks; the TZX adds only a text block
("Created with Ramsoft MakeTZX") and the pauses. No turbo, no protection: the ROM's LD-BYTES loads everything.

| Block | Kind | Data (+2 on tape) | Loads at | ROM-speed time | Pause after (TZX) |
| ---: | --- | ---: | --- | ---: | ---: |
| 0 | header: Program "MOONPATROL", LINE 20 | 17 | | 5.1 s | 1014 ms |
| 1 | the BASIC loader | 187 | the BASIC area | 2.9 s | 2170 ms |
| 2 | header: Bytes "MOON", start 24824, length 40712 | 17 | | 5.1 s | 1088 ms |
| 3 | the game | 40 712 | `$60F8-$FFFF` | 214.2 s | 5712 ms |

The tape lasts 227.3 s at ROM speed (11 383 frames of the 48K), pauses not included; 237.3 s (11 864 frames) with
the TZX's pauses.

The BASIC (`tools/basic_list.py`, block 1):

```
10 RANDOMIZE USR 32768
20 BORDER 0: INK 7: BRIGHT 1: PAPER 0: CLEAR 24823: PRINT AT 10,8;" MOON PATROL "; AT 12,13;"LOADING": INK 0
30 LOAD "" CODE : CLEAR 49999: GO TO 1
```

Line 20 sets RAMTOP to `$60F7`, just under the code, and prints the title in flashing bright text. Line 30 loads
the code to the header's address, `$60F8`, moves RAMTOP up to `$C34F` (`CLEAR 49999`, inside the loaded image)
and goes to line 1, the first line, 10, which enters the game at `$8000`.
