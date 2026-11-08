; --------------------------------------------------------------------------------------------------------------------
; menuhelpers.asm: The screens' helpers: the click, the key waits, the cursor moves, the market rows, the units, the line editor and the planet name prompt
;
; The docked screens are printed line by line with these: NewLine and SetRow keep the text position in range (row 24
; wraps to row 1), ColumnInline sets the column from the byte after its CALL, PrintUnit adds t, kg, g or km, and the
; market rows step three pointers through Prices, MarketStock and the hold. ReadLine is the one line editor (the
; commander's name, a planet's name): digits and capitals, DELETE (CAPS SHIFT + 0) and ENTER.
; --------------------------------------------------------------------------------------------------------------------

; With the sound on (Options bit 7) a short beep through the ROM's BEEPER (HL =
; $80, DE = $60)
;
; Used by the routines at FullMessage, TapeMessage, MessageTick, JumpKeys,
; PlanetNamePrompt, ShowSelected and ClickWait.
Click:
  LD A,(Options)
  BIT 7,A
  RET Z
  LD HL,$0080
  LD DE,$0060
  JP $03B5

; 20 frames, the key bytes cleared, then wait for a key: A = its code (KeyCode
; $FC0D)
;
; Used by the routines at FullMessage, MissionQuestion, CommanderMenu,
; SaveCommander, ReadLine, BuyCargo, QuantityKeys and EquipShip.
WaitKey:
  CALL Wait20
  CALL ClearKeys4
WaitKeyLoop:
  LD A,(KeyCode)
  CP $FF
  JR Z,WaitKeyLoop
  RET

; The four key bytes $FC08-$FC0B zeroed with the interrupts off
;
; Used by the routines at FullMessage, CommanderMenu, JumpKeys, WaitKey,
; PlanetNamePrompt and ReadLine.
ClearKeys4:
  DI
  LD HL,KeyScreens
  LD B,$04
ClearKeys4Loop:
  LD (HL),$00
  INC HL
  DJNZ ClearKeys4Loop
  EI
  RET

; One commodity of the market: its name, the unit, the price (4 digits and the
; point), the stock and its unit; carry when the stock is 0 ("-")
;
; MarketItem picks the name (standard code $D0 + item); the columns are 13, 15
; and 23 (ColumnInline). The price comes through PricePointer, the stock
; through StockPointer, each stepped first.
MarketRow:
  LD A,(MarketItem)
  ADD A,$D0
  CALL PrintCode
  CALL ColumnInline
  DEFB $0D
MarketRowUnit:
  CALL PrintUnit
  CALL ColumnInline
  DEFB $0F
MarketRowPrice:
  LD HL,(PricePointer)
  INC HL
  INC HL
  LD (PricePointer),HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  SCF
  LD A,$04
  LD (Messages+$0011),A
  CALL PrintNumber
  CALL ColumnInline
  DEFB $17
MarketRowStock:
  LD HL,(StockPointer)
  INC HL
  LD A,(HL)
  LD (StockPointer),HL
  AND A
  JR NZ,MarketRowCount
  CALL PrintInline
  DEFB $20
MarketRowNone:
  LD A,$2D
  CALL PrintCodeLine
  SCF
  RET
MarketRowCount:
  LD A,$02
  LD (Messages+$0011),A
  LD HL,(StockPointer)
  LD A,(HL)
  CALL PrintByte
  CALL PrintUnit
  CALL NewLine
  AND A
  RET

; One line of the hold: nothing (carry) for 0 units, else the name, column 13,
; the count (3 digits) and the unit
;
; Used by the routines at ClearPageText and InventoryScreen.
HoldRow:
  LD HL,(HoldPointer)
  INC HL
  LD (HoldPointer),HL
  LD A,(HL)
  AND A
  JR Z,HoldRowEmpty
  LD A,(MarketItem)
  ADD A,$D0
  CALL PrintCode
  CALL ColumnInline
  DEFB $0D
  LD A,$03
  LD (Messages+$0011),A
  LD HL,(HoldPointer)
  LD A,(HL)
  CALL PrintByte
  CALL PrintUnit
  AND A
  RET
