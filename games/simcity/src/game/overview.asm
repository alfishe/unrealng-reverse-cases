; --------------------------------------------------------------------------------------------------------------------
; overview.asm: The maps window's overview
;
; The overview of a 48 x 48 area at 4 x 4 pixels a cell, coloured by the chosen layer.
; --------------------------------------------------------------------------------------------------------------------

; The nine map keys' screen cells (row, column): the keys 1-9 of the maps
; window
MapKeyCells:
  DEFB $04,$03
  DEFB $04,$04
  DEFB $04,$05
  DEFB $05,$03
  DEFB $05,$04
  DEFB $05,$05
  DEFB $06,$03
  DEFB $06,$04
  DEFB $06,$05

; Flip the bright bit of the current key's attribute
;
; Used by the routine at MapsWindow.
HighlightMapKey:
  LD A,(MapArea)
  ADD A,A
  LD C,A
  LD B,$00
  LD HL,MapKeyCells
  ADD HL,BC
  LD B,(HL)
  INC HL
  LD C,(HL)
  CALL AttrAddr
  LD A,(HL)
  XOR $80
  LD (HL),A
  RET

; XOR $46 over the current layer's row of the legend
;
; Used by the routine at MapsWindow.
HighlightLayer:
  LD A,(MapLayer)
  ADD A,$09
  LD B,A
  LD C,$00
  CALL AttrAddr
  LD B,$08
HighlightLayerLoop:
  LD A,(HL)
  XOR $46
  LD (HL),A
  INC L
  DJNZ HighlightLayerLoop
  RET

; Every 4th loop: Q / A change the layer; SYMBOL SHIFT + a digit 1-9 the map
; area (MapsKeysDigit returns if SYMBOL SHIFT is up)
;
; Used by the routine at MapsWindow.
MapsKeys:
  LD A,(MapsCounter)
  AND $03
  JR NZ,MapsKeysDigit
  LD HL,MapLayer
  LD A,(KeyRowQ)
  AND $01
  JR Z,MapsLayerUp
  LD A,(KeyRowA)
  AND $01
  JR Z,MapsLayerDown
MapsKeysDigit:
  LD A,(KeyRowSpace)
  AND $02
  RET NZ
  CALL KeyToChar
  RET C
  SUB $31
  RET C
  CP $09
  RET NC
  LD (MapArea),A
  RET
MapsLayerUp:
  LD A,(HL)
  DEC A
  AND $07
  LD (HL),A
  RET
MapsLayerDown:
  LD A,(HL)
  INC A
  AND $07
  LD (HL),A
  RET

; Draw one cell as 4 x 4 pixels: every second pixel of every second line of its
; tile (or the building tile)
;
; Used by the routine at DrawOverview.
OverviewCell:
  LD L,A
  LD A,(BuildingLeft)
  AND A
  JR NZ,OverviewBuilding
  CALL RoadTraffic
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,CellTiles
  ADD HL,DE
OverviewAt:
  LD DE,Screen+8             ; LD DE,n: the screen address (operand $9BD7)
  INC HL
  CALL ShrinkLine
  INC D
  CALL ShrinkLine
  INC D
  CALL ShrinkLine
  INC D
  JR ShrinkLine
OverviewBuilding:
  LD HL,BuildingLeft
  DEC (HL)
  LD HL,(BuildingTile)
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,BuildingTiles
  ADD HL,DE
  JR OverviewAt

; OverviewSpare
OverviewSpare:
  DEFB $00

; One tile line pair to 4 pixels: bits 7, 5, 3, 1, into the left or right
; nibble
;
; Used by the routine at OverviewCell.
ShrinkLine:
  LD A,(HL)
  AND $80
  LD C,A
  LD A,(HL)
  AND $20
  RLCA
  OR C
  LD C,A
  LD A,(HL)
  AND $08
  RLCA
  RLCA
  OR C
  LD C,A
  LD A,(HL)
  AND $02
  RLCA
  RLCA
  RLCA
  OR C
  LD C,A
  LD B,$0F
  LD A,(RightNibble)
  AND A
  JR Z,ShrinkLineStore
  LD B,$F0
  RRC C
  RRC C
  RRC C
  RRC C
