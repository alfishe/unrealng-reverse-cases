# Screens

| File | Where | Size | Format | Read by |
| --- | --- | --- | --- | --- |
| loading.png (`loading.scr`) | side 1 tape, two SpeedLock blocks (src/tape/side1.txt): the bitmap to `$4000`, the attributes to `$8000` | 6912 | a Spectrum screen as an indexed PNG (tools/res_formats.py: palette index = flash x 32 + ink x 16 + bright x 8 + colour; the text chunk `bc-hidden` keeps the attributes of cells with no ink pixel) | the loader's countdown copies the attributes from `$8000` to `$5800` |

The Erbe release's loading screen differs from Ocean's in 40 bytes (work/stage2/NOTES.md); this one is Ocean's.
