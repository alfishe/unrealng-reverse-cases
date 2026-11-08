; --------------------------------------------------------------------------------------------------------------------
; galaxy.asm: The galaxy's 256 systems from three seed words: the twist, the nearest system, the distance, the names, the system data and the market
;
; Elite's galaxy is generated, never stored: a system is three 16-bit seeds (s0, s1, s2), and the next system's seeds
; are s1, s2 and s0 + s1 + s2 (Twist), four twists a system. The galaxy's first system has the galaxy's seeds ($D090);
; the next galaxy rotates each of the six bytes left one bit (GalaxyJump). From the seeds come the chart position (x =
; s1 high, y = s0 high), the economy, government, tech level, population and productivity (SystemData) and the name
; (SystemName: three or four letter pairs of StdPairs $FDB3 picked by s2's top bits), all as in BBC Elite
; (bbcelite.com's deep dives agree with every step here).
;
; The selected system (the cursor's, $DEBA) and the current one ($D096) are kept as seeds; the work copy at $DEC0 is
; the one twisted. A chart cursor move, a jump and a planet's name typed on the chart all end in FindNearest or
; FindSystem, which leave the selected system's data, name and distance here.
; --------------------------------------------------------------------------------------------------------------------

; One byte no code reads (known from the code only)
GalaxySpare:
  DEFB $00

; The selected system's seeds s0, s1, s2 (SystemData)
SelectedSeeds:
  DEFB $00,$00,$00,$00,$00,$00

; The seeds being twisted: the system the loops are at
SystemSeeds:
  DEFB $00,$00,$00,$00,$00,$00

; FindNearest's best system so far; FindSystem's place in the walk
BestSeeds:
  DEFB $00,$00,$00,$00,$00,$00

; The four bytes TextRandom shifts for the planet's description (from s1 and
; s2)
TextSeeds:
  DEFB $00,$00,$00,$00

; The name typed: the commander's (JAMESON) or a planet's (FindSystem),
; zero-ended
NameInput:
  DEFM "JAMESON   ",$00

; The name SystemName builds (up to eight letters, zero-ended)
NameBuffer:
  DEFM "TEMPNAME",$00

; The current system's name (LAVE)
CurrentName:
  DEFM "LAVE",$00,$00,$00,$00,$00

; The selected system's name
SelectedName:
  DEFM "LAVE",$00,$00,$00,$00,$00

; The distance to the selected system in 0.1 light years (FindNearest,
; JumpDistance)
JumpRange:
  DEFW $0000

; The selected system's economy, 0-7 (0 rich industrial, 7 poor agricultural)
Economy:
  DEFB $00

; Its government, 0-7 (0 anarchy, 7 corporate state)
Government:
  DEFB $00

; Its tech level less one, 0-14
TechLevel:
  DEFB $00

; Its population in 100 millions
Population:
  DEFB $00

; Its productivity in millions of credits
Productivity:
  DEFW $0000

; Two bytes no code reads (known from the code only)
SystemSpare:
  DEFB $00,$00

; FindSystem's count of the systems tried (256 then not found)
SystemCount:
  DEFB $00

; SystemName's next letter
NamePointer:
  DEFW $0000

; Screen 16 of ScreenTable, which nothing asks for: the galaxy number one more
; (wrapping at 8) and the galaxy's seeds twisted (unreachable; GalaxyJump does
; the same in the game)
;
; Used by the routine at NextGalaxyVector.
NextGalaxy:
  LD HL,CommanderRest+$0002
  LD A,(HL)
  INC A
  AND $07
  LD (HL),A
  LD HL,Seeds+$0002
  CALL TwistWord
  LD HL,Seeds+$0004
  CALL TwistWord
  LD HL,Seeds+$0006

; The two bytes at HL rotated left one bit each
;
; Used by the routine at NextGalaxy.
TwistWord:
  LD E,(HL)
  RLC E
  LD (HL),E
  INC HL
  LD D,(HL)
  RLC D
  LD (HL),D
  RET

; The system named in NameInput: walk the galaxy's 256 systems comparing
; NameBuffer; carry when none
;
; Found: the system becomes the selected one, the chart's cross is moved
; (EraseCross before and after SystemData), the name kept (KeepName) and the
; distance worked out (JumpDistanceNow). Called from the charts' PLANET NAME?
; prompt (PlanetNamePrompt), known from the code only.
FindSystem:
  CALL GalaxySeeds
  XOR A
  LD (SystemCount),A
FindSystemNext:
  CALL SaveSeeds
  CALL SystemName
  LD HL,NameInput
  LD DE,NameBuffer
FindSystemCompare:
  LD B,(HL)
  LD A,(DE)
  CP B
  JR NZ,FindSystemMiss
  AND A
  JR Z,FindSystemFound
  INC HL
  INC DE
  JR FindSystemCompare
FindSystemMiss:
  LD HL,SystemCount
  INC (HL)
  JP NZ,FindSystemNext
  SCF
  RET
FindSystemFound:
  CALL RestoreSeeds
  CALL ChartCross
  CALL SystemData
  CALL ChartCross
  CALL KeepName
  JP JumpDistanceNow

; FindNearest's smallest squared distance so far
BestDistance:
  DEFW $0000

; The system nearest the chart cursor becomes the selected one, with the cross
; redrawn on the charts
;
; Used by the routines at JumpKeys, GalaxyJump, ShowSelected and DataScreen.
FindNearest:
  LD A,(ViewIndex)
  CP $07
  JR C,FindNearestNow
  CP $09
  JR NC,FindNearestNow
  CALL ChartCross
  CALL FindNearestNow
  JP ChartCross

; Walk the 256 systems for the smallest dx^2 + (dy/2)^2 to the cursor ($D0BB,
; $D0BC), then its data, name and distance
;
; 10 runs in f1 and d1 (a jump target and the charts). The y difference is
; halved because the charts are drawn half as tall as wide; the root of the
; best sum times 4 is the distance in 0.1 light years (JumpDistance), as the
; BBC's.
FindNearestNow:
  CALL GalaxySeeds
  LD HL,$FFFF
  LD (BestDistance),HL
  LD B,$00
FindNearestLoop:
  PUSH BC
  LD A,(SystemSeeds+$0003)
  LD B,A
  LD A,(SystemSeeds+$0001)
  CALL SquaredDistance
  JR C,FindNearestStep
  EX DE,HL
  LD HL,(BestDistance)
  AND A
  SBC HL,DE
  JR C,FindNearestStep
  LD (BestDistance),DE
  CALL SaveSeeds
FindNearestStep:
  CALL NextSystem
  POP BC
  DJNZ FindNearestLoop
  LD HL,(BestDistance)
  AND A
  CALL JumpDistance
  CALL RestoreSeeds
  CALL SystemData
  CALL SystemName
  CALL KeepName
; This entry point is used by the routine at FindSystem.
JumpDistanceNow:
  LD A,(Seeds+$000B)
  LD B,A
  LD A,(Seeds+$0009)
  CALL SquaredDistance
  CALL JumpDistance
  AND A
  RET

; Four twists: the next system's seeds
;
; Used by the routines at FindNearestNow, GalacticChart, EachSystemCall and
; DrawSystemIcon.
NextSystem:
  LD B,$04
NextSystemLoop:
  PUSH BC
  CALL Twist
  POP BC
  DJNZ NextSystemLoop
  RET

; HL = (the cursor's x - B)^2 + ((the cursor's y - A) / 2)^2, B and A the
; system's x and y
;
; Used by the routine at FindNearestNow.
SquaredDistance:
  PUSH AF
  LD A,(ChartCursorX)
  CALL AbsDifference
  LD D,A
  CALL MultiplyDA
  POP BC
  PUSH HL
  LD A,(ChartCursorY)
  CALL AbsDifference
  SRL A
  LD D,A
  CALL MultiplyDA
  POP DE
  ADD HL,DE
  RET

