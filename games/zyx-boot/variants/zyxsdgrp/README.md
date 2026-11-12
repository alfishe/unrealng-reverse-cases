# Variant zyxsdgrp

From `work/candidates/owner-boots_zyx/zyxsdgrp.scl`, file `B` (B, start 199, length 199, 34 sectors). Built by `tools/build.sh --variant zyxsdgrp`: **identical**.

- Its loader (`basic.txt`, the BASIC as text, `tools/res_basic.py`) reads 1 sector of BASIC, then: `$61A8` x 15, `$A5F8` x 9, `$EB48` x 9.
- The music piece at `$EB50`, 9 sectors, init `$EB53`; play `$EB56`, start `$EB50` (layout B).
- Code: colours the four corners plain green (`LD A,$04` in ColourCornerRows, which draws all four): no gradient, CornerColours is not read (`corners-plain`, tools/variants.py CODE_SWITCHES).
- Files that differ from the original: `basic.txt`, `graphics/font.png`, `graphics/logo.png`, `graphics/rhombus.png`, `music/fuxoft.txt`, `music/player.txt`, `tables/logo-attrs.txt`.
- The tune: "Where Time Dropped Dead" by Frantisek Fuka (Fuxoft's player; the music index matches its AY stream exactly).
- Layout B; the graphics piece is read one sector lower (`$A5F8`) and the music 8 bytes lower (`$EB48`), so the loader's pieces overlap the original's addresses by a few bytes.
