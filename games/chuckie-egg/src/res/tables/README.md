# Tables

CSV, `#` comment lines first, then a header row. Numbers are decimal unless written `$NN`.

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `HenTable.csv` | `$945B-$9517` | 189 | SetupLevel `$AE9C` at `$AFA4`: row (Level AND 7) + 1 (35 level starts in the eight builds) | nine rows of 21: a byte count (8, 12 or 16: two to four hens), then five records (x, y, state, pad); row 0 is never read. Levels 9-16 copy no hens, 17-24 the table again, 25 and up all five records |
| `LiftTable.csv` | `$9787-$97AA` | 36 | SetupLevel `$AE9C` (copies record (Level AND 7) + 1 over the first), MoveLifts `$A014` (restarts a platform from the first record) | the record in play, then one a level: the platform's screen address, x (255 = none), the start height count (3). Lifts on levels 3-7 |
| `CellAttributes.csv` | `$984F-$9857` | 9 | PaintCells `$9538`, EraseHen `$935F`, SetupLevel `$AE9C` | the attribute of map codes 0-8 (codes 9 and up take 6) |
| `LiftPhrases.csv` | `$A399-$A3A0` | 8 | LiftPhrase `$A389` (R AND 7) | the phrase said when Harry catches a lift |
| `DeathPhrases.csv` | `$ABEA-$ABF1` | 8 | DeathPhrase `$AAE4` (R AND 7) | the phrase said when a life is lost |
| `LevelPhrases.csv` | `$B15F-$B166` | 8 | LevelPhrase `$B14F` (R AND 7) | the phrase said at a level start |
