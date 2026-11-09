; --------------------------------------------------------------------------------------------------------------------
; sprites.asm: The block copy and the pre-shifted XOR sprite drawers of the sprite table
;
; BlitRows copies a block of bytes to the screen (the title and the HUD). The drawers serve DrawSprite $A826: HL = the
; position (H = x, L = y), DE = the graphics. Each finds the screen line through the line table $FC00 (a word a line),
; the byte column from x / 8, and the shifted copy from x AND 7 (8 copies) or x AND 6 (4 copies, two pixels apart),
; then XORs the rows. Two of them also colour the cells with the caller's E'.
; --------------------------------------------------------------------------------------------------------------------

; Copies rows of bytes to the screen: rows $B247 to $B248 - 1, at x $B249,
; $B24A bytes a row, from HL
;
; The line table $FC00 gives each row's address, the pixel table $FA00 x's byte
; column. Callers: the title ($8004: two logos) and the HUD of each life start
; ($9136). Witness: game 23, a1 8, g1 7, t1 2, p2 11, h1 9, i1 14, i2 14, h2 1
; entries (a1 frames 20-20424).
BlitRows:
  LD A,(BlitTop)
  LD B,A
BlitRowsLoop:
  PUSH BC
  PUSH HL
  LD L,B
  LD B,$7D
  LD A,(BlitX)
  LD C,A
  SLA C
  RL B
  LD H,$7E
  SLA L
  RL H
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD A,(BC)
  OR L
  LD L,A
  POP DE
  EX DE,HL
  LD B,$00
  LD A,(BlitWidth)
  LD C,A
  LDIR
  POP BC
  INC B
  LD A,(BlitBottom)
  CP B
  JP NZ,BlitRowsLoop
  RET

; A 2-byte, 4-line sprite: 8 shifted copies of 8 bytes
;
; Sprites $11, $12, $1D, $1E. Witness: a1, t1 (the score advance table), i1
; 8626, i2 9653 instructions at the entry.
DrawSprite16x4:
  LD B,$7E
  LD C,L
  SLA C
  RL B
  PUSH BC
  LD A,H
  AND A
  LD HL,$0000
  RRA
  RR L
  RRA
  RR L
  RRA
  RR L
  EXX
  LD C,A
  EXX
  LD A,L
  RRCA
  RRCA
  LD L,A
  ADD HL,DE
  LD B,H
  LD C,L
  POP HL
  EXX
  LD B,$04
  JR SpriteXor2Wide

; A 2-byte, 8-line sprite: 4 shifted copies of 16 bytes
;
; Sprites $40-$43. Witness: a1 20, t1 1, i2 670 runs.
DrawSprite16x8:
  LD B,$7E
  LD C,L
  SLA C
  RL B
  PUSH BC
  LD A,H
  LD HL,$0000
  RRA
  RR L
  RRA
  RR L
  RRA
  RR L
  EXX
  LD C,A
  EXX
  LD A,L
  RRCA
  AND $EF
  RRCA
  LD L,A
  ADD HL,DE
  LD B,H
  LD C,L
  POP HL
  EXX
  LD B,$08
  JR SpriteXor2Wide

; A 2-byte, 9-line sprite: 8 shifted copies of 18 bytes (the wheels)
;
; Sprites $3C-$3E. Witness: game 3118, a1 342, g1 728, p2 1392, h1 728, h2 170
; runs: the deaths (WheelsFly); none in i1 / i2.
DrawSprite16x9:
  LD B,$7E
  LD C,L
  SLA C
  RL B
  PUSH BC
  LD A,H
  AND A
  LD HL,$0000
  RRA
  RR L
  RRA
  RR L
  RRA
  RR L
  EXX
  LD C,A
  EXX
  LD A,L
  RRCA
  LD L,A
  RRCA
  RRCA
  RRCA
  ADD A,L
  LD L,A
  ADD HL,DE
  LD B,H
  LD C,L
  POP HL
  EXX
  LD B,$09

