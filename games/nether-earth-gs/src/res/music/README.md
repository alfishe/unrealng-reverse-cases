# The module

`desert-dream.mod`: the General Sound's in-game music, a 4-channel ProTracker module (`M.K.`, 138 070 bytes), song
title "desert dream". The loader uploads it with `#30` (load module) and plays it with `#31` (docs/09-sound.md 9.1).

On the media the module is cut into five files of at most 32 768 bytes, each loaded to `$8000` and streamed to the
card before the next one (the stream stays open between them):

| File | Bytes of the module |
| --- | --- |
| `neart002` | 0-32 767 |
| `neart003` | 32 768-65 535 |
| `neart004` | 65 536-98 303 |
| `neart005` | 98 304-131 071 |
| `neart006` | 131 072-138 069 (6 998) |

`python3 tools/res_media.py build --out build/res` writes `build/res/music/neart002.bin ... neart006.bin`. The
`.mod` is the five files joined, unchanged: it opens in any MOD tracker or player.
