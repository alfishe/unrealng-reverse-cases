; --------------------------------------------------------------------------------------------------------------------
; actors.asm: The actor records: placement, the per-pass update, the frames, the bursts
;
; The 14 actor records at $74E0 (the hero, then 13 others at $74F2), 18 bytes each: +0 X (column 0-29, $FF a free
; record), +1 Y (line in the 144-line play buffer; $C8 and up is above the top), +2 width in bytes, +3 height in
; lines, +4/+5 the frame's address, +6/+7 the handler, +8..+$0C the kind's five bytes (+9 bit 0 opaque, bit 7 facing
; left; +$0C the attribute), +$0D/+$0E X and Y where the actor entered the room, +$0F flags (bit 1 kept over a room
; change, bit 6 not drawn, bit 7 drawn in the second pass), +$10 the placement's index, +$11 the pixel shift (0 or 100
; and up: none).
; --------------------------------------------------------------------------------------------------------------------

  ORG $8B37

; Move the actor IY right by A eighths of a byte column (no caller)
;
; Adds A to the fraction +$11; past 8 takes 8 off and moves +0 and +$0D one
; column right. Nothing calls it (no
;
; CALL, JP or table word names $8B37): a leftover of the engine.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
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
; facing (StepX $B112 with E = -1). Called by $8736 and the warrior's flying
; head $9474.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
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
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
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

  ORG $8D1D

; Count down to the next random enemy
;
; Every pass: SpawnDelay - 1; at 0 reloads it with 30-61 (Random) and, in grid
; 0, goes to SpawnRandomEnemy $9353.
;
; Witness: L1 10189 (c1o, deaths, s1-idle, s1-right).
SpawnTimer:
  LD A,(SpawnDelay)
  DEC A
  JR Z,SpawnTimerFire
  LD (SpawnDelay),A
  RET
SpawnTimerFire:
  CALL Random
  AND $1F
  ADD A,$1E
  LD (SpawnDelay),A
  LD A,(GridNumber)
  CP $00
  JP Z,SpawnRandomEnemy
  RET

; IY = the first free actor record of 13 (Z), else NZ
;
; A record is free when its +0 is $FF. Returns NZ (via $B2E1) when none is
; free.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
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
; Witness: L1 238 (c1o, deaths, s1-idle, s1-right).
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

  ORG $9065

; Actor handler: a gate that rises while the hero holds the key item
;
; Template $9D00. When the selected item (GetSelectedItem) is of kind 2 the
; gate rises (+$0E - 1) to line $28, else
;
; it sinks (+1) to $48; GateOpen = 1 while it is above line $38. Frame 0 of
; GateFrames (sprite $D9CA, 2 x 24: bars).
;
; Witness: L1 82 (c1o, deaths).
GateActor:
  CALL GetSelectedItem
  CP $02
  JR NZ,GateSink
  LD A,(IY+$0E)
  CP $28
  JR NZ,GateRise
  JP GateState
GateRise:
  LD C,$FF
  CALL MoveActorY
  JP GateState
GateSink:
  LD A,(IY+$0E)
  CP $48
  JP Z,GateState
  LD C,$01
  CALL MoveActorY
GateState:
  XOR A
  LD (GateOpen),A
  LD A,(IY+$0E)
  CP $38
  JR NC,GateFrame
  LD A,$01
  LD (GateOpen),A
GateFrame:
  XOR A
  CALL SetActorFrame

; SetFrame's data: the frame records $D9FA, the sprite bytes $D9CA
GateFrames:
  DEFB $FA,$D9,$CA,$D9

; Actor handler: a slab that sinks into place and becomes floor
;
; Templates $9D1B and $9D29. Sprite $C2B1 (4 bytes x 8). Waits while BossPhase
; is under 3, then sinks one line a
;
; pass to line $70 and there writes cell kind 7 into its 4 cells of the room's
; cells ($7280 + line / 8 x 32 + its
;
; column): the hero can stand on it.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
BridgeSlabActor:
  LD (IY+$02),$04
  LD (IY+$03),$08
  LD HL,BridgeSlabSprite
  LD (IY+$04),L
  LD (IY+$05),H
  LD A,(BossPhase)
  CP $03
  JP C,RemoveActor
  LD A,(IY+$01)
  CP $70
  JR Z,BridgeSlabLand
  DEC (IY+$01)
  RET
