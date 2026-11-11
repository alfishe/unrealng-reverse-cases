; --------------------------------------------------------------------------------------------------------------------
; world.asm: The world: the mission map (vertices, segments), its visibility, the terrain drawing, the camera
;
; The map of a mission lives in its block at bank 0 $DBC5: 64 vertices (X at $DC00+i, Y at $DC40+i, signed bytes, 1024
; world units each) and ($DBDC) segments of 6 bytes at $DC80 (vertex a, vertex b, orientation, two sizes, style).
; SegmentVisibility $AD45 keeps the segments with an endpoint within 8 coarse units of the player; DrawSegments $AEE1
; draws them as quads; GroundDots $BAAC draws the ground grid.
; --------------------------------------------------------------------------------------------------------------------

  ORG $AD45

; Mark the segments near the player visible, 0 / $FF per segment at $8305
;
; Sets the coarse player position `$BC12` (X) and `$BC1D` (Y) = the camera
; words `$67A8` / `$67AB` >> 2, then for each of the ($DBDC) segments at
; `$DC80` tests both endpoints (TestVertexNear `$AE5C` / `$AE78`): visible if
; one lies within 8 coarse units on both axes. The flag goes to `$8305`+n. From
; the segment ($DBDE) on (the switchable ones) the flag is ANDed with the
; switch flags `$7BFD`, so a gate or bridge destroyed or opened by the mission
; script disappears.
;
; Witness: L1 9837 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
SegmentVisibility:
  LD H,$DC
  LD DE,WorldWork
  EXX
  LD HL,MissionHeader+$00BB
  LD A,(MissionHeader+$0019)
  LD (l_ADEA+$0008),A
  LD BC,(WorldVars+$0008)
  SRA B
  RR C
  SRA B
  RR C
  LD A,C
  LD (l_BBFB+$0022),A
  LD BC,(WorldVars+$0005)
  SRA B
  RR C
  SRA B
  RR C
  LD A,C
  LD (l_BBFB+$0017),A
  LD A,(MissionHeader+$0017)
  LD (l_AE0F+$000B),A
l_AD7A:
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD A,(HL)
  AND A
  JP M,l_ADA1
  JR NZ,l_ADBE
  LD A,C
  CALL TestVertexNear
  JP C,l_ADE4
  LD A,C
  CALL TestVertexNearB
  JP NC,l_ADE8
  LD E,A
  LD A,B
  CALL TestVertexNearB
  JP NC,l_ADE8
  CP E
  JR Z,l_ADE4
  JP l_ADE8
l_ADA1:
  LD A,C
  CALL TestVertexNearB
  JP C,l_ADE4
  LD A,C
  CALL TestVertexNear
  JP NC,l_ADE8
  LD E,A
  LD A,B
  CALL TestVertexNear
  JP NC,l_ADE8
  CP E
  JP Z,l_ADE4
  JP l_ADE8
l_ADBE:
  LD A,B
  CALL TestVertexNear
  LD E,A
  LD A,C
  JP NC,l_ADD2
  CALL TestVertexNear
  JP NC,l_ADD1
  CP E
  JP Z,l_ADE4
l_ADD1:
  LD A,C
l_ADD2:
  CALL TestVertexNearB
  JP NC,l_ADE8
  LD E,A
  LD A,B
  CALL TestVertexNearB
  JP NC,l_ADE8
  CP E
  JP NZ,l_ADE8
l_ADE4:
  XOR A
  JP l_ADEA
l_ADE8:
  LD A,$FF
l_ADEA:
  EXX
  LD (l_ADEA+$000D),A
  LD A,(SegmentWalkCount+$0001)
  CP $00
  JP NC,l_ADFA
  LD A,$00
  JR l_AE0F
l_ADFA:
  PUSH HL
  LD HL,FailReason+$0004
  LD B,$00
  LD C,A
  ADD HL,BC
  LD A,(MissionHeader+$0019)
  LD C,A
  AND A
  SBC HL,BC
  LD C,(HL)
  LD A,(l_ADEA+$000D)
  AND C
  POP HL
l_AE0F:
  LD (DE),A
  INC DE
  EXX
  LD BC,$0004
  ADD HL,BC
  LD A,(SegmentWalkCount+$0001)
  CP $00
  JP Z,ResetSegmentWalk
  INC A
  LD (SegmentWalkCount+$0001),A
  LD A,(SegmentWalkCount)
  AND A
  JP Z,l_AE33
  DEC A
  LD (SegmentWalkCount),A
  LD (SegmentVisibility+$0007),HL
  JP l_AD7A
l_AE33:
  LD A,(MissionHeader+$0017)
  LD (SegmentWalkCount),A
  LD (SegmentVisibility+$0007),HL
  EXX
  LD (SegmentVisibility+$0003),DE
  RET

; Reset the segment walk: $DC80, the count ($DBDC), the flags $8305
;
; Stores `$DC80` in the pointer `$AD4C`, the segment count in `$AE5A`, `$8305`
; in `$AD48` and clears `$AE5B`. Called before SegmentVisibility.
;
; Witness: L1 9868 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
ResetSegmentWalk:
  LD HL,MissionHeader+$00BB
  LD (SegmentVisibility+$0007),HL
  LD A,(MissionHeader+$0017)
  LD (SegmentWalkCount),A
  LD DE,WorldWork
  LD (SegmentVisibility+$0003),DE
  XOR A
  LD (SegmentWalkCount+$0001),A
  RET

; The segments left in the walk and the walk index
;
; Written by ResetSegmentWalk `$AE42`.
SegmentWalkCount:
  DEFB $03,$00

; Test vertex A against the coarse player position: within 8 units
;
; EXX, then reads vertex X `$DC00`+A against `$BC12`; falls into
; TestVertexNearX `$AE61`. Carry out: the vertex is near.
;
; Witness: L1 92716 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
TestVertexNear:
  EXX
  LD L,A
  LD A,(l_BBFB+$0017)

; Compare one vertex coordinate with the player's, |d| < 8
;
; Input L = the vertex table offset, A = the player's coarse coordinate. Output
; carry set when |vertex - player| < 8. Used for both axes (TestVertexNearY
; `$AE79` adds `$40` to reach the Y table).
;
; Witness: L1 170288 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
TestVertexNearX:
  LD B,A
  LD A,(HL)
  AND A
  SBC A,B
  JP PO,l_AE6A
  CCF
  RRA
l_AE6A:
  PUSH AF
  AND $80
  LD C,A
  POP AF
  CALL ApiVector08
  CP $08
  LD A,C
  CCF
  EXX
  RET

; Test the segment's second vertex (EXX, then the Y test)
;
; EXX and falls into TestVertexNearY `$AE79`.
;
; Witness: L1 75268 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
TestVertexNearB:
  EXX

; Test a vertex's Y ($DC40+i) against $BC1D
;
; L = vertex + `$40`, A = (`$BC1D`), then JP TestVertexNearX `$AE61`.
;
; Witness: L1 77572 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
TestVertexNearY:
  ADD A,$40
  LD L,A
  LD A,(l_BBFB+$0022)
  JP TestVertexNearX

