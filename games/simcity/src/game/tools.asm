; --------------------------------------------------------------------------------------------------------------------
; tools.asm: The tools: palette, prices, sites, networks, bridges, the bulldozer and the buildings
;
; The 14 tools: the palette and its keys, the prices and Spend, CheckSite and the two refusals, roads, rails and power
; lines with their crossings and bridges, the bulldozer and the rubble, the zones and buildings with their map
; patterns.
; --------------------------------------------------------------------------------------------------------------------

; A click on row 2, column 0: scroll the view with the keys until SPACE (not
; run in any recording)
;
; ScrollMode: O, P, Q, A scroll by a cell a frame, the view redrawn each time,
; until SPACE. No recording clicked there (L1 - from $6CCA; the scroll of the
; recordings goes through the pointer at the view's edge, ScrollByPointer).
ScrollClick:
  LD BC,(ClickCell)
  LD A,C
  AND A
  RET NZ
  LD A,B
  CP $02
  RET NZ
  CALL WaitSpaceUp
ScrollModeLoop:
  LD A,(KeyRowP)
  AND $01
  CALL Z,ScrollRight
  LD A,(KeyRowP)
  AND $02
  CALL Z,ScrollLeft
  LD A,(KeyRowQ)
  AND $01
  CALL Z,ScrollUp
  LD A,(KeyRowA)
  AND $01
  CALL Z,ScrollDown
  HALT
  CALL DrawView
  CALL DrawMovers
  LD HL,PassCount
  LD A,(HL)
  ADD A,$04
  LD (HL),A
  LD A,(KeyRowSpace)
  AND $01
  JR NZ,ScrollModeLoop
  JP WaitSpaceUp

; ViewCol - 1 down to 0
;
; Used by the routines at ScrollClick and ShiftScroll.
ScrollLeft:
  LD HL,ViewCol
  LD A,(HL)
  DEC A
  CP $FF
  RET Z
  LD (HL),A
  RET

; ViewCol + 1 up to 63
;
; Used by the routines at ScrollClick and ShiftScroll.
ScrollRight:
  LD HL,ViewCol
  LD A,(HL)
  INC A
  CP $40
  RET Z
  LD (HL),A
  RET

; ViewRow - 1 down to 0
;
; Used by the routines at ScrollClick and ShiftScroll.
ScrollUp:
  LD HL,ViewRow
  LD A,(HL)
  DEC A
  CP $FF
  RET Z
  LD (HL),A
  RET

; ViewRow + 1 up to 79
;
; Used by the routines at ScrollClick and ShiftScroll.
ScrollDown:
  LD HL,ViewRow
  LD A,(HL)
  INC A
  CP $50
  RET Z
  LD (HL),A
  RET

; SYMBOL SHIFT with a digit picks a tool: 1-9 tools 0-8, 0 tool 9
;
; L1 158 072; 30 with SYMBOL SHIFT (the tools recording's shortcuts).
ToolKeys:
  LD A,(KeyRows)
  AND $01
  RET Z
  LD A,(KeyRowSpace)
  AND $02
  RET NZ
  CALL KeyToChar
  RET C
  CP $30
  JR NZ,ToolKeysDigit
  LD B,$09
  JR SelectTool
ToolKeysDigit:
  CP $31
  RET C
  CP $3A
  RET NC
  SUB $31
  LD B,A
  JR SelectTool

; The tool: 0 bulldozer, 1 road, 2 power line, 3 rail, 4 park, 5-7 R C I, 8
; police, 9 fire, 10 stadium, 11 power station, 12 seaport, 13 airport
CurrentTool:
  DEFB $01

; A click on the palette (rows 1-2, columns 2-29) picks tool (column - 2) / 2
;
; Used by the routine at Click.
ToolClick:
  LD BC,(ClickCell)
  LD A,B
  AND A
  RET Z
  CP $03
  RET NC
  LD A,C
  CP $02
  RET C
  CP $1E
  RET NC
  CALL WaitSpaceUp
  LD A,(ClickCell)
  SUB $02
  SRL A
  LD B,A
; This entry point is used by the routine at ToolKeys.
SelectTool:
  PUSH BC                 ; refused when Funds would go below 0; redraw the
                          ; palette and the name
  CALL ToolPrice
  LD B,$00
  LD HL,(Funds)
  LD A,(Funds+$0002)
  LD C,A
  CALL Sub24
  LD A,C
  POP BC
  AND A
  RET M
  LD A,(CurrentTool)
  CP B
  RET Z
  LD A,B
  LD (CurrentTool),A
  CALL DrawToolIcons
  CALL PrintToolName

; Highlight the current tool's icon and set the map box to its size (ToolSizes)
;
; L1 649.
ShowTool:
  LD A,(CurrentTool)
  SLA A
  ADD A,$02
  LD C,A
  LD B,$01
  LD DE,$0202
  LD (BoxSize),DE
  CALL InvertBox
  CALL GreyUnaffordable
  CALL ToolSize
  LD (BoxSize),DE
  RET

; The 14 tools' box sizes, width and height: 1 x 1 for tools 0-4, 3 x 3 for
; 5-9, 4 x 4 for 10-12, 6 x 6 the airport
ToolSizes:
  INCBIN "res/tables/ToolSizes.bin",$0000,28

; DE = ToolSizes[CurrentTool]
;
; Used by the routines at ShowTool, CheckSite and PutBuilding.
ToolSize:
  LD A,(CurrentTool)
  ADD A,A
  LD E,A
  LD D,$00
  LD HL,ToolSizes
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  RET

; Grey the palette icon of every tool whose price is more than Funds
;
; For the 14 tools: Funds - ToolPrice < 0 (Sub24) greys the icon (GreyIcon).
; Input: none. Side effect: the palette's pixels. L1 649.
GreyUnaffordable:
  LD BC,$0E00
GreyUnaffordableLoop:
  PUSH BC
  LD A,C
  CALL ToolPrice
  LD B,$00
  LD HL,(Funds)
  LD A,(Funds+$0002)
  LD C,A
  CALL Sub24
  LD A,C
  AND A
  JP P,GreyUnaffordableNext
  POP BC
  PUSH BC
  CALL GreyIcon
GreyUnaffordableNext:
  POP BC
  INC C
  DJNZ GreyUnaffordableLoop
  RET

; AND a checker ($AA / $55) into the 2 x 2 icon of tool C (row 1, column 2 + 2
; C)
;
; L1 196.
GreyIcon:
  SLA C
  INC C
  INC C
  LD B,$01
  CALL ScreenAddr
  LD D,$AA
  LD B,$10
GreyIconLine:
  LD C,$02
  PUSH HL
GreyIconByte:
  LD A,(HL)
  AND D
  LD (HL),A
  INC L
  DEC C
  JR NZ,GreyIconByte
  POP HL
  LD A,D
  CPL
  LD D,A
  CALL NextPixelLine
  DJNZ GreyIconLine
  RET

; The 14 tools' prices: 1, 10, 5, 20, 10, 100, 100, 100, 500, 500, 3000, 4000,
; 5000, 10 000
ToolPrices:
  INCBIN "res/tables/ToolPrices.bin",$0000,28

; DE = ToolPrices[A]
;
; L1 9176 (GreyUnaffordable and SelectTool).
ToolPrice:
  ADD A,A
  LD E,A
  LD D,$00
  LD HL,ToolPrices
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  RET

; Funds = Funds - DE, unless that goes below 0: then carry set and Funds kept
;
; Every tool pays through here. Input: DE the price. Output: carry set when
; refused (nothing paid). L1 693.
Spend:
  PUSH HL
  PUSH BC
  LD B,$00
  LD HL,(Funds)
  LD A,(Funds+$0002)
  LD C,A
  CALL Sub24
  AND A
  JP P,SpendStore
  POP BC
  POP HL
  SCF
  RET
SpendStore:
  LD (Funds),HL
  LD A,C
  LD (Funds+$0002),A
  POP BC
  POP HL
  OR A
  RET

; The map cell of the last tool click: column, row
ClickMapCell:
  DEFW $0000
MapCoordsGiven:
  DEFB $00                ; 1 while FixNetworkAt runs: ClickToMapBC takes BC as
                          ; a map cell already

; BC = the clicked map cell (ClickToMap), kept in ClickMapCell; HL = its map
; address
;
; L1 1713.
ClickMapAddr:
  CALL ClickToMap
  LD (ClickMapCell),BC
  JP MapAddr

; BC = the map cell under ClickCell: column + ViewCol, row - 8 + ViewRow
;
; Used by the routines at ClickMapAddr, BridgeLine, Bridge and RubbleStep.
ClickToMap:
  LD BC,(ClickCell)

; BC (a view cell, screen row) to the map cell, unless MapCoordsGiven
;
; L1 3978.
ClickToMapBC:
  LD A,(MapCoordsGiven)
  AND A
  RET NZ
  LD HL,ViewCol
  LD A,C
  ADD A,(HL)
  LD C,A
  INC HL
  LD A,B
  SUB $08
  ADD A,(HL)
  LD B,A
  RET

; FixNetwork round map cell BC (MapCoordsGiven set while it runs)
;
; Used by the bridge (L1 - : no recording built a bridge).
FixNetworkAt:
  LD A,$01
  LD (MapCoordsGiven),A
  CALL FixNetwork
  XOR A
  LD (MapCoordsGiven),A
  RET

; FixNetwork round the clicked cell
;
; Used by the routines at CrossNetwork, PlaceNetwork, Bridge and Bulldoze.
FixNetworkClick:
  LD BC,(ClickCell)

; Re-shape the network cells of kind NetworkKind at BC and its four neighbours
;
; A road, rail or power line cell takes the shape (kind + NetworkShapes[mask])
; of the neighbours of its own kind (the 4-bit mask of NeighbourMask). Input:
; BC, NetworkKind. Side effect: the map. L1 324.
FixNetwork:
  PUSH HL
  PUSH DE
  PUSH BC
  CALL NetworkBit
  LD (NetworkFlag),A
  CALL FixNetworkCell
  DEC B
  CALL FixNetworkCell
  INC B
  DEC C
  CALL FixNetworkCell
  INC C
  INC C
  CALL FixNetworkCell
  INC B
  DEC C
  CALL FixNetworkCell
  POP BC
  POP DE
  POP HL
  RET

; A = the CellFlags bit that marks the kind as crossable: road (7) 4, rail
; ($14) 2, power ($21) 8
;
; Used by the routine at FixNetwork.
NetworkBit:
  LD A,(NetworkKind)
  CP $07
  JR Z,NetworkBitRoad
  CP $14
  JR Z,NetworkBitRail
  LD A,$08
  RET
NetworkBitRoad:
  LD A,$04
  RET
NetworkBitRail:
  LD A,$02
  RET

; The network being laid: 7 road, $14 rail, $21 power line ($30 in the image)
NetworkKind:
  DEFB $30

; the shape offset by the 4-bit neighbour mask (up, left, right, down)
NetworkShapes:
  INCBIN "res/tables/NetworkShapes.bin",$0000,16

; The cell at BC: when it is of NetworkKind, make it kind + its shape (not when
; CellFlags bit 0 keeps it)
;
; L1 1620.
FixNetworkCell:
  PUSH BC
  CALL ClickToMapBC
  CALL IsNetwork
  JR NC,FixNetworkCellEnd
  CALL NeighbourMask
  LD E,D
  LD D,$00
  LD HL,NetworkShapes
  ADD HL,DE
  LD A,(NetworkKind)
  ADD A,(HL)
  POP BC
  PUSH BC
  PUSH AF
  CALL ClickToMapBC
  CALL MapAddr
  POP AF
  LD B,A
  LD A,(HL)
  CALL CellFlagsOf
  BIT 0,A
  JR NZ,FixNetworkCellEnd
  LD (HL),B
FixNetworkCellEnd:
  POP BC
  RET

; NetworkBit's result for this FixNetwork
NetworkFlag:
  DEFB $00
BridgeMode:
  DEFB $00                ; 1 while Bridge looks for the network to continue:
                          ; only the kind's own cells count

; Carry set when the cell at BC is of NetworkKind (kind to kind + 10) or (not
; BridgeMode) crossable by its flags
;
; L1 4200.
IsNetwork:
  PUSH BC
  CALL MapAddrChecked
  POP BC
  RET NC
  LD A,(NetworkKind)
  LD E,A
  LD A,(HL)
  CP E
  JR C,IsNetworkFlags
  LD A,E
  ADD A,$0B
  LD E,A
  LD A,(HL)
  CP E
  JR NC,IsNetworkFlags
IsNetworkYes:
  SCF
  RET
IsNetworkFlags:
  LD A,(BridgeMode)
  AND A
  JR NZ,IsNetworkNo
  LD A,(HL)
  CALL CellFlagsOf
  LD HL,NetworkFlag
  AND (HL)
  JR NZ,IsNetworkYes
IsNetworkNo:
  OR A
  RET

; D = 4 bits: IsNetwork of the cells up, left, right, down of BC
;
; L1 645.
NeighbourMask:
  PUSH BC
  LD D,$00
  DEC B
  CALL IsNetwork
  RL D
  INC B
  DEC C
  CALL IsNetwork
  RL D
  INC C
  INC C
  CALL IsNetwork
  RL D
  INC B
  DEC C
  CALL IsNetwork
  RL D
  POP BC
  RET

; The last water cell the bridge line covered
BridgeEnd:
  DEFW $0000
BridgeCell:
  DEFB $00                ; the cell the bridge line writes (0 for the dry run)

; From the click, step (D, E) over water writing BridgeCell, each cell paid at
; BridgePrice
;
; Stops with carry clear on a cell of BulldozeKeep (a coast or bridge end);
; carry set on anything else not water (the bridge refused). The first pass
; (BridgeCell 0) only tests; the second writes. L1 - (no recording built a
; bridge): known only from the code.
BridgeLine:
  CALL ClickToMap
BridgeLineStep:
  PUSH DE
  PUSH BC
  CALL MapAddrChecked
  POP BC
  POP DE
  RET NC
  LD A,(HL)
  EXX
  LD HL,BulldozeKeep
  LD BC,$0008
  CPIR
  EXX
  JR Z,BridgeLineEnd
  CP $00
  JR Z,BridgeLineWater
  SCF
  RET
BridgeLineWater:
  LD A,(BridgeCell)
  LD (HL),A
  AND A
  JR Z,BridgeLineNext
  EXX
  LD DE,(BridgePrice)
  CALL Spend
  EXX
  RET C
BridgeLineNext:
  LD (BridgeEnd),BC
  LD A,B
  ADD A,D
  LD B,A
  LD A,C
  ADD A,E
  LD C,A
  JR BridgeLineStep
BridgeLineEnd:
  OR A
  RET

; The flags of the cells 0-$59: bit 0 not reshaped, 1 rail, 2 road, 3 conducts
; power, 4 zone, 6 developed, 7 flammable
;
; Read by CellFlagsOf ($7599; L1 11 343 551). Buildings ($80 and up) give $99
; there. The bit meanings follow from the readers: bit 0 FixNetworkCell, bit 1
; the train ($77DC) and the rail count ($8898), bit 2 the road count, bits 1-2
; the traffic route ($856A), bit 3 the power flood ($819A), bits 4 and 6
; BuildingValue and the pollution ($7DEA), bit 7 the fire ($89BB, $79DE).
CellFlags:
  INCBIN "res/tables/CellFlags.bin",$0000,90

; The 14 tools' click routines (MapClick calls ToolHandlers[CurrentTool])
ToolHandlers:
  DEFW Bulldoze,RoadTool,PowerLineTool,RailTool,ParkTool,ResidentialTool,CommercialTool
  DEFW IndustrialTool,PoliceTool,FireTool,StadiumTool,PowerPlantTool,SeaportTool,AirportTool

; A click on the view with the box shown: the crossing, the site check, the
; tool's routine
;
; Only for ClickCell rows 8 and up with BoxShown. A road, rail or power line
; over another network goes to CrossNetwork; else CheckSite refuses (Refuse) or
; the tool's handler from ToolHandlers runs (a CALL whose operand ToolCall is
; written). Then it waits for SPACE up, unless a direction key is held: the
; drag that lays a road cell by cell. L1 607.
MapClick:
  LD A,(ClickCell+$0001)
  CP $08
  RET C
  LD A,(BoxShown)
  AND A
  RET Z
  CALL CrossNetwork
  RET C
  CALL CheckSite
  JP NC,MapClickTool
  CALL Refuse
  JP MapClickWait
MapClickTool:
  LD A,(CurrentTool)
  ADD A,A
  LD C,A
  LD B,$00
  LD HL,ToolHandlers
  ADD HL,BC
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD (ToolCall+$0001),HL
ToolCall:
  CALL $0000              ; CALL n: the handler (operand $7040)
MapClickWait:
  LD A,(KeyRowA)
  AND $01
  RET Z
  LD A,(KeyRowQ)
  AND $01
  RET Z
  LD A,(KeyRowP)
  AND $01
  RET Z
  LD A,(KeyRowP)
  AND $02
  RET Z
  LD A,(KeyRowSpace)
  AND $01
  JR Z,MapClickWait
  RET

; Three pairs of 6 bytes: the cells a network may cross, then the crossing cell
; for each
;
; $7062 power over road or rail; $706E road over power or rail; $707A rail over
; road or power. Read by CrossNetwork (CPIR, the result 6 bytes on).
Crossings:
  INCBIN "res/tables/Crossings.bin",$0000,36

; A road, rail or power line clicked on another network: pay, write the
; crossing cell, reshape; carry set when done
;
; Road 10, rail 20, power 5. L1 470; the crossings themselves L1 47 ($70E3,
; power).
CrossNetwork:
  LD A,(CurrentTool)
  AND A
  JP Z,CrossNetworkNone
  CP $01
  JP Z,CrossRoad
  CP $02
  JP Z,CrossPower
  CP $03
  JP Z,CrossRail
CrossNetworkNone:
  OR A
  RET
CrossRoad:
  CALL ClickMapAddr
  LD A,(HL)
  LD HL,Crossings+$000C
  LD BC,$0006
  CPIR
  JP NZ,CrossNetworkNone
  LD DE,$000A
  LD A,$07
CrossNetworkPay:
  LD (NetworkKind),A
  CALL Spend
  RET C
  LD BC,$0005
  ADD HL,BC
  LD A,(HL)
  PUSH AF
  CALL ClickMapAddr
  POP AF
  LD (HL),A
  CALL FixNetworkClick
  CALL DrawView
  SCF
  RET
CrossRail:
  CALL ClickMapAddr
  LD A,(HL)
  LD HL,Crossings+$0018
  LD BC,$0006
  CPIR
  JP NZ,CrossNetworkNone
  LD DE,$0014
  LD A,$14
  JP CrossNetworkPay
CrossPower:
  CALL ClickMapAddr
  LD A,(HL)
  LD HL,Crossings
  LD BC,$0006
  CPIR
  JP NZ,CrossNetworkNone
  LD DE,$0005
  LD A,$21
  JP CrossNetworkPay

; The cells a building site takes at no cost: 2 land, 0 water
FreeCells:
  DEFB $02,$00
SiteCells:
  DEFB $02,$03            ; the cells a site may hold (cleared at $1 each): 2,
  DEFB $01,$05            ; 3, 1, 5, 4, 6, then $7102
  DEFB $04,$06
SiteWater:
  DEFB $02                ; the seventh: 0 (water) for the networks, 2 for the
                          ; other tools; written by CheckSite

; Carry set when the tool's box at the click may not be built; clears trees at
; $1 a cell
;
; On water, or with AutoBulldoze ($A32B) on: every cell of the box must be in
; SiteCells (water only for road, rail and power); each cell not in FreeCells
; costs 1 and becomes land 2. With AutoBulldoze off on land: StrictSite, every
; cell must be land 2. The bulldozer passes always. L1 464.
CheckSite:
  CALL ClickMapAddr
  LD A,(HL)
  CP $00
  JP Z,CheckSiteLoose
  LD A,(AutoBulldoze)
  AND A
  JP Z,StrictSite
CheckSiteLoose:
  LD A,$02
  LD (SiteWater),A
  LD A,(CurrentTool)
  AND A
  JP Z,CheckSiteOk
  CP $04
  JP NC,CheckSiteBox
  LD A,$00
  LD (SiteWater),A
CheckSiteBox:
  CALL ToolSize
  PUSH DE
  CALL ClickMapAddr
  POP BC
  LD A,C
  LD (CheckSiteRow+$0002),A
CheckSiteRow:
  PUSH HL
  LD C,$00
CheckSiteCell:
  LD A,(HL)
  PUSH HL
  PUSH BC
  LD HL,SiteCells
  LD BC,$0007
  CPIR
  POP BC
  POP HL
  JP Z,CheckSiteClear
  POP HL
  SCF
  RET
CheckSiteClear:
  PUSH HL
  PUSH BC
  LD HL,FreeCells
  LD BC,$0002
  CPIR
  POP BC
  POP HL
  JP Z,CheckSiteNext
  LD DE,$0001
  CALL Spend
  JP C,CheckSiteNext
  LD (HL),$02
CheckSiteNext:
  INC HL
  DEC C
  JP NZ,CheckSiteCell
  POP HL
  LD DE,$0060
  ADD HL,DE
  DJNZ CheckSiteRow
CheckSiteOk:
  OR A
  RET
StrictSite:
  CALL ToolSize           ; every cell of the box must be land (2), else carry
  PUSH DE
  CALL ClickMapAddr
  POP BC
  LD A,C
  LD (StrictSiteRow+$0002),A
StrictSiteRow:
  PUSH HL
  LD C,$00
StrictSiteCell:
  LD A,(HL)
  CP $02
  JR Z,StrictSiteNext
  POP HL
  SCF
  RET
StrictSiteNext:
  INC HL
  DEC C
  JR NZ,StrictSiteCell
  POP HL
  LD DE,$0060
  ADD HL,DE
  DJNZ StrictSiteRow
  OR A
  RET

; Copy the building pattern at IX (ToolSize width x height) into the map at the
; click
;
; L1 145.
PutBuilding:
  CALL ToolSize
  PUSH DE
  CALL ClickMapAddr
  POP BC
; This entry point is used by the routines at ResRevert, ComRevert and
; IndRevert.
PutBuildingSize:
  LD A,C
  LD (PutBuildingRow+$0002),A
PutBuildingRow:
  PUSH HL
  LD C,$00
PutBuildingCell:
  LD A,(IX+$00)
  LD (HL),A
  INC HL
  INC IX
  DEC C
  JR NZ,PutBuildingCell
  POP HL
  LD DE,$0060
  ADD HL,DE
  DJNZ PutBuildingRow
  RET

; PlaceNetwork's price per cell on land
NetPrice:
  DEFW $000A
BridgePrice:
  DEFW $0032              ; and per cell of bridge

; Lay one cell of road, rail or power: HL the price, DE the bridge price, A the
; kind
;
; On water the Bridge; on land (2) pay, write the kind, FixNetwork, redraw; on
; anything else Refuse. L1 312.
PlaceNetwork:
  LD (NetPrice),HL
  LD (BridgePrice),DE
  LD (NetworkKind),A
  CALL ClickMapAddr
  LD A,(HL)
  CP $00
  JR Z,Bridge
  CP $02
  JR NZ,Refuse
  LD DE,(NetPrice)
  CALL Spend
  RET C
  LD A,(NetworkKind)
  LD (HL),A
  CALL FixNetworkClick
  JP DrawView

; The refusal: ToneBeep, but only when no direction key (A, Q, P, O) is held
;
; The two refusals that beep are CheckSite's (the site) and PlaceNetwork's (a
; network on a building or a zone); while the pointer is dragged with a key
; held the beep is left out. L1 3; ToneBeep L1 3 in the tools recording.
Refuse:
  LD A,(KeyRowA)
  AND $01
  RET Z
  LD A,(KeyRowQ)
  AND $01
  RET Z
  LD A,(KeyRowP)
  AND $01
  RET Z
  LD A,(KeyRowP)
  AND $02
  RET Z
  JP ToneBeep

; By the neighbour mask: the bridge direction (1-4; 0 none)
BridgeDirs:
  INCBIN "res/tables/BridgeDirs.bin",$0000,16

; per direction 0-4: the row step, the column step, the bridge cell offset
BridgeSteps:
  INCBIN "res/tables/BridgeSteps.bin",$0000,15

; A network clicked on water: find the direction from the network next to it,
; test the line, then build it
;
; The cost is BridgePrice a cell (road 50, rail 100, power 25). Two BridgeLine
; passes: a dry run, then with kind + offset. L1 - : known only from the code.
Bridge:
  CALL ClickToMap
  LD A,$01
  LD (BridgeMode),A
  CALL NeighbourMask
  XOR A
  LD (BridgeMode),A
  LD A,D
  AND A
  RET Z
  LD E,A
  LD D,$00
  LD HL,BridgeDirs
  ADD HL,DE
  LD A,(HL)
  AND A
  RET Z
  LD B,A
  ADD A,A
  ADD A,B
  LD E,A
  LD HL,BridgeSteps
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  LD (BridgeOffset+$0001),A
  LD A,$00
  LD (BridgeCell),A
  CALL BridgeLine
  RET NC
  LD A,(NetworkKind)
BridgeOffset:
  ADD A,$0B               ; ADD A,n: the bridge cell offset from the kind
                          ; (operand $7257)
  LD (BridgeCell),A
  CALL BridgeLine
  CALL FixNetworkClick
  LD BC,(BridgeEnd)
  CALL FixNetworkAt
  JP DrawView

; The bridge and coast-end cells: the bulldozer turns them back to water
BulldozeKeep:
  DEFB $2C,$2D,$1F,$20,$12,$13,$57,$58
BulldozeNothing:
  DEFB $00,$02,$59        ; 0, 2, $59: nothing to clear (water, land, rubble
                          ; ash)

; Tool 0: clear the clicked cell
;
; A building goes to BulldozeBuilding, a zone centre ($51-$56) to BulldozeZone,
; a bridge to water ($72CA), cells $3C-$50 through the flags to rubble or land,
; the rest to land 2 at $1, then the networks round it are reshaped. L1 2.
Bulldoze:
  CALL ClickMapAddr
  LD A,(HL)
  CP $80
  JP NC,BulldozeBuilding
  CP $51
  JR C,BulldozeCell
  CP $57
  JP C,BulldozeZone
BulldozeCell:
  LD HL,BulldozeKeep
  LD BC,$0008
  CPIR
  JR Z,BulldozeBridge
  LD HL,BulldozeNothing
  LD BC,$0003
  CPIR
  RET Z
  CP $3C
  JR C,BulldozeToLand
  CP $51
  JR C,BulldozeMarked
BulldozeToLand:
  LD DE,$0001
  CALL Spend
  RET C
  CALL ClickMapAddr
  LD (HL),$02
BulldozeReshape:
  LD A,$07
  LD (NetworkKind),A
  CALL FixNetworkClick
  LD A,$21
  LD (NetworkKind),A
  CALL FixNetworkClick
  LD A,$14
  LD (NetworkKind),A
  CALL FixNetworkClick
  JP DrawView
BulldozeBridge:
  LD DE,$0001
  CALL Spend
  RET C
  CALL ClickMapAddr
  LD (HL),$00
  JR BulldozeReshape
BulldozeMarked:
  CALL ClickMapAddr
  LD A,(HL)
  CALL CellFlagsOf
  BIT 4,A
  RET Z
  LD DE,$0001
  CALL Spend
  RET C
  LD (HL),$3A
  JR BulldozeReshape

; With ZONE DEMOLISH WAIT ($A32E, on in the image): Z only when SPACE is held
; through 40 000 loops; NZ at once when it is up
;
; Clearing a building or a zone needs SPACE held about a second; with the
; option off it goes at once. L1 - (no recording bulldozed a building or zone):
; known only from the code.
ConfirmHold:
  LD A,(DemolishWait)
  AND A
  RET Z
  LD DE,MapAreaAddrs+$000D
ConfirmHoldLoop:
  LD A,(KeyRowSpace)
  AND $01
  RET NZ
  DEC DE
  LD A,D
  OR E
  JR NZ,ConfirmHoldLoop
  RET

; By the building's size: the price of clearing it, size squared (0, 1, 4, 9,
; 16, 25, 36)
BulldozeCosts:
  INCBIN "res/tables/BulldozeCosts.bin",$0000,7

