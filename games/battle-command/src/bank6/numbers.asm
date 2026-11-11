; --------------------------------------------------------------------------------------------------------------------
; numbers.asm: Numbers to decimal digits
;
; Two converters: NumberToDigits $C126 for 16-bit numbers (five digits: the stores' weight and the grid position) and
; LongToDigits $D353 for the 32-bit score (ten digits).
; --------------------------------------------------------------------------------------------------------------------

  ORG $C126

; Write HL as five ASCII digits at HL', then replace the leading zeros at $D9AB
; with C'
;
; Input: HL the number, HL' the destination, C' the character for a leading
; zero. DigitOf `$C155` for 10000, 1000, 100 and 10, then the units. Then the
; five digits of PaddedDigits `$D9AB` from the left: each `0` becomes C' until
; the first other digit; a number 0 keeps its last `0`. Witness: L1 104 (c1,
; death, m2erbe, missions, play, play2).
NumberToDigits:
  LD DE,$2710
  CALL DigitOf
  LD DE,$03E8
  CALL DigitOf
  LD DE,$0064
  CALL DigitOf
  LD DE,$000A
  CALL DigitOf
  LD A,L
  ADD A,$30
  EXX
  LD (HL),A
  LD HL,PayloadText+$0002
  LD B,$05
BlankZeroLoop:
  INC HL
  LD A,(HL)
  CP $30
  JR NZ,BlankZeroDone
  LD (HL),C
  DJNZ BlankZeroLoop
  LD A,$30
  LD (HL),A
BlankZeroDone:
  RET

; One decimal digit: A = how many times DE goes into HL, stored at HL' as ASCII
;
; Input: HL, DE. Output: HL the remainder, HL' advanced. Witness: L1 416 (c1,
; death, m2erbe, missions, play, play2).
DigitOf:
  LD A,$FF
DigitCount:
  INC A
  AND A
  SBC HL,DE
  JR NC,DigitCount
  ADD HL,DE
  EXX
  ADD A,$30
  LD (HL),A
  INC HL
  EXX
  RET

  ORG $D353

; Write the 32-bit number HL'HL as ten ASCII digits at DE
;
; LongDigitOf `$D3B4` for each power of ten. Witness: L1 4 (m10, menu,
; missions).
LongToDigits:
  LD BC,$3B9A
  EXX
  LD BC,$CA00
  CALL LongDigitOf
  LD BC,$05F5
  EXX
  LD BC,$E100
  CALL LongDigitOf
  LD BC,$0098
  EXX
  LD BC,$9680
  CALL LongDigitOf
  LD BC,$000F
  EXX
  LD BC,$4240
  CALL LongDigitOf
  LD BC,$0001
  EXX
  LD BC,$86A0
  CALL LongDigitOf
  LD BC,$0000
  EXX
  LD BC,$2710
  CALL LongDigitOf
  LD BC,$0000
  EXX
  LD BC,$03E8
  CALL LongDigitOf
  LD BC,$0000
  EXX
  LD BC,$0064
  CALL LongDigitOf
  LD BC,$0000
  EXX
  LD BC,$000A
  CALL LongDigitOf
  EXX
  LD A,L
  ADD A,$30
  EXX
  LD (DE),A
  RET

; One digit of HL'HL by BC'BC, stored at DE
;
; Witness: L1 36 (m10, menu, missions).
LongDigitOf:
  XOR A
LongDigitLoop:
  SBC HL,BC
  EXX
  SBC HL,BC
  EXX
  JR C,LongDigitDone
  INC A
  JR LongDigitLoop
LongDigitDone:
  ADD HL,BC
  EXX
  ADC HL,BC
  ADD A,$30
  LD (DE),A
  INC DE
  RET
