# Fonts

`font.png`: Font `$F5C9-$F8C8`, 768 bytes, characters 32-127, 8 bytes each (top line first, bit 7 the left pixel),
as a mono sheet 16 a row (0 paper, 1 ink, 2 grid; `tx-sheet`). Readers: PrintChar `$E717` / DrawGlyph (the menu, the
hall of fame) and the HUD (PrintDigit `$E62B`, PrintHudGlyph); characters 123-127 are the HUD's icons (lives, water,
keys, hammers, level). The 11 zero bytes after it (FontTail `$F8C9`) stay in the source.
