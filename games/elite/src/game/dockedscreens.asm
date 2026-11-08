; --------------------------------------------------------------------------------------------------------------------
; dockedscreens.asm: The docked screens of ScreenTable: the galactic and the short range charts, the data on a system, the market prices, the status and the inventory
;
; The six letter keys draw these pages (SelectView through CallScreen): I the galactic chart, O the short range chart,
; P the data on the selected system, K the market prices, L the commander's status, ENTER the inventory. Each page is
; text through PrintCode / PrintOther with the colour bands of ColourBands; the two charts plot instead: the galactic
; chart a dot for each of the 256 systems (through the ROM's PIXEL-ADD $22AA and a SET patched to the dot's bit), the
; short range chart an icon for each system within 19 x and 34 y of the current one and its name on a free text row.
;
; Witnesses: the galactic chart 1 run, the short range chart 3, the data screen 1 (the data on Lave), the market
; prices 1, the status 3 (d1); the inventory 3 runs in t1, 1 in dk, 2 in m1.
; --------------------------------------------------------------------------------------------------------------------

; Screen I: the 256 systems as dots, the current system's cross (16) and its
; fuel circle, the cursor's cross (10), GALACTIC CHART
;
; The chart is the galaxy at half height: a system's dot is at (x, y / 2 + 24),
; x = s1 high, y = s0 high, so rows 24-151 hold it (CrossTop 24, CrossBottom
; 152). The fuel circle's radius is the fuel / 4 (7.0 light years = 70 tenths:
; 17 pixels). The text rows 0-2 and 19-23 are cleared (ClearBlock), the bottom
; five rows coloured $17 under a rule at $5060 for the cursor's name and
; distance. 1 run.
GalacticChart:
  CALL ClearScreen
  LD A,$18
  LD (CrossTop),A
  LD A,$98
  LD (CrossBottom),A
  LD A,$10
  LD (CrossSize),A
  LD A,(Seeds+$000B)
  LD (CrossX),A
  LD A,(Seeds+$0009)
  SRL A
  ADD A,$18
  LD (CrossY),A
  CALL DrawCross
  LD A,(Fuel)
  SRL A
  SRL A
  LD (ChartRadius),A
  CALL DrawChartCircleVector
  LD HL,$4060
  LD A,$03
  CALL ClearBlock
  LD HL,$5100
  LD A,$05
  CALL ClearBlock
  CALL DrawFrame
  LD A,$0A
  LD (CrossSize),A
  CALL ChartCross
  LD A,$C7
  CALL ScreenHeading
  LD A,$17
  LD HL,$5A60
  LD B,$A0
  CALL FillBytes
  LD HL,$5060
  CALL FillRule
  CALL GalaxySeeds
  LD B,$00
GalacticChartLoop:
  PUSH BC
  CALL PlotSystem
  CALL NextSystem
  POP BC
  DJNZ GalacticChartLoop
  RET

; A x 32 bytes before HL cleared on each of the cell's eight pixel rows: SP at
; HL and PUSHes of zero, the interrupts off
;
; HL = $4060, A = 3 clears the character rows 0-2; HL = $5100, A = 5 the rows
; 19-23. PUSH writes below SP, so HL is the block's end. 2 runs.
ClearBlock:
  DI
  LD (ClearBlockStack),SP
  LD (ClearBlockCount),A
  LD C,$08
  LD DE,$0000
ClearBlockRow:
  LD SP,HL
  LD A,(ClearBlockCount)
ClearBlockCells:
  LD B,$10
ClearBlockPush:
  PUSH DE
  DJNZ ClearBlockPush
  DEC A
  JR NZ,ClearBlockCells
  INC H
  DEC C
  JR NZ,ClearBlockRow
  LD SP,(ClearBlockStack)
  EI
  RET

; ClearBlock's A (the rows of 32 bytes)
ClearBlockCount:
  DEFB $00

; ClearBlock's saved SP
ClearBlockStack:
  DEFW $0000

