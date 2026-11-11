# Texts

UTF-8, one quoted string a line (tools/res_formats.py): printable ASCII as itself, `\xNN` any other byte, `\"` and
`\\` escaped; `#` lines are comments. The build joins the strings; inner labels (MenuRedefineText, WinText2, ...)
fall on string boundaries.

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `scroller.txt` | `$6D42-$6EF3` | 434 | RunScroller `$8AEB` (its end `ScrollerText+434`) | the menu scroller: 433 characters and a 0 end mark |
| `cave-names.txt` | `$9700-$997F` | 640 | CaveIntro `$92D4` (`CaveNames-20`), FindPassword `$8E91` | the 32 cave names of 20 characters, space padded: the passwords |
| `password-prompt.txt` | `$9AE8-$9B07` | 32 | ShowPasswordPrompt `$8DFF`, EnterPassword `$8E2D`, EnterName `$7F00` | "ENTER PASSWORD (ENTER=LEVEL ONE)" |
| `key-prompts.txt` | `$A978-$A9D6` | 95 | RedefineKeys `$8C30` | the five prompts, 19 characters each |
| `game-over.txt` | `$AA4E-$AA71` | 36 | ShowGameOver `$8B7F` | "GAME OVER", "YOU SCORED", "AND REACHED LEVEL" |
| `menu.txt` | `$AB00-$AB69` | 106 | ShowMenuTexts `$8A3C` | START GAME, REDEFINE KEYS, the 1988 DEMO MODE line (no longer printed: ControlTexts takes its place), QUIT GAME, the copyright |
| `win.txt` | `$AB6A-$AC2D` | 196 | ShowWinTexts `$A815` | the win screen's lines |
| `credits.txt` | `$AC2E-$AC5E` | 49 | none | Credits: the 1988 credit line, never printed (a leftover kept as text) |
| `hud-labels.txt` | `$BB00-$BB15` | 22 | ShowLevelLivesScore `$89A7` | "LEVEL", "LIVES LEFT:", "SCORE:" |
| `hud-line.txt` | `$BCE0-$BCFF` | 32 | ShowHudLine `$836A` | the bottom line; `a`-`e` are the font's HUD icons (IconGlyphs `$BF08`) |
| `control.txt` | `$EC95-$ECC4` | 48 | ShowControlTexts `$ECC5` | "3 ..... KEYBOARD CONTROL", "4 ..... JOYSTICK CONTROL" (the 1990 control choice) |
