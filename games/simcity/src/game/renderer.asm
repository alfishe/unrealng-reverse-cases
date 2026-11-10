; --------------------------------------------------------------------------------------------------------------------
; renderer.asm: The map view renderer
;
; The view: 32 x 16 cells from ViewCol, ViewRow, one row per UI pass (DrawViewRowPass) or all at once (DrawView). A
; map byte below $80 is a cell tile (CellTiles $EA68, CellAttrs $F530); $80 and up starts a building row whose tiles
; come from BuildingTiles $ED58 and BuildingAttrs $F58E. Unpowered zone centres blink, roads show their traffic.
; --------------------------------------------------------------------------------------------------------------------

; Pass bit 4 at the start of the view row's draw: the blink phase
Blink:
  DEFB $00

; Draw one of the view's 16 rows, the one PassCount AND 15 picks
;
; So the view is redrawn every 16 passes of the UI loop, a row a pass, and the
; blinking cells change with PassCount bits 4 and 5. L1 158 073.
DrawViewRowPass:
  LD A,(PassCount)
  AND $10
  LD (Blink),A
  LD A,(PassCount)
  AND $0F
  ADD A,$08
  LD B,A
  LD C,$00
  CALL ScreenAddr
  LD (DrawTileAt+$0001),HL
  LD BC,(ViewCol)
  LD A,(PassCount)
  AND $0F
  ADD A,B
  LD B,A
  CALL MapAddr
  LD DE,$0040
  LD B,$01
  JP DrawViewRow

; The tile number being drawn
TileIndex:
  DEFW $0000

; Draw cell tile $3B (the "no power" lightning) instead: the on phase of the
; blink of an unpowered zone or building
;
; Used by the routine at DrawBuildingTile.
DrawBlankCell:
  LD L,$3B
  JR DrawCellTile

; Draw one view cell: map byte in A (or the building row in progress), tile and
; attribute
;
; A map byte below $80 is a cell tile at CellTiles $EA68 + 8 n with its
; attribute at CellAttrs $F530 + n; inside a building row (BuildingLeft not 0)
; the next building tile is drawn instead (DrawBuildingTile). Cells $54-$56
; blink (BlinkCell); roads 7 and 8 show their traffic (RoadTraffic). The tile
; goes to ViewAt ($6482), the attribute through PutAttr. L1 5 379 061.
DrawCell:
  LD L,A
  LD A,(BuildingLeft)
  AND A
  JR NZ,DrawBuildingTile
  CALL BlinkCell
  CALL RoadTraffic
; This entry point is used by the routine at DrawBlankCell.
DrawCellTile:
  LD H,$00
  LD (TileIndex),HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,CellTiles
  ADD HL,DE
; This entry point is used by the routine at DrawBuildingTile.
DrawTileAt:
  LD DE,Screen+2048             ; LD DE,n: the screen address of the cell (operand
                          ; $6482, ViewAt)
  LD B,$08
DrawTileLoop:
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  DJNZ DrawTileLoop
  LD BC,(TileIndex)
  LD HL,(CellAttrPtr)
  ADD HL,BC
  LD A,(HL)
  EX DE,HL
  JP PutAttr

; Cells $54-$56 (the unpowered zone centres) blink: with PassCount bit 5 set
; they show tile $3B (the lightning)
;
; L1 4 249 059, 11 661 blanked.
BlinkCell:
  LD A,L
  CP $54
  RET C
  CP $57
  RET NC
  LD A,(PassCount)
  BIT 5,A
  RET Z
  LD L,$3B
  RET

; Road cells 7 and 8: heavy traffic shows tile $34 / $36, medium blinks to $35
; / $37
;
; Reads the traffic map at the cell (MapToRowCol $7635, TrafficAt $7581): $DC
; or more heavy, $96-$DB medium (the second tile when Blink is set). L1 668
; 762.
RoadTraffic:
  LD A,L
  LD B,$34
  CP $07
  JR Z,RoadTrafficLook
  LD B,$36
  CP $08
  RET NZ
RoadTrafficLook:
  PUSH HL
  PUSH DE
  PUSH BC
  LD HL,(ViewCellPtr)
  CALL MapToRowCol
  CALL TrafficAt
  LD A,(HL)
  POP BC
  POP DE
  POP HL
  CP $DC
  JR NC,RoadTrafficTile
  CP $96
  RET C
  LD A,(Blink)
  AND A
  JR Z,RoadTrafficTile
  INC B
