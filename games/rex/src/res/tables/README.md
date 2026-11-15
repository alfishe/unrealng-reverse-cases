# Tables

| File | Address | Size | Readers |
| --- | --- | --- | --- |
| `rex1-char-flags.csv` | REX 1 `$62E0` CharFlags | 256 | DrawRoomCell `$C7E2` (into the room grid), every cell test |
| `rex2-char-flags.csv` | REX 2 `$6506` | 256 | the same, part 2 |
| `demo-char-flags.csv` | DEMO `$6538` | 256 | the same, DEMO |
| `rex1-kill-scores.csv` | REX 1 `$994E` KillScores | 26 | KillObject `$981F` (x 100 points) |
| `rex2-kill-scores.csv` | REX 2 `$9896` | 26 | KillObject |
| `demo-kill-scores.csv` | DEMO `$8EA8` | 16 | ShowPoints `$8E4D` |
| `rex1-attract-rooms.txt` | REX 1 `$A90C` AttractRooms | 9 | Attract `$A915` |
| `demo-tutor-rooms.txt` | DEMO `$A2A2` TutorRooms | 5 | NextTutorRoom |

CSV with a header line; the first column numbers the rows (the character, the object kind) and is not read back;
numbers decimal or `$hex`. The `.txt` tables are byte lists, one a line, `$FF` the end.

The cell types (CharFlags): 0 empty; 2, 4, 5, 6 solid (SolidCells: part 2 adds 3, DEMO has 9, its conveyor);
7 the restart marker; 8 the shield recharger; `$0A`-`$0D` the weapon stations; `$0E`-`$12` platforms Rex and the
objects may pass (PassCells), `$12` the ladder or lift; part 2: 3 kills a falling object, 4 is the big squidgy thing
(BossHit), `$15` and `$16` dissolve walkers. The scores are hundreds by object kind (REX 1: FOOT MAN 1, STOMPER 2,
SCANNER 6, ...; the roll call in texts/rex1-roll-call.txt agrees).
