# Graphics

| File | Address | Bytes | What | Format | Read by |
| --- | --- | --- | --- | --- | --- |
| `glyphs.png` | `$7080` | 320 | the 40 glyphs of the HUD and the texts: 0-9, the ray gun's bolt, a detonator, Rick's head, A-Z, a blank | indexed PNG, 10 glyphs a row, each 8 x 8 inside a 1-pixel grey frame; index 1 ink, 0 paper | the cell drawer in font mode (`$88B1` patches its graphics base to `$7080`), DrawLives `$79C3`, DrawAmmo `$79D1`, DrawDetonators `$79DF`, the score digits |

Glyph n is at `$7080 + 8n`; a text byte b draws glyph b - `$34` (texts/README.md).
