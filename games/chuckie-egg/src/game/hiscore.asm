; --------------------------------------------------------------------------------------------------------------------
; hiscore.asm: The name entry
;
; The only place that uses the ROM's interrupt: under IM 1 the ROM scans the keyboard into LAST_K.
; --------------------------------------------------------------------------------------------------------------------

; Put the score at HL in the table and take a name
;
; Compares the score with the ten entries (CompareScore); not greater than any:
; D = 1, return. Else the entries below shift down, the name is cleared, the
; six digits copied; the Congratulations page (11 rows of 15, rows 23, 21 ..
; 3), DrawHiScores, colours, phrase 7. Then IM 1: the cursor $B7 at the entry's
; row (2 x rank + 1), column 16; HALT until KSTATE4 shows a new key; LAST_K
; ENTER ends, DELETE (12) erases back, codes $20 and up are stored and printed,
; nine at most. IM 2, D = 2.
;
; Witness: gameover-name (one entry, three characters $A8D5, ENTER $A8E4); 2
; calls. Known only from the code: DELETE ($A8C3 never ran).
EnterHiScore:
  PUSH BC
  PUSH AF
  PUSH HL
  LD B,$0A
  LD DE,HiScoreTable+$000A
EnterHiScoreCompare:
  CALL CompareScore
  DEC A
  JR Z,EnterHiScoreInsert
  LD C,$10
EnterHiScoreSkip:
  INC DE
  DEC C
  JR NZ,EnterHiScoreSkip
  DJNZ EnterHiScoreCompare
  POP HL
  POP AF
  POP BC
  LD D,$01
  RET
EnterHiScoreInsert:
  LD IXH,B
  LD HL,HiScoreTable+$0090
  DEC B
  JR Z,EnterHiScoreClear
  LD HL,$0000
  LD DE,$0010
EnterHiScoreShift:
  ADD HL,DE
  DJNZ EnterHiScoreShift
  PUSH HL
  POP BC
  LD DE,HiScoreTable+$009F
  LD HL,HiScoreTable+$008F
  LDDR
  INC HL
EnterHiScoreClear:
  LD B,$0A
EnterHiScoreClearByte:
  LD (HL),$00
  INC HL
  DJNZ EnterHiScoreClearByte
  LD BC,$0006
  PUSH HL
  POP DE
  POP HL
  PUSH HL
  PUSH DE
  LDIR
  LD C,$0B
  LD H,$17
  LD DE,Congratulations
EnterHiScorePageRow:
  LD L,$00
  LD B,$0F
EnterHiScorePageChar:
  LD A,(DE)
  INC DE
  CALL PrintChar
  INC L
  DJNZ EnterHiScorePageChar
  DEC H
  DEC H
  DEC C
  JR NZ,EnterHiScorePageRow
  CALL DrawHiScores
  LD HL,Attributes
  LD A,$03
  LD B,$0F
  LD C,$04
  CALL FillAttrBlock
  INC A
  LD C,$09
  CALL FillAttrBlock
  LD A,$02
  CALL FillAttrBlock
  CALL WaitPhrase
  LD A,$07
  CALL StartPhrase
  CALL WaitPhrase
  POP HL
  LD BC,$000A
  AND A
  SBC HL,BC
  EX DE,HL
  LD A,IXH
  SLA A
  INC A
  LD H,A
  IM 1
  LD L,$10
EnterHiScoreCursor:
  LD A,$B7
  CALL PrintChar
EnterHiScoreRelease:
  LD A,(KSTATE4)
  XOR $FF
  JR NZ,EnterHiScoreRelease
EnterHiScoreWait:
  HALT
  LD A,(KSTATE4)
  XOR $FF
  JR Z,EnterHiScoreWait
  LD A,(LAST_K)
  CP $0D
  JR Z,EnterHiScoreDone
  CP $0C
  JR NZ,EnterHiScoreChar
  LD A,L
  CP $10
  JR Z,EnterHiScoreWait
  XOR A
  DEC DE
  LD (DE),A
  CALL PrintChar
  DEC L
  JR EnterHiScoreCursor
EnterHiScoreChar:
  CP $20
  JR C,EnterHiScoreWait
  LD B,A
  LD A,L
  CP $19
  JR Z,EnterHiScoreWait
  LD A,B
  LD (DE),A
  CALL PrintChar
  INC L
  INC DE
  JR EnterHiScoreCursor
EnterHiScoreDone:
  POP HL
  POP AF
  POP BC
  LD D,$02
  IM 2
  RET
