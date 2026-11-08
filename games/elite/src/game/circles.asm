; --------------------------------------------------------------------------------------------------------------------
; circles.asm: The circles: the sun filled, the planet outlined, the chart's range circle, the hit flashes
;
; One circle engine draws every circle: the centre in CircleX $861B and CircleY $861A (offsets from the view's centre,
; the signs in CircleQuadrant $861C bits 0 and 1), the radius in CircleRadius $861D. CircleMode $8629 is 0 for a
; filled circle (the sun: DrawCircleDI), 1 for an outline (the planet: DrawCircle). A radius below 9 is not drawn.
;
; DrawCircleShape $86EE turns the centre into screen coordinates and sorts the circle by how it meets the view's
; edges: wholly inside (four arcs, CircleArcs $87C8), or cut by the top, the bottom or the sides (the clipped fillers
; $87FE-$893F). Each row's half width comes from the table of squares at $BE00 (HalfChord $8ACD); the outline is
; stepped like a Bresenham circle in the alternate registers, the fill writes whole bytes by PUSHing $FFFF into the
; row (a JR patched into one of six chains of 16 PUSH AF, FillSpan1-6).
;
; The code draws into the back buffer: page $C0 and 128 lines. DrawChartCircle $8E29 patches 32 bytes of it (the
; addresses at CirclePatchSites) for the chart screens on $4000 and puts them back after; HitFlash $8F0D patches the
; base (CircleBase) to draw on the real screen too.
; --------------------------------------------------------------------------------------------------------------------

; One byte no code reads (known from the code only)
CircleZero:
  DEFB $00

; The centre's offset from the view's centre, down or up by CircleQuadrant bit
; 1
CircleY:
  DEFB $00

; The centre's offset across, by bit 0
CircleX:
  DEFB $00

; Bit 0 x positive (right), bit 1 y positive (up), bits 2 and 3 the centre off
; the view across or down
CircleQuadrant:
  DEFB $0F

; The radius in pixels (9 and more drawn)
CircleRadius:
  DEFB $64

; DrawCircleShape's working copy of CircleY, clipped to the edge it meets
CircleRowOffset:
  DEFB $00

; Its copy of CircleX
CircleColOffset:
  DEFB $00

; The centre's row: 64 - or + CircleY
CircleScreenY:
  DEFB $00

; The centre's column: 128 + or - CircleX
CircleScreenX:
  DEFB $00

; The half width of the circle at the clipping row (HalfChord)
ClipHalfWidth:
  DEFB $00

; The stack pointer saved while the fills PUSH and the chart patches POP
CircleSP:
  DEFW $0000

; HalfChord's radius² - row²
HalfChordTarget:
  DEFW $0000

; PointRight's x
CirclePointX:
  DEFB $00

; 1 while the run being plotted grows x (the right half), 0 while it shrinks x;
; the fills read it to pick the edge test
RunRight:
  DEFB $00

; 0 a filled circle (the sun), 1 an outline (the planet)
CircleMode:
  DEFB $00

; The 32 bytes DrawChartCircle patches and puts back
ChartPatchCount:
  DEFB $20

; Plot an outline run: up the screen, x growing (the alternate registers step
; it)
;
; Used by the routines at FillClipped and OutlineEdgeStart.
OutlineRunUpRight:
  PUSH AF
  EXX
  LD HL,$0000
  LD D,H
  LD B,$FF
  EXX
  LD A,$01
  LD (RunRight),A
  LD A,(CircleMode)
  AND A
  JP NZ,OutlinePlotTop
  JP FillSpanTest3

; Plot an outline run: up the screen, x shrinking
;
; Used by the routines at FillClipped and OutlineEdgeStart.
OutlineRunUpLeft:
  PUSH AF
  EXX
  LD HL,$0000
  LD D,H
  LD B,$FF
  EXX
  XOR A
  LD (RunRight),A
  LD A,(CircleMode)
  AND A
  JP NZ,OutlinePlotTop
  JP FillSpanTest3

; The same, down the screen, x growing (known from the code only)
;
; Used by the routines at FillClipped and OutlineEdgeStart.
OutlineRunDownRight:
  PUSH AF
  EXX
  LD HL,$0000
  LD D,H
  LD B,$FF
  EXX
  LD A,$01
  LD (RunRight),A
  LD A,(CircleMode)
  AND A
  JP NZ,OutlinePlotSecond
  JP FillSpanTest2

; The same, down the screen, x shrinking (known from the code only)
;
; Used by the routines at FillClipped and OutlineEdgeStart.
OutlineRunDownLeft:
  PUSH AF
  EXX
  LD HL,$0000
  LD D,H
  LD B,$FF
  EXX
  XOR A
  LD (RunRight),A
  LD A,(CircleMode)
  AND A
  JP NZ,OutlinePlotSecond
  JP FillSpanTest2

; Plot one arc run of the outline, x growing (31504 instructions in the
; recordings)
;
; Used by the routines at CircleArcs and FillCorner.
ArcRunRight:
  PUSH AF
  EXX
  LD HL,$0000
  LD D,H
  LD B,$FF
  EXX
  LD A,$01
  LD (RunRight),A
  LD A,(CircleMode)
  AND A
  JP NZ,OutlinePlotSide
  JP FillSpanTest1

; Plot one arc run, x shrinking
;
; Used by the routines at CircleArcs and FillCorner.
ArcRunLeft:
  PUSH AF
  EXX
  LD HL,$0000
  LD D,H
  LD B,$FF
  EXX
  XOR A
  LD (RunRight),A
  LD A,(CircleMode)
  AND A
  JP NZ,OutlinePlotSide
  JP FillSpanTest1

; Plot an edge run going up, filled or outlined by CircleMode
;
; Used by the routine at FillClipped.
OutlineEdgeUp:
  LD C,A
  LD A,(CircleMode)
  AND A
  LD A,C
  JP NZ,OutlineRunUp
  JP FillRunUp

; Plot an edge run going down
;
; Used by the routine at FillClipped.
OutlineEdgeDown:
  LD C,A
  LD A,(CircleMode)
  AND A
  LD A,C
  JP NZ,OutlineRunDown
  JP FillRunDown

