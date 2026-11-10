; --------------------------------------------------------------------------------------------------------------------
; rooms.asm: The room: its record, its drawing, its items and objects
;
; The world is 128 rooms in a grid 8 rooms across and 16 down (room + 1 east, + 8 south... the exits of MoveDroid
; $7403-$7527 add 1, subtract 1, add 8 and subtract 8). Two tables give each room: the layout (RoomLayouts $BD06: the
; tiles) and the alien map (AlienMap $DB53: the items, the teleporter, the enemies and the objects). 26 rooms are
; empty: their layout is $DB52 and their alien record $DFFA. The editable form of both is src/res/rooms/.
; --------------------------------------------------------------------------------------------------------------------

; Write the room's two object records back into its alien record
;
; Walks the room's record past the item and teleporter bytes (each 1 or 2
; bytes, 0 = none) and the enemy mask, and copies Objects / Object2 (10 bytes
; each, Object1Flags bit 6 set) over the record's object fields when they are
; present. Called on every exit and teleport and on a life lost: L1 276.
SaveRoomObjects:
  LD A,(Room)
  SLA A
  LD HL,AlienMap
  LD D,$00
  LD E,A
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD HL,AlienMap
  ADD HL,DE
  XOR A
  CP (HL)
  JR Z,SaveObjectsItem2
  INC HL
SaveObjectsItem2:
  INC HL
  CP (HL)
  JR Z,SaveObjectsTeleport
  INC HL
SaveObjectsTeleport:
  INC HL
  CP (HL)
  JR Z,SaveObjectsMask
  INC HL
SaveObjectsMask:
  INC HL
  INC HL
  CP (HL)
  JR Z,SaveObjectsNoObject1
  EX DE,HL
  LD HL,Object1Flags
  SET 6,(HL)
  DEC HL
  LD BC,$000A
  LDIR
  EX DE,HL
  JR SaveObjectsObject2
SaveObjectsNoObject1:
  INC HL
SaveObjectsObject2:
  CP (HL)
  RET Z
  EX DE,HL
  LD HL,Object2Flags
  SET 6,(HL)
  DEC HL
  LD BC,$000A
  LDIR
  RET

; Enter the room: reset the movers, read the alien record, wipe and draw the
; room, build the cells
;
; In: A = 0 a scroll wipe (an exit), A not 0 a clear (a life lost, a teleport,
; a new game); Room. The sprite list is emptied; the patrollers marked not
; drawn; the four enemy records and the two objects zeroed. From the room's
; alien record (AlienMap + the word at AlienMap + 2 x Room): Item1Pos /
; Item1Kind, Item2Pos / Item2Kind, TeleportPos / TeleportRoom; the enemy mask
; (bit k: enemy k waits to spawn, timer 1 or 2, state $40, BlankGraphic); the
; two object records copied into Objects. The play area's attributes keep
; BRIGHT and INK (AND $47: paper and FLASH cleared); then the wipe:
; DrawRoomScroll shifts every line of the play area one pixel out, odd lines
; left and even lines right, eight times with a delay (L1 171 scrolls), or
; ClearPlayArea $7917 (110). The attributes are zeroed, then the layout
; (RoomLayouts + RoomLayouts[2 x Room]) is drawn tile by tile: (column, row,
; tile) triples until a column byte with bit 7. Each tile's pixels come from
; TileGraphics[tile] (width, height, rows) and its colours from TileAttrs[tile]
; (a fill byte with bit 7, or one attribute a cell), all clipped to the play
; area. Then the cell table (1 where the attribute is not 0), the items
; (ItemCell $6E88, DrawItem $6E0D for a kind with bit 7) and the teleporter
; ($FF $FF, TeleportColumn / TeleportRow). Shot = 0; DI.
;
; Witness: L1 279 rooms drawn; 6 458 tiles; the attributes' loop 161 103 cells.
DrawRoom:
  LD HL,SpriteList
  LD (SpriteListEnd),HL
  LD (HL),$00
  INC L
  LD (HL),$00
  EI
  LD (DrawMode),A
  LD HL,Patrollers
  SET 7,(HL)
  LD HL,Patroller2
  SET 7,(HL)
  LD HL,Patroller3
  SET 7,(HL)
  LD HL,Enemies
  LD DE,$0009
  LD B,$04
