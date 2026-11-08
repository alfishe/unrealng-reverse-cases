; --------------------------------------------------------------------------------------------------------------------
; drawships.asm: Drawing a ship: the view's axes, the dot of a far ship, the vertices projected, the visible edges, the laser beams
;
; A ship is drawn in the back buffer only in the four space views (ViewIndex 0-3). The view picks the depth axis: z
; for the front and rear views, x for the side views (bit 1), and the sign that is "ahead" (bit 0); a ship behind the
; view or past 256 in depth is not drawn. Its screen position is depth-divided (DividePoint $AC69: x / depth and y /
; depth as fractions) and must lie within 128 x 64 of the centre. Beyond the blueprint's dot distance (+$0B) it is
; four pixels; nearer, the full wireframe: the visible faces (FaceVisibility $BCD4) and the vertices whose faces are
; visible are rotated into the view (Project), their screen points kept in ProjectedPoints $A8FA, then each edge with
; a visible face is drawn (DrawEdges). The detail level is the distance too: a vertex or an edge whose visibility
; distance (the low 5 bits, $1F always) is below the ship's distance is skipped.
;
; The arithmetic is quarter squares: b x c = ((b + c) / 2)² - ((b - c) / 2)² from the squares table (n² for n = 0-255,
; the low bytes at $BE00 and the high at $BF00, built by the kickoff), so Multiply8 $AB34 is two table reads and a
; subtraction.
; --------------------------------------------------------------------------------------------------------------------

; Draw one ship in the view: the depth, the screen position, the gunsight test,
; then the dot or the wireframe
;
; 1681 runs. The ship in the gunsight is the one whose screen point is within
; its own size of the centre with depth below $2C00 (SightTarget $9C97); a
; hostile ship with tactics that nears the player ahead turns off its avoidance
; (+$26 bit 5). A destroyed ship (+$20 bit 4) is not drawn: its screen point
; and size go into +$1C-+$1F for the explosion (ExplosionPoint). The mission's
; Asp is not drawn while the mission state is 1.
DrawShip:
  LD A,(ViewIndex)
  LD B,A
  CP $04
  RET NC
  PUSH IX
  POP HL
  BIT 1,A
  JR NZ,DrawShipDepth
  LD DE,$0006
  ADD HL,DE
DrawShipDepth:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD C,(HL)
  SRL A
  XOR B
  RRCA
  XOR C
  AND $80
  RET NZ
  LD (ShipDistance),DE
  LD H,$00
  LD L,(IY+$01)
  PUSH HL
  AND A
  SBC HL,DE
  JR C,DrawShipNear
  POP HL
  RET
DrawShipNear:
  PUSH DE
  PUSH DE
  BIT 1,B
  JR NZ,DrawShipSide
  EX DE,HL
  LD D,(IX+$01)
  LD E,(IX+$00)
  XOR A
  LD C,A
  CALL DividePoint
  LD A,C
  LD (ScreenX),A
  POP HL
  LD D,(IX+$04)
  LD E,(IX+$03)
  XOR A
  LD C,A
  CALL DividePoint
  LD A,C
  LD (ScreenY),A
  LD B,(IX+$02)
  JP DrawShipQuadrant
DrawShipSide:
  EX DE,HL
  LD D,(IX+$07)
  LD E,(IX+$06)
  XOR A
  LD C,A
  CALL DividePoint
  LD A,C
  LD (ScreenX),A
  POP HL
  LD D,(IX+$04)
  LD E,(IX+$03)
  XOR A
  LD C,A
  CALL DividePoint
  LD A,C
  LD (ScreenY),A
  LD B,(IX+$08)
DrawShipQuadrant:
  LD A,(IX+$05)
  SLA B
  RLA
  RLA
  LD (ScreenQuadrant),A
  POP HL
  POP DE
  XOR A
  LD C,A
  CALL DividePoint
  LD H,C
  LD A,C
  LD (DotProductSpare),A
  LD E,C
  LD A,(ScreenY)
  LD C,A
  SUB H
  JR C,DrawShipX
  SUB $40
  JP NC,DrawLaserOnly
DrawShipX:
  LD A,(ScreenX)
  LD B,A
  SUB H
  JR C,DrawShipSight
  SUB $80
  JP NC,DrawLaserOnly
DrawShipSight:
  LD A,B
  ADD A,C
  LD D,A
  JR C,DrawShipAlive
  SUB E
  JR NC,DrawShipAvoid
  LD A,(IX+$07)
  CP $2C
  JR NC,DrawShipAvoid
  POP HL
  POP AF
  PUSH AF
  PUSH HL
  LD (SightTarget),A
