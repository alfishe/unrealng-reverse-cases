; --------------------------------------------------------------------------------------------------------------------
; cushions.asm: The cushions and the pockets
;
; Coordinates are the ball centre's whole pixels. The table: cushion lines x = 17 and 238 (left, right), y = 65 and
; 166 (top, bottom): a ball past one is stepped back along its velocity (StepBack $8E33, less than a pixel a step)
; until it is on the line, then that velocity component is reversed (ReflectX $8DCB, ReflectY $8DFF). The cushion
; faces, 7 pixels further out, are at y 58 / 173.
;
; Six pockets. The corner pockets are 45-degree channels along y - x = 48 (top left), x + y = 183 (bottom left), x + y
; = 303 (top right), x - y = 72 (bottom right); a ball in a corner zone with |the offset from that diagonal| of 6 or 7
; (large pockets) or 2 or 3 (small) hits the jaw: the bounce on a 45-degree wall swaps vx and vy (ReflectDiagonal
; $8D7D). The middle pockets are channels between x = 122 and 134 (large) or 125 and 131 (small), with jaw points at x
; 115 / 140 (large) or 118 / 137 (small) on the cushion faces y 58 and 173, tested with the radius table Table8x8
; $DCFA (PointJaw $8CF8).
;
; A ball whose centre leaves x 8..247 or y 56..175 is potted: PocketOrCushion $8B4E puts it into its pocket's box,
; marks it, requests the sound and checks the variations' fouls. The pocket size is the menu option $B8BC (1 large,
; the image's value; 0 small): CushionsLarge $8FBB or CushionsSmall $8E81, which also patch the depth test of
; DiagonalJaw $8C7E.
; --------------------------------------------------------------------------------------------------------------------

; Pot a ball that left the playing area, else the cushion tests for the pocket
; size
;
; Input IX = the ball, A = the ball number (0 cue, 1-6); runs once a move (game
; 286, w1 5644). Restores DiagonalJaw's shallow exit ($8C92 = RET C, NOP).
; Inside x 8..247, y 56..175 ($08 <= x < $F8, $38 <= y < $B0): CushionsBySize
; $8C74.
;
; Outside, the ball is potted ($8B71: w1 18, f1 3, p2 2, v1 5, never in game or
; m1): x and y are clamped into the pocket's box, by the column (x < 64, < 192,
; else) and the row (y < 115 top, else bottom): large boxes x 8-15, 122-133,
; 240-247 and y 56-63, 168-175; small x 8-11, 125-130, 244-247 and y 56-59,
; 172-175; fractions 0. +12 = the pocket number (columns 1-3 on the top row, 7
; minus that on the bottom: 4 right, 5 middle, 6 left), +13 bits 5 and 4 set
; and 6 cleared, the sound request $827D = 3.
;
; Fouls of the variations (an object ball, FoulCode $8E80 still 0, the cue ball
; on the table, variation $B8C3 not 0): variation 1 ($8C4B) sets FoulCode = 2
; if a lower-numbered ball is still on the table (v1, 2 times); variation 2
; sets FoulCode = 3 unless the pocket + $9F43 (mod 6, 1-6) is the ball's number
; ($8C43, v1 2 times).
PocketOrCushion:
  LD D,A
  LD A,$D8
  LD (JawShallowExit),A
  XOR A
  LD (JawShallowExit+$0001),A
  LD A,(IX+$01)
  CP $08
  JR C,PocketSnap
  CP $F8
  JR NC,PocketSnap
  LD A,(IX+$03)
  CP $38
  JR C,PocketSnap
  CP $B0
  JR NC,PocketSnap
  JP CushionsBySize
PocketSnap:
  LD A,(Pockets)          ; outside the playing area: potted
  LD E,A
  LD HL,PocketRowSelect
  PUSH HL
  LD HL,PocketClampX
  PUSH HL
  LD A,(IX+$01)
  CP $40
  JR C,PocketLeftColumn
  CP $C0
  JR NC,PocketRightColumn
  LD L,$7D
  LD H,$82
  BIT 0,E
  RET Z
  LD L,$7A
  LD H,$85
  RET
PocketLeftColumn:
  LD L,$08                ; x < 64: boxes x 8..11 or 8..15
  LD H,$0B
  BIT 0,E
  RET Z
  LD H,$0F
  RET