; 30 bytes of scratch for the segment draw
;
; Zero in every image; the segment drawing keeps its working values here (the
; word at `$AE9E` is read by DrawSegmentTail `$B18A`).
SegmentScratch:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00

; Build the clip window and the vertex buffers for the segment draw
;
; From the segment count (+5) sets the loop limit `$AEEA`, the clip window and
; the vertex buffers at `$FD00`-`$FF07` and `$990F`. Called once per frame
; before DrawSegments.
;
; Witness: L1 9794 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
SetupClipWindow:
  LD A,(MissionHeader+$0017)
  LD C,$05
  ADD A,C
  LD (DrawSegmentLoop+$0002),A
  LD A,$08
  LD C,A
  LD A,(l_BBFB+$0017)
  LD B,A
  ADD A,C
  JP PO,l_AEB6
  LD A,$7F
l_AEB6:
  LD (l_B2A3+$0001),A
  LD A,C
  NEG
  ADD A,B
  JP PO,l_AEC2
  LD A,$80
l_AEC2:
  LD (l_B2A6+$0001),A
  LD A,(l_BBFB+$0022)
  LD B,A
  ADD A,C
  JP PO,l_AECF
  LD A,$7F
l_AECF:
  LD (l_B2CC+$0001),A
  LD A,C
  NEG
  ADD A,B
  JP PO,l_AEDB
  LD A,$80
l_AEDB:
  LD (l_B2CF+$0001),A
  LD HL,WorldWork

; Draw every visible segment as a quad
;
; Walks the segments whose flag in `$8305` is set: transforms both vertices
; (TransformVertex `$B242`), clips them by the orientation byte +2 (one axis
; `$AFDE`, the other `$B000`, the diagonals `$B021`, `$B0E4`, `$B16A`), and
; draws the quad by the style byte +5 (DrawSegmentStyle `$B1B6`).
;
; Witness: L1 94909 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
DrawSegments:
  LD A,(HL)
  LD (SegmentScratch+$001C),HL
  AND A
  JR NZ,l_AEEF

; The loop of DrawSegments, entered again by DrawSegmentTail
;
; One pass per segment: reads the next 6-byte record, skips it when its flag is
; 0.
;
; Witness: L1 94909 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
DrawSegmentLoop:
  INC L
  LD A,$00
  CP L
  JR NZ,DrawSegments
  RET
; This entry point is used by the routine at DrawSegments.
l_AEEF:
  LD BC,$FD00
  AND A
  LD A,L
  SBC A,$05
  ADD A,A
  LD C,A
  LD B,$00
  ADD A,A
  LD H,B
  LD L,A
  ADD HL,BC
  LD DE,MissionHeader+$00BB
  ADD HL,DE
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD A,(HL)
  LD (SegmentScratch+$0003),A
  INC HL
  EX AF,AF'
  LD A,(HL)
  LD (StoreVertex+$0001),A
  INC HL
  LD A,(HL)
  LD (l_AF83+$0041),A
  INC HL
  LD A,(HL)
  LD (DrawSegmentStyle+$0004),A
  EX AF,AF'
  AND A
  JP M,l_AF40
  JR Z,l_AF23
  JR l_AF5C
l_AF23:
  LD A,C
  CALL ClipTestX
  JP C,DrawSegmentTail
  EX AF,AF'
  LD A,B
  CALL ClipTestY
  LD D,A
  LD A,C
  CALL ClipTestY
  CP D
  JP Z,DrawSegmentTail
  LD C,D
  LD E,A
  EX AF,AF'
  LD D,A
  LD B,A
  JP TransformSegmentEnds
l_AF40:
  LD A,C
  CALL ClipTestY
  JP C,DrawSegmentTail
  EX AF,AF'
  LD A,C
  CALL ClipTestX
  LD D,A
  LD A,B
  CALL ClipTestX
  CP D
  JP Z,DrawSegmentTail
  LD B,A
  EX AF,AF'
  LD C,A
  LD E,A
  JP TransformSegmentEnds
l_AF5C:
  LD A,C
  EXX
  LD H,$DC
  CALL TestVertexNearY
  LD E,A
  LD A,B
  JP NC,l_AF73
  CALL TestVertexNearB
  JP NC,l_AF72
  CP E
  JP Z,DrawSegmentTail
l_AF72:
  LD A,B
l_AF73:
  CALL TestVertexNear
  LD E,A
  LD A,C
  JR NC,l_AF83
  CALL TestVertexNear
  JR NC,l_AF83
  CP E
  JP Z,DrawSegmentTail
l_AF83:
  PUSH BC
  CALL ClipSegmentAxisY
  POP BC
  JR C,l_AFD6
  LD HL,(SegmentScratch+$0010)
  LD (SegmentScratch+$0016),HL
  LD HL,(SegmentScratch+$0013)
  LD (SegmentScratch+$0019),HL
  LD C,B
  CALL ClipSegmentAxisY
  JR C,l_AFD6
  LD DE,MissionHeader+$213B
  LD (StoreVertex+$000D),DE
  LD DE,MissionHeader+$2141
  LD (StoreVertex+$0013),DE
  LD HL,(SegmentScratch+$0016)
  EXX
  LD HL,(SegmentScratch+$0019)
  EXX
  CALL ClipSegmentAxisX
  LD DE,MissionHeader+$213D
  LD (StoreVertex+$000D),DE
  LD DE,MissionHeader+$213F
  LD (StoreVertex+$0013),DE
  LD A,$00
  LD (StoreVertex+$0001),A
  LD HL,(SegmentScratch+$0010)
  EXX
  LD HL,(SegmentScratch+$0013)
  EXX
  CALL ClipSegmentAxisX
  JP DrawSegmentStyle
l_AFD6:
  LD HL,(SegmentScratch+$001C)
  XOR A
  LD (HL),A
  JP DrawSegmentLoop

; Clip an axis-aligned segment (orientation 0)
;
; The segment runs along one axis; its width is +3 (`$B2E5`), its height +4
; (`$AFC4`). Seen only on the maps of missions 1 and 2 (missions, m2erbe).
;
; Witness: L1 4566 (m2erbe, m4complete, missions).
ClipSegmentAxisX:
  LD DE,(WorldVars+$0004)
  AND A
  SBC HL,DE
  LD (l_9A85+$0009),HL
  EXX
  LD DE,(WorldVars+$0007)
  AND A
  SBC HL,DE
  LD (l_9A5E+$000E),HL
  CALL RotateToView
  LD (l_9A5E+$000E),HL
  EXX
  LD (l_9A85+$0009),HL
  JP StoreVertex

; Clip a segment along the other axis (orientation bit 7)
;
; As ClipSegmentAxisX `$AFDE` for the other axis.
;
; Witness: L1 4608 (m2erbe, m4complete, missions).
ClipSegmentAxisY:
  LD A,C
  CALL VertexByteToWorld
  LD (SegmentScratch+$0004),HL
  LD (SegmentScratch+$0006),A
  EX AF,AF'
  LD A,C
  EXX
  ADD A,$40
  CALL VertexByteToWorld
  LD (SegmentScratch+$0007),HL
  LD (SegmentScratch+$0009),A
  EX AF,AF'
  EXX
  CALL ClipSegmentDiagonal
  AND A
  RET Z
  SCF
  RET

