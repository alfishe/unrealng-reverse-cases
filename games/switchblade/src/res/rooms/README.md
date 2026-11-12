# Rooms

The 127 rooms and the room builder's tables, all from the game part (`src/game/game.ann`). A room is 20 x 11 cells of
12 x 16 pixels, in six planes `$6700-$6CFF` (cell = 20 x row + column). BuildRoomPlanes `$9F34` builds it: DecodeRoom
`$9F63`, the map commands from NextObjectGroup `$9FD6`, then SetupRoomObjects `$A41E` and BuildZones `$A4D1`.
work/stage2/ann/ROOM.md has the details.

| File | Address | Bytes | Format | Readers | What |
| --- | --- | ---: | --- | --- | --- |
| `rooms.txt` | Room1 `$A928` - Room127 `$D0F8` | 10193 | text, one block a room | DecodeRoom `$9F63` (through RoomDataAddress `$A3C9`, the table `$7100`), NextObjectGroup `$9FD6`, SetupRoomObjects `$A41E`, BuildZones `$A4D1` | the 126 room records (rooms 122 and 123 share Room122And123 `$CF88`) |
| `map.txt` | MapColumns `$7048`, MapRowCounts `$70C7`, MapRowStarts `$70DB` (to `$70EE`) | 167 | text grid | FindRoom `$95F9` (EnterRoom `$95C3`) | the 20 map rows, each room's number at its column |
| `outline-starts.csv` | RoomPatternStarts `$7300` | 16 | CSV | DecodeRoom `$9F63` | the low byte in page `$73` of each placement style's first outline shape |
| `outlines-1.txt` | RoomPatterns `$7310-$7329` | 26 | hex lines | DecodeRoom `$9F63` | outline shapes of styles 0-8 and 14 |
| `outlines-2.txt` | RoomPatternsMore `$732E-$7344` | 23 | hex lines | DecodeRoom `$9F63` | outline shapes of styles 9-13 and 15 (after the variables DrawColumnPos `$732A`) |
| `strings.txt` | RoomShapes `$7345-$73BC` | 120 | hex lines | ObjectPattern `$A016`, PlotPattern `$A02E` | tile strings of the commands 0-3: (tile, step) pairs, a step with bit 7 ends |
| `decor-tiles.txt` | ShapeTilesA `$73BD`, ShapeTilesB `$73C1` | 8 | hex lines | RoomOpLedge `$A357` | the decor rows of command `$E` |
| `ledge-tiles.txt` | SpecialTiles `$73C5` | 2 | hex lines | LadderCellTest `$9CB1` | the two ledge tiles `$55` and `$54` (CPIR) |
| `solid-tiles.csv` | SolidTiles `$7292` (LedgeTiles `$72B4`), TopTiles `$72D8` (to `$72DD`) | 76 | CSV (page, tile) | TestCellSolid `$A334` (from NeighbourShade `$A300` and FillBackRow `$A265`), FillBackRow `$A265` (TopTiles) | the tiles that count as solid for the wall fill and shading |
| `bars-1.csv` | StructureRecords `$7400-$74F5` (StructureSetB `$7436`, StructureSetC `$7496`, ComposeDest `$74BA`) | 246 | CSV, 6 bytes a record | StripRecordAddress `$A0EE`, StripPageFromRecord `$A101`, DrawStrip `$A109`; ComposeDest: ActorBoxStore `$8F3B`, ComposeActorCells `$8907` | the bar styles of codes 6, 9 and `$C` |
| `horizon.txt` | RoomStrip `$74F6-$7510` | 27 | hex lines | BuildSurface `$A039` | the horizon row of an open-air room: 20 bytes from `$74F5` + room |
| `bars-2.csv` | StructureSetD `$7511-$75EE` (StructureSetE `$7571`, StructureSetF `$75AD`) | 222 | CSV, 6 bytes a record | StripRecordAddress `$A0EE`, DrawStrip `$A109` | the bar styles of codes `$A`, 7, 8 and 5 |
| `default-zone.txt` | EmptyObjectList `$75FB-$75FF` | 5 | hex lines | SetupRoomObjects `$A41E`, BuildZones `$A4D1` | the zone record of a room with none: one rectangle, cells 0-`$DB` |
| `pickup-tiles.csv` | ObjectTilePlaces `$7BD8-$7BE4` | 13 | CSV (tile, page) | SetupRoomObjects `$A41E` (`$A4B8`) | a pickup type's tile and plane; `$7BE4`: one zero byte that no code reads |

## rooms.txt

There is one block a record, in address order. It starts with `room N ; $ADDR, n bytes` (`room 122 123` for the
shared record). A cell is written `@row.column`. The lines come in record order:

- `groups G0 G1 G2`: the header byte. It gives the number of placements in groups 0, 1 and 2 (0-7, 0-7, 0-3); group g
  starts its shapes g further.
- `place G nN styleS @c`: a wall outline. The first byte is N << 4 | S (N = 0 is 256 steps, S the outline style), the
  second the first cell. It draws tiles 1, or 2 and 3, on plane `$68`.
