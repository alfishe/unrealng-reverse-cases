# Resources

Every resource out of the code, in an editable format; `tools/res_formats.py build` turns them back into the bytes
the source INCBINs, `tools/res_formats.py check` proves the round trip.

| File | What | Format | Entry |
| --- | --- | --- | --- |
| `maps/exolon-map.png` | The full map: the 125 screens' play areas (rows 0-21) as BuildScreen `$8494` draws them, one row a zone of 25 screens, stars from one chained seed | PNG, 6400 x 880, 1x | none: drawn from the image, not INCBINed |

`maps/` is not a source input: `tools/fig_map.py map` draws it from `work/mkgame/original.bin` alone (ScreenTable
`$C7F4`, ElementTable `$852E`, PrintString `$AF2B`, DrawStars `$A2D5`, ForceFieldDraw `$AB97`), `res_formats.py
build` leaves it out of `build/res`, and `res_formats.py check` regenerates it and compares the pixels.
`tools/fig_map.py verify` checked the drawing against the game's own build of every screen (docs/01-game-design.md).
