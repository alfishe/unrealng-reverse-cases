; The print routine's screen address
;
; The bitmap address of the next character cell, kept in memory because the
; glyph copy needs B and DE. docs/08-hud-and-text.md 8.1.
PrintScreenPos:
  DEFW $50FC

; The print routine's attribute address
PrintAttrPos:
  DEFW $5AFC

; Print a string of records
;
; HL = the string: records of attribute + $80, column, row, characters $20-$5F;
; the next byte with bit 7 set starts a new record, $FF ends the string. Glyphs
; from the font at $6300, 8 lines each. docs/08-hud-and-text.md 8.1.
PrintString:
  LD A,(HL)
PrintRecord:
  CP $FF
  RET Z
  RES 7,A                 ; the attribute, kept in A'
  EX AF,AF'
  LD D,$40                ; the screen third by the row: $40, $48 or $50
  INC HL
  LD E,(HL)
  LD C,E
  INC HL
  LD A,(HL)
  LD B,A
  CP $08
  JR C,RowInThird
  SUB $08
  LD D,$48
  CP $08
  JR C,RowInThird
  SUB $08
  LD D,$50
RowInThird:
  RRCA                    ; (row AND 7) * 32 + column
  RRCA
  RRCA
  ADD A,E
  LD E,A
  LD (PrintScreenPos),DE
  INC HL
  EX DE,HL
  LD L,B                  ; attribute address: $5800 + row * 32 + column
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD B,$58
  ADD HL,BC
  LD (PrintAttrPos),HL
  EX DE,HL
PrintCharLoop:
  LD A,(HL)               ; a character, or bit 7: the next record
  BIT 7,A
  JR NZ,PrintRecord
  PUSH HL
  SUB $20                 ; glyph: $6300 + (code - $20) * 8
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,Font
  ADD HL,BC
  LD B,$08
  LD DE,(PrintScreenPos)
GlyphLineLoop:
  LD A,(HL)               ; 8 lines down the cell
  LD (DE),A
  INC D
  INC HL
  DJNZ GlyphLineLoop
  LD DE,(PrintAttrPos)
  EX AF,AF'               ; the attribute
  LD (DE),A
  EX AF,AF'
  INC E
  LD (PrintAttrPos),DE
  LD DE,(PrintScreenPos)  ; the next cell
  INC E
  LD (PrintScreenPos),DE
  POP HL
  INC HL
  JR PrintCharLoop

; Add B tens of points to SCORE
;
; SCORE is ASCII ($EF49-$EF4E, the last digit a fixed '0'): one ten at a time,
; a space counting as '0', with carry to the left. Falls into $EE9E.
; docs/08-hud-and-text.md 8.4.
AddPoints:
  LD HL,Score+$0004       ; the tens digit
AddTenToDigit:
  LD A,(HL)
  CP $20                  ; a leading space counts as 0
  JR NZ,DigitUp
  LD A,$30
DigitUp:
  INC A
  CP $3A
  JR C,StoreDigit
  LD (HL),$30             ; carry into the next digit to the left
  DEC HL
  JR AddTenToDigit
StoreDigit:
  LD (HL),A
  DJNZ AddPoints          ; B times

; Draw SCORE in the panel
;
; SCORE's digits at $529D in small digits ($EEA4). Called by the round setup
; $D151 too.
ShowScore:
  LD DE,$529D
  LD BC,$EF4E

; Draw a number in small digits, right to left
;
; DE = the screen address of the units digit, BC = its character. Draws to the
; left until a '.' byte before the field, each digit from lines 2-6 of its
; glyph ($6302 + (code - $20) * 8). docs/08-hud-and-text.md 8.4.
DrawDigits:
  LD A,(BC)
  CP $2E                  ; '.': the field starts here
  RET Z
  PUSH BC
  SUB $20
  LD H,$00
  LD L,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,$6302             ; lines 2-6 of the glyph
  ADD HL,BC
  LD C,D
  LD B,$05
SmallDigitLineLoop:
  LD A,(HL)
  LD (DE),A
  INC D
  INC HL
  DJNZ SmallDigitLineLoop
  LD D,C
  DEC E
  POP BC
  DEC BC
  JR DrawDigits

