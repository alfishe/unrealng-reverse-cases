; --------------------------------------------------------------------------------------------------------------------
; actors.asm: The actor records: placement, the per-pass update, the frames, the bursts
; --------------------------------------------------------------------------------------------------------------------

  ORG $905E

; Move the actor IY right by A eighths of a byte column (no caller)
;
; Adds A to the fraction +$11; past 8 takes 8 off and moves +0 and +$0D one
; column right. Nothing calls it (no CALL, JP or table word names $905E): a
; leftover of the engine.
;
; Not executed in any recording (the recordings checked: rzx-r4, s4-right);
; known only from the code.
StepFineRight:
  ADD A,(IY+$11)
  CP $08
  JR NC,StepFineRightCarry
  LD (IY+$11),A
  RET
StepFineRightCarry:
  SUB $08
  LD (IY+$11),A
  INC (IY+$00)
  INC (IY+$0D)
  RET

; Move the actor IY back by A eighths of a byte column
;
; Takes A from the fraction +$11; on a borrow adds 8 back and moves the base
; column +$0D one column against the facing (MoveBaseX $B2C0 with E = -1).
; Called by HeroRecoil $8B56.
;
; Witness: L1 42 (s4-right).
StepFineBack:
  LD E,A
  LD A,(IY+$11)
  SUB E
  LD (IY+$11),A
  RET NC
  ADD A,$08
  LD (IY+$11),A
  LD E,$FF
  JP MoveBaseX

; Move the actor IY left by A eighths of a byte column (no caller)
;
; As StepFineRight leftwards (+0 and +$0D one column left on a borrow). Nothing
; calls it: a leftover.
;
; Not executed in any recording (the recordings checked: rzx-r4, s4-right);
; known only from the code.
StepFineLeft:
  LD E,A
  LD A,(IY+$11)
  SUB E
  LD (IY+$11),A
  RET NC
  ADD A,$08
  LD (IY+$11),A
  DEC (IY+$00)
  DEC (IY+$0D)
  RET

  ORG $9245

; Count down to the next random enemy; in grid 10 to the next of its own enemy
;
; Every pass (MainLoop $7843). SpawnDelay - 1; at 0: reloaded with $0E-$2D
; (Random) and, one time in four (Random & 3 = 0), SpawnPick. In grid 10
; instead: reloaded with $50-$8F and, with a free record (FindFreeActor $93E9),
; the template $9F5F (handler $9351) spawned at D = $18, E = $50 (JP SpawnActor
; $A639).
;
; Witness: L1 8620 (rzx-r4, s4-right).
;
; s4-right: 27 reloads, 11 picks, none in a room of SpawnTable. rzx-r4: 259
; reloads, 57 picks, 28 walkers sent in; grid 10's spawn ran 4 times.
SpawnTimer:
  LD A,(GridNumber)
  CP $0A
  JP Z,SpawnTimerGrid10
  LD A,(SpawnDelay)
  DEC A
  JR Z,SpawnTimerFire
  LD (SpawnDelay),A
  RET
SpawnTimerFire:
  CALL Random
  AND $1F
  ADD A,$0E
  LD (SpawnDelay),A
  CALL Random
  AND $03
  JP Z,SpawnPick
  RET
SpawnTimerGrid10:
  LD A,(SpawnDelay)
  DEC A
  JR Z,SpawnTimerGrid10Fire
  LD (SpawnDelay),A
  RET
SpawnTimerGrid10Fire:
  CALL Random
  AND $3F
  ADD A,$50
  LD (SpawnDelay),A
  CALL FindFreeActor
  RET NZ
  LD E,$50
  LD D,$18
  LD HL,MummyTemplate
  JP SpawnActor
SpawnPick:
  LD A,(GridNumber)            ; SpawnTable[GridNumber x 6 + RoomNumber]: 0 none,
                          ; else the line / 8 of a walker from the right
  SLA A
  LD C,A
  SLA A
  ADD A,C
  LD C,A
  LD A,(RoomNumber)
  ADD A,C
  LD C,A
  LD B,$00
  LD HL,SpawnTable
  ADD HL,BC
  LD A,(HL)
  CP $00
  RET Z
  SLA A
  SLA A
  SLA A
  LD E,A
  LD HL,$0000
  ADD HL,BC
  LD A,(HL)
  LD A,$00
  AND $01
  JP Z,SpawnScorpion
  JP SpawnScorpionLeft

; The rooms where a walker comes in: one byte a room, 6 a grid (10 grids), the
; line / 8 or 0
;
; Read by SpawnPick $929D. Non-zero: grid 1 room 1 ($0D), grid 2 rooms 0 and 1
; ($0B, $0D), grid 3 rooms 0, 2 and 3 ($0D), grid 4 rooms 1 and 3 ($0B). The
; value x 8 is the line E; the walker (template $9F4D, handler $9319) comes in
; at column $1A ($92F7: the branch at $92B5 always takes it, since A is set to
; 0 before AND 1; the left-facing spawn $9306 is never reached). Read in both
; recordings (57 picks in rzx-r4).
SpawnTable:
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$0D,$00,$00,$00,$00
  DEFB $0B,$0D,$00,$00,$00,$00
  DEFB $0D,$00,$0D,$0D,$00,$00
  DEFB $00,$0B,$00,$0B,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00

  ORG $93DA

; Zero the 18 bytes of the actor record IY (not referenced)
;
; HL = DE = IY, the first byte 0, LDIR over the next 17. No CALL, JP or word in
; the image reaches it (it follows MummyFrames, `$93DA`).
;
; Not executed in any recording (the recordings checked: s4-right, rzx-r4);
; known only from the code.
ClearActorRecord:
  PUSH IY
  PUSH IY
  POP HL
  POP DE
  LD BC,$0011
  LD (HL),$00
  INC DE
  LDIR
  RET

; IY = the first free actor record of 13 (Z), else NZ
;
; A record is free when its +0 is $FF; the 13 records from $74F2. Returns NZ
; (ReturnNZ $B4A7) when none is free. As in stage 1 at `$8D3A`.
;
; Witness: L1 92 (rzx-r4).
FindFreeActor:
  LD B,$0D
  LD IY,Actors
  LD DE,$0012
