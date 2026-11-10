# Maps

The eight level maps at LevelMaps `$B3B0`, 672 bytes each: 21 rows of 32 cell codes, the bottom row (row 0) first in
the image, the top row first in the text. Each text file carries its legend: `.` 0 empty, `[` `]` 1 / 2 a ladder's
two columns, `o` 3 an egg, `*` 4 grain, `=` 5 a brick, `a`-`n` `$A8-$B5` the duck's cage, `{NN}` any other byte.

Readers: StartGame `$A59D` copies level 1 into every player's LiveMap slot; PlayLevel `$A653` copies the next level
(LevelMaps + 672 x (Level AND 7)) into LiveMap `$61A8`, so levels 9-16 repeat 1-8 and so on; SetupLevel `$AE9C`
prints it. The game then reads and writes only LiveMap (eggs and grain taken).

| File | Address | Bytes | Eggs | Hens (HenTable) | Lift (LiftTable) | Figure |
| --- | --- | ---: | ---: | ---: | --- | --- |
| `Level1.txt` | `$B3B0-$B64F` | 672 | 12 | 2 | none | `docs/img/maps/Level1.png` |
| `Level2.txt` | `$B650-$B8EF` | 672 | 12 | 3 | none | `docs/img/maps/Level2.png` |
| `Level3.txt` | `$B8F0-$BB8F` | 672 | 12 | 3 | x `$40` | `docs/img/maps/Level3.png` |
| `Level4.txt` | `$BB90-$BE2F` | 672 | 12 | 4 | x `$90` | `docs/img/maps/Level4.png` |
| `Level5.txt` | `$BE30-$C0CF` | 672 | 12 | 4 | x `$C8` | `docs/img/maps/Level5.png` |
| `Level6.txt` | `$C0D0-$C36F` | 672 | 12 | 4 | x `$78` | `docs/img/maps/Level6.png` |
| `Level7.txt` | `$C370-$C60F` | 672 | 12 | 3 | x `$F0` | `docs/img/maps/Level7.png` |
| `Level8.txt` | `$C610-$C8AF` | 672 | 12 | 3 | none | `docs/img/maps/Level8.png` |

The figures are outputs, not inputs: `tools/fig_maps.py` draws them from these files, the glyphs of
`../graphics/*.png` and the inks of `../tables/CellAttributes.csv`, as PrintChar `$9C40` and PaintCells `$9538` do.

```bash
python3 tools/fig_maps.py            # writes docs/img/maps/Level1.png ... Level8.png
```
