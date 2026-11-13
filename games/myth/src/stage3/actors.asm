; --------------------------------------------------------------------------------------------------------------------
; actors.asm: The actors: the records, their handlers, the spawns, the drawing order
; --------------------------------------------------------------------------------------------------------------------

  ORG $89D8

; Move the actor IY right by A eighths of a byte column (no caller)
;
; Adds A to the fraction +$11; past 8 takes 8 off and moves +0 and +$0D one
; column right. Nothing calls it (no
;
; CALL, JP or table word names $89D8): a leftover of the engine.
;
; Stage 1's StepFineRight at $8B37 is the same code.
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
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
; facing (StepX $B1A6 with E = -1). Called by HeroRecoil ($85F3) and
; TrollBodyActor ($90D7).
;
; Stage 1's StepFineBack at $8B4E is the same code.
;
; Witness: L1 70 (rzx-r3).
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
; Stage 1's StepFineLeft at $8B61 is the same code.
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
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

  ORG $8BC4

; Count SpawnDelay down; at 0 a random 40-103 again and SpawnViking (grid 1:
; SwampSpawnTimer)
;
; Called every pass by MainLoop. Grid 1 goes to SwampSpawnTimer. Else
; SpawnDelay - 1; at 0 SpawnDelay = $28 + Random & $3F and on to SpawnViking
; (which acts only in grid 0).
;
; Stage 1's SpawnTimer ($8D1D) has the same job for its warriors (not the same
; code: names.err).
;
; Witness: L1 6279 (rzx-r3, s3-right).
SpawnTimer:
  LD A,(GridNumber)
  CP $01
  JP Z,SwampSpawnTimer
  LD A,(SpawnDelay)
  DEC A
  JR Z,SpawnTimerReset
  LD (SpawnDelay),A
  RET
SpawnTimerReset:
  CALL Random
  AND $3F
  ADD A,$28
  LD (SpawnDelay),A
  JP SpawnViking

; IY = the first free actor record of 13 (Z), else NZ
;
; A record is free when its +0 is $FF. Returns NZ (via $B37F) when none is
; free.
;
; Stage 1's FindFreeActor at $8D3A is the same code.
;
; Witness: L1 96 (rzx-r3, s3-right).
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
; Stage 1's FindFreeActorPair at $8D50 is the same code.
;
; Witness: L1 21 (rzx-r3, s3-right).
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

  ORG $959F

; Clear the shots and free all 13 actor records ($74F2, 234 bytes of $FF)
;
; Stage 1's ClearActors at $921E is the same code.
;
; Witness: L1 7 (rzx-r3, s3-right).
ClearActors:
  CALL ClearShots
  LD HL,Actors
  LD DE,ActorsY
  LD BC,$00E9
  LD (HL),$FF
  LDIR
  RET

  ORG $95CC

; Fill the shot slots $75E0-$763F (96 bytes) with $FF
;
; Stage 1's ClearShots at $924B is the same code.
;
; Witness: L1 46 (rzx-r3, s3-right).
ClearShots:
  LD HL,Missiles
  LD DE,MissilesY
  LD BC,$0060
  LD (HL),$FF
  LDIR
  RET

  ORG $963E

; +$0E (the base line) + C
;
; Stage 1's MoveActorY at $92C9 is the same code.
;
; Witness: L1 13 (rzx-r3, s3-right).
MoveActorY:
  LD A,(IY+$0E)
  ADD A,C
  LD (IY+$0E),A
  RET

  ORG $9BFB

; The 13 placement kinds, 9 bytes each: the Y offset, the handler, 5 bytes for
; the record's +8 to +$0C, the record's +$0F
;
; LoadRoomActors $A6CA builds an actor from a placement with its kind's row, as
; in stage 1: +1 Y = the placement's Y x 8 + the offset, +6/+7 the handler, +8
; to +$0C (the counter, the flags, the state, the item, the attribute), +$0F.
; Stage 3's kinds: 0-3 the urns and chests (StrikeableActor $A9C2, frames 6, 4,
; 2, 0 of StrikeableSprites, the item 1 / 1 / 1 / 1 inside), 4 the water
; ($928E: WaterRipple frames), 5 the dragon's head (DragonHeadActor $92BF), 6
; its flame (DragonFlameActor $9329), 7 the drawbridge (DrawbridgeActor $9369),
; 8 and 9 the pyre's flames (PyreFlameActor $93C8, the Y offset 0 and 3), $0A
; the pyre's bier (PyreBierActor $9420), $0B the body on it (PyreBodyActor
; $945E), $0C the lightning (LightningActor $94AC). Read in rzx-r3 (all 117
; bytes) and s3-right (18: kinds 4 and $0C).
ActorKinds:
  INCBIN "res/stage3/table-kinds.bin",$0000,117

