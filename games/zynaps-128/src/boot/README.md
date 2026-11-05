# boot.B: the TRD's boot

`boot.B` (988 bytes of BASIC, 4 sectors at track 9 sector 9 of the TRD; the SCL has no boot), assembled to the
original's bytes: `bootb.asm` (the top file) + `boot.asm`, written from `boot.ann` by `tools/part_mkasm.py`
(`tools/mkasm_all.sh`). Built: `build/obj/boot-5d3b.bin`; `src/media/trd.txt` adds the zeros to the end of its last
sector. [docs/03-build-and-load.md](../../docs/03-build-and-load.md) 3.1.

A generic TR-DOS boot, no author mark: line 0 is a REM with the code, line 1 calls it, then runs the picked file
through TR-DOS (`RANDOMIZE USR VAL "15619": REM : RUN "name"`). The code lists the disk's BASIC files in a frame
titled with the disk's label, in a bold copy of the ROM font, and scrolls the list smoothly through an unrolled LDI
blitter it builds at `$8CA0`.