; Clear a whole building: find its top row, pay size squared, fill it with
; rubble $46, animate
;
; L1 - (no recording bulldozed a building): known only from the code.
BulldozeBuilding:
  CALL ConfirmHold
  RET NZ
  PUSH HL
  POP IX
  CALL FindBuildingStart
  LD DE,$FFA0
BulldozeFindTop:
  BIT 5,(IX+$00)
  JR NZ,BulldozeTop
  ADD IX,DE
  JR BulldozeFindTop
BulldozeTop:
  LD A,(IX+$00)
  AND $07
  LD C,A
  LD B,$00
  LD HL,BulldozeCosts
  ADD HL,DE
  LD E,(HL)
  LD D,$00
  CALL Spend
  RET C
  LD A,(IX+$00)
  AND $07
; This entry point is used by the routine at BulldozeZone.
BulldozeFill:
  LD (BulldozeFillRow+$0003),A
  LD B,A
BulldozeFillRow:
  PUSH IX
  LD C,$00
BulldozeFillCell:
  LD (IX+$00),$46
  INC IX
  DEC C
  JR NZ,BulldozeFillCell
  POP IX
  LD DE,$0060
  ADD IX,DE
  DJNZ BulldozeFillRow
  CALL DrawView
  CALL RubbleStep
  CALL DrawView
  CALL RubbleStep
  CALL DrawView
  CALL RubbleStep
  CALL DrawView
  RET