DrawShipAvoid:
  BIT 6,(IX+$20)
  JR Z,DrawShipAlive
  BIT 2,(IX+$21)
  JR Z,DrawShipAlive
  LD A,(ViewIndex)
  BIT 1,A
  LD A,(IX+$0E)
  LD E,(IX+$07)
  JR Z,DrawShipAvoidTest
  LD A,(IX+$0A)
  LD E,(IX+$01)
DrawShipAvoidTest:
  LD B,A
  AND $7F
  CP $40
  JR C,DrawShipAlive
  LD A,D
  CP $20
  JR NC,DrawShipAlive
  RES 5,(IX+$26)
DrawShipAlive:
  BIT 4,(IX+$20)
  JP NZ,ExplosionPoint
  LD A,(MissionShip)
  DEC A
  JR NZ,DrawShipFar
  BIT 6,(IX+$26)
  JP NZ,DrawLaserOnly
DrawShipFar:
  LD HL,(ShipDistance)
  LD A,H
  CP (IY+$0B)
  JR C,DrawWireframe
  LD A,(ScreenX)
  CP $7F
  JP NC,DrawLaserOnly
  LD C,A
  LD A,(ScreenY)
  CP $3F
  JP NC,DrawLaserOnly
  LD B,A
  LD A,(ViewIndex)
  BIT 0,A
  LD A,(ScreenQuadrant)
  JR Z,DrawShipDot
  XOR $02
DrawShipDot:
  LD D,A
  BIT 1,D
  JR NZ,DrawShipDotLeft
  LD A,C
  ADD A,$7F
  LD C,A
  JR DrawShipDotY
DrawShipDotLeft:
  LD A,$7F
  SUB C
  LD C,A
DrawShipDotY:
  BIT 0,D
  JR Z,DrawShipDotUp
  LD A,B
  ADD A,$3F
  LD B,A
  JR DrawShipDotPlot
DrawShipDotUp:
  LD A,$3F
  SUB B
  LD B,A
DrawShipDotPlot:
  CALL PlotPixel
  INC B
  CALL PlotPixel
  INC C
  CALL PlotPixel
  DEC B
  CALL PlotPixel
  JP DrawLaserOnly

; XOR one pixel at (C, B) into the back buffer through the ROM's PIXEL-ADD
; ($22B1) with H's bit 7 set
;
; Used by the routine at DrawShip.
PlotPixel:
  LD A,B
  CALL $22B1
  LD D,A
  INC D
  LD A,$01
PlotPixelBit:
  RRCA
  DEC D
  JR NZ,PlotPixelBit
  SET 7,H
  XOR (HL)
  LD (HL),A
  RET

; The wireframe: the view's rotation (ViewMatrix), the distance as the detail
; level, the faces, the vertices, the edges and the laser
;
; The laser of a firing ship (+$20 bit 3) is a line from its gun vertex (+$14
; of the blueprint) to a random point at the screen's edge, drawn with bit 7 of
; LineAddress's page byte ($B348) set, so into the back buffer whatever the
; page.
DrawWireframe:
  PUSH IY
  CALL ViewMatrixSetup
  POP IY
  LD HL,(ShipDistance)
  ADD HL,HL
  LD B,$1F
  JR C,DrawWireframeDistance
  LD A,H
  CP B
  JR NC,DrawWireframeDistance
  LD B,H
DrawWireframeDistance:
  LD A,B
  SUB $02
  JR NC,DrawWireframeDetail
  XOR A
DrawWireframeDetail:
  LD (ShipDistance),A
  LD A,$FD
  LD (PointOffset),A
  CALL FaceVisibility
  CALL ProjectVertices
  CALL DrawEdges
  BIT 3,(IX+$20)
  RET Z
  LD A,(IY+$14)
  CALL PointOf
  LD C,A
; This entry point is used by the routine at DrawLaserOnly.
DrawLaserBeam:
  CALL Random
  LD L,A
  SUB $FF
  NEG
  LD H,A
  LD A,C
  CPL
  AND $03
  SLA C
  SLA C
  OR C
  LD C,A
  LD A,(LineAddressBit+$0017)
  PUSH AF
  SET 7,A
  LD (LineAddressBit+$0017),A
  CALL DrawLine
  POP AF
  LD (LineAddressBit+$0017),A
  RES 3,(IX+$20)
  RET

; A destroyed ship: its screen point, its size and the quadrant into +$1C-+$1F,
; the state 11
;
; Used by the routine at DrawShip.
ExplosionPoint:
  LD A,(ScreenX)
  LD (IX+$1C),A
  LD A,(ScreenY)
  LD (IX+$1D),A
  LD A,(DotProductSpare)
  LD (IX+$1F),A
  LD A,(ViewIndex)
  BIT 0,A
  LD A,(ScreenQuadrant)
  JR Z,ExplosionPointQuadrant
  XOR $02
