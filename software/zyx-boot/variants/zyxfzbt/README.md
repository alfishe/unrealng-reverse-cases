# Variant zyxfzbt

From `work/candidates/owner-boots_zyx/zyxfzbt.scl`, file `boot` (B, start 180, length 180, 39 sectors). Written by `tools/variants.py extract`; built by `tools/build.sh --variant zyxfzbt`.

- The music piece at `$C000`, 15 sectors; the menu calls `$C000` at the start and `$C006` every frame.
- Code: starts the music after DrawScreen (the two calls at `$61E7` swapped) (`music-after-screen` in variant.json, tools/variants.py CODE_SWITCHES).
- `graphics/rhombus.png` differs from the original.
- `tables/rhombus-columns.txt` differs from the original.
- `texts/menu-help.txt` differs from the original.
- `texts/no-files.txt` differs from the original.
- `music/piece.bin` differs from the original.
- `basic.bin` differs from the original.