; A = |A - B|
;
; Used by the routine at SquaredDistance.
AbsDifference:
  CP B
  JR NC,AbsDifferenceStore
  LD C,B
  LD B,A
  LD A,C
AbsDifferenceStore:
  SUB B
  RET

; JumpRange = 4 x the root of HL ($FFFF on a carry)
;
; Used by the routine at FindNearestNow.
JumpDistance:
  JR C,JumpDistanceFar
  JR JumpDistanceRoot
JumpDistanceFar:
  LD HL,$FFFF
JumpDistanceRoot:
  LD A,H
  OR L
  JR Z,JumpDistanceStore
  CALL SquareRootVector
  LD L,H
  LD H,$00
  ADD HL,HL
  ADD HL,HL
JumpDistanceStore:
  LD (JumpRange),HL
  RET

; HL = D x A (shift and add, eight steps)
;
; Used by the routines at SquaredDistance and SystemData.
MultiplyDA:
  LD E,$00
  LD B,$08
  LD HL,$0000
MultiplyDALoop:
  SRL D
  RR E
  RL A
  JR NC,MultiplyDANext
  ADD HL,DE
MultiplyDANext:
  DJNZ MultiplyDALoop
  RET

; The name of the system in SystemSeeds into NameBuffer: four pairs when bit 6
; of s0's low byte is set, else three
;
; Used by the routines at ControlFirstSystem, FindSystem, FindNearestNow and
; LabelSystem.
SystemName:
  LD HL,NameBuffer
  LD (NamePointer),HL
  LD B,$08
