; --------------------------------------------------------------------------------------------------------------------
; simulation.asm: The simulation task: power, coverage, pollution, traffic, land value, crime, demand and the growth of every zone
;
; SimTask runs a pass over the city for ever: PowerFlood from the stations, ScanCity (zones and buildings, the plain
; cells: fire, flood, radiation, road and rail upkeep), the coverage of police and fire stations, pollution and
; traffic decay, the demands, the city value, the advice; a month every SpeedMask passes, the budget at the year's
; end.
; --------------------------------------------------------------------------------------------------------------------

; Fill the whole building at HL with the cell FillCellCode ($8998)
;
; L1 8.
FillBuilding:
  PUSH HL
  POP IX
  CALL FindBuildingStart
  LD DE,$FFA0
FillBuildingTop:
  BIT 5,(IX+$00)
  JR NZ,FillBuildingSize
  ADD IX,DE
  JR FillBuildingTop
FillBuildingSize:
  LD A,(IX+$00)
  AND $07
  LD (FillBuildingRow+$0003),A
  LD B,A
FillBuildingRow:
  PUSH IX
  LD C,$00
FillBuildingCell:
  LD A,(SpreadCode)
  LD (IX+$00),A
  INC IX
  DEC C
  JR NZ,FillBuildingCell
  POP IX
  LD DE,$0060
  ADD IX,DE
  DJNZ FillBuildingRow
  RET

; Fill the whole building at HL with the fire cell $3A (L1 -)
;
; Used by the routine at MoveTornado.
BurnBuilding:
  PUSH HL
  POP IX
  CALL FindBuildingStart
  LD DE,$FFA0
BurnBuildingTop:
  BIT 5,(IX+$00)
  JR NZ,BurnBuildingSize
  ADD IX,DE
  JR BurnBuildingTop
BurnBuildingSize:
  LD A,(IX+$00)
  AND $07
  LD (BurnBuildingRow+$0003),A
  LD B,A
BurnBuildingRow:
  PUSH IX
  LD C,$00
BurnBuildingCell:
  LD A,$3A
  LD (IX+$00),A
  INC IX
  DEC C
  JR NZ,BurnBuildingCell
  POP IX
  LD DE,$0060
  ADD IX,DE
  DJNZ BurnBuildingRow
  RET

; The 5 x 5 coverage kernel: the shift count of each cell (9: none)
CoverKernel:
  INCBIN "res/tables/CoverKernel.bin",$0000,25

; the fire station's strength, 0-15 ($0F in the image; set by ApplyFunding)
FireStrength:
  DEFB $0F

; Add the fire station's coverage (FireStrength through CoverKernel) into
; FireCover round the cell
;
; L1 228.
StampFire:
  LD BC,(CurCell)
  LD IX,CoverKernel
  CALL FireAt
  LD DE,$0032
  AND A
  SBC HL,DE
  LD D,$05
StampFireRow:
  PUSH HL
  LD E,$05
StampFireCell:
  CALL AddFire
  INC HL
  INC IX
  DEC E
  JR NZ,StampFireCell
  POP HL
  LD BC,$0018
  ADD HL,BC
  DEC D
  JR NZ,StampFireRow
  RET

; The police station's strength, $0F
PoliceStrength:
  DEFB $0F

; Add the police coverage into PoliceCover
;
; L1 233.
StampPolice:
  LD BC,(CurCell)
  LD IX,CoverKernel
  CALL PoliceAt
  LD DE,$0032
  AND A
  SBC HL,DE
  LD D,$05
StampPoliceRow:
  PUSH HL
  LD E,$05
StampPoliceCell:
  CALL AddPolice
  INC HL
  INC IX
  DEC E
  JR NZ,StampPoliceCell
  POP HL
  LD BC,$0018
  ADD HL,BC
  DEC D
  JR NZ,StampPoliceRow
  RET

; One cell: A = strength >> (kernel - 1), added and clamped to 15
;
; Used by the routine at StampPolice.
AddPolice:
  LD A,(PoliceStrength)
  JR AddCover

; AddFire
;
; Used by the routine at StampFire.
AddFire:
  LD A,(FireStrength)
; This entry point is used by the routine at AddPolice.
AddCover:
  LD B,(IX+$00)
  DEC B
  JR Z,AddCoverAdd
AddCoverShift:
  SRL A
  DJNZ AddCoverShift
AddCoverAdd:
  LD B,A
  LD A,(HL)
  ADD A,B
  CP $10
  JR C,AddCoverStore
  LD A,$0F
AddCoverStore:
  LD (HL),A
  RET

; The 6 x 6 kernel of the sources' pollution: the shift count of each cell (9:
; none)
PollutionKernel:
  INCBIN "res/tables/PollutionKernel.bin",$0000,36

; The 6 x 6 kernel of the traffic's pollution
TrafficKernel:
  INCBIN "res/tables/TrafficKernel.bin",$0000,36

; the source's strength
PollutionStrength:
  DEFB $FF

; Add PollutionStrength through the kernel at IX into Pollution round the
; current cell
;
; L1 8425.
StampPollution:
  LD BC,(CurCell)
  LD IX,PollutionKernel

; StampPollutionIX
;
; L1 30 375.
StampPollutionIX:
  CALL PollutionAt
  LD DE,$0062
  AND A
  SBC HL,DE
  LD D,$06
StampPollutionRow:
  PUSH HL
  LD E,$06
StampPollutionCell:
  CALL AddPollutionCell
  INC HL
  INC IX
  DEC E
  JR NZ,StampPollutionCell
  POP HL
  LD BC,$0030
  ADD HL,BC
  DEC D
  JR NZ,StampPollutionRow
  RET

; One cell: A = PollutionStrength >> (kernel - 1), added, clamped to $FF
;
; Used by the routine at StampPollutionIX.
AddPollutionCell:
  LD A,(PollutionStrength)
  LD B,(IX+$00)
  DEC B
  JR Z,AddPollutionAdd
AddPollutionShift:
  SRL A
  DJNZ AddPollutionShift
AddPollutionAdd:
  LD B,A
  LD A,(HL)
  ADD A,B
  JR NC,AddPollutionStore
  LD A,$FF
AddPollutionStore:
  LD (HL),A
  RET

; ZonePollutionMax = the largest Pollution of the 2 x 2 at the current cell;
; summed into PollutionSum ($847A, $847C)
;
; L1 24 645.
ZonePollution:
  LD BC,(CurCell)
  CALL PollutionAt
  CALL Max2x2
  LD (ZonePollutionMax),A
  LD E,A
  LD D,$00
  LD HL,(PollutionSum)
  ADD HL,DE
  LD (PollutionSum),HL
  LD HL,(PollutionCount)
  INC HL
  LD (PollutionCount),HL
  RET

; ZoneTrafficMax = the largest Traffic of the 2 x 2 at the current cell
;
; L1 2443.
ZoneTraffic:
  LD BC,(CurCell)
  CALL TrafficAt
  CALL Max2x2
  LD (ZoneTrafficMax),A
  RET

; The road or rail cell next to the zone a trip starts from ($FFFF: none)
RouteStart:
  DEFW $FFFF
RingSize:
  DEFW $0303              ; the zone's size: width, height (3 x 3, or 4 x 4 and
                          ; 6 x 6 for the big buildings)

; ScanRing for a building of size HL
;
; Used by the routines at StadiumStep, SeaportStep and AirportStep.
ScanRingSize:
  LD (RingSize),HL
  JR ScanRingStart

; Look at the ring of cells round the zone at BC (3 x 3) and its inside
;
; The ring (ScanRingCell): roads and rails count in RingTransport (one of them
; becomes RouteStart at random), parks ($38, $39) in RingParks, water in
; RingWater, trees in RingTrees, each adding to RingAmenity (12 for transport,
; 14 a park, 16 water or trees), capped at $7F. The inside (ScanInsideCell)
; adds the developed cells' density (cell - $3B) to Density $8869. L1 32 092 +
; 623.
ScanRing:
  LD HL,$0303
  LD (RingSize),HL
; This entry point is used by the routine at ScanRingSize.
ScanRingStart:
  XOR A
  LD (RingTransport),A
  LD (RingParks),A
  LD (RingWater),A
  LD (RingTrees),A
  LD (RingAmenity),A
  LD HL,$FFFF
  LD (RouteStart),HL
  PUSH BC
  DEC B
  LD A,(RingSize)
  LD E,A
ScanRingTop:
  CALL ScanRingCell
  INC C
  DEC E
  JR NZ,ScanRingTop
  POP BC
  DEC C
  LD A,(RingSize+$0001)
  LD D,A
ScanRingSides:
  PUSH BC
  CALL ScanRingCell
  INC C
  LD A,(RingSize)
  LD E,A
ScanRingInside:
  CALL ScanInsideCell
  INC C
  DEC E
  JR NZ,ScanRingInside
  CALL ScanRingCell
  POP BC
  INC B
  DEC D
  JR NZ,ScanRingSides
  INC C
  LD A,(RingSize)
  LD E,A
ScanRingBottom:
  CALL ScanRingCell
  INC C
  DEC E
  JR NZ,ScanRingBottom
  RET

; One ring cell: count it by kind into the Ring counters
;
; L1 395 063.
ScanRingCell:
  PUSH BC
  CALL MapAddrChecked
  POP BC
  RET NC
  LD A,(HL)
  BIT 7,A
  RET NZ
  CP $38
  JR Z,RingIsPark
  CP $39
  JR Z,RingIsPark
  CP $06
  JR Z,RingIsTrees
  CP $00
  JR Z,RingIsWater
  LD A,(HL)
  CALL CellFlagsOf
  AND $06
  RET Z
  LD HL,RingTransport
  INC (HL)
  CALL PickRouteStart
  LD L,$0C
RingAddAmenity:
  LD A,(RingAmenity)
  ADD A,L
  CP $80
  JR C,RingAmenityStore
  LD A,$7F
RingAmenityStore:
  LD (RingAmenity),A
  RET
RingIsWater:
  LD HL,RingWater
  INC (HL)
  LD L,$10
  JR RingAddAmenity
