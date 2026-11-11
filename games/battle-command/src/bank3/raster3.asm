; --------------------------------------------------------------------------------------------------------------------
; raster3.asm: Bank 3: the polygon clip and span filler, the line drawer, the shared 3D models
;
; Paged by $726C. $7290 calls FillPolygon $C4C4 for the face renderers of bank 2, $72B1 calls DrawLine $C9A7. Both
; write the back buffer $8AF1-$96F0. $CA8B-$CFCC holds the models the bank 6 views and the shared objects use.
; --------------------------------------------------------------------------------------------------------------------

; Clip the polygon PolyVerts `$6700` (count `$68A9`) to rows 0..95 into
; PolyYClipped `$66A8`
;
; Sutherland-Hodgman by states: the last vertex inside (`$C17B`), below row 95
; (`$C02F`) or above row 0 (`$C0DE`); the crossings by IntersectRow95 `$C40A`
; and IntersectRow0 `$C420`. Then the X clip `$C218`. Returns Z when nothing is
; left.
;
; Witness: L1 38525 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
ClipPolyY:
  LD A,($68A9)
  AND A
  RET Z
  DEC A
  ADD A,A
  ADD A,A
  LD L,A
  LD H,$67
  LD C,(HL)
  INC L
  LD B,(HL)
  INC L
  LD E,(HL)
  INC L
  LD D,(HL)
  PUSH DE
  EXX
  POP BC
  LD IX,$6700
  LD IY,$66A8
  XOR A
  EX AF,AF'
  LD A,B
  AND A
  LD A,($68A9)
  JP M,ClipYAbove
  LD HL,$005F
  SBC HL,BC
  JP NC,ClipYInside

; Y clip state: the previous vertex below the window
;
; Witness: L1 3183 (c1, death, m2erbe, menu, missions, play, play2).
ClipYBelow:
  PUSH AF
  LD A,(IX+$03)
  AND A
  JP M,l_C059
  LD D,A
  LD E,(IX+$02)
  LD HL,$005F
  SBC HL,DE
  JR NC,l_C0A8
  LD B,D
  LD C,E
  EXX
  LD C,(IX+$00)
  LD B,(IX+$01)
  EXX
  LD DE,$0004
  ADD IX,DE
  POP AF
  DEC A
  JP NZ,ClipYBelow
  JP ClipPolyX
l_C059:
  LD D,B
  LD E,C
  LD B,A
  LD C,(IX+$02)
  EXX
  LD D,B
  LD E,C
  LD C,(IX+$00)
  LD B,(IX+$01)
  PUSH BC
  EXX
  PUSH BC
  PUSH BC
  PUSH DE
  EXX
  PUSH BC
  PUSH DE
  EXX
  CALL IntersectRow95
  LD (IY+$00),L
  LD (IY+$01),H
  LD (IY+$02),$5F
  POP DE
  POP BC
  EXX
  POP DE
  POP BC
  CALL IntersectRow0
  LD (IY+$03),L
  LD (IY+$04),H
  LD (IY+$05),A
  POP BC
  EXX
  POP BC
  EXX
  LD DE,$0004
  ADD IX,DE
  LD E,$06
  ADD IY,DE
  EX AF,AF'
  ADD A,$02
  EX AF,AF'
  POP AF
  DEC A
  JP NZ,ClipYAbove
  JP ClipPolyX
l_C0A8:
  LD D,B
  LD E,C
  LD B,A
  LD C,(IX+$02)
  EXX
  LD D,B
  LD E,C
  LD C,(IX+$00)
  LD B,(IX+$01)
  PUSH BC
  EXX
  PUSH BC
  CALL IntersectRow95
  LD (IY+$00),L
  LD (IY+$01),H
  LD (IY+$02),$5F
  POP BC
  EXX
  POP BC
  EXX
  LD DE,$0004
  ADD IX,DE
  DEC E
  ADD IY,DE
  EX AF,AF'
  INC A
  EX AF,AF'
  POP AF
  DEC A
  JP NZ,ClipYInside
  JP ClipPolyX

; Y clip state: the previous vertex above the window
;
; Witness: L1 1682 (c1, death, menu, missions, play, play2).
ClipYAbove:
  PUSH AF
  LD A,(IX+$03)
  AND A
  JP M,ClipYAboveSkip
  LD D,A
  LD E,(IX+$02)
  LD HL,$005F
  SBC HL,DE
  JR NC,l_C136
  PUSH DE
  EXX
  LD E,(IX+$00)
  LD D,(IX+$01)
  PUSH DE
  PUSH BC
  PUSH DE
  EXX
  PUSH BC
  PUSH DE
  CALL IntersectRow0
  LD (IY+$00),L
  LD (IY+$01),H
  LD (IY+$02),A
  POP DE
  POP BC
  EXX
  POP DE
  POP BC
  EXX
  CALL IntersectRow95
  LD (IY+$03),L
  LD (IY+$04),H
  LD (IY+$05),$5F
  POP BC
  EXX
  POP BC
  LD DE,$0006
  ADD IY,DE
  LD E,$04
  ADD IX,DE
  EX AF,AF'
  ADD A,$02
  EX AF,AF'
  POP AF
  DEC A
  JP NZ,ClipYBelow
  JP ClipPolyX
l_C136:
  PUSH DE
  EXX
  LD E,(IX+$00)
  LD D,(IX+$01)
  PUSH DE
  EXX
  CALL IntersectRow0
  LD (IY+$00),L
  LD (IY+$01),H
  LD (IY+$02),A
  POP BC
  EXX
  POP BC
  LD DE,$0003
  ADD IY,DE
  INC E
  ADD IX,DE
  EX AF,AF'
  INC A
  EX AF,AF'
  POP AF
  DEC A
  JP NZ,ClipYInside
  JP ClipPolyX

; Y clip: still above, skip the vertex
;
; Witness: L1 1530 (c1, death, menu, missions, play, play2).
ClipYAboveSkip:
  LD B,A
  LD C,(IX+$02)
  EXX
  LD C,(IX+$00)
  LD B,(IX+$01)
  EXX
  LD DE,$0004
  ADD IX,DE
  POP AF
  DEC A
  JP NZ,ClipYAbove
  JP ClipPolyX

; Y clip state: the previous vertex inside, output it
;
; Witness: L1 143574 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
ClipYInside:
  PUSH AF
  LD (IY+$02),C
  EXX
  LD (IY+$00),C
  LD (IY+$01),B
  EXX
  LD A,(IX+$03)
  AND A
  JP M,l_C1E5
  LD D,A
  LD E,(IX+$02)
  LD HL,$005F
  SBC HL,DE
  JR NC,l_C1C8
  PUSH DE
  EXX
  LD E,(IX+$00)
  LD D,(IX+$01)
  PUSH DE
  EXX
  CALL IntersectRow95
  LD (IY+$03),L
  LD (IY+$04),H
  LD (IY+$05),$5F
  POP BC
  EXX
  POP BC
  LD DE,$0006
  ADD IY,DE
  LD E,$04
  ADD IX,DE
  EX AF,AF'
  ADD A,$02
  EX AF,AF'
  POP AF
  DEC A
  JP NZ,ClipYBelow
  JP ClipPolyX