SystemNameLoop:
  LD (HL),$00
  INC HL
  DJNZ SystemNameLoop
  LD HL,(SystemSeeds)
  LD A,L
  AND $40
  AND A
  PUSH AF
  CALL NamePair
  CALL NamePair
  CALL NamePair
  POP AF
  JR Z,Twist

; One pair: s2's high byte AND $1F picks StdPairs entry (0: none), a "?" second
; letter left out; then a twist
;
; Used by the routine at SystemName.
NamePair:
  LD HL,(SystemSeeds+$0004)
  LD A,H
  AND $1F
  AND A
  JR Z,Twist
  LD HL,StdPairs
  ADD A,A
  LD D,$00
  LD E,A
  ADD HL,DE
  LD A,(HL)
  INC HL
  PUSH HL
  LD HL,(NamePointer)
  LD (HL),A
  INC HL
  EX DE,HL
  POP HL
  LD A,(HL)
  EX DE,HL
  CP $3F
  JR Z,NamePairNext
  LD (HL),A
  INC HL
NamePairNext:
  LD (NamePointer),HL

; s0, s1, s2 = s1, s2, s0 + s1 + s2
;
; Used by the routines at NextSystem, SystemName and NamePair.
Twist:
  LD HL,(SystemSeeds)
  LD DE,(SystemSeeds+$0002)
  ADD HL,DE
  EX DE,HL
  LD HL,(SystemSeeds+$0002)
  LD (SystemSeeds),HL
  LD HL,(SystemSeeds+$0004)
  LD (SystemSeeds+$0002),HL
  LD HL,(SystemSeeds+$0002)
  ADD HL,DE
  LD (SystemSeeds+$0004),HL
  RET

; NameBuffer becomes SelectedName
;
; Used by the routines at FindSystem and FindNearestNow.
KeepName:
  LD BC,$0008
  LD HL,NameBuffer
  LD DE,SelectedName
  LDIR
  RET

; The selected system from SystemSeeds: its seeds, the cursor on it, the
; economy, government, tech level, population and productivity
;
; As BBC Elite: the government is s1's bits 3-5, the economy s0's high bits 0-2
; (bit 1 set for governments 0 and 1); the tech level (7 - economy) + (s1 high
; AND 3) + government / 2 rounded up; the population 4 x tech + economy +
; government + 1; the productivity ((7 - economy) + 3) x (government + 4) x
; population x 8. 10 runs.
SystemData:
  LD HL,(SystemSeeds)
  LD (SelectedSeeds),HL
  LD A,H
  LD (ChartCursorY),A
  AND $07
  LD (Economy),A
  LD HL,(SystemSeeds+$0002)
  LD (SelectedSeeds+$0002),HL
  LD A,H
  LD (ChartCursorX),A
  LD A,L
  SRL A
  SRL A
  SRL A
  AND $07
  LD (Government),A
  SRL A
  JR NZ,SystemDataTech
  LD A,(Economy)
  OR $02
  LD (Economy),A
SystemDataTech:
  LD A,(Economy)
  XOR $07
  AND A
  LD B,A
  LD A,H
  AND $03
  ADD A,B
  LD B,A
  LD A,(Government)
  SRL A
  ADC A,B
  LD (TechLevel),A
  ADD A,A
  ADD A,A
  LD B,A
  LD A,(Government)
  LD C,A
  LD A,(Economy)
  ADC A,B
  ADC A,C
  ADC A,$01
  LD (Population),A
  LD A,(Economy)
  XOR $07
  ADC A,$03
  LD D,A
  LD A,(Government)
  ADC A,$04
  CALL MultiplyDA
  LD A,(Population)
  LD D,L
  CALL MultiplyDA
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD (Productivity),HL
  LD HL,(SystemSeeds+$0004)
  LD (SelectedSeeds+$0004),HL
  RET

; DISTANCE: and the jump range with its point and LIGHT YEARS, then a new line
; (nothing at 0)
;
; Used by the routines at ShowSelected and DataScreen.
PrintDistance:
  LD HL,(JumpRange)
  LD A,H
  OR L
  JR Z,PrintDistanceEnd
  LD A,$BF
  CALL PrintCodeColon
  LD A,$04
  LD (Messages+$0011),A
  LD HL,(JumpRange)
  SCF
  CALL PrintNumber
  CALL PrintInline
  DEFB $C3

; PrintDistanceEnd
;
; Used by the routine at PrintDistance.
PrintDistanceEnd:
  JP NewLine

