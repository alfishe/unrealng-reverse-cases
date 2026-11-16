; --------------------------------------------------------------------------------------------------------------------
; scroll.asm: The scroll: map, metatiles, the shadow and the column buffer
; --------------------------------------------------------------------------------------------------------------------

; Cut the next cells of a column from a metatile as stored
;
; A = the metatile: MetatileAddress; the column MetaColumn's 4 cells (9 bytes
; each) to ColumnPtr.
;
; Witness: L1 14196 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).
CutMetatile:
  CALL MetatileAddress
  LD A,(MetaColumn)
  LD E,A
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,E
  LD D,$00
  LD E,A
  ADD HL,DE
  LD DE,(ColumnPtr)
  LD A,$04
l_8756:
  EX AF,AF'
  LD A,(HL)
  INC HL
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LD (DE),A
  INC E
  LD BC,$001B
  ADD HL,BC
  EX AF,AF'
  DEC A
  JR NZ,l_8756
  LD (ColumnPtr),DE
  RET

; Cut a column from a metatile mirrored left to right (the bytes through
; BitReverse)
;
; Witness: L1 420 (boss, force, hiscore, hiscore-typed, restart, l1-l4, l6,
; l7).
CutMetatileMirrored:
  CALL MetatileAddress
  LD A,(MetaColumn)
  XOR $03
  LD E,A
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,E
  LD D,$00
  LD E,A
  ADD HL,DE
  LD DE,(ColumnPtr)
  CALL MirrorCell
  CALL MirrorCell
  CALL MirrorCell
  CALL MirrorCell
  LD (ColumnPtr),DE
  RET

; Copy one cell's 8 pixel bytes through BitReverse, then its attribute
;
; Witness: L1 1680 (boss, force, hiscore, hiscore-typed, restart, l1-l4, l6,
; l7).
MirrorCell:
  LD A,(HL)
  EX AF,AF'
  INC HL
  LD B,$5D
  LD IXL,$08
l_87A6:
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC HL
  INC DE
  DEC IXL
  JP NZ,l_87A6
  EX AF,AF'
  LD (DE),A
  INC E
  LD BC,$001B
  ADD HL,BC
  RET

; Cut a column from a metatile upside down
;
; Witness: L1 2071 (boss, deaths-l7, restart, l1-l8).
CutMetatileFlipped:
  CALL MetatileAddress
  LD DE,$008F
  ADD HL,DE
  LD A,(MetaColumn)
  XOR $03
  LD E,A
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,E
  LD E,A
  AND A
  SBC HL,DE
  LD BC,$001C
  LD DE,(ColumnPtr)
  LD A,$04
l_87D6:
  EX AF,AF'
  LD IXL,$08
l_87DA:
  LD A,(HL)
  LD (DE),A
  DEC HL
  INC E
  DEC IXL
  JP NZ,l_87DA
  LD A,(HL)
  LD (DE),A
  INC E
  AND A
  SBC HL,BC
  EX AF,AF'
  DEC A
  JR NZ,l_87D6
  LD (ColumnPtr),DE
  RET

; Cut a column from a metatile mirrored and upside down
;
; Witness: L1 220 (boss, l x5).
CutMetatileBoth:
  CALL MetatileAddress
  LD DE,$008F
  ADD HL,DE
  LD A,(MetaColumn)
  LD E,A
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,E
  LD E,A
  AND A
  SBC HL,DE
  LD DE,(ColumnPtr)
  LD A,$04
l_880B:
  EX AF,AF'
  LD B,$5D
  LD IXL,$08
l_8811:
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  DEC HL
  INC E
  DEC IXL
  JP NZ,l_8811
  LD A,(HL)
  LD (DE),A
  INC E
  AND A
  LD BC,$001C
  SBC HL,BC
  EX AF,AF'
  DEC A
  JR NZ,l_880B
  LD (ColumnPtr),DE
  RET

; HL = the metatile A's data below the level's map (LevelMetatiles - (A + 1) x
; 144)
;
; Witness: L1 18787 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).
MetatileAddress:
  INC A
  ADD A,A
  ADD A,A
  LD H,$00
  LD L,A
  ADD HL,HL
  ADD HL,HL
  PUSH HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  POP DE
  ADD HL,DE
  EX DE,HL
  LD HL,(LevelMetatiles)
  SBC HL,DE
  RET

