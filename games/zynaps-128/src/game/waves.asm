; --------------------------------------------------------------------------------------------------------------------
; waves.asm: the wave launcher and the sprite cache
;
; LaunchWave starts one wave of enemies from the level tables (the data module): $6926 the wave number -> the wave
; index, $6943 two bytes an index (the wave record's bonus byte, then a stream offset), $6A65 eight bytes a kind (the
; template), $6B15 three bytes a level of the weapon rating ($80E9), $6800/$681C the path numbers -> the path
; bytecode. The 44-byte template at $803E is filled once and copied into each free enemy slot, with a starting delay
; that grows from object to object, its own path, its X and Y.
;
; A wave record (3 bytes at $8075, $FF free) counts the wave's live objects; $8073 is the number of wave records the
; game allows at once (EnemyGone gives one back) and $8072 the free enemy slots (FreeEnemySlot gives one back;
; ScatterDebris zeroes it so nothing new arrives during the player's explosion).
;
; The sprite cache: the sprite descriptor of a kind is one of 6 records of 16 bytes at $7EF2 (record 0, $7EE2, serves
; the kinds from $14 up without caching). A record's +$0D counts the objects using it, +$0E is the kind with bit 7,
; +$0F holds the record number in its low nibble; $8087 is the mask of records in use and $8088 a table that gives a
; free record for a mask. A new kind is queued in the ring at $8025/$8026 (8 entries of 3 bytes) for the renderer to
; build, flagged by bit 7 of $81C5.
; --------------------------------------------------------------------------------------------------------------------

; start wave A: the template, the wave record, the objects
;
; A = the wave number. Refused (NC) when no enemy slot is free ($8072 = 0) or
; no wave record is allowed ($8073 = 0); else $8073 - 1, the first free wave
; record at $8075 (first byte $FF) is taken with count 0 and its index kept in
; A'. $6926[A] = the index n; at $6943 + 2n: the bonus byte (record +1: bits
; 6-7 the drop type, bits 0-5 the bonus score), then the sprite kind (bit 7:
; all objects take the next byte as their path, else the kind itself) and the
; object count; the path numbers fill $806A.
;
; The template $803E is zeroed, its target (+$29) = the player $F36C; $6A65 + 8
; x kind gives +$18, the speed level (combined with the weapon rating $80E9 to
; pick 3 bytes of $6B15 for +$19, +$20/+$21, +$22), the score index (+$0C) and
; the speed (+$17) nibbles, the X acceleration (+$10), the Y acceleration
; (+$14), the handler kind (+$07), the colour (+$25) and the hit points (+$0D).
; GetSpriteCache gives the descriptor (+0/+1), its +$0F goes to +$23 and its
; +$0C to the row mask +$0B; +$02 = 1, +$1A = the wave record.
;
; Then for each object: TakeEnemySlot, count + 1, the template copied over the
; slot (bytes +$09/+$0A and the slot's own collision bit +$24 kept), the target
; of the next object = this one, the path pointer from $6800/$681C, the start
; delay +$1B = D (each next object E frames later), active and visible, X and Y
; from the stream (a Y of $FF = a random row). At the end the descriptor's use
; count +$0D grows by the objects launched, the border/speaker gets OUT
; ($FE),0, carry. 9 entries in 48K c2.
LaunchWave:
  PUSH BC
  PUSH AF
  LD A,(FreeEnemySlots)
  AND A
  JP Z,LaunchWaveRefused
  LD A,(WavesAllowed)
  DEC A
  JP M,LaunchWaveRefused
  LD (WavesAllowed),A
  LD IX,WaveRecords
  LD DE,$0003
  LD C,D
LaunchWaveFindRecord:
  LD A,(IX+$00)           ; the first wave record with $FF
  INC A
  JR Z,LaunchWaveRecord
  ADD IX,DE
  INC C
  JR LaunchWaveFindRecord
LaunchWaveRecord:
  LD (IX+$00),$00         ; count 0; its index into A'
  LD A,C
  EX AF,AF'
  POP AF
  LD E,A
  LD HL,WaveIndex
  ADD HL,DE
  LD E,(HL)
  LD HL,WaveDefinitions
  ADD HL,DE
  ADD HL,DE
  LD A,(HL)
  INC HL
  LD (IX+$01),A
  LD A,(HL)
  INC HL
  LD B,(HL)
  INC HL
  PUSH BC
  LD DE,WavePaths
  BIT 7,A
  RES 7,A
  LD (IX+$02),A
  JR Z,LaunchWaveFillKind
  LD C,A
  LD A,(HL)
  INC HL
  INC HL
LaunchWaveFillSame:
  LD (DE),A               ; bit 7: B copies of the next byte
  INC DE
  DJNZ LaunchWaveFillSame
  LD A,C
  JR LaunchWaveTemplate
LaunchWaveFillKind:
  LD (DE),A               ; bit 7 clear: B copies of the kind
  INC DE
  DJNZ LaunchWaveFillKind
LaunchWaveTemplate:
  PUSH HL                 ; zero the 44-byte template at $803E, target = the
                          ; player
  LD HL,WaveTemplate
  LD DE,WaveTemplate+$0001
  LD (HL),$00
  LD BC,$002B
  LDIR
  LD HL,PlayerObject
  LD (WaveTarget),HL
  PUSH AF
  ADD A,A
  ADD A,A
  ADD A,A
  LD HL,EnemyKinds
  LD E,A
  LD D,$00
  ADD HL,DE
  LD A,(HL)
  INC HL
  LD (WaveTemplate+$0018),A
  LD A,(HL)
  INC HL
  EXX
  LD C,A
  LD A,(WeaponRatingLevel)
  ADD A,C
  AND $1C
  RRCA
  LD E,A
  RRCA
  ADD A,E
  LD E,A
  LD D,$00
  LD HL,KindColours
  ADD HL,DE
  LD A,(HL)
  LD (WaveTemplate+$0019),A
  INC HL
  LD A,(HL)
  LD (WaveTemplate+$0020),A
  LD A,C
  AND $E3
  LD (WaveTemplate+$0021),A
  INC HL
  LD A,(HL)
  LD (WaveTemplate+$0022),A
  EXX
  LD A,(HL)
  AND $0F
  LD (WaveTemplate+$000C),A
  XOR (HL)
  RRCA
  RRCA
  RRCA
  RRCA
  LD (WaveTemplate+$0017),A
  INC HL
  LD A,(HL)
  INC HL
  LD (WaveTemplate+$0010),A
  LD A,(HL)
  INC HL
  LD (WaveTemplate+$0014),A
  LD A,(HL)
  INC HL
  LD (WaveTemplate+$0007),A
  LD A,(HL)
  INC HL
  LD (WaveTemplate+$0025),A
  LD A,(HL)
  LD (WaveTemplate+$000D),A
  POP AF
  CALL GetSpriteCache     ; the sprite descriptor of the kind
  LD (WaveTemplate),HL
  LD DE,$000F
  ADD HL,DE
  LD A,(HL)
  LD (WaveTemplate+$0023),A
  LD DE,-3                ; DE = -3: the descriptor's +$0C, the row mask
  ADD HL,DE
  LD A,(HL)
  LD (WaveTemplate+$000B),A
  LD A,$01
  LD (WaveTemplate+$0002),A
  EX AF,AF'
  LD (WaveTemplate+$001A),A
  POP HL
  POP AF
  POP DE
  EX AF,AF'
  LD A,(HL)
  INC HL
  EXX
  LD E,A
  LD D,$01
  EX AF,AF'
  LD B,A
  LD HL,WavePaths
  LD (LaunchWavePathList+$0001),HL
LaunchWaveObject:
  PUSH DE                 ; one object: a free slot, the template, the path,
                          ; the position
  CALL TakeEnemySlot
  JP NC,LaunchWaveNoSlot
  INC (IX+$00)
  LD A,(IY+$24)
  LD (WaveTemplate+$0024),A
  LD A,B
  PUSH IY
  POP DE
  LD HL,WaveTemplate
  LD BC,$0009
  LDIR                    ; the template's first 9 bytes
  INC HL
  INC HL
  INC DE
  INC DE
  LD BC,$0021
  LDIR                    ; the bytes +$0B-$2B (+$09/+$0A kept)
  LD (WaveTarget),IY
  LD B,A
LaunchWavePathList:
  LD HL,$0000             ; the operand: the next path number in $806A
  LD E,(HL)
  INC HL
  LD (LaunchWavePathList+$0001),HL
  LD D,$00
  LD HL,PathStarts
  ADD HL,DE
  LD E,(HL)
  LD HL,PathCode
  ADD HL,DE
  ADD HL,DE
  LD (IY+$1D),L
  LD (IY+$1E),H
  POP DE
  LD (IY+$1B),D
  LD A,D
  ADD A,E
  LD D,A
  SET 7,(IY+$08)
  SET 5,(IY+$08)
  EXX
  LD A,(HL)
  INC HL
  SRA A
  ADD A,E
  RRCA
  RRCA
  LD C,A
  AND $C0
  LD (IY+$03),A
  XOR C
  LD (IY+$04),A
  LD A,(HL)
  INC HL
  CP $FF
  JR NZ,LaunchWaveYOffset
  CALL Random
  AND $7F
  JR LaunchWaveSetY
LaunchWaveYOffset:
  ADD A,D                 ; Y from the stream plus the stagger
LaunchWaveSetY:
  RRCA                    ; Y: the integer row (+6) and the fraction (+5)
  RRCA
  RRCA
  LD C,A
  AND $1F
  LD (IY+$06),A
  XOR C
  LD (IY+$05),A
  EXX
  DEC B
  JP NZ,LaunchWaveObject
LaunchWaveDone:
  LD HL,(WaveTemplate)    ; the descriptor's use count + the objects launched
  LD DE,$000D
  ADD HL,DE
  LD A,(IX+$00)
  ADD A,(HL)
  LD (HL),A
  XOR A
  OUT ($FE),A             ; OUT ($FE),0: speaker and border off
  SCF
  RET
LaunchWaveNoSlot:
  POP DE                  ; no free slot left: end early
  JR LaunchWaveDone
LaunchWaveRefused:
  POP AF                  ; NC: nothing launched
  POP BC
  AND A
  RET

; take one free enemy slot from $F398 on
;
; NC (Z) when $8072, the free enemy slots, is 0; else $8072 - 1 and IY = the
; first record from $F398 whose +$08 bit 7 is clear, carry. The count
; guarantees one is found. 25 entries in 48K c2.
TakeEnemySlot:
  LD HL,FreeEnemySlots
  LD A,(HL)
  AND A
  RET Z
  DEC (HL)
  LD IY,EnemyObjects
  LD DE,$002C
TakeEnemySlotLoop:
  BIT 7,(IY+$08)          ; active: the next record
  JR Z,TakeEnemySlotFound
  ADD IY,DE
  JR TakeEnemySlotLoop
TakeEnemySlotFound:
  SCF                     ; carry: IY free
  RET

; the sprite descriptor of kind A, cached or queued
;
; A = the kind. From $14 up: HL = $7EE2 (record 0) with a load queued each
; time. Else the 6 records from $7EF2 are searched for a used one (+$0D not 0)
; of this kind (+$0E & $7F); found: HL = that record. Not found: a free record
; is picked from $8088 by the use mask $8087 (the low nibble, the high one for
; kinds with bit 4), the least used record evicted (EvictSpriteCache) when none
; is free; the record is queued for building (QueueSpriteLoad), +$0E = kind |
; $80, +$0F + $10, and its bit set in $8087. 7 entries in 48K c2.
GetSpriteCache:
  LD C,A
  CP $14
  JR C,SpriteCacheSearch
  LD HL,SpriteCache
  CALL QueueSpriteLoad
  RET
SpriteCacheSearch:
  LD HL,SpriteCacheUse1   ; 6 records, 16 bytes apart
  LD B,$06
  LD DE,$0010
SpriteCacheSearchLoop:
  PUSH HL                 ; used and of this kind?
  LD A,(HL)
  AND A
  JR Z,SpriteCacheNext
  INC HL
  LD A,(HL)
  AND $7F
  CP C
  JR NZ,SpriteCacheNext
  LD A,$07
  SUB B
  LD B,A
  POP HL
  JR SpriteCacheRecord
SpriteCacheNext:
  POP HL                  ; the next record
  ADD HL,DE
  DJNZ SpriteCacheSearchLoop
SpriteCacheAllocate:
  LD A,(SpriteCacheMask)  ; a free record number for the use mask $8087
  LD E,A
  LD D,$00
  LD HL,SpriteCacheFree
  ADD HL,DE
  LD A,(HL)
  BIT 4,C
  JR Z,SpriteCacheNibble
  RRCA
  RRCA
  RRCA
  RRCA
SpriteCacheNibble:
  AND $0F                 ; 0: none free, evict one and look again
  CALL Z,EvictSpriteCache
  JR Z,SpriteCacheAllocate
  LD B,A
  CALL SpriteCacheRecord
  PUSH HL
  CALL QueueSpriteLoad
  LD DE,$000E
  ADD HL,DE
  LD (HL),C
  SET 7,(HL)
  INC HL
  LD A,(HL)
  ADD A,$10
  LD (HL),A
  AND $0F
  LD HL,SpriteCacheMask
  OR (HL)
  LD (HL),A
  POP HL
  JR SpriteCacheRet

; HL = $7EE2 + 16 x B
;
; Used by the routine at GetSpriteCache.
SpriteCacheRecord:
  LD HL,SpriteCache
  LD DE,$0010
SpriteCacheRecordLoop:
  ADD HL,DE               ; B steps of 16
  DJNZ SpriteCacheRecordLoop

; SpriteCacheRet
;
; Used by the routine at GetSpriteCache.
SpriteCacheRet:
  RET                     ; HL the record

; free the least used sprite-cache record
;
; The used record with the smallest use count +$0D among the 6 from $7EF2 (read
; at $7EFF + 16 n) is cleared and its number (+$0F low nibble) removed from the
; use mask $8087. Not run in 48K c2.
EvictSpriteCache:
  PUSH AF
  PUSH BC
  LD HL,SpriteCacheUse1
  LD DE,$0010
  LD C,$FF
  LD B,$06
EvictSpriteCacheLoop:
  LD A,(HL)               ; smaller use count than the best so far?
  AND A
  JR Z,EvictSpriteCacheNext
  CP C
  JR NC,EvictSpriteCacheNext
  LD C,A
  LD (EvictSpriteCachePtr+$0001),HL
EvictSpriteCacheNext:
  ADD HL,DE               ; the next record
  DJNZ EvictSpriteCacheLoop
EvictSpriteCachePtr:
  LD HL,$0000             ; the operand: the record chosen
  LD (HL),$00
  INC HL
  INC HL
  LD A,(HL)
  AND $0F
  CPL
  LD HL,SpriteCacheMask
  AND (HL)
  LD (HL),A
  POP BC
  POP AF
  RET

; queue the sprite record DE of kind C for building
;
; The ring at $8026 (8 entries of 3 bytes: the kind, the record address), index
; $8025 + 1 mod 8; bit 7 of $81C5 tells the renderer a request is waiting. HL =
; the record on return. 5 entries in 48K c2.
QueueSpriteLoad:
  PUSH AF
  EX DE,HL
  LD HL,DrawQueueWrite
  LD A,(HL)
  INC (HL)
  RES 3,(HL)
  PUSH DE
  LD E,A
  ADD A,A
  ADD A,E
  LD E,A
  LD D,$00
  LD HL,DrawQueue
  ADD HL,DE
  POP DE
  LD (HL),C
  INC HL
  LD (HL),E
  INC HL
  LD (HL),D
  LD HL,EventRequests
  SET 7,(HL)
  EX DE,HL
  POP AF
  RET