DrawRoomClearEnemies:
  LD (HL),$00
  ADD HL,DE
  DJNZ DrawRoomClearEnemies
  LD B,$02
  LD DE,$000A
DrawRoomClearObjects:
  LD (HL),$00
  ADD HL,DE
  DJNZ DrawRoomClearObjects
  LD A,(Room)
  LD D,$00
  LD E,A
  SLA E
  PUSH DE
  LD HL,AlienMap
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD HL,AlienMap
  ADD HL,DE
  EX DE,HL
  LD A,(DE)
  LD (RoomVars),A
  CP $00
  JR Z,DrawRoomItem2
  INC DE
  LD A,(DE)
  LD (Item1Kind),A
DrawRoomItem2:
  INC DE
  LD A,(DE)
  LD (Item2Pos),A
  CP $00
  JR Z,DrawRoomTeleport
  INC DE
  LD A,(DE)
  LD (Item2Kind),A
DrawRoomTeleport:
  INC DE
  LD A,(DE)
  LD (TeleportPos),A
  CP $00
  JR Z,DrawRoomEnemies
  INC DE
  LD A,(DE)
  LD (TeleportRoom),A
DrawRoomEnemies:
  INC DE
  LD HL,Enemies
  LD BC,$0009
  LD A,(DE)
  BIT 0,A
  JR Z,DrawRoomEnemy2
  LD (RoomRecordPtr),DE
  LD (RoomEnemyPtr),HL
  LD (HL),$01
  INC HL
  LD (HL),$40
  INC HL
  INC HL
  INC HL
  LD DE,BlankGraphic
  LD (HL),E
  INC HL
  LD (HL),D
  LD HL,(RoomEnemyPtr)
  LD DE,(RoomRecordPtr)
DrawRoomEnemy2:
  ADD HL,BC
  BIT 1,A
  JR Z,DrawRoomEnemy3
  LD (RoomRecordPtr),DE
  LD (RoomEnemyPtr),HL
  LD (HL),$02
  INC HL
  LD (HL),$40
  INC HL
  INC HL
  INC HL
  LD DE,BlankGraphic
  LD (HL),E
  INC HL
  LD (HL),D
  LD HL,(RoomEnemyPtr)
  LD DE,(RoomRecordPtr)
DrawRoomEnemy3:
  ADD HL,BC
  BIT 2,A
  JR Z,DrawRoomEnemy4
  LD (RoomRecordPtr),DE
  LD (RoomEnemyPtr),HL
  LD (HL),$01
  INC HL
  LD (HL),$40
  INC HL
  INC HL
  INC HL
  LD DE,BlankGraphic
  LD (HL),E
  INC HL
  LD (HL),D
  LD HL,(RoomEnemyPtr)
  LD DE,(RoomRecordPtr)
DrawRoomEnemy4:
  ADD HL,BC
  BIT 3,A
  JR Z,DrawRoomObjects
  LD (RoomRecordPtr),DE
  LD (RoomEnemyPtr),HL
  LD (HL),$02
  INC HL
  LD (HL),$40
  INC HL
  INC HL
  INC HL
  LD DE,BlankGraphic
  LD (HL),E
  INC HL
  LD (HL),D
  LD HL,(RoomEnemyPtr)
  LD DE,(RoomRecordPtr)
DrawRoomObjects:
  ADD HL,BC
  LD BC,$000A
  INC DE
  LD A,(DE)
  CP $00
  JR Z,DrawRoomNoObject1
  EX DE,HL
  LDIR
  EX DE,HL
  JR DrawRoomObject2
DrawRoomNoObject1:
  INC DE
  ADD HL,BC
