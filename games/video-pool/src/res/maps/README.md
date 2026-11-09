# Maps

For a pool game the map is the table and what moves onto it before play: the six rack-in sets. Each PNG is drawn from
`../racks/RackScripts.txt` (not from the image) by `tools/fig_objects.py racks`, which runs RackStep `$A05E`'s rules
on the scripts over the empty table of `w1` frame 707; the same run draws all six sets as `docs/img/maps/racks.png`
(doc 07, 7.4; doc 01, 1.5). These files are outputs, not inputs: the build copies them but no INCBIN reads them.

```bash
python3 tools/fig_objects.py racks --table work/docs/vpC/shots/t707.png --out docs/img/maps/racks.png
```

| File | Set | Frames | What |
| --- | ---: | --- | --- |
| `RackSet0.png` | 0 (`$A0D0`) | 1-2, 13-14, ... | from the left corner pockets along the middle line (seen in `w1` frames 707-877) |
| `RackSet1.png` | 1 (`$A162`) | 3-4, 15-16, ... | from the four corners and the middle pockets (seen in `w1` frames 3 and 4) |
| `RackSet2.png` | 2 (`$A1E4`) | 5-6, 17-18, ... | along the cushions to x 27, then right along the rack rows (from the code) |
| `RackSet3.png` | 3 (`$A29C`) | 7-8, 19-20, ... | from the right corners across to the left cushion and back (from the code) |
| `RackSet4.png` | 4 (`$A38E`) | 9-10, 21-22, ... | round the cushions with pauses and side steps (from the code) |
| `RackSet5.png` | 5 (`$A4F8`) | 11-12, 23-24, ... | all six on one path, dropping into a pocket and coming out of another (from the code) |

Under each table: each ball's first wait and the step on which its script ends (the rack's length is the largest).

## The table geometry

The code holds no geometry table: the cushion lines, the corner and middle jaws and the pocket boxes are immediate
operands of the physics code (module `cushions`, `$8B4E-$90F4`), patched in place for the small pockets
(`$B8BC` = 0). They stay in the code and are listed with their instructions in doc 10 (10.4, the figure `docs/img/physics/geometry.png`) and in
`work/stage2/NOTES.md` ("Cushions and pockets"): cushion lines x 17 / 238 and y 65 / 166, cushion faces y 58 / 173,
the corner channels' diagonals y - x = 48, x + y = 183, x + y = 303, x - y = 72, the middle channels x 122..133 (small
125..130), the potting boundary x 8..247, y 56..175. The only geometry kept as data is the rack, StartPositions
`$9D5D` (`../tables/StartPositions.csv`); the jaw points' contact radius is `../tables/Table8x8.csv`.
