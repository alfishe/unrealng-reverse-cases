# Graphics

The game's font and sprites.

An object's cells are 9 bytes (attribute, 8 pixel lines) or the single byte `$36` for an empty cell (DrawSprite `$8CFD` skips it), so the cells have no fixed stride and only the object table (`tables/game-objects.csv`) cuts them. `sprites.png` and `sprites.csv` are the kit's cell format (`kit/cells.py`): the PNG has each piece (the cells one object, or several at one address, point at) at a place of its own, palette index 0 paper, 1 ink, 2 no pixel (the empty cells and the gaps); the CSV has a line a piece in byte order (`piece,x,y,width,height,objects,attributes`: its top left cell in the PNG, its size in cells, the object numbers, an attribute a cell row by row, `-` for an empty cell) and a `bytes` line in hex for the 9 bytes after the last object, which no object points at. `tools/res_formats.py build` writes the bytes from the two files alone; the layout comes from the object table at install.

Format: `font.png`: 8 x 8 glyphs, 16 a row, palette index 0 paper, 1 ink, 2 no glyph. `sprites.png`, `sprites.csv`: above.

| File | Entry | Address | Bytes | What |
| --- | --- | --- | --- | --- |
| `font.png` | Font (`src/game/game.ann`) | `$7AF0` | 488 | The font: 8 bytes a character from '!' (the code - $20 from $7AE8; a space draws character $3B) |
| `sprites.png`, `sprites.csv` | Sprites (`src/game/game.ann`) | `$A604` | 5731 | The game's sprites: cells of 9 bytes (attribute, 8 pixel bytes) drawn through GameObjects |
