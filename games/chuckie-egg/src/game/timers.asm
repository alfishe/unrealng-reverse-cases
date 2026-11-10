; --------------------------------------------------------------------------------------------------------------------
; timers.asm: The bonus and the time
;
; Both count down in the HUD; the bonus stops at 0, the time ends the life.
; --------------------------------------------------------------------------------------------------------------------

; Take one from the bonus (B = 0) or the time (B = 1) and print it
;
; The last of the three digits (BonusDigits + 2 or TimeDigits + 2) goes down by
; one, borrowing from the digits before. Under 000: the bonus sets BonusRunning
; to 0 and stops; the time drops MainLoop's return address and returns to its
; caller (the life ends; LifeLost prints OUT OF TIME, the digits are $FF 9 9).
; Otherwise the three digits are printed with HudCharacters at $4053 (the
; bonus) or $405D (the time).
;
; Witness: 17 679 calls; 20 under-runs ($A1CE): 19 of the bonus ($A1D2), one of
; the time (tour-redefine).
CountDown:
  LD HL,BonusDigits+2
  LD DE,$0003
  INC B
  DEC B
  JR Z,CountDownDigit
  ADD HL,DE
CountDownDigit:
  LD A,$FF
  LD D,$03
CountDownLoop:
  DEC (HL)
  CP (HL)
  JR NZ,CountDownPrint
  DEC D
  JR NZ,CountDownBorrow
  POP HL
  INC B
  DEC B
  RET NZ
  PUSH HL
  LD HL,BonusRunning
  LD (HL),$00
  RET
CountDownBorrow:
  LD (HL),$09
  DEC HL
  JR CountDownLoop
CountDownPrint:
  LD DE,$000A
  LD HL,Screen+83
  INC B
  DEC B
  JR Z,CountDownPrintAt
  ADD HL,DE
CountDownPrintAt:
  EX DE,HL
  LD HL,BonusDigits
  INC B
  DEC B
  JR Z,CountDownPrintDigits
  INC HL
  INC HL
  INC HL
CountDownPrintDigits:
  PUSH HL
  POP BC
  LD IXL,$03
CountDownPrintDigit:
  PUSH DE
  LD A,(BC)
  SLA A
  SLA A
  SLA A
  LD HL,HudCharacters
  PUSH BC
  LD B,$00
  LD C,A
  ADD HL,BC
  LD B,$08
CountDownPrintLine:
  LD A,(HL)
  LD (DE),A
  INC D
  INC L
  DJNZ CountDownPrintLine
  POP BC
  POP DE
  INC DE
  INC BC
  DEC IXL
  JR NZ,CountDownPrintDigit
  RET

; Leftover: RET, 0
;
; Never read (L1: no access).
LeftoverA21A:
  DEFB $C9,$00