; The dot of the system in SystemSeeds at (x, y / 2 + 24): PIXEL-ADD $22AA, its
; bit patched into the SET at $EC35
;
; PIXEL-ADD counts y from the bottom, so B = (y / 2 XOR 127) + 24 is 175 less
; the row. It returns the bit's place in the byte in A (0 the left); XOR 7,
; times 8, OR $C0 is the second byte of SET n,B, written into the instruction.
; 256 runs.
PlotSystem:
  LD A,(SystemSeeds+$0001)
  SRL A
  XOR $7F
  ADD A,$18
  LD B,A
  LD A,(SystemSeeds+$0003)
  LD C,A
  CALL $22AA
  XOR $07
  SLA A
  SLA A
  SLA A
  OR $C0
  LD DE,PlotSystem+$0022
  LD (DE),A
  LD B,$00
  SET 1,B
  LD A,(HL)
  XOR B
  LD (HL),A
  RET

; A = 0: the window's low edge when cx - 19 or cy - 34 went below 0
;
; Used by the routine at ShortRangeChart.
ClampLow:
  XOR A
  RET

; A = 255: its high edge when cx + 19 or cy + 34 passed 255
;
; Used by the routine at ShortRangeChart.
ClampHigh:
  LD A,$FF
  RET

; The short range chart's text rows that hold a name (255), one byte a row
RowsUsed:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Screen O: SHORT RANGE CHART, the systems near the current one as icons with
; their names, the current system's cross (24), the fuel circle, the cursor's
; cross (16)
;
; The window is the current system's x ± 19 and y ± 34, written into the four
; CP operands of EachSystemInWindow ($ECDF, $ECE3, $ECEA, $ECEE). A system is 4
; pixels a unit of x and 2 of y from the centre (97, 96); the fuel circle's
; radius is the fuel (70 pixels for 7.0 light years). Two walks: the icons
; (DrawSystemIcon) then the names (LabelSystem), so a name never lands under an
; icon drawn after it. 3 runs.
ShortRangeChart:
  XOR A
  LD B,$18
  LD HL,RowsUsed
ShortRangeChartClear:
  LD (HL),A
  INC HL
  DJNZ ShortRangeChartClear
  CALL ClearScreen
  LD A,$BE
  CALL ScreenHeading
  CALL FillAttrRow
  LD A,(Seeds+$000B)
  SUB $13
  CALL C,ClampLow
  LD (EachSystemLoop+$0005),A
  LD A,(Seeds+$000B)
  ADD A,$13
  CALL C,ClampHigh
  LD (EachSystemLoop+$0009),A
  LD A,(Seeds+$0009)
  SUB $22
  CALL C,ClampLow
  LD (EachSystemLoop+$0010),A
  LD A,(Seeds+$0009)
  ADD A,$22
  CALL C,ClampHigh
  LD (EachSystemLoop+$0014),A
  LD A,$18
  LD (CrossTop),A
  LD A,$A7
  LD (CrossBottom),A
  LD A,$18
  LD (CrossSize),A
  LD A,$61
  LD (CrossX),A
  LD A,$60
  LD (CrossY),A
  CALL DrawCross
  LD HL,DrawSystemIcon
  CALL EachSystemInWindow
  LD HL,LabelSystem
  CALL EachSystemInWindow
  LD A,(Fuel)
  LD (ChartRadius),A
  CALL DrawChartCircleVector
  LD A,$10
  LD (CrossSize),A
  JP ChartCross

; The 256 systems: those inside the window (x and y each low <= v < high)
; handed to the routine at HL (the CALL at $ECF1 patched)
;
; 6 runs (two a chart), 60 systems handed on: 10 a chart around Lave.
EachSystemInWindow:
  LD (EachSystemCall+$0001),HL
  CALL GalaxySeeds
  LD B,$00
; This entry point is used by the routine at EachSystemCall.
EachSystemLoop:
  PUSH BC
  LD A,(SystemSeeds+$0003)
  CP $00
  JR C,EachSystemSkip
  CP $00
  JR NC,EachSystemSkip
  LD A,(SystemSeeds+$0001)
  CP $00
  JR C,EachSystemSkip
  CP $00
  JR NC,EachSystemSkip

; EachSystemCall
EachSystemCall:
  CALL EachSystemCall     ; CALL patched to DrawSystemIcon or LabelSystem (they
                          ; step to the next system themselves)
  JR EachSystemNext
