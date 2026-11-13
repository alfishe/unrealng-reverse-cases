# tables

CSV tables: `#` lines comments, a header naming the columns, one record a line; decimal or `$hex`; a column whose
name starts with `_` is for the reader only.

| File | Address | Size | Table | Read by |
| --- | --- | --- | --- | --- |
| beam-glyph-bytes.csv | `$8000` | 128 | the beam's glyph numbers round a vertex: 2 sets (the second for the flashing beam) x 16 directions x 4 (incoming, corner, outgoing pass) | BeamVertex `$906E` |
| out-bounce.csv | `$8080` | 128 | a slanted beam's bounce in the outgoing pass: 8 bytes a direction (two neighbour offsets, four directions) | BeamCornerTurn, ReflectOutSlant |
| in-corner.csv | `$8100` | 64 | a diagonal beam's bounce in the incoming pass, 16 bytes for each of the diagonals 2, 6, 10, 14 | ReflectInCorner |
| in-bounce.csv | `$8140` | 48 | a slanted beam's bounce in the incoming pass: the new direction (or `$80` + n), dx, dy | ReflectInSlant |
| beam-deltas.csv | `$8170` | 32 | dx, dy of the 16 directions (0 east, clockwise) | BeamNewDirection, FindLaser, OpenReceiver |
| graze-offsets.csv | `$8190` | 16 | the character across an axis beam's line: 8 offsets in the character map | BeamAbsorbIn/Out, BeamReflectIn/Out |
| polariser-cells.csv | `$81A0` | 24 | a polariser's three other characters for each of its four | PolariserPassIn/Out |
| sounds.csv | `$81D4` | 40 | 8 PlaySound records of 5 bytes: burn, mine, laser back, burning, charging, gremlin, charged, contact | PassEnd, the sound flags |
| cell-table.csv | `$8200` | 372 | the four character codes of each cell code `$00-$5C` | RenderGrid `$8960` |
| level-settings.csv | `$8385` | 130 | each level slot's energy rate (frames a pixel of the energy bar) and gremlin count | SetUpLevel `$843C` (`$84CD`) |
| sounds-pass-end.csv | `$8660` | 10 | 2 PlaySound records: ReceiverOpenSound, LifeLostSound | PassEnd `$85E7`, LoseLife `$866A` |
| sound-drained.csv | `$8695` | 5 | the PlaySound record EnergyDrainedSound | LoseLife `$866A` |
| wipes.csv | `$8D95` | 128 | PlayAreaWipes and ScreenWipes: per corner the four steps and the four start addresses | WipeIn `$8CAD` |
| cursor-steps.csv | `$993E` | 32 | the cursor's dx, dy for each value of the direction bits | MoveCursor `$9910` |
| letter-keys.csv | `$9EBD` | 27 | the TestKey code of each letter A-Z, `$FF` ends | ReadLetterKey `$9E5A` |
| menu-dither.csv | `$9F41` | 8 | the options screen's background dither, 8 pixel rows | DrawMenuScreen `$9ED8` |
| options-layout.csv | `$A053` | 175 | the options screen's attributes: 87 runs (count, value), `$FF` ends | DrawMenuScreen `$9ED8` |
| gremlin-steps.csv | `$AB97` | 8 | a gremlin's four moves (dX, dY) | GremlinMove `$AC4D` |
| title-tune.csv | `$ADF0` | 528 | the title tune: 176 notes of three voice periods | TitleTune `$AD79`, PlayNote `$ADA7` |