ExplosionPointQuadrant:
  LD C,A
  XOR A
  RR C
  RLA
  RR C
  RLA
  XOR $03
  ADD A,$0C
  LD (IX+$1E),A
  SET 5,(IX+$20)
  RET

; A firing ship that is not drawn still fires: the beam from its screen point
;
; Used by the routine at DrawShip.
DrawLaserOnly:
  BIT 3,(IX+$20)
  RET Z
  LD A,(ScreenX)
  LD D,A
  LD A,(ScreenY)
  LD E,A
  LD A,(ViewIndex)
  BIT 0,A
  LD A,(ScreenQuadrant)
  JR Z,DrawLaserOnlyQuadrant
  XOR $02
DrawLaserOnlyQuadrant:
  LD C,A
  JR DrawLaserBeam

; The screen points of the vertices: x, y and the quadrant ($FF hidden), 3
; bytes each
ProjectedPoints:
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00

; One byte per face: non-zero visible (FaceVisibility)
FaceVisible:
  DEFB $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01

; The ship's axes in the view's order: three rows of three sign and magnitude
; words, then the vertex's rotated parts (+$12-+$17)
ViewMatrix:
  DEFB $7E,$32,$81,$8D,$F3,$24
  DEFB $81,$8D,$7E,$32,$F3,$24
  DEFB $F2,$A4,$F2,$A4,$F3,$24
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00

; The depth's high byte (then the detail level)
ShipDistance:
  DEFB $00

; ShipDistanceHigh
ShipDistanceHigh:
  DEFB $00

; The current vertex's offset into ProjectedPoints
PointOffset:
  DEFB $01

; The rotated vertex plus the ship's position
VertexX:
  DEFW $0000

; VertexY
VertexY:
  DEFW $0000

; VertexZ
VertexZ:
  DEFW $0000

; The ship's or the vertex's screen point and quadrant
ScreenX:
  DEFB $00

; ScreenY
ScreenY:
  DEFB $00

; ScreenQuadrant
ScreenQuadrant:
  DEFB $00

; VertexSignX
VertexSignX:
  DEFB $00

; VertexSignY
VertexSignY:
  DEFB $00

; VertexSignZ
VertexSignZ:
  DEFB $00

; The shift that keeps the vertex's parts in 8 bits
VertexScale:
  DEFB $00

; Zero when the vertex repeats the last one's magnitudes: the products are
; reused
VertexCached:
  DEFB $00

; Each vertex whose visibility distance passes and one of whose faces is
; visible is rotated and projected
;
; Used by the routine at DrawWireframe.
ProjectVertices:
  PUSH IY
  PUSH IY
  LD A,(IY+$03)
  EX (SP),IX
  LD D,(IY+$0D)
  LD E,(IY+$0C)
  ADD IX,DE
  LD IY,ViewMatrix

; ProjectVertex
;
; Used by the routine at ProjectNext.
ProjectVertex:
  PUSH AF
  LD A,(PointOffset)
  ADD A,$03
  LD (PointOffset),A
  LD A,(IX+$03)
  AND $1F
  CP $1F
  JR Z,ProjectVertexFaces
  LD B,A
  LD A,(ShipDistance)
  CP B
  JR NC,ProjectVertexHidden
ProjectVertexFaces:
  LD A,(IX+$04)
  CALL EitherFace
  JR NZ,ProjectVerticesIfNotZero
  LD A,(IX+$05)
  CALL EitherFace
ProjectVerticesIfNotZero:
  JP NZ,Project
ProjectVertexHidden:
  INC A
  LD (VertexCached),A
  POP AF
  JP ProjectNext

; NZ when one of the two faces in A's nibbles is visible
;
; Used by the routines at ProjectVertex and DrawEdges.
EitherFace:
  LD B,A
  SRL B
  SRL B
  SRL B
  SRL B
  AND $0F
  CALL FaceIsVisible
  RET NZ
  LD A,B

; NZ when face A is visible
;
; Used by the routine at EitherFace.
FaceIsVisible:
  LD HL,FaceVisible
  ADD A,L
  LD L,A
  JR NC,FaceIsVisibleNow
  INC H
FaceIsVisibleNow:
  LD A,(HL)
  AND A
  RET

