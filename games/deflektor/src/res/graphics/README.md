# graphics

| File | Address | Size | Format | Read by |
| --- | --- | --- | --- | --- |
| font.png | `$D200` | 768 | 1-bit glyphs, characters 32-127 (glyph = `$D200` + 8 x (code - 32)) | PrintChar and every text: the menu, the panel, the hall of fame, the scroller |
| beam-glyphs.png | `$D500` | 312 | 1-bit glyphs, 39 beam pieces (glyph = `$D500` + 8 x n, n from BeamGlyphBytes `$8000`) | BeamPlotGlyph, BeamOutPlot, BeamCornerPlot (ORed into the pixel buffer) |
| cells.png | `$D700`, `$DF00` | 1696, 212 | attribute PNG, `chars`: characters `$00-$D3`, 16 a row, each with its colour | DrawMarkedChars `$8A09` (8 bytes from `$D700` + 8 x code, colour `$DF00` + code) |

The character codes of each cell come from tables/cell-table.csv (CellTable `$8200`).