; Eight whole actor records (18 bytes each, the first the hero's: handler
; HeroActor $AC46) that SpawnActor copies for the actors no placement makes
;
; The handler at +6/+7 and the frame at +4/+5 as for a placed actor; the rest
; as an actor record (HeroRecord $74E0). The frame word of all but the item is
; BlankIcon $8A44 until SetActorFrame sets a frame. Read in rzx-r3 (all eight)
; and s3-right (the hero and the piece).
ActorTemplates:
  INCBIN "res/stage3/table-actor-templates.bin",$0000,18
ItemTemplate:
  INCBIN "res/stage3/table-actor-templates.bin",$0012,18
PieceTemplate:
  INCBIN "res/stage3/table-actor-templates.bin",$0024,18
FragmentTemplate:
  INCBIN "res/stage3/table-actor-templates.bin",$0036,18
BogManTemplate:
  INCBIN "res/stage3/table-actor-templates.bin",$0048,18
BogManLeftTemplate:
  INCBIN "res/stage3/table-actor-templates.bin",$005A,18
TrollLegsTemplate:
  INCBIN "res/stage3/table-actor-templates.bin",$006C,18
TrollBodyTemplate:
  INCBIN "res/stage3/table-actor-templates.bin",$007E,18

; Clear and set the stage variables at the start of the stage
;
; Clears `$FE08`-`$FE69` (98 bytes), copies the 17 starting carried bytes from
; `$7F1E` to CarriedItems `$7EFC`, seeds RandomPointer from R and draws
; SpawnDelay (a random 0-15), then sets the stage's start values: InitOnly42 1,
; InitOnly41 `$0D`, InitOnly10 2, InitOnly12 1, InitOnly3A `$10`, ItemFirst,
; ItemSelected and ItemLast 6, BurstTimer `$64` (no burst), RandomSeed and
; RandomPointer `$07CF`, EnergyChange `$2E` (energy refilled to full),
; RespawnShiftX `$FF` (no death pending), InitOnly64 `$0A`.
;
; Called once from StageEntry (at `$7804`). Output: none. Side effects: the
; `$FE08`-`$FE69` stage variables (rain, pyre and the bosses' counters all 0).
;
; Witness: L1 2 (rzx-r3, s3-right).
InitStageState:
  LD HL,RandomSeed
  LD DE,RandomSeed+1
  LD BC,$0061
  LD (HL),$00
  LDIR
  LD HL,StartItems
  LD DE,CarriedItems
  LD BC,$0011
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
  LD (InitOnly42),A
  LD A,$0D
  LD (InitOnly41),A
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
  LD (InitOnly64),A
  RET

  ORG $9FD5

; Score 200, burst the two-record enemy (shape `$EFCA`), free both and drop
; item kind 5 (amount 12)
;
; IY = the enemy's first record. AddScore `$7B41` with 200, StartBurst `$A169`
; at X - 7, Y / 8 - 8 with the shape `$EFCA`, colours 3 and 1, the big mode;
; RemoveActorPair `$B3FD`; then SpawnItem `$A081` at the enemy's column, line
; `$68`, with the frame `$EAA0`, kind 5, amount `$0C`. Reached from
; TrollLegsActor (`$9068`, when the troll's hit counter +$0B reaches 0).
;
; Witness: L1 3 (rzx-r3).
ScoreBurst200:
  PUSH IY
  LD BC,$00C8
  CALL AddScore
  LD A,(IY+$00)
  SUB $07
  LD D,A
  LD A,(IY+$01)
  SRL A
  SRL A
  SRL A
  ADD A,$F8
  LD E,A
  LD IX,BurstShape2
  LD B,$03
  LD C,$01
  XOR A
  CALL StartBurst
  POP IY
  LD H,$0C
  LD L,$05
  LD D,(IY+$00)
  CALL RemoveActorPair
  LD E,$68
  LD BC,ItemIconKind5
  JP SpawnItem

; The dragon's last hit: `$FE4D` = `$10`, score 2500 and a big burst at column
; `$10`, row 5
;
; AddScore `$7B41` with `$09C4` (2500), then StartBurst `$A169` (jumped to)
; with the shape `$EFE2`, colours 6 and 4, the big mode. Reached from
; DrawDragon (`$888B`) when its hit count `$FE4D` is `$0F`; `$10` marks the
; dragon beaten.
;
; Witness: L1 1 (rzx-r3).
DragonBeaten:
  LD A,$10
  LD (DragonHits),A
  LD BC,$09C4
  CALL AddScore
  LD D,$10
  LD E,$05
  LD IX,BurstShapeBoss
  LD B,$06
  LD C,$04
  XOR A
  JP StartBurst

; The throne giant's 30th hit: score 2000, a big burst, and the piece of bit
; `$40`
;
; ThroneBossHits `$FE65` = `$1F` (ThroneBossStep `$9514` does nothing more),
; AddScore `$7B41` with `$07D0` (2000), StartBurst `$A169` at column `$14`, row
; 5 with the shape `$EFE2`, colours 6 and 7, the big mode, then SpawnBonus
; `$9F93` (jumped to) at D = `$19`, E = `$4C` with the event bit `$40`. Reached
; from ThroneBossStep `$951F`.
;
; Witness: L1 1 (rzx-r3).
ThroneBossBeaten:
  LD A,$1F
  LD (ThroneBossHits),A
  LD BC,$07D0
  CALL AddScore
  LD D,$14
  LD E,$05
  LD IX,BurstShapeBoss
  LD B,$06
  LD C,$07
  XOR A
  CALL StartBurst
  LD D,$19
  LD E,$4C
  LD B,$40
  JP SpawnBonus

; Score 20, then burst the actor (shape $EF69) into particles and free it
;
; IY = the actor. AddScore $7B41 with 20, then StartBurst at X - 7, Y / 8 with
; the shape $EFBC in the small mode, colours 6 and 4 (3 and 2 when +8 = 8).
; StartBurst returns into the caller, which frees the actor.
;
; Called by StrikeableActor ($A9DF) when an urn or chest breaks.
;
; Stage 1's ScoreBurst20 at $A065 is the same code.
;
; Witness: L1 9 (rzx-r3).
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
; the amount (+$0A). FindFreeActor $8BE3; with a free record: SpawnActor with
; the template $9C82 (16 x 16 lines, handler ItemHandler), then the frame, kind
; and amount. Preserves IY.
;
; Stage 1's SpawnItem at $A098 is the same code.
;
; Witness: L1 13 (rzx-r3).
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

; Free the actor and drop item kind 9 in room 3, else item kind 8
; (DropItemKind8)
;
; IY = the actor. RoomNumber 3: D = its X, E = its entry Y; RemoveActor
; `$B3F8`, SpawnItem `$A081` with the frame `$EA40`, kind 9, amount 1. Other
; rooms: on into DropItemKind8. Reached from StrikeableActor `$A9C2` (+$10 AND
; 3 = 1 or 3).
;
; Kind 9 is the item that starts the rain in room 5 (UpdateRain `$A41E`).
;
; Witness: L1 4 (rzx-r3).
DropItemKind9Or8:
  LD A,(RoomNumber)
  CP $03
  JP Z,DropItemKind9

; Free the actor and drop item kind 8 (amount 36) where it entered the room
;
; IY = the actor. D = its X, E = its entry Y; FreeActor $B3F8, then SpawnItem
; with the frame $EAE0, kind 8, amount $24. Reached by running on from
; DropItemKind9Or8 ($A0AC) outside room 3.
;
; Stage 1's DropItemKind8 at $A0C3 is the same code.
;
; Witness: L1 3 (rzx-r3).
DropItemKind8:
  LD D,(IY+$00)
  LD E,(IY+$0E)
  LD L,$08
  LD H,$24
  LD BC,ItemIconKind8
  CALL RemoveActor
  JP SpawnItem
; This entry point is used by the routine at DropItemKind9Or8.
DropItemKind9:
  LD D,(IY+$00)
  LD E,(IY+$0E)
  LD L,$09
  LD H,$01
  LD BC,ItemIconKind9
  CALL RemoveActor
  JP SpawnItem

; Free the actor and drop item kind 7 in room 0, else item kind 1 (amount 10)
;
; IY = the actor. RoomNumber 0: RemoveActor `$B3F8`, SpawnItem `$A081` at its
; X, entry Y with the frame `$EA80`, kind 7, amount 1. Other rooms: the frame
; `$EB00`, kind 1, amount `$0A`. Reached from StrikeableActor `$A9C2` (+$10 AND
; 3 = 2).
;
; Kind 7 is the hero's thrown weapon of FireBolt `$969A`.
;
; Witness: L1 3 (rzx-r3).
DropItemKind7Or1:
  LD A,(RoomNumber)
  CP $00
  JP Z,DropItemKind7
  LD D,(IY+$00)
  LD E,(IY+$0E)
  LD L,$01
  LD H,$0A
  LD BC,ItemIconKind1
  CALL RemoveActor
  JP SpawnItem
DropItemKind7:
  LD D,(IY+$00)
  LD E,(IY+$0E)
  LD L,$07
  LD H,$01
  LD BC,ItemIconKind7
  CALL RemoveActor
  JP SpawnItem

; An item actor: picked up when the hero stands on it
;
; The handler of the item template `$9C82` (word at `$9C88`). SetCycleColour
; `$B49C` each pass; when the hero is within 20 lines (HeroWithinY `$A13D`) and
; his column `$74E0` is the item's or the one before it: AddScore `$7B41` 400,
; PiecesComplete + 1 for kind 6, AddItem `$7E4D` with A = the kind (+$0B) and D
; = the amount (+$0A), PlaySoundVector 4, and RemoveActor `$B3F8`.
;
; Witness: L1 355 (rzx-r3).
ItemHandler:
  CALL SetCycleColour
  LD C,$14
  CALL HeroWithinY
  RET NC
  LD A,(HeroRecord)
  LD E,(IY+$00)
  CP E
  JR Z,ItemHandlerTaken
  DEC E
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
; actor's Y, then WithinDistance $A9B6: carry when |E - D| < C.
;
; Stage 1's HeroWithinY at $A11E is the same code.
;
; Witness: L1 390 (rzx-r3).
HeroWithinY:
  LD A,(HeroY)
  LD E,A
  LD D,(IY+$01)
  LD A,C
  JP AbsDiffBelow

; Burst the actor's shape $EF69 (small mode, colours 2 and 3), then free it
;
; IY = the actor: StartBurst at X - 6, Y / 8 + 2 with the shape $EFBC, then
; FreeActor. No code or table in the image refers to $A148.
;
; Stage 1's BurstAtActor at $A129 is the same code.
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
; known only from the code.
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
; Stage 1's StartBurst at $A1F3 is the same code.
;
; Witness: L1 14 (rzx-r3).
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
; picks the particles' glyph: $EED9[step + a random 0-3] x 8 + $EEB9, written
; into ParticleGlyph. Each particle (4 bytes from $7040, $FF ends, $80 dead):
; its direction's step table at $EEFC + direction x 32 gives an index into
; BurstSteps (dx, dy; the second set for directions 13 and up), X + dx kept
; within 1-30, Y - dy (a particle above row 0 or below row 17 dies: $80); then
; the 8 glyph bytes are stored into the play buffer at the cell and the cell's
; attribute (ParticleInks) via $B3E8.
;
; Stage 1's UpdateBurst at $A28B is the same code.
;
; Witness: L1 6278 (rzx-r3, s3-right).
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

; A RET after UpdateBurst's closing JP `$A23F`: no code reaches or reads it
;
; rw3.py `$A308`: 0 reads, 0 writes; no jump in the image targets `$A308`.
BurstLeftover:
  DEFB $C9

; BurstTimer = $64: no burst
;
; Stage 1's StopBurst at $A393 is the same code.
;
; Witness: L1 14 (rzx-r3).
StopBurst:
  LD A,$64
  LD (BurstTimer),A
  RET

; The burst's four particle attributes, written by StartBurst
;
; ink C, bright ink C, ink B, bright ink B; the particle's byte 3 (0-3) picks
; one. As loaded: 2, $42, $43, 3.
;
; Stage 1's ParticleInks at $A399 (found through the operands of the matched
; routines); the size and shape given here are stage 3's, from its bytes and
; readers.
ParticleInks:
  DEFB $02,$42,$43,$03

; 20 (dx, dy) steps: 10 for the left-byte particles, 10 for the right-byte ones
;
; Read by UpdateBurst through BurstDirections' indices. Stage 1's BurstSteps at
; $A39D (found through the operands of the matched routines) has the same
; layout.
BurstSteps:
  INCBIN "res/stage3/table-burst-steps.bin",$0000,40

  ORG $A672

; Put the hero at X $0E, Y $31 (PlaceHero)
;
; Stage 1's PlaceHeroAtStart at $A47D is the same code.
;
; Witness: L1 2 (rzx-r3, s3-right).
PlaceHeroAtStart:
  LD D,$0E
  LD E,$31
  CALL PlaceHero
  LD A,$0E
  LD (HeroHeight),A
  RET

; Put the hero's template $9D35 into the hero's record $74E0 at D, E, then
; $ADDD
;
; Input: D, E = X and Y. Called from PlaceHeroAtStart ($A676), EnterGrid1
; ($AD75), EnterGrid2 ($AD98) and LeaveGrid2 ($ADC4).
;
; Stage 1's PlaceHero at $A481 is the same code.
;
; Witness: L1 5 (rzx-r3, s3-right).
PlaceHero:
  LD IY,HeroRecord
  LD HL,ActorTemplates
  CALL SpawnActor
  JP HeroStandFrame

; Set bit 7 of the actor's placement (it does not come back)
;
; IY = the actor: the placement +$10 x 3 + Placements gets bit 7, so
; LoadRoomActors skips it from now on.
;
; Stage 1's MarkPlacementDone at $A48E is the same code.
;
; Witness: L1 9 (rzx-r3).
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
; Stage 1's ReviveAllPlacements at $A4A1 is the same code.
;
; Witness: L1 2 (rzx-r3, s3-right).
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
; Stage 1's SpawnActor at $A4B1 is the same code.
;
; Witness: L1 93 (rzx-r3, s3-right).
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
; $9BFB (9 bytes a kind: Y offset in lines, the handler, five bytes for
; +8..+$0C, +$0F): X and Y relative to the room (Y in lines + the offset), the
; entry X, Y, +$10 = the placement's index, width 1, height 8, +$11 = 0, and a
; random 0-63 for +$0A when the kind gives $40.
;
; Called by the room builder at each room change.
;
; Stage 1's LoadRoomActors at $A4CC is the same code.
;
; Witness: L1 39 (rzx-r3, s3-right).
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
; written into HandlerCall and called with IY = the record.
;
; Stage 1's RunActorHandlers at $A5BD is the same code.
;
; Witness: L1 6280 (rzx-r3, s3-right).
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

  ORG $AC0A

; Set the actor IY to frame A of a frame table (the 4 bytes after the CALL)
;
; The CALL is followed by two words: the frame table DE and the graphics base
; BC; the routine pops them and
;
; returns to its caller's caller. A frame record is 6 bytes (FrameRecordAddress
; $B1BE: DE + 6A): +0 the column
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
; width x height bytes, row by row, one bit a pixel, no mask (DrawSprite $B4EA
; copies it).
;
; Stage 1's SetActorFrame at $AA02 is the same code.
;
; Witness: L1 14148 (rzx-r3, s3-right).
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

  ORG $B1A6

