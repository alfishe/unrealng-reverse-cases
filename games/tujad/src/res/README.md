# Resources

Every resource out of the code, in an editable format; `tools/res_formats.py build` turns them back into the bytes
the source INCBINs, `tools/res_formats.py check` proves the round trip.

| File | What | Format | Entry |
| --- | --- | --- | --- |
| `screen/LoadingScreen.png` | the loading screen | PNG (Spectrum colours) | block 4 `$4000` (src/screen) |
| `sprites/Droid.png` | the droid's 14 frames | PNG sheet | DroidGraphics `$9C40` |
| `sprites/Enemies.png` | the nine enemy kinds, the explosion | PNG sheet | EnemyGraphicsData `$A74E` |
| `sprites/Materialise.png` | an enemy appearing | PNG sheet | MaterialiseGraphics `$AEC5` |
| `sprites/Probe.png` | weapon 3's probe | PNG sheet | ProbeGraphics `$AF85` |
| `sprites/Objects.png` | the five object kinds, their death, the probe's explosion | PNG sheet | ObjectGraphics `$B049` |
| `sprites/Patrollers.png` | the patrollers, right and left | PNG sheet | PatrolRight `$B902` |
| `sprites/ShotGraphics.png` | the bolts of weapons 1 and 2 | PNG sheet | ShotGraphics `$8814` |
| `sprites/HudIcons.png` | the weapon, GEN 19 and energy icons | PNG sheet | HudIcons `$8C55` |
| `graphics/Font.png` | the font | PNG sheet | Font `$E002` |
| `graphics/EdPieces.png` | the picture of the 50 ED pieces | PNG sheet | EdPieces `$E1E2` |
| `graphics/HudGraphics.png` | the HUD frame | PNG sheet | HudGraphics `$8BFD` |
| `graphics/MenuFrame.png` | the menu frame | PNG sheet | MenuFrameTopEdge `$BC02` |
| `graphics/MenuLogoGraphic.png` | the menu logo's block | PNG sheet | MenuLogoGraphic `$8DB2` |
| `tiles/TileTables.txt` | the tile pointers and colours | text | TileGraphics `$6EA8` |
| `tiles/TileData.png` | the tile graphics | PNG sheet | TileData `$E822` |
| `rooms/Rooms.txt` | the 128 rooms: layouts, items, teleporters, enemies, objects | text | RoomLayouts `$BD06`, AlienMap `$DB53` |
| `rooms/StartPositions.csv` | the droid's start in each room | CSV | StartPositions `$9484` |
| `text/Messages.txt` | the scroller's ten messages | text | Messages `$63D2` |
| `text/MenuTexts.txt` | the menu's texts | text | MenuTexts `$8D38` |
| `text/ProgressText.txt` | the progress line | text | ProgressText `$9072` |
| `leftover/Source1.txt` - `Source3.txt` | the authors' leftover source | text | DroidVars `$6359`, RoomVars `$639C`, ExhaustRows `$65E5` |

Each folder's README.md gives the addresses, sizes, readers and formats.