; a zone: 9, its 3 x 3 from the cell up and left
;
; Used by the routine at Bulldoze.
BulldozeZone:
  CALL ConfirmHold
  RET NZ
  LD DE,$0009
  CALL Spend
  RET C
  LD BC,$FF9F
  ADD HL,BC
  PUSH HL
  POP IX
  LD A,$03
  JR BulldozeFill

; The rubble's three steps: $46 -> $47 -> $48 -> 2 (land)
RubbleSteps:
  DEFB $46,$47,$48,$47,$48,$02

; Advance every rubble cell of the 12 rows round the click one step
; (RubbleSteps)
;
; Used by the routine at BulldozeBuilding.
RubbleStep:
  CALL ClickToMap
  LD A,B
  SUB $06
  LD B,A
  LD C,$00
  CALL MapAddr
  PUSH HL
  POP IX
  LD DE,$0480
RubbleStepCell:
  LD A,(IX+$00)
  LD HL,RubbleSteps
  LD BC,$0003
  CPIR
  JR NZ,RubbleStepNext
  LD BC,$0002
  ADD HL,BC
  LD A,(HL)
  LD (IX+$00),A
RubbleStepNext:
  INC IX
  DEC DE
  LD A,D
  OR E
  JR NZ,RubbleStepCell
  RET

