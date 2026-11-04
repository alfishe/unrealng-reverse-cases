; Draw the isometric view: background, objects, copy to the screen
;
; DrawViewBackground clears the buffer $5B00 and paints the corners outside the
; map, DrawMapObjects draws every block, building, robot, shot and the ship,
; CopyViewToScreen puts the 160x160 buffer on the screen. Once per game turn:
; 3423 times in the 36046 frames of the deep recording (the play loop waits for
; 10 frames a turn, $AE1D). About 578000 T-states a call, 8.3 frames: the
; reason a turn is 10 frames.
DrawView:
  CALL DrawViewBackground
  CALL DrawMapObjects
  JP CopyViewToScreen

; Draw the 32 x 16 cells of the view back to front into the view buffer
;
; Clears the deferred ship position $FD11 and draws the ship's shadow (sprite
; 1, height 0) at the ship's view column (ShipX - ViewX) and row ShipY. Then
; walks the visible part of the map along diagonals: the diagonal x - y = 31
; first down to x - y = -15, each from row 0 (x, y) to (x+15, y+15) or the
; right edge; cells left of the view (x < 0) and cells that are 0 are skipped,
; every other cell goes to DrawCell with HL = the cell, D = row, E = view
; column. The order is the painter's order of the projection (DrawSprite): a
; later cell is nearer the viewer. About 442000 T-states a call with the
; sprites it draws (1512 M in the deep recording), the heaviest part of the
; play.
DrawMapObjects:
  LD HL,$0000             ; no deferred ship yet
  LD (ShipDrawPos),HL
  XOR A                   ; height 0 for the shadow
  LD (DrawSprite+$0012),A
  LD HL,(ShipX)
  LD DE,(MapView)           ; DE = MapView with D reduced to its low bit: only
                          ; the low byte of the difference matters
  LD A,D
  AND $01
  LD D,A
  XOR A
  SBC HL,DE
  LD E,L                  ; E = the ship's column in the view
  LD A,(ShipY)
  LD D,A
  LD A,$01                ; sprite 1: the ship's shadow on the ground
  CALL DrawSprite
  LD HL,(MapView)           ; HL = the cell 32 columns right of the view's left
                          ; edge
  LD A,$20
  CALL AddAToHL
  LD DE,$0020             ; D = row 0, E = column 32
DiagonalLoop:
  DEC HL                  ; start the next diagonal one column further left
  DEC E
  PUSH HL
  PUSH DE
DiagonalCellLoop:
  LD A,E
  OR A
  JP M,DiagonalNext       ; left of the view: nothing to draw
  LD A,(HL)
  OR A
  CALL NZ,DrawCell        ; an occupied cell
DiagonalNext:
  INC H                   ; the next cell down the diagonal
  INC H
  INC HL
  INC D
  INC E
  LD A,D
  CP $10                  ; past row 15
  JR NC,DiagonalDone
  LD A,E
  CP $20                  ; past column 31
  JR NZ,DiagonalCellLoop
DiagonalDone:
  LD A,E
  POP DE
  POP HL
  CP $01                  ; the last diagonal ends at column 1 (it started at
                          ; column -15)
  JR NZ,DiagonalLoop
  RET

