# The disk loader (TR-DOS, Tron 2002)

The three files the SCL and the TRD start the game with; each source assembles to the file's exact bytes
(`tools/build_loaders.sh`, compared with the SCL's files). docs/03-build-and-load.md 3.2, docs/09-sound.md 9.2-9.4.

| Source | File | Bytes | At | What |
| --- | --- | --- | --- | --- |
| `basic.asm` | `neart GS` (B) | 67 + 4 | BASIC | `CLEAR 24999`, TR-DOS loads `neart022`, `RANDOMIZE USR 25e3`; the listing is `src/res/text/disk-basic.txt`, the source adds TR-DOS's autostart mark `$80 $AA` + line 10 |
| `loader.asm` | `neart022` (C) | 865 | `$61A8` | loads the screen, uploads the module and the 14 effects to the GS, the driver to bank 1, the game; starts the module; `JP $A600`. Its three bugs are commented at the top |
| `driver.asm` | `neart021` (C) | 248 | `$C000`, bank 1 | the game's sound ids to GS effects |
| `gs.inc` | | | | the GS ports and the commands both loaders and drivers use |

Build: `sjasmplus --nologo -Ibuild src/disk/basic.asm` (from the case folder, after `tools/res_media.py build
--out build/res`, which writes the tokenized listing); `loader.asm` and `driver.asm` need no include path. Outputs:
`build/disk/{basic,loader,driver}.bin`. The SCL's "neart GS" sector is `basic.bin` + zeros; the TRD's holds
leftover bytes after it (`src/res/media/`).
