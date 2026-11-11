# Resources

Every resource out of the code, in an editable format; `tools/res_formats.py build` turns them back into the bytes
the sources INCBIN, `tools/res_formats.py check` proves the round trip (62 editable files, 0 bad; the 3 `.bin` files
of leftovers/ are bytes). kit/mkgame.py `--install` writes them from the images through `install()`. The parts:
game (block 5), select, music and explorers (block 4), screen (block 3), tape (block 2, the BASIC loader).

| File | What | Format | Entry |
| --- | --- | --- | --- |
| `rooms/rooms.txt` | the 72 rooms: back-tile grids, three creatures each; the rooms on the alternate tiles | text | RoomGrids `$D600`, RoomCreatures `$C152`, AltTilesetRooms `$9AC6` |
| `rooms/backtiles.txt` | the 256 back-tiles of 4 x 4 tiles | text, hex | BackTiles `$C600` |
| `tiles/base.png`, `alt.png` | the 256 tiles and the 128 alternate upper tiles, with their attributes | PNG colour cells | TilePixels `$F000` + TileAttrs `$DF00`; AltTilePixels `$FA00` + AltTileAttrs `$C580` |
| `sprites/creatures.png`, `items.png`, `bearers.png` | the creatures (frames `$40-$7E`), the 32 items, the 4 bearers | PNG sprite sheets, 24 x 24 | CreatureSprites `$7200`, ItemSprites `$8400`, BearerFigures `$9FDE` |
| `sprites/explorer-0.png` - `explorer-4.png` | the five explorers' 64 frames | PNG sprite sheets | src/explorers: `$9CF8 + $1200 x n` |
| `graphics/title-logo.png`, `capsules.png`, `flames.png` | the menu logo, the capsule and flame tile frames | PNG 8 x 8 cells | TitleLogo `$95FD`, CapsuleFrames `$92FD`, FlameFrames `$933D` |
| `graphics/cursor.png` | the selector's hand cursor, 4 shifts with masks | PNG 24 x 16 | CursorSprites `$CD8F` (select) |
| `screens/loading.png`, `selector.png`, `panel.png` | the loading screen, the selector screen, the status panel | PNG screen (colour) | LoadingScreen `$4000`, SelectorPicture `$CF0F`, BackBuffer `$E000` + SavedPanelAttrs `$E800` |
| `texts/*.txt` | the menu, credits, telescope view, the 48K tape prompts, Help, the loader's break message | UTF-8 quoted text | MenuText `$9540`, CreditsText `$9579`, CollisionText `$B07C`, HelpPage1 `$C721`, ... |
| `tables/*.csv`, `*.txt` | item places, think hints, the professor's wishes, checkpoints, teleport pads, lift stops, snakes, floor and solid tiles, jump and barrel arcs | CSV; hex or signed lists | ItemPlaces `$B99D`, ThinkHints `$A6E6`, WantedItems `$B6BB`, ... |
| `anims/*.txt` | the hero's frame lists: deaths, telescope, teleport, mud, think, refuse, rooms `$2D` `$2E` `$43`, the professor | hex lists | FallDeathFrames `$A8BF`, ... |
| `music/*` | the tunes (order lists and patterns), instruments, slots, vibrato, arpeggios, envelope rates | text; CSV | TuneTable `$C967`, Instruments `$C028`, ... (src/music) |
| `leftovers/*` | four stretches no code reads before writing | bytes; hex grid | Leftover8D01 `$8D01`, Im2Table `$8E00`, BackBufferLeftover `$E900`, TileMap `$F800` |

Each folder's README.md gives the addresses, sizes, readers and formats. `tools/fig_rooms.py` draws the rooms from
rooms/, tiles/, sprites/ and tables/item-places.csv (docs/img/maps/rooms.png).
