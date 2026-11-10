; --------------------------------------------------------------------------------------------------------------------
; landscape.asm: The landscape generator
;
; NewLandscape from the five-digit gene: the map all water, land discs at random centres and radii, tree discs on
; land, then the coast from the eight-neighbour patterns. MapAddr and MapAddrChecked, the map's address arithmetic,
; live here.
; --------------------------------------------------------------------------------------------------------------------

; The landscape's gene, the seed of the generator (3 in the image: "00003")
Gene:
  DEFW $0003

; Make the landscape from Gene: the map all water, 128 land discs, the coasts,
; 32 tree discs
;
; Resets the simulation (StartSimulation $830C), clears CityMap $C450 to 0
; (water), shows "CREATING LANDSCAPE" ($A6A4), seeds Random with Gene, draws
; 128 discs of land ($02) with radius 2-7 at x, y 16-79 (Disc), cuts the coast
; (MakeCoast), then 32 discs of trees ($06) of radius 2-3 drawn only over land.
; L1 12 (the menus recording's genes 12345 and 00003, the level starts).
NewLandscape:
  CALL StartSimulation
  LD HL,CityMap
  LD DE,CityMap+$0001
  LD BC,$23FF
  LD (HL),$00
  LDIR
  LD IX,CreatingText
  CALL ClearViewArea
  CALL ClearWindowArea
  CALL DrawMenu
  LD HL,(Gene)
  LD (RandomSeed),HL
  XOR A
  LD (DiscOver),A
  LD BC,$8002
  LD E,$07
  CALL Discs
  LD A,$02
  LD (DiscCell),A
  CALL MakeCoast
  LD A,$02
  LD (DiscOver),A
  LD BC,$2006
  LD E,$03
  CALL Discs
  RET

; Four pairs of shifts (4, 4), (5, 3), (3, 5), (4, 4): the disc's two axes
; (round, flat, tall)
DiscShapes:
  INCBIN "res/tables/DiscShapes.bin",$0000,8

; B discs of cell C, radius 2 to E (random), centre 16-79, each with a random
; shape from DiscShapes
;
; Used by the routine at NewLandscape.
Discs:
  LD A,C
  LD (DiscCell),A
  LD A,E
  LD (DiscsLoop+$0005),A
DiscsLoop:
  PUSH BC
  CALL Random
  AND $07
  CP $02
  JR NC,DiscsRadius
  LD A,$02
DiscsRadius:
  LD (DiscRadius),A
  CALL Random
  AND $3F
  ADD A,$10
  LD (DiscVars),A
  CALL Random
  AND $3F
  ADD A,$10
  LD (DiscY),A
  CALL Random
  AND $03
  ADD A,A
  LD C,A
  LD B,$00
  LD HL,DiscShapes
  ADD HL,BC
  LD DE,DiscShift
  LDI
  LDI
  CALL Disc
  POP BC
  DJNZ DiscsLoop
  RET

; The coast: 66 masks of the eight land neighbours, then the 66 cell codes put
; on such water
;
; Read by MakeCoast with CPIR (L1 426 157 compares).
CoastPatterns:
  INCBIN "res/tables/Coast.bin",$0000,66
CoastCells:
  INCBIN "res/tables/Coast.bin",$0042,66

; Every water cell next to land whose neighbour mask is in CoastPatterns
; becomes its coast cell
;
; Used by the routine at NewLandscape.
MakeCoast:
  LD B,$60
MakeCoastRow:
  LD C,$60
MakeCoastCell:
  PUSH BC
  PUSH BC
  CALL MapAddrChecked
  POP BC
  LD A,(HL)
  AND A
  JR NZ,MakeCoastNext
  CALL LandNeighbours
  LD A,D
  AND A
  JR Z,MakeCoastNext
  PUSH BC
  LD HL,CoastPatterns
  LD BC,$0042
  CPIR
  POP BC
  JR NZ,MakeCoastNext
  LD DE,$0041
  ADD HL,DE
  LD E,(HL)
  CALL MapAddrChecked
  LD A,(HL)
  AND A
  JR NZ,MakeCoastNext
  LD (HL),E
MakeCoastNext:
  POP BC
  DEC C
  JR NZ,MakeCoastCell
  DJNZ MakeCoastRow
  RET

; Set to 0 when MapAddrChecked was given a cell off the map
MapEdge:
  DEFB $00

; HL = CityMap + 96 B + C for row B, column C below 96 (carry set); else carry
; clear
;
; L1 2 928 251.
MapAddrChecked:
  LD HL,$0060
  LD A,B
  CP L
  JR NC,MapAddrOff
  LD A,C
  CP L
  JR NC,MapAddrOff

; HL = CityMap + 96 B + C
;
; L1 3 488 641.
MapAddr:
  LD L,B
  LD H,$00
  LD A,C
  LD B,H
  LD C,L
  ADD HL,HL
  ADD HL,BC
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD B,$00
  LD C,A
  ADD HL,BC
  LD BC,CityMap
  ADD HL,BC
  SCF
  RET
; This entry point is used by the routine at MapAddrChecked.
MapAddrOff:
  XOR A
  LD (MapEdge),A
  RET

; The disc being drawn: centre x, y, radius, cell, the cell it may replace (0
; any), the two shifts
DiscVars:
  DEFB $0A
DiscY:
  DEFB $0A
DiscRadius:
  DEFB $05
DiscCell:
  DEFB $02
DiscOver:
  DEFB $00
DiscShift:
  DEFB $04,$04

; Draw a disc of DiscCell: 49 steps of a shift-based circle, each a horizontal
; run across it
;
; The run's ends come from the circle drawing x -= y >> s1, y += x >> s2 (the
; two shifts of DiscShapes), in 8.8 fixed point from (radius, 0): an ellipse
; when the shifts differ. L1 1920.
Disc:
  LD A,(DiscRadius)
  LD H,A
  LD L,$00
  LD (DiscY1+$0001),HL
  LD H,L
  LD (DiscX1+$0001),HL
  LD B,$31
