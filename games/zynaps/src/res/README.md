# Resources

Every resource out of the code, in an editable format; `tools/res_formats.py build` turns them back into the bytes
the source INCBINs, `tools/res_formats.py check` proves the round trip.

| File | What | Format | Entry |
| --- | --- | --- | --- |
| [`screens/loading.scr`](screens/README.md) | The loading screen | a 6912-byte screen; `tools/picy.py pack` makes the tape's picy block from it | the tape, block 6 |
| [`levels/levels.lev.txt`](levels/README.md) | The 12 levels: enemy paths, waves, kinds, level table, wave scripts, scenery scripts, groups, shapes | text | `$6800-$7E59` |
| [`effects/effects.fx.txt`](effects/README.md) | The 6 sound effects | text, one line an effect | `$7E5A-$7E89` |
| [`text/hiscores.hsc.txt`](text/README.md) | The high-score table on the tape | text | `$8261-$82A6` |
| [`text/messages.msg.txt`](text/README.md) | The 28 messages, with their print codes | UTF-8 text | `$82EE-$8515` |
| [`fonts/glyphs.font.png`](fonts/README.md) | The game's 54 glyphs (print codes `$80-$B5`): the ZYNAPS logo and the HEWSON name | PNG, 8 x 8 cells | `$B54F-$B6FE` |
| [`fonts/romleftover.font.png`](fonts/README.md) | What the tape left of the ROM font at the top of memory, used as work cells | PNG | `$FFD4-$FFFE` minus the switch |
| [`gfx/tiles.gfx.png`](gfx/README.md) | The 256 scenery tiles (copied to `$5C00`) | indexed PNG | `$BC00-$C3FF` |
| [`gfx/wave-cells.gfx.png`](gfx/README.md) | The cells of the wave sprites (copied to `$6400`) | indexed PNG | `$C400-$C7FF` |
| [`gfx/sprites.gfx.png`](gfx/README.md) | The ship, the sight, the explosion, the laser, the ball (stored complemented) | indexed PNG | `$E000-$E747` |
| [`gfx/pod.gfx.png`](gfx/README.md) | The weapon pod (stored complemented) | indexed PNG | `$F048-$F107` |
| [`music/titletune.tune.txt`](music/README.md) | The title tune, two-voice beeper ("MUSIC STEVE TURNER") | text: periods, order, patterns | `$FF01-$FFD3` |

The plugins are `tools/res_*.py` (one KINDS list each; a suffix of its own, since `res_formats.py` finds a file's
kind by its suffix). `*.preview.png` files are enlarged views for reading, not sources.
