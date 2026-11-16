# sprites

Every sprite the game's descriptors name, cut from the bytes and laid on a sheet. Sprites are row-major, `width`
bytes a row, no mask. The build reads only the PNG and the CSV.

| Files | Entry | Holds |
| --- | --- | --- |
| `objects.png`, `objects.csv` | `ObjectSprites` `$6BE8-$75AF` | the smaller sizes of object type 5 and all of type 7 |
| `sprites.png`, `sprites.csv` | `Sprites` `$B306-$E2BF` | the other object sizes, the riders, the bike's poses and wheel patches, the splash, the dust |

CSV: `address`, `width` (bytes), `rows`, `x`, `y` (place on the sheet), `users` (the descriptors: object type and
size from `tables/objects.csv`, rider band and pose from `tables/riders.csv`, the bike poses (BikePoses `$9127`),
splash and dust (DrawSplash, DrawDust); these last are in tools/res_formats.py `SPRITE_EXTRA`). A `bytes` line holds
a byte no descriptor names: one, `$DE9A` (0), between the wheel patches of poses 5 and 4, a documented leftover.
PNG index 0 paper, 1 ink, 2 no pixel. The descriptors cover the two files with no overlap.
