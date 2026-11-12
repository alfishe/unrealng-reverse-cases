# Texts

The game's strings as print records. Each file starts with the format in its comment lines:

- `text Y X S1 S2`, then one quoted line a text line: a record of PrintString `$837B` (or PrintStringTall `$836E`,
  double height). The fields are Y and X in pixels / 2, two style bytes, the characters in the font (graphics/font.png,
  codes `$20-$86`), `$FF` for a new line and 0 to end.
- `picture Y X`, then one line of hex glyph numbers a row (`-` for an empty row): a record of PrintGlyphs `$61E5` or
  PrintStoryString `$D863`, whose glyph n is glyph n of graphics/intro-glyphs or story-font.
- `raw "..."`: bytes that are not a record.
- In quotes, printable ASCII stands for itself and `\xNN` is any other byte. A byte below `$20` inside a text is a
  skip or control code of PrintString (`\x07` skips 7 cells, for example).

Every file must keep its size.

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `intro.txt` | IntroScript `$5E4D-$61E4` | 920 | Intro48 `$5D4F` (IntroPicture `$5DE6`, IntroPrint `$5DF1`) | the 48K intro: the eyes, the Fireblade, Havok, and the 7 texts, in the order they are shown. At run time the bytes from `$5FC0` on are under the page tails' code (SetTune ...). |
| `story.txt` | StoryEyesClosed `$D4CB` - StoryText6 (to `$D862`, bank 4) | 920 | StoryPages `$D3D0` (PrintStoryPicture `$D464`, PrintStoryText `$D46F`) | the 128K story pages: the same 920 bytes as IntroScript |
| `control-menu.txt` | ControlMenuText `$6ACB-$6B09` | 63 | ControlMenu `$6A7B` (PrintStringTall `$836E`) | 1.JOYSTICK 1 ... 4.PROTEK OR CURSOR |
| `panel.txt` | ScoreLineInit `$5C15`, StatusLineInit `$5C25` (to `$5C37`) | 35 | NewGame `$5C4D` copies them, with GlobalsInit, to ScoreLine `$6657` and StatusLine `$6667`; the panel prints those | the score line (digits, a skip, the lives) and the status line (EXTRA, the weapon bar, BONUS) |
| `hiscore-texts.txt` | CursorEraseText `$80EB`, HiScoreHeading `$80FB`, HiScoreRankText `$810F` (to `$8118`) | 46 | MoveNameBox `$A8E2` (CursorEraseText), ShowHighScores `$A6EC` (the heading and the rank) | the name cursor's eraser, "RANK SCORE NAME", "NO." and the rank digits |
| `hiscores.txt` | HiScoreTableHead `$8119`, HiScoreEntries `$811D` (to `$81EF`) | 215 | ShowHighScores `$A6EC` (PrintStringTall `$836E`), InsertHighScore `$A806`, NewGame `$5C4D` (the cheat name check) | the high-score table: 10 entries of 8 digits, `\x04` (skip 4), 10 letters, two lines down |
| `copyright.txt` | CopyrightText `$81F0-$8213` | 36 | ShowHighScores `$A6EC` (below the table); MatchCheatName `$5C68` reaches SpareName as `CopyrightText+$23` (+1) | "COPYRIGHT GREMLIN GRAPHICS 1990" |
| `sloppy.txt` | SpareName `$8214-$821D` | 10 | MatchCheatName `$5C68`, InsertHighScore `$A806` | "SLOPPY    ": the 11th name; a high-score name SLOPPY is the cheat (keys 1-4 choose the start room) |
| `strings.txt` | MusicIconText `$821E` - EndText (to `$8319`) | 252 | the 128K glue (src/boot, the icons), InsertHighScore `$A806` and EnterName `$A861` (the name entry), PanelFragments `$FF3C` (FirebladePanelText), HavokFade `$872B` (EndText) | the music and effects icons, "WELL DONE! YOU HAVE A HIGH SCORE", the letter grid, the name cursor, the name, the Fireblade's panel picture, "THE DAWN HAS COME ..." |
| `tape-error.txt` | TapeErrorText `$FFD8` (the BASIC loader) | 20 | the loader's `RST $10` | "TAPE LOADING ERROR" between two ENTERs |

The high-score page's strings `$80EB-$817A` are moved away while Hiro is in room 123 (HavokRoomEnter), so the
Havok room can use the space.
