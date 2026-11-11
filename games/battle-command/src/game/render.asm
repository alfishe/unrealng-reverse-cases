; --------------------------------------------------------------------------------------------------------------------
; render.asm: The 3D display-list interpreter: the frame start, the opcodes, the model scripts' renderers, the box generators
;
; A model is a script of byte opcodes read through IX by RunScript $990F until $FF; the opcode indexes the 23-word
; table $98E1. The vertices live in three rows of words at $FD00 (x), $FE00 (y), $FF00 (z), 64 vertices, in the
; model's own axes already turned by the object's heading (the box generators); ProjectScript $9A43 adds the object's
; position (the operands at $9A6C, $9A8E, $9AB3, set by DrawObject $B827) and writes the screen points to $FC00 (4
; bytes a vertex, x = $8000 behind the eye). The opcodes test faces by their screen winding ($9BAF), fill the front
; faces through the bank 3 filler, draw lines through the bank 3 line drawer, and order the parts of a model by a
; face's visibility ($9D5A). Models: bank 3 $CA8B-$CFCC, bank 2 $8739-$87D5, bank 5 $7E8F-$7FAF, bank 0 $D5D0, $D934,
; $FE80, bank 6 $E512-$E560, and each mission block's library (mission 1: 31 models at $EC57-$FB3E).
; --------------------------------------------------------------------------------------------------------------------

; Start a 3D pass: wait until the last blit is done (`$83BA` = 0), clear the
; back buffer
;
; Spins on `$83BA` (set to `$FF` by RequestViewBlit `$988D`, cleared by the
; interrupt after the blit, ClearBlitRequest `$8AEC`), then calls
; ClearBackBuffer `$96F1`. Callers: the play loops `$694B`, `$6A0C`, `$6AB9`
; and the bank 6 menu views `$C409`, `$C4AD`, `$CA8B`, `$DA09`, `$DB1C`. Its
; own time (18 permille) is the wait for the interrupt.
;
; Witness: L1 13569 (armour, c1, controls, death, fuel, m10, m1complete,
; m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).
StartViewPass:
  LD HL,BlitRequest+$0001
  XOR A
l_9886:
  CP (HL)
  JR NZ,l_9886
  CALL ClearBackBuffer
  RET

; Ask the interrupt to blit the finished back buffer: `$83BA` = `$FF`
;
; Witness: L1 13587 (armour, c1, controls, death, fuel, m10, m1complete,
; m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).
RequestViewBlit:
  LD A,$FF
  LD (BlitRequest+$0001),A
  RET

; Unused: clear 1792 bytes below `$98EF` and fill 1792 bytes below with
; `$AA`/`$55` rows, both by PUSH
;
; Sets `SP` = `$98F1` and calls two PUSH loops that take their return address
; off the stack first. As placed it would overwrite OpcodeTable `$98E1` and the
; code below it; no caller, a leftover of an earlier layout.
;
; Witness: known only from the code (no recording runs it).
ClearBackBufferOld:
  DI
  LD (ClearBackBufferOld+$000F),SP
  LD SP,OpcodeTable+$0010
  CALL sub_98A6
  CALL sub_98C2
  LD SP,$0000
  EI
  RET

; sub_98A6
;
; Used by the routine at ClearBackBufferOld.
sub_98A6:
  POP HL
  LD (l_98AF+$0011),HL
  LD B,$40
  LD HL,$0000
l_98AF:
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  DJNZ l_98AF
  JP $0000

; sub_98C2
;
; Used by the routine at ClearBackBufferOld.
sub_98C2:
  POP HL
  LD (l_98CA+$0015),HL
  LD A,$AA
  LD B,$40
l_98CA:
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  XOR $FF
  LD L,A
  LD H,A
  DJNZ l_98CA
  JP $0000

; The 23 script opcodes' handlers, indexed by the opcode byte
;
; 0 `$992D` native call, 1 `$9938` vertex program, 2 `$9A43` project, 3 `$9AD8`
; lines, 4 `$9B38` lines by faces, 5 `$9BAF` face test, 6 `$9CB1` jump if face
; visible, 7 `$9CE8` the same, 8 `$9D28` branch on face, 9 `$9D1E` return, 10
; `$9D5A` order by face, 11 `$9D0D` call, 12 `$9D8F` fill faces, 13 `$9E1E`
; fill faces with the near clip, 14 `$9ECD` fill polygons, 15 `$9F37` fill back
; faces, 16 `$9F43` lines with the near clip, 17 `$9FC3` lines by faces with
; the near clip, 18 `$A049` translate, 19 `$A07E` fill polygons with the near
; clip, 20 `$A114` fill back faces with the near clip, 21 `$A119` polar points,
; 22 `$B7E5` draw the carried object. Opcodes 4, 6, 7, 8, 17 are in no model of
; the recordings.
OpcodeTable:
  DEFW OpNative
  DEFW OpVertexProgram
  DEFW OpProject
  DEFW OpLines
  DEFW OpLinesByFaces
  DEFW OpTestFaces
  DEFW OpJumpIfVisible
  DEFW OpJumpIfVisible2
  DEFW OpBranchOnFace
  DEFW OpReturn
  DEFW OpOrderByFace
  DEFW OpCall
  DEFW OpFillFaces
  DEFW OpFillFacesClipped
  DEFW OpFillPolys
  DEFW OpFillBackFaces
  DEFW OpLinesClipped
  DEFW OpLinesByFacesClipped
  DEFW OpTranslate
  DEFW OpFillPolysClipped
  DEFW OpFillBackFacesClipped
  DEFW OpPolarPoints
  DEFW ScriptDrawCarried

; Run the model script at IX until the byte `$FF`
;
; Reads the opcode at IX, IX+1, patches the `CALL` at `$9927` with
; OpcodeTable[opcode] and calls it; every handler returns to `$992A` (`JP
; $990F`), with IX past its operands. Input: IX = the script; bank of the
; script paged (bank 3 via `$72BE`, bank 0 for the mission models). Callers:
; DrawObject `$B827` (the objects), `$B190` (the ground and the sky, scripts at
; bank 0 `$FF80`, `$FF8C`, `$FF98`), `$72BE` (bank 6 views with bank 3 models),
; the mission code `$E3F3`, `$E561`, and ScriptTranslate `$A049`, which jumps
; back here.
;
; Witness: L1 319386 (armour, c1, controls, death, fuel, m10, m1complete,
; m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).
RunScript:
  LD E,(IX+$00)
  LD A,$FF
  CP E
  RET Z
  LD HL,OpcodeTable
  LD D,$00
  SLA E
  ADD HL,DE
  INC IX
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (sub_9927+$0001),DE

; sub_9927
sub_9927:
  CALL sub_9927

; The handlers' return: go on with the next opcode
;
; Witness: L1 266356 (armour, c1, controls, death, fuel, m10, m1complete,
; m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).
ScriptNext:
  JP RunScript

; Opcode 0: jump to the native routine at the word operand
;
; IX on past the word, then `JP (HL)`: the routine reads its own operands
; through IX and returns to ScriptNext. The models call the box generators by
; the mission vectors `$67F4` (BoxSquare), `$67F7` (BoxRect), `$67FA`
; (BoxRect16), `$67FD` (BoxSquareTurret) and `$ABFF` (BoxTilted) with 3 operand
; bytes; other targets take none (`$F6B9` in mission 1 clears the tilt `$68E6`;
; `$D4A4`, `$D5C9`, `$E2C0`, `$EC2E`, `$EE06`, `$EE22`, `$FE8F` in bank 0).
;
; Witness: L1 38166 (armour, c1, controls, death, fuel, m10, m1complete,
; m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).
OpNative:
  LD L,(IX+$00)
  INC IX
  LD H,(IX+$00)
  INC IX
  JP (HL)

