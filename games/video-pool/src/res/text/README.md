# Text

The game's texts as UTF-8 text (`tools/res_formats.py`, sections Text and More text). Five formats:

- **Print records** (every file but `SignatureScript.txt`): one record of PrintText `$9E65` a line, `row column
  $attribute "characters"`; the build writes row, column, attribute, the length (the count of the characters) and
  the characters. Attribute bit 7: double width. Characters: a-z and 0-9 come from the game's font, `©` is byte
  `$7F` (the copyright glyph), any other ASCII from the ROM's font; `\xNN` any other byte, `\"` and `\\` escaped.
  Where the code patches a row or a column (FrameBanner, ScoreBlank, EditorTexts, KeysLine), the file holds the
  value in the image.
- **The pen script** (`SignatureScript.txt`): one pen command a line, `up`, `down`, `dot DX DY`, `move DX DY N`,
  `end` (the file's header comments give the bytes).
- **A string** (`VideoText.txt`): the characters as one quoted string, escapes as above.
- **The name-entry grid** (`CharacterGrid.txt`): one row of 14 cells a line, quoted; `\x0c` is "rub", `\x0d` "end".
- **The hall of fame** (`HofTable.txt`): one slot a line, `slot SCORE "NAME" pole X Y attr $AT flag X Y moves M`
  (the file's header says what each field is); the 56-byte name bitmap is zero in the image and written by the game.

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `HudTexts.txt` | `$969D-$96E5` | 73 | NewGameScreen, UpBlinkTask `$96E6`, ShotsBlinkTask `$970E` | The HUD: 1up / 2up and their blanks, hi, the power box row, frame, shots |
| `HudLastShot.txt` | `$9740-$9753` | 20 | ShotsBlinkTask `$970E` | The two halves of the "last shot" blink |
| `GameOverTexts.txt` | `$9890-$98B4` | 37 | GAME OVER (`$9857`) | GAME OVER and the losing player, double width |
| `FrameBanner.txt` | `$9B8E-$9BB7` | 42 | ShowFrameBanner, NextTurn (`$9808`) | The FRAME banner and its blank (row and column patched) |
| `PlayerBannerTexts.txt` | `$9C8F-$9CA6` | 24 | PlayerBanner | PLAYER 1 / PLAYER 2 |
| `FoulTexts.txt` | `$9CFD-$9D2B` | 47 | MessagesTask `$9CB7` | The three foul messages |
| `ScoreBlank.txt` | `$AA6A-$AA73` | 10 | BlankScore | Six spaces over a hall of fame score (row and column patched) |
| `HofTitle.txt` | `$AD4F-$AE91` | 323 | NameEntryPage | The "congratulations" page |
| `PromptLeft.txt` | `$B407-$B463` | 93 | RedefinePrompt | The three "select key for ..." prompts |
| `MenuTitle.txt` | `$B484-$B604` | 385 | MainMenu | The main menu and the variation line |
| `KeysLine.txt` | `$B65F-$B67D` | 31 | ShowKeys (writes the key names), PrintText | The key line under the menu |
| `VariationsTitle.txt` | `$B74D-$B89B` | 335 | VariationsPage | The game variations page |
| `PresentsTexts.txt` | `$B936-$B96B` | 54 | PresentsPage `$B8C5` | "presents", its blank, "press any key to continue." |
| `EditorTexts.txt` | `$C54E-$C58C` | 63 | EditorStart, EditorPlay | "- editor -", "play", "reset" and two blanks |
| `SignatureScript.txt` | `$DA80-$DBF9` | 378 | SignatureCommand `$BD23` | The pen script of "written by" and "James Hutchby" (312 commands, 557 steps; stage 1's "logo data") |
| `HofTable.txt` | `$AC08-$ACDC` | 213 | CountBeaten `$A7EB`, InsertEntry `$A817`, ShowHallOfFame `$A8FD`, the slide routines (written back by them and RenderName) | The hall of fame as the game starts: james 300 (centre), francis 200 (left), bill 100 (right), shown x 10 |
| `CharacterGrid.txt` | `$B167-$B190` | 42 | DrawCharacterGrid `$B0C7`, PickCell `$AF4E` | The name-entry grid: a-n; o-z, space, "."; 0-9, rub, end |
| `VideoText.txt` | `$BD04-$BD08` | 5 | VideoSlideIn `$BC9E` | "video", the letters that slide in above the banner |
