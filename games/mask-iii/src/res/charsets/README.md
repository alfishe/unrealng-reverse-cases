# Zone character sets

PNG: 1-bit, 16 characters a row, character n at row n / 16, column n % 16, 8 x 8 pixels top line first (8 bytes a
character). CSV: the 256 attributes, 16 a row, hex (bit 7 = solid for IsSolid `$B993`, bits 0-6 the colours).

| File | Entry | What |
| --- | --- | --- |
| `zone0.png`, `zone0-attr.csv` | ZoneChars `$E000`, ZoneAttrs `$EF00` | zone 0 (the surface, rooms 0-3), live as loaded |
| `zone1-low.png`, `zone1-high.png`, `zone1-attr.csv` | Zone1CharsLow `$F000` (characters 0-159), Zone1CharsHigh `$6000` (160-255), Zone1Attrs `$EE00` | zone 1 (the caverns, rooms 4-6), put together at `$5B00` by GameEntry |
| `zone2.png`, `zone2-attr.csv` | Zone2Chars `$6400`, Zone2Attrs `$6C00` | zone 2 (the moon, rooms 7-9) |
| `zone3.png`, `zone3-attr.csv` | Zone3Chars `$6D00`, Zone3Attrs `$7500` | zone 3 (the base, rooms 10-15) |
