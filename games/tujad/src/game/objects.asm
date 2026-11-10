; --------------------------------------------------------------------------------------------------------------------
; objects.asm: The room's objects
; --------------------------------------------------------------------------------------------------------------------

; Move and draw one object; a shot of the right weapon kills it
;
; In: HL the record (Objects or Object2). Every other call (the timer in bits
; 0-1 of +0) the object moves: on its first pass in the room (state bit 6) it
; is only drawn; otherwise the old image goes to the sprite list (graphic + 1,
; 4 bytes x 3 character rows), its mark 4 is XORed out of its cells and the
; cells under it are ORed into ObjectBits. A shot's mark there (bit 0): the
; cells zeroed; the weapon from AND $70, JP PO: one bit or all three kept as
; they are (three never match a kill mark: stopped), two bits ANDed with $60, 0
; becomes $10; the object's mark (+8) equal: it dies (state bit 7); else it
; stops (bit 5). A live object steps in its direction (StepRight, StepDown,
; StepLeft, StepUp: 3 x 3 cells, x up to $E8, y up to $A8) and reverses at a
; wall: state AND $FC + 2 after right (left), + 3 after down (up), + 0 after
; left (right), + 1 after up (down). The next frame (97 bytes on, back to the
; first after the last) is shifted to x AND 7 (ShiftGraphic4) and queued, the
; mark 4 XORed in, the attributes set. A dying object steps through
; ObjectDeathFrames, 4 passes a frame, then it is gone (BlankGraphic).
;
; Witness: L1 37 158 calls (2 for each of 18 579 passes), 1 777 moves, 13 hits,
; 11 kills.
MoveObject:
  LD A,(HL)
  AND $03
  CP $00
  RET Z
  LD A,(HL)
  DEC A
  LD (HL),A
  AND $03
  RET NZ
  SET 1,(HL)
  INC HL
  BIT 4,(HL)
  RET NZ
  LD DE,$0008
  ADD HL,DE
  LD A,(HL)
  LD (DrawMode),A
  SCF
  CCF
  SBC HL,DE
  LD A,$03
  LD (StepX),A
  LD (StepY),A
  LD A,$E8
  LD (StepWidth),A
  LD A,$A8
  LD (StepHeight),A
  BIT 6,(HL)
  JR Z,MoveObjectErase
  RES 6,(HL)
  LD D,H
  LD E,L
  INC HL
  INC HL
  JP MoveObjectDraw
MoveObjectErase:
  PUSH HL
  INC HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  PUSH HL
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC DE
  LD HL,(SpriteListEnd)
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),$04
  INC HL
  LD (HL),$03
  INC HL
  CALL ScreenAddrXY
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (SpriteListEnd),HL
  CALL CellAddrXY
  LD A,B
  AND $07
  LD B,$03
  JR Z,MoveObjectEraseCols
  INC B
MoveObjectEraseCols:
  LD A,C
  AND $07
  LD C,$03
  JR Z,MoveObjectEraseMark
  INC C
MoveObjectEraseMark:
  LD A,$04
  LD (ObjectScratch),HL
  LD (ObjectScratch+$0002),BC
  CALL XorCells
  LD DE,ObjectBits
  XOR A
  LD (DE),A
  LD HL,(ObjectScratch)
  LD BC,(ObjectScratch+$0002)
  CALL OrCells
  POP HL
  PUSH HL
  DEC HL
  DEC HL
  LD A,(ObjectBits)
  BIT 0,A
  JR Z,MoveObjectMove
  PUSH HL
  LD HL,(ObjectScratch)
  LD BC,(ObjectScratch+$0002)
  XOR A
  CALL XorCells
  POP HL
  LD A,(ObjectBits)
  AND $70
  JP PO,MoveObjectHitWeapon
  AND $60
MoveObjectHitWeapon:
  CP $00
  JR NZ,MoveObjectHitTest
  LD A,$10
MoveObjectHitTest:
  LD DE,$0007
  ADD HL,DE
  LD B,(HL)
  SCF
  CCF
  SBC HL,DE
  CP B
  JR Z,MoveObjectKilled
  SET 5,(HL)
  JR MoveObjectMove
MoveObjectKilled:
  SET 7,(HL)
