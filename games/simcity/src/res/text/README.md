# Texts

UTF-8 text (tools/res_formats.py). The game's texts are ASCII with bit 7 set on the last letter of a string; the
build sets it back. A byte that is not printable ASCII, or `{`, `}`, `"`, is written `{xx}` in hex. Letters are
drawn with the ROM font (PrintGlyph `$F754`).

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `MonthNames.txt` | `$5F8A-$5FAD` | 36 | PrintDate `$5FAE` | The twelve months, three letters each |
| `GameTexts.txt` | `$5FC6-$6304` | 831 | FindText `$6317` from PrintToolName `$6305`, ShowAdvice `$9997`, PrintEvalFigures `$9792` | 50 strings by index: 0-13 the tools with the price the palette shows, 14-16 the levels, 17-22 the city categories, 23 a space, 24-49 the advice and disaster messages (a disaster's message is GameTexts[number + 23]) |

The menus and windows: [menus/](menus/README.md). The texts printed by PrintInline: [inline/](inline/README.md).

No leftovers: FindText reads every string (L1: every byte of GameTexts read).
