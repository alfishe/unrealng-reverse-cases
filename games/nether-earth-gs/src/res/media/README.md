# The TRD's leftover bytes

The bytes of the TRD that no program reads: the ends of files' last sectors past their length, and three free
sectors. TR-DOS writes whole sectors from memory, so a file's last sector ends with whatever was in the buffer after
the file; the copier that wrote this disk (ZX Spectrum Navigator 1.10, sector 9's text) left them. They are kept
as bytes so the TRD rebuilds exactly; `src/media/trd.txt` places them (the SCL has zeros in every tail but
"neart GS"'s autostart mark). Readable parts are quoted below; the bytes are mostly binary, so there is no text copy.

| File | Where (TRD) | Bytes | What it is |
| --- | --- | --- | --- |
| `trd-tail-neart-gs.bin` | "neart GS", bytes 71-255 of its sector | 185 | the BASIC memory past the program when it was saved: the end of the command line, most likely `SAVE "neart GS" LINE 10` (its first 3 bytes lie under the autostart mark; what is left: `eart GS" LINE 10`, `$0D`, `$80`), then a workspace line `15616` with its number form (`USR 15616`, TR-DOS's entry `$3D00`), the calculator's numbers, zeros |
| `trd-tail-neart001.bin` | neart001, sector 154 bytes 112-255 | 144 | Z80 code (`DI`, `OUT ($FE)`, writes to `$5CB4` P-RAMT, `$5C36` CHARS = `$3C00`, `$5F00`): an older loader's or start-up's code; not identified |
| `trd-tail-neart021.bin` | neart021, bytes 248-255 | 8 | `43 00 80 00 80 80 01 15`: the end of a TR-DOS catalogue entry (`neart002`, `C`, `$8000`, 32 768 bytes, 128 sectors, sector 1 track 21): the same catalogue as below |
| `trd-tail-neart022.bin` | neart022, sector 3 bytes 97-255 | 159 | a TR-DOS catalogue fragment of the author's work disk: `TS6.0 B`, `sts6.0 C`, `pc B`, `bd B`, `loader S`, `neart000 C`, `128-48 S`, `nameload S`, `nameloa1 S`, `neart002 C` (the first entry's name cut, its start, length, sector count and place follow each name) |
| `trd-free-1943.bin` | free sectors 1943-1945 | 768 | 1943: `$5B` bytes of tape-loader-like code (an edge routine with `LD A,R`, `OUT ($FE)`; its first 34 bytes equal neart001 at `$FD32`, an older dump), zeros, `$FD` fill; 1944: `$FD` fill; 1945: system variables and ROM-font-like bytes |

The rest of the free area is not here: `src/media/trd.txt` fills sectors 1941-1942 from an older Neart482 and
1946-2116 with a whole copy of Neart481 (their catalogue entry survives as entry 28, under the end mark).