BridgeSlabLand:
  LD A,(IY+$01)
  AND $F8
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD C,(IY+$00)
  LD B,$00
  ADD HL,BC
  LD BC,Cells
  ADD HL,BC
  LD (HL),$07
  INC L
  LD (HL),$07
  INC L
  LD (HL),$07
  INC L
  LD (HL),$07
  RET

  ORG $921E

; Clear the shots and free all 13 actor records ($74F2, 234 bytes of $FF)
;
; Witness: L1 4 (s1-idle, s1-right).
ClearActors:
  CALL ClearShots
  LD HL,Actors
  LD DE,Actors+$0001
  LD BC,$00E9
  LD (HL),$FF
  LDIR
  RET

  ORG $924B

; Fill the shot slots $75E0-$763F (96 bytes) with $FF
;
; Witness: L1 30 (c1o, deaths, s1-idle, s1-right).
ClearShots:
  LD HL,Missiles
  LD DE,Missiles+$0001
  LD BC,$0060
  LD (HL),$FF
  LDIR
  RET

  ORG $92C9

; +$0E (the base line) + C
;
; Witness: L1 86 (c1o, deaths, s1-right).
MoveActorY:
  LD A,(IY+$0E)
  ADD A,C
  LD (IY+$0E),A
  RET

  ORG $9C8A

; The 17 placement kinds, 9 bytes each: the Y offset, the handler, 5 bytes for
; the record's +8 to +$0C, the record's +$0F
;
; LoadRoomActors $A4CC builds an actor from a placement with its kind's row: +1
; Y = the placement's Y x 8 + the offset, +6/+7 the handler, +8 to +$0C (the
; counter, the flags, the state, the item, the attribute), +$0F (bit 0: kept
; over a room change). Stage 1's kinds: 0 and 1 a hanging body (HangingActor
; $9186; 1 faces the other way), 2 a flame jet (FlameJetActor $8DCC), 3-6 urns
; and chests that break when struck (StrikeableActor $A7C4; +$0B the item
; inside), 7 a fire pit (FirePitActor $8D6D), 8-11 the winged demon's left
; wing, right wing, body and head (BossWingLeft $8E60 to BossHead $8E86), 12
; and 14 a statue head (StatueActor $912B), 13 the gate (GateActor $9065), 15
; the dragon's head (ArenaHeadActor $90E7), 16 the bridge slab (BridgeSlabActor
; $90A3). Read in all four stage-1 builds (81 of its bytes: the kinds of the
; rooms the recordings visit).
ActorKinds:
  INCBIN "res/stage1/table-kinds.bin",$0000,153

