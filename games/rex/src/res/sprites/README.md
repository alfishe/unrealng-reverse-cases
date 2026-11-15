# Sprites

| File | Address | Size | Readers |
| --- | --- | --- | --- |
| `rex1.png` | REX 1 `$7F72-$9479` (Sprites and its labels) | 5384 | DrawSprite `$B258`, DrawMirrored `$B2C1`, DrawCharBlock |
| `rex2.png` | REX 2 `$8198-$946F` | 4824 | the same routines of part 2 |
| `demo.png` | DEMO `$79DC-$8A83` | 4264 | the same routines of DEMO |

Each label of the Sprites entry (SpriteStomper, SpriteRex, SpriteShield, ...) is a set, drawn in the PNG as one strip
of its bytes, W bytes a line, top to bottom: the set's frames follow each other down the strip. A sprite is stored
pre-shifted (the frame lists ShiftFrames pick the copy for X & 7), so most sets show the same picture 2, 4 or 8
times, a pixel or two further right each time. W is chosen from the bytes (`res_formats.guess_width`: the width
under which the next frame is this one shifted, else 3); it only sets how the strip looks, every W gives the same
bytes back, and `tx-sprites` keeps each set's offset, size, W and place. A set read with another width by the code
(a HUD icon is 2 x 16, the shield bubble 4 x 21) shows as the code draws it when W agrees; a few sets (the points
signs, the big gun, the killed human) are drawn by their owners with sizes the strip does not show.
Format: an indexed PNG, 0 paper, 1 ink, 2 the grey between the sets.
