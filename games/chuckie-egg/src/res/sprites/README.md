# Sprites

PNG sheets of 16 x 16 frames (two bytes a row). Both are ORed onto a background the routine composes itself.

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `Sprites.png` | `$8DF0-$900F` | 544 | DrawSprite `$9A4C` (frame A at Sprites + 32 x A, top row first; 134 270 calls in the eight builds) | 17 frames: Harry right 0-3, left 4-7, the duck 8-11 (10-11 when Harry is left of it), blank 12, Harry climbing 13-16. Harry walks with 0, 1, 0, 3: frame 2 is a byte-for-byte copy of 0; the left frames are the right ones mirrored bit for bit; every Harry frame leaves row 0, row 15 and two columns each side blank |
| `HenSprites.png` | `$9010-$910F` | 256 | DrawHen `$929C` (frame A - 1, from its last row up: HL = HenSprites - 2 + 32 x A) | 8 frames: walking 0, 1, 4, 5 (state 1 left / 2 right, + 4 when x AND 4), climbing 2-3, pecking 6 (left), 7 (right). Frames 0-1 fill columns 0-7, frames 4-5 (the next step) columns 4-11: the walk pre-shifted by half a byte, since DrawHen writes whole bytes at x >> 3 |
