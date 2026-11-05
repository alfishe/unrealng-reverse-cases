# src/res/stage2: the scroller text and the 64-column font of the '99 stage 2

Stage 2 (`src/stage2/stage2.asm`, run at `$61A8`) prints the intro's scroller with its own 64-column routine
(`PrintChar` `$6451`). `tools/front99_res.py build` turns these files back into the bytes `src/stage2/stage2/texts.asm`
INCBINs (`res/stage2/scroller.bin`, `res/stage2/font64.bin`); `tools/build_front99.sh` compares the whole stage 2
with `work/media/99/stage2-out.bin`.

| File | Bytes it stands for | Size | Format | Who reads it |
| --- | --- | ---: | --- | --- |
| `scroller.txt` | `ScrollText` `$654C-$7586` | 4 155 | UTF-8 text, see below | `ScrollerLoop` `$6225`, one CR LF line per scroll step, through `PrintChars` `$6446` |
| `font64.png` | `Font64` `$7587-$7D86` | 2 048 | 128 x 128 1-bit PNG, 16 x 16 cells of 8 x 8, cell = character code | `PrintChar`, through `PrintFont` `$6523`, which `IntroMain` sets to `Font64` (`$621F`; `$3C00` on disk) |

## scroller.txt

- The disk text is CP866 (Russian) with CR LF line ends; the source is UTF-8 with LF. Every character must exist
  in CP866.
- `{AT c,r}` is the control `$16 c r` (the print position; the text opens with `{AT 32,22}`).
- `{$hh}` is any other byte that has no printable form. TABs stay TABs (`$09`).
- Trailing spaces are part of the bytes: an editor that strips them breaks the byte match.
- 157 lines. `ScrollerLoop` counts them: `LD B,$9C` (156 lines after the first) at `$622B`, then it starts again
  from the top. A text with another line count needs that constant changed in `src/stage2/stage2.ann`; a longer
  text also moves `Font64` (the label moves with it, so it still runs, but the block no longer matches the
  original).

## font64.png

The font is row-major in memory: byte `font + c + 256*r` is pixel row `r` (0-7) of character `c`. Each glyph is
drawn in both nibbles; `PrintChar` picks the left or right half with a mask by the column's parity. The PNG shows
the bytes as they are (8 pixels wide per cell, both halves).
