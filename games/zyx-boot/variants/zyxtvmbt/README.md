# Variant zyxtvmbt

From `work/candidates/owner-boots_zyx/zyxtvmbt.scl`, file `boot` (B, start 180, length 180, 32 sectors). Built by `tools/build.sh --variant zyxtvmbt`: **identical**.

- Its loader (the original's BASIC with the variant's music address and count) reads 1 sector of BASIC, then: `$61A8` x 15, `$A600` x 8, `$C000` x 8.
- The music piece at `$C000`, 10 sectors, init `$C000`; play `$C00E`.
- Code: reads the catalogue through its own ReadCatalogueSafe at `$6FE0` (an error trap on ERR_SP, then the drive stopped through the TR-DOS ROM), from Start and from SPACE; inits the music before that read instead of before DrawScreen; calls the music before it loads IY in the interrupt (`catalogue-safe`, tools/variants.py CODE_SWITCHES).
- Code of its own, described in `parts/safe.ann` (built by kit/mkgame.py from `parts/safe.json`, placed at `$6FE0`).
- Files that differ from the original: `graphics/rhombus.png`, `music/player.txt`, `music/stc.txt`, `spare/basic-tail.bin`.
- The tune: compiled Sound Tracker ("MARK 800", STC, collection XMX2 by the music index) in the music piece at `$C000`, kept as text (`music/`, kind stc1: head, the shared stc player, the stop's tail, stc.txt). The build packs it with tools/lzpack.py (byte-exact, no hints) behind the depacker head `parts/depack.ann`; the init depacks in place through the printer buffer `$5B8D` and leaves through `JP $0052`, the 48K ROM's RET.
- The BASIC still reads 10 sectors of music (the original's count with the music at `$C000`); the file holds 8, so the read takes 2 sectors past the file's end.
- ReadCatalogueSafe (`parts/safe.ann`, at `$6FE0` in the menu's spare bytes) traps disk errors through ERR_SP and stops the drive after reading; Start and the SPACE key call it (code switch `catalogue-safe`).