; Seven whole actor records (18 bytes each, the first the bridge slab's) that
; SpawnActor $A4B1 copies for the actors no placement makes
;
; The handler at +6/+7 and the frame at +4/+5 as for a placed actor; the rest
; as an actor record (HeroRecord $74E0). Read in all four stage-1 builds.
ActorTemplates:
  INCBIN "res/stage1/table-actor-templates.bin",$0000,18
HeroTemplate:
  INCBIN "res/stage1/table-actor-templates.bin",$0012,18
ItemTemplate:
  INCBIN "res/stage1/table-actor-templates.bin",$0024,18
PieceTemplate:
  INCBIN "res/stage1/table-actor-templates.bin",$0036,18
FragmentTemplate:
  INCBIN "res/stage1/table-actor-templates.bin",$0048,18
WarriorTemplate:
  INCBIN "res/stage1/table-actor-templates.bin",$005A,18
WarriorHeadTemplate:
  INCBIN "res/stage1/table-actor-templates.bin",$006C,18

; Clear and set the stage variables at the start of the stage
;
; Clears $FE08-$FE5F (88 bytes), copies the 12 starting carried-object kinds
; from $7F2F to the carried kinds at $7F17, seeds RandomPointer from R and
; draws SpawnDelay (a random 0-15), then sets the stage's start values:
; BurstTimer $64 (no burst), RandomPointer and RandomSeed $07CF, EnergyChange
; $2E (energy refilled to full), ItemLast 6, and InitOnly10, InitOnly12,
; ItemSelected, ItemFirst, InitOnly3A, InitOnly40, InitOnly41, BossPhase,
; RespawnShiftX, ArenaBossHits.
;
; Called once from StageEntry $7800. Output: none. Side effects: the
; $FE08-$FE5F stage variables.
;
; Witness: L1 2 (s1-idle, s1-right).
InitStageState:
  LD HL,RandomSeed
  LD DE,RandomSeed+1
  LD BC,$0057
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
  AND $0F
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
  LD A,$06
  LD (ItemLast),A
  LD A,$64
  LD (BurstTimer),A
  LD HL,$07CF
  LD (RandomSeed),HL
  LD (RandomPointer),HL
  LD A,$2E
  LD (EnergyChange),A
  LD A,$FF
  LD (RespawnShiftX),A
  LD A,$0A
  LD (BossHits),A
  LD A,$01
  LD (BossPhase),A
  RET

  ORG $A065

; Score 20, then burst the actor (shape $EF69) into particles and free it
;
; IY = the actor. AddScore $7B53 with 20, then StartBurst at X - 7, Y / 8 with
; the shape $EF69 in the small mode, colours 6 and 4 (3 and 2 when +8 = 8).
; StartBurst returns into the caller, which frees the actor.
;
; Reached from the handler $A7C4's jump table ($A7E2).
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
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

; Put an item actor (template $9D47) into a free record
;
; Input: D, E = X and Y, BC = the item's frame, L = the item kind (+$0B), H =
; the amount (+$0A). FindFreeActor $8D3A; with a free record: SpawnActor with
; the template $9D47 (16 x 16 lines, handler ItemHandler), then the frame, kind
; and amount. Preserves IY.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
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

; Free the actor and drop item kind 8 (amount 36) where it entered the room
;
; IY = the actor. D = its X, E = its entry Y; FreeActor $B35E, then SpawnItem
; with the frame $EB6C, kind 8, amount $24. Reached from $A7C4's jump table
; ($A7EF).
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
DropItemKind8:
  LD D,(IY+$00)
  LD E,(IY+$0E)
  LD L,$08
  LD H,$24
  LD BC,ItemIconKind8
  CALL RemoveActor
  JP SpawnItem

; Free the actor and drop item kind 1 (amount 20) where it entered the room
;
; As DropItemKind8 with the frame $EB8C, kind 1, amount $14. Reached from
; $A7C4's jump table ($A7F4).
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
DropItemKind1:
  LD D,(IY+$00)
  LD E,(IY+$0E)
  LD L,$01
  LD H,$14
  LD BC,ItemIconKind1
  CALL RemoveActor
  JP SpawnItem

; An item actor: picked up when the hero stands on it
;
; The handler of the template $9D47 (+6). $B3BD each pass; when the hero is
; within 20 lines (HeroWithinY) and in the item's column or the one after,
; AddScore 400, PiecesComplete + 1 for kind 6, AddCarried $7E5F with A = the
; kind (+$0B) and D = the amount (+$0A), PlaySoundVector 4, and FreeActor.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
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
  CP $06
  JR NZ,ItemHandlerAdd
  LD HL,PiecesComplete
  INC (HL)
ItemHandlerAdd:
  LD D,(IY+$0A)
  CALL AddItem
  LD DE,$0004
  CALL PlaySoundVector
  JP RemoveActor

; Carry set when the hero's Y is within C lines of the actor's
;
; Input: IY = the actor, C = the distance. E = the hero's Y ($74E1), D = the
; actor's Y, then WithinDistance $A7B8: carry when |E - D| < C.
;
; Witness: L1 251 (c1o, deaths, s1-idle, s1-right).
HeroWithinY:
  LD A,(HeroY)
  LD E,A
  LD D,(IY+$01)
  LD A,C
  JP AbsDiffBelow

; Burst the actor's shape $EF69 (small mode, colours 2 and 3), then free it
;
; IY = the actor: StartBurst at X - 6, Y / 8 + 2 with the shape $EF69, then
; FreeActor. No code or table in the image refers to $A129.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
BurstAtActor:
  LD A,(IY+$00)
  SUB $06
  LD D,A
  LD A,(IY+$01)
  SRL A
  SRL A
  SRL A
  ADD A,$02
  LD E,A
  LD IX,BurstShapes
  LD B,$02
  LD C,$03
  XOR A
  CALL StartBurst
  JP RemoveActor

; Free the hit actor and count a hit on the boss; on the 20th, drop item kind 2
; and burst the boss
;
; Reached by a jump from $859F. FreeActor, ArenaFlash = 1; ArenaBossHits + 1 up
; to 20. On the 20th hit: SpawnItem at $14, $70 (frame $EAEC, kind 2, amount
; 0), ArenaBossBeaten = 1, and StartBurst at $0E, 4 with the shape $EFC9
; (colours 4 and 6, big mode).
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
ArenaBossHit:
  CALL RemoveActor
  LD A,$01
  LD (ArenaFlash),A
  LD A,(ArenaBossHits)
  CP $14
  RET Z
  INC A
  LD (ArenaBossHits),A
  CP $14
  RET NZ
  LD D,$14
  LD E,$70
  LD L,$02
  LD H,$00
  LD BC,ItemIconSprites
  CALL SpawnItem
  LD A,$01
  LD (ArenaBossBeaten),A
  LD D,$0E
  LD E,$04
  LD IX,BurstShapeBossHit
  LD B,$04
  LD C,$06
  XOR A
  JP StartBurst

; Mark the actor gone (+$0F = $14), BossPhase = 3, burst the shape $EF99 at 8,
; 4
;
; Reached by a jump from $8EAD. Big mode, colours 4 and 5.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
BossFlees:
  LD (IY+$0F),$14
  LD A,$03
  LD (BossPhase),A
  LD D,$08
  LD E,$04
  LD IX,BurstShapeBoss
  LD B,$05
  LD C,$04
  XOR A
  JP StartBurst

; Score 64, burst the actor (shape $EFB1), mark its placement done and free it
;
; IY = the actor. AddScore 64, StartBurst at X - 7 (X - 5 facing right), Y / 8
; + 1 with the shape $EFB1 (small mode, colours 1 and 3), MarkPlacementDone,
; FreeActor. Reached from $9141 (the handler $912B).
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
ScoreBurst64:
  LD BC,$0040
  CALL AddScore
  LD E,$07
  BIT 7,(IY+$09)
  JR NZ,ScoreBurst64Left
  LD E,$05
ScoreBurst64Left:
  LD A,(IY+$00)
  SUB E
  LD D,A
  LD A,(IY+$01)
  SRL A
  SRL A
  SRL A
  ADD A,$01
  LD E,A
  LD IX,BurstShapeStatue
  LD B,$03
  LD C,$01
  LD A,$01
  CALL StartBurst
  CALL MarkPlacementDone
  JP RemoveActor

; Score 160 and burst the actor (shape $EF85, big mode)
;
; IY = the actor. AddScore 160, StartBurst at X - 7, Y / 8 + 2 with the shape
; $EF85, colours 7 and 6, big mode. Reached from $9195 (the handler $9186).
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
ScoreBurst160:
  LD BC,$00A0
  CALL AddScore
  LD A,(IY+$00)
  SUB $07
  LD D,A
  LD A,(IY+$01)
  SRL A
  SRL A
  SRL A
  ADD A,$02
  LD E,A
  LD IX,BurstShapeHanging
  LD B,$06
  LD C,$07
  XOR A
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
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
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
; Called by the main loop. Nothing while BurstTimer = $64. Else BurstTimer + 1;
; at the last step ($1C, or $0E when BurstSmall) it ends (StopBurst). The step
; picks the particles' glyph: $EE86[step + a random 0-3] x 8 + $EE66, written
; into ParticleGlyph. Each particle (4 bytes from $7040, $FF ends, $80 dead):
; its direction's step table at $EEA9 + direction x 32 gives an index into
; BurstSteps (dx, dy; the second set for directions 13 and up), X + dx kept
; within 1-30, Y - dy (a particle above row 0 or below row 17 dies: $80); then
; the 8 glyph bytes are stored into the play buffer at the cell and the cell's
; attribute (ParticleInks) via $B34E.
;
; Witness: L1 10188 (c1o, deaths, s1-idle, s1-right).
UpdateBurst:
  LD E,$1C
  LD A,(BurstSmall)
  CP $00
  JR Z,UpdateBurstStep
  LD E,$0E
UpdateBurstStep:
  LD A,(BurstTimer)
  CP $64
  RET Z
  INC A
  CP E
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
; No code jumps here (the loop above ends with JP UpdateBurstLoop).
BurstLeftover:
  DEFB $C9

; BurstTimer = $64: no burst
;
; Witness: L1 0 ().
StopBurst:
  LD A,$64
  LD (BurstTimer),A
  RET

; The burst's four particle attributes, written by StartBurst
;
; ink C, bright ink C, ink B, bright ink B; the particle's byte 3 (0-3) picks
; one. As loaded: 2, $42, $43, 3.
ParticleInks:
  DEFB $02,$42,$43,$03

; 20 (dx, dy) steps: 10 for the left-byte particles, 10 for the right-byte ones
BurstSteps:
  INCBIN "res/stage1/table-burst-steps.bin",$0000,40

  ORG $A47D

; Put the hero at X $0E, Y $31 (PlaceHero)
;
; Witness: L1 2 (s1-idle, s1-right).
PlaceHeroAtStart:
  LD D,$0E
  LD E,$31

; Put the hero's template $9D35 into the hero's record $74E0 at D, E, then
; $ADDD
;
; Input: D, E = X and Y. Called from PlaceHeroAtStart and $AB1C (a grid
; change).
;
; Witness: L1 2 (s1-idle, s1-right).
PlaceHero:
  LD IY,HeroRecord
  LD HL,HeroTemplate
  CALL SpawnActor
  JP HeroStandFrame

; Set bit 7 of the actor's placement (it does not come back)
;
; IY = the actor: the placement +$10 x 3 + Placements gets bit 7, so
; LoadRoomActors skips it from now on.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
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
; Called once from StageEntry: every placed actor comes back.
;
; Witness: L1 2 (s1-idle, s1-right).
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
; Y at +$0D, +$0E). Preserves IY and DE.
;
; Witness: L1 18 (c1o, deaths, s1-idle, s1-right).
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
; lower bound: it is assumed there is one) and is filled from the kind table
; $9C8A (9 bytes a kind: Y offset in lines, the handler, five bytes for
; +8..+$0C, +$0F): X and Y relative to the room (Y in lines + the offset), the
; entry X, Y, +$10 = the placement's index, width 1, height 8, +$11 = 0, and a
; random 0-63 for +$0A when the kind gives $40.
;
; Called by the room builder at each room change.
;
; Witness: L1 26 (c1o, deaths, s1-idle, s1-right).
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
  XOR A
  LD (WorkByte),A