l_C1C8:
  LD B,D
  LD C,E
  EXX
  LD C,(IX+$00)
  LD B,(IX+$01)
  EXX
  LD DE,$0004
  ADD IX,DE
  DEC E
  ADD IY,DE
  EX AF,AF'
  INC A
  EX AF,AF'
  POP AF
  DEC A
  JP NZ,ClipYInside
  JP ClipPolyX
l_C1E5:
  LD D,B
  LD E,C
  LD B,A
  LD C,(IX+$02)
  PUSH BC
  EXX
  LD D,B
  LD E,C
  LD C,(IX+$00)
  LD B,(IX+$01)
  PUSH BC
  EXX
  CALL IntersectRow0
  LD (IY+$03),L
  LD (IY+$04),H
  LD (IY+$05),A
  POP BC
  EXX
  POP BC
  LD DE,$0006
  ADD IY,DE
  LD E,$04
  ADD IX,DE
  EX AF,AF'
  ADD A,$02
  EX AF,AF'
  POP AF
  DEC A
  JP NZ,ClipYAbove

; Clip the Y-clipped list to columns 0..255 (the limit patched by SetClipWidth
; `$CFCD`) into PolyXClipped `$6680`
;
; States `$C245` (previous right of the window), `$C2E6` (left), `$C378`
; (inside); crossings by IntersectColRight `$C478`, IntersectCol0 `$C48E`; the
; count to `$68A9`.
;
; Witness: L1 38524 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
ClipPolyX:
  NOP
  EX AF,AF'
  RET Z
  LD E,A
  DEC A
  LD L,A
  ADD A,A
  ADD A,L
  ADD A,$A8
  LD L,A
  LD H,$66
  LD C,(HL)
  INC L
  LD B,(HL)
  INC L
  LD A,(HL)
  EXX
  LD C,A
  EXX
  LD IX,$66A8
  LD IY,$6680
  XOR A
  EX AF,AF'
  LD A,B
  AND A
  LD A,E
  JP M,ClipXLeft
  LD HL,$00FF
  SBC HL,BC
  JP NC,ClipXInside

; X clip state: the previous vertex right of the window
;
; Witness: L1 11998 (c1, death, m2erbe, missions, play, play2).
ClipXRight:
  PUSH AF
  LD A,(IX+$01)
  AND A
  JP M,l_C26E
  LD D,A
  LD E,(IX+$00)
  LD HL,$00FF
  SBC HL,DE
  JR NC,l_C2B5
  LD B,D
  LD C,E
  EXX
  LD C,(IX+$02)
  EXX
  LD DE,$0003
  ADD IX,DE
  POP AF
  DEC A
  JP NZ,ClipXRight
  EX AF,AF'
  LD ($68A9),A
  RET
l_C26E:
  LD D,B
  LD E,C
  LD B,A
  LD C,(IX+$00)
  EXX
  LD E,C
  LD C,(IX+$02)
  PUSH BC
  EXX
  PUSH BC
  PUSH BC
  PUSH DE
  EXX
  PUSH BC
  PUSH DE
  EXX
  CALL IntersectColRight
  LD (IY+$00),$FF
  LD (IY+$01),A
  POP DE
  POP BC
  EXX
  POP DE
  POP BC
  CALL IntersectCol0
  LD (IY+$02),$00
  LD (IY+$03),A
  POP BC
  EXX
  POP BC
  EXX
  LD DE,$0003
  ADD IX,DE
  INC E
  ADD IY,DE
  EX AF,AF'
  ADD A,$02
  EX AF,AF'
  POP AF
  DEC A
  JP NZ,ClipXLeft
  EX AF,AF'
  LD ($68A9),A
  RET
l_C2B5:
  LD D,B
  LD E,C
  LD B,A
  LD C,(IX+$00)
  EXX
  LD E,C
  LD C,(IX+$02)
  PUSH BC
  EXX
  PUSH BC
  CALL IntersectColRight
  LD (IY+$00),$FF
  LD (IY+$01),A
  POP BC
  EXX
  POP BC
  EXX
  LD DE,$0003
  ADD IX,DE
  DEC E
  ADD IY,DE
  EX AF,AF'
  INC A
  EX AF,AF'
  POP AF
  DEC A
  JP NZ,ClipXInside
  EX AF,AF'
  LD ($68A9),A
  RET

; X clip state: the previous vertex left of the window
;
; Witness: L1 13550 (c1, death, m2erbe, menu, missions, play, play2).
ClipXLeft:
  PUSH AF
  LD A,(IX+$01)
  AND A
  JP M,l_C360
  LD D,A
  LD E,(IX+$00)
  LD HL,$00FF
  SBC HL,DE
  JR NC,l_C337
  PUSH DE
  EXX
  LD E,(IX+$02)
  PUSH DE
  PUSH BC
  PUSH DE
  EXX
  PUSH BC
  PUSH DE
  CALL IntersectCol0
  LD (IY+$00),$00
  LD (IY+$01),A
  POP DE
  POP BC
  EXX
  POP DE
  POP BC
  EXX
  CALL IntersectColRight
  LD (IY+$02),$FF
  LD (IY+$03),A
  POP BC
  EXX
  POP BC
  LD DE,$0003
  ADD IX,DE
  INC E
  ADD IY,DE
  EX AF,AF'
  ADD A,$02
  EX AF,AF'
  POP AF
  DEC A
  JP NZ,ClipXRight
  EX AF,AF'
  LD ($68A9),A
  RET
l_C337:
  PUSH DE
  EXX
  LD E,(IX+$02)
  PUSH DE
  EXX
  CALL IntersectCol0
  LD (IY+$00),$00
  LD (IY+$01),A
  POP BC
  EXX
  POP BC
  LD DE,$0003
  ADD IX,DE
  DEC E
  ADD IY,DE
  EX AF,AF'
  INC A
  EX AF,AF'
  POP AF
  DEC A
  JP NZ,ClipXInside
  EX AF,AF'
  LD ($68A9),A
  RET
l_C360:
  LD B,A
  LD C,(IX+$00)
  EXX
  LD C,(IX+$02)
  EXX
  LD DE,$0003
  ADD IX,DE
  POP AF
  DEC A
  JP NZ,ClipXLeft
  EX AF,AF'
  LD ($68A9),A
  RET

