# Level 5: the Fat Guy's headquarters

Level 5's block (side B block 5, 21 760 bytes at `$A800`), cut by src/levels/levels.ann `@piece level5`. The formats are in ../README.md; `tools/res_formats.py` converts them.

| File | Address | Bytes | What | Format |
| --- | --- | --- | --- | --- |
| `level/cell-flags.csv` | `$A800` | 256 | CellFlags: a flag byte per cell (special surface, solid, floor, ladder, ladder top, deadly, front) | cell, one column a bit |
| `level/cells.png` | `$A900`, `$B100` | 2048 + 256 | CellGraphics and CellAttrs: the 256 cells (8 x 8) and their attributes | PNG colour cells, 16 a row |
| `level/blocks.txt` | `$B200` | 4096 | Blocks: 256 blocks of 4 x 4 cells | a block a line, four rows of four cell numbers |
| `level/frame-map.csv` | `$C20E` | 95 | SpriteFrameMap: animation frame -> sprite, mirrored | frame, sprite, mirrored |
| `level/sprites.png` | `$C26D` | 8576 | Sprites: 67 sprites of 24 x 21 (0-26 the same in every level) | PNG sheet, 8 a row; paper, ink, transparent, ink over the mask |
| `level/maps.txt` | `$E3ED` | 1184 | Maps: every section's map, 8 blocks a row | a row a line |
| `level/sections.txt` | `$ECED` | 1246 | SectionTable and the exit and map entry lists it points to | section lines, then exit / object / box lines |
| `level/kinds.txt` | `$F1CB`, `$F239`, `$F3A3`, `$F630` | 110 + 362 + 653 + 438 | KindTable, TrapAnims, TrapPaths, KindRecords | kind lines, script lines, record lines |
| `level/fat-guy.txt` | `$F83C` | 148 | FatGuyParts, FatGuyPiecePaths, FatGuyPieceAnims: the five parts and their flight after the kill | part lines, path and anim tokens |
| `level/fat-guy-path.txt` | `$FAF4` | 63 | FatGuyPath: the Fat Guy's path while he lives | path tokens |

Read by: the game (src/game) through LevelHeader `$C200` (KindTable, SectionTable, the maps' base): BuildView `$88D4` (maps, blocks), the cell drawers `$76D4`, `$77B1` (cells), CollisionFlags `$915E` (cell flags), SetupSection `$8A6D` and CheckSectionExit `$8993` (sections, exits), ScanMapObjects `$8B42`, SpawnFromMap `$9C97`, SpawnMapObject `$9D6C` (map entries, kinds), UpdateTrap `$A2F7` and AnimateTrap `$A608` (paths, anims, frame map), the composer `$7329` (sprites); FatGuyStart `$F7E6` and FatGuyUpdate `$F8D0` (the Fat Guy).