RingIsPark:
  LD HL,RingParks
  INC (HL)
  LD L,$0E
  JR RingAddAmenity
RingIsTrees:
  LD HL,RingTrees
  INC (HL)
  LD L,$10
  JR RingAddAmenity

; The first transport cell, then each next one with 1 in 2, becomes RouteStart
;
; Used by the routine at ScanRingCell.
PickRouteStart:
  LD A,(RouteStart)
  CP $FF
  JR Z,PickRouteStartSet
  CALL Random
  AND $01
  RET Z
PickRouteStartSet:
  LD (RouteStart),BC
  RET

; A developed cell (CellFlags bit 6) inside the zone adds cell - $3B to Density
;
; Used by the routine at ScanRing.
ScanInsideCell:
  PUSH BC
  CALL MapAddrChecked
  POP BC
  RET NC
  LD A,(HL)
  BIT 7,A
  RET NZ
  CALL CellFlagsOf
  BIT 6,A
  RET Z
  LD A,(HL)
  SUB $3B
  LD HL,Density
  ADD A,(HL)
  LD (HL),A
  RET

; A = |CityCentre column - B| + |CityCentre row - C|
;
; L1 27 944.
CentreDistance:
  LD HL,(CityCentre)
  LD A,H
  SUB B
  JP P,CentreDistanceRow
  NEG
CentreDistanceRow:
  LD E,A
  LD A,L
  SUB C
  JP P,CentreDistanceSum
  NEG
CentreDistanceSum:
  ADD A,E
  RET

; ScanRing's counts: parks, water, trees, transport, the amenity
RingParks:
  DEFB $00
RingWater:
  DEFB $00
RingTrees:
  DEFB $00
RingTransport:
  DEFB $00
RingAmenity:
  DEFB $00
LandValue:
  DEFB $00                ; the zone's land value, LandValueOf's result

; LandValue = 127 - CentreDistance + RingAmenity, for a powered zone with
; transport and a trip (or traffic 50+); else 0
;
; Summed into LandValueSum ($8472, count $8474). L1 33 251.
LandValueOf:
  LD A,(ZonePowered)
  AND A
  JR Z,LandValueNone
  LD A,(RingTransport)
  AND A
  JR Z,LandValueNone
  LD A,(TripMade)
  AND A
  JR NZ,LandValueScore
  CALL ZoneTraffic
  CP $32
  JR C,LandValueNone
LandValueScore:
  CALL CentreCloseness
  LD HL,RingAmenity
  ADD A,(HL)
  LD HL,LandValue
  LD (HL),A
  LD E,A
  LD D,$00
  LD HL,(LandValueSum)
  ADD HL,DE
  RET C
  LD (LandValueSum),HL
LandValueTally:
  LD HL,(LandValueCount)
  INC HL
  LD (LandValueCount),HL
  RET
LandValueNone:
  XOR A
  LD (LandValue),A
  JR LandValueTally

; A = 127 - CentreDistance, 0 when farther
;
; Used by the routine at LandValueOf.
CentreCloseness:
  LD BC,(CurCell)
  CALL CentreDistance
  LD B,A
  LD A,$7F
  SUB B
  RET NC
  XOR A
  RET

; One byte no code reads
CrimeSpare:
  DEFB $00
Crime:
  DEFB $00                ; the zone's crime, CrimeOf's result

; Crime = (255 - LandValue) / 16 - PoliceCover here, not below 0; summed into
; CrimeSum ($846E, $8470)
;
; L1 33 251.
CrimeOf:
  LD BC,(CurCell)
  CALL PoliceAt
  LD C,A
  LD HL,LandValue
  LD A,$FF
  SUB (HL)
  SRL A
  SRL A
  SRL A
  SRL A
  SUB C
  JR NC,CrimeStore
  XOR A
CrimeStore:
  LD (Crime),A
  LD E,A
  LD D,$00
  LD HL,(CrimeSum)
  ADD HL,DE
  RET C
  LD (CrimeSum),HL
  LD HL,(CrimeCount)
  INC HL
  LD (CrimeCount),HL
  RET

; TaxPenaltyOf's result
TaxPenalty:
  DEFB $00

; TaxPenalty = 8 x TaxRate ($91E4), plus TaxRate on medium, 2 TaxRate on hard
; ($A518)
;
; L1 33 251.
TaxPenaltyOf:
  LD A,(TaxRate)
  LD B,A
  ADD A,A
  ADD A,A
  ADD A,A
  LD (TaxPenalty),A
  LD A,(Level)
  AND A
  RET Z
  LD A,(TaxPenalty)
  ADD A,B
  LD (TaxPenalty),A
  LD A,(Level)
  CP $02
  RET Z
  LD A,(TaxPenalty)
  ADD A,B
  LD (TaxPenalty),A
  RET

; The 2 x 2 maximum of Pollution at the zone
ZonePollutionMax:
  DEFB $00
ZoneTrafficMax:
  DEFB $00                ; ... of Traffic
ZoneScore:
  DEFB $00                ; ZoneScoreOf's result, 0-255
ZoneDemand:
  DEFB $00                ; the zone kind's demand (16 bits, signed), added to
  DEFB $00                ; the score

; ZoneScore = LandValue - Pollution - Crime - TaxPenalty + ZoneDemand, clamped
; 0-255; 0 with pollution 28+ or no land value
;
; The heart of the growth: a zone grows when its score is high. L1 33 251.
ZoneScoreOf:
  CALL LandValueOf
  CALL CrimeOf
  CALL TaxPenaltyOf
  LD A,(ZonePollutionMax)
  CP $1C
  JR NC,ZoneScoreZero
  LD A,(LandValue)
  AND A
  JR Z,ZoneScoreZero
  LD HL,ZonePollutionMax
  SUB (HL)
  JR NC,ZoneScoreCrime
  XOR A
ZoneScoreCrime:
  LD HL,Crime
  SUB (HL)
  JR NC,ZoneScoreTax
  XOR A
ZoneScoreTax:
  LD HL,TaxPenalty
  SUB (HL)
  JR NC,ZoneScoreDemand
  XOR A
ZoneScoreDemand:
  LD L,A
  LD H,$00
  LD DE,(ZoneDemand)
  ADD HL,DE
  CALL Clamp8
  LD A,L
  LD (ZoneScore),A
  RET
ZoneScoreZero:
  XOR A
  LD (ZoneScore),A
  RET

; L = HL clamped to 0-255 (negative 0, above 255 255)
;
; Used by the routine at ZoneScoreOf.
Clamp8:
  LD A,H
  AND A
  RET Z
  JP P,Clamp8High
  LD L,$00
  RET
Clamp8High:
  LD L,$FF
  RET

; ResidentialScore's results: the level 0-7 and the building tile base
ResLevel:
  DEFB $00
ResTile:
  DEFB $00

; ResLevel = (ZoneScore - 128) / 16 (0 below 128... $0F), ResTile = ZoneScore /
; 2, or 16 ResLevel + $50 from 128 up
;
; L1 17 800.
ResidentialScore:
  CALL ZoneScoreOf
  LD A,(ZoneScore)
  SRL A
  LD (ResTile),A
  LD A,(ZoneScore)
  SUB $80
  JR NC,ResidentialScoreLevel
  LD A,$FF
ResidentialScoreLevel:
  SRL A
  SRL A
  SRL A
  SRL A
  LD B,A
  LD (ResLevel),A
  LD A,(ZoneScore)
  CP $80
  RET C
  LD A,B
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,$50
  LD (ResTile),A
  RET

; CommercialScore's results: ZoneScore / 25 and 4 times it
ComLevel:
  DEFB $00
ComTile:
  DEFB $00

; CommercialScore
;
; L1 6845.
CommercialScore:
  CALL ZoneScoreOf
  LD A,(ZoneScore)
  LD L,A
  LD H,$00
  LD A,$19
  CALL Div8
  LD A,L
  LD (ComLevel),A
  ADD A,A
  ADD A,A
  LD (ComTile),A
  RET

; IndustrialScore's results: ZoneScore / 31 and 8 times it
IndLevel:
  DEFB $00
IndTile:
  DEFB $00

; IndustrialScore
;
; L1 7446.
IndustrialScore:
  CALL ZoneScoreOf
  LD A,(ZoneScore)
  LD L,A
  LD H,$00
  LD A,$1F
  CALL Div8
  LD A,L
  LD (IndLevel),A
  ADD A,A
  ADD A,A
  ADD A,A
  LD (IndTile),A
  RET

; The map addresses of the power stations found (FindPlants), 0 ended
PowerPlants:
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000

; Scan the map for 4 x 4 building tops ($B4) of type 6 (coal) or 8 (nuclear)
; into PowerPlants
;
; L1 1101 (once a simulation pass).
FindPlants:
  LD IX,PowerPlants
  LD HL,CityMap
  LD BC,$2400
FindPlantsLoop:
  LD A,$B4
  CPIR
  LD A,(HL)
  AND $3F
  CP $06
  JR Z,FindPlantsFound
  CP $08
  JR Z,FindPlantsFound
  LD A,B
  OR C
  JR NZ,FindPlantsLoop
  LD (IX+$00),$00
  LD (IX+$01),$00
  RET
FindPlantsFound:
  DEC HL
  LD (IX+$00),L
  INC IX
  LD (IX+$00),H
  INC IX
  INC HL
  JR FindPlantsLoop

; Counts the power stations that ran out of capacity this pass (BROWNOUTS
; DETECTED)
Brownout:
  DEFB $00

; Clear PowerMap, then flood the power from each station over conducting cells:
; nuclear 1350 cells, coal 450
;
; L1 1101. Every powered cell costs one of the station's budget; a station that
; runs out stops its flood (Brownout + 1).
PowerFlood:
  CALL FindPlants
  LD HL,PowerMap
  LD DE,PowerMap+$0001
  LD BC,$047F
  LD (HL),$00
  LDIR
  XOR A
  LD (Brownout),A
  LD IX,PowerPlants
PowerFloodPlant:
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD A,H
  OR L
  RET Z
  INC HL
  LD A,(HL)
  AND $3F
  DEC HL
  LD DE,$0546
  CP $08
  JR Z,PowerFloodBudget
  LD DE,$01C2