ShrinkLineStore:
  LD A,(DE)
  AND B
  OR C
  LD (DE),A
  INC HL
  INC HL
  RET

; The map area shown, 0-8 (the digit - 1)
MapArea:
  DEFB $00
OverviewSpare2:
  DEFB $00
  DEFB $00
OverviewOrigin:
  DEFB $00                ; the area's top-left cell (column, row)
  DEFB $00
RightNibble:
  DEFB $00                ; 1 when the cell goes in the right half of the byte
OverviewCellAt:
  DEFB $00                ; the cell drawn (column, row)
  DEFB $00
MapAreaAddrs:
  DEFB $50                ; the nine areas' map addresses (48 x 48 cells, 24
  DEFB $C4                ; apart)
  DEFB $68
  DEFB $C4
  DEFB $80
  DEFB $C4
  DEFB $50
  DEFB $CD
  DEFB $68
  DEFB $CD
  DEFB $80
  DEFB $CD
  DEFB $50
  DEFB $D6
  DEFB $68
  DEFB $D6
  DEFB $80
  DEFB $D6
MapAreaCells:
  DEFB $00                ; their top-left (row, column)
  DEFB $00
  DEFB $00
  DEFB $18
  DEFB $00
  DEFB $30
  DEFB $18
  DEFB $00
  DEFB $18
  DEFB $18
  DEFB $18
  DEFB $30
  DEFB $30
  DEFB $00
  DEFB $30
  DEFB $18
  DEFB $30
  DEFB $30

; Draw the 48 x 48 cells of MapArea at 4 x 4 pixels, coloured by the layer;
; stop at a key
;
; L1 105.
DrawOverview:
  LD HL,Screen+8
  LD (OverviewAt+$0001),HL
  XOR A
  LD (RightNibble),A
  LD A,$10
  LD (Blink),A
  LD A,(MapArea)
  ADD A,A
  LD C,A
  LD B,$00
  LD HL,MapAreaAddrs
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD BC,$0011
  ADD HL,BC
  LD B,(HL)
  INC HL
  LD C,(HL)
  LD (OverviewOrigin),BC
  LD A,B
  LD (OverviewCellAt+$0001),A
  EX DE,HL
  LD B,$30
DrawOverviewRow:
  LD DE,(OverviewAt+$0001)
  PUSH DE
  LD A,(OverviewOrigin)
  LD (OverviewCellAt),A
  LD C,$30
DrawOverviewCell:
  LD A,(BuildingLeft)
  AND A
  JR NZ,DrawOverviewDraw
  LD A,(HL)
  CP $80
  CALL NC,StartBuilding
DrawOverviewDraw:
  LD (ViewCellPtr),HL
  EXX
  CALL OverviewCell
  LD C,$21
  CALL PutLayerAttr
  CALL LayerOf
  LD HL,RightNibble
  LD A,(HL)
  XOR $01
  LD (HL),A
  JR NZ,DrawOverviewNext
  LD HL,(OverviewAt+$0001)
  INC HL
  LD (OverviewAt+$0001),HL
DrawOverviewNext:
  LD HL,(BuildingTile)
  INC HL
  LD (BuildingTile),HL
  LD HL,OverviewCellAt
  INC (HL)
  EXX
  INC HL
  DEC C
  JR NZ,DrawOverviewCell
  POP DE
  EX DE,HL
  CALL NextPixelLine
  CALL NextPixelLine
  CALL NextPixelLine
  CALL NextPixelLine
  LD (OverviewAt+$0001),HL
  EX DE,HL
  LD DE,$0030
  ADD HL,DE
  XOR A
  LD (BuildingLeft),A
  LD A,(OverviewCellAt+$0001)
  INC A
  LD (OverviewCellAt+$0001),A
  PUSH HL
  PUSH BC
  CALL AnyKey
  POP BC
  POP HL
  RET NZ
  DJNZ DrawOverviewRow
  RET

; The attribute of each layer level 1-7 (paper colours)
LayerColours:
  DEFB $00,$49,$52,$5B,$64,$6D,$76,$7F

