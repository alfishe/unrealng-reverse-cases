; --------------------------------------------------------------------------------------------------------------------
; levels.asm: The level set-up: the playfield model, the map ring and the per-level counters
;
; LevelSetUp resets everything the playfield engine keeps between frames: the span node pool, the 18 row records, the
; map ring, the glyph bitmap, the mirror table, the level counters and the stars.
; --------------------------------------------------------------------------------------------------------------------

; Reset the playfield model at the start of a level or life
;
; Chains the 95 nodes of the pool $F800 (the free list in $7F68, $FAF8 = $FFFF
; the end), clears the 576 bytes of RowRecords ($F12C-$F36B) and fills each of
; the 18 records: +0/+1 the map pointer ($B71F, $B79F, $B81F, ... two rows a
; page), +2/+3 the attribute address of column 31 ($583F + 32 row), +4/+5 the
; screen address ($4020 ...), +6/+7 the head SentinelNode, +$0D/+$0E the tail =
; record + 2, +$13 = 32 empty columns, +$12 = 1.
;
; Clears the map ring $B700-$BFFF, ScrollColumn = $B760, $8022 = $B730,
; GlyphBitmap $FFE0-$FFFF = 0; builds BitReverse ($FB00: each byte with its
; bits reversed).
;
; Sets the six fields $8075 + 3k to $FF, $8072-$8074 = 5, 6, 3, clears $8087,
; $8024, $8025, $80BD, $80BE and the six bytes $7EFF + 16k; then, with
; interrupts off, calls $91C6 and InitStars.
;
; Called from the level start $AF49 (c2: 1 entry).
LevelSetUp:
  LD HL,NodePool
  LD (NodeFreeList),HL
  LD B,$5F
  EX DE,HL
ChainNodes:
  LD HL,$0008
  ADD HL,DE
  EX DE,HL
  LD (HL),E
  INC HL
  LD (HL),D
  DJNZ ChainNodes
  LD HL,ColumnFlags+$001F
  LD (NodePool+$02F8),HL
  LD HL,RowRecords
  LD DE,RowRecords+$0001
  LD BC,$023F
  LD (HL),$00
  LDIR
  LD A,$12
  LD IX,RowRecords
  LD HL,$4020
  LD BC,SentinelNode
  EXX
  LD HL,$583F
  LD DE,$0020
  LD BC,$B71F
  EXX
InitRowRecord:
  PUSH AF
  EXX
  LD (IX+$02),L
  LD (IX+$03),H
  ADD HL,DE
  LD (IX+$00),C
  LD (IX+$01),B
  LD A,C
  ADD A,$80
  LD C,A
  LD A,$00
  ADC A,B
  LD B,A
  EXX
  LD (IX+$04),L
  LD (IX+$05),H
  LD (IX+$06),C
  LD (IX+$07),B
  PUSH IX
  POP DE
  INC DE
  INC DE
  LD (IX+$0D),E
  LD (IX+$0E),D
  LD (IX+$13),$20
  LD (IX+$12),$01
  LD DE,$0720
  ADD HL,DE
  LD A,H
  AND $F8
  LD H,A
  LD DE,$0020
  ADD IX,DE
  POP AF
  DEC A
  JR NZ,InitRowRecord
  LD HL,data_B700
  LD DE,data_B700+$0001
  LD BC,$08FF
  LD (HL),$00
  LDIR
  LD HL,MapRingSpace+$0031
  LD (ScrollColumn),HL
  LD HL,MapRingSpace+$0001
  LD (ScrollMap),HL
  LD HL,ColumnFlags
  LD DE,ColumnFlags+$0001
  LD (HL),$00
  LD BC,$001F
  LDIR
  LD HL,BitReverse
BitReverseByte:
  LD A,$80
BitReverseBit:
  RLC L
  RRA
  JR NC,BitReverseBit
  LD (HL),A
  INC L
  JR NZ,BitReverseByte
  LD HL,WaveRecords
  LD DE,$0003
  LD B,$06
InitLevelFields:
  LD (HL),$FF
  ADD HL,DE
  DJNZ InitLevelFields
  LD A,$05
  LD (FreeEnemySlots),A
  LD A,$06
  LD (WavesAllowed),A
  LD A,$03
  LD (EnemyShotsLeft),A
  XOR A
  LD (SpriteCacheMask),A
  LD (DrawQueueRead),A
  LD (DrawQueueWrite),A
  LD (HarmlessMaskA),A
  LD (HarmlessMaskB),A
  LD B,$06
  LD HL,SpriteCacheUse1
  LD DE,$0010
ClearObjectFlags:
  LD (HL),A
  ADD HL,DE
  DJNZ ClearObjectFlags
  DI
  CALL ClearHitGrid
  CALL InitStars
  EI
  RET
