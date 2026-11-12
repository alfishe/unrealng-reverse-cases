; --------------------------------------------------------------------------------------------------------------------
; rhombi.asm: The four corner rhombi: their 34 phases built at the start, printed one step at a time
;
; The rhombus (RombSource $6E98, src/res/graphics/rhombus.png) is a 40x40 sprite: 5 bytes a row, 40 rows. Its turn is
; faked by dropping columns: phase k (0-7) keeps 40 - 5k of the 40 pixel columns, dropped in the order RombColumnOrder
; $6B74 gives, packed together and placed RombPhaseOffsets[8 - k] pixels from the left so the narrowed picture stays
; centred. Phase 8 is the rhombus edge-on, phases 9-16 the mirror images of phases 0-7 (the back face). PhaseOrder
; $6ADD walks 32 steps: 0-7, 8, 16-9, 10-16, 8, 7-1: a full turn.
;
; Phase 8 is drawn only where a column's order value is at or above the threshold ($40 for set A, $80 for set B); the
; values are 0-39, so phase 8 stays the blank sprite the loader's clear left: the rhombus vanishes edge-on (known only
; from the code).
; --------------------------------------------------------------------------------------------------------------------

; Build phases 0-7 and the edge-on phase 8 of the rhombus in RombWork, at DE
; (256 bytes a phase)
;
; In: DE = the set's base (PhasesA $7800 or PhasesB $8A00), RombThreshold
; $768E. For each phase (C = 8 down to 1) and each of the 40 rows:
; ClearPhaseMask $633B sets PhaseOffset $76C0 = RombOffsets[C] and clears
; PhaseMask $7698; the first 5 x C entries of RombColumns mark their columns in
; PhaseMask (MarkPhaseColumn $6354); ScaleRombLine $6364 writes the row. Each
; phase starts at the next 256 bytes (D + 1, E = 0).
;
; Then phase 8 at DE: for each row k, $18 at byte 2 when RombColumns[k] >= the
; threshold (never: see the module's header).
;
; Witness: L1 8 (c x4).
BuildRombPhases:
  LD IY,RombOffsets
  LD C,$08
BuildPhase:
  LD HL,RombWork
  LD B,$28
BuildPhaseRow:
  LD IX,RombColumns
  CALL ClearPhaseMask
  PUSH BC
MarkColumns:
  LD B,$05                ; mark the first 5 x C columns
MarkColumn:
  LD A,(IX+$00)
  AND $3F
  CALL MarkPhaseColumn
  INC IXL
  DJNZ MarkColumn
  DEC C
  JR NZ,MarkColumns
  POP BC
  CALL ScaleRombLine
  DJNZ BuildPhaseRow
  INC D
  LD E,$00
  DEC C
  JR NZ,BuildPhase
  EX DE,HL
  LD DE,RombColumns
  LD A,(RombThreshold)
  LD B,A
EdgeOnRow:
  INC L                   ; phase 8: the edge-on line
  INC L
  LD A,(DE)
  CP B
  JR C,EdgeOnNext
  LD (HL),$18
EdgeOnNext:
  INC L
  INC L
  INC L
  INC E
  LD A,L
  CP $C8
  JR NZ,EdgeOnRow
  RET

; Clear PhaseMask and set PhaseOffset to RombOffsets[C]
;
; The offset's index is written into the LD A,(IY+d) at $634D (IY = RombOffsets
; $765C).
;
; Witness: L1 2560 (c x4).
ClearPhaseMask:
  EXX
  LD HL,PhaseMask
  LD DE,PhaseMask+$0001
  LD BC,$0027
  LD (HL),B
  LDIR
  EXX
  LD A,C
  LD (ClearPhaseIndex+$0002),A
ClearPhaseIndex:
  LD A,(IY+$00)
  LD (PhaseOffset),A
  RET

