; --------------------------------------------------------------------------------------------------------------------
; print.asm: Printing: characters, inline codes, numbers, frames, the status panel and the texts
;
; PrintInline and its codes (FF row column, FB attribute, FD box, FC number, FE end), the decimal printers, DrawBox,
; the status panel (menu bar, city name, funds, date, tool), MonthNames and GameTexts with FindText and PrintPadded.
; --------------------------------------------------------------------------------------------------------------------

; Print character A at PrintAddr (JP to PrintGlyph $F754)
;
; L1 163 852.
PrintChar:
  CALL PrintGlyph
  RET

; Print the codes that follow the CALL, up to $FE, then return after them
;
; The codes: $FF row column (position), $FB attribute (PrintAttr), $FD row
; column width height (a box, DrawBox), $FC number (printed as up to 3 digits;
; not used in any recording), $FE the end (JP to the byte after it); any other
; byte a character. PrintCol counts up. Used for every fixed text and window
; frame (L1 371 calls).
PrintInline:
  POP HL
PrintInlineNext:
  LD A,(HL)
  CP $FE
  JP Z,PrintInlineEnd
  CP $FB
  JR Z,PrintInlineAttr
  CP $FF
  JR Z,PrintInlineAt
  CP $FD
  JP Z,PrintInlineBox
  CP $FC
  JR Z,PrintInlineNumber
  PUSH HL
  CALL PrintChar
  CALL NextColumn
  POP HL
; This entry point is used by the routines at NextColumn and PrintDigit.
PrintInlineSkip:
  INC HL
  JR PrintInlineNext

; PrintAddr and PrintCol one column on
;
; L1 450 406.
NextColumn:
  LD HL,(PrintAddr)
  INC HL
  LD (PrintAddr),HL
  LD HL,PrintCol
  INC (HL)
  RET
; This entry point is used by the routine at PrintInline.
PrintInlineAttr:
  INC HL                  ; $FB n: PrintAttr = n
  LD A,(HL)
  LD (PrintAttr),A
  JR PrintInlineSkip
; This entry point is used by the routine at PrintInline.
PrintInlineNumber:
  INC HL                  ; $FC n: n in 3 digits (L1 -)
  LD A,(HL)
  PUSH HL
  LD L,A
  LD H,$00
  CALL Print3Digits
  POP HL
  JR PrintInlineSkip

; Four bytes no code reads (LD ($F751),BC: a cut instruction of the source);
; kept as bytes
PrintSpare:
  DEFB $ED,$43,$51,$F7