FindFreeActorLoop:
  LD A,(IY+$00)
  CP $FF
  RET Z
  ADD IY,DE
  DJNZ FindFreeActorLoop
  JP ReturnNZ

; IY = the first free actor record whose next record is free too (Z), else NZ
;
; 12 records searched from $74F2. As in stage 1 at `$8D50`. No CALL, JP or word
; in the stage-4 image reaches it.
;
; Witness: L1 5 (rzx-r4).
FindFreeActorPair:
  LD B,$0C
  LD IY,Actors
  LD DE,$0012
FindPairLoop:
  LD A,(IY+$00)
  CP $FF
  JR NZ,FindPairNext
  LD A,(IY+$12)
  CP $FF
  RET Z
FindPairNext:
  ADD IY,DE
  DJNZ FindPairLoop
  JP ReturnNZ

; Free all 13 actor records ($74F2, 234 bytes of $FF), then clear the shots
;
; Fills $74F2-$75DB with $FF and goes on into ClearShots. Called from
; StageEntry `$780A` and StartGrid $A5CC. As in stage 1 at `$921E`.
;
; Witness: L1 17 (rzx-r4, s4-right).
ClearActors:
  LD HL,Actors
  LD DE,Actors+$0001
  LD BC,$00E9
  LD (HL),$FF
  LDIR
  JR ClearShots

  ORG $9446

; Fill the missile records $75E0-$763F (96 bytes) with $FF
;
; Witness: L1 74 (rzx-r4, s4-right).
ClearShots:
  LD HL,Missiles
  LD DE,Missiles+$0001
  LD BC,$0060
  LD (HL),$FF
  LDIR
  RET

  ORG $9515

; +$0E (the base line) + C
;
; Witness: L1 7 (rzx-r4, s4-right).
MoveActorY:
  LD A,(IY+$0E)
  ADD A,C
  LD (IY+$0E),A
  RET

  ORG $9E1B

; The 22 placement kinds, 9 bytes each: the Y offset, the handler, 5 bytes for
; the record's +8 to +$0C, the record's +$0F
;
; LoadRoomActors $A654 builds an actor from a placement with its kind's row, as
; in stage 1: +1 Y = the placement's Y x 8 + the offset, +6/+7 the handler, +8
; to +$0C (the counter, the flags, the state, the item, the attribute), +$0F
; (bit 1: kept over a room change). Stage 4's kinds: 0-2 urns and chests that
; break at the low strike (StrikeableActor $A938; +$0B the item inside: 5, 3,
; 1), 3 an object that leaves item 9, an urn (StrikeableKind9 $A997), 4 the
; water's surface (WaterRipple $8629; also the 62 X-250 fillers of the
; placement lists), 5 a floor switch (FloorSwitch $865C), 6 and 10 a pendulum
; (Pendulum $888F), 7 a falling column (FallingColumn $87AC), 8 a crumbling
; slab (CrumblingSlab $869B), 9 switched spikes (SwitchedSpikes $86FF), 11 an
; inert actor (InertActor $8B39), 12 a brazier (Brazier $8917), 13 the altar
; disc (AltarDisc $8931), 14 and 15 crumbling ledges (CrumblingLedge $89A8; 15
; starts with +$0A = $64 and does not crumble), 16 the boss's mouth (BossMouth
; $8AD4), 17 an urn marker (UrnMarker $8B1A), 18 a bridge ledge (BridgeLedge
; $8A59), 19 the ankh shrine (AnkhShrine $8A88), 20 and 21 the barrier's block
; and pillar (BarrierBlockActor $96CB, BarrierPillarActor $96DD; +$0F bit 0).
;
; Read in s4-right and rzx-r4 (LoadRoomActors: all 22 rows; every kind's
; handler ran in rzx-r4).
ActorKinds:
  INCBIN "res/stage4/table-kinds.bin",$0000,198