DiscStep:
  PUSH BC
DiscX1:
  LD HL,$0000             ; LD HL,n: the first coordinate (operand $6C1A)
DiscY1:
  LD DE,$0000             ; LD DE,n: the second coordinate (operand $6C1D)
  LD B,D
  LD C,E
  LD A,(DiscShift)
DiscShift1:
  SRA B
  RR C
  DEC A
  JR NZ,DiscShift1
  INC BC
  AND A
  SBC HL,BC
  EX DE,HL
  LD B,D
  LD C,E
  LD A,(DiscShift+$0001)
DiscShift2:
  SRA B
  RR C
  DEC A
  JR NZ,DiscShift2
  INC BC
  ADD HL,BC
  EX DE,HL
  LD (DiscX1+$0001),HL
  LD (DiscY1+$0001),DE
  LD BC,(DiscVars)
  LD A,D
  ADD A,B
  LD B,A
  LD A,H
  ADD A,C
  LD C,A
  LD A,(DiscX1+$0002)
  NEG
  ADD A,A
  LD D,A
DiscRun:
  PUSH BC
  CALL MapAddrChecked
  POP BC
  LD A,(DiscOver)
  AND A
  JR Z,DiscPut
  PUSH BC
  LD B,A
  LD A,(HL)
  CP B
  POP BC
  JR NZ,DiscRunNext
DiscPut:
  LD A,(DiscCell)
  LD (HL),A
DiscRunNext:
  INC C
  DEC D
  JR NZ,DiscRun
  POP BC
  DJNZ DiscStep
  RET

; Carry set when the cell at row B, column C is on the map and holds land ($02)
;
; Used by the routine at LandNeighbours.
IsLand:
  PUSH BC
  CALL MapAddrChecked
  POP BC
  RET NC
  LD A,(HL)
  CP $02
  JR Z,IsLandYes
  OR A
  RET
IsLandYes:
  SCF
  RET

; D = the land bits of the eight neighbours of (B, C), the row above first
;
; L1 54 876.
LandNeighbours:
  PUSH BC
  LD D,$00
  DEC B
  DEC C
  CALL IsLand
  RL D
  INC C
  CALL IsLand
  RL D
  INC C
  CALL IsLand
  RL D
  DEC C
  DEC C
  INC B
  CALL IsLand
  RL D
  INC C
  INC C
  CALL IsLand
  RL D
  DEC C
  DEC C
  INC B
  CALL IsLand
  RL D
  INC C
  CALL IsLand
  RL D
  INC C
  CALL IsLand
  RL D
  POP BC
  RET