DrawRoomObject2:
  LD BC,$000A
  LD A,(DE)
  CP $00
  JR Z,DrawRoomDim
  EX DE,HL
  LDIR
DrawRoomDim:
  LD BC,$0240
  LD DE,Attributes+192
DrawRoomDimLoop:
  LD A,(DE)
  AND $47
  LD (DE),A
  INC DE
  DEC BC
  LD A,B
  OR C
  JR NZ,DrawRoomDimLoop
  LD A,(DrawMode)
  CP $00
  JR Z,DrawRoomScroll
  CALL ClearPlayArea
  JR DrawRoomLayout
DrawRoomScroll:
  LD B,$08                ; A = 0: the scroll wipe
DrawRoomScrollStep:
  PUSH BC
  LD HL,Screen+192
  LD B,$48
DrawRoomScrollLine:
  PUSH BC
  PUSH HL
  LD B,$20
DrawRoomScrollRight:
  SRL (HL)
  INC L
  DJNZ DrawRoomScrollRight
  POP HL
  INC H
  PUSH HL
  LD B,$20
DrawRoomScrollLeft:
  SLA (HL)
  INC L
  DJNZ DrawRoomScrollLeft
  POP HL
  INC H
  LD A,H
  AND $07
  JR NZ,DrawRoomScrollNext
  LD A,L
  ADD A,$20
  LD L,A
  JR C,DrawRoomScrollNext
  LD A,H
  SUB $08
  LD H,A
DrawRoomScrollNext:
  POP BC
  DJNZ DrawRoomScrollLine
  LD BC,$0064
DrawRoomScrollDelay:
  DEC BC
  LD A,B
  OR C
  JR NZ,DrawRoomScrollDelay
  POP BC
  DJNZ DrawRoomScrollStep
DrawRoomLayout:
  LD HL,Attributes+192             ; zero the attributes, then the tiles
  LD DE,Attributes+193
  LD BC,$023F
  LD (HL),$00
  LDIR
  POP DE
  LD HL,RoomLayouts
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD HL,RoomLayouts
  ADD HL,DE
DrawRoomTile:
  LD C,(HL)               ; the next triple: column, row, tile
  BIT 7,C
  JP NZ,DrawRoomCells
  INC HL
  LD B,(HL)
  INC HL
  LD E,(HL)
  INC HL
  PUSH HL
  LD D,$00
  SLA E
  PUSH DE
  LD HL,TileAttrs-$0002
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (TileAttrPtr),DE
  POP DE
  LD HL,TileGraphics-$0002
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD A,B
  RRCA
  RRCA
  RRCA
  AND $E0
  OR C
  LD L,A
  LD A,B
  AND $18
  SET 6,A
  LD H,A
  LD A,L
  ADD A,$A0
  LD L,A
  JR NC,DrawTilePixels
  LD A,H
  ADD A,$08
  LD H,A
DrawTilePixels:
  PUSH HL
  LD A,(DE)
  LD C,A
  INC DE
  LD A,(DE)
  LD B,A
  INC DE
DrawTileRow:
  PUSH AF
  PUSH HL
  LD A,C
DrawTileByte:
  PUSH AF
  LD A,H
  AND $F8
  CP $58
  JR Z,DrawTileByteNext
  CP $40
  JR NZ,DrawTileStore
  LD A,L
  AND $E0
  CP $C0
  JR C,DrawTileSkip
DrawTileStore:
  LD A,(DE)
  LD (HL),A
  INC L
DrawTileSkip:
  INC DE
DrawTileByteNext:
  POP AF
  DEC A
  JR NZ,DrawTileByte
  POP HL
  INC H
  LD A,H
  AND $07
  JR NZ,DrawTileRowNext
  LD A,L
  ADD A,$20
  LD L,A
  JR C,DrawTileRowNext
  LD A,H
  SUB $08
  LD H,A
