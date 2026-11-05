# Resources

| Folder | What | Built by | Into |
| --- | --- | --- | --- |
| `screens/` | the intro's three pictures, PNG | `tools/res_formats.py build` | `build/screens/*.scr` |
| `sound/`, `music/` | the page-4 engine's data and the STarKos song SK10, as text | `tools/build_sound.sh` | `build/sound/` |
| `gfx/`, `fonts/` | the game's tiles, sprites, pod and logo glyphs, PNG | `tools/res_formats.py build` (`res_gfx.py`, `res_font.py`) | `build/res/` |
| `levels/` | the game's level data as text | `tools/res_formats.py build` (`res_levels.py`) | `build/res/` |
| `text/` | the game's messages and high-score table as text | `tools/res_formats.py build` (`res_text.py`) | `build/res/` |
| `effects/` | the 48K beeper effects (played on a 48K only) as text | `tools/res_formats.py build` (`res_effects.py`) | `build/res/` |
| `music/titletune.tune.txt` | the game's title tune (silent on a 128K) as text | `tools/res_formats.py build` (`res_tune.py`) | `build/res/` |
| `media/` | the disk's own bytes: the label, the leftovers after the BASIC in `ZYNAPS.B`'s first sector | `src/media/*.txt` | the SCL, the TRD |

Each folder has its README.