PowerFloodBudget:
  LD (FloodBudget),DE
  CALL MapToRowCol
  LD (FloodStart),BC
  PUSH IX
  CALL FloodFill
  POP IX
  INC IX
  INC IX
  JR PowerFloodPlant

; The flood's span flags: the row above and below already queued
FloodAbove:
  DEFB $00
FloodBelow:
  DEFB $00
FloodStart:
  DEFB $00                ; the station's cell (column, row)
  DEFB $00
FloodBudget:
  DEFB $00                ; the cells it may still power
  DEFB $08
FloodSP:
  DEFB $00                ; SP saved, to leave the flood at once
  DEFB $00
CellStack:
  DEFB $00                ; 128 cell pairs: the flood's spans; also PushCell's
  DEFB $00                ; stack
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00

; A scan-line flood fill from FloodStart over IsConductive cells, each made
; powered (PowerCell)
;
; L1 1162.
FloodFill:
  CALL IsConductive
  RET NZ
  LD IX,CellStack
  LD (FloodSP),SP
  LD BC,$FFFF
  CALL FloodPush
  LD BC,(FloodStart)
  CALL FloodPush
FloodFillPop:
  CALL FloodPop
  LD A,B
  CP $FF
  RET Z
FloodFillLeft:
  CALL IsConductive
  JR NZ,FloodFillSpan
  DEC C
  JR FloodFillLeft
FloodFillSpan:
  INC C
  CALL IsConductive
  JR NZ,FloodFillPop
  XOR A
  LD (FloodAbove),A
  LD (FloodBelow),A
FloodFillRun:
  CALL PowerCell
  DEC B
  LD HL,FloodAbove
  CALL FloodMark
  INC B
  INC B
  LD HL,FloodBelow
  CALL FloodMark
  DEC B
  INC C
  CALL IsConductive
  JR Z,FloodFillRun
  JR FloodFillPop

; Queue the cell above or below once per run of conducting cells (flag at HL)
;
; Used by the routine at FloodFill.
FloodMark:
  CALL IsConductive
  JR NZ,FloodMarkClear
  LD A,(HL)
  AND A
  RET NZ
  LD (HL),$01

; Push BC on the span stack, unless it is full ($811D)
;
; Used by the routine at FloodFill.
FloodPush:
  PUSH IX
  POP HL
  LD DE,FloodFill
  AND A
  SBC HL,DE
  RET NC
  LD (IX+$00),C
  INC IX
  LD (IX+$00),B
  INC IX
  RET
; This entry point is used by the routine at FloodMark.
FloodMarkClear:
  LD (HL),$00
  RET

; BC from the span stack
;
; Used by the routine at FloodFill.
FloodPop:
  DEC IX
  LD B,(IX+$00)
  DEC IX
  LD C,(IX+$00)
  RET

; Z set when the cell at BC is on the map, not powered yet and a building or
; CellFlags bit 3
;
; L1 1 057 667.
IsConductive:
  PUSH BC
  PUSH HL
  PUSH BC
  CALL MapAddrChecked
  POP BC
  JR NC,IsConductiveNo
  PUSH HL
  CALL PowerBit
  LD A,(HL)
  AND E
  POP HL
  JR NZ,IsConductiveNo
  LD A,(HL)
  CP $80
  JR NC,IsConductiveYes
  CALL CellFlagsOf
  BIT 3,A
  JR Z,IsConductiveNo
IsConductiveYes:
  XOR A
  POP HL
  POP BC
  RET
IsConductiveNo:
  LD A,$01
  AND A
  POP HL
  POP BC
  RET

; Set the cell's bit in PowerMap and count FloodBudget down; at 0 leave the
; flood (SP back) with Brownout + 1
;
; Used by the routine at FloodFill.
PowerCell:
  PUSH BC
  CALL PowerBit
  LD A,(HL)
  OR E
  LD (HL),A
  POP BC
  LD HL,(FloodBudget)
  DEC HL
  LD (FloodBudget),HL
  LD A,H
  OR L
  RET NZ
  LD SP,(FloodSP)
  LD HL,Brownout
  INC (HL)
  RET

; The city's assessed value (24 bits) and the last pass's ($81E0)
CityValue:
  DEFB $00,$00,$00
CityValueLast:
  DEFB $00,$00,$00

; CityValue = rails x 5 + roads x 10 + police x 1000 + fire x 1000 + hospitals
; x 400 + stadiums x 3000 + seaports x 5000 + airports x 10 000 + coal x 3000 +
; nuclear x 6000
;
; L1 1089.
AssessCity:
  LD HL,(CityValue)
  LD A,(CityValue+$0002)
  LD C,A
  LD (CityValueLast),HL
  LD A,C
  LD (CityValueLast+$0002),A
  LD HL,(RailCount)
  LD DE,$0005
  CALL Mul16
  LD (CityValue),HL
  LD A,C
  LD (CityValue+$0002),A
  LD HL,(RoadCount)
  LD DE,$000A
  CALL AddValue
  LD HL,(PoliceCount)
  LD DE,$03E8
  CALL AddValue
  LD HL,(FireCount)
  LD DE,$03E8
  CALL AddValue
  LD HL,(HospitalCount)
  LD DE,$0190
  CALL AddValue
  LD HL,(StadiumCount)
  LD DE,$0BB8
  CALL AddValue
  LD HL,(SeaportCount)
  LD DE,$1388
  CALL AddValue
  LD HL,(AirportCount)
  LD DE,$2710
  CALL AddValue
  LD HL,(CoalCount)
  LD DE,$0BB8
  CALL AddValue
  LD HL,(NuclearCount)
  LD DE,$1770

; CityValue = CityValue + HL x DE
;
; Used by the routine at AssessCity.
AddValue:
  CALL Mul16
  LD DE,(CityValue)
  LD A,(CityValue+$0002)
  LD B,A
  CALL Add24
  LD (CityValue),HL
  LD A,C
  LD (CityValue+$0002),A
  RET

; 4 (R - C - I): read by the evaluation
PopBalance:
  DEFW $0000

; PopBalanceOf
;
; Used by the routine at SimTask.
PopBalanceOf:
  LD DE,(ComPop)
  LD HL,(IndPop)
  ADD HL,DE
  EX DE,HL
  LD HL,(ResPop)
  AND A
  SBC HL,DE
  ADD HL,HL
  ADD HL,HL
  LD (PopBalance),HL
  RET

; The three demands (signed), read as ZoneDemand: R, C, I
ResDemand:
  DEFW $0000
ComDemand:
  DEFW $0000
IndDemand:
  DEFW $0000

; R = 8 (C + I - R) + 4 stadiums - 26; C = 8 ((R + I) / 2 - C) + 4 airports -
; 30; I = 8 ((R + C) / 2 - I) + 4 seaports - 30
;
; R, C, I are the populations ResPop $8446, ComPop $8448, IndPop $844A. L1
; 1089.
DemandOf:
  LD DE,(ComPop)
  LD HL,(IndPop)
  ADD HL,DE
  LD DE,(ResPop)
  AND A
  SBC HL,DE
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  EX DE,HL
  LD HL,(StadiumCount)
  ADD HL,HL
  ADD HL,HL
  EX DE,HL
  ADD HL,DE
  LD DE,$FFE6
  ADD HL,DE
  LD (ResDemand),HL
  LD DE,(ResPop)
  LD HL,(IndPop)
  ADD HL,DE
  SRL H
  RR L
  LD DE,(ComPop)
  AND A
  SBC HL,DE
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  EX DE,HL
  LD HL,(AirportCount)
  ADD HL,HL
  ADD HL,HL
  EX DE,HL
  ADD HL,DE
  LD DE,$FFE2
  ADD HL,DE
  LD (ComDemand),HL
  LD DE,(ComPop)
  LD HL,(ResPop)
  ADD HL,DE
  SRL H
  RR L
  LD DE,(IndPop)
  AND A
  SBC HL,DE
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  EX DE,HL
  LD HL,(SeaportCount)
  ADD HL,HL
  ADD HL,HL
  EX DE,HL
  ADD HL,DE
  LD DE,$FFE2
  ADD HL,DE
  LD (IndDemand),HL
  RET

; Population ($8443, 24 bits) = Population + 16 DE
;
; Used by the routines at ResidentialStep and ResBuildingStep.
AddPopulation:
  PUSH HL
  PUSH BC
  EX DE,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  EX DE,HL
  LD B,$00
  LD HL,(Population)
  LD A,(Population+$0002)
  LD C,A
  CALL Add24
  LD (Population),HL
  LD A,C
  LD (Population+$0002),A
  POP BC
  POP HL
  RET

; Make the simulation task (entry SimTask, SP $F6EE), the date January 1902,
; Funds by the level: 20 000, 10 000, 5000
;
; L1 13.
StartSimulation:
  LD A,$01
  LD (SwitchOff),A
  LD HL,SimFrame
  LD (SimSP),HL
  LD HL,SimTask
  LD (SimEntry),HL
  LD HL,$076E
  LD (Year),HL
  XOR A
  LD (Month),A
  CALL InitSimulation
  LD C,$00
  LD H,$4E
  LD L,$20
  LD (Funds),HL
  LD A,C
  LD (Funds+$0002),A
  LD A,(Level)
  AND A
  RET Z
  LD C,$00
  LD H,$27
  LD L,$10
  LD (Funds),HL
  LD A,C
  LD (Funds+$0002),A
  LD A,(Level)
  CP $01
  RET Z
  LD C,$00
  LD H,$13
  LD L,$88
  LD (Funds),HL
  LD A,C
  LD (Funds+$0002),A
  RET

; Nonzero: the zones are scanned but do not grow (the pause)
SimPaused:
  DEFB $00
SimPass:
  DEFB $00                ; the simulation pass counter

; The simulation task: init, then for ever one pass over the city; a month
; every SpeedMask + 1 passes
;
; A pass: ClearCounters, SetSpeed, PowerFlood, ScanCity (the growth),
; CoverStations (every 4th), DecayPollution, DecayTraffic, DemandOf, Averages2,
; AssessCity, PopBalanceOf, ServiceNeeds, Advise ($99AD), Averages; when
; SimPass AND MonthMask is 0, MonthEnd ($8E94) and NextMonth. c1: L1 12
; entries, 1089 passes.
SimTask:
  CALL InitSimulation
