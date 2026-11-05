# src/res/menu99: the strings, the pointer and the viewer font of the '99 start-up menu

The menu block (`src/menu99/menu.asm`, unpacked to `$D800-$E6F3` of page 1 and run from a copy in page 0) INCBINs
these resources as `res/menu99/<file>.bin`. `tools/menu99_res.py build OUT` turns the files here back into those
bytes; `tools/menu99_res.py check` compares them with `work/media/99/menu-out.bin`; `tools/build_menu99.sh` builds and
compares the whole block. `tools/menu99_mkgame.py menu --install` writes these files from the image (first cut).

| File | Bytes it stands for | Size | Format | Who reads it |
| --- | --- | ---: | --- | --- |
| `menu-strings.txt` [menu] | `MenuText` `$D826-$D911` | 236 | PrintInline text, see below | `MenuScreen` `$D813` |
| `menu-strings.txt` [bottom] | `MenuBottomText` `$D920-$D966` | 71 | the same | `MenuBottom` `$D912` |
| `menu-strings.txt` [description] | `DescTitle` `$DB2B-$DB4C` | 34 | the same | `ShowDescription` `$DB1F` |
| `menu-strings.txt` [about] | `AboutTitle` `$DB5B-$DB7E` | 36 | the same | `ShowAbout` `$DB4F` |
| `menu-strings.txt` [advices] | `AdvicesTitle` `$DB97-$DBB4` | 30 | the same | `ShowAdvices` `$DB8B` |
| `menu-strings.txt` [greets] | `GreetsTitle` `$DBC3-$DBDF` | 29 | the same | `ShowGreets` `$DBB7` |
| `pointer.png` | `PointerSprite` `$DE11-$DE20` | 16 | 8 x 8 indexed PNG, 4 colours | `DrawPointer` `$DD73` |
| `viewer-font.png` | `ViewerFont` `$DEF1-$E6F0` | 2 048 | 128 x 128 1-bit PNG, 16 x 16 cells of 8 x 8 | `ViewerPutChar` `$DC8E` |

There is no title picture in the menu block: the big "NETHER EARTH ZS EDITION'99" is text, drawn by the game's
`PrintInline` (`$D42D`) at size `$31` from the game's own font (screen: `work/stage2/menu99/shots/f02700.png`, m99
frame 2700).

## menu-strings.txt

One section a string, `[name]` on its own line. The game's `PrintInline` reads the bytes after its CALL:

- `{AT y,x}` = `1 y x` (the print position, row first). A line break of the file goes before each one for reading;
  the file's line breaks are not bytes.
- `{ATTR n}` = `2 n` (the attribute), `{SIZE $hh}` = `4 hh` (the character size, as the game takes it: `$11`
  normal, `$21` the bottom items, `$31` the title), `{NL}` = `3` (the next line; none here).
- `{$hh}` any other byte that is no printable ASCII; every other character is itself.
- The closing `0` is not written: each section ends with it.

## pointer.png

8 x 8 pixels, the colour index is the pixel's (mask, pixel) pair: 0 = (1, 0) the screen shows through (magenta), 1 =
(0, 0) black, 2 = (0, 1) white, 3 = (1, 1) the screen with the pixel set (grey; unused). The bytes are mask, pixels for
each row; `DrawPointer` shifts both right by x AND 7 and writes screen AND mask OR pixels.

## viewer-font.png

The font is row-major in memory: byte `font + c + 256*r` is pixel row `r` (0-7) of character `c` (CP866). Each glyph
is drawn in both nibbles; `ViewerPutChar` keeps the left or right half by the column's parity. The PNG shows the bytes
as they are (8 pixels wide per cell, both halves). The 2048 bytes equal stage 2's `Font64` (`$7587-$7D86`,
`src/res/stage2/font64.png`) byte for byte: the release carries the font twice.
