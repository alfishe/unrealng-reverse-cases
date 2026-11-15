; --------------------------------------------------------------------------------------------------------------------
; rexmove.asm: Rex's moves: walk, jump, fall, the edges of the room
; --------------------------------------------------------------------------------------------------------------------

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
; Witness: L1 1507 (c2, p2-room20, rzx-p2- x21).
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
; Witness: L1 1319 (c2, rzx-p2- x21).
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

; Move Rex by RexSpeed in his facing unless a solid cell (type 3 kills him); at
; the edges ExitLeft / ExitRight
;
; Changed from REX 1's RexWalk $D013 (src/game/rexmove.asm).
;
; Witness: L1 8996 (c2, p2-room20, rzx-p2- x21).
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
  CP $03
  JP C,ExitLeft
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
  JP Z,RexWalkDeadly
  LD DE,$0020
  ADD HL,DE
  CALL IsSolid
  JP Z,RexWalkDeadly
  JP RexWalkStep
RexWalkLeftCell:
  LD HL,(RexCellPtr)
  LD DE,$0020
  ADD HL,DE
  CALL IsSolid
  JP Z,RexWalkDeadly
  LD DE,$0020
  ADD HL,DE
  CALL IsSolid
  JP Z,RexWalkDeadly
  JP RexWalkStep
RexWalkDeadly:
  LD A,(CellFound)        ; a cell of type 3 under Rex: RexDies
  CP $03
  CALL Z,RexDies
  RET

; Z if the cell at HL is solid (SolidCells: 2, 4, 5, 6, 3); the type found in
; $A25D
;
; Changed from REX 1's IsSolid $D06C (src/game/rexmove.asm).
;
; Witness: L1 37941 (c2, p2-room20, rzx-p2- x21).
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
; Witness: L1 118632 (c2, p2-room20, rzx-p2- x21).
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
  LD (CellFound),A
  POP BC
  POP HL
  RET

; Z if the cell at HL lets a body or a bullet through (PassCells $CE27: 0,
; $0E-$12, 3, $15, $16); the type found in $A25D
;
; Changed from REX 1's IsPassable $D08B (src/game/rexmove.asm).
;
; Witness: L1 80691 (c2, p2-room20, rzx-p2- x21).
IsPassable:
  PUSH HL
  PUSH BC
  LD A,(HL)
  LD B,$09
  LD HL,PassCells
  JP InList

; The solid cell types 2, 4, 5, 6, 3 (IsSolid), then PassCells $CE27: 0, $0E,
; $0F, $10, $11, $12, 3, $15, $16 (IsPassable)
;
; Changed from REX 1's SolidCells $D096 (src/game/rexmove.asm).
SolidCells:
  DEFB $02,$04,$05,$06,$03
PassCells:
  DEFB $00,$0E,$0F,$10,$11,$12,$03,$15,$16 ; the cells a body or a bullet
                                           ; passes

; Rex at the left edge: to the room RoomLeft $A229 at X $E0
;
; As REX 1's ExitLeft $D0A0 (src/game/rexmove.asm).
;
; Witness: L1 3 (rzx-p2-02000, rzx-p2-04000, rzx-p2-10000).
ExitLeft:
  LD A,(RoomLeft)
  OR A
  RET Z
  LD (Room),A
  LD A,$E8
  LD (RexX),A
  POP BC
  JP ChangeRoom

; Rex at the right edge: to the room RoomRight $A226 at X $10
;
; As REX 1's ExitRight $D0B1 (src/game/rexmove.asm).
;
; Witness: L1 3 (p2-room20, rzx-p2-00000, rzx-p2-12000).
ExitRight:
  LD A,(RoomRight)
  OR A
  RET Z
  LD (Room),A
  LD A,$08
  LD (RexX),A
  POP BC
  JP ChangeRoom

; Up: a jump if Rex stands (not jumping or falling)
;
; As REX 1's StartJump $D0C2 (src/game/rexmove.asm).
;
; Witness: L1 1172 (c2, p2-room20, rzx-p2- x21).
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

; The jump steps (Rex's jump, StartJump; an object's fall, StartFall): 6, 6, 4,
; 4, 2, 2, 0, 0, 0, 0, then $FF and 8
JumpSteps:
  DEFB $06,$06,$04,$04,$02,$02,$00,$00,$00,$00,$FF,$08

; One step of the jump: up by JumpSteps unless a solid cell above (type 3 kills
; him); off the top ExitUp
;
; Changed from REX 1's RexJump $D0E4 (src/game/rexmove.asm).
;
; Witness: L1 9003 (c2, p2-room20, rzx-p2- x21).
RexJump:
  LD A,(Jumping)
  OR A
  RET Z
  LD HL,(RexCellPtr)
  LD DE,$0021
  ADD HL,DE
  CALL IsSolid
  JP Z,RexJumpDeadly
  INC HL
  CALL IsSolid
  JP Z,RexJumpDeadly
  LD A,(RexY)
  LD HL,(JumpPtr)
  LD E,(HL)
  SUB E
  CP $08
  JP C,ExitTop
  LD (RexY),A
  INC HL
  LD (JumpPtr),HL
  LD A,(HL)
  CP $FF
  RET NZ
  XOR A
  LD (Jumping),A
  RET
RexJumpDeadly:
  LD A,(CellFound)        ; a cell of type 3: RexDies
  CP $03
  CALL Z,RexDies

; Stop the jump and the fall; Rex on the cell's top
;
; As REX 1's Land $D11A (src/game/rexmove.asm).
;
; Witness: L1 44 (c2, p2-room20, rzx-p2- x8).
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

; Rex off the top: to the room RoomUp $A227 at the bottom
;
; As REX 1's ExitTop $D12F (src/game/rexmove.asm).
;
; Witness: L1 7 (rzx-p2- x7).
ExitTop:
  XOR A
  LD (Jumping),A
  LD A,$02
  LD (FallSpeed),A
  LD A,(RoomUp)
  OR A
  RET Z
  LD (Room),A
  LD A,$A0
  LD (RexY),A
  XOR A
  LD (FallSpeed),A
  POP BC
  JP ChangeRoom

; Rex falls when no floor is under him (a passable cell 3 kills him); off the
; bottom to RoomDown $A228, or death with no exit
;
; Changed from REX 1's RexFall $D14D (src/game/rexmove.asm).
;
; Witness: L1 8996 (c2, p2-room20, rzx-p2- x21).
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
  LD A,(CellFound)
  CP $03
  CALL Z,RexDies
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
  LD A,(RoomDown)         ; off the bottom: the exit below, or death
  OR A
  JP Z,RexFallStop
  LD (Room),A
  LD A,$08
  LD (RexY),A
  POP BC
  JP ChangeRoom
RexFallStop:
  XOR A
  LD (FallSpeed),A
  LD (Jumping),A
RexFallDies:
  CALL RexDies            ; no exit below: RexDies
  RET