; Eight whole actor records (18 bytes each, the first the hero's) that
; SpawnActor $A639 copies for the actors no placement makes
;
; The handler at +6/+7 and the frame at +4/+5 as for a placed actor; the rest
; as an actor record (HeroRecord $74E0). Read in s4-right and rzx-r4
; (SpawnActor; the dust, the ledges forming and the scorpion's and mummy's
; templates only in rzx-r4).
ActorTemplates:
HeroTemplate:
  INCBIN "res/stage4/table-actor-templates.bin",$0000,18
ItemTemplate:
  INCBIN "res/stage4/table-actor-templates.bin",$0012,18
PieceTemplate:
  INCBIN "res/stage4/table-actor-templates.bin",$0024,18
FragmentTemplate:
  INCBIN "res/stage4/table-actor-templates.bin",$0036,18
ColumnDustTemplate:
  INCBIN "res/stage4/table-actor-templates.bin",$0048,18
BridgeLedgeTemplate:
  INCBIN "res/stage4/table-actor-templates.bin",$005A,18
ScorpionTemplate:
  INCBIN "res/stage4/table-actor-templates.bin",$006C,18
MummyTemplate:
  INCBIN "res/stage4/table-actor-templates.bin",$007E,18

; Clear and set the stage variables at the start of the stage
;
; Clears $FE08-$FE5B (84 bytes), copies the 12 starting item kinds from $7F69
; to CarriedItems $7F51, clears $9DAB-$9E1A (112 bytes of stage 4's room-state
; area), seeds RandomPointer from R (twice) and draws SpawnDelay (Random
; $90AC), then the start values: InitOnly3E 1, InitOnly3D $0D, InitOnly10 2,
; InitOnly12 1, InitOnly36 $10, ItemFirst 6, ItemSelected 6, ItemLast 7 (two
; items carried at the start), $7F64 = 6 (CarriedCounts' slot 7: the second
; item's amount), BurstTimer $64 (no burst), RandomSeed and RandomPointer
; $07CF, BossHits $14, EnergyChange $2E (the energy refilled), RespawnShiftX
; $FF (no death pending).
;
; Called once from StageEntry `$7804`. As in stage 1 at `$9DA1`, with stage 4's
; layout of the work space.
;
; Witness: L1 2 (rzx-r4, s4-right).
InitStageState:
  LD HL,RandomSeed
  LD DE,RandomSeed+1
  LD BC,$0053
  LD (HL),$00
  LDIR
  LD HL,StartItems
  LD DE,CarriedItems
  LD BC,$000C
  LDIR
  LD HL,TrapSlots
  LD DE,TrapSlots+$0001
  LD BC,$006F
  LD (HL),$00
  LDIR
  LD A,R
  LD C,A
  LD A,R
  LD B,A
  LD (RandomPointer),BC
  CALL Random
  LD (SpawnDelay),A
  LD A,$01
  LD (InitOnly3E),A
  LD A,$0D
  LD (InitOnly3D),A
  LD A,$02
  LD (InitOnly10),A
  LD A,$01
  LD (InitOnly12),A
  LD A,$10
  LD (InitOnly36),A
  LD A,$06
  LD (ItemFirst),A
  LD A,$06
  LD (ItemSelected),A
  LD A,$07
  LD (ItemLast),A
  LD A,$06
  LD (CarriedCounts+$0007),A
  LD A,$64
  LD (BurstTimer),A
  LD HL,$07CF
  LD (RandomSeed),HL
  LD (RandomPointer),HL
  LD A,$14
  LD (BossHits),A
  LD A,$2E
  LD (EnergyChange),A
  LD A,$FF
  LD (RespawnShiftX),A
  RET

; 12 bytes 0, 1, 2, 2, 1, 0, 0, 1, 3, 3, 1, 0: no reader found (known only from
; the code)
;
; No instruction or word of the stage-4 image refers to `$9FF1`.
LeftoverSteps:
  DEFB $00,$01,$02,$02,$01,$00,$00,$01,$03,$03,$01,$00

  ORG $A1C8

; Score 20, then burst the actor (shape $E95B) into particles; the caller frees
; it
;
; IY = the actor (called from StrikeableActor `$A954` and StrikeableKind9
; `$A9A7`). AddScore $7B94 with 20, then StartBurst at column - 7, line / 8
; with the shape $E95B in the small mode, colours 6 and 4 (3 and 2 when +8 = 8:
; ScoreBurst20Alt, which no stage-4 strikeable reaches). As in stage 1 at
; `$A065`.
;
; Witness: L1 17 (rzx-r4).
ScoreBurst20:
  LD BC,$0014
  CALL AddScore
  LD A,(IY+$00)
  SUB $07
  LD D,A
  LD A,(IY+$01)
  SRL A
  SRL A
  SRL A
  LD E,A
  LD IX,BurstShapes
  LD A,(IY+$08)
  CP $08
  JR Z,ScoreBurst20Alt
  LD B,$06
  LD C,$04
  LD A,$01
  JP StartBurst
ScoreBurst20Alt:
  LD B,$03
  LD C,$02
  LD A,$01
  JP StartBurst

; Score 80, burst the actor (the big shape $E973) and free it: the mummy's end
;
; IY = the mummy (jumped to from MummyActor `$936C` on its third hit). AddScore
; $7B94 with $50 (80), StartBurst at column - 7, line / 8, shape $E973, big
; mode, colours 6 and 4, then RemoveActor $B520.
;
; Witness: L1 4 (rzx-r4).
ScoreBurst80:
  LD BC,$0050
  CALL AddScore
  LD A,(IY+$00)
  SUB $07
  LD D,A
  LD A,(IY+$01)
  SRL A
  SRL A
  SRL A
  LD E,A
  LD IX,BurstShapes+$0018
  LD B,$06
  LD C,$04
  LD A,$00
  CALL StartBurst
  JP RemoveActor

; Score 200, burst the barrier's block (shape $E95B) and free it; BarrierState
; = 1
;
; IY = the block (jumped to from BarrierBlockActor `$96DA` when a shot hit it).
; AddScore $7B94 with $C8 (200), StartBurst at column - 7, line / 8, shape
; $E95B, big mode, colours 6 and 7; BarrierState = 1 (the pillar may now be
; hit), RemoveActor $B520.
;
; Witness: L1 1 (rzx-r4).
ScoreBurst200:
  LD BC,$00C8
  CALL AddScore
  LD A,(IY+$00)
  SUB $07
  LD D,A
  LD A,(IY+$01)
  SRL A
  SRL A
  SRL A
  LD E,A
  LD IX,BurstShapes
  LD B,$06
  LD C,$07
  LD A,$00
  CALL StartBurst
  LD A,$01
  LD (BarrierState),A
  JP RemoveActor

  ORG $A2A5

; Put an item actor (template $9EF3) into a free record
;
; Input: D, E = the column and line, BC = the item's image, L = the item kind
; (+$0B), H = the amount (+$0A). FindFreeActor $93E9; with a free record:
; SpawnActor $A639 with the template $9EF3 (2 x 16 lines, handler ItemHandler),
; then the image +4/+5, the kind and the amount. Preserves IY. Also jumped to
; from `$8229`. As in stage 1 at `$A098`.
;
; Witness: L1 18 (rzx-r4).
SpawnItem:
  PUSH IY
  PUSH HL
  PUSH BC
  PUSH AF
  PUSH DE
  CALL FindFreeActor
  JR NZ,SpawnItemFull
  POP DE
  LD HL,ItemTemplate
  CALL SpawnActor
  POP AF
  POP BC
  POP HL
  LD (IY+$04),C
  LD (IY+$05),B
  LD (IY+$0B),L
  LD (IY+$0A),H
  POP IY
  RET
SpawnItemFull:
  POP DE
  POP AF
  POP BC
  POP HL
  POP IY
  RET

; Leave item kind 1 (36 shots) where the actor IY was, then free it
;
; Column +0, line +$0E; amount $24, image $E463 (SpawnItem), then RemoveActor
; $B520. From StrikeableActor `$A983` (a broken urn whose placement index +$10
; AND 3 is 1).
;
; Witness: L1 2 (rzx-r4).
DropItemKind1:
  LD D,(IY+$00)
  LD E,(IY+$0E)
  LD L,$01
  LD H,$24
  LD BC,$E463
  CALL SpawnItem
  JP RemoveActor

; Leave item kind 2 (20 throws) where the actor IY was, then free it
;
; Amount $14, image $E403. From StrikeableActor `$A988` (placement index AND 3
; = 2).
;
; Witness: L1 4 (rzx-r4).
DropItemKind2:
  LD D,(IY+$00)
  LD E,(IY+$0E)
  LD L,$02
  LD H,$14
  LD BC,$E403
  CALL SpawnItem
  JP RemoveActor

; Leave item kind 6 (one) where the actor IY was, then free it
;
; Amount 1, image $E423. From StrikeableActor `$A967` (grid 3, room 1). Kind 6
; selected opens the way into grid 10 (CheckGridPassages `$AD0E`).
;
; Witness: L1 3 (rzx-r4).
DropItemKind6:
  LD D,(IY+$00)
  LD E,(IY+$0E)
  LD L,$06
  LD H,$01
  LD BC,$E423
  CALL SpawnItem
  JP RemoveActor

; Leave item kind 3 (60 shots) where the actor IY was, then free it
;
; Amount $3C, image $E3E3. From StrikeableActor `$A974` (grid 4, room 2).
;
; Witness: L1 3 (rzx-r4).
DropItemKind3:
  LD D,(IY+$00)
  LD E,(IY+$0E)
  LD L,$03
  LD H,$3C
  LD BC,$E3E3
  CALL SpawnItem
  JP RemoveActor

; Leave item kind 8 (one) where the actor IY was, then free it
;
; Amount 1, image $E3C3. From StrikeableActor `$A979` (grid 4, room 4).
;
; Witness: L1 1 (rzx-r4).
DropItemKind8:
  LD D,(IY+$00)
  LD E,(IY+$0E)
  LD L,$08
  LD H,$01
  LD BC,$E3C3
  CALL SpawnItem
  JP RemoveActor

; An item actor: picked up when the hero stands on it
;
; The handler word of the template $9EF3. SetCycleColour $B5A8 each pass; when
; the hero is within 20 lines (HeroWithinY) and in the item's column or the one
; after: AddScore $7B94 with 400, PiecesComplete + 1 for kind 5, AddItem $7EA0
; with A = the kind (+$0B) and D = the amount (+$0A), PlaySoundVector 4,
; RemoveActor $B520. As in stage 1 at `$A0E9` (there kind 6 counted).
;
; Witness: L1 394 (rzx-r4).
ItemHandler:
  CALL SetCycleColour
  LD C,$14
  CALL HeroWithinY
  RET NC
  LD A,(HeroRecord)
  LD E,(IY+$00)
  CP E
  JR Z,ItemHandlerTaken
  INC E
  CP E
  RET NZ
ItemHandlerTaken:
  LD BC,$0190
  CALL AddScore
  LD A,(IY+$0B)
  CP $05
  JR NZ,ItemHandlerAdd
  LD HL,PiecesComplete
  INC (HL)
ItemHandlerAdd:
  LD D,(IY+$0A)
  CALL AddItem
  LD DE,$0004
  CALL PlaySoundVector
  JP RemoveActor

; Carry when the hero stands within 1 column of the actor's (3 more facing
; left) and within C lines (not referenced)
;
; E = the hero's column ($74E0), D = the actor's (+3 when it faces left),
; AbsDiffBelow $A92A with the limit 1; no carry returns, else on into
; HeroWithinY. No instruction or word of the image refers to `$A364`.
;
; Not executed in any recording (the recordings checked: s4-right, rzx-r4);
; known only from the code.
HeroNearActor:
  LD A,(HeroRecord)
  LD E,A
  LD D,(IY+$00)
  BIT 7,(IY+$09)
  JR Z,HeroNearActorTest
  INC D
  INC D
  INC D
HeroNearActorTest:
  LD A,$01
  CALL AbsDiffBelow
  RET NC

; Carry set when the hero's line is within C lines of the actor's
;
; Input: IY = the actor, C = the distance. E = the hero's line ($74E1), D = the
; actor's, then AbsDiffBelow $A92A with the limit C. Called from ItemHandler
; `$A334` and `$8375`. As in stage 1 at `$A11E`.
;
; Witness: L1 693 (rzx-r4).
HeroWithinY:
  LD A,(HeroY)
  LD E,A
  LD D,(IY+$01)
  LD A,C
  JP AbsDiffBelow

; Turn a 16 x 12 shape into particles at $7040 that fly apart (UpdateBurst)
;
; Input: A = BurstSmall (1 small, 0 big), D, E = the shape's left column and
; top cell row, IX = the shape (12 rows of 2 bytes, bit 7 left), B and C = the
; two inks. PlaySoundVector 1, RandomPointer = $0D7A (every burst flies the
; same way), the colours C, C + $40, B, B + $40 into ParticleInks, BurstTimer =
; $FF. Each set bit of the shape gives a particle record of 4 bytes at $7040:
; the column, the cell row, the direction (a random 0-5, + 13 for the right
; byte), the ink (a random 0-3); $FF ends the list. Frees the actor IY (+0 =
; $FF); preserves IY. As in stage 1 at `$A1F3`.
;
; Witness: L1 23 (rzx-r4).
StartBurst:
  LD (BurstSmall),A
  PUSH DE
  LD DE,$0001
  CP $01
  JR Z,StartBurstSound
  LD DE,$0001
StartBurstSound:
  CALL PlaySoundVector
  POP DE
  LD HL,$0D7A
  LD (RandomPointer),HL
  PUSH IY
  LD A,C
  LD (ParticleInks),A
  ADD A,$40
  LD (ParticleInks+$0001),A
  LD A,B
  LD (ParticleInks+$0002),A
  ADD A,$40
  LD (ParticleInks+$0003),A
  LD A,$FF
  LD (BurstTimer),A
  LD IY,RoomAttributes
  LD B,$0C
StartBurstRow:
  PUSH BC
  LD B,$02
  LD L,$00
StartBurstByte:
  PUSH BC
  LD A,(IX+$00)
  LD (WorkByte),A
  LD B,$08
StartBurstBit:
  PUSH BC
  LD A,(WorkByte)
  BIT 7,A
  JR Z,StartBurstNextBit
  LD (IY+$00),D
  LD (IY+$01),E
StartBurstDirection:
  PUSH HL
  CALL Random
  POP HL
  AND $07
  CP $06
  JR NC,StartBurstDirection
  ADD A,L
  LD (IY+$02),A
  PUSH HL
  CALL Random
  POP HL
  AND $03
  LD (IY+$03),A
  INC IY
  INC IY
  INC IY
  INC IY
StartBurstNextBit:
  LD A,(WorkByte)
  SLA A
  LD (WorkByte),A
  INC D
  POP BC
  DJNZ StartBurstBit
  INC IX
  POP BC
  LD A,L
  ADD A,$0D
  LD L,A
  DJNZ StartBurstByte
  INC E
  LD A,D
  SUB $10
  LD D,A
  POP BC
  DJNZ StartBurstRow
  LD (IY+$00),$FF
  POP IY
  RET

; Move and draw the burst's particles one step (every pass)
;
; Called by the main loop `$7864`. Nothing while BurstTimer = $64. Else
; BurstTimer + 1; at $1C it ends (StopBurst; stage 4 has no shorter end for the
; small mode). The step picks the particles' glyph: $E85A[step + a random 0-3]
; x 8 + $E83A, written into ParticleGlyph. Each particle (4 bytes from $7040,
; $FF ends, $80 dead): its direction's step list at $E87D + direction x 32
; (index the step + its ink bits, doubled when BurstSmall) gives an index into
; BurstSteps (dx, dy; the second ten for directions 13 and up); the column + dx
; is kept within 1-30, the row - dy (outside rows 0-17 the particle dies: $80);
; then the 8 glyph bytes go into the play buffer and the cell's attribute
; (ParticleInks[ink]) into the shadow (AttrShadowAddressA $B510). As in stage 1
; at `$A28B`.
;
; Witness: L1 8619 (rzx-r4, s4-right).
UpdateBurst:
  LD A,(BurstTimer)
  CP $64
  RET Z
  INC A
  CP $1C
  JP Z,StopBurst
  LD (BurstTimer),A
  CALL Random
  AND $03
  LD C,A
  LD A,(BurstTimer)
  ADD A,C
  LD C,A
  LD B,$00
  LD HL,BurstGlyphs
  ADD HL,BC
  LD C,(HL)
  SLA C
  SLA C
  SLA C
  LD B,$00
  LD HL,ParticleGlyphs
  ADD HL,BC
  LD (ParticleGlyph+$0001),HL
  LD IY,RoomAttributes
UpdateBurstLoop:
  LD A,(IY+$00)
  CP $FF
  RET Z
  CP $80
  JP Z,UpdateBurstNext
  LD E,$01
  LD A,(IY+$02)
  CP $0A
  JR C,UpdateBurstIndex
  SUB $0D
  LD E,$00
UpdateBurstIndex:
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,BurstDirections
  ADD HL,BC
  LD A,(BurstTimer)
  LD C,A
  LD A,(IY+$03)
  AND $03
  ADD A,C
  LD C,A
  LD A,(BurstSmall)
  CP $00
  JR Z,UpdateBurstStepIndex
  SLA C
UpdateBurstStepIndex:
  LD B,$00
  ADD HL,BC
  LD C,(HL)
  SLA C
  LD B,$00
  LD HL,BurstSteps
  ADD HL,BC
  LD A,E
  CP $00
  JR Z,UpdateBurstMove
  LD BC,$0014
  ADD HL,BC
UpdateBurstMove:
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD A,(IY+$00)
  ADD A,E
  JR Z,UpdateBurstY
  CP $1F
  JR NC,UpdateBurstY
  LD (IY+$00),A
UpdateBurstY:
  LD A,(IY+$01)
  SUB D
  JR Z,UpdateBurstDraw
  CP $12
  JR C,UpdateBurstStoreY
  LD (IY+$00),$80
  JR UpdateBurstNext
UpdateBurstStoreY:
  LD (IY+$01),A
UpdateBurstDraw:
  LD A,(IY+$01)
  LD H,A
  LD L,$00
  LD BC,PlayBuffer
  ADD HL,BC
  LD C,(IY+$00)
  LD B,$00
  ADD HL,BC
ParticleGlyph:
  LD DE,$0000             ; LD DE,n: n = the step's glyph (written by
                          ; UpdateBurst)
  LD BC,$0020
  LD A,(DE)
  LD (HL),A
  ADD HL,BC
  INC DE
  LD A,(DE)
  LD (HL),A
  ADD HL,BC
  INC DE
  LD A,(DE)
  LD (HL),A
  ADD HL,BC
  INC DE
  LD A,(DE)
  LD (HL),A
  ADD HL,BC
  INC DE
  LD A,(DE)
  LD (HL),A
  ADD HL,BC
  INC DE
  LD A,(DE)
  LD (HL),A
  ADD HL,BC
  INC DE
  LD A,(DE)
  LD (HL),A
  ADD HL,BC
  INC DE
  LD A,(DE)
  LD (HL),A
  LD A,(IY+$03)
  AND $03
  LD L,A
  LD H,$00
  LD BC,ParticleInks
  ADD HL,BC
  LD E,(HL)
  LD A,(IY+$01)
  SLA A
  SLA A
  SLA A
  CALL AttrShadowAddressA
  LD (HL),E
