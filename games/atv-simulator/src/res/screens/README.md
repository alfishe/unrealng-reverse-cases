# screens

| File | Address | Size | Format | Readers |
| --- | --- | --- | --- | --- |
| `loading.scr` | `$4000` (tape block 6, loaded by the loader at `$FFDC`, LoadScreen `$FFDD`) | 6912 | a SCREEN$: the pixels, then the attributes | the ROM's LD-BYTES; the game never reads it (Title clears the screen) |
| `loading.png` | - | 256 x 192 | a view of `loading.scr` in the Spectrum's colours, written by `tools/res_formats.py`; check keeps it up to date, the build does not read it | - |

The source is the SCREEN$ (the tape's block is its bytes). Edit the PNG's picture in an editor that writes a SCREEN$
and replace `loading.scr`.