; SystemSeeds = the galaxy's seeds: the walk starts at its first system
;
; Used by the routines at FindSystem, FindNearestNow, GalacticChart and
; EachSystemInWindow.
GalaxySeeds:
  LD HL,Seeds+$0002
  LD DE,SystemSeeds
  JR CopySeeds

; BestSeeds = SystemSeeds
;
; Used by the routines at FindSystem and FindNearestNow.
SaveSeeds:
  LD HL,SystemSeeds
  LD DE,BestSeeds
  JR CopySeeds

; SystemSeeds = BestSeeds
;
; Used by the routines at FindSystem and FindNearestNow.
RestoreSeeds:
  LD HL,BestSeeds
  LD DE,SystemSeeds

; Six bytes from HL to DE
;
; Used by the routines at GalaxySeeds and SaveSeeds.
CopySeeds:
  LD BC,$0006
  LDIR
  RET

; A new fluctuation byte ($D06A) from StarSeed, then MakeMarket
;
; Used by the routine at JumpArrive.
NewMarket:
  LD A,(StarSeed)
  LD (CommanderRest+$0007),A

; Each commodity's price ($E1BD) and the station's stock ($D09E) from
; Commodities, the economy and the fluctuation
;
; For each of the 17 entries (base price, factor, base quantity, mask): the
; product = economy x (factor AND $1F); the stock = base quantity +
; (fluctuation AND mask) less the product and one for a positive factor (INC A
; / NEG), plus the product for a negative one, 0 when negative, AND $3F; the
; price = (base price + (fluctuation AND mask) plus or minus the product) x 4,
; in tenths of a credit. The last commodity's stock (alien items) is forced to
; 0. 4 runs (d1 and the arrivals); tools/galaxy.py --market reproduces Diso's
; 17 prices and stocks of f1 exactly. NewGame turns the stock's store ($E1AE,
; LD (HL),A) into a NOP for its call, so the first market keeps the stock of
; the commander record.
MakeMarket:
  LD HL,MarketStock
  LD DE,Prices
  EXX
  LD HL,Commodities
  LD B,$11
MakeMarketLoop:
  PUSH BC
  LD E,(HL)
  INC HL
  LD A,(HL)
  LD D,A
  PUSH DE
  AND $1F
  JR Z,MakeMarketQuantity
  LD B,A
  LD A,(Economy)
  LD C,A
  XOR A
MakeMarketLoop2:
  ADD A,C
  DJNZ MakeMarketLoop2
MakeMarketQuantity:
  LD E,A
  INC HL
  LD B,(HL)
  INC HL
  LD C,(HL)
  INC HL
  LD A,(CommanderRest+$0007)
  AND C
  ADD A,B
  LD B,A
  LD A,E
  BIT 7,D
  JR NZ,MakeMarketStock
  INC A
  NEG
MakeMarketStock:
  ADD A,B
  BIT 7,A
  JR Z,MakeMarketStockStore
  XOR A
MakeMarketStockStore:
  AND $3F
  LD B,E
  POP DE
  PUSH AF
  LD A,(CommanderRest+$0007)
  AND C
  ADD A,E
  LD E,$00
  RL E
  LD C,A
  LD A,B
  BIT 7,D
  JR Z,MakeMarketPositive
  LD D,A
  LD A,C
  SUB D
  JR MakeMarketPrice
MakeMarketPositive:
  ADD A,C
  JR NC,MakeMarketPrice
  INC E
MakeMarketPrice:
  LD B,E
  ADD A,A
  RL B
  ADD A,A
  RL B
  LD C,A
  PUSH BC
  EXX
  POP BC
  LD A,C
  LD (DE),A
  INC DE
  LD A,B
  LD (DE),A
  INC DE
  POP AF
  LD (HL),A
  INC HL
  EXX
  POP BC
  DJNZ MakeMarketLoop
  LD HL,MarketStock+$0010
  LD (HL),B
  RET

; Two bytes before Prices: the market screens' pointers start here and step 2
; first
PriceBase:
  DEFB $00,$00

; The 17 commodities' prices in tenths of a credit (MakeMarket)
Prices:
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
  DEFW $0000

; The market screens' row: the commodity (0-16), which also picks the unit (t,
; kg, g)
MarketItem:
  DEFB $00

; The trading pages' pointer into the hold ($D06B on), stepped first
HoldPointer:
  DEFW $0000

; Their pointer into Prices
PricePointer:
  DEFW $0000

; Their pointer into MarketStock (buying) or the hold, stepped first
StockPointer:
  DEFW $0000

; The text position SaveCursor keeps
SavedCursor:
  DEFW $0000
