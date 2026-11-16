# texts

| File | Address | Size | Readers |
| --- | --- | --- | --- |
| `hiscore.txt` | HiScoreTitle `$695F` | 11 | "HI SCORE", then "A" (BigChar `$6968`: the trail intro's digit and the name entry's letter are written over it) |
| `hinames.txt` | HiNames `$696A` | 30 | the high score table's five names (six characters each), NameEntry writes them |
| `hiscores.txt` | HiScores `$6988` | 30 | the five scores (CheckHiScore, HiCompare) |
| `menu.txt` | MenuTexts `$70AA` | 354 | the menus' strings and the credits; each starts with two bytes InitTextWidths fills (its centring and width, 0 in the image), `]` moves to x `$78` (the key column), `\xFF` ends the block |
| `trails.txt` | TrailTexts `$79E6` | 88 | "TRAIL NO.", the dots, then the six trail names of 11 characters each (CopyTrailName copies one into TrailNameSlot `$79F0`) |
| `game.txt` | GameTexts `$EC4E` | 49 | "TIME OUT", "OUT OF FUEL", "EXTENDED PLAY", "LAP TIME" with the blanks the lap time is written into |

UTF-8, one string a line. A line ending in `|` is a string with the game's end mark (Print stops at `|`); a quoted
line is bytes with no end mark (the fixed-width trail names); `\xNN` is a byte that is no printable character.
The glyphs are game sprites (see `../sprites/README.md`, the font): only `A`-`Z`, `0`-`9`, `a`-`j`, space, `!`, `"`,
`.` and `]` print.
