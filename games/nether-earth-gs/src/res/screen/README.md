# The loading screen

`loading.png`: `neart000`, the 6 912-byte screen the loaders show first (bitmap + attributes, loaded to `$4000`).
A 256 x 192 indexed PNG with the 16 Spectrum colours; its text chunk `zx-hidden` holds what a picture cannot show
(the ink / paper of cells whose pixels are all one colour, the FLASH bits), so `tools/res_media.py` rebuilds the
exact bytes (the converter is advanced-nether-earth's `intro_screen.py`, unchanged but for names). Edit it in any
editor that keeps the palette; cells must keep two colours at most.

What it shows: a corridor in perspective between grey walls with yellow domes, an explosion at its end, coloured
blocks and stars above, and its words, drawn in pixels (no text file: they are not characters):

- **NETHER EARTH**, top left, in blue on blue, the title in two lines ("NETHER" over "EARTH");
- **GS-512**, below it at the left, green / cyan letters on red: the General Sound with 512 KB the conversion needs
  (the module and the effects take 359 KB, docs/09-sound.md 9.1);
- **TRON 2002**, top right, blue on red in a grey frame: the conversion's author and year (Tron Z, 2002).

The loaders draw the progress box over the bottom of it (the disk loader's `DrawProgress`, a tick per file).