SimTaskPass:
  CALL ClearCounters
  CALL SetSpeed
  CALL PowerFlood
  CALL ScanCity
  CALL CoverStations
  CALL DecayPollution
  CALL DecayTraffic
  CALL DemandOf
  CALL Averages2
  CALL AssessCity
  CALL PopBalanceOf
  CALL ServiceNeeds
  CALL Advise
  CALL Averages
  LD A,(SimPass)
  LD HL,MonthMask
  AND (HL)
  JR NZ,SimTaskNext
  CALL MonthEnd
  CALL NextMonth
SimTaskNext:
  LD HL,SimPass
  INC (HL)
  JR SimTaskPass

; Clear the arrays $A950-$C44F, the counters and the disasters; city centre 32,
; 32; strengths $0F
;
; L1 25.
InitSimulation:
  LD HL,$2020
  LD (CityCentre),HL
  LD HL,FireCover
  LD DE,FireCover+$0001
  LD BC,$1AFF
  LD (HL),$00
  LDIR
  LD A,$FF
  LD (RoadDecay),A
  LD (RailDecay),A
  LD A,$0F
  LD (PoliceStrength),A
  LD (FireStrength),A
  XOR A
  LD (AvgLandValue),A
  LD (AvgCrime),A
  LD (AvgTraffic),A
  LD (SimPass),A
  LD (BudgetDue),A
  LD (HospitalNeed),A
  LD (ChurchNeed),A
  LD (TrainOut),A
  LD (PlaneOut),A
  LD (PlaneTimer),A
  LD (MeltdownPending),A
  LD (TornadoOut),A
  LD (SimPaused),A
  LD HL,$0000
  LD (TransportCost),HL
  LD (PoliceCost),HL
  LD (FireCost),HL
  LD (TransportFunded),HL
  LD (PoliceFunded),HL
  LD (FireFunded),HL
  LD (PopBalance),HL
  LD (LastBuildings),HL
  LD (LastAirports),HL
  LD (LastNuclear),HL
  LD (LastFireCells),HL
  LD (ResDemand),HL
  LD (ComDemand),HL
  LD (IndDemand),HL
  LD C,$00
  LD H,$00
  LD L,$00
  LD (PopLastYear),HL
  LD A,C
  LD (PopLastYear+$0002),A
  LD (PopYearBefore),HL
  LD A,C
  LD (PopYearBefore+$0002),A
  LD (CityValue),HL
  LD A,C
  LD (CityValue+$0002),A
  LD (CityValueLast),HL
  LD A,C
  LD (CityValueLast+$0002),A
  LD (LastPop),HL
  LD A,C
  LD (LastPop+$0002),A
  RET

; The pass's counters, cleared by ClearCounters ($8443-$847F)
Population:
  DEFB $00,$00,$01
ResPop:
  DEFB $00,$00            ; (16 bits each from here) residential population
ComPop:
  DEFB $00,$00
IndPop:
  DEFB $00,$00
PoliceCount:
  DEFB $00,$00
FireCount:
  DEFB $00,$00
ChurchCount:
  DEFB $00,$00
HospitalCount:
  DEFB $00,$00
NuclearCount:
  DEFB $00,$00
CoalCount:
  DEFB $00,$00
StadiumCount:
  DEFB $00,$00
AirportCount:
  DEFB $00,$00
SeaportCount:
  DEFB $00,$00
UnpoweredZones:
  DEFB $00,$00
PoweredZones:
  DEFB $00,$00
BuildingCount:
  DEFB $00,$00
TransportUpkeep:
  DEFB $00,$00
Count8466:
  DEFB $00,$00
Count8468:
  DEFB $00,$00
RoadCount:
  DEFB $00,$00
RailCount:
  DEFB $00,$00
CrimeSum:
  DEFB $00,$00
CrimeCount:
  DEFB $00,$00
LandValueSum:
  DEFB $00,$00
LandValueCount:
  DEFB $00,$00
TrafficSum:
  DEFB $00,$00
TrafficCount:
  DEFB $00,$00
PollutionSum:
  DEFB $00,$00
PollutionCount:
  DEFB $00,$00
FireCells:
  DEFB $00,$00

; Zero $8443-$847F; the city's extent to empty (min $FF, max 0)
;
; Used by the routine at SimTask.
ClearCounters:
  LD HL,Population
  LD DE,Population+$0001
  LD BC,$003C
  LD (HL),$00
  LDIR
  XOR A
  LD (ExtentCols),A
  LD (ExtentRows),A
  CPL
  LD (ExtentCols+$0001),A
  LD (ExtentRows+$0001),A
  RET

; Copies of the last pass for the disasters: fires, airports, nuclear plants;
; the city centre
LastFireCells:
  DEFW $0000
LastAirports:
  DEFW $0000
LastNuclear:
  DEFW $0000
CityCentre:
  DEFW $2020              ; column, row

; CityCentre = the middle of the extent; the last-pass copies; AvgPollution =
; PollutionSum / count
;
; L1 1089.
Averages:
  LD A,(ExtentCols)
  LD HL,ExtentCols+$0001
  ADD A,(HL)
  SRL A
  LD (CityCentre),A
  LD A,(ExtentRows)
  LD HL,ExtentRows+$0001
  ADD A,(HL)
  SRL A
  LD (CityCentre+$0001),A
  LD HL,(FireCells)
  LD (LastFireCells),HL
  LD HL,(NuclearCount)
  LD (LastNuclear),HL
  LD HL,(AirportCount)
  LD (LastAirports),HL
  LD HL,(PollutionSum)
  LD DE,(PollutionCount)
  CALL Div16
  LD A,L
  LD (AvgPollution),A
  RET

; Pollution's average
AvgPollution:
  DEFB $00

; Every second pass: each Pollution byte - 64? ($4000: D 64, floor E 0);
; AvgPollution = average / 4
;
; L1 1089 (542 decays).
DecayPollution:
  LD A,(SimPass)
  AND $01
  RET Z
  LD HL,Pollution
  LD BC,$0900
  LD DE,Screen
DecayPollutionLoop:
  LD A,(HL)
  SUB D
  JR NC,DecayPollutionStore
  LD A,E
DecayPollutionStore:
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,DecayPollutionLoop
  LD HL,(PollutionSum)
  LD DE,(PollutionCount)
  CALL Div16
  LD A,L
  SRL A
  SRL A
  LD (AvgPollution),A
  RET

; Zero FireCover and PoliceCover ($A950-$ADCF)
;
; Used by the routine at CoverStations.
ClearCover:
  LD HL,FireCover
  LD DE,FireCover+$0001
  LD BC,$047F
  LD (HL),$00
  LDIR
  RET

; Traffic's average / 4
AvgTraffic:
  DEFB $00

; Sum the traffic, then each Traffic byte: below 24 to 0, 200 and up - 34, else
; - 24
;
; L1 1089.
DecayTraffic:
  LD HL,Traffic
  LD BC,$0900
DecayTrafficLoop:
  LD A,(HL)
  EXX
  AND A
  JR Z,DecayTrafficCell
  LD E,A
  LD D,$00
  LD HL,(TrafficSum)
  ADD HL,DE
  JR C,DecayTrafficCell
  LD (TrafficSum),HL
  LD HL,(TrafficCount)
  INC HL
  LD (TrafficCount),HL
DecayTrafficCell:
  EXX
  LD A,(HL)
  CP $18
  JR C,DecayTrafficZero
  CP $C8
  JR C,DecayTrafficSlow
  SUB $22
  LD (HL),A
  JR DecayTrafficNext
DecayTrafficSlow:
  SUB $18
  LD (HL),A
  JR DecayTrafficNext
DecayTrafficZero:
  LD (HL),$00
DecayTrafficNext:
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,DecayTrafficLoop
  LD HL,(TrafficSum)
  LD DE,(TrafficCount)
  CALL Div16
  LD A,L
  SRL A
  SRL A
  LD (AvgTraffic),A
  RET

; 1 when the zone's trip reached its destination
TripMade:
  DEFB $00
TripMask:
  DEFB $00                ; the CellFlags bits the trip may travel (road 4,
                          ; rail 2), from RouteStart's cell

; From RouteStart walk the roads or rails (TripWalk) to a zone of the wanted
; kind; on success the path gets traffic
;
; L1 9735.
MakeTrip:
  XOR A
  LD (TripMade),A
  LD A,(RingTransport)
  AND A
  RET Z
  LD BC,(RouteStart)
  PUSH BC
  CALL MapAddr
  POP BC
  LD A,(HL)
  CALL CellFlagsOf
  AND $06
  LD (TripMask),A
  XOR A
  LD (CellStackCount),A
  CALL PushCell
  CALL TripWalk
  RET C
  LD A,$01
  LD (TripMade),A
  CALL AddTripTraffic
  RET

; A road trip: each cell of the path + 20 Traffic (to $F0) and pollution
; (strength 5, TrafficKernel)
;
; L1 7281.
AddTripTraffic:
  LD A,(TripMask)
  BIT 2,A
  RET Z
AddTripTrafficLoop:
  LD A,(CellStackCount)
  AND A
  RET Z
  CALL PopCell
  CALL TrafficAt
  LD A,(HL)
  ADD A,$14
  JR C,AddTripTrafficCap
  CP $F0
  JR C,AddTripTrafficStore
AddTripTrafficCap:
  LD A,$F0
AddTripTrafficStore:
  LD (HL),A
  LD A,$05
  LD (PollutionStrength),A
  LD IX,TrafficKernel
  CALL StampPollutionIX
  JR AddTripTrafficLoop

; Leftover code no one calls (XOR A; LD ($8568),A; LD HL,($8462); INC HL ...)
TripLeftover:
  DEFB $AF,$32,$68,$85,$2A,$62,$84,$23,$7C,$B5,$28,$03,$22,$62,$84,$C9
TripBack:
  DEFB $00                ; the direction the walk came from
TripSteps:
  DEFB $00

