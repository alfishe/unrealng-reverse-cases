; --------------------------------------------------------------------------------------------------------------------
; actors.asm: The actor records: placement, the per-pass update, the frames, the bursts
; --------------------------------------------------------------------------------------------------------------------

  ORG $8B5E

; Move the actor IY right by A eighths of a byte column (no caller)
;
; Adds A to the fraction +$11; past 8 takes 8 off and moves +0 and +$0D one
; column right. Nothing calls it (no
;
; CALL, JP or table word names $8B5E): a leftover of the engine.
;
; As in stage 1 at $8B37, the same code.
;
; Not executed in any recording (the recordings checked: s2-right, rzx-r2);
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
; column +$0D one column against the
;
; facing (MoveBaseX $B256 with E = -1). Called by HeroRecoil ($87DE); stage 1's
; other caller, the warrior's flying head, has no stage-2 counterpart.
;
; As in stage 1 at $8B4E, the same code.
;
; Not executed in any recording (the recordings checked: s2-right, rzx-r2);
; known only from the code.
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

; Move the actor IY left by A eighths of a byte column
;
; As StepFineRight leftwards (+0 and +$0D one column left on a borrow). Called
; by MedusaHeadFalls ($81F5): Medusa's falling head drifts left.
;
; As in stage 1 at $8B61, the same code.
;
; Witness: L1 26 (rzx-r2).
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

  ORG $8D45

; Count down to the next random enemy
;
; Every pass: SpawnDelay - 1; at 0 reloads it with 5-20 (Random & 15 + 5) and,
; on a random bit 0 clear, goes to SpawnRandomEnemy $8F8C (stage 1: 30-61 and
; grid 0 only; the grid test is in SpawnRandomEnemy here). rzx-r2: 437 reloads,
; 190 tries.
;
; As in stage 1 at $8D1D with a shorter delay.
;
; Witness: L1 8032 (rzx-r2, s2-right, stageload).
SpawnTimer:
  LD A,(SpawnDelay)
  DEC A
  JR Z,SpawnTimerFire
  LD (SpawnDelay),A
  RET
SpawnTimerFire:
  CALL Random
  AND $0F
  ADD A,$05
  LD (SpawnDelay),A
  CALL Random
  AND $01
  JP Z,SpawnRandomEnemy
  RET

; Code no CALL or JP reaches: PUSH IY twice, POP HL, POP DE, LD BC,$11, LD
; (HL),0, INC DE, LDIR, RET (clears the 18-byte record at IY)
;
; No reader and no jump: the bytes between SpawnTimer and FindFreeActor. As
; code it would clear the actor record IY; stage 2 frees records with
; RemoveActor instead.
ClearRecordUnused:
  DEFB $FD,$E5,$FD,$E5,$E1,$D1,$01,$11,$00,$36,$00,$13,$ED,$B0,$C9

; IY = the first free actor record of 13 (Z), else NZ
;
; A record is free when its +0 is $FF. Returns NZ (via $B410) when none is
; free.
;
; As in stage 1 at $8D3A, the same code.
;
; Witness: L1 303 (rzx-r2, s2-right, stageload).
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
; For an enemy of two records (the warrior and its head). 12 records searched.
;
; As in stage 1 at $8D50, the same code.
;
; Witness: L1 11 (rzx-r2, s2-right, stageload).
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

  ORG $8EE1

; Free the actor record IY and the next one (+0 and +$12 = $FF)
;
; No stage-2 code calls or jumps to it (stage 1's callers, the warrior's walk,
; have no stage-2 counterpart); not executed in any recording (the recordings
; checked: s2-right, rzx-r2); known only from the code.
;
; As in stage 1 at $B363, the same code.
;
; Not executed in any recording (the recordings checked: s2-right, rzx-r2);
; known only from the code.
RemoveActorPair:
  LD (IY+$00),$FF
  LD (IY+$12),$FF
  RET

; Clear the shots and free all 13 actor records ($74F2, 234 bytes of $FF)
;
; Fills $74F2-$75DB with $FF, then ClearShots (JR). Called by StageEntry
; ($780A) and StartGrid ($A377): 8 times in rzx-r2 (frames 248-17558).
;
; As in stage 1 at $921E.
;
; Witness: L1 13 (rzx-r2, s2-right, stageload).
ClearActors:
  LD HL,Actors
  LD DE,Actors+$0001
  LD BC,$00E9
  LD (HL),$FF
  LDIR
  JR ClearShots

  ORG $8F14

; Fill the shot slots $75E0-$763F (96 bytes) with $FF
;
; Called by RoomChange ($9265); jumped to from ClearActors ($8EF7).
;
; As in stage 1 at $924B, the same code.
;
; Witness: L1 56 (rzx-r2, s2-right, stageload).
ClearShots:
  LD HL,Missiles
  LD DE,Missiles+$0001
  LD BC,$0060
  LD (HL),$FF
  LDIR
  RET

  ORG $8F84

