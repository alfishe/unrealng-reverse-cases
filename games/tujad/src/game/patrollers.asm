; --------------------------------------------------------------------------------------------------------------------
; patrollers.asm: The three patrollers: guards that walk a row through several rooms
;
; A patroller walks along a row of the world, a column every four of its turns (one turn every three passes), from
; room to room; it turns where its record says. It is drawn only when it is in the droid's room. Its mark 8 in the
; cells kills the droid at a touch (HazardDeath).
; --------------------------------------------------------------------------------------------------------------------

; One turn of the patroller at PatrollerPtr: erase, step, draw
;
; Erase it (DrawPatroller) when it was drawn and is in the room; clear bit 7;
; PatrollerStep; draw it when it is in the room. L1 18 583 turns, 495 erased,
; 507 drawn.
MovePatroller:
  LD A,$08
  LD (DrawMode),A
  LD HL,(PatrollerPtr)
  BIT 7,(HL)
  JR NZ,MovePatrollerStep
  INC HL
  INC HL
  INC HL
  LD A,(Room)
  CP (HL)
  JR NZ,MovePatrollerStep
  LD HL,(PatrollerPtr)
  CALL DrawPatroller
MovePatrollerStep:
  LD HL,(PatrollerPtr)
  RES 7,(HL)
  CALL PatrollerStep
  LD HL,(PatrollerPtr)
  INC HL
  INC HL
  INC HL
  LD A,(Room)
  CP (HL)
  RET NZ
  LD HL,(PatrollerPtr)
  LD A,$08
  LD (DrawMode),A
  CALL DrawPatroller
  RET

; Advance the frame; every fourth a column, round the ends
;
; +0 the frame 0-3; at 4: a column right (y bit 0 clear) or left; past column
; $1D (or 0) into the next room (+3 + 1 or - 1); at the right end (room +4,
; column +5) or the left end (+6, +7) it turns (bit 0 of y flips) and steps
; back. L1 18 583, 4 630 steps, 102 + 72 room changes, 28 + 28 turns.
PatrollerStep:
  INC (HL)
  LD A,$04
  CP (HL)
  RET NZ
  LD (HL),$00
  INC HL
  BIT 0,(HL)
  JR NZ,PatrollerStepLeft
  INC HL
  INC (HL)
  LD A,$1D
  CP (HL)
  JR NZ,PatrollerStepRightEnd
  XOR A
  LD (HL),A
  INC HL
  INC (HL)
  RET
PatrollerStepRightEnd:
  LD B,(HL)
  INC HL
  LD A,(HL)
  INC HL
  CP (HL)
  RET NZ
  INC HL
  LD A,(HL)
  CP B
  RET NZ
  DEC HL
  DEC HL
  DEC HL
  DEC (HL)
  DEC HL
  SET 0,(HL)
  RET
PatrollerStepLeft:
  INC HL
  DEC (HL)
  LD A,$FF
  CP (HL)
  JR NZ,PatrollerStepLeftEnd
  LD A,$1C
  LD (HL),A
  INC HL
  DEC (HL)
  RET
PatrollerStepLeftEnd:
  LD B,(HL)
  INC HL
  LD A,(HL)
  INC HL
  INC HL
  INC HL
  CP (HL)
  RET NZ
  INC HL
  LD A,(HL)
  CP B
  RET NZ
  DEC HL
  DEC HL
  DEC HL
  DEC HL
  DEC HL
  INC (HL)
  DEC HL
  RES 0,(HL)
  RET

; XOR a patroller into the sprite list and its mark into the cells
;
; The frame from $B902 (walking right) or $BA82 (left), 96 bytes a frame (4
; bytes x 24 rows: Patrol graphics); 4 x 3 character cells, the mark DrawMode
; (8), the attribute $42. L1 1 002.
DrawPatroller:
  LD A,(HL)
  INC HL
  LD B,(HL)
  LD DE,PatrolRight
  BIT 0,B
  RES 0,B
  JR Z,DrawPatrollerColumn
  LD DE,PatrolLeft
DrawPatrollerColumn:
  INC HL
  LD C,(HL)
  LD HL,$0060
  EX DE,HL
  CP $00
  JR Z,DrawPatrollerQueue
DrawPatrollerFrame:
  ADD HL,DE
  DEC A
  JR NZ,DrawPatrollerFrame
DrawPatrollerQueue:
  EX DE,HL
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
  CALL ScreenAddr
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (SpriteListEnd),HL
  CALL CellAddr
  LD BC,$0304
  LD A,(DrawMode)
  PUSH BC
  PUSH HL
  CALL XorCells
  POP HL
  POP BC
  LD A,H
  AND $03
  OR $58
  LD H,A
  LD A,$42
  CALL FillAttr
  RET

; Where the droid starts in each of the 128 rooms: (x, y)
;
; PlaceDroid $7A7B reads StartPositions + 2 x Room after a life lost and at a
; new game (room $54). The editable form is part of src/res/rooms/ (the start
; of each room).
StartPositions:
  INCBIN "res/rooms/StartPositions.bin",$0000,256