; Draw a filled circle with interrupts off (the sun and HitFlash: k2's
; explosion drew 45; no grabbed frame shows a sun's disc)
;
; Used by the routines at DrawSunPlanet and HitFlash.
DrawCircleDI:
  LD A,(CircleRadius)
  CP $09
  RET C
  DI
  XOR A
  LD (CircleMode),A
  JP DrawCircleNow

; Draw an outlined circle (the planet), radius 9 or more
;
; f1, w1, d1: 899 calls, 2697 instructions. CircleMode = 1, then
; DrawCircleShape.
DrawCircle:
  LD A,(CircleRadius)
  CP $09
  RET C

; DrawCircleOutline
;
; Used by the routine at TunnelFrame.
DrawCircleOutline:
  LD A,$01
  LD (CircleMode),A
; This entry point is used by the routine at DrawCircleDI.
DrawCircleNow:
  CALL DrawCircleShape
  EI
  RET

; Draw the circle CircleX, CircleY, CircleQuadrant, CircleRadius: sort it by
; the view's edges
;
; The screen centre is (128, 64): CircleScreenX $8621 = 128 +/- CircleX,
; CircleScreenY $8620 = 64 +/- CircleY by the quadrant bits; bits 2 and 3 of
; the quadrant (set by the projection) mark a centre off the view. From where
; the circle meets the edges (x against $78, y against $40) it goes to
; CircleArcs (all inside, 3028 of 3201 calls) or a clipped filler.
DrawCircleShape:
  LD BC,(CircleY)
  LD (CircleRowOffset),BC
  LD DE,(CircleQuadrant)
  LD A,$40
  BIT 1,E
  JR NZ,DrawCircleShapeIfNotZero
  ADD A,C
  ADD A,C
DrawCircleShapeIfNotZero:
  SUB C
  LD (CircleScreenY),A
  LD A,$80
  BIT 0,E
  JR Z,DrawCircleShapeIfZero
  ADD A,B
  ADD A,B
DrawCircleShapeIfZero:
  SUB B
  LD (CircleScreenX),A
  LD A,C
  CP $40
  BIT 3,E
  EX AF,AF'
  LD A,B
  CP $78
  BIT 2,E
  JR Z,DrawCircleShapeReturn2
  JR NC,DrawCircleShapeIfNotBelow
  EX AF,AF'
  JR Z,DrawCircleShapeReturn
  JR NC,DrawCircleSide
  JR DrawCircleInside
DrawCircleShapeReturn:
  RET NC
  JR DrawCircleSide
DrawCircleShapeReturn2:
  RET NC
DrawCircleShapeIfNotBelow:
  EX AF,AF'
  JR Z,DrawCircleShapeReturn3
  JR NC,DrawCircleCorner
  JR DrawCircleAbove
DrawCircleShapeReturn3:
  RET NC
  JR DrawCircleCorner
DrawCircleInside:
  LD A,B
  ADD A,D
  JR C,DrawCircleShapeIfBelow
  CP $78
  JP C,CircleArcs
DrawCircleShapeIfBelow:
  LD A,D
  SUB B
  JR C,DrawCircleShapeIfBelow2
  CP $78
DrawCircleShapeIfBelow2:
  JP C,FillSides
  JP FillClipped
DrawCircleAbove:
  LD A,B
  SUB $78
  LD B,A
  LD (CircleColOffset),A
  LD A,D
  SUB B
  RET C
  RET Z
  SUB $F0
  JP NC,FillClippedTop
  JP FillSidesTop
DrawCircleSide:
  LD A,C
  SUB $40
  LD C,A
  LD (CircleRowOffset),A
  LD A,D
  SUB C
  RET C
  LD A,D
  CALL Square
  LD H,D
  LD L,E
  LD A,C
  CALL Square
  SBC HL,DE
  LD A,$78
  SUB B
  CALL Square
  SBC HL,DE
  JP C,FillCorner
  ADD HL,DE
  LD A,$78
  ADD A,B
  CALL Square
  SBC HL,DE
  JP NC,FillClippedOther
  JP FillSidesOther
DrawCircleCorner:
  LD A,B
  SUB $78
  LD B,A
  LD A,C
  SUB $40
  LD C,A
  LD (CircleRowOffset),BC
  LD A,D
  CALL Square
  LD H,D
  LD L,E
  LD A,C
  CALL Square
  SBC HL,DE
  RET C
  LD A,B
  CALL Square
  SBC HL,DE
  RET C
  ADD HL,DE
  LD A,B
  ADD A,$F8
  JR C,DrawCircleShapeToFillSidesOtherTop
  CALL Square
  SBC HL,DE
  JP NC,FillClippedOtherTop
DrawCircleShapeToFillSidesOtherTop:
  JP FillSidesOtherTop

; HL = A * A from the table of squares ($BE00 low bytes, $BF00 high bytes)
;
; Used by the routines at VectorLengthShift, DrawCircleShape, HalfChord and
; DrawScanner.
Square:
  PUSH HL
  LD H,$BE
  LD L,A
  LD E,(HL)
  INC H
  LD D,(HL)
  POP HL
  RET

; A circle wholly inside the view: the four quarter arcs
;
; Used by the routine at DrawCircleShape.
CircleArcs:
  CALL CircleArc
  CALL ArcRunLeft
  CALL CircleArc
  JP ArcRunRight

; One quarter arc from the circle's top or bottom row, by the screen address of
; its first point
;
; Used by the routine at CircleArcs.
CircleArc:
  LD BC,(CircleScreenY)
  LD DE,(CircleQuadrant)
  LD A,D
  NEG
  EXX
  LD C,A
  LD E,$00
  EXX
  LD A,B
  SUB D
  CALL PointLeft
  LD A,(CircleScreenY)
  LD C,A
  LD A,(CircleScreenX)
  ADD A,D
  JP PointRight
; This entry point is used by the routine at DrawCircleShape.
FillClippedTop:
  LD A,B
  ADD A,$78
  LD B,A
  LD (CircleColOffset),A
  XOR A
  JR FillClippedJoin

; A circle cut by the view's top or bottom: the rows inside, each from its half
; width
;
; Used by the routine at DrawCircleShape.
FillClipped:
  LD A,$88
  ADD A,B
  INC A
; This entry point is used by the routine at CircleArc.
FillClippedJoin:
  EX AF,AF'
  LD A,$78
  ADD A,B
  CALL HalfChord
  LD (ClipHalfWidth),A
  LD B,A
  LD A,(CircleScreenY)
  CALL OutlineEdgeUp
  CALL SpanStep
  CALL SpanStart
  LD A,(CircleQuadrant)
  BIT 0,A
  CALL Z,OutlineRunDownLeft
  CALL NZ,OutlineRunUpLeft
  LD A,(ClipHalfWidth)
  LD B,A
  LD A,(CircleScreenY)
  CALL OutlineEdgeDown
  CALL SpanStep
  CALL SpanStart
  LD A,(CircleQuadrant)
  BIT 0,A
  CALL Z,OutlineRunDownRight
  CALL NZ,OutlineRunUpRight
  RET
; This entry point is used by the routine at DrawCircleShape.
FillClippedOtherTop:
  LD A,B
  ADD A,$78
  LD B,A
  LD (CircleColOffset),A
  XOR A
  JR FillClippedJoin2
; This entry point is used by the routine at DrawCircleShape.
FillClippedOther:
  LD A,B
  SUB $77
FillClippedJoin2:
  EX AF,AF'
  LD DE,(CircleQuadrant)
  LD A,$78
  ADD A,B
  CALL HalfChord
  LD (ClipHalfWidth),A
  SUB C
  LD B,A
  BIT 1,E
  JR Z,FillClippedIfZero
  XOR A
  CALL OutlineEdgeDown
  CALL SpanStep
  CALL SpanStart
  LD A,(CircleQuadrant)
  BIT 0,A
  CALL Z,OutlineRunDownRight
  CALL NZ,OutlineRunUpRight
  RET
FillClippedIfZero:
  LD A,$7F
  CALL OutlineEdgeUp
  CALL SpanStep
  CALL SpanStart
  LD A,(CircleQuadrant)
  BIT 0,A
  CALL Z,OutlineRunDownLeft
  CALL NZ,OutlineRunUpLeft
  RET
; This entry point is used by the routine at DrawCircleShape.
FillSidesTop:
  LD A,B
  ADD A,$78
  LD (CircleColOffset),A
  LD B,A
  XOR A
  JR FillClippedJoin3
; This entry point is used by the routine at DrawCircleShape.
FillSides:
  LD A,B
  SUB $77
FillClippedJoin3:
  EX AF,AF'
  BIT 0,E
  JR Z,FillClippedCallSpanEndRight
  CALL SpanEndLeft
  CALL OutlineRunUpRight
  CALL SpanEndLeft
  JP OutlineRunUpLeft
FillClippedCallSpanEndRight:
  CALL SpanEndRight
  CALL OutlineRunDownRight
  CALL SpanEndRight
  JP OutlineRunDownLeft
; This entry point is used by the routine at DrawCircleShape.
FillSidesOtherTop:
  LD A,B
  ADD A,$78
  LD (CircleColOffset),A
  LD B,A
  XOR A
  JR FillClippedJoin4
; This entry point is used by the routine at DrawCircleShape.
FillSidesOther:
  LD A,B
  SUB $77
FillClippedJoin4:
  EX AF,AF'
  LD DE,(CircleQuadrant)
  LD A,C
  CALL HalfChord
  LD (ClipHalfWidth),A
  LD A,C
  EXX
  LD E,A
  LD A,(ClipHalfWidth)
  NEG
  LD C,A
  EXX
  BIT 0,E
  JR Z,FillClippedGetClipHalfWidth
  LD A,(ClipHalfWidth)
  CPL
  ADD A,$81
  ADD A,B
  LD C,$00
  BIT 1,E
  JR NZ,FillClippedCallPointLeft
  LD C,$7F
FillClippedCallPointLeft:
  CALL PointLeft
  LD A,(CircleMode)
  AND A
  JP NZ,OutlineEdgeStart
  LD A,E
  AND $1F
  CP $1F
  RET Z
  LD A,E
  OR $1F
  LD L,A
  LD C,$00
  LD A,(CircleQuadrant)
  BIT 1,A
  CALL NZ,OutlineRunUpRight
  CALL Z,OutlineRunUpLeft
  RET
FillClippedGetClipHalfWidth:
  LD A,(ClipHalfWidth)
  ADD A,$80
  SUB B
  CP $08
  RET C
  LD C,$00
  BIT 1,E
  JR NZ,FillClippedCallPointRight
  LD C,$7F
FillClippedCallPointRight:
  CALL PointRight
  LD A,L
  AND $E0
  OR $01
  LD E,A
  LD A,(CircleMode)
  AND A
  JP NZ,OutlineEdgeStartRight
  LD B,$FF
  LD A,(CircleQuadrant)
  BIT 1,A
  CALL NZ,OutlineRunDownRight
  CALL Z,OutlineRunDownLeft
  RET

; A circle cut by two edges
;
; Used by the routine at DrawCircleShape.
FillCorner:
  LD DE,(CircleQuadrant)
  LD A,C
  CALL HalfChord
  LD (ClipHalfWidth),A
  LD A,C
  EXX
  LD E,A
  LD A,(ClipHalfWidth)
  NEG
  LD C,A
  EXX
  XOR A
  BIT 1,E
  JR NZ,FillCornerSetCircleScreenY
  LD A,$7F
FillCornerSetCircleScreenY:
  LD (CircleScreenY),A
  LD C,A
  LD A,(ClipHalfWidth)
  LD L,A
  LD A,(CircleScreenX)
  SUB L
  CALL PointLeft
  LD A,(CircleScreenY)
  LD C,A
  LD A,(ClipHalfWidth)
  LD L,A
  LD A,(CircleScreenX)
  ADD A,L
  CALL PointRight
  LD A,(CircleQuadrant)
  BIT 1,A
  CALL NZ,ArcRunRight
  CALL Z,ArcRunLeft
  RET

; One end of a row run, the left side (known from the code only)
;
; Used by the routine at FillClipped.
SpanEndLeft:
  CALL ArcSeed
  LD A,(CircleScreenY)
  LD C,A
  LD A,$80
  ADD A,B
  SUB D
  CALL PointLeft
  LD A,(CircleMode)
  AND A
  JP NZ,OutlinePointStart
  LD A,E
  OR $1F
  LD L,A
  LD C,$00
  RET

; The other end (known from the code only)
;
; Used by the routine at FillClipped.
SpanEndRight:
  CALL ArcSeed
  LD A,(CircleScreenY)
  LD C,A
  LD A,$80
  ADD A,D
  SUB B
  CALL PointRight
  LD A,L
  AND $E0
  OR $01
  LD E,A
  LD B,A
  LD A,(CircleMode)
  AND A
  LD A,B
  JR NZ,SpanEndRightIfNotZero
  LD B,$FF
  RET
SpanEndRightIfNotZero:
  LD B,$80
  RET

; The alternate registers for an arc: the Bresenham terms from the centre
; (known from the code only)
;
; Used by the routines at SpanEndLeft and SpanEndRight.
ArcSeed:
  LD BC,(CircleRowOffset)
  LD DE,(CircleQuadrant)
  LD A,D
  NEG
  EXX
  LD C,A
  LD E,$00
  EXX
  RET

; HL = the back buffer address of point (C, A), C = the mask of its leftmost
; pixel
;
; Used by the routines at CircleArc, FillClipped, FillCorner and SpanEndLeft.
PointLeft:
  LD B,C
  LD C,A
  LD A,B
  CALL $22B0
  SET 7,H
  LD B,A
  LD A,(CircleMode)
  AND A
  LD A,B
  JP NZ,MaskRight
  LD B,$FF
  INC A
PointLeftLoop:
  SRL B
  DEC A
  JR NZ,PointLeftLoop
  LD E,L
  RET

; HL = the address of point (C, A), the mask of its rightmost pixel (B kept in
; CirclePointX)
;
; Used by the routines at CircleArc, FillClipped, FillCorner and SpanEndRight.
PointRight:
  PUSH AF
  LD A,B
  LD (CirclePointX),A
  POP AF
  LD B,C
  LD C,A
  LD A,B
  CALL $22B0
  SET 7,H
  SUB $08
  NEG
  LD C,A
  LD A,(CircleMode)
  AND A
  LD A,C
  JP NZ,MaskLeft
  LD C,$FF
PointRightLoop:
  SLA C
  DEC A
  JR NZ,PointRightLoop
  LD A,(CirclePointX)
  LD B,A
  RET

; The run's Bresenham step from the half width at the row
;
; Used by the routine at FillClipped.
SpanStep:
  LD BC,(CircleRowOffset)
  LD A,$88
  SUB B
  EXX
  LD C,A
  LD A,(ClipHalfWidth)
  LD E,A
  EXX
  RET

; The run's start address and mask (outline mode goes to OutlineSpanStart
; $8FF9)
;
; Used by the routine at FillClipped.
SpanStart:
  LD A,(CircleMode)
  AND A
  JP NZ,OutlineSpanStart
  LD A,L
  AND $E0
  OR $01
  LD E,A
  LD C,$00
  LD B,$FF
  RET