; +$0E (the base line) + C
;
; Called by ExtraLifeActor ($9B17), HarpyRiseActor ($A82A), DropActor ($A95F),
; CheckHeroFooting ($ACD8), HeroLeap ($B207).
;
; As in stage 1 at $92C9, the same code.
;
; Witness: L1 1047 (rzx-r2, s2-right, stageload).
MoveActorY:
  LD A,(IY+$0E)
  ADD A,C
  LD (IY+$0E),A
  RET

  ORG $9607

; The 21 placement kinds, 9 bytes each: the Y offset, the handler, 5 bytes for
; the record's +8 to +$0C, the record's +$0F
;
; As stage 1's: LoadRoomActors ($A499) builds an actor from a placement with
; its kind's row: +1 Y = the placement's Y x 8 + the offset, +6/+7 the handler,
; +8 to +$0C (the counter, the flags, the state, the item, the attribute), +$0F
; (bit 0 shootable: ShotHitsActor; bit 1 kept over a room change:
; LoadRoomActors). The handlers: 0 KneelingStatueActor, 1, 14, 15
; WarriorStatueActor, 2 HarpyLampActor, 3 HarpyRiseActor, 4 and 5 PoolActor, 6
; DropActor, 7-10 HydraHead1Actor, HydraHead2Actor, HydraHead3Actor,
; HydraHead1LowActor, 11 MedusaActor, 12 MedusaHeadActor, 13 HarpyFlameActor,
; 16-19 StrikeableActor, 20 WaterActor.
;
; All 189 bytes read in rzx-r2 (117 in s2-right).
ActorKinds:
  INCBIN "res/stage2/table-kinds.bin",$0000,189

