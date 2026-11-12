# Graphics

Mono PNG sheets (ink black on white), written and read by `tools/res_gfx.py`. The sheet's layout (cell size, cells a
row) is in the PNG's text chunk `zyx-sheet`, so the converter needs nothing else; the bytes are the cells one after
the other, each cell row by row, left byte first.

| File | Entry | Bytes | Layout | Readers |
| --- | --- | ---: | --- | --- |
| `font.png` | Font `$A600` | 768 | 96 cells of 8 x 8, 16 a row | the ROM's RST `$10` with Chars `$5C36` = `$A500` (DrawScreen `$6510`, PrintString, ListCatalogue) |
| `logo.png` | Logo `$A900` (LogoPart2 `$A9C8`, LogoPart3 `$AA90`, LogoPart4 `$AB58`) | 800 | 4 cells of 40 x 40 (5 bytes a row) | PrintSprite via DrawScreen; FlipSprite via DrawReflection `$6DC6` |
| `rhombus.png` | RombSource `$6E98` | 200 | 1 cell of 40 x 40 | DrawScreen; Start copies it to RombWork for BuildRombPhases `$62F1` |
| `twinkle.png` | TwinkleSprites `$6F60` | 128 | 4 cells of 16 x 16 (2 bytes a row) | DrawTwinkle `$6BFD` |

Of the 48 variants with the original loader, 25 change the rhombus, 18 the logo, 7 the font and 4 the twinkle (variants/README.md).
