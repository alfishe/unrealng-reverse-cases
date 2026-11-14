; --------------------------------------------------------------------------------------------------------------------
; render.asm: The playfield: the char map, the cell flags, the sprite composer and drawers, the redraws and the scrolls
;
; The playfield is a char map of 32 columns from $6500 (44 rows: $6500-$6A7F, built by BuildScreenMap $AD5A from the
; screen's 4x4-char blocks); its rows from $6600 are the screen's rows. A cell's flag byte sits $600 above it
; ($6B00-$707F): 0 clean, 1 redraw the map's char, 2 or more draw composed char n from $5CF0 + 8n, $FF the end
; sentinel ($6F00, below the 24 screen rows $6C00-$6EFF). The charset is at CharsetBase $A73D ($7100, or $7A00 for
; some screens), a char's attribute at $7900 + char ($8200 with the other charset).
;
; Each pass ($E414-$E41F) ComposeObjects $A73F walks the object table $EA8E (30-byte records, +0: 0 empty, $FF the
; end) and ComposeObject $A2EC draws every object's sprite into fresh composed chars: ComposeCell $A6D0 copies each
; covered cell's char (the map's, or the composed one already there) to a new buffer and points the cell's flag at it.
; A char whose property byte at $5C00 + char has any of bits 3-6 set gets a scratch buffer that is never shown: the
; sprite passes behind it.
;
; A sprite frame is 21 rows of 3 bytes, each byte an (AND mask, OR data) pair, popped with SP. Aligned on x (x AND 7 =
; 0) it covers 3 columns of 3 or 4 cells; otherwise each row is shifted right by x AND 7 into 4 bytes (the shift chain
; at $A633, entered at $A633 + 14 (x AND 7)). Bit 0 of the record's +6 mirrors the frame: the bytes of a row are
; swapped and each one bit-reversed through the table at $5B00.
;
; DrawDirtyCells $A25D then draws every flagged cell: a flag of 1 draws the map's char and clears the flag, a composed
; char is drawn and its flag set back to 1, so the next frame restores the background. RedrawScreen $A781 draws the
; flagged cells with their attributes (after MarkAllDirty $A239: the whole screen) and keeps the HUD row's flags.
;
; The view scrolls by whole cells: when Rick's y passes $CC or falls below $60 the game loop ($E42B-$E43B) calls
; ScrollViewDown $ADB9 or ScrollViewUp $ADF0, two steps of 4 rows (32 pixels), each moving the map, the composed marks
; and every object, then rebuilds the map at the new ViewTopRow $ADB7.
; --------------------------------------------------------------------------------------------------------------------

  ORG $A239

; Set every cell flag of the screen to 1 ($6C00-$6EFF): the next draw redraws
; all
;
; Pushes $0101 384 times with SP = $6F00, interrupts off, then restores SP and
; enables interrupts.
;
; Callers: LoadScreen ($ACF7), the level's end ($ABD8) and the end of the last
; level ($AC4C). Output: B, HL changed.
;
; Witness: L1 443 (beeper48, c1, controls, ending, ending2, gameover, l1end,
; spotL3Z7-51, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4,
; spotL1Z4-43).
MarkAllDirty:
  DI
  LD (MarkAllDirtySP+$0001),SP
  LD SP,CellFlagsRow24
  LD HL,$0101
  LD B,$18
MarkAllDirtyLoop:
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  DJNZ MarkAllDirtyLoop
MarkAllDirtySP:
  LD SP,$0000             ; its operand: the caller's SP
  EI
  RET