; This entry point is used by the routine at EachSystemInWindow.
EachSystemSkip:
  CALL NextSystem
EachSystemNext:
  POP BC
  DJNZ EachSystemLoop
  RET

; HL = the screen address of the system's icon (its top left at x 94 + 4 dx,
; row 93 + 2 dy from the current system), A its bit, B and C the coordinates
;
; dx and dy are the system's x and y less the current system's; the icon is 8 x
; 8, so its centre is the cross's (97, 96) for dx = dy = 0. 60 runs.
SystemPixel:
  LD C,$61
  LD A,(Seeds+$000B)
  LD B,A
  LD A,(SystemSeeds+$0003)
  SUB B
  SLA A
  SLA A
  ADD A,C
  SUB $03
  LD C,A
  LD D,$60
  LD A,(Seeds+$0009)
  LD B,A
  LD A,(SystemSeeds+$0001)
  SUB B
  SLA A
  NEG
  ADD A,D
  SUB $0E
  LD B,A
  PUSH BC
  CALL $22AA
  POP BC
  RET

; One of the four ChartIcons (s2 high AND $18: 8 bytes each) XORed in at the
; system's place, shifted A bits across two bytes, then the next system
;
; The shift A is written into the LD B at $ED47. The icon's eight rows step
; down the screen's thirds as NextRowDown does. 30 runs.
DrawSystemIcon:
  CALL SystemPixel
  LD (DrawSystemIconRow+$000B),A
  LD DE,ChartIcons
  LD A,(SystemSeeds+$0005)
  AND $18
  ADD A,E
  LD E,A
  JR NC,DrawSystemIconRows
  INC D
DrawSystemIconRows:
  LD B,$08
DrawSystemIconRow:
  PUSH BC
  LD A,(DrawSystemIconRow+$000B)
  AND A
  LD A,(DE)
  LD C,$00
  JR Z,DrawSystemIconXor
  LD B,$01
DrawSystemIconShift:
  SRL A
  RR C
  DJNZ DrawSystemIconShift
DrawSystemIconXor:
  LD B,A
  LD A,(HL)
  XOR B
  LD (HL),A
  INC HL
  LD A,(HL)
  XOR C
  LD (HL),A
  DEC HL
  LD A,H
  INC A
  AND $07
  JR NZ,DrawSystemIconDown
  LD A,H
  AND $F8
  LD H,A
  LD A,$20
  ADD A,L
  LD L,A
  JR NC,DrawSystemIconNext
  LD A,$08
  ADD A,H
  LD H,A
  JR DrawSystemIconNext
DrawSystemIconDown:
  INC H
DrawSystemIconNext:
  INC DE
  POP BC
  DJNZ DrawSystemIconRow
  JP NextSystem

; Two bytes no code reads (known from the code only)
LabelSpare:
  DEFB $00,$00

; LabelSystem writes 8 - the name's length here, and no code reads it (known
; from the code only)
LabelLength:
  DEFB $00

; The system's name at the text cell right of its icon: its own row, else the
; row above (from row 3), else the row below (to row 22), else none
;
; The column is the icon's x / 8 + 1, the row 22 less the icon's B / 8 rounded
; up. 30 runs: the ten names around Lave (Diso, Leesti, Orrere, Reorte,
; Riedquat, Uszaa, Zaonce, Tionisla, Orerve and Lave itself) on each of three
; charts.
LabelSystem:
  CALL SystemPixel
  PUSH BC
  CALL SystemName
  LD BC,$0009
  LD HL,NameBuffer
  XOR A
  CPIR
  LD A,C
  XOR $07
  INC A
  LD (LabelLength),A
  POP BC
  LD A,C
  RRA
  RRA
  RRA
  AND $1F
  INC A
  LD (TextColumn),A
  LD A,B
  SRL A
  SRL A
  SRL A
  JR NC,LabelSystemRow
  INC A
LabelSystemRow:
  NEG
  ADD A,$16
  LD (TextRow),A
  CALL PrintIfRowFree
  RET C
  LD HL,TextRow
  DEC (HL)
  LD A,(HL)
  CP $03
  JR C,LabelSystemBelow
  CALL PrintIfRowFree
  RET C
