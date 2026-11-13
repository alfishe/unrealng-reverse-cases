# Sprites: the 54 frames

| File | Resource | Address | Entry |
| --- | --- | --- | --- |
| `frames.png` | `sprites/frames.bin` (6804 bytes) | `$8401-$9E94` | SpriteFrames |
| `copied.png` | `sprites/copied.bin` (2 x 126 bytes) | `$6BA4-$6C21`, `$6C22-$6C9F` | Kind16Frame, Kind19Frame (module `loader`) |

`copied.png` holds the two frames below the graphics that Start `$AB4D` copies with two LDIRs (`$AB62`) to `$6A80`
(kind 16's frame) and `$7080` (GraphicSlot19, kind 19's frame), past the char map: their bytes on the tape sit inside
the AY player's area, which is work space once RAM 1 has the player. Same format as `frames.png`, one row of two.

`tools/res_gfx.py` (a format module of `tools/res_formats.py`) turns the PNG into the bytes and back;
`tools/res_formats.py check` proves the round trip.

## The format

A frame is 24 x 21 pixels, 126 bytes: 21 rows of 6 bytes, frame F at `$8401` + 126F. DrawSprite `$A419` points SP at
the frame and POPs HL, BC and DE a row, so a row's bytes are, in memory order, OR3, OR2, OR1, AND1, AND3, AND2: for each
of the three byte columns (1 is the left one) the screen byte is ANDed with the mask and ORed with the pixels. The
frames face one way; the mirrored draw (the object's +6 bit 0) swaps columns 1 and 3 and reverses the bits through
the table at `$5B00`.

**The PNG.** The 54 frames in rows of 9, frame 0 top left, a one-pixel grid (index 4) round each. Pixel indices:

| Index | Mask bit | Pixel bit | Shows |
| --- | --- | --- | --- |
| 0 | 1 | 0 | transparent: the background stays |
| 1 | 0 | 1 | ink: a set pixel |
| 2 | 0 | 0 | paper inside the mask: a cleared pixel (the outline round the figure) |
| 3 | 1 | 1 | a set pixel over the kept background |

## The frames

The names are the source's inner labels (`src/game`, entry SpriteFrames). How a frame is chosen: an object kind's
graphic (ObjectKinds +2/+3, kinds 4-21), an animation list byte B = F + 1 (`$EE0B`: `$8383` + 126B), or the code.
A falling enemy shows its graphic + 126, the next frame (`$F099`, `$F3ED`).

| Frame | Name | Used by |
| --- | --- | --- |
| 0-2 | RickWalk0-2 | Rick standing and walking (WalkFrames `$FD6D`); 2 also in the air |
| 3 | RickDying | Rick dying |
| 4 | Frame4 | a small shot, the bullet; kind 57 |
| 5, 6 | RickCrawl1, RickCrawl0 | crawling (CrawlFrames `$FD75`) |
| 7, 8, 9 | RickFiring, RickPoking, RickClimbing | firing, poking with the stick, on a ladder |
| 10 | DynamiteFuse | the burning stick (FuseFrames `$ECF2`) |
| 11 | BulletsPickup | kind 17, the bullets to pick up |
| 12-14 | Blast0-2 | the blast (BlastFrames `$ECF6`), kinds 29, 30, 54, 55, 67, 68 |
| 15-53 | Frame15-Frame53 | the kinds in each label's comment; 19, 24, 28 the falling frames of 18, 23, 27 |

Frames 20-22, 25, 26, 30 and 31 are named by no kind, list or instruction. Two more frames sit outside this block,
filled at the entry from the bytes after the music: kind 16's at `$6A80` and kind 19's at `$7080` (GraphicSlot19).
