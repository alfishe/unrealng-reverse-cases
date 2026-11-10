; --------------------------------------------------------------------------------------------------------------------
; cellmath.asm: Screen and cell addresses, the wall tests, the attribute and cell fills, the random number
; --------------------------------------------------------------------------------------------------------------------

; The screen address of a cell: DE from HL in the cell table
;
; L1 50.
CellToScreen:
  LD A,H
  AND $03
  SLA A
  SLA A
  SLA A
  SET 6,A
  LD D,A
  LD E,L
  RET

; The screen address of pixel (C, B): DE
;
; In: B the pixel row, C the pixel x (C / 8 the column). L1 34 302.
ScreenAddrXY:
  LD A,B
  AND $C0
  RRA
  SCF
  RRA
  RRCA
  XOR B
  AND $F8
  XOR B
  LD D,A
  LD A,C
  RLCA
  RLCA
  RLCA
  XOR B
  AND $C7
  XOR B
  RLCA
  RLCA
  LD E,A
  RET

; The screen address of pixel row B, column C: DE
;
; L1 68 943.
ScreenAddr:
  LD A,B
  AND $C0
  RRA
  SCF
  RRA
  RRCA
  XOR B
  AND $F8
  XOR B
  LD D,A
  LD A,B
  SLA A
  SLA A
  AND $E0
  ADD A,C
  LD E,A
  RET

; The cell of pixel row B, pixel x C: HL
;
; L1 36 761.
CellAddrXY:
  LD A,B
  RLCA
  RLCA
  LD L,A
  AND $03
  OR $60
  LD H,A
  LD A,L
  AND $E0
  LD L,A
  LD A,C
  RRCA
  RRCA
  RRCA
  AND $1F
  ADD A,L
  LD L,A
  RET

; The cell of pixel row B, column C: HL
;
; CellTable rows from $6000: $6000 + 32 x (B / 8) + C. L1 35 926.
CellAddr:
  LD A,B
  RLCA
  RLCA
  LD L,A
  AND $03
  OR $60
  LD H,A
  LD A,L
  AND $E0
  LD L,A
  LD A,C
  ADD A,L
  LD L,A
  RET

; Is there a wall in a column of A cells? A = 1 yes, 0 no; an item is noted in
; FoundItem
;
; In: HL the top cell, A the cells, DE the y (when y AND 7 is not 0 one more
; cell counts, unless it is below the play area). An item cell (bit 7) goes to
; FoundItem and is no wall. L1 5 573.
CellBlockedColumn:
  LD BC,$0020
CellBlockedColumnLoop:
  PUSH AF
  LD A,(HL)
  BIT 7,A
  JR Z,CellBlockedColumnWall
  LD (FoundItem),HL
  JR CellBlockedColumnNext
CellBlockedColumnWall:
  CP $01
  JR Z,CellBlockedColumnHit
CellBlockedColumnNext:
  ADD HL,BC
  POP AF
  DEC A
  JR NZ,CellBlockedColumnLoop
  LD A,(DE)
  AND $07
  RET Z
  LD A,H
  CP $6B
  LD A,$00
  RET NC
  LD A,(HL)
  BIT 7,A
  JR Z,CellBlockedColumnLast
  LD (FoundItem),HL
  LD A,$00
  RET
CellBlockedColumnHit:
  POP AF
  JR CellBlockedColumnYes
CellBlockedColumnLast:
  CP $01
  LD A,$00
  RET NZ
CellBlockedColumnYes:
  LD A,$01
  RET

; Is there a wall in a row of A cells? A = 1 yes, 0 no
;
; As CellBlockedColumn along a row (DE the x). L1 8 094.
CellBlockedRow:
  PUSH AF
  LD A,(HL)
  BIT 7,A
  JR Z,CellBlockedRowWall
  LD (FoundItem),HL
  JR CellBlockedRowNext
CellBlockedRowWall:
  CP $01
  JR Z,CellBlockedRowHit
CellBlockedRowNext:
  INC L
  POP AF
  DEC A
  JR NZ,CellBlockedRow
  LD A,(DE)
  AND $07
  RET Z
  LD A,L
  AND $1F
  RET Z
  LD A,(HL)
  BIT 7,A
  JR Z,CellBlockedRowLast
  LD (FoundItem),HL
  LD A,$00
  RET
CellBlockedRowHit:
  POP AF
  JR CellBlockedRowYes
CellBlockedRowLast:
  CP $01
  LD A,$00
  RET NZ
CellBlockedRowYes:
  LD A,$01
  RET

