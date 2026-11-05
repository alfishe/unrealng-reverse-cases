; --------------------------------------------------------------------------------------------------------------------
; objgrid.asm: the free-slot search, the collision grid and the jump-table dispatch
;
; The collision test of Zynaps is a bitmap grid rebuilt every frame: ClearHitGrid zeroes $FC00-$FD8F, MarkEnemyGrid
; ORs the collision bit (+$24) of each of the 8 enemy slots ($F398-$F4CC) into the X bytes ($FC00, one byte a quarter
; column) and the Y bytes ($FD00, one byte an eighth of a row) the object covers, and TestHitGrid ORs those bytes back
; over the 8 friendly records (the player $F36C, the four laser shots $F4F8-$F57C, the two side-weapon slots
; $F5A8/$F5D4 and the sight $F600). The AND of the X union and the Y union is the set of enemies that overlap the
; record; it goes into the record's +$0D, and the union for the player and the active laser shots goes into $80BB,
; which every enemy handler tests with its own bit.
;
; The grid routines walk the records and the grid with SP (POP is the fastest read on the Z80): each saves SP into the
; operand of its final LD SP,$0000 first and runs with interrupts on, so the interrupt pushes land in the record or
; grid bytes below SP; the game's interrupt handler is short and those bytes are rebuilt the next frame.
;
; JumpTable ($91E2) is the dispatch every table-driven routine uses: HL a table of words, A the index; it jumps to the
; word, so the target's RET returns to the caller of JumpTable.
; --------------------------------------------------------------------------------------------------------------------

; find a free record among the 16 from $F36C (unused)
;
; IY = the first of the 16 records of 44 bytes from $F36C whose +$08 bit 7
; (active) is clear, NC; carry when all 16 are in use. Nothing in the image
; calls or jumps here and no recording ran it (0 executions in 48K c1, 48K c2):
; a left-over; the wave launcher uses TakeEnemySlot ($938D).
FindFreeObjectSlot:
  LD IY,PlayerObject
  LD DE,$002C
  LD B,$10
  OR A
FindFreeSlotLoop:
  BIT 7,(IY+$08)          ; active: the next record
  JR Z,FindFreeSlotDone
  ADD IY,DE
  DJNZ FindFreeSlotLoop
  SCF
FindFreeSlotDone:
  RET                     ; NC: IY free; carry: none

