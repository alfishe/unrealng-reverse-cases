# Texts

UTF-8, one quoted string a line, `#` lines comments; printable ASCII as itself, `\xNN` any other byte. The PrintText
`$E667` codes: `$16` AT row column, `$01`/`$02` single/double height, `$10` INK, `$11` PAPER, `$12` FLASH, `$13`
BRIGHT, `$14` attribute, `$15` (one parameter), `$09` one column on, `$00` the end.

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `menu.txt` | `$EFEF` | 115 | Menu `$EF33` | the options 0-4 and the credit line |
| `players.txt` | `$F063` | 32 | MenuTogglePlayers | ONE PLAYER / TWO PLAYERS |
| `menu-backdrop.txt` | `$F0E8` | 125 | Menu | the coloured backdrop blocks |
| `hall-of-fame-title.txt` | `$EDEF` | 196 | ShowHallOfFame | the frame and the title |
| `once-upon-a-time.txt` | `$E7CD` | 25 | PrintOnceUponATime `$E7C6` (unrun) | "Erase Una Vez ..." with the CPC LOCATE code `$1F` |
| `editor.txt` | `$E1C9` | 81 | none | the CPC level editor's menu (letters A = 1 ... Z = 26) |