; X clip state: the previous vertex inside
;
; Witness: L1 121481 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
ClipXInside:
  PUSH AF
  LD (IY+$00),C
  EXX
  LD (IY+$01),C
  EXX
  LD A,(IX+$01)
  AND A
  JP M,l_C3D9
  LD D,A
  LD E,(IX+$00)
  LD HL,$00FF
  SBC HL,DE
  JR NC,l_C3BD
  PUSH DE
  EXX
  LD E,(IX+$02)
  PUSH DE
  EXX
  CALL IntersectColRight
  LD (IY+$02),$FF
  LD (IY+$03),A
  POP BC
  EXX
  POP BC
  LD DE,$0003
  ADD IX,DE
  INC E
  ADD IY,DE
  EX AF,AF'
  ADD A,$02
  EX AF,AF'
  POP AF
  DEC A
  JP NZ,ClipXRight
  EX AF,AF'
  LD ($68A9),A
  RET
l_C3BD:
  LD B,D
  LD C,E
  EXX
  LD C,(IX+$02)
  EXX
  LD DE,$0003
  ADD IX,DE
  DEC E
  ADD IY,DE
  EX AF,AF'
  INC A
  EX AF,AF'
  POP AF
  DEC A
  JP NZ,ClipXInside
  EX AF,AF'
  LD ($68A9),A
  RET
l_C3D9:
  LD D,B
  LD E,C
  LD B,A
  LD C,(IX+$00)
  PUSH BC
  EXX
  LD E,C
  LD C,(IX+$02)
  PUSH BC
  EXX
  CALL IntersectCol0
  LD (IY+$02),$00
  LD (IY+$03),A
  POP BC
  EXX
  POP BC
  LD DE,$0003
  ADD IX,DE
  INC E
  ADD IY,DE
  EX AF,AF'
  ADD A,$02
  EX AF,AF'
  POP AF
  DEC A
  JP NZ,ClipXLeft
  EX AF,AF'
  LD ($68A9),A
  RET

; The x where the edge crosses row 95 (exact when an end is on it)
;
; Witness: L1 3152 (c1, death, m2erbe, menu, missions, play, play2).
IntersectRow95:
  EX DE,HL
  LD DE,$005F
  XOR A
  SBC HL,DE
  JR Z,l_C471
  EX DE,HL
  LD H,B
  LD L,C
  LD BC,$005F
  AND A
  SBC HL,BC
  JR Z,l_C474
  LD B,H
  LD C,L

; The x where the edge crosses row 0, by bisection
;
; Witness: L1 15203 (c1, death, m2erbe, menu, missions, play, play2).
IntersectRow0:
  LD H,D
  LD L,E
  ADD HL,BC
  SRA H
  JP M,l_C442
  RR L
  LD A,L
  OR H
  JR Z,l_C461
  EX DE,HL
  EXX
  EX DE,HL
  AND A
  ADC HL,BC
  JP PE,l_C439
  LD A,H
  RLA
l_C439:
  RR H
  RR L
  EX DE,HL
  EXX
  JP IntersectRow0
l_C442:
  RR L
  INC HL
  LD A,L
  OR H
  JR Z,l_C461
  DEC HL
  LD B,H
  LD C,L
  EXX
  LD H,D
  LD L,E
  AND A
  ADC HL,BC
  JP PE,l_C457
  LD A,H
  RLA
l_C457:
  RR H
  RR L
  LD B,H
  LD C,L
  EXX
  JP IntersectRow0
l_C461:
  EXX
  EX DE,HL
  AND A
  ADC HL,BC
  JP PE,l_C46B
  LD A,H
  RLA
l_C46B:
  RR H
  RR L
  XOR A
  RET
; This entry point is used by the routine at IntersectRow95.
l_C471:
  EXX
  EX DE,HL
  RET
; This entry point is used by the routine at IntersectRow95.
l_C474:
  EXX
  LD H,B
  LD L,C
  RET

; The y where the edge crosses the right column (255)
;
; Witness: L1 5322 (c1, death, m2erbe, missions, play, play2).
IntersectColRight:
  EX DE,HL
  LD DE,$00FF
  XOR A
  SBC HL,DE
  JR Z,l_C4BE
  EX DE,HL
  LD H,B
  LD L,C
  LD BC,$00FF
  AND A
  SBC HL,BC
  JR Z,l_C4C1
  LD B,H
  LD C,L

; The y where the edge crosses column 0, by bisection
;
; Witness: L1 67550 (c1, death, m2erbe, menu, missions, play, play2).
IntersectCol0:
  LD H,D
  LD L,E
  ADD HL,BC
  SRA H
  JP M,l_C4A6
  RR L
  LD A,L
  OR H
  JR Z,l_C4B9
  EX DE,HL
  EXX
  LD A,E
  ADD A,C
  RRA
  LD E,A
  EXX
  JP IntersectCol0
l_C4A6:
  RR L
  INC HL
  LD A,L
  OR H
  JR Z,l_C4B9
  DEC HL
  LD B,H
  LD C,L
  EXX
  LD A,E
  ADD A,C
  RRA
  LD C,A
  EXX
  JP IntersectCol0
l_C4B9:
  EXX
  LD A,E
  ADD A,C
  RRA
  RET
; This entry point is used by the routine at IntersectColRight.
l_C4BE:
  EXX
  LD A,E
  RET
; This entry point is used by the routine at IntersectColRight.
l_C4C1:
  EXX
  LD A,C
  RET

; Fill the polygon PolyVerts `$6700` in the colour `$7579`: clip, find the top
; and bottom, walk the edges, fill
;
; After the clips, fewer than 3 vertices return. Finds the lowest and highest
; row in `$6681`..., marks the top vertex, doubles the list, sets the top row
; `$67BD` and the row count `$68A8`, and calls EdgeWalk `$C542`. Entered from
; bank 5 `$7290` (38 827 calls over the recordings).
;
; Witness: L1 38525 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
FillPolygon:
  CALL ClipPolyY
  RET Z
  LD (FillPolygon+$0008),A
  LD A,$00
  CP $03
  RET C
  LD B,A
  LD C,A
  XOR A
  EX AF,AF'
  LD A,$FF
  LD HL,$6681
  LD D,H
l_C4DA:
  CP (HL)
  JR C,l_C4DF
  LD A,(HL)
  LD E,L
l_C4DF:
  EX AF,AF'
  CP (HL)
  JR NC,l_C4E4
  LD A,(HL)
l_C4E4:
  EX AF,AF'
  INC L
  INC L
  DJNZ l_C4DA
  LD (l_C4FE+$0019),A
  DEC E
  PUSH DE
  POP IX
  LD HL,$6681
  LD B,C
  EX AF,AF'
  LD ($67BD),A
l_C4F8:
  CP (HL)
  JP NZ,l_C4FE
  SET 7,(HL)
l_C4FE:
  INC L
  INC L
  DJNZ l_C4F8
  SLA C
  LD B,$00
  LD L,C
  LD H,B
  ADD HL,DE
  EX DE,HL
  PUSH DE
  POP IY
  LD DE,$6680
  LD H,B
  LD L,C
  ADD HL,DE
  EX DE,HL
  LDIR
  LD C,$00
  SUB C
  INC A
  LD ($68A8),A
  DEC A
  JP NZ,EdgeWalk
  LD A,(FillPolygon+$0008)
  LD B,A
  LD HL,$6680
  XOR A
  EX AF,AF'
  LD A,$FF