; Move the actor IY's base column by E (the other way when it faces left)
;
; Stage 1's MoveBaseX at $B112 is the same code.
;
; Witness: L1 506 (rzx-r3, s3-right).
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
; Stage 1's NegateIfFacingLeft at $B122 is the same code.
;
; Witness: L1 15528 (rzx-r3, s3-right).
NegateIfFacingLeft:
  BIT 7,(IY+$09)
  RET Z
  NEG
  RET

; HL = DE + 6A: frame A's record in the frame table DE
;
; Stage 1's FrameRecordAddress at $B12A is the same code.
;
; Witness: L1 14148 (rzx-r3, s3-right).
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

  ORG $B32B

; Add a missile (shot, spark) to the first eight slots of the missile records
; $75E0
;
; In: D column, E line, C type, B and A its parameters. The list holds 16
; records of 6 bytes: +0 column ($FF free),
;
; +1 line, +2 type (the handler of MissileHandlers $B3B8), +3 $FF, +4 B, +5 A.
; The search starts after the slot of
;
; MissileCursor $FE27 (round robin over 8). A = $FA puts a Random $8A26 byte in
; +5. Out: Z when the eight slots are
;
; full (nothing added), else NZ. AddMissileHigh $B334 uses slots 8-15 ($7610).
;
; Stage 1's AddMissile at $B28D is the same code.
;
; Witness: L1 42 (rzx-r3).
AddMissile:
  PUSH BC
  PUSH DE
  PUSH AF
  LD BC,Missiles
  JP AddMissileFrom

