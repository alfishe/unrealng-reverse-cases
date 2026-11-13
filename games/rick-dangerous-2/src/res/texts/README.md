# Texts

UTF-8, one string a line. In the game's font a character is drawn as glyph (code - `$34`): letters are plain ASCII,
space is `$20`, and a digit d is stored as d + `$34` (the menus' "1" is the byte `$35`, "5"). The files show the
digits as they appear; `tools/res_formats.py` adds the 4 back. A byte with no glyph is written `{XX}` (the end texts'
column and pixel row before each line, the `$60 $00` before the title). Each line ends with the block's `$FF`; a final
empty line is the `$FF` that ends a list of records.

| File | Address | Bytes | What | Read by |
| --- | --- | --- | --- | --- |
| `game-over.txt` | `$7EC8` | 11 | "GAME  OVER" | DropText, PrintText from GameOver `$7E1E` |
| `level-menu.txt` | `$7FC7` | 158 | the level menu: the prompt and the five level names | DropText from LevelMenu |
| `control-menu.txt` | `$8159` | 85 | the control menu: 0 start, 1-4 the methods, the title | DropText from ControlMenu |
| `tape.txt` | `$843A` | 48 | "START TAPE ON SIDE TWO", "STOP TAPE AND PRESS FIRE" | PrintText from LoadLevel |
| `end-congratulations.txt` | `$87A0` | 157 | the CONGRATULATIONS end (level 4 or 5 done without all five levels): `{column}{row}` text records; the "5" of "LEVEL 5" is overwritten with the level by Congratulations `$8754` | ShowEndText |
| `end-fat-guy.txt` | `$883D` | 116 | the Fat Guy's end (all five levels in one game) | ShowEndText from TallyLives |
