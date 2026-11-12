# Variant zyxarbt

From `work/candidates/owner-boots_zyx/zyxarbt.scl`, file `NO load` (B, start 180, length 180, 48 sectors). Written by `tools/variants.py extract`; built by `tools/build.sh --variant zyxarbt`.

- The music piece at `$C0B7`, 24 sectors; the menu calls `$C0B7` at the start and `$C0BD` every frame.
- The menu's stack at `$BF68` (MenuStack `$FCBC` in the original).
- `spare/basic-tail.bin` differs from the original.
- `music/piece.bin` differs from the original.
- `files/00.boot.B`: another file of the disk, kept as its bytes.
- `files/01.arb.scr.C`: another file of the disk, kept as its bytes.