; Draw the flagged cells of the screen (no attributes): the per-frame update
;
; Sets the sentinel $6F00 = $FF, calls MaskHudCells, then scans the flags from
; $6C00. Flag 1: draws the map's char (the map byte $600 below the flag) from
; the charset at CharsetBase and clears the flag. Flag n >= 2: draws composed
; char n ($5CF0 + 8n) and sets the flag to 1, so the cell is restored next
; frame. $FF: return.
;
; The screen address follows from the flag's: the low byte is the cell's, the
; third is (H - $6C).
;
; Callers: the frame loop ($E41F), the game over ($E360) and the end of each
; scroll ($ADEC, $AE21). Output: AF, BC, DE, HL changed.
;
; Witness: L1 43014 (beeper48, c1, controls, emptygun, ending, ending2,
; gameover, l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6,
; L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44,
; spotL1Z4-47).
DrawDirtyCells:
  LD A,$FF
  LD (CellFlagsRow24),A
  CALL MaskHudCells
  LD HL,CellFlags-1
DrawDirtyNext:
  XOR A
DrawDirtyScan:
  INC HL
  OR (HL)
  JP Z,DrawDirtyScan
  DEC A
  JP Z,DrawDirtyMapChar
  CP $FE
  RET Z
  LD (HL),$01
  PUSH HL
  EX DE,HL
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,$5CF8
  ADD HL,BC
  LD A,D
  SUB $6C
  ADD A,A
  ADD A,A
  ADD A,A
  OR $40
  LD D,A
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  POP HL
  JP DrawDirtyNext
DrawDirtyMapChar:
  LD (HL),$00             ; flag 1: the map's char, the flag cleared
  PUSH HL
  LD A,H
  ADD A,$FA
  LD H,A
  LD E,(HL)
  LD A,H
  ADD A,$9A
  ADD A,A
  ADD A,A
  ADD A,A
  OR $40
  LD H,A
  EX DE,HL
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,(CharsetBase)
  ADD HL,BC
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  POP HL
  JP DrawDirtyNext

; Draw the sprite of the object at IX into composed chars of the cells it
; covers
;
; Input: IX an object record: +1 x, +2/+3 y (from the map's $6500 row; +3 is 0,
; or 1 with +2 below $EB, else nothing is drawn), +4/+5 the frame (0: no
; sprite, return), +6 bit 0 mirror.
;
; Finds the first map cell HL = $6500 + 32 (y / 8) + x / 8, then calls
; ComposeCell for every cell the sprite covers, column by column: 3 columns of
; 3 cells (y AND 7 below 4) or of 4 cells when aligned; 4 columns when x AND 7
; is not 0 (ComposeShifted). The drawers' IY = the first composed buffer + (y
; AND 7); the next column's buffer is 24 or 32 bytes on.
;
; The column offsets are written into the drawers' (IY+d) operands. Output:
; everything but IX; interrupts on at the end. Called by ComposeObjects only.
;
; Witness: L1 225623 (beeper48, c1, controls, emptygun, ending2, gameover,
; l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7,
; L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).
ComposeObject:
  LD A,(IX+$04)
  OR (IX+$05)
  RET Z
  LD H,$00
  LD A,(IX+$03)
  AND A
  JP Z,ComposeObjectAt
  CP $01
  RET NZ
  LD H,A
  LD A,(IX+$02)
  CP $EB
  RET NC
ComposeObjectAt:
  LD A,(IX+$02)
  LD D,A
  ADD A,A
  RL H
  ADD A,A
  RL H
  AND $E0
  LD L,A
  LD A,(IX+$01)
  LD E,A
  SRL A
  SRL A
  SRL A
  OR L
  LD L,A
  LD BC,$6500
  ADD HL,BC
  LD A,E
  AND $07
  JP NZ,ComposeShifted
  LD A,D
  AND $07
  EX AF,AF'
  LD A,D
  AND $04
  JP Z,ComposeAligned3
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$FFA1
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$FFA1
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD A,$20
  LD (SpriteAlignedCol2In+$0002),A
  LD (SpriteAlignedCol2Out+$0002),A
  ADD A,A
  LD (SpriteAlignedCol3In+$0002),A
  LD (SpriteAlignedCol3Out+$0002),A
  EX DE,HL
  LD BC,$FFA0
  ADD HL,BC
  EX AF,AF'
  LD C,A
  LD B,$00
  ADD HL,BC
  JP SpriteDrawAligned