; Opcode 1: build vertices from others with a byte program: load, store,
; midpoint, add, subtract, negate
;
; Under `DI` with `SP` used as a pointer into the vertex rows. The current
; point P = (DE, DE', BC') = (x, y, z). Bytes: `$00-$3F` n: P = V[n];
; `$40-$7F`: V[n AND `$3F`] = P; `$80-$BF`: P = (P + V[n AND `$3F`]) / 2; `$C0`
; m: P = P + V[m]; `$E0` m: P = P - V[m]; `$F0`: P = -P; `$F8`: P.x = -P.x, P.z
; = -P.z (the half-turn about the vertical); any other byte (`$FF`) ends it,
; `SP` back, `EI`. With the box corners `V34-V41` from a box generator,
; midpoints and sums give every other vertex of the model in its turned axes.
;
; Witness: L1 24235 (armour, c1, controls, death, fuel, m10, m1complete,
; m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).
OpVertexProgram:
  POP DE
  LD (l_99C1+$0001),DE
  LD (l_99AD+$0011),SP
  DI
l_9942:
  LD A,(IX+$00)
  INC IX
  ADD A,A
  JR C,l_9965
  JP M,l_9993
  LD H,$FD
  LD L,A
  LD SP,HL
  POP DE
  LD HL,$00FE
  ADD HL,SP
  LD SP,HL
  EXX
  POP DE
  EXX
  LD HL,$00FE
  ADD HL,SP
  LD SP,HL
  EXX
  POP BC
  EXX
  JP l_9942
l_9965:
  JP M,l_99AD
  LD H,$FD
  LD L,A
  LD SP,HL
  POP HL
  ADD HL,DE
  SRA H
  RR L
  EX DE,HL
  EXX
  LD HL,$00FE
  ADD HL,SP
  LD SP,HL
  POP HL
  ADD HL,DE
  SRA H
  RR L
  EX DE,HL
  LD HL,$00FE
  ADD HL,SP
  LD SP,HL
  POP HL
  ADD HL,BC
  SRA H
  RR L
  LD B,H
  LD C,L
  EXX
  LD H,$FF
  JP l_9942
l_9993:
  AND $7F
  LD H,$FF
  ADD A,$02
  LD L,A
  LD SP,HL
  EXX
  PUSH BC
  LD HL,data_FEBB+$0047
  ADD HL,SP
  LD SP,HL
  PUSH DE
  LD HL,data_FEBB+$0047
  ADD HL,SP
  LD SP,HL
  EXX
  PUSH DE
  JP l_9942
l_99AD:
  ADD A,A
  JP Z,l_99C4
  ADD A,A
  JP Z,l_99E7
  ADD A,A
  JP Z,l_9A14
  ADD A,A
  JP Z,l_9A2F
  LD SP,$0000
  EI
l_99C1:
  JP l_99C1
l_99C4:
  LD A,(IX+$00)
  INC IX
  ADD A,A
  LD H,$FD
  LD L,A
  LD SP,HL
  POP HL
  ADD HL,DE
  EX DE,HL
  LD HL,$00FE
  ADD HL,SP
  LD SP,HL
  EXX
  POP HL
  ADD HL,DE
  EX DE,HL
  LD HL,$00FE
  ADD HL,SP
  LD SP,HL
  POP HL
  ADD HL,BC
  LD B,H
  LD C,L
  EXX
  JP l_9942
l_99E7:
  LD A,(IX+$00)
  INC IX
  ADD A,A
  LD H,$FD
  LD L,A
  LD SP,HL
  POP HL
  AND A
  EX DE,HL
  SBC HL,DE
  EX DE,HL
  LD HL,$00FE
  ADD HL,SP
  LD SP,HL
  EXX
  POP HL
  AND A
  EX DE,HL
  SBC HL,DE
  EX DE,HL
  LD HL,$00FE
  ADD HL,SP
  LD SP,HL
  LD L,C
  LD H,B
  POP BC
  AND A
  SBC HL,BC
  LD B,H
  LD C,L
  EXX
  JP l_9942
l_9A14:
  LD HL,$0000
  AND A
  SBC HL,DE
  EX DE,HL
  EXX
  LD HL,$0000
  AND A
  SBC HL,DE
  EX DE,HL
  LD HL,$0000
  AND A
  SBC HL,BC
  LD B,H
  LD C,L
  EXX
  JP l_9942
l_9A2F:
  LD HL,$0000
  AND A
  SBC HL,DE
  EX DE,HL
  EXX
  LD HL,$0000
  AND A
  SBC HL,BC
  LD B,H
  LD C,L
  EXX
  JP l_9942

; Opcode 2 (n, 2k): project n vertices from V[k] to screen points in
; ProjectedPoints `$FC00`
;
; For each vertex: depth = z + the operand at `$9A6C` (the object's z, `$0190`
; by default); if depth < 96 the point is marked behind the eye (`$FC00`+4i =
; `$8000`). Otherwise sx = 128 + 256 (x + `$9A8E`) / depth (shifted right by
; the count at `$9A93` first, the zoom), sy = 64 - 256 (y + `$9AB3`) / depth,
; through Divide `$A687` and DivideByLog `$A6D2` (one logarithm of the depth
; for both). Output: `$FC00`+4i = sx word, `$FC02`+4i = sy word.
;
; Witness: L1 56575 (armour, c1, controls, death, fuel, m10, m1complete,
; m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).
OpProject:
  POP DE
  LD (l_9AD5+$0001),DE
  LD D,$FC
  LD C,(IX+$00)
  INC IX
  LD E,(IX+$00)
  INC IX
  PUSH IX
  PUSH DE
  POP IX
  SLA E
  PUSH DE
  POP IY
l_9A5E:
  LD IXH,$FF
  LD E,(IX+$00)
  LD D,(IX+$01)
  DEC IXH
  DEC IXH
  LD HL,$0190
  ADD HL,DE
  PUSH HL
  AND A
  LD DE,$0060
  SBC HL,DE
  JP P,l_9A85
  LD (IY+$00),$00
  LD (IY+$01),$80
  POP HL
  JP l_9AC7
l_9A85:
  LD E,(IX+$00)
  LD D,(IX+$01)
  INC IXH
  LD HL,$0000
  ADD HL,DE
  POP DE
  LD A,$00
  AND A
  JR Z,l_9A9E
  LD B,A
l_9A98:
  SRA D
  RR E
  DJNZ l_9A98
l_9A9E:
  CALL Divide
  PUSH DE
  LD DE,$0080
  ADD HL,DE
  LD (IY+$00),L
  LD (IY+$01),H
  LD E,(IX+$00)
  LD D,(IX+$01)
  LD HL,$0000
  ADD HL,DE
  POP DE
  CALL DivideByLog
  LD DE,$0040
  CALL NegHL
  ADD HL,DE
  LD (IY+$02),L
  LD (IY+$03),H
l_9AC7:
  LD DE,$0004
  ADD IY,DE
  LD E,$02
  ADD IX,DE
  DEC C
  JR NZ,l_9A5E
  POP IX
