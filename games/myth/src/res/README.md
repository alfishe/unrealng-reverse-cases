# Resources

Every resource out of the code, in an editable format: one file a data entry of a part's `.ann` (`@res`).
`python3 tools/res_formats.py build` turns them back into the bytes the sources INCBIN (`tools/build.sh` runs it
first), `python3 tools/res_formats.py check` proves every file comes back unchanged through its bytes. Each folder
has its own README.md with the address, size, format and readers of every file.

| Folder | Part | What |
| --- | --- | --- |
| `screens/` | tape (blocks 13 and 15) | the loading screen `loading.scr` (6912 bytes, kept as a `.scr`) |
| `loader/` | sl1 | the loader's countdown digits |
| `resident/` | resident (`$F000`-`$FFFF`) | the print font, the Print texts, the stage records, the AY effects, the colour cycle, the dissolve masks, the bit-reverse and screen-line tables, the ROM font's leftover copy |
| `front/` | front (the main block) | the System 3 logo screen, the two menu fonts, the keyboard map, the highlight bars |
| `front-texts/` | front | the credits and menu texts, the key names, the leftover old DEFINE KEYS texts |
| `stage1/` ... `stage5/` | stage1 ... stage5 | each stage's graphics block (tiles, blocks, map), rooms and placements, sprite sets, bitmaps, pictures, tables, texts (stage 5: no rooms; its text pages) |

## Formats

The format modules are `tools/res_*.py`, loaded by `tools/res_formats.py` (each module's docstring has its formats
in full):

| Module | Files | Editable form |
| --- | --- | --- |
| `res_resident.py` | `resident/*`, `loader/*` | PNG fonts and digits, `text-*.txt` (one quoted string), CSV tables, text tables |
| `res_front.py` | `front/*`, `front-texts/*` | the logo and fonts as PNG, the keyboard as CSV, bars and texts as text |
| `res_stage.py` | `stageN/*` (every stage; the stage is the folder) | `graphics.txt` + `tiles.png` (the RLE block), `rooms.txt`, `sprites-NAME.png` (frames + frame table), `bitmaps-NAME-WxH.png`, `picture-NAME-WxH.png` (linear picture with colours), `rowpicture-NAME.png` (row-packed picture), `table-NAME.csv` (columns in `res_stage.TABLES`, including dameron-path, frame-offsets, burst-directions-cut), `text-NAME.txt` |
| `res_stage5.py` | `stage5/textlines-*` | `textlines-NAME.txt`: `COLUMN PIXEL BYTE2 TEXT` a line, `\` the full stop |

The maps are drawn from these files alone by `python3 tools/fig_rooms.py stageN` (`docs/img/maps/`).