; Nine whole actor records (18 bytes each, the first the hero's) that
; SpawnActor copies for the actors no placement makes
;
; The handler at +6/+7 and the frame at +4/+5 as for a placed actor; the rest
; as an actor record (HeroRecord $74E0). All read in rzx-r2 (90 of 162 bytes in
; s2-right); ExtraLifeTemplateFlags written by ReleaseExtraLife.
ActorTemplates:
HeroTemplate:
  INCBIN "res/stage2/table-actor-templates.bin",$0000,18
SpiritTemplate:
  INCBIN "res/stage2/table-actor-templates.bin",$0012,18
HarpyWingsTemplate:
  INCBIN "res/stage2/table-actor-templates.bin",$0024,18
HarpyTemplate:
  INCBIN "res/stage2/table-actor-templates.bin",$0036,18
ItemTemplate:
  INCBIN "res/stage2/table-actor-templates.bin",$0048,18
ExtraLifeTemplate:
  INCBIN "res/stage2/table-actor-templates.bin",$005A,9
ExtraLifeTemplateFlags:
  INCBIN "res/stage2/table-actor-templates.bin",$0063,9
SparkleTemplate:
  INCBIN "res/stage2/table-actor-templates.bin",$006C,18
PieceTemplate:
  INCBIN "res/stage2/table-actor-templates.bin",$007E,18
FragmentTemplate:
  INCBIN "res/stage2/table-actor-templates.bin",$0090,18

; Clear and set the stage variables at the start of the stage
;
; Clears $FE08-$FE6D (102 bytes), copies StartItems to CarriedItems, seeds
; RandomPointer from R and draws SpawnDelay (Random), then sets the stage's
; start values: InitOnly41 1, InitOnly40 $0D, InitOnly10 2, InitOnly12 1,
; InitOnly3A $10, ItemFirst and ItemSelected 6, ItemLast 7, slot 7's count $24
; (36 of item 1), BurstTimer $64 (no burst), RandomSeed and RandomPointer
; $07CF, the hydra: Hydra1Neck and Hydra3Neck $0E, Hydra2Neck $16, HydraHeads
; 3, the necks' ends (Hydra1X, Y) = $28, $15, (Hydra2X, Y) = $6D, $11,
; (Hydra3X, Y) = $34, $0E; EnergyChange $2E (energy refilled to full),
; RespawnShiftX $FF.
;
; Called once from StageEntry ($7804), frame 26 in both recordings. Output:
; none. Side effects: the $FE08-$FE6D stage variables.
;
; As in stage 1 at $9DA1 with stage 2's variables.
;
; Witness: L1 3 (rzx-r2, s2-right, stageload).
InitStageState:
  LD HL,RandomSeed
  LD DE,RandomSeed+1
  LD BC,$0065
  LD (HL),$00
  LDIR
  LD HL,StartItems
  LD DE,CarriedItems
  LD BC,$000C
  LDIR
  LD A,R
  LD C,A
  LD A,R
  LD B,A
  LD (RandomPointer),BC
  CALL Random
  LD (SpawnDelay),A
  LD A,$01
  LD (InitOnly41),A
  LD A,$0D
  LD (InitOnly40),A
  LD A,$02
  LD (InitOnly10),A
  LD A,$01
  LD (InitOnly12),A
  LD A,$10
  LD (InitOnly3A),A
  LD A,$06
  LD (ItemFirst),A
  LD A,$06
  LD (ItemSelected),A
  LD A,$07
  LD (ItemLast),A
  LD A,$24
  LD (CarriedCounts+$0007),A
  LD A,$64
  LD (BurstTimer),A
  LD HL,$07CF
  LD (RandomSeed),HL
  LD (RandomPointer),HL
  LD A,$0E
  LD (Hydra3Neck),A
  LD (Hydra1Neck),A
  LD A,$16
  LD (Hydra2Neck),A
  LD A,$03
  LD (HydraHeads),A
  LD A,$28
  LD (Hydra1X),A
  LD A,$15
  LD (Hydra1Y),A
  LD A,$6D
  LD (Hydra2X),A
  LD A,$11
  LD (Hydra2Y),A
  LD A,$34
  LD (Hydra3X),A
  LD A,$0E
  LD (Hydra3Y),A
  LD A,$2E
  LD (EnergyChange),A
  LD A,$FF
  LD (RespawnShiftX),A
  RET

; 12 bytes no code reads: 0, 1, 2, 2, 1, 0, 0, 1, 3, 3, 1, 0
;
; No instruction reads or writes them (neither recording touches them, and no
; operand points into $9804-$980F).
Unused9804:
  DEFB $00,$01,$02,$02,$01,$00,$00,$01,$03,$03,$01,$00

  ORG $99E1

; Score 20, then burst the actor (shape BurstShape20 $EEE2) into particles and
; free it
;
; IY = the actor. AddScore $7B1F with 20, then StartBurst at X - 7, Y / 8 with
; the shape at $EEE2 in the small mode, colours 6 and 4 (3 and 2 when +8 = 8).
; StartBurst returns into the caller, which frees the actor.
;
; Called by StrikeableActor ($A9D4) when an urn is struck: 10 times in rzx-r2.
;
; As in stage 1 at $A065, the same code.
;
; Witness: L1 10 (rzx-r2).
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
  LD IX,BurstShape20
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

; The warrior statue (kind 1) smashed: Statue1State = $C8, a burst, item kind 2
; and 7 fragments
;
; Statue1State = $C8 (the statue is not placed again), then StartBurst at
; column $0D, row 4 with BurstShapeStatue $EECA, inks 6 and 7, the big mode (A
; = 0); SpawnItem kind 2 (amount 1, the icon ItemIconKind2 $DEE5) at column
; $14, line $60; SpawnFragments (a JP) with D = 7 fragments at column $14, line
; $75.
;
; Jumped to from WarriorStatueActor ($A756 JP Z) at the sixth strike: once in
; rzx-r2.
;
; Witness: L1 1 (rzx-r2).
BreakStatue1:
  LD A,$C8
  LD (Statue1State),A
  LD D,$0D
  LD E,$04
  LD IX,BurstShapeStatue
  LD B,$06
  LD C,$07
  LD A,$00
  CALL StartBurst
  LD D,$14
  LD E,$60
  LD L,$02
  LD H,$01
  LD BC,ItemIconKind2
  CALL SpawnItem
  LD D,$07
  LD B,$14
  LD C,$75
  JP SpawnFragments

; The kneeling statue (kind 0) broken: Statue0Broken = 1, a burst, 36 of item
; kind 1 and 5 fragments
;
; Statue0Broken = 1, StartBurst at column $0D, row 5 with BurstShapeStatue
; $EECA, inks 6 and 7, the big mode; SpawnItem kind 1 (amount $24, the icon
; ItemIconKind1 $DE85) at column $14, line $60; SpawnFragments (a JP) with D =
; 5 at column $13, line $75.
;
; Jumped to from KneelingStatueActor ($A70B JP Z): once in rzx-r2.
;
; Witness: L1 1 (rzx-r2).
BreakStatue0:
  LD A,$01
  LD (Statue0Broken),A
  LD D,$0D
  LD E,$05
  LD IX,BurstShapeStatue
  LD B,$06
  LD C,$07
  LD A,$00
  CALL StartBurst
  LD D,$14
  LD E,$60
  LD BC,ItemIconKind1
  LD L,$01
  LD H,$24
  CALL SpawnItem
  LD D,$05
  LD B,$13
  LD C,$75
  JP SpawnFragments

; Put an item actor (template $970C) into a free record
;
; Input: D, E = X and Y, BC = the item's frame, L = the item kind (+$0B), H =
; the amount (+$0A). FindFreeActor $8D71; with a free record: SpawnActor with
; the template $970C (16 x 16 lines, handler ItemHandler), then the frame, kind
; and amount. Preserves IY.
;
; As in stage 1 at $A098, the same code.
;
; Witness: L1 7 (rzx-r2).
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

; An urn's extra life: ExtraLifeTemplate two columns from the urn, on the
; hero's far side
;
; IY = the struck urn. HL = ExtraLifeTemplate $971E, D = the urn's base column
; (+$0D), E = its base line (+$0E) - $18. The hero facing right (HeroFlags bit
; 7 clear): the template's flags ExtraLifeTemplateFlags $9727 = $80 (the life
; faces left) and D + 2; facing left: D - 2 (the flags as they are: once set to
; $80 they stay). SpawnActor (a JP) puts the life into the urn's own record.
;
; Jumped to from StrikeableActor ($A9E6 JP Z) for the urn kinds that hold a
; life: twice in rzx-r2.
;
; Witness: L1 2 (rzx-r2).
ReleaseExtraLife:
  LD HL,ExtraLifeTemplate
  LD D,(IY+$0D)
  LD A,(HeroFlags)
  AND $80
  JR NZ,ReleaseExtraLifeLeft
  LD A,$80
  LD (ExtraLifeTemplateFlags),A
  INC D
  INC D
  JR ReleaseExtraLifeSpawn