l_9AD5:
  JP l_9AD5

; Opcode 3: a polyline: `$80`+v moves to point v, v draws a line to it, `$C0`
; ends
;
; A line is drawn only when both ends are in front of the eye; ClipLine2D
; `$A184` clips it to the window and `$72B1` draws it with bank 3 `$C9A7`.
;
; Witness: L1 5137 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; menu, missions, play, play2).
OpLines:
  POP DE
  LD (l_9B35+$0001),DE
l_9ADD:
  LD A,(IX+$00)
  AND A
  JP M,l_9B15
  ADD A,A
  ADD A,A
  LD L,A
  LD H,$FC
  LD E,(HL)
  INC L
  LD D,(HL)
  INC L
  PUSH DE
  LD E,(HL)
  INC L
  LD D,(HL)
  POP HL
  PUSH HL
  PUSH DE
  LD A,H
  XOR $80
  OR L
  JP Z,l_9B0D
  EXX
  LD A,H
  XOR $80
  OR L
  JP Z,l_9B0D
  EXX
  CALL ClipLine2D
  JP NC,l_9B0D
  CALL Bank3Lookup
l_9B0D:
  POP DE
  POP HL
  EXX
  INC IX
  JP l_9ADD
l_9B15:
  CP $C0
  JP Z,l_9B33
  AND $7F
  ADD A,A
  ADD A,A
  LD L,A
  LD H,$FC
  LD E,(HL)
  INC L
  LD D,(HL)
  PUSH DE
  INC L
  LD E,(HL)
  INC L
  LD D,(HL)
  PUSH DE
  EXX
  POP DE
  POP HL
  EXX
  INC IX
  JP l_9ADD
l_9B33:
  INC IX
l_9B35:
  JP l_9B35

; Opcode 4: edges drawn when either of two faces is visible: (face a, face b,
; v) or `$80`+v, `$C0` ends
;
; The wire edge between faces a and b (flags `$6728`+a, +b) is drawn to point v
; when one of them faces the eye, else the pen moves to v. In no model of the
; recordings (one use in mission 1 at `$F99E`, its model not drawn in them).
;
; Witness: known only from the code (no recording runs it).
OpLinesByFaces:
  POP DE
  LD (l_9BAC+$0001),DE
l_9B3D:
  LD A,(IX+$00)
  AND A
  JP M,l_9B8D
  LD H,$67
  ADD A,$28
  LD L,A
  LD D,H
  INC IX
  LD A,(IX+$00)
  ADD A,$28
  LD E,A
  LD A,(DE)
  OR (HL)
  INC IX
  LD A,(IX+$00)
  JP Z,l_9B93
  ADD A,A
  ADD A,A
  LD H,$FC
  LD L,A
  LD E,(HL)
  INC L
  LD D,(HL)
  INC L
  PUSH DE
  LD E,(HL)
  INC L
  LD D,(HL)
  POP HL
  PUSH HL
  PUSH DE
  LD A,H
  XOR $80
  OR L
  JP Z,l_9B85
  EXX
  LD A,H
  XOR $80
  OR L
  JP Z,l_9B85
  EXX
  CALL ClipLine2D
  JP NC,l_9B85
  CALL Bank3Lookup
l_9B85:
  POP DE
  POP HL
  EXX
  INC IX
  JP l_9B3D
l_9B8D:
  CP $C0
  JR Z,l_9BAA
  AND $7F
l_9B93:
  ADD A,A
  ADD A,A
  LD L,A
  LD H,$FC
  LD E,(HL)
  INC L
  LD D,(HL)
  PUSH DE
  INC L
  LD E,(HL)
  INC L
  LD D,(HL)
  PUSH DE
  EXX
  POP DE
  POP HL
  EXX
  INC IX
  JP l_9B3D
l_9BAA:
  INC IX
l_9BAC:
  JP l_9BAC

; Opcode 5 (slot, n, n x (a, b, c)): set the visibility flags of n faces from
; their screen winding
;
; Slot base to `$9C6B` (+`$28`), then TestFace `$9BC3` for each triple of point
; offsets (4 x vertex).
;
; Witness: L1 24102 (armour, c1, controls, death, fuel, m10, m1complete,
; m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).
OpTestFaces:
  POP DE
  LD (l_9C79+$0001),DE
  LD A,(IX+$00)
  ADD A,$28
  LD (StoreFaceFlag+$0001),A
  INC IX
  LD A,(IX+$00)
  INC IX

; One face: the sign of the cross product (b - a) x (c - a) of three screen
; points into FaceFlags
;
; Counts the points behind the eye in `$9BDA`: 3 gives flag 0 (`$9CAA`), 1-2
; give `$FF` (`$9CA3`, drawn and clipped later); else the two edge vectors are
; scaled to bytes (ScaleToBytes `$9C84`) and multiplied with MulSigned `$A7BF`:
; flag = `$FF` when ex1 * ey2 < ey1 * ex2.
;
; Witness: L1 133984 (armour, c1, controls, death, fuel, m10, m1complete,
; m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).
TestFace:
  EX AF,AF'
  LD L,(IX+$00)
  LD A,$00
  LD (TestFace+$0017),A
  INC IX
  LD H,$FC
  LD C,(HL)
  INC L
  LD B,(HL)
  LD A,B
  XOR $80
  OR C
  JR NZ,l_9BDF
  LD A,$00
  INC A
  LD (TestFace+$0017),A
l_9BDF:
  PUSH HL
  EXX
  POP HL
  INC L
  LD C,(HL)
  INC L
  LD B,(HL)
  EXX
  LD L,(IX+$00)
  INC IX
  LD E,(HL)
  INC L
  LD D,(HL)
  LD A,D
  XOR $80
  OR E
  JR NZ,l_9BFC
  LD A,(TestFace+$0017)
  INC A
  LD (TestFace+$0017),A
l_9BFC:
  PUSH HL
  EXX
  POP HL
  INC L
  LD E,(HL)
  INC L
  LD D,(HL)
  PUSH DE
  EX DE,HL
  AND A
  SBC HL,BC
  EX DE,HL
  POP BC
  PUSH DE
  EXX
  PUSH DE
  EX DE,HL
  AND A
  SBC HL,BC
  EX DE,HL
  POP BC
  PUSH DE
  LD H,$FC
  LD L,(IX+$00)
  INC IX
  LD E,(HL)
  INC L
  LD D,(HL)
  LD A,D
  XOR $80
  OR E
  LD A,(TestFace+$0017)
  JR NZ,l_9C28
  INC A
l_9C28:
  CP $03
  JP Z,FaceAllBehind
  AND A
  JP NZ,FacePartlyBehind
  PUSH HL
  EX DE,HL
  AND A
  SBC HL,BC
  EXX
  POP HL
  INC L
  LD E,(HL)
  INC L
  LD D,(HL)
  EX DE,HL
  AND A
  SBC HL,BC
  PUSH HL
  EXX
  POP DE
  EXX
  POP HL
  POP DE
  LD C,$00
  CALL ScaleToBytes
  EXX
  LD C,$00
  CALL ScaleToBytes
  EXX
  LD A,L
  EXX
  LD C,L
  LD L,A
  LD A,C
  EXX
  LD L,A
  CALL MulSigned
  PUSH HL
  EXX
  LD A,L
  CALL MulSigned
  POP DE
  SBC HL,DE
  RL H
  CCF
  SBC A,A
  LD B,A

