# Variant zyxalex

From `work/candidates/owner-boots_zyx/zyxalex.scl`, file `boot` (B, start 180, length 180, 34 sectors). Written by `tools/variants.py extract`; built by `tools/build.sh --variant zyxalex`.

- The music piece at `$F424`, 10 sectors; the menu calls `$F42A` at the start, then `$F42D` (one more CALL: every later code address moves by 3) and `$F427` every frame.
- The menu's stack at `$BF68` (MenuStack `$FCBC` in the original).
- The IM 2 vector table at `$DC00` (Im2Table `$FD00` in the original).
- The interrupt's JP at `$DBDB` (Im2Jump `$FCFC` in the original).
- The clean screen copy at `$C000` (ScreenCopy `$E000` in the original).
- The OR mask from a screen address to the copy at `$80` (ScreenCopyHigh `$E0` in the original).
- `graphics/font.png` differs from the original.
- `graphics/logo.png` differs from the original.
- `graphics/rhombus.png` differs from the original.
- `spare/basic-tail.bin` differs from the original.
- `spare/code-tail.bin` differs from the original.
- `tables/logo-attrs.txt` differs from the original.
- `music/piece.bin` differs from the original.
