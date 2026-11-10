; --------------------------------------------------------------------------------------------------------------------
; steps.asm: One step of an enemy or an object, and the shifts of their graphics
;
; StepRight, StepDown, StepLeft and StepUp take HL at a record's x (and y after it), the mover's size in StepWidth /
; StepHeight cells and the limits; between whole cells they just step 2 pixels, at a cell edge they test the next
; column or row for a wall (CellBlockedColumn / CellBlockedRow). They return Z when the move hit the limit or a wall,
; so the mover turns. An item in the way is passed over (FoundItem).
; --------------------------------------------------------------------------------------------------------------------

; Step a mover 2 pixels right
;
; L1 3 912.
StepRight:
  LD A,$07
  AND (HL)
  JR NZ,StepRightMove
  PUSH HL
  PUSH DE
  LD C,(HL)
  INC HL
  LD B,(HL)
  LD D,H
  LD E,L
  CALL CellAddrXY
  INC L
  INC L
  LD A,(StepX)
  CP $02
  JR Z,StepRightTest
  INC L
StepRightTest:
  CALL CellBlockedColumn
  CP $00
  JR Z,StepRightDone
  LD HL,$0000
  LD (FoundItem),HL
StepRightDone:
  POP DE
  POP HL
  CP $01
  RET Z
  LD BC,(FoundItem)
  LD A,B
  OR C
  RET NZ
StepRightMove:
  LD A,(StepWidth)
  INC (HL)
  INC (HL)
  CP (HL)
  RET

; Step a mover 2 pixels down
;
; L1 4 688.
StepDown:
  LD A,$07
  AND (HL)
  JR NZ,StepDownMove
  PUSH HL
  PUSH DE
  LD B,(HL)
  DEC HL
  LD C,(HL)
  LD D,H
  LD E,L
  CALL CellAddrXY
  LD A,(StepY)
  CP $02
  JR Z,StepDownTwo
  LD BC,$0060
  JR StepDownTest
StepDownTwo:
  LD BC,$0040
StepDownTest:
  ADD HL,BC
  CALL CellBlockedRow
  CP $00
  JR Z,StepDownDone
  LD HL,$0000
  LD (FoundItem),HL
StepDownDone:
  POP DE
  POP HL
  CP $01
  RET Z
  LD BC,(FoundItem)
  LD A,B
  OR C
  RET NZ
StepDownMove:
  LD A,(StepHeight)
  INC (HL)
  INC (HL)
  CP (HL)
  RET

; Step a mover 2 pixels left
;
; L1 4 138.
StepLeft:
  LD A,$07
  AND (HL)
  JR NZ,StepLeftMove
  PUSH HL
  PUSH DE
  LD C,(HL)
  INC HL
  LD B,(HL)
  LD D,H
  LD E,L
  CALL CellAddrXY
  DEC L
  LD A,(StepX)
  CALL CellBlockedColumn
  CP $00
  JR Z,StepLeftDone
  LD HL,$0000
  LD (FoundItem),HL
StepLeftDone:
  POP DE
  POP HL
  CP $01
  RET Z
  LD BC,(FoundItem)
  LD A,B
  OR C
  RET NZ
StepLeftMove:
  XOR A
  DEC (HL)
  DEC (HL)
  CP (HL)
  RET

; Step a mover 2 pixels up (to y $30)
;
; L1 4 455.
StepUp:
  LD A,$07
  AND (HL)
  JR NZ,StepUpMove
  PUSH HL
  PUSH DE
  LD B,(HL)
  DEC HL
  LD C,(HL)
  LD D,H
  LD E,L
  CALL CellAddrXY
  LD BC,$0020
  SCF
  CCF
  SBC HL,BC
  LD A,(StepY)
  CALL CellBlockedRow
  CP $00
  JR Z,StepUpDone
  LD HL,$0000
  LD (FoundItem),HL
StepUpDone:
  POP DE
  POP HL
  CP $01
  RET Z
  LD BC,(FoundItem)
  LD A,B
  OR C
  RET NZ
StepUpMove:
  LD A,$30
  DEC (HL)
  DEC (HL)
  CP (HL)
  RET

; Shift a 3-byte-wide, 16-row graphic in place to the pixel offset A
;
; In: HL the graphic's first byte (its current offset 0-7), A the offset
; wanted. The 48 bytes after it are shifted right or left by the difference,
; and the byte is set: the enemy graphics ($A74E-$AEC4) are kept pre-shifted
; this way rather than shifted at each draw. L1 20 289 calls, 2 330 shifts.
ShiftGraphic3:
  CP (HL)
  RET Z
  LD C,(HL)
  LD (HL),A
  SUB C
  PUSH HL
  POP IX
  INC IX
  LD C,$10
  JP M,ShiftGraphic3Left
ShiftGraphic3RightRow:
  LD B,A
ShiftGraphic3Right:
  SRL (IX+$00)
  RR (IX+$01)
  RR (IX+$02)
  DJNZ ShiftGraphic3Right
  INC IX
  INC IX
  INC IX
  DEC C
  JR NZ,ShiftGraphic3RightRow
  RET
ShiftGraphic3Left:
  NEG
ShiftGraphic3LeftRow:
  LD B,A
ShiftGraphic3LeftBit:
  SLA (IX+$02)
  RL (IX+$01)
  RL (IX+$00)
  DJNZ ShiftGraphic3LeftBit
  INC IX
  INC IX
  INC IX
  DEC C
  JR NZ,ShiftGraphic3LeftRow
  RET

; Shift a 4-byte-wide, 24-row graphic in place to the pixel offset A
;
; As ShiftGraphic3 for the objects of width 4 ($B413-$B6B9 and the others). L1
; 1 765 calls, 299 shifts.
ShiftGraphic4:
  CP (HL)
  RET Z
  LD C,(HL)
  LD (HL),A
  SUB C
  PUSH HL
  POP IX
  INC IX
  LD C,$18
  JP M,ShiftGraphic4Left
ShiftGraphic4RightRow:
  LD B,A
ShiftGraphic4Right:
  SRL (IX+$00)
  RR (IX+$01)
  RR (IX+$02)
  RR (IX+$03)
  DJNZ ShiftGraphic4Right
  INC IX
  INC IX
  INC IX
  INC IX
  DEC C
  JR NZ,ShiftGraphic4RightRow
  RET
ShiftGraphic4Left:
  NEG
ShiftGraphic4LeftRow:
  LD B,A
ShiftGraphic4LeftBit:
  SLA (IX+$03)
  RL (IX+$02)
  RL (IX+$01)
  RL (IX+$00)
  DJNZ ShiftGraphic4LeftBit
  INC IX
  INC IX
  INC IX
  INC IX
  DEC C
  JR NZ,ShiftGraphic4LeftRow
  RET
