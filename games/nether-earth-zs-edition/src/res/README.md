# src/res: the resources of both releases

Every piece of data that is not code, as an editable file. Each part's build turns these back into the original
bytes and its source INCBINs them; `tools/build.sh` builds all and compares both disks with `orig/`.

| Folder | Part | What | README |
| --- | --- | --- | --- |
| `intro98/` | '98 BASIC and intro | the PT3 tune `cool-winter.pt3`, the scroller text, the logo, the robot, the font, the slack | [intro98](intro98/README.md) |
| `game98/` | '98 game | the font, 89 sprite blocks, the view edges, order names, the level (ZS's map), the menu tune | [game98](game98/README.md) |
| `stage2/` | '99 stage 2 | the intro scroller (CP866), the 64-column font | [stage2](stage2/README.md) |
| `pictures99/` | '99 pictures | the intro photo (RLE re-packed bit for bit), slack | [pictures99](pictures99/README.md) |
| `music99/` | '99 music | the Sound Tracker tune `ne_mus.stc`, slack | [music99](music99/README.md) |
| `menu99/` | '99 start-up menu | the menu strings, the pointer, the viewer font | [menu99](menu99/README.md) |
| `game99/` | '99 game | the new font, 89 sprite blocks, edges, order names, shapes, NE's (dead) tune | [game99](game99/README.md) |
| `maps/` | '99 disk and game | the twelve `NELEV_xx` maps and the built-in level as text, previews | [maps](maps/README.md) |
| `text/` | '99 disk | the five `.W` texts in UTF-8 (built back to CP866 with their slack) | [text](text/README.md) |

The packed blocks' sector slack is not a resource: it is the block's own unpacked bytes past its length (the author
packed in place), and `tools/build.sh` writes it ([03](../../docs/03-build-and-load.md), 3.4).