; This entry point is used by the routine at OutlineEdgeUp.
FillRunUp:
  PUSH DE
  PUSH AF
  PUSH BC
  LD B,A
  LD C,$F8
  CALL $22B0
  SET 7,H
  POP BC
  PUSH BC
  LD DE,$FFFF
  LD (CircleSP),SP
  DEC B
  INC B
  JR Z,SpanStartLoop3
SpanStartLoop:
  LD SP,HL
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  LD A,H
  DEC H
  AND $07
  JR Z,SpanStartIfZero
SpanStartLoop2:
  DJNZ SpanStartLoop
SpanStartLoop3:
  LD SP,(CircleSP)
  POP BC
  POP AF
  POP DE
  RET
SpanStartIfZero:
  LD A,L
  SUB $20
  LD L,A
  JR C,SpanStartIfBelow
  LD A,H
  ADD A,$08
  LD H,A
  JR SpanStartLoop2
SpanStartIfBelow:
  LD A,H
  CP $C0
  JR NC,SpanStartLoop2
  JR SpanStartLoop3
; This entry point is used by the routine at OutlineEdgeDown.
FillRunDown:
  PUSH DE
  PUSH AF
  PUSH BC
  LD B,A
  LD C,$F8
  CALL $22B0
  SET 7,H
  POP BC
  PUSH BC
  LD DE,$FFFF
  LD (CircleSP),SP
  DEC B
  INC B
  JR Z,SpanStartLoop6
SpanStartLoop4:
  LD SP,HL
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  PUSH DE
  INC H
  LD A,H
  AND $07
  JR Z,SpanStartIfZero2
SpanStartLoop5:
  DJNZ SpanStartLoop4
SpanStartLoop6:
  LD SP,(CircleSP)
  POP BC
  POP AF
  POP DE
  RET
