; --------------------------------------------------------------------------------------------------------------------
; print.asm: Glyph print and the disabled number read-out
;
; PrintGlyph $C4BB prints one character of the ROM font for the Help pages. ShowCoords $C4D6 is a RET in front of
; PrintNumber3 $C4D7, a three-digit print MoveCursor $C1D5 calls three times a pass: the author's read-out of Explorer
; and the cursor's x and y at the top left of the screen, switched off by that RET.
; --------------------------------------------------------------------------------------------------------------------

; Print the ROM-font glyph of A at screen address HL; HL + 1
;
; The 8 bytes at $3C00 + 8 x A copied down the character cell (D + 1 a row).
; BC, DE kept; HL returns + 1. Called by PrintPage $C574 for each character,
; and by PrintNumber3 $C4D7 and PrintDigit $C52C (never executed).
;
; explorers: 3878 calls (the Help pages).
;
; Witness: L1 3878 (explorers).
PrintGlyph:
  PUSH BC
  PUSH DE
  PUSH HL
  EX DE,HL
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,RomCharSet
  ADD HL,BC
  LD B,$08
GlyphRowLoop:
  LD A,(HL)               ; 8 rows
  LD (DE),A
  INC D
  INC HL
  DJNZ GlyphRowLoop
  POP HL
  POP DE
  POP BC
  INC HL
  RET

; RET: the coordinate read-out switched off
;
; MoveCursor $C1D5 calls it three times a pass with A = Explorer, x, y and DE =
; $4040, $4000, $4020. The RET stops it in front of PrintNumber3 $C4D7, which
; would print A in decimal at DE.
;
; c1: 3381 runs (1127 x 3).
;
; Witness: L1 10377 (c1, explorers).
ShowCoords:
  RET

; Print A (0-255) as three decimal digits at DE, leading zeros as spaces after
; the number
;
; DigitBuffer $5BA6-$5BA8 gets the hundreds, tens and units as ASCII by
; repeated subtraction; the leading "0" digits are skipped (B counts them) and
; as many spaces printed after the digits (PrintGlyph $C4BB), so the field is
; always three characters. AF kept. Its CALL operands are in RelocTable, so it
; was live code once; ShowCoords' RET at $C4D6 cuts it off. Not executed in any
; recording (c1, explorers); known only from the code.
;
; Witness: L1 0 ().
PrintNumber3:
  PUSH AF
  LD HL,DigitBuffer
  LD (HL),$30
HundredsLoop:
  CP $64
  JR C,TensDigit
  SUB $64
  INC (HL)
  JR HundredsLoop
TensDigit:
  INC HL
  LD (HL),$30
TensLoop:
  CP $0A
  JR C,UnitsDigit
  SUB $0A
  INC (HL)
  JR TensLoop
UnitsDigit:
  INC HL
  LD (HL),$30
UnitsLoop:
  CP $01
  JR C,SkipLeadingZeros
  DEC A
  INC (HL)
  JR UnitsLoop
SkipLeadingZeros:
  LD HL,DigitBuffer
  LD A,$30
  LD B,$01
  CP (HL)
  JR NZ,PrintThreeDigits
  INC B
  INC HL
  CP (HL)
  JR NZ,PrintTwoDigits
  INC B
  INC HL
  JR PrintLastDigit
PrintThreeDigits:
  CALL PrintDigit
  INC HL
  INC E
PrintTwoDigits:
  CALL PrintDigit
  INC HL
  INC E
PrintLastDigit:
  CALL PrintDigit
  INC E
  EX DE,HL
  DJNZ PadSpaces
  JR PrintNumberDone
PadSpaces:
  LD A,$20                ; one space per zero skipped
  CALL PrintGlyph
  DJNZ PadSpaces
PrintNumberDone:
  POP AF
  RET

; Print the digit at (HL) at screen address DE
;
; PrintGlyph $C4BB with HL and DE kept. Called only by PrintNumber3 $C4D7: not
; executed in any recording.
;
; Witness: L1 0 ().
PrintDigit:
  PUSH HL
  PUSH DE
  LD A,(HL)
  EX DE,HL
  CALL PrintGlyph
  POP DE
  POP HL
  RET