; Store the face flag B at `$6728` + slot, next slot, loop over the triples
;
; Witness: L1 133984 (armour, c1, controls, death, fuel, m10, m1complete,
; m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).
StoreFaceFlag:
  LD A,$00
  LD L,A
  LD H,$67
  LD (HL),B
  INC A
  LD (StoreFaceFlag+$0001),A
  EX AF,AF'
  DEC A
  JP NZ,TestFace
l_9C79:
  JP l_9C79
; This entry point is used by the routine at ScaleToBytes.
l_9C7C:
  SRA H
  RR L
  SRA D
  RR E

; Halve the two words HL, DE together until both fit in a signed byte (C = the
; sign bias)
;
; The loop `$9C7C` shifts both right. Unreferenced code at `$9C9A` (another
; flag store) follows.
;
; Witness: L1 247063 (armour, c1, controls, death, fuel, m10, m1complete,
; m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).
ScaleToBytes:
  LD A,L
  RLA
  LD A,H
  ADC A,C
  JR NZ,l_9C7C
l_9C8A:
  LD A,E
  RLA
  LD A,D
  ADC A,C
  RET Z
  SRA H
  RR L
  SRA D
  RR E
  JP l_9C8A

; data_9C9A
data_9C9A:
  DEFB $DD,$23,$DD,$23,$06,$FF,$C3,$6A
  DEFB $9C

; A face with one or two points behind the eye: flag `$FF`
;
; Witness: L1 1130 (c1, death, m1complete, m4complete).
FacePartlyBehind:
  POP DE
  POP DE
  LD B,$FF
  JP StoreFaceFlag

; A face with all three points behind the eye: flag 0
;
; Witness: L1 12422 (armour, c1, death, m1complete, m4complete, missions, play,
; play2).
FaceAllBehind:
  POP DE
  POP DE
  LD B,$00
  JP StoreFaceFlag

; Opcode 6 (face, address): go on at the address when the face is visible, else
; skip 3 bytes
;
; Unreferenced code at `$9CD7` (the same with a return address pushed) follows.
;
; Witness: known only from the code (no recording runs it).
OpJumpIfVisible:
  POP DE
  LD (l_9CC8+$0001),DE
  LD A,(IX+$00)
  ADD A,$28
  LD L,A
  LD H,$67
  LD A,(HL)
  AND A
  LD BC,$0003
  JP NZ,l_9CCB
  ADD IX,BC
l_9CC8:
  JP l_9CC8
l_9CCB:
  LD E,(IX+$01)
  LD D,(IX+$02)
  PUSH DE
  POP IX
  JP l_9CC8

; data_9CD7
data_9CD7:
  DEFB $DD,$E5,$E1,$09,$DD,$5E,$01,$DD
  DEFB $56,$02,$D5,$DD,$E1,$E5,$C3,$C8
  DEFB $9C

; Opcode 7 (face, address): the same as opcode 6
;
; Witness: known only from the code (no recording runs it).
OpJumpIfVisible2:
  POP DE
  LD (l_9CFE+$0001),DE
  LD A,(IX+$00)
  ADD A,$28
  LD L,A
  LD H,$67
  LD A,(HL)
  AND A
  JR NZ,l_9D01
  LD BC,$0003
  ADD IX,BC
l_9CFE:
  JP l_9CFE
l_9D01:
  LD E,(IX+$01)
  LD D,(IX+$02)
  PUSH DE
  POP IX
  JP l_9CFE

; Opcode 11 (address): run the script at the address as a subroutine (IX
; pushed, opcode 9 returns)
;
; Witness: L1 1496 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe,
; m2ocean, menu, missions, play, play2, search).
OpCall:
  LD C,(IX+$00)
  INC IX
  LD B,(IX+$00)
  INC IX
  POP HL
  PUSH IX
  PUSH BC
  POP IX
  JP (HL)

; Opcode 9: return from a script subroutine: IX popped from the stack
;
; Used to end the parts of OpCall `$9D0D` and OpOrderByFace `$9D5A`.
;
; Witness: L1 27230 (armour, c1, controls, death, fuel, m10, m1complete,
; m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).
OpReturn:
  POP DE
  LD (l_9D25+$0001),DE
  POP IX
l_9D25:
  JP l_9D25

; Opcode 8 (face, visible, hidden): go on at one of two addresses, the return
; pushed (IX + 5)
;
; Witness: known only from the code (no recording runs it).
OpBranchOnFace:
  POP DE
  LD (l_9D4B+$0001),DE
  LD A,(IX+$00)
  ADD A,$28
  LD L,A
  LD H,$67
  LD A,(HL)
  AND A
  PUSH IX
  POP HL
  LD BC,$0005
  ADD HL,BC
  PUSH HL
  JP Z,l_9D4E
  LD E,(IX+$01)
  LD D,(IX+$02)
  PUSH DE
  POP IX
l_9D4B:
  JP l_9D4B
l_9D4E:
  LD E,(IX+$03)
  LD D,(IX+$04)
  PUSH DE
  POP IX
  JP l_9D4B

; Opcode 10 (face, part A, part B): draw the inline part and the two parts in
; an order set by the face
;
; Face visible: the inline part (IX + 5), then A, then B; hidden: A, then the
; inline part, then B. Each part ends with opcode 9; the two other entries are
; pushed as returns. This is how a model sorts its own parts (the turret before
; or behind the hull) without a depth sort.
;
; Witness: L1 12854 (armour, c1, controls, death, fuel, m10, m1complete,
; m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).
OpOrderByFace:
  POP DE
  LD (l_9D84+$0001),DE
  LD A,(IX+$00)
  ADD A,$28
  LD L,A
  LD H,$67
  LD A,(HL)
  AND A
  LD E,(IX+$01)
  LD D,(IX+$02)
  PUSH IX
  POP HL
  LD BC,$0005
  ADD HL,BC
  LD C,(IX+$03)
  LD B,(IX+$04)
  JP Z,l_9D87
  PUSH HL
  POP IX
  PUSH BC
  PUSH DE
l_9D84:
  JP l_9D84
l_9D87:
  PUSH DE
  POP IX
  PUSH BC
  PUSH HL
  JP l_9D84

; Opcode 12 (n, n x face): fill the visible faces; face = (slot, length, k,
; colour, k point offsets)
;
; Patches `$9DB2` to `JP Z` (skip hidden faces) and `$9DAD` to fall through,
; then shares FillFaceList `$9D99`. A face with a point behind the eye is
; skipped (`$9E0B`).
;
; Witness: L1 27293 (armour, c1, controls, death, fuel, m10, m1complete,
; m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).
OpFillFaces:
  LD A,$CA
  LD (l_9DA6+$000C),A
  LD A,$00
  LD (l_9DA6+$0007),A

; Copy each chosen face's screen points to PolyVerts `$6700` and fill it with
; bank 3 `$C4C4` (via `$7290`)
;
; The colour to `$7579`, the count to `$68A9`, the face count in `$68AA`. A
; face whose flag fails the test is skipped by its length byte.
;
; Witness: L1 28219 (armour, c1, controls, death, fuel, m10, m1complete,
; m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).
FillFaceList:
  POP DE
  LD (l_9E02+$0001),DE
  LD A,(IX+$00)
  LD (PanelGauges+$0002),A
  INC IX