PocketRightColumn:
  LD L,$F4                ; x >= 192: x 244..247 or 240..247
  LD H,$F7
  BIT 0,E
  RET Z
  LD L,$F0
  RET
PocketClampX:
  CP L                    ; C = x clamped to L..H (reached by RET)
  JR NC,PocketClampXHigh
  LD C,L
  RET
PocketClampXHigh:
  CP H
  JR C,PocketClampXKeep
  LD C,H
  RET
PocketClampXKeep:
  LD C,A
  RET
PocketRowSelect:
  LD HL,PocketStore       ; y < 115: boxes y 56..59 or 56..63
  PUSH HL
  LD HL,PocketClampY
  PUSH HL
  LD A,(IX+$03)
  CP $73
  JR NC,PocketBottomRow
  LD L,$38
  LD H,$3B
  BIT 0,E
  RET Z
  LD H,$3F
  RET
PocketBottomRow:
  LD L,$AC                ; y 172..175 or 168..175
  LD H,$AF
  BIT 0,E
  RET Z
  LD L,$A8
  RET
PocketClampY:
  CP L                    ; B = y clamped
  JR NC,PocketClampYHigh
  LD B,L
  RET
PocketClampYHigh:
  CP H
  JR C,PocketClampYKeep
  LD B,H
  RET
PocketClampYKeep:
  LD B,A
  RET
PocketStore:
  LD (IX+$00),$00         ; the ball in the box; C = the column 1-3
  LD (IX+$01),C
  LD (IX+$02),$00
  LD (IX+$03),B
  LD A,C
  LD C,$01
  CP $40
  JR C,PocketNumberBottom
  INC C
  CP $C0
  JR C,PocketNumberBottom
  INC C
PocketNumberBottom:
  LD A,C                  ; y >= 128: pocket = 7 - column
  BIT 7,B
  JR Z,PocketMark
  LD A,$07
  SUB C
PocketMark:
  LD (IX+$0C),A           ; +12 = the pocket, +13: potted, redraw, stopped;
                          ; sound 3
  SET 5,(IX+$0D)
  SET 4,(IX+$0D)
  RES 6,(IX+$0D)
  LD A,$03
  LD (SoundRequest),A
  LD A,D
  OR A
  RET Z
  LD A,(FoulCode)         ; the foul tests of the variations (object ball, no
                          ; foul yet, cue on the table, variation set)
  OR A
  RET NZ
  PUSH IX
  LD IX,BallRecords
  BIT 7,(IX+$0D)
  POP IX
  RET Z
  LD A,(Variation)
  OR A
  RET Z
  DEC A
  JR Z,PocketOrderTest
  LD A,(PlayerVars)       ; variation 2: the pocket + $9F43 wrapped to 1-6 must
                          ; be the ball
  ADD A,(IX+$0C)
  CP $07
  JR C,PocketWrongTest
  SUB $06
PocketWrongTest:
  CP D
  RET Z
  LD A,$03
  LD (FoulCode),A
  RET
PocketOrderTest:
  PUSH IX                 ; variation 1: a lower ball still on the table is a
                          ; foul
  LD IX,BallRecords
  LD BC,$000E
  LD A,$01
PocketOrderLoop:
  ADD IX,BC
  BIT 5,(IX+$0D)
  JR NZ,PocketOrderNext
  BIT 7,(IX+$0D)
  JR Z,PocketOrderNext
  CP D
  JR NC,PocketOrderNext
  LD A,$02
  LD (FoulCode),A
PocketOrderNext:
  INC A
  CP $07
  JR NZ,PocketOrderLoop
  POP IX
  RET