; Put the 20 play rows on the screen: attributes copied, scenery shifted one
; pixel left, changed sprite cells copied
;
; For each row of RowTable: the row's attributes copied from PlayAttrs to the
; screen (LDDR, columns 1-30); the row walked from the right by its SolidMap
; tags, scenery cells shifted on the screen (RowTable holds the screen pages,
; $40xx), other cells copied from the pixel shadow to the screen. While the map
; moves (ScrollHalted $7A8E = 0) the runs of scenery cells are shifted one
; pixel left through the unrolled chain ShiftRun; while it stands they are
; skipped. Sprite cells (tag 1 to $DB) are copied from the pixel shadow and
; DrawnMap set; untagged cells with DrawnMap 1 are cleared; every tag but $9C
; is cleared, $9C only when FrameCounter AND 7 = 7 ($88CD).
;
; Witness: L1 33972 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
ScrollRows:
  LD IX,RowTable

; l_8846
;
; Used by the routine at l_8869.
l_8846:
  LD A,(IX+$03)
  AND A
  RET Z
  LD D,A
  ADD A,$20
  LD H,A
  LD E,(IX+$02)
  DEC E
  LD L,E
  LD BC,$001E
  LDDR
  LD A,D
  ADD A,$26
  LD D,A
  LD E,(IX+$02)
  LD H,(IX+$01)
  LD L,E
  LD BC,$0004
  ADD IX,BC

; l_8869
;
; Used by the routine at ShiftRunDone.
l_8869:
  LD A,E
  AND $1F
  JP Z,l_8846
  LD A,(DE)
  CP $DC
  JP C,l_8881
  LD A,(ScrollHalted)
  AND A
  JP Z,l_88E6
  DEC E
  DEC L
  JP l_8869
l_8881:
  PUSH HL
  AND A
  JP Z,l_88B3
  LD A,H
  ADD A,$20
  LD B,A
  LD C,L
  LD A,(BC)
  LD (HL),A
  INC B
  INC H
  LD A,(BC)
  LD (HL),A
  INC B
  INC H
  LD A,(BC)
  LD (HL),A
  INC B
  INC H
  LD A,(BC)
  LD (HL),A
  INC B
  INC H
  LD A,(BC)
  LD (HL),A
  INC B
  INC H
  LD A,(BC)
  LD (HL),A
  INC B
  INC H
  LD A,(BC)
  LD (HL),A
  INC B
  INC H
  LD A,(BC)
  LD (HL),A
  LD B,D
  INC D
  INC D
  INC D
  LD A,$01
  LD (DE),A
  JP l_88CD
l_88B3:
  LD B,D
  INC D
  INC D
  INC D
  LD A,(DE)
  AND A
  JP Z,l_88CD
  XOR A
  LD (HL),A
  INC H
  LD (HL),A
  INC H
  LD (HL),A
  INC H
  LD (HL),A
  INC H
  LD (HL),A
  INC H
  LD (HL),A
  INC H
  LD (HL),A
  INC H
  LD (HL),A
  LD (DE),A
l_88CD:
  LD D,B
  LD A,(DE)
  CP $9C
  JP NZ,l_88DE
  LD A,(FrameCounter)
  AND $07
  CP $07
  JP NZ,l_88E0
l_88DE:
  XOR A
  LD (DE),A
l_88E0:
  POP HL
  DEC E
  DEC L
  JP l_8869
l_88E6:
  LD BC,ShiftRunDone
  PUSH BC
  PUSH HL
  LD B,$01
l_88ED:
  DEC E
  LD A,E
  AND $1F
  JP Z,l_88FB
  INC B
  LD A,(DE)
  CP $DC
  JP NC,l_88ED
l_88FB:
  LD A,B
  XOR $1F
  LD L,A
  ADD A,A
  ADD A,L
  LD L,A
  LD H,$00
  LD BC,ShiftRun
  ADD HL,BC
  POP BC
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  LD H,B
  LD L,C
  RET