RoadTrafficTile:
  LD L,B
  RET

; A byte IX points at while a building row is drawn (no reader of its value)
BuildingDummy:
  DEFB $00

; The next tile of the building row in progress: BuildingTiles $ED58 + 8 n,
; attribute $F58E + n
;
; With PassCount bit 5, the first drawn cell of a building row whose start byte
; AND $F0 is $A0 (a top row, power bit 4 clear) shows tile $3B, the lightning.
; IX then points at BuildingDummy, so the row's other cells and the lower rows
; never blink: only the top-left cell of an unpowered building does. L1 1 130
; 002.
DrawBuildingTile:
  LD HL,BuildingLeft
  DEC (HL)
  LD A,(IX+$00)
  LD IX,BuildingDummy
  LD HL,PassCount
  BIT 5,(HL)
  JR Z,DrawBuildingAttr
  AND $F0
  CP $A0
  JP Z,DrawBlankCell
DrawBuildingAttr:
  LD HL,BuildingAttrs
  LD (CellAttrPtr),HL
  LD HL,(BuildingTile)
  LD (TileIndex),HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,BuildingTiles
  ADD HL,DE
  JP DrawTileAt

; The attribute table of the cell being drawn (CellAttrs or BuildingAttrs)
CellAttrPtr:
  DEFW $0000
ViewCol:
  DEFB $1E                ; the view's left column on the map, 0-64
ViewRow:
  DEFB $25                ; the view's top row, 0-80
ViewCellPtr:
  DEFW $0000              ; the map address of the cell being drawn

; Draw the whole view: 16 rows of 32 cells from the map at ViewCol, ViewRow
;
; L1 627 (after every scroll, window and dialog).
DrawView:
  LD HL,Screen+2048
  LD (DrawTileAt+$0001),HL
  LD BC,(ViewCol)
  CALL MapAddr
  LD DE,$0040
  LD B,$10
; This entry point is used by the routine at DrawViewRowPass.
DrawViewRow:
  LD C,$20
DrawViewCell:
  LD A,(BuildingLeft)
  AND A
  JR NZ,DrawViewCellTile
  LD A,(HL)
  CP $80
  CALL NC,StartBuilding
DrawViewCellTile:
  LD (ViewCellPtr),HL
  EXX
  LD HL,CellAttrs
  LD (CellAttrPtr),HL
  CALL DrawCell
  LD HL,(DrawTileAt+$0001)
  INC L
  JR NZ,DrawViewNext
  LD HL,Screen+4096
DrawViewNext:
  LD (DrawTileAt+$0001),HL
  LD HL,(BuildingTile)
  INC HL
  LD (BuildingTile),HL
  EXX
  INC HL
  DEC C
  JR NZ,DrawViewCell
  XOR A
  LD (BuildingLeft),A
  ADD HL,DE
  DJNZ DrawViewRow
  RET

; The cells left in the building row being drawn
BuildingLeft:
  DEFB $00
BuildingTile:
  DEFB $00                ; the tile number n of the next building cell (16
  DEFB $00                ; bits)

; A map byte $80 or more: work out the building's tile number and the cells
; left
;
; From a $C0-$FF byte it steps back to the row's first byte
; (FindBuildingStart). Width = first AND 7, n = (second AND $3F) x 8 + (third
; AND 7) + the cells stepped back. L1 356 616.
StartBuilding:
  PUSH HL
  POP IX
  XOR A
  LD (BuildingBack),A
  EXX
  LD A,(IX+$00)
  CP $C0
  CALL NC,FindBuildingStart
  LD A,(BuildingBack)
  LD C,A
  LD B,$00
  LD A,(IX+$00)
  AND $07
  SUB C
  LD (BuildingLeft),A
  LD A,(IX+$01)
  AND $3F
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,(IX+$02)
  AND $07
  OR L
  LD L,A
  ADD HL,BC
  LD (BuildingTile),HL
  EXX
  RET

; FindBuildingStart's count
BuildingBack:
  DEFB $00

; Step IX back over the $C0-$FF bytes to the row's $80-$BF byte, counting them
;
; L1 34 254 (the buildings cut by the view's left edge).
FindBuildingStart:
  LD HL,BuildingBack
FindBuildingStartLoop:
  LD A,(IX+$00)
  AND $C0
  CP $C0
  RET NZ
  INC (HL)
  DEC IX
  JR FindBuildingStartLoop
