# Resources

| Folder | What | Built by | Into |
| --- | --- | --- | --- |
| `screens/` | the intro's three pictures, PNG | `tools/res_formats.py build` | `build/screens/*.scr` |
| `sound/`, `music/` | the page-4 engine's data and the STarKos song SK10, as text | `tools/build_sound.sh` | `build/sound/` |
| `game/` | the 48K game as it runs (`game-6800.bin`), binary until its annotations | used as it is (`src/game/setup.asm`) | |
| `media/` | the disk's own bytes: the label, the leftovers after the BASIC in `ZYNAPS.B`'s first sector | `src/media/*.txt` | the SCL, the TRD |

Each folder has its README.