; The unrolled RL (HL) / DEC L chain, entered 3 bytes a cell from its end to
; shift a run of cells one pixel left
;
; Witness: L1 255048 (boss, deaths-l7, force, restart, l1-l8).
ShiftRun:
  RL (HL)
  DEC L

; the chain from 30 cells
;
; Witness: L1 265656 (boss, deaths-l7, force, restart, l1-l8).
ShiftRun30:
  RL (HL)
  DEC L

; the chain from 29 cells
;
; Witness: L1 276704 (boss, deaths-l7, force, restart, l1-l8).
ShiftRun29:
  RL (HL)
  DEC L

; the chain from 28 cells
;
; Witness: L1 288496 (boss, deaths-l7, force, restart, l1-l8).
ShiftRun28:
  RL (HL)
  DEC L

; the chain from 27 cells
;
; Witness: L1 300088 (boss, deaths-l7, force, restart, l1-l8).
ShiftRun27:
  RL (HL)
  DEC L

; the chain from 26 cells
;
; Witness: L1 311440 (boss, deaths-l7, force, restart, l1-l8).
ShiftRun26:
  RL (HL)
  DEC L

; the chain from 25 cells
;
; Witness: L1 349464 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).
ShiftRun25:
  RL (HL)
  DEC L

; the chain from 24 cells
;
; Witness: L1 374656 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).
ShiftRun24:
  RL (HL)
  DEC L

; the chain from 23 cells
;
; Witness: L1 397144 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).
ShiftRun23:
  RL (HL)
  DEC L

; the chain from 22 cells
;
; Witness: L1 420184 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).
ShiftRun22:
  RL (HL)
  DEC L

; the chain from 21 cells
;
; Witness: L1 443376 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).
ShiftRun21:
  RL (HL)
  DEC L

; the chain from 20 cells
;
; Witness: L1 478448 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).
ShiftRun20:
  RL (HL)
  DEC L

; the chain from 19 cells
;
; Witness: L1 503472 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).
ShiftRun19:
  RL (HL)
  DEC L

; the chain from 18 cells
;
; Witness: L1 532976 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).
ShiftRun18:
  RL (HL)
  DEC L

; the chain from 17 cells
;
; Witness: L1 580696 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).
ShiftRun17:
  RL (HL)
  DEC L

; the chain from 16 cells
;
; Witness: L1 629912 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, restart, l1-l8).
ShiftRun16:
  RL (HL)
  DEC L

; the chain from 15 cells
;
; Witness: L1 718528 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).
ShiftRun15:
  RL (HL)
  DEC L

; the chain from 14 cells
;
; Witness: L1 759776 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).
ShiftRun14:
  RL (HL)
  DEC L

; the chain from 13 cells
;
; Witness: L1 818984 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).
ShiftRun13:
  RL (HL)
  DEC L

; the chain from 12 cells
;
; Witness: L1 869872 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).
ShiftRun12:
  RL (HL)
  DEC L

; the chain from 11 cells
;
; Witness: L1 947552 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).
ShiftRun11:
  RL (HL)
  DEC L

; the chain from 10 cells
;
; Witness: L1 1014688 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).
ShiftRun10:
  RL (HL)
  DEC L

; the chain from 9 cells
;
; Witness: L1 1212288 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).
ShiftRun9:
  RL (HL)
  DEC L

; the chain from 8 cells
;
; Witness: L1 1527280 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).
ShiftRun8:
  RL (HL)
  DEC L

; the chain from 7 cells
;
; Witness: L1 2032696 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).
ShiftRun7:
  RL (HL)
  DEC L

; the chain from 6 cells
;
; Witness: L1 2289541 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).
ShiftRun6:
  RL (HL)
  DEC L

; the chain from 5 cells
;
; Witness: L1 2427765 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).
ShiftRun5:
  RL (HL)
  DEC L

; the chain from 4 cells
;
; Witness: L1 2679349 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).
ShiftRun4:
  RL (HL)
  DEC L

; the chain from 3 cells
;
; Witness: L1 3179797 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).
ShiftRun3:
  RL (HL)
  DEC L

; the chain from 2 cells
;
; Witness: L1 3432452 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).
ShiftRun2:
  RL (HL)
  DEC L

; the last cell, then the next pixel line
;
; Witness: L1 3510244 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).
ShiftRun1:
  RL (HL)
  INC H
  LD L,C
  AND A
  RET

