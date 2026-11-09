# Fonts

The three fonts of the print code, as PNG sheets of 96 glyphs (`$20-$7F`, 16 a row), 8 bytes a glyph, bit 7 leftmost.
The glyph address is the font base + 8 x code (bases `$F000`, `$F300`, `$F600`: the glyphs start at code `$20`); only
the first rows are drawn (FontDescriptors `$F096`: widths, line step, rows). The code `$1A n` of a print string
selects font n; font 3 is the ROM's at `$3C00`, selected by no recording. The character set is the Spectrum's
(`$5E` up arrow, `$60` pound, `$7F` copyright).

| File | Address | Bytes | Format | Readers | What |
| --- | --- | ---: | --- | --- | --- |
| `FontSmall.png` | `$F100-$F3FF` | 768 | 8 bytes a glyph, `$20-$7F` | PrintChar `$FDCC` (FontDescriptors `$F096`, the code `$1A`) | Font 0: glyphs for `$20`-`$7F`, 8 bytes each, 5 rows used |
| `FontBold.png` | `$F400-$F6FF` | 768 | 8 bytes a glyph, `$20-$7F` | PrintChar `$FDCC` (FontDescriptors `$F096`, the code `$1A`) | Font 1, the thick title font: glyphs `$20`-`$7F`, 6 rows used |
| `FontPlain.png` | `$F700-$F9FF` | 768 | 8 bytes a glyph, `$20-$7F` | PrintChar `$FDCC` (FontDescriptors `$F096`, the code `$1A`) | Font 2: glyphs `$20`-`$7F`, 6 rows used, printed without colours |
