# Spare bytes

Bytes the pieces carry but no instruction reads (none in c1-c4, none in the code): leftovers of the memory each piece
was saved from. They are resources only because the variants differ in them; there is no format, they stay bytes.

| File | Entry | Bytes | What |
| --- | --- | ---: | --- |
| `code-tail.bin` | TwinkleSpare `$6FE0` | 200 | zeros to the end of the code piece's 15th sector (in layout B, 3 bytes later: the last 3 fall past the piece) |
| `graphics-tail.bin` | GraphicsSpare `$ADF9` | 7 | zeros to the end of the graphics piece |
| `basic-tail.bin` | SectorTail `$5DF3` (src/basic) | 72 | after the BASIC program: `oot27" LINE 10`, the end of the SAVE that wrote the file, then number bytes and zeros; most variants have `boot12`, `boot32`, ... here |
