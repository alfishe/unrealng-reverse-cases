; --------------------------------------------------------------------------------------------------------------------
; score.asm: The score and the high score
; --------------------------------------------------------------------------------------------------------------------

  ORG $BCDE

; Negate the 32-bit number at HL-3..HL (two's complement) for the printer
;
; CPL on the four bytes from HL down, then + 1 through AddToNumber ($BD15 with
; DE = 1, IX the number). Called by PrintNumber $BD78 when the number is
; negative ($BD9D); not executed in any recording (c1, explorers, gameover, the
; 31 rzx builds). No minus sign is printed: known only from the code.
;
; Witness: L1 0 ().
NegateNumber:
  LD A,(HL)
  CPL
  LD (HL),A
  DEC HL
  LD A,(HL)
  CPL
  LD (HL),A
  DEC HL
  LD A,(HL)
  CPL
  LD (HL),A
  DEC HL
  LD A,(HL)
  CPL
  LD (HL),A
  LD DE,$0001
  JR AddToNumber

; Add DE (signed) to the score and print it, every register kept
;
; DE = the points (+50 a pickup $BBE9, +75 the crystal $BA2A, +150 the Silver
; Cross $B538 and each gift $B5FE, from GameInit $8FCC, $A851 +75). Saves IX,
; IY, HL, BC, AF and the alternate HL, BC, DE; AddToScore $BD11, PrintScore
; $BD75.
;
; Witness: L1 46 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
AddScore:
  PUSH IX
  PUSH IY
  PUSH HL
  PUSH BC
  PUSH AF
  EXX
  PUSH HL
  PUSH BC
  PUSH DE
  EXX
  CALL AddToScore
  CALL PrintScore
  EXX
  POP HL
  POP BC
  POP DE
  EXX
  POP AF
  POP BC
  POP HL
  POP IY
  POP IX
  RET

; Score $5C18 (32 bits) + DE, sign-extended
;
; IX = Score $5C18, then AddToNumber $BD15: BC = $FFFF when DE is negative,
; else 0; the low word + DE, the high word + BC with the carry. Out: HL the new
; high word.
;
; Witness: L1 46 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
AddToScore:
  LD IX,Score
; This entry point is used by the routine at NegateNumber.
AddToNumber:
  LD BC,$FFFF             ; IX = the number, DE = the amount
  BIT 7,D
  JR NZ,AddToNumberLow
  LD BC,$0000
AddToNumberLow:
  LD L,(IX+$00)
  LD H,(IX+$01)
  ADD HL,DE
  LD (IX+$00),L
  LD (IX+$01),H
  LD L,(IX+$02)
  LD H,(IX+$03)
  ADC HL,BC
  LD (IX+$02),L
  LD (IX+$03),H
  RET

; Print HiScore $5B78 at screen $5049 (row 18, column 9)
;
; The printer's source operand PrintNumberSource+1 ($BD89) is pointed at
; HiScore $5B78 for one PrintNumber $BD78 call, then restored. Reached by JP
; from NewHiScore $BD72 only; split off as its own entry here (the cut ran it
; on from AddToScore's RET at $BD3A).
;
; Witness: L1 4 (c1, explorers, gameover, rzx).
PrintHiScore:
  LD HL,(PrintNumberSource+$0001)
  PUSH HL
  LD HL,HiScore
  LD (PrintNumberSource+$0001),HL
  LD HL,Screen+4169
  CALL PrintNumber
  POP HL
  LD (PrintNumberSource+$0001),HL
  RET

; Take the score as the high score if it is higher, and print it
;
; Compares Score $5C18 with HiScore $5B78 from the top byte ($5C1B, $5B7B)
; down; a negative score (bit 7 of $5C1B) never counts. Higher: the 4 bytes are
; copied and PrintHiScore $BD3B prints it. Called at the end of a game by
; $906D.
;
; Witness: L1 8 (c1, explorers, gameover, rzx). c1, explorers, gameover and
; rzx50000 each set a high score once ($BD67).
NewHiScore:
  LD HL,Score+3
  BIT 7,(HL)
  RET NZ
  LD DE,HiScore+3
  LD B,$04
NewHiScoreLoop:
  LD A,(DE)
  CP (HL)
  JR C,NewHiScoreTake
  JR Z,NewHiScoreNext
  RET
NewHiScoreNext:
  DEC HL
  DEC DE
  DJNZ NewHiScoreLoop
  RET
NewHiScoreTake:
  LD HL,Score
  LD DE,HiScore
  LD BC,$0004
  LDIR
  JP PrintHiScore

; Print Score $5C18 at screen $5029 (row 17, column 9)
;
; HL = $5029, then PrintNumber $BD78.
;
; Witness: L1 46 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
PrintScore:
  LD HL,Screen+4137

; Print a 32-bit number as four digits at HL, no leading zeros
;
; HL = the screen address. Four spaces are printed first ($90C6), then the
; number (Score $5C18, or the address in PrintNumberSource+1) is copied to
; NumberWork $5C1C and divided by 1000, 100, 10 and 1 (PlaceValues $BE18,
; DivideNumber $BDDF); each quotient is printed as the character '0' + q, the
; leading zeros as nothing (DigitShown $5C20), a last 0 always. A thousands
; quotient above 9 prints the character after '9' (known only from the code).
;
; Witness: L1 50 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
PrintNumber:
  PUSH HL
  LD B,$04
PrintNumberBlank:
  LD A,$20                ; four spaces
  CALL PrintChar
  DJNZ PrintNumberBlank
  POP HL
  EXX
  XOR A
  LD (DigitShown),A
PrintNumberSource:
  LD HL,Score             ; LD HL,n: n the number to print (Score $5C18;
                          ; PrintHiScore puts HiScore $5B78 here)
  LD DE,NumberWork
  LD BC,$0004
  LDIR
  EX DE,HL
  DEC HL
  LD IX,NumberWork
  BIT 7,(HL)
  JR Z,PrintNumberDigits
  CALL NegateNumber
  JR PrintNumberDigits
PrintNumberDigits:
  LD IY,PlaceValues
  LD B,$04
PrintNumberLoop:
  PUSH BC                 ; the next place value
  LD C,$00
  LD E,(IY+$00)
  LD D,(IY+$01)
  LD B,(IY+$02)
  INC IY
  INC IY
  INC IY
  CALL DivideNumber
  LD A,(DigitShown)
  OR A
  LD A,C
  JR NZ,PrintNumberDigit
  OR A
  JR Z,PrintNumberZero
  LD (DigitShown),A
PrintNumberDigit:
  ADD A,$30               ; '0' + the quotient
  EXX
  CALL PrintChar
  EXX
  POP BC
PrintNumberNext:
  DJNZ PrintNumberLoop
  RET
PrintNumberZero:
  POP BC                  ; a leading zero: only the last digit is printed
  LD A,B
  CP $01
  JR NZ,PrintNumberNext
  DEC A
  PUSH BC
  JR PrintNumberDigit

; C = how many times the 24-bit B:DE goes into the 32-bit number at IX
;
; Subtracts B:DE from IX+0..+3 until it goes below 0, then restores the last
; value. Out: C + the count (C = 0 on entry from PrintNumber), the number at IX
; the remainder.
;
; Witness: L1 501 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
DivideNumber:
  LD L,(IX+$00)
  LD H,(IX+$01)
  PUSH HL
  AND A
  SBC HL,DE
  LD (IX+$00),L
  LD (IX+$01),H
  LD A,(IX+$02)
  PUSH AF
  SBC A,B
  LD (IX+$02),A
  LD A,(IX+$03)
  PUSH AF
  SBC A,$00
  LD (IX+$03),A
  JR C,DivideNumberUndo
  POP AF
  POP AF
  POP HL
  INC C
  JR DivideNumber
DivideNumberUndo:
  POP AF                  ; below 0: restore the last value
  LD (IX+$03),A
  POP AF
  LD (IX+$02),A
  POP HL
  LD (IX+$01),H
  LD (IX+$00),L
  RET

; 1000, 100, 10, 1 as 24-bit numbers, low byte first
;
; Read by PrintNumber $BD78 (IY). Witness: every build that prints a score (21
; builds).
PlaceValues:
  DEFB $E8,$03,$00
  DEFB $64,$00,$00
  DEFB $0A,$00,$00
  DEFB $01,$00,$00
