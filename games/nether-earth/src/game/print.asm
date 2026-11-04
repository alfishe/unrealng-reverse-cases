; Print A (0-99) as two digits, a leading zero blank
;
; Used by the routines at ShowMilesCode, DistanceShow, PrintMenuResourceValue
; and PrintResourceValues.
PrintNumber2:
  LD L,A
  LD H,$00
  LD E,$20
  JR PrintTensUnits

; Print A (0-99) as two digits with a leading zero
;
; The clock ($AD90, 6828 calls: "20.20") and the robot counts of the panel.
PrintNumber2Zero:
  LD L,A
  LD H,$00
  LD E,$00
  JR PrintTensUnits

; Print HL as five digits, leading zeros blank
;
; Used by $AD90 for the day number ("DAY:    4"). Falls into PrintNumber3.
PrintNumber5:
  LD BC,$D8F0             ; -10000
  LD E,$20
  CALL PrintDigit
  LD BC,$FC18             ; -1000
  CALL PrintDigit

; Print HL as three digits (E = $20: leading zeros blank, else printed)
;
; The operand $FF9C is -100 (main.asm shows it as Buildings+155: a false
; symbol). Used by PrintMenuTotal and $A833.
PrintNumber3:
  LD BC,-$0064            ; -100
  CALL PrintDigit

; Print the tens and the units of HL
;
; Used by the routines at PrintNumber2 and PrintNumber2Zero.
PrintTensUnits:
  LD BC,$FFF6             ; -10
  CALL PrintDigit
  LD A,L                  ; the units digit, always printed
  ADD A,$30
  JP PrintCharKeep

; Print the digit of HL for the power -BC; HL keeps the rest
;
; Counts how often BC (a negative power of 10) can be added. A zero while E =
; $20 prints a space and keeps E; any printed digit increments E, so later
; zeros print as 0.
PrintDigit:
  XOR A
DigitCountLoop:
  ADD HL,BC
  INC A
  JR C,DigitCountLoop
  SBC HL,BC               ; one too far: undo
  DEC A
  JR NZ,DigitPrint
  LD A,E                  ; a leading zero
  CP $20
  JP Z,PrintCharKeep      ; blank: E = $20 is the space
  XOR A
DigitPrint:
  INC E                   ; a digit: no more leading zeros, print "0" + A
  ADD A,$30

; PrintChar A with BC, DE, HL kept (EXX around)
;
; Used by the routines at ShowStrengthValue, GameTurnEnd, CheckSpaceKey,
; PrintDigitColumn, PrintTensUnits and PrintDigit.
PrintCharKeep:
  EXX
  CALL PrintChar
  EXX
  RET

; print the text after the CALL: 0 ends, 1 Y X a position, 2 A an attribute, 3
; the next line, 4 N a setting, else a character
;
; Used by the routines at RobotMenuShow, ShowOrder, ShowOrderMiles,
; ShowStrength, OrdersMenu, OrdersMenuChoose, RetreatTitle, DistanceMenu,
; DistanceSelect, TargetMenu, CaptureMenu, SetOrder, GameTurn, CheckGameEnd,
; GameWon, MainMenuOptions, MenuKeyboardOption, MenuKempstonOption,
; MenuInterface2Option, PrintTitle, PrintTitleEnd, LoadGameBlocks, SaveGame,
; ControlsOptionAttr, ControlsOptionPlain, RedefineKeys, PrintKeyPrompt,
; PrintKeyPromptName, DefineKey, DefineKeyScan, CheckEnterKey,
; CheckCapsShiftKey, CheckSpaceKey, ConstructionMenu, PrintMenuResources,
; PrintMenuResource, DrawPlayScreen, ShowStatusPanel, UpdateStatusPanel,
; PrintResourceValues, PrintInsgCounts, PrintHumnCounts, ClearPanel and
; ClearPanelLine.
PrintInline:
  EXX
PrintInlineLoop:
  POP HL                  ; the next byte after the CALL: the return address
                          ; moves with it
  LD A,(HL)
  INC HL
  PUSH HL
  OR A
  JR Z,PrintInlineEnd
  CALL PrintControl       ; a control code or a character
  JR PrintInlineLoop
PrintInlineEnd:
  EXX                     ; 0: return past the string
  RET

; PrintInline's byte A: control codes 1-4 or a character
;
; 1 Y X: the position (row Y, column X, kept in $FD32/$FD31). 2 A: the
; attribute $FD13. 3: newline (the next row, the same column). 4 N: the size,
; high nibble the height in character rows ($FD16), low nibble the width in
; bytes ($FD17); 0 = normal. A character goes to PrintChar for size 0, else to
; PrintBigChar. The operands are read through the caller's return address on
; the stack, two levels up.
PrintControl:
  CP $01
  JR Z,SetPosition
  CP $02
  JR Z,SetAttr
  CP $03
  JR Z,PrintNewline
  CP $04
  JR Z,SetSize
  LD C,A                  ; a character
  LD A,(PrintWidth)
  OR A
  LD A,C
  JR Z,PrintChar          ; size 0: normal
  JP PrintBigChar