- The map commands. Each command is one byte: code = the low nibble, repeat = the high nibble.
  - `strings $PG @c=$EE ...`: codes 0-3, tile strings on plane `$68` + code. Each operand is a cell and a string's
    low byte in page `$73`.
  - `surface xN`: code 4, the open-air rows. It has no operand and is run N times. Its noise reads the 48K ROM; in
    room 123 it reads the room's own bytes.
  - `barC sS nN @c ; ...`: codes 5, 6, 7, 8, 9, `$A` and `$C`, bars. S is the style record, N the length (1-16).
  - `piece kK nN @c ; ...`: code `$B` (ObjectTypeB `$A006`). K selects the routine of RoomCodeHandlersB `$75EF`.
  - `walls styleS @c [@c]`: code `$D` (RoomOpFillBack `$A1F1`). It fills and shades the back wall from one or two
    cells with wall tile `$1A` + S.
  - `decor setH nN @c ; ...`: code `$E` (RoomOpLedge `$A357`), a row of N front tiles.
  - `nop $XX`: a command whose repeat nibble is 0. The game reads it and does nothing.
  - `end xN`: code `$F` (RoomPatch `$72DE`), the end of the commands.
- `zones default`: a 0 byte, meaning the room has the one zone of EmptyObjectList.
- `zone @a-b.c ... @c ... [bit7] [last]`: a reveal zone record. It gives rectangles (first cell - last cell), then
  single cells. `last` sets bit 3, which ends the list.
- `pickup tT nN @c`: a pickup. T is its type (pickup-tiles.csv), N its taken bit, @c its cell.
- `enemy $KK @c`: an enemy start, kind `$KK` (tables/kind-templates.csv).

The counts byte (enemies << 4 | pickups) is computed from the pickup and enemy lines. A room's record must keep its
size.

## map.txt

There are 20 rows, each listing the room numbers at their columns (0-29), with `.` where there is no room. Rooms are
numbered row by row, in the order of MapColumns. The room above a room is the one in its column on the row above
(EnterRoom). The three tables are written from the grid: the columns in room order, the counts, and the starts (the
running sum of the counts).

## The figures: tools/fig_rooms.py

`python3 tools/fig_rooms.py [--rooms 1-127] [--map] [--compare]` draws each room as the game builds and draws it
(`tools/swroom.py`, the stage-2 port). Each image shows every zone revealed and the pickups in place, with no actors.
It writes `work/stage2/fig/rooms/roomNNN.png` (the 256 x 192 screen, scaled 2x) and, with `--map`, `map.png` (the
20-row map at half scale, 3600 x 1760).

The memory it fills comes from src/res alone:

- the files above at their addresses;
- the pointers `$7100`, computed from the order of rooms.txt;
- graphics/tiles.png at `$D104`;
- graphics/enemies.png and giants.png: tile `$FF`, which room 122's open-air rows leave in plane `$68`, is read from
  `$D104 + 24 x 254`, inside the giants' frames;
- tables/cell-colours.csv at `$66F7`, where BuildPageTails puts it at run time.

The open-air rooms' noise (BuildSurface `$A039`) reads the 48K ROM from `$0000 + 257 - room`. fig_rooms takes the ROM
from `data/rom/48.rom` of the unreal-ng checkout (kitlib.unreal_root: `--unreal`, `$UNREAL_NG`, or the submodule
`R/unreal-ng`) and checks its md5, `4c42a2f075212361c3117015b107ff68`. This is the same ROM that ROOM-tmp's
swbuild.py reads.

Checks (2026-11-12):

- **Against ROOM-tmp.** For all 127 rooms, the planes `$67-$6C` of cells 0-219, built from src/res, are identical to
  those built by ROOM-tmp's room_png.py from resident.bin, and the drawn screens are identical pixel for pixel.
- **Against the recordings.** `--compare` reads work/stage2/rec/poke-roomNNN/: the room entered by a POKE of the map
  position on a 48K, end.szx, and screen.png. It draws the room with the zones end.szx has revealed (`$6DFF`) and
  compares the colour of each pixel in those cells with screen.png. The planes match end.szx byte for byte in all 15
  rooms (cells 0-219, `$67` bit 1 left out). The pixels differ only in the actors' cells: Hiro at cells 80 and 100,
  where he walks in, and the enemies.

| Room | Zones | Pixels that differ | Cells |
| ---: | --- | ---: | --- |
| 12 | `$80` | 216 of 24960 (0.87 %) | 80, 100, 169, 172 |
| 13 | `$80` | 28 of 42240 (0.07 %) | 80, 100 |
| 19 | `$40` | 43 of 19392 (0.22 %) | 80, 100 |
| 21 | `$40` | 67 of 30720 (0.22 %) | 80, 100, 143, 144 |
| 36 | `$80` | 201 of 42240 (0.48 %) | 80, 100, 122, 142, 149, 169 |
| 47 | `$80` | 227 of 42240 (0.54 %) | 5, 24, 25, 80, 92, 100 |
| 48 | `$80` | 242 of 42240 (0.57 %) | 80, 100, 133, 143, 144, 163, 164 |
| 49 | `$80` | 78 of 25344 (0.31 %) | 80, 100, 165, 166, 185, 186 |
| 50 | `$80` | 186 of 10368 (1.79 %) | 45, 63, 64, 80, 83, 84, 100 |
| 52 | `$80` | 220 of 42240 (0.52 %) | 22, 56, 57, 62, 63, 80, 100 |
| 54 | `$40` | 47 of 14400 (0.33 %) | 80, 100 |
| 55 | `$80` | 236 of 42240 (0.56 %) | 80, 100, 104, 105, 110, 124, 125, 136 |
| 91 | `$00` | no cell revealed yet | - |
| 92 | `$80` | 45 of 12288 (0.37 %) | 80, 100 |
| 109 | `$80` | 45 of 42240 (0.11 %) | 80, 100 |

ROOM-tmp's own comparisons with RZX snapshots (ROOM.md) found the same pattern: 0.04-1.46 % of pixels differ, all in
sprite or pickup cells, and no attributes differ.
