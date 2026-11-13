# graphics

| File | Address | Size | Format | Read by |
| --- | --- | --- | --- | --- |
| font.png | `$D200` | 768 | 1-bit glyphs, characters 32-127 (glyph = `$D200` + 8 x (code - 32)) | PrintChar and every text: the menu, the panel, the hall of fame, the scroller |
| beam-glyphs.png | `$D500` | 312 | 1-bit glyphs, 39 beam pieces (glyph = `$D500` + 8 x n, n from BeamGlyphBytes `$8000`) | BeamPlotGlyph, BeamOutPlot, BeamCornerPlot (ORed into the pixel buffer) |
| cells.png | `$D700`, `$DF00` | 1696, 212 | attribute PNG, `chars`: characters `$00-$D3`, 16 a row, each with its colour | DrawMarkedChars `$8A09` (8 bytes from `$D700` + 8 x code, colour `$DF00` + code) |
| level-digits.png | `$88B0` | 88 | 1-bit glyphs, 11: the panel's LEVEL digits 0-9 and P | SetUpLevel `$843C` (`$8454`: LevelDigits + 8 x digit) |
| game-over.png | `$8714` | 192 | 1-bit bitmap, 12 bytes a row: the GAME OVER banner, 96 x 16 | LoseLife `$866A` (columns 10-21 of rows 9-10) |
| cursor.png | `$9A37` | 32 | 1-bit bitmap, 2 bytes a row: the cursor's square, 16 x 16 | DrawCursorSquare `$9A11` |
| name-cursor.png | `$9FE3` | 8 | 1-bit glyph: the name entry's blinking diamond | the name entry (HallOfFame) |
| ending-plug.png | `$AA87` | 32 | 1-bit bitmap, 2 bytes a row: the mains plug, 16 x 16 | the ending (`EndingPlugTopLoop` `$A8E7`) |
| ending-kettle.png | `$AAA7` | 60 | 1-bit bitmap, 3 bytes a row: the kettle, 24 x 20 | the ending (`EndingKettleTopLoop` `$A907`) |
| gremlin.png | `$AAE3` | 128 | 1-bit bitmap, 2 bytes a row: the gremlin's four frames of 16 x 16, one under the other | UpdateGremlins `$AB9F` |

The character codes of each cell come from tables/cell-table.csv (CellTable `$8200`).
