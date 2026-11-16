# Levels

Each level's body (LoadLevel `$FE03` loads it to `$C4AE`) holds its own graphics and map; `levelN/` has the five resources of src/levelN/levelN.ann. `python3 tools/levelmap.py OUTDIR` draws every level's scenery and its metatiles from these files alone.

| File | Format |
| --- | --- |
| `map.txt` | 5 lines (the metatile rows, top to bottom), one token a block column of 32 pixels: the metatile number and its drawer, `.` as stored (`$8741`), `m` mirrored (`$8778`), `f` upside down (`$87B8`), `b` both (`$87F2`) |
| `metatiles.png`, `metatiles-attrs.csv` | metatile n at x = 32 n, 4 x 4 cells upright (index 0 paper, 1 ink); the CSV the 16 cell attributes of each metatile, row by row. In memory metatile n is the 144 bytes at the map - 144 (n + 1) (MetatileAddress `$882D`), so the file runs from the highest metatile down |
| `objects.csv` | the object table: width, height (cells), the cells' address (LevelObject `$8E85`) |
| `sprites.png`, `sprites.csv` | the objects' cells in the kit's cell format (`kit/cells.py`, the pieces cut by `objects.csv`: see `graphics/README.md`); the 9 bytes after the last object, which no object points at, as a `bytes` line |
| `waves.txt` | the wave script (RunWaves), one wave a line: block column, metatile column.scroll step, then `kind K at C,R` (the kind, the enemy's column and row) or `command N A` (kind `$63`); from the end mark `$FF` on, the bytes up to the kind table (the end mark and the kind records) as `bytes` lines in hex. Formats: doc 7, 7.3 (RunWaves and the commands) |

| File | Entry | Address | Bytes |
| --- | --- | --- | --- |
| `level1/sprites.bin` | L1Sprites | `$C4E0` | 4889 |
| `level1/objects.bin` | L1Objects | `$D7F9` | 280 |
| `level1/metatiles.bin` | L1Metatiles | `$D911` | 3168 |
| `level1/map.bin` | L1Map | `$E571` | 535 |
| `level1/waves.bin` | L1Waves | `$E788` | 2163 |
| `level2/sprites.bin` | L2Sprites | `$C4E0` | 3730 |
| `level2/objects.bin` | L2Objects | `$D372` | 208 |
| `level2/metatiles.bin` | L2Metatiles | `$D442` | 4896 |
| `level2/map.bin` | L2Map | `$E762` | 335 |
| `level2/waves.bin` | L2Waves | `$E8B1` | 2278 |
| `level3/sprites.bin` | L3Sprites | `$C4E0` | 6318 |
| `level3/objects.bin` | L3Objects | `$DD8E` | 424 |
| `level3/metatiles.bin` | L3Metatiles | `$DF36` | 2016 |
| `level3/map.bin` | L3Map | `$E716` | 320 |
| `level3/waves.bin` | L3Waves | `$E856` | 1274 |
| `level4/sprites.bin` | L4Sprites | `$C4E0` | 5685 |
| `level4/objects.bin` | L4Objects | `$DB15` | 412 |
| `level4/metatiles.bin` | L4Metatiles | `$DCB1` | 2160 |
| `level4/map.bin` | L4Map | `$E521` | 370 |
| `level4/waves.bin` | L4Waves | `$E693` | 2295 |
| `level5/sprites.bin` | L5Sprites | `$C4E0` | 3182 |
| `level5/objects.bin` | L5Objects | `$D14E` | 156 |
| `level5/metatiles.bin` | L5Metatiles | `$D1EA` | 720 |
| `level5/map.bin` | L5Map | `$D4BA` | 370 |
| `level5/waves.bin` | L5Waves | `$D62C` | 2200 |
| `level6/sprites.bin` | L6Sprites | `$C4E0` | 1875 |
| `level6/objects.bin` | L6Objects | `$CC33` | 132 |
| `level6/metatiles.bin` | L6Metatiles | `$CCB7` | 3312 |
| `level6/map.bin` | L6Map | `$D9A7` | 310 |
| `level6/waves.bin` | L6Waves | `$DADD` | 2181 |
| `level7/sprites.bin` | L7Sprites | `$C4E0` | 3184 |
| `level7/objects.bin` | L7Objects | `$D150` | 216 |
| `level7/metatiles.bin` | L7Metatiles | `$D228` | 5328 |
| `level7/map.bin` | L7Map | `$E6F8` | 370 |
| `level7/waves.bin` | L7Waves | `$E86A` | 2281 |
| `level8/sprites.bin` | L8Sprites | `$C4E0` | 5308 |
| `level8/objects.bin` | L8Objects | `$D99C` | 184 |
| `level8/metatiles.bin` | L8Metatiles | `$DA54` | 2304 |
| `level8/map.bin` | L8Map | `$E354` | 920 |
| `level8/waves.bin` | L8Waves | `$E6EC` | 1246 |
