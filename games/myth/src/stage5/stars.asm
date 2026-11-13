; --------------------------------------------------------------------------------------------------------------------
; stars.asm: The stars streaming right to left behind the duel
;
; 16 stars at Stars $BA86 (4 bytes: +0 X in pixels, +1 the screen line, +2 the speed class: 0 slow, 4 pixels a pass, 1
; fast, 8 pixels a pass; +3 a counter whose bit 0 picks a new line or keeps the old one when the star wraps). Drawn
; straight to the screen with blank edges; hidden where Dameron's head is.
; --------------------------------------------------------------------------------------------------------------------

  ORG $85F9

; Seed the 16 stars: X = 16 x n (n = 16 down to 1), a random line $30-$BF
; rounded to 8
;
; For n = 16 down to 1 at Stars $BA86: +1 = (a Random $9492 byte under $90) +
; $30 AND $F8, +0 = n x 16 (n = 16 gives 0); a second Random $9492 call only
; advances the ROM pointer. Called once by StageEntry.
;
; Witness: L1 3 (ending, rzx-r5, s5-right).
InitStars:
  LD B,$10
  LD IX,Stars
  LD DE,$0004
InitStarsNext:
  PUSH BC
InitStarsLine:
  CALL Random
  CP $90
  JP NC,InitStarsLine
  ADD A,$30
  AND $F8
  LD (IX+$01),A
  CALL Random
  POP BC
  LD A,B
  SLA A
  SLA A
  SLA A
  SLA A
  LD (IX+$00),A
  ADD IX,DE
  DJNZ InitStarsNext
  RET

; Move the stars left by 4 (slow) or 8 (fast) pixels; a wrapped star may take a
; new line
;
; For n = 16 down to 1: +2 = n AND 1, X - 4 (+2 = 0) or - 8 (+2 = 1). Under $F8
; the new X is stored. Wrapped: +3 - 1; odd keeps the line and the wrapped X;
; even: a new line from NextSeed ($9483, AND $F8, under $90) + $30 AND $FC and
; X = $F0.
;
; Witness: L1 11696 (ending, rzx-r5, s5-right).
MoveStars:
  LD B,$10
  LD IX,Stars
  LD DE,$0004
MoveStarsNext:
  PUSH BC
  LD A,B
  AND $01
  LD (IX+$02),A
  INC A
  SLA A
  SLA A
  NEG
  ADD A,(IX+$00)
  LD C,A
  CP $F8
  JP C,MoveStarStore
  DEC (IX+$03)
  LD A,(IX+$03)
  AND $01
  JP Z,MoveStarNewLine
  LD A,C
  JP MoveStarsSkip
MoveStarNewLine:
  CALL NextSeed
  AND $F8
  CP $90
  JP NC,MoveStarNewLine
  ADD A,$30
  AND $FC
  LD (IX+$01),A
  LD A,$F0
MoveStarStore:
  LD (IX+$00),A
MoveStarsSkip:
  ADD IX,DE
  POP BC
  DJNZ MoveStarsNext
  RET

; Draw the 16 stars
;
; For each: DE = ScreenLineTable[+1] + X / 8, then DrawStar. Every pass from
; MainLoop.
;
; Witness: L1 11696 (ending, rzx-r5, s5-right).
DrawStars:
  LD B,$10
  LD IX,Stars
DrawStarsNext:
  PUSH BC
  LD C,(IX+$01)
  LD B,$00
  LD HL,ScreenLineTable
  ADD HL,BC
  ADD HL,BC
  LD A,(IX+$00)
  SRL A
  SRL A
  SRL A
  ADD A,(HL)
  LD E,A
  INC HL
  LD D,(HL)
  CALL DrawStar
  LD BC,$0004
  ADD IX,BC
  POP BC
  DJNZ DrawStarsNext
  RET

; Draw one star at DE unless it is behind Dameron's head
;
; IX = the star. Hidden (return) when the phase is under 4, X is beyond
; Dameron's X + $88 and the line is within Y + $31 to Y + $A0. Slow stars (+2 =
; 0): 3 lines of 3 bytes from StarSlow $A400 (X AND 7 = 0) or StarSlow1 $A409.
; Fast stars: 5 lines of 4 bytes from StarFast $A412 (even passes) or StarFast1
; $A426 (odd), or with +3 odd (DrawStarNarrow) 3 bytes of each line from the
; second.
;
; Witness: L1 187136 (ending, rzx-r5, s5-right).
DrawStar:
  LD C,$88
  LD A,(DuelPhase)
  CP $04
  JP NC,DrawStarVisible
  LD A,(DameronX)
  ADD A,C
  CP (IX+$00)
  JP NC,DrawStarVisible
  LD A,(DameronY)
  ADD A,$30
  CP (IX+$01)
  JP NC,DrawStarVisible
  ADD A,$70
  CP (IX+$01)
  JP C,DrawStarVisible
  RET
DrawStarVisible:
  LD A,(IX+$02)
  CP $00
  JP Z,DrawStarSlow
  LD HL,StarFast
  LD A,(PassCounter)
  AND $01
  JP Z,DrawStarFast
  LD HL,StarFast1
DrawStarFast:
  LD A,(IX+$03)
  AND $01
  JP NZ,DrawStarNarrow
  LD B,E
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  LD E,B
  INC D
  LD B,E
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  LD E,B
  INC D
  LD B,E
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  LD E,B
  INC D
  LD B,E
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  LD E,B
  INC D
  LD B,E
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  LD E,B
  INC D
  RET
DrawStarSlow:
  LD HL,StarSlow
  LD A,(IX+$00)
  AND $07
  JP Z,DrawStarSlowLines
  LD HL,StarSlow1
DrawStarSlowLines:
  LD B,E
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  LD E,B
  INC D
  LD B,E
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  LD E,B
  INC D
  LD B,E
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  LD E,B
  INC D
  RET
DrawStarNarrow:
  LD B,E
  INC L
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  LD E,B
  INC D
  LD B,E
  INC L
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  LD E,B
  INC D
  LD B,E
  INC L
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  LD E,B
  INC D
  LD B,E
  INC L
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  LD E,B
  INC D
  LD B,E
  INC L
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  LD E,B
  INC D
  RET