l_9DA6:
  LD A,(IX+$00)
  ADD A,$28
  LD L,A
  JR l_9DA6
  LD H,$67
  LD A,(HL)
  AND A
  JP Z,l_9E14
  LD A,(IX+$03)
  LD (AwolState+$0001),A
  LD H,$FC
  LD DE,PolyVerts
  EXX
  LD A,(IX+$02)
  LD (PanelGauges+$0001),A
  LD BC,$0003
  ADD IX,BC
  LD B,A
l_9DCD:
  EXX
  INC IX
  LD L,(IX+$00)
  LD C,(HL)
  INC L
  LD B,(HL)
  INC L
  LD A,B
  XOR $80
  OR C
  JP Z,l_9E0B
  EX DE,HL
  LD (HL),C
  INC L
  LD (HL),B
  INC L
  EX DE,HL
  LD C,(HL)
  INC L
  LD B,(HL)
  INC L
  EX DE,HL
  LD (HL),C
  INC L
  LD (HL),B
  INC L
  EX DE,HL
  EXX
  DJNZ l_9DCD
  INC IX
  PUSH IX
  PUSH IY
  CALL Bank3SetObject
  POP IY
  POP IX
l_9DFE:
  LD A,(PanelGauges+$0002)
  DEC A
l_9E02:
  JP Z,l_9E02
  LD (PanelGauges+$0002),A
  JP l_9DA6
l_9E0B:
  EXX
  LD C,B
  LD B,$00
  ADD IX,BC
  JP l_9DFE
l_9E14:
  LD E,(IX+$01)
  LD D,$00
  ADD IX,DE
  JP l_9DFE

; Opcode 13: fill the visible faces, clipping those that cross the near plane
;
; Witness: L1 6425 (armour, c1, controls, death, fuel, m1complete, m4complete,
; missions, play, play2).
OpFillFacesClipped:
  LD A,$CA

; As FillFaceList, but a point behind the eye calls ClipPolyNear `$A509` to cut
; the face at the near plane
;
; A = the opcode patched at `$9E40` (`JP Z` for opcode 13, `JP NZ` for 20). The
; first point offset is kept in `$66CC` for the closing edge.
;
; Witness: L1 14717 (armour, c1, controls, death, fuel, m1complete, m4complete,
; missions, play, play2).
FillFaceListClipped:
  POP DE
  LD (l_9EB1+$0001),DE
  LD (l_9E3C+$0004),A
  XOR A
  LD (l_9E34+$0007),A
  LD A,(IX+$00)
  LD (PanelGauges+$0002),A
  INC IX
l_9E34:
  LD A,(IX+$00)
  ADD A,$28
  LD L,A
  JR l_9E3C
l_9E3C:
  LD H,$67
  LD A,(HL)
  AND A
  JP Z,l_9EBA
  XOR A
  LD (PolyOutCount),A
  LD A,(IX+$03)
  LD (AwolState+$0001),A
  LD H,$FC
  LD DE,PolyVerts
  EXX
  LD A,(IX+$04)
  LD (PolyClipVars),A
  LD A,(IX+$02)
  LD (PanelGauges+$0001),A
  LD (PolyClipVars+$0001),A
  LD BC,$0003
  ADD IX,BC
  LD B,A
l_9E68:
  EXX
  INC IX
l_9E6B:
  LD L,(IX+$00)
  EX AF,AF'
  LD A,L
  EX AF,AF'
  LD C,(HL)
  INC L
  LD B,(HL)
  INC L
  LD A,B
  XOR $80
  OR C
  JP Z,l_9EC4
  EX DE,HL
  LD (HL),C
  INC L
  LD (HL),B
  INC L
  EX DE,HL
  LD C,(HL)
  INC L
  LD B,(HL)
  INC L
  EX DE,HL
  LD (HL),C
  INC L
  LD (HL),B
  INC L
  EX AF,AF'
  LD (GameVars),A
  LD A,(PolyOutCount)
  INC A
  LD (PolyOutCount),A
  EX DE,HL
  EXX
  DJNZ l_9E68
  INC IX
l_9E9C:
  PUSH IX
  PUSH IY
  LD A,(PolyOutCount)
  LD (PanelGauges+$0001),A
  CALL Bank3SetObject
  POP IY
  POP IX
l_9EAD:
  LD A,(PanelGauges+$0002)
  DEC A
l_9EB1:
  JP Z,l_9EB1
  LD (PanelGauges+$0002),A
  JP l_9E34
l_9EBA:
  LD E,(IX+$01)
  LD D,$00
  ADD IX,DE
  JP l_9EAD
l_9EC4:
  CALL ClipPolyNear
  JR C,l_9E9C
  JR Z,l_9E6B
  JR l_9EAD

; Opcode 14 (n, n x (k, colour, k point offsets)): fill polygons with no face
; test
;
; Witness: L1 11527 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; menu, missions, play, play2).
OpFillPolys:
  POP DE
  LD (l_9F25+$0001),DE
  LD A,(IX+$00)
  LD (PanelGauges+$0002),A
  INC IX
l_9EDA:
  LD A,(IX+$00)
  LD (PanelGauges+$0001),A
  LD B,A
  INC IX
  EXX
  LD A,(IX+$00)
  LD (AwolState+$0001),A
  LD H,$FC
  LD DE,PolyVerts
  EXX
l_9EF0:
  EXX
  INC IX
  LD L,(IX+$00)
  LD C,(HL)
  INC L
  LD B,(HL)
  INC L
  LD A,B
  XOR $80
  OR C
  JP Z,l_9F2E
  EX DE,HL
  LD (HL),C
  INC L
  LD (HL),B
  INC L
  EX DE,HL
  LD C,(HL)
  INC L
  LD B,(HL)
  INC L
  EX DE,HL
  LD (HL),C
  INC L
  LD (HL),B
  INC L
  EX DE,HL
  EXX
  DJNZ l_9EF0
  INC IX
  PUSH IX
  PUSH IY
  CALL Bank3SetObject
  POP IY
  POP IX
l_9F21:
  LD A,(PanelGauges+$0002)
  DEC A
l_9F25:
  JP Z,l_9F25
  LD (PanelGauges+$0002),A
  JP l_9EDA
l_9F2E:
  EXX
  LD C,B
  LD B,$00
  ADD IX,BC
  EXX
  JR l_9F21

; Opcode 15: fill the faces whose flag is 0 (`JP NZ` at `$9DB2`): the insides
; seen through an opening
;
; Witness: L1 926 (armour, m1complete, m4complete, missions, play2).
OpFillBackFaces:
  LD A,$C2
  LD (l_9DA6+$000C),A
  XOR A
  LD (l_9DA6+$0007),A
  JP FillFaceList

; Opcode 16: a polyline like opcode 3, a segment with an end behind the eye cut
; at the near plane (`$A422`, `$A42B`)
;
; Witness: L1 5538 (death, m1complete, m4complete, missions).
OpLinesClipped:
  POP DE
  LD (l_9FB2+$0001),DE