SpanStartIfZero2:
  LD A,L
  ADD A,$20
  LD L,A
  JR C,SpanStartIfBelow2
  LD A,H
  SUB $08
  LD H,A
  JR SpanStartLoop5
SpanStartIfBelow2:
  LD A,H
  CP $D0
  JR C,SpanStartLoop5
  JR SpanStartLoop6

; A = sqrt(radius^2 - row^2): the half width of the circle at a row, by
; bisection over the squares
;
; Used by the routines at FillClipped and FillCorner.
HalfChord:
  PUSH BC
  PUSH DE
  PUSH HL
  PUSH AF
  LD A,D
  CALL Square
  LD H,D
  LD L,E
  POP AF
  CALL Square
  SBC HL,DE
  LD B,$80
  XOR A
  LD (HalfChordTarget),HL
HalfChordLoopGetHalfChordTarget:
  LD HL,(HalfChordTarget)
  ADD A,B
  CALL Square
  SBC HL,DE
  JR NC,HalfChordIfNotBelow
  SUB B
HalfChordIfNotBelow:
  SRL B
  JR NC,HalfChordLoopGetHalfChordTarget
  POP HL
  POP DE
  POP BC
  RET
; This entry point is used by the routines at ArcRunRight and ArcRunLeft.
FillSpanTest1:
  LD A,E
  SUB L
  JR NC,HalfChordJoin
  LD A,(RunRight)
  AND A
  JR NZ,HalfChordIfNotZero
  LD A,$BF
  CP H
  JR C,FillSpan1
  JR HalfChordJoin
HalfChordIfNotZero:
  LD A,$CF
  CP H
  JR NC,FillSpan1
HalfChordJoin:
  POP AF
  RET
FillSpan1:
  LD (CircleSP),SP
; This entry point is used by the routine at FillPushes1.
HalfChordIfNotZero2:
  LD A,(HL)
  OR C
  LD (HL),A
  LD D,L
  LD L,E
  LD A,(HL)
  OR B
  LD (HL),A
  LD A,D
  SUB E
  DEC A
  SRL A
  JR NC,HalfChordIfNotBelow2
  INC L
  LD (HL),$FF
HalfChordIfNotBelow2:
  LD L,D
  SUB $11
  CPL
  LD (HalfChordJoin2+$0001),A
  LD SP,FillWord
  POP AF
  LD SP,HL
HalfChordJoin2:
  JR HalfChordJoin2

; A chain of 16 PUSH AF: FillSpan1's patched JR enters it to write the run's
; whole bytes
;
; Known from the code only, like the five chains after it: the filled circle
; (the sun) was never drawn in a recording. The JR before each chain is patched
; with 16 minus the number of words; AF is $FFFF (FillWord $8FB6) and SP the
; run's end.
FillPushes1:
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  LD A,(RunRight)
  AND A
  LD SP,(CircleSP)
  JR NZ,FillPushes1CallCircleLineDown
  CALL CircleLineUp
  JR FillPushes1Join
FillPushes1CallCircleLineDown:
  CALL CircleLineDown
FillPushes1Join:
  EXX
  ADD HL,DE
  INC E
  ADD HL,DE
  BIT 7,H
  EXX
  JR NZ,FillPushes1IfNotZero
  SRL B
  JR NC,FillPushes1IfNotBelow
FillPushes1Loop:
  SLA C
  JR NC,FillPushes1IfNotBelow2
FillPushes1Loop2:
  EXX
  ADD HL,BC
  INC C
; This entry point is used by the routines at FillPushes3 and FillPushes5.
FillPushes1Join2:
  ADD HL,BC
  BIT 7,H
  EXX
FillPushes1IfNotZero:
  JP NZ,HalfChordIfNotZero2
  JR FillPushes1Loop5
FillPushes1IfNotBelow:
  INC E
  LD A,L
  SUB E
  JR Z,FillPushes1Loop3
  LD B,$7F
  JR FillPushes1Loop
FillPushes1IfNotBelow2:
  DEC L
  LD A,L
  SUB E
  JR Z,FillPushes1Loop3
  LD C,$FE
  JR FillPushes1Loop2
FillPushes1Loop3:
  LD SP,(CircleSP)
  POP AF
  RET
FillSpanEdge1:
  INC E
  LD A,L
  SUB E
  JR Z,FillPushes1Loop3
  LD B,$7F
  JR FillPushes1Join3
FillPushes1Loop4:
  DEC L
  LD A,L
  SUB E
  JR Z,FillPushes1Loop3
  LD C,$FE
  JR FillPushes1Join4
; This entry point is used by the routine at FillPushes2.
FillPushes1Loop5:
  SRL B
  JR NC,FillSpanEdge1
FillPushes1Join3:
  SLA C
  JR NC,FillPushes1Loop4
FillPushes1Join4:
  EXX
  ADD HL,BC
  INC C
  JR Z,FillPushes1Loop3
; This entry point is used by the routines at FillPushes3 and FillPushes5.
FillPushes1Join5:
  ADD HL,BC
  BIT 7,H
  EXX
  JR Z,FillPushes1Loop5
  EXX
  ADD HL,DE
  INC E
  ADD HL,DE
  EXX
  LD A,(HL)
  OR C
  LD (HL),A
  LD D,L
  LD L,E
  LD A,(HL)
  OR B
  LD (HL),A
  LD A,D
  SUB E
  DEC A
  SRL A
  JR NC,FillPushes1IfNotBelow3
  INC L
  LD (HL),$FF
FillPushes1IfNotBelow3:
  LD L,D
  SUB $11
  CPL
  LD (FillPushes1Join6+$0001),A
  LD SP,FillWord
  POP AF
  LD SP,HL
FillPushes1Join6:
  JR FillPushes1Join6

; The second chain of 16 PUSH AF
FillPushes2:
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  LD A,(RunRight)
  AND A
  LD SP,(CircleSP)
  JR NZ,FillPushes2CallCircleLineDown
  CALL CircleLineUp
  JR FillPushes1Loop5
FillPushes2CallCircleLineDown:
  CALL CircleLineDown
  JR FillPushes1Loop5

; Test a filled run against the view, then fill it (the second engine)
;
; Used by the routines at OutlineRunDownRight and OutlineRunDownLeft.
FillSpanTest2:
  LD A,L
  AND $1F
  CP $20
  JR NC,FillSpanTest2Join
  LD A,(RunRight)
  AND A
  JR NZ,FillSpanTest2IfNotZero
  LD A,$BF
  CP H
  JR C,FillSpan2
  JR FillSpanTest2Join
FillSpanTest2IfNotZero:
  LD A,$CF
  CP H
  JR NC,FillSpan2
FillSpanTest2Join:
  POP AF
  RET
FillSpan2:
  LD (CircleSP),SP
; This entry point is used by the routine at FillPushes3.
FillSpanTest2IfNotZero2:
  LD A,(HL)
  OR C
  LD (HL),A
  LD D,L
  LD L,E
  LD A,D
  SUB E
  SRL A
  JR NC,FillSpanTest2IfNotBelow
  LD (HL),$FF
FillSpanTest2IfNotBelow:
  LD L,D
  SUB $11
  CPL
  LD (FillSpanTest2Join2+$0001),A
  LD SP,FillWord
  POP AF
  LD SP,HL
FillSpanTest2Join2:
  JR FillSpanTest2Join2

; The third chain
FillPushes3:
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  LD A,(RunRight)
  AND A
  LD SP,(CircleSP)
  JR NZ,FillPushes3CallCircleLineDown
  CALL CircleLineUp
  JR FillPushes3Join
FillPushes3CallCircleLineDown:
  CALL CircleLineDown
FillPushes3Join:
  EXX
  ADD HL,DE
  INC E
  ADD HL,DE
  BIT 7,H
  EXX
  JR NZ,FillPushes3IfNotZero
  SLA C
  JR NC,FillPushes3IfNotBelow
