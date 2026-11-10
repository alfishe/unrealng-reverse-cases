# Tiles

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `TileTables.txt` | `$6EA8-$7160` | 697 | DrawRoomLayout `$6C93` (DrawRoom `$6B22`): TileGraphics - 2 + 2 x tile, TileAttrs - 2 + 2 x tile | TileGraphics (71 words, the 71st never read; tile 49 is 0), TileAttrs (70 words) and the colour blocks `$6FC2-$7160` they point at, shared between tiles. A colour block's first byte with bit 7 is one colour for the whole tile, else one attribute a cell. `$6FC2-$6FC3` and `$715D-$7160` are read by no tile. Format: the file's header |
| `TileData.png` | `$E822-$FDFF` | 5598 | DrawRoomLayout | The tile graphics, tile n in slot n - 1 (10 a row; slot 49 empty: tile 49 has no graphic; slot 71: the block of the 71st TileGraphics word, a graphic no code reads, `$FDDC-$FDFD`). A block is a width in bytes, a height in pixel rows and the rows, top row first (the width and height are the `head` bytes in the text chunk `tujad-sheet`; change them there with the picture). The bytes no block covers are `raw` items: 56 zeros `$F8A6-$F8DD` and 2 bytes `$FDFE-$FDFF`. The blocks are not in tile order: the build keeps the order of the text chunk, so TileTables.txt must point at the new addresses when a block changes size |

tools/fig_roommap.py draws every room from these and rooms/.
