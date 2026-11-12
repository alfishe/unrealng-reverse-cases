# Variant zyxboot-04

From `work/candidates/owner-boots_zyx/zyxboot.scl`, file `ZYX-4` (B, start 180, length 180, 33 sectors). Written by `tools/variants.py extract`; built by `tools/build.sh --variant zyxboot-04`.

- The music piece at `$EB50`, 10 sectors; the menu calls `$EB53` at the start, then `$EB50` (one more CALL: every later code address moves by 3) and `$EB56` every frame.
- The menu's stack at `$BF68` (MenuStack `$FCBC` in the original).
- The clean screen copy at `$C000` (ScreenCopy `$E000` in the original).
- The OR mask from a screen address to the copy at `$80` (ScreenCopyHigh `$E0` in the original).
- Code: reads the Kempston joystick: `IN A,($1F)` at Joystick `$68B9` in place of `LD A,$00` (`kempston` in variant.json, tools/variants.py CODE_SWITCHES).
- `spare/basic-tail.bin` differs from the original.
- `music/piece.bin` differs from the original.