ReleaseExtraLifeLeft:
  DEC D
  DEC D
ReleaseExtraLifeSpawn:
  LD A,(IY+$0E)
  SUB $18
  LD E,A
  JP SpawnActor

; An urn's item: 36 of item kind 1 (the icon ItemIconKind1 $DE85) where the urn
; stood, the urn freed
;
; IY = the urn. SpawnItem at its column (+0) and base line (+$0E) with kind 1,
; amount $24, then RemoveActor (a JP).
;
; Jumped to from StrikeableActor ($A9E1 JP Z): three times in rzx-r2.
;
; Witness: L1 3 (rzx-r2).
DropUrnItem:
  LD D,(IY+$00)
  LD E,(IY+$0E)
  LD L,$01
  LD H,$24
  LD BC,ItemIconKind1
  CALL SpawnItem
  JP RemoveActor

; An item on the floor: taken when the hero stands on it (400 points, AddItem,
; effect 4)
;
; IY = the item (ItemTemplate $970C, frame = its icon). The colour cycles
; (SetCycleColour). HeroOnItem with C = $14: no carry, nothing more. Taken:
; AddScore 400 ($0190), AddItem with A = the kind (+$0B) and D = the amount
; (+$0A), PlaySoundVector 4; the kind 5 (the artefact) adds 1 to
; PiecesComplete; RemoveActor (a JP).
;
; The handler in ItemTemplate: 268 passes and 7 items taken in rzx-r2.
;
; Witness: L1 268 (rzx-r2).
ItemHandler:
  CALL SetCycleColour
  LD C,$14
  CALL HeroOnItem
  RET NC
  LD BC,$0190
  CALL AddScore
  LD A,(IY+$0B)
  LD D,(IY+$0A)
  CALL AddItem
  LD DE,$0004
  CALL PlaySoundVector
  LD A,(IY+$0B)
  CP $05
  JP NZ,RemoveActor
  LD HL,PiecesComplete
  INC (HL)
  JP RemoveActor

; The extra life: drifts up and left (frames 18-21 of the lamp set); the hero
; touching it gains a life
;
; IY = the life (ExtraLifeTemplate $971E, +8 = $12). +8 + 1; at $16 it goes
; back to $12 and the life moves: MoveBaseX with E = -1 (freed at column 0 or
; $20 and up), MoveActorY with C = -4. The touch: the hero's line ($74E1) less
; the life's line under $14 and the hero's column equal to the life's or one
; less: StartLivesFlash, Lives + 1 (not stored when it would be 6) with
; PlaySoundVector 4, then ExtraLifeSparkle (a JP), which turns the record into
; the sparkle. Else HarpyLampFrame (a JP) shows frame +8 of HarpyLampSet $A7F2.
;
; The handler in ExtraLifeTemplate: 102 passes in rzx-r2, the life taken once.
;
; Witness: L1 102 (rzx-r2).
ExtraLifeActor:
  INC (IY+$08)
  LD A,(IY+$08)
  CP $16
  JR NZ,ExtraLifeTouch
  LD (IY+$08),$12
  LD E,$FF
  CALL MoveBaseX
  JP Z,RemoveActor
  CP $20
  JP NC,RemoveActor
  LD C,$FC
  CALL MoveActorY
ExtraLifeTouch:
  LD A,(HeroY)
  SUB (IY+$01)
  CP $14
  JR NC,ExtraLifeFrame
  LD E,(IY+$00)
  LD A,(HeroRecord)
  CP E
  JR Z,ExtraLifeTaken
  DEC A
  CP E
  JR NZ,ExtraLifeFrame
ExtraLifeTaken:
  CALL StartLivesFlash
  LD A,(Lives)
  INC A
  CP $06
  JP Z,ExtraLifeSparkle
  LD (Lives),A
  LD DE,$0004
  CALL PlaySoundVector
  JP ExtraLifeSparkle
ExtraLifeFrame:
  LD A,(IY+$08)
  JP HarpyLampFrame