ComposeAligned3:
  PUSH HL                 ; y AND 7 < 4: 3 cells a column
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$FFC1
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$FFC1
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD A,$18
  LD (SpriteAlignedCol2In+$0002),A
  LD (SpriteAlignedCol2Out+$0002),A
  ADD A,A
  LD (SpriteAlignedCol3In+$0002),A
  LD (SpriteAlignedCol3Out+$0002),A
  EX DE,HL
  LD BC,$FFB8
  ADD HL,BC
  EX AF,AF'
  LD C,A
  LD B,$00
  ADD HL,BC
SpriteDrawAligned:
  PUSH HL                 ; the drawer: 21 rows of 3 bytes, IY on the first
                          ; composed byte, SP on the frame
  POP IY
  DI
  LD (SpriteAlignedSP+$0001),SP
  LD HL,SpriteAlignedPut
  LD (SpriteAlignedJump+$0001),HL
  BIT 0,(IX+$06)
  JP Z,SpriteAlignedPlain
  LD HL,SpriteAlignedMirror
  LD (SpriteAlignedJump+$0001),HL
SpriteAlignedPlain:
  LD L,(IX+$04)
  LD H,(IX+$05)
  LD SP,HL
  LD B,$15
SpriteAlignedRow:
  EXX
  POP HL
  POP BC
  POP DE
SpriteAlignedJump:
  JP SpriteAlignedPut     ; its operand: $A468 (plain) or $A444 (mirrored, bit
                          ; 0 of +6)
SpriteAlignedMirror:
  LD A,L                  ; swap the bytes' order, reverse each through $5B00
  LD L,C
  LD C,A
  LD A,B
  LD B,E
  LD E,A
  LD (SpriteAlignedPair+$0001),HL
  LD H,$5B
  LD L,B
  LD B,(HL)
  LD L,C
  LD C,(HL)
  LD L,D
  LD D,(HL)
  LD L,E
  LD E,(HL)
SpriteAlignedPair:
  LD HL,$0000             ; its operand: the row's first (AND, OR) pair while
                          ; the others are reversed
  LD A,L
  EXX
  LD H,$5B
  LD L,A
  LD A,(HL)
  EXX
  LD L,A
  LD A,H
  EXX
  LD L,A
  LD A,(HL)
  EXX
  LD H,A
SpriteAlignedPut:
  LD A,(IY+$00)           ; (IY+0), (IY+d1), (IY+d2): AND mask, OR data
  AND B
  OR C
  LD (IY+$00),A
SpriteAlignedCol2In:
  LD A,(IY+$20)           ; its displacement, written by ComposeObject: $20 (4
                          ; cells a column) or $18 (3)
  AND D
  OR H
SpriteAlignedCol2Out:
  LD (IY+$20),A
SpriteAlignedCol3In:
  LD A,(IY+$00)           ; $40 or $30
  AND E
  OR L
SpriteAlignedCol3Out:
  LD (IY+$00),A
  INC IY
  EXX
  DJNZ SpriteAlignedRow
SpriteAlignedSP:
  LD SP,$0000             ; its operand: the caller's SP
  EI
  RET
ComposeShifted:
  ADD A,A                 ; x AND 7 not 0: the shift chain's entry, 4 columns
  LD C,A
  ADD A,A
  LD B,A
  ADD A,A
  ADD A,B
  ADD A,C
  LD C,A
  LD B,$00
  PUSH HL
  LD HL,SpriteShiftChain
  ADD HL,BC
  LD (SpriteShiftEntry+$0001),HL
  POP HL
  LD A,D
  AND $07
  EX AF,AF'
  LD A,D
  AND $04
  JP NZ,ComposeShifted4
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$FFC1
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$FFC1
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$FFC1
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  LD A,$18
  LD (SpriteShiftedCol2In+$0002),A
  LD (SpriteShiftedCol2Out+$0002),A
  ADD A,A
  LD (SpriteShiftedCol3In+$0002),A
  LD (SpriteShiftedCol3Out+$0002),A
  LD A,$48
  LD (SpriteShiftedCol4In+$0002),A
  LD (SpriteShiftedCol4Out+$0002),A
  EX DE,HL
  LD BC,$FFA0
  ADD HL,BC
  EX AF,AF'
  LD C,A
  LD B,$00
  ADD HL,BC
  JP SpriteDrawShifted
