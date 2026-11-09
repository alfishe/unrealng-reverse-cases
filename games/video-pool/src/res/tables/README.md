# Tables

The physics tables as CSV: `#` lines say what the rows, columns and cells mean, then a header line, then one line a
row (`tools/res_formats.py`, section CSV tables). All four are read only.

| File | Address | Bytes | Format | Readers | What |
| --- | --- | ---: | --- | --- | --- |
| `ContactTable.csv` | `$DBFA-$DCF9` | 256 | 16 x 16 grid, row \|dy\|, column \|dx\|, decimal | BallContacts `$87EF` at 16 \|dy\| + \|dx\| | Ball against ball: 128 the balls overlap (d² <= 212), 1-31 the contact ring cell (d² 218..250, the record of CollisionRecords), 0 apart |
| `Table8x8.csv` | `$DCFA-$DD39` | 64 | 8 x 8 grid, row \|dy\|, column \|dx\|, decimal | PointJaw `$8CF8` | Ball against a middle pocket's jaw point: 128 overlap (d² <= 37), 1 touching (40..53), 0 apart |
| `FrictionTable.csv` | `$DD3A-$DE39` | 256 | 16 x 16 grid, row the \|vy\| nibble, column the \|vx\| nibble, cells `y:x` | FrictionSteps `$90F5` at 16 ny + nx | The friction steps in 1/256 pixel a tick: round (5 x the unit vector of the direction), y step high nibble, x step low nibble; (0, 0) = `4:4` never read |
| `CollisionRecords.csv` | `$DE3A-$DEF3` | 186 | one line a record: record, nxx, nyy, nxy (8.8 words, decimal) | BallContacts (`$886F`: CollisionRecords + 6 (n - 1)), ScaleVelocity `$89C4` | For each ring cell (dx, dy): 256 dx²/225, 256 dy²/225, 256 \|dx dy\|/225, the distance taken as 15 |
