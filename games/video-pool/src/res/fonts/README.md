# Fonts

The game's own font as an indexed PNG sheet (the same sheet format as `../graphics/README.md`).

| File | Address | Bytes | Format | Readers | What |
| --- | --- | ---: | --- | --- | --- |
| `Font.png` | `$DEF4-$E013` | 288 | PNG sheet, 36 glyphs of 8 x 8, 12 a row | PrintChar `$9E7C`, the hall of fame's name printers (`$AB04`, `$B118`) | a-z (codes `$61-$7A`), then 0-9 (codes `$30-$39`, FontDigits `$DFC4`); every other code is the ROM's CHAR_SET `$3D00`, `$7F` the copyright glyph `$9F2E` (in the code, not a resource) |