ComposeShifted4:
  PUSH HL                 ; y AND 7 >= 4: 4 cells a column
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$FFA1
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$FFA1
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$FFA1
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  PUSH HL
  CALL ComposeCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  CALL ComposeCell
  EX DE,HL
  LD BC,$FF80
  ADD HL,BC
  EX AF,AF'
  LD C,A
  LD B,$00
  ADD HL,BC
  LD A,$20
  LD (SpriteShiftedCol2In+$0002),A
  LD (SpriteShiftedCol2Out+$0002),A
  ADD A,A
  LD (SpriteShiftedCol3In+$0002),A
  LD (SpriteShiftedCol3Out+$0002),A
  LD A,$60
  LD (SpriteShiftedCol4In+$0002),A
  LD (SpriteShiftedCol4Out+$0002),A
SpriteDrawShifted:
  PUSH HL                 ; the shifting drawer: each row into 4 bytes
  POP IY
  DI
  LD (SpriteShiftedSP+$0001),SP
  LD HL,SpriteShiftedShift
  LD (SpriteShiftedJump+$0001),HL
  BIT 0,(IX+$06)
  JP Z,SpriteShiftedPlain
  LD HL,SpriteShiftedMirror
  LD (SpriteShiftedJump+$0001),HL
SpriteShiftedPlain:
  LD L,(IX+$04)
  LD H,(IX+$05)
  LD SP,HL
  LD L,$15
SpriteShiftedRow:
  EXX
  POP HL
  POP BC
  POP DE
SpriteShiftedJump:
  JP SpriteShiftedShift   ; its operand: $A62B (plain) or $A607 (mirrored)
SpriteShiftedMirror:
  LD A,L
  LD L,C
  LD C,A
  LD A,B
  LD B,E
  LD E,A
  LD (SpriteShiftedPair+$0001),HL
  LD H,$5B
  LD L,B
  LD B,(HL)
  LD L,C
  LD C,(HL)
  LD L,D
  LD D,(HL)
  LD L,E
  LD E,(HL)
SpriteShiftedPair:
  LD HL,$0000             ; its operand: the row's first pair while the others
                          ; are reversed
  LD A,L
  EXX
  LD D,$5B
  LD E,A
  LD A,(DE)
  EXX
  LD L,A
  LD A,H
  EXX
  LD E,A
  LD A,(DE)
  EXX
  LD H,A
SpriteShiftedShift:
  EXX                     ; the mask's fill bits ($FF), then the chain
  LD C,$FF
  EXX
  XOR A
SpriteShiftEntry:
  JP SpriteShiftChain     ; its operand: $A633 + 14 (x AND 7)
SpriteShiftChain:
  ADD HL,HL               ; 8 steps of 14 bytes, one bit each: the step entered
                          ; and those after it run
  RL C
  RLA
  SLL E
  RL D
  RL B
  EXX
  RL C
  EXX
  ADD HL,HL
  RL C
  RLA
  SLL E
  RL D
  RL B
  EXX
  RL C
  EXX
  ADD HL,HL
  RL C
  RLA
  SLL E
  RL D
  RL B
  EXX
  RL C
  EXX
  ADD HL,HL
  RL C
  RLA
  SLL E
  RL D
  RL B
  EXX
  RL C
  EXX
  ADD HL,HL
  RL C
  RLA
  SLL E
  RL D
  RL B
  EXX
  RL C
  EXX
  ADD HL,HL
  RL C
  RLA
  SLL E
  RL D
  RL B
  EXX
  RL C
  EXX
  ADD HL,HL
  RL C
  RLA
  SLL E
  RL D
  RL B
  EXX
  RL C
  EXX
  ADD HL,HL
  RL C
  RLA
  SLL E
  RL D
  RL B
  EXX
  RL C
  LD B,A
  LD A,(IY+$00)
  AND C
  OR B
  LD (IY+$00),A
  EXX
