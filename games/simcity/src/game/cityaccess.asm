; --------------------------------------------------------------------------------------------------------------------
; cityaccess.asm: The city's arrays and cell helpers
;
; Grid48 and Grid24 over the coverage, pollution and traffic arrays, CellFlagsOf, the building writers, the power
; bitmap, MapToRowCol, Div8, BuildingValue, the directions and the cell stack, NextMonth.
; --------------------------------------------------------------------------------------------------------------------

; The array Grid48 and Grid24 read
GridBase:
  DEFW Pollution

; A = GridBase[48 (B / 2) + C / 2]: a 48 x 48 array over 2 x 2 cells
;
; HL its address. L1 763 487.
Grid48:
  PUSH BC
  PUSH DE
  SRL B
  SRL C
  LD L,B
  LD H,$00
  LD B,H
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD D,H
  LD E,L
  ADD HL,HL
  ADD HL,DE
  ADD HL,BC
  LD BC,(GridBase)
  ADD HL,BC
  LD A,(HL)
  POP DE
  POP BC
  RET

; A = GridBase[24 (B / 4) + C / 4]: a 24 x 24 array over 4 x 4 cells
;
; L1 40 571.
Grid24:
  PUSH BC
  PUSH DE
  SRL B
  SRL B
  SRL C
  SRL C
  LD L,B
  LD H,$00
  LD B,H
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD D,H
  LD E,L
  ADD HL,HL
  ADD HL,DE
  ADD HL,BC
  LD BC,(GridBase)
  ADD HL,BC
  LD A,(HL)
  POP DE
  POP BC
  RET

; Grid48 of Pollution $ADD0
;
; Used by the routines at StampPollutionIX and ZonePollution.
PollutionAt:
  LD HL,Pollution
  LD (GridBase),HL
  JR Grid48

; Grid48 of Traffic $B6D0
;
; Used by the routines at RoadTraffic, ZoneTraffic and AddTripTraffic.
TrafficAt:
  LD HL,Traffic
  LD (GridBase),HL
  JR Grid48

; Grid24 of PoliceCover $AB90
;
; Used by the routines at StampPolice, CrimeOf and LayerOf.
PoliceAt:
  LD HL,PoliceCover
  LD (GridBase),HL
  JR Grid24

; Grid24 of FireCover $A950
;
; Used by the routines at StampFire and FireCell.
FireAt:
  LD HL,FireCover
  LD (GridBase),HL
  JR Grid24

; A = CellFlags[A] for a cell below $80, $99 for a building byte
;
; L1 11 343 551, the most run routine.
CellFlagsOf:
  PUSH BC
  PUSH DE
  PUSH HL
  BIT 7,A
  JR Z,CellFlagsLook
  LD A,$99
  JR CellFlagsEnd
CellFlagsLook:
  LD C,A
  LD B,$00
  LD HL,CellFlags
  ADD HL,BC
  LD A,(HL)
CellFlagsEnd:
  POP HL
  POP DE
  POP BC
  RET

; Write a 3 x 3 building of tile base DE + 9 A at the map address HL's cell:
; rows $B3, $83, $83
;
; The zones' growth writes its buildings here. L1 3235.
PutZoneBuilding:
  LD L,A
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,L
  LD L,A
  LD H,$00
  ADD HL,DE
  EX DE,HL
  CALL MapAddr
  LD A,$B3
  CALL WriteBuildingRow
  LD A,$83
  CALL WriteBuildingRow
  LD A,$83
  CALL WriteBuildingRow
  RET

; One row: A, then the three tile bytes $C0 | (n >> 3) and $C0 | (n AND 7)
; pairs; HL the next row
;
; L1 9705.
WriteBuildingRow:
  LD (HL),A
  INC HL
  LD B,D
  LD A,E
  SRL B
  RRA
  SRL B
  RRA
  SRL B
  RRA
  OR $C0
  LD (HL),A
  INC HL
  LD A,E
  AND $07
  OR $C0
  LD (HL),A
  LD BC,$005E
  ADD HL,BC
  EX DE,HL
  LD BC,$0003
  ADD HL,BC
  EX DE,HL
  RET

; Two bytes no code reads
PutBuildingSpare:
  DEFB $D1,$C9

; HL = the byte of the power bitmap PowerMap ($BFD0, 12 bytes a row) for cell
; (B, C); E its bit, D its mask
;
; L1 1 380 041.
PowerBit:
  PUSH BC
  LD A,C
  AND $07
  ADD A,$11
  LD L,A
  LD H,$5B
  LD A,(HL)
  LD L,B
  LD H,$00
  LD B,H
  ADD HL,HL
  ADD HL,HL
  LD D,H
  LD E,L
  ADD HL,HL
  ADD HL,DE
  SRL C
  SRL C
  SRL C
  ADD HL,BC
  LD BC,PowerMap
  ADD HL,BC
  LD E,A
  CPL
  LD D,A
  POP BC
  RET

; The same for a map address in HL
;
; Used by the routines at BuildingPower and ZonePower.
PowerBitAt:
  LD DE,$3BB0
  ADD HL,DE
  LD A,L
  AND $07
  ADD A,$11
  LD E,A
  LD D,$5B
  LD A,(DE)
  LD E,A
  CPL
  LD D,A
  LD A,L
  SRL H
  RRA
  SRL H
  RRA
  SRL H
  RRA
  LD L,A
  LD BC,PowerMap
  ADD HL,BC
  RET

