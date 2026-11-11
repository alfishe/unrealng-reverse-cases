; --------------------------------------------------------------------------------------------------------------------
; enemies.asm: The four enemies
;
; An enemy appears on a random free 2 x 2 cell block in the play area (MoveEnemy's spawn), materialises over four
; frames, then flies diagonally, bouncing off the walls and the edges, one step every second pass. Its sprite's flag
; byte is its state: when the interrupt's XOR draws it over ink (the droid, a shot), bit 7 is set and it explodes,
; then waits to come back. Its mark 2 in the cells is what the droid's touch test reads as the fast energy drain.
; --------------------------------------------------------------------------------------------------------------------

; The next of the nine enemy kinds: its frame count and graphics
;
; EnemyKindTurn cycles 1-9; DrawMode ($63B1) = EnemyFrameCounts[kind], HL = the
; kind's EnemyGraphics word. L1 403.
EnemyKind:
  LD A,(EnemyKindTurn)
  INC A
  CP $0A
  JR NZ,EnemyKindSet
  LD A,$01
EnemyKindSet:
  LD (EnemyKindTurn),A
  LD E,A
  LD D,$00
  LD HL,EnemyFrameCounts-1
  ADD HL,DE
  LD A,(HL)
  LD (DrawMode),A
  SLA E
  LD HL,EnemyGraphics-2
  ADD HL,DE
  RET

; One step of an enemy: spawn, materialise, fly, explode
;
; In: HL the record, EnemyBufferPtrs. A record with timer 0 is empty. The timer
; counts down; at 0 it is 2 again and the enemy acts (L1 11 212 of 74 324
; calls). Spawn (state $40): x and y from the 13 x 4 lattice (x Random OR $20
; AND $F8, $E0-$F8 clamped to $D0; y Random OR $50 AND $78) until the 2 x 2
; cells are 0 (720 tries, 581 spawns), the attribute Random AND 7 OR $42 ($42,
; $43, $46 or $47). Each act: the old frame (the draw buffer) is queued to
; erase and the mark 2 XORed out. Hit (state bit 7): ExplosionFrames, one
; explosion frame an act (the state steps by 4); the mark is not XORed back, so
; the cells hold 2 only after the 2nd and 4th act; then state $40 and the timer
; random OR $29 (202 explosions end). Materialising (bit 6): MaterialiseFrames,
; the mark XORed again (2 x 2), so the cells stay clean; then a random
; direction and the next kind (EnemyKind: 403). Flying: state 0 right and down,
; 1 left and down, 2 left and up, 3 right and up; a blocked step flips that
; half of the direction (StepRight / StepLeft and StepDown / StepUp, 2 x 2
; cells, x up to $F0, y up to $B0). The next frame (49 bytes on) is shifted to
; x AND 7 in place (ShiftGraphic3), copied to the erase buffer and queued with
; the state as its flag byte, the mark 2 XORed in and the attributes set.
;
; Witness: L1 74 324 calls, 7 790 flights, 1 071 explosion steps, 2 352
; materialise steps.
MoveEnemy:
  XOR A
  CP (HL)
  RET Z
  DEC (HL)
  RET NZ
  LD (HL),$02
  LD DE,$0008
  ADD HL,DE
  LD A,(HL)
  LD (DrawMode),A
  SCF
  CCF
  SBC HL,DE
  LD A,$02
  LD (StepX),A
  LD (StepY),A
  LD A,$F0
  LD (StepWidth),A
  LD A,$B0
  LD (StepHeight),A
  INC HL
  LD D,H
  LD E,L
  LD A,(HL)
  AND $FC
  CP $40
  JR NZ,MoveEnemyPlace
  PUSH HL
  PUSH DE
  LD DE,$001F
MoveEnemySpawn:
  CALL Random
  OR $20
  AND $F8
  CP $D0
  JR C,MoveEnemySpawnY
  LD A,$D0
MoveEnemySpawnY:
  LD C,A
  CALL Random
  OR $50
  AND $78
  LD B,A
  CALL CellAddrXY
  XOR A
  CP (HL)
  JR NZ,MoveEnemySpawn
  INC L
  CP (HL)
  JR NZ,MoveEnemySpawn
  ADD HL,DE
  CP (HL)
  JR NZ,MoveEnemySpawn
  INC L
  CP (HL)
  JR NZ,MoveEnemySpawn
  POP DE
  POP HL
  INC HL
  LD (HL),C
  INC HL
  LD (HL),B
  PUSH HL
  INC HL
  INC HL
  INC HL
  INC HL
  INC HL
  CALL Random
  AND $07
  OR $42
  LD (HL),A
  POP HL
  JR MoveEnemyErase
MoveEnemyPlace:
  INC HL
  LD C,(HL)
  INC HL
  LD B,(HL)
MoveEnemyErase:
  PUSH HL
  PUSH DE
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  LD A,C
  AND $07
  PUSH BC
  CALL ShiftGraphic3
  INC HL
  LD DE,(EnemyBufferPtrs+$0002)
  LD BC,$0030
  LDIR
  POP BC
  LD DE,(EnemyBufferPtrs+$0002)
  LD HL,(SpriteListEnd)
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),$03
  INC HL
  LD (HL),$02
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
  LD B,$02
  JR Z,MoveEnemyEraseCols
  INC B
MoveEnemyEraseCols:
  LD A,C
  AND $07
  LD C,$02
  JR Z,MoveEnemyEraseMark
  INC C
