# Rooms

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `Rooms.txt` | `$BD06-$DFFF` | 8954 | DrawRoom `$6B22` (both tables), SaveRoomObjects `$6ADC`, RoomRecord `$7B8F` (ScrambleRooms `$7BA0`, NewGame `$7A2F`), the pickup in MoveDroid `$7208` | RoomLayouts `$BD06` (128 offset words, the layouts `$BE06-$DB51`, the empty layout `$DB52`) and AlienMap `$DB53` (128 offset words, the records `$DC53-$DFF9`, the empty record `$DFFA-$DFFF`): one section a room with its tiles, items, teleporter, enemies and objects. 102 rooms; 26 empty. The build lays the records out in room order and rebuilds the offsets; the code needs AlienMap at `$DB53`, so the layouts must keep their total size. Format: the file's header |
| `StartPositions.csv` | `$9484-$9583` | 256 | PlaceDroid `$7A6D` | The droid's start (x column, y pixel row) in each room after a life lost, and in room `$54` at a new game |

The world map from these: tools/fig_roommap.py (docs/img/play/world-map-rooms.png); the stage 1 map from
screenshots: tools/fig_worldmap.py (docs/img/play/world-map.png).
