# Resources

Every resource out of the code, in an editable format where one keeps every byte; `python3 tools/res_formats.py build` turns them back into the bytes the sources INCBIN (`tools/build.sh` runs it first), `python3 tools/res_formats.py check` proves every editable file comes back unchanged through its bytes (0 bad). Each folder has a README with the address, size and reader of every file; the formats are in tools/res_formats.py.

| Folder | Part | What |
| --- | --- | --- |
| `texts/` | game | the texts (UTF-8) and the high-score table |
| `tables/` | game | the score awards, the clear list, the default keys, the interrupt tasks, the object table (CSV) |
| `graphics/` | game | the font (PNG) and the sprites (PNG + CSV) |
| `sound/` | game | the note periods, command and script tables, the sound scripts |
| `screens/` | tape, game | the loading screen and the title picture (SCREEN$) |
| `levels/` | level1-8 | each level's map (text grid), metatiles (PNG + CSV), object table (CSV), sprites (PNG + CSV) |
| `loader/` | stage2 | the second stage's block table and countdown digits |
| `leftovers/` | game | the bytes nothing reads |