l_C52C:
  CP (HL)
  JR C,l_C530
  LD A,(HL)
l_C530:
  EX AF,AF'
  CP (HL)
  JR NC,l_C535
  LD A,(HL)
l_C535:
  EX AF,AF'
  INC L
  INC L
  DJNZ l_C52C
  LD C,A
  EX AF,AF'
  LD B,A
  PUSH BC

; CALL FillSpans `$C86A` then RET (the edge walker jumps here when the spans
; are on the stack)
;
; Witness: L1 33753 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
FillSpansThenReturn:
  CALL FillSpans

; The RET after FillSpans
;
; Witness: L1 33753 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
FillSpansReturn:
  RET

; Walk the left and right edges from the top vertex down, pushing one (left,
; right) span per row on the stack
;
; `SP` saved at `$C7EA`; each edge's step from EdgeSlope `$C959`; the next edge
; on either side by `$C82D` (left, IX forward) and `$C7ED` (right, IY back); at
; the bottom it jumps to FillSpansThenReturn `$C53E`. The biggest block of bank
; 3: 385 instructions.
;
; Witness: L1 31451 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
EdgeWalk:
  LD (l_C7E9+$0001),SP
  LD A,(IX+$00)
  LD (l_C574+$000B),A
  LD E,A
  LD A,(IX+$01)
  LD D,A
l_C551:
  INC IX
  INC IX
  LD L,(IX+$00)
  LD H,(IX+$01)
  RES 7,H
  CP H
  JR C,l_C56B
  JR NZ,l_C551
  EX DE,HL
  LD A,E
  LD (l_C574+$000B),A
  LD A,D
  JP l_C551
l_C56B:
  LD A,H
  SUB D
  LD D,A
  LD A,E
  SUB L
  JR NC,l_C574
  NEG
l_C574:
  PUSH AF
  LD H,A
  LD L,D
  LD B,D
  INC B
  CALL EdgeSlope
  EX DE,HL
  LD HL,$007F
  EXX
  LD A,(IY+$00)
  LD (l_C5AF+$000B),A
  LD E,A
  LD A,(IY+$01)
  LD D,A
l_C58C:
  DEC IY
  DEC IY
  LD L,(IY+$00)
  LD H,(IY+$01)
  RES 7,H
  CP H
  JR C,l_C5A6
  JR NZ,l_C58C
  EX DE,HL
  LD A,E
  LD (l_C5AF+$000B),A
  LD A,D
  JP l_C58C
l_C5A6:
  LD A,H
  SUB D
  LD D,A
  LD A,E
  SUB L
  JR NC,l_C5AF
  NEG
l_C5AF:
  PUSH AF
  LD H,A
  LD L,D
  LD B,D
  INC B
  CALL EdgeSlope
  EX DE,HL
  LD HL,$007F
  LD A,B
  EX AF,AF'
  EXX
  POP AF
  JR C,l_C5D0
  POP AF
  JP C,l_C6F1
  PUSH DE
  EXX
  EX (SP),HL
  SCF
  SBC HL,DE
  POP HL
  EXX
  JP l_C5DF
l_C5D0:
  POP AF
  JP NC,l_C665
  PUSH DE
  EXX
  EX (SP),HL
  AND A
  SBC HL,DE
  POP HL
  EXX
  JP l_C76A
l_C5DF:
  LD C,E
  SRL D
  RR E
  LD A,H
  AND A
  SBC HL,DE
  RL E
  RL D
  LD E,C
  DEC B
  JP l_C62D
l_C5F1:
  LD C,E
  SRL D
  RR E
  LD A,H
  AND A
  SBC HL,DE
  RL E
  RL D
  LD E,C
  DEC B
  JP l_C640
l_C603:
  PUSH BC
  EX AF,AF'
  LD A,B
  CP C
  JP C,l_C7E9
  EXX
  LD A,H
  SBC HL,DE
  DJNZ l_C640
  BIT 7,(IX+$01)
  JR NZ,l_C61F
  CALL NextLeftEdge
  JP NC,l_C5F1
  JP l_C701
l_C61F:
  LD H,(IX+$00)
  LD L,$7F
  SRL D
  RR E
  ADD HL,DE
  LD A,H
  JP l_C640
l_C62D:
  EXX
  LD B,A
  LD A,E
  SRL D
  RR E
  AND A
  SBC HL,DE
  LD C,H
  RL E
  RL D
  LD E,A
  JP l_C646
l_C640:
  EXX
  LD B,A
  AND A
  SBC HL,DE
  LD C,H
l_C646:
  EX AF,AF'
  DEC A
  JR NZ,l_C603
  BIT 7,(IY+$01)
  JR NZ,l_C659
  CALL NextRightEdge
  JP C,l_C6B3
  JP l_C62D
l_C659:
  LD C,(IY+$00)
  LD A,B
  CP C
  JP C,l_C7E9
  PUSH BC
  JP FillSpansThenReturn
l_C665:
  LD C,E
  SRL D
  RR E
  AND A
  LD A,H
  SBC HL,DE
  RL E
  RL D
  LD E,C
  DEC B
  JP l_C6B3
l_C677:
  LD C,E
  SRL D
  RR E
  AND A
  LD A,H
  SBC HL,DE
  RL E
  RL D
  LD E,C
  DEC B
  JP l_C6C4
l_C689:
  PUSH BC
  EX AF,AF'
  LD A,B
  CP C
  JP C,l_C7E9
  EXX
  LD A,H
  SBC HL,DE
  DJNZ l_C6C4
  BIT 7,(IX+$01)
  JR NZ,l_C6A5
  CALL NextLeftEdge
  JP C,l_C77A
  JP l_C677
l_C6A5:
  SRL D
  RR E
  LD H,(IX+$00)
  LD L,$7F
  ADD HL,DE
  LD A,H
  JP l_C6C4
l_C6B3:
  EXX
  LD B,A
  LD C,H
  LD A,E
  SRL D
  RR E
  ADD HL,DE
  RL E
  RL D
  LD E,A
  JP l_C6C8
l_C6C4:
  EXX
  LD B,A
  LD C,H
  ADD HL,DE
l_C6C8:
  EX AF,AF'
  DEC A
  JR NZ,l_C689
  BIT 7,(IY+$01)
  JR NZ,l_C6DB
  CALL NextRightEdge
  JP C,l_C6B3
  JP l_C62D
l_C6DB:
  LD H,(IY+$00)
  LD L,$7F
  SRL D
  RR E
  AND A
  SBC HL,DE
  LD C,H
  LD A,B
  CP C
  JP C,l_C7E9
  PUSH BC
  JP FillSpansThenReturn