SpriteShiftedCol2In:
  LD A,(IY+$20)           ; its displacement, written by ComposeObject: $20 or
                          ; $18
  AND B
  OR C
SpriteShiftedCol2Out:
  LD (IY+$20),A
SpriteShiftedCol3In:
  LD A,(IY+$40)           ; $40 or $30
  AND D
  OR H
SpriteShiftedCol3Out:
  LD (IY+$40),A
SpriteShiftedCol4In:
  LD A,(IY+$60)           ; $60 or $48
  AND E
  OR L
SpriteShiftedCol4Out:
  LD (IY+$60),A
  INC IY
  EXX
  DEC L
  JP NZ,SpriteShiftedRow
SpriteShiftedSP:
  LD SP,$0000             ; its operand: the caller's SP
  EI
  RET

; Give the map cell at HL a new composed char holding what is drawn there now
;
; Input: HL a map cell. Output: DE the new buffer's end (the caller steps back
; to its start), HL, BC, AF changed. A new buffer is ComposeCount's number n,
; at $5CF0 + 8n; ComposeCount goes up by one.
;
; If the cell's char has any of bits 3-6 set in its property byte ($5C00 +
; char): a scratch buffer, the flag unchanged (ComposeHidden: the sprite is
; hidden there). Else the flag (HL + $600) becomes n and the buffer gets the
; char's 8 bytes: from the charset (flag 0 or 1) or from the composed char the
; flag names (ComposeOverSprite: two sprites in one cell).
;
; Called 9-16 times by ComposeObject per object. The most run routine of the
; range (level4: 148302 runs).
;
; Witness: L1 1823882 (beeper48, c1, controls, emptygun, ending2, gameover,
; l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7,
; L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).
ComposeCell:
  LD D,$5C
  LD E,(HL)
  LD A,(DE)
  AND $78
  JP NZ,ComposeHidden
  LD BC,$0600
  ADD HL,BC
  LD A,(HL)
  CP $02
  JP NC,ComposeOverSprite
  LD A,(ComposeCount)
  LD (HL),A
  INC A
  LD (ComposeCount),A
  EX DE,HL
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,(CharsetBase)
  ADD HL,BC
ComposeCopy:
  EX DE,HL
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,$5CE8
  ADD HL,BC
  EX DE,HL
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  RET
ComposeOverSprite:
  LD D,A                  ; the cell holds a composed char already: copy that
                          ; one
  LD A,(ComposeCount)
  LD (HL),A
  INC A
  LD (ComposeCount),A
  LD L,D
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,$5CF0
  ADD HL,BC
  JP ComposeCopy
ComposeHidden:
  LD A,(ComposeCount)     ; a char drawn over sprites: a scratch buffer, no
                          ; flag
  INC A
  LD (ComposeCount),A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,$5CF0
  ADD HL,BC
  EX DE,HL
  RET

; The next composed char's number (2 at each pass's start)
;
; Set to 2 by ComposeObjects, counted up by ComposeCell. The flags 0 and 1 mean
; the map, so the numbers start at 2 ($5D00).
ComposeCount:
  DEFB $00

; The charset of the screen: $7100, or $7A00 when the screen record's +0 is not
; 0 (LoadScreen $ACAD)
;
; Read by DrawDirtyCells, ComposeCell and DrawAllDirtyCells: char c's 8 bytes
; at CharsetBase + 8c.
CharsetBase:
  DEFW CharSet0

; Compose the sprites of all objects for this frame
;
; ComposeCount = 2, then calls ComposeObject for every record of the object
; table $EA8E (30 bytes each) whose +0 is not 0, up to the record whose +0 is
; $FF.
;
; Callers: the frame loop ($E414), the game over ($E35A) and
; ClearOffscreenFlags ($AF52). Output: everything, IX past the table.
;
; Witness: L1 43008 (beeper48, c1, controls, emptygun, ending2, gameover,
; l1end, l1z1left, spotL2Z4-34, spotL3Z7-51, spotL4Z8-69, L1Z1-L1Z6, L2Z1-L2Z7,
; L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43, spotL1Z4-44, spotL1Z4-47).
ComposeObjects:
  LD A,$02
  LD (ComposeCount),A
  LD IX,ObjectTable