UpdateBurstNext:
  INC IY
  INC IY
  INC IY
  INC IY
  JP UpdateBurstLoop

; An unreached RET byte after UpdateBurst's loop (its loop ends by RET Z at
; `$A456`)
;
; UpdateBurst leaves by RET Z inside its loop; nothing jumps to this byte. Not
; executed in any recording (the recordings checked: s4-right, rzx-r4); known
; only from the code.
BurstLeftover:
  DEFB $C9

; BurstTimer = $64: no burst
;
; Jumped to from UpdateBurst `$A426`. As in stage 1 at `$A393`.
;
; Witness: L1 15 (rzx-r4).
StopBurst:
  LD A,$64
  LD (BurstTimer),A
  RET

; The burst's four particle attributes, written by StartBurst
;
; ink C, bright ink C, ink B, bright ink B; the particle's byte 3 (0-3) picks
; one (UpdateBurst `$A4FD`). As loaded: 2, $42, $43, 3.
ParticleInks:
  DEFB $02,$42,$43,$03

; 20 (dx, dy) steps: 10 for the left-byte particles, 10 for the right-byte ones
;
; Read by UpdateBurst `$A491` (+$14 for the right-byte directions). dx -1 to 1
; columns, dy -1 to 1 rows.
BurstSteps:
  INCBIN "res/stage4/table-burst-steps.bin",$0000,40

  ORG $A605