; The cushion tests of the pocket size: $B8BC = 0 small, else large
;
; Runs on every move inside the playing area: CushionsLarge $8FBB in game 286,
; w1 5626, f1 1571, p2 3848, v1 2294 (the image's $B8BC = 1); CushionsSmall
; $8E81 only in m1 (970, the small-pockets option).
CushionsBySize:
  LD A,(Pockets)
  OR A
  JP NZ,CushionsLarge
  JP CushionsSmall

; A corner pocket's 45-degree jaw: A = the offset from the diagonal (carry =
; negative), BC = the wall's normal signs
;
; Entered by JP from the corner tests of CushionsSmall $8E81 / CushionsLarge
; $8FBB with A = the signed offset of the ball from the pocket's diagonal
; (carry set when negative), C / B = $00 or $FF for the x / y sign of the
; wall's normal, HL = the test to repeat. A negative offset is negated and B, C
; complemented. Offset 2-3 (small) or 6-7 (large): JawContact. Less: inside the
; channel, no bounce (RET C at $8C92). More: the ball went too deep: $8C92 is
; patched to JR C,JawContact and StepBack $8E33 runs with HL pushed as its
; return, so the test repeats from the cushion test until the offset is within
; the band. Entered w1 43, f1 46, p2 20, v1 31 times; the deep case $8C94 w1 7,
; f1 4, v1 6.
;
; JawContact: if the ball moves into the wall in x and in y ($8CE4), or in the
; one axis whose speed is the larger (|vx| against |vy|, $8CB5), the fractions
; are set to C, B and ReflectDiagonal $8D7D swaps the components; else ($8CED)
; the fractions are set to the complements and no bounce.
DiagonalJaw:
  JR NC,JawDepthTest
  NEG                     ; negative offset: negate, complement the signs
  PUSH AF
  LD A,B
  CPL
  LD B,A
  LD A,C
  CPL
  LD C,A
  POP AF
JawDepthTest:
  CP $02                  ; CP 2 / CP 6 here and CP 3 / CP 7 at $8C8E: the
                          ; operands patched by $8E81 / $8FBB
  JR Z,JawContact
  CP $03
  JR Z,JawContact
JawShallowExit:
  RET C                   ; RET C / NOP, patched to JR C,JawContact after a
                          ; step back
  NOP
  LD A,$38                ; too deep: patch, step back, repeat the test at HL
  LD (JawShallowExit),A
  LD A,$0E
  LD (JawShallowExit+$0001),A
  PUSH HL
  JP StepBack
JawContact:
  LD A,C                  ; L = C xor vx, H = B xor vy: bit 7 = moving into the
                          ; wall
  XOR (IX+$05)
  LD L,A
  LD A,B
  XOR (IX+$07)
  LD H,A
  OR L
  JP P,JawAway
  LD A,H
  AND L
  JP M,JawReflect
  LD A,L
  OR A
  PUSH AF
  LD E,(IX+$04)
  LD D,(IX+$05)
  BIT 7,D
  JR Z,JawAbsVy
  LD A,E
  CPL
  LD E,A
  LD A,D
  CPL
  LD D,A
  INC DE
JawAbsVy:
  LD L,(IX+$06)
  LD H,(IX+$07)
  BIT 7,H
  JR Z,JawCompare
  LD A,L
  CPL
  LD L,A
  LD A,H
  CPL
  LD H,A
  INC HL
JawCompare:
  POP AF                  ; the larger component decides
  JP P,JawCompareSub
  EX DE,HL
JawCompareSub:
  SCF
  SBC HL,DE
  JR C,JawAway
JawReflect:
  LD (IX+$00),C
  LD (IX+$02),B
  JP ReflectDiagonal
JawAway:
  LD A,C                  ; no bounce: fractions = the complements of C, B
  CPL
  LD (IX+$00),A
  LD A,B
  CPL
  LD (IX+$02),A
  RET

; A middle pocket's jaw point (C, B): the radius test of Table8x8, step back,
; bounce
;
; Input IX, C / B = the jaw point's x / y ($73 or $76, $8C or $89; $3A or $AD);
; entered from the middle-cushion tests. |dx| < 8 and |dy| < 8, and not |dx| =
; |dy| >= 5, else no contact; then Table8x8 $DCFA[8 |dy| + |dx|]: 0 apart, $80
; overlap (StepBack $8E33 and look again, $8D26: w1 1, v1 9), 1 touching.
; Entered w1 7, v1 3, m1 8 times.
;
; The bounce uses bit 7 of the point's coordinates in place of the normal's
; signs (C xor vx, B xor vy, as DiagonalJaw does with its signs): moving into
; the point in both axes, the fractions set from the position's sign and
; ReflectDiagonal $8D7D; in x only, ReflectX $8DCB; in y only, ReflectY $8DFF;
; moving away, nothing.
PointJaw:
  LD A,(IX+$01)
  SUB C
  JR NC,PointJawDy
  NEG
PointJawDy:
  LD E,A
  CP $08
  RET NC
  LD A,(IX+$03)
  SUB B
  JR NC,PointJawDyAbs
  NEG
PointJawDyAbs:
  CP $08                  ; |dx| = |dy| >= 5: outside the radius
  RET NC
  CP E
  JR NZ,PointJawLookup
  CP $05
  RET NC
