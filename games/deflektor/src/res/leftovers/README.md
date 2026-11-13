# leftovers

Bytes inside the game's image that no code reads, kept as they are so the build stays bit for bit (each is a data
entry of src/game/game.ann).

| File | Address | Size | What |
| --- | --- | --- | --- |
| gap-7b00.bin | `$7B00` | 128 | zeros between TitlePicture and PanelPicture |
| spare-d1c0.bin | `$D1C0` | 64 | zeros after LevelData's last slot, below the font |
| beam-glyphs-spare.png | `$D638` | 200 | 25 glyph slots past the last glyph BeamGlyphBytes names: 14 dotted beam drawings (an unused beam style), then zeros |
| cell-graphics-spare.bin | `$DDA0` | 352 | zeros: the graphics of characters `$D4-$FF`, which no cell code names |
| cell-colours-spare.bin | `$DFD4` | 44 | zeros: the colours of characters `$D4-$FF` |
