# screens

| File | What |
| --- | --- |
| `loading.scr` | the loading screen, tape block 6 (6912 bytes, SCREEN$). src/tape/tape.txt stores it as is; the build reads this file |
| `loading.png` | a view of it (`tools/res_formats.py` `screen_view`), not read by the build |

The screen stays a SCREEN$ file: a PNG cannot give back the attributes of cells with one colour.
