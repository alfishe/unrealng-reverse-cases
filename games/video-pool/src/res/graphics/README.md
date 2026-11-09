# Graphics

The ball sprites as an indexed PNG sheet (palette 0 paper black, 1 ink white, 2 the grey grid between frames; the PNG
text chunk `vp-sheet` holds the layout, so the sheet builds back on its own: `tools/res_formats.py`, section PNG
sheets).

| File | Address | Bytes | Format | Readers | What |
| --- | --- | ---: | --- | --- | --- |
| `BallSprites.png` | `$D000-$DA7F` | 2688 | PNG sheet, 56 frames of 24 x 16 pixels (3 bytes x 16 lines), 7 a row | DrawBall `$9548` (every byte in every build) | The seven balls pre-shifted: row s = the shift x AND 7, column b = the ball (0 the cue ball, 1-6 the object balls with their number cut out); a 15 x 15 disc, centre (7, 7), line 16 empty; drawn with XOR, no mask |