; Clip a diagonal segment
;
; Orientation other than 0 / `$80`: the two vertices give the slope; calls
; ClipDiagonalSide `$B0E4` and `$B16A`.
;
; Witness: L1 4608 (m2erbe, m4complete, missions).
ClipSegmentDiagonal:
  LD DE,(WorldVars+$0004)
  LD BC,(WorldVars+$0006)
  CALL ClipDiagonalEnd
  LD (SegmentScratch+$000A),HL
  LD (SegmentScratch+$000C),A
  JP P,l_B038
  CALL Negate24
l_B038:
  EXX
  EX AF,AF'
  LD DE,(WorldVars+$0007)
  LD BC,(WorldVars+$0009)
  CALL ClipDiagonalEnd
  LD (SegmentScratch+$000D),HL
  LD (SegmentScratch+$000F),A
  JP P,l_B051
  CALL Negate24
l_B051:
  PUSH HL
  LD C,A
  PUSH BC
  EXX
  EX AF,AF'
  POP BC
  POP DE
  AND A
  SBC HL,DE
  SBC A,C
  JP P,ClipDiagonalSide
  LD DE,(SegmentScratch+$000D)
  LD BC,(SegmentScratch+$000F)
  LD A,(SegmentScratch+$0003)
  CP $01
  JR Z,l_B0A9
  LD HL,(SegmentScratch+$0007)
  LD A,(SegmentScratch+$0009)
  AND A
  SBC HL,DE
  SBC A,C
  LD (SegmentScratch+$0013),HL
  LD (SegmentScratch+$0015),A
  PUSH DE
  PUSH BC
  LD BC,(WorldVars+$0009)
  LD DE,(WorldVars+$0007)
  CALL ClipDiagonalEnd
  POP BC
  POP DE
  RET NZ
  LD HL,(SegmentScratch+$0004)
  LD A,(SegmentScratch+$0006)
  AND A
  ADC HL,DE
  ADC A,C
  LD (SegmentScratch+$0010),HL
  LD (SegmentScratch+$0012),A
  LD BC,(WorldVars+$0006)
  LD DE,(WorldVars+$0004)
  JP ClipDiagonalEnd
l_B0A9:
  LD HL,(SegmentScratch+$0004)
  LD A,(SegmentScratch+$0006)
  AND A
  SBC HL,DE
  SBC A,C
  LD (SegmentScratch+$0010),HL
  LD (SegmentScratch+$0012),A
  PUSH DE
  PUSH BC
  LD BC,(WorldVars+$0006)
  LD DE,(WorldVars+$0004)
  CALL ClipDiagonalEnd
  POP BC
  POP DE
  RET NZ
  LD HL,(SegmentScratch+$0007)
  LD A,(SegmentScratch+$0009)
  AND A
  SBC HL,DE
  SBC A,C
  LD (SegmentScratch+$0013),HL
  LD (SegmentScratch+$0015),A
  LD BC,(WorldVars+$0009)
  LD DE,(WorldVars+$0007)
  JP ClipDiagonalEnd

; Clip one side of a diagonal segment
;
; Part of ClipSegmentDiagonal `$B021`.
;
; Witness: L1 3647 (m2erbe, m4complete, missions).
ClipDiagonalSide:
  LD DE,(SegmentScratch+$000A)
  LD BC,(SegmentScratch+$000C)
  LD A,(SegmentScratch+$0003)
  CP $01
  JR Z,l_B12E
  LD HL,(SegmentScratch+$0007)
  LD A,(SegmentScratch+$0009)
  AND A
  ADC HL,DE
  ADC A,C
  LD (SegmentScratch+$0013),HL
  LD (SegmentScratch+$0015),A
  PUSH DE
  PUSH BC
  LD BC,(WorldVars+$0009)
  LD DE,(WorldVars+$0007)
  CALL ClipDiagonalEnd
  POP BC
  POP DE
  RET NZ
  LD HL,(SegmentScratch+$0004)
  LD A,(SegmentScratch+$0006)
  AND A
  SBC HL,DE
  SBC A,C
  LD (SegmentScratch+$0010),HL
  LD (SegmentScratch+$0012),A
  LD BC,(WorldVars+$0006)
  LD DE,(WorldVars+$0004)
  JP ClipDiagonalEnd
l_B12E:
  LD HL,(SegmentScratch+$0004)
  LD A,(SegmentScratch+$0006)
  AND A
  SBC HL,DE
  SBC A,C
  LD (SegmentScratch+$0010),HL
  LD (SegmentScratch+$0012),A
  PUSH DE
  PUSH BC
  LD BC,(WorldVars+$0006)
  LD DE,(WorldVars+$0004)
  CALL ClipDiagonalEnd
  POP BC
  POP DE
  RET NZ
  LD HL,(SegmentScratch+$0007)
  LD A,(SegmentScratch+$0009)
  AND A
  SBC HL,DE
  SBC A,C
  LD (SegmentScratch+$0013),HL
  LD (SegmentScratch+$0015),A
  LD BC,(WorldVars+$0009)
  LD DE,(WorldVars+$0007)
  CALL ClipDiagonalEnd
  RET

; Clip the far end of a diagonal segment
;
; Part of ClipSegmentDiagonal `$B021`.
;
; Witness: L1 18411 (m2erbe, m4complete, missions).
ClipDiagonalEnd:
  AND A
  SBC HL,DE
  SBC A,C
  LD B,$20
  LD C,$00
  JP P,l_B182
  AND A
  ADC HL,BC
  ADC A,C
  JP M,l_B181
l_B17C:
  LD A,$00
  LD H,A
  LD L,A
  AND A
l_B181:
  RET
l_B182:
  AND A
  SBC HL,BC
  SBC A,C
  JP M,l_B17C
  RET

; Continue the segment loop from the saved pointer $AE9E
;
; LD HL,(`$AE9E`) then JP DrawSegmentLoop `$AEE8`.
;
; Witness: L1 19364 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
DrawSegmentTail:
  LD HL,(SegmentScratch+$001C)
  JP DrawSegmentLoop

; Transform both corners of a segment into the vertex buffer $FD00
;
; Points the store `$B2F1` / `$B2F7` at `$FD00` / `$FD06`, transforms the first
; corner (TransformVertex `$B242`), copies the height `$AFC4` to `$B2E5`, then
; the second corner into `$FD02` / `$FD04`.
;
; Witness: L1 17081 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
TransformSegmentEnds:
  PUSH BC
  LD HL,MissionHeader+$213B
  LD (StoreVertex+$000D),HL
  LD HL,MissionHeader+$2141
  LD (StoreVertex+$0013),HL
  CALL TransformVertex
  LD A,(l_AF83+$0041)
  LD (StoreVertex+$0001),A
  LD HL,MissionHeader+$213D
  LD (StoreVertex+$000D),HL
  LD HL,MissionHeader+$213F
  LD (StoreVertex+$0013),HL
  POP DE
  CALL TransformVertex

