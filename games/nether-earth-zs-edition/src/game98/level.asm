; --------------------------------------------------------------------------------------------------------------------
; level.asm: The level: the scenery and base lists, the shape table and the 11 shapes BuildMap turns into the map
;
; The '98's one battlefield, ZS's own: new scenery and base lists at NE's addresses and in NE's formats, NE's shape
; table and 11 shapes unchanged. BuildMap ($BC6F) expands it into Map at every new game (the map itself is not in the
; file). Docs: NE's docs/07-objects.md 7.5 (the map), 7.6 (buildings and capture points). Resource:
; src/res/game98/map/level.txt, one source for all the files of this module (sections scenery, bases, table, shape;
; format in src/res/game98/README.md, Level text).
;
; What ZS changed: SceneryWest has 66 records (NE 69) and ends at $BE6F, 9 zero bytes before SceneryEast; SceneryEast
; 68 (NE 68), both re-laid; the bases moved (the player's warbase from (22,9) to (22,14), the enemy's to (285,10),
; (412,14), (488,10)) and the factories are 2 nuclear, 5 chassis, 5 phasers, 4 of each other kind. The '98 has more
; trench (the types $0C-$0E, which only anti-grav crosses: 336 map cells against NE's 204, 21 records of the trench
; shapes 7 and 8 against 13) and more rocks ($08-$0B, tracks and anti-grav: 598 cells against 436); the walls (types
; $0F and up) cover 1382 cells, NE 1380. The rebuilt map (work/stage2/game98/mapreach.py, TestCell's limits): from the
; player's warbase a bipod reaches 5 of the 24 factories and no enemy warbase, tracks 15 factories and only the
; warbase (285,10); anti-grav reaches all (NE: every chassis reaches every base).
;
; Order of use: PlaceScenery ($BCD6) walks SceneryWest (D = 0, columns 0-255) and SceneryEast (D = 1, 256-511): a 2 x
; 2 tile block (PutBlock) or a shape of ShapeTable (DrawShape $BD61); then PlaceBases ($BCF9) walks BaseListWest /
; BaseListEast, draws shape 0 (warbase) or 1 (factory) at each and fills the capture points (Warbases, Factories) and
; the buildings. MarkBaseDestroyed ($BC1C) walks a base's shape again to lay debris. Not written in play; only the
; broken LoadNewLevel ($C23B) copies 500 bytes over it from $DD00.
;
; Formats: scenery record (tile or $80 + shape, x low byte, y), 0 ends; base record (type 0 warbase / 1-6 factory, x
; low byte, y), $FF ends; ShapeTable 11 words; a shape is 3-byte steps (tile, dx, dy): tile 0 only moves, a step with
; move (0, 0) ends the shape after its block.
; --------------------------------------------------------------------------------------------------------------------

; The scenery of columns 0-255: 66 records (tile or shape, x, y), the 0 that
; ends them, 9 zero bytes
;
; Read by BuildMap through PlaceScenery with D = 0. Bit 7 clear: a 2 x 2 block
; of that tile; bit 7 set: shape (byte & $7F) of ShapeTable. ZS's list: single
; blocks only of tiles $11 (14) and $12 (26), free-standing blocks of height 7
; and 15 that stop every chassis (NE also used the low tiles $02-$09 and $0D);
; shapes 2, 3, 6, 7, 8, 9. The 0 at $BE6F ends it; the 9 zero bytes after it
; ($BE70-$BE78) keep SceneryEast at NE's address and are never read (the level
; text keeps them as a db line). The tile heights the ship and the robots meet
; are the table $D7BC.
SceneryWest:
  INCBIN "res/game98/map/scenery-west.bin",$0000,208

; The scenery of columns 256-511: 68 records and the 0 that ends them
;
; Read by BuildMap through PlaceScenery with D = 1 (x + 256). The same record
; format as SceneryWest: bit 7 clear a 2 x 2 block of that tile (PutBlock), bit
; 7 set shape (byte AND $7F) of ShapeTable. ZS's list: tiles $07 (2), $11 (5),
; $12 (25); shapes 2-9 (NE also shape 10 and the low tiles). Its two shape 6
; records are the fence posts at the right edge, as in NE.
SceneryEast:
  INCBIN "res/game98/map/scenery-east.bin",$0000,205

; The bases of columns 0-255: 13 records (type, x, y), $FF ends
;
; Type 0 a warbase, 1-6 a factory making resource 1-6 (electronics, nuclear,
; phasers, missiles, cannon, chassis). The '98: the player's warbase at (22,14)
; and the factories (38,5) type 4, (50,9) 6, (62,13) 1, (74,9) 5, (86,5) 3,
; (143,5) 2, (143,13) 6, (155,9) 1, (167,3) 3, (167,13) 4, (247,5) 5, (247,13)
; 6 (NE: the warbase at (22,9), other factories). The (x, y) is the base's
; door: the cell a robot stands on to capture it (the capture tick $AD90) and
; where the enemy's new robots appear (warbases).
BaseListWest:
  INCBIN "res/game98/map/bases-west.bin",$0000,40