; mark the 8 enemy slots' collision bits in the grid
;
; Called once a frame from the play loop at $AA96 (331 entries in 48K c2). C =
; the collision bit, 1 for the slot $F398 and rotated left for each next slot,
; so slot n owns bit n. For each active and visible slot (+$08 bits 7 and 5):
; its sprite descriptor (+0/+1, IX) gives the width +$0B and the height +$08;
; the X position (+3/+4, in 1/4 columns) picks the first of the X bytes at
; $FC00, every 4th byte over the width plus the last gets the bit; the Y
; position (+5/+6, in 1/8 rows) picks the Y byte at $FD00, every 8th byte over
; the height gets the bit, the rows whose bit in the row mask +$0B is clear
; excepted (a big enemy's rows out of play).
;
; Reads the records with SP (POP IX, POP HL); SP is kept in the operand at
; $9144.
MarkEnemyGrid:
  LD (MarkGridRestoreSp+$0001),SP
  LD C,$01
  EXX
  LD IY,EnemyObjects
  LD DE,$002C
  LD B,$08
MarkGridObject:
  EXX                     ; the next slot: skip unless active and visible
  BIT 7,(IY+$08)
  JR Z,MarkGridNextObject
  BIT 5,(IY+$08)
  JR Z,MarkGridNextObject
  LD SP,IY
  POP IX
  INC SP
  POP HL
  LD A,L
  AND $C0
  OR H
  RLCA
  RLCA
  LD B,(IX+$0B)
  DEC B
  LD H,$FC
  LD L,A
  LD E,$04
MarkGridColumns:
  LD A,(HL)               ; the bit into every 4th X byte, one a column of the
                          ; width
  OR C
  LD (HL),A
  LD A,L
  ADD A,E
  LD L,A
  DJNZ MarkGridColumns
  DEC L
  LD A,(HL)
  OR C
  LD (HL),A
  POP HL
  LD A,L
  AND $E0
  OR H
  RLCA
  RLCA
  RLCA
  LD B,(IX+$08)
  DEC B
  LD H,$FD
  LD L,A
  LD E,$08
  LD D,(IY+$0B)
  SLA D
  JP C,MarkGridRow
  JR Z,MarkGridNextObject
MarkGridSkipRows:
  DEC B                   ; leading rows outside the row mask: not marked
  SLA D
  JR C,MarkGridRow
  JP MarkGridSkipRows
MarkGridRowLoop:
  SLA D                   ; the next row: in the mask?
  JR NC,MarkGridRowOff
MarkGridRow:
  LD A,(HL)               ; the bit into the Y byte of this row
  OR C
  LD (HL),A
  LD A,L
  ADD A,E
  LD L,A
  DJNZ MarkGridRowLoop
MarkGridLastRow:
  DEC L                   ; the last Y byte of the object
  LD A,(HL)
  OR C
  LD (HL),A
MarkGridNextObject:
  RLC C                   ; the next slot's bit
  EXX
  ADD IY,DE
  DJNZ MarkGridObject
MarkGridRestoreSp:
  LD SP,$0000             ; SP back (the operand written at $90CB)
  RET
MarkGridRowOff:
  JR Z,MarkGridLastRow    ; a row outside the mask: step over it
  LD A,L
  ADD A,E
  LD L,A
  DJNZ MarkGridRowLoop
  JR MarkGridLastRow

; the overlap masks of the player, the shots and the weapons
;
; Called once a frame from $A9ED (494 entries in 48K c2, 2 % of play's time).
; For the 8 records from $F36C (the player, then $F4F8 = $F36C + $018C and
; every 44 bytes on: the four laser shots, the plasma/missile slots $F5A8 and
; $F5D4, the sight $F600): OR of the X bytes over the width (the player's width
; less one) and OR of the Y bytes over the height (4 bytes an eighth of a row
; step, read with POP); the AND of both is the set of enemy bits this record
; touches, stored in +$0D. The union for the first five records (the player and
; the lasers), active ones only, goes into $80BB, the laser-hit mask the enemy
; handlers test. SP is kept in the operand at $91C3.
TestHitGrid:
  LD (TestGridRestoreSp+$0001),SP
  LD IY,PlayerObject
  LD DE,$018C
  LD C,$00
  LD B,$08
TestGridObject:
  EXX                     ; the next record: the descriptor and its width
  LD SP,IY
  POP IX
  LD B,(IX+$0B)
  LD A,(IY+$07)
  CP $01
  JR Z,TestGridWidth
  DEC B
TestGridWidth:
  INC SP                  ; the X position into the X bytes at $FC00
  POP HL
  POP DE
  LD A,L
  AND $C0
  OR H
  RLCA
  RLCA
  LD H,$FC
  LD L,A
  XOR A
  LD SP,HL
TestGridColumns:
  POP HL                  ; OR of 4 X bytes a column
  OR L
  OR H
  POP HL
  OR L
  OR H
  DJNZ TestGridColumns
  LD C,A
  LD B,(IX+$08)
  DEC B
  LD A,E
  AND $E0
  OR D
  RLCA
  RLCA
  RLCA
  LD H,$FD
  LD L,A
  XOR A
  LD SP,HL
TestGridRows:
  POP HL                  ; OR of the Y bytes over the height
  OR L
  OR H
  POP HL
  OR L
  OR H
  POP HL
  OR L
  OR H
  POP HL
  OR L
  OR H
  DJNZ TestGridRows
  AND C
  LD (IY+$0D),A           ; +$0D: the enemies this record overlaps
  EXX
  OR C
  LD L,A
  LD A,B                  ; only the player and the four lasers count for
                          ; $80BB, and only when active
  CP $04
  JR C,TestGridNext
  BIT 7,(IY+$08)
  JR Z,TestGridNext
  LD C,L
TestGridNext:
  ADD IY,DE               ; the next record: 44 bytes on ($018C for the first
                          ; step)
  LD DE,$002C
  DJNZ TestGridObject
  LD A,C
  LD (LaserHitMask),A     ; $80BB: the hit mask of the player and the lasers
TestGridRestoreSp:
  LD SP,$0000             ; SP back (the operand written at $9150)
  RET

; clear the collision grid $FC00-$FD8F
;
; Pushes 200 zero words down from $FD90 (20 x 10 PUSH HL): the X bytes
; $FC00-$FCFF and the Y bytes $FD00-$FD8F. Called from $8C3B, $A9ED and $B03A
; (496 entries in 48K c2). SP is kept in the operand at $91DF.
ClearHitGrid:
  LD (ClearGridRestoreSp+$0001),SP
  LD SP,ScriptStack
  LD HL,$0000
  LD B,$14
ClearGridLoop:
  PUSH HL                 ; 10 words a pass
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  DJNZ ClearGridLoop
ClearGridRestoreSp:
  LD SP,$0000             ; SP back (the operand written at $91C6)
  RET

; jump to the word number A of the table at HL
;
; HL = the word at HL + 2A, JP (HL); DE is spoilt. The routine reached returns
; to JumpTable's caller. Used by the object loop ($80FA), the path interpreter
; ($8114, $8124), the player's side weapon ($80EA), the pod ($80F0) and the
; routines at $AC0E, $AD66, $ADF4, $B0FF and $B21C. 6080 entries in 48K c2.
JumpTable:
  ADD A,A
  LD E,A
  LD D,$00
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  JP (HL)
