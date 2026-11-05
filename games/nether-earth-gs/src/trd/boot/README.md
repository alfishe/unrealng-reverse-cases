# src/trd/boot: the TRD's boot file

`boot` runs first on the TRD (TR-DOS starts the file named boot). Its BASIC line 1 holds a short loader in a REM;
it reads the file's HRUM block to `$61A8` and calls it; the block unpacks TRON's catalogue menu "Work Loader v1.2"
(1999), which lists the disk's BASIC files and RUNs the one chosen by writing its name into line 3's
`RUN "        "`.

| File | What |
| --- | --- |
| `boot.asm` | the whole file, 13 sectors: the BASIC program (lines 1-3, the REM code `Boot`), the autostart mark, the sector's old tail, the HRUM block (`HRUM_SFX`), HRUM's credit, the `$CD` filler |
| `hrum35.asm` | the HRUM 3.5 self-extractor (macro `HRUM_SFX`), copied from ../advanced-nether-earth/src/sfx/hrum35.asm |
| `boot-menu.asm`, `menu.asm` | the menu's main part, `$61A8-$68CB` (written by `tools/trd_mkasm.py` from `menu.ann`) |
| `boot-print64.asm`, `print64.asm` | the 64-column printer the menu copies to `$8156` (`$8156-$8A35`, from `print64.ann`) |
| `menu.ann`, `print64.ann` | the annotations: the single source of the two parts' `.asm` (edit these, then run `trd_mkasm.py --install`) |

The build (`tools/build_trd_extras.sh`): `boot-menu.asm` and `boot-print64.asm` assemble the two parts; joined they
are the 4100 bytes the block unpacks (`build/trd/obj/menu.bin`); `tools/hrum.py pack --prefer 2348:264` packs them
into the original stream (one tie the packer model breaks the other way: `work/stage2/NOTES-trd.md`); `boot.asm`
takes the stream and the 5 tail bytes.

**The HRUM block.** `HRUM_SFX 0, 1, $4000, $61A8, 4100, ..., 2685, ..., 0, 1, 0`: DI; the caller's SP kept in the
depacker's `LD SP` (`$6233`); the 119-byte depacker copied to `$4000` (the cleared screen) and entered by RET; the
2685-byte stream moved up to end at `$71AB`; unpacked from `$61A8`; the last 5 bytes (`60 60 60 00 00`) from the
depacker's tail; EI; RET to `Boot`, which jumps to the menu's `Start`. The depacker reads exactly the stream: the
credit after it, the filler and the 8 extra sectors `Boot` reads (20 in all: the block's 12, then the first sector
of `neart GS` and 7 of `neart000`) are never used, and the unpacked menu overwrites them.

**The menu** (`menu.asm`): `Start` sets the system variables, copies the printer to `$8156`, reads the catalogue
(9 sectors of track 0 to `$EA60`), keeps the BASIC files' names (`CatalogueFilter`), sorts a copy by the first
character (`SortCatalogue`), lists them in four columns of 24 and waits in `KeyLoop`: 0-9, Q/A/O/P or the cursor
keys, SPACE/ENTER (`Run`), EDIT (read again), SS+CS (the other order). `Run` copies the name to `RunName` (`$5DDD`,
in boot's line 3) and returns to BASIC. `FdcSectors` (`$6752-$682B`) is an FDC sector read/write routine no call
reaches. **The printer** (`print64.asm`): 4-pixel characters through channel S (`ChannelOut`), the font as a
resource; scrolls, a line input and string printers of the same package no call reaches, and 59 bytes of an older
layout (`LeftoverCode`).

**Regenerating the menu sources** (skoolkit's venv, see `tools/trd_mkasm.py`):

```sh
python3 tools/trd_mkasm.py --image build/trd/obj/boot-menu.bin --org '$61A8' --ann src/trd/boot/menu.ann \
  --top boot-menu --dest src/trd/boot --res src/res/trd --l1 work/stage2/trd/rA/l1.json \
  --built boot/texts.bin=trd/text/trd-boot-menu.bin --save build/trd/obj/boot-menu.bin --install
python3 tools/trd_mkasm.py --image build/trd/obj/boot-print64.bin --org '$8156' --ann src/trd/boot/print64.ann \
  --top boot-print64 --dest src/trd/boot --res src/res/trd --l1 work/stage2/trd/rA/l1.json \
  --save build/trd/obj/boot-print64.bin --install
```

`work/stage2/trd/rA/l1.json` is the analysis recording of the menu (the menu shown, cursor keys, ENTER); without it
the code is what mkgame's walk from the `.ann`'s entries reaches.
