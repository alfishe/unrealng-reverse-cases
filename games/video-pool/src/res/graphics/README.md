# Graphics

The bitmaps as indexed PNG sheets (palette 0 paper black, 1 ink white, 2 the grey grid between frames; the PNG text
chunk `vp-sheet` holds the layout, so a sheet builds back on its own: `tools/res_formats.py`, section PNG sheets; a
fifth number 1 in the layout: each line's bytes are stored right to left). The OCP banner is a plain PNG of its rows
(`vp-rle`, below). The span and edge lists are text (`tools/res_formats.py`, section Record lists): one record a
line, `end` for the `$FF`.

| File | Address | Bytes | Format | Readers | What |
| --- | --- | ---: | --- | --- | --- |
| `BallSprites.png` | `$D000-$DA7F` | 2688 | PNG sheet, 56 frames of 24 x 16 pixels (3 bytes x 16 lines), 7 a row | DrawBall `$9548` (every byte in every build) | The seven balls pre-shifted: row s = the shift x AND 7, column b = the ball (0 the cue ball, 1-6 the object balls with their number cut out); a 15 x 15 disc, centre (7, 7), line 16 empty; drawn with XOR, no mask |
| `SolidLine.png` | `$AAD8-$AADE` | 7 | PNG sheet, one frame of 56 x 1 | RestoreFlagLine `$AABD` through CopyNameLines `$AAAF` | A flag's solid line, seven `$FF` |
| `FlagTail.png` | `$AB41-$AB7A` | 58 | PNG sheet, one frame of 16 x 29, each line stored right byte first | XorTailLines `$AA12` | The flag's ragged tail, XORed at x + 48: lines 0-4 the field goes on 8 pixels, lines 5-23 the notched edge, 24-28 the curled corner |
| `PenShaftImage.png` | `$BFFE-$C03D` | 64 | PNG sheet, one frame of 32 x 16 | PenShaftCopy4 `$BF33` (PenShaftBlock `$BEDC` picks the row by x AND 7) | The pen's shaft: a 12-pixel bar one pixel further right each row |
| `BannerData.png` | `$BA86-$BB12` | 141 | PNG, 240 x 37, one line a data row (palette 0 paper, 1 magenta ink); built back as runs, one byte a run (bit 7 ink, bits 0-6 half the length), every run an even length | BannerRowEdges `$BA0A`, BannerRollIn `$B96C`, BannerDrawRows `$B9E0` | The OCP banner of the presents page: the letters O, C, P are the paper gaps in the ink stripes; 37 rows (the first and the last drawn one line high, the others two) |
| `FlipLetters.txt` | `$BB98-$BC10` | 121 | text: `letter NAME`, `edge DX DY KIND`, `end` | FlipLetter `$BB74` | The edges of the turning letters O (`$BB98`), C (`$BBBD`), P (`$BBDC`), L (`$BBFB`): per stripe line a left and a right edge, KIND bit 1 the right edge, bit 2 the 24-pixel width, bit 3 both widths |
| `RubLines.txt` | `$B191-$B1D9` | 73 | text: `span DX DY LENGTH`, `end` | DrawLineList `$B101` | The word "rub" of the name-entry grid as 24 horizontal lines from (x `$B7`, y `$90`) |
| `EndLines.txt` | `$B1DA-$B225` | 76 | text, as RubLines | DrawLineList `$B101` | The word "end", 25 lines from (x `$D7`, y `$90`) |
| `PenNib.txt` | `$BFCC-$BFEA` | 31 | text, as RubLines | PenSpans `$BE79` | The pen's nib: ten spans from the pen point down-right |
| `PenCap.txt` | `$BFEB-$BFFD` | 19 | text, as RubLines | PenSpans `$BE79` (after the shaft) | The pen's end cap: six spans, lengths 11 down to 1 |
