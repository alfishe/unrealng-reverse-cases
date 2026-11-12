# Variant zyxhsbt

From `work/candidates/owner-boots_zyx/zyxhsbt.scl`, file `boot` (B, start 180, length 180, 38 sectors). Written by `tools/variants.py extract`; built by `tools/build.sh --variant zyxhsbt`.

- The music piece at `$C030`, 14 sectors; the menu calls `$C030` at the start and `$C036` every frame.
- Code: reads the Kempston joystick: `IN A,($1F)` at Joystick `$68B9` in place of `LD A,$00` (`kempston` in variant.json, tools/variants.py CODE_SWITCHES).
- Code: tests the glint's half with `ADD A,$01` at GlintHalf `$6D1F` (the original `AND $01`) (`glint-add` in variant.json, tools/variants.py CODE_SWITCHES).
- `graphics/logo.png` differs from the original.
- `graphics/rhombus.png` differs from the original.
- `spare/basic-tail.bin` differs from the original.
- `tables/logo-attrs.txt` differs from the original.
- `music/piece.bin` differs from the original.