PointJawLookup:
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,E
  LD D,$00
  LD E,A
  LD HL,Table8x8
  ADD HL,DE
  LD A,(HL)
  OR A
  RET Z
  JP P,PointJawReflect
PointJawBackOff:
  CALL StepBack
  LD A,(IX+$01)
  SUB C
  JR NC,PointJawBackDy
  NEG
PointJawBackDy:
  LD E,A
  LD A,(IX+$03)
  SUB B
  JR NC,PointJawBackLookup
  NEG
PointJawBackLookup:
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,E
  LD D,$00
  LD E,A
  LD HL,Table8x8
  ADD HL,DE
  LD A,(HL)
  OR A
  JP M,PointJawBackOff
PointJawReflect:
  LD A,C
  XOR (IX+$05)
  LD L,A
  LD A,B
  XOR (IX+$07)
  LD H,A
  AND L
  JP M,PointJawCorner
  LD A,H
  OR L
  RET P
  LD A,H
  OR A
  JP P,ReflectX
  JP ReflectY
PointJawCorner:
  LD A,(IX+$01)           ; moving into it in both axes
  OR A
  LD A,$00
  JP P,PointJawFracY
  DEC A
PointJawFracY:
  LD (IX+$00),A
  LD A,(IX+$03)
  OR A
  LD A,$00
  JP P,PointJawSetFracY
  DEC A
PointJawSetFracY:
  LD (IX+$02),A

; The bounce off a 45-degree wall: swap vx and vy (and the friction steps),
; negated when B xor C is positive
;
; Ran w1 10, f1 7, p2 1, v1 5, m1 2 times. (vx, vy, step x, step y) become (vy,
; vx, step y, step x), all four negated when the normal's signs B and C are
; equal ($8D95: w1 4, v1 5, m1 1). Sound request $827D = 2, EventCount $8B4D +
; 1.
ReflectDiagonal:
  PUSH BC
  LD L,(IX+$04)
  LD H,(IX+$05)
  LD E,(IX+$06)
  LD D,(IX+$07)
  LD A,B
  XOR C
  LD C,(IX+$08)
  LD B,(IX+$09)
  JP M,ReflectDiagonalStore
  LD A,E
  CPL
  LD E,A
  LD A,D
  CPL
  LD D,A
  INC DE
  LD A,L
  CPL
  LD L,A
  LD A,H
  CPL
  LD H,A
  INC HL
  LD A,B
  NEG
  LD B,A
  LD A,C
  NEG
  LD C,A
ReflectDiagonalStore:
  LD (IX+$04),E
  LD (IX+$05),D
  LD (IX+$06),L
  LD (IX+$07),H
  LD (IX+$08),B
  LD (IX+$09),C
  POP BC
  LD A,$02
  LD (SoundRequest),A
  LD A,(EventCount)
  INC A
  LD (EventCount),A
  RET

; The bounce off a side cushion: vx and the x friction step negated
;
; vx = -vx (NEG / CPL with the carry: a 16-bit negate), +8 negated, the x
; fraction set to $00 or $FF by the sign of the x pixel byte (bit 7: right half
; $FF); sound request $827D = 2, EventCount $8B4D + 1. Ran game 1, w1 31, f1
; 11, p2 24, v1 14, m1 7 times.
ReflectX:
  LD A,(IX+$04)
  NEG
  CCF
  LD (IX+$04),A
  LD A,(IX+$05)
  CPL
  ADC A,$00
  LD (IX+$05),A
  LD A,(IX+$08)
  NEG
  LD (IX+$08),A
  LD A,(IX+$01)
  OR A
  LD A,$00
  JP P,ReflectXFrac
  DEC A
ReflectXFrac:
  LD (IX+$00),A
  LD A,$02
  LD (SoundRequest),A
  LD A,(EventCount)
  INC A
  LD (EventCount),A
  RET

; The bounce off a top or bottom cushion: vy and the y friction step negated
;
; As ReflectX $8DCB for y: vy, +9 negated, the y fraction $00 or $FF by bit 7
; of the y pixel; sound 2, EventCount + 1. Ran game 1, w1 48, f1 9, p2 39, v1
; 19, m1 8 times.
ReflectY:
  LD A,(IX+$06)
  NEG
  CCF
  LD (IX+$06),A
  LD A,(IX+$07)
  CPL
  ADC A,$00
  LD (IX+$07),A
  LD A,(IX+$09)
  NEG
  LD (IX+$09),A
  LD A,(IX+$03)
  OR A
  LD A,$00
  JP P,ReflectYFrac
  DEC A