l_C6F1:
  LD A,E
  SRL D
  RR E
  ADD HL,DE
  RL E
  RL D
  LD E,A
  LD A,H
  DEC B
  JP l_C732
l_C701:
  LD A,E
  SRL D
  RR E
  ADD HL,DE
  RL E
  RL D
  LD E,A
  LD A,H
  DEC B
  JP l_C745
l_C711:
  PUSH BC
  EX AF,AF'
  LD A,B
  CP C
  JP C,l_C7E9
  EXX
  ADD HL,DE
  LD A,H
  DJNZ l_C745
  BIT 7,(IX+$01)
  JR NZ,l_C72C
  CALL NextLeftEdge
  JP C,l_C701
  JP l_C5F1
l_C72C:
  LD A,(IX+$00)
  JP l_C745
l_C732:
  EXX
  LD B,A
  LD A,E
  SRL D
  RR E
  AND A
  SBC HL,DE
  LD C,H
  RL E
  RL D
  LD E,A
  JP l_C74B
l_C745:
  EXX
  LD B,A
  AND A
  SBC HL,DE
  LD C,H
l_C74B:
  EX AF,AF'
  DEC A
  JR NZ,l_C711
  BIT 7,(IY+$01)
  JR NZ,l_C75E
  CALL NextRightEdge
  JP C,l_C7AB
  JP l_C732
l_C75E:
  LD C,(IY+$00)
  LD A,B
  CP C
  JP C,l_C7E9
  PUSH BC
  JP FillSpansThenReturn
l_C76A:
  LD A,E
  SRL D
  RR E
  ADD HL,DE
  RL E
  RL D
  LD E,A
  LD A,H
  DEC B
  JP l_C7AB
l_C77A:
  LD A,E
  SRL D
  RR E
  ADD HL,DE
  RL E
  RL D
  LD E,A
  LD A,H
  DEC B
  JP l_C7BC
l_C78A:
  PUSH BC
  EX AF,AF'
  LD A,B
  CP C
  JP C,l_C7E9
  EXX
  ADD HL,DE
  LD A,H
  DJNZ l_C7BC
  BIT 7,(IX+$01)
  JR NZ,l_C7A5
  CALL NextLeftEdge
  JP C,l_C77A
  JP l_C677
l_C7A5:
  LD A,(IX+$00)
  JP l_C7BC
l_C7AB:
  EXX
  LD B,A
  LD C,H
  LD A,E
  SRL D
  RR E
  ADD HL,DE
  RL E
  RL D
  LD E,A
  JP l_C7C0
l_C7BC:
  EXX
  LD B,A
  LD C,H
  ADD HL,DE
l_C7C0:
  EX AF,AF'
  DEC A
  JR NZ,l_C78A
  BIT 7,(IY+$01)
  JR NZ,l_C7D3
  CALL NextRightEdge
  JP C,l_C7AB
  JP l_C732
l_C7D3:
  LD H,(IY+$00)
  LD L,$80
  SRL D
  RR E
  AND A
  SBC HL,DE
  LD C,H
  LD A,B
  CP C
  JP C,l_C7E9
  PUSH BC
  JP FillSpansThenReturn
l_C7E9:
  LD SP,$0000
  RET

; Take the next edge on the right side (IY backwards): its rows and step
;
; Witness: L1 10893 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
NextRightEdge:
  LD A,(IY+$00)
  LD (l_C81F+$0009),A
  LD E,A
  LD A,(IY+$01)
  AND $7F
  LD D,A
l_C7FA:
  DEC IY
  DEC IY
  LD L,(IY+$00)
  LD H,(IY+$01)
  RES 7,H
  CP H
  JR C,l_C814
  JR NZ,l_C7FA
  EX DE,HL
  LD A,E
  LD (l_C81F+$0009),A
  LD A,D
  JP l_C7FA
l_C814:
  LD A,H
  SUB D
  LD D,A
  INC A
  EX AF,AF'
  LD A,E
  SUB L
  JR NC,l_C81F
  NEG
l_C81F:
  PUSH AF
  LD H,A
  LD L,D
  CALL EdgeSlope
  EX DE,HL
  LD HL,$007F
  POP AF
  LD A,B
  EXX
  RET

; Take the next edge on the left side (IX forwards): its rows and step
;
; Witness: L1 9734 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
NextLeftEdge:
  LD A,(IX+$00)
  LD (l_C85D+$000A),A
  LD E,A
  LD A,(IX+$01)
  AND $7F
  LD D,A
l_C83A:
  INC IX
  INC IX
  LD L,(IX+$00)
  LD H,(IX+$01)
  RES 7,H
  CP H
  JR C,l_C854
  JR NZ,l_C83A
  EX DE,HL
  LD A,E
  LD (l_C85D+$000A),A
  LD A,D
  JP l_C83A
l_C854:
  LD A,H
  SUB D
  LD B,A
  LD A,E
  SUB L
  JR NC,l_C85D
  NEG
l_C85D:
  PUSH AF
  LD H,A
  LD L,B
  INC B
  CALL EdgeSlope
  EX DE,HL
  LD HL,$007F
  POP AF
  RET

; Pop the spans and fill them row by row in the back buffer with the colour's
; 2-row dither pattern
;
; The pattern from FillPatterns `$66D6` + 2 `$7579` (solid `$FF` when `$757A` =
; 0); the edges masked with RightEdgeMasks / LeftEdgeMasks `$66F0`; the middle
; bytes by a patched jump into 31 `LD (HL),B`. Writes `$8AF8-$96F0`; 85
; permille of the recordings' time (the heaviest routine of the 3D view after
; the blit).
;
; Witness: L1 33753 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
FillSpans:
  POP HL
  LD (l_C930+$000A),HL
  LD A,($757A)
  AND A
  JP NZ,l_C879
  LD B,$FF
  JR l_C885
l_C879:
  LD A,($7579)
  ADD A,A
  ADD A,$D6
  LD L,A
  LD H,$66
  LD A,(HL)
  INC L
  LD B,(HL)
l_C885:
  LD C,A
  LD (l_C930+$0002),A
  LD A,($67BD)
  LD H,A
  RRA
  LD A,B
  JR NC,l_C892
  XOR C
l_C892:
  EX AF,AF'
  XOR A
  CALL $A7B6
  LD DE,$8AF1
  ADD HL,DE
  LD A,($68A8)
  LD B,A
  EX AF,AF'
  LD DE,$FFE0
l_C8A3:
  PUSH HL
  EXX
  POP HL
  LD B,A
  POP DE
  EX AF,AF'
  LD A,E
  RRCA
  RRCA
  RRCA
  AND $1F
  LD C,A
  PUSH BC
  LD B,$00
  ADD HL,BC
  POP BC
  LD A,D
  RRCA
  RRCA
  RRCA
  AND $1F
  SUB C
  JP Z,l_C93C
  LD C,A
  PUSH DE
  LD A,E
  AND $07
  JR Z,l_C8D6
  LD D,$66
  ADD A,$F8
  LD E,A
  LD A,(DE)
  LD E,A
  CPL
  AND B
  LD D,A
  LD A,(HL)
  AND E
  OR D
  LD (HL),A
  DEC C
  INC HL