; Draw a segment by its style byte (+5)
;
; ResetViewOrigin `$B3B6`, then the style (the operand at `$B1BA`): 0 draws
; with IX = `$FF8C`, negative with `$FF80`, 1 with `$FF98`, 2 through `$B22C`,
; 4 / 5 / 6 set the `$FE00` constants first. The same byte is the terrain type
; TerrainCollision `$CC3C` returns in `$CE69`.
;
; Witness: L1 19364 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
DrawSegmentStyle:
  CALL ResetViewOrigin
  LD A,$00
  AND A
  JR Z,l_B1F2
  JP M,l_B1FC
  CP $02
  JR Z,l_B22C
  CP $01
  JR Z,l_B1E8
  LD DE,$00B0
  CP $05
  JR Z,l_B210
  CP $04
  JR Z,l_B21E
  CP $06
  JR Z,l_B206
  LD (MissionHeader+$2241),DE
  LD (MissionHeader+$223B),DE
l_B1E0:
  LD (MissionHeader+$223D),DE
  LD (MissionHeader+$223F),DE
l_B1E8:
  LD IX,data_FEBB+$00DD
  CALL RunScript
  JP DrawSegmentTail
l_B1F2:
  LD IX,data_FEBB+$00D1
  CALL RunScript
  JP DrawSegmentTail
l_B1FC:
  LD IX,data_FEBB+$00C5
  CALL RunScript
  JP DrawSegmentTail
l_B206:
  LD IX,data_FEBB+$00E7
  CALL RunScript
  JP DrawSegmentTail
l_B210:
  LD BC,$0070
  LD (MissionHeader+$2241),BC
  LD (MissionHeader+$223B),BC
  JP l_B1E0
l_B21E:
  LD (MissionHeader+$2241),DE
  LD (MissionHeader+$223B),DE
  LD DE,$0070
  JP l_B1E0
l_B22C:
  LD DE,(WorldVars+$000A)
  LD (MissionHeader+$223B),DE
  LD (MissionHeader+$223D),DE
  LD IX,data_FEBB+$00C5
  CALL RunScript
  JP DrawSegmentTail

; Transform one map vertex to view space
;
; Input: the vertex index. Vertex minus camera (VertexRelative `$B265`), the
; rotation (`$B2FF`, `$B38E`), the stores through `$B2F1` / `$B2F7`.
;
; Witness: L1 34162 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
TransformVertex:
  LD H,D
  LD BC,(WorldVars+$0004)
  CALL VertexRelative
  LD (l_9A85+$0009),HL
  LD H,E
  LD BC,(WorldVars+$0007)
  CALL VertexRelative
  LD (l_9A5E+$000E),HL
  CALL RotateToView
  LD (l_9A5E+$000E),HL
  EXX
  LD (l_9A85+$0009),HL
  JP StoreVertex

; Vertex position minus the camera, 24-bit
;
; Byte * 1024 (ByteToWorld `$B282`) minus the camera X / Y `$67A8` / `$67AB`.
;
; Witness: L1 68324 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
VertexRelative:
  SLA H
  SLA H
  LD L,$00
  AND A
  SBC HL,BC
  RET

; Negate a 24-bit value
;
; Seen only in missions (167 runs).
;
; Witness: L1 960 (m4complete, missions).
Negate24:
  LD (Negate24+$000D),A
  EX DE,HL
  LD A,$00
  LD HL,$0000
  AND A
  SBC HL,DE
  SBC A,$00
  RET

; A vertex byte to a 24-bit world coordinate (signed byte * 1024)
;
; Reads the vertex byte and falls into ByteToWorld `$B282`.
;
; Witness: L1 9216 (m2erbe, m4complete, missions).
VertexByteToWorld:
  LD H,$DC
  LD L,A
  LD A,(HL)

