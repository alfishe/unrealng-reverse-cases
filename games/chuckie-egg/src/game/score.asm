; --------------------------------------------------------------------------------------------------------------------
; score.asm: The score and the extra life
;
; AddScore is the only writer of the score.
; --------------------------------------------------------------------------------------------------------------------

; Add B x 10 points; an extra life every 10 000; print the score
;
; Input: B the tens to add (0: only print). The tens digit (Score + 4) goes up
; B times with the carry through the digits before. When the 10 000s digit
; (Score + 1) differs from LastTenThousands: the player's lives + 1, and with
; fewer than six an icon $B6 at row 22, column 4 + lives + 7 x (player - 1).
; Then the six digits are printed at ScoreScreenAddr with CharacterSet's digits
; (from $8670).
;
; Witness: 5 659 calls; the 10 000s digit changed 6 times ($A3C4), one icon
; drawn ($A3D7; levels-1-9, level 4: lives 5 to 6, as the stage 1 notes saw).
AddScore:
  LD A,B
  AND A
  JR Z,AddScorePrint
  LD A,$0A
AddScoreTen:
  LD HL,Score+4
AddScoreDigit:
  INC (HL)
  CP (HL)
  JR NZ,AddScoreNext
  LD (HL),$00
  DEC HL
  JR AddScoreDigit
AddScoreNext:
  DJNZ AddScoreTen
  LD HL,LastTenThousands
  LD A,(Score+1)
  CP (HL)
  JR Z,AddScorePrint
  LD (HL),A
  LD A,(Player)
  ADD A,$EF
  LD H,$6E
  LD L,A
  LD C,(HL)
  INC (HL)
  SUB $EF
  LD B,A
  LD A,C
  CP $06
  JR NC,AddScorePrint
  LD A,$FD
AddScoreIconColumn:
  ADD A,$07
  DJNZ AddScoreIconColumn
  ADD A,C
  LD L,A
  LD H,$16
  LD A,$B6
  CALL PrintChar
AddScorePrint:
  LD DE,(ScoreScreenAddr)
  LD BC,Score
  LD IXL,$06
AddScorePrintDigit:
  PUSH DE
  LD A,(BC)
  SLA A
  SLA A
  SLA A
  PUSH BC
  ADD A,$70
  LD H,$86
  LD L,A
  LD B,$08
AddScorePrintLine:
  LD A,(HL)
  LD (DE),A
  INC D
  INC L
  DJNZ AddScorePrintLine
  POP BC
  POP DE
  INC DE
  INC BC
  DEC IXL
  JR NZ,AddScorePrintDigit
  RET

; A zero
;
; Never read (L1: no access).
LeftoverA40F:
  DEFB $00
