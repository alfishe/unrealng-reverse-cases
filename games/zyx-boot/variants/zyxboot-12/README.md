# Variant zyxboot-12

From `work/candidates/owner-boots_zyx/zyxboot.scl`, file `ZYX-12` (B, start 180, length 180, 36 sectors). Written by `tools/variants.py extract`; built by `tools/build.sh --variant zyxboot-12`.

- The music piece at `$C000`, 12 sectors; the menu calls `$C003` at the start and `$C000` every frame.
- Code: has no joystick block: the 22 bytes at Joystick `$68B9` are zeros (NOPs) (`no-joystick` in variant.json, tools/variants.py CODE_SWITCHES).
- `spare/basic-tail.bin` differs from the original.
- `music/piece.bin` differs from the original.