; Up to 30 steps of TripStep, each checked for arrival (TripArrived); carry
; when lost
;
; L1 9735.
TripWalk:
  LD A,$05
  LD (TripBack),A
  XOR A
  LD (TripSteps),A
TripWalkLoop:
  CALL TripStep
  JR C,TripWalkBack
  CALL TripArrived
  RET NC
  JR TripWalkStep
TripWalkBack:
  LD A,(CellStackCount)
  AND A
  JR Z,TripWalkLost
  DEC A
  LD (CellStackCount),A
  JR TripWalkCount
TripWalkStep:
  LD HL,TripSteps
  LD A,(HL)
  ADD A,$01
  LD (HL),A
TripWalkCount:
  LD A,(TripSteps)
  SUB $1E
  JR C,TripWalkLoop
; This entry point is used by the routines at GrowCell and DeclineCell.
TripWalkLost:
  SCF
  RET

; TripStep's turn, direction and tries
TripTurn:
  DEFB $00
TripDir:
  DEFB $00
TripTries:
  DEFB $00

; One step: from a random direction try the four, not back, onto a cell with
; TripMask; every second step pushed
;
; L1 67 734.
TripStep:
  CALL Random
  AND $03
  LD (TripTurn),A
  LD A,$04
  LD (TripTries),A
TripStepTry:
  LD A,(TripTurn)
  AND $03
  LD (TripDir),A
  LD HL,TripBack
  CP (HL)
  JR Z,TripStepNext
  LD A,(TripDir)
  CALL NeighbourAddr
  LD A,(HL)
  BIT 7,A
  JR NZ,TripStepNext
  CALL CellFlagsOf
  LD HL,TripMask
  AND (HL)
  JR NZ,TripStepGo
TripStepNext:
  LD HL,TripTurn
  INC (HL)
  LD HL,TripTries
  DEC (HL)
  JR NZ,TripStepTry
  SCF
  RET
TripStepGo:
  LD A,(TripDir)
  CALL StepDir
  LD A,(TripDir)
  ADD A,$02
  AND $03
  LD (TripBack),A
  LD A,(TripSteps)
  AND $01
  CALL Z,PushCell
  OR A
  RET

; The two BuildingValue kinds a trip may end at
TripTargets:
  DEFB $00,$00

; Carry clear when a neighbour's BuildingValue is one of TripTargets
;
; Used by the routine at TripWalk.
TripArrived:
  LD E,$04
TripArrivedLoop:
  PUSH DE
  LD A,E
  DEC A
  CALL NeighbourAddr
  CALL BuildingValue
  JR C,TripArrivedNext
  LD HL,TripTargets
  CP (HL)
  JR Z,TripArrivedYes
  INC HL
  CP (HL)
  JR Z,TripArrivedYes
TripArrivedNext:
  POP DE
  DEC E
  JR NZ,TripArrivedLoop
  SCF
  RET
TripArrivedYes:
  POP DE
  OR A
  RET

; Every 4th pass: ClearCover, then each powered 3 x 3 top ($B3: police type 0,
; fire type 1) stamps its coverage
;
; L1 1090 (273 stamping).
CoverStations:
  LD A,(SimPass)
  AND $03
  RET NZ
  CALL ClearCover
  LD HL,CityMap
  LD B,$60
  LD D,$00
CoverStationsRow:
  LD C,$60
  LD E,$00
CoverStationsCell:
  LD A,(HL)
  AND $F0
  CP $B0
  JR NZ,CoverStationsNext
  LD (CurCell),DE
  INC HL
  LD A,(HL)
  AND $3F
  CP $00
  CALL Z,CoverPolice
  CP $01
  CALL Z,CoverFire
  DEC HL
CoverStationsNext:
  INC HL
  INC E
  DEC C
  JR NZ,CoverStationsCell
  INC D
  DJNZ CoverStationsRow
  RET

; CoverPolice
;
; Used by the routine at CoverStations.
CoverPolice:
  EXX
  EX AF,AF'
  CALL StampPolice
  EX AF,AF'
  EXX
  RET

; CoverFire
;
; Used by the routine at CoverStations.
CoverFire:
  EXX
  CALL StampFire
  EXX
  RET

; ScanCity's state of the current cell: powered, kind (1 building, 2 zone),
; building type, zone centre
ZonePowered:
  DEFB $00
CellKind:
  DEFB $00
BuildingType:
  DEFB $00
ZoneCentre:
  DEFB $00

; Every map cell: buildings' power (BuildingPower), zones' power (ZonePower),
; then their step (ZoneStep) and the plain cells (CellStep)
;
; L1 1101; 10 084 466 cells.
ScanCity:
  LD HL,CityMap
  LD B,$60
  LD D,$00
ScanCityRow:
  LD C,$60
  LD E,$00
ScanCityCell:
  XOR A
  LD (ZonePowered),A
  LD (CellKind),A
  LD (ZoneCentre),A
  LD (BuildingType),A
  LD A,(HL)
  AND $E0
  CP $A0
  CALL Z,BuildingPower
  LD A,(HL)
  CP $51
  JR C,ScanCityStep
  CP $57
  CALL C,ZonePower
ScanCityStep:
  LD A,(SimPaused)
  AND A
  JR NZ,ScanCityNext
  LD A,(CellKind)
  AND A
  CALL NZ,ZoneStep
  CALL CellStep
ScanCityNext:
  INC HL
  INC E
  DEC C
  JR NZ,ScanCityCell
  INC D
  DJNZ ScanCityRow
  RET

; A building's top-left byte: bit 4 = powered (PowerMap); BuildingType;
; stations count as powered
;
; Used by the routine at ScanCity.
BuildingPower:
  LD A,$01
  LD (CellKind),A
  PUSH HL
  PUSH HL
  EXX
  POP HL
  POP IX
  LD A,(IX+$01)
  AND $3F
  LD (BuildingType),A
  CP $06
  JR Z,BuildingPowerEnd
  CP $08
  JR Z,BuildingPowerEnd
  RES 4,(HL)
  CALL PowerBitAt
  LD A,(HL)
  AND E
  JR Z,BuildingPowerEnd
  SET 4,(IX+$00)
  LD A,$01
  LD (ZonePowered),A
BuildingPowerEnd:
  EXX
  RET

; ZonePower's new centre cell
ZoneCentreCell:
  DEFB $00

; A zone centre: $51-$53 when powered, $54-$56 (blinking) when not
;
; Used by the routine at ScanCity.
ZonePower:
  LD A,$02
  LD (CellKind),A
  PUSH HL
  PUSH HL
  EXX
  POP IX
  POP HL
  LD A,(HL)
  LD D,$54
  LD E,$51
  CP D
  JR Z,ZonePowerKind
  CP E
  JR Z,ZonePowerKind
  LD D,$55
  LD E,$52
  CP D
  JR Z,ZonePowerKind
  CP E
  JR Z,ZonePowerKind
  LD D,$56
  LD E,$53
ZonePowerKind:
  LD A,D
  LD (ZoneCentre),A
  LD (ZoneCentreCell),A
  PUSH DE
  CALL PowerBitAt
  LD A,(HL)
  AND E
  POP DE
  JR Z,ZonePowerStore
  LD A,E
  LD (ZoneCentreCell),A
  LD A,$01
  LD (ZonePowered),A
ZonePowerStore:
  EXX
  LD A,(ZoneCentreCell)
  CP (IX+$00)
  RET Z
  LD (IX+$00),A
  RET

; The cell ScanCity is at: column, row; then its map address
CurCell:
  DEFW $0000
CurAddr:
  DEFW $0000

; A zone or building: count it powered or not, widen the extent, then the
; zone's growth or the building's routine
;
; L1 36 698.
ZoneStep:
  LD (CurAddr),HL
  LD (CurCell),DE
  EXX
  LD HL,ZoneStep+$001F
  PUSH HL
  CALL CountPowered
  CALL WidenExtent
  LD A,(CellKind)
  CP $02
  JR Z,ZoneByKind
  CP $01
  JP Z,BuildingStep
  POP HL
  EXX
  RET

; PoweredZones or UnpoweredZones + 1
;
; Used by the routine at ZoneStep.
CountPowered:
  LD A,(ZonePowered)
  AND A
  JR Z,CountUnpowered
  LD HL,(PoweredZones)
  INC HL
  LD A,H
  OR L
  JR Z,CountPoweredEnd
  LD (PoweredZones),HL
CountPoweredEnd:
  RET
CountUnpowered:
  LD HL,(UnpoweredZones)
  INC HL
  LD A,H
  OR L
  JR Z,CountUnpoweredEnd
  LD (UnpoweredZones),HL
CountUnpoweredEnd:
  RET

; The city's extent: least and greatest column, then row
ExtentCols:
  DEFB $00,$FF
ExtentRows:
  DEFB $00,$FF

; ExtentCols and ExtentRows take in CurCell
;
; Used by the routine at ZoneStep.
WidenExtent:
  LD A,(CurCell)
  LD HL,ExtentCols
  CALL MinMax
  LD A,(CurCell+$0001)
  LD HL,ExtentRows

; (HL) = min, (HL+1) = max with A
;
; Used by the routine at WidenExtent.
MinMax:
  CP (HL)
  JR C,MinMaxHigh
  LD (HL),A
MinMaxHigh:
  INC HL
  CP (HL)
  RET NC
  LD (HL),A
  RET

; Density 0; the R, C or I zone's growth
;
; Used by the routine at ZoneStep.
ZoneByKind:
  XOR A
  LD (Density),A
  LD A,(ZoneCentre)
  CP $54
  JP Z,ResidentialStep
  CP $55
  JP Z,CommercialStep
  CP $56
  JP Z,IndustrialStep
  RET

; The routines of the building kinds (BuildingKinds' second byte)
BuildingRoutines:
  DEFW PoliceStep,FireStep,ChurchStep,HospitalStep,StadiumStep,CoalStep,NuclearStep,SeaportStep,AirportStep,ResBuildingStep,ComBuildingStep,IndBuildingStep

; Per building type: type, routine (BuildingRoutines), level, density; $FF $FF
; ended
BuildingKinds:
  INCBIN "res/tables/BuildingKinds.bin",$0000,86

; the current zone's density (ScanInsideCell) or the building's (BuildingKinds)
Density:
  DEFB $00
BuildingLevel:
  DEFB $00                ; the building's level (BuildingKinds' third byte)

