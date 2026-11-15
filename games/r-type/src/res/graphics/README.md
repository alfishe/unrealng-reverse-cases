# Graphics

The game's font and sprites.

The sprites stay bytes: an object's cells are 9 bytes (attribute, 8 pixel lines) or the single byte `$36` for an empty cell (DrawSprite `$8CFD` skips it), so the cells have no fixed stride and only the object table (`tables/game-objects.csv`) cuts them; `python3 tools/objsheet.py` draws a level's objects the same way. A PNG form needs the table and the bytes between objects together (NOTES, "For the lead (kit)").

Format: `font.png`: 8 x 8 glyphs, 16 a row, palette index 0 paper, 1 ink, 2 no glyph. `sprites.bin`: bytes (see below).

| File | Entry | Address | Bytes | What |
| --- | --- | --- | --- | --- |
| `font.png` | Font (`src/game/game.ann`) | `$7AF0` | 488 | The font: 8 bytes a character from '!' (the code - $20 from $7AE8; a space draws character $3B) |
| `sprites.bin` (bytes) | Sprites (`src/game/game.ann`) | `$A604` | 5731 | The game's sprites: cells of 9 bytes (attribute, 8 pixel bytes) drawn through GameObjects |
