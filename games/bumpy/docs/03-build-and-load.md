# 3. Build and load

What this covers: the medium block by block, the loader, the source build. The recordings it rests on: c1 (power-on,
`LOAD ""` typed, the original tape at ROM speed; [WALKTHROUGH 1](../WALKTHROUGH.md#1-one-recording-from-power-on)).

<!-- Figures this document needs (GUIDE.md 4.2), remove each line when it is in: -->
<!-- - the build (mermaid) -->

## 3.1 The tape block by block

`orig/Bumpy.tap.zip`'s `BUMPY.TAP`, listed by `kit/tapblocks.py list` (the times at ROM speed, pauses not
included). Every block is a standard ROM block: there is no custom loader, no packer and no protection, so there is
no unpack to animate.

| Block | Kind | Name | Length | Loads at | ROM-speed time | What it is |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | header, Program | "BUMPY" | 191 | | 5.1 s | autostart `LINE 10` |
| 1 | data | | 191 | the BASIC area | 3.0 s | the loader (3.2) |
| 2 | header, Bytes | "BUMPY.SCR" | 6912 | (header `$8000`) | 5.1 s | `LOAD "" SCREEN$` ignores the header's address and loads it to `$4000` |
| 3 | data | | 6912 | `$4000-$5AFF` | 36.2 s | the loading screen (the same bytes as the zip's `SCRSHOT/BUMPY.SCR`) |
| 4 | header, Bytes | "BUMPY.CDE" | 38 700 | `$61A8` (25000) | 5.1 s | |
| 5 | data | | 38 700 | `$61A8-$F8D3` | 204.6 s | the whole game: code, data, sprites, the 100 level records |

Total 259.0 s at ROM speed (12 971 frames). In c1 the game's first instruction `$AB7C` runs at frame 13 357
(T-state 19 678 of the frame), after typing `LOAD ""` and the pauses between the blocks.

## 3.2 The loader

The BASIC is one line (`tools/basic_list.py`):

```basic
10 POKE 23624,0: POKE 23693,0: POKE 23607,128: CLEAR 24999: LOAD "" SCREEN$: PRINT: BRIGHT 1: OVER 1: PAPER 5:
   LOAD "" CODE 25000: POKE 23607,60: POKE 23685,0: RANDOMIZE USR 43900
```

Between `PAPER 5:` and `LOAD` the line holds the bytes `$0A $00`, which the listing shows as `{10}{00}`.

- `POKE 23624,0` (BORDCR) and `POKE 23693,0` (ATTR-P) make the border and the text black.
- `POKE 23607,128` sets the high byte of CHARS to `$80`, so the ROM's "Bytes:" messages print from a font at
  `$8100`, which holds zeros at that time: the tape messages do not show. `POKE 23607,60` puts the ROM font back.
- `CLEAR 24999` puts RAMTOP at `$61A7`: the machine stack sits just below the game, and `USR` enters with SP
  `$6190` (SkoolKit `tap2sna.py -s 43900`, `work/stage1/images/entry.z80`).
- `POKE 23685,0` (SCR-CT) stops the "scroll?" prompt.

The code is entered at `$AB7C` (`DI`) with the image exactly as `LD-BYTES` left it: the entry image's
`$61A8-$F8D3` equals block 5 byte for byte (`work/stage1/images/code.bin` against `entry.z80`), so the game has no
unpacking or relocation stage. What changes between the entry and play: [doc 2, 2.2](02-architecture.md#22-the-images).

## 3.3 The source build

Not written yet (stage 4).