; Where the chain returns: back into ScrollRows
;
; Witness: L1 438780 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).
ShiftRunDone:
  LD H,B
  LD L,E
  JP l_8869

; The scroll's step for this pass
;
; ScrollRows; FrameCounter + 1, ScrollStep = its low 3 bits. Step 0: the next
; metatile column (every 4th a new block column: MapColumn + 1), the column
; buffer flushed into column 31; the other steps cut one metatile of the block
; column each (CutNextMetatile).
;
; Witness: L1 33318 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
Scroll:
  CALL ScrollRows
  LD A,(ScrollStep)
  CP $07
  CALL Z,ScrollAttrs
  LD A,(FrameCounter)
  INC A
  LD (FrameCounter),A
  AND $07
  LD (ScrollStep),A
  JR Z,ScrollNewColumn
  CP $02
  RET C
  CP $07
  RET NC
  LD A,(ScrollHalted)
  AND A
  RET NZ
  JR CutNextMetatile
ScrollNewColumn:
  LD HL,(MapBlockPtr)     ; step 0
  LD A,(MetaColumn)
  INC A
  AND $03
  LD (MetaColumn),A
  JR NZ,l_89BB
  LD A,(MapColumn)
  INC A
  LD (MapColumn),A
  LD DE,$0005
  ADD HL,DE
  LD (MapBlockPtr),HL
l_89BB:
  LD (MapReadPtr),HL
  LD A,(ScrollHalted)
  AND A
  RET NZ
  LD HL,ColumnBuffer
  LD (ColumnPtr),HL
  LD IX,RowTable
  LD B,$14
l_89CF:
  LD E,(IX+$00)
  LD D,(IX+$01)
  LD A,(HL)
  LD (DE),A
  INC L
  INC D
  LD A,(HL)
  LD (DE),A
  INC L
  INC D
  LD A,(HL)
  LD (DE),A
  INC L
  INC D
  LD A,(HL)
  LD (DE),A
  INC L
  INC D
  LD A,(HL)
  LD (DE),A
  INC L
  INC D
  LD A,(HL)
  LD (DE),A
  INC L
  INC D
  LD A,(HL)
  LD (DE),A
  INC L
  INC D
  LD A,(HL)
  LD (DE),A
  INC L
  INC D
  LD A,(IX+$03)
  ADD A,$20
  LD D,A
  LD A,(HL)
  AND $7F
  LD (DE),A
  LD A,D
  ADD A,$06
  LD D,A
  LD A,(HL)
  RLCA
  AND $01
  CPL
  INC A
  LD (DE),A
  INC L
  LD DE,$0004
  ADD IX,DE
  DJNZ l_89CF
  RET
CutNextMetatile:
  LD HL,(MapReadPtr)      ; a map byte: bits 0-5 the metatile, bits 6-7 the
                          ; drawer (as stored, mirrored, upside down, both)
  LD A,(HL)
  AND $3F
  LD D,A
  LD A,(HL)
  INC HL
  LD (MapReadPtr),HL
  AND $C0
  JR NZ,l_8A28
  LD A,D
  CALL CutMetatile
  RET
l_8A28:
  CP $40
  JR NZ,l_8A31
  LD A,D
  CALL CutMetatileMirrored
  RET
l_8A31:
  CP $80
  JR NZ,l_8A3A
  LD A,D
  CALL CutMetatileFlipped
  RET
l_8A3A:
  LD A,D
  CALL CutMetatileBoth
  RET

; Write B into the four sprite drawers' column limit
;
; Witness: L1 94 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7,
; gameover, hiscore, hiscore-typed, restart, l2-l8).
SetDrawLimit:
  LD A,B

