; --------------------------------------------------------------------------------------------------------------------
; exhaust.asm: The droid's exhaust flicker
; --------------------------------------------------------------------------------------------------------------------

; XOR the exhaust rows under the droid (8 pixel rows of 3 bytes)
;
; Five character rows under the droid's top (one column on when it faces left
; and walks); not below the screen. Each byte goes where the cell is no wall
; and holds no item, and the cell's attribute becomes $45. MainLoop calls it
; before and after MoveDroid, so the old flicker is erased and the new one
; drawn (L1 37 128).
DroidExhaust:
  LD BC,(DroidVars)
  CALL ScreenAddr
  LD A,(DroidFrame)
  CP $0C
  JR Z,DroidExhaustRows
  LD A,(DroidFlags)
  BIT 0,A
  JR Z,DroidExhaustRows
  BIT 1,A
  JR NZ,DroidExhaustRows
  INC E
DroidExhaustRows:
  LD L,E
  LD H,D
  LD A,L
  ADD A,$A0
  LD L,A
  JR NC,DroidExhaustDraw
  LD A,H
  ADD A,$08
  LD H,A
DroidExhaustDraw:
  LD A,H
  CP $58
  RET NC
  LD A,(DroidWidth)
  LD (DrawMode),A
  LD A,H
  RRCA
  RRCA
  RRCA
  AND $03
  OR $60
  LD B,A
  LD C,L
  LD (MoverScratch),BC
  LD B,$08
  LD A,L
  AND $E0
  CP $E0
  JR NZ,DroidExhaustStart
  LD A,H
  AND $18
  CP $10
  JR NZ,DroidExhaustStart
  LD A,H
  AND $07
  JR Z,DroidExhaustStart
  NEG
  AND $07
  LD B,A
DroidExhaustStart:
  LD DE,ExhaustRows
DroidExhaustRow:
  PUSH BC
  PUSH HL
  PUSH DE
  LD BC,(MoverScratch)
  LD A,(DrawMode)
DroidExhaustByte:
  PUSH AF
  LD A,(BC)
  CP $01
  JR Z,DroidExhaustNext
  BIT 7,A
  JR NZ,DroidExhaustNext
  LD A,(DE)
  XOR (HL)
  LD (HL),A
  LD A,B
  XOR $38
  LD B,A
  LD A,$45
  LD (BC),A
  LD A,B
  XOR $38
  LD B,A
DroidExhaustNext:
  INC DE
  INC L
  INC C
  POP AF
  DEC A
  JR NZ,DroidExhaustByte
  POP DE
  INC DE
  INC DE
  INC DE
  POP HL
  INC H
  LD A,H
  AND $07
  JR NZ,DroidExhaustRowNext
  LD BC,(MoverScratch)
  LD A,C
  ADD A,$20
  LD C,A
  JR NC,DroidExhaustCellRow
  INC B
DroidExhaustCellRow:
  LD (MoverScratch),BC
  LD A,L
  ADD A,$20
  LD L,A
  JR C,DroidExhaustRowNext
  LD A,H
  SUB $08
  LD H,A
DroidExhaustRowNext:
  POP BC
  DJNZ DroidExhaustRow
  RET

; Rotate the four exhaust rows' patterns and mask them
;
; ExhaustRow for rows 1 and 3, ExhaustRowLeft for rows 2 and 4 (the patterns
; run apart), then ExhaustMask. L1 18 571.
ExhaustStep:
  LD HL,ExhaustRaw
  LD (MoverScratch),HL
  LD HL,(ExhaustPtrs)
  CALL ExhaustRow
  LD (ExhaustPtrs),HL
  LD HL,(ExhaustPtrs+$0002)
  CALL ExhaustRowLeft
  LD (ExhaustPtrs+$0002),HL
  LD HL,(ExhaustPtrs+$0004)
  CALL ExhaustRow
  LD (ExhaustPtrs+$0004),HL
  LD HL,(ExhaustPtrs+$0006)
  CALL ExhaustRowLeft
  LD (ExhaustPtrs+$0006),HL
  CALL ExhaustMask
  RET

; A random free pattern record for a row whose counter ran out
;
; L1 5 012 tries, 3 134 picks: Random AND $1C picks one of the eight
; ExhaustPatterns until its counter is 0, which becomes 8-39.
ExhaustPick:
  CALL Random
  AND $1C
  LD HL,ExhaustPatterns
  LD D,$00
  LD E,A
  ADD HL,DE
  LD A,(HL)
  CP $00
  JR NZ,ExhaustPick
  CALL Random
  AND $1F
  ADD A,$09
  DEC A
  LD (HL),A
  RET

; Rotate a pattern one pixel right into the next ExhaustRaw row
;
; L1 37 142.
ExhaustRow:
  DEC (HL)
  CALL Z,ExhaustPick
  INC HL
  LD B,$03
  PUSH HL
  SCF
ExhaustRowRotate:
  RR (HL)
  INC HL
  DJNZ ExhaustRowRotate
  PUSH AF
  LD HL,(MoverScratch)
  LD B,$03
ExhaustRowCopy:
  RR (HL)
  INC HL
  DJNZ ExhaustRowCopy
  LD (MoverScratch),HL
  POP AF
  POP HL
  JR C,ExhaustRowDone
  RES 7,(HL)
ExhaustRowDone:
  DEC HL
  RET

; Rotate a pattern one pixel left into the next ExhaustRaw row
;
; L1 37 142.
ExhaustRowLeft:
  DEC (HL)
  CALL Z,ExhaustPick
  LD DE,$0003
  ADD HL,DE
  LD B,$03
  PUSH HL
  SCF
  CCF
ExhaustRowLeftRotate:
  RL (HL)
  DEC HL
  DJNZ ExhaustRowLeftRotate
  PUSH AF
  LD HL,(MoverScratch)
  INC HL
  INC HL
  INC HL
  LD (MoverScratch),HL
  DEC HL
  LD B,$03
ExhaustRowLeftCopy:
  RL (HL)
  DEC HL
  DJNZ ExhaustRowLeftCopy
  POP AF
  POP HL
  JR NC,ExhaustRowLeftDone
  SET 0,(HL)
  AND A
ExhaustRowLeftDone:
  SCF
  CCF
  SBC HL,DE
  RET

; ExhaustRaw's four rows into ExhaustRows, masked by the droid's frame
;
; Frame 12 (DroidFly2, in the air) takes ExhaustMasks + 2 ($0F, $F0), every
; other frame $65D6. L1 18 572.
ExhaustMask:
  LD A,(DroidFrame)
  LD HL,ExhaustMasks
  CP $0B
  JR Z,ExhaustMaskRows
  LD HL,ExhaustMasks+$0002
  CP $0C
  JR Z,ExhaustMaskRows
  LD HL,ExhaustMasks
ExhaustMaskRows:
  LD BC,ExhaustRaw
  LD DE,ExhaustRows
  LD A,$04
ExhaustMaskRow:
  PUSH AF
  PUSH HL
  INC DE
  INC DE
  INC DE
  LD A,(BC)
  AND (HL)
  LD (DE),A
  INC BC
  INC DE
  INC HL
  LD A,(BC)
  AND $FF
  LD (DE),A
  INC BC
  INC DE
  LD A,(BC)
  AND (HL)
  LD (DE),A
  INC BC
  INC DE
  POP HL
  POP AF
  DEC A
  JR NZ,ExhaustMaskRow
  RET
