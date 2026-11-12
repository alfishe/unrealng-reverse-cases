# Variant zyxfp4bt

From `work/candidates/owner-boots_zyx/zyxfp4bt.scl`, file `ZYXFP4bt` (B, start 180, length 180, 35 sectors). Written by `tools/variants.py extract`; built by `tools/build.sh --variant zyxfp4bt`.

- The music piece at `$C780`, 11 sectors; the menu calls `$0052` at the start and `$C780` every frame.
- Code: reads the Kempston joystick: `IN A,($1F)` at Joystick `$68B9` in place of `LD A,$00` (`kempston` in variant.json, tools/variants.py CODE_SWITCHES).
- `graphics/logo.png` differs from the original.
- `graphics/rhombus.png` differs from the original.
- `spare/basic-tail.bin` differs from the original.
- `tables/corner-colours.txt` differs from the original.
- `tables/logo-attrs.txt` differs from the original.
- `tables/phase-order.txt` differs from the original.
- `music/piece.bin` differs from the original.