; Tool 1: PlaceNetwork with 10, bridge 50, cell 7
;
; L1 at the click only (no entry count kept: reached through ToolHandlers).
RoadTool:
  LD HL,$000A
  LD DE,$0032
  LD A,$07
  JP PlaceNetwork

; Tool 3: 20, bridge 100, cell $14
RailTool:
  LD HL,$0014
  LD DE,$0064
  LD A,$14
  JP PlaceNetwork

; Tool 2: 5, bridge 25, cell $21
PowerLineTool:
  LD HL,$0005
  LD DE,$0019
  LD A,$21
  JP PlaceNetwork

; One byte no code reads
ToolSpare:
  DEFB $00

; Tool 4: 10, a park $38 (one in eight $39); refused (Refuse) when the map
; column is 2
;
; The CP $02 tests A, which ClickMapAddr leaves as the column (MapAddr's LD
; A,C), not the cell: a park on map column 2 always beeps, any other site takes
; the park (CheckSite has cleared it already). Known only from the code; L1 1.
ParkTool:
  CALL ClickMapAddr
  CP $02
  JP Z,Refuse
  LD DE,$000A
  CALL Spend
  RET C
  LD C,$38
  CALL Random
  AND $07
  JR NZ,ParkPut
  INC C
ParkPut:
  LD (HL),C
  JP DrawView