l_9F48:
  LD A,(IX+$00)
  AND A
  JP M,l_9F90
  EX AF,AF'
  LD A,(GameVars)
  EX AF,AF'
  LD (GameVars),A
  ADD A,A
  ADD A,A
  LD L,A
  LD H,$FC
  LD E,(HL)
  INC L
  LD D,(HL)
  INC L
  PUSH DE
  LD E,(HL)
  INC L
  LD D,(HL)
  POP HL
  PUSH HL
  PUSH DE
  LD A,(GameVars)
  LD B,A
  EXX
  EX AF,AF'
  LD B,A
  EXX
  LD A,H
  XOR $80
  OR L
  JP Z,l_9FB5
  EXX
  LD A,H
  XOR $80
  OR L
  EXX
  JP Z,l_9FBC
l_9F7F:
  CALL ClipLine2D
  JP NC,l_9F88
  CALL Bank3Lookup
l_9F88:
  POP DE
  POP HL
  EXX
  INC IX
  JP l_9F48
l_9F90:
  CP $C0
  JP Z,l_9FB0
  AND $7F
  LD (GameVars),A
  ADD A,A
  ADD A,A
  LD L,A
  LD H,$FC
  LD E,(HL)
  INC L
  LD D,(HL)
  PUSH DE
  INC L
  LD E,(HL)
  INC L
  LD D,(HL)
  PUSH DE
  EXX
  POP DE
  POP HL
  EXX
  INC IX
  JR l_9F48
l_9FB0:
  INC IX
l_9FB2:
  JP l_9FB2
l_9FB5:
  CALL NearClipLineEnd
  JR C,l_9F7F
  JR l_9F88
l_9FBC:
  CALL NearClipLine
  JR C,l_9F7F
  JR l_9F88

; Opcode 17: opcode 4 with the near clip
;
; Its near-clip calls `$A039`, `$A041` are unreferenced. In no model of the
; recordings.
;
; Witness: known only from the code (no recording runs it).
OpLinesByFacesClipped:
  POP DE
  LD (l_A036+$0001),DE
l_9FC8:
  LD A,(IX+$00)
  AND A
  JP M,l_A014
  LD H,$67
  ADD A,$28
  LD L,A
  LD D,H
  INC IX
  LD E,(IX+$00)
  LD A,(DE)
  OR (HL)
  INC IX
  LD A,(IX+$00)
  JP Z,l_A01A
  EX AF,AF'
  LD A,(GameVars)
  EX AF,AF'
  LD (GameVars),A
  ADD A,A
  ADD A,A
  LD L,A
  LD H,$FC
  LD E,(HL)
  INC L
  LD D,(HL)
  INC L
  PUSH DE
  LD E,(HL)
  INC L
  LD D,(HL)
  POP HL
  PUSH HL
  PUSH DE
  LD A,(GameVars)
  LD B,A
  EXX
  EX AF,AF'
  LD B,A
  EXX
  CALL ClipLine2D
  JR NC,l_A00C
  CALL Bank3Lookup
l_A00C:
  POP DE
  POP HL
  EXX
  INC IX
  JP l_9FC8
l_A014:
  CP $C0
  JR Z,l_A034
  AND $7F
l_A01A:
  LD (GameVars),A
  ADD A,A
  ADD A,A
  LD L,A
  LD H,$FC
  LD E,(HL)
  INC L
  LD D,(HL)
  PUSH DE
  INC L
  LD E,(HL)
  INC L
  LD D,(HL)
  PUSH DE
  EXX
  POP DE
  POP HL
  EXX
  INC IX
  JP l_9FC8
l_A034:
  INC IX
l_A036:
  JP l_A036

; data_A039
data_A039:
  DEFB $CD,$22,$A4,$38,$C6,$C3,$0C,$A0
  DEFB $CD,$2B,$A4,$38,$BE,$C3,$0C,$A0

; Opcode 18 (2k): add vertex k to the projection's position operands `$9A8E`,
; `$9AB3`, `$9A6C`
;
; Then `JP $990F` (not RET): the handler's return address stays on the stack
; and is taken by the `RET Z` of the next `$FF`.
;
; Witness: L1 32 (missions).
OpTranslate:
  LD L,(IX+$00)
  LD H,$FD
  LD E,(HL)
  INC L
  LD D,(HL)
  EX DE,HL
  LD BC,(l_9A85+$0009)
  ADD HL,BC
  LD (l_9A85+$0009),HL
  EX DE,HL
  DEC L
  INC H
  LD E,(HL)
  INC L
  LD D,(HL)
  EX DE,HL
  LD BC,(l_9A9E+$0015)
  ADD HL,BC
  LD (l_9A9E+$0015),HL
  EX DE,HL
  DEC L
  INC H
  LD E,(HL)
  INC L
  LD D,(HL)
  EX DE,HL
  LD BC,(l_9A5E+$000E)
  ADD HL,BC
  LD (l_9A5E+$000E),HL
  EX DE,HL
  INC IX
  JP RunScript

; Opcode 19 (n, n x (k, colour, k point offsets)): fill polygons, clipping at
; the near plane
;
; Witness: L1 15521 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
OpFillPolysClipped:
  POP DE
  LD (l_A0F6+$0001),DE
  LD A,(IX+$00)
  LD (PanelGauges+$0002),A
  INC IX
l_A08B:
  XOR A
  LD (PolyOutCount),A
  LD A,(IX+$01)
  LD (AwolState+$0001),A
  LD H,$FC
  LD DE,PolyVerts
  EXX
  LD A,(IX+$02)
  LD (PolyClipVars),A
  LD A,(IX+$00)
  LD (PanelGauges+$0001),A
  LD (PolyClipVars+$0001),A
  INC IX
  LD B,A
l_A0AD:
  EXX
  INC IX
; This entry point is used by the routine at l_A109.
l_A0B0:
  LD L,(IX+$00)
  EX AF,AF'
  LD A,L
  EX AF,AF'
  LD C,(HL)
  INC L
  LD B,(HL)
  INC L
  LD A,B
  XOR $80
  OR C
  JP Z,l_A109
  EX DE,HL
  LD (HL),C
  INC L
  LD (HL),B
  INC L
  EX DE,HL
  LD C,(HL)
  INC L
  LD B,(HL)
  INC L
  EX DE,HL
  LD (HL),C
  INC L
  LD (HL),B
  INC L
  EX AF,AF'
  LD (GameVars),A
  LD A,(PolyOutCount)
  INC A
  LD (PolyOutCount),A
  EX DE,HL
  EXX
  DJNZ l_A0AD
  INC IX
; This entry point is used by the routine at l_A109.
l_A0E1:
  PUSH IX
  PUSH IY
  LD A,(PolyOutCount)
  LD (PanelGauges+$0001),A
  CALL Bank3SetObject
  POP IY
  POP IX
; This entry point is used by the routine at l_A109.
l_A0F2:
  LD A,(PanelGauges+$0002)
  DEC A
l_A0F6:
  JP Z,l_A0F6
  LD (PanelGauges+$0002),A
  JP l_A08B

; data_A0FF
data_A0FF:
  DEFB $DD,$5E,$01,$16,$00,$DD,$19,$C3
  DEFB $F2,$A0

; l_A109
;
; Used by the routine at OpFillPolysClipped.
l_A109:
  CALL ClipPolyNear
  JR C,l_A0E1
  JP Z,l_A0B0
  JP l_A0F2

; Opcode 20: fill the faces whose flag is 0, clipping at the near plane
; (FillFaceListClipped with `JP NZ`)
;
; Witness: L1 8292 (armour, c1, death, fuel, m1complete, m4complete, missions,
; play, play2).
OpFillBackFacesClipped:
  LD A,$C2
  JP FillFaceListClipped