; The bases of columns 256-511: 15 records (type, x, y), $FF ends
;
; The '98: the enemy's three warbases at (285,10), (412,14), (488,10) (given to
; the enemy by BuildMap; NE (261,8), (369,8), (494,8)) and twelve factories:
; (302,3) type 3, (318,3) 1, (334,3) 2, (354,13) 4, (362,11) 6, (368,9) 3,
; (380,9) 3, (386,11) 5, (394,13) 1, (438,3) 4, (446,3) 5, (454,3) 6. With
; BaseListWest: 4 warbases and 24 factories (2 nuclear, 5 chassis, 5 phasers, 4
; of each other kind), the order of the bases table $FD70. Measured as the crow
; flies or by an anti-grav's walk, 7 factories lie nearer the player's warbase
; and 17 nearer an enemy one, as in NE.
BaseListEast:
  INCBIN "res/game98/map/bases-east.bin",$0000,46

; The shapes' addresses, index 0-10 (DrawShape)
;
; 0 the warbase, 1 the factory (both drawn by PlaceBases), 2-10 the scenery
; shapes (a scenery record $82-$8A).
ShapeTable:
  INCBIN "res/game98/map/shape-table.bin",$0000,22

; Shape 0: the warbase, 15 blocks of tiles $0F (height 7) and $10 (height 15)
; around the door
;
; Steps (tile, columns, rows): a first move of (-4,-4), then blocks reaching 4
; columns either side and up to 8 rows above the door. The pad, the block above
; the door at (x, y-4), is a tile $10 block: altitude 15 over it is the landing
; height of ConstructionMenu.
ShapeWarbase:
  INCBIN "res/game98/map/shapes/warbase.bin",$0000,48

; Shape 1: the factory, tiles $0F at (x-2, y) and (x+2, y), $10 on the roof row
; y-2 at x-2, x, x+2
;
; The door (x, y) stays free between the two low blocks.
ShapeFactory:
  INCBIN "res/game98/map/shapes/factory.bin",$0000,18

; Shape 2: 4 x 3 blocks of tiles $02-$05 (height 2)
;
; Steps (tile, dx, dy): 12 blocks in 3 rows of 4, each block 2 cells right of
; the last, a row 2 cells down (-6, 2); the tiles cycle through the four stone
; pictures. Drawn by DrawShape for scenery records $82 (5 placed). Ground
; height 2: the ship and robots pass over it.
ShapeLowTiles:
  INCBIN "res/game98/map/shapes/low-tiles.bin",$0000,36

; Shape 3: 4 x 3 blocks of tiles $08-$0B (height 6)
;
; The rock version of ShapeLowTiles: the same 3 x 4 layout with tiles $08-$0B
; (height 6). Scenery $83, 10 placed.
ShapeMidTiles:
  INCBIN "res/game98/map/shapes/mid-tiles.bin",$0000,36

; Shape 4: four blocks of tile $12 (height 15) in a column
;
; Steps of (0, 2): a wall 2 cells thick, 8 rows long, tile $12 (the tall
; block). Scenery $84, 3 placed. A nuclear blast can turn its blocks to debris.
ShapeTallWallV:
  INCBIN "res/game98/map/shapes/tall-wall-v.bin",$0000,12

; Shape 5: four blocks of tile $12 in a row
;
; Steps of (2, 0): the same wall along X, 8 columns long. Scenery $85, 8
; placed.
ShapeTallWallH:
  INCBIN "res/game98/map/shapes/tall-wall-h.bin",$0000,12

; Shape 6: four blocks of tile $15 (height 99, impassable) in a column: the
; fences at both ends of the map
;
; Placed at (12,1), (12,9), (503,1), (503,9): the row of posts at the map's
; left and right edges.
ShapeEdgeFence:
  INCBIN "res/game98/map/shapes/edge-fence.bin",$0000,12

; Shape 7: tiles $0C, $0D, $0D, $0E (height 0) in a column
;
; Steps of (0, 2): a trench along Y: start $0C, middle $0D twice, end $0E
; (height 0, drawn sunken). Scenery $87, 7 placed.
ShapeFlatLineV:
  INCBIN "res/game98/map/shapes/flat-line-v.bin",$0000,12

; Shape 8: tiles $0C, $0D, $0D, $0E in a row
;
; Steps of (2, 0): the same trench along X. Scenery $88, 6 placed.
ShapeFlatLineH:
  INCBIN "res/game98/map/shapes/flat-line-h.bin",$0000,12

; Shape 9: four blocks of tile $11 (height 7) in a row
;
; Steps of (2, 0): four low blocks $11 (height 7) in a row, a wall 8 columns
; long. Scenery $89, 10 placed.
ShapeLowWallH:
  INCBIN "res/game98/map/shapes/low-wall-h.bin",$0000,12

; Shape 10: tiles $11, $12, $11 in a row
;
; Steps of (2, 0): low, tall, low ($11, $12, $11), 6 columns. Scenery $8A, 9
; placed.
ShapeMixedWallH:
  INCBIN "res/game98/map/shapes/mixed-wall-h.bin",$0000,9

; Unused: zero to $C0FF
;
; 115 zero bytes between the level and the main menu ($C100); nothing reads or
; writes them. Room for a longer level description
; (src/res/game98/map/level.txt may grow into it without moving the code).
MapTablesSpare:
  DEFS $73                ; 115 zero bytes up to the main menu at $C100: room
                          ; for a longer level, never read