; B = row, C = column of the map address HL
;
; L1 669 924.
MapToRowCol:
  LD DE,$3BB0
  ADD HL,DE
  XOR A
  LD DE,$FFA0
MapToRowColLoop:
  INC A
  ADD HL,DE
  JR C,MapToRowColLoop
  SBC HL,DE
  DEC A
  LD B,A
  LD C,L
  RET

; HL = HL / A, remainder in A
;
; L1 16 469.
Div8:
  LD B,$10
  LD C,A
  XOR A
Div8Loop:
  ADD HL,HL
  RLA
  JR C,Div8Sub
  CP C
  JR C,Div8Next
Div8Sub:
  SUB C
  INC HL
Div8Next:
  DJNZ Div8Loop
  RET

; Leftover: an older copy of a divide (LD C,L ... RET), no code runs it
DivLeftover:
  DEFB $4C,$7D,$21,$00,$00,$06,$10,$29,$17,$CB,$11,$30,$01,$19,$10,$F7,$C9

; A = the largest of the 2 x 2 bytes of a 48-wide array at HL
;
; L1 27 088.
Max2x2:
  LD D,$00
  LD B,$02
Max2x2Row:
  LD C,$02
  PUSH HL
Max2x2Cell:
  LD A,(HL)
  CP D
  JR C,Max2x2Next
  LD D,A
Max2x2Next:
  INC HL
  DEC C
  JR NZ,Max2x2Cell
  POP HL
  LD A,D
  LD DE,$0030
  ADD HL,DE
  LD D,A
  DJNZ Max2x2Row
  RET

; By building routine (BuildingKinds' second byte): the class TripArrived
; matches against TripTargets (9 R, 10 C, 11 I; police 0, fire 1, church 2,
; hospital 3)
BuildingValues:
  INCBIN "res/tables/BuildingValues.bin",$0000,12

; A = the value of the cell at HL for its neighbours: a building's kind class,
; 9 for a developed zone cell; carry for nothing
;
; A type missing from the table returns with RET Z and BC still pushed:
; unreachable, every placed type is in the table. L1 191 120.
BuildingValue:
  PUSH BC
  LD A,(HL)
  BIT 7,A
  JR Z,BuildingValueCell
  PUSH HL
  POP IX
  CALL FindBuildingStart
  LD DE,$FFA0
BuildingValueTop:
  BIT 5,(IX+$00)
  JR NZ,BuildingValueKind
  ADD IX,DE
  JR BuildingValueTop
BuildingValueKind:
  LD A,(IX+$01)
  AND $3F
  LD E,A
  LD HL,BuildingKinds
  LD BC,$0004
BuildingValueLook:
  LD A,(HL)
  CP $FF
  RET Z
  CP E
  JR Z,BuildingValueFound
  ADD HL,BC
  JR BuildingValueLook
BuildingValueFound:
  INC HL
  LD C,(HL)
  LD B,$00
  LD HL,BuildingValues
  ADD HL,BC
  LD A,(HL)
  POP BC
  OR A
  RET
BuildingValueCell:
  CALL CellFlagsOf
  BIT 4,A
  JR Z,BuildingValueNone
  BIT 6,A
  JR Z,BuildingValueNone
  LD A,$09
  POP BC
  OR A
  RET
BuildingValueNone:
  POP BC
  SCF
  RET

; The four steps (column, row): up, right, down, left
Directions:
  DEFB $00,$FF,$01,$00,$00,$01,$FF,$00

; HL = the map address of the neighbour A of BC (BC moved)
;
; Used by the routines at MoveTrain, TripStep and TripArrived.
NeighbourAddr:
  PUSH BC
  CALL StepDir
  CALL MapAddr
  POP BC
  RET

; BC = BC + Directions[A]
;
; L1 392 992.
StepDir:
  ADD A,A
  LD E,A
  LD D,$00
  LD HL,Directions
  ADD HL,DE
  LD A,C
  ADD A,(HL)
  LD C,A
  INC HL
  LD A,B
  ADD A,(HL)
  LD B,A
  RET

; The cells on CellStack (at $801D)
CellStackCount:
  DEFB $00

; Put BC on CellStack
;
; Used by the routines at MakeTrip and TripStep.
PushCell:
  LD HL,CellStackCount
  INC (HL)
  CALL CellStackTop
  LD (HL),C
  INC HL
  LD (HL),B
  RET

; Take BC from CellStack
;
; Used by the routine at AddTripTraffic.
PopCell:
  CALL CellStackTop
  LD C,(HL)
  INC HL
  LD B,(HL)
  LD HL,CellStackCount
  DEC (HL)
  RET

; HL = the free slot of CellStack
;
; Used by the routines at PushCell and PopCell.
CellStackTop:
  LD A,(CellStackCount)
  ADD A,A
  LD E,A
  LD D,$00
  LD HL,CellStack
  ADD HL,DE
  RET

; Month + 1; after December the year + 1
;
; L1 934 in c1's simulation. Month $8F9B, Year $8F9C.
NextMonth:
  LD HL,Month
  LD A,(HL)
  INC A
  CP $0C
  JR Z,NextYear
  LD (HL),A
  RET
NextYear:
  XOR A
  LD (HL),A
  LD HL,(Year)
  INC HL
  LD (Year),HL
  RET