; Opcode 21 (n, next, frame table): n vertices from (angle, radius, height)
; triples, turned by the heading
;
; The frame (`$A12C`, the object record's +4, set by DrawObject `$B827`) picks
; a word of the table at IX+3: the address of n triples. Each gives x = r
; sin(heading + angle) / 128, z = r cos(...) / 128, y = height, stored from V32
; downwards. Then IX = next. Mission 1 uses it once (`$EFC5`, a barrel run out
; in five frames).
;
; Witness: L1 723 (armour, m1complete, m4complete, play2).
OpPolarPoints:
  POP DE
  LD (l_A179+$0001),DE
  PUSH IX
  POP HL
  LD A,(HL)
  LD (l_A138+$0037),A
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  PUSH DE
  LD A,$00
  ADD A,A
  LD C,A
  LD B,$00
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  LD E,$41
l_A138:
  LD D,$FF
  LD A,(MissionScore+$0005)
  ADD A,(HL)
  INC HL
  EXX
  CALL ApiVector14
  EX AF,AF'
  LD E,A
  EXX
  LD A,(HL)
  EXX
  CALL MulFrac
  PUSH HL
  EXX
  POP BC
  EX DE,HL
  LD (HL),B
  DEC L
  LD (HL),C
  INC L
  DEC H
  LD (HL),$00
  DEC L
  EX DE,HL
  LD A,(HL)
  INC HL
  LD C,(HL)
  INC HL
  EX DE,HL
  LD (HL),C
  INC L
  DEC H
  EXX
  LD E,A
  EX AF,AF'
  CALL MulFrac
  PUSH HL
  EXX
  LD A,B
  POP BC
  LD (HL),B
  DEC L
  LD (HL),C
  DEC L
  LD A,$00
  DEC A
  LD (l_A138+$0037),A
  EX DE,HL
  JR NZ,l_A138
  POP IX
l_A179:
  JP l_A179

; The 2D clip window: x max (`$FF`), y max (`$5F`), and the clipper's work
; words
;
; `$A17C` = 255 (bank 6 `$CA8B` sets 95 for the narrow console view), `$A17E` =
; 95; `$A180-$A183` hold the two points while ClipLine2D bisects.
ClipWindow:
  DEFB $FF,$00
  DEFB $5F,$00
  DEFB $00,$00
  DEFB $00,$00

  ORG $AA47

; BoxSquare with the second heading `$68E9` in place of `$68E7` (the mission
; vector `$67FD`): a turret
;
; Witness: L1 17 (missions).
BoxSquareTurret:
  POP DE
  LD (l_AA5B+$0006),DE
  LD A,(MissionScore+$0005)
  LD (l_AA5B+$0001),A
  LD A,(GoalFlag+$0001)
  LD (MissionScore+$0005),A
  CALL ApiVector18

; l_AA5B
l_AA5B:
  LD A,$00
  LD (MissionScore+$0005),A
  JP $0000

; Native (turn, size, height): the 8 corners V34-V41 of a square box turned by
; the heading `$68E7` + turn, V33 = 0
;
; With S = size sin(a) / 128 and C = size cos(a) / 128: V34 = (C, -h, -S), V35
; = (S, -h, C), V36 = (-C, -h, S), V37 = (-S, -h, -C), V38-V41 the same at y =
; +h. The mission vector `$67F4`.
;
; Witness: L1 3795 (armour, c1, death, m1complete, m4complete, missions, play,
; play2).
BoxSquare:
  POP DE
  LD (l_AAF2+$0001),DE
  LD B,(IX+$00)
  INC IX
  LD A,(MissionScore+$0005)
  ADD A,B
  LD H,$63
  LD L,A
  LD E,(HL)
  ADD A,$40
  LD L,A
  LD A,(HL)
  PUSH AF
  LD A,(IX+$00)
  CALL MulFrac
  LD (MissionHeader+$2181),HL
  LD (data_FEBB+$008D),HL
  LD (MissionHeader+$2189),HL
  LD (data_FEBB+$0095),HL
  LD A,H
  CPL
  LD H,A
  LD A,L
  CPL
  LD L,A
  LD (data_FEBB+$0089),HL
  LD (MissionHeader+$2185),HL
  LD (data_FEBB+$0091),HL
  LD (MissionHeader+$218D),HL
  POP AF
  LD E,(IX+$00)
  CALL MulFrac
  INC IX
  LD (data_FEBB+$008B),HL
  LD (MissionHeader+$217F),HL
  LD (data_FEBB+$0093),HL
  LD (MissionHeader+$2187),HL
  CALL NegHL
  LD (MissionHeader+$2183),HL
  LD (data_FEBB+$008F),HL
  LD (MissionHeader+$218B),HL
  LD (data_FEBB+$0097),HL

; Last operand h: y = -h for V34-V37, +h for V38-V41; V33 = (0, 0, 0); return
;
; Witness: L1 24903 (armour, c1, controls, death, fuel, m10, m1complete,
; m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).
BoxHeights:
  LD HL,$0000
  LD (MissionHeader+$217D),HL
  LD (MissionHeader+$227D),HL
  LD (data_FEBB+$0087),HL
  LD A,(IX+$00)
  LD L,A
  RLA
  SBC A,A
  LD H,A
  LD (MissionHeader+$2287),HL
  LD (MissionHeader+$2289),HL
  LD (MissionHeader+$228B),HL
  LD (MissionHeader+$228D),HL
  CALL NegHL
  LD (MissionHeader+$227F),HL
  LD (MissionHeader+$2281),HL
  LD (MissionHeader+$2283),HL
  LD (MissionHeader+$2285),HL
  INC IX
l_AAF2:
  JP l_AAF2

; Native (half angle, radius, height): a rectangle box with 16-bit corners
; (Sine16), turned by the heading
;
; The corners lie at the radius r on the angles heading +/- b and their
; opposites, so b sets the aspect. Through MulWordByte `$67D9`. The mission
; vector `$67FA`.
;
; Witness: L1 6117 (armour, c1, death, fuel, m1complete, m4complete, missions,
; play, play2).
BoxRect16:
  POP DE
  LD (l_AAF2+$0001),DE
  LD A,(MissionScore+$0005)
  LD B,(IX+$00)
  LD C,A
  ADD A,B
  INC IX
  EXX
  CALL SinCos16
  PUSH BC
  EX DE,HL
  LD A,(IX+$00)
  CALL ApiVector09
  LD (MissionHeader+$2181),HL
  LD (MissionHeader+$2189),HL
  CALL NegHL
  LD (MissionHeader+$2185),HL
  LD (MissionHeader+$218D),HL
  POP HL
  LD A,(IX+$00)
  CALL ApiVector09
  LD (data_FEBB+$008B),HL
  LD (data_FEBB+$0093),HL
  CALL NegHL
  LD (data_FEBB+$008F),HL
  LD (data_FEBB+$0097),HL
  EXX
  LD A,B
  NEG
  ADD A,C
  CALL SinCos16
  PUSH BC
  EX DE,HL
  LD A,(IX+$00)
  CALL ApiVector09
  LD (MissionHeader+$2183),HL
  LD (MissionHeader+$218B),HL
  CALL NegHL
  LD (MissionHeader+$217F),HL
  LD (MissionHeader+$2187),HL
  POP HL
  LD A,(IX+$00)
  CALL ApiVector09
  LD (data_FEBB+$008D),HL
  LD (data_FEBB+$0095),HL
  CALL NegHL
  LD (data_FEBB+$0089),HL
  LD (data_FEBB+$0091),HL
  LD HL,$0000
  LD (MissionHeader+$217D),HL
  LD (MissionHeader+$227D),HL
  LD (data_FEBB+$0087),HL
  INC IX
  JP BoxHeights

; Native (half angle, radius, height): the same rectangle box with 8-bit
; corners (Sine8, MulFrac)
;
; The mission vector `$67F7`; the most used box (bank 3 models, mission 1: 22
; of 31 models).
;
; Witness: L1 14991 (armour, c1, controls, death, fuel, m10, m1complete,
; m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).
BoxRect:
  POP DE
  LD (l_AAF2+$0001),DE
  LD A,(MissionScore+$0005)
  LD B,(IX+$00)
  LD C,A
  ADD A,B
  INC IX
  EXX
  CALL ApiVector14
  LD E,(IX+$00)
  CALL MulFrac
  LD (MissionHeader+$2181),HL
  LD (MissionHeader+$2189),HL
  CALL NegHL
  LD (MissionHeader+$2185),HL
  LD (MissionHeader+$218D),HL
  EX AF,AF'
  LD E,(IX+$00)
  CALL MulFrac
  LD (data_FEBB+$008B),HL
  LD (data_FEBB+$0093),HL
  CALL NegHL
  LD (data_FEBB+$008F),HL
  LD (data_FEBB+$0097),HL
  EXX
  LD A,B
  NEG
  ADD A,C
  CALL ApiVector14
  LD E,(IX+$00)
  CALL MulFrac
  LD (MissionHeader+$2183),HL
  LD (MissionHeader+$218B),HL
  CALL NegHL
  LD (MissionHeader+$217F),HL
  LD (MissionHeader+$2187),HL
  EX AF,AF'
  LD E,(IX+$00)
  CALL MulFrac
  LD (data_FEBB+$008D),HL
  LD (data_FEBB+$0095),HL
  CALL NegHL
  LD (data_FEBB+$0089),HL
  LD (data_FEBB+$0091),HL
  INC IX
  LD HL,$0000
  LD (MissionHeader+$217D),HL
  LD (MissionHeader+$227D),HL
  LD (data_FEBB+$0087),HL
  JP BoxHeights

; Spare byte; the pitch of BoxTilted (`$ABFE`, from the object record +`$2A` by
; DrawObject `$B827`)
BoxTiltPitch:
  DEFB $00,$00

; Native (half angle, radius, height): a rectangle box turned by the heading,
; the pitch `$ABFE` and the roll `$68E6`
;
; Rotates each corner pair with RotatePair `$AD06` (sine and cosine of the roll
; in `$AD04`); sets V0 = 0. Called from OpNative in death and play2 (a tilted
; vehicle).
;
; Witness: L1 1818 (armour, death, m1complete, m4complete, play2).
BoxTilted:
  POP DE
  LD (BoxTilted+$0103),DE
  LD B,(IX+$00)
  INC IX
  LD A,(BoxTiltPitch+$0001)
  ADD A,B
  CALL ApiVector14
  LD E,(IX+$00)
  CALL MulFrac
  LD (MissionHeader+$2187),HL
  LD (MissionHeader+$2189),HL
  EX AF,AF'
  LD E,(IX+$00)
  CALL MulFrac
  LD (MissionHeader+$2287),HL
  LD (MissionHeader+$2289),HL
  CALL NegHL
  LD (MissionHeader+$2283),HL
  LD (MissionHeader+$2285),HL
  LD A,(BoxTiltPitch+$0001)
  LD E,(IX+$00)
  AND A
  SBC A,E
  CALL ApiVector14
  LD E,(IX+$00)
  CALL MulFrac
  LD (MissionHeader+$218B),HL
  EX AF,AF'
  LD E,(IX+$00)
  INC IX
  CALL MulFrac
  LD (MissionHeader+$228D),HL
  LD (MissionHeader+$228B),HL
  CALL NegHL
  LD (MissionHeader+$227F),HL
  LD (MissionHeader+$2281),HL
  LD HL,(MissionScore+$0004)
  CALL SinCosHalf
  LD D,A
  LD (RollSinCos),DE
  LD B,(IX+$00)
  LD A,(MissionHeader+$2189)
  LD C,A
  CALL RotatePair
  LD (MissionHeader+$2189),HL
  CALL NegHL
  LD (MissionHeader+$2185),HL
  EX DE,HL
  LD (data_FEBB+$0093),HL
  CALL NegHL
  LD (data_FEBB+$008F),HL
  LD B,(IX+$00)
  LD A,(MissionHeader+$218B)
  LD C,A
  CALL RotatePair
  LD (MissionHeader+$218B),HL
  CALL NegHL
  LD (MissionHeader+$217F),HL
  EX DE,HL
  LD (data_FEBB+$0095),HL
  CALL NegHL
  LD (data_FEBB+$0089),HL
  LD A,(IX+$00)
  INC IX
  NEG
  LD B,A
  LD A,(MissionHeader+$2187)
  LD C,A
  CALL RotatePair
  LD (MissionHeader+$2187),HL
  CALL NegHL
  LD (MissionHeader+$2183),HL
  EX DE,HL
  LD (data_FEBB+$0091),HL
  CALL NegHL
  LD (data_FEBB+$008D),HL
  LD HL,(MissionHeader+$218B)
  LD DE,(MissionHeader+$2189)
  AND A
  SBC HL,DE
  LD DE,(MissionHeader+$2187)
  ADD HL,DE
  LD (MissionHeader+$218D),HL
  CALL NegHL
  LD (MissionHeader+$2181),HL
  LD HL,(data_FEBB+$0095)
  LD DE,(data_FEBB+$0093)
  AND A
  SBC HL,DE
  LD DE,(data_FEBB+$0091)
  ADD HL,DE
  LD (data_FEBB+$0097),HL
  CALL NegHL
  LD (data_FEBB+$008B),HL
  LD HL,$0000
  LD (MissionHeader+$213B),HL
  LD (MissionHeader+$223B),HL
  LD (data_FEBB+$0045),HL
  JP $0000

; The sine and cosine of the roll for RotatePair
RollSinCos:
  DEFB $00,$00

; Turn the pair (B, C) by the angle in `$AD04`: HL, DE = the two rotated words
;
; Witness: L1 5454 (armour, death, m1complete, m4complete, play2).
RotatePair:
  LD DE,(RollSinCos)
  LD A,E
  EX AF,AF'
  LD A,B
  EXX
  LD E,A
  EX AF,AF'
  CALL MulFrac
  LD (RotatePair+$003A),HL
  EXX
  LD A,D
  EX AF,AF'
  LD A,B
  EXX
  LD E,A
  EX AF,AF'
  CALL MulFrac
  LD (RotatePair+$0029),HL
  EXX
  LD A,E
  EX AF,AF'
  LD A,C
  EXX
  LD E,A
  EX AF,AF'
  CALL MulFrac
  EX DE,HL
  LD HL,$0000
  AND A
  SBC HL,DE
  PUSH HL
  EXX
  LD A,D
  EX AF,AF'
  LD A,C
  EXX
  LD E,A
  EX AF,AF'
  CALL MulFrac
  LD DE,$0000
  ADD HL,DE
  POP DE
  RET
