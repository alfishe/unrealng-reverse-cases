# Tables

The game's small tables.

Format: CSV: a header of field names, one record a line, hex as `$nn`; a `tail` line keeps the bytes after the last whole record.

| File | Entry | Address | Bytes | What |
| --- | --- | --- | --- | --- |
| `score-awards.csv` | ScoreAwards (`src/game/game.ann`) | `$70DC` | 20 | The score awards: 10 pairs (place, digit) AwardScore hands to AddScore |
| `clear-list.csv` | ClearList (`src/game/game.ann`) | `$75B7` | 38 | The blocks ClearPlayState zeroes at every start: address, length, ...; a zero word ends it |
| `defined-keys.csv` | DefinedKeys (`src/game/game.ann`) | `$7780` | 12 | Six keys as (half-row port high byte, bit mask), DefineKeys / ReadKeys |
| `game-objects.csv` | GameObjects (`src/game/game.ann`) | `$BC67` | 444 | 111 objects of 4 bytes: width, height, the cells' address (GameObject) |
| `task-table.csv` | TaskTable (`src/game/game.ann`) | `$BE60` | 25 | The 5 interrupt tasks: address, switch, counter, reload |
