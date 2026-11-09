# Resources

Every resource out of the code, in an editable format; `tools/res_formats.py build` turns them back into the bytes
the source INCBINs, `tools/res_formats.py check` proves the round trip (39 editable files).

| File | What | Format | Entry |
| --- | --- | --- | --- |
| `graphics/BallSprites.png` | the 56 pre-shifted ball sprites | PNG sheet | BallSprites `$D000` |
| `graphics/SolidLine.png`, `FlagTail.png` | the hall of fame's flag: its solid line and its ragged tail | PNG sheets | SolidLine `$AAD8`, FlagTail `$AB41` |
| `graphics/PenShaftImage.png` | the signature pen's shaft | PNG sheet | PenShaftImage `$BFFE` |
| `graphics/BannerData.png` | the OCP banner of the presents page | PNG of its rows (run lengths) | BannerData `$BA86` |
| `graphics/FlipLetters.txt` | the edges of the turning letters O, C, P, L | text records | FlipLetterO `$BB98` |
| `graphics/RubLines.txt`, `EndLines.txt`, `PenNib.txt`, `PenCap.txt` | "rub" and "end" of the name grid, the pen's nib and cap | text span lists | RubLines `$B191`, EndLines `$B1DA`, PenNib `$BFCC`, PenCap `$BFEB` |
| `fonts/Font.png` | the font a-z, 0-9 | PNG sheet | Font `$DEF4` |
| `fonts/CopyrightGlyph.png` | the copyright glyph, character `$7F` | PNG sheet | CopyrightGlyph `$9F2E` |
| `racks/RackScripts.txt` | the rack-in scripts: the set table, six sets, 36 scripts | text commands | RackSets `$A0C4` ... `$A701` |
| `tables/*.csv` (4) | the four physics tables | CSV | ContactTable `$DBFA`, Table8x8 `$DCFA`, FrictionTable `$DD3A`, CollisionRecords `$DE3A` |
| `tables/ShotsPerFrame.csv`, `StartPositions.csv`, `KeyTable.csv`, `FlipWidths.csv` | the shots of a frame, the rack, the key matrix, the turning letters' widths | CSV | ShotsPerFrame `$9C06`, StartPositions `$9D5D`, KeyTable `$8254`, FlipWidths16 `$BC74` |
| `text/*.txt` (14) | the print records of every page: 75 records, 1537 bytes | UTF-8 text | HudTexts `$969D` ... EditorTexts `$C54E` |
| `text/SignatureScript.txt` | the pen script of the signature | text commands | SignatureScript `$DA80` |
| `text/HofTable.txt` | the hall of fame as the game starts | text, one slot a line | HofTable `$AC08` |
| `text/CharacterGrid.txt`, `VideoText.txt` | the name-entry grid; "video" | quoted strings | CharacterGrid `$B167`, VideoText `$BD04` |
| `maps/RackSet0.png` ... `RackSet5.png` | the six rack sets drawn as maps | PNG (an output of `tools/fig_objects.py racks`, from `racks/`; not INCBINned) | (none) |

Each folder's README.md lists its files with address, size, format and readers.

## What stays bytes, and why

Every other data entry of `src/game/game.ann` stays in the source, for one of these reasons:

| Reason | Entries |
| --- | --- |
| Work variables: the game writes them, their image bytes are a moment's state | InputState `$827C`, SoundRequest `$827D`, DrawList `$869E`, ContactVars `$89B5`, BallRecords `$8A88` and OtherPlayerBalls `$8AEA` (placed from StartPositions at each rack), FrictionTurn `$8B4C`, EventCount `$8B4D`, FoulCode `$8E80`, TaskSlots `$91DF`, SpritePos `$95D8`, ScoreVars `$9B2A`, PlayerVars `$9F43`, NewEntry1 `$ACDD`, RepeatDelay `$B226`, NameBuffer `$B227`, Players `$B8BB` (the menu's settings), PresentsSP `$BD09`, PenBand `$C03E`, EditorCursorSpeed `$C58D` |
| Pointer tables: routine or record addresses the assembler writes from labels | InputHandlers `$811B`, the task lists AimTasks `$84AA`, MovingTasks `$84BA`, EditorAimTasks `$C518` (period, routine), HofTextList `$AD3D`, MenuTexts `$B464`, VariationTexts `$B731` |
| Code: the ROM calculator's literals, code bytes never run | AimCalcDx `$8A1A`, AimCalcDyOverR `$8A2D`, AimCalcDxOverR `$8A45`, ScaleByPowerCalc `$8A7A` (RST `$28` programs); EditorStaleCopy `$C591`; DevFragment `$E053`, DevParseList `$E0B8` |
| Space and padding | PenShaftPad1-3 `$BF0D`, `$BF1F`, `$BF31`; FreeSpace `$C600`, StackSpace `$CFC0`, DevZeros `$E100` |

Data that is not an entry at all but immediate operands of instructions stays code, listed in the documents:

- **The sounds**: SoundLoop's three tones (`LD BC` at `$8077`, `$807D`, `$8083`: delay passes and cycles) and every
  BEEPER note (the foul jingle `$9786-$979C`, the count-up's pitch `$9975`, `$99DC`, `$99F5`, the last-shot beep
  `$9CAC`, the clicks `$AF0C`, `$AF2F`, `$B2C7` ...): there is no tone table, doc 09, 9.6 lists every operand.
  `tools/uknc_convert.py` reads them from the built image for the UKNC port.
- **The key names**: KeyName `$B626` writes "ent", "s/s", "c/s" and the quotes with `LD (HL),n`; the KeysLine
  record around them is `text/KeysLine.txt`.
- **The table geometry**: the cushion lines, jaws and pocket boxes are operands of the cushion code (`maps/README.md`).
- **The numbers and the hall of fame's names** are built by the code from the variables at run time.