l_C8D6:
  LD A,$1F
  AND A
  SBC A,C
  ADD A,A
  LD (l_C8D6+$0009),A
  JR l_C8D6+$0009
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  POP DE
  LD A,D
  AND $07
  LD D,$66
  ADD A,$F0
  LD E,A
  LD A,(DE)
  LD E,A
  CPL
  AND B
  LD D,A
  LD A,(HL)
  AND E
  OR D
  LD (HL),A
l_C930:
  EX AF,AF'
  XOR $00
  EXX
  ADD HL,DE
  DEC B
  JP NZ,l_C8A3
  JP $0000
l_C93C:
  EX DE,HL
  LD A,L
  AND $07
  ADD A,$F8
  LD L,A
  LD A,H
  LD H,$66
  LD C,(HL)
  AND $07
  ADD A,$F0
  LD L,A
  LD A,C
  OR (HL)
  LD C,A
  CPL
  AND B
  LD B,A
  LD A,(DE)
  AND C
  OR B
  LD (DE),A
  JP l_C930

; HL = 256 H / L by logarithms (LogFraction, LogInteger, ExpFraction): the x
; step per row; 0 or `$FFFF` at the limits
;
; Witness: L1 83529 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
EdgeSlope:
  LD A,H
  LD H,$5C
  LD E,(HL)
  INC H
  LD D,(HL)
  LD L,A
  LD A,(HL)
  ADD A,$08
  DEC H
  LD L,(HL)
  LD H,A
  SBC HL,DE
  JP P,l_C96F
  LD HL,$0000
  RET
l_C96F:
  LD A,H
  LD E,A
  LD H,$5E
  LD L,(HL)
  LD H,$01
  SUB $08
  JR NC,l_C98D
  LD A,$07
  SUB E
  LD (l_C980+$0001),A
l_C980:
  JR NZ,l_C980
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD L,H
  LD H,$00
  RET
l_C98D:
  LD A,$0F
  SUB E
  JR C,l_C9A3
  LD (l_C995+$0001),A
l_C995:
  JR NZ,l_C995
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  RET

; data_C99F
data_C99F:
  DEFB $21,$00,$00,$C9

; l_C9A3
;
; Used by the routine at EdgeSlope.
l_C9A3:
  LD HL,$FFFF
  RET

; Draw a line from (H, L) to (D, E) (x, y bytes) into the back buffer by OR,
; Bresenham
;
; Special cases: vertical (`$CA60`), horizontal (`$CA4E`), 45 degrees
; (`$CA74`); the pixel bit of the start in `$CA89`. Entered from bank 5
; `$72B1`.
;
; Witness: L1 4996 (c1, death, m2erbe, menu, missions, play, play2).
DrawLine:
  LD A,D
  SUB H
  JR NC,l_C9AE
  NEG
  EX DE,HL
l_C9AE:
  LD C,A
  LD A,E
  LD DE,$0020
  SUB L
  JR NC,l_C9BB
  NEG
  LD DE,$FFE0
l_C9BB:
  LD B,A
  PUSH BC
  PUSH DE
  LD A,H
  LD B,H
  LD H,L
  AND $F8
  LD L,$00
  SRL H
  RRA
  SRL H
  RRA
  SRL H
  RRA
  LD DE,$8AF1
  ADD HL,DE
  ADD A,L
  LD L,A
  JR NC,l_C9D7
  INC H
l_C9D7:
  LD A,B
  AND $07
  LD (LinePixelBit),A
  LD B,A
  LD A,$80
  JR Z,l_C9E5
l_C9E2:
  RRCA
  DJNZ l_C9E2
l_C9E5:
  LD C,A
  POP DE
  LD A,(HL)
  EXX
  EX AF,AF'
  POP DE
  LD A,D
  AND A
  JP Z,l_CA4E
  LD A,E
  AND A
  JP Z,DrawVerticalLine
  SUB D
  JR C,l_CA26
  JP Z,l_CA74
  LD B,E
  LD A,E
  RRA
l_C9FE:
  SUB D
  JR C,l_CA13
  EXX
  EX AF,AF'
  OR C
  RRC C
  JP NC,l_CA0C
  LD (HL),A
  INC HL
  LD A,(HL)
l_CA0C:
  EXX
  EX AF,AF'
  DJNZ l_C9FE
  JP l_CA21
l_CA13:
  ADD A,E
  EXX
  EX AF,AF'
  OR C
  RRC C
  LD (HL),A
  ADC HL,DE
  LD A,(HL)
  EXX
  EX AF,AF'
  DJNZ l_C9FE
l_CA21:
  EXX
  EX AF,AF'
  OR C
  LD (HL),A
  RET
l_CA26:
  LD B,D
  LD A,D
  SRL A
l_CA2A:
  SUB E
  JR C,l_CA3A
  EXX
  EX AF,AF'
  LD A,C
  OR (HL)
  LD (HL),A
  ADD HL,DE
  EXX
  EX AF,AF'
  DJNZ l_CA2A
  JP l_CA48
l_CA3A:
  ADD A,D
  EXX
  EX AF,AF'
  LD A,C
  OR (HL)
  LD (HL),A
  RRC C
  ADC HL,DE
  EXX
  EX AF,AF'
  DJNZ l_CA2A
l_CA48:
  EXX
  EX AF,AF'
  LD A,C
  OR (HL)
  LD (HL),A
  RET
l_CA4E:
  LD A,E
  INC A
  EXX
  LD B,A
  EX AF,AF'
l_CA53:
  OR C
  RRC C
  JP NC,l_CA5C
  LD (HL),A
  INC HL
  LD A,(HL)
l_CA5C:
  DJNZ l_CA53
  LD (HL),A
  RET

; A vertical line: `SET n,(HL)` patched to the column's bit, down D + 1 rows
;
; Witness: L1 1262 (c1, death, m2erbe, menu, missions, play, play2).
DrawVerticalLine:
  LD A,(LinePixelBit)
  CPL
  RLCA
  RLCA
  ADD A,A
  LD (l_CA6E+$0001),A
  LD A,D
  EXX
  LD B,A
  INC B
l_CA6E:
  SET 0,(HL)
  ADD HL,DE
  DJNZ l_CA6E
  RET
; This entry point is used by the routine at DrawLine.
l_CA74:
  LD B,D
  EX AF,AF'
l_CA76:
  EXX
  LD A,C
  OR (HL)
  LD (HL),A
  RRC C
  JP NC,l_CA80
  INC HL
l_CA80:
  ADD HL,DE
  EXX
  DJNZ l_CA76
  EXX
  LD A,C
  OR (HL)
  LD (HL),A
  RET

; DrawLine's start pixel bit number, and a spare byte
LinePixelBit:
  DEFB $00,$00

