# ZYNAPS.B's loader: the BASIC with the REM loader, and the Hrust 1 depacker

The first two sectors of `ZYNAPS.B`, each source assembling to the original's bytes (`tools/build.sh`, compared with
the TRD's). [docs/03-build-and-load.md](../../docs/03-build-and-load.md) 3.2-3.3.

| Source | Annotations | Built | At | What |
| --- | --- | --- | --- | --- |
| `zynapsb.asm` + `loader.asm` | `loader.ann` | `build/obj/zynapsb-basic.bin` (172 bytes) | `$5D3B` (PROG) | line 0: a REM holding the loader (`$5D40`); line 1: `CLEAR VAL "24575": RANDOMIZE USR VAL "23872"`; TR-DOS's autostart mark `$80 $AA` + line 1 |
| `depacker.asm` + `depack.asm` | `depacker.ann` | `build/obj/depacker.bin` (256 bytes) | `$5B00` | the Hrust 1 depacker that unpacks both blocks in place at `$6000` |

The `.asm` files are written from the `.ann` files by `kit/mkgame.py --image` (all parts: `tools/mkasm_all.sh`): edit
the `.ann`, not the `.asm`. The bytes after the autostart mark in sector 0 are `src/res/media/`; the format the
depacker reads, and the packer that writes it, are `tools/hrust1.py`.