; One rotated part of a scaled vertex: three products with a matrix row,
; summed; a repeat reuses the products with new signs
;
; Used by the routine at Project.
RotateVertexScaled:
  LD A,(VertexCached)
  AND A
  JR NZ,RotateVertexNew
  LD A,(IX+$00)
  CP (IX-$06)
  JR NZ,RotateVertexNew
  LD A,(IX+$01)
  CP (IX-$05)
  JR NZ,RotateVertexNew
  LD A,(IX+$02)
  CP (IX-$04)
  JR NZ,RotateVertexNew
  LD A,(IX+$03)
  XOR (IX-$03)
  LD B,A
  LD L,(IY+$12)
  LD H,(IY+$13)
  LD E,(IY+$14)
  LD D,(IY+$15)
  XOR H
  AND $80
  LD H,A
  LD (IY+$13),H
  RL B
  LD A,B
  XOR D
  AND $80
  LD D,A
  LD (IY+$15),D
  CALL AddSignedBytes
  LD L,A
  LD E,(IY+$16)
  LD D,(IY+$17)
  LD A,B
  RLA
  XOR D
  AND $80
  LD D,A
  LD (IY+$17),D
  CALL AddSignedBytes
  LD L,A
  LD DE,$0006
  ADD IY,DE
  JR RotateVertexScale
RotateVertexNew:
  LD B,(IX+$00)
  CALL MultiplyScaled
  LD A,(IX+$03)
  XOR (IY+$01)
  RLA
  RR H
  LD (IY+$12),L
  LD (IY+$13),H
  EX DE,HL
  INC IY
  INC IY
  LD B,(IX+$01)
  CALL MultiplyScaled
  LD A,(IX+$03)
  RLA
  XOR (IY+$01)
  RLA
  RR H
  LD (IY+$12),L
  LD (IY+$13),H
  CALL AddSignedBytes
  LD L,A
  EX DE,HL
  INC IY
  INC IY
  LD B,(IX+$02)
  CALL MultiplyScaled
  LD A,(IX+$03)
  RLA
  RLA
  XOR (IY+$01)
  RLA
  RR H
  LD (IY+$12),L
  LD (IY+$13),H
  CALL AddSignedBytes
  LD L,A
  INC IY
  INC IY
RotateVertexScale:
  LD A,(VertexScale)
  LD B,A
  XOR A
  LD C,H
  RES 7,H
RotateVertexShift:
  SRL H
  RR L
  RRA
  DJNZ RotateVertexShift
  JR NC,RotateVertexSign
  INC HL
RotateVertexSign:
  BIT 7,C
  RET Z
  SET 7,H
  RET

; A = L + E with the signs in H and D (bit 7), the sign out in H
;
; Used by the routines at DotProduct, RotateVertexScaled, RotateVertexReuse and
; RotateNormal.
AddSignedBytes:
  LD A,H
  XOR D
  RLA
  JR C,AddSignedBytesSub
  LD A,L
  ADD A,E
  RET
AddSignedBytesSub:
  LD A,L
  SUB E
  RET NC
  NEG
  AND A
  LD H,D
  RET

; A = B x C / 256 by quarter squares (the high bytes)
;
; Used by the routines at RotatePart, CombineParts, MultiplyHigh4,
; MultiplyScaled, RotateNormal, OrthogonalisePart and MultiplyWord.
Multiply8High:
  LD A,B
  SUB C
  JR NC,Multiply8HighNow
  NEG
Multiply8HighNow:
  SRL A
  LD H,$BF
  LD L,A
  LD D,(HL)
  LD A,B
  ADD A,C
  RRA
  LD L,A
  LD A,(HL)
  SUB D
  RET

; B shifted up by VertexScale, times a matrix byte's magnitude
;
; Used by the routine at RotateVertexScaled.
MultiplyScaled:
  LD A,(VertexScale)
MultiplyScaledShift:
  SLA B
  DEC A
  JR NZ,MultiplyScaledShift
  LD C,(IY+$01)
  RES 7,C
  PUSH DE
  CALL Multiply8High
  LD L,A
  LD H,$00
  POP DE
  RET

; HL = B x C by quarter squares
;
; Used by the routines at SquareComponent, TidyPart, CombineParts,
; DifferenceOfProducts, MultiplyUnused, MultiplyRound and MultiplyWord.
Multiply8:
  LD A,B
  SUB C
  JR NC,Multiply8Now
  NEG
Multiply8Now:
  SRL A
  LD H,$BE
  LD L,A
  LD E,(HL)
  INC H
  LD D,(HL)
  DEC H
  LD A,B
  ADD A,C
  RRA
  LD L,A
  LD A,(HL)
  INC H
  LD H,(HL)
  LD L,A
  AND A
  SBC HL,DE
  RET

; HL (sign B) plus 2 x DE (sign D): a vertex part added to the ship's position
;
; Used by the routine at ProjectAdd.
AddDoubled:
  LD C,D
  RL E
  RL D
  LD A,B
  XOR C
  JR NZ,AddDoubledSub
  ADD HL,DE
  LD A,B
  RET
