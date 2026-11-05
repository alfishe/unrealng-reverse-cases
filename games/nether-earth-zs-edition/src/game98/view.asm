; --------------------------------------------------------------------------------------------------------------------
; view.asm: the isometric view: the buffer, the painter's walk over the map, the masked sprites
;
; The play area, redrawn from nothing every game turn into the 160 x 160 pixel buffer ViewBuffer ($5B00-$677F, 20
; bytes x 160 lines) and copied to the screen at character (1,1). Nothing scrolls and nothing is erased: moving the
; view is only ViewX + 1. The redraw takes about 8.3 frames and is why a game turn is 10 frames. NE's
; docs/06-rendering.md 6.1-6.6.
;
; Calling order: DrawView = DrawViewBackground (ClearViewBuffer, FillViewCorner, DrawEdgeStrips: the corners outside
; the map) + DrawMapObjects (the ship's shadow, then the 32 x 16 visible cells along diagonals back to front) +
; CopyViewToScreen. Each cell goes to DrawCell: its block (sprite = the type), then DrawCellObject (a robot by
; FindRobot, a building by FindBuilding, else a shot) and the ship. Every picture ends in DrawSprite.
;
; The depth order is the walk itself, there is no sort. An object a later neighbouring block would paint over is
; deferred: DrawMover (robots, shots) and DrawCell (the ship) look for the latest-drawn neighbour (FindLatestBlock,
; CheckObjectNeighbour, CheckBlockNeighbour, KeepLaterCell), mark that cell (bit 6, or bit 7 for the ship) and draw
; when the walk reaches it, at the real position.
;
; DrawSprite is the projection: half-byte column L = 2E + D - 24, bottom line H = 8D + 100 - 4E - height. Sprites
; (SpriteTable $D6E8, two pre-shifted pictures each) are (mask, pixels) pairs from the bottom line up, drawn with AND
; / OR and clipped on all four sides. Robots are stacks of part sprites (DrawRobot, DrawRobotPart: PartSpriteTable
; $D6C8, PartHeights $D7B4); buildings take BuildingSprites / BuildingHeights by type.
;
; Self-modified operands: the height of the next sprite at $CF3F (DrawSprite+$12, written by every caller), the left /
; right cut at $CFAF, the corner fill and skip counts at $D038 / $D041. ClearViewBuffer clears with PUSH (SP parked in
; SavedSP).
; --------------------------------------------------------------------------------------------------------------------

; Draw the isometric view: background, objects, copy to the screen
;
; DrawViewBackground clears the buffer $5B00 and paints the corners outside the
; map, DrawMapObjects draws every block, building, robot, shot and the ship,
; CopyViewToScreen puts the 160x160 buffer on the screen. Once per game turn:
; 3423 times in the 36046 frames of NE's deep recording (the play loop waits
; for 10 frames a turn, $AE1D). About 578000 T-states a call, 8.3 frames: the
; reason a turn is 10 frames.
;
; Called by PlayLoop, the menu loops that keep the game going (ListMenu's turn
; $AD1F, DirectControlLoop, DistanceLoop, CombatFireShot), the nuclear blast
; ($BA6D) and DrawPlayScreen. No HALT before the copy: the screen may tear for
; a frame.
DrawView:
  CALL DrawViewBackground ; clear the buffer, paint the corners and the map's
                          ; edge
  CALL DrawMapObjects     ; the shadow, the blocks, buildings, robots, shots
                          ; and the ship
  JP CopyViewToScreen     ; the buffer to the screen; its RET ends DrawView

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
; sprites it draws (1512 M in NE's deep recording), the heaviest part of the
; play.
DrawMapObjects:
  LD HL,$0000             ; no deferred ship yet
  LD (ShipDrawPos),HL           ; ShipDrawPos = 0
  XOR A                   ; height 0 for the shadow
  LD (DrawSprite+$0012),A ; into DrawSprite's height operand ($CF3F)
  LD HL,(ShipX)           ; the shadow's view column: ShipX - ViewX
  LD DE,(MapView)           ; DE = MapView with D reduced to its low bit: only
                          ; the low byte of the difference matters
  LD A,D                  ; the high byte of MapView ($DD or $DE) ...
  AND $01                 ; ... cut to its low bit: 1 for ViewX below 256, 0
                          ; above
  LD D,A                  ; DE = ViewX + $100 or ViewX - $100: the low byte is
                          ; ViewX's
  XOR A                   ; no borrow into the SBC
  SBC HL,DE               ; L = the low byte of ShipX - ViewX
  LD E,L                  ; E = the ship's column in the view
  LD A,(ShipY)            ; D = the shadow's view row: ShipY
  LD D,A                  ; (the view row is the map row: the view shows rows
                          ; 0-15)
  LD A,$01                ; sprite 1: the ship's shadow on the ground
  CALL DrawSprite         ; draw the shadow first: everything else covers it
  LD HL,(MapView)           ; HL = the cell 32 columns right of the view's left
                          ; edge
  LD A,$20                ; 32 columns: one past the view's last column
  CALL AddAToHL           ; HL = the map cell at view column 32, row 0
  LD DE,$0020             ; D = row 0, E = column 32
DiagonalLoop:
  DEC HL                  ; start the next diagonal one column further left
  DEC E                   ; and its view column
  PUSH HL                 ; keep the diagonal's first cell
  PUSH DE                 ; and its row / column
DiagonalCellLoop:
  LD A,E                  ; the view column of this cell
  OR A                    ; negative: left of the view
  JP M,DiagonalNext       ; left of the view: nothing to draw
  LD A,(HL)               ; the map cell's byte
  OR A                    ; 0: an empty cell, nothing to draw
  CALL NZ,DrawCell        ; an occupied cell
DiagonalNext:
  INC H                   ; the next cell down the diagonal
  INC H                   ; (one map row is $200 bytes)
  INC HL                  ; and one column right
  INC D                   ; view row + 1
  INC E                   ; view column + 1
  LD A,D                  ; the row reached
  CP $10                  ; past row 15
  JR NC,DiagonalDone      ; past row 15: the diagonal ends
  LD A,E                  ; the column reached
  CP $20                  ; past column 31
  JR NZ,DiagonalCellLoop  ; not yet column 32: the next cell
DiagonalDone:
  LD A,E                  ; A = the column where this diagonal ended
  POP DE                  ; back to the diagonal's first cell
  POP HL                  ; and its map address
  CP $01                  ; the last diagonal ends at column 1 (it started at
                          ; column -15)
  JR NZ,DiagonalLoop      ; not the last diagonal: one column further left
  RET                     ; all 47 diagonals drawn

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
; neighbour. In NE's deep recording the ship was deferred in 2828 of the 3423
; view draws.
DrawCell:
  PUSH HL                 ; keep the cell
  PUSH DE                 ; and its view row / column
  PUSH AF                 ; and its byte
  BIT 5,A                 ; bit 5: the right half of a block, no sprite of its
                          ; own
  JR NZ,DrawCellObjects   ; covered half: on to the object and the ship
  AND $1F                 ; the block type is the sprite number
  JR Z,DrawCellObjects    ; type 0: no block
  LD HL,DrawSprite+$0012  ; height 0
  LD (HL),$00             ; into DrawSprite's operand
  CALL DrawSprite         ; the block: sprite = its type, A
DrawCellObjects:
  POP AF                  ; then the object (bit 6) and the ship (bit 7)
  POP DE                  ; the view position back
  POP HL                  ; the cell back
  BIT 6,A                 ; bit 6: an object stands or is deferred here
  CALL NZ,DrawCellObject  ; the robot, building or shot of this cell
  LD A,(HL)               ; the cell's byte again (A was used)
  BIT 7,A                 ; bit 7: the ship
  RET Z                   ; no ship here: done
  LD BC,(ShipDrawPos)           ; already deferred?
  LD A,B                  ; ShipDrawPos not 0: this is the cell the ship was
                          ; deferred to
  OR C                    ; (B the row, C the column)
  JR NZ,ShipDeferred      ; draw the ship there
  PUSH DE                 ; DE = the latest cell found so far: this one
  LD D,H                  ; the ship's own cell is the latest so far
  LD E,L                  ; (DE = HL)
  CALL FindLatestBlock    ; the blocks around the ship's cell
  PUSH HL                 ; keep the ship's cell
  DEC HL                  ; (x-1, y-1)
  DEC H                   ; (two DEC H: one map row up)
  DEC H                   ; (the row's second half)
  CALL CheckObjectNeighbour ; an object there and the blocks around it
  INC H                   ; (x-1, y)
  INC H                   ; (one map row down)
  CALL CheckObjectNeighbour ; an object there and the blocks around it
  INC H                   ; (x-1, y+1) unless past row 15
  INC H                   ; (one map row down)
  LD A,H                  ; the row of (x-1, y+1)
  CP $FD                  ; $FD00: row 16, past the map
  JR NC,ShipCompareLatest ; the ship is on row 15: no cells below
  CALL CheckObjectNeighbour ; an object there and the blocks around it
  INC HL                  ; (x, y+1)
  CALL CheckObjectNeighbour ; an object there and the blocks around it
  INC HL                  ; (x+1, y+1)
  CALL CheckObjectNeighbour ; an object there and the blocks around it
ShipCompareLatest:
  POP HL                  ; is the latest object cell the ship's own? Then draw
                          ; it now, else defer
  LD A,D                  ; the latest cell's high byte
  CP H                    ; the ship's?
  JR NZ,ShipDefer         ; another cell: defer the ship to it
  LD A,E                  ; the low byte
  CP L                    ; the ship's?
  JR NZ,ShipDefer         ; another cell: defer
  POP DE                  ; the view position back (the ship's own)
  JR ShipDrawNow          ; draw the ship now
ShipDefer:
  EX DE,HL                ; mark the later cell with bit 7, keep the ship's
                          ; view position
  SET 7,(HL)              ; bit 7 on the later cell: draw the ship there
  EX DE,HL                ; HL = the ship's cell again
  POP DE                  ; DE = the ship's view row / column
  LD (ShipDrawPos),DE           ; $FD11 = column, $FD12 = row
  RET                     ; nothing drawn yet
ShipDeferred:
  RES 7,(HL)              ; the deferred cell: clear its mark and draw at the
                          ; kept position
  PUSH HL                 ; keep the deferred cell
  PUSH DE                 ; and its view position
  LD D,B                  ; D = the ship's view row, kept in ShipDrawPos
  LD E,C                  ; E = its view column
  JR ShipDraw             ; draw it there
ShipDrawNow:
  PUSH HL                 ; keep the cell
  PUSH DE                 ; and the view position (the ship's own)
ShipDraw:
  LD A,(Altitude)            ; sprite 0 at height Altitude
  LD (DrawSprite+$0012),A ; into DrawSprite's operand
  XOR A                   ; sprite 0: the ship
  CALL DrawSprite         ; draw it, over everything drawn so far
  POP DE                  ; the view position back
  POP HL                  ; the cell back
  RET                     ; back to the walk

; Ship: an object at HL counts, and so do the blocks around it
;
; Used for the ship's neighbours: if HL has bit 6 (a robot, a building or a
; shot stands there, or one was deferred there) it competes (KeepLaterCell),
; and then the code falls into FindLatestBlock for the blocks around that
; object, because the ship flies above objects and their own neighbours can
; cover it too. In: HL the cell, DE the latest cell so far. Out: DE the latest.
; HL kept.
CheckObjectNeighbour:
  BIT 6,(HL)              ; an object (bit 6) on this neighbour?
  RET Z                   ; none: nothing competes
  CALL KeepLaterCell      ; it competes; then, falling through, the blocks
                          ; around it

; DE = the cell drawn last among DE and the blocks next to HL
;
; Checks the blocks (bit 5 clear, type not 0) at (x-1,y+1), (x,y+1) (both only
; when y+1 < 16), (x-1,y) and (x+1,y+1) (y+1 < 16) of cell HL with
; CheckBlockNeighbour; (x+1,y) is passed over (HL only goes through it). Those
; are the cells whose sprites can overlap a robot, a shot or the ship standing
; at HL. HL is kept. Used by DrawCell (the ship) and DrawMover (robots, shots).
FindLatestBlock:
  PUSH HL                 ; keep HL: the cell the neighbours are taken around
  DEC HL                  ; (x-1, y+1)
  INC H                   ; (one map row down)
  INC H                   ; (the row's second half)
  LD A,H                  ; row 16 is past the map ($DD00 + $200*16 = $FD00)
  CP $FD                  ; at or past $FD00?
  JR NC,FindLatestSameRow ; y = 15: no cells below; only (x-1, y) is checked
  CALL CheckBlockNeighbour ; (x-1, y+1)
  INC HL                  ; (x, y+1)
  CALL CheckBlockNeighbour ; (x, y+1)
  DEC HL                  ; back to (x-1, y+1)
FindLatestSameRow:
  DEC H                   ; the cells (x-1, y) through (x+1, y+1)
  DEC H                   ; (one map row up)
  CALL CheckBlockNeighbour ; (x-1, y)
  INC HL                  ; through (x+1, y) to (x+1, y+1), unless past row 15
  INC HL                  ; (x+1, y): passed over, never checked
  INC H                   ; (one map row down)
  INC H                   ; (the row's second half)
  LD A,H                  ; the row of (x+1, y+1)
  CP $FD                  ; past row 15?
  CALL C,CheckBlockNeighbour ; (x+1, y+1) when on the map
  POP HL                  ; HL back: the cell the search was around
  RET                     ; DE = the latest cell

; A block at HL competes for the latest cell
;
; Bit 5 set (the right half of a block) or type 0 (empty): nothing. Otherwise
; falls into KeepLaterCell.
CheckBlockNeighbour:
  BIT 5,(HL)              ; covered half of a 2 x 2 block?
  RET NZ                  ; yes: it has no sprite of its own
  LD A,(HL)               ; the cell's byte
  AND $1F                 ; the block type
  RET Z                   ; empty: nothing to compete

; DE = HL if map cell HL is drawn after cell DE
;
; The drawing order of DrawMapObjects: diagonals by falling x - y, along a
; diagonal by rising x. A = (yHL - yDE) + (xDE - xHL) (columns by the low
; bytes, rows from the high bytes: (H - $DD) / 2). A > 0: HL's diagonal is
; later; A = 0: same diagonal, later when xHL > xDE.
KeepLaterCell:
  LD A,E                  ; the column of DE (the low byte)
  SUB L                   ; C = xDE - xHL
  LD C,A                  ; (C = xDE - xHL)
  LD A,D                  ; B = yDE
  SUB $DD                 ; minus the map's base page
  SRL A                   ; / 2: a map row is two pages
  LD B,A                  ; (B = yDE)
  LD A,H                  ; A = yHL - yDE + xDE - xHL
  SUB $DD                 ; minus the map's base page
  SRL A                   ; / 2: yHL
  SUB B                   ; yHL - yDE
  ADD A,C                 ; + xDE - xHL: the diagonal difference
  RET M                   ; HL drawn earlier
  JR NZ,KeepLaterTake     ; positive: HL's diagonal is later
  LD A,C                  ; same diagonal: the bigger column is later
  OR A                    ; xDE - xHL
  RET P                   ; xHL <= xDE: DE stays the latest
KeepLaterTake:
  LD D,H                  ; HL is later: DE = HL
  LD E,L                  ; (DE = HL)
  RET                     ; DE = the latest cell

; Z: IY the robot record standing on map cell HL, B = 48 - its slot (slots 0-23
; the player's)
;
; Walks the 48 records of Robots (16 bytes: slots 0-23 the player's, 24-47 the
; enemy's) comparing the draw cell +$00/+$01 with HL; a free slot has +$01 = 0
; and never matches a map address. Out: Z, IY = the record, B = 48 - slot; NZ
; when none. DE is kept. A robot deferred by DrawMover is found at the deferred
; cell, as the walk needs it. Called by DrawCellObject, PlayLoop (the robot
; under the ship), the captures, the shot hits, the blast and ObjectTop.
FindRobot:
  LD IY,$DA00             ; the 48 robot records, 16 bytes each
  LD B,$30                ; 48 slots: B = 48 - the slot at a match
FindRobotLoop:
  LD A,(IY+$00)           ; compare +$00/+$01 with HL
  CP L                    ; the low byte of the cell
  JR NZ,FindRobotNext     ; not this robot
  LD A,(IY+$01)           ; the high byte (0 for a free slot)
  CP H                    ; the same cell?
  RET Z                   ; found: Z, IY = the record
FindRobotNext:
  PUSH DE                 ; the next 16-byte robot record
  LD DE,$0010             ; the record size
  ADD IY,DE               ; IY = the next record
  POP DE                  ; DE back (the view position for DrawCellObject)
  DJNZ FindRobotLoop      ; the next slot
  OR $01                  ; none: NZ
  RET                     ; IY past the last record

; Z: IY the building record (Buildings) on map cell HL
;
; Walks the 56 records of Buildings (3 bytes: the map cell address, the type)
; comparing the cell with HL. Out: Z, IY = the record; NZ when none. DE is
; kept. Called by DrawCellObject, CheckWarbasePad (the construction menu's
; pad), ObjectTopBuilding and RemoveBuilding.
FindBuilding:
  LD IY,Buildings             ; the 56 building records, 3 bytes each
  LD B,$38                ; 56 records
FindBuildingLoop:
  LD A,(IY+$00)           ; compare the cell address with HL
  CP L                    ; the low byte of the cell
  JR NZ,FindBuildingNext  ; not this building
  LD A,(IY+$01)           ; the high byte
  CP H                    ; the same cell?
  RET Z                   ; found: Z, IY = the record
FindBuildingNext:
  PUSH DE                 ; the next 3-byte building record
  LD DE,$0003             ; the record size
  ADD IY,DE               ; IY = the next record
  POP DE                  ; DE back
  DJNZ FindBuildingLoop   ; the next record
  OR $01                  ; none: NZ
  RET                     ; IY past the last record

; Draw the object of map cell HL (bit 6): a robot, a building or a shot
;
; A robot whose +$00/+$01 is HL goes to DrawMover. A building record goes to
; its sprite: BuildingSprites[type] at height BuildingHeights[type]. Otherwise
; the five shot records at $D7D3 (9 bytes: +$00/+$01 cell, +$02/+$03 x, +$04 y,
; +$05 direction, +$06 range, +$07 weapon 1-3, +$08 height) are searched; a
; match goes to DrawMover. Nothing found: nothing drawn. 8330 calls in NE's
; deep recording: 1485 robots, 6845 buildings, the shot search never ran (no
; shot stood in the view while it was drawn; the shot path is read from the
; code and from the shot records at frame 20000).
DrawCellObject:
  CALL FindRobot          ; a robot whose draw cell +$00/+$01 is HL?
  JR Z,DrawMover          ; a robot here
  CALL FindBuilding       ; a building whose cell is HL?
  JR Z,DrawBuilding       ; a building here
  LD IY,Shots             ; the five shot records, 9 bytes each
  LD B,$05                ; 5 records
ShotSearchLoop:
  LD A,(IY+$00)           ; the shot's draw cell, the low byte
  CP L                    ; this cell?
  JR NZ,ShotSearchNext    ; no: the next shot
  LD A,(IY+$01)           ; the high byte (0: a free record)
  CP H                    ; this cell?
  JR Z,DrawMover          ; a shot here
ShotSearchNext:
  PUSH DE                 ; the next 9-byte shot record
  LD DE,$0009             ; the record size
  ADD IY,DE               ; IY = the next shot
  POP DE                  ; DE back
  DJNZ ShotSearchLoop     ; the next shot
  RET                     ; nothing found: nothing drawn
DrawBuilding:
  PUSH HL                 ; building type C: sprite and height from the tables
                          ; below
  PUSH DE                 ; and the view position
  LD A,(IY+$02)           ; the building's type, 0-8
  LD C,A                  ; kept in C
  LD HL,BuildingHeights   ; the height of the type
  CALL AddAToHL           ; HL = BuildingHeights + the type
  LD A,(HL)               ; the type's height
  LD (DrawSprite+$0012),A ; into DrawSprite's operand
  LD A,C                  ; the type again
  LD HL,BuildingSprites   ; the sprite of the type
  CALL AddAToHL           ; HL = BuildingSprites + the type
  LD A,(HL)               ; the type's sprite
  CALL DrawSprite         ; draw it
  POP DE                  ; the view position back
  POP HL                  ; the cell back
  RET                     ; back to DrawCell

; The sprite of each building type
;
; Index = the Buildings type: 0 the player's warbase pad $2C (a crate),
; factories 1 electronics $28, 2 nuclear $25, 3 phasers $23, 4 missiles $20, 5
; cannon $1D, 6 chassis $17 (each the robot part of its product, facing down:
; $16 + the parts table $D6C8), 7 and 8 the flags $2A and $2B. In NE's deep
; recording at frame 20000 the type 7 / 8 records stand two columns left of a
; factory (four of the player's warbase pad): a factory's owner flag; 7 the
; player's, 8 the enemy's.
;
; The bytes: $2C, $28, $25, $23, $20, $1D, $17, $2A, $2B. Read by DrawBuilding.
BuildingSprites:
  DEFB $2C,$28,$25,$23,$20,$1D,$17,$2A,$2B ; by building type: 0 pad 44 (the
                                           ; warbase sign), factories 1
                                           ; electronics 40, 2 nuclear 37, 3
                                           ; phasers 35, 4 missiles 32, 5
                                           ; cannon 29, 6 chassis 23, flags 7
                                           ; ours 42, 8 the enemy's 43

; The height each building sprite is drawn at
;
; Type 0 at $13, the six factory signs at $0F (on the factory's roof blocks),
; the flags at $1A: the bytes $13, $0F x 6, $1A, $1A. Read by DrawBuilding into
; DrawSprite's height operand. Not the heights the ship lands on: those are
; BuildingTops (the world module).
BuildingHeights:
  DEFB $13,$0F,$0F,$0F,$0F,$0F,$0F,$1A,$1A ; type 0 the pad $13, factory signs
                                           ; 1-6 $0F (on the roof blocks),
                                           ; flags 7-8 $1A

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
; every block whose sprite overlaps it. In NE's deep recording 1485 robot draws
; reached here; 18 were deferred (each drawn later at the walked-back
; position), 1449 drawn at once. No shot reached here: see DrawCellObject.
DrawMover:
  PUSH DE                 ; keep the view position
  LD D,H                  ; this cell is the latest so far
  LD E,L                  ; (DE = HL)
  CALL FindLatestBlock    ; a later block next to it?
  LD A,D                  ; the latest cell's high byte
  CP H                    ; this cell's?
  JR NZ,MoverDefer        ; another cell: defer
  LD A,E                  ; the low byte
  CP L                    ; this cell's?
  JR Z,MoverDeferred      ; no later block: draw here if it is the real cell
MoverDefer:
  EX DE,HL                ; defer: mark the later cell and point the record at
                          ; it
  SET 6,(HL)              ; bit 6 on the later cell: the walk calls
                          ; DrawCellObject there
  LD (IY+$00),L           ; the record's draw cell = the later cell, so
                          ; FindRobot / the shot search find it there
  LD (IY+$01),H           ; (the high byte)
  EX DE,HL                ; HL = this cell again
  POP DE                  ; the view position back
  RET                     ; nothing drawn yet
MoverDeferred:
  POP DE                  ; reached: the real cell from +$02-$04
  PUSH DE                 ; keep it again
  EX DE,HL                ; DE = this cell
  LD L,(IY+$02)           ; the real x, low byte (+$02)
  LD H,(IY+$03)           ; the real x, high byte (+$03)
  LD A,(IY+$04)           ; the real y (+$04)
  CALL MapCell            ; HL = the real map cell
  LD A,D                  ; the real cell's high byte
  CP H                    ; this cell's?
  JR NZ,MoverRestore      ; no: the object was deferred here
  LD A,E                  ; the low byte
  CP L                    ; this cell's?
  JR NZ,MoverRestore      ; no: deferred here
  POP DE                  ; this is the real cell: draw here
  JR DrawMoverSprite      ; draw at this view position
MoverRestore:
  LD (IY+$00),L           ; deferred: the record back to its real cell, the
                          ; mark cleared
  LD (IY+$01),H           ; (the high byte)
  LD B,H                  ; BC = the real cell
  LD C,L                  ; (C its column's low byte, B its row page)
  EX DE,HL                ; HL = the deferred cell
  POP DE                  ; DE = its view position
  PUSH DE                 ; kept for the return
  PUSH HL                 ; and the deferred cell
  RES 6,(HL)              ; the deferral mark off the deferred cell
  DEC HL                  ; the view column: from the deferred column - 1 up to
                          ; the real one
  DEC E                   ; (one view column left too: the loop steps right
                          ; again)
MoverColumnLoop:
  LD A,C                  ; the real column
  CP L                    ; reached?
  JR Z,MoverRowLoop       ; yes: now the row
  INC HL                  ; one column right
  INC E                   ; and in the view
  JR MoverColumnLoop      ; again
MoverRowLoop:
  LD A,B                  ; the view row: up to the real row
  CP H                    ; reached?
  JR Z,MoverDrawReal      ; yes: draw
  DEC H                   ; (one map row up)
  DEC H                   ; (the row's second half)
  DEC D                   ; and in the view
  JR MoverRowLoop         ; again
MoverDrawReal:
  CALL DrawMoverSprite    ; at the real row: draw the sprite there
  POP HL                  ; the deferred cell back
  POP DE                  ; its view position back
  RET                     ; back to the walk

; Draw IY: a robot record ($DA00 up) as a stack of parts, a shot as one sprite
;
; Records at $D800 and up are robots: DrawRobot. A shot (records at $D7D3) is
; sprite $2B + 2 * weapon (+$07: 1 cannon, 2 missiles, 3 phasers) + 1 when it
; flies down or up (+$05 = 4 or 8), at height +$08: $2D/$2E a cannon shell,
; $2F/$30 a missile trail, $31/$32 a phaser beam (the sprite pictures in
; start.bin). The shot branch did not run in NE's recordings.
DrawMoverSprite:
  PUSH IY                 ; IY's high byte tells robots from shots
  POP BC                  ; BC = the record's address
  LD A,B                  ; its high byte
  CP $D8                  ; $D800 and up: the robots (from $DA00); the shots
                          ; are at $D7D3
  JP NC,DrawRobot         ; a robot: the stack of parts
  PUSH HL                 ; keep the cell
  PUSH DE                 ; and the view position
  LD C,(IY+$07)           ; C = the weapon, +$07: 1 cannon, 2 missiles, 3
                          ; phasers
  LD A,(IY+$05)           ; the direction +$05: 1 right, 2 left, 4 down, 8 up
  CP $03                  ; carry for 1 / 2 (right / left); the CCF turns it
                          ; round
  CCF                     ; carry: 4 / 8, down / up: the picture for that axis
  RL C                    ; C = 2 * weapon + axis
  LD A,(IY+$08)           ; the shot's height
  LD (DrawSprite+$0012),A ; into DrawSprite's operand
  LD A,$2B                ; the shot sprites $2D-$32 start at $2B + 2 * 1
  ADD A,C                 ; + 2 * weapon + axis
  CALL DrawSprite         ; draw the shot
  POP DE                  ; the view position back
  POP HL                  ; the cell back
  RET                     ; back to DrawMover

; Draw robot IY at view row D, column E: its parts bottom up
;
; Height starts at +$0D (the ground under the robot, 0 in the construction
; menu); for each bit of the parts mask +$07 from bit 0 (bipod, tracks,
; anti-grav, cannon, missiles, phasers, nuclear, electronics) DrawRobotPart
; draws the part and raises the height. Called by DrawMoverSprite and
; ShowRobotDesign.
DrawRobot:
  PUSH HL                 ; keep the cell
  LD C,(IY+$07)           ; C = the parts mask +$07, bit 0 bipod ... bit 7
                          ; electronics
  LD B,$08                ; 8 parts
  LD A,(IY+$0D)           ; the base height
  LD (DrawSprite+$0012),A ; into DrawSprite's operand
RobotPartLoop:
  RR C                    ; the next part's bit, from bit 0, into the carry
  CALL C,DrawRobotPart    ; this part fitted?
  DJNZ RobotPartLoop      ; the next part
  POP HL                  ; the cell back
  RET                     ; back to DrawMoverSprite or ShowRobotDesign

; Draw part 8 - B of robot IY facing +$08, then raise the height
;
; Sprite = $16 + the parts table $D6C8[4 * part + direction], direction = the
; number of the lowest set bit of +$08 (0 right, 1 left, 2 down, 3 up, the
; Input bits). After drawing, the height ($CF3F) grows by the part's height
; $D7B4[part]: bipod 11, tracks 7, anti-grav 8, cannon 6, missiles 6, phasers
; 7, nuclear 7, electronics 7.
DrawRobotPart:
  PUSH BC                 ; keep the part count
  PUSH DE                 ; and the view position
  LD A,$08                ; A = the part number
  SUB B                   ; part = 8 - B: 0 bipod ... 7 electronics
  PUSH AF                 ; keep it for the height
  LD C,(IY+$08)           ; C = the facing +$08: one bit of 1 right, 2 left, 4
                          ; down, 8 up (0 would loop forever)
  LD B,$FF                ; B = the direction number
DirectionLoop:
  INC B                   ; count the bits ...
  RR C                    ; ... from bit 0 ...
  JR NC,DirectionLoop     ; ... until the set one: B = 0 right, 1 left, 2 down,
                          ; 3 up
  ADD A,A                 ; 4 directions a part
  ADD A,A                 ; part * 4
  ADD A,B                 ; + direction
  LD HL,PartSpriteTable   ; the parts' sprite table
  CALL AddAToHL           ; HL = the entry
  LD A,(HL)               ; the part's sprite - $16
  ADD A,$16               ; the part sprites start at $16
  CALL DrawSprite         ; draw the part at the current height
  POP AF                  ; A = the part again
  POP DE                  ; the view position back
  POP BC                  ; the part count back
  LD HL,PartHeights       ; the part's height
  CALL AddAToHL           ; HL = PartHeights + part
  LD A,($CF3F)            ; the height this part stood at (the operand)
  ADD A,(HL)              ; + the part's own height
  LD (DrawSprite+$0012),A ; the next part stands on top of it
  RET                     ; back to DrawRobot's loop

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
; calls, 978 M T-states in NE's deep recording.
DrawSprite:
  LD C,A                  ; keep the sprite number
  RLC E                   ; E * 2
  LD A,E                  ; 2E
  ADD A,D                 ; L = 2E + D - 24: the column in half bytes
  SUB $18                 ; - 24
  LD L,A                  ; L = the column in half bytes (may be negative)
  RLC E                   ; E * 4
  LD A,D                  ; H = 8D + 100 - 4E - height
  ADD A,A                 ; 2D
  ADD A,A                 ; 4D
  ADD A,A                 ; 8D
  ADD A,$64               ; + 100
  SUB E                   ; - 4E
  SUB $00                 ; the height: the operand $CF3F, written by the
                          ; callers
  LD H,A                  ; H = the buffer line of the sprite's bottom line
  LD A,C                  ; the sprite number, 0-$3F
  AND $3F                 ; sprite numbers have 6 bits
  SRA L                   ; byte column; carry = the odd half byte
  ADC A,A                 ; two images a sprite: 0 aligned, 1 shifted by 4
                          ; pixels
  PUSH HL                 ; keep L and H
  LD HL,SpriteTable       ; the sprite pointers, two a sprite
  CALL TableWord          ; HL = the sprite
  LD C,(HL)               ; C = rows, B = bytes a row
  INC HL                  ; (B = the width)
  LD B,(HL)               ; B = bytes a row
  INC HL                  ; HL = the first (mask, pixels) pair of the bottom
                          ; row
  EX DE,HL                ; DE = the sprite data
  POP HL                  ; L = the byte column, H = the bottom line
  XOR A                   ; no bytes clipped on the left yet
  LD (SpriteRowLoop+$0003),A ; the operand $CFAF = 0
  LD A,L                  ; past the right edge?
  CP $14                  ; column 20 or more (positive)?
  RET P                   ; right of the buffer: nothing
  LD A,H                  ; the bottom line below the buffer?
  CP $A0                  ; line 160 or more?
  JR C,ClipLeft           ; no: on to the left clip
  CP $E2                  ; entirely below
  RET NC                  ; $E2 and up: no row reaches the buffer
  SUB $9F                 ; rows below the buffer
  SUB C                   ; minus the sprite's rows
  RET P                   ; every row below the buffer: nothing
  NEG                     ; C = the rows that remain
  LD C,A                  ; the rows that stay in the buffer
ClipBottomLoop:
  PUSH BC                 ; skip a row of the sprite
ClipBottomSkip:
  INC DE                  ; skip the sprite row's bytes
  INC DE                  ; (2 bytes a pair)
  DJNZ ClipBottomSkip     ; each pair of the row
  POP BC                  ; the width back
  DEC H                   ; the bottom line one up
  LD A,H                  ; up to the buffer's last line?
  CP $9F                  ; line 159
  JR NZ,ClipBottomLoop    ; not yet: skip another row
ClipLeft:
  LD A,L                  ; the byte column
  OR A                    ; negative?
  JP P,ClipRight          ; no: on to the right clip
  NEG                     ; bytes cut on the left
  LD (SpriteRowLoop+$0003),A ; the bytes to skip each row: the operand $CFAF
  LD L,$00                ; draw from column 0
  CP B                    ; all the sprite's bytes cut?
  RET NC                  ; yes: nothing left
ClipRight:
  LD A,L                  ; the start column
  ADD A,B                 ; + the width: the column past the sprite
  CP $15                  ; 20 or less: it fits
  JR C,BufferAddress      ; on to the drawing
  SUB $14                 ; bytes cut on the right
  LD (SpriteRowLoop+$0003),A ; the same skip operand: with the source moved
                             ; back, each row's skip eats the tail of the row
                             ; before
ClipRightLoop:
  DEC DE                  ; start that many pairs earlier: each row then leaves
                          ; out its last pairs
  DEC DE                  ; (one pair: 2 bytes)
  DEC A                   ; one pair less to move
  JR NZ,ClipRightLoop     ; until all cut pairs
BufferAddress:
  PUSH DE                 ; DE = $5B00 + 20*H + L
  LD A,L                  ; the byte column
  PUSH AF                 ; kept
  LD L,H                  ; the line ...
  LD H,$00                ; ... into HL
  ADD HL,HL               ; 2 x
  ADD HL,HL               ; 4 x
  LD D,H                  ; DE = 4 x line
  LD E,L                  ; (the low byte)
  ADD HL,HL               ; 8 x
  ADD HL,HL               ; 16 x
  ADD HL,DE               ; 20 x line
  POP AF                  ; the column back
  CALL AddAToHL           ; + the column
  LD DE,$5B00             ; the buffer's start
  ADD HL,DE               ; HL = the buffer byte of the bottom row
  POP DE                  ; DE = the sprite data
  EX DE,HL                ; now DE = the buffer, HL = the sprite
SpriteRowLoop:
  PUSH BC                 ; keep the rows left and the width
  PUSH DE                 ; and this row's buffer address
  LD A,$00                ; bytes to skip on the left: the operand $CFAF
  OR A                    ; any bytes to skip?
  JP Z,SpriteByteLoop     ; none
SkipLeftLoop:
  INC HL                  ; skip a (mask, pixels) pair ...
  INC HL                  ; ... both bytes
  DEC B                   ; one byte fewer to draw
  DEC A                   ; one skip less
  JP NZ,SkipLeftLoop      ; until all skipped
SpriteByteLoop:
  LD A,(DE)               ; AND the mask, OR the pixels
  AND (HL)                ; the mask keeps the background outside the outline
  INC HL                  ; to the pixels
  OR (HL)                 ; the sprite's ink
  LD (DE),A               ; into the buffer
  INC HL                  ; the next pair
  INC DE                  ; the next buffer byte
  DJNZ SpriteByteLoop     ; each byte of the row
  POP DE                  ; the row's start
  POP BC                  ; the rows and the width back
  LD A,$EC                ; one buffer row up
  ADD A,E                 ; (E - 20)
  LD E,A                  ; the low byte
  JP C,SpriteRowNext      ; no borrow: D stays
  DEC D                   ; borrow from D
  LD A,D                  ; the high byte
  CP $5A                  ; above $5B00: stop
  RET Z                   ; $5Axx: the top of the sprite is cut off
SpriteRowNext:
  DEC C                   ; the next sprite row
  JP NZ,SpriteRowLoop     ; more rows: the next one up
  RET                     ; the sprite is drawn

; Clear the view buffer and paint the corners outside the map
;
; ClearViewBuffer, FillViewCorner (the solid top left corner), then the
; diagonal edge strips from $D6A8: 6 strips down and left from buffer row 0,
; column 10 (the top left edge), 3 from row 136, column 18 and 4 of the other
; diagonal ($D6B8) from row 128, column 18 (the bottom right corner, the blue
; area that DrawPlayScreen colours $41 / $71). Called by DrawView and once by
; $A62D.
DrawViewBackground:
  CALL ClearViewBuffer    ; all 3200 bytes to 0
  CALL FillViewCorner     ; the solid staircase of the top left corner
  LD HL,ViewEdgeA         ; the edge, ink on the left
  LD B,$06                ; 6 strips: the far left edge of the map
  LD DE,$5B0A             ; row 0, column 10
  CALL DrawEdgeStrips     ; down and left from the top
  LD HL,ViewEdgeA         ; the same edge
  LD B,$03                ; 3 strips at the bottom
  LD DE,$65B2             ; row 136, column 18
  CALL DrawEdgeStrips     ; the lower part of the edge
  LD HL,ViewEdgeB         ; the edge with the ink on the right
  LD B,$04                ; 4 strips: the near right corner past the map's
                          ; south edge
  LD DE,$6512             ; row 128, column 18
  JP DrawEdgeStrips       ; its RET ends DrawViewBackground

; Zero the view buffer $5B00-$677F (20 bytes x 160 rows)
;
; Pushes HL = 0 with SP at $6780 (198 x 16 bytes, SP kept in $FD08), then
; clears the first 32 bytes with LDIR. Called by DrawViewBackground,
; ShowRobotDesign and $CB52.
ClearViewBuffer:
  LD (SavedSP),SP           ; keep SP
  LD SP,Font              ; the end of the buffer
  LD B,$C6                ; 198 x 8 words
  LD HL,$0000             ; the zeros to push
ClearPushLoop:
  PUSH HL                 ; 8 pushes: 16 bytes a pass, down from $6780 (an
                          ; interrupt pushes into the part not yet cleared)
  PUSH HL                 ; 2
  PUSH HL                 ; 3
  PUSH HL                 ; 4
  PUSH HL                 ; 5
  PUSH HL                 ; 6
  PUSH HL                 ; 7
  PUSH HL                 ; 8
  DJNZ ClearPushLoop      ; 198 passes: down to $5B20
  LD SP,(SavedSP)           ; SP back
  LD HL,$5B00             ; the 32 bytes left at the start
  LD DE,$5B01             ; the LDIR copies the zero along
  LD BC,$001F             ; 31 more bytes
  LD (HL),$00             ; the first zero
  LDIR                    ; $5B00-$5B1F
  RET                     ; the buffer is clear

; Fill the top left corner of the view buffer: a staircase of 5 bands
;
; 5 bands of 8 rows; the first fills 10 bytes of each row, each next band 2
; fewer (10, 8, 6, 4, 2). The fill and skip counts are the operands $D038 and
; $D041, reset to 10 at the start and moved by 2 after each band. The '98 file
; holds 0 and $14 there (NE's tape 10 and 10): the counts after the fifth band
; of the last call before ZS saved the memory; the start of each call writes 10
; into both again, so the code is NE's. Ran 100 times in this part's play
; recording, 2699 in deep.
FillViewCorner:
  LD A,$0A                ; 10 for both counts
  LD (CornerRowLoop+$0002),A ; bytes filled a row
  LD (CornerByteLoop+$0006),A ; bytes skipped a row
  LD HL,$5B00             ; from the buffer's top left corner
  LD B,$05                ; 5 bands
BandLoop:
  PUSH BC                 ; keep the band count
  LD B,$08                ; 8 rows a band
CornerRowLoop:
  PUSH BC                 ; keep the row count
  LD B,$00                ; the fill count: the operand $D038
  LD A,$FF                ; all ink
CornerByteLoop:
  LD (HL),A               ; fill a byte
  INC HL                  ; the next byte
  DJNZ CornerByteLoop     ; the fill count
  POP BC                  ; the row count back
  LD A,$14                ; the skip count: the operand $D041
  CALL AddAToHL           ; HL = the next row's start (fill + skip = 20)
  DJNZ CornerRowLoop      ; the next row of the band
  POP BC                  ; the band count back
  PUSH HL                 ; keep the buffer address
  LD HL,CornerRowLoop+$0002 ; 2 bytes fewer, 2 more skipped
  DEC (HL)                ; fill 2 bytes fewer ...
  DEC (HL)                ; ... (10, 8, 6, 4, 2)
  LD HL,CornerByteLoop+$0006 ; the skip count
  INC (HL)                ; skip 2 bytes more ...
  INC (HL)                ; ... (10, 12, 14, 16, 18)
  POP HL                  ; the buffer address back
  DJNZ BandLoop           ; the next band
  RET                     ; the corner is filled

; Copy B strips of 8 rows x 2 bytes (pattern HL) into the buffer, each 8 rows
; down and 2 bytes left
;
; The diagonal edge of the map in the view. The patterns are at $D6A8 (ink on
; the left: $FFFF, $FFFC, ..., $C000) and $D6B8 (ink on the right).
DrawEdgeStrips:
  PUSH BC                 ; keep the strip count
  PUSH HL                 ; and the pattern
  LD BC,$08FF             ; B = 8 rows; C = $FF: the 16 LDI decrement C only, B
                          ; stays the DJNZ count
StripRowLoop:
  LDI                     ; the pattern's left byte
  LDI                     ; and its right byte
  LD A,$12                ; the next row: 20 bytes in all
  ADD A,E                 ; + 18: DE back to the strip's column, one row down
  LD E,A                  ; (the low byte)
  LD A,D                  ; the carry ...
  ADC A,$00               ; ... into ...
  LD D,A                  ; ... D
  DJNZ StripRowLoop       ; the next row
  POP HL                  ; the pattern again for the next strip
  POP BC                  ; the strip count back
  DEC DE                  ; 2 bytes left for the next strip
  DEC DE                  ; (DE is already 8 rows down)
  DJNZ DrawEdgeStrips     ; the next strip
  RET                     ; the edge is drawn

; Copy the view buffer to the screen at character row 1, column 1 (20 x 20
; characters)
;
; 160 lines of 20 bytes with unrolled LDI, the destination stepped through the
; screen's thirds. 256 M T-states in NE's deep recording.
CopyViewToScreen:
  LD HL,$5B00             ; from the buffer's first line
  LD DE,$4021             ; the screen: line 0 of character row 1, column 1
  LD C,$14                ; 20 character rows
CopyCharRowLoop:
  LD B,$08                ; 8 pixel lines a character row
CopyLineLoop:
  PUSH BC                 ; keep the counts (the LDIs change BC)
  PUSH DE                 ; and the line's screen address
  LDI                     ; the 20 bytes of the line, unrolled: byte 1
  LDI                     ; 2
  LDI                     ; 3
  LDI                     ; 4
  LDI                     ; 5
  LDI                     ; 6
  LDI                     ; 7
  LDI                     ; 8
  LDI                     ; 9
  LDI                     ; 10
  LDI                     ; 11
  LDI                     ; 12
  LDI                     ; 13
  LDI                     ; 14
  LDI                     ; 15
  LDI                     ; 16
  LDI                     ; 17
  LDI                     ; 18
  LDI                     ; 19
  LDI                     ; 20
  POP DE                  ; the line's start again
  POP BC                  ; the counts back
  INC D                   ; the next pixel line
  DJNZ CopyLineLoop       ; the next pixel line of the character row
  LD A,E                  ; the next character row
  ADD A,$20               ; + 32: the next character row (the source HL runs on
                          ; by itself)
  LD E,A                  ; the low byte
  JR C,CopyCharRowNext    ; carry: into the next third, where D (+8 from the
                          ; lines) already points
  LD A,D                  ; inside the same third ...
  SUB $08                 ; ... D back by the 8 lines
  LD D,A                  ; (the character row's line 0)
CopyCharRowNext:
  DEC C                   ; the next character row
  JP NZ,CopyCharRowLoop   ; the next of the 20 character rows
  RET                     ; the view is on the screen
