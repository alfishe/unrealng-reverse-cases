# Nether Earth GS resources

The editable data `tools/build.sh` builds the three media from, together with the sources in `src/`. Each folder is
turned into the files' exact bytes by its converter, writing `build/res/` (or `build/game/` for the game image);
the built SCL, TRD and TAP are compared with the originals byte for byte, so an edit here shows at once as a
difference.

| Folder | What | Converter | Built |
| --- | --- | --- | --- |
| [`game/`](game/README.md) | the game image's resources: font, 89 sprites, view edges, level, Nether Earth's (silent) menu tune, order names (`src/game/`) | `tools/res_formats.py` (`tools/build_game.sh`) | `build/game/res/` |
| [`music/`](music/README.md) | the General Sound module `desert-dream.mod` (ProTracker) | `tools/res_media.py` | `build/res/music/neart002-006.bin` |
| [`sfx/`](sfx/README.md) | the 14 GS effect samples as WAV | `tools/res_media.py` | `build/res/sfx/neart007-020.bin, neart023.bin` |
| [`screen/`](screen/README.md) | the loading screen `loading.png` (lossless) | `tools/res_media.py` | `build/res/screen/neart000.bin` |
| [`text/`](text/README.md) | the BASIC listings, the TRD's sector 9 text and label, the TRD extras' texts (UTF-8) | `tools/res_media.py`, `tools/basic_tok.py`, `tools/mktrd.py` | `build/res/text/*.bin` |
| [`trd/`](trd/README.md) | the TRD extras' data: the boot's sector tail and 64-column font, Neart481's packed blocks, Neart482's blocks | `tools/build_trd_extras.sh` (`hrum.py`, `trd_lz.py`) | `build/trd/` |
| [`media/`](media/README.md) | the TRD's leftover bytes no program reads (sector tails, free sectors) | bytes, placed by `tools/mktrd.py` | — |

`python3 tools/res_media.py check` builds every resource of `music/`, `sfx/`, `screen/` and `text/` into a scratch
folder and compares it with the original files; `tools/build_loaders.sh` does the same against `orig/`.