AddDoubledSub:
  SBC HL,DE
  JR NC,AddDoubledFlip
  ADD HL,DE
  EX DE,HL
  AND A
  SBC HL,DE
  LD A,C
  RET
AddDoubledFlip:
  LD A,H
  OR L
  LD A,C
  RET Z
  POP DE
  POP AF
  NEG
  PUSH AF
  PUSH DE
  DEC HL
  LD A,B
  RET

; A vertex of small parts (no scale): the rotated parts from the face normals'
; routine, or reused
;
; Used by the routine at Project.
RotateVertexSmall:
  LD A,(VertexCached)
  AND A
  PUSH IX
  JR NZ,RotateVertexSmallNew
  LD B,$03
RotateVertexSmallSame:
  LD A,(IX+$00)
  CP (IX-$06)
  JR NZ,RotateVertexSmallNew
  INC IX
  DJNZ RotateVertexSmallSame
  POP IX
  CALL RotateVertexReuse
  LD (VertexX),HL
  CALL RotateVertexReuse
  LD (VertexY),HL
  CALL RotateVertexReuse
  LD (VertexZ),HL
  JR RotateVertexSmallDone
RotateVertexSmallNew:
  POP IX
  CALL RotateNormal
  LD (VertexX),HL
  CALL RotateNormal
  LD (VertexY),HL
  CALL RotateNormal
  LD (VertexZ),HL
RotateVertexSmallDone:
  XOR A
  LD (VertexHigh),A
  LD (VertexHigh+$0001),A
  LD (VertexHigh+$0002),A
  JP ProjectAdd

; A repeat vertex: the last products with the new signs
;
; Used by the routine at RotateVertexSmall.
RotateVertexReuse:
  LD A,(IX+$03)
  XOR (IX-$03)
  LD B,A
  LD L,(IY+$12)
  LD H,(IY+$13)
  LD E,(IY+$14)
  LD D,(IY+$15)
  XOR H
  AND $80
  LD H,A
  LD (IY+$13),H
  RL B
  LD A,B
  XOR D
  AND $80
  LD D,A
  LD (IY+$15),D
  CALL AddSignedBytes
  LD L,A
  LD E,(IY+$16)
  LD D,(IY+$17)
  LD A,B
  RLA
  XOR D
  AND $80
  LD D,A
  LD (IY+$17),D
  CALL AddSignedBytes
  LD L,A
  LD DE,$0006
  ADD IY,DE
  RET

; One rotated part: three high-byte products of the parts with a matrix row
;
; Used by the routines at RotateVertexSmall and NormalPart.
RotateNormal:
  LD B,(IX+$00)
  LD C,(IY+$01)
  RES 7,C
  CALL Multiply8High
  LD L,A
  LD A,(IX+$03)
  XOR (IY+$01)
  AND $80
  LD H,A
  LD (IY+$12),L
  LD (IY+$13),H
  EX DE,HL
  LD B,(IX+$01)
  LD C,(IY+$03)
  RES 7,C
  PUSH DE
  CALL Multiply8High
  POP DE
  LD L,A
  LD A,(IX+$03)
  RLA
  XOR (IY+$03)
  AND $80
  LD H,A
  LD (IY+$14),L
  LD (IY+$15),H
  CALL AddSignedBytes
  LD L,A
  EX DE,HL
  LD B,(IX+$02)
  LD C,(IY+$05)
  RES 7,C
  PUSH DE
  CALL Multiply8High
  POP DE
  LD L,A
  LD A,(IX+$03)
  RLA
  RLA
  XOR (IY+$05)
  AND $80
  LD H,A
  LD (IY+$16),L
  LD (IY+$17),H
  CALL AddSignedBytes
  LD L,A
  LD DE,$0006
  ADD IY,DE
  RET