HoldRowEmpty:
  SCF
  RET

; Other token A and ":"
;
; Used by the routines at DataScreen, PrintEconomy and StatusScreen.
PrintOtherColon:
  CALL PrintOther
  JR PrintColon

; Standard code A and ":"
;
; Used by the routines at ControlCash, ControlFuel, PrintDistance and
; DataScreen.
PrintCodeColon:
  CALL PrintCode

; PrintColon
;
; Used by the routine at PrintOtherColon.
PrintColon:
  LD A,$3A
  JR PrintCodeNow

; Standard code A and a space
;
; Used by the routines at EquipShip, EquipFitted, PrintSpecies and PrintLaser.
PrintCodeSpace:
  CALL PrintCode
  LD A,$20

; PrintCodeNow
;
; Used by the routine at PrintColon.
PrintCodeNow:
  JP PrintCode

; Standard code A and a new line
;
; Used by the routines at PrintLine, ViewTexts, MessageSet, MarketRow,
; FirearmsPrice, QuantityPrompt, EquipShip, PrintCodeGap, MarketPrices,
; StatusScreen, StatusSystem and InventoryScreen.
PrintCodeLine:
  CALL PrintCode

; Column 0 of the next row (a capital next)
;
; Used by the routines at JustifyPrint, TapeMessage, PrintDistanceEnd,
; MarketRow, SetColumn, ReadLine, ShowSelected, ClearPageText, EquipShip,
; DataScreen, NewLineGap, NewLineGapSecond, EquipmentLine and InventoryScreen.
NewLine:
  LD A,$01
  LD (PrintCapital),A
  CALL ColumnZero

; NewLineRow
;
; Used by the routine at PlotChar.
NewLineRow:
  LD A,(TextRow)
  INC A
  JR SetRow

; Column 0
;
; Used by the routines at NewLine, SetRow and ClearInputRows.
ColumnZero:
  XOR A
  LD (TextColumn),A
  RET

; The column from the byte after the CALL
;
; Used by the routines at ControlTab, MarketRow, HoldRow, FirearmsPrice,
; ShowCash, NoRoom, EquipShip, ScreenHeading, StatusScreen and StatusSystem.
ColumnInline:
  POP HL
  LD A,(HL)
  INC HL
  PUSH HL

; Column A; 32 and more is a new line
;
; Used by the routines at EquipShip and EquipmentLine.
SetColumn:
  LD (TextColumn),A
  CP $20
  RET C
  JR NewLine

; Row A; 24 and more is row 1, column 0
;
; Used by the routines at ControlRow, NewLineRow, ClearInputRows, EquipShip,
; DataScreen, StatusScreen and InventoryScreen.
SetRow:
  LD (TextRow),A
  CP $18
  RET C
  LD A,$01
  LD (TextRow),A
  JR ColumnZero

; One letter back on row 21 or 22 (ReadLine's DELETE): the cell's eight pixel
; rows cleared
;
; The screen address's low byte is written into the LD HL at $E2ED (the column
; - 1 plus $A1 or $C1): the line editor's rows are rows 5 and 6 of the screen's
; last third.
DeleteChar:
  LD A,(TextRow)
  LD B,$A1
  CP $15
  JR Z,DeleteCharColumn
  LD B,$C1
DeleteCharColumn:
  LD A,(TextColumn)
  AND A
  RET Z
  DEC A
  LD (TextColumn),A
  ADD A,B
  LD (DeleteCharColumn+$000E),A
  LD HL,$5000
  XOR A
  LD B,$08
DeleteCharLoop:
  LD (HL),A
  INC H
  DJNZ DeleteCharLoop
  RET

; Standard code A in capitals (control 6), then sentence case (control 8)
;
; Used by the routines at PageTitle, ShowSelected and DataScreen.
PrintCapitals:
  PUSH AF
  CALL PrintInline
  DEFB $06
  POP AF
  CALL PrintCode
  LD A,$08
  JP PrintCode

