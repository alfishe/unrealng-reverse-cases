# Variant zyxgambt

From `work/candidates/owner-boots_zyx/zyxgambt.scl`, file `boot` (B, start 180, length 180, 35 sectors). Written by `tools/variants.py extract`; built by `tools/build.sh --variant zyxgambt`.

- The music piece at `$EB50`, 11 sectors; the menu calls `$EB53` at the start, then `$EB50` (one more CALL: every later code address moves by 3) and `$EB56` every frame.
- The menu's stack at `$BF68` (MenuStack `$FCBC` in the original).
- The clean screen copy at `$C000` (ScreenCopy `$E000` in the original).
- The OR mask from a screen address to the copy at `$80` (ScreenCopyHigh `$E0` in the original).
- The glint's outer cells' attribute at `$41` (GlintEdge `$02` in the original).
- The glint's middle cell's attribute at `$43` (GlintCentre `$42` in the original).
- `graphics/font.png` differs from the original.
- `graphics/logo.png` differs from the original.
- `graphics/twinkle.png` differs from the original.
- `spare/basic-tail.bin` differs from the original.
- `tables/corner-colours.txt` differs from the original.
- `tables/logo-attrs.txt` differs from the original.
- `texts/menu-help.txt` differs from the original.
- `music/piece.bin` differs from the original.