; SetDrawLimitA
SetDrawLimitA:
  LD (l_8D09+$0010),A     ; the same with A (the levels' code calls it)
  LD (l_8D75+$000E),A
  LD (l_8DE1+$000E),A
  LD (l_8E3B+$000E),A
  RET

; Draw the R-TYPE logo: the letters fly in and settle, with the stars and the
; scroll running
;
; Witness: L1 17 (c1, ending, gameover, hiscore, l1-l7).
TitleLogo:
  CALL PlayStars
  LD BC,$081F
l_8A53:
  LD A,$26
l_8A55:
  PUSH BC
  PUSH AF
  CALL DrawGame
  POP AF
  POP BC
  INC A
  CP $2C
  JR NZ,l_8A55
  PUSH BC
  CALL StarTask
  CALL ScrollRows
  POP BC
  DEC C
  DEC C
  LD A,C
  CP $01
  JR NZ,l_8A53
  LD BC,$0801
l_8A73:
  LD E,$26
l_8A75:
  PUSH BC
  PUSH DE
  LD HL,CollapseColumns
  LD A,E
  SUB $26
  ADD A,L
  LD L,A
  LD A,C
  CP (HL)
  JR C,l_8A84
  LD C,(HL)
l_8A84:
  LD A,E
  CALL DrawGame
  POP DE
  POP BC
  INC E
  LD A,E
  CP $2C
  JR NZ,l_8A75
  PUSH BC
  CALL StarTask
  CALL ScrollRows
  POP BC
  INC C
  INC C
  LD A,C
  CP $1B
  JR NZ,l_8A73
  LD BC,$FF01
l_8AA2:
  PUSH BC
  LD A,$2C
  CALL DrawGame
  LD BC,$0801
  CALL LogoRow
  POP BC
  LD A,C
  ADD A,$04
  LD C,A
  INC B
  INC B
  LD A,B
  CP $0E
  JR C,l_8AA2
  LD B,$04
  CALL WaitFrames
  NOP
  LD BC,$0801
l_8AC3:
  PUSH BC
  PUSH BC
  LD A,B
  ADD A,$05
  LD B,A
  LD C,$1D
  LD A,$2C
  CALL DrawGame
  POP BC
  CALL LogoRow
  POP BC
  INC B
  LD A,B
  CP $0E
  JR NZ,l_8AC3
  LD HL,PlayAttrs
  LD BC,$0160
  LD A,$45
  CALL FillBlock
  RET

; Draw the logo letters along a row, run the stars and the scroll once
;
; Witness: L1 170 (c1, ending, gameover, hiscore, l1-l7).
LogoRow:
  LD A,$26
l_8AE9:
  PUSH BC
  PUSH AF
  CALL DrawGame
  POP AF
  POP BC
  INC C
  INC C
  INC C
  INC C
  INC C
  INC A
  CP $2C
  JR NZ,l_8AE9
  PUSH BC
  CALL StarTask
  CALL ScrollRows
  CALL ClearHits
  POP BC
  RET

; Call the control method's reader through ControlVector
;
; Witness: L1 36240 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
ReadControls:
  LD HL,(ControlVector)
  JP (HL)

; Read Interface 2 (half-row $F7FE, keys 1-5: XOR $BF, AND $1F, no table)
;
; Witness: L1 123263 (c1, ctl-if2, ctl-kempston, ctl-sinclair, gameover,
; hiscore).
ReadIf2:
  LD A,$F7
  IN A,($FE)
  XOR $BF
  AND $1F
  JR ControlDetach

; Read the six DefinedKeys into the control bits
;
; Witness: L1 158840 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
ReadKeys:
  LD HL,DefinedKeys
  JR ReadKeysFrom

; Read the Kempston port $1F into the control bits
;
; Witness: L1 123262 (c1, ctl-if2, ctl-kempston, ctl-sinclair, gameover,
; hiscore).
ReadKempston:
  IN A,($1F)
  AND $1F
  JR Z,ControlDetach
  LD B,A
  AND $03
  LD A,B
  JR Z,ControlDetach
  XOR $03

; ControlDetach
;
; Used by the routines at ReadIf2, ReadKempston and ReadSinclair.
ControlDetach:
  LD C,A                  ; the joystick readers' detach key (DetachKey)
  LD HL,DetachKey
  JR ReadDetach

; Read the Sinclair joystick (half-row $EFFE, keys 6-0, through BitReverse)
;
; Witness: L1 123264 (c1, ctl-if2, ctl-kempston, ctl-sinclair, gameover,
; hiscore).
ReadSinclair:
  LD A,$EF
  IN A,($FE)
  LD B,$5D
  LD C,A
  LD A,(BC)
  RRCA
  RRCA
  RRCA
  XOR $BF
  AND $1F
  JR ControlDetach
; This entry point is used by the routine at ReadKeys.
ReadKeysFrom:
  LD C,$00                ; the keys at HL into the bits
  CALL TestKey
  JR NZ,l_8B47
  SET 0,C
l_8B47:
  CALL TestKey
  JR NZ,l_8B4E
  SET 1,C
l_8B4E:
  CALL TestKey
  JR NZ,l_8B55
  SET 3,C
l_8B55:
  CALL TestKey
  JR NZ,l_8B5C
  SET 2,C
l_8B5C:
  CALL TestKey
  JR NZ,ReadDetach
  SET 4,C

; ReadDetach
;
; Used by the routines at ControlDetach and ReadSinclair.
ReadDetach:
  CALL TestKey            ; the detach key into bit 5; the bits stored in
                          ; ControlBits
  JR NZ,l_8B6A
  SET 5,C
l_8B6A:
  LD A,C
  AND A
  LD (ControlBits),A
  RET

; Read the key (port, mask) at HL: Z when pressed; HL past the pair
;
; Witness: L1 1322831 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
TestKey:
  LD A,(HL)
  IN A,($FE)
  INC HL
  AND (HL)
  INC HL
  RET

; Pause: CAPS SHIFT + 1 pauses, CAPS SHIFT + 2 goes on
;
; Returns at once unless half-row $FEFE reads CAPS SHIFT alone (of its low 4
; keys) and half-row $F7FE key 1 alone. Paused: interrupts off (the sound and
; stars stop), "GAME PAUSED" printed over and over until CAPS SHIFT and key 2
; alone are down; then the text row cleared, interrupts on, DrawHud. There is
; no abort key: the game only ends when the lives and credits run out.
;
; Witness: L1 33318 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
CheckPause:
  CALL ReadRow0
  RET NZ
  CALL ReadRow1
  RET NZ
  DI
  CALL ClearTextRow
l_8B83:
  CALL ReadRow0
  JR NZ,l_8B96
  CALL ReadRow1
  CP $02
  JR NZ,l_8B96
  CALL ClearTextRow
  EI
  JP DrawHud
l_8B96:
  LD HL,PausedText
  LD C,$0A
  CALL PrintRow22
  JR l_8B83

; A = keys 1-4 of half-row $F7FE as bits (pressed = 1); Z when key 1 alone
;
; Witness: L1 68 (pause).
ReadRow1:
  LD A,$F7
  JR l_8BA6

; A = CAPS SHIFT, Z, X, C of half-row $FEFE; Z when CAPS SHIFT alone
;
; Witness: L1 34503 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
ReadRow0:
  LD A,$FE

; l_8BA6
;
; Used by the routine at ReadRow1.
l_8BA6:
  IN A,($FE)
  CPL
  AND $0F
  CP $01
  RET

; Set the ship up for a life
;
; The first play (FirstPlay 0): ShieldTimer $38 and the fly-in from the left
; (ShipEntry 1); later lives: ShieldTimer $20 at the set place.
;
; Witness: L1 47 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7,
; gameover, hiscore, hiscore-typed, restart, l2-l8).
StartPlay:
  LD HL,FirstPlay
  LD A,(HL)
  AND A
  JR NZ,l_8BD3
  INC (HL)
  LD A,$38
  LD (ShieldTimer),A
  LD A,$0A
  LD (ShipRow),A
  LD A,$C9
  LD (ShieldControls),A
  LD A,$FF
  LD (ShipColumn),A
  XOR A
  LD (ShipFrame),A
  INC A
  LD (ShipEntry),A
  RET
