# 2. Architecture

What this covers: the machine budget, the memory map (a figure), stages from the medium to play, the frame, the main loop's call graph, the module map. The recordings it rests on: `c1` and its game window `c1g` (power-on, the 10 Mega Games copy of the tape at ROM timing), the 60 RZX segments `rzx-NNNNNN` and the own recordings of [WALKTHROUGH 6.0](../WALKTHROUGH.md#60-the-recordings).

<!-- Figures this document needs (GUIDE.md 4.2), remove each line when it is in: -->
<!-- - the stages from power-on to play (mermaid) -->

## 2.1 The memory map

The 48K's 64 K as the game uses it from its entry `$8382` (stage 1, a first map: each line with what shows it; the
L1 counts are from all recordings, [2.2](#22-the-heatmap-and-the-stack)).

| Range | What | Witness |
| --- | --- | --- |
| `$0000-$3FFF` | ROM: the font at `$3D00` for the loader only; the game runs no ROM code | the loader `$B672`; L1 of all recordings: no instruction below `$8382` runs (2.2) |
| `$4000-$5AFF` | the screen: the play area 240 x 144 from (8, 8), the panel below (LEVEL, LIVES, OVERLOAD, ENERGY, SCORE, HIGH, COMPUTER) | screenshots ([WALKTHROUGH 6.1](../WALKTHROUGH.md#61-screens-and-levels)) |
| `$5B00-$5FFF` | the loader's leftovers (`$5B00` `POP HL; JP (HL)`, `$5C00` the block head); never read or written by the game (2.2) | [doc 3, 3.1](03-build-and-load.md#31-the-tape-block-by-block) |
| `$6000-$7AFF` | the title picture (6912 bytes, a screen); read only | draft map of `c1g`; the title screen; L1: read, never written |
| `$7B80-$7FFF` | the options panel's picture | draft map of `c1g` |
| `$80F8-$81FB` | small tables (pointers used by `$94FD` and `$9278`, records used by `$854A` and `$A8C0`) | draft map of `c1g` |
| `$81FD`, `$81FF` | the control method (0 keyboard, 1 Sinclair, 2 Kempston, 3 Protek), the level (0-59, 60 = the ending) | `$9869`; RZX watch |
| `$8200-$8373` | the cell table: four character codes for each of the cell codes `$00-$5C` | `$8960`; [the tile sheet](img/sprites/tiles.png) |
| `$8374-$8381` | the game's variables: `$8379`, `$837A`, `$837D` lives, `$837F` frame counter, `$8380` | draft map; `$8408` |
| `$8382-$AFFF` | the code (entry `$8382`, the main loop `$843C` / `$854A`, the level draw `$891A`, the keys `$97F0`, the menu `$9BC0`, the IM 2 handler `$A32A`) with its texts and tables: the per-level table `$8385` (2 bytes a level), the LEVEL digits `$88B0`, "INTERMISSION" `$972C`, the menu and hall of fame `$9F4C-$A051`, the COMPUTER messages `$A113-$A2C3`, the ending's text `$A987-$AA71` | `c1g` L1 and draft map |
| `$B000-$D1BF` | the levels: 64 slots of 135 bytes (15 x 9 cells), 60 levels, the practice level in slot `$3C` | `$891A`; [the level maps](img/maps/all.png) |
| `$C1BE-$D1BF` | inside the level area: bytes that disassemble as code (the draft map's "code that never ran") are the later levels | `tools/level_maps.py` draws them as levels |
| `$D200-$D4B7` | the text font (characters 32-118 of a set based at `$D100`) | `$8E3A`, the draft map |
| `$D508-$D5B7` | small graphics used by `$9278`, `$9440`, `$94FD` | draft map |
| `$D700-$DEFF` | the cell characters: 8 bytes each (`$D700 + 8 x code`) | `$8A09` |
| `$DF00-$DFFF` | the cell characters' colours (`$DF00 + code`) | `$8A09` |
| `$E000-$E27F` | the character map of the play area (20 rows of 32) | `$8960` |
| `$E300-$E57F` | the "to draw" marks, one a character | `$8A09` |
| `$E600-$E87F` | the play area's colours (20 rows of 32), copied to `$5800` by `$8C75` | `$8A09`, draft map |
| `$E900-$FCFF` | the play area's pixels (160 rows of 32 bytes), copied to the screen by `$8C10` | `$8A09`, draft map |
| `$FD00-$FDFA` | the level grid (`$FD23`, 17 bytes a row); before the game, the mover of stage 8 | `$891A`; [doc 3, 3.1](03-build-and-load.md#31-the-tape-block-by-block) |
| `$FDFD-$FDFF` | `JP $A32A`, the IM 2 handler's entry | `$A2FA` |
| `$FE00-$FF00` | the IM 2 table, 257 bytes of `$FD` | `$A311` |
| `$FF01-$FFFF` | the stack (`SP` = `$FFFF` from `$FD0F`); its low mark is `$FFF3` | 2.2 |


## 2.2 The heatmap and the stack

![Executions, reads and writes of `$4000-$FFFF` summed over all recordings](img/arch/heatmap.png)

The L1s of 68 recordings summed (`tools/l1_merge.py` into `work/stage1/all-l1.json`, drawn by `kit/heatmap.py` with
`work/stage1/regions.txt`): `c1g`, `menu`, `controls`, `kempston`, `energy`, `overload`, `mine`, `gameover` and the
60 RZX segments, 395 379 frames, 4371 distinct instructions. What they show:

- Code runs only in `$8382-$AFFF` and at `$FDFD` (the IM 2 jump): no ROM routine, nothing in `$5B00-$7FFF` or the
  level area.
- `$5B00-$5FFF` is never read or written after the entry; `$6000-$7FFF` (the title and the options panel pictures) is
  read only; the levels `$B000-$D1BF` are read only.
- Inside `$8382-$AFFF`, 376 bytes are written: the variables between the routines and the operand `$A63C` (WALKTHROUGH
  3).
- The heaviest writes are the play-area buffers `$E000-$FCFF` and the screen; `$FD00-$FDFF` (the grid) and
  `$FE00-$FF00` (the IM 2 table, written once) follow.
- **The stack's low mark is `$FFF3`**: the lowest byte written in `$FF01-$FFFF` over all recordings, 12 bytes under
  `SP` = `$FFFF` (`$FD0F`), so the stack never comes near the IM 2 table at `$FF00`.

## 2.3 The levels

![The 60 levels and the practice level, drawn from the data by the game's own `$891A`](img/maps/all.png)

Each level is 135 bytes at `$B000 + $87 x level` (15 x 9 cells, a byte a cell, row by row); `$891A` copies it to the
grid `$FD23` (17 bytes a row) and `$8960` draws each cell as four characters of the table `$8200`
([the tile sheet](img/sprites/tiles.png)). The picture is `tools/level_maps.py`: SkoolKit's simulator runs `$891A`
for each slot over the entry image and draws the play-area buffers. In reading order: levels 1-60 (`$B000`,
`$B087`, ... `$CF1D`) and the practice level, slot `$3C` at `$CFA4`. One picture a level is in `img/maps/level-NN.png`
(61 the practice level): [1](img/maps/level-01.png) · [2](img/maps/level-02.png) · [3](img/maps/level-03.png) · [4](img/maps/level-04.png) · [5](img/maps/level-05.png) · [6](img/maps/level-06.png) · [7](img/maps/level-07.png) · [8](img/maps/level-08.png) · [9](img/maps/level-09.png) · [10](img/maps/level-10.png) · [11](img/maps/level-11.png) · [12](img/maps/level-12.png) · [13](img/maps/level-13.png) · [14](img/maps/level-14.png) · [15](img/maps/level-15.png) · [16](img/maps/level-16.png) · [17](img/maps/level-17.png) · [18](img/maps/level-18.png) · [19](img/maps/level-19.png) · [20](img/maps/level-20.png) · [21](img/maps/level-21.png) · [22](img/maps/level-22.png) · [23](img/maps/level-23.png) · [24](img/maps/level-24.png) · [25](img/maps/level-25.png) · [26](img/maps/level-26.png) · [27](img/maps/level-27.png) · [28](img/maps/level-28.png) · [29](img/maps/level-29.png) · [30](img/maps/level-30.png) · [31](img/maps/level-31.png) · [32](img/maps/level-32.png) · [33](img/maps/level-33.png) · [34](img/maps/level-34.png) · [35](img/maps/level-35.png) · [36](img/maps/level-36.png) · [37](img/maps/level-37.png) · [38](img/maps/level-38.png) · [39](img/maps/level-39.png) · [40](img/maps/level-40.png) · [41](img/maps/level-41.png) · [42](img/maps/level-42.png) · [43](img/maps/level-43.png) · [44](img/maps/level-44.png) · [45](img/maps/level-45.png) · [46](img/maps/level-46.png) · [47](img/maps/level-47.png) · [48](img/maps/level-48.png) · [49](img/maps/level-49.png) · [50](img/maps/level-50.png) · [51](img/maps/level-51.png) · [52](img/maps/level-52.png) · [53](img/maps/level-53.png) · [54](img/maps/level-54.png) · [55](img/maps/level-55.png) · [56](img/maps/level-56.png) · [57](img/maps/level-57.png) · [58](img/maps/level-58.png) · [59](img/maps/level-59.png) · [60](img/maps/level-60.png) · [61](img/maps/level-61.png);
and each level's address and bytes in `img/maps/levels.json`. Elements drawn in play are not in it: the beam, the
cursor, and the turning elements are shown at their first angle.
