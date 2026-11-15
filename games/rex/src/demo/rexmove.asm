; --------------------------------------------------------------------------------------------------------------------
; rexmove.asm: Rex's moves: walk, jump, fall, the edges of the room
; --------------------------------------------------------------------------------------------------------------------

  ORG $D2D0

; The SPEED UP bonus: count down; the speed back at the end
;
; As REX 1's SpeedUpTick $CFCC (src/game/rexmove.asm).
;
; Known only from the code: no recording runs it.
;
; Witness: L1 0 ().
SpeedUpTick:
  LD A,(SpeedUpPhase)
  DEC A
  LD (SpeedUpPhase),A
  OR A
  RET NZ
  XOR A
  LD (SpeedUp),A
  RET

; Right: facing right, the speed set
;
; As REX 1's WalkRightKey $CFDA (src/game/rexmove.asm).
;
; Witness: L1 969 (d1, demo-cycle).
WalkRightKey:
  LD A,(SpeedUp)
  OR A
  JP Z,WalkRightFast
  LD A,$04
  LD (RexSpeed),A
  CALL SpeedUpTick
  JP WalkRightFacing
WalkRightFast:
  LD A,$02                ; SPEED UP: 2 pixels
  LD (RexSpeed),A
WalkRightFacing:
  XOR A
  LD (RexFacing),A
  RET

; Left: facing left, the speed set
;
; As REX 1's WalkLeftKey $CFF6 (src/game/rexmove.asm).
;
; Witness: L1 658 (d1, demo-cycle).
WalkLeftKey:
  LD A,(SpeedUp)
  OR A
  JP Z,WalkLeftFast
  LD A,$FC
  LD (RexSpeed),A
  CALL SpeedUpTick
  JP WalkLeftFacing
WalkLeftFast:
  LD A,$FE
  LD (RexSpeed),A
WalkLeftFacing:
  LD A,$01
  LD (RexFacing),A
  RET

; Move Rex by RexSpeed in his facing unless a solid cell; at the edges ExitLeft
; / ExitRight
;
; As REX 1's RexWalk $D013 (src/game/rexmove.asm).
;
; Witness: L1 6540 (d1, demo-cycle).
RexWalk:
  LD A,(RexFacing)
  OR A
  JP Z,RexWalkRightCell
  JP RexWalkLeftCell
RexWalkStep:
  LD A,(RexX)
  LD HL,RexSpeed
  ADD A,(HL)
  CP $F0
  JP NC,ExitRight
  LD (RexX),A
  LD A,(Jumping)
  OR A
  RET NZ
  LD A,(FallSpeed)
  OR A
  RET NZ
  XOR A
  LD (RexSpeed),A
  RET
RexWalkRightCell:
  LD HL,(RexCellPtr)
  LD DE,$0023
  ADD HL,DE
  CALL IsSolid
  RET Z
  LD DE,$0020
  ADD HL,DE
  CALL IsSolid
  RET Z
  JP RexWalkStep
RexWalkLeftCell:
  LD HL,(RexCellPtr)
  LD DE,$0020
  ADD HL,DE
  CALL IsSolid
  RET Z
  LD DE,$0020
  ADD HL,DE
  CALL IsSolid
  RET Z
  JP RexWalkStep

; Z if the cell at HL is solid (SolidCells: 2, 4, 5, 6, 9); the type found in A
;
; Changed from REX 1's IsSolid $D06C (src/game/rexmove.asm).
;
; Witness: L1 32693 (d1, demo-cycle).
IsSolid:
  PUSH HL
  PUSH BC
  LD A,(HL)
  LD B,$05
  LD HL,SolidCells

; Z if A is one of B values at DE
;
; As REX 1's InList $D074 (src/game/rexmove.asm).
;
; Witness: L1 81499 (d1, demo-cycle).
InList:
  LD C,$FF
InListLoop:
  CPI
  JP Z,InListFound
  DJNZ InListLoop
  POP BC
  POP HL
  LD A,$01
  OR A
  LD A,$00
  RET
InListFound:
  XOR A
  DEC HL
  LD A,(HL)
  POP BC
  POP HL
  RET

; Z if the cell at HL lets a body or a bullet through (PassCells $D39A: 0,
; $0E-$12, $14)
;
; Changed from REX 1's IsPassable $D08B (src/game/rexmove.asm).
;
; Witness: L1 48806 (d1, demo-cycle).
IsPassable:
  PUSH HL
  PUSH BC
  LD A,(HL)
  LD B,$07
  LD HL,PassCells
  JP InList