LabelSystemBelow:
  LD HL,TextRow
  INC (HL)
  INC (HL)
  LD A,(HL)
  CP $17
  RET NC

; The name in NameBuffer at TextRow unless RowsUsed has it: the row marked and
; the name printed (carry), else no carry
;
; 39 runs for 30 names: nine names took a second row.
PrintIfRowFree:
  LD A,(TextRow)
  LD HL,RowsUsed
  CALL AddAToHL
  LD A,(HL)
  AND A
  RET NZ
  LD A,$FF
  LD (HL),A
  LD A,$01
  LD (PrintCapital),A
  LD HL,NameBuffer
  JP PrintCodes

; Screen P: DATA ON <system> for the system nearest the cursor: the distance,
; the economy, government, tech level, population and species, productivity,
; radius, and its description
;
; The species is in brackets after the population; the productivity has " M
; CR", the radius " km" (PrintUnit with MarketItem 17). The description is
; other token 5 (TextRandom from TextSeeds = s1, s2), or IS RESISTING A THARGON
; INVASION (other $DE) for the galaxy's first system while a Thargoid mission
; is on (MissionState not 0). 1 run (d1, the data on Lave: Rich Agricultural,
; Dictatorship, Tech.Level 5, Population 2.5 Billion (Human Colonials), Gross
; Productivity 7000 M CR, Average Radius 4116 km).
DataScreen:
  CALL FindNearest
  CALL ClearPageText
  LD DE,DataBands
  CALL ColourBands
  LD A,$A3
  CALL PageTitle
  LD A,$03
  CALL SetRow
  CALL PrintDistance
  CALL NewLine
  CALL PrintEconomy
  LD A,$A2
  CALL PrintCodeColon
  LD A,$B1
  LD B,A
  LD A,(Government)
  ADD A,B
  CALL PrintCodeGap
  LD A,$C4
  CALL PrintCodeColon
  LD A,$03
  LD (Messages+$0011),A
  LD A,(TechLevel)
  INC A
  CALL PrintByte
  CALL NewLineGap
  LD A,$D7
  CALL PrintOtherColon
  LD A,(Population)
  CALL PrintByteDot
  LD A,$C6
  CALL PrintCodeGap
  CALL PrintInline
  DEFB $28
  CALL PrintSpecies
  CALL PrintInline
  DEFB $53
  LD A,$29
  CALL PrintCodeGap
  LD A,$6F
  CALL PrintOtherColon
  LD HL,(Productivity)
  LD A,$05
  LD (Messages+$0011),A
  AND A
  CALL PrintNumber
  CALL PrintInline
  DEFB $20
  CALL PrintInline
  DEFB $4D
  LD A,$E2
  CALL PrintCapitals
  CALL NewLineGap
  LD A,$FA
  CALL PrintCodeColon
  CALL PrintRadius
  CALL PrintInline
  DEFB $20
  LD A,$11
  LD (MarketItem),A
  CALL PrintUnit
  CALL NewLineGap
  LD A,(MissionState)
  AND A
  JR Z,DataScreenDescription
  LD HL,SelectedSeeds
  CALL IsFirstSystem
  JR C,DataScreenDescription
  LD A,$DE
  JP PrintOther
DataScreenDescription:
  LD HL,(SelectedSeeds+$0002)
  LD (TextSeeds),HL
  LD HL,(SelectedSeeds+$0004)
  LD (TextSeeds+$0002),HL
  LD A,$05
  JP PrintOther

; Standard code A, a new line and an empty line
;
; Used by the routines at DataScreen, PrintEconomy and StatusScreen.
PrintCodeGap:
  CALL PrintCodeLine
  JR NewLineGapSecond

; A new line and an empty line
;
; Used by the routines at EquipShip and DataScreen.
NewLineGap:
  CALL NewLine

; NewLineGapSecond
;
; Used by the routine at PrintCodeGap.
NewLineGapSecond:
  JP NewLine