; The sparkle where a life was taken: frames 1-5 of SparkleSet, then freed
;
; IY = the sparkle (SparkleTemplate $9730, +8 = $FF). +8 + 1; at 6 RemoveActor
; (a JP); else SetActorFrame $AC52 with the inline words SparkleSet.
;
; The handler in SparkleTemplate: 7 passes in rzx-r2.
;
; Witness: L1 7 (rzx-r2).
SparkleActor:
  INC (IY+$08)
  LD A,(IY+$08)
  CP $06
  JP Z,RemoveActor
  CALL SetActorFrame

; SetActorFrame's inline words: the frame table $E5F8, the graphics
; SparkleSprites $E5D3
;
; Read by SetActorFrame from SparkleActor ($9B5A): rzx-r2 (all four bytes); not
; in s2-right.
SparkleSet:
  DEFW SparkleFrameTable,SparkleSprites

; Carry when the hero stands on the item IY: the same column (3 further right
; when the item faces left), the line within C
;
; E = the hero's column ($74E0), D = the item's column, + 3 when its +9 bit 7
; is set; AbsDiffAtMost with A = 1 (carry only when the two are equal); no
; carry: return. Then on into HeroWithinY with C.
;
; Called by ItemHandler ($9AD2): 268 times in rzx-r2.
;
; Witness: L1 268 (rzx-r2).
HeroOnItem:
  LD A,(HeroRecord)
  LD E,A
  LD D,(IY+$00)
  BIT 7,(IY+$09)
  JR Z,HeroOnItemColumn
  INC D
  INC D
  INC D
HeroOnItemColumn:
  LD A,$01
  CALL AbsDiffAtMost
  RET NC

; Carry set when the hero's Y is within C lines of the actor's
;
; Input: IY = the actor, C = the distance. E = the hero's Y ($74E1), D = the
; actor's Y, then AbsDiffAtMost $A91B (a JP): carry when |E - D| < C.
;
; As in stage 1 at $A11E, the same code.
;
; Witness: L1 53 (rzx-r2).
HeroWithinY:
  LD A,(HeroY)
  LD E,A
  LD D,(IY+$01)
  LD A,C
  JP AbsDiffAtMost

; A burst of the shape $EEB8 at column $14, row 7 (inks 4 and 5, the big mode):
; no code reaches it
;
; D = $14, E = 7, IX = BurstShapeMedusa $EEB8, B = 4, C = 5, A = 0, then JR
; StartBurst. No JP, CALL or JR in stage 2 leads here and no table holds its
; address; it lies between HeroWithinY's JP and BurstSpirit.
;
; Not executed in any recording (the recordings checked: s2-right, rzx-r2);
; known only from the code.
UnusedBurst:
  LD D,$14
  LD E,$07
  LD IX,BurstShapeMedusa
  LD B,$04
  LD C,$05
  LD A,$00
  JR StartBurst

; A spirit hit: a burst of BurstShape20 $EEE2 at its column - 6, row + 2 (inks
; 2 and 3, the big mode), the spirit freed
;
; IY = the spirit. D = its column - 6, E = its line / 8 + 2; StartBurst with IX
; = $EEE2, B = 2, C = 3, A = 0, then RemoveActor (a JP).
;
; Jumped to from SpiritFloat ($907A JP NZ) when the spirit is hit. Not executed
; in any recording (the recordings checked: s2-right, rzx-r2) (no spirit is hit
; in them); known only from the code.
BurstSpirit:
  LD A,(IY+$00)
  SUB $06
  LD D,A
  LD A,(IY+$01)
  SRL A
  SRL A
  SRL A
  ADD A,$02
  LD E,A
  LD IX,BurstShape20
  LD B,$02
  LD C,$03
  LD A,$00
  CALL StartBurst
  JP RemoveActor

; Each pass: once the last head is cut and its burst reaches step 4, burst the
; hydra's body and give room 7's bonus
;
; Nothing unless BurstTimer = 4 and HydraHeads = 0. Then HydraHeads = $64 (the
; hydra beaten). Room 7: StartBurst at column $0F, row 2 with
; BurstShapeHydraBody $EEFA (inks 4 and 5, the big mode), then SpawnBonus (a
; JP) with D = $12, E = $3C and the event bit B = $20. Room 3 (above the body):
; StartBurst at column $0D, row 7 with BurstShapeHydraTop $EEEE (a JP). Other
; rooms: nothing more.
;
; Called by MainLoop ($7864) every pass: 1951 calls in s2-right, 5805 in rzx-r2
; (the body burst and the bonus once, in room 7).
;
; Witness: L1 8031 (rzx-r2, s2-right, stageload).
HydraDefeated:
  LD A,(BurstTimer)
  CP $04
  RET NZ
  LD A,(HydraHeads)
  CP $00
  RET NZ
  LD A,$64
  LD (HydraHeads),A
  LD A,(RoomNumber)
  CP $03
  JR Z,HydraDefeatedRoom3
  CP $07
  RET NZ
  LD D,$0F
  LD E,$02
  LD IX,BurstShapeHydraBody
  LD B,$04
  LD C,$05
  LD A,$00
  CALL StartBurst
  LD D,$12
  LD E,$3C
  LD B,$20
  JP SpawnBonus
