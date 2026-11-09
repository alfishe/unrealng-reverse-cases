# Tables

The tables as CSV (the four physics tables, the rules' shots, the rack, the key matrix, the letters' widths): `#` lines say what the rows, columns and cells mean, then a header line, then one line a
row (`tools/res_formats.py`, section CSV tables). All are read only.

| File | Address | Bytes | Format | Readers | What |
| --- | --- | ---: | --- | --- | --- |
| `ContactTable.csv` | `$DBFA-$DCF9` | 256 | 16 x 16 grid, row \|dy\|, column \|dx\|, decimal | BallContacts `$87EF` at 16 \|dy\| + \|dx\| | Ball against ball: 128 the balls overlap (d² <= 212), 1-31 the contact ring cell (d² 218..250, the record of CollisionRecords), 0 apart |
| `Table8x8.csv` | `$DCFA-$DD39` | 64 | 8 x 8 grid, row \|dy\|, column \|dx\|, decimal | PointJaw `$8CF8` | Ball against a middle pocket's jaw point: 128 overlap (d² <= 37), 1 touching (40..53), 0 apart |
| `FrictionTable.csv` | `$DD3A-$DE39` | 256 | 16 x 16 grid, row the \|vy\| nibble, column the \|vx\| nibble, cells `y:x` | FrictionSteps `$90F5` at 16 ny + nx | The friction steps in 1/256 pixel a tick: round (5 x the unit vector of the direction), y step high nibble, x step low nibble; (0, 0) = `4:4` never read |
| `CollisionRecords.csv` | `$DE3A-$DEF3` | 186 | one line a record: record, nxx, nyy, nxy (8.8 words, decimal) | BallContacts (`$886F`: CollisionRecords + 6 (n - 1)), ScaleVelocity `$89C4` | For each ring cell (dx, dy): 256 dx²/225, 256 dy²/225, 256 \|dx dy\|/225, the distance taken as 15 |
| `ShotsPerFrame.csv` | `$9C06-$9C0E` | 9 | one line a frame: frame, shots | ShotsForFrame `$9BE6` (frame - 1; frame 10 on: 2, `LD L,$02` at `$9BED`) | The shots of frames 1-9: 5, 5, 4, 4, 4, 3, 3, 3, 3 |
| `StartPositions.csv` | `$9D5D-$9D6A` | 14 | one line a ball: ball, x, y | ResetBallPositions `$9D2C` | The rack: the cue ball (40, 115) and balls 1-6 in a triangle with its point at (190, 115); the rack scripts (`../racks`) end on the same points |
| `KeyTable.csv` | `$8254-$827B` | 40 | one line a half row: port, then the five keys from bit 0 (a character, or caps, enter, space, symbol) | KeyDown `$822E` (CPIR) | The keyboard matrix: the K-TEST character of each key, by half row from the outer key in (caps `$27`, enter `$0D`, space `$20`, symbol `$18`) |
| `FlipWidths.csv` | `$BC74-$BC9D` | 42 | one line a step k 0-20: step, w16, w24 (the file holds the 21 w16, then the 21 w24) | FlipEdge `$BC11` | The half-widths of a turning letter: FlipWidths16 16 cos 4.5k, FlipWidths24 `$BC89` 24 cos 4.5k |
