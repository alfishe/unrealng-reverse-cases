# Variant zyxboot-09

From `work/candidates/owner-boots_zyx/zyxboot.scl`, file `ZYX-9` (B, start 306, length 306, 84 sectors). Built by `tools/build.sh --variant zyxboot-09`: **identical**.

- Its loader (`basic.txt`, the BASIC as text, `tools/res_basic.py`) reads 2 sectors of BASIC, then: `$61A8` x 15, `$A600` x 8, `$EB50` x 9, `$C350` x 21.
- The music piece at `$EB50`, 9 sectors, init `$EB53`; play `$EB56`, start `$EB50` (layout B).
- Code of its own, described in `parts/pictures.ann` (built by kit/mkgame.py from `parts/pictures.json`, placed at `$C350`).
- `files/tail.bin`: the file's sectors after the last piece, kept as its bytes.
- Files that differ from the original: `basic.txt`, `files/tail.bin`, `graphics/rle-picture-1.png`, `graphics/rle-picture-2.png`, `music/fuxoft.txt`, `music/player.txt`.
- The tune: the same as zyxisl's (Fuxoft's player; notes match "Feud" by Frantisek Fuka).
- Layout B and the same loader and pictures as zyxisl; 29 more sectors of the file (`files/tail.bin`) are never read by the loader.
