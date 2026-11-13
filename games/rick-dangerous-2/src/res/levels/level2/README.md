# Level 2: the Ice Caverns of Freezia

Level 2's block (side B block 2, 21 760 bytes at `$A800`), cut by src/levels/levels.ann `@piece level2`. The formats are in ../README.md; `tools/res_formats.py` converts them.

| File | Address | Bytes | What | Format |
| --- | --- | --- | --- | --- |
| `level/cell-flags.csv` | `$A800` | 256 | CellFlags: a flag byte per cell (special surface, solid, floor, ladder, ladder top, deadly, front) | cell, one column a bit |
| `level/cells.png` | `$A900`, `$B100` | 2048 + 256 | CellGraphics and CellAttrs: the 256 cells (8 x 8) and their attributes | PNG colour cells, 16 a row |
| `level/blocks.txt` | `$B200` | 4096 | Blocks: 256 blocks of 4 x 4 cells | a block a line, four rows of four cell numbers |
| `level/frame-map.csv` | `$C20E` | 95 | SpriteFrameMap: animation frame -> sprite, mirrored | frame, sprite, mirrored |
| `level/sprites.png` | `$C26D` | 8704 | Sprites: 68 sprites of 24 x 21 (0-26 the same in every level) | PNG sheet, 8 a row; paper, ink, transparent, ink over the mask |
| `level/maps.txt` | `$E46D` | 2176 | Maps: every section's map, 8 blocks a row | a row a line |
| `level/sections.txt` | `$ED6D` | 1646 | SectionTable and the exit and map entry lists it points to | section lines, then exit / object / box lines |
| `level/kinds.txt` | `$F3DB`, `$F437`, `$F575`, `$F7BB` | 92 + 318 + 582 + 399 | KindTable, TrapAnims, TrapPaths, KindRecords | kind lines, script lines, record lines |

Read by: the game (src/game) through LevelHeader `$C200` (KindTable, SectionTable, the maps' base): BuildView `$88D4` (maps, blocks), the cell drawers `$76D4`, `$77B1` (cells), CollisionFlags `$915E` (cell flags), SetupSection `$8A6D` and CheckSectionExit `$8993` (sections, exits), ScanMapObjects `$8B42`, SpawnFromMap `$9C97`, SpawnMapObject `$9D6C` (map entries, kinds), UpdateTrap `$A2F7` and AnimateTrap `$A608` (paths, anims, frame map), the composer `$7329` (sprites).
