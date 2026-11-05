# Resources

Every resource out of the code, in an editable format. Two tools build them back into the bytes the sources INCBIN
and the disk builder reads (both run by `tools/build.sh`, into `build/res/`):

- `tools/res_formats.py build` the game's resources (the plugins `tools/res_*.py`, copied from the 48K case with
  the GS image's differences: [gfx](gfx/README.md), [fonts](fonts/README.md)); `tools/res_formats.py check` proves
  the round trip.
- `tools/disk_media.py build` the disk's media: the modules, the effects, the loading screen.

The game's files are the 48K case's, the same PNG and text, except `text/messages.msg.txt` (one message,
[docs/texts/game.md](../../docs/texts/game.md)) and `fonts/romleftover.font.png` (one byte more).

| File | What | Format | Entry |
| --- | --- | --- | --- |
| [`music/level01.mod` .. `level13.mod`](music/README.md) | The 13 ProTracker modules, one a level, 13 the title's | MOD | the disk's module records |
| [`sfx/fx-start.wav`, `fx01.wav` .. `fx21.wav`](sfx/README.md) | The 22 sampled effects | WAV, 8-bit unsigned mono | the boot banks and the disk's FX sets |
| [`screen/loading.png`](screen/README.md) | The loading screen (the 48K tape's) | indexed PNG + the 6912 bytes in a text chunk | Trush block 0 |
| [`levels/levels.lev.txt`](levels/README.md) | The 12 levels: enemy paths, waves, kinds, level table, wave scripts, scenery scripts, groups, shapes | text | `$6800-$7E59` |
| [`effects/effects.fx.txt`](effects/README.md) | The 48K's 6 beeper effects (in the image, never heard in the GS: the requests go to the driver) | text, one line an effect | `$7E5A-$7E89` |
| [`text/hiscores.hsc.txt`](text/README.md) | The high-score table | text | `$8261-$82A6` |
| [`text/messages.msg.txt`](text/README.md) | The 28 messages, with their print codes | UTF-8 text | `$82EE-$8515` |
| [`fonts/glyphs.font.png`](fonts/README.md) | The game's 54 glyphs (print codes `$80-$B5`): the ZYNAPS logo and the HEWSON name | PNG, 8 x 8 cells | `$B54F-$B6FE` |
| [`fonts/romleftover.font.png`](fonts/README.md) | What is left of the ROM font at the top of memory, used as work cells | PNG | `$FFD8-$FFFF` |
| [`gfx/tiles.gfx.png`](gfx/README.md) | The 256 scenery tiles | indexed PNG | `$5C00-$63FF` and `$BC00-$C3FF` |
| [`gfx/wave-cells.gfx.png`](gfx/README.md) | The cells of the wave sprites | indexed PNG | `$6400-$67FF` and `$C400-$C7FF` |
| [`gfx/sprites.gfx.png`](gfx/README.md) | The ship, the sight, the explosion, the laser, the ball | indexed PNG | `$E000-$E747` |
| [`gfx/pod.gfx.png`](gfx/README.md) | The weapon pod | indexed PNG | `$F048-$F107` |
| [`music/titletune.tune.txt`](music/README.md) | The 48K's beeper title tune (in the image, not played) | text | `$FF01-$FFD3` |

The disk parts' code (`src/disk/`) holds its texts inline; all of them: [docs/texts/](../../docs/texts/).
`*.preview.png` files are enlarged views for reading, not sources.
