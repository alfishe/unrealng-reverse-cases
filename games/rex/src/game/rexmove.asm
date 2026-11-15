; --------------------------------------------------------------------------------------------------------------------
; rexmove.asm: Rex's moves: walk, jump, fall, the edges of the room
;
; Rex walks 2 pixels a pass (4 with SPEED UP, SpeedUp $A072: WalkRightKey / WalkLeftKey set RexSpeed), jumps by
; JumpSteps $D0D8 (up 6, 6, 4, 4, 2, 2, 0, ...) and falls faster each step (FallSpeed $A0BC) until a cell that is not
; passable (PassCells $D09A) or a ladder. Walking off the left or right edge, jumping off the top or falling off the
; bottom changes the room by the exits; falling with no exit below kills him.
; --------------------------------------------------------------------------------------------------------------------

  ORG $CFCC

; The SPEED UP bonus: count down; the speed back at the end
;
; SpeedUpPhase $A073 starts at 200 (PrizeSpeedUp) and counts the walking
; passes; at 0 SpeedUp ends. Run by p1-speedup: the roulette stopped on SPEED
; UP by fire, SpeedUpPhase 200 at frame 1740 down to 0 at 2740, RexSpeed 4 / -4
; meanwhile, 2 / -2 after.
;
; Witness: L1 200 (p1-speedup).
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
; Witness: L1 4760 (c1, p1-code, p1-cursor, p1-define, p1-kempston,
; p1-rooms238, p1-speedup, p1-room x5, rzx-p1- x32).
WalkRightKey:
  LD A,(SpeedUp)
  OR A
  JP Z,WalkRightNormal
WalkRightFast:
  LD A,$04                ; SPEED UP (SpeedUp not 0): 4 pixels, SpeedUpTick
                          ; counts down
  LD (RexSpeed),A
  CALL SpeedUpTick
  JP WalkRightFacing
WalkRightNormal:
  LD A,$02                ; the normal walk: 2 pixels
  LD (RexSpeed),A
WalkRightFacing:
  XOR A
  LD (RexFacing),A
  RET

; Left: facing left, the speed set
;
; Witness: L1 4294 (c1, p1-code, p1-cursor, p1-speedup, p1-room x5, rzx-p1-
; x32).
WalkLeftKey:
  LD A,(SpeedUp)
  OR A
  JP Z,WalkLeftNormal
WalkLeftFast:
  LD A,$FC                ; SPEED UP: 4 pixels left, SpeedUpTick counts down
  LD (RexSpeed),A
  CALL SpeedUpTick
  JP WalkLeftFacing
WalkLeftNormal:
  LD A,$FE                ; the normal walk: 2 pixels left
  LD (RexSpeed),A
WalkLeftFacing:
  LD A,$01
  LD (RexFacing),A
  RET

; Move Rex by RexSpeed in his facing unless a solid cell; at the edges ExitLeft
; / ExitRight
;
; Witness: L1 16675 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x32).
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

; Z if the cell at HL is solid (SolidCells' first 4: 2, 4, 5, 6)
;
; Witness: L1 111966 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x32).
IsSolid:
  PUSH HL
  PUSH BC
  LD A,(HL)
  LD B,$04
  LD HL,SolidCells

; Z if A is one of B values at DE
;
; Witness: L1 262708 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x32).
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

; Z if the cell at HL lets a body or a bullet through: empty (0) or one of
; $0E-$12 (PassCells $D09A)
;
; Witness: L1 150742 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x32).
IsPassable:
  PUSH HL
  PUSH BC
  LD A,(HL)
  LD B,$06
  LD HL,PassCells
  JP InList

; The solid cell types 2, 4, 5, 6 (IsSolid), then PassCells $D09A: 0, $0E, $0F,
; $10, $11, $12 (IsPassable)
SolidCells:
  DEFB $02,$04,$05,$06
PassCells:
  DEFB $00,$0E,$0F,$10,$11,$12 ; the cells a body or a bullet passes

; Rex at the left edge: to the room RoomLeft $A090 at X $E8
;
; Witness: L1 161 (p1-speedup, p1-room14, p1-room26, p1-room27, rzx-p1- x12).
ExitLeft:
  LD A,(RoomLeft)
  OR A
  RET Z
  LD (Room),A
  LD A,$E8
  LD (RexX),A
  POP BC
  JP ChangeRoom

; Rex at the right edge: to the room RoomRight $A08D at X $08
;
; Witness: L1 298 (c1, p1-cursor, p1-kempston, p1-rooms238, p1-speedup,
; p1-room14, p1-room24, p1-room26, p1-room27, rzx-p1- x14).
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
; Witness: L1 2080 (c1, p1-code, p1-cursor, p1-define, p1-kempston, p1-speedup,
; p1-room14, p1-room26, p1-room27, p1-room30, rzx-p1- x32).
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

; The jump's rise a step: 6, 6, 4, 4, 2, 2, 0, 0, 0, 0, then $FF and the fall's
; start 8
JumpSteps:
  DEFB $06,$06,$04,$04,$02,$02,$00,$00,$00,$00,$FF,$08

; One step of the jump: up by JumpSteps unless a solid cell above; off the top
; ExitUp
;
; Witness: L1 16687 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x32).
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

; Stop the jump and the fall; Rex on the cell's top
;
; Witness: L1 150 (p1-code, p1-speedup, p1-room14, p1-room26, p1-room27,
; p1-room30, rzx-p1- x12).
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

; Rex off the top: to the room RoomUp $A08E at the bottom
;
; Witness: L1 17 (p1-code, p1-speedup, p1-room30, rzx-p1- x10).
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

; Rex falls when no floor is under him; off the bottom to RoomDown $A08F, or
; death with no exit
;
; Witness: L1 16675 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x32).
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
  CALL RexDies
  RET