; Put the hero's template $9EE1 into the hero's record $74E0 at column $16,
; line $41, standing
;
; SpawnActor $A639 at D = $16, E = $41, then HeroStandFrame $AF09. Called from
; StageEntry `$781F`. Stage 1 (`$A47D`) puts him at $0E, $31.
;
; Witness: L1 2 (rzx-r4, s4-right).
PlaceHeroAtStart:
  LD IY,HeroRecord
  LD HL,ActorTemplates
  LD D,$16
  LD E,$41
  CALL SpawnActor
  JP HeroStandFrame

; Set bit 7 of the actor's placement (it does not come back)
;
; IY = the actor: the placement +$10 x 3 + Placements gets bit 7, so
; LoadRoomActors skips it from now on. Called by StrikeableActor `$A957`,
; StrikeableKind9 `$A9AA` and `$8A12`. As in stage 1 at `$A48E`.
;
; Witness: L1 17 (rzx-r4).
MarkPlacementDone:
  LD L,(IY+$10)
  LD H,$00
  PUSH HL
  ADD HL,HL
  POP BC
  ADD HL,BC
  LD BC,(Placements)
  ADD HL,BC
  LD A,(HL)
  OR $80
  LD (HL),A
  RET

; Clear bit 7 of every placement of the current grid
;
; Called once from StageEntry `$781C`: every placed actor comes back. As in
; stage 1 at `$A4A1`.
;
; Witness: L1 2 (rzx-r4, s4-right).
ReviveAllPlacements:
  LD HL,(Placements)
  LD DE,$0003