; PhaseMask[A] = 1: column A is kept in this phase
;
; The index is written into the LD (IX+d),1 at $635D.
;
; Witness: L1 57600 (c x4).
MarkPhaseColumn:
  PUSH IX
  LD IX,PhaseMask
  LD (MarkPhaseWrite+$0002),A
MarkPhaseWrite:
  LD (IX+$00),$01
  POP IX
  RET

; Copy one 40-pixel row of the rhombus to the phase: only the marked columns,
; packed, from PhaseOffset on
;
; In: HL = the source row, DE = the phase row, PhaseMask $7698, PhaseOffset
; $76C0 (bits 7-3 the byte, 2-0 the pixel). For each of the 40 source pixels
; whose PhaseMask byte is 1, writes the pixel (SET or RES, the opcode built
; into the instruction at $63AD) at the next destination pixel. Returns HL and
; DE 5 bytes on (the next row).
;
; Witness: L1 2560 (c x4).
ScaleRombLine:
  PUSH BC
  PUSH IY
  PUSH DE
  PUSH HL
  POP IX
  PUSH HL
  LD A,(PhaseOffset)
  AND $F8
  RRCA
  RRCA
  RRCA
  LD C,A
  LD B,$00
  EX DE,HL
  ADD HL,BC
  PUSH HL
  POP IY
  LD HL,PhaseMask
  LD A,(PhaseOffset)
  AND $07
  LD C,A
  LD A,$07
  SUB C
  LD C,A
  LD D,$05
ScaleNextByte:
  LD E,$7E                ; the next source byte
ScaleNextBit:
  LD A,E                  ; the next source bit: the BIT n,(IX) at $6392 built
                          ; from E
  LD (ScaleTestBit+$0003),A
  XOR A
ScaleTestBit:
  BIT 0,(IX+$00)
  JR Z,ScaleHaveBit
  LD A,$40
ScaleHaveBit:
  EX AF,AF'
  LD A,(HL)
  CP $01
  JR NZ,ScaleSkipBit
  LD B,$86
  EX AF,AF'
  OR B
  LD B,A
  LD A,C
  RLCA
  RLCA
  RLCA
  OR B
  LD (ScaleWriteBit+$0003),A
ScaleWriteBit:
  RES 0,(IY+$00)          ; RES / SET n,(IY+0): the opcode written above
  DEC C
  LD A,C
  CP $FF
  JR NZ,ScaleSkipBit
  INC IYL
  LD C,$07
ScaleSkipBit:
  INC L
  LD A,E
  SUB $08
  LD E,A
  CP $3E
  JR NZ,ScaleNextBit
  INC IX
  DEC D
  JR NZ,ScaleNextByte
  POP HL
  POP DE
  LD BC,$0005
  ADD HL,BC
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  POP IY
  POP BC
  RET

; Write the mirror image (left to right) of the 40x40 sprite at HL to DE
;
; Reverses the 5 bytes of each row and the bits of each byte (MirrorByte
; $6419). HL = DE is allowed (FlipSprite $6E35 uses it so).
;
; Witness: L1 80 (c x4).
MirrorSprite:
  PUSH HL
  POP IX
  PUSH DE
  POP IY
  LD B,$28
MirrorRow:
  PUSH BC
  LD C,(IX+$00)
  CALL MirrorByte
  LD A,(IX+$04)
  LD (IY+$04),C
  LD C,A
  CALL MirrorByte
  LD (IY+$00),C
  LD C,(IX+$01)
  CALL MirrorByte
  LD A,(IX+$03)
  LD (IY+$03),C
  LD C,A
  CALL MirrorByte
  LD (IY+$01),C
  LD C,(IX+$02)
  CALL MirrorByte
  LD (IY+$02),C
  LD BC,$0005
  ADD IX,BC
  ADD IY,BC
  POP BC
  DJNZ MirrorRow
  RET

; Reverse the bits of C
;
; Witness: L1 16000 (c x4).
MirrorByte:
  LD B,$08
