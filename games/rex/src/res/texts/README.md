# Texts

| File | Address | Size | Readers |
| --- | --- | --- | --- |
| `rex1-game.txt` | REX 1 `$AAAE` GameTexts | 303 | PrintText `$A307`: PHASE ONE, GAME OVER, the HUD figures, the bonus and weapon panels |
| `rex1-menu.txt` | REX 1 `$DF05` MenuTexts | 262 | TitleMenu `$DAC0`, DefineKeys `$DD54` |
| `rex1-roll-call.txt` | REX 1 `$DC26` RollCallTexts | 302 | RollCallText `$DB71` |
| `rex1-hud.txt` | REX 1 `$A24C` HudTexts | 62 | DrawHud |
| `rex1-code.txt` | REX 1 `$A884` CodeText | 25 | CodePanel `$A7CE` (writes the 16 digits into it) |
| `rex2-game.txt` | REX 2 `$AAF7` GameTexts | 411 | PHASE TWO, GAME OVER, BIO GROWTHS KILLED, the ending, the panels |
| `rex2-menu.txt` | REX 2 `$DFC6` MenuTexts | 257 | TitleMenu, DefineKeys |
| `rex2-hud.txt` | REX 2 `$A3F4` HudTexts | 62 | DrawHud |
| `rex2-code.txt` | REX 2 `$DCA7` CodeTexts | 120 | EnterCode `$DB27`: INVALID CODE, TRY AGAIN, INPUT YOUR CODE |
| `demo-hud.txt` | DEMO `$9D41` HudTexts | 62 | DrawHud |
| `demo-bonus.txt` | DEMO `$A3D2` BonusTexts | 95 | BonusRoulette |
| `demo-tutor.txt` | DEMO `$A431` TutorTexts | 2133 | TutorPanel, the credits (TutorCredits `$AC42`) |

UTF-8 text, one record a line: `$AT COL $LINE "TEXT"`, the bytes [attribute][column][line in pixels] text, 0
(PrintText). The text is the font's codes 32-95 as themselves (upper case, digits, `:` and `.` among them), `\"` and
`\\` escaped; `#`, `]`, `\`, `^`, `_`, `@` and the like print the game's own pictures (fonts/README.md). Anything that
is no such record (a `$FF` end, the zeros of DefineTaken, the weapon panels' leading flag byte) is a `bytes` line.
`#` lines are comments.