HydraDefeatedRoom3:
  LD D,$0D
  LD E,$07
  LD IX,BurstShapeHydraTop
  LD B,$04
  LD C,$05
  LD A,$00
  JP StartBurst

; Turn a 16 x 12 shape into particles at $7040 that fly apart (UpdateBurst)
;
; Input: A = BurstSmall (1 small: 14 steps; 0 big: 28), D, E = the shape's left
; column and top cell row, IX = the shape (12 rows of 2 bytes, bit 7 left), B
; and C = the two inks. PlaySoundVector 1, RandomPointer = $0D7A (every burst
; flies the same way), the colours C, C + $40 (bright), B, B + $40 into
; ParticleInks, BurstTimer = $FF. Each set bit of the shape gives a particle
; record of 4 bytes at $7040: X, Y (cell row), the direction (a random 0-5, +
; 13 for the right byte), the ink (a random 0-3); $FF ends the list. Preserves
; IY.
;
; As in stage 1 at $A1F3, the same code.
;
; Witness: L1 17 (rzx-r2).
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
; Called by the main loop ($7861) once a pass. Nothing while BurstTimer $FE3A =
; $64. Else BurstTimer + 1; at $1C the burst ends (StopBurst $9D90). Unlike
; stage 1 ($A28B) the end is $1C in both modes: there is no shorter end for the
; small mode; BurstSmall $FE3B only doubles the step index below.
;
; The step picks the particles' glyph: the byte at $EDC7 + the step + a random
; 0-3 (Random $8BAC) x 8 + $EDA7, written into ParticleGlyph (the LD DE,n at
; $9D46). Each particle (4 bytes from $7040: +0 the column, +1 the cell row, +2
; the direction, +3 the ink 0-3; $FF ends the list, $80 a dead one): its
; direction's row of 32 at $EDEA (directions 0-9 the second set of BurstSteps,
; $0A and up the first, less $0D) gives at the step (+ the ink's bits, doubled
; when BurstSmall) an index into BurstSteps (dx, dy): the column + dx is kept
; in 1-30, the row - dy dies ($80) at 18 and up. The 8 glyph bytes go into the
; play buffer at the cell ($5B00 + row x 256 + column, a line every 32 bytes)
; and ParticleInks[+3] into the cell's attribute (AttrShadowAddressA $B479).
;
; In rzx-r2 it draws 453 steps (the bursts of the statues, the urns and the
; hydra's heads); s2-right has no burst.
;
; As in stage 1 at $A296 (UpdateBurstStep), the same instructions; stage 1's
; head with the small-mode end is gone.
;
; Witness: L1 8031 (rzx-r2, s2-right, stageload).
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
  JR C,UpdateBurstDirection
  SUB $0D
  LD E,$00
UpdateBurstDirection:
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
  JR Z,UpdateBurstIndex
  SLA C
UpdateBurstIndex:
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

; An unreached RET byte after UpdateBurst's loop
;
; No code jumps to $9D8F (UpdateBurst's loop leaves by RET Z at $9CCB). As
; stage 1's $A392.
BurstLeftover:
  DEFB $C9

; BurstTimer = $64: no burst
;
; Jumped to by UpdateBurst at the burst's last step ($9C9B). In rzx-r2 16
; bursts end here.
;
; As in stage 1 at $A393, the same code.
;
; Witness: L1 16 (rzx-r2).
StopBurst:
  LD A,$64
  LD (BurstTimer),A
  RET

; The burst's four particle attributes, written by StartBurst
;
; Ink C, bright ink C, ink B, bright ink B (StartBurst $9BFA writes them); a
; particle's +3 (0-3) picks one (UpdateBurst $9D72). As loaded: 2, $42, $43, 3.
; As in stage 1 at $A399.
ParticleInks:
  DEFB $02,$42,$43,$03

; 20 (dx, dy) steps: 10 for the directions $0A and up (less $0D), 10 for the
; directions 0-9
;
; Read by UpdateBurst $9D06 (+ $14 for the second set): signed dx (columns) and
; dy (cell rows, subtracted). The pairs
;
; 0, 2, 4, 6, 8 of each set: (0,0) (0,1) (0,0) (0,-1) (1,0)... As in stage 1's
; BurstSteps $A39D. Read in rzx-r2:
;
; $9D9A-$9D9D, $9DA0-$9DA7, $9DAE-$9DB1, $9DB4-$9DBB; the pairs at $9D9E,
; $9DA8-$9DAD, $9DB2 and $9DBC-$9DC1 no
;
; recording read.
BurstSteps:
  INCBIN "res/stage2/table-burst-steps.bin",$0000,20
BurstStepsSecond:
  INCBIN "res/stage2/table-burst-steps.bin",$0014,20

  ORG $A396

; Put the hero at X $0E, Y $41 in grid 0 (the stage's start)
;
; IY = the hero's record $74E0, the hero's template $96C4 copied in at D = $0E,
; E = $41 (SpawnActor $A416), then the
;
; standing frame (HeroStandFrame $AED5). Called once by StageEntry ($781F).
; Stage 1 had one PlaceHero with D, E as
;
; input; stage 2 has five copies with the place built in: this one and
; PlaceHeroGrid1 to PlaceHeroBackGrid0.
;
; Witness: L1 3 (rzx-r2, s2-right, stageload).
PlaceHeroAtStart:
  LD IY,HeroRecord
  LD HL,ActorTemplates
  LD D,$0E
  LD E,$41
  CALL SpawnActor
  JP HeroStandFrame

; Put the hero at X 2, Y 9: the entry into grid 1 (room 0)
;
; As PlaceHeroAtStart $A396. Called by EnterGrid1 $8814 ($8827): 1 time in each
; recording (s2-right falls into grid
;
; 1 just before its game over).
;
; Witness: L1 2 (rzx-r2, s2-right).
PlaceHeroGrid1:
  LD IY,HeroRecord
  LD HL,ActorTemplates
  LD D,$02
  LD E,$09
  CALL SpawnActor
  JP HeroStandFrame

; Put the hero at X 2, Y $21: the entry into grid 2
;
; As PlaceHeroAtStart $A396. Called by EnterGrid2 $8835 ($8848): 2 times in
; rzx-r2.
;
; Witness: L1 2 (rzx-r2).
PlaceHeroGrid2:
  LD IY,HeroRecord
  LD HL,ActorTemplates
  LD D,$02
  LD E,$21
  CALL SpawnActor
  JP HeroStandFrame

; Put the hero at X $18, Y $29 facing left: back from grid 2 into grid 1
;
; As PlaceHeroAtStart $A396, then +9 bit 7 set (facing left). Called by $8859
; ($8870): 2 times in rzx-r2.
;
; Witness: L1 2 (rzx-r2).
PlaceHeroBackGrid1:
  LD IY,HeroRecord
  LD HL,ActorTemplates
  LD D,$18
  LD E,$29
  CALL SpawnActor
  SET 7,(IY+$09)
  JP HeroStandFrame

; Put the hero at X $1E, Y $31 facing left: back from grid 1 into grid 0 (room
; 5)
;
; As PlaceHeroBackGrid1 $A3C9. Called by $8882 ($889C): 1 time in rzx-r2.
;
; Witness: L1 1 (rzx-r2).
PlaceHeroBackGrid0:
  LD IY,HeroRecord
  LD HL,ActorTemplates
  LD D,$1E
  LD E,$31
  CALL SpawnActor
  SET 7,(IY+$09)
  JP HeroStandFrame

; Set bit 7 of the actor's placement (it does not come back)
;
; IY = the actor: the placement +$10 x 3 + Placements gets bit 7, so
; LoadRoomActors $A431 skips it from now on. Called by StrikeableActor $A9D7
; when an urn breaks (10 times in rzx-r2).
;
; As in stage 1 at $A48E, the same code.
;
; Witness: L1 10 (rzx-r2).
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
; Called once from StageEntry ($781C): every placed actor comes back.
;
; As in stage 1 at $A4A1, the same code.
;
; Witness: L1 3 (rzx-r2, s2-right, stageload).
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
; Input: HL = the template, IY = the record, D, E = X and Y (also the entry X,
; Y at +$0D, +$0E). Preserves IY and DE. Called by the hero's placings, the
; items (SpawnItem $9A6E), the fragments (InitFragment $AA6C), the harpy
; ($8DA4) and the actor spawners of the other range.
;
; As in stage 1 at $A4B1, the same code.
;
; Witness: L1 94 (rzx-r2, s2-right, stageload).
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
; Frees every record of $74F2-$75DB without +$0F bit 1. Then walks Placements
; (3 bytes: the kind, bit 7 done; X and Y in cells over the whole grid; $FF
; ends). A placement not done inside the room window (X in 2 x RoomColumn to +
; 29, Y in 2 x RoomRow to + 17) takes a free record found from $75CA down (no
; lower bound: it is assumed there is one) and is filled from ActorKinds $9607
; (9 bytes a kind: Y offset in lines, the handler, five bytes for +8..+$0C,
; +$0F): X and Y relative to the room (Y in lines + the offset), the entry X,
; Y, +$10 = the placement's index, width 1, height 8, +$11 = 0, and a random
; 0-63 (NextSeed $8B9D) for +$0A when the kind gives $40 (no stage-2 kind does:
; not executed in any recording).
;
; Called by RoomChange $9257 ($92E8) at each room change: 7 times in s2-right,
; 33 in rzx-r2. Stage 2 has 21 kinds (ActorKinds $9607-$96C3).
;
; As in stage 1 at $A4CC, the same instructions (its own table address).
;
; Witness: L1 43 (rzx-r2, s2-right, stageload).
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
; written into HandlerCall and called with IY = the record. Called twice a
; main-loop pass ($782B, $7855).
;
; As in stage 1 at $A5BD, the same code.
;
; Witness: L1 8034 (rzx-r2, s2-right, stageload).
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

  ORG $AC52

; Set the actor IY to frame A of a frame table (the 4 bytes after the CALL)
;
; The CALL is followed by two words: the frame table DE and the graphics base
; BC; the routine pops them and returns to its caller's caller. A frame record
; is 6 bytes (FrameRecordAddress $B278: DE + 6A): +0 the column offset (negated
; when the actor faces left, +9 bit 7), +1 the line offset, +2 the width in
; bytes, +3 the height in lines, +4/+5 the offset of the image from the
; graphics base. The actor's column +0 = the offset + its base column +$0D, its
; line +1 = the line offset + its base line +$0E, +2 and +3 the size, +4/+5 the
; image address. An image is width x height bytes, row by row, one bit a pixel,
; no mask.
;
; Every actor's frame goes through it: 6475 calls in s2-right, 14847 in rzx-r2.
;
; As in stage 1 at $AA02, the same code.
;
; Witness: L1 22570 (rzx-r2, s2-right, stageload).
SetActorFrame:
  POP IX
  LD E,(IX+$00)
  LD D,(IX+$01)
  LD C,(IX+$02)
  LD B,(IX+$03)
  PUSH BC
  CALL FrameRecordAddress
  POP BC
  LD A,(HL)
  CALL NegateIfFacingLeft
  ADD A,(IY+$0D)
  LD (IY+$00),A
  LD A,(IY+$0E)
  INC HL
  ADD A,(HL)
  LD (IY+$01),A
  INC HL
  LD A,(HL)
  LD (IY+$02),A
  INC HL
  LD A,(HL)
  LD (IY+$03),A
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  ADD HL,BC
  LD (IY+$04),L
  LD (IY+$05),H
  RET

  ORG $B256

; Move the actor IY's base column by E (the other way when it faces left)
;
; Called by ExtraLifeSparkle ($841F), HeroRecoil ($87D2), ExtraLifeActor
; ($9B0A), CheckHeroFooting ($ACD3), HeroStand ($AEBA), HeroStand ($AECE),
; HeroFireHeld ($AEFF), HeroFireHeld ($AF13) and 15 more; jumped to from
; StepFineBack ($8B85).
;
; As in stage 1 at $B112, the same code.
;
; Witness: L1 583 (rzx-r2, s2-right, stageload).
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
; Called by HarpyPlaceWings ($8ECF), SetActorFrame ($AC66), HeroWalk ($B07B).
;
; As in stage 1 at $B122, the same code.
;
; Witness: L1 23293 (rzx-r2, s2-right, stageload).
NegateIfFacingLeft:
  BIT 7,(IY+$09)
  RET Z
  NEG
  RET

; A = -A + 4 when the actor IY faces left, else A (no caller)
;
; BIT 7,(IY+9) / RET Z / NEG / ADD A,4 / RET. No CALL, JP or word in the image
; reaches $B26E (stage 1 has no such
;
; code). Not executed in any recording (the recordings checked: s2-right,
; rzx-r2); known only from the code.
NegatePlus4Unused:
  BIT 7,(IY+$09)
  RET Z
  NEG
  ADD A,$04
  RET

; HL = DE + 6A: frame A's record in the frame table DE
;
; Called by SetActorFrame ($AC61).
;
; As in stage 1 at $B12A, the same code.
;
; Witness: L1 22570 (rzx-r2, s2-right, stageload).
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

  ORG $B3BD

; Add a missile (shot, spark) to the first eight slots of the missile records
; $75E0
;
; In: D column, E line, C type, B and A its parameters. The list holds 16
; records of 6 bytes: +0 column ($FF free), +1 line, +2 type (the handler of
; MissileHandlers $B449), +3 $FF, +4 B, +5 A. The search starts after the slot
; of MissileCursor $FE27 (round robin over 8). A = $FA puts a Random $8BAC byte
; in +5. Out: Z when the eight slots are full (nothing added), else NZ.
; AddMissileHigh $B3C5 uses slots 8-15 ($7610).
;
; Called by $90E0, AimedShot, FireHeroMissile, HydraHeadShot and
; KindTwelveShot: 188 in s2-right, 282 in rzx-r2.
;
; As in stage 1 at $B28D (its JP is a JR here).
;
; Witness: L1 554 (rzx-r2, s2-right, stageload).
AddMissile:
  PUSH BC
  PUSH DE
  PUSH AF
  LD BC,Missiles
  JR AddMissileFrom