MoveEnemyEraseMark:
  LD A,$02
  CALL XorCells
  POP DE
  POP HL
  LD A,(DE)
  BIT 7,A
  JP NZ,MoveEnemyExplode
  BIT 6,A
  JP NZ,MoveEnemyMaterialise
  LD BC,$0000
  LD (FoundItem),BC
  DEC HL
  CP $00
  JR NZ,MoveEnemyState1
  CALL StepRight
  JR NZ,MoveEnemyDownRight
  LD A,$01
  LD (DE),A
MoveEnemyDownRight:
  INC HL
  CALL StepDown
  JR NZ,MoveEnemyDraw
  LD A,$03
  LD (DE),A
  JR MoveEnemyDraw
MoveEnemyState1:
  CP $01
  JR NZ,MoveEnemyState2
  CALL StepLeft
  JR NZ,MoveEnemyDownLeft
  XOR A
  LD (DE),A
MoveEnemyDownLeft:
  INC HL
  CALL StepDown
  JR NZ,MoveEnemyDraw
  LD A,$02
  LD (DE),A
  JR MoveEnemyDraw
MoveEnemyState2:
  CP $02
  JR NZ,MoveEnemyState3
  CALL StepLeft
  JR NZ,MoveEnemyUpLeft
  LD A,$03
  LD (DE),A
MoveEnemyUpLeft:
  INC HL
  CALL StepUp
  JR NZ,MoveEnemyDraw
  LD A,$01
  LD (DE),A
  JR MoveEnemyDraw
MoveEnemyState3:
  CALL StepRight
  JR NZ,MoveEnemyUpRight
  LD A,$02
  LD (DE),A
MoveEnemyUpRight:
  INC HL
  CALL StepUp
  JR NZ,MoveEnemyDraw
  XOR A
  LD (DE),A
MoveEnemyDraw:
  LD B,(HL)
  DEC HL
  LD C,(HL)
  PUSH DE
  INC HL
  INC HL
  PUSH HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  INC (HL)
  LD A,(HL)
  INC HL
  CP (HL)
  JR NZ,MoveEnemyNextFrame
  DEC HL
  LD (HL),$00
  DEC A
  EX DE,HL
  LD DE,$0031
  SCF
  CCF
MoveEnemyFirstFrame:
  SBC HL,DE
  DEC A
  JR NZ,MoveEnemyFirstFrame
  JR MoveEnemyShift
MoveEnemyNextFrame:
  LD HL,$0031
  ADD HL,DE
MoveEnemyShift:
  LD A,C
  AND $07
  PUSH BC
  CALL ShiftGraphic3
  POP BC
  EX DE,HL
  POP HL
  LD (HL),E
  INC HL
  LD (HL),D
  INC DE
  EX DE,HL
  PUSH BC
  LD DE,(EnemyBufferPtrs)
  LD BC,$0030
  LDIR
  POP BC
  LD DE,(EnemyBufferPtrs)
  LD HL,(SpriteListEnd)
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  POP DE
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (HL),$03
  INC HL
  LD (HL),$02
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
  LD B,$02
  JR Z,MoveEnemyMarkCols
  INC B
MoveEnemyMarkCols:
  LD A,C
  AND $07
  LD C,$02
  JR Z,MoveEnemyMark
  INC C
MoveEnemyMark:
  LD A,$02
  PUSH BC
  PUSH HL
  CALL XorCells
  POP HL
  LD A,H
  AND $03
  OR $58
  LD H,A
  POP BC
  LD A,(DrawMode)
  CALL FillAttr
  RET
MoveEnemyExplode:
  ADD A,$04
  LD (DE),A
  AND $FC
  CP $94
  JR NZ,MoveEnemyExplodeFrame
  LD A,$40
  LD (DE),A
  CALL Random
  DEC DE
  OR $29
  LD (DE),A
  EX DE,HL
  INC HL
  INC HL
  INC HL
  INC HL
  LD DE,BlankGraphic
  LD (HL),E
  INC HL
  LD (HL),D
  RET
MoveEnemyExplodeFrame:
  SUB $04
  RES 7,A
  SRL A
  LD HL,ExplosionFrames
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
  LD A,C
  AND $07
  PUSH BC
  EX DE,HL
  CALL ShiftGraphic3
  POP BC
  EX DE,HL
  INC HL
  LD (HL),E
  INC HL
  LD (HL),D
  INC DE
  EX DE,HL
  LD DE,(EnemyBufferPtrs)
  LD BC,$0030
  LDIR
  LD DE,(EnemyBufferPtrs)
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
MoveEnemyMaterialise:
  ADD A,$04
  LD (DE),A
  AND $FC
  CP $54
  JR NZ,MoveEnemyMaterialiseFrame
  CALL Random
  AND $03
  LD (DE),A
  PUSH DE
  CALL EnemyKind
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  XOR A
  CALL ShiftGraphic3
  EX DE,HL
  POP HL
  INC HL
  INC HL
  INC HL
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (HL),$00
  INC HL
  LD A,(DrawMode)
  LD (HL),A
  JR MoveEnemyQueue
MoveEnemyMaterialiseFrame:
  SUB $04
  RES 6,A
  SRL A
  LD HL,MaterialiseFrames
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
  PUSH DE
  CALL CellAddrXY
  LD BC,$0202
  LD A,$02
  PUSH HL
  CALL XorCells
  POP HL
  LD A,H
  AND $03
  OR $58
  LD H,A
  LD BC,$0202
  LD A,(DrawMode)
  CALL FillAttr
  POP DE
  POP HL
  INC HL
  DEC DE
  LD (HL),E
  INC HL
  LD (HL),D
MoveEnemyQueue:
  INC DE
  EX DE,HL
  LD DE,(EnemyBufferPtrs)
  LD BC,$0030
  LDIR
  LD DE,(EnemyBufferPtrs)
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
