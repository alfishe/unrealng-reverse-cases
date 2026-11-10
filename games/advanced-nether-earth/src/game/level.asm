; --------------------------------------------------------------------------------------------------------------------
; level.asm: The level: the scenery and base lists, the shape table and the 11 shapes BuildMap turns into the map
;
; The one battlefield of the game, as a compact description that BuildMap ($BC6F) expands into Map at every new game
; (the map itself is not in the image). Resource: src/res/game/map/level.txt, one source for all the files of this
; module (sections scenery, bases, table, shape).
;
; Order of use: PlaceScenery ($BCD6) walks SceneryWest (D = 0, columns 0-255) and SceneryEast (D = 1, 256-511): a 2 x
; 2 tile block (PutBlock) or a shape of ShapeTable (DrawShape $BD61); then PlaceBases ($BCF9) walks BaseListWest /
; BaseListEast, draws shape 0 (warbase) or 1 (factory) at each and fills the capture points (Warbases, Factories) and
; the buildings. MarkBaseDestroyed ($BC1C) walks a base's shape again to lay debris. Never written.
;
; Formats: scenery record (tile or $80 + shape, x low byte, y), 0 ends; base record (type 0 warbase / 1-6 factory, x
; low byte, y), $FF ends; ShapeTable 11 words; a shape is 3-byte steps (tile, dx, dy): tile 0 only moves, a step with
; move (0, 0) ends the shape after its block.
; --------------------------------------------------------------------------------------------------------------------

; The scenery of columns 0-255: 69 records (tile or shape, x, y) and the 0 that
; ends them
;
; Read by BuildMap through PlaceScenery with D = 0. Bit 7 clear: a 2 x 2 block
; of that tile; bit 7 set: shape (byte & $7F) of ShapeTable. Tiles used:
; $02-$09 and $0D (low features), $11 and $12 (free-standing blocks, height 7
; and 15: the ones a nuclear blast turns to debris). Shapes 2-10. The tile
; heights the ship and the robots meet are the table $D7BC.
SceneryWest:
  INCBIN "res/game/map/scenery-west.bin",$0000,208

; The scenery of columns 256-511: 68 records and the 0 that ends them
;
; Read by BuildMap through PlaceScenery with D = 1 (x + 256). The same record
; format as SceneryWest: bit 7 clear a 2 x 2 block of that tile (PutBlock), bit
; 7 set shape (byte AND $7F) of ShapeTable. It includes the fence posts of
; shape 6 at the map's right edge (503,1), (503,9).
SceneryEast:
  INCBIN "res/game/map/scenery-east.bin",$0000,205

; The bases of columns 0-255: 13 records (type, x, y), $FF ends
;
; Type 0 a warbase, 1-6 a factory making resource 1-6 (electronics, nuclear,
; phasers, missiles, cannon, chassis). Here: the player's warbase at (22,9) and
; the factories (39,6) type 4, (53,3) 6, (62,10) 1, (79,3) 5, (97,3) 3, (125,3)
; 2, (140,11) 6, (160,5) 1, (180,3) 3, (217,3) 4, (227,9) 5, (241,3) 6. The (x,
; y) is the base's door: the cell a robot stands on to capture it (the capture
; tick $AD90) and where the enemy's new robots appear (warbases).
BaseListWest:
  INCBIN "res/game/map/bases-west.bin",$0000,40

; The bases of columns 256-511: 15 records (type, x, y), $FF ends
;
; The enemy's three warbases at (261,8), (369,8), (494,8) (given to the enemy
; by BuildMap) and twelve factories. With BaseListWest: 4 warbases and 24
; factories, four of each type, the order of the bases table $FD70.
BaseListEast:
  INCBIN "res/game/map/bases-east.bin",$0000,46

