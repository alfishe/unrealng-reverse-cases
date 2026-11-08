; --------------------------------------------------------------------------------------------------------------------
; linedraw.asm: Lines in the 3D view: clipping to the 256 x 128 window, the octant, and four patched Bresenham loops
;
; A line's ends come as offsets from the view's centre with their quadrant bits (C: bits 2-3 the first end's, D E,
; bits 0-1 the second's, H L; bit 0 below the centre, bit 1 left of it: the signs of y and x, as ProjectedPoints keeps
; them), each offset 0-$7F across and 0-$3F down. DrawLine gives each end an outcode (bit 0 past x $80, bit 1 past y
; $40); both outside on the same side, nothing is drawn (the table LineSteps $AFF0); one or both outside, ClipLine
; moves the far end to the window's edge along the slope. LineOctant works out the slope as an 8-bit fraction
; (LineFraction) and the octant; LineSetup patches the step direction (RLC C or RRC C for left or right, INC L or DEC
; L at a byte edge) into one of four loops, named by the way they go and the axis that steps on the carry: LineUpX and
; LineDownX y major (a row a step, x on the carry), LineUpY and LineDownY x major. The line is drawn from D E towards
; H L. Each loop ORs (or XORs, UpdateShips's patch at $B435, $B465, $B486, $B4B2 while the sun is large) a pixel per
; step and adds the fraction to E, stepping the minor axis on the carry.
; --------------------------------------------------------------------------------------------------------------------

; ClipLine's saved outcodes and slope
ClipSave:
  DEFW $0000

; ClipSlope
ClipSlope:
  DEFW $0000

; Draw a line between two points of the view (D E and H L, quadrants in C),
; clipped to the window
;
; 14814 runs. $FF in both coordinates of an end (a hidden point) draws nothing.
DrawLine:
  LD A,H
  AND E
  INC A
  RET Z
  LD A,L
  AND D
  INC A
  RET Z
  PUSH DE
  PUSH HL
  PUSH BC
  LD A,C
  AND $0C
  LD B,A
  LD A,D
  CP $80
  JR C,DrawLineEnd1Y
  SET 0,B
DrawLineEnd1Y:
  LD A,E
  CP $40
  JR C,DrawLineEnd2
  SET 1,B
DrawLineEnd2:
  LD A,C
  AND $03
  ADD A,A
  ADD A,A
  LD C,A
  LD A,H
  CP $80
  JR C,DrawLineEnd2Y
  SET 0,C
DrawLineEnd2Y:
  LD A,L
  CP $40
  JR C,DrawLineCodes
  SET 1,C
DrawLineCodes:
  LD HL,LineSteps
  LD A,B
  AND $03
  JR Z,DrawLineFirstIn
  LD A,B
  ADD A,L
  LD L,A
  JR NC,DrawLineCode1
  INC H
DrawLineCode1:
  LD B,(HL)
  LD HL,LineSteps
  LD A,C
  AND $03
  JR Z,DrawLineEnd1In
  LD A,C
  ADD A,L
  LD L,A
  JR NC,DrawLineBoth
  INC H
DrawLineBoth:
  LD C,(HL)
  LD A,B
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,C
  LD HL,LineSteps
  ADD A,$07
  ADD A,L
  JR NC,DrawLineIfNotBelow
  INC H
DrawLineIfNotBelow:
  LD L,A
  LD A,(HL)
  AND A
  JP NZ,ClipLine
  POP HL
  POP HL
  POP HL
  RET
DrawLineEnd1In:
  POP BC
  POP DE
  POP HL
  LD A,C
  ADD A,A
  ADD A,A
  SRL C
  SRL C
  OR C
  AND $0F
  LD C,A
  JR DrawLineClipped
DrawLineFirstIn:
  LD A,C
  AND $03
  JR Z,DrawLineInside
  POP BC
  POP HL
  POP DE
DrawLineClipped:
  LD B,C
  CALL LineOctant
  CALL LineAddress
  JP LineSkip
DrawLineInside:
  POP BC
  POP HL
  POP DE
  LD B,C
  CALL LineOctant
  CALL LineAddress
  INC H
  INC L
  LD D,B
  BIT 4,B
  LD A,L
  JR Z,LineSetup
  LD A,H

; Pick the loop by the octant and patch its direction bytes and the fraction,
; then jump into it
;
; Used by the routines at DrawLine and LineSkip.
LineSetup:
  EXX
  CP $02
  JR NC,LineSetupLength
  LD A,$02
LineSetupLength:
  DEC A
  LD D,A
  LD A,E
  LD E,$80
  EXX
  LD B,A
  LD A,D
  EXX
  AND $1C
  CP $0E
  JR NC,LineSetupDown
  CP $06
  JR NC,LineSetupUpSteep
  CP $02
  JR NC,LineSetupUpRight
  LD A,$01
  LD (LineDownX+$000C),A
  LD A,$2D
  LD (LineDownXByte),A
  JR LineSetupDownX
LineSetupUpRight:
  LD A,$01
  LD (LineUpX+$000C),A
  LD A,$2D
  LD (LineUpXByte),A
  JR LineSetupUpXGo
LineSetupUpSteep:
  CP $0A
  JR NC,LineSetupUpX
  LD A,$09
  LD (LineDownX+$000C),A
  LD A,$2C
  LD (LineDownXByte),A
LineSetupDownX:
  EXX
  LD A,B
  EXX
  LD (LineDownX+$0007),A
  JP LineDownX
LineSetupDown:
  CP $16
  JR NC,LineSetupDownSteep
  CP $12
  JR NC,LineSetupDownRight
  LD A,$01
  LD (LineDownYStep+$0001),A
  LD A,$2D
  LD (LineDownYByte),A
  JR LineSetupDownY
LineSetupDownRight:
  LD A,$01
  LD (LineUpYStep+$0001),A
  LD A,$2D
  LD (LineUpYByte),A
  JR LineSetupUpYGo
LineSetupDownSteep:
  CP $1A
  JR NC,LineSetupUpY
  LD A,$09
  LD (LineDownYStep+$0001),A
  LD A,$2C
  LD (LineDownYByte),A
LineSetupDownY:
  EXX
  LD A,B
  EXX
  LD (LineDownY+$0007),A
  JP LineDownY
LineSetupUpX:
  LD A,$09
  LD (LineUpX+$000C),A
  LD A,$2C
  LD (LineUpXByte),A
LineSetupUpXGo:
  EXX
  LD A,B
  EXX
  LD (LineUpX+$0007),A
  JP LineUpX
LineSetupUpY:
  LD A,$09
  LD (LineUpYStep+$0001),A
  LD A,$2C
  LD (LineUpYByte),A
LineSetupUpYGo:
  EXX
  LD A,B
  EXX
  LD (LineUpY+$0007),A
  JP LineUpY

; One or both ends outside: the crossing with the window's edge from the slope,
; then the visible part
;
; 10 runs over f1, w1, d1 (the station near the edge).
ClipLine:
  POP HL
  PUSH HL
  DEC A
  JR NZ,ClipLineBoth
  BIT 0,B
  JR Z,ClipLineOneY
  LD A,L
  AND $0C
  SRL L
  SRL L
  OR L
  LD B,A
  LD HL,$8040
  CALL LineOctant
  LD (ClipSlope),BC
  POP BC
  POP HL
  LD B,C
  CALL LineOctant
  LD DE,(ClipSlope)
  LD A,B
  XOR D
  AND $10
  JR Z,ClipLineIfZero
  LD E,$FF
ClipLineIfZero:
  BIT 4,B
  JR Z,ClipLineIfZero2
  LD A,C
  SUB E
  JR ClipLineJoin
ClipLineIfZero2:
  LD A,E
  SUB C
ClipLineJoin:
  JP C,ClipLineAtY
  JP ClipLineAtX
ClipLineOneY:
  POP BC
  POP HL
  LD B,C
  CALL LineOctant
  LD A,E
  CP $40
  JP NC,ClipLineAtY
  JP ClipLineAtX
ClipLineBoth:
  LD (ClipSave),BC
  BIT 0,B
  JR Z,ClipLineEdge
  POP BC
  POP DE
  POP HL
  PUSH DE
  PUSH HL
  LD A,C
  SRL A
  SRL A
  SLA C
  SLA C
  OR C
  AND $0F
  LD C,A
  LD L,C
  PUSH BC
  LD BC,(ClipSave)
  LD A,B
  LD B,C
  LD C,A
  LD (ClipSave),BC
ClipLineEdge:
  LD A,B
  ADD A,C
  CP $07
  LD H,$00
  JR C,ClipLineSlope
  CP $0C
  LD H,$03
  JR NC,ClipLineSlope
  LD A,B
  XOR C
  DEC H
  CP $08
  JR NC,ClipLineSlope
  DEC H
  CP $04
  JR C,ClipLineSlope
  CP $05
  JR Z,ClipLineCorner
  LD A,B
  XOR $06
  LD H,$03
  AND C
  JR Z,ClipLineSlope
  CP $06
  JR Z,ClipLineSlope
  LD H,$00
  JR ClipLineSlope
ClipLineCorner:
  LD A,B
  CP $02
  JR NZ,ClipLineSlope
  INC H
ClipLineSlope:
  LD A,L
  AND $0C
  OR H
  LD B,A
  LD HL,$8040
  CALL LineOctant
  LD (ClipSlope),BC
  POP BC
  POP HL
  LD B,C
  CALL LineOctant
  LD DE,(ClipSlope)
  LD A,B
  XOR D
  AND $10
  JR Z,ClipLineSide
  LD E,$FF
ClipLineSide:
  LD HL,(ClipSave)
  BIT 4,B
  JR Z,ClipLineSideX
  BIT 1,H
  JR NZ,ClipLineSideTest
  JR ClipLineSideY
ClipLineSideX:
  BIT 1,H
  JR NZ,ClipLineSideY
ClipLineSideTest:
  LD A,E
  SUB C
  JR NC,ClipLineNone
ClipLineMiss:
  BIT 1,H
  JR Z,ClipLineAtX
  JR ClipLineAtY
ClipLineSideY:
  LD A,C
  SUB E
  JR C,ClipLineMiss
ClipLineNone:
  POP HL
  RET
ClipLineAtY:
  POP DE                  ; the crossing with y's edge: x moved by the slope
  PUSH BC
  LD A,E
  SUB $40
  LD E,A
  LD L,B
  BIT 4,B
  JR NZ,ClipLineAtYSteep
  CALL MultiplyRound
  JR ClipLineAtYMove
ClipLineAtYSteep:
  LD B,C
  CALL LineFraction
ClipLineAtYMove:
  LD A,L
  RRA
  RRA
  XOR L
  AND $02
  JR NZ,ClipLineAtYAdd
  LD A,D
  SUB C
  LD D,A
  POP BC
  JR NC,ClipLineAtYClamp
  NEG
  LD D,A
  LD A,B
  XOR $02
  LD B,A
ClipLineAtYClamp:
  LD E,$3F
  LD A,D
  CP $80
  JR C,ClipLineAtYDraw
  LD D,$7F
ClipLineAtYDraw:
  CALL LineAddress
  JP LineSkip
ClipLineAtYAdd:
  LD A,D
  ADD A,C
  LD D,A
  POP BC
  JR ClipLineAtYClamp
ClipLineAtX:
  POP DE                  ; the crossing with x's edge: y moved by the slope
  PUSH BC
  LD A,D
  SUB $80
  LD D,A
  LD L,B
  BIT 4,B
  JR Z,ClipLineAtXSteep
  CALL MultiplyRound
  JR ClipLineAtXMove
ClipLineAtXSteep:
  LD B,C
  CALL LineFraction
ClipLineAtXMove:
  LD A,L
  RRA
  RRA
  XOR L
  AND $01
  JR NZ,ClipLineAtXAdd
  LD A,E
  SUB C
  LD E,A
  POP BC
  JR NC,ClipLineAtXClamp
  NEG
  LD E,A
  LD A,B
  XOR $01
  LD B,A
ClipLineAtXClamp:
  LD D,$7F
  LD A,E
  CP $40
  JR C,ClipLineAtXDraw
  LD E,$3F
ClipLineAtXDraw:
  CALL LineAddress
  JP LineSkip
ClipLineAtXAdd:
  LD A,E
  ADD A,C
  LD E,A
  POP BC
  JR ClipLineAtXClamp

; C = A x C / 256, rounded
;
; Used by the routine at ClipLine.
MultiplyRound:
  PUSH DE
  PUSH HL
  LD B,A
  CALL Multiply8
  LD DE,$0080
  ADD HL,DE
  LD C,H
  POP HL
  POP DE
  RET

; C = A x 256 / B (A below B): the slope
;
; Used by the routines at ClipLine, LineSkip and LineOctant.
LineFraction:
  LD C,$FE
  PUSH DE
  LD E,$00
  CALL DividePointLoop
  POP DE
  RET

; The start point's back-buffer address (HL'), its pixel (C') and the pixels to
; the next character row (B'); the page byte at $B348 is $C0
;
; Used by the routines at DrawLine and ClipLine.
LineAddress:
  PUSH BC
  PUSH BC
  PUSH DE
  EXX
  POP BC
  POP DE
  BIT 1,D
  JR NZ,LineAddressLeft
  LD A,$7F
  ADD A,B
  JR LineAddressY
LineAddressLeft:
  LD A,$7F
  SUB B
LineAddressY:
  LD B,A
  BIT 0,D
  JR Z,LineAddressUp
  LD A,$3F
  ADD A,C
  JR LineAddressNow
LineAddressUp:
  LD A,$3F
  SUB C
LineAddressNow:
  LD C,B
  LD B,A
  LD A,C
  AND $07
  LD D,B
  LD B,A
  INC B
  LD A,$01
LineAddressBit:
  RRCA
  DJNZ LineAddressBit
  LD B,D
  LD D,A
  SRL C
  SRL C
  SRL C
  LD A,B
  RRA
  RRA
  RRA
  AND $18
  LD H,A
  LD A,B
  AND $07
  OR H
  OR $C0
  LD H,A
  LD A,B
  AND $38
  ADD A,A
  ADD A,A
  OR C
  LD L,A
  LD A,H
  AND $07
  INC A
  LD B,A
  LD C,D
  POP AF
  BIT 2,A
  JR NZ,LineAddressDone
LineAddressRows:
  LD A,$09
  SUB B
  LD B,A
LineAddressDone:
  EXX
  RET

; The pixels of the line before the window: the start moved in by the slope
;
; Used by the routines at DrawLine and ClipLine.
LineSkip:
  PUSH BC
  LD HL,$8040
  LD A,B
  RRA
  RRA
  AND $03
  SLA B
  SLA B
  OR B
  XOR $03
  AND $0F
  LD B,A
  CALL LineOctant
  POP DE
  LD A,B
  XOR D
  AND $10
  JR Z,LineSkipX
  LD C,$FF
LineSkipX:
  BIT 4,D
  JR Z,LineSkipY
  LD A,E
  SUB C
  LD A,H
  JP C,LineSetup
  JP Z,LineSetup
  LD A,L
  JR LineSkipFraction
LineSkipY:
  LD A,E
  SUB C
  LD A,L
  JP C,LineSetup
  JP Z,LineSetup
  LD A,H
LineSkipFraction:
  LD B,E
  AND A
  JR Z,LineSkipGo
  DEC A
LineSkipGo:
  CALL LineFraction
  LD A,C
  JP LineSetup

; The differences, the octant (B's bits 4-7) and the slope as a fraction (C)
;
; Used by the routines at DrawLine, ClipLine and LineSkip.
LineOctant:
  LD A,B
  SRL A
  SRL A
  XOR B
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  OR B
  OR $03
  LD B,A
  RES 5,B
  AND $20
  LD A,D
  JR Z,LineOctantXSub
  BIT 3,B
  JR Z,LineOctantXAdd
  SET 5,B
LineOctantXAdd:
  ADD A,H
  JR NC,LineOctantXDone
  JR LineOctantY
LineOctantXSub:
  SUB H
  JR C,LineOctantXNeg
  BIT 3,B
  JR Z,LineOctantXDone
  SET 5,B
  JR LineOctantXDone
LineOctantXNeg:
  NEG
  BIT 3,B
  JR NZ,LineOctantXDone
  SET 5,B
LineOctantXDone:
  RES 1,B
LineOctantY:
  LD H,A
  BIT 4,B
  LD A,E
  RES 4,B
  JR Z,LineOctantYSub
  BIT 2,B
  JR Z,LineOctantYAdd
  SET 4,B
LineOctantYAdd:
  ADD A,L
  JR NC,LineOctantYDone
  JR LineOctantMajor
LineOctantYSub:
  SUB L
  JR C,LineOctantYNeg
  BIT 2,B
  JR Z,LineOctantYDone
  SET 4,B
  JR LineOctantYDone
LineOctantYNeg:
  NEG
  BIT 2,B
  JR NZ,LineOctantYDone
  SET 4,B
LineOctantYDone:
  RES 0,B
LineOctantMajor:
  LD L,A
  LD C,L
  RRC B
  RR C
  LD A,H
  RRC B
  RRA
  CP C
  JR C,LineOctantSteep
  SET 4,B
  PUSH BC
  BIT 7,B
  JR Z,LineOctantShallow
  LD B,A
  LD A,C
  JR LineOctantSlope
LineOctantSteep:
  RES 4,B
  PUSH BC
  BIT 6,B
  JR Z,LineOctantSteepY
  LD B,C
  JR LineOctantSlope
LineOctantShallow:
  LD A,L
  LD B,H
  JR LineOctantSlope
LineOctantSteepY:
  LD A,H
  LD B,L
LineOctantSlope:
  CALL LineFraction
  LD A,C
  POP BC
  LD C,A
  RET

; The y-major loop going up: a row up a step, a pixel across on the fraction's
; carry
;
; Used by the routine at LineUpX.
LineUpXRow:
  DEC H

; LineUpX
;
; Used by the routine at LineSetup.
LineUpX:
  LD A,(HL)
  OR C
  LD (HL),A
  DEC D
  RET Z
  LD A,E
  ADD A,$00
  LD E,A
  JR NC,LineUpXNext
  RRC C
  JR C,LineUpXByte
LineUpXNext:
  DJNZ LineUpXRow
  LD B,$08
  LD A,H
  ADD A,$07
  LD H,A
  LD A,L
  SUB $20
  LD L,A
  JP NC,LineUpX
  LD A,H
  SUB B
  LD H,A
  JP LineUpX
LineUpXByte:
  INC L
  JP LineUpXNext
LineUpYByte:
  INC L
  JP LineUpY
; This entry point is used by the routine at LineUpY.
LineUpYStep:
  RRC C
  JR C,LineUpYByte

; The x-major loop going up: a pixel across a step, a row up on the carry
;
; Used by the routines at LineSetup and LineUpX.
LineUpY:
  LD A,(HL)
  OR C
  LD (HL),A
  DEC D
  RET Z
  LD A,E
  ADD A,$00
  LD E,A
  JR NC,LineUpYStep
  DEC H
  DJNZ LineUpYStep
  LD B,$08
  LD A,H
  ADD A,B
  LD H,A
  LD A,L
  SUB $20
  LD L,A
  JP NC,LineUpYStep
  LD A,H
  SUB B
  LD H,A
  JP LineUpYStep
; This entry point is used by the routine at LineDownX.
LineDownXRow:
  INC H

; The y-major loop going down
;
; Used by the routine at LineSetup.
LineDownX:
  LD A,(HL)
  OR C
  LD (HL),A
  DEC D
  RET Z
  LD A,E
  ADD A,$00
  LD E,A
  JR NC,LineDownXNext
  RRC C
  JR C,LineDownXByte
LineDownXNext:
  DJNZ LineDownXRow
  LD B,$08
  LD A,H
  SUB $07
  LD H,A
  LD A,L
  ADD A,$20
  LD L,A
  JP NC,LineDownX
  LD A,H
  ADD A,B
  LD H,A
  JP LineDownX
LineDownXByte:
  INC L
  JP LineDownXNext
; This entry point is used by the routine at LineDownY.
LineDownYStep:
  RRC C
  JR C,LineDownYByte

; The x-major loop going down
;
; Used by the routine at LineSetup.
LineDownY:
  LD A,(HL)
  OR C
  LD (HL),A
  DEC D
  RET Z
  LD A,E
  ADD A,$00
  LD E,A
  JR NC,LineDownYStep
  INC H
  DJNZ LineDownYStep
  LD B,$08
  LD A,H
  SUB B
  LD H,A
  LD A,L
  ADD A,$20
  LD L,A
  JP NC,LineDownYStep
  LD A,H
  ADD A,B
  LD H,A
  JP LineDownYStep
; This entry point is used by the routine at LineDownX.
LineDownYByte:
  INC L
  JP LineDownY

; LinesSpare
LinesSpare:
  DEFB $00

; LaserBeam
LaserBeam:
  DEFB $00