ReflectYFrac:
  LD (IX+$02),A
  LD A,$02
  LD (SoundRequest),A
  LD A,(EventCount)
  INC A
  LD (EventCount),A
  RET

; Move the ball back along its velocity by less than one pixel
;
; Input IX. Copies vx, vy, halves both (arithmetic shifts) until each lies in
; -255..255 / 256 (high byte 0, or $FF with a non-zero low byte), then
; subtracts them from x and y. Called by BallContacts $87EF, DiagonalJaw $8C7E,
; PointJaw $8CF8 and the cushion tests: game 2, w1 401, f1 106, p2 281, v1 173,
; m1 79 calls.
StepBack:
  PUSH BC
  LD E,(IX+$04)
  LD D,(IX+$05)
  LD C,(IX+$06)
  LD B,(IX+$07)
StepBackNormalise:
  LD A,D
  OR A
  JR Z,StepBackCheckVy
  INC A
  JR NZ,StepBackHalve
  LD A,E
  OR A
  JR Z,StepBackHalve
StepBackCheckVy:
  LD A,B
  OR A
  JR Z,StepBackApply
  INC A
  JR NZ,StepBackHalve
  LD A,C
  OR A
  JR NZ,StepBackApply
StepBackHalve:
  SRA D
  RR E
  SRA B
  RR C
  JR StepBackNormalise
StepBackApply:
  LD L,(IX+$00)
  LD H,(IX+$01)
  XOR A
  SBC HL,DE
  LD (IX+$00),L
  LD (IX+$01),H
  LD L,(IX+$02)
  LD H,(IX+$03)
  XOR A
  SBC HL,BC
  LD (IX+$02),L
  LD (IX+$03),H
  POP BC
  RET

; The shot's foul from the variations: 0 none, 2 wrong order, 3 wrong pocket
;
; Written by PocketOrCushion $8B4E ($8C47 = 3, $8C68 = 2: v1 only), cleared at
; the shot's start ($84CB); read by the end-of-shot code ($8375, $83BD, $83F1,
; $83FA, $8478) and $8C1D: game 310, w1 2929 reads.
FoulCode:
  DEFB $00

; The cushions and the pocket mouths for small pockets
;
; Patches DiagonalJaw's depth band to 2-3 ($8C8B = 2, $8C8F = 3), then by x: x
; >= 239 the right end, x < 17 the left end, else the long cushions. Ends: the
; straight cushion (y 67..163) reflects vx once x is back within 17..238; above
; y 67 / below y 164 a corner pocket: DiagonalJaw on y - x = 48 / x + y = 183
; (left) or x + y = 303 / x - y = 72 (right). Long cushions: y < 65 the top, y
; >= 167 the bottom, else free. On those: x < 19 or x >= 236 back to the ends;
; x 125..130 the pocket channel (no test); x 118..124 and 131..137 the jaw
; zone: PointJaw at (118 or 137, 58 / 173) until the ball is past the face,
; then x = 125.0 / 130.996 and ReflectX (the channel walls); elsewhere the
; straight cushion: step back to y = 65 / 166 and ReflectY. Only m1 (small
; pockets) ran it: 970 times, frames 7430-7745.
CushionsSmall:
  LD A,$02
  LD (JawDepthTest+$0001),A
  LD A,$03
  LD (JawDepthTest+$0005),A
SmallCushionTest:
  LD A,(IX+$01)           ; the test repeated after each step back (HL)
  CP $EF
  JR NC,SmallRightEnd
  CP $11
  JP NC,SmallLongCushions
SmallLeftEnd:
  LD HL,SmallCushionTest
  LD E,(IX+$01)
  LD D,(IX+$03)
  LD A,D
  CP $A4
  JR NC,SmallBottomLeftJaw
  CP $43
  JR C,SmallTopLeftJaw
  LD A,E
  CP $11
  JP NC,ReflectX
  CALL StepBack
  JR SmallLeftEnd
SmallTopLeftJaw:
  LD BC,$FF00             ; offset = y - 48 - x
  LD A,D
  SUB $30
  SUB E
  JP DiagonalJaw