DrawTileRowNext:
  POP AF
  DEC A
  JR NZ,DrawTileRow
  POP HL
  LD A,H
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  SRL B
  SRL B
  SRL B
  LD DE,(TileAttrPtr)
  LD A,(DE)
  BIT 7,A
  JR NZ,DrawTileFill
DrawTileAttrRow:
  PUSH BC
  PUSH HL
  LD B,C
DrawTileAttrCell:
  LD A,H
  CP $5B
  JR NC,DrawTileAttrNext
  CP $58
  JR NZ,DrawTileAttrStore
  LD A,L
  AND $E0
  CP $C0
  JR C,DrawTileAttrNext
DrawTileAttrStore:
  LD A,(DE)
  LD (HL),A
  INC L
DrawTileAttrNext:
  INC DE
  DJNZ DrawTileAttrCell
  POP HL
  LD A,L
  ADD A,$20
  LD L,A
  JR NC,DrawTileAttrRowNext
  INC H
DrawTileAttrRowNext:
  POP BC
  DJNZ DrawTileAttrRow
  POP HL
  JP DrawRoomTile
DrawTileFill:
  RES 7,A                 ; a first attribute byte with bit 7: one colour for
                          ; the whole tile
  LD E,A
DrawTileFillRow:
  PUSH BC
  PUSH HL
  LD B,C
DrawTileFillCell:
  LD A,H
  CP $5B
  JR NC,DrawTileFillNext
  CP $58
  JR NZ,DrawTileFillStore
  LD A,L
  AND $E0
  CP $C0
  JR C,DrawTileFillNext
DrawTileFillStore:
  LD (HL),E
  INC L
  DJNZ DrawTileFillCell
DrawTileFillNext:
  POP HL
  LD A,L
  ADD A,$20
  LD L,A
  JR NC,DrawTileFillRowNext
  INC H
DrawTileFillRowNext:
  POP BC
  DJNZ DrawTileFillRow
  POP HL
  JP DrawRoomTile
DrawRoomCells:
  LD HL,CellTable         ; the cell table from the attributes, then the items
                          ; and the teleporter
  LD DE,Attributes+192
  LD BC,$0240
DrawRoomCellsLoop:
  LD A,(DE)
  CP $00
  JR Z,DrawRoomCellEmpty
  LD (HL),$01
  JR DrawRoomCellNext
DrawRoomCellEmpty:
  LD (HL),A
DrawRoomCellNext:
  INC HL
  INC DE
  DEC BC
  LD A,B
  OR C
  JR NZ,DrawRoomCellsLoop
  LD A,(RoomVars)
  CP $00
  JR Z,DrawRoomItem2Cells
  LD HL,CellTable
  CALL ItemCell
  LD A,(Item1Kind)
  BIT 7,A
  JR Z,DrawRoomItem2Cells
  CALL DrawItem
DrawRoomItem2Cells:
  LD A,(Item2Pos)
  CP $00
  JR Z,DrawRoomTeleportCells
  LD HL,CellTable
  CALL ItemCell
  LD A,(Item2Kind)
  BIT 7,A
  JR Z,DrawRoomTeleportCells
  CALL DrawItem
DrawRoomTeleportCells:
  LD A,(TeleportPos)
  CP $00
  JR Z,DrawRoomDone
  LD HL,CellTable+$0040
  CALL ItemCell
  PUSH HL
  INC L
  LD (HL),$FF
  INC L
  LD (HL),$FF
  POP HL
  LD A,L
  AND $1F
  LD (TeleportColumn),A
  LD A,L
  AND $E0
  SRL A
  SRL A
  BIT 0,H
  JR Z,DrawRoomTeleportRow
  SET 6,A
  JR DrawRoomTeleportSet
DrawRoomTeleportRow:
  BIT 1,H
  JR Z,DrawRoomTeleportSet
  SET 7,A
DrawRoomTeleportSet:
  LD (TeleportRow),A
DrawRoomDone:
  XOR A
  LD (Shot),A
  DI
  RET