; The rows of the 2-byte drawers: XOR 2 bytes a line, B lines
;
; Witness: game 28 062, i1 34 504 instructions at the entry.
SpriteXor2Wide:
  LD A,C
  EXX
  ADD A,(HL)
  LD E,A
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  LD A,(BC)
  XOR (HL)
  LD (HL),A
  INC BC
  INC HL
  LD A,(BC)
  XOR (HL)
  LD (HL),A
  INC BC
  EX DE,HL
  EXX
  DJNZ SpriteXor2Wide
  EXX
  RET

; A 3-byte, 8-line sprite in colour: 4 shifted copies of 24 bytes; 3 x 2 cells
; set to E'
;
; Sprites 1-$0A, $27-$2A, $37-$3A. Witness: a1 40, t1 2, i1 13 327, i2 10 725
; runs.
DrawSprite24x8Attr:
  LD B,$7E
  LD C,L
  SLA C
  RL B
  PUSH BC
  LD A,H
  LD HL,$0000
  RRA
  RR L
  RRA
  RR L
  RRA
  RR L
  EXX
  LD C,A
  EXX
  LD A,L
  RRCA
  AND $EF
  RRCA
  LD L,A
  RRCA
  ADD A,L
  LD L,A
  ADD HL,DE
  LD B,H
  LD C,L
  POP HL
  PUSH HL
  PUSH BC
  EXX
  LD A,C
  EXX
  ADD A,(HL)
  LD E,A
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  LD A,H
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  EXX
  LD A,E
  EXX
  LD B,$02
  LD DE,$001E
DrawSprite24x8Cells:
  LD (HL),A
  INC HL
  LD (HL),A
  INC HL
  LD (HL),A
  ADD HL,DE
  DJNZ DrawSprite24x8Cells
  POP BC
  POP HL
  EXX
  LD B,$08
  JP SpriteXor3Wide

; A 3-byte, 8-line sprite: 8 shifted copies of 24 bytes
;
; Sprite $14. Witness: a1 20, t1 1, i2 374 runs.
DrawSprite24x8:
  LD B,$7E
  LD C,L
  SLA C
  RL B
  PUSH BC
  LD A,H
  LD HL,$0000
  RRA
  RR L
  RRA
  RR L
  RRA
  RR L
  EXX
  LD C,A
  EXX
  RRC L
  LD A,L
  RRCA
  ADD A,L
  LD L,A
  ADD HL,DE
  LD B,H
  LD C,L
  POP HL
  EXX
  LD B,$08
  JP SpriteXor3Wide

; A 3-byte, 12-line sprite: 4 shifted copies of 36 bytes
;
; Sprites $0F, $2B-$2E, $44, $45. Witness: game 1049, a1 163, g1 546, p2 484,
; h1 546, i1 2342, i2 4368, h2 71 runs.
DrawSprite24x12:
  LD B,$7E
  LD C,L
  SLA C
  RL B
  PUSH BC
  LD A,H
  LD HL,$0000
  RRA
  RR L
  RRA
  RR L
  RRA
  RR L
  EXX
  LD C,A
  EXX
  LD A,L
  RRCA
  AND $EF
  LD L,A
  RRCA
  RRCA
  RRCA
  ADD A,L
  LD L,A
  ADD HL,DE
  LD B,H
  LD C,L
  POP HL
  EXX
  LD B,$0C
  JR SpriteXor3Wide

; A 3-byte, 16-line sprite: 4 shifted copies of 48 bytes
;
; Sprite $10. Witness: a1 40, t1 2, i1 15, i2 1072 runs.
DrawSprite24x16:
  CALL SpriteSetup24
  EXX
  LD B,$10
  JR SpriteXor3Wide

; A 3-byte, 16-line sprite in colour: 4 shifted copies of 48 bytes; 3 x 3 cells
; set to E'
;
; Sprites $0B-$0E, $2F-$32. Witness: a1 20, t1 1, i1 3164, i2 4112 runs.
DrawSprite24x16Attr:
  CALL SpriteSetup24
  PUSH HL
  PUSH BC
  EXX
  LD A,C
  EXX
  ADD A,(HL)
  LD E,A
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  LD A,H
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  EXX
  LD A,E
  EXX
  LD B,$03
  LD DE,$001E
DrawSprite24x16Cells:
  LD (HL),A
  INC HL
  LD (HL),A
  INC HL
  LD (HL),A
  ADD HL,DE
  DJNZ DrawSprite24x16Cells
  POP BC
  POP HL
  EXX
  LD B,$10
  JR SpriteXor3Wide