; The 3 x 3 zone cells: the frame $49-$50 round the centre $54 (residential,
; unpowered)
ResidentialZone:
  DEFB $49,$4A,$4B,$50,$54,$4C,$4F,$4E,$4D

; Tool 5: 100, the zone at the click
;
; L1 77.
ResidentialTool:
  LD DE,$0064
  CALL Spend
  RET C
  LD IX,ResidentialZone
  CALL PutBuilding
  JP DrawView

; ... centre $55
CommercialZone:
  DEFB $49,$4A,$4B,$50,$55,$4C,$4F,$4E,$4D

; Tool 6: 100
CommercialTool:
  LD DE,$0064
  CALL Spend
  RET C
  LD IX,CommercialZone
  CALL PutBuilding
  JP DrawView

; ... centre $56
IndustrialZone:
  DEFB $49,$4A,$4B,$50,$56,$4C,$4F,$4E,$4D

; Tool 7: 100
IndustrialTool:
  LD DE,$0064
  CALL Spend
  RET C
  LD IX,IndustrialZone
  CALL PutBuilding
  JP DrawView

; The police station, 3 x 3: building rows ($A3 top, $83) with tile numbers
; $C0+
PoliceBuilding:
  DEFB $A3,$C0,$C0,$83,$C0,$C3,$83,$C0,$C6