; The shapes' addresses, index 0-10 (DrawShape)
;
; 0 the warbase, 1 the factory (both drawn by PlaceBases), 2-10 the scenery
; shapes (a scenery record $82-$8A).
ShapeTable:
  INCBIN "res/game/map/shape-table.bin",$0000,22
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
  INCBIN "res/game/map/shapes/warbase.bin",$0000,48

; Shape 1: the factory, tiles $0F at (x-2, y) and (x+2, y), $10 on the roof row
; y-2 at x-2, x, x+2
;
; The door (x, y) stays free between the two low blocks.
ShapeFactory:
  INCBIN "res/game/map/shapes/factory.bin",$0000,18

; Shape 2: 4 x 3 blocks of tiles $02-$05 (height 2)
;
; Steps (tile, dx, dy): 12 blocks in 3 rows of 4, each block 2 cells right of
; the last, a row 2 cells down (-6, 2); the tiles cycle through the four stone
; pictures. Drawn by DrawShape for scenery records $82 (5 placed). Ground
; height 2: the ship and robots pass over it.
ShapeLowTiles:
  INCBIN "res/game/map/shapes/low-tiles.bin",$0000,36

; Shape 3: 4 x 3 blocks of tiles $08-$0B (height 6)
;
; The rock version of ShapeLowTiles: the same 3 x 4 layout with tiles $08-$0B
; (height 6). Scenery $83, 10 placed.
ShapeMidTiles:
  INCBIN "res/game/map/shapes/mid-tiles.bin",$0000,36

; Shape 4: four blocks of tile $12 (height 15) in a column
;
; Steps of (0, 2): a wall 2 cells thick, 8 rows long, tile $12 (the tall
; block). Scenery $84, 3 placed. A nuclear blast can turn its blocks to debris.
ShapeTallWallV:
  INCBIN "res/game/map/shapes/tall-wall-v.bin",$0000,12

; Shape 5: four blocks of tile $12 in a row
;
; Steps of (2, 0): the same wall along X, 8 columns long. Scenery $85, 8
; placed.
ShapeTallWallH:
  INCBIN "res/game/map/shapes/tall-wall-h.bin",$0000,12

; Shape 6: four blocks of tile $15 (height 99, impassable) in a column: the
; fences at both ends of the map
;
; Placed at (12,1), (12,9), (503,1), (503,9): the row of posts at the map's
; left and right edges.
ShapeEdgeFence:
  INCBIN "res/game/map/shapes/edge-fence.bin",$0000,12

; Shape 7: tiles $0C, $0D, $0D, $0E (height 0) in a column
;
; Steps of (0, 2): a trench along Y: start $0C, middle $0D twice, end $0E
; (height 0, drawn sunken). Scenery $87, 7 placed.
ShapeFlatLineV:
  INCBIN "res/game/map/shapes/flat-line-v.bin",$0000,12

; Shape 8: tiles $0C, $0D, $0D, $0E in a row
;
; Steps of (2, 0): the same trench along X. Scenery $88, 6 placed.
ShapeFlatLineH:
  INCBIN "res/game/map/shapes/flat-line-h.bin",$0000,12

; Shape 9: four blocks of tile $11 (height 7) in a row
;
; Steps of (2, 0): four low blocks $11 (height 7) in a row, a wall 8 columns
; long. Scenery $89, 10 placed.
ShapeLowWallH:
  INCBIN "res/game/map/shapes/low-wall-h.bin",$0000,12

; Shape 10: tiles $11, $12, $11 in a row
;
; Steps of (2, 0): low, tall, low ($11, $12, $11), 6 columns. Scenery $8A, 9
; placed.
ShapeMixedWallH:
  INCBIN "res/game/map/shapes/mixed-wall-h.bin",$0000,9

; Unused: zero to $C0FF
;
; 115 zero bytes between the level and the main menu ($C100); nothing reads or
; writes them. Room for a longer level description (src/res/map/level.txt may
; grow into it without moving the code).
MapTablesSpare:
  DEFS $73                ; 115 zero bytes up to the main menu at $C100: room
                          ; for a longer level, never read
