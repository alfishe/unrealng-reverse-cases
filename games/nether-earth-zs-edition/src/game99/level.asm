; --------------------------------------------------------------------------------------------------------------------
; level.asm: The built-in level: the scenery and base lists, the shape table and the 11 shapes BuildMap turns into the map
;
; The level BuildMap ($BC6F) expands into Map at every new game (the map itself is zero in the image): the four lists
; at $BDA9-$BF9B, then ShapeTable and the shapes. The lists' room is $1F3 bytes, the size of a NELEV file before its
; tail: LOAD MAP copies a file's first $1F3 bytes here and its tail into BuildMap's operands, so a loaded map replaces
; this one until the program is loaded again.
;
; The built-in level is a placeholder: the player's warbase at (18,8) between two edge fences, the enemy's at (497,8)
; between two more, no factory, and between them, in tall blocks and walls, the Russian word ЗАГРУЗИСЬ ("load
; yourself"): the radar shows it at the first game, telling the player to load a map with LOAD MAP. Resource
; src/res/maps/builtin.txt (tools/zs_level.py, the NELEV text without the tail; preview src/res/maps/png/builtin.png).
; It has two capture points (the operands $ADB4, $BB1F) and both warbases: a capture is handed to record 26 or 27
; (GameTurnEnd), so the enemy's warbase can only be destroyed.
;
; Order of use: PlaceScenery ($BCD6) walks SceneryWest (D = 0, columns 0-255) and SceneryEast (D = 1, 256-511): a 2 x
; 2 tile block (PutBlock) or a shape of ShapeTable (DrawShape $BD61); then PlaceBases ($BCF9) walks BaseListWest /
; BaseListEast, draws shape 0 (warbase) or 1 (factory) at each and fills the capture points (Warbases, Factories) and
; the buildings. MarkBaseDestroyed ($BC1C) walks a base's shape again with debris tiles. The shapes
; (src/res/game99/map/shapes.txt) are the same bytes as Nether Earth's.
;
; Formats: scenery record (tile or $80 + shape, x low byte, y), 0 ends; base record (type 0 warbase / 1-6 factory, x
; low byte, y), $FF ends; ShapeTable 11 words; a shape is 3-byte steps (tile, dx, dy): tile 0 only moves, a step with
; move (0, 0) ends the shape after its block.
; --------------------------------------------------------------------------------------------------------------------

; The scenery of columns 0-255: 55 records (tile or shape, x, y) and the 0 that
; ends them
;
; Read by BuildMap through PlaceScenery with D = 0. Bit 7 clear: a 2 x 2 block
; of that tile; bit 7 set: shape (byte & $7F) of ShapeTable. Here: four edge
; fences (shape 6) at columns 12 and 24, around the player's warbase, and the
; letters of ЗАГРУЗИСЬ at columns 30-101, rows 3-12: tile $11 (low block) for
; the З, tile $12 (tall block) and tall walls (shape 4) for the rest.
SceneryWest:
  INCBIN "res/maps/builtin.bin",$0000,166

; The scenery of columns 256-511: 4 records and the 0 that ends them
;
; Read by BuildMap through PlaceScenery with D = 1 (x + 256): four edge fences
; (shape 6) at columns 491 and 503, rows 1 and 9, around the enemy's warbase.
SceneryEast:
  INCBIN "res/maps/builtin.bin",$00A6,13

; The bases of columns 0-255: the player's warbase at (18,8), $FF ends
;
; Type 0 a warbase, 1-6 a factory making resource 1-6 (electronics, nuclear,
; phasers, missiles, cannon, chassis). The (x, y) is the base's door. The first
; warbase placed is record 0, the player's.
BaseListWest:
  INCBIN "res/maps/builtin.bin",$00B3,4

; The bases of columns 256-511: the enemy's warbase at (497,8), $FF ends
;
; Record 1, given to the enemy by BuildMap's loop.
BaseListEast:
  INCBIN "res/maps/builtin.bin",$00B7,4

; The rest of the lists' room: zero up to $BF9B
;
; 312 zero bytes. A NELEV file's lists may fill the room up to $BF9B: LOAD MAP
; copies $1F3 bytes from $BDA9 whatever the lists use.
LevelSpare:
  INCBIN "res/maps/builtin.bin",$00BB,312

; The shapes' addresses, index 0-10 (DrawShape)
;
; 0 the warbase, 1 the factory (both drawn by PlaceBases), 2-10 the scenery
; shapes (a scenery record $82-$8A).
ShapeTable:
  INCBIN "res/map/shape-table.bin",$0000,22
  ASSERT {ShapeTable} == ShapeWarbase && {ShapeTable+2} == ShapeFactory && {ShapeTable+4} == ShapeLowTiles
  ASSERT {ShapeTable+6} == ShapeMidTiles && {ShapeTable+8} == ShapeTallWallV && {ShapeTable+10} == ShapeTallWallH
  ASSERT {ShapeTable+12} == ShapeEdgeFence && {ShapeTable+14} == ShapeFlatLineV && {ShapeTable+16} == ShapeFlatLineH
  ASSERT {ShapeTable+18} == ShapeLowWallH && {ShapeTable+20} == ShapeMixedWallH

; Shape 0: the warbase, 15 blocks of tiles $0F (height 7) and $10 (height 15)
; around the door
;
; Steps (tile, columns, rows): a first move of (-4,-4), then blocks reaching 4
; columns either side and up to 8 rows above the door. The pad, the block above
; the door at (x, y-4), is a tile $10 block: altitude 15 over it is the landing
; height of ConstructionMenu.
ShapeWarbase:
  INCBIN "res/map/shapes/warbase.bin",$0000,48

; Shape 1: the factory, tiles $0F at (x-2, y) and (x+2, y), $10 on the roof row
; y-2 at x-2, x, x+2
;
; The door (x, y) stays free between the two low blocks.
ShapeFactory:
  INCBIN "res/map/shapes/factory.bin",$0000,18

; Shape 2: 4 x 3 blocks of tiles $02-$05 (height 2)
;
; Steps (tile, dx, dy): 12 blocks in 3 rows of 4, each block 2 cells right of
; the last, a row 2 cells down (-6, 2; the tiles cycle through the four stone
; pictures. Drawn by DrawShape for scenery records $82 (5 placed). Ground
; height 2: the ship and robots pass over it.
ShapeLowTiles:
  INCBIN "res/map/shapes/low-tiles.bin",$0000,36

; Shape 3: 4 x 3 blocks of tiles $08-$0B (height 6)
;
; The rock version of ShapeLowTiles: the same 3 x 4 layout with tiles $08-$0B
; (height 6). Scenery $83, 10 placed.
ShapeMidTiles:
  INCBIN "res/map/shapes/mid-tiles.bin",$0000,36

; Shape 4: four blocks of tile $12 (height 15) in a column
;
; Steps of (0, 2): a wall 2 cells thick, 8 rows long, tile $12 (the tall
; block). Scenery $84, 3 placed. A nuclear blast can turn its blocks to debris.
ShapeTallWallV:
  INCBIN "res/map/shapes/tall-wall-v.bin",$0000,12

; Shape 5: four blocks of tile $12 in a row
;
; Steps of (2, 0): the same wall along X, 8 columns long. Scenery $85, 8
; placed.
ShapeTallWallH:
  INCBIN "res/map/shapes/tall-wall-h.bin",$0000,12

; Shape 6: four blocks of tile $15 (height 99, impassable) in a column: the
; fences at both ends of the map
;
; Placed at (12,1), (12,9), (503,1), (503,9): the row of posts at the map's
; left and right edges.
ShapeEdgeFence:
  INCBIN "res/map/shapes/edge-fence.bin",$0000,12

; Shape 7: tiles $0C, $0D, $0D, $0E (height 0) in a column
;
; Steps of (0, 2): a trench along Y: start $0C, middle $0D twice, end $0E
; (height 0, drawn sunken). Scenery $87, 7 placed.
ShapeFlatLineV:
  INCBIN "res/map/shapes/flat-line-v.bin",$0000,12

; Shape 8: tiles $0C, $0D, $0D, $0E in a row
;
; Steps of (2, 0): the same trench along X. Scenery $88, 6 placed.
ShapeFlatLineH:
  INCBIN "res/map/shapes/flat-line-h.bin",$0000,12

; Shape 9: four blocks of tile $11 (height 7) in a row
;
; Steps of (2, 0): four low blocks $11 (height 7) in a row, a wall 8 columns
; long. Scenery $89, 10 placed.
ShapeLowWallH:
  INCBIN "res/map/shapes/low-wall-h.bin",$0000,12

; Shape 10: tiles $11, $12, $11 in a row
;
; Steps of (2, 0): low, tall, low ($11, $12, $11), 6 columns. Scenery $8A, 9
; placed.
ShapeMixedWallH:
  INCBIN "res/map/shapes/mixed-wall-h.bin",$0000,9

; Unused: zero to $C0FF
;
; 115 zero bytes between the level and the main menu ($C100; nothing reads or
; writes them. The lists' room before them ends at $BF9B; these bytes follow
; the shapes.
MapTablesSpare:
  DEFS $73                ; 115 zero bytes up to the main menu at $C100: room
                          ; for a longer level, never read