FillPushes3Loop:
  EXX
  ADD HL,BC
  INC C
  EX AF,AF'
  CP C
  JR Z,FillPushes3IfZero
  EX AF,AF'
  ADD HL,BC
  BIT 7,H
  EXX
FillPushes3IfNotZero:
  JP NZ,FillSpanTest2IfNotZero2
  JR FillPushes3Loop4
FillPushes3IfNotBelow:
  DEC L
  LD A,L
  SUB E
  INC A
  JR Z,FillPushes3Loop3
  LD C,$FE
  JR FillPushes3Loop
FillPushes3IfZero:
  EX AF,AF'
  EXX
  LD A,L
  SUB E
  EXX
  JR Z,FillPushes3Loop3
  JP FillPushes1Join2
FillPushes3Loop2:
  EX AF,AF'
  EXX
  LD A,L
  SUB E
  EXX
  JR Z,FillPushes3Loop3
  JP FillPushes1Join5
FillPushes3Loop3:
  LD SP,(CircleSP)
  POP AF
  RET
FillSpanEdge2:
  DEC L
  LD A,L
  SUB E
  INC A
  JR Z,FillPushes3Loop3
  LD C,$FE
  JR FillPushes3Join2
; This entry point is used by the routine at FillPushes4.
FillPushes3Loop4:
  SLA C
  JR NC,FillSpanEdge2
FillPushes3Join2:
  EXX
  ADD HL,BC
  INC C
  JR Z,FillPushes3Loop3
  EX AF,AF'
  CP C
  JR Z,FillPushes3Loop2
  EX AF,AF'
  ADD HL,BC
  BIT 7,H
  EXX
  JR Z,FillPushes3Loop4
  EXX
  ADD HL,DE
  INC E
  ADD HL,DE
  EXX
  LD A,(HL)
  OR C
  LD (HL),A
  LD D,L
  LD L,E
  LD A,D
  SUB E
  SRL A
  JR NC,FillPushes3IfNotBelow2
  LD (HL),$FF
FillPushes3IfNotBelow2:
  LD L,D
  SUB $11
  CPL
  LD (FillPushes3Join3+$0001),A
  LD SP,FillWord
  POP AF
  LD SP,HL
FillPushes3Join3:
  JR FillPushes3Join3

; The fourth chain
FillPushes4:
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  LD A,(RunRight)
  AND A
  LD SP,(CircleSP)
  JR NZ,FillPushes4CallCircleLineDown
  CALL CircleLineUp
  JR FillPushes3Loop4
FillPushes4CallCircleLineDown:
  CALL CircleLineDown
  JR FillPushes3Loop4

; Test a filled run against the view, then fill it (the third engine)
;
; Used by the routines at OutlineRunUpRight and OutlineRunUpLeft.
FillSpanTest3:
  LD A,E
  AND $1F
  CP $20
  JR NC,FillSpanTest3Join
  LD A,(RunRight)
  AND A
  JR NZ,FillSpanTest3IfNotZero
  LD A,$BF
  CP H
  JR C,FillSpan3
  JR FillSpanTest3Join
FillSpanTest3IfNotZero:
  LD A,$CF
  CP H
  JR NC,FillSpan3
FillSpanTest3Join:
  POP AF
  RET
FillSpan3:
  LD (CircleSP),SP
; This entry point is used by the routine at FillPushes5.
FillSpanTest3IfNotZero2:
  LD D,L
  LD L,E
  LD A,(HL)
  OR B
  LD (HL),A
  LD A,D
  SUB E
  DEC A
  SRL A
  JR NC,FillSpanTest3IfNotBelow
  INC L
  LD (HL),$FF
FillSpanTest3IfNotBelow:
  LD L,D
  SUB $11
  CPL
  LD (FillSpanTest3Join2+$0001),A
  LD SP,FillWord
  POP AF
  LD SP,HL
FillSpanTest3Join2:
  JR FillSpanTest3Join2

; The fifth chain
FillPushes5:
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  LD A,(RunRight)
  AND A
  LD SP,(CircleSP)
  JR NZ,FillPushes5CallCircleLineDown
  CALL CircleLineUp
  JR FillPushes5Join
FillPushes5CallCircleLineDown:
  CALL CircleLineDown
FillPushes5Join:
  EXX
  ADD HL,DE
  INC E
  ADD HL,DE
  BIT 7,H
  EXX
  JR NZ,FillPushes5IfNotZero
  SRL B
  JR NC,FillPushes5IfNotBelow
FillPushes5Loop:
  EXX
  ADD HL,BC
  INC C
  EX AF,AF'
  CP C
  JR Z,FillPushes5IfZero
  EX AF,AF'
  ADD HL,BC
  BIT 7,H
  EXX
FillPushes5IfNotZero:
  JP NZ,FillSpanTest3IfNotZero2
  JR FillPushes5Loop4
FillPushes5IfNotBelow:
  INC E
  LD A,L
  SUB E
  JR Z,FillPushes5Loop3
  LD B,$7F
  JR FillPushes5Loop
FillPushes5IfZero:
  EX AF,AF'
  JP FillPushes1Join2
FillPushes5Loop2:
  EX AF,AF'
  JP FillPushes1Join5
FillPushes5Loop3:
  LD SP,(CircleSP)
  POP AF
  RET
FillSpanEdge3:
  INC E
  LD A,L
  SUB E
  JR Z,FillPushes5Loop3
  LD B,$7F
  JR FillPushes5Join2
; This entry point is used by the routine at FillPushes6.
FillPushes5Loop4:
  SRL B
  JR NC,FillSpanEdge3
FillPushes5Join2:
  EXX
  ADD HL,BC
  INC C
  JR Z,FillPushes5Loop3
  EX AF,AF'
  CP C
  JR Z,FillPushes5Loop2
  EX AF,AF'
  ADD HL,BC
  BIT 7,H
  EXX
  JR Z,FillPushes5Loop4
  EXX
  ADD HL,DE
  INC E
  ADD HL,DE
  EXX
  LD D,L
  LD L,E
  LD A,(HL)
  OR B
  LD (HL),A
  LD A,D
  SUB E
  DEC A
  SRL A
  JR NC,FillPushes5IfNotBelow2
  INC L
  LD (HL),$FF
FillPushes5IfNotBelow2:
  LD L,D
  SUB $11
  CPL
  LD (FillPushes5Join3+$0001),A
  LD SP,FillWord
  POP AF
  LD SP,HL
FillPushes5Join3:
  JR FillPushes5Join3

; The sixth chain
FillPushes6:
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  PUSH AF
  LD A,(RunRight)
  AND A
  LD SP,(CircleSP)
  JR NZ,FillPushes6CallCircleLineDown
  CALL CircleLineUp
  JR FillPushes5Loop4
FillPushes6CallCircleLineDown:
  CALL CircleLineDown
  JR FillPushes5Loop4

; HL one pixel line up the back buffer (a character row boundary through
; CircleRowUp)
;
; Used by the routines at FillPushes1, FillPushes2, FillPushes3, FillPushes4,
; FillPushes5, FillPushes6, OutlinePlotTop and OutlinePixels.
CircleLineUp:
  LD A,H
  DEC H
  AND $07
  RET NZ

; DE one character row up
;
; Used by the routine at OutlinePixel.
CircleRowUp:
  LD A,E
  SUB $20
  LD E,A
  LD A,L
  SUB $20
  LD L,A
  JR NC,CircleRowUpIfNotBelow
  LD A,$BF
  CP H
  JR Z,CircleAbort
  RET
CircleRowUpIfNotBelow:
  LD A,H
  ADD A,$08
  LD H,A
  RET

