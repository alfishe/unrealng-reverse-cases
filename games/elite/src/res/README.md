# Resources

Every resource out of the code, in an editable format; `tools/res_formats.py build` turns them back into the bytes
the source INCBINs, `tools/res_formats.py check` proves the round trip. `kit/mkgame.py --install` writes the sources
from the image (through `tools/res_formats.py install`), and `tools/build.sh` builds the tape from them.

| File | What | Format | Entry |
| --- | --- | --- | --- |
| `fonts/font.png` | The character set: 91 glyphs for the codes `$20-$7A`, with the dashboard's frame pieces on `! " # $ % & + ; < = >` | PNG, 8 x 8 cells, 16 a row: index 0 paper, 1 ink, 2 no glyph | Font `$5D70-$6047` |
| `ships/ships.txt` | The 19 blueprint headers and their 16 shapes (the rock hermit flies the asteroid's, the trader and pirate Cobra and Python share theirs) with their vertices, edges and faces ([07-objects.md](../../docs/07-objects.md)) | text, one line a vertex, an edge or a face, its fields decoded | ShipAsp `$61CC` to ShipThargonFaces `$6FA2` |
| `dashboard/compass.png` | The compass dots (target in front, behind) and the dial | PNG: two 16 x 4 dots and the 24 x 24 dial, one under the other | CompassDotFront `$8481-$84D8` |
| `text/tokens.txt` | The 149 standard and 263 other strings of the two token sets ([08-hud-and-text.md](../../docs/08-hud-and-text.md)) | text, one line a string, `{xx}` for a code byte; `tools/tokens.py` decodes them | StdTokens `$F11E`, OtherTokens `$F4F5-$FBFF` |
| `screens/loading.scr` | The loading screen | a 6912-byte SCREEN$ | the tape, block 5 (`$4000-$5AFF`) |
| `tape/master-memory.bin` | 1096 bytes of the machine Softlock was mastered on (system variables and a BASIC remnant) | bytes | TZX block 37, `$5C00-$6047` |

The readable texts of the game (the missions, the planet descriptions) are in [docs/texts](../../docs/texts/).
