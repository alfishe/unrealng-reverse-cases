# Graphics

PNG sheets (`res_formats.py`: one pixel a bit, palette 0 paper / 1 ink / 2 grid; the `ce-sheet` text chunk holds the
shape). Glyph = sheet start + 8 x code, top row first (PrintChar `$9C40` copies the eight bytes down the cell).

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `CharacterSet.png` | `$84F0-$89DF` | 1264 | PrintChar `$9C40` (33 112 calls), DrawSprite `$9A4C` and DrawHen `$929C` (the background cells under a sprite) | codes 0-`$9D`: 0-5 the map cells (empty, ladder left / right, egg, grain, brick), `$0B-$1D` the HUD labels, `$20-$7F` the font (`$41-$5A` thin capitals, `$61-$7A` bold capitals, no lower case; `$7E` (R), `$7F` (C)), `$80-$8E` the blocks of the big CHUCKIE EGG, `$8F-$96` the A+F logo, `$97-$9A` SPACE, CAPS SHIFT, SYMBOL SHIFT, ENTER, `$9B-$9D` LEVEL |
| `HudCharacters.png` | `$89E0-$8B4F` | 368 | PrintChar `$9C40` (L1: 477 reads of `$8AB0-$8B4E`, 1596 of `$8AA0-$8AAE`), CountDown `$A1B8` (HudCharacters + 8 x digit) | codes `$9E-$CB`: `$9E-$A7` digits 0-9, `$A8-$B5` the duck's cage, `$B6` the life icon, `$B7` the name entry's cursor, `$B8-$CB` the small "A&F SOFTWARE" lettering; the digits are 7 rows under a blank top line, not larger than the font's `$30-$39` |
