# Loader

The loading picture of tape block 2 (the BASIC array a$, `src/loader/loader.ann`).

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `PictureGraphics.png` | `$5CE3-$5EF2` | 528 | PrintPictureChar `$5FC9` for codes `$5F` and up (frame = code - `$60`; c1: 200 of 768 characters) | 66 graphics of 8 x 8, PNG sheet: the title logo, the panel frames |
| `PictureText.txt` | `$601C-$631B` | 768 | Loader `$5EF3` through PrintPictureChar (c1: 768 reads, frames 246-361) | 24 rows of 32 codes, the top row first; codes below `$5F` are the ROM font's ("IS LOADING", the key instructions) |

The picture as the loader draws it, with its attribute bands: `docs/img/loading.png`, drawn by
`tools/fig_loading.py` from these two files, the ROM font (`$3C00`) and the fills of Loader `$5F1D-$5F9D` (an output,
not INCBINned).