; Is there a wall or an item in a column of A cells? (weapon 3's steering)
;
; Called only by the steering of weapon 3's shot (MoveShot3 $832C, $8351),
; which no build ran (L1 -): the same test, but an item counts as a wall.
CellSolidColumn:
  LD BC,$0020
CellSolidColumnLoop:
  PUSH AF
  LD A,(HL)
  BIT 7,A
  JR NZ,CellSolidColumnHit
  CP $01
  JR Z,CellSolidColumnHit
  ADD HL,BC
  POP AF
  DEC A
  JR NZ,CellSolidColumnLoop
  LD A,(DE)
  AND $07
  RET Z
  LD A,H
  CP $6B
  LD A,$00
  RET NC
  LD A,(HL)
  BIT 7,A
  JR NZ,CellSolidColumnYes
  CP $01
  LD A,$00
  RET NZ
CellSolidColumnYes:
  LD A,$01
  RET
CellSolidColumnHit:
  POP AF
  JR CellSolidColumnYes

; Is there a wall or an item in a row of A cells? (weapon 3's steering)
;
; Called only by the steering of weapon 3's shot ($837B, $83A7; L1 -).
CellSolidRow:
  PUSH AF
  LD A,(HL)
  BIT 7,A
  JR NZ,CellSolidRowHit
  CP $01
  JR Z,CellSolidRowHit
  INC L
  POP AF
  DEC A
  JR NZ,CellSolidRow
  LD A,(DE)
  AND $07
  RET Z
  LD A,L
  AND $1F
  RET Z
  LD A,(HL)
  BIT 7,A
  JR NZ,CellSolidRowYes
  CP $01
  LD A,$00
  RET NZ
CellSolidRowYes:
  LD A,$01
  RET
CellSolidRowHit:
  POP AF
  JR CellSolidRowYes

; Fill a block of attributes (or cells): B rows of C bytes with A
;
; In: HL the top left, B rows, C columns, A the value. L1 12 535.
FillAttr:
  LD DE,$0020
FillAttrRow:
  PUSH BC
  PUSH HL
  LD B,C
FillAttrByte:
  LD (HL),A
  INC L
  DJNZ FillAttrByte
  POP HL
  ADD HL,DE
  POP BC
  DJNZ FillAttrRow
  RET

; XOR A into a block of cells, or zero it when A = 0
;
; In: HL the top left cell, B rows, C columns, A the mark (2 an enemy, 4 an
; object, 8 a patroller). A mover XORs its mark out of its old cells and into
; the new ones. L1 25 553 (25 zeroings).
XorCells:
  OR A
  JR Z,XorCellsZero
  LD DE,$0020
XorCellsRow:
  PUSH BC
  PUSH HL
  LD B,C
XorCellsByte:
  PUSH AF
  XOR (HL)
  LD (HL),A
  POP AF
  INC L
  DJNZ XorCellsByte
  POP HL
  ADD HL,DE
  POP BC
  DJNZ XorCellsRow
  RET
XorCellsZero:
  LD DE,$0020
XorCellsZeroRow:
  PUSH BC
  PUSH HL
  LD B,C
XorCellsZeroByte:
  LD (HL),$00
  INC L
  DJNZ XorCellsZeroByte
  POP HL
  ADD HL,DE
  POP BC
  DJNZ XorCellsZeroRow
  RET

; OR the cells of a block (not the item cells) into (DE)
;
; In: HL the top left, B rows, C columns, DE the byte that collects (TouchBits,
; ObjectBits). L1 9 176.
OrCells:
  PUSH BC
  PUSH HL
  LD B,C
OrCellsByte:
  LD A,(HL)
  BIT 7,A
  JR NZ,OrCellsNext
  EX DE,HL
  OR (HL)
  LD (HL),A
  EX DE,HL
OrCellsNext:
  INC L
  DJNZ OrCellsByte
  POP HL
  LD A,L
  ADD A,$20
  LD L,A
  JR NC,OrCellsRowNext
  INC H
OrCellsRowNext:
  POP BC
  DJNZ OrCells
  RET

; The next random number: A
;
; RandomSeed's four bytes as an add-with-carry chain: C = $29, then for each
; byte (A = C, C = byte, byte = A + byte + carry). Out: A = the new fourth
; byte. No R register, no timer: the sequence depends only on how many times it
; has been called. Menu $893B calls it in its wait loop, so the number at the
; start of a game is set by how many frames the player took at the menu (L1 710
; 553 calls).
Random:
  EXX
  LD B,$04
  LD C,$29
  LD HL,RandomSeed
RandomLoop:
  LD A,C
  LD C,(HL)
  ADC A,(HL)
  LD (HL),A
  INC HL
  DJNZ RandomLoop
  EXX
  RET