SmallBottomLeftJaw:
  LD BC,$0000             ; offset = 183 - y - x
  LD A,$B7
  SUB D
  SUB E
  JP DiagonalJaw
SmallRightEnd:
  LD HL,SmallCushionTest
  LD E,(IX+$01)
  LD D,(IX+$03)
  LD A,D
  CP $A4
  JR NC,SmallBottomRightJaw
  CP $43
  JR C,SmallTopRightJaw
  LD A,E
  CP $EF
  JP C,ReflectX
  CALL StepBack
  JR SmallRightEnd
SmallTopRightJaw:
  LD BC,$FFFF             ; offset = y - 47 + x, mod 256
  LD A,D
  SUB $30
  INC A
  ADD A,E
  CCF
  JP DiagonalJaw
SmallBottomRightJaw:
  LD BC,$00FF             ; offset = 184 - y + x, mod 256
  LD A,$B7
  SUB D
  INC A
  ADD A,E
  CCF
  JP DiagonalJaw
SmallLongCushions:
  LD A,(IX+$03)
  CP $41
  JR C,SmallTopCushion
  CP $A7
  RET C
SmallBottomCushion:
  LD A,(IX+$01)
  CP $13
  JP C,SmallLeftEnd
  CP $EC
  JP NC,SmallRightEnd
  CP $7D
  JR C,SmallBottomLeftOfPocket
  CP $83
  RET C
  LD C,$89
  LD B,$AD
  LD DE,$82FF
  CP $8A
  JR C,SmallBottomChannel
  JR SmallBottomStraight
SmallBottomLeftOfPocket:
  LD C,$76                ; jaw x 118, channel wall 125.0
  LD B,$AD
  LD DE,$7D00
  CP $76
  JR NC,SmallBottomChannel
SmallBottomStraight:
  LD A,(IX+$03)           ; y >= 174 here: the ball put on the jaw point
  CP $AE
  JR C,SmallBottomLine
  LD (IX+$01),C
  LD (IX+$03),B
  JP PointJaw
SmallBottomChannel:
  LD A,(IX+$03)           ; past the face: on the channel wall, ReflectX
  CP $AD
  JP C,PointJaw
  LD (IX+$00),E
  LD (IX+$01),D
  JP ReflectX
SmallBottomLine:
  LD A,(IX+$03)           ; step back to y 166, ReflectY
  CP $A7
  JP C,ReflectY
  CALL StepBack
  JR SmallBottomCushion
SmallTopCushion:
  LD A,(IX+$01)
  CP $13
  JP C,SmallLeftEnd
  CP $EC
  JP NC,SmallRightEnd
  CP $7D
  JR C,SmallTopLeftOfPocket
  CP $83
  RET C
  LD C,$89
  LD B,$3A
  LD DE,$82FF
  CP $8A
  JR C,SmallTopChannel
  JR SmallTopStraight
SmallTopLeftOfPocket:
  LD C,$76
  LD B,$3A
  LD DE,$7D00
  CP $76
  JR NC,SmallTopChannel
SmallTopStraight:
  LD A,(IX+$03)
  CP $39
  JR NC,SmallTopLine
  LD (IX+$01),C
  LD (IX+$03),B
  JP PointJaw
SmallTopChannel:
  LD A,(IX+$03)
  CP $3A
  JP NC,PointJaw
  LD (IX+$00),E
  LD (IX+$01),D
  JP ReflectX
SmallTopLine:
  LD A,(IX+$03)           ; step back to y 65, ReflectY
  CP $41
  JP NC,ReflectY
  CALL StepBack
  JR SmallTopCushion

; The cushions and the pocket mouths for large pockets (the default)
;
; As CushionsSmall $8E81 with the large geometry: the band 6-7 ($8C8B = 6,
; $8C8F = 7), the corner zones above y 71 and below y 160, the long cushions'
; ends at x 23 / 232, the middle channel x 122..133 with the walls 122.0 /
; 133.996, the jaw zones x 115..121 and 134..140 with the jaw points (115 or
; 140, 58 / 173). The same cushion lines x 17 / 238, y 65 / 166. Ran game 286,
; w1 5626, f1 1571, p2 3848, v1 2294 times; the straight-cushion bounces are
; the bulk of ReflectX / ReflectY.
CushionsLarge:
  LD A,$06
  LD (JawDepthTest+$0001),A
  LD A,$07
  LD (JawDepthTest+$0005),A