; Put an item on its 2 x 2 cells and draw it
;
; In: HL its cell (ItemCell), A its kind. The kind goes into the four cells;
; the graphic and attribute by the kind: $80 GEN 19 ($8CD5, $45), $81 an energy
; source ($8D15, $42), $C1-$C3 a weapon (HudIcons + 32 x n, WeaponColours),
; $82-$B3 an ED piece (piece n = kind - $81 is the EdPieces tile at column (n -
; 1) / 5, row (n - 1) % 5 of the 10 x 5 picture: DrawItemEdColumn adds 32 for
; each 5 in n, DrawItemEdRow 320 for the rest; colour $67); Blit16 $8A93 draws
; the 16 x 16 pixels; the four attributes. L1 141.
DrawItem:
  PUSH HL
  LD DE,$001F
  LD (HL),A
  INC L
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  INC L
  LD (HL),A
  POP HL
  SLA H
  SLA H
  SLA H
  SET 6,H
  PUSH HL
  CP $80
  JR Z,DrawItemGen
  CP $81
  JR Z,DrawItemEnergy
  BIT 6,A
  JR NZ,DrawItemWeapon
  RES 7,A
  DEC A
  LD DE,$0020
  LD HL,EdPieces-$0160
DrawItemEdColumn:
  ADD HL,DE
  LD B,A
  SUB $05
  JR Z,DrawItemEdRows
  JR NC,DrawItemEdColumn
DrawItemEdRows:
  LD DE,$0140
DrawItemEdRow:
  ADD HL,DE
  DJNZ DrawItemEdRow
  EX DE,HL
  LD C,$67
  JR DrawItemDraw
DrawItemGen:
  LD DE,IconGen19
  LD C,$45
  JR DrawItemDraw
DrawItemEnergy:
  LD DE,IconEnergySource
  LD C,$42
  JR DrawItemDraw
DrawItemWeapon:
  AND $3F
  LD DE,$0020
  LD HL,HudIcons
  LD B,A
DrawItemWeaponIcon:
  ADD HL,DE
  DJNZ DrawItemWeaponIcon
  EX DE,HL
  LD HL,WeaponColours-$0001
  ADD A,L
  LD L,A
  JR NC,DrawItemWeaponColour
  INC H
DrawItemWeaponColour:
  LD C,(HL)
DrawItemDraw:
  POP HL
  PUSH HL
  CALL Blit16
  POP HL
  LD A,H
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  LD DE,$001F
  LD (HL),C
  INC L
  LD (HL),C
  ADD HL,DE
  LD (HL),C
  INC L
  LD (HL),C
  RET

; The cell of a position byte: HL + 32 x (A AND $0F) + 2 x (A >> 4)
;
; In: HL the base (CellTable, or CellTable + 64 for the teleporter), A the
; position byte (low nibble the row, high nibble the column / 2). Out: HL. L1
; 321.
ItemCell:
  PUSH AF
  AND $0F
  CP $00
  JR Z,ItemCellColumn
  LD B,A
  LD DE,$0020
ItemCellRow:
  ADD HL,DE
  DJNZ ItemCellRow
ItemCellColumn:
  POP AF
  SRL A
  SRL A
  SRL A
  SRL A
  CP $00
  RET Z
  LD B,A
ItemCellColumnLoop:
  INC HL
  INC HL
  DJNZ ItemCellColumnLoop
  RET

; The graphics of tiles 1-70 (and a 71st no room uses)
;
; DrawRoom reads TileGraphics - 2 + 2 x tile ($6CC9). Tile 49 is 0 (no room
; uses it); the 71st word ($6F34, $FDDC) is never read. A graphic is a width in
; bytes, a height in pixel rows, then the rows (TileData $E822-$FDDF). The
; editable form: src/res/tiles/.
TileGraphics:
  INCBIN "res/tiles/TileTables.bin",$0000,142
TileAttrs:
  INCBIN "res/tiles/TileTables.bin",$008E,140
TileAttrData:
  INCBIN "res/tiles/TileTables.bin",$011A,415