l_8BD3:
  LD A,$20
  LD (ShieldTimer),A
  LD A,$0A
  LD (ShipRow),A
  LD A,$08
  LD (ShipColumn),A
  LD A,$03
  LD (ShipFrame),A
  RET

; The CONTINUE screen: count down while fire may be pressed
;
; Witness: L1 3 (continue, gameover, hiscore).
Continue:
  LD HL,$5800
  LD BC,$0300
  LD A,$45
  CALL FillBlock
  CALL ClearScreen
  LD HL,ContinueText
  LD BC,$0308
  CALL PrintTextNormal
  LD HL,PressFireText
  LD BC,$1307
  CALL PrintTextNormal
  LD HL,CreditText
  LD BC,$1609
  CALL PrintTextNormal
  LD B,$0A
  LD A,$02
  LD (ContinueRow),A
l_8C18:
  PUSH BC
  CALL BigDigit
  LD HL,$2281
  CALL PlaySound
  LD A,(ContinueRow)
  INC A
  INC A
  LD (ContinueRow),A
  LD A,$50
l_8C2C:
  EX AF,AF'
  LD B,$01
  CALL WaitFrames
  CALL ReadControls
  BIT 4,A
  JR NZ,l_8C59
  LD HL,$5A60
  LD A,(FrameCounter)
  INC A
  LD (FrameCounter),A
  RRCA
  AND $07
  ADD A,$40
  XOR $07
  LD (HL),A
  LD BC,$0020
  CALL FillBlock
  EX AF,AF'
  DEC A
  JR NZ,l_8C2C
  POP BC
  DJNZ l_8C18
  RET