; HL one pixel line down
;
; Used by the routines at FillPushes1, FillPushes2, FillPushes3, FillPushes4,
; FillPushes5, FillPushes6, OutlinePlotTop and OutlinePixels.
CircleLineDown:
  INC H
  LD A,H
  AND $07
  RET NZ

; DE one character row down
;
; Used by the routine at OutlinePixel.
CircleRowDown:
  LD A,E
  ADD A,$20
  LD E,A
  LD A,L
  ADD A,$20
  LD L,A
  JR NC,CircleRowDownIfNotBelow
  LD A,$D0
  CP H
  JR Z,CircleAbort
  RET
CircleRowDownIfNotBelow:
  LD A,H
  SUB $08
  LD H,A
  RET

; Leave the circle code from inside a run: SP back from CircleSP
;
; Used by the routines at CircleRowUp and CircleRowDown.
CircleAbort:
  POP AF
  LD SP,(CircleSP)
  POP AF
  RET

; Draw the chart's range circle: the circle code patched for the screen, then
; back
;
; The centre is ChartCursorX / ChartCursorY ($D051, $D052) against the chart's
; centre (128, 96), the radius ChartRadius $D053. CirclePatchSites $8ECD lists
; 32 code bytes; ChartPatch $8E8D holds their values for the chart, ViewPatch
; $8EAD the values for the 3D view. d1: 4 runs (the charts).
DrawChartCircle:
  LD B,$0C
  LD A,(CrossX)
  LD C,A
  SUB $80
  JR C,DrawChartCircleIfBelow
  SET 0,B
  JR DrawChartCircleSetCircleX
DrawChartCircleIfBelow:
  LD A,$80
  SUB C
DrawChartCircleSetCircleX:
  LD (CircleX),A
  LD A,(CrossY)
  LD C,A
  SUB $60
  JR NC,DrawChartCircleSetCircleY
  SET 1,B
  LD A,$60
  SUB C
DrawChartCircleSetCircleY:
  LD (CircleY),A
  LD A,B
  LD (CircleQuadrant),A
  LD A,(ChartRadius)
  LD (CircleRadius),A
  DI
  LD (CircleSP),SP
  LD A,(ChartPatchCount)
  LD HL,ChartPatch
  LD SP,CirclePatchSites
DrawChartCirclePatch:
  POP DE
  LDI
  DEC A
  JR NZ,DrawChartCirclePatch
  LD SP,(CircleSP)
  EI
  CALL DrawCircle
  DI
  LD (CircleSP),SP
  LD A,(ChartPatchCount)
  LD HL,ViewPatch
  LD SP,CirclePatchSites
DrawChartCircleRestore:
  POP DE
  LDI
  DEC A
  JR NZ,DrawChartCircleRestore
  LD SP,(CircleSP)
  EI
  RET

; The 32 code bytes for the chart screens
ChartPatch:
  DEFB $60,$60,$80,$80,$80,$80,$80,$7F
  DEFB $1F,$00,$00,$00,$00,$00,$80,$00
  DEFB $FF,$00,$00,$28,$FF,$00,$00,$58
  DEFB $57,$3F,$3F,$57,$57,$3F,$58,$3F

; The 32 code bytes for the 3D view
ViewPatch:
  DEFB $40,$40,$78,$78,$78,$88,$78,$77
  DEFB $1E,$01,$CB,$FC,$CB,$FC,$88,$01
  DEFB $F7,$CB,$FC,$C0,$F7,$CB,$FC,$D0
  DEFB $CF,$BF,$BF,$CF,$CF,$BF,$D0,$BF

; The 32 code addresses DrawChartCircle patches
CirclePatchSites:
  DEFW $86FB,$8714,$871A,$873B,$8744,$87FF,$8804,$889A
  DEFW $8FDE,$89B3,$89DA,$89DB,$89FB,$89FC,$8A1B,$8FFD
  DEFW $9008,$900C,$900D,$902D,$9036,$903A,$903B,$905B
  DEFW $9075,$906E,$9106,$910D,$9209,$9202,$8E18,$8DFE

; Draw the growing red circles of the ships just hit, on the screen (HitFlashes
; $9C96)
;
; With HitFlashes set (the explosions; k2 frame 2572 on): the circle code is
; patched for the screen (CircleBase), and each slot whose flags (+$20) have
; bits 4 and 5 set gets 15 filled circles growing by 2 from its screen position
; (+$1C-+$1F) between two attribute fills (FillAttrsVector, L = $0A then $0F);
; then the base goes back to the back buffer.
HitFlash:
  LD A,(ShipsPresent)
  AND A
  RET Z
  LD A,$40
  LD (SpanStartIfBelow+$0002),A
  LD A,$4F
  LD (CircleBase+$0013),A
  LD A,$3F
  LD (CircleBase+$001E),A
  LD HL,$0000
  LD A,$50
  CALL CircleBase
  LD IX,ShipSlots
  LD B,$08
HitFlashSlot:
  PUSH BC
  LD A,(IX+$20)
  LD C,A
  AND $30
  CP $30
  JR NZ,HitFlashNext
  LD L,$0A
  CALL FillAttrsVector
  LD H,(IX+$1C)
  LD L,(IX+$1D)
  LD (CircleY),HL
  LD L,(IX+$1E)
  LD H,(IX+$1F)
  LD (CircleQuadrant),HL
  LD C,$0F
HitFlashGrow:
  PUSH BC
  CALL DrawCircleDI
  POP BC
  LD A,(CircleRadius)
  ADD A,$02
  LD (CircleRadius),A
  DEC C
  JR NZ,HitFlashGrow
  LD L,$0F
  CALL FillAttrsVector
  RES 4,(IX+$20)
HitFlashNext:
  LD DE,$0027
  ADD IX,DE
  POP BC
  DJNZ HitFlashSlot
  LD A,$C0
  LD (SpanStartIfBelow+$0002),A
  LD A,$CF
  LD (CircleBase+$0013),A
  LD A,$BF
  LD (CircleBase+$001E),A
  LD HL,$FCCB
  LD A,$D0

; Patch the circle code's screen base: HL and A the new page bytes
;
; Used by the routine at HitFlash.
CircleBase:
  LD (PointLeft+$0006),HL
  LD (PointRight+$000C),HL
  LD (FillRunUp+$0009),HL
  LD (FillRunDown+$0009),HL
  LD (SpanStartIfBelow2+$0002),A
  LD (CircleRowDown+$000B),A
  LD A,$4F
  LD (FillSpanTest3IfNotZero+$0001),A
  LD (HalfChordIfNotZero+$0001),A
  LD (FillSpanTest2IfNotZero+$0001),A
  LD A,$3F
  LD (FillSpanTest3+$000E),A
  LD (FillSpanTest1+$000B),A
  LD (FillSpanTest2+$000E),A
  LD (CircleRowUp+$000B),A
  RET

; Two zeros
CircleSpare:
  DEFB $00,$00

; $FFFF: AF for the PUSH chains
FillWord:
  DEFW $FFFF

; The outline mode's edge set-up at a cell start (known from the code only)
;
; Used by the routine at FillClipped.
OutlineEdgeStart:
  LD A,E
  AND $E0
  OR $1E
  LD L,A
  LD C,$01
  LD A,(CircleQuadrant)
  BIT 1,A
  CALL NZ,OutlineRunUpRight
  CALL Z,OutlineRunUpLeft
  RET
; This entry point is used by the routine at FillClipped.
OutlineEdgeStartRight:
  LD B,$80
  LD A,(CircleQuadrant)
  BIT 1,A
  CALL NZ,OutlineRunDownRight
  CALL Z,OutlineRunDownLeft
  RET
; This entry point is used by the routine at SpanEndLeft.
OutlinePointStart:
  LD A,E
  AND $E0
  OR $1E
  LD L,A
  LD C,$01
  RET

