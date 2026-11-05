# disk

**What it is.** The texts on the disk outside the game and the menu: the label, the catalogue, the BASIC line, the
credits that are never shown and the packer's signature. All English.

| Where | Text | Source |
| --- | --- | --- |
| the TRD label (sector 9, `$F5`) | `AMD4ever` | [`src/media/trd.txt`](../../src/media/trd.txt) |
| the catalogue | `ZYNAP_GS` (BASIC, 65 bytes), then `zynapsGS` types `1`-`8`: covers for the data run, start = length = the type's digit | `src/media/trd.txt` |
| `ZYNAP_GS` line 1 | `RANDOMIZE USR VAL "23882"`, the boot loader as the line's tail | [`src/disk/basic.asm`](../../src/disk/basic.asm) |
| the REM after the boot loader (never listed) | `MIKE BLUM (C)1997` | `src/disk/basic.asm` |
| Trush block 0, after the fade code (never printed) | ` PROGRAM BY MIKE BLUM ` | [`src/disk/screen/screen.asm`](../../src/disk/screen/screen.asm) |
| the head of each of the 38 Trush blocks | `COMPRESSOR BY ALEXANDER TRUSH ODESSA` | [`src/disk/trush.asm`](../../src/disk/trush.asm) |

"AMD4ever" reads "AMD for ever", the processor maker.