; ECONOMY: and RICH / AVERAGE / POOR / MAINLY (codes $AA-$AD) and INDUSTRIAL or
; AGRICULTURAL (economy / 4: codes $A8, $A9)
;
; Economy 0-3 take $AA + e, 5-7 $AA + e - 5, 4 MAINLY: 0 rich, 1 average, 2
; poor, 3 mainly industrial, 4 mainly, 5 rich, 6 average, 7 poor agricultural,
; as the BBC's.
PrintEconomy:
  LD A,$70
  CALL PrintOtherColon
  LD A,(Economy)
  CP $04
  JR Z,PrintEconomyMainly
  JR C,PrintEconomyKind
  SUB $05
PrintEconomyKind:
  ADD A,$AA
  CALL PrintCode
PrintEconomyType:
  LD A,(Economy)
  SRL A
  SRL A
  ADD A,$A8
  JR PrintCodeGap
PrintEconomyMainly:
  CALL PrintInline
  DEFB $AD
  JR PrintEconomyType

; The system's people: HUMAN COLONIALS (s2 low below $80), else up to three
; adjectives and the kind, as the BBC's
;
; s2 high bits 2-4 below 3: LARGE, FIERCE, SMALL (codes $E3-$E5); bits 5-7
; below 6: GREEN, RED, YELLOW, BLUE, BLACK, HARMLESS ($E6-$EB); (s0 high XOR s1
; high) AND 7 below 6: SLIMY, BUG-EYED, HORNED, BONY, FAT, FURRY ($EC-$F1); the
; kind ((that + s2 high AND 3) AND 7): RODENTS to INSECTS ($F2-$F9). Lave's
; people: s2 low below $80.
PrintSpecies:
  LD HL,(SelectedSeeds+$0004)
  LD A,L
  CP $80
  JR NC,PrintSpeciesAlien
  LD A,$BC
  JR PrintSpeciesEnd
PrintSpeciesAlien:
  LD A,H
  SRL A
  SRL A
  PUSH AF
  AND $07
  CP $03
  JR NC,PrintSpeciesColour
  ADD A,$E3
  CALL PrintCodeSpace
PrintSpeciesColour:
  POP AF
  SRL A
  SRL A
  SRL A
  CP $06
  JR NC,PrintSpeciesLook
  ADD A,$E6
  CALL PrintCodeSpace
PrintSpeciesLook:
  LD HL,(SelectedSeeds)
  LD A,H
  LD B,A
  LD HL,(SelectedSeeds+$0002)
  LD A,H
  XOR B
  AND $07
  PUSH AF
  CP $06
  JR NC,PrintSpeciesKind
  ADD A,$EC
  CALL PrintCodeSpace
PrintSpeciesKind:
  LD HL,(SelectedSeeds+$0004)
  LD A,H
  AND $03
  LD B,A
  POP AF
  ADD A,B
  AND $07
  ADD A,$F2
PrintSpeciesEnd:
  JP PrintCode

; The radius in km: ((s2 high AND 15) + 11) x 256 + s1 high, five digits
;
; Used by the routine at DataScreen.
PrintRadius:
  LD HL,(SelectedSeeds+$0004)
  LD A,H
  AND $0F
  ADD A,$0B
  LD HL,(SelectedSeeds+$0002)
  LD L,H
  LD H,A
  LD A,$05
  LD (Messages+$0011),A
  AND A
  JP PrintNumber

; No carry when the selected system is the galaxy's first (its six seeds the
; galaxy's)
;
; m2 ran it once, from JumpTick through MissionTriggers at frame 5183: the jump
; to Ausis, galaxy 2's first system, made MissionState 3 into 4 (the Thargoid
; base).
IsFirstSystem:
  LD DE,Seeds+$0002
  LD B,$06
IsFirstSystemLoop:
  LD A,(DE)
  CP (HL)
  JR NZ,IsFirstSystemNo
  INC DE
  INC HL
  DJNZ IsFirstSystemLoop
  AND A
  RET
IsFirstSystemNo:
  SCF
  RET