; Add a missile to the slots 8-15 ($7610) of the missile records
;
; Stage 1's AddMissileHigh at $B296 is the same code.
;
; Witness: L1 121 (rzx-r3, s3-right).
AddMissileHigh:
  PUSH BC
  PUSH DE
  PUSH AF
  LD BC,MissilesHigh

; Add a missile to the eight slots from BC
;
; Stage 1's AddMissileFrom at $B29C is the same code.
;
; Witness: L1 163 (rzx-r3, s3-right).
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

  ORG $B384

; Run the handler of every missile in use (once a main-loop pass)
;
; The 16 records of the missile records $75E0 (6 bytes each, IY): a record
; whose +0 is not $FF calls the handler
;
; MissileHandlers[+2] through the CALL at MissileCall $B3AA, whose operand it
; writes. IX is kept.
;
; Stage 1's UpdateMissiles at $B2E6 is the same code.
;
; Witness: L1 6278 (rzx-r3, s3-right).
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

; The handler of each missile kind 0-9
;
; 10 words, kinds 0-9: 0, 1 and 6 HangFlashBorder $8629 (no stage-3 code adds
; these kinds), 2 and 3 UpdateThrownAmmo $7FF5 (the thrown
;
; objects, left and right), 4 UpdateThroneShot $80F0 (the giant's shots), 5
; UpdateBolt $821F (the hero's bolt), 7 and 8
;
; UpdatePathFlyer $842E, 9 UpdateHeroShot $80B8. Read by UpdateMissiles (LD HL
; at $B39E).
;
; Stage 1's MissileHandlers at $B31A (found through the operands of the matched
; routines); the size and shape given here are stage 3's, from its bytes and
; readers.
MissileHandlers:
  DEFW HangFlashBorder
  DEFW HangFlashBorder
  DEFW UpdateThrownAmmo
  DEFW UpdateThrownAmmo
  DEFW UpdateThroneShot
  DEFW UpdateBolt
  DEFW HangFlashBorder
  DEFW UpdatePathFlyer
  DEFW UpdatePathFlyer
  DEFW UpdateHeroShot

  ORG $B3F8

; Free the actor record IY (+0 = $FF)
;
; Stage 1's RemoveActor at $B35E is the same code.
;
; Witness: L1 237 (rzx-r3, s3-right).
RemoveActor:
  LD (IY+$00),$FF
  RET

; Free the actor record IY and the next one (+0 and +$12 = $FF)
;
; Jumped to from TrollLeaves ($90C3); called by ScoreBurst200 ($A004).
;
; Stage 1's RemoveActorPair at $B363 is the same code.
;
; Witness: L1 3 (rzx-r3).
RemoveActorPair:
  LD (IY+$00),$FF
  LD (IY+$12),$FF
  RET
