# The intro's pictures

| File | Block 1 | Shown |
| --- | --- | --- |
| `title.png` | `$8710` | first: the ZYNAPS logo, `RVS.M.STAWICKI` |
| `options.png` | `$A210` | second: the credits, `0.START 1.INF.LIVES 2.K-MOUSE`, with the colour bars running |
| `hewson.png` | `$BD10` | last, kept on the screen while block 2 loads: the Hewson picture |

256 x 192 indexed PNG, 32 colours: index = bright x 16 + (pixel set) x 8 + the colour, so an edit in any paint
program that keeps the palette gives the exact screen back; the colours a cell does not show are in the PNG's text
chunk `zx-hidden` (`tools/res_formats.py`'s docstring). `python3 tools/res_formats.py check` builds each, writes it
back and builds it again. The texts on the pictures: `docs/texts/intro.md`.