SetAttr:
  POP DE                  ; 2 A
  POP HL
  LD A,(HL)
  INC HL
  PUSH HL
  PUSH DE
  LD (PrintAttr),A
  RET
SetPosition:
  POP DE                  ; 1 Y X
  POP HL
  LD B,(HL)
  INC HL
  LD C,(HL)
  LD (PrintColumn),BC
  INC HL
  PUSH HL
  PUSH DE
  JP SetPrintPos

; The next print row, the same column
;
; Used by the routines at GameTurnEnd, ReadFireKey, PrintResourceValues,
; PrintDigitColumn and PrintControl.
PrintNewline:
  LD BC,(PrintColumn)
  INC B
  LD (PrintColumn),BC
  JP SetPrintPos
; This entry point is used by the routine at PrintControl.
SetSize:
  POP DE                  ; 4 N: height nibble, width nibble
  POP HL
  LD A,(HL)
  INC HL
  PUSH HL
  PUSH DE
  LD C,A
  RRCA
  RRCA
  RRCA
  RRCA
  AND $0F
  LD (PrintHeight),A
  LD A,C
  AND $0F
  LD (PrintWidth),A
  RET

; Print position: B = row, C = column -> $FD04 the screen address, $FD14 the
; attribute address
;
; Used by the routines at PrintControl and PrintNewline.
SetPrintPos:
  LD A,B
  AND $F8
  ADD A,$40
  LD H,A
  LD A,B
  AND $07
  RRCA
  RRCA
  RRCA
  ADD A,C
  LD L,A
  LD (PrintAddr),HL
  LD A,H
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  LD (PrintAttrAddr),HL
  RET

; Print character A at the print position in the print attribute, advance one
; column
;
; The font is at $6680 + 8*code ($6780 for the space, right after the view
; buffer). 8 lines into ($FD04), the attribute ($FD13) into ($FD14), both
; advanced.
PrintChar:
  LD H,$00
  LD L,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,Font-$100         ; the font
  ADD HL,DE
  LD DE,(PrintAddr)
  PUSH DE
  LD B,$08
GlyphLineLoop:
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  DJNZ GlyphLineLoop
  POP DE
  INC DE
  LD (PrintAddr),DE
  LD HL,(PrintAttrAddr)
  LD A,(PrintAttr)
  LD (HL),A
  INC HL
  LD (PrintAttrAddr),HL
  RET

; Print character A scaled: each line repeated $FD16 times, width 1 or 2 bytes
; ($FD17)
;
; Width 1: each glyph line written $FD16 times (2: a character two rows high,
; "RADAR:"). Width 2: each glyph byte doubled to 16 bits. Then the screen
; address moves on by the width and a block of width x height attribute cells
; gets $FD13. 180 calls in the deep recording.
PrintBigChar:
  LD H,$00
  LD L,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,Font-$100
  ADD HL,DE
  LD A,(PrintWidth)
  CP $02                  ; width 2: doubled pixels
  JR NC,WideChar
  EX DE,HL
  LD HL,(PrintAddr)
  LD C,$08
TallLineLoop:
  LD A,(PrintHeight)
  LD B,A
TallRepeatLoop:
  LD A,(DE)
  LD (HL),A
  CALL NextScreenLine
  DJNZ TallRepeatLoop
  INC DE
  DEC C
  JR NZ,TallLineLoop
  JR BigCharAttrs
WideChar:
  PUSH IX
  PUSH HL
  POP IX
  LD HL,(PrintAddr)
  LD C,$08
WideLineLoop:
  LD A,(IX+$00)
  LD B,$08
WideBitLoop:
  RLCA                    ; each bit twice into DE
  PUSH AF
  RL E
  RL D
  POP AF
  RL E
  RL D
  DJNZ WideBitLoop
  LD A,(PrintHeight)
  LD B,A
WideRepeatLoop:
  LD (HL),D
  INC L
  LD (HL),E
  DEC L
  CALL NextScreenLine
  DJNZ WideRepeatLoop
  INC IX
  DEC C
  JR NZ,WideLineLoop
  POP IX
BigCharAttrs:
  LD HL,(PrintAddr)           ; advance, then the attribute block
  LD A,(PrintWidth)
  CALL AddAToHL
  LD (PrintAddr),HL
  LD HL,(PrintAttrAddr)
  PUSH HL
  LD BC,(PrintHeight)
  LD A,(PrintAttr)
  LD E,A
BigAttrRowLoop:
  PUSH HL
  PUSH BC
BigAttrCellLoop:
  LD (HL),E
  INC HL
  DJNZ BigAttrCellLoop
  POP BC
  POP HL
  LD A,L
  ADD A,$20
  LD L,A
  LD A,H
  ADC A,$00
  LD H,A
  DEC C
  JR NZ,BigAttrRowLoop
  POP HL
  LD A,B
  CALL AddAToHL
  LD (PrintAttrAddr),HL
  RET