; A screen's title: code A in capitals, the condition light, and code $77
; (three new lines)
;
; Used by the routines at ClearPageText, ScreenHeading, DataScreen,
; MarketPrices and InventoryScreen.
PageTitle:
  CALL PrintCapitals
  CALL ConditionLightVector
  LD A,$77
  JP PrintCode

; The zero-ended standard codes at HL; carry at the end
;
; Used by the routines at PrintString, ControlPeople, PlanetNamePrompt and
; PrintIfRowFree.
PrintCodes:
  LD A,(HL)
  CP $00
  SCF
  RET Z
  INC HL
  PUSH HL
  CALL PrintCode
  POP HL
  JR PrintCodes

; The unit of MarketItem in small letters: t (0-12, 16), kg (13, 14), g (15),
; km (17: the data screen's radius)
;
; Used by the routines at MarketRow, HoldRow, QuantityPrompt and DataScreen.
PrintUnit:
  LD A,$00
  LD (PrintCapital),A
  LD A,(MarketItem)
  CP $0D
  JR C,PrintUnitTonnes
  CP $0F
  JR C,PrintUnitKilo
  JR Z,PrintUnitGrams
  CP $11
  JR C,PrintUnitTonnes
  JR PrintUnitKm
PrintUnitTonnes:
  LD A,$54
  JR PrintUnitNow
PrintUnitKilo:
  LD A,$4B
  CALL PrintCode
PrintUnitGrams:
  LD A,$47
  JR PrintUnitNow
PrintUnitKm:
  CALL PrintInline
  DEFB $4B
  LD A,$4D

; PrintUnitNow
;
; Used by the routine at PrintUnit.
PrintUnitNow:
  JP PrintCode

; Carry when MarketItem is sold in tonnes (0-12 and 16): BuyCheck and SellCheck
; count only those against the free space
;
; Used by the routines at BuyCheck and SellCheck.
IsTonnes:
  LD A,(MarketItem)
  CP $0D
  RET C
  CP $10
  JR NZ,IsTonnesNo
  SCF
  RET
IsTonnesNo:
  AND A
  RET

; 20 frames
;
; Used by the routines at WaitKey and ReadLine.
Wait20:
  LD B,$14
  JR WaitFrames

; 36 frames
;
; Used by the routines at FullMessage, WaitControl, JumpKeys, BuyCargo,
; ClickWait and ClearPageText.
Wait36:
  LD B,$24

; B frames (HALT B times)
;
; Used by the routine at Wait20.
WaitFrames:
  HALT
  DJNZ WaitFrames
  RET

; The text position into SavedCursor
;
; Used by the routines at FirearmsPrice and ClearPageText.
SaveCursor:
  LD HL,(TextColumn)
  LD (SavedCursor),HL
  RET

; Rows 21 and 22 cleared, the position at row 21, column 0
;
; Used by the routines at TapeBreak, PlanetNamePrompt, ReadLine, ShowSelected,
; QuantityPrompt and EquipShip.
ClearInputRows:
  LD A,$15
  CALL SetRow
  CALL ColumnZero
  XOR A
  LD HL,$50A1
  CALL ClearCells

; Row 22 (cells 1-30) cleared
;
; Used by the routine at TapeMessage.
ClearRow22:
  LD HL,$50C1

; Eight pixel rows of 30 cells from HL set to A
;
; Used by the routine at ClearInputRows.
ClearCells:
  LD B,$08
ClearCellsRow:
  PUSH BC
  LD B,$1E
  PUSH HL
ClearCellsByte:
  LD (HL),A
  INC HL
  DJNZ ClearCellsByte
  POP HL
  INC H
  POP BC
  DJNZ ClearCellsRow
  RET

; The text position from SavedCursor
;
; Used by the routines at FirearmsPrice and ClearPageText.
RestoreCursor:
  LD HL,(SavedCursor)
  LD (TextColumn),HL
  RET

; ReadLine: the letters typed
InputLength:
  DEFB $00

; ReadLine: the next letter's place
InputPointer:
  DEFW $0000

; ReadLine: the last key's code
InputKey:
  DEFB $00

; PLANET NAME? (other $0E, 8 letters): the system found becomes the selected
; one, else "<name> NOT FOUND"
;
; Used by the routine at PlanetNameVector.
PlanetNamePrompt:
  LD A,$0E
  LD B,$08
  LD HL,NameInput
  CALL ReadLine
  LD A,(InputLength)
  AND A
  JP Z,ClearInputRows
  CALL FindSystem
  JR NC,PlanetNameFound
  LD HL,NameInput
  CALL PrintCodes
  CALL PrintInline
  DEFB $08
  CALL PrintInline
  DEFB $E1
  CALL Click
  JP ClearKeys4
PlanetNameFound:
  CALL PrintInline
  DEFB $08
  JP ShowSelectedNow

; ReadLine's prompt (an other token)
InputPrompt:
  DEFB $00

; ReadLine's buffer
InputStart:
  DEFW $0000

; Read up to B letters into HL after the other token A on the cleared input
; rows; ENTER ends, DELETE takes one back
;
; B is written into the CP at $E413 (the length check). Accepted: 0-9 and @,
; A-Z (codes $30-$39, $40-$5A); each is stored and printed. DELETE ($FE: CAPS
; SHIFT with 0, the keyboard scan's code) moves back one and clears the cell.
; ENTER or a full buffer ends the line with a zero; the editor waits for ENTER
; to be let go. Known from the code only (no recording typed a name).
ReadLine:
  LD (InputPrompt),A
  LD A,B
  LD (ReadLineLetter+$0005),A
  LD (InputStart),HL
  LD HL,(InputStart)
  LD (InputPointer),HL
  XOR A
  LD (InputLength),A
  CALL ClearInputRows
  CALL PrintInline
  DEFB $06
  LD A,(InputPrompt)
  CALL PrintOther
ReadLineKey:
  CALL WaitKey
  LD (InputKey),A
  CP $0D
  JR Z,ReadLineEnd
  CP $FE
  JR Z,ReadLineDelete
  LD A,(InputKey)
  CP $30
  JR C,ReadLineKey
  CP $5B
  JR NC,ReadLineKey
  CP $3A
  JR C,ReadLineLetter
  CP $40
  JR C,ReadLineKey
ReadLineLetter:
  LD D,A
  LD A,(InputLength)
  CP $0A
  JR NC,ReadLineEnd
  INC A
  LD (InputLength),A
  LD A,D
  LD HL,(InputPointer)
  LD (HL),A
  INC HL
  LD (InputPointer),HL
  CALL PrintCode
  JR ReadLineKey
ReadLineDelete:
  LD A,(InputLength)
  AND A
  JR Z,ReadLineKey
  DEC A
  LD (InputLength),A
  LD HL,(InputPointer)
  DEC HL
  LD (InputPointer),HL
  CALL DeleteChar
  LD B,$06
ReadLineDeleteWait:
  HALT
  DJNZ ReadLineDeleteWait
  CALL ClearKeys4
  JR ReadLineKey
ReadLineEnd:
  LD HL,(InputPointer)
  LD (HL),$00
  CALL NewLine
  CALL Wait20
ReadLineRelease:
  LD A,(KeyCode)
  CP $0D
  JR Z,ReadLineRelease
  JP ClearKeys4

; The system nearest the cursor: its name in capitals and its distance on the
; input rows, a click
;
; Used by the routine at CursorDistance.
ShowSelected:
  CALL FindNearest
; This entry point is used by the routine at PlanetNamePrompt.
ShowSelectedNow:
  CALL ClearInputRows
  LD A,$03
  CALL PrintCapitals
  CALL NewLine
  CALL PrintDistance
  JP Click
