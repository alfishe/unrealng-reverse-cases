# Resources

Every resource out of the code, in an editable format; `tools/res_formats.py build` turns them back into the bytes
the sources INCBIN (and the tapes' blocks), `tools/res_formats.py check` proves each against the original bytes.
`kit/mkgame.py --install` writes them through `tools/res_formats.py install` (the `res_install` key of each json).

| Folder | What | Format | Entries |
| --- | --- | --- | --- |
| [pictures](pictures/README.md) | ten packed screens of bank 7 | PNG + the packer's parse | src/bank7/pictures.asm |
| [screens](screens/README.md) | the loading screen | PNG | src/tape/side1.txt |
| [fonts](fonts/README.md) | the 8x8 font (bank 6), the small font (bank 2) | PNG sheets | src/bank6, src/game (text) |
| [texts](texts/README.md) | the 20 texts of bank 6 (options, password, failure reasons, status, weapons, payload, legends) | UTF-8 with `{XX}` | src/bank6 |
| [music](music/README.md) | the AY player's tune data | hex in named parts | src/bank4/music.asm |
| [missions](missions/README.md) | the ten mission blocks and the catalogue of side 2 | text (tools/res_missions.py) + world figures | src/tape/side2.txt |
| [models](models/README.md) | the 3D model scripts: bank 3 SharedModels, bank 6 MapModels, the missions' libraries | `.mdl`, one instruction a line (tools/models3d.py; the missions' as `model` lines of their texts); listings and figures as views (tools/fig_models.py) | src/bank3, src/bank6, src/tape/side2.txt |

Leftover bytes: the pictures' two padding bytes each (pictures/README.md), SmallFontLeftover `$7D35` (fonts),
mission 2's foreign tail (missions/README.md); the leftovers inside the code images are entries of their modules.