; Clear SCORE, MAX and the round table
;
; Spaces into the round table entries of rounds 1-10 ($EF55, 60 bytes), SCORE
; and MAX; HIGH is kept. Called by the menu $F1AA when it is entered, not after
; the demo. docs/08-hud-and-text.md 8.4.
ClearScores:
  LD HL,RoundTable+$0006
  LD B,$3C
ClearRoundTableLoop:
  LD (HL),$20
  INC HL
  DJNZ ClearRoundTableLoop
  LD HL,Score
  LD B,$05
ClearScoreLoop:
  LD (HL),$20
  INC HL
  DJNZ ClearScoreLoop
  LD HL,MaxScore
  LD B,$05
ClearMaxLoop:
  LD (HL),$20
  INC HL
  DJNZ ClearMaxLoop
  RET

; MAX into HIGH if higher, and draw HIGH
;
; First updates MAX from SCORE ($EF17). Then compares MAX with HIGH digit by
; digit as strings (a space sorts below the digits) and copies MAX into HIGH
; when it is higher. HIGH is drawn at $51FD. Called by the menu $F1AA when it
; is entered, not after the demo. docs/08-hud-and-text.md 8.4,
; docs/10-gameplay-logic.md 10.7.
UpdateHigh:
  CALL UpdateMax
  LD HL,MaxScore
  LD DE,HighScore
  LD B,$05
HighCompareLoop:
  PUSH BC                 ; the first digit that differs decides
  LD A,(DE)
  LD B,A
  INC DE
  LD A,(HL)
  INC HL
  CP B
  JR NZ,HighDigitDiffers
  POP BC
  DJNZ HighCompareLoop
  JR DrawHigh
HighDigitDiffers:
  CP B
  JR NC,MaxIntoHigh
  POP BC
  JR DrawHigh
MaxIntoHigh:
  POP BC                  ; MAX is higher
  LD HL,MaxScore
  LD DE,HighScore
  LD BC,$0005
  LDIR
DrawHigh:
  LD DE,$51FD             ; HIGH in the panel
  LD BC,$EF97
  JP DrawDigits

; SCORE into MAX if higher, and draw MAX
;
; The same string compare, SCORE against MAX; MAX is drawn at $51BD. Called by
; the round setup $D151, at every loss ($CF33) and by $EEE3.
; docs/10-gameplay-logic.md 10.7.
UpdateMax:
  LD HL,Score
  LD DE,MaxScore
  LD B,$05
MaxCompareLoop:
  PUSH BC
  LD A,(DE)
  LD B,A
  INC DE
  LD A,(HL)
  INC HL
  CP B
  JR NZ,MaxDigitDiffers
  POP BC
  DJNZ MaxCompareLoop
  JR DrawMax
MaxDigitDiffers:
  CP B
  JR NC,ScoreIntoMax
  POP BC
  JR DrawMax
ScoreIntoMax:
  POP BC                  ; SCORE is higher
  LD HL,Score
  LD DE,MaxScore
  LD BC,$0005
  LDIR
DrawMax:
  LD DE,$51BD             ; MAX in the panel
  LD BC,$EF9E
  JP DrawDigits

; '.': the left end of SCORE for $EEA4
ScoreStop:
  DEFB $2E

; SCORE: five characters and a fixed '0'
;
; Six ASCII characters; leading spaces stay spaces until a carry reaches them.
; docs/08-hud-and-text.md 8.4.
Score:
  DEFM "     0"

; The round table: 6 bytes a round, rounds 0-10
;
; Each entry: the lives at the round's start, then SCORE's five characters at
; that moment. $D151 writes a round's entry at every setup; a lost life or a
; fall back restores SCORE from it. docs/04-game-loop.md 4.2, 4.4.
RoundTable:
  DEFB $20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20
  DEFB $20,$20,$20,$20,$20,$20

; '.': the left end of HIGH
HighStop:
  DEFB $2E

; HIGH: kept until the machine is reset
HighScore:
  DEFM "     0"

; '.': the left end of MAX
MaxStop:
  DEFB $2E

; MAX: the best SCORE of this game
MaxScore:
  DEFM "     0"

; The end of the draw list at $6500
;
; Written by $EFA5 and $F089.
DrawListEnd:
  DEFW $0000

; The end of the depth list at $FF00
DepthListEnd:
  DEFW $0000

; The end of the static-object list at $C99E
StaticListEnd:
  DEFW $0000
