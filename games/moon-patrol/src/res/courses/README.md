# Course scripts

The two course scripts as text, one command a line (the format is in `tools/res_formats.py`, section COURSE). They
are read by the interpreter CourseRun `$9751`: each segment runs until `End`; a sector end is `SectorEnd` with its par
time, bonus, scenery and best time (the best time is the one word play writes back here: BestTimeWrite in
SectorBonus `$A4EE`). The last line of each is the word that jumps to the course switch after it (`$BB07`, `$BED4`).

| File | Address | Bytes | Format | Readers | What |
| --- | --- | ---: | --- | --- | --- |
| `BeginnerCourse.txt` | `$B7E8-$BB06` | 799 | text, one command a line | ChampionToBeginner, GameStart | The Beginner course script, points A-Z in five sectors (E, J, P, U, Z) |
| `ChampionCourse.txt` | `$BB24-$BED3` | 944 | text, one command a line | BeginnerToChampion, GameStart | The Champion course script, points A-Z in five sectors |
