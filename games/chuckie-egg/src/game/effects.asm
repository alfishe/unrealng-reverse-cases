; --------------------------------------------------------------------------------------------------------------------
; effects.asm: Boxes, delays and messages
;
; The screen effects between the scenes: nested attribute boxes, the scrolled messages.
; --------------------------------------------------------------------------------------------------------------------

; An attribute rectangle of colour TextIndex
;
; Inputs: H, L a corner (row from the bottom, column), D the height, E the
; width. The four sides between (H, L) and (H - D, L + E) (AttrAddr $AA23).
; Registers kept. Witness: 1 056 calls.
DrawBox:
  PUSH AF
  PUSH HL
  PUSH BC
  PUSH DE
  PUSH HL
  POP BC
  CALL AttrAddr
  EX DE,HL
  LD A,B
  SUB H
  LD B,H
  LD H,A
  LD A,C
  ADD A,L
  LD C,L
  LD L,A
  CALL AttrAddr
  LD A,(TextIndex)
DrawBoxEdge:
  LD (DE),A
  LD (HL),A
  INC DE
  DEC HL
  DEC C
  JR NZ,DrawBoxEdge
  LD IXL,B
  LD BC,$0020
DrawBoxSide:
  LD (DE),A
  LD (HL),A
  AND A
  SBC HL,BC
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  DEC IXL
  JR NZ,DrawBoxSide
  POP DE
  POP BC
  POP HL
  POP AF
  RET

; Count BC down
;
; Witness: 39 283 calls.
Delay:
  PUSH AF
DelayLoop:
  DEC BC
  LD A,B
  OR C
  JR NZ,DelayLoop
  POP AF
  RET

; Twelve nested boxes from the edge in; IXH 2 in colours, 1 in black
;
; Colours from $12 stepping by 9 (IXH 2), or 3 throughout (IXH 1); Delay 5000
; between boxes. Witness: 20 calls.
BoxWipe:
  LD HL,$0C0B
  LD DE,$0109
  LD A,$12
  DEC IXH
  JR NZ,BoxWipeStart
  LD A,$03
BoxWipeStart:
  INC IXH
  LD B,$0C
BoxWipeBox:
  LD (TextIndex),A
  CALL DrawBox
  PUSH BC
  LD BC,$1388
  CALL Delay
  POP BC
  INC H
  DEC L
  INC D
  INC D
  INC E
  INC E
  DEC IXH
  JR Z,BoxWipeNext
  ADD A,$09
  CP $30
  JR C,BoxWipeNext
  LD A,$12
BoxWipeNext:
  INC IXH
  DJNZ BoxWipeBox
  RET

; Wait until no phrase plays
;
; Witness: 1 662 374 loops.
WaitPhrase:
  LD A,(PhraseTimer)
  XOR $FF
  JR NZ,WaitPhrase
  RET

; Boxes growing from the middle in four quadrants, twice
;
; The first round in colours (from 9, + 9 a box), the pixels cleared, the
; second in green (4). Delay 10000 a step. Witness: 17 calls (the level ends, a
; name entered).
BoxZoom:
  LD IXH,$00
  LD HL,TextIndex
  LD (HL),$09
BoxZoomRound:
  LD HL,$0605
  LD D,$01
BoxZoomStep:
  PUSH HL
  PUSH DE
  LD E,D
  CALL DrawBox
  LD A,$14
  ADD A,L
  LD L,A
  LD A,$0C
  ADD A,H
  LD H,A
  CALL DrawBox
  LD A,$08
  ADD A,E
  LD E,A
  LD A,L
  SUB $14
  LD L,A
  LD A,$08
  ADD A,E
  CALL DrawBox
  LD A,H
  SUB $0C
  LD H,A
  LD A,$0C
  ADD A,L
  LD L,A
  CALL BoxZoomBox
  POP DE
  POP HL
  INC E
  INC E
  INC D
  INC D
  INC H
  DEC L
  LD BC,$2710
  CALL Delay
  LD A,L
  CP $FF
  JR NZ,BoxZoomStep
  LD BC,$1800
  LD HL,Screen
BoxZoomClear:
  LD (HL),$00
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,BoxZoomClear
  LD A,IXH
  LD IXH,$01
  LD HL,TextIndex
  LD (HL),$04
  AND A
  JR Z,BoxZoomRound
  RET

; Scroll C characters from DE across row 11, then out
;
; Rows 11-14 green; ScrollLine at row 11 with the next character printed at
; column 30 every 8 shifts, then 256 shifts more. Witness: 22 calls.
Message:
  LD HL,Attributes+352
  LD B,$80
MessageColour:
  LD (HL),$04
  INC HL
  DJNZ MessageColour
  LD B,$01
MessageScroll:
  LD HL,Screen+2145
  CALL ScrollLine
  DJNZ MessageScroll
  LD A,(DE)
  LD HL,$0C1E
  INC DE
  CALL PrintChar
  LD B,$08
  DEC C
  JR NZ,MessageScroll
  LD B,$00
MessageOut:
  LD HL,Screen+2145
  CALL ScrollLine
  DJNZ MessageOut
  RET

; DrawBox, the colour + 9 first in the colour round
;
; Witness: 204 calls.
BoxZoomBox:
  INC IXH
  DEC IXH
  JR NZ,BoxZoomDraw
  LD A,(TextIndex)
  ADD A,$09
  LD (TextIndex),A
BoxZoomDraw:
  CALL DrawBox
  RET

; A = 1 when the score at HL is greater than the one at DE
;
; Six digits, the most significant first. Witness: 11 calls.
CompareScore:
  PUSH BC
  PUSH DE
  PUSH HL
  LD C,$01
  LD B,$06
CompareScoreDigit:
  LD A,(DE)
  INC DE
  CP (HL)
  INC HL
  JR C,CompareScoreDone
  JR NZ,CompareScoreNo
  DJNZ CompareScoreDigit
CompareScoreNo:
  DEC C
CompareScoreDone:
  LD A,C
  POP HL
  POP DE
  POP BC
  RET

; HL = the attribute address of row H (from the bottom), column L
;
; HL = $5B00 - 32 x (H + 1) + L. Witness: 2 112 calls.
AttrAddr:
  PUSH DE
  PUSH BC
  EX DE,HL
  LD HL,Attributes+768
  LD BC,$0020
  INC D
AttrAddrRow:
  AND A
  SBC HL,BC
  DEC D
  JR NZ,AttrAddrRow
  ADD HL,DE
  POP BC
  POP DE
  RET

; C rows of B attributes A from HL
;
; Witness: 24 calls.
FillAttrBlock:
  PUSH BC
  LD DE,$0020
FillAttrBlockRow:
  PUSH BC
  PUSH HL
FillAttrBlockCell:
  LD (HL),A
  INC HL
  DJNZ FillAttrBlockCell
  POP HL
  ADD HL,DE
  POP BC
  DEC C
  JR NZ,FillAttrBlockRow
  POP BC
  RET
