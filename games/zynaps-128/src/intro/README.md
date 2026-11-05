# Block 1: the intro

Block 1 unpacked, `$6000`-`$E8D4` (35 029 bytes), assembled to the original's bytes; `tools/build.sh` then packs it
with `tools/hrust1.py` into sectors 2-57 of `ZYNAPS.B`. [docs/03-build-and-load.md](../../docs/03-build-and-load.md)
3.4.

| File | What |
| --- | --- |
| `block1.asm` | the top file (written from `intro.ann`): the constants, `INCLUDE "intro.asm"`, `SAVEBIN build/obj/block1.bin` |
| `intro.asm` | the intro's code (`$6000`-`$632C`: the copies to page 4 and `$8000`, the IM 2 tune, the pictures' row-by-row reveal, the options, the colour bars) and its resources by `INCBIN` |
| `intro.ann` | the annotations `intro.asm` is written from (`tools/part_mkasm.py`, `tools/mkasm_all.sh`) |
| `block1.hints` | the one packer choice `tools/hrust1.py` cannot derive (block 1, 12 105 bytes in: a 3-byte match at distance 5803) |

The resources, built before the block (`-Ibuild`): `sound/engine-c968.bin`, `sound/engine-data-de48.bin` and
`sound/starkos-8000.bin` (`tools/build_sound.sh` from `src/sound/` and `src/res/sound/`, `src/res/music/`), and
`screens/{title,options,hewson}.scr` (`tools/res_formats.py` from `src/res/screens/*.png`).
