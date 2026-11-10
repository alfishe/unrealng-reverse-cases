# Graphics

PNG sheets as in sprites/ (tools/res_formats.py).

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `Font.png` | `$E002-$E1E1` | 480 | PrintText `$8AB4` (Font - `$100` + 8 x code), the scroller in Interrupt `$95D0` (Font - 257 + 8 x code + the line) | 60 characters, codes `$20-$5B`, 16 a row. 282 of the 480 bytes read in L1 (the characters no text uses never are) |
| `EdPieces.png` | `$E1E2-$E821` | 1600 | DrawItem `$6E0D` (a piece lying in a room), ProgressScreen `$8F53` (the found pieces at `$4886`) | The picture the 50 ED pieces make: 10 x 5 tiles of 16 x 16, tile row x 10 + column. Piece n (item kind `$81` + n) is the tile at column (n - 1) / 5, row (n - 1) % 5 |
| `HudGraphics.png` | `$8BFD-$8C54` | 88 | DrawHud `$8AE8` (Print8 `$8A79`) | 11 characters of the HUD frame: the top and bottom edges, the left and right edges, the corners, the divider |
| `MenuFrame.png` | `$BC02-$BD01` | 256 | Menu `$8854` (Blit16 `$8A93`) | 8 blocks of 16 x 16: row 1 the top, bottom, left and right edges, row 2 the corners top left, top right, bottom left, bottom right |
| `MenuLogoGraphic.png` | `$8DB2-$8DC1` (+ `$8DC2-$8DD1`) | 32 | MenuLogo `$89E5` | The block of the menu's TUJAD logo, 16 rows of 2 bytes; the lower half (`$8DC2`) is also drawn alone |
