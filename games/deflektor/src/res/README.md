# Resources

Every resource out of the code, in an editable format; `tools/res_formats.py build --out build/res` turns them back
into the bytes the sources INCBIN (tools/build.sh does it first), `tools/res_formats.py check` proves the round trip
(22 files, 0 bad). The formats are described in the docstring of tools/res_formats.py and in each folder's README.md.
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
