; --------------------------------------------------------------------------------------------------------------------
; duck.asm: The duck
;
; The duck sits in its cage on levels 1-8 and flies after Harry from level 9.
; --------------------------------------------------------------------------------------------------------------------

; Steer the duck toward Harry and move it
;
; Every 12 slow ticks. DuckDx and DuckDy move one step toward Harry's x and y
; (each held within -5 .. 5). DrawSprite with frame 12 erases it, PaintCells
; repaints the cells (measured in levels-1-3 frames 600-900: the caged duck
; read blank by the beam in 10 of 28 redraws); DuckX + DuckDx bounces at 0 and
; $EE, DuckY + DuckDy at $14 and $A6 (the speed becomes 5 or -5). On levels 1-8
; (Level < 8) the position is set back to (8, $98), the cage. Then DrawSprite
; draws frame 8 + DuckFrame (Harry right of it or level with it) or 10 +
; DuckFrame (left), and DuckFrame flips. DrawSprite's duck test applies.
;
; Witness: 9 553 calls; held in the cage $A175 9 418, free 135 (levels-1-9,
; level 9). Known only from the code: the bounces ($A12F, $A140, $A157, $A161).
MoveDuck:
  LD IX,HarryX
  LD A,(DuckX)
  CP (IX+$00)
  JR Z,MoveDuckY
  JR C,MoveDuckRight
  LD A,(DuckDx)
  DEC A
  CP $FA
  JR NZ,MoveDuckLeftDone
  INC A
MoveDuckLeftDone:
  JR MoveDuckSetDx
MoveDuckRight:
  LD A,(DuckDx)
  INC A
  CP $06
  JR NZ,MoveDuckSetDx
  DEC A
MoveDuckSetDx:
  LD (DuckDx),A
MoveDuckY:
  LD A,(DuckY)
  CP (IX+$01)
  JR Z,MoveDuckMove
  JR C,MoveDuckUp
  LD A,(DuckDy)
  DEC A
  CP $FA
  JR NZ,MoveDuckDownDone
  INC A
MoveDuckDownDone:
  JR MoveDuckSetDy
MoveDuckUp:
  LD A,(DuckDy)
  INC A
  CP $06
  JR NZ,MoveDuckSetDy
  DEC A
MoveDuckSetDy:
  LD (DuckDy),A
MoveDuckMove:
  LD HL,(DuckX)
  LD A,$0C
  CALL DrawSprite
  CALL PaintCells
  LD A,(DuckX)
  BIT 7,(IX+$72)
  JR NZ,MoveDuckLeft
  ADD A,(IX+$72)
  CP $EE
  JR C,MoveDuckMoveY
  SUB (IX+$72)
  SUB (IX+$72)
  LD (IX+$72),$FB
  JR MoveDuckMoveY
MoveDuckLeft:
  ADD A,(IX+$72)
  JR C,MoveDuckMoveY
  SUB (IX+$72)
  SUB (IX+$72)
  LD (IX+$72),$05
MoveDuckMoveY:
  LD (DuckX),A
  LD A,(DuckY)
  ADD A,(IX+$73)
  CP $A6
  JR C,MoveDuckLow
  SUB (IX+$73)
  SUB (IX+$73)
  LD (IX+$73),$FB
  JR MoveDuckCage
MoveDuckLow:
  CP $14
  JR NC,MoveDuckCage
  SUB (IX+$73)
  SUB (IX+$73)
  LD (IX+$73),$05
MoveDuckCage:
  LD (DuckY),A
  LD A,(Level)
  CP $08
  JR NC,MoveDuckDraw
  LD HL,$9808
  LD (DuckX),HL
MoveDuckDraw:
  LD HL,(DuckX)
  LD C,$08
  LD A,(HarryX)
  CP (IX+$70)
  JR NC,MoveDuckFrame
  LD C,$0A
MoveDuckFrame:
  LD A,C
  ADD A,(IX+$75)
  CALL DrawSprite
  LD A,(DuckFrame)
  XOR $01
  LD (DuckFrame),A
  RET

; 30 zeros
;
; Never read (L1: no access).
ZerosA19A:
  DEFS $1E