l_8C59:
  POP BC
  AND A
  RET

; Draw the countdown digit as block characters
;
; Witness: L1 21 (continue, gameover, hiscore).
BigDigit:
  LD A,B
  ADD A,A
  ADD A,A
  ADD A,A
  LD H,$00
  LD L,A
  LD DE,Font+$0070
  ADD HL,DE
  LD BC,$080B
l_8C6A:
  PUSH HL
  PUSH BC
  LD A,(HL)
l_8C6D:
  LD HL,Font+$000B
  RLCA
  PUSH AF
  JR C,l_8C75
  INC HL
l_8C75:
  CALL PrintTextNormal
  LD A,C
  CP $13
  JR NC,l_8C80
  POP AF
  JR l_8C6D
l_8C80:
  POP AF
  POP BC
  POP HL
  INC HL
  INC B
  LD A,B
  CP $10
  JR C,l_8C6A
  RET

; Move the ship in at the first start (ShipEntry 1, then 2), then hand it to
; the controls
;
; Witness: L1 33322 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
ShipFlyIn:
  LD A,(ShipEntry)
  AND A
  RET Z
  LD BC,(ShipColumn)
  CP $01
  JR NZ,l_8CB0
  INC C
  LD A,C
  CP $1C
  JR NZ,l_8CA3
  LD A,$02
  LD (ShipEntry),A
l_8CA3:
  LD A,$03
l_8CA5:
  LD (ShipColumn),BC
  CALL DrawGame
  CALL ShipShield
  RET
l_8CB0:
  DEC C
  LD A,$04
  CP C
  JR NZ,l_8CA5
  XOR A
  LD (ShipEntry),A
  LD (ShieldControls),A
  LD A,$03
  LD (ShipFrame),A
  INC A
  JR l_8CA5

; Meant to stop the three channels; frees channel 3 only (bits $82 and $81 mean
; the first free channel, which is channel 3 again)
;
; Witness: L1 46 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair, deaths-l7,
; gameover, hiscore, hiscore-typed, restart).
Silence:
  LD HL,$0083
  PUSH HL
  CALL PlaySound
  POP HL
  DEC L
  PUSH HL
  CALL PlaySound
  POP HL
  DEC L
  CALL PlaySound
  RET

; Scroll the attribute shadow and the solid map one cell left (unless
; ScrollHalted)
;
; Witness: L1 4150 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, ending, force, gameover, hiscore, hiscore-typed, pause, restart,
; l1-l8).
ScrollAttrs:
  LD A,(ScrollHalted)
  AND A
  RET NZ
  LD DE,PlayAttrs+$0001
  LD HL,PlayAttrs+$0002
  LD A,$14
  CALL ScrollAttrRows
  LD DE,SolidMap+$0001
  LD HL,SolidMap+$0002
  LD A,$14

; LDIR a run of each of A rows of 32
;
; Witness: L1 134640 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, force, gameover, hiscore, hiscore-typed, pause, restart, l1-l8).
ScrollAttrRows:
  LD BC,$001E
  LDIR
  INC DE
  INC E
  INC HL
  INC L
  DEC A
  JR NZ,ScrollAttrRows
  RET
