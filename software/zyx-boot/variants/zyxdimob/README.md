# Variant zyxdimob

From `work/candidates/owner-boots_zyx/zyxdimob.scl`, file `boot1` (B, start 201, length 201, 34 sectors). Written by `tools/variants.py extract`; built by `tools/build.sh --variant zyxdimob`.

- The music piece at `$E505`, 10 sectors; the menu calls `$E505` every frame and never an init.
- The menu's stack at `$BF68` (MenuStack `$FCBC` in the original).
- The clean screen copy at `$C000` (ScreenCopy `$E000` in the original).
- The OR mask from a screen address to the copy at `$80` (ScreenCopyHigh `$E0` in the original).
- Code: reads the Kempston joystick: `IN A,($1F)` at Joystick `$68B9` in place of `LD A,$00` (`kempston` in variant.json, src/main/main.ann @variant Kempston).
- Code: never calls the music's init: the 6 bytes of the two CALLs at `$61E7` are zeros (family B layout) (`no-music-init` in variant.json, tools/variants.py CODE_SWITCHES).
- `graphics/logo.png` differs from the original.
- `graphics/rhombus.png` differs from the original.
- `graphics/twinkle.png` differs from the original.
- `texts/menu-help.txt` differs from the original.
- `music/piece.bin` differs from the original.
- `basic.bin` differs from the original.