; Shared 3D model scripts (RunScript format), 1346 bytes: six models and their
; parts
;
; `$CA8B` (a building with two halves ordered by face 0: parts `$CAA7`,
; `$CCDA`), `$CAA7` (32 vertices, 24 faces, nested parts with OpCall to
; `$CDF8`), `$CCDA`, `$CDF8` (a sub-model called twice), `$CE47`, `$CED1`
; (`$CB39` of bank 6 draws it), `$CF26`. Each starts with a box generator (`00
; F7 67` = BoxRect). Read by RunScript `$990F` in all 11 recordings.
SharedModels:
  DEFB $00,$F7,$67,$18,$7F,$1E,$01,$27,$A6,$A6,$A8,$75,$FF,$02,$03,$4C
  DEFB $05,$00,$01,$A0,$9C,$98,$0A,$00,$DA,$CC,$F7,$CD,$00,$F7,$67,$18
  DEFB $7F,$1E,$01,$22,$A6,$40,$A6,$44,$23,$A7,$41,$A7,$45,$24,$A8,$42
  DEFB $A8,$46,$25,$A9,$43,$A9,$47,$05,$84,$7F,$84,$84,$48,$3F,$85,$85
  DEFB $49,$06,$87,$7E,$87,$87,$4A,$3E,$86,$86,$4B,$86,$E0,$06,$7B,$04
  DEFB $87,$7D,$BF,$BD,$4C,$3D,$BE,$BD,$4D,$3D,$84,$4E,$E0,$04,$78,$3D
  DEFB $87,$4F,$05,$86,$7C,$85,$50,$BC,$51,$06,$BC,$52,$BC,$53,$E0,$12
  DEFB $7A,$26,$A9,$7D,$A7,$BD,$54,$3D,$A8,$BD,$55,$27,$A8,$7C,$A7,$BC
  DEFB $56,$C0,$3B,$5A,$C0,$3A,$5C,$C0,$3A,$C0,$3B,$5D,$3C,$A8,$BC,$57
  DEFB $C0,$3B,$5B,$E0,$3A,$5E,$E0,$3A,$C0,$3B,$5F,$3C,$A9,$A9,$58,$3C
  DEFB $A6,$A6,$59,$22,$A8,$BA,$7A,$22,$A8,$BB,$7B,$00,$E0,$04,$79,$C0
  DEFB $08,$60,$C0,$3A,$40,$09,$C0,$39,$61,$C0,$3A,$41,$10,$C0,$39,$E0
  DEFB $3B,$42,$12,$C0,$39,$E0,$3B,$43,$0B,$C0,$39,$6A,$E0,$3A,$44,$0A
  DEFB $C0,$39,$6B,$E0,$3A,$45,$0F,$C0,$39,$C0,$3B,$46,$0E,$C0,$39,$C0
  DEFB $3B,$47,$FF,$02,$20,$00,$05,$00,$18,$60,$5C,$64,$58,$4C,$44,$4C
  DEFB $5C,$6C,$68,$58,$44,$70,$78,$48,$2C,$48,$78,$40,$24,$74,$48,$2C
  DEFB $10,$40,$08,$04,$2C,$7C,$60,$64,$74,$24,$2C,$28,$14,$20,$24,$04
  DEFB $28,$3C,$18,$38,$20,$00,$54,$3C,$28,$50,$20,$38,$3C,$54,$34,$50
  DEFB $38,$30,$3C,$34,$38,$54,$50,$30,$3C,$38,$1C,$40,$48,$0C,$1C,$04
  DEFB $10,$0A,$17,$B1,$CC,$D9,$CC,$0A,$14,$69,$CC,$B0,$CC,$0A,$04,$47
  DEFB $CC,$68,$CC,$0C,$0E,$00,$0A,$06,$08,$7C,$78,$70,$74,$64,$60,$04
  DEFB $08,$04,$03,$70,$78,$48,$40,$01,$08,$04,$05,$58,$5C,$44,$4C,$16
  DEFB $08,$04,$07,$40,$48,$0C,$08,$05,$08,$04,$07,$2C,$48,$78,$7C,$06
  DEFB $08,$04,$07,$40,$24,$74,$70,$07,$08,$04,$08,$48,$2C,$10,$0C,$08
  DEFB $08,$04,$08,$40,$08,$04,$24,$09,$08,$04,$06,$2C,$7C,$60,$28,$0A
  DEFB $08,$04,$06,$74,$24,$20,$64,$0B,$08,$04,$07,$2C,$28,$14,$10,$0C
  DEFB $08,$04,$07,$20,$24,$04,$00,$14,$08,$04,$07,$60,$64,$20,$28,$17
  DEFB $0C,$08,$01,$00,$04,$08,$0C,$10,$14,$18,$1C,$09,$0C,$04,$02,$07
  DEFB $03,$01,$4C,$5C,$6C,$03,$07,$03,$01,$68,$58,$44,$01,$08,$04,$05
  DEFB $58,$5C,$4C,$44,$00,$08,$04,$08,$5C,$58,$68,$6C,$09,$09,$0C,$09
  DEFB $11,$07,$03,$07,$3C,$54,$34,$12,$07,$03,$07,$50,$38,$30,$13,$08
  DEFB $04,$08,$34,$30,$38,$3C,$14,$08,$04,$01,$54,$50,$30,$34,$0F,$07
  DEFB $03,$05,$54,$3C,$28,$10,$07,$03,$05,$50,$20,$38,$0D,$08,$04,$08
  DEFB $28,$3C,$18,$14,$0E,$08,$04,$08,$38,$20,$00,$1C,$15,$08,$04,$03
  DEFB $3C,$38,$1C,$18,$09,$09,$0A,$02,$C7,$CC,$D8,$CC,$01,$20,$6C,$21
  DEFB $6D,$22,$6E,$23,$6F,$38,$76,$FF,$0B,$F8,$CD,$09,$01,$2A,$6C,$2B
  DEFB $6D,$24,$6E,$25,$6F,$38,$F0,$76,$FF,$0B,$F8,$CD,$09,$09,$09,$00
  DEFB $7B,$AB,$20,$48,$0F,$01,$22,$A4,$F0,$C0,$35,$40,$C0,$22,$62,$23
  DEFB $C0,$00,$63,$24,$C0,$00,$64,$25,$C0,$00,$65,$26,$C0,$00,$66,$27
  DEFB $C0,$00,$67,$28,$C0,$00,$68,$29,$C0,$00,$69,$22,$A5,$7F,$A2,$40
  DEFB $3F,$A5,$41,$23,$A4,$7E,$A3,$43,$3E,$A4,$42,$23,$A2,$A2,$44,$A2
  DEFB $E0,$22,$72,$24,$A5,$A5,$45,$28,$A6,$7F,$A6,$46,$3F,$A9,$47,$27
  DEFB $A8,$7F,$86,$48,$3F,$87,$49,$26,$E0,$27,$7E,$07,$80,$7F,$80,$4A
  DEFB $C0,$3E,$C0,$32,$4B,$3F,$81,$4C,$C0,$3E,$C0,$32,$4D,$3F,$87,$4E
  DEFB $C0,$3E,$4F,$3F,$86,$50,$C0,$3E,$51,$FF,$02,$12,$00,$05,$00,$0D
  DEFB $1C,$18,$00,$18,$10,$00,$14,$1C,$04,$24,$18,$1C,$18,$20,$0C,$24
  DEFB $1C,$14,$08,$0C,$20,$10,$0C,$14,$44,$40,$28,$3C,$38,$40,$38,$3C
  DEFB $34,$2C,$28,$30,$3C,$44,$2C,$0A,$00,$CB,$CD,$F6,$CD,$0C,$08,$00
  DEFB $08,$04,$07,$1C,$18,$00,$04,$01,$07,$03,$06,$18,$10,$00,$02,$07
  DEFB $03,$06,$14,$1C,$04,$03,$08,$04,$08,$24,$20,$18,$1C,$04,$08,$04
  DEFB $07,$18,$20,$0C,$10,$05,$08,$04,$07,$24,$1C,$14,$08,$06,$08,$04
  DEFB $06,$08,$0C,$20,$24,$07,$0A,$06,$01,$10,$0C,$08,$14,$04,$00,$09
  DEFB $0C,$05,$08,$08,$04,$03,$44,$40,$28,$2C,$0A,$08,$04,$03,$38,$3C
  DEFB $34,$30,$09,$08,$04,$04,$3C,$38,$40,$44,$0B,$08,$04,$04,$2C,$28
  DEFB $30,$34,$0C,$08,$04,$05,$3C,$44,$2C,$34,$09,$09,$FF,$01,$2E,$AF
  DEFB $77,$AF,$AD,$6F,$C0,$36,$70,$37,$AE,$AC,$6E,$C0,$36,$71,$2C,$C0
  DEFB $36,$72,$2D,$C0,$36,$73,$FF,$02,$08,$58,$05,$1E,$04,$B0,$B4,$BC
  DEFB $B4,$CC,$C0,$CC,$C8,$C4,$C8,$B0,$B8,$0C,$04,$1E,$08,$04,$04,$B0
  DEFB $B4,$BC,$B8,$20,$08,$04,$05,$CC,$C8,$C4,$C0,$1F,$08,$04,$09,$B4
  DEFB $CC,$C0,$BC,$21,$08,$04,$09,$C8,$B0,$B8,$C4,$09,$00,$F7,$67,$08
  DEFB $30,$08,$01,$29,$A2,$5E,$A9,$61,$1E,$A6,$60,$1E,$A5,$5F,$1E,$A2
  DEFB $5E,$26,$A7,$E0,$27,$41,$C0,$21,$5D,$1F,$C0,$01,$5C,$20,$C0,$01
  DEFB $5B,$1E,$C0,$01,$5A,$FF,$02,$10,$34,$05,$00,$07,$A0,$A4,$94,$84
  DEFB $74,$70,$98,$9C,$8C,$6C,$80,$78,$A4,$98,$88,$9C,$A0,$90,$74,$6C
  DEFB $68,$0A,$04,$AD,$CE,$D0,$CE,$0C,$03,$00,$08,$04,$04,$A0,$A4,$94
  DEFB $90,$02,$08,$04,$04,$98,$9C,$8C,$88,$05,$08,$04,$05,$9C,$A0,$90
  DEFB $8C,$09,$0C,$04,$04,$08,$04,$05,$A4,$98,$88,$94,$01,$08,$04,$03
  DEFB $84,$74,$70,$7C,$03,$08,$04,$03,$6C,$80,$78,$68,$06,$08,$04,$04
  DEFB $74,$6C,$68,$70,$09,$FF,$00,$F7,$67,$10,$20,$20,$01,$26,$A7,$A6
  DEFB $41,$F0,$42,$26,$A2,$A6,$43,$F0,$44,$29,$A8,$A9,$45,$F0,$46,$29
  DEFB $A5,$A9,$47,$F0,$48,$FF,$02,$08,$02,$05,$00,$04,$04,$20,$18,$10
  DEFB $14,$1C,$04,$14,$10,$1C,$0C,$18,$0C,$04,$00,$08,$04,$05,$04,$20
  DEFB $18,$0C,$01,$08,$04,$05,$10,$14,$1C,$08,$02,$08,$04,$03,$04,$14
  DEFB $10,$20,$03,$08,$04,$03,$1C,$0C,$18,$08,$FF,$00,$F7,$67,$20,$30
  DEFB $0A,$01,$29,$A2,$41,$A9,$44,$26,$81,$60,$84,$84,$61,$20,$84,$A0
  DEFB $60,$22,$81,$45,$25,$81,$46,$85,$86,$5E,$05,$86,$85,$5F,$29,$A6
  DEFB $42,$A9,$5D,$F8,$5A,$02,$A6,$5C,$F8,$5B,$27,$E0,$26,$43,$20,$E0
  DEFB $03,$59,$1F,$E0,$03,$58,$21,$E0,$03,$57,$1E,$E0,$03,$56,$FF,$02
  DEFB $12,$2C,$05,$00,$08,$74,$70,$88,$68,$6C,$90,$70,$68,$8C,$6C,$74
  DEFB $94,$64,$80,$7C,$84,$5C,$58,$5C,$64,$60,$7C,$80,$84,$0A,$07,$B1
  DEFB $CF,$CC,$CF,$0C,$04,$00,$08,$04,$02,$74,$70,$88,$94,$04,$08,$04
  DEFB $01,$64,$80,$7C,$60,$05,$08,$04,$01,$84,$5C,$58,$78,$06,$08,$04
  DEFB $00,$5C,$64,$60,$58,$09,$0C,$03,$01,$08,$04,$03,$68,$6C,$90,$8C
  DEFB $02,$08,$04,$04,$70,$68,$8C,$88,$03,$08,$04,$04,$6C,$74,$94,$90
  DEFB $09,$FF

; Patch the X clip's limit (10 operands) with A: `$FF` full width, `$5F` the
; 96-pixel console view
;
; Called through `$74CF` (`$74C9` A = `$FF`, `$74CD` A = `$5F`) by bank 6
; `$CA8B`.
;
; Witness: L1 30 (c1, death, m2erbe, missions, play, play2).
SetClipWidth:
  LD (ClipPolyX+$0026),A
  LD (ClipXRight+$000D),A
  LD (l_C26E+$001A),A
  LD (l_C2B5+$0014),A
  LD (ClipXLeft+$000D),A
  LD (ClipXLeft+$0034),A
  LD (ClipXInside+$0015),A
  LD (ClipXInside+$0028),A
  LD (IntersectColRight+$0002),A
  LD (IntersectColRight+$000D),A
  RET
