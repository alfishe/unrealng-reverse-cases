# The tape loader (Hood, 2017)

Hood's conversion of the disk version to a standard-speed tape: his BASIC, the disk loader with 91 bytes changed
(`neart0222`) and a reworked driver. Each source is the file's own source (not a patch of `src/disk/`) and assembles
to its exact bytes (`tools/build_loaders.sh`, compared with the TAP's blocks). docs/03-build-and-load.md 3.3,
docs/09-sound.md 9.7.

| Source | TAP block | Bytes | At | What |
| --- | --- | --- | --- | --- |
| `basic.asm` | `NetherE GS` (Program, LINE 10) | 961 | BASIC | the music ON / OFF menu, then `LOAD "" CODE` of every file and a `RANDOMIZE USR` into the loader after each; listing `src/res/text/tape-basic.txt` |
| `loader.asm` | `neart0222` | 865 | `$61A8` | the disk loader's layout, entered per file (`SendModule1-5`, `SendFx1-14b`, `PageBank0`, `StartGame`); every command waits for the card. The changed bytes and the dead ones are commented |
| `driver.asm` | `neart021` (param 2 = 0) | 271 | `$C000`, bank 6 | the disk driver's id list, a new play routine: select (`#2E`), note (`#40`), play (`#39`), each command waited for |

The USR addresses in the BASIC (25022 ... 25561) are the loader's labels; `src/tape/loader.asm` names each one.
Build: `sjasmplus --nologo -Ibuild src/tape/basic.asm` (after `tools/res_media.py build --out build/res`);
outputs `build/tape/{basic,loader,driver}.bin`. The game on tape (`neart001`, Hood's build) comes from
`build/game/neart001-tap.bin`.
