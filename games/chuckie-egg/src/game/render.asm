; --------------------------------------------------------------------------------------------------------------------
; render.asm: The attributes under a sprite and the map cell address
;
; PaintCells restores the map's colours where a sprite was; MapCellAddr turns a pixel position into a LiveMap address.
; --------------------------------------------------------------------------------------------------------------------

; Paint the attributes of the 3 x 3 map cells at (L, H)
;
; Input: L = x, H = y of a sprite. From the cell under (x, y) down, three rows
; of three cells (two columns at x >= $F1, as DrawSprite; two rows only at y <
; $11, with no y AND 7 test) get their attribute from CellAttributes (code 9
; and up: 6). Only the attributes are painted: DrawSprite $9A4C redraws the
; pixels with the background. Registers kept.
;
; Callers: MainLoop before Harry moves, JumpStep before each step, JumpFall
; $A2BE before each fall step, MoveDuck before the duck moves. Witness: 147 583
; calls.
PaintCells:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  LD B,$03
  LD A,L
  CP $F1
  JR C,PaintCellsRows
  DEC B
PaintCellsRows:
  LD C,$03
  LD A,H
  CP $11
  JR NC,PaintCellsStart
  DEC C
PaintCellsStart:
  CALL CellAttrAddr
  CALL MapCellAddr
PaintCellsRow:
  PUSH BC
  PUSH DE
  PUSH HL
PaintCellsCell:
  LD A,(HL)
  CP $09
  JR C,PaintCellsAttr
  LD A,$06
  JR PaintCellsSet
PaintCellsAttr:
  ADD A,$4F
  PUSH BC
  LD B,$98
  LD C,A
  LD A,(BC)
  POP BC
PaintCellsSet:
  LD (DE),A
  INC DE
  INC HL
  DJNZ PaintCellsCell
  POP HL
  LD DE,$0020
  AND A
  SBC HL,DE
  POP DE
  PUSH HL
  EX DE,HL
  LD DE,$0020
  ADD HL,DE
  EX DE,HL
  POP HL
  POP BC
  DEC C
  JR NZ,PaintCellsRow
  POP HL
  POP DE
  POP BC
  POP AF
  RET

; DE = the attribute address of pixel (L, H)
;
; As AttrAddrHen $93DD, the result in DE. Witness: 147 583 calls (PaintCells).
CellAttrAddr:
  PUSH AF
  PUSH HL
  LD A,$BF
  SUB H
  LD H,$00
  EX DE,HL
  LD HL,Attributes
  SRL E
  SRL E
  SRL E
  ADD HL,DE
  AND $F8
  SLA A
  RL D
  SLA A
  RL D
  LD E,A
  ADD HL,DE
  EX DE,HL
  POP HL
  POP AF
  RET

; HL = the LiveMap address of the cell at pixel (L, H)
;
; Output: HL = LiveMap + x / 8 + 4 x (y AND $F8): row y / 8 from the bottom, 32
; cells a row. Witness: 147 583 calls (PaintCells).
MapCellAddr:
  PUSH AF
  PUSH DE
  EX DE,HL
  LD HL,LiveMap
  LD A,D
  LD D,$00
  SRL E
  SRL E
  SRL E
  ADD HL,DE
  AND $F8
  LD E,A
  SLA E
  RL D
  SLA E
  RL D
  ADD HL,DE
  POP DE
  POP AF
  RET

; 107 zeros
;
; Never read (L1: no access).
Zeros95C5:
  DEFS $6B