; Tool 8: 500
PoliceTool:
  LD DE,$01F4
  CALL Spend
  RET C
  LD IX,PoliceBuilding
  CALL PutBuilding
  JP DrawView

; The fire station, 3 x 3
FireBuilding:
  DEFB $A3,$C1,$C1,$83,$C1,$C4,$83,$C1,$C7

; Tool 9: 500
FireTool:
  LD DE,$01F4
  CALL Spend
  RET C
  LD IX,FireBuilding
  CALL PutBuilding
  JP DrawView

; The stadium, 4 x 4
StadiumBuilding:
  DEFB $A4,$C4,$C4,$C0,$84,$C5,$C0,$C0,$84,$C5,$C4,$C0,$84,$C6,$C0,$C0

; Tool 10: 3000
StadiumTool:
  LD DE,$0BB8
  CALL Spend
  RET C
  LD IX,StadiumBuilding
  CALL PutBuilding
  JP DrawView

; The coal power station, 4 x 4
CoalPlant:
  DEFB $B4,$C6,$C4,$C0,$84,$C7,$C0,$C0,$84,$C7,$C4,$C0,$84,$C8,$C0,$C0
NuclearPlant:
  DEFB $B4,$C8,$C4,$C0,$84,$C9,$C0,$C0,$84,$C9,$C4,$C0,$84,$CA,$C0,$C0 ; the
                                                                       ; nuclear
                                                                       ; one