; Screen K: <system> MARKET PRICES, the heading line (code $FF) and the 17
; commodities (MarketRow); in witch space only the heading
;
; 1 run (the Lave market of d1).
MarketPrices:
  CALL FirearmsPrice
  CALL ClearPageText
  LD A,$A7
  CALL PageTitle
  LD HL,$0310
  LD (TextColumn),HL
  LD A,$FF
  CALL PrintCodeLine
  LD DE,MarketBands2
  CALL ColourBands
  LD A,(WitchSpace)
  AND A
  RET NZ
  XOR A
  LD (MarketItem),A
  LD HL,PriceBase
  LD (PricePointer),HL
  LD HL,Seeds+$000F
  LD (StockPointer),HL
MarketPricesLoop:
  CALL MarketRow
  LD HL,MarketItem
  INC (HL)
  LD A,(HL)
  CP $11
  JR C,MarketPricesLoop
  RET

; The view the status page's laser line is at (0-3)
StatusLaserView:
  DEFB $00

; Screen L: COMMANDER <name>, the present and the hyperspace systems, the fuel,
; the cash, the legal status, the rating, the equipment and the lasers
;
; The legal status: CLEAN (0), OFFENDER (1-49), FUGITIVE (50 and more). The
; rating: while the combat score's top byte is 0 its middle byte against 8, 16,
; 32, 64, 128 (HARMLESS, MOSTLY HARMLESS, POOR, AVERAGE, ABOVE AVERAGE: the
; first threshold at or above it, COMPETENT past 128), else the top byte
; against 2, 10, 25 (COMPETENT, DANGEROUS, DEADLY), ELITE past 25
; (RatingScores). The equipment lines: LARGE CARGO BAY, FUEL SCOOPS, the E.C.M.
; SYSTEM JAMMER (MissionFlags bit 7) or E.C.M. SYSTEM, ENERGY BOMB, ENERGY
; UNIT, DOCKING COMPUTERS, GALACTIC HYPERSPACE, the four lasers (FRONT PULSE
; LASER...), CLOAKING DEVICE (bit 6). The escape pod ($D089) has no line. 3
; runs.
StatusScreen:
  LD A,$0B
  LD (ViewIndex),A
  CALL ClearPageText
  CALL ConditionLightVector
  LD DE,StatusBands
  CALL ColourBands
  CALL ColumnInline
  DEFB $06
  CALL PrintInline
  DEFB $7E
  LD A,$04
  CALL SetRow
  LD A,$02
  CALL StatusSystem
  LD A,$03
  CALL StatusSystem
  LD A,$06
  CALL SetRow
  CALL PrintInline
  DEFB $05
  CALL PrintInline
  DEFB $07
  LD A,$71
  CALL PrintOtherColon
  CALL PrintInline
  DEFB $20
  LD B,$12
  LD A,(LegalStatus)
  AND A
  JR Z,StatusLegal
  CP $32
  JR C,StatusOffender
  INC B
StatusOffender:
  INC B
StatusLegal:
  LD A,B
  CALL PrintCodeLine
  LD A,$72
  CALL PrintOtherColon
  CALL PrintInline
  DEFB $20
  LD HL,CombatScore+$0002
  LD A,(HL)
  AND A
  JR NZ,StatusRatingHigh
  DEC HL
  LD DE,RatingScores
  LD B,$15
  JR StatusRatingLoop
StatusRatingHigh:
  LD DE,RatingHigh
  LD B,$1A
StatusRatingLoop:
  LD A,(DE)
  CP (HL)
  JR NC,StatusRating
  INC B
  INC DE
  JR StatusRatingLoop
StatusRating:
  LD A,B
  CALL PrintCodeGap
  CALL PrintInline
  DEFB $11
  CALL EquipmentLine
  LD A,(Equipment)
  CALL PrintIfFitted
  DEFB $6B
  LD A,(Equipment+$0004)
  CALL PrintIfFitted
  DEFB $6F
  LD A,(MissionFlags)
  BIT 7,A
  JR Z,StatusEcm
  LD A,$CF
  CALL PrintOther
  CALL EquipmentLine
  JR StatusBomb
StatusEcm:
  LD A,(Equipment+$0001)
  CALL PrintIfFitted
  DEFB $6C

