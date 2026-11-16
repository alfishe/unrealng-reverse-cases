# texts

UTF-8, one string a line as the code takes it (PrintList and the layouts give the lengths: there is no end
mark); the build joins the lines with nothing. `{XX}` is a byte outside `$20-$7E` or a trailing space.

| File | Entry | Strings |
| --- | --- | --- |
| `menu.txt` | `MenuTexts` `$8C56-$8D48` | title, menu items, player counts, control methods, DEFINE KEYS' names, 8 blanks |
| `credits.txt` | `CreditTexts` `$8D56-$8DAB` | the 4 credit lines |
| `hud.txt` | `HudTexts` `$8DC5-$8DE1` | TOP STAGE SPEED K<> SCORE TIME NAME |
| `lap.txt` | `LapTexts` `$8735-$8754` | TOTAL RECORD PLAYER LAPTIME, the time template |
| `namegrid.txt` | `FrameChars` `$8AB3`, `NameGrid` `$8AC3` | the two frames' 8 pieces, the 3 rows of the name grid |
| `keys.txt` | `Keys` `$831C` | method 0's keys (`{03}` SPACE) |
| `keynames.txt` | `KeyNames` `$8355` | SYM ENT SPC CPS (codes 1-4) |
| `keymap.txt` | `KeyMap` `$8520` | one line per half row, bits 4-0 (`{01}`-`{04}` the codes above) |
| `extended.txt`, `demo.txt` | `ExtendedText` `$A1CC`, `DemoText` `$A8D6` | EXTENDED PLAY, DEMO |

The characters are the game's font (font/README.md): some draw shapes, not their ASCII meaning.