; B = the single pixel mask of column A (rotating right)
;
; Used by the routine at PointLeft.
MaskRight:
  LD B,$01
  INC A
MaskRightLoop:
  RRC B
  DEC A
  JR NZ,MaskRightLoop
  LD E,L
  RET

; C = the single pixel mask of column CirclePointX (rotating left)
;
; Used by the routine at PointRight.
MaskLeft:
  LD C,$80
MaskLeftLoop:
  RLC C
  DEC A
  JR NZ,MaskLeftLoop
  LD A,(CirclePointX)
  LD B,A
  RET

; The outline mode's run set-up
;
; Used by the routine at SpanStart.
OutlineSpanStart:
  LD A,L
  AND $E0
  OR $01
  LD E,A
  LD C,$01
  LD B,$80
  RET

; Plot an outline run going up (the stepping in the alternate registers)
;
; Used by the routine at OutlineEdgeUp.
OutlineRunUp:
  PUSH AF
  PUSH BC
  LD B,A
  LD C,$F7
  CALL $22B0
  SET 7,H
  POP BC
  PUSH BC
  DEC B
  INC B
  JR Z,OutlineRunUpLoop3
OutlineRunUpLoop:
  LD A,H
  DEC H
  AND $07
  JR Z,OutlineRunUpIfZero
OutlineRunUpLoop2:
  DJNZ OutlineRunUpLoop
OutlineRunUpLoop3:
  POP BC
  POP AF
  RET
OutlineRunUpIfZero:
  LD A,L
  SUB $20
  LD L,A
  JR C,OutlineRunUpIfBelow
  LD A,H
  ADD A,$08
  LD H,A
  JR OutlineRunUpLoop2
OutlineRunUpIfBelow:
  LD A,H
  CP $C0
  JR NC,OutlineRunUpLoop2
  JR OutlineRunUpLoop3

; Plot an outline run going down
;
; Used by the routine at OutlineEdgeDown.
OutlineRunDown:
  PUSH AF
  PUSH BC
  LD B,A
  LD C,$F7
  CALL $22B0
  SET 7,H
  POP BC
  PUSH BC
  DEC B
  INC B
  JR Z,OutlineRunDownLoop3
OutlineRunDownLoop:
  INC H
  LD A,H
  AND $07
  JR Z,OutlineRunDownIfZero
OutlineRunDownLoop2:
  DJNZ OutlineRunDownLoop
OutlineRunDownLoop3:
  POP BC
  POP AF
  RET
OutlineRunDownIfZero:
  LD A,L
  ADD A,$20
  LD L,A
  JR C,OutlineRunDownIfBelow
  LD A,H
  SUB $08
  LD H,A
  JR OutlineRunDownLoop2
OutlineRunDownIfBelow:
  LD A,H
  CP $D0
  JR C,OutlineRunDownLoop2
  JR OutlineRunDownLoop3

; Plot the outline from the top of the circle (the first engine)
;
; Used by the routines at OutlineRunUpRight and OutlineRunUpLeft.
OutlinePlotTop:
  LD A,E
  AND $1F
  CP $20
  JR NC,OutlinePlotTopJoin
  LD A,(RunRight)
  AND A
  JR NZ,OutlinePlotTopIfNotZero
  LD A,$BF
  CP H
  JR C,OutlinePlotTopJoin2
  JR OutlinePlotTopJoin
OutlinePlotTopIfNotZero:
  LD A,$CF
  CP H
  JR NC,OutlinePlotTopJoin2
OutlinePlotTopJoin:
  POP AF
  RET
OutlinePlotTopJoin2:
  LD (CircleSP),SP
OutlinePlotTopLoop:
  LD D,L
  LD L,E
  LD A,(HL)
  OR B
  LD (HL),A
  LD L,D
  LD A,(RunRight)
  AND A
  JR NZ,OutlinePlotTopCallCircleLineDown
  CALL CircleLineUp
  JR OutlinePlotTopJoin3
OutlinePlotTopCallCircleLineDown:
  CALL CircleLineDown
OutlinePlotTopJoin3:
  EXX
  ADD HL,DE
  INC E
  ADD HL,DE
  BIT 7,H
  EXX
  JR NZ,OutlinePlotTopLoop
  RRC B
  JR C,OutlinePlotTopIfBelow
OutlinePlotTopLoop2:
  EXX
  ADD HL,BC
  INC C
  EX AF,AF'
  CP C
  JR Z,OutlinePlotTopIfZero
  EX AF,AF'
  ADD HL,BC
  BIT 7,H
  EXX
  JR NZ,OutlinePlotTopLoop
  JR OutlinePlotTopLoop6
OutlinePlotTopIfBelow:
  INC E
  LD A,L
  SUB E
  JR C,OutlinePlotTopLoop4
  JR OutlinePlotTopLoop2
OutlinePlotTopIfZero:
  EX AF,AF'
  JP OutlineStep
OutlinePlotTopLoop3:
  EX AF,AF'
  JP OutlinePixelsLoop
OutlinePlotTopLoop4:
  LD SP,(CircleSP)
  POP AF
  RET
OutlinePlotTopLoop5:
  INC E
  LD A,L
  SUB E
  JR C,OutlinePlotTopLoop4
  JR OutlinePlotTopJoin4
OutlinePlotTopLoop6:
  LD D,L
  LD L,E
  LD A,(HL)
  OR B
  LD (HL),A
  LD L,D
  RRC B
  JR C,OutlinePlotTopLoop5
OutlinePlotTopJoin4:
  EXX
  ADD HL,BC
  INC C
  JR Z,OutlinePlotTopLoop4
  EX AF,AF'
  CP C
  JR Z,OutlinePlotTopLoop3
  EX AF,AF'
  ADD HL,BC
  BIT 7,H
  EXX
  JR Z,OutlinePlotTopLoop6
  EXX
  ADD HL,DE
  INC E
  ADD HL,DE
  EXX
  LD A,(RunRight)
  AND A
  JR NZ,OutlinePlotTopCallCircleLineDown2
  CALL CircleLineUp
  JR OutlinePlotTopLoop6
OutlinePlotTopCallCircleLineDown2:
  CALL CircleLineDown
  JR OutlinePlotTopLoop6

; Plot the outline along a side (5730 runs)
;
; Used by the routines at ArcRunRight and ArcRunLeft.
OutlinePlotSide:
  LD A,E
  SUB L
  JR NC,OutlinePlotSideJoin
  LD A,(RunRight)
  AND A
  JR NZ,OutlinePlotSideIfNotZero
  LD A,$BF
  CP H
  JR C,OutlinePlotSideJoin2
  JR OutlinePlotSideJoin
OutlinePlotSideIfNotZero:
  LD A,$CF
  CP H
  JR NC,OutlinePlotSideJoin2
OutlinePlotSideJoin:
  POP AF
  RET
OutlinePlotSideJoin2:
  LD (CircleSP),SP

; OR the pixel C into (HL), step the row; the outline's inner loop (1787849
; instructions)
;
; Used by the routine at OutlineStep.
OutlinePixel:
  LD A,(HL)
  OR C
  LD (HL),A
  LD D,L
  LD L,E
  LD A,(HL)
  OR B
  LD (HL),A
  LD L,D
  LD A,(RunRight)
  AND A
  JR NZ,OutlinePixelIfNotZero
  LD A,H
  DEC H
  AND $07
  CALL Z,CircleRowUp
  JR OutlinePixelJoin
OutlinePixelIfNotZero:
  INC H
  LD A,H
  AND $07
  CALL Z,CircleRowDown
OutlinePixelJoin:
  EXX
  ADD HL,DE
  INC E
  ADD HL,DE
  BIT 7,H
  EXX
  JP NZ,OutlinePixel
  RRC B
  JR C,OutlineStepIfBelow