; Draw map cell HL (A = its byte) at view row D, column E
;
; Cell bits: 0-4 the block type, 5 the right half of a two-cell block (nothing
; drawn), 6 an object (building, robot or shot, or a robot / shot deferred to
; this cell), 7 the ship, or the ship deferred to this cell. A block (bit 5
; clear, type not 0) is drawn as sprite = type at height 0. Bit 6 calls
; DrawCellObject. Bit 7 handles the ship: on the first bit-7 cell ($FD11 = 0,
; the ship's own cell, set by $B024) it looks for the cell drawn last among the
; neighbouring blocks (FindLatestBlock) and the neighbouring objects
; (CheckObjectNeighbour at (x-1,y-1), (x-1,y), (x-1,y+1), (x,y+1), (x+1,y+1)).
; If that is the ship's cell the ship is drawn at once, otherwise bit 7 is set
; on that later cell and the ship's view position is kept in $FD11; when the
; walk reaches it, bit 7 is cleared again and the ship (sprite 0) is drawn at
; the kept position, at height Altitude. So the ship is never painted over by a
; neighbour. In the deep recording the ship was deferred in 2828 of the 3423
; view draws.
DrawCell:
  PUSH HL
  PUSH DE
  PUSH AF
  BIT 5,A                 ; bit 5: the right half of a block, no sprite of its
                          ; own
  JR NZ,DrawCellObjects
  AND $1F                 ; the block type is the sprite number
  JR Z,DrawCellObjects
  LD HL,DrawSprite+$0012  ; height 0
  LD (HL),$00
  CALL DrawSprite
DrawCellObjects:
  POP AF                  ; then the object (bit 6) and the ship (bit 7)
  POP DE
  POP HL
  BIT 6,A                 ; bit 6: an object stands or is deferred here
  CALL NZ,DrawCellObject
  LD A,(HL)
  BIT 7,A                 ; bit 7: the ship
  RET Z
  LD BC,(ShipDrawPos)           ; already deferred?
  LD A,B
  OR C
  JR NZ,ShipDeferred
  PUSH DE                 ; DE = the latest cell found so far: this one
  LD D,H
  LD E,L
  CALL FindLatestBlock    ; the blocks around the ship's cell
  PUSH HL
  DEC HL                  ; (x-1, y-1)
  DEC H
  DEC H
  CALL CheckObjectNeighbour
  INC H                   ; (x-1, y)
  INC H
  CALL CheckObjectNeighbour
  INC H                   ; (x-1, y+1) unless past row 15
  INC H
  LD A,H
  CP $FD
  JR NC,ShipCompareLatest
  CALL CheckObjectNeighbour
  INC HL                  ; (x, y+1)
  CALL CheckObjectNeighbour
  INC HL                  ; (x+1, y+1)
  CALL CheckObjectNeighbour
ShipCompareLatest:
  POP HL                  ; is the latest object cell the ship's own? Then draw
                          ; it now, else defer
  LD A,D
  CP H
  JR NZ,ShipDefer
  LD A,E
  CP L
  JR NZ,ShipDefer
  POP DE
  JR ShipDrawNow          ; draw the ship now
ShipDefer:
  EX DE,HL                ; mark the later cell with bit 7, keep the ship's
                          ; view position
  SET 7,(HL)
  EX DE,HL
  POP DE
  LD (ShipDrawPos),DE           ; $FD11 = column, $FD12 = row
  RET
ShipDeferred:
  RES 7,(HL)              ; the deferred cell: clear its mark and draw at the
                          ; kept position
  PUSH HL
  PUSH DE
  LD D,B
  LD E,C
  JR ShipDraw
ShipDrawNow:
  PUSH HL
  PUSH DE
ShipDraw:
  LD A,(Altitude)            ; sprite 0 at height Altitude
  LD (DrawSprite+$0012),A
  XOR A
  CALL DrawSprite
  POP DE
  POP HL
  RET

; Ship: an object at HL counts, and so do the blocks around it
;
; Used for the ship's neighbours: if HL has bit 6 it competes (KeepLaterCell)
; and then falls into FindLatestBlock for the blocks around that object.
CheckObjectNeighbour:
  BIT 6,(HL)
  RET Z
  CALL KeepLaterCell

; DE = the cell drawn last among DE and the blocks next to HL
;
; Checks the blocks (bit 5 clear, type not 0) at (x-1,y+1), (x,y+1) (both only
; when y+1 < 16), (x-1,y) and (x+1,y+1) (y+1 < 16) of cell HL with
; CheckBlockNeighbour; (x+1,y) is passed over (HL only goes through it). Those
; are the cells whose sprites can overlap a robot, a shot or the ship standing
; at HL. HL is kept. Used by DrawCell (the ship) and DrawMover (robots, shots).
FindLatestBlock:
  PUSH HL
  DEC HL                  ; (x-1, y+1)
  INC H
  INC H
  LD A,H                  ; row 16 is past the map ($DD00 + $200*16 = $FD00)
  CP $FD
  JR NC,FindLatestSameRow
  CALL CheckBlockNeighbour
  INC HL                  ; (x, y+1)
  CALL CheckBlockNeighbour
  DEC HL
FindLatestSameRow:
  DEC H                   ; the cells (x-1, y) through (x+1, y+1)
  DEC H
  CALL CheckBlockNeighbour
  INC HL                  ; through (x+1, y) to (x+1, y+1), unless past row 15
  INC HL
  INC H
  INC H
  LD A,H
  CP $FD
  CALL C,CheckBlockNeighbour
  POP HL
  RET

; A block at HL competes for the latest cell
;
; Bit 5 set (the right half of a block) or type 0 (empty): nothing. Otherwise
; falls into KeepLaterCell.
CheckBlockNeighbour:
  BIT 5,(HL)
  RET NZ
  LD A,(HL)
  AND $1F
  RET Z

; DE = HL if map cell HL is drawn after cell DE
;
; The drawing order of DrawMapObjects: diagonals by falling x - y, along a
; diagonal by rising x. A = (yHL - yDE) + (xDE - xHL) (columns by the low
; bytes, rows from the high bytes: (H - $DD) / 2). A > 0: HL's diagonal is
; later; A = 0: same diagonal, later when xHL > xDE.
KeepLaterCell:
  LD A,E
  SUB L                   ; C = xDE - xHL
  LD C,A
  LD A,D                  ; B = yDE
  SUB $DD
  SRL A
  LD B,A
  LD A,H                  ; A = yHL - yDE + xDE - xHL
  SUB $DD
  SRL A
  SUB B
  ADD A,C
  RET M                   ; HL drawn earlier
  JR NZ,KeepLaterTake
  LD A,C                  ; same diagonal: the bigger column is later
  OR A
  RET P
KeepLaterTake:
  LD D,H                  ; HL is later: DE = HL
  LD E,L
  RET

; Z: IY the robot record standing on map cell HL, B = 48 - its slot (slots 0-23
; the player's)
;
; Used by the routines at PlayLoop, GameTurnEnd, ObjectTop, ScanLane, MoveShot,
; NuclearBlast and DrawCellObject.
FindRobot:
  LD IY,Robots
  LD B,$30
FindRobotLoop:
  LD A,(IY+$00)           ; compare +$00/+$01 with HL
  CP L
  JR NZ,FindRobotNext
  LD A,(IY+$01)
  CP H
  RET Z
FindRobotNext:
  PUSH DE                 ; the next 16-byte robot record
  LD DE,$0010
  ADD IY,DE
  POP DE
  DJNZ FindRobotLoop
  OR $01                  ; none: NZ
  RET

; Z: IY the building record (Buildings) on map cell HL
;
; Used by the routines at PlayLoop, KeepHigher, RemoveBuilding and
; DrawCellObject.
FindBuilding:
  LD IY,Buildings
  LD B,$38
FindBuildingLoop:
  LD A,(IY+$00)           ; compare the cell address with HL
  CP L
  JR NZ,FindBuildingNext
  LD A,(IY+$01)
  CP H
  RET Z
FindBuildingNext:
  PUSH DE                 ; the next 3-byte building record
  LD DE,$0003
  ADD IY,DE
  POP DE
  DJNZ FindBuildingLoop
  OR $01                  ; none: NZ
  RET

; Draw the object of map cell HL (bit 6): a robot, a building or a shot
;
; A robot whose +$00/+$01 is HL goes to DrawMover. A building record goes to
; its sprite: BuildingSprites[type] at height BuildingHeights[type]. Otherwise
; the five shot records at $D7D3 (9 bytes: +$00/+$01 cell, +$02/+$03 x, +$04 y,
; +$05 direction, +$06 range, +$07 weapon 1-3, +$08 height) are searched; a
; match goes to DrawMover. Nothing found: nothing drawn. 8330 calls in the deep
; recording: 1485 robots, 6845 buildings, the shot search never ran (no shot
; stood in the view while it was drawn; the shot path is read from the code and
; from the shot records at frame 20000).
DrawCellObject:
  CALL FindRobot
  JR Z,DrawMover          ; a robot here
  CALL FindBuilding
  JR Z,DrawBuilding       ; a building here
  LD IY,Shots             ; the five shot records, 9 bytes each
  LD B,$05
ShotSearchLoop:
  LD A,(IY+$00)
  CP L
  JR NZ,ShotSearchNext
  LD A,(IY+$01)
  CP H
  JR Z,DrawMover          ; a shot here
ShotSearchNext:
  PUSH DE                 ; the next 9-byte shot record
  LD DE,$0009
  ADD IY,DE
  POP DE
  DJNZ ShotSearchLoop
  RET
DrawBuilding:
  PUSH HL                 ; building type C: sprite and height from the tables
                          ; below
  PUSH DE
  LD A,(IY+$02)
  LD C,A
  LD HL,BuildingHeights   ; the height of the type
  CALL AddAToHL
  LD A,(HL)
  LD (DrawSprite+$0012),A
  LD A,C
  LD HL,BuildingSprites   ; the sprite of the type
  CALL AddAToHL
  LD A,(HL)
  CALL DrawSprite
  POP DE
  POP HL
  RET

; The sprite of each building type
;
; Index = the Buildings type: 0 the player's warbase pad $2C (a crate),
; factories 1 electronics $28, 2 nuclear $25, 3 phasers $23, 4 missiles $20, 5
; cannon $1D, 6 chassis $17 (each the robot part of its product, facing down:
; $16 + the parts table $D6C8), 7 and 8 the flags $2A and $2B. In the deep
; recording at frame 20000 the type 7 / 8 records stand two columns left of a
; factory (four of the player's warbase pad): a factory's owner flag; 7 the
; player's, 8 the enemy's.
BuildingSprites:
  DEFB $2C,$28,$25,$23,$20,$1D,$17,$2A,$2B

; The height each building sprite is drawn at
;
; Type 0 at $13, the six factory signs at $0F (on the factory's roof blocks),
; the flags at $1A.
BuildingHeights:
  DEFB $13,$0F,$0F,$0F,$0F,$0F,$0F,$1A,$1A

; Draw robot or shot IY found at cell HL (view row D, column E), after the
; blocks that overlap it
;
; Robots and shots keep their real position in +$02/+$03 (x) and +$04 (y) and
; in +$00/+$01 the cell the walk draws them at. At the real cell
; FindLatestBlock looks for a later neighbouring block; if there is one, the
; object is moved there (bit 6 set on it, +$00/+$01 = it) and nothing is drawn
; yet. When the walk reaches the deferred cell, +$00/+$01 is set back to the
; real cell, the deferred cell's bit 6 is cleared and the view position is
; walked back from the deferred cell to the real one (x first, then y), and
; DrawMoverSprite draws the object there. So a robot is drawn after (over)
; every block whose sprite overlaps it. In the deep recording 1485 robot draws
; reached here; 18 were deferred (each drawn later at the walked-back
; position), 1449 drawn at once. No shot reached here: see DrawCellObject.
DrawMover:
  PUSH DE
  LD D,H
  LD E,L
  CALL FindLatestBlock    ; a later block next to it?
  LD A,D
  CP H
  JR NZ,MoverDefer
  LD A,E
  CP L
  JR Z,MoverDeferred
MoverDefer:
  EX DE,HL                ; defer: mark the later cell and point the record at
                          ; it
  SET 6,(HL)
  LD (IY+$00),L
  LD (IY+$01),H
  EX DE,HL
  POP DE
  RET
MoverDeferred:
  POP DE                  ; reached: the real cell from +$02-$04
  PUSH DE
  EX DE,HL
  LD L,(IY+$02)
  LD H,(IY+$03)
  LD A,(IY+$04)
  CALL MapCell
  LD A,D
  CP H
  JR NZ,MoverRestore
  LD A,E
  CP L
  JR NZ,MoverRestore
  POP DE                  ; this is the real cell: draw here
  JR DrawMoverSprite
MoverRestore:
  LD (IY+$00),L           ; deferred: the record back to its real cell, the
                          ; mark cleared
  LD (IY+$01),H
  LD B,H
  LD C,L
  EX DE,HL
  POP DE
  PUSH DE
  PUSH HL
  RES 6,(HL)
  DEC HL                  ; the view column: from the deferred column - 1 up to
                          ; the real one
  DEC E
MoverColumnLoop:
  LD A,C
  CP L
  JR Z,MoverRowLoop
  INC HL
  INC E
  JR MoverColumnLoop
MoverRowLoop:
  LD A,B                  ; the view row: up to the real row
  CP H
  JR Z,MoverDrawReal
  DEC H
  DEC H
  DEC D
  JR MoverRowLoop
MoverDrawReal:
  CALL DrawMoverSprite    ; at the real row: draw the sprite there
  POP HL
  POP DE
  RET

; Draw IY: a robot record ($DA00 up) as a stack of parts, a shot as one sprite
;
; Records at $D800 and up are robots: DrawRobot. A shot (records at $D7D3) is
; sprite $2B + 2 * weapon (+$07: 1 cannon, 2 missiles, 3 phasers) + 1 when it
; flies down or up (+$05 = 4 or 8), at height +$08: $2D/$2E a cannon shell,
; $2F/$30 a missile trail, $31/$32 a phaser beam (the sprite pictures in
; start.bin). The shot branch did not run in the recordings.
DrawMoverSprite:
  PUSH IY                 ; IY's high byte tells robots from shots
  POP BC
  LD A,B
  CP $D8
  JP NC,DrawRobot
  PUSH HL
  PUSH DE
  LD C,(IY+$07)
  LD A,(IY+$05)
  CP $03                  ; carry: direction 4 or 8 (along the rows)
  CCF
  RL C                    ; C = 2 * weapon + axis
  LD A,(IY+$08)           ; the shot's height
  LD (DrawSprite+$0012),A
  LD A,$2B
  ADD A,C
  CALL DrawSprite
  POP DE
  POP HL
  RET

; Draw robot IY at view row D, column E: its parts bottom up
;
; Height starts at +$0D (the ground under the robot, 0 in the construction
; menu); for each bit of the parts mask +$07 from bit 0 (bipod, tracks,
; anti-grav, cannon, missiles, phasers, nuclear, electronics) DrawRobotPart
; draws the part and raises the height. Called by DrawMoverSprite and
; ShowRobotDesign.
DrawRobot:
  PUSH HL
  LD C,(IY+$07)
  LD B,$08
  LD A,(IY+$0D)           ; the base height
  LD (DrawSprite+$0012),A
RobotPartLoop:
  RR C
  CALL C,DrawRobotPart    ; this part fitted?
  DJNZ RobotPartLoop
  POP HL
  RET

; Draw part 8 - B of robot IY facing +$08, then raise the height
;
; Sprite = $16 + the parts table $D6C8[4 * part + direction], direction = the
; number of the lowest set bit of +$08 (0 right, 1 left, 2 down, 3 up, the
; Input bits). After drawing, the height ($CF3F) grows by the part's height
; $D7B4[part]: bipod 11, tracks 7, anti-grav 8, cannon 6, missiles 6, phasers
; 7, nuclear 7, electronics 7.
DrawRobotPart:
  PUSH BC
  PUSH DE
  LD A,$08                ; A = the part number
  SUB B
  PUSH AF
  LD C,(IY+$08)
  LD B,$FF                ; B = the direction number
DirectionLoop:
  INC B
  RR C
  JR NC,DirectionLoop
  ADD A,A                 ; 4 directions a part
  ADD A,A
  ADD A,B
  LD HL,PartSpriteTable
  CALL AddAToHL
  LD A,(HL)
  ADD A,$16               ; the part sprites start at $16
  CALL DrawSprite
  POP AF
  POP DE
  POP BC
  LD HL,PartHeights       ; the part's height
  CALL AddAToHL
  LD A,($CF3F)
  ADD A,(HL)
  LD (DrawSprite+$0012),A
  RET

; Draw sprite A at view row D, column E, height ($CF3F) into the view buffer
;
; The isometric projection: the half-byte column L = 2E + D - 24, the pixel row
; of the sprite's bottom line H = 8D + 100 - 4E - height. So a step along x
; moves 8 pixels right and 4 up, a step along y 4 right and 8 down. The sprite
; table $D6E8 holds two words a sprite (A*2 + 1 for an odd half-byte column:
; the image shifted by 4 pixels). A sprite: rows, width in bytes, then for each
; row bottom up (mask, pixels) byte pairs; drawn by AND mask, OR pixels into
; the 20-byte rows of the buffer $5B00, upwards. Clipping: right of column 19
; or a bottom line past row $E1: nothing; bottom lines $A0-$E1 skip the rows
; below the buffer; a negative column skips the left bytes of each row ($CFAF),
; a sprite past column 19 the right bytes; the top stops at $5B00. 116709
; calls, 978 M T-states in the deep recording.
DrawSprite:
  LD C,A
  RLC E                   ; E * 2
  LD A,E
  ADD A,D                 ; L = 2E + D - 24: the column in half bytes
  SUB $18
  LD L,A
  RLC E                   ; E * 4
  LD A,D                  ; H = 8D + 100 - 4E - height
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,$64
  SUB E
  SUB $00                 ; the height: the operand $CF3F, written by the
                          ; callers
  LD H,A
  LD A,C                  ; the sprite number, 0-$3F
  AND $3F
  SRA L                   ; byte column; carry = the odd half byte
  ADC A,A                 ; two images a sprite: 0 aligned, 1 shifted by 4
                          ; pixels
  PUSH HL
  LD HL,SpriteTable
  CALL TableWord          ; HL = the sprite
  LD C,(HL)               ; C = rows, B = bytes a row
  INC HL
  LD B,(HL)
  INC HL
  EX DE,HL
  POP HL
  XOR A                   ; no bytes clipped on the left yet
  LD (SpriteRowLoop+$0003),A
  LD A,L                  ; past the right edge?
  CP $14
  RET P
  LD A,H                  ; the bottom line below the buffer?
  CP $A0
  JR C,ClipLeft
  CP $E2                  ; entirely below
  RET NC
  SUB $9F                 ; rows below the buffer
  SUB C
  RET P
  NEG                     ; C = the rows that remain
  LD C,A
ClipBottomLoop:
  PUSH BC                 ; skip a row of the sprite
ClipBottomSkip:
  INC DE                  ; skip the sprite row's bytes
  INC DE
  DJNZ ClipBottomSkip
  POP BC
  DEC H
  LD A,H
  CP $9F
  JR NZ,ClipBottomLoop
ClipLeft:
  LD A,L
  OR A
  JP P,ClipRight
  NEG                     ; bytes cut on the left
  LD (SpriteRowLoop+$0003),A
  LD L,$00
  CP B
  RET NC
ClipRight:
  LD A,L
  ADD A,B
  CP $15
  JR C,BufferAddress
  SUB $14                 ; bytes cut on the right
  LD (SpriteRowLoop+$0003),A
ClipRightLoop:
  DEC DE                  ; start that many pairs earlier: each row then leaves
                          ; out its last pairs
  DEC DE
  DEC A
  JR NZ,ClipRightLoop
BufferAddress:
  PUSH DE                 ; DE = $5B00 + 20*H + L
  LD A,L
  PUSH AF
  LD L,H
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD D,H
  LD E,L
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  POP AF
  CALL AddAToHL
  LD DE,ViewBuffer
  ADD HL,DE
  POP DE
  EX DE,HL
SpriteRowLoop:
  PUSH BC
  PUSH DE
  LD A,$00                ; bytes to skip on the left: the operand $CFAF
  OR A
  JP Z,SpriteByteLoop
SkipLeftLoop:
  INC HL
  INC HL
  DEC B
  DEC A
  JP NZ,SkipLeftLoop
SpriteByteLoop:
  LD A,(DE)               ; AND the mask, OR the pixels
  AND (HL)
  INC HL
  OR (HL)
  LD (DE),A
  INC HL
  INC DE
  DJNZ SpriteByteLoop
  POP DE
  POP BC
  LD A,$EC                ; one buffer row up
  ADD A,E
  LD E,A
  JP C,SpriteRowNext
  DEC D
  LD A,D
  CP $5A                  ; above $5B00: stop
  RET Z
SpriteRowNext:
  DEC C                   ; the next sprite row
  JP NZ,SpriteRowLoop
  RET

; Clear the view buffer and paint the corners outside the map
;
; ClearViewBuffer, FillViewCorner (the solid top left corner), then the
; diagonal edge strips from $D6A8: 6 strips down and left from buffer row 0,
; column 10 (the top left edge), 3 from row 136, column 18 and 4 of the other
; diagonal ($D6B8) from row 128, column 18 (the bottom right corner, the blue
; area that DrawPlayScreen colours $41 / $71). Called by DrawView and once by
; $A62D.
DrawViewBackground:
  CALL ClearViewBuffer
  CALL FillViewCorner
  LD HL,ViewEdgeA
  LD B,$06
  LD DE,ViewBuffer+$000A  ; row 0, column 10
  CALL DrawEdgeStrips
  LD HL,ViewEdgeA
  LD B,$03
  LD DE,ViewBuffer+$0AB2  ; row 136, column 18
  CALL DrawEdgeStrips
  LD HL,ViewEdgeB         ; the edge with the ink on the right
  LD B,$04
  LD DE,ViewBuffer+$0A12  ; row 128, column 18
  JP DrawEdgeStrips

; Zero the view buffer $5B00-$677F (20 bytes x 160 rows)
;
; Pushes HL = 0 with SP at $6780 (198 x 16 bytes, SP kept in $FD08), then
; clears the first 32 bytes with LDIR. Called by DrawViewBackground,
; ShowRobotDesign and $CB52.
ClearViewBuffer:
  LD (SavedSP),SP           ; keep SP
  LD SP,Font              ; the end of the buffer
  LD B,$C6                ; 198 x 8 words
  LD HL,$0000
ClearPushLoop:
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  DJNZ ClearPushLoop
  LD SP,(SavedSP)
  LD HL,ViewBuffer        ; the 32 bytes left at the start
  LD DE,ViewBuffer+$0001
  LD BC,$001F
  LD (HL),$00
  LDIR
  RET

; Fill the top left corner of the view buffer: a staircase of 5 bands
;
; 5 bands of 8 rows; the first fills 10 bytes of each row, each next band 2
; fewer (10, 8, 6, 4, 2). The fill and skip counts are the operands $D038 and
; $D041, reset to 10 at the start and moved by 2 after each band.
FillViewCorner:
  LD A,$0A
  LD (CornerRowLoop+$0002),A ; bytes filled a row
  LD (CornerByteLoop+$0006),A ; bytes skipped a row
  LD HL,ViewBuffer
  LD B,$05
BandLoop:
  PUSH BC
  LD B,$08
CornerRowLoop:
  PUSH BC
  LD B,$0A                ; the fill count: the operand $D038
  LD A,$FF
CornerByteLoop:
  LD (HL),A
  INC HL
  DJNZ CornerByteLoop
  POP BC
  LD A,$0A                ; the skip count: the operand $D041
  CALL AddAToHL
  DJNZ CornerRowLoop
  POP BC
  PUSH HL
  LD HL,CornerRowLoop+$0002 ; 2 bytes fewer, 2 more skipped
  DEC (HL)
  DEC (HL)
  LD HL,CornerByteLoop+$0006
  INC (HL)
  INC (HL)
  POP HL
  DJNZ BandLoop
  RET

; Copy B strips of 8 rows x 2 bytes (pattern HL) into the buffer, each 8 rows
; down and 2 bytes left
;
; The diagonal edge of the map in the view. The patterns are at $D6A8 (ink on
; the left: $FFFF, $FFFC, ..., $C000) and $D6B8 (ink on the right).
DrawEdgeStrips:
  PUSH BC
  PUSH HL
  LD BC,$08FF
StripRowLoop:
  LDI
  LDI
  LD A,$12                ; the next row: 20 bytes in all
  ADD A,E
  LD E,A
  LD A,D
  ADC A,$00
  LD D,A
  DJNZ StripRowLoop
  POP HL
  POP BC
  DEC DE                  ; 2 bytes left for the next strip
  DEC DE
  DJNZ DrawEdgeStrips
  RET

; Copy the view buffer to the screen at character row 1, column 1 (20 x 20
; characters)
;
; 160 lines of 20 bytes with unrolled LDI, the destination stepped through the
; screen's thirds. 256 M T-states in the deep recording.
CopyViewToScreen:
  LD HL,ViewBuffer
  LD DE,$4021             ; the screen: line 0 of character row 1, column 1
  LD C,$14                ; 20 character rows
CopyCharRowLoop:
  LD B,$08
CopyLineLoop:
  PUSH BC
  PUSH DE
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  POP DE
  POP BC
  INC D                   ; the next pixel line
  DJNZ CopyLineLoop
  LD A,E                  ; the next character row
  ADD A,$20
  LD E,A
  JR C,CopyCharRowNext
  LD A,D
  SUB $08
  LD D,A
CopyCharRowNext:
  DEC C                   ; the next character row
  JP NZ,CopyCharRowLoop
  RET