; Look up the building's type in BuildingKinds and jump to its routine
;
; Used by the routine at ZoneStep.
BuildingStep:
  LD HL,BuildingKinds
  LD BC,$0004
  LD A,(BuildingType)
  LD E,A
BuildingStepLook:
  LD A,(HL)
  CP $FF
  RET Z
  CP E
  JR Z,BuildingStepFound
  ADD HL,BC
  JR BuildingStepLook
BuildingStepFound:
  INC HL
  LD C,(HL)
  INC HL
  LD A,(HL)
  LD (BuildingLevel),A
  INC HL
  LD A,(HL)
  LD (Density),A
  SLA C
  LD B,$00
  LD HL,BuildingRoutines
  ADD HL,BC
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  JP (HL)

; A plain cell: fire $45, flood $44, radiation $59; roads and rails counted and
; decayed
;
; L1 10 084 463.
CellStep:
  LD A,(HL)
  CP $80
  RET NC
  LD (CurAddr),HL
  LD (CurCell),DE
  EXX
  LD HL,CellStepEnd
  PUSH HL
  CP $59
  JP Z,RadiationCell
  CP $45
  JP Z,FireCell
  CP $44
  JP Z,FloodCell
  CALL CellFlagsOf
  BIT 2,A
  JR NZ,RoadCell
  BIT 1,A
  JR NZ,RailCell
  POP HL
CellStepEnd:
  EXX
  RET

; The mask of the roads' decay (Random AND it = 0 crumbles a cell); $FF none
RoadDecay:
  DEFB $FF

; Count the road (RoadCount, upkeep + 1, a bridge + 3); with RoadDecay it may
; crumble to $3A
;
; Used by the routine at CellStep.
RoadCell:
  LD HL,RoadDecay
  LD A,(HL)
  INC A
  JR Z,RoadCellCount
  CALL Random
  AND (HL)
  JP Z,ToRubble
RoadCellCount:
  LD HL,(RoadCount)
  INC HL
  LD A,H
  OR L
  JR Z,RoadCellUpkeep
  LD (RoadCount),HL
RoadCellUpkeep:
  LD HL,(TransportUpkeep)
  INC HL
  LD A,H
  OR L
  JR Z,RoadCellBridge
  LD (TransportUpkeep),HL
RoadCellBridge:
  LD HL,(CurAddr)
  LD A,(HL)
  CP $13
  JR Z,RoadBridgeUpkeep
  CP $12
  RET NZ
RoadBridgeUpkeep:
  LD HL,(TransportUpkeep)
  LD DE,$0003
  ADD HL,DE
  JR C,RoadCellEnd
  LD (TransportUpkeep),HL
RoadCellEnd:
  RET

; The same for the rails
RailDecay:
  DEFB $FF

; Count the rail (RailCount, upkeep + 4, a bridge + 6), StartTrain; with
; RailDecay it may crumble
;
; Used by the routine at CellStep.
RailCell:
  LD HL,RailDecay
  LD A,(HL)
  INC A
  JR Z,RailCellCount
  CALL Random
  AND (HL)
  JR Z,ToRubble
RailCellCount:
  LD HL,(RailCount)
  INC HL
  LD A,H
  OR L
  JR Z,RailCellUpkeep
  LD (RailCount),HL
RailCellUpkeep:
  LD HL,(TransportUpkeep)
  LD DE,$0004
  ADD HL,DE
  JR C,RailCellTrain
  LD (TransportUpkeep),HL
RailCellTrain:
  CALL StartTrain
  LD HL,(CurAddr)
  LD A,(HL)
  CP $20
  JR Z,RailBridgeUpkeep
  CP $1F
  RET NZ
RailBridgeUpkeep:
  LD HL,(TransportUpkeep)
  LD DE,$0006
  ADD HL,DE
  JR C,RailCellEnd
  LD (TransportUpkeep),HL
RailCellEnd:
  RET

; $59: with 1 in 4096 rubble, else pollution $40 round it
;
; Used by the routine at CellStep.
RadiationCell:
  CALL Random
  LD HL,(RandomSeed)
  LD A,H
  AND $0F
  OR L
  JR Z,ToRubble
  LD A,$40
  LD (PollutionStrength),A
  JP StampPollution

; the cell becomes $3A
;
; Used by the routines at RoadCell, RailCell, RadiationCell, FireCell and
; Spread.
ToRubble:
  LD HL,(CurAddr)
  LD (HL),$3A
  RET

; the cell becomes land 2
;
; Used by the routine at FloodCell.
ToLand:
  LD HL,(CurAddr)
  LD (HL),$02
  RET

; $45: FireCells + 1; put out with a chance of (FireCover + 1) / 16, else
; Spread
;
; Used by the routine at CellStep.
FireCell:
  LD HL,(FireCells)
  INC HL
  LD A,H
  OR L
  JR Z,FireCellCover
  LD (FireCells),HL
FireCellCover:
  CALL FireAt
  INC A
  LD B,A
  CALL Random
  AND $0F
  CP B
  JR C,ToRubble
  LD A,$45
  LD (SpreadCode),A
  XOR A
  LD (SpreadFlood),A
  JR Spread

; The flood's spreads left (50)
FloodLeft:
  DEFB $32

; $44: while FloodLeft, spread the water; then the cell dries to land
;
; Used by the routine at CellStep.
FloodCell:
  LD HL,FloodLeft
  LD A,(HL)
  AND A
  JR Z,ToLand
  DEC (HL)
  LD A,$44
  LD (SpreadCode),A
  LD (SpreadFlood),A
  JR Spread

; Spread's cell ($45 fire, $44 flood), its kind (0 fire) and its neighbour
; count
SpreadCode:
  DEFB $00
SpreadFlood:
  DEFB $00
SpreadCount:
  DEFB $00

; Each of the four neighbours that burns (flags bit 7, a building) or floods: 1
; in 8 catches; a fire with nothing round dies with 1 in 4
;
; Used by the routines at FireCell and FloodCell.
Spread:
  XOR A
  LD (SpreadCount),A
  LD E,$04
SpreadLoop:
  PUSH DE
  LD BC,(CurCell)
  LD A,E
  DEC A
  CALL StepDir
  CALL MapAddr
  JR NC,SpreadNext
  LD A,(SpreadFlood)
  AND A
  JR NZ,SpreadNear
  LD A,(HL)
  CP $80
  JR NC,SpreadNear
  CALL CellFlagsOf
  BIT 7,A
  JR Z,SpreadNext
SpreadNear:
  LD A,(SpreadCount)
  INC A
  LD (SpreadCount),A
  CALL Random
  AND $07
  JR NZ,SpreadNext
  CALL SpreadTo
SpreadNext:
  POP DE
  DEC E
  JR NZ,SpreadLoop
  LD A,(SpreadFlood)
  AND A
  RET NZ
  CALL Random
  AND $03
  RET NZ
  LD A,(SpreadCount)
  AND A
  JP Z,ToRubble
  RET

; The neighbour at HL takes SpreadCode: a whole building (FillBuilding), else
; the cell (not the bridges, not water for floods)
;
; Used by the routine at Spread.
SpreadTo:
  LD A,(SpreadFlood)
  AND A
  JR Z,SpreadToCell
  LD A,(HL)
  AND A
  RET Z
SpreadToCell:
  BIT 7,(HL)
  JP NZ,FillBuilding
  PUSH HL
  LD HL,BulldozeKeep
  LD BC,$0008
  CPIR
  POP HL
  RET Z
  LD A,(SpreadCode)
  LD (HL),A
  RET

; The eight cells round a zone centre: row step, column step, the empty frame
; cell ($49-$50)
ZoneFrame:
  INCBIN "res/tables/ZoneFrame.bin",$0000,24

; BC = a random one of the eight frame cells round CurCell; IX its ZoneFrame
; row
;
; L1 51 171.
PickFrameCell:
  CALL Random
  AND $07
  LD C,A
  ADD A,A
  ADD A,C
  LD C,A
  LD B,$00
  LD IX,ZoneFrame
  ADD IX,BC
  LD A,(CurCell)
  ADD A,(IX+$01)
  LD C,A
  LD A,(CurCell+$0001)
  ADD A,(IX+$00)
  LD B,A
  RET

; GrowTries ($8F67) times: a frame cell one house up (GrowCell); stop at the
; first that grows
;
; Used by the routine at ResidentialStep.
GrowZone:
  LD A,(GrowTries)
  CP $FF
  RET Z
  LD B,A
GrowZoneLoop:
  PUSH BC
  CALL PickFrameCell
  CALL GrowCell
  POP BC
  RET NC
  DJNZ GrowZoneLoop
  RET

; A frame cell (CellFlags bit 4): the empty frame becomes house $3C, a house
; $3C-$42 one more; $43 full (carry)
;
; L1 6862.
GrowCell:
  CALL MapAddr
  LD A,(HL)
  CALL CellFlagsOf
  BIT 4,A
  RET Z
  LD A,(HL)
  CP (IX+$02)
  JR NZ,GrowCellUp
  LD (HL),$3C
  RET
GrowCellUp:
  LD A,(HL)
  INC A
  CP $44
  JP Z,TripWalkLost
  LD (HL),A
  OR A
  RET

; GrowTries times: a frame cell one house down (DeclineCell)
;
; Used by the routine at ResidentialStep.
DeclineZone:
  LD A,(GrowTries)
  CP $FF
  RET Z
  LD B,A
DeclineZoneLoop:
  PUSH BC
  CALL PickFrameCell
  CALL DeclineCell
  POP BC
  RET NC
  DJNZ DeclineZoneLoop
  RET

; A house one down; $3C goes back to the empty frame cell; an empty frame cell
; does not decline (carry)
;
; L1 44 309.
DeclineCell:
  CALL MapAddr
  LD A,(HL)
  CALL CellFlagsOf
  BIT 4,A
  RET Z
  LD A,(HL)
  CP (IX+$02)
  JP Z,TripWalkLost
  LD A,(HL)
  DEC A
  CP $3B
  JR NZ,DeclineCellStore
  LD A,(IX+$02)
  LD (HL),A
  OR A
  RET
