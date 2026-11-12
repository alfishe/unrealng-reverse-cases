# Variant zyxboot-10

From `work/candidates/owner-boots_zyx/zyxboot.scl`, file `ZYX-10` (B, start 180, length 180, 38 sectors). Written by `tools/variants.py extract`; built by `tools/build.sh --variant zyxboot-10`.

- The music piece at `$BFFE`, 14 sectors; the menu calls `$BFFE` at the start and `$C003` every frame.
- Code: has no joystick block: the 22 bytes at Joystick `$68B9` are zeros (NOPs) (`no-joystick` in variant.json, tools/variants.py CODE_SWITCHES).
- `spare/basic-tail.bin` differs from the original.
- `music/piece.bin` differs from the original.
