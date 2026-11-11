# 11. Data reference

Every data entry of the game image `$7200`-`$FFFF`, in address order by module (`src/game/<module>.asm`):
tables, buffers, records, variables, graphics, text; an inner label (a field, a row) is a row of its own under
its entry, its size up to the next label; an entry with inner labels gives its own bytes, up to the first,
of the whole entry's ("17 of 34"). The name, the title and the description are the
source's (`src/game/game.ann`); the readers and writers are the routines the recordings saw touch it
(`work/stage1/c1`, local and not in the repository), then those only the case's other recordings (`read_builds`) saw, with the first of them in brackets, and, marked
"(code)", the routines (the label at or below the instruction) whose `LD` through `(nn)`, or through `HL`, `DE` or `BC` loaded with `nn` in the same block, reads or writes it where the recordings did not see them do so.
Written by `kit/refdocs.py`.
The parts of the medium (`case.json` `ref_parts`: Tape BASIC and loader, The 128K setup and the explorer selector
(RAM 1), The AY music player (RAM 6), The explorer data sets, The loading screen) follow the game, each under its
own heading with its modules, its source, its annotations and its recordings.

## sprites

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7200` | `CreatureSprites` | 4536 | The creatures' sprites: frames `$40-$7E` of the sprite space, 63 sprites of 24 x 24. The sprite space starts at ExplorerSet `$6000`: frame F lies at `$6000` + 72 x F, frames `$00-$3F` the chosen explorer's set, `$40-$7E` these, `$7F` the blank frame BlankSprite `$83B8`, `$80` + n item n (ItemSprites `$8400`). Each sprite is three columns of 24 bytes, left column first, top byte first, ink 1. The plotter `$9C7E` reads them through the frame number (`$9FAA` computes the address); RenderPass `$9B22` draws them with a one-pixel outline from OutlineMasks `$FF00`, mirrored through BitReverse `$FE00` when flags bit 7 is set (the stored graphics face left, so bit 7 set faces right). The frames: the professor and his poses, the snake, the crocodile, the bird, the frog, the stone faces, the treasure chest, the drops, the comet, the planets of the space scene (src/res/sprites/creatures.png). Witness: every play build reads `$7200-$7D40`, `$7E18-$82E0`; the frames at `$7D41-$7E17` and `$82E1-$83B7` are read in no play build (c1, explorers, gameover, rzx x31 byte counts; work/stage2/bytemap.py). | `BlitColumns`, `DrawSpriteRow` | - |
| `$83B8` | `BlankSprite` | 72 | Frame `$7F`: 72 zero bytes, the empty sprite. Read in every play build (bytemap.py): a slot with nothing to show draws this frame. | `DrawSpriteRow` | - |
| `$8400` | `ItemSprites` | 2304 | The 32 items' sprites, frames `$80-$9F` of the sprite space. 72 bytes each in the creatures' layout. DrawItem `$9DE3` draws item n from `$8400` + 72 x n. The names are in src/res/sprites/README.md (SK's names, checked against the pictures). Witness: every byte read in play except `$8BE1-$8C27`, item `$1C` (Barrel Small) after its first byte: the item is never shown in the recordings. | `BlitColumns`, `DrawItem`, `DrawSpriteRow` | - |

## entry

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8D00` | `Var8D00` | 1 | A game variable inside the image, set to 0 by GameEntry `$8F00` | `DrawSpriteRow` (`stage1/rzx/r18000`) | `GameEntry` |
| `$8D01` | `Leftover8D01` | 255 | Leftover: 255 bytes no code reads (350 of the 511 bytes up to `$8EFF` are zeros). No play build reads or writes `$8D01-$8DFF` (bytemap.py). | `DrawSpriteRow` (`stage1/rzx/r18000`) | - |
| `$8E00` | `Im2Table` | 256 | The IM 2 table: on the tape, leftover bytes; GameEntry fills `$8E00-$8F00` with `$5F`. GameEntry `$8F00` writes 257 bytes of `$5F` from `$8E00`, its own first byte `$8F00` included (the SkoolKit snapshot, taken after it, holds `$5F` there). With I = `$8E` and the bus at `$FF` the CPU reads the vector from `$8EFF` and `$8F00`: `$5F5F`, where GameEntry put JP `$9491`. Witness: the play L1 counts 69582 reads of `$8EFF` (and of `$8F00`) against 78587 interrupts in the same builds, so the count is a lower bound, not one read an interrupt; no other byte of the table is read. | `DrawSpriteRow` (`stage1/rzx/r18000`) | `GameEntry` |

## util

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$93AD` | `RandomState` | 2 | Random's 16-bit state: 12345 (`$3039`) as loaded. Read and written only by Random `$9390`. | `Random` | `Random` |

## rooms

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$918C` | `AltTileset` | 1 | The tile set in place: 0 the base set, `$FF` the alternate set. Toggled only by SwapTileset `$918D`; read by the room set-up `$9880` (which swaps the set for the 15 rooms of the list at `$9AC6`), RoomEffects `$91C0`, ShowCapsules `$92BD`, EndGame `$906D`, `$A102`, `$A193` and others. Written in rzx18000, rzx20000, rzx26000 (twice), rzx34000, rzx50000. | `FloorDistance`, `GameEntry`, `HeroTileChecks`, `OnLadder`, `RoomEffects` +9 | `SwapTileset` (`stage1/rzx/r18000`) |
| `$92FD` | `CapsuleFrames` | 64 | Four frames of the capsule, tiles `$8C-$8D`: 16 bytes each, the left tile then the right. Copied to `$F460` by Capsules `$9282`. The frames differ only in rows 3-6 of the right tile. Read in rzx18000-rzx50000. | `Capsules` (`stage1/rzx/r18000`), `RoomEffects` (`stage1/rzx/r26000`) | - |
| `$933D` | `FlameFrames` | 32 | Four 8-byte frames of tile `$B5`, a flame, PassCount AND 3 picks one. Copied into tile `$B5`'s bitmap (`$F5A8`) by RoomEffects `$91E2` for the first two flames of a base-set room (13 rooms hold tile `$B5`), then the cell is drawn again. Read in gameover (room `$1C`) and 11 rzx segments. | `RoomEffects` (`stage1/gameover`) | - |
| `$9AC6` | `AltTilesetRooms` | 15 | The 15 rooms drawn with the alternate tiles `$80-$FF` (SK). SetUpRoomTiles `$9880` scans all 15 (B = 15) on every room set-up; a listed room has the tiles from `$FA00` (attributes `$C580`) in place of `$F400` (`$DF80`). Read in every play build (1495 reads). doc 06, 6.3 draws room `$14` (a base-set room) from the data and it equals the screen. | `SetUpRoomTiles` | - |
| `$9AD5` | `EffectCellsA` | 16 | The tile-map addresses of the room's tiles `$B5` (base set) or `$DD` (alternate set), zero-ended. Built on every room set-up by FindTileCells `$9A8C` (from `$98C2`) after SetUpRoomTiles clears `$9AD5-$9AF4`. Read each pass by the effect routine `$91C0`: with the base set the first two cells show a tile `$B5` animated in 4 frames by PassCount `$5C02` with random pixel noise; with the alternate set the words go in pairs, two `$DD` cells on one row that `$91C0` joins with a noise beam, and the hero inside it gets event `$18` (`$9255`). 103 894 reads over the play builds; zeros in the image. | `RoomEffects`, `SetUpRoomTiles` | `SetUpRoomTiles`, `FindTileCells` (`stage1/gameover`) |
| `$9AE5` | `EffectCellsB` | 16 | The tile-map addresses of the room's tiles `$8C` (alternate set only), zero-ended. Built by FindTileCells from `$98D0` when the alternate set is in; read each pass by `$9282` through `$92BD` (91 023 reads). Room `$3B` has the most, 6. | `SetUpRoomTiles`, `Capsules` (`stage1/rzx/r18000`), `RoomEffects` (`stage1/rzx/r26000`), `ShowCapsules` (`stage1/rzx/r18000`) | `SetUpRoomTiles`, `FindTileCells` (`stage1/rzx/r18000`) |
| `$9AF5` | `CheckpointRooms` | 45 | The 44 rooms where SaveRespawnPoint records the restart point, then `$FF`. SetUpRoom `$9855` scans from `$9AF5` to the first byte with bit 7 set. Listed: `$00` `$01` `$04` `$07-$09` `$0C-$0E` `$12-$15` `$17-$1B` `$1F` `$21-$23` `$26-$2A` `$2C` `$30-$36` `$38-$3B` `$3D` `$3E` `$40` `$44` `$45`. Not listed: `$02` `$03` `$05` `$06` `$0A` `$0B` `$0F-$11` `$16` `$1C-$1E` `$20` `$24` `$25` `$2B` `$2D-$2F` `$37` `$3C` `$3F` `$41-$43`. Read in every play build (6179 reads). | `SetUpRoom` | - |
| `$C600` | `BackTiles` | 4096 | The 256 back-tiles: 4 x 4 tile indices each. A room is 8 x 4 back-tiles (RoomGrids `$D600`), each 4 x 4 tiles of 8 x 8 pixels: the 32 x 16 tile map TileMap `$F800`. 242 of the 256 back-tiles appear in the 72 grids; the highest index used is `$F4`. Witness: the play builds read the back-tiles of the rooms they enter (bytemap.py). | `BuildTileMap`, `DrawTileAt` (`stage1/rzx/r12000`), `DrawTileBuffer` (`stage1/rzx/r06500`) | - |
| `$D600` | `RoomGrids` | 2304 | The back-tile grids of the 72 rooms: 32 bytes a room, 4 rows of 8. Room R (level x 12 + column) at `$D600` + 32 x R. Rooms `$46` and `$47`, past the 70 of the map, exist in both tables and are portal targets; their records in RoomCreatures `$C152` are zeros. Witness: each room the recordings enter has its 32 bytes read (bytemap.py; 57 rooms in the RZX run). | `BuildTileMap` | - |
| `$F800` | `TileMap` | 512 | The room's tile map, 32 x 16 tile indices, rebuilt on each room entry; on the tape a leftover. The builder (`$9914`) writes it from the room's grid and the back-tiles before anything reads it. The 512 bytes on the tape are the map of a room as it was when the tape was saved. | `DeadlyTileProbe`, `DrawRoom`, `FindTileCells`, `FloorDistance`, `OnLadder` +7 | `BuildTileMap`, `SetTile` (`stage1/gameover`), `SetTileBuffer` (`stage1/rzx/r18000`) |

