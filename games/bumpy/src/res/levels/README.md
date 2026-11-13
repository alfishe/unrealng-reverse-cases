# Levels

`levels.txt` holds the 100 level records of LevelRecords `$8C3C-$A987` (75 bytes each, 7500 bytes). The reader is
BuildLevel `$CF2E` (at every life's start: record Level `$AB00`, copied to LevelRecord `$AA20`); the text form is
written and read by `tools/res_formats.py` (`levels_out` / `levels_in`), drawn by `tools/fig_levels.py`.

Record: +0..+35 the 36 cells, six rows of six, top row first (cell = 6 x row + column): the wall type in the high
nibble, the platform type in the low; +36 the ball's start cell; +37 the prizes to take; +38 the exit's cell; +39..+74
the object in each cell.

In the text, each level is a line `level NN start C exit C prizes N` and six rows `platforms | walls | objects`:
a hex digit a platform or wall (`.` for 0), two hex digits an object (`..` for 0).

| Platform | What | Drawn by | Landing |
| --- | --- | --- | --- |
| 0 | none: the ball falls through | PlatDrawNone `$D0A4` | falls to the cell below; off the bottom row state 7 (lost) |
| 1 | plain | PlatDraw1 (`$7788`) | bounce |
| 2, 3, 4 | crumbling: each bounce or leave wears it 2 → 3 → 4 → 0 | `$7900`, `$7A78`, `$7B62` | bounce |
| 5 | stopping: the ball waits for left or right (state 5) | `$7BE2` | stop |
| 6, 7 | conveyors: push left (state 1) / right (state 2) | `$77A8`, `$77F8` | move |
| 8, 9 | type 1 / type 5 on fire | + FirePictures `$814D` | a water drop puts it out (→ 1 / 5), else death |
| 10 | bricks: 8 layers, knocked off from below, the first with a hammer | BrickPicture `$8345` | bounce |
| 11 | the exit (written at ExitCell when PrizesLeft reaches 0) | ExitFrames `$80D5` | level end (state 8) |
| 12 | spikes | SpikesPicture `$7D5A` | death (burst, state 6) |

| Wall | What |
| --- | --- |
| 1, 2, 3 | a lock: each key lowers it by one, type 1 opens (`WallLock1-3`, `$7F7C`, `$7F4C`, `$7F1C`) |
| 4 | a wall no key opens, animated (`$7E5C`) |

The wall of a cell stands on its right; column 5's walls are never drawn (WallAddresses `$E179` holds 0 there).

| Object | What |
| --- | --- |
| 1 | hammer (Hammers `$AAFF` + 1) |
| 2 | key (Keys `$AAFE` + 1) |
| 3 | water drop (Water `$AAFD` + 1) |
| 4 | bottle: an extra life (Lives `$AB01` + 1) |
| 5-40 | prizes: 15 points each, PrizesLeft `$AA45` - 1 |