ComposeObjectsLoop:
  LD A,(IX+$00)
  AND A
  JP Z,ComposeObjectsNext
  CP $FF
  RET Z
  CALL ComposeObject
ComposeObjectsNext:
  LD BC,$001E
  ADD IX,BC
  JP ComposeObjectsLoop

; A callable copy of BuildMirrorTable: never called
;
; The same code as Start's $AB6A-$AB8C (fill $5B00-$5BFF with the bit-reversed
; bytes) and a RET. No instruction of the game calls or jumps here and no
; recording ran it: known only from the code.
;
; Witness: L1 0 ().
UnusedBuildMirror:
  LD B,$00
  LD H,$5B
UnusedMirrorByte:
  LD L,B
  LD A,B
  LD C,$00
  RLA
  RR C
  RLA
  RR C
  RLA
  RR C
  RLA
  RR C
  RLA
  RR C
  RLA
  RR C
  RLA
  RR C
  RLA
  RR C
  LD (HL),C
  DJNZ UnusedMirrorByte
  RET

; Draw every flagged cell with its attribute, keeping the HUD row's flags
;
; Saves the sentinel byte $6F00 (into RedrawSentinel) and the 30 flags
; $6C21-$6C3E of the HUD row (into SavedHudCells, 30 LDIs each way), calls
; DrawAllDirtyCells, then puts both back.
;
; Callers: LoadScreen ($ACFA), the level's end ($ABE8) and each scroll step
; ($ADD8, $AE0F). Output: everything.
;
; Witness: L1 614 (beeper48, c1, controls, ending, ending2, gameover, l1end,
; spotL3Z7-51, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4,
; spotL1Z4-43).
RedrawScreen:
  LD A,(CellFlagsRow24)
  LD (RedrawSentinel+$0001),A
  LD HL,CellFlags+$21
  LD DE,SavedHudCells
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  CALL DrawAllDirtyCells
  LD DE,CellFlags+$21
  LD HL,SavedHudCells
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
RedrawSentinel:
  LD A,$00                ; its operand: the byte that was at $6F00
  LD (CellFlagsRow24),A
  RET

; The 30 flags of the HUD row $6C21-$6C3E while RedrawScreen runs (32 bytes;
; the last 2 unused)
SavedHudCells:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; Draw the flagged cells and their attributes
;
; Like DrawDirtyCells, and each cell's attribute is set from the attribute
; table (AttrTableHigh: $79 or $82) by its map char. A flag of 1 is cleared
; after the draw; a composed char's flag is left. The sentinel $FF ends the
; scan.
;
; Called by RedrawScreen only. Output: everything.
;
; Witness: L1 614 (beeper48, c1, controls, ending, ending2, gameover, l1end,
; spotL3Z7-51, L1Z1-L1Z6, L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4,
; spotL1Z4-43).
DrawAllDirtyCells:
  LD A,$FF
  LD (CellFlagsRow24),A
  CALL MaskHudCells
  LD HL,CellFlags-1
DrawAllNext:
  XOR A
DrawAllScan:
  INC HL
  OR (HL)
  JP Z,DrawAllScan
  CP $FF
  RET Z
  PUSH HL
  LD C,A
  LD A,H
  ADD A,$FA
  LD H,A
  LD E,(HL)
  ADD A,$F2
  LD H,A
  LD D,$79                ; its operand (AttrTableHigh): the attribute table's
                          ; high byte, $79 or $82 (LoadScreen $AC8D, $ACA1)
  LD A,(DE)
  LD (HL),A
  LD A,H
  SUB $58
  ADD A,A
  ADD A,A
  ADD A,A
  OR $40
  LD H,A
  DEC C
  JP NZ,DrawAllComposed
  EX DE,HL
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,(CharsetBase)
  ADD HL,BC
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  POP HL
  LD (HL),$00
  JP DrawAllNext