## menu

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$94AF` | `InputDevice` | 1 | The control device: 0 keyboard, 1 Kempston, 2 Sinclair. Set by DeviceMenu `$93AF` (keys 1, 2, 3; c1 and explorers), read by the input routine `$B894` in play. | `DeviceMenu`, `ReadDevice`, `MenuLoop` (`stage1/explorers`) | `DeviceMenu`, `MenuKeys` (`stage1/explorers`), `MenuLoop` (`stage1/rzx/r00000`) |
| `$9525` | `UnusedRet` | 1 | A lone RET (`$C9`) that no code reaches. No jump, call or table in the image names `$9525`; never executed or read in any recording. | - | - |
| `$9540` | `MenuText` | 57 | The device options: four lines a blank line apart, 0 ends. Printed by PrintMenuText `$94EF` at row 8, column 8: "1 : KEYBOARD", "2 : KEMPSTON", "3 : SINCLAIR", "0 : START GAME", with `$0D $0D` between them (rows 8, 10, 12, 14). The option box of MenuLoop `$9440` covers rows 8-12. | `PrintString` | - |
| `$9579` | `CreditsText` | 132 | The credits: five lines, rows 17-21, 0 ends. Printed by DeviceMenu `$943D` at row 17, column 2, attribute `$47`. "BY  TEQUE SOFTWARE  DEV. LTD", "(c)   ARGUS PRESS SOFTWARE LTD" (`$7F` the ROM's copyright sign), "PROGRAM   SHAUN HOLLINGWORTH", "          PETE  HARRAP", "+2 MUSIC  BEN DAGLISH", each line ended by `$0D`, the last by 0 (`$95FC`). The "+2 MUSIC" line is printed on a 48K too. | `PrintString` | - |
| `$95FD` | `TitleLogo` | 600 | The TERRAMEX logo of the menu: 3 rows of 25 cells, 8 bytes a cell from the top. Drawn by DeviceMenu `$93AF` (`$9403`) at row 3, column 3, cell by cell along a row, attribute `$46` (yellow on black). 600 bytes, read in every menu (c1, explorers, gameover, rzx50000). | `DeviceMenu` | - |

## render

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9C97` | `PlotShiftUnused` | 4 | The shift step for X mod 8 = 0 (ADD HL,HL / SLL D / RLA): never reached. BufferAddress `$9CEE` points IY at `$9C97` + 4 * (X mod 8) for X mod 8 = 1-7 and at PlotRowAligned `$9CE7` for 0, so these four bytes, a shift step like the seven after them, are not executed in any of the 34 builds (only the 128K set-up's copy of the image reads them in c1). | - | - |
| `$E000` | `BackBuffer` | 2048 | The back buffer of the play window in play; on the tape and between games the saved panel's pixels. In play RenderPass `$9B22` composes the actors here, at the screen address + `$A000` (rows of the play window in the screen's layout, `$E000-$EFFF` for the top two thirds), copies their rectangles to the screen and repaints the background from the tile map. Before play the first 2048 bytes are the status panel (the screen's bottom third, `$5000-$57FF`): InitGame copies them to the screen at `$8F8B`, DeviceMenu `$93AF` cuts the menu's frame from them, and EndGame `$906D` saves the panel back here when a game ends. Witness: c1 reads all of `$E000-$E8FF` (byte counts, page 0; InitGame copies them before the first game, and EndGame has not run yet); every play build reads and writes `$DF80-$EFFF`. | `CopyCell`, `CopyCharRow`, `CopyRect`, `GameEntry`, `PlotRowAligned` +7 | `DrawRoom`, `GameEntry`, `PlotRowAligned`, `PlotRowShift6`, `RestoreRect` +7 |
| `$E800` | `SavedPanelAttrs` | 256 | The saved panel's attributes (8 rows of 32), part of the back buffer in play. Copied to `$5A00` by InitGame (`$8F8B`); saved again by EndGame `$906D` (`$907B`). | `CopyRect`, `DrawItem`, `GameEntry`, `PlotRowAligned`, `PlotRowShift6` +5 | `DrawItem`, `DrawRoom`, `GameEntry`, `PlotRowAligned`, `PlotRowShift6` +8 |
| `$E900` | `BackBufferLeftover` | 1792 | The rest of the back buffer: on the tape, leftover bytes play overwrites. No code reads these 1792 bytes before play writes them. They hold, among other bytes, twelve 24 x 24 sprites in the sprite layout at `$E930-$EC8F` that no frame number reaches (the sprite space ends at `$A7B8`; SK names three of them "captured by the snake"), drawn in src/res/leftovers/README.md. | `CopyRect`, `DrawItem`, `PlotRowAligned`, `PlotRowShift6`, `CopyBackCell` (`stage1/rzx/r18000`) +2 | `DrawItem`, `DrawRoom`, `PlotRowAligned`, `PlotRowShift6`, `RestoreRect` +5 |
| `$FE00` | `BitReverse` | 256 | Byte n reversed bit for bit: mirrors a sprite byte for the mirrored (right-facing) frames. Checked: all 256 bytes equal n reversed. Read by the mirror patch of the plotter (`$9C82`/`$9C87`). | `DrawSpriteRow` | - |
| `$FF00` | `OutlineMasks` | 256 | The outline mask of byte n: NOT (n OR n << 1 OR n >> 1). Checked: all 256 bytes follow the formula. RenderPass ANDs the screen with the mask of the rows above, at and below a sprite row, so a sprite gets a one-pixel black outline. | `DrawItem`, `DrawSpriteRow` | - |

## panel

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9FDE` | `BearerFigures` | 72 of 288 | The four bearer figures under the carried items, 24 x 24 sprites. Drawn by DrawBearers `$9EBD` (figure = log index AND 3), each 72 bytes in three columns of 24 (a row of 24 below = one column). start-room-14.png shows three of them at row 20, columns 22-30. Read in every play build (246 722 reads). | `BlitColumns` | - |
| `$A026` | `BearerFigure1` (`BearerFigures`+72) | 72 | figure 1 | `BlitColumns` | - |
| `$A06E` | `BearerFigure2` (`BearerFigures`+144) | 72 | figure 2 | `BlitColumns` | - |
| `$A0B6` | `BearerFigure3` (`BearerFigures`+216) | 72 | figure 3 | `BlitColumns` (`stage1/gameover`) | - |

## player

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A0FE` | `HeroProbes` | 4 | The hero's four contact flags, cleared and set by `$A102` each time it runs. `$A102` (IY = `$A0FE`) zeroes them and its tile tests set them. Of their uses: +0 and +1 are tested by `$A34B` before it turns the velocity `$5C34` round (+0 when moving left, +1 when moving right), +3 is tested by `$AD17` after a climb step and in `$A34B` for downward moves (known only from the code). 83 554 reads and 150 559 writes over the builds. | `HeroTileChecks`, `HeroUpdate`, `BalloonRide` (`stage1/rzx/r14000`), `BounceUp` (`stage1/gameover`), `FloatInRoom2C` (`stage1/rzx/r18000`) +6 | `HeroTileChecks`, `WallColumnCheck`, `FloorDistance` (`stage1/gameover`), `FloorScanFrom` (`stage1/rzx/r18000`), `HeadroomRows` (`stage1/rzx/r18000`) |
| `$A234` | `FloorTiles` | 14 of 23 | The floor tiles: stand on, walk through (23 bytes), then the solid tiles to their `$00` end. FloorDistance `$A1F4` scans this list from its start through ExtraSolidTiles `$A242` and SolidTiles `$A24B` to the `$00` at `$A263`, so every listed tile is a floor; the first 14 (`$95`, `$AC-$B0`, `$CF`, `$BC`, `$BD`, `$C0`, `$C1`, `$C8-$CA`) are floors only: no wall test reads them. `$BC` and `$BD` are the mud tiles of HeroTileChecks `$A102`. Read on every pass in every play recording (58740 reads of `$A234`). | `FloorDistance`, `FloorScanFrom` (`stage1/rzx/r18000`), `HeroTileChecks` (`stage1/gameover`), `SolidTileAt` (`stage1/rzx/r00000`), `WallColumnCheck` (`stage1/gameover`) | - |
| `$A242` | `ExtraSolidTiles` (`FloorTiles`+14) | 9 | `$1E` `$1F` `$31-$33` `$3C-$3F`: walls too in rooms `$18` and up (LeftWallCheck `$A2D6`) and for the creatures (SolidTileAt `$A32F`) | `FloorDistance`, `FloorScanFrom` (`stage1/rzx/r18000`), `HeroTileChecks` (`stage1/gameover`), `SolidTileAt` (`stage1/rzx/r00000`), `WallColumnCheck` (`stage1/gameover`) | - |
| `$A24B` | `SolidTiles` | 25 | The solid tiles of the normal tile set: walls and floors, `$00` end. WallColumnCheck `$A2B2` compares the tiles of a column with this list (from ExtraSolidTiles `$A242` in rooms `$18` and up); a match stops a walk (HeroUpdate `$A51A`) or turns a creature. | `FloorDistance`, `HeroTileChecks`, `WallColumnCheck`, `FloorScanFrom` (`stage1/rzx/r18000`), `SolidTileAt` (`stage1/rzx/r00000`) | - |
| `$A264` | `AltFloorTiles` | 4 of 13 | The floor tiles of the other tile set (4 bytes), then the solid ones to their `$00` end. The other tile set is in when `$918C` is not 0 (the 15 rooms of AltTilesetRooms `$9AC6`). FloorDistance `$A1F4` scans from here instead of FloorTiles `$A234`. | `FloorDistance` (`stage1/rzx/r26000`), `FloorScanFrom` (`stage1/rzx/r18000`), `SolidTileAt` (`stage1/rzx/r34000`), `WallColumnCheck` (`stage1/rzx/r18000`) | - |
| `$A268` | `AltExtraSolidTiles` (`AltFloorTiles`+4) | 9 | `$1E` `$1F` `$31-$33` `$3C-$3F` again, for the other set | `FloorDistance` (`stage1/rzx/r26000`), `FloorScanFrom` (`stage1/rzx/r18000`), `SolidTileAt` (`stage1/rzx/r34000`), `WallColumnCheck` (`stage1/rzx/r18000`) | - |
| `$A271` | `AltSolidTiles` | 34 | The solid tiles of the other tile set, `$00` end. The first 15 are those of SolidTiles `$A24B`, then 18 of the other set. | `FloorDistance` (`stage1/rzx/r26000`), `FloorScanFrom` (`stage1/rzx/r18000`), `SolidTileAt` (`stage1/rzx/r34000`), `WallColumnCheck` (`stage1/rzx/r18000`) | - |
| `$A66C` | `ExplorerRooms` | 5 | Each explorer's own room: entered from room `$29` to the left, left back to room `$29` to the right (SK, renamed). Rooms `$2D`, `$2E`, `$2F`, `$46` and `$47` for explorers 0-4. ExitLeft `$A640` reads the explorer's byte; ExitRight `$A671` sends the hero from any of these rooms to room `$29`. Each has its room handler (RoomScripts `$B7EC`: `$B370`, ExplorerRoom2E `$B263`, ExplorerRoom2F `$B22D`, ExplorerRoom46 `$B2EB`, ExplorerRoom47 `$B18A`), and each handler tests one item: the explorer's key item of the instructions. Evidence: the RZX run plays explorer 0 (one extra read of `$A66C` at the room `$29` exit). | `ExitRight` (`stage1/rzx/r00000`), `HeroUpdate` (`stage1/gameover`) | - |
| `$AF39` | `SavedSP` | 2 | The SP at HeroUpdate's start (JumpHoleCheck returns from here) | `JumpHoleCheck` (`stage1/rzx/r06500`) | `HeroUpdate` |
| `$B87C` | `InputBits` | 1 | The controls read this pass: bit 0 right, 1 left, 2 down, 3 up, 4 fire. Written by ReadDevice `$B894` every call (cleared, then the bits of the pressed controls) and read back at its end (`$B930`). Witness: written in all 34 builds (52351 writes). | `InputBitsOut`, `ReadDevice` (`stage1/explorers`) | `ReadDevice` |

## status

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A6E6` | `ThinkHints` | 72 | The item the hero thinks of in each room: 72 bytes, a row a level, `$FF` none. Read only by Think `$AB6E` (status 10, the T key): ThinkHints[room] goes to `$5B9B` and chooses BrightIdea `$ABC7` (an item) or NoIdea `$ABD9` (`$FF`). Written by InitGame (rooms `$17`, `$1A` = `$FF`, `$0F` = 7), by SetUpRoomTiles `$9880` at `$98E9` (room `$0F` = 6, in room `$10`) and by Room1ADeath `$A88F` (rooms `$17`, `$1A` = `$0C`). No recording ran Think, so the reads are known only from the code. The items fit the rooms' handlers: room `$1D` = 9 (the barrel of BarrelSpot `$AA3C`), room `$14` and `$08` = `$0A` (Hover `$AD32`), room `$0F` = 7 (BalloonRide `$AC35`). | - | `GameEntry`, `NewGame` (`stage1/explorers`), `Room1ADeath` (`stage1/rzx/r10000`), `RunSelector` (`stage1/rzx/r00000`), `SetUpRoomTiles` (`stage1/gameover`) |
| `$A72E` | `StatusHandlers` | 66 | The handlers of statuses 1-33 for StatusDispatch `$A6CC` (SK). Word N - 1 is status N. Where a status is set is said at each handler. | `JumpThroughWord` | - |
| `$A79F` | `TelescopeFrames` | 26 | The frames of status 30 (looking into the telescope), `$FF` end. Read by LookIntoTelescope `$A822` through NextFrame `$ABDE`, each frame for 2 passes. Never read in a recording (room `$12` not reached). | - | - |
| `$A83B` | `Room2DFrames` | 22 | The frames of status 28, `$FF` end | `NextFrame` (`stage1/rzx/r16000`) | - |
| `$A86E` | `Room43Frames` | 26 | The frames of status 27, `$FF` end | `NextFrame` (`stage1/rzx/r38000`) | - |
| `$A8BF` | `FallDeathFrames` | 2 of 43 | The death frame lists: status 26 (`$1C`), 23, 24, 25, each `$FF` ended | `NextFrame` (`stage1/gameover`) | - |
| `$A8C1` | `SilentDeathFrames` (`FallDeathFrames`+2) | 31 | status 23 | - | - |
| `$A8E0` | `CreatureDeathFrames` (`FallDeathFrames`+33) | 6 | status 24: `$25-$28`, then hidden | `NextFrame` (`stage1/rzx/r06000`) | - |
| `$A8E6` | `Room1ADeathFrames` (`FallDeathFrames`+39) | 4 | status 25: `$14-$16` | `NextFrame` (`stage1/rzx/r10000`) | - |
| `$A955` | `TeleportFrames` | 4 of 10 | The teleport's frames, the destination room (`$80` + room) patched in, `$FF` end | `NextFrame` (`stage1/rzx/r24750`) | `Teleport` (`stage1/rzx/r24750`), `TeleportStep` (code) |
| `$A959` | `TeleportDest` (`TeleportFrames`+4) | 1 | written by Teleport: `$BD` (room `$3D`) or `$A0` (room `$20`) | `NextFrame` (`stage1/rzx/r24750`) | `Teleport` (`stage1/rzx/r24750`), `TeleportStep` (code) |
| `$A95A` | `TeleportFramesArrive` (`TeleportFrames`+5) | 5 | - | `NextFrame` (`stage1/rzx/r24750`) | - |
| `$A9E6` | `LiftStops` | 8 | The lift's stop in each room of its shaft: room, Y of `$5B9F`. Rooms `$1F`, `$2B`, `$37`, `$43` (column 7, levels 2-5). | `LiftAtStop` (`stage1/rzx/r36000`), `LiftDown` (`stage1/rzx/r20000`) | - |
| `$AA22` | `SinkFrames` | 26 | The frames of status 17, `$FF` end | - | - |
| `$AAFA` | `BarrelArc` | 84 of 116 | Y steps of status 14, one a pass (84), signed | `BarrelRide` (`stage1/rzx/r16000`) | - |
| `$AB4E` | `BarrelShortArc` (`BarrelArc`+84) | 32 | Y steps of status 15 (32) | - | - |
| `$ABEB` | `ThinkFrames` | 9 of 47 | The frames of status 10, then 11, then 12, each `$FF` ended | - | - |
| `$ABF4` | `IdeaFrames` (`ThinkFrames`+9) | 25 | status 11 | - | - |
| `$AC0D` | `NoIdeaFrames` (`ThinkFrames`+34) | 13 | status 12 | - | - |
| `$AE69` | `JumpLoneRet` | 1 | A RET no code reaches. After JR `$AE84` at `$AE67`; no jump or call targets it (known only from the code). | - | - |
| `$AE8D` | `JumpFrames` | 17 of 34 | The frames of the 17 jump steps. 17 bytes, one frame a step. JumpRise follows at `$AE9E`: at the snap pass (step 17) JumpArc calls FrameFromTable before its CP `$11`, so the frame of that pass is JumpRise[0] = `$04`. | `FrameFromTable` (`stage1/gameover`), `JumpStepY` (`stage1/gameover`) | - |
| `$AE9E` | `JumpRise` (`JumpFrames`+17) | 17 | Y up per step: 18 up, then 18 down | `FrameFromTable` (`stage1/gameover`), `JumpStepY` (`stage1/gameover`) | - |
| `$AECD` | `RefuseFrames` | 32 | The frames played when the hero refuses a drop, `$FF` end. Started by RefuseShake `$A567`. Evidence: 7 refusals in 3 rzx segments; the instructions: "your character will obey all your instructions, even stupid ones, although this may lead to some head shaking". | `FrameListPlay` (`stage1/rzx/r00000`) | - |
| `$AEED` | `FrameListPtr` | 2 | The frame list being played, 0 when none | `HeroUpdate`, `FrameListStep` (code) | `FrameListPlay` (`stage1/rzx/r00000`), `StartFrameList` (`stage1/rzx/r00000`) |

## roomscripts

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B072` | `PadLatch` | 1 | Not 0 while the hero stands on the pad he arrived on | `TeleportPadCheck` (`stage1/rzx/r24750`) | `SetUpRoomTiles`, `TeleportPadCheck`, `Teleport` (`stage1/rzx/r24750`), `TeleportArrive` (code) |
| `$B073` | `TeleportPads` | 9 | The three pads: room, Y, X (rooms `$20`, `$3D`, `$30`) | `TeleportPadCheck`, `Teleport` (`stage1/rzx/r24750`) | - |
| `$B07C` | `CollisionText` | 58 | "TIME REMAINING TO COLLISION", CR, "DAYS:   HOURS:   MINUTES:   ", 0. Printed by TelescopeView `$A7B9`. | - | - |
| `$B2D7` | `Room2EFrames` | 20 | Object 4's frames in room `$2E` after item 4, 0 end | - | - |
| `$B4A2` | `BasketPad1` | 1 | Leftover: one byte `$79` (LD A,C) between two routines. No instruction runs or reads it in play (the load in c1 only); known only from the code. | - | - |
| `$B4D4` | `BasketPad2` | 1 | Leftover: one byte `$79` (LD A,C) between two routines. No instruction runs or reads it in play (the load in c1 only); known only from the code. | - | - |
| `$B5D1` | `SnakeTemplate` | 12 | The three snakes of room `$1A`: X, Y, frame, flags. Copied to `$5B0C-$5B17` by SnakesRoom1A `$B562` at stage 0. Witness: rzx08000 and rzx10000 read it once each. | `SnakesRoom1A` (`stage1/rzx/r08000`) | - |
| `$B6BB` | `WantedItems` | 6 | The six items the professor asks for, in order. Read by ProfessorScript `$B5DD` at index GiftCount `$5C3D`: `$0F` Formula, `$13` Coat Hanger, `$12` Battery, `$15` Atomic Pile, `$11` Button, `$17` Cup of tea (item names SK). Witness: rzx44000-rzx50000 read it at the bubbles, 11 times; the RZX run gives all six. | `ProfessorScript` (`stage1/rzx/r44000`) | - |
| `$B6C1` | `ProfFrames` | 44 | The professor's frame sequence: 43 sprite frames and the end mark `$FF`. Played one frame a pass by ProfessorScript `$B5DD` through `$ABE1` (index LabStep `$B6ED`): `$4E` (11 passes), `$45` x 3, `$46`, then `$47` / `$48` five times, `$47`, `$46`, `$45` x 3, `$4D` (13 passes; the asking pose), `$FF`. SK took it for text ("NNNNNNNNNNNEEEFGHGHGHGHGHGFEEEMMMMMMMMMMMMM"). Witness: rzx42000-rzx50000 read it while he stands. | `NextFrameAt` (`stage1/rzx/r42000`) | - |
| `$B6ED` | `LabStep` | 1 | The step index into ProfFrames, a variable. Cleared by ProfessorScript at the placing (`$B61B`) and at each stop (`$B69D`); stepped by `$ABE1`. Witness: rzx42000-rzx50000 read it 3744 times. | `NextFrameAt` (`stage1/rzx/r42000`) | `NextFrameAt` (`stage1/rzx/r42000`), `ProfessorScript` (`stage1/rzx/r42000`) |
| `$B7EC` | `RoomScripts` | 144 | The per-room script of each room `$00-$47`: a routine address, 0 for none. RunRoomScript `$B7DD` jumps to word Room (`$5C01`) through `$A6DD` every pass, with IX = the explorer object `$5B04`; a zero word does nothing. 72 words: the 70 map rooms `$00-$45` and the two rooms `$46`, `$47` that only the portals reach. 21 rooms have a script; the ones in this range: `$17` and `$1A` the snakes (`$B55A`, `$B562`), `$2D` the cricket ball (`$B370`), `$35` and `$36` the flickering floor (`$B7A3`, `$B79C`), `$39` the Silver Cross (`$B4E2`), `$3B` the professor (`$B5DD`), `$3C` the radiation (`$B784`), `$3E` and `$40` the lever (`$B72D`, `$B723`), `$3F` the basket (`$B409`), `$43` the Silver Lining (`$B704`). The others go to `$AFD7` (rooms `$03`, `$0F`), `$B16A` (`$12`), `$B0B6` (`$28`), `$A34B` (`$2C`), `$B263` (`$2E`), `$B22D` (`$2F`), `$B2EB` (`$46`) and `$B18A` (`$47`). Witness: the play builds read the words of the rooms they visit (rzx16000 and rzx18000 read word `$2D`, rzx42000-rzx50000 word `$3B`); words `$46` and `$47` are read only by the load in c1. | `JumpThroughWord` | - |
| `$BB51` | `BridgeTiles` | 4 of 8 | The tiles of the bridge's second sweep: 4 for room `$19`, 4 for room `$3A`. Indexed by the column & 3 in BridgeEffect `$BA97`. Room `$19`: `$97`, `$9A`, `$9D`, `$9E`; room `$3A` (`$BB55`): `$81` x 4. Witness: rzx08000, rzx12000 read the first four, rzx42000 the second four. | `BridgeEffect` (`stage1/rzx/r08000`) | - |
| `$BB55` | `BridgeTiles3A` (`BridgeTiles`+4) | 4 | room `$3A` | `BridgeEffect` (`stage1/rzx/r42000`) | - |

## objects

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B99D` | `ItemPlaces` | 60 of 93 | Where the items lie: 31 records of 3 bytes, [room + taken bit, item, position]. Byte 0: the room (`$00-$47`) in bits 0-6, bit 7 set when the item has been taken (PickUpItem `$BB6C` sets it through the record address the slot keeps; it then matches no room). Byte 1: the item (0-31, an index into the item sprites `$8400`) in bits 0-4 and bits 3-5 of X in bits 5-7. Byte 2: bits 6-7 of X in bits 0-1 and Y / 8 in bits 2-7 (byte2 & `$FC` = Y / 2). So X = (byte2 & 3) * 64 + (byte1 & `$E0`) / 4 and Y = (byte2 & `$FC`) * 2, both multiples of 8 (PlaceItem `$B95F`). Checked live: record 15 (room `$21`, Barrel Small, byte2 `$24`) lies at X `$28`, Y `$48` (work/stage2/probe_points.py). ResetItems `$B932` clears every taken bit at a new game; InitGame then sets the one of record 20 (`$B9D9`, the Energy Crystal of room `$30`) at `$8F86`, so that crystal is not there until the explorer puts it in place (ItemsPass `$B9FA` clears the bit again). SpawnRoomItems `$B93F` scans the records for the room on every room entry and puts the first two matches in the item slots `$5C0E` and `$5C13`; no room has more than two. The Formula (15) lies in each of the four portal rooms `$2E`, `$2F`, `$46`, `$47`; rooms `$10` and `$1D` hold two items each. The item names are those of the SkoolKit notes (SK, Items-Format.md); in-play checks: the pickups the play builds make (PickUpItem `$BBE4`, 22 runs in 13 builds). | `GameEntry`, `PickUpItem`, `PlaceItem`, `ResetItems`, `SpawnRoomItems` +3 | `GameEntry`, `PickUpItem`, `ResetItems`, `ItemsPass` (`stage1/rzx/r24750`), `NewGame` (`stage1/explorers`) +1 |
| `$B9D9` | `CrystalPlace` (`ItemPlaces`+60) | 33 | 20: room `$30`, item 24 Energy Crystal, X `$48`, Y `$60` | `GameEntry`, `ResetItems`, `SpawnRoomItems`, `ItemsPass` (`stage1/rzx/r24750`), `NewGame` (`stage1/explorers`) +3 | `GameEntry`, `ResetItems`, `ItemsPass` (`stage1/rzx/r24750`), `NewGame` (`stage1/explorers`), `PickUpItem` (`stage1/rzx/r22000`) +1 |
| `$BA96` | `SwapLatch` | 1 | 1 while the S key is held after a swap, so one press swaps once. Witness: written every pass in all 34 builds. | `ItemsKeys` (`stage1/rzx/r24750`), `ItemsPass` (`stage1/gameover`) | `ItemsPass`, `ItemsKeys` (`stage1/rzx/r24750`) |

## score

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$BE18` | `PlaceValues` | 12 | 1000, 100, 10, 1 as 24-bit numbers, low byte first. Read by PrintNumber `$BD78` (IY). Witness: every build that prints a score (21 builds). | `PrintNumber`, `PrintScore` (`stage1/rzx/r00000`) | - |

## creatures

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$BE24` | `CreatureRecords` | 10 of 30 | The room's three creatures as DecodeRoomCreatures unpacks them: 3 records of 10 bytes. Written by DecodeRoomCreatures `$BE42` from RoomCreatures `$C152` on every room entry; run by RunCreatures `$BE98` (IY = the record). +0 the type (the handler, CreatureHandlers `$BECA`), +1 the type again (the fliers put it back from here when they leave the room), +2 the hit flag (bit 7), +3 the hit frame (0-7), +4 the first sprite frame, +5 the start X, +6 the start Y, +7 the animation counter with the direction in bit 7, +8 the timer (bit 0 set once placed: PlaceCreature `$C135`), +9 unused. Split from the place values here (the cut had one block `$BE18-$BE41`). Witness: read and written by every play build. | `AnimateCreature`, `CreatureTimer`, `DecodeRoomCreatures`, `LeftFlier`, `PlaceCreature` +7 | `AnimateCreature`, `CreatureTimer`, `DecodeRoomCreatures`, `LeftFlier`, `PlaceCreature` +5 |
| `$BE2E` | `CreatureRecord2` (`CreatureRecords`+10) | 10 | - | `AnimateCreature`, `CreatureTimer`, `DecodeRoomCreatures`, `LeftFlier`, `PlaceCreature` +6 | `AnimateCreature`, `CreatureTimer`, `DecodeRoomCreatures`, `LeftFlier`, `PlaceCreature` +4 |
| `$BE38` | `CreatureRecord3` (`CreatureRecords`+20) | 10 | - | `DecodeRoomCreatures`, `RunCreatures`, `AnimateCreature` (`stage1/rzx/r04000`), `CreatureTimer` (`stage1/rzx/r02000`), `DropCreature` (`stage1/rzx/r02000`) +4 | `DecodeRoomCreatures`, `AnimateCreature` (`stage1/rzx/r04000`), `CreatureTimer` (`stage1/rzx/r02000`), `DropCreature` (`stage1/rzx/r02000`), `PlaceCreature` (`stage1/rzx/r02000`) +2 |
| `$BECA` | `CreatureHandlers` | 18 | The handler of each creature type 0-8. Type 0 NoCreature, 1 WalkerCreature, 2 ClimberCreature, 3 LeftFlier, 4 RightFlier, 5 DropCreature, 6 StillCreature, 7 RiserCreature, 8 PlaceCreature (scenery: put in place every pass). Witness: every play build reads the words of the types its rooms hold. | `RunCreatures` | - |
| `$C12D` | `TileScanFlags` | 4 of 8 | The results of the creatures' tile tests: two records of 4 bytes. `$A2AC` and `$A2FA` write +0 and +1 through IY = `$C12D`, `$A31F` and `$A30B` write +4 and +5 through IY = TileScanSecond `$C131` (LeftWallCheck, RightWallCheck, CreatureSolidAt, CreatureFloorBelow). +2, +3, +6, +7 are only read by the load in c1. SK took `$C12E-$C134` for NOPs (code). | `LeftFlier`, `ClimberCreature` (`stage1/rzx/r34000`), `DropCreature` (`stage1/rzx/r00000`), `RightFlier` (`stage1/rzx/r00000`), `WalkerCreature` (`stage1/rzx/r02000`) +1 | `WallColumnCheck`, `SolidTileAt` (`stage1/rzx/r00000`) |
| `$C131` | `TileScanSecond` (`TileScanFlags`+4) | 4 | - | `ClimberCreature` (`stage1/rzx/r34000`), `DropCreature` (`stage1/rzx/r00000`), `DropStep` (code) | `SolidTileAt` (`stage1/rzx/r00000`) |
| `$C152` | `RoomCreatures` | 864 | The creatures of each room `$00-$47`: 3 records of 4 bytes a room, 12 bytes. DecodeRoomCreatures `$BE42` reads the 12 bytes at `$C152` + 12 x Room on every room entry (from `$9855`) and unpacks each 4-byte record into a 10-byte record of CreatureRecords `$BE24`, which RunCreatures `$BE98` runs every pass in the object slots `$5B08`, `$5B0C`, `$5B10` (record k in slot k + 1). An all-zero record is an empty slot (type 0, RET). The record: byte 0 = the hit flag in bit 7, the hit frame in bits 4-6 (0-7; 4 and more: every frame hits), the type in bits 0-3 (an index into CreatureHandlers `$BECA`); byte 1 = the first sprite frame of its animation (the object frame byte, IX+2); byte 2 = the start X; byte 3 = the start Y in bits 0-6 and the start direction in bit 7 (types 1 and 2: set = moving right / down; the fliers force it, 3 clear and 4 set; AnimateCreature copies it to the object flag byte IX+3 with the animation counter). The hit flag and the hit frame are used by AnimateCreature `$C0AC` and RiserCreature `$C069` only; the drop (`$BFF6`) always tests contact. The types: 1 walker (2 pixels a pass along X, turns at a wall or the room edge, WalkerCreature `$BEDD`), 2 climber (the same along Y, ClimberCreature `$BF22`), 3 left flier and 4 right flier (wait a random time, then fly across once, `$BF67`, `$BFBB`), 5 drop (waits, falls, splashes with sound 5, `$BFF6`), 6 still (animated in place until its frame is `$55` or `$7F`, `$C054`), 7 riser (rises and sinks in a cycle with random pauses, `$C069`), 8 scenery (put in place every pass, never animated, never hits: CreatureHandlers points type 8 straight at PlaceCreature `$C135`). Counted over the 72 rooms: 33 drops, 20 risers, 10 walkers, 10 scenery, 8 still, 3 right fliers, 2 left fliers, 2 climbers. The sprite frames the types use: drops `$5C`, risers `$58`, walkers `$60` / `$78` / `$6B`, the snakes of room `$17` `$51` (SnakesRoom17 `$B55A` and RunSnakes `$B57C` animate them), still ones `$64`; SK names (Room-Format.md / Actors.md): `$05` Water Drop, `$07` Tentacles in a concrete block, `$01` / `$03` Flying Lizard. 72 rooms (864 bytes, to `$C4B1`), the 70 of the map and the portal rooms `$46`, `$47` (both empty). Witness: every play build reads the records of the rooms it enters, 4 bytes at a time a slot (DecodeRoomCreatures, L1 105 runs in 31 builds); rooms `$01`, `$02`, `$05`, `$06`, `$11`, `$12`, `$1E`, `$21`, `$24`, `$25`, `$2E`, `$2F`, `$46`, `$47` are read only by the load in c1. | `DecodeRoomCreatures` | - |

## sound

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C55B` | `SoundEffects` | 14 | The players of the sounds 0-6. Read by SoundDispatch `$C4BC`: 0 SoundRise, 1 SoundRomFall, 2 SoundChirp, 3 SoundHiss, 4 SoundRomBurst, 5 SoundBeepHigh, 6 SoundBeepLow. Witness: the play builds read the words of the sounds they play. | `SoundDispatch` | - |
| `$C569` | `SoundPad` | 23 | Leftover: 23 bytes (`$00` x 16, then `$03` `$00` `$02` `$00` `$01` `$00` `$00`) no code refers to. No instruction of the image names an address in `$C569-$C57F` and no play build reads them (the load in c1 only); known only from the code. | - | - |

## tiles

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C580` | `AltTileAttrs` | 128 | The attributes of the alternate upper tiles `$80-$FF`. In a room of AltTilesetRooms `$9AC6` the room builder swaps these 128 bytes with TileAttrs+`$80` (`$DF80`) and AltTilePixels `$FA00` with TilePixels+`$400` (`$F400`); the next room on the base set swaps them back. Witness: written and read in the rzx builds 18000, 20000, 26000 (the swap `$918D`). | `SwapTileset` (`stage1/rzx/r18000`) | `SwapTileset` (`stage1/rzx/r18000`) |
| `$DF00` | `TileAttrs` | 256 | The attribute of each of the 256 tiles. Looked up by tile index (A + `$DF00`) when the tile map is drawn (`$99A4`). `$DF80-$DFFF` are swapped with AltTileAttrs `$C580` in the rooms on the alternate set. | `DrawRoom`, `SwapTileset` (`stage1/rzx/r18000`) | `SwapTileset` (`stage1/rzx/r18000`) |
| `$F000` | `TilePixels` | 2048 | The 256 tiles' pixels: 8 bytes each. Tile T at `$F000` + 8 x T (the word `$5B72` = `$F000`). `$F400-$F7FF` (tiles `$80-$FF`) are swapped with AltTilePixels `$FA00` in the rooms on the alternate set. | `DrawRoom`, `RestoreRect`, `DrawTileAt` (`stage1/gameover`), `DrawTileBuffer` (`stage1/rzx/r06500`), `RestoreActorBackgrounds` (`stage1/rzx/r08000`) +2 | `Capsules` (`stage1/rzx/r18000`), `RoomEffects` (`stage1/gameover`), `SwapTileset` (`stage1/rzx/r18000`) |
| `$FA00` | `AltTilePixels` | 1024 | The alternate upper tiles `$80-$FF`: 128 tiles of 8 bytes | `SwapTileset` (`stage1/rzx/r18000`) | `SwapTileset` (`stage1/rzx/r18000`) |


## Tape BASIC and loader (`src/tape/basic.json`)

Terramex, Grandslam 1987: TZX block 2, the BASIC program "TERRAMEX" (302 bytes at PROG `$5CCB`, LINE 0, the program
58 bytes): line 0 and, in the variables area at VARS `$5D05`, the machine-code loader entered at `$5D08`. Its
entries are `src/tape/<module>.asm`, written from `src/tape/basic.ann` by `kit/mkgame.py --part
src/tape/basic.json`; the readers and writers from `work/stage1/c1`.

### Tape BASIC and loader: basic

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5CCB` | `BasicLine0` | 58 | Line 0: RANDOMIZE USR (0+(PEEK (00000)+000*PEEK (00000))), the hidden numbers 3, 23627, 256, 23628. USR (3 + PEEK VARS + 256 x PEEK (VARS + 1)): VARS is the system variable at `$5C4B`; the call goes to VARS + 3 = `$5D08`, LoaderEntry, the first byte of `l$`'s text. The digits printed are zeros and the hidden five-byte forms are the real numbers, so LIST shows nothing useful. c1: the ROM runs the line after the load (USR at `$34BB` enters `$5D08` at frame 696). | - | - |
| `$5D05` | `LoaderString` | 3 | The variables area: string variable `l$`, 241 bytes (the loader is its text). `$4C` = a string variable named l (bits 7-5 = 010), then its length `$00F1` = 241: `$5D08-$5DF8`, the rest of the block. The ROM never evaluates `l$`; it is only a place the BASIC keeps intact. | - | - |
| `$5DB7` | `BreakMessage` | 34 | AT 10,4; INK 7; PAPER 1; "User pressed break-reload!", `$FF` ends. Printed by BreakHandler `$5D83` through RST `$10`: the control codes `$16` (AT) 10,4, `$10` (INK) 7, `$11` (PAPER) 1, the text, `$FF` the end mark. Not read in any recording. | - | - |
| `$5DD9` | `StringPad` | 32 | 32 "*": the rest of `l$`'s 241 bytes, never read. Filler to the end of the block; no code reads it. | - | - |


## The 128K setup and the explorer selector (RAM 1) (`src/select/select.json`)

Terramex, Grandslam 1987: TZX block 4 `$7200-$9CF7`, the 128K setup and the explorer selector, assembled at `$C000`
as the setup's relocation pass leaves them in RAM 1; tools/mktape.py undoes the relocation for the tape. Its entries
are `src/select/<module>.asm`, written from `src/select/select.ann` by `kit/mkgame.py --part
src/select/select.json`; the readers and writers from `work/stage1/c1`, `work/stage1/explorers`.

### The 128K setup and the explorer selector (RAM 1): setup

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C003` | `RelocTableOffset` | 2 | The offset of RelocTable from the block's start (`$2A0F`). RelocateSelector `$C0AB` adds this word to the block's address to find RelocTable `$EA0F`. It is not itself relocated. | `SelectorStart` | - |

### The 128K setup and the explorer selector (RAM 1): relocation

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$EA0F` | `RelocTable` | 134 of 136 | The offsets of the 67 relocatable words from the block's start, a zero word ends. RelocateSelector `$C0AB` reads it once (c1: 68 words at frame 11841). The words listed are the block's own addresses: CALL, JP and LD operands; the stub, bank and paging-slot addresses are not in it. | `SelectorStart` | - |
| `$EA95` | `RelocTableEnd` (`RelocTable`+134) | 2 | the zero word | `SelectorStart` | - |

### The 128K setup and the explorer selector (RAM 1): selector

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C2B8` | `StopTapeText` | 48 | The 48K's STOP THE TAPE / THEN PRESS SPACE KEY: ROM print codes, `$0D` ends. For RST `$10`: INK 8, PAPER 8 (transparent), AT 10,9, FLASH 1, "STOP THE TAPE", FLASH 0, AT 12,6, "THEN PRESS SPACE KEY", `$0D` (the end mark ShowStopTape `$C295` tests, not printed). Not read in any recording (128K). | - | - |
| `$C2E8` | `StartTapeText` | 44 | The 48K's EXPLORER SELECTED / START TAPE: ROM print codes, `$0D` ends. For RST `$10` (PrintStartTape `$C196`): FLASH 0, INK 8, PAPER 8, AT 1,1, "EXPLORER", AT 2,1, "SELECTED", AT 5,0, FLASH 1, "START TAPE", `$0D`. Printed over the picture at the top left. Not read in any recording (128K). | - | - |
| `$C4A2` | `CursorXY` | 2 of 4 | The cursor's place (L = x, H = y) and its screen address. CursorXY: x 0-`$E8` and y 0-`$A8`, the top left of the 24 x 16 hand; SelectorRestart `$C106` sets x 100, y 80 (`$5064`), MoveCursor `$C1D5` moves it. CursorScreen `$C4A4`: the screen address DrawCursor `$C314` drew at, read by RestoreUnderCursor `$C1A2`. explorers writes `$C4A2-$C4A5`. | `DrawCursor`, `MoveCursor`, `RestoreUnderCursor` | `DrawCursor`, `MoveCursor`, `SelectorStart`, `SelectorRestart` (code) |
| `$C4A4` | `CursorScreen` (`CursorXY`+2) | 2 | the screen address of the drawn cursor | `RestoreUnderCursor` | `DrawCursor` |
| `$CD8F` | `CursorSprites` | 48 of 384 | The hand cursor: 4 frames pre-shifted 0, 2, 4, 6 pixels, 24 x 16, graphic then mask. Each frame is 96 bytes: the graphic, 3 columns of 16 bytes (column-major, top to bottom), then the mask in the same order (AND before OR). DrawCursor `$C314` picks the frame by x AND 6. explorers reads all four. | `PlotCursorByte` | - |
| `$CDBF` | `CursorMask0` (`CursorSprites`+48) | 48 | frame 0's mask | `PlotCursorByte` | - |
| `$CDEF` | `CursorFrame2` (`CursorSprites`+96) | 48 | shifted 2 pixels | `PlotCursorByte` | - |
| `$CE1F` | `CursorMask2` (`CursorSprites`+144) | 48 | - | `PlotCursorByte` | - |
| `$CE4F` | `CursorFrame4` (`CursorSprites`+192) | 48 | shifted 4 pixels | `PlotCursorByte` | - |
| `$CE7F` | `CursorMask4` (`CursorSprites`+240) | 48 | - | `PlotCursorByte` | - |
| `$CEAF` | `CursorFrame6` (`CursorSprites`+288) | 48 | shifted 6 pixels | `PlotCursorByte` | - |
| `$CEDF` | `CursorMask6` (`CursorSprites`+336) | 48 | - | `PlotCursorByte` | - |
| `$CF0F` | `SelectorPicture` | 6144 of 6912 | The selector screen: the five explorers' portraits and names, the Help box (6912 bytes). A whole screen (`$1800` bitmap, `$300` attributes): Fortisque-Smithe (top middle), Herr Krusche (top right), Big John Caine (left), Henri Beaucoup (bottom right), Wu Pong (bottom middle) and a "?" Help box (bottom left), each named under the portrait. DrawSelectorPicture `$C1C9` copies it to the screen; RestoreUnderCursor `$C1A2` reads it back under the cursor. | `DrawSelectorPicture`, `RestoreUnderCursor` | - |
| `$E70F` | `SelectorAttributes` (`SelectorPicture`+6144) | 768 | the attributes, 24 rows of 32 | `DrawSelectorPicture` | - |

### The 128K setup and the explorer selector (RAM 1): input

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C3BD` | `InputBits` | 1 of 2 | The device bits ReadDevice builds, and the device it reads. InputBits: bit 0 right, 1 left, 2 down, 3 up, 4 FIRE; InputDevice `$C3BE`: 0 keyboard, 1 Kempston, 2 Sinclair (ReadAnyDevice `$C3BF` sets it). explorers writes both (`$C3BD-$C3BE`). | `ReadDevice` | `ReadAnyDevice`, `ReadDevice` |
| `$C3BE` | `InputDevice` (`InputBits`+1) | 1 | 0 keyboard, 1 Kempston, 2 Sinclair | `ReadDevice` | `ReadAnyDevice` |

### The 128K setup and the explorer selector (RAM 1): help

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C5F9` | `Help48KText` | 271 | Help on a 48K: choose now, restart the tape; SPACE goes on, ENTER returns. PrintPage `$C574` text: " As you have a 48K machine you must choose your explorer now and then load in the rest of the program. Restart the tape when you have chosen your explorer. You will have to switch off and reload the tape to choose a new explorer.", then at column 0, row 23 "<SPACE> Continue <ENTER> Returns" and `$00`. Not read in any recording (128K); known only from the code. | - | - |
| `$C708` | `HelpTitle` | 25 | The title card: TERRAMEX INSTRUCTIONS at column 5, row 10, then `$01` (pause). explorers reads it three times (ShowHelp `$C536`). | `PrintPage` (`stage1/explorers`) | - |
| `$C721` | `HelpPage1` | 606 | Instructions page 1: Professor Albert Eyestrain, the asteroid, his formula. Professor Albert Eyestrain warned twenty years ago of a gigantic asteroid; ridiculed, he vanished, leaving a formula: "who finds it will be able to find me". The asteroid now hits within a month. Ends with "<SPACE> Continue <ENTER> Returns" at row 23 and `$00`. | `PrintPage` (`stage1/explorers`) | - |
| `$C97F` | `HelpPage2` | 510 | Instructions page 2: find the professor; 5 explorers; the VAC. Find the professor and convince him to save the world; you are one of 5 explorers in a desert mountain range with strange creatures and things that "do not behave normally"; a VAC flies over power sources in the ground ("Guess who made it ?"). | `PrintPage` (`stage1/explorers`) | - |
| `$CB7D` | `HelpPage3` | 530 | Instructions page 3: the invisible bearers and the keys. Your invisible bearers carry things, but to use something you must carry it yourself. Keys: Z left, X right, O up, K down, SPACE jump; S swap the item with the nearest; 1 move bearers and objects right, 2 left; CAPS SHIFT + Q quits and restarts; the joystick is chosen on the title page; here up, down, left, right move the hand and FIRE selects. Ends with "<SPACE> Repeats <ENTER> Returns" and `$00`. | `PrintPage` (`stage1/explorers`) | - |

### The 128K setup and the explorer selector (RAM 1): leftovers

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$EA97` | `BlockTail` | 97 | The block's last 97 bytes: attribute-like values (`$68`, `$47`, `$43`), never read. Not SelectorPicture's attributes; no code reads them and no recording reads them (explorers reads `$C708-$EA0E`). Copied with the block (and 1000 bytes of set 0 after it) to RAM 1. Known only from the code. | - | - |


## The AY music player (RAM 6) (`src/music/music.json`)

Terramex, Grandslam 1987: TZX block 4 `$6000-$71FF`, the AY music player and its tunes, which the 128K setup copies
to RAM 6, where the IM 2 handler calls it at `$C000` every frame. Its entries are `src/music/<module>.asm`, written
from `src/music/music.ann` by `kit/mkgame.py --part src/music/music.json`; the readers and writers from
`work/stage1/c1`, `work/stage1/explorers`, `work/stage1/gameover`.

### The AY music player (RAM 6): state

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C027` | `PlayerState` | 1 | 0: start tune 0 at the next call; 1: a tune is playing. Read by MusicTick `$C014` and UpdateTune `$C1E4`, set to 1 by StartTune `$C79F`, to 0 by EndTune `$C780`. The image holds 0, so the first call after the copy starts tune 0. Explorers writes it at frames 9581 and 9582 (the tune's end and the restart). | `MusicTick`, `UpdateTune` | `StartTune`, `EndTune` (`stage1/explorers`) |
| `$C028` | `Instruments` | 243 | The instruments: 27 records of 9 bytes (the shape in the module's header). Selected through SlotTable by SetInstrument `$C3D8` (IY = the record). Rates below are AttackRates/DecayRates entries: "n/f" n volume steps a frame, "1/nf" one step every n frames. Who uses a record is tune 0's use (the channel and pattern). Every real record has sustain 0, release index 10 (1/5f; with the gate off 2 frames before a note's end the release never steps: its code `$C5F0` ran in no recording) and gate-off time 2. Witness: the recordings read records 0 and 2-10 (records 1 and 11-26 are read in none). | `ReadPatternEvent` | - |
| `$C11B` | `SlotTable` | 48 | The instrument slots: 8 x channel + slot -> the record's offset (9 x record) in Instruments. Read by SetInstrument `$C3D8` (index 8 x channel + n, n 0-15), written by SetSlot `$C7F7` (8 x channel + n, n 0-31), so 48 bytes: rows 0-2 are channels A, B and C, rows 3-5 are reached only by an n beyond the channel's 8 slots (no tune does). Witness: the recordings read channel A slots 0, 3, 6, channel B 0, 3, 4, 6, channel C 2, 5, 6, 7; explorers writes `$C123` (B slot 0: `$48`, record 8) and `$C129` (B slot 6: `$51`, then `$5A`). | `ReadPatternEvent` | `SetSlot` (`stage1/explorers`) |
| `$C14B` | `TunePointer` | 2 | The current tune's entry in TuneTable. Set by StartTune `$C79F` (TuneTable + 6 x tune), read by UpdateTune `$C1E4` for each channel's order list. | `UpdateTune` | `StartTune` |
| `$C14D` | `NoteEndFlag` | 1 | Not 0: a note ended this frame (no effects, no AY write). UpdateTune `$C1E4` adds 1 for each channel whose note timer is 1 at the frame's start (the timer is set to 0 there, so the channel reads its next event this frame). ChannelEffects `$C56D` returns before the envelope and the effects, UpdateTune skips WriteAY `$C290`, and EndFrame `$C2DF` clears the flag. explorers: 1778 of 15 189 updates skip the AY write. | `ChannelEffects`, `UpdateTune` | `UpdateTune`, `EndFrame` (`stage1/explorers`) |
| `$C14E` | `MixerImage` | 1 | The AY mixer (register 7) the player writes: `$B8` at the start. Bits 0-2 tone off, 3-5 noise off for channels A, B, C, set by SetInstrument `$C3D8` from the instrument's +2 bit 7; bits 6-7 stay %10 from the image. Written to register 7 by WriteAY `$C2CB`. | `ReadPatternEvent`, `UpdateTune`, `WriteAY` (`stage1/explorers`) | `ReadPatternEvent` |
| `$C14F` | `PlayerSpare` | 4 | Not used: `$0F` and three zeros. No instruction reads or writes it (known only from the code). | - | - |
| `$C153` | `ChannelA` | 3 of 45 | Channel A's record (45 bytes, the fields in the module's header). IX for channel A in UpdateTune `$C1E4`; cleared by StartTune `$C79F`. WriteAY `$C290` reads the period and the volume, EndTune `$C780` zeroes the volume. | `ChannelEffects`, `CheckGateOff`, `ReadOrderList`, `ReadPatternEvent`, `SetTranspose` +4 | `ChannelEffects`, `CheckGateOff`, `ReadOrderList`, `ReadPatternEvent`, `SetRepeat` +5 |
| `$C156` | `ChannelATimer` (`ChannelA`+3) | 26 | +`$03` the note timer, tested by UpdateTune | `ChannelEffects`, `CheckGateOff`, `ReadPatternEvent`, `StartTune`, `UpdateChannel` +1 | `ChannelEffects`, `ReadPatternEvent`, `SetRepeat`, `StartTune`, `UpdateChannel` +1 |
| `$C170` | `ChannelAPeriod` (`ChannelA`+29) | 2 | +`$1D`/+`$1E` the tone period: AY registers 0 and 1 | `StartTune`, `UpdateTune`, `WriteAY` (`stage1/explorers`) | `ReadPatternEvent`, `StartTune` |
| `$C172` | `ChannelAVolume` (`ChannelA`+31) | 14 | +`$1F` the volume: AY register 8 | `ChannelEffects`, `CheckGateOff`, `ReadPatternEvent`, `StartTune`, `UpdateTune` +1 | `ChannelEffects`, `CheckGateOff`, `ReadPatternEvent`, `StartTune`, `EndTune` (`stage1/explorers`) |
| `$C180` | `ChannelB` | 3 of 45 | Channel B's record. As ChannelA, AY registers 2, 3 and 9. | `ChannelEffects`, `CheckGateOff`, `FetchPatternByte`, `ReadOrderList`, `ReadPatternEvent` +7 | `ChannelEffects`, `CheckGateOff`, `ReadOrderList`, `ReadPatternEvent`, `SetDetune` +7 |
| `$C183` | `ChannelBTimer` (`ChannelB`+3) | 26 | +`$03` the note timer | `ChannelEffects`, `CheckGateOff`, `ReadPatternEvent`, `StartTune`, `UpdateChannel` +1 | `ChannelEffects`, `ReadPatternEvent`, `SetDetune`, `SetRepeat`, `StartTune` +2 |
| `$C19D` | `ChannelBPeriod` (`ChannelB`+29) | 2 | +`$1D`/+`$1E` the tone period: AY registers 2 and 3 | `ChannelEffects`, `StartTune`, `UpdateTune`, `WriteAY` (`stage1/explorers`) | `ChannelEffects`, `ReadPatternEvent`, `StartTune` |
| `$C19F` | `ChannelBVolume` (`ChannelB`+31) | 14 | +`$1F` the volume: AY register 9 | `ChannelEffects`, `CheckGateOff`, `ReadPatternEvent`, `StartTune`, `UpdateTune` +1 | `ChannelEffects`, `CheckGateOff`, `ReadPatternEvent`, `StartTune`, `EndTune` (`stage1/explorers`) |
| `$C1AD` | `ChannelC` | 3 of 45 | Channel C's record. As ChannelA, AY registers 4, 5 and 10 (written only while tune 0 plays, TuneNumberOp `$C2AE`). | `ChannelEffects`, `CheckGateOff`, `FetchPatternByte`, `ReadOrderList`, `ReadPatternEvent` +5 | `ChannelEffects`, `CheckGateOff`, `ReadOrderList`, `ReadPatternEvent`, `SetRepeat` +5 |
| `$C1B0` | `ChannelCTimer` (`ChannelC`+3) | 26 | +`$03` the note timer | `ChannelEffects`, `CheckGateOff`, `ReadPatternEvent`, `StartTune`, `UpdateChannel` +1 | `ChannelEffects`, `ReadPatternEvent`, `SetRepeat`, `StartTune`, `UpdateChannel` +1 |
| `$C1CA` | `ChannelCPeriod` (`ChannelC`+29) | 2 | +`$1D`/+`$1E` the tone period: AY registers 4 and 5 | `StartTune`, `UpdateTune`, `ChannelEffects` (`stage1/explorers`), `WriteAY` (`stage1/explorers`) | `ChannelEffects`, `ReadPatternEvent`, `StartTune` |
| `$C1CC` | `ChannelCVolume` (`ChannelC`+31) | 14 | +`$1F` the volume: AY register 10 | `ChannelEffects`, `CheckGateOff`, `ReadPatternEvent`, `StartTune`, `UpdateTune` +1 | `ChannelEffects`, `CheckGateOff`, `ReadPatternEvent`, `StartTune`, `EndTune` (`stage1/explorers`) |
| `$C1DA` | `PatternPointers` | 6 | The pattern each channel is playing (A, B, C). Set to EmptyPattern `$C82D` by StartTune `$C79F`, to a pattern by StartPattern `$C34A` (PatternLo/PatternHi), read by UpdateTune `$C1E4` into DE. | `UpdateTune` | `ReadOrderList`, `StartTune` |
| `$C1E0` | `CommandParam` | 1 | A scratch byte: an order command's parameter, then a vibrato step's size. ReadOrderList `$C32A` writes the low 5 bits of an order-list command for SetRepeat `$C81B` and SetSlot `$C7F7`; VibratoStep `$C636` keeps the step's size there. | `ChannelEffects`, `SetRepeat`, `SetSlot` (`stage1/explorers`), `VibratoDown` (code), `VibratoPositive` (code) +1 | `ChannelEffects`, `ReadOrderList`, `VibratoPositive` (code), `VibratoStep` (code) |
| `$C1E1` | `PlayerSpare2` | 2 | Not used: two zeros. No instruction reads or writes it (known only from the code). | - | - |
| `$C1E3` | `ChannelIndex` | 1 | The channel being updated: 0 A, 1 B, 2 C. Set by UpdateTune `$C1E4`, read by StartPattern `$C34B` (PatternPointers) and SetInstrument `$C3F6` (the mixer bits). | `ReadOrderList`, `ReadPatternEvent`, `SlotRowOp` (code), `StartPattern` (code) | `UpdateTune` |

### The AY music player (RAM 6): channel

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C33E` | `OrderJumpPad1` | 1 | A filler byte: the jump table's entries are 4 bytes apart. Never executed or read: JR d lands on the JP after it (known only from the code). | - | - |
| `$C342` | `OrderJumpPad2` | 1 | A filler byte between the jumps. Never executed or read (known only from the code). | - | - |
| `$C346` | `OrderJumpPad3` | 1 | A filler byte between the jumps. Never executed or read (known only from the code). | - | - |

### The AY music player (RAM 6): tunes

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C82D` | `EmptyPattern` | 1 | A pattern of no events: every channel's pattern at a tune's start. StartTune `$C79F` points PatternPointers `$C1DA` at it, so a channel's first frame reads `$FF` and goes to its order list. Witness: read by every recording that starts a tune (c1, explorers, the rzx pieces with an EndTune). | `ReadPatternEvent` | - |
| `$C82E` | `PeriodLo` | 108 | The tone periods' low bytes: 108 notes, C0 to B8. Index i (StartNote `$C4C9`: the note + 20 + the transpose; ArpeggioEffect adds the step's semitones) is MIDI note i + 12 at the AY clock of 1.7734 MHz: index 57 = 252 = A4 (439.8 Hz). The period is PeriodLo[i] + 256 x PeriodHi[i]. Two flaws: every C# (indices 1, 13, 25, ..., 85) is 0.38 semitone flat, and index 8 (G#0, 4526) is G0's period again. Tune 0 plays C# at indices 25 and 61 (7 notes). The recordings read indices 14-96. | `ChannelEffects`, `ReadPatternEvent` | - |
| `$C89A` | `PeriodHi` | 108 | The tone periods' high bytes: 108 notes. As PeriodLo. Its last 8 bytes (`$C8FE-$C905`, all 0) are also VibratoTable-8's record 0, which no instrument names (offset 0 is no vibrato). | `ChannelEffects`, `ReadPatternEvent` | - |
| `$C906` | `VibratoTable` | 8 | The vibrato record at offset 8: a delay of 40 frames, the deltas +1, 0, -1, 0, +1, 0, -1. Addressed as VibratoTable-8 + the instrument's +7 (StartNote `$C51E`, VibratoStep `$C631`): byte 0 the delay (bit 7 clear) or cycles (bit 7 set), bytes 1-7 the signed period deltas of one half cycle. Instruments 4, 5 and 7 name it. Witness: the recordings read all 8 bytes. | `ChannelEffects`, `ReadPatternEvent` | - |
| `$C90E` | `VibratoSpare` | 25 | 25 bytes after the vibrato record that nothing reads. No instrument's +7 points here and no recording reads them; as vibrato records their deltas would be 18 to 128 period units. Known only from the code: left over. | - | - |
| `$C927` | `ArpeggioTable` | 64 | The arpeggios: 8 records of 8 bytes, record n at ArpeggioTable + 8n (n 1-7; 0 is off). A record: a header (bit 7: loop; bits 3-6: the hold of the base note at the note's start, + 1; bits 0-2: the number of steps), then the steps (bits 3-7: the semitones over the note, bits 0-2: the hold in frames, 0 = 256). Read by StartNote `$C52A` and ArpeggioEffect `$C694`. Witness: the recordings read records 1-6 (the header and the steps). | `ChannelEffects`, `ReadPatternEvent` | - |
| `$C967` | `TuneTable` | 24 | The tunes: 4 entries of 3 words, the order lists of channels A, B and C. StartTune `$C79F`: TunePointer `$C14B` = TuneTable + 6 x tune. Tunes 0, 2 and 3 are the same entry; tune 1 has its own lists. Only tune 0 is ever started (the player module). Witness: the recordings read entry 0 (`$C967-$C96C`) only. | `UpdateTune` | - |
| `$C97F` | `Tune0OrderA` | 51 | Tune 0, channel A: the order list (9696 frames). Read by ReadOrderList `$C310` and the order commands. Witness: the recordings read it whole. | `ReadOrderList`, `SetTranspose` | - |
| `$C9B2` | `Tune0OrderB` | 40 | Tune 0, channel B: the order list (9696 frames). Read by ReadOrderList `$C310` and the order commands. Witness: the recordings read it whole. | `ReadOrderList`, `SetDetune`, `SetTranspose`, `SetSlot` (`stage1/explorers`) | - |
| `$C9DA` | `Tune0OrderC` | 43 | Tune 0, channel C: the order list (10 236 frames, cut at 9696 by channel A's end). Read by ReadOrderList `$C310` and the order commands. Witness: the recordings read it whole. | `ReadOrderList`, `SetTranspose` | - |
| `$CA05` | `Tune1OrderA` | 10 | Tune 1, channel A: the order list (4728 frames). Known only from the code: tune 1 is never started, no recording reads it. | - | - |
| `$CA0F` | `Tune1OrderB` | 23 | Tune 1, channel B: the order list (4728 frames). Known only from the code: tune 1 is never started, no recording reads it. | - | - |
| `$CA26` | `Tune1OrderC` | 15 | Tune 1, channel C: the order list (5268 frames). Known only from the code: tune 1 is never started, no recording reads it. | - | - |
| `$CA35` | `TuneSpare` | 2 | Two `$FF` bytes after tune 1's channel C list. Not read in any recording (known only from the code). | - | - |
| `$CA37` | `PatternLo` | 27 | The 27 patterns' addresses: the low bytes. StartPattern `$C353`: pattern n is at PatternLo[n] + 256 x PatternHi[n]. Witness: the recordings read the entries of the patterns tune 0 plays. | `ReadOrderList` | - |
| `$CA52` | `PatternHi` | 27 | The 27 patterns' addresses: the high bytes. As PatternLo. | `ReadOrderList` | - |
| `$CA6D` | `Pattern0` | 10 | Pattern 0: 432 frames (tune 0 A x3, tune 0 B x5). Read by ReadPatternEvent `$C2F6`, PatternEvent `$C36D`, StartNote `$C4C9` and FetchPatternByte `$C825`. Witness: the recordings read it whole. | `ReadPatternEvent` | - |
| `$CA77` | `Pattern1` | 15 | Pattern 1: 432 frames (tune 1 B x2). Known only from the code: no played tune holds it, no recording reads it. | - | - |
| `$CA86` | `Pattern2` | 13 | Pattern 2: 54 frames (tune 0 C x66, tune 1 C x30). Read by ReadPatternEvent `$C2F6`, PatternEvent `$C36D`, StartNote `$C4C9` and FetchPatternByte `$C825`. Witness: the recordings read it whole. | `ReadPatternEvent` | - |
| `$CA93` | `Pattern3` | 8 | Pattern 3: 216 frames (tune 0 A x1, tune 0 B x1). Read by ReadPatternEvent `$C2F6`, PatternEvent `$C36D`, StartNote `$C4C9` and FetchPatternByte `$C825`. Witness: the recordings read it whole. | `ReadPatternEvent` | - |
| `$CA9B` | `Pattern4` | 17 | Pattern 4: 648 frames (no tune). Known only from the code: no played tune holds it, no recording reads it. | - | - |
| `$CAAC` | `Pattern5` | 22 | Pattern 5: 108 frames (tune 0 A x32, tune 0 B x4). Read by ReadPatternEvent `$C2F6`, PatternEvent `$C36D`, StartNote `$C4C9` and FetchPatternByte `$C825`. Witness: the recordings read it whole. | `ReadPatternEvent` | - |
| `$CAC2` | `Pattern6` | 52 | Pattern 6: 1728 frames (tune 0 B x2). Read by ReadPatternEvent `$C2F6`, PatternEvent `$C36D`, StartNote `$C4C9` and FetchPatternByte `$C825`. Witness: the recordings read it whole. | `FetchPatternByte`, `ReadPatternEvent` | - |
| `$CAF6` | `Pattern7` | 27 | Pattern 7: 108 frames (tune 0 C x20). Read by ReadPatternEvent `$C2F6`, PatternEvent `$C36D`, StartNote `$C4C9` and FetchPatternByte `$C825`. Witness: the recordings read it whole. | `ReadPatternEvent` | - |
| `$CB11` | `Pattern8` | 27 | Pattern 8: 108 frames (tune 0 C x4). Read by ReadPatternEvent `$C2F6`, PatternEvent `$C36D`, StartNote `$C4C9` and FetchPatternByte `$C825`. Witness: the recordings read it whole. | `ReadPatternEvent` | - |
| `$CB2C` | `Pattern9` | 28 | Pattern 9: 108 frames (tune 0 C x4). Read by ReadPatternEvent `$C2F6`, PatternEvent `$C36D`, StartNote `$C4C9` and FetchPatternByte `$C825`. Witness: the recordings read it whole. | `ReadPatternEvent` | - |
| `$CB48` | `Pattern10` | 66 | Pattern 10: 384 frames (tune 0 A x8, tune 1 A x8). Read by ReadPatternEvent `$C2F6`, PatternEvent `$C36D`, StartNote `$C4C9` and FetchPatternByte `$C825`. Witness: the recordings read it whole. | `ReadPatternEvent` | - |
| `$CB8A` | `Pattern11` | 66 | Pattern 11: 384 frames (tune 0 C x3, tune 1 C x3). Read by ReadPatternEvent `$C2F6`, PatternEvent `$C36D`, StartNote `$C4C9` and FetchPatternByte `$C825`. Witness: the recordings read it whole. | `ReadPatternEvent` (`stage1/explorers`) | - |
| `$CBCC` | `Pattern12` | 3 | Pattern 12: 144 frames (tune 0 B x1). Read by ReadPatternEvent `$C2F6`, PatternEvent `$C36D`, StartNote `$C4C9` and FetchPatternByte `$C825`. Witness: the recordings read it whole. | `FetchPatternByte` (`stage1/explorers`), `ReadPatternEvent` (`stage1/explorers`) | - |
| `$CBCF` | `Pattern13` | 98 | Pattern 13: 384 frames (tune 0 B x6, tune 1 B x6). Read by ReadPatternEvent `$C2F6`, PatternEvent `$C36D`, StartNote `$C4C9` and FetchPatternByte `$C825`. Witness: the recordings read it whole. | `ReadPatternEvent` (`stage1/explorers`) | - |
| `$CC31` | `Pattern14` | 46 | Pattern 14: 384 frames (tune 0 C x4, tune 1 C x4). Read by ReadPatternEvent `$C2F6`, PatternEvent `$C36D`, StartNote `$C4C9` and FetchPatternByte `$C825`. Witness: the recordings read it whole. | `ReadPatternEvent` (`stage1/explorers`) | - |
| `$CC5F` | `Pattern15` | 34 | Pattern 15: 1656 frames (tune 0 A x1, tune 1 A x1). Read by ReadPatternEvent `$C2F6`, PatternEvent `$C36D`, StartNote `$C4C9` and FetchPatternByte `$C825`. Witness: the recordings read it whole. | `ReadPatternEvent` (`stage1/explorers`) | - |
| `$CC81` | `Pattern16` | 96 | Pattern 16: 384 frames (tune 0 B x1, tune 1 B x1). Read by ReadPatternEvent `$C2F6`, PatternEvent `$C36D`, StartNote `$C4C9` and FetchPatternByte `$C825`. Witness: the recordings read it whole. | `ReadPatternEvent` (`stage1/explorers`) | - |
| `$CCE1` | `Pattern17` | 46 | Pattern 17: 384 frames (tune 0 C x1, tune 1 C x1). Read by ReadPatternEvent `$C2F6`, PatternEvent `$C36D`, StartNote `$C4C9` and FetchPatternByte `$C825`. Witness: the recordings read it whole. | `ReadPatternEvent` (`stage1/explorers`) | - |
| `$CD0F` | `Pattern18` | 15 | Pattern 18: 96 frames (tune 0 B x2, tune 1 B x2). Read by ReadPatternEvent `$C2F6`, PatternEvent `$C36D`, StartNote `$C4C9` and FetchPatternByte `$C825`. Witness: the recordings read it whole. | `ReadPatternEvent` (`stage1/explorers`) | - |
| `$CD1E` | `Pattern19` | 12 | Pattern 19: 72 frames (tune 0 B x3, tune 1 B x3). Read by ReadPatternEvent `$C2F6`, PatternEvent `$C36D`, StartNote `$C4C9` and FetchPatternByte `$C825`. Witness: the recordings read it whole. | `ReadPatternEvent` (`stage1/explorers`) | - |
| `$CD2A` | `Pattern20` | 4 | Pattern 20: 192 frames (tune 0 C x1, tune 1 C x1). Read by ReadPatternEvent `$C2F6`, PatternEvent `$C36D`, StartNote `$C4C9` and FetchPatternByte `$C825`. Witness: the recordings read it whole. | `ReadPatternEvent` (`stage1/explorers`) | - |
| `$CD2E` | `Pattern21` | 1 | Pattern 21: empty (`$FF` only); no tune plays it. Not read in any recording (known only from the code). | - | - |
| `$CD2F` | `Pattern22` | 1 | Pattern 22: empty (`$FF` only); no tune plays it. Not read in any recording (known only from the code). | - | - |
| `$CD30` | `Pattern23` | 1 | Pattern 23: empty (`$FF` only); no tune plays it. Not read in any recording (known only from the code). | - | - |
| `$CD31` | `Pattern24` | 1 | Pattern 24: empty (`$FF` only); no tune plays it. Not read in any recording (known only from the code). | - | - |
| `$CD32` | `Pattern25` | 1 | Pattern 25: empty (`$FF` only); no tune plays it. Not read in any recording (known only from the code). | - | - |
| `$CD33` | `Pattern26` | 3 | Pattern 26: 192 frames (tune 0 B x1, tune 0 C x2, tune 1 B x4, tune 1 C x2). Read by ReadPatternEvent `$C2F6`, PatternEvent `$C36D`, StartNote `$C4C9` and FetchPatternByte `$C825`. Witness: the recordings read it whole. | `FetchPatternByte`, `ReadPatternEvent` | - |
| `$CD36` | `AttackRates` | 16 | The attack rates: an instrument's +3 high nibble 1-15 (0 is the default, 15 a frame). Below `$80`: that many volume steps every frame; `$80` + n: one step every n frames. Read by SetInstrument `$C444`. Witness: the recordings read entry 7 (4 a frame, instruments 4 and 7). | `ReadPatternEvent` | - |
| `$CD46` | `DecayRates` | 16 | The decay and release rates: an instrument's +3 and +4 low nibbles 1-15. As AttackRates; read by SetInstrument `$C477` (decay) and `$C4A0` (release). Witness: the recordings read entries 6-10, 12 and 13. | `ReadPatternEvent` | - |
| `$CD5D` | `MusicLeftover` | 1187 | The rest of the block: 1187 bytes the player never reads. Known only from the code: no instruction reads `$CD5D-$D1FF` and no recording reads it in RAM 6; the copy brings it along with the player (`$6D5D-$71FF` on the tape). Bit patterns, not tune data (no pointer leads here). | - | - |


## The explorer data sets (`src/explorers/explorers.json`)

Terramex, Grandslam 1987: TZX block 4 `$9CF8-$F6F7`, the five explorer data sets of `$1200` bytes, which the
selector copies to `$6000-$71FF` for the explorer chosen (on the 128K from RAM 4 and 3). Its entries are
`src/explorers/<module>.asm`, written from `src/explorers/explorers.ann` by `kit/mkgame.py --part
src/explorers/explorers.json`; the readers and writers from `work/stage1/c1`.

### The explorer data sets: explorers

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9CF8` | `FortisqueSmitheSet` | 4608 | Set 0: Fortisque-Smithe. Witness: the explorers recording plays all five explorers (Explorer `$5B70` = 0-4 at frames 1000, 3500, 6000, 9000, 11 500) and reads each set in play at `$6000`. | - | - |
| `$AEF8` | `HerrKruscheSet` | 4608 | Set 1: Herr Krusche | - | - |
| `$C0F8` | `HenriBeaucoupSet` | 4608 | Set 2: Henri Beaucoup | - | - |
| `$D2F8` | `BigJohnCaineSet` | 4608 | Set 3: Big John Caine | - | - |
| `$E4F8` | `WuPongSet` | 4608 | Set 4: Wu Pong | - | - |


## The loading screen (`src/screen/screen.json`)

Terramex, Grandslam 1987: TZX block 3, the loading screen, loaded by the loader's LD-BYTES at `$4000`. Its entries
are `src/screen/<module>.asm`, written from `src/screen/screen.ann` by `kit/mkgame.py --part
src/screen/screen.json`; the readers and writers from `work/stage1/c1`.

### The loading screen: screen

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$4000` | `LoadingScreen` | 6912 | The loading screen: 6144 bytes of pixels, 768 of attributes. Witness: c1 loads it at `$4000` (the loader's first LD-BYTES); it stays on screen through the load of blocks 4 and 5. | - | - |
