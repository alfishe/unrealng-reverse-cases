# Screen

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `LoadingScreen.png` | `$4000-$5AFF` | 6912 | the ULA only (no code of the game reads it; Menu `$8854` overwrites it) | The loading screen of block 4 (`LOAD "" CODE` puts it on the screen). A 256 x 192 picture in the Spectrum's colours whose palette index keeps ink and paper apart; the text chunk `tujad-hidden` keeps the attributes of the cells that show one colour only. Format: tools/res_formats.py |