; Tool 11: with 3000 or more, the menu $9F41 asks coal (3000) or nuclear (5000)
;
; L1 8.
PowerPlantTool:
  LD DE,$0BB8
  LD HL,(Funds)
  AND A
  SBC HL,DE
  RET C
  LD IX,PlantMenu
  CALL ShowMenu
  LD DE,$1388
  LD IX,NuclearPlant
  LD A,(PlantChoice)
  AND A
  RET Z
  CP $01
  JR Z,PowerPlantPay
  LD DE,$0BB8
  LD IX,CoalPlant
PowerPlantPay:
  CALL Spend
  RET C
  CALL PutBuilding
  JP DrawView

; The seaport, 4 x 4
SeaportBuilding:
  DEFB $A4,$CA,$C4,$C0,$84,$CB,$C0,$C0,$84,$CB,$C4,$C0,$84,$CC,$C0,$C0

; Tool 12: 5000
SeaportTool:
  LD DE,$1388
  CALL Spend
  RET C
  LD IX,SeaportBuilding
  CALL PutBuilding
  JP DrawView

; The airport, 6 x 6
AirportBuilding:
  DEFB $A6,$CC,$C4,$C0,$C0,$C0,$86,$CD,$C2,$C0,$C0,$C0,$86,$CE,$C0,$C0,$C0,$C0,$86,$CE,$C6,$C0,$C0,$C0,$86,$CF,$C4,$C0,$C0,$C0,$86,$D0,$C2,$C0,$C0,$C0

; Tool 13: 10 000
AirportTool:
  LD DE,$2710
  CALL Spend
  RET C
  LD IX,AirportBuilding
  CALL PutBuilding
  JP DrawView