LoadRoomActorsSlot:
  LD A,(IY+$00)
  CP $FF
  JR Z,LoadRoomActorsPlacement
  LD BC,-18
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
  LD BC,-18
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
; written into HandlerCall and called with IY = the record.
;
; Witness: L1 10190 (c1o, deaths, s1-idle, s1-right).
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

  ORG $AA02

; Set the actor IY to frame A of a frame table (the 4 bytes after the CALL)
;
; The CALL is followed by two words: the frame table DE and the graphics base
; BC; the routine pops them and
;
; returns to its caller's caller. A frame record is 6 bytes (FrameRecordAddress
; $B12A: DE + 6A): +0 the column
;
; offset (negated when the actor faces left, +9 bit 7), +1 the line offset, +2
; the width in bytes, +3 the height in
;
; lines, +4/+5 the offset of the image from the graphics base. The actor's
; column +0 = the offset + its base column
;
; +$0D, its line +1 = the line offset + its base line +$0E, +2 and +3 the size,
; +4/+5 the image address. An image is
;
; width x height bytes, row by row, one bit a pixel, no mask (DrawSprite $B42B
; copies it).
;
; Witness: L1 28567 (c1o, deaths, s1-idle, s1-right).
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

  ORG $B112

; Move the actor IY's base column by E (the other way when it faces left)
;
; Witness: L1 182 (c1o, deaths, s1-right).
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
; Witness: L1 28591 (c1o, deaths, s1-idle, s1-right).
NegateIfFacingLeft:
  BIT 7,(IY+$09)
  RET Z
  NEG
  RET

