# Graphics: the char sets and the font

`tools/res_gfx.py` (a format module of `tools/res_formats.py`) turns each PNG into the bytes the game source INCBINs
and back; `tools/res_formats.py check` proves the round trip.

| File | Resources | Address | Entry | What |
| --- | --- | --- | --- | --- |
| `charset0.png` | `graphics/charset0.bin`, `graphics/charattr0.bin` | `$7100-$78FF`, `$7900-$79FF` | CharSet0, CharAttr0 | char set 0 (levels 1-2): 256 chars and their attributes |
| `charset1.png` | `graphics/charset1.bin`, `graphics/charattr1.bin` | `$7A00-$81FF`, `$8200-$82FF` | CharSet1, CharAttr1 | char set 1 (levels 3-4) |
| `font.png` | `graphics/font.bin` | `$9E95-$9FEC` | Font | 43 glyphs: 0-9, A-Z, three pictures, comma, full stop, question mark, space |

## The char sets

Char C's 8 lines are at the set + 8C, top line first, and its attribute at the attribute page + C. A zone's byte +0
chooses the set (EnterZone `$AC83` patches the page `$79` or `$82` into `$A853` and `$AA80`); the map (`$6500` on)
holds the char codes; the redraw `$A834` copies a char's lines and attribute to the screen; `$F6A9` builds the
chars' properties (walls, ladders, deadly cells) for the set from run-length tables at `$F6C0` / `$F6D0`.
The attribute of char 0 (`$7900`, the empty space) is rewritten at run time with the level's colour (LevelIntro
`$E320`, `$AC14`): the file holds the loaded value.

**The PNG.** 16 x 16 cells of 8 x 8 pixels, char 0 top left, row by row, a one-pixel grid (palette index 16) round
every cell. The palette's first 16 entries are the Spectrum's colours (0-7, then 8-15 BRIGHT); each pixel is the index
of its cell's INK (a set bit) or PAPER. The attributes are the PNG's text chunk `attributes`: 16 lines of 16 bytes in
hex, a line a row of cells. To recolour a char, change its byte there and paint the cell with its new INK and PAPER
indices; a pixel of any other index is refused. A cell whose INK and PAPER are the same keeps its bits in the text
chunk `bits` (`cell:hex`); char set 0 and 1 have none that differ from 0.

## The font

One row of 43 cells, black INK on white PAPER (the attributes in the text chunk are all `$38`; the build refuses
others). Glyph G is at `$9E95` + 8G. The printers read it: `$A977` (digits as numbers), `$A9E8`, `$AA0E` / `$AA25`
(glyph numbers) and `$AA8D` / `$AA9F` (ASCII: code - `$37`). Glyphs 36-38 are pictures for the HUD's counters (a
bullet, a stick of dynamite, a face); 39-42 comma, full stop, question mark, space.
