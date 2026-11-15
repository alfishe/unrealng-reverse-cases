# Fonts

| File | Address | Size | Readers |
| --- | --- | --- | --- |
| `rex1.png` | REX 1 `$60E0` (Font) | 512 | PrintChar `$A2E9`, PrintDigits `$A3C8`, PanelBox `$CE7B`, FontChar `$DEF0` |
| `rex2.png` | REX 2 `$6306` (Font) | 512 | the same routines of part 2 |
| `demo.png` | DEMO `$6338` (Font) | 512 | the same routines of DEMO |

The 64 characters of codes 32-95 (space to underscore), 8 x 8, 16 a row; the printers read code c at Font - 256 +
8 x c. Format: an indexed PNG, 0 paper, 1 ink, 2 the grid between the characters; `tx-sheet` gives the layout. Some
codes are the game's own pictures, not letters: `#` the HUD's bar, `(` `*` `,` ... the box frame of PanelBox, `]`
`\` `^` `_` `@` and `"` `$` `%` `&` `'` the HUD's icon row (texts/README.md).
