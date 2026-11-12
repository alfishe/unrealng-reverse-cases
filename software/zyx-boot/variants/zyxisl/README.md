# Variant zyxisl

From `work/candidates/owner-boots_zyx/zyxisl.scl`, file `boot` (B, start 306, length 306, 55 sectors). Built by `tools/build.sh --variant zyxisl`: **identical**.

- Its loader (`basic.txt`, the BASIC as text, `tools/res_basic.py`) reads 2 sectors of BASIC, then: `$61A8` x 15, `$A600` x 8, `$EB50` x 9, `$C350` x 21.
- The music piece at `$EB50`, 9 sectors, init `$EB53`; play `$EB56`, start `$EB50` (layout B).
- Code of its own, described in `parts/pictures.ann` (built by kit/mkgame.py from `parts/pictures.json`, placed at `$C350`).
- Files that differ from the original: `basic.txt`, `graphics/rle-picture-1.png`, `graphics/rle-picture-2.png`, `music/fuxoft.txt`, `music/player.txt`.
- The tune: Fuxoft's player; the music index matches its notes to "Feud" by Frantisek Fuka ("Tune 8").
- Layout B (plain: the NOTES' "Start changed" was wrong). Before the menu, `parts/pictures.ann` unpacks two RLE screens (`$9D` escapes, unpackers at `$C350` and `$CD75`) and waits for a key after each.