; HL = DE + 6A: frame A's record in the frame table DE
;
; Witness: L1 28567 (c1o, deaths, s1-idle, s1-right).
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

  ORG $B28D

; Add a missile (shot, spark) to the first eight slots of the missile records
; $75E0
;
; In: D column, E line, C type, B and A its parameters. The list holds 16
; records of 6 bytes: +0 column ($FF free),
;
; +1 line, +2 type (the handler of MissileHandlers $B31A), +3 $FF, +4 B, +5 A.
; The search starts after the slot of
;
; MissileCursor $FE27 (round robin over 8). A = $FA puts a Random $8B85 byte in
; +5. Out: Z when the eight slots are
;
; full (nothing added), else NZ. AddMissileHigh $B296 uses slots 8-15 ($7610).
;
; Witness: L1 29 (s1-right).
AddMissile:
  PUSH BC
  PUSH DE
  PUSH AF
  LD BC,Missiles
  JP AddMissileFrom

; Add a missile to the slots 8-15 ($7610) of the missile records
;
; Witness: L1 56 (c1o, deaths, s1-right).
AddMissileHigh:
  PUSH BC
  PUSH DE
  PUSH AF
  LD BC,MissilesHigh

; Add a missile to the eight slots from BC
;
; Witness: L1 85 (c1o, deaths, s1-right).
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

  ORG $B2E6