ReviveAllPlacementsLoop:
  LD A,(HL)
  CP $FF
  RET Z
  AND $7F
  LD (HL),A
  ADD HL,DE
  JR ReviveAllPlacementsLoop

; Copy an 18-byte template (HL) into the record IY and put it at D, E
;
; Input: HL = the template, IY = the record, D, E = the column and line (also
; the base column and line at +$0D, +$0E). Preserves IY and DE. As in stage 1
; at `$A4B1`.
;
; Witness: L1 113 (rzx-r4, s4-right).
SpawnActor:
  PUSH IY
  PUSH DE
  PUSH IY
  POP DE
  LD BC,$0012
  LDIR
  POP DE
  LD (IY+$00),D
  LD (IY+$0D),D
  LD (IY+$01),E
  LD (IY+$0E),E
  POP IY
  RET

; Free the actors not kept over a room change and create the room's placed
; actors
;
; Jumped to from RoomChange `$988C`. Frees every record of $74F2-$75DB without
; +$0F bit 1. Then walks Placements (3 bytes: the kind, bit 7 done; column and
; row in cells over the whole grid; $FF ends). A placement not done inside the
; room window (column in 2 x RoomColumn to + 29, row in 2 x RoomRow to + 17)
; takes a free record found from $75CA down and is filled from the kind table
; $9E1B (9 bytes a kind: the line offset, the handler, five bytes for +8..+$0C,
; +$0F): the column and line relative to the room (the line = row x 8 + the
; offset), the base column and line, +$10 = the placement's index (WorkByte),
; width 1, height 8, +$11 = 0, and a random 0-63 (NextSeed $909D) for +$0A when
; the kind gives $40 (no stage-4 kind does). As in stage 1 at `$A4CC`.
;
; Witness: L1 57 (rzx-r4, s4-right).
LoadRoomActors:
  LD IY,Actors
  LD DE,$0012
  LD B,$0D
LoadRoomActorsFree:
  BIT 1,(IY+$0F)
  JR NZ,LoadRoomActorsNext
  LD (IY+$00),$FF
LoadRoomActorsNext:
  ADD IY,DE
  DJNZ LoadRoomActorsFree
  LD HL,(Placements)
  LD IY,LastActor
  LD A,$00
  LD (WorkByte),A
LoadRoomActorsSlot:
  LD A,(IY+$00)
  CP $FF
  JR Z,LoadRoomActorsPlacement
  LD BC,$FFEE
  ADD IY,BC
  JR LoadRoomActorsSlot
LoadRoomActorsPlacement:
  LD A,(HL)
  CP $FF
  RET Z
  PUSH HL
  LD A,(HL)
  CP $80
  JP NC,LoadRoomActorsSkip
  LD A,(RoomColumn)
  SLA A
  LD B,A
  ADD A,$1E
  LD C,A
  LD A,(RoomRow)
  SLA A
  LD D,A
  ADD A,$12
  LD E,A
  INC HL
  LD A,(HL)
  CP B
  JP C,LoadRoomActorsSkip
  CP C
  JP NC,LoadRoomActorsSkip
  INC HL
  LD A,(HL)
  DEC HL
  DEC HL
  CP D
  JP C,LoadRoomActorsSkip
  CP E
  JP NC,LoadRoomActorsSkip
  PUSH HL
  PUSH DE
  PUSH BC
  LD A,(HL)
  LD HL,ActorKinds
  LD B,A
  CP $00
  JR Z,LoadRoomActorsFill
  LD DE,$0009
LoadRoomActorsKind:
  ADD HL,DE
  DJNZ LoadRoomActorsKind
LoadRoomActorsFill:
  LD A,(HL)
  LD (IY+$01),A
  INC HL
  LD A,(HL)
  LD (IY+$06),A
  INC HL
  LD A,(HL)
  LD (IY+$07),A
  INC HL
  PUSH IY
  POP DE
  EX DE,HL
  LD BC,$0008
  ADD HL,BC
  EX DE,HL
  LD BC,$0005
  LDIR
  LD A,(HL)
  LD (IY+$0F),A
  LD (IY+$11),$00
  POP BC
  POP DE
  POP HL
  PUSH HL
  INC HL
  LD A,(HL)
  SUB B
  LD (IY+$00),A
  INC HL
  LD A,(HL)
  SUB D
  SLA A
  SLA A
  SLA A
  ADD A,(IY+$01)
  LD (IY+$01),A
  POP HL
  LD A,(IY+$00)
  LD (IY+$0D),A
  LD A,(IY+$01)
  LD (IY+$0E),A
  LD A,(WorkByte)
  LD (IY+$10),A
  LD (IY+$02),$01
  LD (IY+$03),$08
  LD A,(IY+$0A)
  CP $40
  JR NZ,LoadRoomActorsTaken
  CALL NextSeed
  AND $3F
  LD (IY+$0A),A
