# Screens

`loading.scr` is the SpeedLock loading screen (the tape loads its bitmap to `$4000` and its attributes to `$8000`, src/tape/tape.txt); `title.scr` is the title picture at `$DD18` ShowLoadingScreen `$814F` copies to the screen at the entry. Both stay SCREEN$ files: their attributes hold ink = paper cells a PNG cannot keep.

Format: SCREEN$ files (6912 bytes: bitmap, attributes).

| File | Entry | Address | Bytes | What |
| --- | --- | --- | --- | --- |
| `title.scr` (bytes) | TitleScreen (`src/game/game.ann`) | `$DD18` | 6912 | The title picture (a SCREEN$) ShowLoadingScreen copies to the screen |
