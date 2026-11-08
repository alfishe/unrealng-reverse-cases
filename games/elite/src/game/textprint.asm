; --------------------------------------------------------------------------------------------------------------------
; textprint.asm: Numbers, cash, the two token sets, the character printer, rules and bars, the random synonyms
;
; Two interpreters print the game's texts (tools/tokens.py decodes both). PrintCode $D425, the standard set: below $0E
; a control code (TokenControl), $0E-$1F tokens $80-$91, $20-$5F characters, $60-$7F tokens 0-$1F, $80-$9F two-letter
; pairs ($FDB3), $A0 and up tokens 0-$5F; token n is the n-th zero-ended string of the table at TokenTable ($F11A).
; PrintOther $D45F, the other set (the table at $F11C): string n-1 for token n, its codes below $20 controls
; (OtherControl), up to $5A characters, $5B-$80 a random pick of one of five tokens (RandomToken, the synonym rows at
; $D5F5), $81-$D6 other tokens, $D7 and up pairs ($FD99). Both print through PrintChar, which keeps the case (capitals
; at a word's start, the rest small, by PrintCase) and either plots or buffers the letter for the justified text.
;
; A letter is plotted from the font at $5D70 into the screen at (TextColumn, TextRow) with XOR (or over, by the byte
; at $D548); the column wraps at 32.
; --------------------------------------------------------------------------------------------------------------------

; The number being printed, less the digits printed so far
NumberLeft:
  DEFW $0000

; Print A as a number with one decimal place
;
; Used by the routines at ControlFuelValue and DataScreen.
PrintByteDot:
  SCF
  JR PrintByteNow

; Print A as a number
;
; Used by the routines at ControlGalaxy, JumpTick, MarketRow, HoldRow,
; EquipShip and DataScreen.
PrintByte:
  AND A

; PrintByteNow
;
; Used by the routine at PrintByteDot.
PrintByteNow:
  LD H,$00
  LD L,A

; Print HL in decimal (carry: the last digit after a point), padded to the
; width $D0CE
;
; Five digits by repeated subtraction (PrintDigit) from 10000 down, the leading
; zeros left out ($D0CC on until a non-zero digit). 1512 runs: the status, the
; market and the charts' numbers.
PrintNumber:
  PUSH AF
  PUSH HL
  CALL PadNumber
  POP HL
  LD A,$01
  LD (Messages+$000F),A
  LD (NumberLeft),HL
  LD DE,$2710
  CALL PrintDigit
  LD DE,$03E8
  CALL PrintDigit
  LD DE,$0064
  CALL PrintDigit
  LD DE,$000A
  CALL PrintDigit
PrintNumberLast:
  POP AF
  JR NC,PrintNumberUnits
  LD A,(Messages+$000F)
  AND A
  JP Z,PrintNumberPoint
PrintNumberZero:
  XOR A
  CALL PrintDigitChar
PrintNumberPoint:
  CALL PrintInline

; The "." printed by PrintNumberPoint's CALL PrintInline
PointCode:
  DEFB $2E

; The last digit
;
; Used by the routine at PrintNumber.
PrintNumberUnits:
  LD HL,(NumberLeft)
  LD A,L
  CALL PrintDigitChar
  XOR A
  LD (Messages+$0011),A
  INC A
  LD (Messages+$000F),A
  RET

; Print the cash: the thousands ($D066) and the rest ($D068, tenths), with the
; point
;
; Used by the routine at ControlCash.
PrintCash:
  LD HL,(CommanderRest+$0003)
  LD DE,(CommanderRest+$0005)

; PrintCashNow
;
; Used by the routine at EquipShip.
PrintCashNow:
  PUSH DE
  LD A,L
  OR H
  JR Z,PrintCashSmall
  LD A,$03
  LD (Messages+$0011),A
  AND A
  CALL PrintNumber
  XOR A
  LD (Messages+$000F),A
  LD A,$04
  LD (Messages+$0011),A
  JR PrintCashRest
PrintCashSmall:
  LD A,$07
  LD (Messages+$0011),A
PrintCashRest:
  POP HL
  SCF
  JP PrintNumber

; One digit: how many DE fit in NumberLeft, printed unless a leading zero
;
; Used by the routine at PrintNumber.
PrintDigit:
  LD HL,(NumberLeft)
  XOR A
  AND A
PrintDigitCount:
  SBC HL,DE
  JP C,PrintDigitDone
  INC A
  JR PrintDigitCount
PrintDigitDone:
  ADD HL,DE
  LD (NumberLeft),HL
  AND A
  JR Z,PrintDigitSkip
  LD B,A
  XOR A
  LD (Messages+$000F),A
  LD A,B

; Print digit A
;
; Used by the routines at PrintNumber and PrintNumberUnits.
PrintDigitChar:
  ADD A,$30
  JP PrintCode
; This entry point is used by the routine at PrintDigit.
PrintDigitSkip:
  LD A,(Messages+$000F)
  AND A
  JR Z,PrintDigitChar
  RET

; Print the spaces (or zeros) that bring the number to the width
;
; Used by the routine at PrintNumber.
PadNumber:
  LD B,$01
  JR NC,PadNumberCount
  PUSH HL
  AND A
  LD DE,$000A
  SBC HL,DE
  POP HL
  JR C,PadNumber3
PadNumberCount:
  AND A
  LD DE,$000A
  CALL AtLeast
  JR C,PadNumber2
  LD DE,$0064
  CALL AtLeast
  JR C,PadNumber3
  LD DE,$03E8
  CALL AtLeast
  JR C,PadNumber4
  LD DE,$2710
  CALL AtLeast
  JR C,PadNumber5
  INC B
PadNumber5:
  INC B
PadNumber4:
  INC B
PadNumber3:
  INC B
PadNumber2:
  LD A,(Messages+$0011)
  CP B
  RET Z
  RET C
  SUB B
  LD B,A
PadNumberLoop:
  PUSH BC
  LD A,(Messages+$000F)
  AND A
  JP Z,PadNumberZero
  LD A,$20
  JP PadNumberChar
PadNumberZero:
  LD A,$30
PadNumberChar:
  CALL PrintCode
  POP BC
  DJNZ PadNumberLoop
  RET

; NC when HL is at least DE (HL kept)
;
; Used by the routine at PadNumber.
AtLeast:
  PUSH HL
  SBC HL,DE
  POP HL
  RET

; The cash's tenths plus DE, carrying 10000 into the thousands
;
; Used by the routines at AddCash, SellCheck and EquipShip.
AddCredits:
  LD HL,(CommanderRest+$0005)
  ADD HL,DE
  LD (CommanderRest+$0005),HL
  AND A
  LD DE,$2710
  SBC HL,DE
  RET C
  LD (CommanderRest+$0005),HL
  LD DE,$0001

; The thousands plus DE
;
; Used by the routine at EquipShip.
AddThousands:
  LD HL,(CommanderRest+$0003)
  ADD HL,DE
  LD (CommanderRest+$0003),HL
  RET

; The thousands less DE; carry when not enough
;
; Used by the routine at EquipShip.
TakeThousands:
  LD HL,(CommanderRest+$0003)
  SBC HL,DE
  JR C,TakeThousandsShort
  LD (CommanderRest+$0003),HL
  AND A
  RET
TakeThousandsShort:
  SCF
  RET

; The cash less DE tenths, borrowing a thousand; carry when not enough
;
; Used by the routines at BuyCheck and EquipShip.
TakeCredits:
  LD HL,(CommanderRest+$0005)
  AND A
  SBC HL,DE
  JR NC,TakeCreditsStore
  LD HL,(CommanderRest+$0003)
  LD A,L
  OR H
  SCF
  RET Z
  DEC HL
  LD (CommanderRest+$0003),HL
  LD HL,$2710
  AND A
  SBC HL,DE
  LD DE,(CommanderRest+$0005)
  ADD HL,DE
TakeCreditsStore:
  LD (CommanderRest+$0005),HL
  AND A
  RET

; Zero: PrintOtherChar's codes go to the standard set
OtherSetOn:
  DEFB $01

; Print the standard code in the byte after the CALL
;
; Used by the routines at PrintNumber, ControlFuel, PrintDistance, MarketRow,
; PrintCapitals, PrintUnit, PlanetNamePrompt, ReadLine, ShowCash, NoRoom,
; QuantityPrompt, ClearPageText, EquipShip, EquipFitted, DataScreen,
; PrintEconomy, StatusScreen, StatusBomb, StatusSystem and InventoryScreen.
PrintInline:
  POP HL
  LD A,(HL)
  INC HL
  PUSH HL

; Print code A of the standard set: a control, a character, a pair or a token
;
; 228436 runs over f1, w1, d1.
PrintCode:
  CP $0E
  JP C,TokenControl
  CP $20
  JP C,PrintCodeLowToken
  CP $60
  JP C,PrintChar
  CP $80
  JR C,PrintToken
  CP $A0
  JP C,PrintStdPair
  SUB $A0
  JR PrintToken
PrintCodeLowToken:
  ADD A,$72
PrintToken:
  LD HL,(TokenTable)
  LD D,A
  INC D
PrintTokenFind:
  DEC D
  JP Z,PrintTokenLoop
  LD BC,$FFFF
  XOR A
  CPIR
  JR PrintTokenFind
PrintTokenLoop:
  LD A,(HL)
  AND A
  RET Z
  PUSH HL
  CALL PrintCode
  POP HL
  INC HL
  JR PrintTokenLoop

; Print other token A: skip A - 1 strings of the other table, then each code
;
; Used by the routines at PrintOtherVector, FullMessage, ColourPage,
; PrintOtherChar, RandomToken, CommanderMenu, SecurityNumber, TapeMessage,
; JumpKeys, PrintOtherColon, ReadLine, ClearPageText, DataScreen, StatusScreen
; and InventoryScreen.
PrintOther:
  LD HL,(OtherTable)
  LD D,A
PrintOtherFind:
  DEC D
  JR Z,PrintOtherLoop
  LD BC,$FFFF
  LD A,$00
  CPIR
  JP PrintOtherFind

; One code of an other string: a control, a character, a random pick, a token
; or a pair
PrintOtherChar:
  LD B,A
  LD A,(OtherSetOn)
  CP $00
  LD A,B
  JR Z,PrintCode
  CP $20
  JP C,OtherControl
  CP $5B
  JR C,PrintChar
  CP $81
  JP C,RandomToken
  CP $D7
  JR C,PrintOther
  JP PrintOtherPair
; This entry point is used by the routine at PrintOther.
PrintOtherLoop:
  LD A,(HL)
  AND A
  RET Z
  PUSH HL
  CALL PrintOtherChar
  POP HL
  INC HL
  JR PrintOtherLoop

; Print a character with the case rules, or buffer it for the justified text
;
; PrintCase $D0D1: 0 the sentence case (a capital after a non-letter), 1 all
; capitals, 2 the next letter capital then small.
PrintChar:
  CP $41
  JR C,PrintCharOther
  CP $5B
  JR NC,PrintCharOther
  PUSH AF
  LD A,(PrintCase)
  CP $01
  JR Z,PrintCharOut
  LD A,(PrintCapitalNext)
  AND A
  JR Z,PrintCharCase
  XOR A
  LD (PrintCapitalNext),A
  LD (PrintCapital),A
  JR PrintCharOut
PrintCharCase:
  LD A,(PrintCapital)
  CP $01
  JR NZ,PrintCharSmall
  XOR A
  LD (PrintCapital),A
  LD A,(PrintCase)
  CP $02
  JR Z,PrintCharSmall
  JR PrintCharOut
PrintCharSmall:
  POP AF
  ADD A,$20
  PUSH AF
  JR PrintCharOut
PrintCharOther:
  PUSH AF
  LD A,$01
  LD (PrintCapital),A
PrintCharOut:
  LD A,(PrintBuffering)
  CP $01
  JP Z,JustifyChar
  POP AF

; Plot character A at the next column (wrapping to a new line past 31), XOR
; into the screen
;
; Used by the routine at JustifyPrint.
PlotChar:
  PUSH AF
  LD HL,TextColumn
  INC (HL)
  LD A,(HL)
  CP $20
  JR C,PlotCharGlyph
  LD A,$01
  LD (HL),A
  CALL NewLineRow
PlotCharGlyph:
  POP AF
  LD HL,Font
  SUB $20
  LD C,A
  LD B,$00
  SLA C
  RL B
  SLA C
  RL B
  SLA C
  RL B
  ADD HL,BC
  PUSH HL
  LD HL,$4000
  LD A,(TextRow)
  CP $10
  JP NC,PlotCharThird3
  CP $08
  JP NC,PlotCharThird2
  LD B,A
  JP PlotCharRow
PlotCharThird3:
  SUB $10
  LD B,A
  LD DE,$1000
  ADD HL,DE
  JP PlotCharRow
PlotCharThird2:
  SUB $08
  LD B,A
  LD DE,$0800
  ADD HL,DE
PlotCharRow:
  LD C,$00
  SRL B
  RR C
  SRL B
  RR C
  SRL B
  RR C
  ADD HL,BC
  LD B,$00
  LD A,(TextColumn)
  LD C,A
  ADD HL,BC
  POP DE
  LD B,$08
PlotCharLine:
  LD A,(DE)
  LD C,(HL)
  XOR C
  LD (HL),A
  INC H
  INC DE
  DJNZ PlotCharLine
  RET

; 30 attributes of colour 5 from $5AA1 (the dashboard's message line)
;
; Used by the routines at CommanderMenu, FirearmsPrice, TradePage, EquipShip
; and ShortRangeChart.
FillAttrRow:
  LD HL,$5AA1
  LD A,$05

; B = 30 attributes of A from HL, then HL past the row's edge
;
; Used by the routine at InventoryScreen.
FillAttrs30:
  LD B,$1E
  CALL FillBytes
  INC HL
  INC HL
  RET

; The heading's rule: 32 bytes $FF at $4340
HorizontalRule:
  LD HL,$4340

; 32 bytes of $FF from HL
;
; Used by the routines at DrawFrame, MenuTop and GalacticChart.
FillRule:
  LD A,$FF
  LD B,$20

; B bytes of A from HL
;
; Used by the routines at FillAttrs30, ColourBands, MenuTop and GalacticChart.
FillBytes:
  LD (HL),A
  INC HL
  DJNZ FillBytes
  RET

; The page's colour bands from the list at DE: a width in 8ths and a gap of
; rows each, colour 5; the two corner cells white
;
; The status and the market pages call it with their lists ($FD8E and others).
ColourBands:
  LD HL,$5821
ColourBandsLoop:
  LD A,(DE)
  INC DE
  PUSH AF
  AND $F8
  RRCA
  RRCA
  RRCA
  LD B,A
  PUSH HL
  LD A,$05
  CALL FillBytes
  POP HL
  POP AF
  AND $07
  JR Z,ColourBandsEnd
  LD B,A
ColourBandsRow:
  LD A,$20
  ADD A,L
  LD L,A
  JR NC,ColourBandsGap
  INC H
ColourBandsGap:
  DJNZ ColourBandsRow
  JR ColourBandsLoop
ColourBandsEnd:
  LD HL,$5822
  LD A,$07
  LD (HL),A
  INC HL
  LD (HL),A
  RET

; Other pair A - $D7 from $FD99
;
; Used by the routine at PrintOtherChar.
PrintOtherPair:
  SUB $D7
  LD HL,OtherPairs
  JR PrintPairNow

; Standard pair A - $80 from $FDB3
;
; Used by the routine at PrintCode.
PrintStdPair:
  SUB $80
  LD HL,StdPairs

; Two characters, the second left out when it is "?"
;
; Used by the routine at PrintOtherPair.
PrintPairNow:
  ADD A,A
  LD D,$00
  LD E,A
  ADD HL,DE
  LD A,(HL)
  PUSH HL
  CALL PrintChar
  POP HL
  INC HL
  LD A,(HL)
  CP $3F
  RET Z
  JP PrintChar

; A random one of the five tokens of row A - $5B of Synonyms, by the text
; generator's next byte
;
; Used by the routine at PrintOtherChar.
RandomToken:
  LD D,$00
  SUB $5B
  LD E,A
  LD HL,Synonyms
  ADD HL,DE
  LD A,(HL)
  PUSH AF
  CALL TextRandom
  LD B,$00
  CP $33
  JP C,RandomToken1
  CP $66
  JP C,RandomToken2
  CP $99
  JP C,RandomToken3
  CP $CC
  JP C,RandomToken4
  INC B
RandomToken4:
  INC B
RandomToken3:
  INC B
RandomToken2:
  INC B
RandomToken1:
  POP AF
  ADD A,B
  JP PrintOther

; The text generator: the four bytes at $DECC shifted and added; A its next
; byte
;
; Used by the routines at RandomToken and ControlRandomName.
TextRandom:
  LD HL,(TextSeeds)
  SLA L
  EX DE,HL
  LD HL,(TextSeeds+$0002)
  ADC HL,DE
  LD A,H
  LD (TextSeeds),HL
  EX DE,HL
  LD (TextSeeds+$0002),HL
  RET

; The first other token of each row of five synonyms
Synonyms:
  DEFB $10,$15,$1A,$1F,$9B,$A0,$2E,$A5
  DEFB $24,$29,$3D,$33,$38,$AA,$42,$47
  DEFB $4C,$51,$56,$8C,$60,$65,$87,$82
  DEFB $5B,$6A,$B4,$B9,$BE,$E1,$E6,$EB
  DEFB $F0,$F5,$FA,$73,$78,$7D

; ClearScreenSP
ClearScreenSP:
  DEFW $0000

; Clear the page by PUSHes: 768 attributes $07, 6144 pixel bytes 0; then the
; frame: both side columns, the top and bottom rules; print at row 1, column 0
;
; Used by the routines at ClearScreenVector, FullMessage, ColourPage,
; CommanderMenu, JumpKeys, FirearmsPrice, EquipShip, GalacticChart and
; ShortRangeChart.
ClearScreen:
  DI
  LD (ClearScreenSP),SP
  LD SP,ScannerSave
  LD DE,$0707
  LD C,$18
ClearScreenAttrRow:
  LD B,$10
ClearScreenAttrs:
  PUSH DE
  DJNZ ClearScreenAttrs
  DEC C
  JP NZ,ClearScreenAttrRow
  LD DE,$0000
  LD C,$C0
ClearScreenPixelRow:
  LD B,$10
ClearScreenPixels:
  PUSH DE
  DJNZ ClearScreenPixels
  DEC C
  JP NZ,ClearScreenPixelRow
  LD SP,(ClearScreenSP)
  EI

; The page's frame: bit 7 of column 0 and bit 0 of column 31 on 192 lines, the
; top and bottom lines solid
;
; Used by the routines at GalacticChart and StatusBomb.
DrawFrame:
  LD B,$C0
  LD DE,$0020
  LD HL,$4000
DrawFrameLeft:
  LD A,(HL)
  OR $80
  LD (HL),A
  ADD HL,DE
  DJNZ DrawFrameLeft
  LD B,$C0
  LD HL,$401F
DrawFrameRight:
  LD A,(HL)
  OR $01
  LD (HL),A
  ADD HL,DE
  DJNZ DrawFrameRight
  LD HL,$4000
  CALL FillRule
  LD HL,$57E0
  CALL FillRule
  XOR A
  LD L,A
  INC A
  LD H,A
  LD (TextColumn),HL
  RET

; The justified text's line (32 bytes), the next word ($D695, 31), the counts
; ($D6B3, $D6B4) and two pointers ($D6B5, $D6B7)
JustifyLine:
  DEFB $20,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00

; Buffer a character of the justified text; a full line is spread to 30 columns
; (spaces added between words) and printed
;
; The other set's control codes 14 and 15 start and end it (the mission texts
; and the data screen's description). 1025 runs (the data on Lave of d1).
JustifyChar:
  LD HL,(JustifyLine+$0040)
  INC HL
  LD (JustifyLine+$0040),HL
  POP AF
  LD (HL),A
  CP $2E
  JP Z,JustifyPrint
  LD B,A
  LD A,(JustifyLine+$003F)
  INC A
  LD (JustifyLine+$003F),A
  CP $1F
  RET C
  LD A,$20
  CP B
  JP Z,JustifyPrint
  CALL JustifyBackWord
  LD A,B
  LD (JustifyLine+$003E),A
  AND A
  JR Z,JustifySpreadLoop
JustifyCarry:
  LD HL,(JustifyLine+$0040)
  INC HL
  LD C,B
  LD B,$00
  LD DE,JustifyLine+$0020
  LDIR
JustifyNext:
  LD HL,JustifyLine
  LD A,(JustifyLine+$003E)
  LD E,A
  LD D,$00
  ADD HL,DE
  LD (JustifyLine+$0042),HL
  LD A,(JustifyLine+$003E)
  CP $1F
  JP NC,JustifyPrint
JustifyClear:
  LD HL,(JustifyLine+$0040)
  LD B,A
JustifyClearLoop:
  LD (HL),$00
  INC HL
  DJNZ JustifyClearLoop
JustifySpread:
  LD A,(JustifyLine+$003E)
JustifySpreadLoop:
  PUSH AF
  CALL JustifyBackWord
  CALL JustifyAddSpace
  POP AF
  DEC A
  JR NZ,JustifySpreadLoop

; Print the 30 characters of the line, a new line, the capital off
;
; Used by the routines at JustifyChar and JustifyOff.
JustifyPrint:
  LD HL,JustifyLine+$0001
  LD B,$1E
JustifyPrintLoop:
  PUSH BC
  PUSH HL
  LD A,(HL)
  CALL PlotChar
  POP HL
  INC HL
  POP BC
  DJNZ JustifyPrintLoop
  CALL NewLine
  LD A,$00
  LD (PrintCapital),A

; The carried word becomes the start of the next line
;
; Used by the routine at JustifyOn.
JustifyNewLine:
  LD HL,(JustifyLine+$0042)
  LD (JustifyLine+$0040),HL
  LD HL,JustifyLine
  LD (JustifyLine+$0042),HL
  LD A,(JustifyLine+$003E)
  LD (JustifyLine+$003F),A
  XOR A
  LD (JustifyLine+$003E),A
  LD B,$1E
  LD C,$20
  LD HL,JustifyLine+$0020
  LD DE,JustifyLine+$0001
JustifyNewLineCopy:
  LD A,(HL)
  LD (DE),A
  LD (HL),C
  INC HL
  INC DE
  DJNZ JustifyNewLineCopy
  RET

; Other control 14: buffering on, the buffers blank
JustifyOn:
  LD A,$01
  LD (PrintBuffering),A
  LD B,$1F
  LD A,$20
  LD HL,JustifyLine+$0020
JustifyOnBlank:
  LD (HL),A
  INC HL
  DJNZ JustifyOnBlank
  LD HL,JustifyLine
  LD (JustifyLine+$0042),HL
  XOR A
  LD (JustifyLine+$003E),A
  JR JustifyNewLine

; Other control 15: buffering off, the last line printed as it is
JustifyOff:
  LD A,$00
  LD (PrintBuffering),A
  LD A,(JustifyLine+$003F)
  AND A
  CALL NZ,JustifyPrint
  RET

; Back to the space before the last word (or the line's start)
;
; Used by the routine at JustifyChar.
JustifyBackWord:
  LD HL,(JustifyLine+$0040)
  LD B,$00
JustifyBackWordLoop:
  DEC HL
  LD A,(HL)
  INC B
  CP $20
  JR NZ,JustifyBackWordLoop
  LD (JustifyLine+$0040),HL
  LD DE,JustifyLine+$0001
  AND A
  SBC HL,DE
  RET NC
  LD HL,JustifyLine+$001F
  LD (JustifyLine+$0040),HL
  JR JustifyBackWord

; One more space at the pointer: the rest of the line moved right by one
;
; Used by the routine at JustifyChar.
JustifyAddSpace:
  LD B,$20
  LD HL,(JustifyLine+$0040)
JustifyAddSpaceLoop:
  LD A,(HL)
  LD C,A
  LD (HL),B
  LD B,C
  INC HL
  XOR A
  CP C
  JR NZ,JustifyAddSpaceLoop
  RET

; Other control A through the table at $D7DF
;
; Used by the routine at PrintOtherChar.
OtherControl:
  LD HL,OtherControls
  JR JumpTable

; Standard control A through the table at $D7C3
;
; Used by the routine at PrintCode.
TokenControl:
  LD HL,TokenControls

; Jump to the A-th address of the table at HL
;
; Used by the routine at OtherControl.
JumpTable:
  LD D,$00
  SLA A
  LD E,A
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  JP (HL)

; The standard set's 14 control codes: 0 nothing, 1 the galaxy's number, 2 the
; current system, 3 the selected system, 4 the commander, 5 the fuel, 6
; capitals, 7 the cash, 8 sentence case, 9 a new line, 10 the other set on, 11
; the galaxy's first system, 12 and 13 nothing
TokenControls:
  DEFW ControlNone,ControlGalaxy,ControlCurrent,ControlSelected,ControlCommander,ControlFuel,ControlCapitals
  DEFW ControlCash,ControlSentence,NewLine,OtherOn,ControlFirstSystem,ControlNone,ControlNone

; The other set's 32: 0 nothing, 1 capitals, 2 sentence case, 3 the selected
; system, 4 the commander, 5 and 6 the other set on and off, 7 a beep, 8 tab, 9
; a clear page, 10 the column 0, 11 the rule, 12 a new line, 13 capital then
; small, 14 and 15 the justified text, 16 the galaxy's first system, 17 the
; system's people (-ian), 18 a random name, 19 a capital next, 21 the text area
; cleared, 22 and 24 waits, 23 and 29 rows 10 and 6, 25 a wait
OtherControls:
  DEFW ControlNone,ControlCapitals,ControlSentence,ControlSelected,ControlCommander,OtherOn,OtherOff,Click
  DEFW ControlTab,ClearScreen,NewLineRow,HorizontalRule,NewLine,ControlMixed,JustifyOn,JustifyOff
  DEFW ControlFirstSystem,ControlPeople,ControlRandomName,CapitalNext,ControlNone,ClearInputRows,Wait20,ControlRow10
  DEFW Wait36,WaitControl,ControlNone,ControlNone,ControlNone,ControlRow6,ControlNone,ControlNone

; Other control 25: wait 36 frames
WaitControl:
  JP Wait36

; Standard 7: "CASH:" the cash and " CR", a new line
ControlCash:
  LD A,$C5
  CALL PrintCodeColon
  CALL PrintCash
  LD A,$E2
  JR PrintLine

; Standard 4: the commander's name
ControlCommander:
  LD HL,CommanderName
  JR PrintString

; Standard 8: sentence case
ControlSentence:
  LD A,$00
  JR SetCase

; Standard 5: "FUEL:" the fuel with its point, " LIGHT YEARS", a new line
ControlFuel:
  LD A,$69
  CALL PrintCodeColon
  CALL PrintInline

; The space after "FUEL:"
FuelSpace:
  DEFB $20

; ControlFuelValue
ControlFuelValue:
  LD A,(Fuel)
  CALL PrintByteDot
  LD A,$C3

; Print token A and a new line
;
; Used by the routine at ControlCash.
PrintLine:
  JP PrintCodeLine

; Standard 1: the galaxy's number (1-8) in two places
ControlGalaxy:
  LD A,$02
  LD (Messages+$0011),A
  LD A,(CommanderRest+$0002)
  INC A
  JP PrintByte

; Standard 11: the name of the galaxy's first system (its seeds from the
; galaxy's)
ControlFirstSystem:
  LD HL,Seeds+$0002
  LD DE,SystemSeeds
  LD BC,$0006
  LDIR
  CALL SystemName
  LD HL,NameBuffer
  JR PrintString

; Standard 2: the current system's name
ControlCurrent:
  CALL CapitalNext
  LD HL,CurrentName
  JR PrintString

; Standard 3: the selected system's name
ControlSelected:
  CALL CapitalNext
  LD HL,SelectedName

; Print the zero-ended string at HL
;
; Used by the routines at ControlCommander, ControlFirstSystem, ControlCurrent
; and ControlPeople.
PrintString:
  JP PrintCodes

; Other 8: column 4
ControlTab:
  CALL ColumnInline

; TabColumn
TabColumn:
  DEFB $04

; Other 19: the next letter a capital
;
; Used by the routines at ControlCurrent, ControlSelected, ControlRandomName
; and ControlPeople.
CapitalNext:
  LD A,$01
  LD (PrintCapitalNext),A

; Nothing
ControlNone:
  RET

; Other 18: a random name of one to four letter pairs (the pairs $FD9B on)
ControlRandomName:
  CALL CapitalNext
  CALL TextRandom
  AND $03
ControlRandomNameLoop:
  PUSH AF
  CALL TextRandom
  AND $3E
  LD HL,OtherPairs+$0002
  LD D,$00
  LD E,A
  ADD HL,DE
  PUSH HL
  CALL PrintPairChar
  POP HL
  INC HL
  CALL PrintPairChar
  POP AF
  AND A
  RET Z
  DEC A
  JR ControlRandomNameLoop

; Other 13: a capital, then small
ControlMixed:
  LD A,$02
  JR SetCase

; ControlSpare
ControlSpare:
  DEFB $C9

; Standard 6, other 1: capitals
ControlCapitals:
  LD A,$01

; PrintCase = A
;
; Used by the routines at ControlSentence and ControlMixed.
SetCase:
  LD (PrintCase),A
  RET

; Other 17: the system's name and "IAN", its last vowel dropped
ControlPeople:
  CALL CapitalNext
  LD HL,SelectedName
  CALL PrintCodes
  DEC HL
  LD A,(HL)
  LD B,$05
  LD HL,Vowels
ControlPeopleLoop:
  CP (HL)
  JR Z,ControlPeopleVowel
  INC HL
  DJNZ ControlPeopleLoop
ControlPeopleEnd:
  LD HL,PeopleSuffix
  JR PrintString
ControlPeopleVowel:
  LD HL,JustifyLine+$003F
  DEC (HL)
  LD HL,(JustifyLine+$0040)
  DEC HL
  LD (JustifyLine+$0040),HL
  JR ControlPeopleEnd

; "IAN" and the vowels it replaces
PeopleSuffix:
  DEFM "IAN",$00

; Vowels
Vowels:
  DEFM "AEIOU"

; Standard 10, other 5: the other set on (OtherSetOn 1)
OtherOn:
  LD A,$01
  JR SetOtherSet

; Other 6: off
OtherOff:
  LD A,$00

; SetOtherSet
;
; Used by the routine at OtherOn.
SetOtherSet:
  LD (OtherSetOn),A
  RET

; Other 29: row 6
ControlRow6:
  LD A,$06
  JR ControlRow

; Other 23: row 10
ControlRow10:
  LD A,$0A

; ControlRow
;
; Used by the routine at ControlRow6.
ControlRow:
  JP SetRow

; A pair's character unless "?"
;
; Used by the routine at ControlRandomName.
PrintPairChar:
  LD A,(HL)
  CP $3F
  RET Z
  JP PrintCode

; Three bytes no code reads (known from the code only)
ControlData:
  DEFB $00,$00,$00
