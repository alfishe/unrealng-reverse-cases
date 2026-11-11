# Tables

Tables of rules and parameters: CSV with a header row where the records have fields, a line of hex or signed numbers
where the table is a list. `#` lines are comments; a `name` column (item-places.csv) is a reading aid that is not read
back. Lists that end in a mark keep it (`$00` or `$FF`).

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `item-places.csv` | ItemPlaces `$B99D` | 93 | ResetItems `$B932`, SpawnRoomItems `$B93F`, the pick-up | 31 records: room (+ taken bit 7), item, X, Y. Bytes: 0 = room + taken; X = (byte 2 AND 3) x 64 + (byte 1 AND `$E0`) / 4; Y = (byte 2 AND `$FC`) x 2 (PlaceItem `$B95F`; checked live: room `$21`'s Barrel Small, record 15, lies at X `$28`, Y `$48`); item = byte 1 AND `$1F` |
| `think-hints.csv` | ThinkHints `$A6E6` | 72 | ThinkHint `$ABA7` (the T key), InitGame `$8F69` | per room the item the hero thinks of, `$FF` none |
| `wanted-items.csv` | WantedItems `$B6BB` | 6 | ProfSetFrame `$B651` | the six items the professor in room `$3B` asks for, in order: `$0F` `$13` `$12` `$15` `$11` `$17` |
| `checkpoint-rooms.txt` | CheckpointRooms `$9AF5` | 45 | SetUpRoomCheckpoint `$9863` | the 44 rooms whose entry records the restart point after a death; `$FF` ends |
| `explorer-rooms.csv` | ExplorerRooms `$A66C` | 5 | ExitLeft `$A640`, ExitRight `$A671` | the room left of room `$29` for each explorer |
| `teleport-pads.csv` | TeleportPads `$B073` | 9 | TeleportPadCheck `$B03B`, TeleportJump `$A929` | the three pads: room, Y, X (rooms `$20`, `$3D`, `$30`) |
| `lift-stops.csv` | LiftStops `$A9E6` | 8 | LiftAtStop `$A9A9` | the lift's stop (Y) in each room of its shaft |
| `snakes-1a.csv` | SnakeTemplate `$B5D1` | 12 | SnakesRoom1A `$B562` | the three snakes of room `$1A`: X, Y, frame, flags |
| `bridge-tiles.txt` | BridgeTiles `$BB51` | 8 | BridgeDraw `$BADF` | the bridge tiles of room `$19`, then of room `$3A` |
| `floor-tiles.txt` | FloorTiles `$A234` | 23 | FloorScanRow `$A20B` | base set: tiles stood on but walked through; the scan runs on into SolidTiles |
| `solid-tiles.txt` | SolidTiles `$A24B` | 25 | FloorScanRow, WallColumnRow `$A2BE` | base set: walls and floors; `$00` ends |
| `alt-floor-tiles.txt` | AltFloorTiles `$A264` | 13 | FloorScanRow | the same for the alternate set (runs on into AltSolidTiles) |
| `alt-solid-tiles.txt` | AltSolidTiles `$A271` | 34 | FloorScanRow, WallColumnRow | the same for the alternate set; `$00` ends |
| `jump.txt` | JumpFrames `$AE8D` | 34 | JumpArc `$ADAC` | the 17 frames of the jump, then its 17 Y steps (signed) |
| `barrel-arcs.txt` | BarrelArc `$AAFA` | 116 | BarrelRide `$AA6F` | the barrel rides' Y steps, one a pass, signed: the long arc (84), then the short one |