; Run the handler of every missile in use (once a main-loop pass)
;
; The 16 records of the missile records $75E0 (6 bytes each, IY): a record
; whose +0 is not $FF calls the handler
;
; MissileHandlers[+2] through the CALL at MissileCall $B30C, whose operand it
; writes. IX is kept.
;
; Witness: L1 10188 (c1o, deaths, s1-idle, s1-right).
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
  CALL $0000              ; CALL nn: nn = the effect's handler, written by
                          ; UpdateMissiles
  POP BC
  LD DE,$0006
UpdateMissilesNext:
  ADD IY,DE
  DJNZ UpdateMissilesLoop
  POP IX
  RET

; The handler of each missile kind 0-11
;
; 0 $876C, 1 $80DF, 2 and 3 $8006 (the thrown items, left and right), 4 $83A9,
; 5 $8403 (the boss's shots), 6 $8564
;
; (the bolt), 7 and 8 $842C (the death burst), 9 $8171, $0A and $0B $85C8.
MissileHandlers:
  DEFW HangFlashBorder
  DEFW UpdateAimedShot
  DEFW UpdateThrownArc
  DEFW UpdateThrownArc
  DEFW UpdateDriftRight
  DEFW UpdateDriftLeft
  DEFW UpdateFlatShot
  DEFW UpdatePathFlyer
  DEFW UpdatePathFlyer
  DEFW UpdateHeroShot
  DEFW UpdateBouncer
  DEFW UpdateBouncer

  ORG $B35E

; Free the actor record IY (+0 = $FF)
;
; Witness: L1 76 (c1o, s1-right).
RemoveActor:
  LD (IY+$00),$FF
  RET

; Free the actor record IY and the next one (+0 and +$12 = $FF)
;
; Jumped to from $95F7 and $95FC.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
RemoveActorPair:
  LD (IY+$00),$FF
  LD (IY+$12),$FF
  RET
