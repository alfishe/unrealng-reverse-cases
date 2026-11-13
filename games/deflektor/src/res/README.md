# Resources

Every resource out of the code, in an editable format; `tools/res_formats.py build --out build/res` turns them back
into the bytes the sources INCBIN (tools/build.sh does it first), `tools/res_formats.py check` proves the round trip
(45 files, 0 bad). The formats are described in the docstring of tools/res_formats.py and in each folder's README.md.
Pictures of every level from levels/levels.txt: `python3 tools/level_maps.py OUT`.

| File | Address | Size | Format | What | Read by |
| --- | --- | --- | --- | --- | --- |
| screens/title.png | `$6000` | 6912 | attribute PNG, `screen` | TitlePicture: the title screen | the title (`TitleKeyReleaseLoop`), copied whole to `$4000` |
| screens/panel.png | `$7B80` | 1152 | attribute PNG, `linear` | PanelPicture: the play panel, rows 20-23 | DrawPanel `$A50C` |
| tables/beam-glyph-bytes.csv | `$8000` | 128 | CSV | BeamGlyphBytes: the beam's glyphs round a vertex, 2 sets x 16 directions x 4 | BeamVertex `$906E` (`D` = `$80`) |
| tables/out-bounce.csv | `$8080` | 128 | CSV | OutBounceTable | BeamCornerTurn, ReflectOutSlant |
| tables/in-corner.csv | `$8100` | 64 | CSV | InCornerTable | ReflectInCorner |
| tables/in-bounce.csv | `$8140` | 48 | CSV | InBounceTable | ReflectInSlant |
| tables/beam-deltas.csv | `$8170` | 32 | CSV | BeamDeltas: dx, dy of the 16 directions | BeamNewDirection, FindLaser, OpenReceiver |
| tables/graze-offsets.csv | `$8190` | 16 | CSV | GrazeOffsets | BeamAbsorbIn/Out, BeamReflectIn/Out |
| tables/polariser-cells.csv | `$81A0` | 24 | CSV | PolariserCells | PolariserPassIn/Out |
| tables/sounds.csv | `$81D4` | 40 | CSV | the 8 PlaySound records (BurnSound to ContactSound) | PassEnd, the sound flags (`SoundFlagsFound`) |
| tables/level-settings.csv | `$8385` | 130 | CSV | LevelSettings: energy rate and gremlin count of each slot | SetUpLevel `$843C` |
| tables/sounds-pass-end.csv | `$8660` | 10 | CSV | ReceiverOpenSound, LifeLostSound | PassEnd, LoseLife |
| tables/sound-drained.csv | `$8695` | 5 | CSV | EnergyDrainedSound | LoseLife `$866A` |
| graphics/game-over.png | `$8714` | 192 | 1-bit bitmap | GameOverBanner, 96 x 16 | LoseLife `$866A` |
| graphics/level-digits.png | `$88B0` | 88 | 1-bit glyphs | LevelDigits: 0-9 and P | SetUpLevel `$843C` |
| tables/wipes.csv | `$8D95` | 128 | CSV | PlayAreaWipes and ScreenWipes: 8 corner records of 8 words | WipeIn `$8CAD` |
| texts/practice.txt | `$8A9D` | 36 | hex text | PracticeText | PrintPlay `$8E47` |
| texts/intermission.txt | `$972B` | 15 | hex text | IntermissionText | the pause `$973F` |
| tables/cursor-steps.csv | `$993E` | 32 | CSV | CursorSteps | MoveCursor `$9910` |
| graphics/cursor.png | `$9A37` | 32 | 1-bit bitmap | CursorGraphic, 16 x 16 | DrawCursorSquare `$9A11` |
| tables/letter-keys.csv | `$9EBD` | 27 | CSV | LetterKeys | ReadLetterKey `$9E5A` |
| tables/menu-dither.csv | `$9F41` | 8 | CSV | MenuDither | DrawMenuScreen `$9ED8` |
| texts/options.txt | `$9F49` | 154 | hex text | HallOfFameTitle, OptionsText | PrintFull `$8E3A` |
| graphics/name-cursor.png | `$9FE3` | 8 | 1-bit glyphs | NameCursorGlyph | the name entry |
| texts/hall-of-fame.txt | `$9FEB` | 104 | hex text | HallOfFameScores, HallOfFameNames | PrintFull, HallOfFame |
| tables/options-layout.csv | `$A053` | 175 | CSV | OptionsLayout: 87 attribute runs | DrawMenuScreen `$9ED8` |
| texts/messages.txt | `$A112` | 488 | hex text | the COMPUTER line's messages and loop words | the COMPUTER line |
| texts/ending.txt | `$A984` | 259 | hex text | EndingText | PrintFull `$8E3A` |
| graphics/ending-plug.png | `$AA87` | 32 | 1-bit bitmap | EndingPlug, 16 x 16 | the ending |
| graphics/ending-kettle.png | `$AAA7` | 60 | 1-bit bitmap | EndingKettle, 24 x 20 | the ending |
| graphics/gremlin.png | `$AAE3` | 128 | 1-bit bitmap | GremlinFrames, 4 x 16 x 16 | UpdateGremlins `$AB9F` |
| tables/gremlin-steps.csv | `$AB97` | 8 | CSV | GremlinSteps | GremlinMove `$AC4D` |
| tables/title-tune.csv | `$ADF0` | 528 | CSV | TitleTuneData: 176 notes x 3 periods | TitleTune `$AD79` |
| tables/cell-table.csv | `$8200` | 372 | CSV | CellTable: the four characters of each cell code `$00-$5C` | RenderGrid `$8960` |
| levels/levels.txt | `$B000` | 8640 | level text | LevelData: 64 slots of 135 cells (60 levels, the practice level in slot `$3C`, 3 unused) | BuildLevel (LevelSetup `$891A`) |
| graphics/font.png | `$D200` | 768 | 1-bit glyphs | Font, characters 32-127 | PrintChar, the menu, the hall of fame, the scroller |
| graphics/beam-glyphs.png | `$D500` | 312 | 1-bit glyphs | BeamGlyphs, 39 glyphs | BeamPlotGlyph, BeamOutPlot, BeamCornerPlot |
| graphics/cells.png | `$D700` + `$DF00` | 1696 + 212 | attribute PNG, `chars` | CellGraphics and CellColours, characters `$00-$D3` | DrawMarkedChars `$8A09`; the wall tests of BeamAbsorb/Reflect |
| loader/glyphs.png | `$B326` | 472 | 1-bit glyphs | the loading screen's font (the turbo block's 4th load) | stage 2's PrintGlyph `$B812` |
| loader/script.txt | `$998E` | 6552 | hex text | the loading screen's script (5th load) | stage 2's ScriptStep `$B78E` |
| leftovers/gap-7b00.bin | `$7B00` | 128 | bytes | zeros between the title and the panel | none |
| leftovers/spare-d1c0.bin | `$D1C0` | 64 | bytes | zeros after the last level slot | none |
| leftovers/beam-glyphs-spare.png | `$D638` | 200 | 1-bit glyphs | 25 glyph slots past the last named glyph | none |
| leftovers/cell-graphics-spare.bin | `$DDA0` | 352 | bytes | zeros: characters `$D4-$FF` | none |
| leftovers/cell-colours-spare.bin | `$DFD4` | 44 | bytes | zeros: colours of `$D4-$FF` | none |

The game's work areas (the grid `$FD23`, the character map `$E000`, the buffers `$E300-$FCFF`) are not resources:
the game builds them. The main block's code outside the game (src/head) and the loader (src/tape, src/loader) have no
resources but these two loader files.

What stays bytes in the sources (DEFB / DEFW in src/game), and why: the game's variables (ControlMethod, Level,
Lives, CellsLeft, the explosion slots `$81B8`, the beam's and the wipe's state, RandomSeed, ScoreText, the name entry's
and the COMPUTER line's variables, the energy and overload bars, SoundFlags, the gremlin records `$AB63`), which the
game sets before it reads them, so their bytes in the image are no data the docs describe; and the few unread bytes
Spare81FC, Spare81FE, Unused9AF1, UnusedA102 and UnusedAD46 (`s`, 51 zeros). Every table, picture, text and tune is a
file above.