; The attribute LayerColours[A] (0: none) for the cell
;
; Used by the routine at LayerOf.
LayerColour:
  AND A
  RET Z
  LD C,A
  LD B,$00
  LD HL,LayerColours
  ADD HL,BC
  LD C,(HL)

; The attribute C at the overview cell's attribute address
;
; Used by the routine at DrawOverview.
PutLayerAttr:
  LD HL,(OverviewAt+$0001)
  LD A,H
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  LD (HL),C
  RET
; This entry point is used by the routine at LayerOf.
PatternMark:
  LD D,$0F                ; a 4 x 4 dot pattern over the cell (the power and
                          ; transport layers)
  LD B,$A0
  LD C,$50
  LD A,(RightNibble)
  AND A
  JR Z,PatternMarkAt
  LD D,$F0
  LD B,$0A
  LD C,$05
PatternMarkAt:
  LD HL,(OverviewAt+$0001)
  LD A,(HL)
  AND D
  OR B
  LD (HL),A
  INC H
  LD A,(HL)
  AND D
  OR C
  LD (HL),A
  INC H
  LD A,(HL)
  AND D
  OR B
  LD (HL),A
  INC H
  LD A,(HL)
  AND D
  OR C
  LD (HL),A
  RET

; The layer: 0 city, 1 pollution, 2 police, 3 fire, 4 traffic, 5 power, 6
; transport, 7 crime (6 in the image)
MapLayer:
  DEFB $06

; The overlay of the layer for the overview cell
;
; L1 32 928.
LayerOf:
  LD A,(MapLayer)
  CP $00
  RET Z
  LD A,$01
  LD (SwitchOff),A
  LD HL,(GridBase)
  PUSH HL
  LD HL,LayerEnd
  PUSH HL
  LD A,(MapLayer)
  CP $01
  JR Z,LayerPollution
  CP $02
  JP Z,LayerPolice
  CP $03
  JP Z,LayerFire
  CP $04
  JR Z,LayerTraffic
  CP $05
  JR Z,LayerPower
  CP $06
  JR Z,LayerTransport
  JR LayerCrime
LayerEnd:
  POP HL                  ; the return: GridBase back, the switch allowed
  LD (GridBase),HL
  XOR A
  LD (SwitchOff),A
  RET
LayerCrime:
  LD HL,(ViewCellPtr)     ; a zone: 15 - (32 - distance) / 2 - police, halved
  LD A,(HL)
  CALL CellFlagsOf
  BIT 4,A
  RET Z
  LD BC,(OverviewCellAt)
  CALL CentreDistance
  CP $20
  JR C,LayerCrimeNear
  LD A,$1F
LayerCrimeNear:
  LD B,A
  LD A,$20
  SUB B
  JR NC,LayerCrimePolice
  XOR A
LayerCrimePolice:
  SRL A
  SUB $0F
  NEG
  LD E,A
  LD BC,(OverviewCellAt)
  CALL PoliceAt
  LD D,A
  LD A,E
  SUB D
  JR NC,LayerCrimeColour
  XOR A
LayerCrimeColour:
  SRL A
  CALL LayerColour
  RET
LayerPower:
  LD BC,(OverviewCellAt)  ; a powered cell: the dot pattern
  CALL PowerBit
  LD A,(HL)
  AND E
  RET Z
  JP PatternMark
LayerTransport:
  LD HL,(ViewCellPtr)     ; a road or rail cell: the pattern
  LD A,(HL)
  CALL CellFlagsOf
  AND $06
  RET Z
  LD A,$05
  JP PatternMark
LayerTraffic:
  LD HL,Traffic
  JR LayerGrid48
LayerPollution:
  LD HL,Pollution
LayerGrid48:
  LD (GridBase),HL
  LD BC,(OverviewCellAt)
  CALL Grid48
  SRL A
  SRL A
  SRL A
  SRL A
  SRL A
  JP LayerColour
LayerFire:
  LD HL,FireCover
  JR LayerGrid24
LayerPolice:
  LD HL,PoliceCover
LayerGrid24:
  LD (GridBase),HL
  LD BC,(OverviewCellAt)
  CALL Grid24
  SRL A
  JP LayerColour