; HL in 5 digits at PrintCol, PrintRow
;
; L1 2 (the gene's 5 digits).
PrintNumberAt:
  PUSH HL
  LD BC,(PrintCol)
  CALL ScreenAddr
  LD (PrintAddr),HL
  POP HL

; HL in 5 digits, leading zeros printed
;
; L1 4.
Print5Digits:
  LD DE,-10000
  CALL PrintDigitOf

; HL in 4 digits (the year)
;
; L1 9921.
Print4Digits:
  LD DE,-1000
  CALL PrintDigitOf

; HL in 3 digits (menus' numbers, the tax rate)
;
; L1 11 961.
Print3Digits:
  LD DE,$FF9C
  CALL PrintDigitOf
  LD DE,$FFF6
  CALL PrintDigitOf
  LD A,L
  CALL PrintDigit
  RET

; One digit: count how often DE (a negative power of ten) goes into HL, then
; print it
;
; Used by the routines at Print5Digits, Print4Digits and Print3Digits.
PrintDigitOf:
  XOR A
DigitCount:
  INC A
  ADD HL,DE
  JR C,DigitCount
  SBC HL,DE
  DEC A

; Print the digit A (0-9) at PrintAddr and step on
;
; L1 45 808.
PrintDigit:
  ADD A,$30
  LD (PrintCharCode),A
  PUSH HL
  CALL PrintChar
  LD HL,(PrintAddr)
  INC HL
  LD (PrintAddr),HL
  POP HL
  RET
; This entry point is used by the routine at PrintInline.
PrintInlineEnd:
  INC HL                  ; $FE: return after the codes
  JP (HL)
; This entry point is used by the routine at PrintInline.
PrintInlineAt:
  INC HL                  ; $FF row column
  LD B,(HL)
  INC HL
  LD C,(HL)
  PUSH HL
  CALL ScreenAddr
  LD (PrintAddr),HL
  POP HL
  JR PrintInlineSkip
; This entry point is used by the routine at PrintInline.
PrintInlineBox:
  INC HL                  ; $FD row column width height
  PUSH HL
  CALL DrawBox
  POP HL
  LD DE,$0003
  ADD HL,DE
  JP PrintInlineSkip

; DrawBox's box: width and height in characters
BoxDims:
  DEFB $18,$18

; Draw a window frame from icon tiles $38-$3F: row, column, width, height at
; (HL)
;
; The corners and edges are icon tiles: top $38 $39 $3A, sides $3F $3B, bottom
; $3E $3D $3C; the inside is left alone. Sets PrintCol/PrintRow at the corner.
; It also patches $5F0F (BoxRowRight+9) with the box's column, a fourth
; self-modified operand. L1 193.
DrawBox:
  LD B,(HL)
  INC HL
  LD C,(HL)
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (PrintCol),BC
  LD (BoxDims),DE
  LD A,(PrintCol)
  LD (BoxRowRight+$0009),A
  LD A,$38
  LD B,$39
  LD C,$3A
  CALL DrawBoxRow
  LD A,(BoxDims+$0001)
  SUB $02
  LD B,A
DrawBoxSides:
  PUSH BC
  LD A,$3F
  LD B,$20
  LD C,$3B
  CALL DrawBoxRow
  POP BC
  DJNZ DrawBoxSides
  LD A,$3E
  LD B,$3D
  LD C,$3C
  CALL DrawBoxRow
  RET

; One byte no code reads; kept as bytes
BoxSpare:
  DEFB $01

; One row of a frame: tile A, BoxDims-2 tiles B (a space: skipped), tile C,
; then PrintRow + 1
;
; The three tiles are written into the operands of the three LD A,n below
; (self-modified, $5EE9, $5EF9, $5F07). L1 3154.
DrawBoxRow:
  LD (BoxRowLeft+$0001),A
  LD A,B
  LD (BoxRowFill+$0001),A
  LD A,C
  LD (BoxRowRight+$0001),A
  LD BC,(PrintCol)
  CALL ScreenAddr
  LD (PrintAddr),HL
BoxRowLeft:
  LD A,$5C                ; LD A,left
  CALL DrawIconHere
  LD A,(BoxDims)
  SUB $02
  LD B,A
BoxRowMiddle:
  PUSH BC
  LD HL,PrintAddr
  INC (HL)
BoxRowFill:
  LD A,$20                ; LD A,middle: $20 is left out (the box's inside)
  CP $20
  CALL NZ,DrawIconHere
  POP BC
  DJNZ BoxRowMiddle
  LD HL,PrintAddr
  INC (HL)
BoxRowRight:
  LD A,$5E                ; LD A,right
  CALL DrawIconHere
  LD HL,PrintCol
  LD (HL),$00
  INC HL
  INC (HL)
  RET

; Draw the menu bar, the status box, the city name, funds, tool palette, tool
; name and date
;
; The menu bar "SYSTEM OPTIONS DISASTERS WINDOWS" at row 0 (attribute 7), the
; box rows 3-7, then DrawNameFunds, DrawToolIcons, ShowTool, PrintToolName,
; PrintDate, PrintFunds. L1 34 (the first draw and after each window).
DrawStatusPanel:
  CALL PrintInline

; PrintInline codes: the menu bar (SYSTEM OPTIONS DISASTERS WINDOWS)
StatusBarText:
  INCBIN "res/text/inline/StatusBar.bin",$0000,42

; The status box: rows 3-7 of the top third (attribute $38), then the name, the
; tools, the date, the funds
DrawStatusBox:
  CALL PrintInline

; PrintInline codes: the status box
StatusBoxText:
  DEFB $FB,$38,$FD,$03,$00,$20,$05,$FB,$39,$FE

; The name, the funds, the tool palette, the tool name and the date
DrawStatusItems:
  CALL DrawNameFunds
  CALL DrawToolIcons
  CALL ShowTool
  CALL PrintToolName
  CALL PrintDate
  CALL PrintFunds
  RET

; Print the city name (12 letters, CityName $5F68) at row 5, column 1, and
; "FUNDS" with the dollar sign at row 5, column 17
;
; CityName lies inside the inline text: typing a name writes these bytes
; (InputName $A6F9), so the text prints the current name. L1 35.
DrawNameFunds:
  CALL PrintInline

; PrintInline codes: attribute $39, row 5, column 1 (the name follows)
CityNameAt:
  DEFB $FB,$39,$FF,$05,$01
CityName:
  DEFB $48,$45,$52,$45,$53 ; the city's name, 12 letters, "HERESVILLE  " in the
  DEFB $56,$49,$4C,$4C,$45 ; image; InputName edits only 11 and the 12th letter
  DEFB $20,$20,$FF,$05,$11 ; is not saved (SaveCityName holds 11)
  DEFB $46,$55,$4E,$44,$53
  DEFB $20,$24,$FE

; RET
DrawNameFundsEnd:
  RET

; Print Funds ($8F97, 24 bits) at row 5, column 24
;
; L1 9918: every month and every purchase.
PrintFunds:
  LD BC,$0518
  LD HL,Funds
  CALL PrintNumberVar
  RET

; The twelve months, three letters each, bit 7 on the last
MonthNames:
  INCBIN "res/text/MonthNames.bin",$0000,36

; Print the month (MonthNames by Month $8F9B) at row 4, column 23 and the year
; ($8F9C) after it
;
; L1 9917.
PrintDate:
  LD A,(Month)
  LD HL,MonthNames
  CALL FindText
  LD BC,$0417
  LD A,$03
  CALL PrintPadded
  LD HL,(Year)
  CALL Print4Digits
  RET

; The tool names with prices, the levels, the six city classes, the 27 advice
; and disaster messages
;
; 50 strings, bit 7 on each last letter, found by FindText $6317 by index: 0-13
; the tools ("BULLDOZE" with its price, 1 dollar, ... "AIRPORT", 10 000
; dollars), 14-16 the levels (EASY, MEDIUM, HARD), 17-22 the classes (VILLAGE
; ... MEGALOPOLIS), 23 a space, 24-49 the advice and disasters ("MORE
; RESIDENTIAL ZONES NEEDED" ... "TORNADO DETECTED"). Read by PrintToolName, the
; level name, the class name and the advice (L1 1 602 984 reads, every byte).
GameTexts:
  INCBIN "res/text/GameTexts.bin",$0000,831

; Print the current tool's name and price (GameTexts by CurrentTool) at row 4,
; column 1, padded to 20 columns
;
; L1 99.
PrintToolName:
  LD HL,GameTexts
  LD A,(CurrentTool)
  CALL FindText
  LD BC,$0401
  LD A,$13
  CALL PrintPadded
  RET

; HL = the A-th (from 0) bit-7-ended string of the table at HL
;
; L1 14 996.
FindText:
  AND A
  RET Z
  LD E,$00
  LD D,A
FindTextLoop:
  BIT 7,(HL)
  JR Z,FindTextNext
  INC E
  LD A,D
  CP E
  JR NZ,FindTextNext
  INC HL
  RET
FindTextNext:
  INC HL
  JR FindTextLoop

; Print the string at HL at row B, column C, then spaces to A + 1 columns (C
; counts down from A for each letter but the last)
;
; L1 14 996.
PrintPadded:
  PUSH AF
  PUSH HL
  CALL ScreenAddr
  LD (PrintAddr),HL
  POP HL
  POP AF
  LD C,A
PrintPaddedLoop:
  LD A,(HL)
  AND $7F
  PUSH HL
  PUSH BC
  CALL PrintGlyph
  CALL NextColumn
  POP BC
  POP HL
  BIT 7,(HL)
  JR NZ,PrintPaddedPad
  INC HL
  DEC C
  JR PrintPaddedLoop
PrintPaddedPad:
  LD A,C
  AND A
  RET Z
  RET M
  LD B,A
PrintPaddedSpace:
  PUSH BC
  LD A,$20
  CALL PrintGlyph
  CALL NextColumn
  POP BC
  DJNZ PrintPaddedSpace
  RET
