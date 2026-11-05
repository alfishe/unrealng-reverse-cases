# src/res/intro98: the tune, the scroller, the pictures and the leftovers of the '98 intro and BASIC

The '98 file NEZSEd.B starts with the BASIC (`src/basic98/basic.asm`, sectors 0-1 at `$5D3B`) and the intro block
(`src/intro98/intro98.asm`, sectors 2-43 at `$C000-$E9FF`, from `src/intro98/intro.ann` through
`tools/intro98_mkgame.py`). `tools/intro98_res.py build` turns these files into the bytes the sources INCBIN as
`res/intro98/<file>`; `tools/build_intro98.sh` builds both parts and compares them with `work/media/98/basic.bin`
and `work/media/98/intro.bin`. `python3 tools/intro98_res.py check` builds each source, writes it back and builds it
again. The bytes are the file's, not the ones at run time.

| File | Bytes it stands for | Size | Format | Who reads it |
| --- | --- | ---: | --- | --- |
| `cool-winter.pt3` | `Pt3Module` `$CE21-$D88E` | 2 670 | Pro Tracker 3.3 module as the tracker saves it: "COOL WINTER" by KLIM/OHG '97, 15 positions (loop 1), 9 patterns, 8 samples, 10 ornaments, delay 5, tone table 1 | `Pt3Init` `$C000` (sets the pointers), `Pt3PlayEntry` `$C005` every frame |
| `scroll-text.txt` | `ScrollText` `$DAC2-$E3B8` | 2 295 | UTF-8 text, see below | `ScrollStep` `$D982`, one pixel a frame |
| `logo.png` | `LogoMask` `$E3B9-$E3F8` | 64 | 64 x 64 PNG, 8 x 8 cells of 8 x 8 pixels; a lit cell = 1, dark = 0 | `LogoColour` `$D95F` (paints the lit cells from `$580C`) |
| `robot.png`, `robot.parse` | `RobotStream` `$E4B3-$E6CB` | 537 | 192 x 64 PNG, the four frames of the box side by side (48 x 64 each, yellow on black), and the token list of the packed stream, see below | `RobotFrame` `$E3FE`, one frame every 32 frames |
| `font.png` | `IntroFont` `$E6CC-$E9CB` | 768 | 128 x 48 PNG, 96 glyphs of 8 x 8 from code `$20`, 16 a row, ink = 1 | `ScrollStep` (`ScrollFont` = `IntroFont` - 256 + code * 8) |
| `font-tail-leftover.bin` | `FontTailLeftover` `$E9CC-$E9FF` | 52 | bytes | nothing (no read in r98's intro window) |
| `basic98-slack.bin` | the BASIC's sector-1 slack `$5E93-$5F3A` | 168 | bytes | nothing: the memory after the program when the file was saved (edit-line tails, an old machine stack, a disk shell's code), described in `src/basic98/basic.asm` |

## scroll-text.txt

- The original is KOI-7 N2 as `IntroFont` draws it: `$20-$3F` ASCII, `$40-$5F` the upper-case Cyrillic
  `ЮАБЦДЕФГХИЙКЛМНОПЯРСТУЖВЬЫЗШЭЩЧЪ`, `$60-$7F` the same letters in lower case. Every letter of the text must be one
  of these (no Ё, no Latin letters while `IntroFont` is the font).
- `[font $3D00]` is the control `$01 $00 $3D`: from there the ROM's font, its bytes read as ASCII (the e-mail
  address, the group names); `[font $E6CC]` switches back to `IntroFont`. The scroller shows a space for the
  control.
- `[end]` is the `$00` that ends the text; the word after it (`$E3B7`, `$E381` in the original) is where the
  scroller goes on, written as `[loop]` at that place of the text (the last "Нажмите что-нибудь..." repeats).
- `[$hh]` is any other byte. Line breaks of the file are not characters: lines are joined with nothing between them
  (the tool breaks them only before a space). Lines starting with `#` are comments. Spaces are part of the bytes
  (the long runs are pauses).
- A longer or shorter text moves everything after it (`LogoMask`, the robot, the font): the labels move with it,
  so the intro still runs, but the block no longer matches the original.

## robot.png and robot.parse

`RobotFrame` decodes one frame of `RobotStream` into the screen from `$4000` in its own order: down each column of
bytes of a screen third, then the next column (pixel bytes, then attributes, linear). The first frame (303 bytes
written) draws the box on a black screen; frames 2-4 (79, 80, 78 bytes) change it; after the fourth the stream
starts again at frame 1 (`RobotSelf` + `$B0` = `RobotStream`), so the cycle is 1-2-3-4-1 (63 frames decoded in
r98's intro window).
`robot.png` holds the box after each frame. `robot.parse` holds the stream's tokens, one a line, frames ended by
`end`; the bytes of literals and fills are taken from the PNG:

| Token | Code | Meaning |
| --- | --- | --- |
| `skip N` | `$84-$BF` | N positions left as they are (1-60) |
| `skipl N` | `$80-$83` + a byte | N positions left (0-1023) |
| `lit N` | an even code `$C2-$FE` | N literal bytes (1-31) |
| `fill N` | `$C5`, `$C9` ... (4j+1) | N times the next byte (3-17) |
| `filll N` | `$C1` + count + byte | N times the byte |
| `zero N` | `$C7`, `$CB` ... (4j+3) | N zeros (2-16) |
| `zerol N` | `$C3` + count | N zeros |
| `copy N -D` | `$00-$7F` + a byte | N bytes (3-18) from D positions back (1-2048) |
| `end` | `$C0` | the frame ends |

The exact bit layout of each code is in `tools/intro98_res.py` (`robot_decode`, `robot_encode`) and in the robot
module's header (`src/intro98/intro.ann`).