DrawAllComposed:
  EX DE,HL                ; flag n >= 2: composed char n
  LD L,C
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,$5CF8
  ADD HL,BC
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  DEC DE
  INC D
  LDI
  POP HL
  JP DrawAllNext

  ORG $ADB9

; Scroll the view down by 8 rows, in two steps of 4
;
; ClearOffscreenFlags, then twice: ShiftMapUp, ShiftMarksUp, ShiftObjects by
; -32 (y), ViewTopRow + 4, WaitFrames 4, RedrawScreen. Then BuildScreenMap, the
; objects of the rows coming in ($FD7D, D = ViewTopRow + $20, E = 8) and
; DrawDirtyCells.
;
; Called from the game loop when Rick's y is $CC or more ($E432).
;
; Witness: L1 71 (beeper48, c1, gameover, L1Z1, L1Z2, L1Z4-L1Z6, L2Z6, L3Z6,
; L3Z8, L3Z10, L4Z3, L4Z5, level1, level3, level4, spotL1Z4-43).
ScrollViewDown:
  CALL ClearOffscreenFlags
  LD B,$02
ScrollDownStep:
  PUSH BC
  CALL ShiftMapUp
  CALL ShiftMarksUp
  LD BC,$FFE0
  CALL ShiftObjects
  LD A,(ViewTopRow)
  ADD A,$04
  LD (ViewTopRow),A
  LD C,$04
  CALL WaitFrames
  CALL RedrawScreen
  POP BC
  DJNZ ScrollDownStep
  CALL BuildScreenMap
  LD A,(ViewTopRow)
  ADD A,$20
  LD D,A
  LD E,$08
  CALL SpawnObjects
  CALL DrawDirtyCells
  RET

; Scroll the view up by 8 rows, in two steps of 4
;
; The mirror of ScrollViewDown: ShiftMapDown, ShiftMarksDown, ShiftObjects by
; +32, ViewTopRow - 4; the objects of the top rows ($FD7D, D = ViewTopRow, E =
; 8). Called when Rick's y is below $60 ($E43B). Scrolled up in L1Z4, L2Z2,
; L3Z8 and L3Z9 and in level2 (11 of the 16).
;
; Witness: L1 16 (L1Z4, L2Z2, L3Z8, L3Z9, level2).
ScrollViewUp:
  CALL ClearOffscreenFlags
  LD B,$02
ScrollUpStep:
  PUSH BC
  CALL ShiftMapDown
  CALL ShiftMarksDown
  LD BC,$0020
  CALL ShiftObjects
  LD A,(ViewTopRow)
  SUB $04
  LD (ViewTopRow),A
  LD C,$04
  CALL WaitFrames
  CALL RedrawScreen
  POP BC
  DJNZ ScrollUpStep
  CALL BuildScreenMap
  LD A,(ViewTopRow)
  LD D,A
  LD E,$08
  CALL SpawnObjects
  CALL DrawDirtyCells
  RET

; Move the map up 4 rows ($6680 -> $6600 ...), flagging every changed cell
;
; $6A00 and $6A80 hold $FF as the end. A cell that changes takes the char 4
; rows below and, if its flag is 0 or 1, the flag 1.
;
; Witness: L1 141 (beeper48, c1, gameover, L1Z1, L1Z2, L1Z4-L1Z6, L2Z6, L3Z6,
; L3Z8, L3Z10, L4Z3, L4Z5, level1, level3, level4, spotL1Z4-43).
ShiftMapUp:
  LD HL,MusicImage+$07FF
  LD DE,MusicImage+$087F
  LD BC,$6BFF
  LD A,$FF
  LD (MusicImage+$0C00),A
  LD (MusicImage+$0C80),A