MoveObjectMove:
  POP HL
  POP DE
  LD A,(DE)
  BIT 7,A
  JP NZ,MoveObjectDying
  BIT 5,A
  JR NZ,MoveObjectDraw
  DEC HL
  LD A,(DE)
  AND $03
  CP $00
  JR NZ,MoveObjectDown
  CALL StepRight
  INC HL
  JR NZ,MoveObjectDraw
  LD A,(DE)
  AND $FC
  ADD A,$02
  LD (DE),A
  JR MoveObjectDraw
MoveObjectDown:
  CP $01
  JR NZ,MoveObjectLeft
  INC HL
  CALL StepDown
  JR NZ,MoveObjectDraw
  LD A,(DE)
  AND $FC
  ADD A,$03
  LD (DE),A
  JR MoveObjectDraw
MoveObjectLeft:
  CP $02
  JR NZ,MoveObjectUp
  CALL StepLeft
  INC HL
  JR NZ,MoveObjectDraw
  LD A,(DE)
  AND $FC
  LD (DE),A
  JR MoveObjectDraw
MoveObjectUp:
  INC HL
  CALL StepUp
  JR NZ,MoveObjectDraw
  LD A,(DE)
  AND $FC
  ADD A,$01
  LD (DE),A
MoveObjectDraw:
  LD B,(HL)
  DEC HL
  LD C,(HL)
  INC HL
  INC HL
  PUSH DE
  PUSH HL
  LD A,(DE)
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  INC (HL)
  LD A,(HL)
  INC HL
  CP (HL)
  JR NZ,MoveObjectNextFrame
  DEC HL
  LD (HL),$00
  DEC A
  EX DE,HL
  LD DE,$0061
  SCF
  CCF
MoveObjectFirstFrame:
  SBC HL,DE
  DEC A
  JR NZ,MoveObjectFirstFrame
  JR MoveObjectShift
MoveObjectNextFrame:
  LD HL,$0061
  ADD HL,DE
MoveObjectShift:
  LD A,C
  AND $07
  PUSH BC
  CALL ShiftGraphic4
  POP BC
  EX DE,HL
  POP HL
  LD (HL),E
  INC HL
  LD (HL),D
  INC DE
  LD HL,(SpriteListEnd)
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  POP DE
  LD (HL),$00
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),$04
  INC HL
  LD (HL),$03
  INC HL
  CALL ScreenAddrXY
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (SpriteListEnd),HL
  CALL CellAddrXY
  LD A,B
  AND $07
  LD B,$03
  JR Z,MoveObjectMarkCols
  INC B
MoveObjectMarkCols:
  LD A,C
  AND $07
  LD C,$03
  JR Z,MoveObjectMark
  INC C
MoveObjectMark:
  LD A,$04
  PUSH BC
  PUSH HL
  CALL XorCells
  POP HL
  POP BC
  LD A,H
  AND $03
  OR $58
  LD H,A
  LD A,(DrawMode)
  CALL FillAttr
  RET
MoveObjectDying:
  LD A,(DE)
  RES 5,A
  ADD A,$04
  LD (DE),A
  AND $FC
  CP $90
  JR NZ,MoveObjectDeathFrame
  LD A,(DE)
  RES 7,A
  LD (DE),A
  PUSH HL
  LD HL,(ObjectScratch)
  LD BC,(ObjectScratch+$0002)
  XOR A
  CALL XorCells
  POP HL
  LD DE,BlankGraphic
  JR MoveObjectDeathDraw
MoveObjectDeathFrame:
  AND $0C
  SRL A
  LD HL,ObjectDeathFrames
  PUSH DE
  LD D,$00
  LD E,A
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  POP HL
  INC HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  PUSH HL
  EX DE,HL
  LD A,C
  AND $07
  CALL ShiftGraphic4
  EX DE,HL
  POP HL
MoveObjectDeathDraw:
  INC HL
  LD (HL),E
  INC HL
  LD (HL),D
  INC DE
  LD HL,(SpriteListEnd)
  LD (HL),E
  INC HL
  LD (HL),D
  LD BC,$0007
  SCF
  CCF
  SBC HL,BC
  LD DE,(SpriteListEnd)
  INC DE
  INC DE
  LD BC,$0006
  LDIR
  LD (SpriteListEnd),DE
  RET
