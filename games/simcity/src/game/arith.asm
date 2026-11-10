; --------------------------------------------------------------------------------------------------------------------
; arith.asm: The number printers and the arithmetic
;
; Signed 24-bit printing, Sub24, Add24, Mul16 (a 24-bit product), Div24By8 and Div16.
; --------------------------------------------------------------------------------------------------------------------

; PrintAddr after the last number printed
NumberEnd:
  DEFW $0000

; HL (C = 0) in up to 7 digits at row B, column C
;
; Used by the routines at PrintBudget and ScoreOf.
PrintNumberHL:
  PUSH HL
  CALL ScreenAddr
  LD (PrintAddr),HL
  POP HL
  LD C,$00
  CALL PrintNumber24
  RET

; The 24-bit number at (HL) (low, middle, high) at row B, column C
;
; Used by the routines at PrintFunds, PrintBudget and PrintEvalFigures.
PrintNumberVar:
  PUSH HL
  CALL ScreenAddr
  LD (PrintAddr),HL
  POP HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD C,(HL)
  EX DE,HL

; CHL as a signed decimal, leading zeros left out and made up as trailing
; spaces
;
; Powers of ten from 1 000 000 down, each a 24-bit subtraction loop (Digit24).
; Used by every money and population figure. L1 28 400.
PrintNumber24:
  XOR A
  LD (NumberFlags),A
  LD (NumberFlags+$0001),A
  CALL PrintSign
  PUSH HL
  PUSH BC
  EXX
  POP BC
  POP HL
  LD B,$F0
  LD DE,Traffic+$06F0
  EXX
  CALL Digit24
  EXX
  LD B,$FE
  LD DE,Irradiate+$0002
  EXX
  CALL Digit24
  EXX
  LD B,$FF
  LD DE,CityMap+$14A0
  EXX
  CALL Digit24
  EXX
  LD B,$FF
  LD DE,UiStack+$045D
  EXX
  CALL Digit24
  EXX
  LD B,$FF
  LD DE,$FF9C
  EXX
  CALL Digit24
  EXX
  LD B,$FF
  LD DE,$FFF6
  EXX
  CALL Digit24
  EXX
  PUSH HL
  EXX
  POP HL
  LD B,L
  CALL PrintDigitB
  LD HL,(PrintAddr)
  LD (NumberEnd),HL
  LD A,(NumberFlags+$0001)
  AND A
  RET Z
  LD B,A
PrintNumberPad:
  PUSH BC
  LD A,$20
  CALL PrintGlyph
  CALL NextColumn
  POP BC
  DJNZ PrintNumberPad
  RET

; A negative CHL (bit 7 of C): print "-" and negate it
;
; L1 7 (the budget's negative balances).
PrintSign:
  BIT 7,C
  RET Z
  LD A,C
  CPL
  LD C,A
  LD A,H
  CPL
  LD H,A
  LD A,L
  CPL
  LD L,A
  LD DE,$0001
  ADD HL,DE
  LD A,C
  ADC A,$00
  LD C,A
  PUSH HL
  PUSH BC
  LD A,$2D
  CALL PrintChar
  CALL NextColumn
  POP BC
  POP HL
  RET

; A digit printed already; the leading zeros left out
NumberFlags:
  DEFB $00,$00

; B = how often B'DE' (a negative power of ten) goes into C'HL'; print it
; unless a leading zero
;
; Used by the routine at PrintNumber24.
Digit24:
  LD B,$00
Digit24Loop:
  INC B
  EXX
  ADD HL,DE
  LD A,C
  ADC A,B
  LD C,A
  EXX
  JR C,Digit24Loop
  EXX
  SBC HL,DE
  LD A,C
  SBC A,B
  LD C,A
  EXX
  DEC B
  LD A,(NumberFlags)
  AND A
  JR NZ,PrintDigitB
  LD A,B
  AND A
  JR Z,LeadingZero
  LD (NumberFlags),A

; Print the digit B
;
; Used by the routines at PrintNumber24 and Digit24.
PrintDigitB:
  LD A,B
  ADD A,$30
  LD (PrintCharCode),A
  CALL PrintChar
  JP NextColumn
; This entry point is used by the routine at Digit24.
LeadingZero:
  LD HL,NumberFlags+$0001
  INC (HL)
  RET

; CHL = CHL - BDE (24 bits); carry and sign as the high byte left them
;
; The one 24-bit subtraction: prices against Funds and the city class's
; thresholds both use it (stage 1: the POKE file's NOP NOP at $6681 breaks
; both). L1 25 262.
Sub24:
  AND A
  SBC HL,DE
  LD A,C
  SBC A,B
  LD C,A
  RET

; CHL = CHL + BDE (24 bits)
;
; L1 39 110.
Add24:
  ADD HL,DE
  LD A,C
  ADC A,B
  LD C,A
  RET

; CHL = HL x DE (24-bit product), shift and add
;
; L1 16 721.
Mul16:
  PUSH DE
  EXX
  POP DE
  LD HL,$0000
  LD C,L
  EXX
  LD C,H
  LD A,L
  LD B,$10
Mul16Loop:
  EXX
  ADD HL,HL
  RL C
  EXX
  SLA A
  RL C
  JR NC,Mul16Next
  EXX
  EX AF,AF'
  ADD HL,DE
  LD A,C
  ADC A,$00
  LD C,A
  EX AF,AF'
  EXX
  ADD HL,DE
Mul16Next:
  DJNZ Mul16Loop
  EXX
  PUSH HL
  PUSH BC
  EXX
  POP BC
  POP HL
  RET

; CHL = CHL / A, remainder in A
;
; L1 5831.
Div24By8:
  LD E,C
  LD B,$18
  LD C,A
  XOR A
Div24Loop:
  ADD HL,HL
  RL E
  RLA
  JR C,Div24Sub
  CP C
  JR C,Div24Next
Div24Sub:
  SUB C
  LD D,A
  INC HL
  LD A,E
  ADC A,$00
  LD E,A
  LD A,D
Div24Next:
  DJNZ Div24Loop
  LD C,E
  RET

; HL = HL / DE; HL = 0 when DE is 0
;
; L1 5092.
Div16:
  LD A,D
  OR E
  JR Z,Div16ByZero
  LD B,H
  LD C,L
  LD HL,$0000
  LD A,$10
Div16Loop:
  SCF
  RL C
  RL B
  ADC HL,HL
  SBC HL,DE
  JR NC,Div16Next
  ADD HL,DE
  DEC C
Div16Next:
  DEC A
  JR NZ,Div16Loop
  LD H,B
  LD L,C
  RET
Div16ByZero:
  LD HL,$0000
  RET
