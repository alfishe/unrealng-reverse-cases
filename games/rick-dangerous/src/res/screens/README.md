# Screens

| File | Resource | Bytes | Where it comes from |
| --- | --- | --- | --- |
| `loading.png` | `screens/loading.scr` | 6912 | the loading screen: group 1 of the tape deciphered at `$CF00-$E9FF`, copied to `$4000` by the second loader stage (tools/bleepload.py, `screen-4000.bin`) |

`tools/res_gfx.py` (a format module of `tools/res_formats.py`) turns the PNG into the 6912 bytes (6144 of bitmap in the
Spectrum's line order, 768 attributes) and back; `tools/res_formats.py check` proves the round trip.

**The PNG.** 256 x 192 pixels in their colours, no grid. The palette's first 16 entries are the Spectrum's colours
(0-7, then 8-15 BRIGHT); each pixel is the index of its char cell's INK (a set bit) or PAPER. The attributes, with
FLASH and which index is INK, are the PNG's text chunk `attributes`: 24 lines of 32 bytes in hex. A cell whose INK and
PAPER are one index keeps its bits in the text chunk `bits` (`cell:hex`). Paint a cell only with its two indices; to
recolour, change its attribute byte in the text chunk.