; The solid cell types 2, 4, 5, 6, 9 (IsSolid), then PassCells $D39A: 0, $0E,
; $0F, $10, $11, $12, $14 (IsPassable)
;
; Changed from REX 1's SolidCells $D096 (src/game/rexmove.asm).
SolidCells:
  DEFB $02,$04,$05,$06,$09
PassCells:
  DEFB $00,$0E,$0F,$10,$11,$12,$14 ; the cells a body or a bullet passes

; Rex at the right edge: to the room RoomRight $5B91 at X $10
;
; As REX 1's ExitRight $D0B1 (src/game/rexmove.asm).
;
; Witness: L1 4 (d1, demo-cycle).
ExitRight:
  LD A,(RoomRight)
  OR A
  RET Z
  LD (Room),A
  LD A,$08
  LD (RexX),A
  POP BC
  JP ToMainLoop

; Up: a jump if Rex stands (not jumping or falling)
;
; As REX 1's StartJump $D0C2 (src/game/rexmove.asm).
;
; Witness: L1 368 (d1, demo-cycle).
StartJump:
  LD A,(FallSpeed)
  OR A
  RET NZ
  LD A,(Jumping)
  OR A
  RET NZ
  LD A,$01
  LD (Jumping),A
  LD HL,JumpSteps
  LD (JumpPtr),HL
  RET

; The jump steps (StartJump; an object's fall, StartFall): 6, 6, 4, 4, 2, 2, 0,
; 0, 0, 0, then $FF and 8
JumpSteps:
  DEFB $06,$06,$04,$04,$02,$02,$00,$00,$00,$00,$FF,$08

; One step of the jump: up by JumpSteps unless a solid cell above; off the top
; ExitUp
;
; As REX 1's RexJump $D0E4 (src/game/rexmove.asm).
;
; Witness: L1 6540 (d1, demo-cycle).
RexJump:
  LD A,(Jumping)
  OR A
  RET Z
  LD HL,(RexCellPtr)
  LD DE,$0021
  ADD HL,DE
  CALL IsSolid
  JP Z,Land
  INC HL
  CALL IsSolid
  JP Z,Land
  LD A,(RexY)
  LD HL,(JumpPtr)
  LD E,(HL)
  SUB E
  LD (RexY),A
  INC HL
  LD (JumpPtr),HL
  LD A,(HL)
  CP $FF
  RET NZ
  XOR A
  LD (Jumping),A
  RET

; Stop the jump and the fall; Rex on the cell's top
;
; As REX 1's Land $D11A (src/game/rexmove.asm).
;
; Witness: L1 18 (d1, demo-cycle).
Land:
  LD A,$02
  LD (FallSpeed),A
  XOR A
  LD (Jumping),A
  LD A,(RexY)
  AND $07
  OR A
  RET NZ
  XOR A
  LD (FallSpeed),A
  RET

; Rex falls when no floor is under him; off the bottom to RoomDown $5B93, or
; death with no exit
;
; As REX 1's RexFall $D14D (src/game/rexmove.asm).
;
; Witness: L1 6540 (d1, demo-cycle).
RexFall:
  LD A,(Jumping)
  OR A
  RET NZ
  LD A,(RexY)
  LD HL,FallSpeed
  ADD A,(HL)
  CP $BA
  JP NC,ExitBottom
  LD (RexY),A
  AND $07
  OR A
  RET NZ
  LD A,(RexX)
  LD (SpriteX),A
  LD A,(RexY)
  LD (SpriteY),A
  LD A,(RexFacing)
  CALL CellPointer
  LD DE,$0061
  ADD HL,DE
  LD A,(HL)
  CALL IsPassable
  JP NZ,RexFallLand
  INC HL
  LD A,(HL)
  CALL IsPassable
  JP NZ,RexFallLand
  LD A,(FallSpeed)
  ADD A,$02
  CP $06
  RET Z
  LD (FallSpeed),A
  RET
RexFallLand:
  XOR A
  LD (FallSpeed),A
  RET
ExitBottom:
  LD A,(RoomDown)            ; off the bottom: the exit below, or death
  OR A
  JP Z,RexFallStop
  LD (Room),A
  LD A,$08
  LD (RexY),A
  POP BC
  JP ToMainLoop
RexFallStop:
  XOR A
  LD (FallSpeed),A
  LD (Jumping),A
  LD A,(Room)
  CP $04
  RET Z
SoundOffReturn:
  CALL RexDies            ; CALL SoundSilence: RET; no instruction reaches it
                          ; (leftover)
  RET