DeclineCellStore:
  LD (HL),A
  OR A
  RET

; The R zone: ResPop + 1, Population + 16 Density, a trip to C or I (when
; Random AND 63 < Density), the score; grow or decline
;
; Grows while Density < ResTile (ZoneScore / 2), else declines; a full zone
; (Density 63+) becomes a 3 x 3 building: a ChurchNeed or HospitalNeed building
; first ($1B, $12), else the residential block (tile $88). L1 17 802.
ResidentialStep:
  LD BC,(CurCell)
  DEC B
  DEC C
  CALL ScanRing
  LD HL,(ResPop)
  INC HL
  LD A,H
  OR L
  JR Z,ResidentialPop
  LD (ResPop),HL
ResidentialPop:
  LD A,(Density)
  LD E,A
  LD D,$00
  CALL AddPopulation
  LD A,(RingTransport)
  LD (TripMade),A
  CALL Random
  AND $3F
  LD HL,Density
  SUB (HL)
  JR NC,ResidentialScoreIt
  LD HL,$0A0B
  LD (TripTargets),HL
  CALL MakeTrip
ResidentialScoreIt:
  CALL ZonePollution
  LD HL,(ResDemand)
  LD (ZoneDemand),HL
  CALL ResidentialScore
  LD A,(Density)
  CP $10
  JR C,ResidentialGrow
ResidentialGrow:
  LD A,(Density)
  CP $3F
  JR NC,ResidentialBuild
  LD HL,ResTile
  CP (HL)
  JP C,GrowZone
  JP DeclineZone
ResidentialBuild:
  LD A,(HospitalNeed)
  AND A
  JR NZ,ResidentialBuildHospital
  LD A,(ChurchNeed)
  AND A
  JR NZ,ResidentialBuildChurch
  XOR A
  LD BC,(CurCell)
  DEC B
  DEC C
  LD DE,$0088
  JP PutZoneBuilding
ResidentialBuildHospital:
  XOR A
  LD (HospitalNeed),A
  LD BC,(CurCell)
  DEC B
  DEC C
  LD DE,$001B
  JP PutZoneBuilding
ResidentialBuildChurch:
  XOR A
  LD (ChurchNeed),A
  LD BC,(CurCell)
  DEC B
  DEC C
  LD DE,$0012
  JP PutZoneBuilding

; A residential block (types $11-$14): count, the trip, the score; with the
; growth chance a block of level ResLevel / 2, or back to a full zone
;
; Below score 128 (ResLevel $0F) the block goes back to the houses zone
; ResRevertZone. Not run in any recording (no block grew there): known only
; from the code.
ResBuildingStep:
  LD HL,(ResPop)
  INC HL
  LD A,H
  OR L
  JR Z,ResBuildingPop
  LD (ResPop),HL
ResBuildingPop:
  LD BC,(CurCell)
  CALL ScanRing
  LD A,(Density)
  LD E,A
  LD D,$00
  CALL AddPopulation
  LD A,(RingTransport)
  LD (TripMade),A
  CALL Random
  AND $7F
  LD HL,Density
  SUB (HL)
  JR NC,ResBuildingScore
  LD HL,$0A0B
  LD (TripTargets),HL
  CALL MakeTrip
ResBuildingScore:
  CALL ZonePollution
  LD A,(ResDemand)
  LD (ZoneDemand),A
  CALL ResidentialScore
  CALL Random
  LD HL,IndChance
  AND (HL)
  RET NZ
  LD A,(HL)
  CP $FF
  RET Z
  LD A,(ResLevel)
  CP $08
ResBuildingLevel:
  JR NC,ResRevert         ; JR NC: ResLevel 8 and up, back to the houses
  SRL A
  LD BC,(CurCell)
  LD DE,$0088
  JP PutZoneBuilding

; The full R zone a block falls back to: houses $40-$43 round the powered
; centre $51
ResRevertZone:
  DEFB $42,$40,$42,$41,$51,$43,$43,$42,$43
ResEmptyZone:
  DEFB $49,$4A,$4B,$50,$51,$4C,$4F,$4E,$4D ; the empty R zone, centre $51: a
                                           ; hospital or church falls back to
                                           ; it

; Put ResRevertZone (or, from $8BAD, the pattern at IX) at the building
;
; Used by the routine at ResBuildingStep.
ResRevert:
  LD IX,ResRevertZone
; This entry point is used by the routines at ChurchStep and HospitalStep.
ResRevertAt:
  LD BC,(CurCell)
  CALL MapAddr
  LD BC,$0303
  JP PutBuildingSize

; By ComLevel - 1: the commercial building variant (0-3)
ComBuildings:
  INCBIN "res/tables/ComBuildings.bin",$0000,10

; The C zone: ComPop + 1; powered: ring, a trip to R or I (1 in 32 - Density),
; the score; with the C chance a building of its level, or back to an empty
; zone
;
; L1 2575.
CommercialStep:
  LD HL,(ComPop)
  INC HL
  LD A,H
  OR L
  JR Z,CommercialPowered
  LD (ComPop),HL
CommercialPowered:
  LD A,(ZonePowered)
  AND A
  RET Z
  LD BC,(CurCell)
  DEC B
  DEC C
  LD (CurCell),BC
  JR CommercialRing

; a commercial building (types $15-$18): the same from the building's corner
ComBuildingStep:
  LD HL,(ComPop)
  INC HL
  LD A,H
  OR L
  JR Z,CommercialRing
  LD (ComPop),HL
; This entry point is used by the routine at CommercialStep.
CommercialRing:
  LD BC,(CurCell)
  CALL ScanRing
  LD A,(RingTransport)
  LD (TripMade),A
  CALL Random
  AND $1F
  LD HL,Density
  SUB (HL)
  JR NC,CommercialScoreIt
  LD HL,$090B
  LD (TripTargets),HL
  CALL MakeTrip
CommercialScoreIt:
  CALL ZonePollution
  LD HL,(ComDemand)
  LD (ZoneDemand),HL
  CALL CommercialScore
  CALL Random
  LD HL,ComChance
  AND (HL)
  RET NZ
  LD A,(HL)
  CP $FF
  RET Z
  LD A,(ComLevel)
  CALL NoGrowthAlone
  CP $00
  JR Z,ComRevert
  DEC A
  LD C,A
  LD B,$00
  LD HL,ComBuildings
  ADD HL,BC
  LD A,(HL)
  LD BC,(CurCell)
  LD DE,$00AC
  JP PutZoneBuilding

; The empty C zone, centre $52 (powered)
ComEmptyZone:
  DEFB $49,$4A,$4B,$50,$52,$4C,$4F,$4E,$4D

; Put ComEmptyZone at the zone
;
; L1 126.
ComRevert:
  LD BC,(CurCell)
  CALL MapAddr
  LD BC,$0303
  LD IX,ComEmptyZone
  JP PutBuildingSize

; The I zone: IndPop + 1; powered: ring, a trip to R, the score (pollution not
; counted); with the I chance a building of its level, or back; pollution 4 x
; IndLevel
;
; L1 1795.
IndustrialStep:
  LD HL,(IndPop)
  INC HL
  LD A,H
  OR L
  JR Z,IndustrialPowered
  LD (IndPop),HL
IndustrialPowered:
  LD A,(ZonePowered)
  AND A
  RET Z
  LD BC,(CurCell)
  DEC B
  DEC C
  LD (CurCell),BC
  JR IndustrialRing

; an industrial building (types $1A-$1D)
IndBuildingStep:
  LD HL,(IndPop)
  INC HL
  LD A,H
  OR L
  JR Z,IndustrialRing
  LD (IndPop),HL
; This entry point is used by the routine at IndustrialStep.
IndustrialRing:
  LD BC,(CurCell)
  CALL ScanRing
  LD A,(RingTransport)
  LD (TripMade),A
  CALL Random
  AND $3F
  LD HL,Density
  SUB (HL)
  JR NC,IndustrialScoreIt
  LD HL,$0909
  LD (TripTargets),HL
  CALL MakeTrip
IndustrialScoreIt:
  LD HL,(IndDemand)
  LD (ZoneDemand),HL
  XOR A
  LD (ZonePollutionMax),A
  CALL IndustrialScore
  CALL Random
  LD HL,IndChance
  AND (HL)
  JR NZ,IndustrialPollute
  LD A,(HL)
  CP $FF
  JR Z,IndustrialPollute
  LD A,(IndLevel)
  CALL NoGrowthAlone
  CP $00
  JR Z,IndRevert
  DEC A
  SRL A
  LD BC,(CurCell)
  LD DE,$00D0
  CALL PutZoneBuilding
IndustrialPollute:
  LD A,(IndLevel)
  ADD A,A
  ADD A,A
  LD (PollutionStrength),A
  JP StampPollution

; A = 0 when last month's population (LastPop) was 0, else A kept: a city of
; nobody falls back
;
; Used by the routines at ComBuildingStep and IndBuildingStep.
NoGrowthAlone:
  PUSH AF
  LD HL,LastPop
  LD A,(HL)
  INC HL
  OR (HL)
  INC HL
  OR (HL)
  JP Z,NoGrowthAloneZero
  POP AF
  RET
NoGrowthAloneZero:
  POP AF
  XOR A
  RET

; The empty I zone, centre $53 (powered)
IndEmptyZone:
  DEFB $49,$4A,$4B,$50,$53,$4C,$4F,$4E,$4D

; Put IndEmptyZone at the zone
;
; L1 719.
IndRevert:
  LD BC,(CurCell)
  CALL MapAddr
  LD BC,$0303
  LD IX,IndEmptyZone
  JP PutBuildingSize

; A coal station: CoalCount + 1, pollution $FF round it
CoalStep:
  LD HL,(CoalCount)
  INC HL
  LD A,H
  OR L
  JR Z,CoalPollute
  LD (CoalCount),HL
