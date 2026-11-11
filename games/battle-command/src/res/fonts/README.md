# Fonts

| File | Address | Size | Format | Read by |
| --- | --- | --- | --- | --- |
| font8x8.png | bank 6 Font8x8 `$F5E4-$F8F3` | 784 | 98 glyphs for `$20-$81`, 8 bytes each, top row first; `$80` and `$81` are the road and river patterns of the map legends | PrintChar `$6FF0` (PrintString `$6FB3`), PrintRawString `$C707` (bank 6) |
| small-font.png | bank 2 SmallFont `$7C59-$7D34` | 220 | 44 glyphs `"0"` to `"["`, 5 rows of a byte, stored inverted (ink 0); the 5 pixels are the high bits, the low three always 1. In this font `:` prints a space and `[` a full stop | SmallGlyph `$6DDA`, PrintSmallChar `$6DE8` (control codes 5 and 7) |

The PNG is a sheet of 16 glyphs a row, one 8-pixel cell each (FONT_ROWS in tools/res_formats.py gives each font's
rows); the PNG's text chunks keep what the picture cannot show, so the bytes come back exactly.

Leftover: the 28 bytes after the small font, SmallFontLeftover `$7D35`, are read and written by nothing (an earlier
build's bytes; they stay in src/game as data).