LoadRoomActorsTaken:
  LD BC,$FFEE
  ADD IY,BC
LoadRoomActorsSkip:
  LD A,(WorkByte)
  INC A
  LD (WorkByte),A
  POP HL
  LD BC,$0003
  ADD HL,BC
  JP LoadRoomActorsSlot

; Call the handler of every used actor record (the hero first)
;
; For the 14 records from $74E0: when +0 is not $FF, the handler +6/+7 is
; written into HandlerCall and called with IY = the record. Called from `$782B`
; and the main loop `$7855`. As in stage 1 at `$A5BD`.
;
; Witness: L1 8621 (rzx-r4, s4-right).
RunActorHandlers:
  LD B,$0E
  LD IY,HeroRecord
RunActorHandlersLoop:
  PUSH BC
  LD A,(IY+$00)
  INC A
  JR Z,RunActorHandlersNext
  LD L,(IY+$06)
  LD H,(IY+$07)
  LD (HandlerCall+$0001),HL
HandlerCall:
  CALL $0000              ; CALL n: n = the record's handler (written above)
RunActorHandlersNext:
  POP BC
  LD DE,$0012
  ADD IY,DE
  DJNZ RunActorHandlersLoop
  RET

  ORG $B2C0

; Move the actor IY's base column by E (the other way when it faces left)
;
; As in stage 1 at `$B112`.
;
; Witness: L1 904 (rzx-r4, s4-right).
MoveBaseX:
  LD A,E
  BIT 7,(IY+$09)
  JR Z,MoveBaseXAdd
  NEG
MoveBaseXAdd:
  ADD A,(IY+$0D)
  LD (IY+$0D),A
  RET

; A = -A when the actor IY faces left (+9 bit 7)
;
; As in stage 1 at `$B122`.
;
; Witness: L1 62844 (rzx-r4, s4-right).
NegateIfFacingLeft:
  BIT 7,(IY+$09)
  RET Z
  NEG
  RET

; Facing left: A = 4 - A (not referenced)
;
; BIT 7 of +9; facing right A stays; facing left NEG and + 4. No instruction or
; word of the image refers to `$B2D8`.
;
; Not executed in any recording (the recordings checked: s4-right, rzx-r4);
; known only from the code.
NegateAdd4IfLeft:
  BIT 7,(IY+$09)
  RET Z
  NEG
  ADD A,$04
  RET

; HL = DE + 6A: frame A's record in the frame table DE
;
; As in stage 1 at `$B12A`.
;
; Witness: L1 62837 (rzx-r4, s4-right).
FrameRecordAddress:
  LD L,A
  LD H,$00
  ADD HL,HL
  PUSH HL
  ADD HL,HL
  POP BC
  ADD HL,BC
  ADD HL,DE
  RET

  ORG $B454

; Add a missile (shot, spark) to the first eight slots of the missile records
; $75E0
;
; In: D column, E line, C type, B and A its parameters. 16 records of 6 bytes:
; +0 column ($FF free), +1 line, +2 type (MissileHandlers), +3 $FF, +4 B, +5 A.
; The search starts after MissileCursor's slot (round robin over 8). A = $FA
; puts a Random $90AC byte in +5. Out: Z when the eight slots are full (nothing
; added), else NZ. From HeroThrowMissile `$AEC6` and HeadShots `$B443`. As in
; stage 1 at `$B28D`.
;
; Witness: L1 120 (rzx-r4).
AddMissile:
  PUSH BC
  PUSH DE
  PUSH AF
  LD BC,Missiles
  JR AddMissileFrom

; Add a missile to the slots 8-15 ($7610) of the missile records
;
; As in stage 1 at `$B296`.
;
; Witness: L1 97 (rzx-r4, s4-right).
AddMissileHigh:
  PUSH BC
  PUSH DE
  PUSH AF
  LD BC,MissilesHigh

; Add a missile to the eight slots from BC
;
; As in stage 1 at `$B29C`.
;
; Witness: L1 217 (rzx-r4, s4-right).
AddMissileFrom:
  LD D,$00
AddMissileSearch:
  LD A,(MissileCursor)
  INC A
  AND $07
  LD (MissileCursor),A
  SLA A
  LD L,A
  SLA A
  ADD A,L
  LD L,A
  LD H,$00
  ADD HL,BC
  INC D
  LD A,D
  CP $08
  JR Z,AddMissileFull
  LD A,(HL)
  CP $FF
  JR NZ,AddMissileSearch
  POP AF
  POP DE
  POP BC
  LD (HL),D
  INC HL
  LD (HL),E
  INC HL
  LD (HL),C
  INC HL
  LD (HL),$FF
  INC HL
  LD (HL),B
  INC HL
  LD (HL),A
  CP $FA
  RET NZ
  PUSH HL
  CALL Random
  POP HL
  LD (HL),A
  LD A,$01
  CP $02
  RET
AddMissileFull:
  POP AF
  POP DE
  POP BC

  ORG $B4AC

; Run the handler of every missile in use (once a main-loop pass)
;
; The 16 missile records $75E0 (6 bytes each, IY): a record whose +0 is not $FF
; calls MissileHandlers[+2] through the CALL at MissileCall, whose operand it
; writes. IX is kept. As in stage 1 at `$B2E6`.
;
; Witness: L1 8619 (rzx-r4, s4-right).
UpdateMissiles:
  PUSH IX
  LD B,$10
  LD IY,Missiles
  LD DE,$0006
UpdateMissilesLoop:
  LD A,(IY+$00)
  CP $FF
  JR Z,UpdateMissilesNext
  PUSH BC
  LD L,(IY+$02)
  SLA L
  LD H,$00
  LD BC,MissileHandlers
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (MissileCall+$0001),DE
MissileCall:
  CALL $0000              ; CALL nn: nn = the kind's handler, written by
                          ; UpdateMissiles
  POP BC
  LD DE,$0006
UpdateMissilesNext:
  ADD IY,DE
  DJNZ UpdateMissilesLoop
  POP IX
  RET

