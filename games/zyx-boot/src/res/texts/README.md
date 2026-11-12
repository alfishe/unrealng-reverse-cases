# Texts

UTF-8 text, written and read by `tools/res_text.py`. The bytes are what the ROM's RST `$10` prints with the menu's
font: the controls are written in braces, `{AT y,x}`, `{INK n}`, `{PAPER n}`, `{BRIGHT n}`, `{END}` (the `$FF` that
ends a string for PrintString), and any other byte below `$20` or above `$7F` as `{$XX}`.

| File | Entry | Bytes | Printed by | What |
| --- | --- | ---: | --- | --- |
| `menu-help.txt` | MenuHelp `$6AFD` | 68 | DrawScreen `$6510` (rows 19-21, covered by DrawReflection later) | SPACE  TO NEW DISK, "SS" TO NEXT PAGES, "CS" TO FIRST PAGE |
| `no-files.txt` | NoFilesText `$6B41` | 18 | ListCatalogue `$65C7` when the page lists no file | NO EXE FILES ! at row 11, column 9 |
| `player-text.txt` | PlayerText `$C014` (src/music) | 63 | nothing: the ASC compiler's credit inside the player, never printed | ASM COMPILATION OF DISCO MUSIC BY ANT P BY ANDREW SENDETSKI ASC |

Of the 48 variants with the original loader, 15 change the help lines and 7 the NO EXE FILES ! text (variants/README.md).