; The line table entry and the copy of a 3-byte, 16-line sprite (48 bytes a
; shift)
;
; Witness: a1 60, t1 3, i1 3179, i2 5184 entries.
SpriteSetup24:
  LD B,$7E
  LD C,L
  SLA C
  RL B
  PUSH BC
  LD A,H
  LD HL,$0000
  RRA
  RR L
  RRA
  RR L
  RRA
  RR L
  EXX
  LD C,A
  EXX
  LD A,L
  RRCA
  AND $EF
  LD L,A
  RRCA
  ADD A,L
  LD L,A
  ADD HL,DE
  LD B,H
  LD C,L
  POP HL
  RET

; The rows of the 3-byte drawers: XOR 3 bytes a line, B lines
;
; Witness: game 12 588, i1 185 584 instructions at the entry.
SpriteXor3Wide:
  LD A,C
  EXX
  ADD A,(HL)
  LD E,A
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  LD A,(BC)
  XOR (HL)
  LD (HL),A
  INC BC
  INC HL
  LD A,(BC)
  XOR (HL)
  LD (HL),A
  INC BC
  INC HL
  LD A,(BC)
  XOR (HL)
  LD (HL),A
  INC BC
  EX DE,HL
  EXX
  DJNZ SpriteXor3Wide
  EXX
  RET

; A 4-byte, 16-line sprite: 4 shifted copies of 64 bytes
;
; No sprite of $00-$45 uses it. Witness: a1 20, t1 1, i2 1524 runs.
DrawSprite32x16:
  LD B,$7E
  LD C,L
  SLA C
  RL B
  PUSH BC
  LD A,H
  LD HL,$0000
  RRA
  RR L
  RRA
  RR L
  RRA
  RR L
  EXX
  LD C,A
  EXX
  LD A,L
  AND $DF
  LD L,A
  ADD HL,DE
  LD B,H
  LD C,L
  POP HL
  EXX
  LD B,$10
DrawSprite32x16Rows:
  LD A,C
  EXX
  ADD A,(HL)
  LD E,A
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  LD A,(BC)
  XOR (HL)
  LD (HL),A
  INC BC
  INC HL
  LD A,(BC)
  XOR (HL)
  LD (HL),A
  INC BC
  INC HL
  LD A,(BC)
  XOR (HL)
  LD (HL),A
  INC BC
  INC HL
  LD A,(BC)
  XOR (HL)
  LD (HL),A
  INC BC
  EX DE,HL
  EXX
  DJNZ DrawSprite32x16Rows
  EXX
  RET

; A 5-byte, 23-line sprite: 4 shifted copies, 128 bytes apart (the buggy)
;
; Sprite 0 (the buggy, $E140), $13, the death frames $1F-$26 and $33-$36.
; Witness: game 3191, a1 610, g1 994, t1 1, p2 1344, h1 994, i1 7524, i2 9168,
; h2 81 runs.
DrawSprite40x23:
  LD B,$7E
  LD C,L
  SLA C
  RL B
  PUSH BC
  LD A,H
  LD HL,$0000
  RRA
  RR L
  RRA
  RR L
  RRA
  RR L
  EXX
  LD C,A
  EXX
  LD A,L
  AND $DF
  LD L,A
  ADD HL,HL
  ADD HL,DE
  LD B,H
  LD C,L
  POP HL
  EXX
  LD B,$17
DrawSprite40x23Rows:
  LD A,C
  EXX
  ADD A,(HL)
  LD E,A
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  LD A,(BC)
  XOR (HL)
  LD (HL),A
  INC BC
  INC HL
  LD A,(BC)
  XOR (HL)
  LD (HL),A
  INC BC
  INC HL
  LD A,(BC)
  XOR (HL)
  LD (HL),A
  INC BC
  INC HL
  LD A,(BC)
  XOR (HL)
  LD (HL),A
  INC BC
  INC HL
  LD A,(BC)
  XOR (HL)
  LD (HL),A
  INC BC
  EX DE,HL
  EXX
  DJNZ DrawSprite40x23Rows
  EXX
  RET