; The handler of each missile kind 0-9
;
; 0 and 4 $8D68, 1 $803A (UpdateAimedShot), 2 $80F4 (FireKind3's shot), 3
; HeadShot $B5C5, 5 and 6 $8450 (the thrown item, left and right), 7 and 8
; $8484 (UpdatePathFlyer; 7 the death burst), 9 $80CC (FireKind1's shot). Read
; by UpdateMissiles `$B4C6`.
MissileHandlers:
  DEFW HangFlashBorder
  DEFW UpdateAimedShot
  DEFW UpdateHeroBolt
  DEFW HeadShot
  DEFW HangFlashBorder
  DEFW UpdateDart
  DEFW UpdateDart
  DEFW UpdatePathFlyer
  DEFW UpdatePathFlyer
  DEFW UpdateHeroShot

  ORG $B520

; Free the actor record IY (+0 = $FF)
;
; As in stage 1 at `$B35E`.
;
; Witness: L1 303 (rzx-r4, s4-right).
RemoveActor:
  LD (IY+$00),$FF
  RET

; C = $44 or $45 (bright green, bright cyan) on alternate passes
;
; No instruction or word of the image refers to `$B525`. As in stage 1 at
; `$B36C`.
;
; Not executed in any recording (the recordings checked: s4-right, rzx-r4);
; known only from the code.
ColourGreenCyan:
  LD A,(PassCounter)
  LD C,$44
  AND $01
  RET Z
  LD C,$45
  RET

; C = $42 or $43 (bright red, bright magenta) on alternate passes
;
; From FragmentActor `$AA4C`. As in stage 1 at `$B377`.
;
; Not executed in any recording (the recordings checked: s4-right, rzx-r4);
; known only from the code.
ColourRedMagenta:
  LD A,(PassCounter)
  LD C,$42
  AND $01
  RET Z
  LD C,$43
  RET

; C = $42 (bright red) or 6 (yellow) on alternate passes
;
; From `$8089` and `$8092`. As in stage 1 at `$B382`.
;
; Witness: L1 642 (rzx-r4).
ColourRedYellow:
  LD A,(PassCounter)
  LD C,$42
  AND $01
  RET Z
  LD C,$06
  RET

; The actor's colour: $47 while the hero is in columns 0-8, else down by one a
; call to $43 (not referenced)
;
; No instruction or word of the image refers to `$B546`.
;
; Not executed in any recording (the recordings checked: s4-right, rzx-r4);
; known only from the code.
DimNearStart:
  LD A,(HeroRecord)
  CP $09
  JR C,DimNearStartWhite
  LD A,(IY+$0C)
  CP $43
  RET Z
  DEC (IY+$0C)
  RET
DimNearStartWhite:
  LD (IY+$0C),$47
  RET

; C = $46 or $43 (bright yellow, bright magenta) on alternate passes
;
; From `$8540` and MissileColour. As in stage 1 at `$B38D`.
;
; Witness: L1 2691 (s4-right).
ColourYellowMagenta:
  LD A,(PassCounter)
  LD C,$46
  AND $01
  RET Z
  LD C,$43
  RET

; C = the colour of the missile IY: kind 2 ColourYellowMagenta, else
; MissileColours[pass AND 3]
;
; Called only from DrawMissileMirrored `$B626`. As in stage 1 at `$B3A3`.
;
; Not executed in any recording (the recordings checked: s4-right, rzx-r4);
; known only from the code.
MissileColour:
  LD A,(IY+$02)
  CP $02
  JR Z,ColourYellowMagenta
  LD A,(PassCounter)
  AND $03
  LD C,A
  LD B,$00
  LD HL,MissileColours
  ADD HL,BC
  LD C,(HL)
  RET

; bright red, bright magenta, bright red, magenta
;
; Read by MissileColour (LD HL,MissileColours + FrameCounter AND 3), which no
; recording ran (the recordings checked: s4-right, rzx-r4); known only from the
; code.
MissileColours:
  DEFB $42,$43,$42,$03

; C = ColourCycle4[pass AND 3]: bright red, bright magenta, bright red, yellow
;
; Called by the kind-12 handler `$8917`.
;
; Witness: L1 5259 (rzx-r4).
ColourRedYellowCycle:
  LD A,(PassCounter)
  AND $03
  LD C,A
  LD B,$00
  LD HL,ColourCycle4
  ADD HL,BC
  LD C,(HL)
  RET

; $42, $43, $42, 6
;
; Read by ColourRedYellowCycle (LD HL,ColourCycle4 + the counter AND 3). Read
; in rzx-r4 (5259 passes); not in s4-right.
ColourCycle4:
  DEFB $42,$43,$42,$06

; C = HeadShotColours[pass AND 7]: bright red to bright yellow and back
;
; Called by HeadShot `$B5FE`.
;
; Witness: L1 2178 (rzx-r4).
HeadShotColour:
  LD A,(PassCounter)
  AND $07
  LD C,A
  LD B,$00
  LD HL,HeadShotColours
  ADD HL,BC
  LD C,(HL)
  RET

; $42, $43, $44, $45, $46, $45, $44, $43
;
; Read by HeadShotColour (LD HL,HeadShotColours + the counter AND 7). Read in
; rzx-r4 (2178 passes); not in s4-right.
HeadShotColours:
  DEFB $42,$43,$44,$45,$46,$45,$44,$43

; The actor IY's colour +$0C = CycleColour
;
; As in stage 1 at `$B3BD`.
;
; Witness: L1 6649 (rzx-r4).
SetCycleColour:
  CALL CycleColour
  LD (IY+$0C),A
  RET

; A = CycleColours[pass AND 7]: bright cyan, green, magenta, red, blue, red,
; magenta, green
;
; As in stage 1 at `$B3C4`; HeroUpdate `$AE3B` uses it for the weak hero.
;
; Witness: L1 7385 (rzx-r4, s4-right).
CycleColour:
  LD A,(PassCounter)
  AND $07

; A = CycleColours[A] (CycleColour's second half)
;
; Called with A = 0-7 by `$8AC7`.
;
; Witness: L1 7517 (rzx-r4, s4-right).
CycleColourA:
  LD C,A
  LD B,$00
  LD HL,CycleColours
  ADD HL,BC
  LD A,(HL)
  RET

; the colour cycle
;
; Read by CycleColourA (LD HL,CycleColours) in s4-right (170 passes) and rzx-r4
; (7347), and by FlashPieces $83A1 in rzx-r4 (540).
CycleColours:
  DEFB $45,$44,$43,$42,$41,$42,$43,$44
