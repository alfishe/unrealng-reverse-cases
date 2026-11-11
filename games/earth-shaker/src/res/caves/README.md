# Caves

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `caves.txt` | `$C000-$E73F` | 10048 | UnpackCave `$82B6` (cave N at `$BEC6` + 314N), CaveSetup `$9313` (the graphics and colours), tools/fig_caves.py | The 32 caves of 314 bytes: 300 bytes of cells, two a byte (the left cell in the low nibble), 30 a row, 20 rows; then the 14 parameter bytes UnpackCave copies to CaveParams `$FD9A-$FDA7` |

Format (tools/res_formats.py, the file's header repeats it): `# ` lines are comments (a row may start with `#`, a
wall). A cave is `cave N`, ten parameter lines, then 20 rows of 30 characters, one a cell:

| Char | Code | Cell | Char | Code | Cell |
| --- | --- | --- | --- | --- | --- |
| `.` | 0 | empty | `T` | 8 | jelly bean (refills the time bar) |
| `X` | 1 | exit | `Z` | 9 | force field |
| `0` | 2 | boulder | `A` | `$A` | anti-gravity arrow |
| `R` | 3 | player facing right | `S` | `$B` | switch box |
| `L` | 4 | player facing left | `+` | `$C` | potion (extra life) |
| `#` | 5 | wall | `D` | `$D` | teleporter |
| `:` | 6 | earth | `O` | `$E` | bubble |
| `*` | 7 | gem | `F` | `$F` | fire |

| Field | Bytes | Variable | Meaning |
| --- | ---: | --- | --- |
| `gems_needed` | 1 | GemsNeeded `$FD9A` | gems that open the exit |
| `gem_value` | 1 | GemValue `$FD9B` | points a gem |
| `start` | 2 | PlayerIndex `$FD9C` | the player's cell, 30 x row + column (the file adds row and column as a comment) |
| `gems_digits` | 2 | GemsNeededDigits `$FD9E` | gems_needed as the two HUD digits, tens first |
| `earth_graphic` | 2 | EarthGraphic `$FDA0` | the graphic of cell 6, by name (GfxFallingEarth `$A450` makes earth fall: SetEarthFalls `$FB81`) |
| `wall_graphic` | 2 | WallGraphic `$FDA2` | the graphic of cell 5, by name |
| `door_colour` | 1 | DoorColour `$FDA4` | the attribute CaveSetup writes into GfxExit `$9B08` |
| `boulder_colour` | 1 | BoulderColour `$FDA5` | into GfxBoulder `$9B2C` |
| `wall1_colour` | 1 | Wall1Colour `$FDA6` | into GfxWall1 `$9CB8` |
| `earth_colour` | 1 | EarthColour `$FDA7` | into GfxEarth `$9B50` |

SetGraphicColour `$9305` writes a colour into the four attributes of a graphic as bright, plain, plain, bright (top
left, top right, bottom right, bottom left). The two graphic words are names of the source's labels: the entry is an
`@res caves/caves.bin include`, the build writes `caves.inc` (DB lines, a DW line per graphic word, kit/resinc.py), so
a graphic that moves is followed. A `$hex` number is accepted too.