; StatusBomb
;
; Used by the routine at StatusScreen.
StatusBomb:
  LD A,(Equipment+$0006)
  CALL PrintIfFitted
  DEFB $71
  LD A,(Equipment+$0007)
  CALL PrintIfFitted
  DEFB $72
  LD A,(Equipment+$0008)
  CALL PrintIfFitted
  DEFB $73
  LD A,(Equipment+$0009)
  CALL PrintIfFitted
  DEFB $74
  LD A,$FF
  LD (StatusLaserView),A
  LD HL,LaserMounts
  LD B,$04
StatusLasersLoop:
  PUSH BC
  CALL PrintLaser
  POP BC
  DJNZ StatusLasersLoop
  LD A,(MissionFlags)
  BIT 6,A
  JR Z,StatusFrame
  CALL PrintInline
  DEFB $7D
StatusFrame:
  JP DrawFrame

; A not 0: the code byte after the CALL on its own line at column 5; the return
; past the byte either way
;
; 21 runs: seven equipment lines a status page.
PrintIfFitted:
  POP HL
  LD B,(HL)
  INC HL
  PUSH HL
  AND A
  RET Z
  LD A,B
  CALL PrintCode

; A new line, column 5
;
; Used by the routines at StatusScreen and PrintLaser.
EquipmentLine:
  CALL NewLine
  LD A,$05
  JP SetColumn

; The laser of the next view (StatusLaserView one more): FRONT / REAR / LEFT /
; RIGHT and PULSE / BEAM / MILITARY / MINING LASER; nothing for none
;
; Codes $60 + view, then $66 + kind for 1-2 (PULSE LASER $67, BEAM LASER $68),
; $72 + kind for 3-4 (MILITARY $75, MINING $76). 12 runs: four a page.
PrintLaser:
  LD A,(StatusLaserView)
  INC A
  LD (StatusLaserView),A
  LD A,(HL)
  INC HL
  AND A
  RET Z
  PUSH HL
  PUSH AF
  LD A,(StatusLaserView)
  ADD A,$60
  CALL PrintCodeSpace
  POP AF
  CP $03
  JR C,PrintLaserPulse
  LD B,$72
  JR PrintLaserName
PrintLaserPulse:
  LD B,$66
PrintLaserName:
  ADD A,B
  CALL PrintCode
  POP HL
  JR EquipmentLine

; Column 21, ":" and standard control A (2 the current system, 3 the selected
; one), a new line
;
; Used by the routine at StatusScreen.
StatusSystem:
  EX AF,AF'
  CALL ColumnInline
  DEFB $15
  CALL PrintInline
  DEFB $3A
  EX AF,AF'
  JP PrintCodeLine

; The rating's thresholds for the score's middle byte (8, 16, 32, 64, 128, end
; $FF)
RatingScores:
  DEFB $08,$10,$20,$40,$80,$FF

; Those for its top byte (2, 10, 25, end $FF)
RatingHigh:
  DEFB $02,$0A,$19,$FF

; Screen ENTER: INVENTORY, the fuel, the cash, LARGE CARGO BAY (its line
; coloured), REFUGEES (MissionFlags bit 5), the hold (HoldRow for each
; commodity)
;
; t1 (3 runs from frame 848), dk and m1 showed it.
InventoryScreen:
  LD A,$0C
  LD (ViewIndex),A
  CALL ClearPageText
  LD A,$A4
  CALL PageTitle
  LD DE,InventoryBands
  CALL ColourBands
  LD A,$03
  CALL SetRow
  CALL PrintInline
  DEFB $05
  LD A,$07
  CALL PrintCodeLine
  LD A,(Equipment)
  AND A
  JR Z,InventoryRefugees
  LD HL,$58C1
  LD A,$05
  CALL FillAttrs30
  CALL PrintInline
  DEFB $6B
InventoryRefugees:
  CALL NewLine
  LD A,(MissionFlags)
  BIT 5,A
  JR Z,InventoryHold
  LD A,$0C
  CALL PrintOther
  CALL NewLine
InventoryHold:
  XOR A
  LD (MarketItem),A
  LD HL,CommanderRest+$0007
  LD (HoldPointer),HL
InventoryHoldLoop:
  CALL HoldRow
  CALL NC,NewLine
  LD HL,MarketItem
  INC (HL)
  LD A,(HL)
  CP $11
  JR C,InventoryHoldLoop
  RET
