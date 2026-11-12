# Variant zyxsiriu

From `work/candidates/owner-boots_zyx/zyxsiriu.scl`, file `boot` (B, start 180, length 180, 38 sectors). Written by `tools/variants.py extract`; built by `tools/build.sh --variant zyxsiriu`.

- The music piece at `$BFFE`, 14 sectors; the menu calls `$BFFE` at the start and `$C003` every frame.
- Code: has no joystick block: the 22 bytes at Joystick `$68B9` are zeros (NOPs) (`no-joystick` in variant.json, src/main/main.ann @variant NoJoystick).
- `spare/basic-tail.bin` differs from the original.
- `tables/keys.txt` differs from the original.
- `texts/menu-help.txt` differs from the original.
- `music/piece.bin` differs from the original.
