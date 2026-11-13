# Front: the logo, the fonts, the keyboard table and the colour tables

The pictures and tables of the main block (`$6C3F-$A83E`, src/front/front.ann). The formats are in
tools/res_front.py; `python3 tools/res_formats.py build` turns each file back into the bytes the sources `INCBIN`.

| File | Address | Bytes | Format | Read by |
| --- | --- | ---: | --- | --- |
| logo.png | `$79DB` (LogoScreen, attributes `$91DB`) | 6912 | 256 x 192 colour-cell PNG: palette index = flash x 32 + set x 16 + bright x 8 + colour; the text chunk `front-logo` lists the cells whose ink (no set pixel) or paper (all set) the picture cannot show | ShowLogo `$785A` |
| font-small.png | `$9ED2` (FontSmall) | 296 | 37 glyphs (A-Z, space, 0-9) of 8 bytes, 10 cells of 8 x 8 a row, grey lines between; each cell's top row is the width mask (red), rows 1-7 the glyph | PrintText `$9D72` (font 0) |
| font-large.png | `$9FFA` (FontLarge) | 216 | 27 glyphs (A-Z, space), as font-small.png | PrintText `$9D72` (font 1) |
| keyboard.csv | `$9970` (KeyRowPorts) and `$9980` (KeyRowChars) | 16 + 40 | `port,keys`: the 8 half rows in scan order and their 5 key characters, bit 0 first (`-` CAPS SHIFT, `+` ENTER, `/` SPACE, `.` SYMBOL SHIFT) | ScanKeyboard `$9916` |
| shimmer.txt | `$78E2` (ShimmerColours) | 96 | attribute bytes, `$hh` each, 16 a line: a 32-byte streak pattern three times; bytes 60-95 are never read | ShimmerFrame `$79AE` |
| menu-bar.txt | `$9A33` (MenuBarColours) | 8 | attribute bytes: the menu highlight's colour of pass D AND 7 | MenuHighlight `$99E2` |
| joystick-bar.txt | `$9A8C` (JoystickBarColours) | 8 | the same for the SELECT JOYSTICK highlight | JoystickHighlight `$9A3B` |

The starfield behind the logo is drawn in logo.png's bitmap: no code moves it and the block has no star tables.
The dissolve masks the logo wipe and the text reveal use (`$F9CB-$F9EA`) belong to the resident part.