; Signed byte to 24-bit: A * 1024 (vector $67E2)
;
; Input A, output the 24-bit value in A:HL. The mission code calls it through
; `$67E2` (the object list's X / Y words use the same scale).
;
; Witness: L1 145759 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
ByteToWorld:
  AND A
  LD H,A
  LD A,$00
  LD L,A
  JP P,l_B28B
  DEC A
l_B28B:
  SLA H
  RL A
  SLA H
  RL A
  RET

; Clip test of a view-space point against the window on X
;
; Carry out: outside.
;
; Witness: L1 27209 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
ClipTestX:
  LD H,$DC
  LD L,A
  LD A,(l_BBFB+$0017)
  LD E,A
  LD A,(HL)
  AND A
  SBC A,E
  JP PO,l_B2AA
  JR NC,l_B2A6
l_B2A3:
  LD A,$00
  RET
l_B2A6:
  LD A,$00
  SCF
  RET
l_B2AA:
  JP P,l_B2B4
  CP $F8
  JR C,l_B2A6
  LD A,(HL)
  AND A
  RET
l_B2B4:
  CP $08
  JR NC,l_B2A3
  LD A,(HL)
  AND A
  RET

; Clip test of a view-space point on Y (depth)
;
; Carry out: outside.
;
; Witness: L1 24034 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
ClipTestY:
  LD H,$DC
  ADD A,$40
  LD L,A
  LD A,(l_BBFB+$0022)
  LD E,A
  LD A,(HL)
  AND A
  SBC A,E
  JP PO,l_B2D3
  JR NC,l_B2CF
l_B2CC:
  LD A,$00
  RET
l_B2CF:
  LD A,$00
  SCF
  RET
l_B2D3:
  JP P,l_B2DD
  CP $F8
  JR C,l_B2CF
  LD A,(HL)
  AND A
  RET
l_B2DD:
  CP $08
  JR NC,l_B2CC
  LD A,(HL)
  AND A
  RET

; Store a transformed vertex through $B2F1 / $B2F7
;
; The height operand `$B2E5` (from the segment's +3) is the vertex's height.
;
; Witness: L1 38728 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
StoreVertex:
  LD A,$01
  LD BC,(WorldVars+$0003)
  AND A
  SBC A,C
  LD (SegmentScratch+$0002),A
  EX AF,AF'
  LD DE,$0000
  CALL RotateVertex
  LD DE,$0000
  LD A,(SegmentScratch+$0002)
  ADD A,$80
  EX AF,AF'

; Rotate a camera-relative vertex by the view angle
;
; Through the camera sin / cos `$9A6C` / `$9A8E`.
;
; Witness: L1 77456 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
RotateVertex:
  LD A,(DrawSegmentStyle+$0004)
  AND A
  JP M,l_B344
  JP Z,RotateAndStore
  CP $02
  JP Z,l_B365
  CP $06
  JP Z,l_B344
  EX AF,AF'
  CALL ApiVector14
  LD BC,(l_9A85+$0009)
  CALL SignExtendA
  SRA H
  RR A
  SRA H
  RR A
  CALL RotateMulAdd
  LD (HL),$00
  INC L
  LD (HL),$00
  DEC L
  INC H
  LD BC,(l_9A5E+$000E)
  EX DE,HL
  EX AF,AF'
  CALL SignExtendA
  SRA H
  RR A
  SRA H
  RR A
  JP RotateMulAdd
l_B344:
  EX AF,AF'
  CALL ApiVector14
  LD BC,(l_9A85+$0009)
  CALL SignExtendA
  CALL RotateMulAdd
  LD (HL),$00
  INC L
  LD (HL),$00
  DEC L
  INC H
  LD BC,(l_9A5E+$000E)
  EX DE,HL
  EX AF,AF'
  CALL SignExtendA
  JP RotateMulAdd
l_B365:
  EX AF,AF'
  CALL ApiVector14
  LD BC,(l_9A85+$0009)
  CALL SignExtendA
  CALL RotateMulAdd
  LD (HL),$00
  INC L
  LD (HL),$00
  DEC L
  INC H
  LD BC,(l_9A5E+$000E)
  EX DE,HL
  EX AF,AF'
  CALL SignExtendA
  JP RotateMulAdd

; Sign-extend A into HL (H = 0 or $FF)
;
; Seen only in missions.
;
; Witness: L1 40720 (m4complete, missions).
SignExtendA:
  LD H,$00
  AND A
  JP P,l_B38D
  DEC H
l_B38D:
  RET

; Rotate by the sin / cos of A and store the pair
;
; EX AF,AF', sin / cos through `$67E8`, multiply by `$9A8E` (RotateMul
; `$B3A6`), clears the target.
;
; Witness: L1 57096 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
RotateAndStore:
  EX AF,AF'
  CALL ApiVector14
  LD BC,(l_9A85+$0009)
  CALL RotateMul
  LD (HL),$00
  INC L
  LD (HL),$00
  DEC L
  INC H
  LD BC,(l_9A5E+$000E)
  EX DE,HL
  EX AF,AF'

; One product of the rotation (BC * the sin or cos)
;
; Part of RotateAndStore.
;
; Witness: L1 114192 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
RotateMul:
  LD H,$00
  AND A
  JP P,RotateMulAdd
  DEC H

; The second product, added to the first
;
; Part of RotateAndStore.
;
; Witness: L1 154912 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
RotateMulAdd:
  LD L,A
  ADD HL,BC
  EX DE,HL
  LD (HL),E
  INC L
  LD (HL),D
  DEC L
  INC H
  RET

; Reset the view origin before a segment is drawn
;
; Called by DrawSegmentStyle `$B1B6` once per drawn segment (6628 runs, as many
; as it).
;
; Witness: L1 19364 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
ResetViewOrigin:
  LD HL,$0000
  LD (l_9A85+$0009),HL
  LD (l_9A5E+$000E),HL
  LD HL,(WorldVars+$000A)
  CALL ApiVector07
  LD (l_9A9E+$0015),HL
  RET

  ORG $B9F6

; Set the camera from the viewed object (the player, a missile, the Dragonfly)
;
; Copies +$21..+$28 (table select, heading, X, Y) of the record at (`$B9F4`) to
; `$67A5`-`$67AC`, the height +5/+6 (or the IR height `$B8FF` when `$BA13` is
; set) to `$67AD`. The rear view (`$BA27` set) adds `$80` to the heading. Then
; CameraSinCos `$BA32`.
;
; Witness: L1 9837 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
SetCamera:
  LD HL,(BearingTable+$0016)
  PUSH HL
  LD BC,$0021
  ADD HL,BC
  LD DE,WorldVars+$0002
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  POP HL
  LD A,$00
  AND A
  JR Z,l_BA1C
  LD HL,IrViewHeight+$0003
  JR l_BA1F
l_BA1C:
  LD C,$05
  ADD HL,BC
l_BA1F:
  LDI
  LDI
  LD HL,(WorldVars+$0002)
  LD A,$00
  AND A
  JR Z,CameraSinCos
  LD BC,Bootstrap
  ADD HL,BC
  LD (WorldVars+$0002),HL

; The camera heading's sine and cosine
;
; Reads the camera heading `$67A6`, sin / cos through `$67E8` (`$A899`), stores
; the pair in the operands `$BBBD` / `$BBC8` of RotateToView.
;
; Witness: L1 19674 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
CameraSinCos:
  CALL ApiVector07
  CALL SinCosHalf
  LD (RotateToView+$000C),A
  LD A,E
  LD (RotateToView+$0001),A
  RET

; CameraSinCos for the second pass
;
; CALL CameraSinCos for the second view pass.
;
; Witness: L1 9837 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
CameraSinCosAgain:
  LD HL,(WorldVars+$0002)
  JR CameraSinCos

; Rear view off
;
; Clears `$BA27`, falls into ToggleRearView.
;
; Witness: L1 5 (play).
RearViewOff:
  LD A,(l_BA1F+$0008)
  XOR $FF

; Rear view on or off: the flag $BA27, the text REAR:VIEW / :::
;
; Prints `$BA86` ("REAR:VIEW") or `$BA9F` (blank) with the attribute at
; `$5AD2`.
;
; Witness: L1 36 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
ToggleRearView:
  LD HL,$5AD2
  JR Z,l_BA62
  EX AF,AF'
  LD A,(ToggleBinoculars+$0001)
  AND A
  RET NZ
  EX AF,AF'
  LD (l_BA1F+$0008),A
  LD A,$42
  LD (HL),A
  LD HL,RearViewText
  JP PrintString
l_BA62:
  LD (l_BA1F+$0008),A
  LD A,$44
  LD (HL),A
  LD HL,ViewTextBlank
  JP PrintString

; The view labels: IR:SIGHT, REAR:VIEW, BINOC:X2 and their blanks
;
; Strings for PrintString `$6FB3` (`$07` position code, `$FF` end): `$BA6E`
; "IR:SIGHT", `$BA7A` blank, `$BA86` "REAR:VIEW", `$BA93` "BINOC:X2" (the digit
; at `$BA9D`), `$BA9F` blank.
ViewTexts:
  DEFB $07,$84,$11,$49,$52,$3A,$53,$49,$47,$48,$54,$FF
IrSightBlank:
  DEFB $07,$84,$11,$3A,$3A,$3A,$3A,$3A,$3A,$3A,$3A,$FF
RearViewText:
  DEFB $07,$96,$11,$52,$45,$41,$52,$3A,$56,$49,$45,$57,$FF ; "REAR:VIEW"
BinocularText:
  DEFB $07,$96,$11,$42,$49,$4E,$4F,$43,$3A,$58,$32,$FF ; "BINOC:X2", the digit
                                                       ; at $BA9D set by
                                                       ; ShowBinocularZoom
ViewTextBlank:
  DEFB $07,$96,$11,$3A,$3A,$3A,$3A,$3A,$3A,$3A,$3A,$3A,$FF

; Draw the ground-plane dot grid
;
; The grid moves with the camera: GridVectors `$BB54`, then PlotGroundDot
; `$BB75` for each dot, GridStep `$BBA6` between rows.
;
; Witness: L1 9794 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
GroundDots:
  LD A,(WorldVars+$0004)
  CPL
  LD L,A
  LD A,(WorldVars+$0005)
  CPL
  AND $01
  LD H,A
  LD (l_9A85+$0009),HL
  LD A,(WorldVars+$0007)
  CPL
  LD L,A
  LD A,(WorldVars+$0008)
  CPL
  AND $01
  LD H,A
  LD (l_9A5E+$000E),HL
  CALL RotateToView
  LD (l_BB0A+$0004),HL
  EXX
  LD (l_BB0A+$0001),HL
  LD HL,(WorldVars+$000A)
  CALL NegHL
  LD (PlotGroundDot+$0016),HL
  LD L,$C0
  CALL GridVectors
  CALL GridStep
  LD L,$00
  CALL GridVectors
  CALL GridStep
  LD L,$80
  CALL GridVectors
  LD (l_BB23+$0006),HL
  LD (l_BB23+$0001),BC
  LD L,$40
  CALL GridVectors
  LD (l_BB3E+$000E),HL
  LD (l_BB3E+$0004),BC
  LD A,$08
  LD (l_BB23+$0013),A
l_BB0A:
  LD HL,$0000
  LD DE,$0000
  LD A,$08
  LD (l_BB23+$000B),A
l_BB15:
  LD A,D
  AND A
  JP M,l_BB23
  PUSH HL
  PUSH DE
  EXX
  POP DE
  POP HL
  CALL PlotGroundDot
  EXX
l_BB23:
  LD BC,$0000
  ADD HL,BC
  EX DE,HL
  LD BC,$0000
  ADD HL,BC
  EX DE,HL
  LD A,$00
  DEC A
  LD (l_BB23+$000B),A
  JR NZ,l_BB15
  LD A,$00
  DEC A
  LD (l_BB23+$0013),A
  JR NZ,l_BB3E
  RET
l_BB3E:
  LD HL,(l_BB0A+$0001)
  LD DE,$0000
  ADD HL,DE
  LD (l_BB0A+$0001),HL
  LD HL,(l_BB0A+$0004)
  LD DE,$0000
  ADD HL,DE
  LD (l_BB0A+$0004),HL
  JR l_BB0A

; The grid's step vectors for the camera heading
;
; The camera's sin / cos scaled to the grid spacing: the steps along a row and
; between rows.
;
; Witness: L1 39176 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
GridVectors:
  LD A,(WorldVars+$0003)
  NEG
  ADD A,L
  CALL ApiVector14
  LD H,$00
  AND A
  JP P,l_BB64
  DEC H
l_BB64:
  LD L,A
  ADD HL,HL
  ADD HL,HL
  LD B,H
  LD C,L
  EX AF,AF'
  LD H,$00
  AND A
  JP P,l_BB71
  DEC H
l_BB71:
  LD L,A
  ADD HL,HL
  ADD HL,HL
  RET

; Project one ground dot and plot it
;
; Rotates the dot to view space, divides by depth, plots through `$AA27` when
; on screen (117 517 runs).
;
; Witness: L1 324616 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
PlotGroundDot:
  CALL Divide
  LD BC,(l_9A9E+$0005)
  ADD HL,BC
  LD A,H
  AND A
  RET NZ
  LD A,L
  CP $FF
  RET NC
  LD (PlotGroundDot+$002D),A
  LD HL,$0000
  LD BC,$0000
  ADD HL,BC
  CALL DivideByLog
  CALL NegHL
  LD BC,(l_9A9E+$001D)
  ADD HL,BC
  LD A,H
  AND A
  RET NZ
  LD A,L
  CP $5F
  RET NC
  LD H,A
  LD L,$00
  JP PlotBackBuffer

; Step to the next grid row
;
; Adds the row vector to the grid origin.
;
; Witness: L1 19588 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
GridStep:
  EX DE,HL
  LD HL,(l_BB0A+$0004)
  ADD HL,DE
  ADD HL,DE
  ADD HL,DE
  ADD HL,DE
  LD (l_BB0A+$0004),HL
  LD HL,(l_BB0A+$0001)
  ADD HL,BC
  ADD HL,BC
  ADD HL,BC
  ADD HL,BC
  LD (l_BB0A+$0001),HL
  RET

; Rotate dx, dy by the camera (sin `$BBBD`, cos `$BBC8`)
;
; Outputs the depth offset in `$9A6C` and the x offset in `$9A8E` (OpProject
; adds `$9A6C` to z and compares with 96).
;
; Witness: L1 154474 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
RotateToView:
  LD A,$00
  LD HL,(l_9A5E+$000E)
  CALL ApiVector09
  LD (RotateToView+$001E),HL
  LD A,$00
  LD HL,(l_9A5E+$000E)
  CALL ApiVector09
  PUSH HL
  LD A,(RotateToView+$000C)
  LD HL,(l_9A85+$0009)
  CALL ApiVector09
  LD DE,$0000
  ADD HL,DE
  PUSH HL
  EXX
  POP HL
  EXX
  LD HL,(l_9A85+$0009)
  CALL NegHL
  LD A,(RotateToView+$0001)
  CALL ApiVector09
  POP DE
  ADD HL,DE
  RET

  ORG $CC3C

; Does the object touch a visible segment; the style to $CE69 (vector $67F1)
;
; Input IX = the object. Scans the segments flagged in `$8305` (TerrainScan
; `$CC4D`), tests the object's position against each one's box or diagonal
; (TerrainDiagonal `$CDB6`). Output carry set on a touch, the style +5 of the
; segment in `$CE69`. The mission code uses it through `$67F1` for the enemies.
;
; Witness: L1 20647 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
TerrainCollision:
  LD A,(IX+$07)
  AND A
  RET Z
  LD HL,WorldWork
  LD A,(MissionHeader+$0017)
  LD D,$00
  LD E,A
  ADD HL,DE
  LD B,A
  INC B

; The scan over the visible segments
;
; Sets the segment pointer and the count.
;
; Witness: L1 208483 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
TerrainScan:
  LD A,(HL)
  AND A
  JR NZ,l_CC56

; The scan loop
;
; One segment per pass (62 693 runs).
;
; Witness: L1 207509 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
TerrainScanLoop:
  DEC HL
  DJNZ TerrainScan
  AND A
  RET
; This entry point is used by the routine at TerrainScan.
l_CC56:
  LD A,B
  DEC A
  EXX
  ADD A,A
  LD C,A
  LD B,$00
  ADD A,A
  LD H,B
  LD L,A
  ADD HL,BC
  LD BC,$DC80
  ADD HL,BC
  LD D,$DC
  LD E,(HL)
  LD A,(DE)
  LD (l_CCD8+$0007),A
  LD A,$40
  ADD A,E
  LD E,A
  LD A,(DE)
  LD (l_CC98+$001A),A
  INC HL
  LD E,(HL)
  LD A,(DE)
  LD (l_CCEB+$0014),A
  LD A,$40
  ADD A,E
  LD E,A
  LD A,(DE)
  LD (l_CC98+$0021),A
  INC HL
  LD A,(HL)
  INC HL
  INC HL
  INC HL
  LD C,(HL)
  EX AF,AF'
  LD A,C
  AND A
  JP M,l_CC98
  CP $03
  JP Z,TerrainNext
  CP $02
  JP Z,TerrainNext
l_CC98:
  LD (TerrainType),A
  EX AF,AF'
  LD (DevMissionLoader),A
  AND A
  JP M,l_CCEB
  JP NZ,TerrainDiagonal
  LD HL,$007F
  LD (l_CD30+$0007),HL
  LD A,$00
  LD (l_CD30+$000A),A
  LD A,$00
  CALL ApiVector12
  EX DE,HL
  LD C,A
  LD A,$00
  CALL ApiVector12
  ADD HL,DE
  ADC A,C
  SRA A
  RR H
  RR L
  LD (l_CD5C+$002A),HL
  LD (l_CD5C+$002D),A
  EX DE,HL
  LD B,C
  LD C,A
  LD A,B
  SBC HL,DE
  SBC A,C
  JP P,l_CCD8
  CALL TerrainNegate24
l_CCD8:
  LD (l_CD5C+$0013),HL
  LD (l_CD5C+$0016),A
  LD A,$00
  CALL ApiVector12
  LD (l_CD30+$001E),HL
  LD (l_CD30+$0021),A
  JR l_CD30
l_CCEB:
  LD HL,$007F
  LD (l_CD5C+$0013),HL
  LD A,$00
  LD (l_CD5C+$0016),A
  LD A,(l_CCD8+$0007)
  CALL ApiVector12
  EX DE,HL
  LD C,A
  LD A,$00
  CALL ApiVector12
  ADD HL,DE
  ADC A,C
  SRA A
  RR H
  RR L
  LD (l_CD30+$001E),HL
  LD (l_CD30+$0021),A
  EX DE,HL
  LD B,C
  LD C,A
  LD A,B
  SBC HL,DE
  SBC A,C
  JP P,l_CD1E
  CALL TerrainNegate24
l_CD1E:
  LD (l_CD30+$0007),HL
  LD (l_CD30+$000A),A
  LD A,(l_CC98+$001A)
  CALL ApiVector12
  LD (l_CD5C+$002A),HL
  LD (l_CD5C+$002D),A
l_CD30:
  LD E,(IX+$0B)
  LD D,(IX+$0C)
  LD HL,$0000
  LD A,$00
  ADD HL,DE
  ADC A,$00
  LD (l_CD5C+$0001),HL
  LD (l_CD5C+$0004),A
  LD L,(IX+$23)
  LD H,(IX+$24)
  LD A,(IX+$25)
  LD DE,$0000
  LD C,$00
  AND A
  SBC HL,DE
  SBC A,C
  JP P,l_CD5C
  CALL TerrainNegate24
l_CD5C:
  LD DE,$0000
  LD C,$00
  AND A
  SBC HL,DE
  SBC A,C
  JP P,TerrainNext
  LD E,(IX+$0F)
  LD D,(IX+$10)
  LD HL,$0000
  LD A,$00
  ADD HL,DE
  ADC A,$00
  LD (l_CD94+$0001),HL
  LD (l_CD94+$0004),A
  LD L,(IX+$26)
  LD H,(IX+$27)
  LD A,(IX+$28)
  LD DE,$0000
  LD C,$00
  AND A
  SBC HL,DE
  SBC A,C
  JP P,l_CD94
  CALL TerrainNegate24
l_CD94:
  LD DE,$0000
  LD C,$00
  AND A
  SBC HL,DE
  SBC A,C
  JP P,TerrainNext
  SCF
  RET

; Continue with the next segment
;
; Steps to the next record.
;
; Witness: L1 48694 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
TerrainNext:
  EXX
  JP TerrainScanLoop

; Negate a 24-bit difference
;
; Negates the 24-bit value in A:HL.
;
; Witness: L1 62388 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
TerrainNegate24:
  EX AF,AF'
  LD A,L
  CPL
  LD L,A
  LD A,H
  CPL
  LD H,A
  EX AF,AF'
  CPL
  LD BC,$0001
  ADD HL,BC
  ADC A,$00
  RET

; Distance to a diagonal segment
;
; The perpendicular distance for orientation other than 0 / `$80` (missions,
; m2erbe).
;
; Witness: L1 5964 (m2erbe, m4complete, missions).
TerrainDiagonal:
  LD A,(l_CCD8+$0007)
  LD C,A
  LD A,(l_CCEB+$0014)
  ADD A,C
  SRA A
  LD E,A
  LD A,(IX+$24)
  LD H,(IX+$25)
  SRA H
  RR A
  SRA H
  RR A
  SUB E
  CALL ApiVector08
  LD E,A
  LD A,(l_CCD8+$0007)
  LD C,A
  LD A,(l_CCEB+$0014)
  AND A
  SBC A,C
  CALL ApiVector08
  SRL A
  AND A
  SBC A,E
  JP M,TerrainNext
  LD A,(l_CC98+$001A)
  LD C,A
  LD A,(l_CC98+$0021)
  ADD A,C
  SRA A
  LD E,A
  LD A,(IX+$27)
  LD H,(IX+$28)
  SRA H
  RR A
  SRA H
  RR A
  SUB E
  CALL ApiVector08
  LD E,A
  LD A,(l_CC98+$001A)
  LD C,A
  LD A,(l_CC98+$0021)
  AND A
  SBC A,C
  CALL ApiVector08
  SRL A
  AND A
  SBC A,E
  JP M,TerrainNext
  LD A,(l_CCD8+$0007)
  CALL ApiVector12
  LD E,(IX+$23)
  LD D,(IX+$24)
  LD C,(IX+$25)
  AND A
  SBC HL,DE
  SBC A,C
  JP P,l_CE31
  CALL TerrainNegate24
l_CE31:
  PUSH HL
  LD (l_CE4E+$0001),A
  LD A,(l_CC98+$001A)
  CALL ApiVector12
  LD E,(IX+$26)
  LD D,(IX+$27)
  LD C,(IX+$28)
  AND A
  SBC HL,DE
  SBC A,C
  JP P,l_CE4E
  CALL TerrainNegate24
l_CE4E:
  LD C,$00
  POP DE
  AND A
  SBC HL,DE
  SBC A,C
  JP P,l_CE5B
  CALL TerrainNegate24
l_CE5B:
  LD C,$00
  LD DE,$00FF
  AND A
  SBC HL,DE
  SBC A,C
  JP NC,TerrainNext
  RET

  ORG $CEA4

; Binoculars off (called from $74E0)
;
; `XOR A` / `JR $CEAB`. `$74E0` calls it with bank 0 paged.
;
; Known only from the code: no recording runs it (static walk).
BinocularsOff:
  XOR A
  JR SetBinoculars

; Binoculars on or off
;
; `LD A,n` whose n (`$CEA8`) is the flag, `XOR $FF`, falls into SetNightSight
; (8 runs in play).
;
; Witness: L1 8 (play).
ToggleBinoculars:
  LD A,$00
  XOR $FF

; Apply the binoculars flag: the zoom $9A93, the lamp, the key repeat, the text
;
; On: `$CEA8` = A, the zoom `$9A93` = 1, the lamp attribute `$5ACC` = `$42`,
; key repeat `$9719` = `$20`, prints "BINOC:X2" `$BA93`. Off: `$9A93` = 0,
; `$5ACC` = `$44`, `$9719` = 4, the blank `$BA9F`. The rear view (`$BA27`)
; blocks both.
;
; Witness: L1 39 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
SetBinoculars:
  LD HL,$5ACC
  JR NZ,l_CEC9
  LD (ToggleBinoculars+$0001),A
  LD (HL),$44
  XOR A
  LD (l_9A85+$000E),A
  LD A,$04
  LD (StepFrames),A
  LD A,(l_BA1F+$0008)
  AND A
  RET NZ
  LD HL,ViewTextBlank
  JP PrintString
l_CEC9:
  EX AF,AF'
  LD A,(l_BA1F+$0008)
  AND A
  RET NZ
  EX AF,AF'
  LD (ToggleBinoculars+$0001),A
  LD A,$01
  LD (l_9A85+$000E),A
  LD (HL),$42
  LD A,$20
  LD (StepFrames),A
  LD HL,BinocularText
  JP PrintString

; Step the binocular zoom 1-3 (x2, x4, x8)
;
; When the binoculars are on: `$CED4` + 1, wrapping 4 to 1, to the zoom
; `$9A93`; falls into ShowSightZoom (play: 6 runs).
;
; Witness: L1 6 (play).
CycleBinocularZoom:
  LD A,(ToggleBinoculars+$0001)
  AND A
  RET Z
  LD A,(l_CEC9+$000B)
  INC A
  CP $04
  JR C,l_CEF4
  LD A,$01
l_CEF4:
  LD (l_9A85+$000E),A

; Draw the zoom icon ($D8B4 + 32 * n) and BINOC:X2 / X4 / X8
;
; Stores the zoom in `$CED4`, draws the 32-byte icon `$D8B4` + 32 * n through
; `$6D7F`, puts "0" + 2^n in `$BA9D` and prints `$BA93`. Called from `$6A01`.
;
; Known only from the code: no recording runs it (static walk).
ShowBinocularZoom:
  LD (l_CEC9+$000B),A
  LD HL,EngineTone+$0013
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  LD E,A
  LD D,$00
  ADD HL,DE
  LD D,$02
  LD C,$10
  EXX
  LD C,$04
  LD A,$A0
  CALL CopyGraphic
  LD A,(l_CEC9+$000B)
  LD B,A
  LD A,$01
l_CF18:
  ADD A,A
  DJNZ l_CF18
  ADD A,$30
  LD (BinocularText+$000A),A
  LD HL,BinocularText
  JP PrintString

  ORG $D8D4

; The binocular zoom icons
;
; Starts with the binocular zoom icons that ShowBinocularZoom `$CEF7` draws
; from `$D8B4` + 32 * n, n = 1-3: `$D8D4`, `$D8F4`, `$D914`, 32 bytes each. The
; rest up to `$DA08` is read by no routine of this fragment.
BinocularIcons:
  DEFB $02,$00,$55,$55,$A8,$0A,$51,$C5
  DEFB $A7,$F2,$4A,$B9,$8D,$D8,$5A,$ED
  DEFB $9B,$6C,$5B,$ED,$8D,$D8,$4E,$B9
  DEFB $A7,$F2,$51,$C5,$00,$00,$FF,$FF
  DEFB $02,$00,$55,$55,$A8,$0A,$51,$45
  DEFB $A7,$72,$4E,$39,$8D,$58,$5B,$7D
  DEFB $9B,$6C,$5F,$ED,$8D,$D8,$4E,$39
  DEFB $A7,$F2,$51,$C5,$00,$00,$FF,$FF
  DEFB $02,$00,$55,$55,$A8,$0A,$51,$C5
  DEFB $A7,$F2,$4E,$29,$8D,$D8,$5F,$AD
  DEFB $9B,$6C,$5B,$FD,$8D,$D8,$4E,$39
  DEFB $A7,$F2,$51,$C5,$00,$00,$FF,$FF
  DEFB $00,$F7,$67,$40,$40,$30,$00,$A4
  DEFB $D4,$01,$22,$C0,$00,$5A,$23,$C0
  DEFB $01,$5B,$24,$C0,$02,$5C,$25,$C0
  DEFB $03,$5D,$26,$C0,$04,$5E,$27,$C0
  DEFB $05,$5F,$28,$C0,$06,$60,$29,$C0
  DEFB $07,$61,$22,$C0,$08,$6A,$23,$C0
  DEFB $09,$6B,$24,$C0,$0A,$6C,$25,$C0
  DEFB $0B,$6D,$26,$C0,$0C,$6E,$27,$C0
  DEFB $0D,$6F,$28,$C0,$0E,$70,$29,$C0
  DEFB $0F,$71,$FF,$02,$10,$34,$03,$9A
  DEFB $1A,$9B,$1B,$9C,$1C,$9D,$1D,$9E
  DEFB $1E,$9F,$1F,$A0,$20,$A1,$21,$A2
  DEFB $22,$A3,$23,$A4,$24,$A5,$25,$A6
  DEFB $26,$A7,$27,$A8,$28,$A9,$29,$C0
  DEFB $FF,$00,$F7,$67,$10,$40,$10,$01
  DEFB $29,$A8,$57,$A8,$5F,$26,$A7,$60
  DEFB $A7,$5E,$27,$A4,$5D,$24,$A5,$5C
  DEFB $A4,$5B,$23,$A2,$5A,$A3,$59,$26
  DEFB $A9,$58,$FF,$00,$F7,$67,$20,$7F
  DEFB $10,$01,$27,$A9,$56,$27,$A6,$40
  DEFB $A7,$55,$00,$A6,$54,$26,$A9,$41
  DEFB $A6,$53,$01,$A9,$52,$28,$A9,$42
  DEFB $A8,$51,$02,$A9,$50,$27,$A8,$42
  DEFB $A7,$4F,$02,$A8,$4E,$FF,$02,$1B
  DEFB $1C,$05,$00,$0A,$78,$7C,$74,$7C
  DEFB $6C,$74,$78,$74,$64,$7C,$5C,$70
  DEFB $80,$78,$64,$74,$6C,$64,$5C,$60
  DEFB $70,$70,$60,$68,$60,$80,$68,$6C
  DEFB $70,$68,$0C,$08,$38,$07,$03,$02
  DEFB $58,$50,$54,$39,$07,$03,$02,$48
  DEFB $4C,$58,$3A,$07,$03,$02,$40,$58
  DEFB $44,$3B,$07,$03,$02,$58,$3C,$38
  DEFB $3C,$07,$03,$04,$4C,$50,$58,$3D
  DEFB $07,$03,$04,$40,$48,$58,$3E,$07
  DEFB $03,$04,$44,$58,$38,$3F,$07,$03
  DEFB $04,$54,$3C,$58,$0C,$0A,$00,$07
  DEFB $03,$04,$78,$7C,$74,$01,$07,$03
  DEFB $05,$7C,$6C,$74,$02,$07,$03,$05
  DEFB $78,$74,$64,$03,$08,$04,$04,$7C
  DEFB $5C,$70,$6C,$04,$08,$04,$04,$80
  DEFB $78,$64,$68,$05,$07,$03,$01,$74
  DEFB $6C,$64,$06,$07,$03,$05,$5C,$60
  DEFB $70,$07,$07,$03,$01,$70,$60,$68