; Rotate the mask: one pixel along x
;
; Used by the routine at OutlineStep.
OutlineStepX:
  RLC C
  JR C,OutlineStepIfBelow2

; The Bresenham term for a step in y
;
; Used by the routine at OutlineStep.
OutlineStepY:
  EXX
  ADD HL,BC
  INC C

; The Bresenham decision: a step in x, y or both
;
; Used by the routines at OutlinePlotTop and OutlinePixels.
OutlineStep:
  ADD HL,BC
  BIT 7,H
  EXX
  JP NZ,OutlinePixel
  JP OutlinePixels
; This entry point is used by the routine at OutlinePixel.
OutlineStepIfBelow:
  INC E
  LD A,L
  SUB E
  JR Z,OutlineStepJoin
  JP OutlineStepX
; This entry point is used by the routine at OutlineStepX.
OutlineStepIfBelow2:
  DEC L
  LD A,L
  SUB E
  JR Z,OutlineStepJoin
  JP OutlineStepY
; This entry point is used by the routine at OutlinePixels.
OutlineStepJoin:
  LD SP,(CircleSP)
  POP AF
  RET
; This entry point is used by the routine at OutlinePixels.
OutlineStepIfBelow3:
  INC E
  LD A,L
  SUB E
  JR Z,OutlineFillRight
  JP OutlinePixelsJoin
; This entry point is used by the routine at OutlinePixels.
OutlineStepIfBelow4:
  DEC L
  LD A,L
  SUB E
  JR Z,OutlineFillLeft
  JP OutlinePixelsJoin2

; Plot the two mirrored pixels of a row and step (442222 instructions)
;
; Used by the routine at OutlineStep.
OutlinePixels:
  LD A,(HL)
  OR C
  LD (HL),A
  LD D,L
  LD L,E
  LD A,(HL)
  OR B
  LD (HL),A
  LD L,D
  RRC B
  JR C,OutlineStepIfBelow3
; This entry point is used by the routine at OutlineStep.
OutlinePixelsJoin:
  RLC C
  JR C,OutlineStepIfBelow4
; This entry point is used by the routine at OutlineStep.
OutlinePixelsJoin2:
  EXX
  ADD HL,BC
  INC C
  JR Z,OutlineFillBoth
; This entry point is used by the routine at OutlinePlotTop.
OutlinePixelsLoop:
  ADD HL,BC
  BIT 7,H
  EXX
  JR Z,OutlinePixels
  EXX
  ADD HL,DE
  INC E
  ADD HL,DE
  EXX
  LD A,(RunRight)
  AND A
  JR NZ,OutlinePixelsCallCircleLineDown
  CALL CircleLineUp
  JR OutlinePixels
OutlinePixelsCallCircleLineDown:
  CALL CircleLineDown
  JR OutlinePixels
; This entry point is used by the routine at OutlineStep.
OutlineFillRight:
  LD L,E
  LD A,(HL)
  LD B,$FF
  AND A
  JR Z,OutlinePixelsJoin3
  LD B,A
  LD A,$FF
OutlinePixelsLoop2:
  SRL B
  JR C,OutlinePixelsIfBelow
  ADD A,A
  JR OutlinePixelsLoop2
OutlinePixelsIfBelow:
  LD (HL),A
  JR OutlinePixelsLoop4
; This entry point is used by the routine at OutlineStep.
OutlineFillLeft:
  LD A,(HL)
  LD B,$FF
  AND A
  JR Z,OutlinePixelsJoin3
OutlinePixelsLoop3:
  ADD A,A
  JR C,OutlinePixelsJoin3
  SRL B
  JR OutlinePixelsLoop3
OutlinePixelsJoin3:
  LD (HL),B
OutlinePixelsLoop4:
  JP OutlineStepJoin
OutlineFillBoth:
  EXX
  LD A,(HL)
  AND A
  JR Z,OutlinePixelsIfZero
  LD B,A
  LD A,$FF
OutlinePixelsLoop5:
  SRL B
  JR C,OutlinePixelsIfBelow2
  ADD A,A
  JR OutlinePixelsLoop5
OutlinePixelsIfZero:
  LD A,$FF
OutlinePixelsIfBelow2:
  LD (HL),A
  LD L,E
  LD A,(HL)
  LD B,$FF
  AND A
  JR Z,OutlinePixelsJoin4
OutlinePixelsLoop6:
  ADD A,A
  JR C,OutlinePixelsJoin4
  SRL B
  JR OutlinePixelsLoop6
OutlinePixelsJoin4:
  LD (HL),B
  JR OutlinePixelsLoop4
; This entry point is used by the routines at OutlineRunDownRight and
; OutlineRunDownLeft.
OutlinePlotSecond:
  LD A,L
  AND $1F
  CP $20
  JR NC,OutlinePixelsJoin5
  LD A,(RunRight)
  AND A
  JR NZ,OutlinePixelsIfNotZero
  LD A,$BF
  CP H
  JR C,OutlinePixelsJoin6
  JR OutlinePixelsJoin5
OutlinePixelsIfNotZero:
  LD A,$CF
  CP H
  JR NC,OutlinePixelsJoin6
OutlinePixelsJoin5:
  POP AF
  RET
OutlinePixelsJoin6:
  LD (CircleSP),SP
OutlinePixelsLoop7:
  LD A,(HL)
  OR C
  LD (HL),A
  LD A,(RunRight)
  AND A
  JR NZ,OutlinePixelsCallCircleLineDown2
  CALL CircleLineUp
  JR OutlinePixelsJoin7
OutlinePixelsCallCircleLineDown2:
  CALL CircleLineDown
OutlinePixelsJoin7:
  EXX
  ADD HL,DE
  INC E
  ADD HL,DE
  BIT 7,H
  EXX
  JR NZ,OutlinePixelsLoop7
  RLC C
  JR C,OutlinePixelsIfBelow3
OutlinePixelsLoop8:
  EXX
  ADD HL,BC
  INC C
  EX AF,AF'
  CP C
  JR Z,OutlinePixelsIfZero2
  EX AF,AF'
  ADD HL,BC
  BIT 7,H
  EXX
  JR NZ,OutlinePixelsLoop7
  JR OutlinePixelsLoop12
OutlinePixelsIfBelow3:
  DEC L
  LD A,L
  SUB E
  INC A
  JR Z,OutlinePixelsLoop10
  JR OutlinePixelsLoop8
OutlinePixelsIfZero2:
  EX AF,AF'
  JP OutlineStep
OutlinePixelsLoop9:
  EX AF,AF'
  JP OutlinePixelsLoop
OutlinePixelsLoop10:
  LD SP,(CircleSP)
  POP AF
  RET
OutlinePixelsLoop11:
  DEC L
  LD A,L
  SUB E
  INC A
  JR Z,OutlinePixelsLoop10
  JR OutlinePixelsJoin8
OutlinePixelsLoop12:
  LD A,(HL)
  OR C
  LD (HL),A
  RLC C
  JR C,OutlinePixelsLoop11
OutlinePixelsJoin8:
  EXX
  ADD HL,BC
  INC C
  JR Z,OutlinePixelsLoop10
  EX AF,AF'
  CP C
  JR Z,OutlinePixelsLoop9
  EX AF,AF'
  ADD HL,BC
  BIT 7,H
  EXX
  JR Z,OutlinePixelsLoop12
  EXX
  ADD HL,DE
  INC E
  ADD HL,DE
  EXX
  LD A,(RunRight)
  AND A
  JR NZ,OutlinePixelsCallCircleLineDown3
  CALL CircleLineUp
  JR OutlinePixelsLoop12
OutlinePixelsCallCircleLineDown3:
  CALL CircleLineDown
  JR OutlinePixelsLoop12

; One unused byte
CircleUnused:
  DEFS $01