ShiftMapUpLoop:
  INC DE
  INC HL
  INC BC
  LD A,(DE)
  CP (HL)
  JR Z,ShiftMapUpLoop
  CP $FF
  RET Z
  LD (HL),A
  LD A,(BC)
  CP $02
  JP NC,ShiftMapUpLoop
  LD A,$01
  LD (BC),A
  JP ShiftMapUpLoop

; Move the map down 4 rows, from the bottom, flagging every changed cell
;
; The end markers at $647F and $64FF. Called by ScrollViewUp.
;
; Witness: L1 32 (L1Z4, L2Z2, L3Z8, L3Z9, level2).
ShiftMapDown:
  LD HL,MusicImage+$0B00
  LD DE,MusicImage+$0A80
  LD BC,CellFlagsRow24
  LD A,$FF
  LD (MusicImage+$067F),A
  LD (MusicImage+$06FF),A
ShiftMapDownLoop:
  DEC DE
  DEC HL
  DEC BC
  LD A,(DE)
  CP (HL)
  JP Z,ShiftMapDownLoop
  CP $FF
  RET Z
  LD (HL),A
  LD A,(BC)
  CP $02
  JP NC,ShiftMapDownLoop
  LD A,$01
  LD (BC),A
  JP ShiftMapDownLoop

; Move the composed-char flags (2 and up) 4 rows up, leaving a 1 behind
;
; The end $FF at $7000. Called by ScrollViewDown.
;
; Witness: L1 141 (beeper48, c1, gameover, L1Z1, L1Z2, L1Z4-L1Z6, L2Z6, L3Z6,
; L3Z8, L3Z10, L4Z3, L4Z5, level1, level3, level4, spotL1Z4-43).
ShiftMarksUp:
  LD A,$FF
  LD (CellFlagsEnd),A
  LD HL,CellFlags
  LD BC,$FF80
  LD DE,$0080
ShiftMarksUpNext:
  XOR A
ShiftMarksUpScan:
  INC HL
  OR (HL)
  JP Z,ShiftMarksUpScan
  DEC A
  JP Z,ShiftMarksUpNext
  CP $FE
  RET Z
  ADD HL,BC
  INC A
  LD (HL),A
  ADD HL,DE
  LD (HL),$01
  JP ShiftMarksUpNext

; Move the composed-char flags 4 rows down, leaving a 1 behind
;
; The end $FF at $6AFF, scanning down from $6EFF. Called by ScrollViewUp.
;
; Witness: L1 32 (L1Z4, L2Z2, L3Z8, L3Z9, level2).
ShiftMarksDown:
  LD A,$FF
  LD (MusicImage+$0CFF),A
  LD HL,CellFlagsRow24
  LD BC,$FF80
  LD DE,$0080
ShiftMarksDownNext:
  XOR A
ShiftMarksDownScan:
  DEC HL
  OR (HL)
  JP Z,ShiftMarksDownScan
  DEC A
  JP Z,ShiftMarksDownNext
  CP $FE
  RET Z
  ADD HL,DE
  INC A
  LD (HL),A
  ADD HL,BC
  LD (HL),$01
  JP ShiftMarksDownNext

  ORG $AF18

; Clear the flags of the map rows above and below the view, then compose the
; objects
;
; Clears $6B00-$6BFF and $6F00-$6FFF with PUSHes (interrupts off), then
; ComposeObjects. Called at the start of both scrolls.
;
; Witness: L1 87 (beeper48, c1, gameover, L1Z1, L1Z2, L1Z4-L1Z6, L2Z2, L2Z6,
; L3Z6, L3Z8-L3Z10, L4Z3, L4Z5, level1-level4, spotL1Z4-43).
ClearOffscreenFlags:
  DI
  LD (ClearFlagsSP+$0001),SP
  LD SP,CellFlags
  LD B,$08
  LD HL,$0000
ClearAboveLoop:
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  DJNZ ClearAboveLoop
  LD SP,CellFlagsEnd
  LD B,$08
ClearBelowLoop:
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  DJNZ ClearBelowLoop
ClearFlagsSP:
  LD SP,$0000             ; its operand: the caller's SP
  EI
  CALL ComposeObjects
  RET
