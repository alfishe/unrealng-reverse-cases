# Rooms

The 72 rooms: 70 on the 6 x 12 map (room R = level x 12 + column, levels 0-5 from the surface down) and `$46`,
`$47`, the explorers' own rooms reached through room `$29`'s left exit (tables/explorer-rooms.csv). `tools/fig_rooms.py`
draws all of them from these files and the tiles, sprites and item places (docs/img/maps/rooms.png).

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `rooms.txt` | AltTilesetRooms `$9AC6`; RoomCreatures `$C152-$C4B1`; RoomGrids `$D600-$DEFF` | 15 + 864 + 2304 | SetUpRoomTiles `$9880`, DecodeRoomCreatures `$BE42`, BuildTileMap `$9914` | per room: the 4 x 8 back-tile grid and the three creature records; the list of rooms on the alternate tiles |
| `backtiles.txt` | BackTiles `$C600-$D5FF` | 4096 | BuildTileMapCell `$992B` | the 256 back-tiles, 4 x 4 tile indices each (242 used, the highest `$F4`) |

## rooms.txt

- `alternate $RR ...`: the 15 rooms drawn with tiles/alt.png, in the table's order (the order is kept: it is the byte
  order).
- `room $RR level L column C [alternate]`: a header (the level, column and `alternate` mark are a reading aid; the room
  number orders the records).
- Four lines of 8 hex back-tile indices: the room's 32 x 16 cells as 8 x 4 back-tiles of 4 x 4 tiles.
- Three `creature` lines, `-` for an empty record: `TYPE frame $FF x $XX y $YY dir D hit H hitframe N`. The record
  bytes: byte 0 = hit (bit 7), hitframe (bits 4-6), type (bits 0-3); byte 1 = the first sprite frame of the
  animation (`$40-$7E`, frame F at `$6000 + 72 x F`); byte 2 = X in pixels; byte 3 = dir (bit 7: moving right or down)
  and Y (bits 0-6). The types are the handlers of CreatureHandlers: none, walker, climber, leftflier, rightflier, drop,
  still, riser, scenery. hit 1: only frames from hitframe on kill the hero (AnimateCreature); hit 0: every frame.

Rooms `$46` and `$47` have empty creature records.

## backtiles.txt

`NN: a b c d | e f g h | ...`: back-tile NN, four rows of four tile indices (hex), top row first. Indices from `$80`
take the upper half of the tile set, which in an alternate room is tiles/alt.png.