; C = the fraction (A H L) / (D E C'), DE scaled to 8 bits first: the
; perspective division
;
; 128713 runs of the normalising loop. C = 256 x numerator / denominator, $FF
; when the numerator is not smaller.
DividePoint:
  LD B,$09

; DividePointNormalise
;
; Used by the routine at DividePointShift.
DividePointNormalise:
  DEC B

; DividePointShift
DividePointShift:
  JR Z,DividePointStart
  RLA
  ADC HL,HL
  JR C,DividePointRound
  RL C
  RL E
  RL D
  JR NC,DividePointNormalise
  RR D
  RR E
  SCF
DividePointRound:
  RR H
  RR L
DividePointStart:
  LD A,D
  LD C,$FF
  CP H
  RET NC
  LD B,H
  DEC C

; DividePointLoop
;
; Used by the routine at LineFraction.
DividePointLoop:
  SLA E
  RLA
  JR C,DividePointSub
  CP B
  JR NC,DividePointSub
  SLA C
  RET NC
  JR DividePointLoop
DividePointSub:
  SUB B
  SCF
  RL C
  RET NC
  JR DividePointLoop

; The rotated vertex's top bytes
VertexHigh:
  DEFB $00,$00,$00

; Rotate one vertex into the view (scaled, small or reused), add the ship's
; position and divide by the depth
;
; Used by the routine at ProjectVertex.
Project:
  PUSH IY
  LD A,(ShipDistance)
  CP $04
  JP NC,RotateVertexSmall
  LD A,(IX+$00)
  OR (IX+$01)
  OR (IX+$02)
  LD B,$FF
ProjectScale:
  INC B
  SLA A
  JR NC,ProjectScale
  LD A,B
  LD (VertexScale),A
  AND A
  JP Z,RotateVertexSmall
  CALL RotateVertexScaled
  LD (VertexHigh),A
  LD (VertexX),HL
  CALL RotateVertexScaled
  LD (VertexHigh+$0001),A
  LD (VertexY),HL
  CALL RotateVertexScaled
  LD (VertexHigh+$0002),A
  LD (VertexZ),HL

; The ship's position plus the rotated vertex, then the screen point by the
; view's axes, stored in ProjectedPoints
;
; Used by the routine at RotateVertexSmall.
ProjectAdd:
  XOR A
  LD (VertexCached),A
  POP IY
  POP HL
  EX (SP),IX
  PUSH HL
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD B,(IX+$02)
  LD DE,(VertexX)
  LD A,(VertexHigh)
  RLA
  PUSH AF
  CALL AddDoubled
  LD (VertexX),HL
  LD (VertexSignX),A
  POP AF
  LD (VertexHigh),A
  LD L,(IX+$03)
  LD H,(IX+$04)
  LD B,(IX+$05)
  LD DE,(VertexY)
  LD A,(VertexHigh+$0001)
  RLA
  PUSH AF
  CALL AddDoubled
  LD (VertexY),HL
  LD (VertexSignY),A
  POP AF
  LD (VertexHigh+$0001),A
  LD L,(IX+$06)
  LD H,(IX+$07)
  LD B,(IX+$08)
  LD DE,(VertexZ)
  LD A,(VertexHigh+$0002)
  RLA
  PUSH AF
  CALL AddDoubled
  LD (VertexZ),HL
  LD (VertexSignZ),A
  POP AF
  LD (VertexHigh+$0002),A
  LD A,(ViewIndex)
  BIT 1,A
  JR NZ,ProjectAddSide
  LD DE,(VertexX)
  LD A,(VertexHigh)
  LD C,A
  LD A,(VertexHigh+$0002)
  CALL DividePoint
  LD A,C
  LD (ScreenX),A
  LD DE,(VertexY)
  LD HL,(VertexZ)
  LD A,(VertexHigh+$0001)
  LD C,A
  LD A,(VertexHigh+$0002)
  CALL DividePoint
  LD A,C
  LD (ScreenY),A
  LD A,(VertexSignX)
  RLA
  RL C
  LD A,(VertexSignZ)
  RLA
  RL B
  JR ProjectAddQuadrant
ProjectAddSide:
  EX DE,HL
  LD HL,(VertexX)
  LD A,(VertexHigh+$0002)
  LD C,A
  LD A,(VertexHigh)
  CALL DividePoint
  LD A,C
  LD (ScreenX),A
  LD DE,(VertexY)
  LD HL,(VertexX)
  LD A,(VertexHigh+$0001)
  LD C,A
  LD A,(VertexHigh)
  CALL DividePoint
  LD A,C
  LD (ScreenY),A
  LD A,(VertexSignX)
  RLA
  RL B
  LD A,(VertexSignZ)
  RLA
  RL C
ProjectAddQuadrant:
  LD A,(VertexSignY)
  RLA
  RL C
  LD A,(ViewIndex)
  BIT 0,A
  LD A,C
  JR Z,ProjectAddStore
  XOR $02
ProjectAddStore:
  AND $03
  LD (ScreenQuadrant),A
  LD A,(PointOffset)
  LD HL,ProjectedPoints
  ADD A,L
  JR NC,ProjectAddIfNotBelow
  INC H
ProjectAddIfNotBelow:
  LD L,A
  LD A,(ScreenX)
  LD (HL),A
  INC HL
  LD A,(ScreenY)
  LD (HL),A
  INC HL
  LD A,(ViewIndex)
  LD C,A
  RRA
  XOR C
  XOR B
  RRA
  LD A,(ScreenQuadrant)
  JR NC,ProjectAddDone
  LD A,$FF
ProjectAddDone:
  LD (HL),A
  POP AF
  EX (SP),IX

; The next vertex
;
; Used by the routine at ProjectVertex.
ProjectNext:
  LD BC,$0006
  ADD IX,BC
  INC DE
  DEC A
  JP NZ,ProjectVertex
  POP IX
  POP IY
  RET

; Each edge with a visible face, its distance passing and both ends in front: a
; line between its two points
;
; Used by the routine at DrawWireframe.
DrawEdges:
  LD E,(IY+$0E)
  LD D,(IY+$0F)
  LD B,(IY+$04)
  PUSH IY
  EX (SP),IX
  ADD IX,DE
DrawEdgesLoop:
  PUSH BC
  LD A,(IX+$00)
  CP $1F
  JR Z,DrawEdgesFaces
  LD C,A
  LD A,(ShipDistance)
  CP C
  JR NC,DrawEdgesNext
DrawEdgesFaces:
  LD A,(IX+$03)
  CALL EitherFace
  JR Z,DrawEdgesNext
  LD A,(IX+$01)
  CALL PointOf
  JR NZ,DrawEdgesNext
  LD C,A
  PUSH DE
  LD A,(IX+$02)
  CALL PointOf
  EX DE,HL
  POP DE
  JR NZ,DrawEdgesNext
  RRCA
  RRA
  RL C
  RLA
  RL C
  CALL DrawLine
DrawEdgesNext:
  POP BC
  LD DE,$0004
  ADD IX,DE
  DJNZ DrawEdgesLoop
  POP IX
  RET

; D, E, A = the screen point of vertex A; NZ when it is hidden
;
; Used by the routines at DrawWireframe and DrawEdges.
PointOf:
  LD B,A
  ADD A,A
  LD HL,ProjectedPoints
  JR NC,PointOfOffset
  INC H
PointOfOffset:
  ADD A,B
  JR NC,PointOfAdd
  INC H
PointOfAdd:
  ADD A,L
  LD L,A
  JR NC,PointOfRead
  INC H
PointOfRead:
  LD D,(HL)
  INC HL
  LD E,(HL)
  INC HL
  LD A,(HL)
  BIT 7,A
  RET

; Make the roof axis square to the nose: roof -= nose x (roof . nose)
;
; Used by the routines at UpdateSlot and TurnTitleShip.
Orthogonalise:
  PUSH IX
  PUSH IX
  EX (SP),IY
  LD DE,$0009
  ADD IX,DE
  LD E,$0F
  ADD IY,DE
  CALL DotProduct
  LD E,A
  CALL OrthogonalisePart
  CALL OrthogonalisePart
  CALL OrthogonalisePart
  POP IY
  POP IX
  RET

; One part of it, clamped
;
; Used by the routine at Orthogonalise.
OrthogonalisePart:
  LD C,(IX+$01)
  LD B,E
  SLA B
  SLA C
  CALL Multiply8High
  LD C,A
  LD A,E
  XOR (IX+$01)
  RLA
  RR C
  LD B,(IY+$01)
  LD A,B
  XOR C
  SLA C
  RL H
  SLA B
  RL H
  RLA
  LD A,B
  JR C,OrthogonalisePartSub
  ADD A,C
  JR NC,OrthogonalisePartStore
  LD A,$FF
  JP OrthogonalisePartStore
OrthogonalisePartSub:
  SUB C
  JR NC,OrthogonalisePartStore
  NEG
  RR H
OrthogonalisePartStore:
  RR H
  RRA
  LD (IY+$01),A
  INC IX
  INC IX
  INC IY
  INC IY
  RET

; The side axis as the roof x nose cross product (three DifferenceOfProducts),
; and ViewMatrix filled from the three axes
;
; Used by the routine at DrawWireframe.
ViewMatrixSetup:
  LD IY,ViewMatrix
  LD B,(IX+$0C)
  LD C,(IX+$14)
  LD D,(IX+$0E)
  LD E,(IX+$12)
  CALL DifferenceOfProducts
  LD (IX+$16),H
  LD (IY+$01),H
  LD B,(IX+$0E)
  LD (IY+$11),B
  LD C,(IX+$10)
  LD (IY+$03),C
  LD D,(IX+$0A)
  LD E,(IX+$14)
  LD (IY+$0F),E
  CALL DifferenceOfProducts
  LD (IX+$18),H
  LD (IY+$07),H
  LD B,(IX+$0A)
  LD (IY+$05),B
  LD C,(IX+$12)
  LD (IY+$09),C
  LD D,(IX+$0C)
  LD (IY+$0B),D
  LD E,(IX+$10)
  CALL DifferenceOfProducts
  LD (IX+$1A),H
  LD (IY+$0D),H
  RET

; HL = B x C - D x E with the signs, halved: a part of a cross product
;
; Used by the routine at ViewMatrixSetup.
DifferenceOfProducts:
  SLA B
  RRA
  XOR C
  SLA C
  AND $80
  LD H,A
  SLA D
  RRA
  XOR E
  SLA E
  AND $80
  XOR H
  SLA H
  RRA
  XOR $80
  PUSH AF
  PUSH DE
  CALL Multiply8
  POP BC
  PUSH HL
  CALL Multiply8
  POP DE
  POP AF
  BIT 6,A
  JR Z,DifferenceOfProductsSub
  ADD HL,DE
  JR NC,DifferenceOfProductsDone
  LD HL,$FFFF
  JR DifferenceOfProductsDone
DifferenceOfProductsSub:
  EX DE,HL
  AND A
  SBC HL,DE
  JR NC,DifferenceOfProductsDone
  ADD HL,DE
  EX DE,HL
  AND A
  SBC HL,DE
  XOR $80
DifferenceOfProductsDone:
  RLA
  RR H
  RR L
  RET

; A sum of three 8 x 16 products (known from the code only: nothing calls it)
MultiplyUnused:
  PUSH IX
  LD IX,$0000
  LD B,A
  PUSH BC
  PUSH DE
  PUSH BC
  PUSH DE
  PUSH BC
  PUSH DE
  LD B,E
  CALL Multiply8
  EX DE,HL
  ADD IX,DE
  POP DE
  POP BC
  LD B,D
  CALL Multiply8
  LD E,$00
  LD D,L
  ADD IX,DE
  LD L,H
  LD H,E
  JR NC,MultiplyUnusedIfNotBelow
  INC HL
MultiplyUnusedIfNotBelow:
  POP BC
  POP DE
  PUSH HL
  LD B,D
  CALL Multiply8
  LD E,$00
  LD D,L
  ADD IX,DE
  POP DE
  LD L,H
  LD H,$00
  JR NC,MultiplyUnusedIfNotBelow2
  INC HL
MultiplyUnusedIfNotBelow2:
  ADD HL,DE
  POP BC
  POP DE
  LD C,D
  PUSH HL
  CALL Multiply8
  POP DE
  ADD HL,DE
  POP IX
  RET

; BC = (H L A) / DE: a 16-bit quotient by shifts
;
; Used by the routines at Divide16Vector, DivideComponent and SquareRootAdd.
Divide16:
  LD BC,$FFFE
Divide16Loop:
  ADD A,A
  RL L
  RL H
  JR C,Divide16Over
  SBC HL,DE
  JR NC,Divide16One
  ADD HL,DE
  SLA C
  RL B
  RET NC
  JR Divide16Loop
Divide16Over:
  AND A
  SBC HL,DE
Divide16One:
  SCF
  RL C
  RL B
  RET NC
  JR Divide16Loop

; (HL - DE) / 2 in sign and magnitude
;
; Used by the routines at HalveSignedVector and RelativePart.
SubtractSigned:
  LD A,D
  XOR $80
  LD D,A

; (HL + DE) / 2 in sign and magnitude
;
; Used by the routine at FaceDot.
AddSignedHalf:
  LD A,H
  XOR D
  LD B,H
  LD C,D
  RES 7,H
  RES 7,D
  AND $80
  JR NZ,AddSignedHalfSub
  ADD HL,DE
  JR AddSignedHalfDone
AddSignedHalfSub:
  SBC HL,DE
  JR NC,AddSignedHalfDone
  ADD HL,DE
  EX DE,HL
  AND A
  SBC HL,DE
  LD B,C
AddSignedHalfDone:
  SRL H
  RR L
  BIT 7,B
  RET Z
  SET 7,H
  RET

; DrawLine's step table: per octant the screen moves
LineSteps:
  DEFB $00,$04,$02,$03
  DEFB $00,$04,$06,$05
  DEFB $00,$08,$02,$01
  DEFB $00,$08,$06,$07
  DEFB $00,$00,$00,$02
  DEFB $01,$02,$00,$00
  DEFB $00,$00,$00,$02
  DEFB $02,$01,$02,$02
  DEFB $00,$00,$00,$00
  DEFB $00,$02,$01,$02
  DEFB $02,$02,$00,$00
  DEFB $00,$02,$02,$01
  DEFB $01,$02,$00,$00
  DEFB $00,$00,$00,$02
  DEFB $02,$01,$02,$02
  DEFB $00,$00,$00,$02
  DEFB $00,$02,$01,$02
  DEFB $00,$00,$00,$00
  DEFB $00,$02,$02,$01
  DEFB $02,$02,$00,$00
