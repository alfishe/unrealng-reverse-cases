# Variant zyxslbt

From `work/candidates/owner-boots_zyx/zyxslbt.scl`, file `boot` (B, start 180, length 180, 33 sectors). Written by `tools/variants.py extract`; built by `tools/build.sh --variant zyxslbt`.

- The music piece at `$EB50`, 9 sectors; the menu calls `$EB53` at the start, then `$EB50` (one more CALL: every later code address moves by 3) and `$EB56` every frame.
- The menu's stack at `$BF68` (MenuStack `$FCBC` in the original).
- The clean screen copy at `$C000` (ScreenCopy `$E000` in the original).
- The OR mask from a screen address to the copy at `$80` (ScreenCopyHigh `$E0` in the original).
- `graphics/font.png` differs from the original.
- `graphics/logo.png` differs from the original.
- `graphics/rhombus.png` differs from the original.
- `spare/basic-tail.bin` differs from the original.
- `music/piece.bin` differs from the original.
