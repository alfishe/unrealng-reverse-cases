# The media layouts

Every byte of the three media, from the built files and the resources:

| Layout | Writer | Medium | Compared with |
| --- | --- | --- | --- |
| `scl.txt` | `tools/mkscl.py` | `build/NE_GS_TZ.SCL` | the SCL inside `orig/NE_GS_TZ.zip` |
| `trd.txt` | `tools/mktrd.py` | `build/Nether Earth (1987)(...)[h 2002 Tron Z].trd` | the TRD in `orig/` |
| `tap.txt` | `tools/mktap.py` (kit/tap.py's blocks) | `build/Nether Earth (1987)(...)[h 2017 Hood, Tron Z].tap` | the TAP in `orig/` |

`tools/build.sh` writes and compares all three. Each tool's docstring describes the lines. Paths are relative to the
case; `$GAME_DIR` (the game image, `build/game`) and `$TRD_DIR` (the TRD's own files, `build/trd`) are fixed by
`tools/build.sh`; a test may point them at stubs (`GAME_DIR=... python3 tools/mkscl.py src/media/scl.txt OUT`).

- **SCL**: 25 files ("neart GS", neart000-023); every byte after a file's length is zero.
- **TRD**: "boot", the same 25 files, Neart481, Neart482 from track 1; the non-zero sector tails, the leftover
  catalogue entry 28, sector 9 (the copier's text, the label) and the free sectors' older copies
  (`src/res/media/README.md`).
- **TAP**: 25 header + data pairs in the order Hood's BASIC loads them; the headers are the ROM's (`neart021`'s
  param 2 is 0, all other CODE headers 32 768; the BASIC's param 2 is its length).
