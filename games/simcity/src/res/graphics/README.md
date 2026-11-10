# Graphics

PNG sheets in the Spectrum's 64-colour ink / paper palette (tools/res_formats.py, its docstring). A tile sheet holds
a tile set and its attribute table: tile n at column n % 16, row n / 16, drawn in its attribute's colours; the
build splits the sheet back into the two tables. Tiles past the end of the attribute table are white on black.

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `Icons.png` | IconTiles `$E850-$EA67`, IconAttrs `$F4F8-$F52F` | 536 + 56 | DrawIcon `$5C28`, DrawIconHere `$5C57` | 67 tiles: the tool palette and the window graphics (DrawIcon, with tile n's attribute) and the box frames (DrawIconHere, with PrintAttr). Only tiles 0-55 have an attribute: IconAttrs ends where CellAttrs starts, so DrawIcon on tiles 56-66 would read CellAttrs; known only from the code which tiles DrawIcon is given |
| `Cells.png` | CellTiles `$EA68-$ED57`, CellAttrs `$F530-$F58D` | 752 + 94 | DrawCell `$6468`, DrawView `$650B`, AnimateFire `$906D`, AnimateFlood `$908A`, OverviewCell `$9BC3` | The 94 map cells below `$80`: water, coast, land, trees, roads, rails, power lines and their crossings, parks, rubble, houses, flood, fire, the zone frames and centres, radiation (the codes: work/stage2/NOTES.md) |
| `Buildings.png` | BuildingTiles `$ED58-$F4F7`, BuildingAttrs `$F58E-$F681` | 1952 + 244 | DrawBuildingTile `$64D6`, OverviewCell `$9BC3` | The 244 tiles of the buildings: a building row on the map shows tiles n, n + 1, ... (n from its second and third byte), so the sheet is the buildings cut into runs, not whole pictures. tools/fig_city.py puts them together |
| `Pointer.png` | PointerShape `$5CEC`, PointerMask `$5CF4` | 16 | DrawPointer `$5CFE` | The pointer: 8 rows of the arrow (ORed in), then 8 rows of its mask (ANDed first); white = a set bit |
| `Movers.png` | MoverSprites `$A884-$A923` | 160 | DrawMover `$7735` | Five 16 x 16 sprites, 2 bytes a row: the plane, two tornado frames, the train across and the train down |

The font is the ROM's (`$3C00`, PrintGlyph `$F754` makes it bold, each row ORed with itself shifted right): the game
holds no font of its own, so there is no font resource.

A whole city from these sheets and a saved city: `python3 tools/fig_city.py work/stage1/rec/menus/town.tap
out.png`; the stage 1 map from memory, `tools/fig_tiles.py map` (docs/img/play/096503-metro-city-map.png), is the
same picture pixel for pixel (only its palette's 205 for 215 differs).

No leftovers: the tables are read whole by tile number (which tile numbers occur: tools/fig_tiles.py sheet --used).
