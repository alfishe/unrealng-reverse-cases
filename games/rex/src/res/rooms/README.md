# Rooms

| File | Bytes | Address | Size | Readers |
| --- | --- | --- | --- | --- |
| `rex1.txt` | `rex1-maps.bin`, `rex1-exits.bin`, `rex1-objects.bin` | REX 1 RoomMaps `$75E0`, RoomExits `$B133`, RoomObjectLists `$AECD` | 2450, 210, 614 | DrawRoom `$C745`, ReadExits `$C8EF`, MakeObjects `$CB52` |
| `rex2.txt` | `rex2-maps.bin`, `rex2-exits.bin`, `rex2-objects.bin` | REX 2 `$7806`, `$B1A7`, `$AFC2` | 2450, 156, 485 | the same routines of part 2 |
| `demo.txt` | `demo-maps.bin`, `demo-exits.bin`, `demo-objects.bin` | DEMO `$7838`, `$B033`, `$AFEE` | 420, 36, 69 | the same routines of DEMO |

One file a part, three resources in it:

- `room N`, then `exits U R D L $ADDR`: the room numbers up, right, down and left (0 none, 99 the end of the part:
  part 1's room 34 up, the CODE panel), and the address of the room's object list (the exits' word);
- seven rows of ten block codes (hex): the map, 30 x 21 characters (blocks/, chars/);
- `list $ADDR ROOMS: ...` at the end: each object list at its address with the rooms that use it, split for the eye
  into the header | each `[kind][X][Y]` | `$FF`. The header is [spawn sides: bit 7 top, 6 right, 5 left][spawn period]
  [spawn kind] in REX 1 and REX 2 and [sides][period] in DEMO (ReadExits); up to 16 objects. The lists must follow
  each other with no gap (the build checks each address).

REX 1 has rooms 0-34 (room 0 is never entered: its exit right leads to room 1, where the game starts). REX 2 has
26 rooms in its exits table and 35 map slots: the slots 26-34 are a leftover, REX 1's rooms 26-34 with 44 to 69 of
each room's 70 codes the same, reached by no exit. DEMO has rooms 0-5; TutorRooms plays 4, 1, 0, 2.

`python3 tools/room_maps.py [--part rex1|rex2|demo|all] [--out DIR]` draws every room (`room-NN.png`) and the world
map of each part (`map.png`: the rooms placed by their exits from the first room; the rooms no exit reaches in a row
below, their numbers on orange) from these files, not from the image.