MirrorByteBit:
  RR C
  RLA
  DJNZ MirrorByteBit
  LD C,A
  RET

; Turn the 40x40 sprite at HL by 90 degrees (through RotateBuffer $9C00)
;
; For each of the 40 source columns (left to right), shifts the column's 40
; pixels into one 40-pixel row of RotateBuffer $9C00, then copies the 200 bytes
; back to HL. Called 3 times on RombWork, 17 times on set B, twice by
; FlipSprite for each logo sprite.
;
; Witness: L1 112 (c x4).
RotateSprite:
  PUSH HL
  LD DE,RotateBuffer
  LD B,$05
RotateColumnByte:
  PUSH BC
  PUSH HL
  LD B,$08
RotateColumnBit:
  PUSH BC
  PUSH HL
  LD B,$28
RotateSourceRow:
  PUSH BC
  RL (HL)
  PUSH DE
  LD B,$05
RotateShiftRow:
  LD A,(DE)
  RRA
  LD (DE),A
  INC E
  DJNZ RotateShiftRow
  POP DE
  LD BC,$0005
  ADD HL,BC
  POP BC
  DJNZ RotateSourceRow
  INC E
  INC E
  INC E
  INC E
  INC E
  POP HL
  POP BC
  DJNZ RotateColumnBit
  POP HL
  POP BC
  INC HL
  DJNZ RotateColumnByte
  POP DE
  PUSH DE
  LD HL,RotateBuffer
  LD BC,$00C8
  LDIR
  POP HL
  RET

  ORG $64DA

; Print the rhombus at its step (BC) at HL from the phase set at DE, and
; advance the step
;
; The phase is PhaseOrder[(BC)], its sprite DE + 256 x phase; PrintSprite
; $64F4. The step (BC) + 1, modulo 32.
;
; Witness: L1 20744 (c x4).
PrintRombPhase:
  LD A,(BC)
  PUSH BC
  LD C,A
  LD B,$00
  LD IX,PhaseOrder
  ADD IX,BC
  LD A,(IX+$00)
  ADD A,D
  LD D,A
  CALL PrintSprite
  POP HL
  LD A,(HL)
  INC A
  AND $1F
  LD (HL),A
  RET

; Print a 40x40 sprite from DE to the screen at HL (5 cells across, 5 down)
;
; Plain copy (no masking). Used for the rhombi, the logo and, into ScreenCopy,
; the reflection.
;
; Witness: L1 20792 (c x4).
PrintSprite:
  LD B,$05
PrintSpriteCellRow:
  PUSH BC
  LD B,$08
PrintSpriteLine:
  PUSH BC
  LD BC,$0005
  EX DE,HL
  LDIR
  EX DE,HL
  LD BC,$00FB
  ADD HL,BC
  POP BC
  DJNZ PrintSpriteLine
  LD BC,-2048+32
  ADD HL,BC
  POP BC
  DJNZ PrintSpriteCellRow
  RET

  ORG $6ADD

; The rhombus phase shown at each of the 32 steps of a turn
;
; Read by PrintRombPhase $64DA.
PhaseOrder:
  INCBIN "res/tables/phase-order.bin",$0000,32

  ORG $6B74

; The 40 rhombus columns in the order the phases keep them (5 fewer a phase)
;
; Copied to RombColumns $7600 by Start.
RombColumnOrder:
  INCBIN "res/tables/rhombus-columns.bin",$0000,40

; Per phase, where its narrowed rhombus starts (the pixel column)
;
; Copied to RombOffsets $765C by Start.
RombPhaseOffsets:
  INCBIN "res/tables/rhombus-offsets.bin",$0000,9

  ORG $6E98

; The rhombus: 40x40, 5 bytes a row
;
; Printed by DrawScreen and copied to RombWork by Start.
RombSource:
  INCBIN "res/graphics/rhombus.bin",$0000,200
