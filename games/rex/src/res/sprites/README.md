# Sprites

| File | Address | Size | Readers |
| --- | --- | --- | --- |
| `rex1.png` | REX 1 `$7F72-$9479` (Sprites and its labels) | 5384 | DrawSprite `$B258`, DrawMirrored `$B2C1`, DrawCharBlock |
| `rex2.png` | REX 2 `$8198-$946F` | 4824 | the same routines of part 2 |
| `demo.png` | DEMO `$79DC-$8A83` | 4264 | the same routines of DEMO |

Each label of the Sprites entry (SpriteStomper, SpriteRex, SpriteShield, ...) is a set, drawn in the PNG as one strip
of its bytes, W bytes a line, top to bottom: the set's frames follow each other down the strip. A sprite is stored
pre-shifted (the frame lists ShiftFrames pick the copy for X & 7), so most sets show the same picture 2, 4 or 8
times, a pixel or two further right each time. W is the width the code draws the set with
(`res_formats.SPRITE_WIDTHS`): the DrawSprite calls of the part 1 recordings give it for 27 of REX 1's 34 sets (3 for
the 16-pixel sprites with their shift byte, 2 for the fixed frames and the HUD icons, 4 for the shield bubble 4 x 21,
6 for the big gun and its explosion 6 x 48); REX 2's and DEMO's copies of the same bytes take the same width. The sets
never drawn in a recording (7 in REX 1, the rest of REX 2 and DEMO) keep the width read from the bytes
(`res_formats.guess_width`: the width under which the next frame is this one shifted, else 3). W only sets how the
strip looks: every W gives the same bytes back, and `tx-sprites` keeps each set's offset, size, W and place.
Format: an indexed PNG, 0 paper, 1 ink, 2 the grey between the sets.
