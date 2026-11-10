# Resources

Every resource out of the code, in an editable format; `tools/res_formats.py build` turns them back into the bytes
the sources INCBIN (`src/game/*.asm` and `src/loader/*.asm`), `tools/res_formats.py check` proves the round trip
(35 editable files, 0 bad). `tools/build.sh` runs the build into `build/res` first.

| File | What | Format | Entry |
| --- | --- | --- | --- |
| `graphics/CharacterSet.png` | the character set, codes 0-`$9D`: map cells, font, title logo, key names | PNG sheet, 8 x 8 | CharacterSet `$84F0` |
| `graphics/HudCharacters.png` | codes `$9E-$CB`: HUD digits, the cage, life icon, cursor | PNG sheet, 8 x 8 | HudCharacters `$89E0` |
| `sprites/Sprites.png` | Harry, the duck, blank, Harry climbing: 17 frames | PNG sheet, 16 x 16 | Sprites `$8DF0` |
| `sprites/HenSprites.png` | the hens' 8 frames | PNG sheet, 16 x 16 | HenSprites `$9010` |
| `maps/Level1.txt` ... `Level8.txt` | the eight level maps | text, one character a cell, legend in the head | LevelMaps `$B3B0` ... LevelMap8 `$C610` |
| `tables/HenTable.csv` | the hens of levels 1-8 | CSV | HenTable `$945B` |
| `tables/LiftTable.csv` | the lift of each level | CSV | LiftTable `$9787` |
| `tables/CellAttributes.csv` | the ink of map cell codes 0-8 | CSV | CellAttributes `$984F` |
| `tables/LiftPhrases.csv`, `DeathPhrases.csv`, `LevelPhrases.csv` | the phrase numbers the three pickers choose from | CSV | LiftPhrases `$A399`, DeathPhrases `$ABEA`, LevelPhrases `$B15F` |
| `text/KeySets.txt` | the three key sets | text, key names | KeySets `$8250` |
| `text/InstructionsText.txt`, `TitleText.txt`, `Congratulations.txt` | the instructions, title and name-entry pages | UTF-8 quoted rows | InstructionsText `$8390`, TitleText `$9630`, Congratulations `$AD67` |
| `text/HudText.txt`, `HiScoreTable.txt`, `MenuTexts.txt` | the HUD labels, the default hi-score table, the menu texts | UTF-8 quoted strings | HudText `$9764`, HiScoreTable `$97AF`, MenuTexts `$ABF2` |
| `text/MenuLeftover.txt` | leftover: three earlier menu lines, never read | UTF-8 quoted string | MenuLeftover `$8336` |
| `text/SourceLeftover*.txt` (4) | leftover: the author's assembler source, never read | text, one source line a line | SourceLeftoverB167 `$B167`, `B307` `$B307`, `B381` `$B381`, `C8B0` `$C8B0` |
| `sound/TitleTune.txt`, `DeathTune.txt` | the two beeper tunes | text, one note a line | TitleTune `$AE0C`, DeathTune `$AE6A` |
| `sound/Phrases.txt` | the phrase table and the 32 speech phrases | text, allophone names | PhraseTable `$C8C8` |
| `loader/PictureGraphics.png` | the loading picture's 66 graphics | PNG sheet, 8 x 8 | PictureGraphics `$5CE3` (tape block 2) |
| `loader/PictureText.txt` | the loading picture's 768 character codes | quoted rows | PictureText `$601C` (tape block 2) |

Each folder's README.md lists its files with address, size, format and readers. Figures drawn from the resources
(outputs, not INCBINned): `docs/img/maps/Level1.png` ... `Level8.png` (`tools/fig_maps.py`) and
`docs/img/loading.png` (`tools/fig_loading.py`).

Text encoding: printable ASCII is itself, `·` (U+00B7) is code 0 (the empty cell the game prints as a space), the
fullwidth digits `０`-`９` (U+FF10-U+FF19) are the HUD digit codes `$9E-$A7`, and any other byte is `\xNN`. The build
writes the original codes back; the loader's PictureText uses `\xNN` only.

## What stays bytes, and why

| Reason | Entries |
| --- | --- |
| Leftovers never read (L1 of the eight builds: no access) | LeftoverMapRow `$8214`, LeftoverSprite `$9110`, LeftoverCode943E `$943E`, Leftover97AB `$97AB`, LeftoverCode9A2C `$9A2C`, LeftoverCode9C8E `$9C8E`, LeftoverCode9E57 `$9E57`, LeftoverCodeA0C0 `$A0C0`, LeftoverA21A `$A21A`, LeftoverA3A1 `$A3A1`, LeftoverA40F `$A40F`; the readable leftovers are resources above (MenuLeftover, SourceLeftover*) |
| Fill never read | FillFF `$8B50` (672 bytes of `$FF`, the size of one map) |
| Space and padding | Zeros8274 `$8274`, Zeros9518 `$9518`, Zeros95C5 `$95C5`, Zeros9BFF `$9BFF`, Zeros9C9F `$9C9F`, Zeros9CB5 `$9CB5`, Zeros9D06 `$9D06`, Zeros9DF1 `$9DF1`, Zeros9E8D `$9E8D`, Zeros9F3F `$9F3F`, Zeros9FDF `$9FDF`, ZerosA19A `$A19A`, ZerosCBC4 `$CBC4` |
| Code-like data | TuneCalc `$AB6D` (an RST `$28` calculator program), VectorTable `$B200` (the IM 2 table, 263 bytes of `$9C`; only `$B2FF-$B300` are read) |
| Loader padding | ArrayPadding `$631C` (seven spaces of a$, tape block 2) |
| Work variables | none in the image: the game's variables (`$61A8-$7375`) lie below the block and are named by `@equ` in `src/game/game.ann` |