CoalPollute:
  XOR A
  LD (ZoneDemand),A
  LD (ZonePollutionMax),A
  LD (RingAmenity),A
  INC A
  LD (TripMade),A
  CALL ZoneScoreOf
  LD A,$FF
  LD (PollutionStrength),A
  JP StampPollution

; A nuclear station: NuclearCount + 1, Meltdown (when pending), pollution $30
NuclearStep:
  LD HL,(NuclearCount)
  INC HL
  LD A,H
  OR L
  JR Z,NuclearPollute
  LD (NuclearCount),HL
NuclearPollute:
  XOR A
  LD (ZoneDemand),A
  LD (ZonePollutionMax),A
  LD (RingAmenity),A
  INC A
  LD (TripMade),A
  CALL ZoneScoreOf
  CALL Meltdown
  LD A,$30
  LD (PollutionStrength),A
  JP StampPollution

; A police station: PoliceCost ($8466) + 100; powered, PoliceCount + 1
PoliceStep:
  LD HL,(Count8466)
  LD DE,$0064
  ADD HL,DE
  JR C,PolicePowered
  LD (Count8466),HL
PolicePowered:
  LD A,(ZonePowered)
  AND A
  RET Z
  LD HL,(PoliceCount)
  INC HL
  LD A,H
  OR L
  JR Z,PoliceStepEnd
  LD (PoliceCount),HL
PoliceStepEnd:
  RET

; A fire station: FireCost ($8468) + 100; powered, FireCount + 1
FireStep:
  LD HL,(Count8468)
  LD DE,$0064
  ADD HL,DE
  JR C,FirePowered
  LD (Count8468),HL
FirePowered:
  LD A,(ZonePowered)
  AND A
  RET Z
  LD HL,(FireCount)
  INC HL
  LD A,H
  OR L
  JR Z,FireStepEnd
  LD (FireCount),HL
FireStepEnd:
  RET

; Type 2: ChurchCount + 1; unpowered, with the R chance back to an empty R zone
; (not run in the recordings)
ChurchStep:
  LD HL,(ChurchCount)
  INC HL
  LD A,H
  OR L
  JR Z,ChurchCounted
  LD (ChurchCount),HL
ChurchCounted:
  CALL Random
  LD HL,IndChance
  AND (HL)
  RET NZ
  LD A,(HL)
  CP $FF
  RET Z
  LD A,(ZonePowered)
  AND A
  JR NZ,ChurchEnd
  LD IX,ResEmptyZone
  JP ResRevertAt
ChurchEnd:
  RET

; Type 3: HospitalCount + 1; the same
HospitalStep:
  LD HL,(HospitalCount)
  INC HL
  LD A,H
  OR L
  JR Z,HospitalCounted
  LD (HospitalCount),HL
HospitalCounted:
  CALL Random
  LD HL,IndChance
  AND (HL)
  RET NZ
  LD A,(HL)
  CP $FF
  RET Z
  LD A,(ZonePowered)
  AND A
  JR NZ,HospitalEnd
  LD IX,ResEmptyZone
  JP ResRevertAt
HospitalEnd:
  RET

; A powered stadium with transport: 1 in 32 a trip to R; when it arrives
; StadiumCount + 1
;
; L1 648.
StadiumStep:
  LD A,(ZonePowered)
  AND A
  RET Z
  LD BC,(CurCell)
  LD HL,$0404
  CALL ScanRingSize
  LD A,(RingTransport)
  AND A
  RET Z
  LD (TripMade),A
  LD HL,$0909
  LD (TripTargets),HL
  CALL Random
  AND $1F
  CALL Z,MakeTrip
  LD A,(TripMade)
  AND A
  RET Z
  LD HL,(StadiumCount)
  INC HL
  LD A,H
  OR L
  JR Z,StadiumStepEnd
  LD (StadiumCount),HL
StadiumStepEnd:
  RET

; A powered seaport with water and transport round it: 1 in 32 a trip to I;
; SeaportCount + 1; pollution $60
SeaportStep:
  LD A,(ZonePowered)
  AND A
  RET Z
  LD BC,(CurCell)
  LD HL,$0404
  CALL ScanRingSize
  LD A,(RingWater)
  AND A
  RET Z
  LD A,(RingTransport)
  AND A
  RET Z
  LD (TripMade),A
  LD HL,$0B0B
  LD (TripTargets),HL
  CALL Random
  AND $1F
  CALL Z,MakeTrip
  LD A,(TripMade)
  AND A
  RET Z
  LD HL,(SeaportCount)
  INC HL
  LD A,H
  OR L
  JR Z,SeaportPollute
  LD (SeaportCount),HL
SeaportPollute:
  LD A,$60
  LD (PollutionStrength),A
  JP StampPollution

; A powered airport (6 x 6): 1 in 32 a trip to C; AirportCount + 1; StartPlane
AirportStep:
  LD A,(ZonePowered)
  AND A
  RET Z
  LD BC,(CurCell)
  LD HL,$0606
  CALL ScanRingSize
  LD A,(RingTransport)
  AND A
  RET Z
  LD (TripMade),A
  LD HL,$0A0A
  LD (TripTargets),HL
  CALL Random
  AND $1F
  CALL Z,MakeTrip
  LD A,(TripMade)
  AND A
  RET Z
  LD HL,(AirportCount)
  INC HL
  LD A,H
  OR L
  JR Z,AirportPlane
  LD (AirportCount),HL
AirportPlane:
  JP StartPlane

; The population at the last month's end; at the year's ends ($8E8D two years
; back, $8E90 last year)
LastPop:
  DEFB $00,$00,$00
PopYearBefore:
  DEFB $00,$00,$00
PopLastYear:
  DEFB $00,$00,$00
BudgetDue:
  DEFB $00                ; 1 while the UI task shows the budget (the year's
                          ; end without the auto budget)

; LastPop; in December: the year's populations, the costs to the budget
; ($9311-$9315), the budget (shown, or auto), Funds, the evaluation
;
; L1 934; the December branch L1 77.
MonthEnd:
  LD HL,(Population)
  LD A,(Population+$0002)
  LD C,A
  LD (LastPop),HL
  LD A,C
  LD (LastPop+$0002),A
  LD A,(Month)
  CP $0B
  RET NZ
  LD HL,(PopLastYear)
  LD A,(PopLastYear+$0002)
  LD C,A
  LD (PopYearBefore),HL
  LD A,C
  LD (PopYearBefore+$0002),A
  LD HL,(Population)
  LD A,(Population+$0002)
  LD C,A
  LD (PopLastYear),HL
  LD A,C
  LD (PopLastYear+$0002),A
  LD HL,(TransportUpkeep)
  LD (TransportCost),HL
  LD HL,(Count8466)
  LD (PoliceCost),HL
  LD HL,(Count8468)
  LD (FireCost),HL
  LD A,(AutoBudget)
  AND A
  JR NZ,MonthEndAuto
  LD A,$01
  LD (BudgetDue),A
MonthEndWait:
  LD A,(BudgetDue)        ; wait for the UI task's budget window to clear
                          ; BudgetDue
  AND A
  JR NZ,MonthEndWait
  JR MonthEndFunds
MonthEndAuto:
  CALL TaxIncomeOf
  CALL BudgetFigures
MonthEndFunds:
  LD HL,(FundsAfter)
  LD A,(FundsAfter+$0002)
  LD C,A
  LD (Funds),HL
  LD A,C
  LD (Funds+$0002),A
  CALL ApplyFunding
  RET

; Averages2's results: 2 x the crime average, the land value average / 8, the
; building count
AvgCrime:
  DEFB $00
AvgLandValue:
  DEFB $00
LastBuildings:
  DEFB $00
  DEFB $00

; AvgCrime, AvgLandValue, LastBuildings
;
; Used by the routine at SimTask.
Averages2:
  LD HL,(CrimeSum)
  LD DE,(CrimeCount)
  CALL Div16
  LD A,L
  ADD A,A
  LD (AvgCrime),A
  LD HL,(LandValueSum)
  LD DE,(LandValueCount)
  CALL Div16
  LD A,L
  SRL A
  SRL A
  SRL A
  LD (AvgLandValue),A
  LD HL,(BuildingCount)
  LD (LastBuildings),HL
  RET

; ServiceNeeds' results: ResPop / 18 - HospitalCount and ResPop / 20 -
; ChurchCount (0 when not positive)
HospitalNeed:
  DEFB $00
ChurchNeed:
  DEFB $00

; ServiceNeeds
;
; Used by the routine at SimTask.
ServiceNeeds:
  XOR A
  LD (HospitalNeed),A
  LD HL,(ResPop)
  LD A,$12
  CALL Div8
  LD DE,(HospitalCount)
  AND A
  SBC HL,DE
  BIT 7,H
  JR NZ,ServiceNeedsChurch
  LD A,L
  LD (HospitalNeed),A
ServiceNeedsChurch:
  XOR A
  LD (ChurchNeed),A
  LD HL,(ResPop)
  LD A,$14
  CALL Div8
  LD DE,(ChurchCount)
  AND A
  SBC HL,DE
  BIT 7,H
  RET NZ
  LD A,L
  LD (ChurchNeed),A
  RET

; The speed's five values, copied from SpeedTable by SetSpeed: the growth
; tries, the I chance mask, the C chance mask, a fourth (no reader), the month
; mask
GrowTries:
  DEFB $08
IndChance:
  DEFB $07
ComChance:
  DEFB $07
SpeedSpare:
  DEFB $07
MonthMask:
  DEFB $01

; four speeds of five: fast (8, 1, 15, 1, 0), normal (4, 3, 31, 3, 1), slow (3,
; 7, 63, 7, 3), paused (all $FF)
SpeedTable:
  INCBIN "res/tables/SpeedTable.bin",$0000,20

; Copy SpeedTable[Speed $A3AB] to GrowTries-MonthMask
;
; L1 1101.
SetSpeed:
  LD A,(Speed)
  LD B,A
  ADD A,A
  ADD A,A
  ADD A,B
  LD C,A
  LD B,$00
  LD HL,SpeedTable
  ADD HL,BC
  LD DE,GrowTries
  LD BC,$0005
  LDIR
  RET
