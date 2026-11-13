# Tables

CSV with a header (`#` lines comments, numbers decimal or `$hex`; the first column numbers the records and is not
read back), or text records.

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `object-inks.csv` | ObjectInks `$C6F6` | 41 | BuildLevelObject `$CFF4`, TakeObject | the attribute each object kind is drawn in |
| `demo-moves.csv` | DemoMoves `$D25A` | 49 | ChooseNextState `$B7E4` in the demo (DemoInputPtr `$ABA4`) | the demo's decisions: next state 0-5, 9 arm the spring |
| `level-colours.csv` | LevelColours `$E119` | 24 | BuildLevel `$CF2E` → `$B6DB` (a RET) | CPC inks of pens 1-3 by level mod 7 |
| `cell-addresses.csv` | CellAddresses `$E131` | 72 | `$BB05` | each cell's CPC screen address |
| `wall-addresses.csv` | WallAddresses `$E179` | 72 | `$BB1D` | each wall's CPC screen address (0 for column 5) |
| `brick-steps.csv` | BrickSteps `$E1C1` | 8 | HitBrick `$B8D1` | the layer count the rising ball touches at each up step |
| `control-sets.csv` | KeyboardKeys `$F092` | 24 | LoadControls `$F0AA` | the key codes of the keyboard, Kempston and Sinclair sets |
| `hall-of-fame.txt` | HallOfFame `$EEB3` | 128 | EnterHallOfFame `$EC40`, PrintHallOfFame | 4 records: the PrintText line, the score word, 12 zero bytes |
