# 6. Rendering

What this covers: what the GS conversion shows that the 48K does not, and where the game's drawing data lies in the
GS image. The game's renderer itself (the scroll of tile glyphs, the sprite cache, the strips) is Zynaps's, byte for
byte; its routines are in [12](12-routine-reference.md) and described in the 48K case's chapter 6.

## 6.1 The loading screen

The loading screen is the 48K tape's picture (6912 bytes, identical to the 48K case's `loading.scr`). It is shown
three times in the GS:

- at the boot: Trush block 0 unpacks it at `$7F58` with its own code (`src/disk/screen/`), which fades it in
  (MakeFades builds the fade steps of the attributes) and keeps a copy in bank 7;
- at every level load: the loader copies bank 7's picture to the screen before it reads the disk. The records
  are read and unpacked in bank 7 (`PackedAt` `$BED4`, unpacked to `$C000`), over the picture's copy, so at the end
  `ScreenToBank7` copies the screen back into bank 7. The round start then draws the play screen again;
- between the title pages: TitleStub shows it ([img/compare/title-picture.png](img/compare/title-picture.png)).

## 6.2 The options menu

The menu is drawn by its own printer ([texts/menu.md](texts/menu.md)): `ClearScreen` (black border, bitmap and
attributes zeroed), then `PrintText` with a bold copy of the ROM font that `MakeFont` makes in bank 7 at `$FD00`
(each row of a ROM glyph ORed with itself shifted right one pixel). One character cell a character, with an
attribute letter per string.

## 6.3 The graphics in the GS image

The GS image is the memory after the 48K start-up ran ([src/res/gfx/README.md](../src/res/gfx/README.md)): the
scenery tiles and the wave cells are at `$5C00` and `$6400`, where the game reads them, and still at `$BC00` and
`$C400`; the sprites (`$E000-$E747`) and the pod (`$F048-$F107`) are complemented. The resources are the 48K's PNG
files; `tools/res_gfx.py` writes both copies and the complement.