LargeCushionTest:
  LD A,(IX+$01)           ; the test repeated after each step back (HL)
  CP $EF
  JR NC,LargeRightEnd
  CP $11
  JP NC,LargeLongCushions
LargeLeftEnd:
  LD HL,LargeCushionTest
  LD E,(IX+$01)
  LD D,(IX+$03)
  LD A,D
  CP $A0
  JR NC,LargeBottomLeftJaw
  CP $47
  JR C,LargeTopLeftJaw
  LD A,E
  CP $11
  JP NC,ReflectX
  CALL StepBack
  JR LargeLeftEnd
LargeTopLeftJaw:
  LD BC,$FF00             ; offset = y - 48 - x
  LD A,D
  SUB $30
  SUB E
  JP DiagonalJaw
LargeBottomLeftJaw:
  LD BC,$0000             ; offset = 183 - y - x
  LD A,$B7
  SUB D
  SUB E
  JP DiagonalJaw
LargeRightEnd:
  LD HL,LargeCushionTest
  LD E,(IX+$01)
  LD D,(IX+$03)
  LD A,D
  CP $A0
  JR NC,LargeBottomRightJaw
  CP $47
  JR C,LargeTopRightJaw
  LD A,E
  CP $EF
  JP C,ReflectX
  CALL StepBack
  JR LargeRightEnd
LargeTopRightJaw:
  LD BC,$FFFF             ; offset = y - 47 + x, mod 256
  LD A,D
  SUB $30
  INC A
  ADD A,E
  CCF
  JP DiagonalJaw
LargeBottomRightJaw:
  LD BC,$00FF             ; offset = 184 - y + x, mod 256
  LD A,$B7
  SUB D
  INC A
  ADD A,E
  CCF
  JP DiagonalJaw
LargeLongCushions:
  LD A,(IX+$03)           ; y < 65 top, y >= 167 bottom, else free
  CP $41
  JR C,LargeTopCushion
  CP $A7
  RET C
LargeBottomCushion:
  LD A,(IX+$01)
  CP $17
  JP C,LargeLeftEnd
  CP $E8
  JP NC,LargeRightEnd
  CP $7A
  JR C,LargeBottomLeftOfPocket
  CP $86
  RET C
  LD C,$8C
  LD B,$AD
  LD DE,$85FF
  CP $8D
  JR C,LargeBottomChannel
  JR LargeBottomStraight
LargeBottomLeftOfPocket:
  LD C,$73                ; jaw x 115, channel wall 122.0
  LD B,$AD
  LD DE,$7A00
  CP $73
  JR NC,LargeBottomChannel
LargeBottomStraight:
  LD A,(IX+$03)           ; y >= 174: the ball put on the jaw point (never run)
  CP $AE
  JR C,LargeBottomLine
  LD (IX+$01),C
  LD (IX+$03),B
  JP PointJaw
LargeBottomChannel:
  LD A,(IX+$03)           ; past the face: on the channel wall, ReflectX
  CP $AD
  JP C,PointJaw
  LD (IX+$00),E
  LD (IX+$01),D
  JP ReflectX
LargeBottomLine:
  LD A,(IX+$03)           ; step back to y 166, ReflectY
  CP $A7
  JP C,ReflectY
  CALL StepBack
  JR LargeBottomCushion
LargeTopCushion:
  LD A,(IX+$01)
  CP $17
  JP C,LargeLeftEnd
  CP $E8
  JP NC,LargeRightEnd
  CP $7A
  JR C,LargeTopLeftOfPocket
  CP $86
  RET C
  LD C,$8C
  LD B,$3A
  LD DE,$85FF
  CP $8D
  JR C,LargeTopChannel
  JR LargeTopStraight
LargeTopLeftOfPocket:
  LD C,$73
  LD B,$3A
  LD DE,$7A00
  CP $73
  JR NC,LargeTopChannel
LargeTopStraight:
  LD A,(IX+$03)
  CP $39
  JR NC,LargeTopLine
  LD (IX+$01),C
  LD (IX+$03),B
  JP PointJaw
LargeTopChannel:
  LD A,(IX+$03)
  CP $3A
  JP NC,PointJaw
  LD (IX+$00),E
  LD (IX+$01),D
  JP ReflectX
LargeTopLine:
  LD A,(IX+$03)           ; step back to y 65, ReflectY
  CP $41
  JP NC,ReflectY
  CALL StepBack
  JR LargeTopCushion
