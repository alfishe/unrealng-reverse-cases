; --------------------------------------------------------------------------------------------------------------------
; enemies.asm: The enemies, the hazards and the bosses: the Vikings, the trolls, the bog men, the dragon, the pyre, the lightning, the giant on the throne
;
; Grid 0 (the longship): Vikings (SpawnViking, VikingActor), the lightning (LightningStep, LightningActor), the rain
; and the sea (CheckWaterDeath). Grid 1 (the swamp and the forest): trolls in two records (SpawnTroll, TrollLegsActor,
; TrollBodyActor), bog men (SpawnBogMan, BogManActor), the funeral pyre (PyreFlameActor, PyreBierActor, PyreBodyActor:
; the rain puts the flames out and the body rises), the dragon in room 8 (DrawDragon, DragonHeadActor,
; DragonFlameActor; 15 thrown objects kill it: DragonHits $0F) and the drawbridge (DrawbridgeActor). Grid 2 (the
; castle's hall): the giant on the throne (ThroneBossStep; 30 bolts kill it).
; --------------------------------------------------------------------------------------------------------------------

  ORG $82B9

; Piece actor: takes 6 hits, rises, bobs and then waits to be taken as a piece
; of the artefact (1200 points)
;
; IY = the actor (18-byte record from PieceTemplate `$9C94`, spawned two at a
; time by SpawnBonus `$9F93`). Colour from the cycle (SetCycleColour `$B49C`).
; +$0B not 0 (the second record, the sparkle): frames 2-9 in turn (+8 + 1 AND
; 7, + 2). Else by +$0A: 6 PieceRises, 7 PieceWaitsPickup; 0-5: each hit (+9
; bit 4, set by a shot or the hero's blow) clears the flag and adds 1 to +$0A;
; at 6 the next record's +0 is set to $FF (the sparkle freed). Frame 0. Draws
; with SetActorFrame (PieceActorSet: the frame table `$DFB3`, the set
; PieceSprites `$DECB`). Output: none.
;
; The hit path ran 30 times and the sixth hit 5 times (rzx-r3: the five
; pieces).
;
; Stage 1's UpdatePieceActor at $8233 has the same code but for its frame table
; and set.
;
; Witness: L1 3871 (rzx-r3, s3-right).
UpdatePieceActor:
  CALL SetCycleColour
  LD A,(IY+$0B)
  CP $00
  JR NZ,PieceActorAnimate
  LD A,(IY+$0A)
  CP $06
  JP Z,PieceRises
  CP $07
  JP Z,PieceWaitsPickup
  BIT 4,(IY+$09)
  JR Z,PieceActorStill
  RES 4,(IY+$09)
  INC (IY+$0A)
  LD A,(IY+$0A)
  CP $06
  JR NZ,PieceActorStill
  LD (IY+$12),$FF
PieceActorStill:
  XOR A                   ; frame 0
  JP PieceActorDraw
PieceActorAnimate:
  LD A,(IY+$08)           ; the sparkle: the next frame
  INC A
  AND $07
  LD (IY+$08),A
  ADD A,$02
; This entry point is used by the routines at PieceRises and PieceWaitsPickup.
PieceActorDraw:
  CALL SetActorFrame

; SetActorFrame's words after the CALL at `$82F7`: the frame table `$DFB3`, the
; graphics base `$DECB`
;
; Read by SetActorFrame `$AC0A` each time the piece is drawn.
PieceActorSet:
  DEFW PieceFrameTable,PieceSprites

; State 6: rise and bob along RiseSteps for 30 steps (effect 3 at steps 16 and
; 25), then state 7
;
; Stage 1's PieceRises at $8279 is the same code.
;
; Witness: L1 155 (rzx-r3).
PieceRises:
  INC (IY+$08)
  LD A,(IY+$08)
  CP $1E
  JR Z,PieceRisesDone
  CP $10
  JP Z,PieceRisesSound
  CP $19
  JP NZ,PieceRisesMove
PieceRisesSound:
  LD DE,$0003
  CALL PlaySoundVector
PieceRisesMove:
  LD C,(IY+$08)
  LD B,$00
  LD HL,RiseSteps
  ADD HL,BC
  LD A,(HL)
  ADD A,(IY+$0E)
  LD (IY+$0E),A
  XOR A
  JP PieceActorDraw
PieceRisesDone:
  INC (IY+$0A)
  XOR A
  JP PieceActorDraw

; The rising piece's y change at each step 0-29
;
; Stage 1's RiseSteps at $82AE (found through the operands of the matched
; routines); the size and shape given here are stage 3's, from its bytes and
; readers.
RiseSteps:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$01,$02,$03,$04,$05,$06
  DEFB $FC,$FD,$FE,$FF,$00,$01,$02,$03
  DEFB $04,$FE,$FF,$00,$01,$02

; State 7: when the hero touches it at its column (or the next): 1200 points,
; the piece's bit, freed
;
; $A13D (the hero within $14 lines); then the hero's x ($74E0) equal to +0 or
; +0 + 1: AddScore 1200, PieceTakenFlag = 1, PiecesMask |= +$10, freed ($B3F8).
;
; Stage 1's PieceWaitsPickup at $82CC is the same code.
;
; Witness: L1 35 (rzx-r3).
PieceWaitsPickup:
  LD C,$14
  CALL HeroWithinY
  JR NC,PieceNotTaken
  LD A,(HeroRecord)
  LD E,(IY+$00)
  CP E
  JR Z,PieceTaken
  INC E
  CP E
  RET NZ
PieceTaken:
  LD BC,$04B0
  CALL AddScore
  LD A,$01
  LD (PieceTakenFlag),A
  LD A,(PiecesMask)
  OR (IY+$10)
  LD (PiecesMask),A
  JP RemoveActor
PieceNotTaken:
  XOR A
  JP PieceActorDraw

  ORG $87ED

; Room 5 while the pyre burns ($FE5D 0): the hero at columns 10-17 loses 3
;
; Called every pass by the hero's pass at $ADEC. RoomNumber 5 (the test reads
; no grid; grid 1's room 5 holds the pyre), $FE5D 0 (the pyre's state: its
; flames, PyreFlameActor, stand while it is 0) and the hero's column 10-17:
; DamageHero with C = 3. Ran 6280 times; the damage call ($8802) never.
;
; Witness: L1 6280 (rzx-r3, s3-right).
PyreFireDamage:
  LD A,(RoomNumber)
  CP $05
  RET NZ
  LD A,(PyreState)
  CP $00
  RET NZ
  LD A,(IY+$00)
  CP $0A
  RET C
  CP $12
  RET NC
  LD C,$03
  JP DamageHero

; Room 8 while the dragon lives: the hero at column 13 and on loses 2 a pass
; once the dragon has breathed
;
; Called every pass by the hero's pass at $ADE6. RoomNumber 8 (grid 1's dragon
; room; no grid test), the hero's column $74E0 13 or more, DragonHits not $10
; (alive) and DragonBreath not 0: DamageHero with C = 2. DragonBreath is
; written by DragonHeadActor (the breath's step 1-$12) and keeps $12 between
; breaths, so after the first breath the right part of the room hurts while the
; dragon lives (known from the code at $92FF and $8819; rzx-r3 ran the damage
; call 11 times).
;
; Witness: L1 6280 (rzx-r3, s3-right).
DragonFireDamage:
  LD A,(RoomNumber)
  CP $08
  RET NZ
  LD A,(HeroRecord)
  CP $0D
  RET C
  LD A,(DragonHits)
  CP $10
  RET Z
  LD A,(DragonBreath)
  CP $00
  RET Z
  LD C,$02
  JP DamageHero

  ORG $887A

; Grid 1 room 8: draw the dragon's body; on a hit count it and flash it red; at
; 15 hits it dies
;
; Called every pass by MainLoop. Grid 1 room 8 only. DragonHits $0F: jumps to
; $A00F (DragonHits = $10, 2500 points, a burst: the dragon's death; rzx-r3's
; screen 012501 shows the burst). $10: nothing (the dragon is gone). Else
; DrawRowPicture draws the 69-line row-packed body $C921 into the buffer at
; $6192; then, without a hit (DragonHitFlag 0), the body's colours $CABF (9 x 9
; attributes, $FF transparent) go into the shadow attributes at $6E92; with a
; hit (DragonHitFlag 1, set by UpdateThrownAmmo) DragonHitFlag = 0, DragonHits
; + 1 and the same 9 x 9 cells are painted $42 (bright red) for this pass.
;
; Stage 1's DrawArenaPicture ($89BB) has the same job for its arena's dragon
; (not the same code: names.err).
;
; Witness: L1 6278 (rzx-r3, s3-right).
DrawDragon:
  LD A,(GridNumber)
  CP $01
  RET NZ
  LD A,(RoomNumber)
  CP $08
  RET NZ
  LD A,(DragonHits)
  CP $0F
  JP Z,DragonBeaten
  CP $10
  RET Z
  LD HL,DragonPicture
  LD DE,PlayBuffer+1682
  LD B,$45
  CALL DrawRowPicture
  LD A,(DragonHitFlag)
  CP $01
  JR Z,DragonHit
  LD HL,DragonAttributes
  LD DE,DragonAttributesCell
  LD B,$09
DrawDragonRow:
  PUSH BC
  PUSH DE
  LD B,$09
DrawDragonCell:
  LD A,(HL)
  CP $FF
  JR Z,DrawDragonNext
  LD (DE),A
DrawDragonNext:
  INC E
  INC HL
  DJNZ DrawDragonCell
  POP DE
  EX DE,HL
  LD BC,$0020
  ADD HL,BC
  EX DE,HL
  POP BC
  DJNZ DrawDragonRow
  RET
DragonHit:
  XOR A                   ; a hit: count it and paint the body red
  LD (DragonHitFlag),A
  LD A,(DragonHits)
  CP $10
  RET Z
  INC A
  LD (DragonHits),A
  LD HL,DragonAttributes
  LD DE,DragonAttributesCell
  LD B,$09
DragonHitRow:
  PUSH BC
  PUSH DE
  LD B,$09
DragonHitCell:
  LD A,(HL)
  CP $FF
  JR Z,DragonHitNext
  LD A,$42
  LD (DE),A
DragonHitNext:
  INC E
  INC HL
  DJNZ DragonHitCell
  POP DE
  EX DE,HL
  LD BC,$0020
  ADD HL,BC
  EX DE,HL
  POP BC
  DJNZ DragonHitRow
  RET

  ORG $8C16

; Grid 0 (the longship): a Viking comes in at the left or right edge, at most 4
; at once
;
; Needs grid 0, a free record (FindFreeActor), VikingCount not 4, a room other
; than 0 and 3. A random bit picks the side: from the right (SpawnVikingRight:
; the hero's column under $16, VikingTemplateLeft at column $1E) or from the
; left (SpawnVikingLeft: the hero's column 8 or more, VikingTemplateRight at
; column 0), line $40; VikingCount + 1. Ran 44 times (37 past the grid test, 16
; Vikings spawned).
;
; Witness: L1 44 (rzx-r3, s3-right).
SpawnViking:
  LD A,(GridNumber)
  CP $00
  RET NZ
  CALL FindFreeActor
  RET NZ
  LD A,(VikingCount)
  CP $04
  RET Z
  LD A,(RoomNumber)
  CP $00
  RET Z
  CP $03
  RET Z
  LD E,$40
  CALL Random
  AND $01
  JR Z,SpawnVikingRight
  JR SpawnVikingLeft
SpawnVikingRight:
  LD A,(HeroRecord)       ; from the right edge, facing left
  CP $16
  RET NC
  LD A,(VikingCount)
  INC A
  LD (VikingCount),A
  LD HL,VikingTemplateLeft
  LD D,$1E
  JP SpawnActor
SpawnVikingLeft:
  LD A,(HeroRecord)       ; from the left edge, facing right
  CP $08
  RET C
  LD A,(VikingCount)
  INC A
  LD (VikingCount),A
  LD HL,VikingTemplateRight
  LD D,$00
  JP SpawnActor

; Actor handler: a Viking warrior (horned helmet, round shield, axe) on the
; longship
;
; IY = the record (VikingTemplateLeft / VikingTemplateRight). Removed in rooms
; 0 and 3. A shot's hit (+9 bit 4) outside state 4: the flag cleared, state 4
; (VikingHit). Then by the state +$0A: 0 VikingWalk, 1 VikingStand, 2
; VikingBlock, 3 VikingStrike, 4 VikingHit, 6 VikingDie (state 5 returns).
; VikingFrameSet's 17 frames: 0 standing, 1-6 walking, 7-$0C the axe's swing,
; $0D-$0E the shield up, $0F-$10 hit and falling. The small white warriors on
; the longship in rzx-r3's screens 000562-004043.
;
; Witness: L1 696 (rzx-r3, s3-right).
VikingActor:
  LD A,(RoomNumber)
  CP $00
  JP Z,RemoveActor
  CP $03
  JP Z,RemoveActor
  BIT 4,(IY+$09)
  JR Z,VikingState
  LD A,(IY+$0A)
  CP $04
  JR Z,VikingState
  RES 4,(IY+$09)
  LD (IY+$0A),$04
  LD (IY+$0B),$FF
  JP VikingHit
VikingState:
  LD A,(IY+$0A)
  CP $00
  JP Z,VikingWalk
  CP $01
  JP Z,VikingStand
  CP $02
  JP Z,VikingBlock
  CP $03
  JP Z,VikingStrike
  CP $04
  JP Z,VikingHit
  CP $06
  JP Z,VikingSink
  RET
; This entry point is used by the routine at VikingStand.
VikingWalkOn:
  LD (IY+$0A),$00         ; back to walking (state 0)
  JP VikingActor

; State 0: walk 2 columns every 6 passes; stop when a body is ahead or the hero
; is near
;
; +8 counts the walk frames 1-6. At 7 (frame 1 again): the base column +2
; (facing right) or -2; removed at column $1D and more or under 5 (VikingCount
; is not lowered so). Facing right: a body 2 columns ahead (IsBodyAhead) or the
; hero within 6 columns (IsHeroBeyondAhead with C = 6) stops it (state 1);
; facing left: IsBodyBehind and IsHeroBeyondBehind with 8. Then VikingFrame.
;
; Witness: L1 457 (rzx-r3, s3-right).
VikingWalk:
  INC (IY+$08)
  LD A,(IY+$08)
  CP $07
  JP NZ,VikingFrame
  LD (IY+$08),$01
  BIT 7,(IY+$09)
  JR NZ,VikingWalkLeft
  INC (IY+$0D)
  INC (IY+$0D)
  LD A,(IY+$0D)
  CP $1D
  JP NC,RemoveActor
  CALL IsBodyAhead
  JR NZ,VikingWalkStop
  LD C,$06
  CALL IsHeroBeyondAhead
  JP C,VikingFrame
VikingWalkStop:
  LD (IY+$0A),$01
  JP VikingStand
VikingWalkLeft:
  DEC (IY+$0D)
  DEC (IY+$0D)
  LD A,(IY+$0D)
  CP $05
  JP C,RemoveActor
  CALL IsBodyBehind
  JR NZ,VikingWalkStopLeft
  LD C,$08
  CALL IsHeroBeyondBehind
  JP NC,VikingFrame
VikingWalkStopLeft:
  LD (IY+$0A),$01
  JP VikingStand

; State 1: face the hero; fall to his high strike, else now and then block or
; strike
;
; VikingFaceHero, frame 0. Facing left, 1 in 4 passes it first walks on (state
; 0, VikingWalkOn). The hero out of reach (more than 5 columns ahead, 6
; behind): only the frame. In reach: the hero's high strike landing
; (IsHeroHitFrame6) while he faces the Viking: VikingHit (state 4, +$0B = $FF).
; Else a random 0-31: under $1C nothing; $1F or +$10 = 0: a strike (state 3),
; the hero loses 6 at once (DamageHero C = 6); else a block (state 2) for +$10
; = 10-25 passes.
;
; Witness: L1 131 (rzx-r3, s3-right).
VikingStand:
  CALL VikingFaceHero
  LD (IY+$08),$00
  BIT 7,(IY+$09)
  JR NZ,VikingStandLeft
  LD C,$05
  CALL IsHeroBeyondAhead
  JP C,VikingFrame
  CALL IsHeroHitFrame6
  JP NZ,VikingStandChoose
  LD A,(HeroFlags)
  BIT 7,A
  JP Z,VikingStandChoose
  LD (IY+$0A),$04
  LD (IY+$0B),$FF
  JP VikingHit
VikingStandLeft:
  CALL Random
  AND $03
  CP $02
  JP Z,VikingWalkOn
  LD C,$06
  CALL IsHeroBeyondBehind
  JP NC,VikingFrame
  CALL IsHeroHitFrame6
  JP NZ,VikingStandChoose
  LD A,(HeroFlags)
  BIT 7,A
  JP NZ,VikingStandChoose
  LD (IY+$0A),$04
  LD (IY+$0B),$FF
  JP VikingHit
VikingStandChoose:
  CALL Random
  AND $1F
  CP $1C
  JP C,VikingFrame
  CP $1F
  JR Z,VikingStandStrike
  LD A,(IY+$10)
  CP $00
  JR Z,VikingStandStrike
  LD (IY+$0B),$FF
  LD (IY+$0A),$02
  CALL Random
  AND $0F
  ADD A,$0A
  LD (IY+$10),A
  JP VikingBlock
VikingStandStrike:
  LD (IY+$0B),$FF
  LD (IY+$0A),$03
  LD C,$06
  CALL DamageHero
  JP VikingStrike

; State 2: hold the shield up (VikingBlockFrames) while +$10 lasts, then stand
; (state 1)
;
; +$0B counts 0-7 (the frame VikingBlockFrames[+$0B]); at step 4 +$10 - 1 and,
; until it reaches 0, the step goes back to 3 (the shield stays up). At 8:
; state 1.
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
; known only from the code.
VikingBlock:
  INC (IY+$0B)
  LD A,(IY+$0B)
  CP $08
  JR NZ,VikingBlockHold
  LD (IY+$0A),$01
  JP VikingStand
VikingBlockHold:
  CP $04
  JR NZ,VikingBlockFrame
  DEC (IY+$10)
  JR Z,VikingBlockFrame
  DEC A
  LD (IY+$0B),A
VikingBlockFrame:
  LD C,A
  LD B,$00
  LD HL,VikingBlockFrames
  ADD HL,BC
  LD A,(HL)
  LD (IY+$08),A
  JP VikingFrame

; The block's frames by step 0-7: 0, $0D, $0D, $0E, $0D, $0D, 0, 0
;
; Read by VikingBlock at $8DC7 (no read in the recordings: rw3.py).
VikingBlockFrames:
  DEFB $00,$0D,$0D,$0E,$0D,$0D,$00,$00

; State 3: the axe's swing (VikingStrikeFrames, 15 steps), then stand with +$10
; = 1
;
; The damage was dealt when the strike began (VikingStand). At step $0F: state
; 1, +$10 = 1.
;
; Witness: L1 64 (rzx-r3, s3-right).
VikingStrike:
  INC (IY+$0B)
  LD A,(IY+$0B)
  CP $0F
  JR NZ,VikingStrikeFrame
  LD (IY+$0A),$01
  LD (IY+$10),$01
  JP VikingStand
VikingStrikeFrame:
  LD C,(IY+$0B)
  LD B,$00
  LD HL,VikingStrikeFrames
  ADD HL,BC
  LD A,(HL)
  LD (IY+$08),A
  JP VikingFrame

; The swing's frames by step 0-14: 7 7 8 8 9 9 $0A $0A $0B $0B $0C $0C 0 0 0
;
; Read by VikingStrike at $8DF4 (all 15 bytes read in rzx-r3).
VikingStrikeFrames:
  DEFB $07,$07,$08,$08,$09,$09,$0A,$0A
  DEFB $0B,$0B,$0C,$0C,$00,$00,$00

; State 4: a hit; the second one kills, else a 4-pass stagger
;
; When bit 6 of +9 differs from the hero's (bit 6 of $74E9): back to state 1,
; no harm. Else +$10 + 1: 2 or more goes to VikingDie; else +$0B counts 0-3
; with frame $0F (VikingHitFrames), then state 1 and +$10 = 1.
;
; Witness: L1 18 (rzx-r3).
VikingHit:
  LD A,(HeroFlags)
  AND $40
  LD E,A
  LD A,(IY+$09)
  AND $40
  CP E
  JR Z,VikingHitCount
  LD (IY+$0A),$01
  JP VikingStand
VikingHitCount:
  LD A,(IY+$10)
  INC A
  LD (IY+$10),A
  CP $02
  JR C,VikingHitStagger
  JP VikingDie
VikingHitStagger:
  INC (IY+$0B)
  LD A,(IY+$0B)
  CP $04
  JR NZ,VikingHitFrame
  LD (IY+$0A),$01
  LD (IY+$10),$01
  JP VikingStand
VikingHitFrame:
  LD C,(IY+$0B)
  LD B,$00
  LD HL,VikingHitFrames
  ADD HL,BC
  LD A,(HL)
  LD (IY+$08),A
  JP VikingFrame

; The stagger's frames: $0F four times
;
; Read by VikingHit at $8E4B.
VikingHitFrames:
  DEFB $0F,$0F,$0F,$0F

; The Viking falls: state 6, frames $10-$12, then removed; 1 in 16 leaves item
; 8
;
; State 6 (from VikingHit or the dispatch): +$0B 0-6, the frame $0F + (+$0B +
; 1) / 2. At 6: removed (RemoveActor, its column kept in D), VikingCount - 1,
; and when a random byte's low 4 bits are 0 an item of kind 8 is spawned
; (SpawnItem: column D, line $58, amount $24, the icon $EAE0). Ran 10 times
; (rzx-r3), the item once.
;
; Witness: L1 10 (rzx-r3).
VikingDie:
  LD (IY+$0B),$FF
  LD (IY+$08),$10
  LD (IY+$0A),$06
  JP VikingSink
; This entry point is used by the routine at VikingActor.
VikingSink:
  LD A,(IY+$0B)
  CP $06
  JP Z,VikingGone
  INC A
  LD (IY+$0B),A
  SRL A
  ADD A,$0F
  LD (IY+$08),A
  JP VikingFrame
VikingGone:
  LD D,(IY+$00)
  CALL RemoveActor
  LD A,(VikingCount)
  DEC A
  LD (VikingCount),A
  CALL Random
  AND $0F
  RET NZ
  LD E,$58
  LD L,$08
  LD H,$24
  LD BC,ItemIconKind8
  JP SpawnItem

; Show frame +8 of the Viking's set (SetActorFrame with VikingFrameSet)
;
; Witness: L1 669 (rzx-r3, s3-right).
VikingFrame:
  LD A,(IY+$08)
  CALL SetActorFrame

; SetActorFrame's inline words: the frame table $D7F5, the graphics base $D368
;
; Read by SetActorFrame $AC0A after the CALL at $8E9D.
VikingFrameSet:
  DEFW VikingFrameTable,VikingSprites

; NZ when an actor with a body (+$0F bit 5) stands 2 columns right of the actor
; IY
;
; C = +0 + 2, then IsBodyAtColumn. Called by VikingWalk.
;
; Witness: L1 27 (rzx-r3, s3-right).
IsBodyAhead:
  LD A,(IY+$00)
  ADD A,$02
  LD C,A

; NZ when one of the 13 actors, not free and with +$0F bit 5 (the Vikings),
; stands at column C
;
; Returns through ReturnNZ / ReturnZ. Stage 1's IsColumnTaken ($93C1) is the
; like test (within 2 columns, bit 2).
;
; Witness: L1 69 (rzx-r3, s3-right).
IsBodyAtColumn:
  LD IX,Actors
  LD DE,$0012
  LD B,$0D
IsBodyAtColumnLoop:
  LD A,(IX+$00)
  CP $FF
  JR Z,IsBodyAtColumnNext
  BIT 5,(IX+$0F)
  JR Z,IsBodyAtColumnNext
  LD A,(IX+$00)
  CP C
  JP Z,ReturnNZ
IsBodyAtColumnNext:
  ADD IX,DE
  DJNZ IsBodyAtColumnLoop
  JP ReturnZ

; NZ when an actor with a body stands 2 columns left of the actor IY
;
; C = +0 - 2, then IsBodyAtColumn. Called by VikingWalk.
;
; Witness: L1 42 (rzx-r3, s3-right).
IsBodyBehind:
  LD A,(IY+$00)
  SUB $02
  LD C,A
  JP IsBodyAtColumn

; Turn the actor IY to the hero when he is behind it (+9 bit 7 flipped,
; MoveBaseX with E = -3)
;
; Facing right: returns while the hero's column is not under its own; facing
; left: while it is not over it. Called by VikingStand.
;
; Witness: L1 131 (rzx-r3, s3-right).
VikingFaceHero:
  BIT 7,(IY+$09)
  JR NZ,VikingFaceHeroLeft
  LD A,(HeroRecord)
  CP (IY+$00)
  RET NC
  JP VikingTurn
VikingFaceHeroLeft:
  LD A,(HeroRecord)
  CP (IY+$00)
  RET C
  JP VikingTurn
VikingTurn:
  LD A,(IY+$09)
  XOR $80
  LD (IY+$09),A
  LD E,$FD
  CALL MoveBaseX
  RET

; Carry when the actor's column + C is under the hero's column
;
; Called by VikingWalk (C = 6) and VikingStand (C = 5).
;
; Witness: L1 107 (rzx-r3, s3-right).
IsHeroBeyondAhead:
  LD A,(HeroRecord)
  LD B,A
  LD A,(IY+$00)
  ADD A,C
  CP B
  RET

; Carry when the actor's column - C is under the hero's column
;
; A = +0 - C, CP the hero's column $74E0. Called by VikingWalk (C = 8) and
; VikingStand (C = 6), which go on walking or standing (JP NC) while the hero
; is farther left than that.
;
; Witness: L1 78 (rzx-r3, s3-right).
IsHeroBeyondBehind:
  LD A,(HeroRecord)
  LD B,A
  LD A,(IY+$00)
  SUB C
  CP B
  RET

; SpawnActor's template: a Viking facing left (handler VikingActor), spawned at
; the right edge
;
; 18 bytes as an actor record: +2/+3 1 x 8, +4/+5 BlankIcon, +6/+7 VikingActor,
; +9 $80 (facing left), +$0C 7 (white), +$0F $23 (bits 0 shootable, 1, 5 a
; body), +$11 $80. Read by SpawnActor $A6AF (SpawnVikingRight).
VikingTemplateLeft:
  DEFB $00,$00,$01,$08,$44,$8A,$64,$8C,$00,$80,$00,$00,$07,$00,$00,$23,$00,$80

; SpawnActor's template: a Viking facing right, spawned at the left edge
;
; As VikingTemplateLeft with +9 = 0. Read by SpawnActor (SpawnVikingLeft).
VikingTemplateRight:
  DEFB $00,$00,$01,$08,$44,$8A,$64,$8C,$00,$00,$00,$00,$07,$00,$00,$23,$00,$80

; Grid 1 rooms 0-7 but 5: count SpawnDelay down, then 1 in 4 a troll or
; (SwampSpawnRooms) a bog man
;
; Rooms 8 and more and room 5: nothing. SwampSpawnRooms[RoomNumber] 0:
; SpawnDelay - 1; at 0 SpawnDelay = $14 + Random & 7 and 1 in 4 SpawnTroll. 1:
; SpawnDelay - 1; at 0 SpawnDelay = 5 + Random & 7 and 1 in 4 SpawnBogMan.
;
; Witness: L1 3497 (rzx-r3).
SwampSpawnTimer:
  LD A,(RoomNumber)
  CP $08
  RET NC
  CP $05
  RET Z
  LD A,(RoomNumber)
  LD C,A
  LD B,$00
  LD HL,SwampSpawnRooms
  ADD HL,BC
  LD A,(HL)
  CP $01
  JR Z,SwampSpawnBogMan
  LD A,(SpawnDelay)
  DEC A
  LD (SpawnDelay),A
  RET NZ
  CALL Random
  AND $07
  ADD A,$14
  LD (SpawnDelay),A
  CALL Random
  AND $03
  RET NZ
  JP SpawnTroll
SwampSpawnBogMan:
  LD A,(SpawnDelay)
  DEC A
  LD (SpawnDelay),A
  RET NZ
  CALL Random
  AND $07
  ADD A,$05
  LD (SpawnDelay),A
  CALL Random
  AND $03
  RET NZ
  JP SpawnBogMan

; A RET no code reaches (after the JP at $8F82)
;
; No jump, call or word points to $8F85 (a scan of the skool's operands); not
; executed in any recording (rzx-r3, s3-right).
SwampSpawnRet:
  DEFB $C9

; Per grid-1 room 0-10: 1 the room has bog men, 0 trolls
;
; 0 1 0 1 0 0 1 0 1 0 1. Read by SwampSpawnTimer at $8F4A for rooms 0-7
; (rw3.py: 7 bytes read; room 5 returns before); the bytes of rooms 8-10 no
; code reads (the CP $08 at $8F3A returns first).
SwampSpawnRooms:
  DEFB $00,$01,$00,$01,$00,$00,$01,$00
SwampSpawnRoomsUnread:
  DEFB $01,$00,$01        ; rooms 8-10: no code reads them

; Spawn a troll (legs and body, two records) at the room's edge away from the
; hero, one a side
;
; Needs a free pair (FindFreeActorPair). The hero's column 16 or more: column 5
; facing left (C = $80); else column $1A facing right; line $50. Not where the
; cell at line $78, column D + B (1 or 4) is solid (CellAt), nor when a troll
; facing that way is there (TrollFacingTaken). Spawns the legs $9CDC and the
; body $9CEE (the next record), both with the facing C. Ran 13 times, 8 trolls
; spawned.
;
; Witness: L1 13 (rzx-r3).
SpawnTroll:
  CALL FindFreeActorPair
  RET NZ
  LD B,$01
  LD D,$05
  LD C,$80
  LD A,(HeroRecord)
  CP $10
  JR NC,SpawnTrollPlace
  LD B,$04
  LD D,$1A
  LD C,$00
SpawnTrollPlace:
  LD E,$50
  PUSH DE
  PUSH BC
  LD A,D
  ADD A,B
  LD E,A
  LD D,$78
  CALL CellAt
  POP BC
  POP DE
  RET Z
  PUSH DE
  PUSH BC
  CALL TrollFacingTaken
  POP BC
  POP DE
  RET Z
  PUSH IY
  PUSH BC
  PUSH DE
  LD HL,TrollLegsTemplate
  CALL SpawnActor
  LD BC,$0012
  ADD IY,BC
  POP DE
  LD HL,TrollBodyTemplate
  CALL SpawnActor
  POP BC
  POP IY
  LD (IY+$09),C
  LD (IY+$1B),C
  RET

; Z when an actor with +$0F bit 4 (a troll), not free, faces the way C ($80 or
; 0)
;
; Over the 13 actor records; NZ (ReturnNZ) when none.
;
; Witness: L1 12 (rzx-r3).
TrollFacingTaken:
  LD B,$0D
  LD DE,$0012
  LD IX,Actors
TrollFacingTakenLoop:
  BIT 4,(IX+$0F)
  JR Z,TrollFacingTakenNext
  LD A,(IX+$00)
  CP $FF
  JR Z,TrollFacingTakenNext
  LD A,(IX+$09)
  AND $80
  CP C
  RET Z
TrollFacingTakenNext:
  ADD IX,DE
  DJNZ TrollFacingTakenLoop
  JP ReturnNZ

; Actor handler: the troll's legs (the lower record), which carry the body;
; four hits kill it
;
; IY = the legs, IY + $12 the body (TrollBodyActor). State 1 (standing): kept
; while the hero is near (IsHeroNearTroll) or the ground ahead ends
; (TrollGroundAhead); else 1 in 8 passes back to state 0 (both records). State
; 0: the hero near or no ground ahead: state 1 (both). Every pass +$10 + 1 and
; the colour 3 (magenta) on both; a hit on either record (+9 bit 4): both state
; 1, the flags cleared, colour 1 (blue) for this pass, +$0B (4 from the
; template) - 1, at 0 $9FD5 (200 points and the troll's end). Walking (state
; 0): every 8 passes the frame +8 + 1 (0-3), and at frame 0 the base column
; moves (MoveBaseX E = -1); at column 0 TrollLeaves. Then TrollFrame and the
; body's line +$0E = the legs' line - $1E.
;
; The purple troll with the club in the swamp, rzx-r3's screen 005509.
;
; Witness: L1 644 (rzx-r3).
TrollLegsActor:
  LD A,(IY+$0A)
  CP $01
  JR Z,TrollLegsStanding
  CALL IsHeroNearTroll
  JR C,TrollLegsStop
  CALL TrollGroundAhead
  JR NZ,TrollLegsStanding
TrollLegsStop:
  LD (IY+$0A),$01
  LD (IY+$1C),$01
  RET
TrollLegsStanding:
  CALL IsHeroNearTroll
  JR C,TrollLegsColour
  CALL TrollGroundAhead
  JR Z,TrollLegsColour
  CALL Random
  AND $07
  JR NZ,TrollLegsColour
  LD (IY+$0A),$00
  LD (IY+$1C),$00
TrollLegsColour:
  INC (IY+$10)
  LD (IY+$0C),$03
  LD (IY+$1E),$03
  BIT 4,(IY+$09)
  JR NZ,TrollLegsHit
  BIT 4,(IY+$1B)
  JR Z,TrollLegsWalk
TrollLegsHit:
  LD (IY+$0A),$01
  LD (IY+$1C),$01
  RES 4,(IY+$09)
  RES 4,(IY+$1B)
  LD (IY+$0C),$01
  LD (IY+$1E),$01
  DEC (IY+$0B)
  JP Z,ScoreBurst200
TrollLegsWalk:
  LD A,(IY+$0A)
  CP $01
  JR Z,TrollLegsDraw
  LD A,(IY+$10)
  AND $07
  JR NZ,TrollLegsDraw
  LD A,(IY+$08)
  INC A
  AND $03
  LD (IY+$08),A
  JR NZ,TrollLegsDraw
  LD E,$FF
  CALL MoveBaseX
  LD A,(IY+$00)
  CP $00
  JP Z,TrollLeaves
TrollLegsDraw:
  CALL TrollFrame
  LD A,(IY+$01)
  SUB $1E
  LD (IY+$20),A
  RET

; A = the cell under the troll's front (line $78, base column + 4, or + 0
; facing left); Z: not solid
;
; CellAt with D = $78, E = +$0D + (4 facing right, 0 facing left).
;
; Witness: L1 1215 (rzx-r3).
TrollGroundAhead:
  LD A,$04
  BIT 7,(IY+$09)
  JR Z,TrollGroundAheadCell
  XOR A
TrollGroundAheadCell:
  ADD A,(IY+$0D)
  LD E,A
  LD D,$78
  JP CellAt

; Show frame +8 of the troll's set (SetActorFrame with TrollFrameSet)
;
; Frames 0-3 the legs walking, 4-6 the body (club down, raised, swung).
;
; Witness: L1 1281 (rzx-r3).
TrollFrame:
  LD A,(IY+$08)
  CALL SetActorFrame

; SetActorFrame's inline words: the frame table $D23A, the graphics base $D0B6
;
; Read by SetActorFrame $AC0A after the CALL at $90B2.
TrollFrameSet:
  DEFW TrollFrameTable,TrollSprites

; The troll walked off at column 0: SpawnDelay / 4, both records freed
;
; Reached from TrollLegsActor (at $908E).
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
; known only from the code.
TrollLeaves:
  LD A,(SpawnDelay)
  SRL A
  SRL A
  LD (SpawnDelay),A
  JP RemoveActorPair

; Actor handler: the troll's body with the club (the upper record): follows the
; legs, swings at the hero
;
; State 0: on every 8th pass of the legs' counter (IY - 2, the legs' +$10) the
; body steps back (StepFineBack 2) with them; frame 4 (club down). State 1:
; TrollSwingCheck; not swinging: frame 4, else +$0B counts down through
; TrollSwingFrames (frames 5 and 6). A swing starts in TrollSwingCheck.
;
; Witness: L1 641 (rzx-r3).
TrollBodyActor:
  LD A,(IY+$0A)
  CP $01
  JP Z,TrollBodySwing
  LD A,(IY-$02)
  AND $07
  JR NZ,TrollBodyIdle
  LD A,$02
  CALL StepFineBack
TrollBodyIdle:
  JP TrollBodyRest
TrollBodyRest:
  LD (IY+$08),$04
  JP TrollFrame
TrollBodySwing:
  CALL TrollSwingCheck
  LD A,(IY+$0A)
  CP $00
  JP Z,TrollBodyRest
  LD A,(IY+$0B)
  CP $00
  JR Z,TrollBodySwingCheck
  DEC (IY+$0B)
  LD C,(IY+$0B)
  LD B,$00
  LD HL,TrollSwingFrames
  ADD HL,BC
  LD A,(HL)
  LD (IY+$08),A
  JP TrollFrame
TrollBodySwingCheck:
  CALL TrollSwingCheck
  LD (IY+$08),$04
  JP TrollFrame

; The swing's frames by +$0B 9-0: 4 4 5 5 6 6 6 6 5 5 (read backwards)
;
; Read by TrollBodyActor at $9102; no swing ran in the recordings (rw3.py: no
; read).
TrollSwingFrames:
  DEFB $04,$04,$05,$05,$06,$06,$06,$06
  DEFB $05,$05

; Not swinging and the hero within 3 columns in front: 1 in 16 a swing of the
; club, the hero loses 40
;
; +$0B 0 only. IsHeroNearTroll's test (AbsDiffBelow 3 of the hero's column and
; the base column + 2, negated facing left); then a random 0-15 = 7; then the
; hero in front (facing right: his column over the troll's; left: under): +$0B
; = $0A (the swing), DamageHero with C = $28. The swing itself ($913E on) never
; ran.
;
; Witness: L1 112 (rzx-r3).
TrollSwingCheck:
  LD A,(IY+$0B)
  CP $00
  RET NZ
  LD A,(HeroRecord)
  LD E,A
  LD A,$02
  CALL NegateIfFacingLeft
  ADD A,(IY+$0D)
  LD D,A
  LD A,$03
  CALL AbsDiffBelow
  RET NC
  CALL Random
  AND $0F
  CP $07
  RET NZ
  BIT 7,(IY+$09)
  JR NZ,TrollSwingLeft
  LD A,(HeroRecord)
  CP (IY+$00)
  RET NC
  JR TrollSwingHit
TrollSwingLeft:
  LD A,(HeroRecord)
  CP (IY+$00)
  RET C
TrollSwingHit:
  LD (IY+$0B),$0A
  LD C,$28
  CALL DamageHero
  RET

; Carry when the hero's column is within 3 of the troll's base column + 2 (- 2
; facing left)
;
; AbsDiffBelow with A = 3. Called by TrollLegsActor.
;
; Witness: L1 1231 (rzx-r3).
IsHeroNearTroll:
  LD A,(HeroRecord)
  LD E,A
  LD A,$02
  CALL NegateIfFacingLeft
  ADD A,(IY+$0D)
  LD D,A
  LD A,$03
  JP AbsDiffBelow

; A bog man rises out of the swamp at a random column
;
; Needs a free record (FindFreeActor). D = Random & $1C, not 0, 4 or $1C;
; IsBottomCellSolid must find the bottom cell row 17 solid at that column;
; SpawnBogManCheck (a RET). D under 16: template $9CCA at D + 3, else $9CB8 at
; D - 7; line $52.
;
; Witness: L1 30 (rzx-r3).
SpawnBogMan:
  CALL FindFreeActor
  RET NZ
  CALL Random
  AND $1C
  RET Z
  CP $04
  RET Z
  CP $1C
  RET Z
  LD D,A
  CALL IsBottomCellSolid
  CALL SpawnBogManCheck
  LD HL,BogManTemplate
  LD C,$F9
  LD A,D
  CP $10
  JR NC,SpawnBogManPlace
  LD HL,BogManLeftTemplate
  LD C,$03
SpawnBogManPlace:
  ADD A,C
  LD D,A
  LD E,$52
  LD A,D
  JP SpawnActor

; The room cell at cell row 17 ($11), column D: solid returns, not solid
; abandons the spawn
;
; E = D, D = $11, then $B1FC (CellAt's entry for a cell row in D: bit 1 of the
; cell). NZ (solid): returns to SpawnBogMan. Z: drops the return address and
; returns from SpawnBogMan.
;
; Witness: L1 15 (rzx-r3).
IsBottomCellSolid:
  PUSH DE
  LD E,D
  LD D,$11
  CALL CellAtRow
  JR NZ,IsBottomCellSolidYes
  POP DE
  POP HL
  RET
IsBottomCellSolidYes:
  POP DE
  RET

; A bare RET called by SpawnBogMan (at $9184)
;
; Witness: L1 12 (rzx-r3).
SpawnBogManCheck:
  RET

; Actor handler: a bog man that rises out of the swamp, wades along and sinks
; again
;
; $B439 first (the colour: +$0C from a cycle of green and cyan by PassCounter &
; 7). State 0: BogManRise. State 1: the hero in its column and below its line:
; DamageHero with C = 2 unless IsShieldUp. +8 under $10: + 2 (mod 16), and at 0
; the base column moves one (MoveBaseX E = -1), removed at column -4 or $1E;
; BogManCheckGround, then 1 in 8 BogManCheckSink. +8 $10 and on: BogManSink.
; The frame is +8 / 2 (BogManFrame). The green figure in the swamp in rzx-r3's
; screen 007024; its 20 frames show a figure wading and then sinking flat.
;
; Witness: L1 553 (rzx-r3).
BogManActor:
  CALL SetGreenCycleColour
  LD A,(IY+$0A)
  CP $00
  JP Z,BogManRise
  LD A,(HeroRecord)
  CP (IY+$00)
  JR NZ,BogManWalk
  LD A,(HeroY)
  CP (IY+$01)
  JR C,BogManWalk
  CALL IsShieldUp
  JP NZ,BogManWalk
  LD C,$02
  CALL DamageHero
BogManWalk:
  LD A,(IY+$08)
  CP $10
  JP NC,BogManSink
  ADD A,$02
  AND $0F
  LD (IY+$08),A
  JR NZ,BogManFrame
  LD E,$FF
  CALL MoveBaseX
  LD A,(IY+$0D)
  CP $FC
  JP Z,RemoveActor
  CP $1E
  JP Z,RemoveActor
  CALL BogManCheckGround
  CALL Random
  AND $07
  JR NZ,BogManFrame
  JP BogManCheckSink

; Show frame +8 / 2 of the bog man's set (SetActorFrame with BogManFrameSet)
;
; Frames 0-7 wading, 8-19 sinking.
;
; Witness: L1 537 (rzx-r3).
BogManFrame:
  LD A,(IY+$08)
  SRL A
  CALL SetActorFrame

; SetActorFrame's inline words: the frame table $DE53, the graphics base $D861
;
; Read by SetActorFrame $AC0A after the CALL at $9208.
BogManFrameSet:
  DEFW BogManFrameTable,BogManSprites

; State 0: rise 12 steps along BogManRiseSteps, then state 1 (+8 = $FF)
;
; Witness: L1 144 (rzx-r3).
BogManRise:
  INC (IY+$0B)
  LD A,(IY+$0B)
  CP $0C
  JR NZ,BogManRiseStep
  LD (IY+$08),$FF
  INC (IY+$0A)
  JP BogManActor
BogManRiseStep:
  LD C,A
  LD B,$00
  LD HL,BogManRiseSteps
  ADD HL,BC
  LD A,(HL)
  ADD A,(IY+$0E)
  LD (IY+$0E),A
  LD (IY+$08),$00
  JP BogManFrame

; The rise's line changes by +$0B 0-11: -5 -4 -4 -3 -3 -2 -2 -1 -1 -1 0 1
;
; Read by BogManRise at $922A (steps 1-11; all 12 bytes read in rzx-r3).
BogManRiseSteps:
  DEFB $FB,$FC,$FC,$FD,$FD,$FE,$FE,$FF
  DEFB $FF,$FF,$00,$01

; +8 $10-$27: sink (frames 8-19), removed at $28
;
; Witness: L1 131 (rzx-r3).
BogManSink:
  INC (IY+$08)
  LD A,(IY+$08)
  CP $28
  JP Z,RemoveActor
  JP BogManFrame

; Three solid cells under the bog man's feet ($B213's test): start sinking (+8
; = $10)
;
; E = the column + 3, D = the line + $40, then $B213 (NZ when the cells at
; columns E, E - 1 and E - 2 of that line are all solid). Z: nothing.
;
; Witness: L1 18 (rzx-r3).
BogManCheckSink:
  LD A,$03
  ADD A,(IY+$00)
  LD E,A
  BIT 7,(IY+$09)
  JR Z,BogManCheckSinkCell
  LD A,$03
  ADD A,(IY+$00)
  LD E,A
BogManCheckSinkCell:
  LD A,(IY+$0E)
  ADD A,$40
  LD D,A
  CALL CellAtSpan3
  JP Z,BogManFrame
  LD (IY+$08),$10
  JP BogManFrame

; No solid cell one column ahead at its feet: BogManCheckSink at once (the
; caller's return dropped)
;
; CellAt with E = the column + 1 (- 1 facing left), D = the line + $40.
;
; Witness: L1 32 (rzx-r3).
BogManCheckGround:
  LD A,$01
  CALL NegateIfFacingLeft
  ADD A,(IY+$00)
  LD E,A
  LD A,(IY+$0E)
  ADD A,$40
  LD D,A
  CALL CellAt
  RET NZ
  POP HL
  JP BogManCheckSink

; Actor handler, kind 4: the water's surface, a 4 x 2 strip that ripples
; through 3 frames
;
; On odd passes +8 = (+8 + 1) mod 3, the image $D310 + 4 x +8, 4 bytes x 2
; lines. Its kind row gives the colour $0D (cyan on blue): the blue water of
; the swamp.
;
; Witness: L1 10338 (rzx-r3, s3-right).
WaterRippleActor:
  LD A,(PassCounter)
  AND $01
  RET Z
  INC (IY+$08)
  LD A,(IY+$08)
  CP $03
  JR NZ,WaterRippleFrame
  XOR A
  LD (IY+$08),A
WaterRippleFrame:
  LD A,(IY+$08)
  SLA A
  SLA A
  LD C,A
  LD B,$00
  LD HL,WaterRipple
  ADD HL,BC
  LD (IY+$04),L
  LD (IY+$05),H
  LD (IY+$02),$04
  LD (IY+$03),$02
  RET

; Actor handler, kind 5: the dragon's head; now and then it opens its jaws and
; breathes fire
;
; Removed when DragonHits is $10 (the dragon dead). Colour 4 (green), $42 (red)
; while DragonHitFlag is 1. State 0: 1 in 8 passes state 1, +$0B = $FF. State
; 1: +$0B + 1 up to $13 (then state 0); DragonBreath = +$0B; the frame
; DragonHeadFrames[+$0B]. Shown with SetActorFrame (DragonHeadSet). The green
; dragon breathing fire in rzx-r3's screens 011012-012128.
;
; Witness: L1 477 (rzx-r3).
DragonHeadActor:
  LD A,(DragonHits)
  CP $10
  JP Z,RemoveActor
  LD (IY+$0C),$04
  LD A,(DragonHitFlag)
  CP $01
  JR NZ,DragonHeadState
  LD (IY+$0C),$42
DragonHeadState:
  LD A,(IY+$0A)
  CP $00
  JR NZ,DragonHeadBreathe
  CALL Random
  AND $07
  CP $03
  JR NZ,DragonHeadDraw
  LD (IY+$0A),$01
  LD (IY+$0B),$FF
DragonHeadBreathe:
  INC (IY+$0B)
  LD A,(IY+$0B)
  CP $13
  JR NZ,DragonHeadStep
  LD (IY+$0A),$00
  JR DragonHeadDraw
DragonHeadStep:
  LD C,A
  LD (DragonBreath),A
  LD B,$00
  LD HL,DragonHeadFrames
  ADD HL,BC
  LD A,(HL)
  LD (IY+$08),A
DragonHeadDraw:
  LD A,(IY+$08)
  CALL SetActorFrame

; SetActorFrame's inline words: the frame table $CCC1, the graphics base $CB10
;
; Read by SetActorFrame $AC0A after the CALL at $930F.
DragonHeadSet:
  DEFW DragonHeadFrameTable,DragonHeadSprites

; The head's frame by breath step 0-$12: 1 1 2 2 3 x 9 2 2 1 1 0 0 (the jaws
; open and close)
;
; Read by DragonHeadActor at $9308.
DragonHeadFrames:
  DEFB $01,$01,$02,$02,$03,$03,$03,$03
  DEFB $03,$03,$03,$03,$03,$02,$02,$01
  DEFB $01,$00,$00

; Actor handler, kind 6: the dragon's flame, shown at breath steps 4-$11
;
; Removed when the dragon is dead. DragonBreath under 4 or $12 and on: hidden
; (BlankIcon 1 x 2 at line $88). Else frame (DragonBreath - 4) / 2 with the
; missile colours (MissileColour $B470), SetActorFrame with DragonFlameSet.
;
; Witness: L1 477 (rzx-r3).
DragonFlameActor:
  LD A,(DragonHits)
  CP $10
  JP Z,RemoveActor
  LD A,(DragonBreath)
  CP $12
  JR NC,DragonFlameHide
  CP $04
  JR NC,DragonFlameShow
DragonFlameHide:
  LD HL,BlankIcon
  LD (IY+$01),$88
  LD (IY+$04),L
  LD (IY+$05),H
  LD (IY+$02),$01
  LD (IY+$03),$02
  RET
DragonFlameShow:
  SUB $04
  SRL A
  LD (IY+$08),A
  CALL MissileColour
  LD (IY+$0C),C
  LD A,(IY+$08)
  CALL SetActorFrame

; SetActorFrame's inline words: the frame table $D08C, the graphics base $CCD9
;
; Read by SetActorFrame $AC0A after the CALL at $9362.
DragonFlameSet:
  DEFW BreathFrameTable,BreathSprites

; Actor handler, kind 7: the castle's drawbridge; item 2 selected lowers it,
; then its cells become floor
;
; Item 2 selected (GetSelectedItem): state 1. $FE5C 1 (down): the four room
; cells at $73EE = 3 (solid), the attributes $5A2E-$5A31 = 7 and the frame 7.
; Else in state 1 the frame +8 + 1 up to 7. At 7: $FE5C = 1. The frame shown is
; +8 / 2 (4 pictures, raised to lowered). The tower's drawbridge coming down in
; rzx-r3's screens 013529-014003.
;
; Witness: L1 120 (rzx-r3).
DrawbridgeActor:
  CALL GetSelectedItem
  CP $02
  JR NZ,DrawbridgeCheck
  LD (IY+$0A),$01
DrawbridgeCheck:
  LD A,(DrawbridgeDown)
  CP $01
  JR NZ,DrawbridgeLower
  LD HL,CellsDrawbridge
  LD (HL),$03
  INC L
  LD (HL),$03
  INC L
  LD (HL),$03
  INC L
  LD (HL),$03
  LD HL,Attributes+558
  LD (HL),$07
  INC L
  LD (HL),$07
  INC L
  LD (HL),$07
  INC L
  LD (HL),$07
  LD (IY+$08),$07
  JP DrawbridgeFrame
DrawbridgeLower:
  LD A,(IY+$0A)
  CP $00
  JP Z,DrawbridgeFrame
  LD A,(IY+$08)
  CP $07
  JP Z,DrawbridgeFrame
  INC (IY+$08)
DrawbridgeFrame:
  LD A,(IY+$08)
  CP $07
  JR NZ,DrawbridgeDraw
  LD A,$01
  LD (DrawbridgeDown),A
  LD A,$07
DrawbridgeDraw:
  SRL A
  CALL SetActorFrame

; SetActorFrame's inline words: the frame table $C73C, the graphics base $C5D0
;
; Read by SetActorFrame $AC0A after the CALL at $93C1.
DrawbridgeSet:
  DEFW DrawbridgeFrameTable,DrawbridgeSprites

; Actor handler, kinds 8 and 9: a flame of the funeral pyre; it dies down when
; $FE5D becomes 1
;
; $FE5D (the pyre's state) 2 and on: removed. $FE5D 1 and the state not 1:
; state 1, +$0B = 6. Colour ColourRedYellow; frame a random 0-5. State 1: on
; every other pass (PassCounter + the column even) +$0B - 1 (removed at 0) and
; the line + 2: the flames sink. Shown with SetActorFrame (PyreFlameSet). The
; yellow flames round the pyre in rzx-r3's screen 008576.
;
; Witness: L1 466 (rzx-r3).
PyreFlameActor:
  LD A,(PyreState)
  CP $02
  JP NC,RemoveActor
  CP $01
  JR NZ,PyreFlameColour
  LD A,(IY+$0A)
  CP $01
  JR Z,PyreFlameColour
  LD (IY+$0B),$06
  LD (IY+$0A),$01
PyreFlameColour:
  CALL ColourRedYellow
  LD (IY+$0C),C
PyreFlameFrame:
  CALL Random
  AND $07
  CP $06
  JR NC,PyreFlameFrame
  LD (IY+$08),A
  LD A,(IY+$0A)
  CP $00
  JP Z,PyreFlameDraw
  LD A,(PassCounter)
  ADD A,(IY+$00)
  AND $01
  JP NZ,PyreFlameDraw
  DEC (IY+$0B)
  JP Z,RemoveActor
  LD A,(IY+$0E)
  ADD A,$02
  LD (IY+$0E),A
PyreFlameDraw:
  LD A,(IY+$08)
  CALL SetActorFrame

; SetActorFrame's words after the CALL at `$9419`: the frame table `$C7F0`, the
; graphics base PyreFlameSprites `$C754`
;
; Read by SetActorFrame `$AC0A` each time a pyre flame is drawn (458 times in
; rzx-r3).
PyreFlameSet:
  DEFW PyreFlameFrameTable,PyreFlameSprites

; Placement kind 10: the funeral pyre's bier; sinks into the ground once the
; body has risen
;
; IY = the actor (kind 10 of the kinds table at `$9BFB`: handler word at
; `$9C56`, opaque, attribute `$46` bright yellow, +$0B = `$0C`, +$0F bit 7:
; drawn in the second pass, over the body). Grid 1 room 5 has one (placement at
; X `$7C`, Y 8 of the list at `$9B8F`), with the body PyreBodyActor and the
; four flames of kinds 8 and 9 (PyreFlameActor `$93C8`) around them: the yellow
; box with the body on it in rzx-r3's screen 008576.
;
; By PyreState `$FE5D`: 4 (the body is gone) frees the record (RemoveActor
; `$B3F8`). 3 (the body rises): +$0B counts down `$0C` passes, then the bier
; sinks one line a pass; at line `$40` it drops its item (PyreDropItem), at
; line `$50` it is freed. Every pass it shows frame 0 of PyreSet (SetActorFrame
; `$AC0A`).
;
; Output: none. Called by RunActorHandlers `$A7BB` through the record's +6/+7.
;
; Witness: L1 214 (rzx-r3).
PyreBierActor:
  LD A,(PyreState)
  CP $04
  JP Z,RemoveActor
  CP $03
  JR NZ,PyreBierShow
  LD A,(IY+$0B)
  CP $00
  JR Z,PyreBierSink
  DEC (IY+$0B)
  JR PyreBierShow
PyreBierSink:
  LD A,(IY+$0E)
  CP $40
  CALL Z,PyreDropItem
  CP $50
  JP Z,RemoveActor
  INC (IY+$0E)
PyreBierShow:
  XOR A
  CALL SetActorFrame

; SetActorFrame's words after the CALL at `$9449`: the frame table `$C909`, the
; graphics base `$C814`
;
; Frame 0 the bier (5 x 15), frames 1-3 the body lying (5 x 11, 5 x 11, 5 x
; 12). Read by SetActorFrame `$AC0A` (the return address it pops).
PyreBierSet:
  DEFW BierFrameTable,BierSprites

; Drop the bier's item: item kind 2, amount 1, at column `$0F`, line `$68`
;
; SpawnItem `$A081` with D = `$0F`, E = `$68`, H = 1 (the amount), L = 2 (the
; kind), BC = `$EA00` (its icon frame). Called once by PyreBierActor when the
; sinking bier passes line `$40`.
;
; Witness: L1 1 (rzx-r3).
PyreDropItem:
  LD BC,ItemIconSprites
  LD D,$0F
  LD E,$68
  LD H,$01
  LD L,$02
  JP SpawnItem

; Placement kind 11: the body on the pyre; rises out of the room once the rain
; has put the flames out
;
; IY = the actor (kind 11: handler word at `$9C5F`, frame 1, opaque, white).
; PyreState `$FE5D` 4 frees it. While +$0A is 0 it lies still; when PyreState
; is 2 (set by UpdateRain `$A41E` at the rain's step `$64`) and the hero's
; column `$74E0` is at or right of the body's, PyreState becomes 3 and +$0A 1.
; From then on the body animates (frames 1, 2, 3, 1, ...) and rises one line a
; pass; at line `$DC` (gone over the top) PyreState becomes 4, which frees it
; and the bier. Frame +8 of the set at `$94A8`.
;
; rzx-r3 set PyreState 3 once (`$947E`) and 4 once (`$949F`); the rise took 100
; passes (`$9492`).
;
; Witness: L1 286 (rzx-r3).
PyreBodyActor:
  LD A,(PyreState)
  CP $04
  JP Z,RemoveActor
  LD A,(IY+$0A)
  CP $00
  JR NZ,PyreBodyRise
  LD A,(PyreState)
  CP $02
  JR NZ,PyreBodyShow
  LD A,(HeroRecord)
  CP (IY+$00)
  JR C,PyreBodyShow
  LD A,$03
  LD (PyreState),A
  INC (IY+$0A)
PyreBodyRise:
  INC (IY+$08)
  LD A,(IY+$08)
  CP $04
  JR NZ,PyreBodyMove
  LD (IY+$08),$01
PyreBodyMove:
  LD A,(IY+$0E)
  DEC A
  LD (IY+$0E),A
  CP $DC
  JR NZ,PyreBodyShow
  LD A,$04
  LD (PyreState),A
PyreBodyShow:
  LD A,(IY+$08)
  CALL SetActorFrame

; SetActorFrame's words after the CALL at `$94A5`: the same frame table `$C909`
; and base `$C814` as PyreBierSet
;
; Read by SetActorFrame `$AC0A`.
PyreBodySet:
  DEFW BierFrameTable,BierSprites

; Placement kind 12: the lightning bolt of the longship's storm (grid 0, one a
; room)
;
; IY = the actor (kind 12: handler word at `$9C68`, opaque, white, +$0B = 2).
; Grid 0's placements (`$9B62`) put one in each of its rooms at line 0. Its
; shape follows LightningState `$FE59` (stepped by LightningStep `$A588`): the
; record's image +4/+5, width +2 and height +3 are LightningFrames[state]:
; states 0-3 the bolt growing down (2 x `$18`, 2 x `$30`, 2 x `$48`, 3 x `$68`
; lines), state 4 the blank 1 x 1 image `$8A44` (no bolt). In state 4 the
; column is a random 4-`$19` each pass (Random `$8A26`). In state 0 the counter
; +$0B decides whether this flash shows a bolt: while it is not 0 it counts
; down and the bolt is put at column `$1E`, outside the play area (two flashes
; of three), at 0 it is set to 2 again and the bolt stays at the column chosen
; in state 4.
;
; No SetActorFrame: the record's +0/+1 are the bolt's top left. Called by
; RunActorHandlers `$A7BB`.
;
; The bolt in the sky over the longship: rzx-r3 screen 002625.
;
; Witness: L1 2393 (rzx-r3, s3-right).
LightningActor:
  LD A,(LightningState)
  CP $00
  JR NZ,LightningActorColumn
  LD A,(IY+$0B)
  CP $00
  JR Z,LightningActorReset
  DEC (IY+$0B)
  LD (IY+$00),$1E
  JR LightningActorShape
LightningActorReset:
  LD (IY+$0B),$02
LightningActorColumn:
  LD A,(LightningState)
  CP $04
  JR NZ,LightningActorShape
LightningActorRandom:
  CALL Random
  AND $1F
  CP $04
  JR C,LightningActorRandom
  CP $1A
  JR NC,LightningActorRandom
  LD (IY+$00),A
LightningActorShape:
  LD A,(LightningState)
  SLA A
  SLA A
  LD C,A
  LD B,$00
  LD HL,LightningFrames
  ADD HL,BC
  LD A,(HL)
  LD (IY+$04),A
  INC HL
  LD A,(HL)
  LD (IY+$05),A
  INC HL
  LD A,(HL)
  LD (IY+$02),A
  INC HL
  LD A,(HL)
  LD (IY+$03),A
  RET

; LightningActor's five shapes: the image address, the width in bytes, the
; height in lines
;
; Indexed by LightningState x 4. Read by LightningActor `$94AC` (all 20 bytes
; in rzx-r3).
LightningFrames:
  DEFB $F5,$C1,$02,$18    ; state 0: `$C1F5`, 2 x `$18`
  DEFB $25,$C2,$02,$30    ; state 1: `$C225`, 2 x `$30`
  DEFB $85,$C2,$02,$48    ; state 2: `$C285`, 2 x `$48`
  DEFB $15,$C3,$03,$68    ; state 3: `$C315`, 3 x `$68`
  DEFB $44,$8A,$01,$01    ; state 4: the blank `$8A44`, 1 x 1 (no bolt)

; Grid 2's boss: the giant on the throne; draw it, colour it, shoot, count the
; hits, die at 30
;
; Called every main-loop pass (`$7874`); nothing unless GridNumber is 2 (the
; castle's hall). ThroneBossHits `$FE65`: `$1E` the 30th hit, ThroneBossBeaten
; `$A02A`; `$1F` beaten, nothing more.
;
; Else it draws the seated giant into the play buffer, the row-packed picture
; `$C44D` (DrawRowPicture `$89A4`, `$4F` lines from `$5F18`: line 32, column
; `$18`). Without a hit (ThroneHitFlag `$FE66` not 1) the 5 x 10 attribute mask
; `$C59E` is copied into the shadow from `$6E59` (row 10, column `$19`), the
; bytes `$FF` skipped; then every 8th pass (PassCounter AND 7 = 0) it throws a
; missile of kind 4 (AddMissile `$B32B`: D = `$1A`, E = `$50`, B = a random 0-3
; direction, C = 4). With a hit (`$FE66` = 1, set by the missile handler
; `$821F` when the hero's thrown kind-7 item reaches it): `$FE66` = 0,
; ThroneBossHits + 1, and the mask's cells are painted bright red (`$42`) for
; that pass instead.
;
; The giant and its sparks: rzx-r3 screen 014505.
;
; Witness: L1 6278 (rzx-r3, s3-right).
ThroneBossStep:
  LD A,(GridNumber)
  CP $02
  RET NZ
  LD A,(ThroneBossHits)
  CP $1E
  JP Z,ThroneBossBeaten
  CP $1F
  RET Z
  LD HL,ThronePicture
  LD DE,PlayBuffer+1048
  LD B,$4F
  CALL DrawRowPicture
  LD A,(ThroneHitFlag)
  CP $01
  JR Z,ThroneBossHit
  LD HL,ThroneAttributes
  LD DE,ThroneAttributesCell
  LD B,$0A
ThroneBossColourRow:
  PUSH BC
  PUSH DE
  LD B,$05
ThroneBossColourCell:
  LD A,(HL)
  CP $FF
  JR Z,ThroneBossColourNext
  LD (DE),A
ThroneBossColourNext:
  INC E
  INC HL
  DJNZ ThroneBossColourCell
  POP DE
  EX DE,HL
  LD BC,$0020
  ADD HL,BC
  EX DE,HL
  POP BC
  DJNZ ThroneBossColourRow
  JR ThroneBossShoot
ThroneBossHit:
  XOR A
  LD (ThroneHitFlag),A
  LD A,(ThroneBossHits)
  CP $1E
  RET Z
  INC A
  LD (ThroneBossHits),A
  LD HL,ThroneAttributes
  LD DE,ThroneAttributesCell
  LD B,$0A
ThroneBossFlashRow:
  PUSH BC
  PUSH DE
  LD B,$05
ThroneBossFlashCell:
  LD A,(HL)
  CP $FF
  JR Z,ThroneBossFlashNext
  LD A,$42
  LD (DE),A
ThroneBossFlashNext:
  INC E
  INC HL
  DJNZ ThroneBossFlashCell
  POP DE
  EX DE,HL
  LD BC,$0020
  ADD HL,BC
  EX DE,HL
  POP BC
  DJNZ ThroneBossFlashRow
  RET
ThroneBossShoot:
  LD A,(PassCounter)
  AND $07
  RET NZ
  CALL Random
  AND $03
  LD B,A
  LD D,$1A
  LD E,$50
  LD C,$04
  JP AddMissile

  ORG $A9B6

; Carry when |E - D| is under A
;
; In: A the limit, D and E the two values. Out: A = |E - D|, carry set when it
; is under the limit. It stores the
;
; limit into its own compare at AbsDiffLimit $A9BF. Used for the distances
; between the hero and an actor (reach,
;
; pick-up) by the strikeable actors, the fragments and the routines of the
; other modules.
;
; Stage 1's AbsDiffBelow at $A7B8 is the same code.
;
; Witness: L1 1760 (rzx-r3).
AbsDiffBelow:
  LD (AbsDiffLimit+$0001),A
  LD A,E
  SUB D
  JR NC,AbsDiffLimit
  NEG
AbsDiffLimit:
  CP $00                  ; the limit, written by the first instruction
  RET

; Placement kinds 0-3: an urn or chest that the hero's strike breaks (two
; hits), with an item or fragments inside
;
; The handler word of kinds 0-3 (`$9BFC`, `$9C05`, `$9C0E`, `$9C17`, frames 6,
; 4, 2, 0: the even frame intact, the odd one damaged). IY = the actor. When
; the hero's strike lands this pass (IsHeroHitFrame6 `$7FE9`: Z) and
; InStrikeReach `$AA19` says the actor is in front of him, the hit count +8
; (also the frame) goes up: odd, effect 2 and the damaged frame; even,
; ScoreBurst20 `$A04E` (score and explosion), MarkPlacementDone `$A68C` (it
; does not come back), then by +$10 (the placement's index) AND 3: 2
; DropItemKind7Or1 `$A0DA`, 1 or 3 DropItemKind9Or8 `$A0AC`, 0 eight fragments
; (ShatterActor `$AA06`).
;
; Each pass it shows frame +8 of StrikeableActorSet (SetActorFrame `$AC0A`).
;
; Witness: L1 2609 (rzx-r3).
StrikeableActor:
  CALL IsHeroHitFrame6
  JR NZ,StrikeableActorFrame
  CALL InStrikeReach
  JR NZ,StrikeableActorFrame
  INC (IY+$08)
  LD A,(IY+$08)
  AND $01
  JR Z,StrikeableActorDies
  LD DE,$0002
  CALL PlaySoundVector
  JP StrikeableActorFrame
StrikeableActorDies:
  CALL ScoreBurst20       ; the second hit: score, explosion, the done mark,
                          ; then the drop by +$10
  CALL MarkPlacementDone
  LD A,(IY+$10)
  AND $03
  CP $02
  JP Z,DropItemKind7Or1
  CP $01
  JP Z,DropItemKind9Or8
  CP $03
  JP Z,DropItemKind9Or8
  JP ShatterActor
StrikeableActorFrame:
  LD A,(IY+$08)
  CALL SetActorFrame

; SetActorFrame's words: the frame table `$E0B9`, the graphics base `$DFEF`
;
; Read by SetActorFrame `$AC0A` after the CALL at `$A9FF`.
StrikeableActorSet:
  DEFW StrikeableFrameTable,StrikeableSprites

; Burst the actor into eight fragments and remove it
;
; IY = the actor. B = its column, C = its line rounded down to 8, +5;
; SpawnFragments $AA49 with D = 8, then
;
; RemoveActor $B3F8.
;
; Stage 1's ShatterActor at $A803 is the same code.
;
; Witness: L1 2 (rzx-r3).
ShatterActor:
  LD B,(IY+$00)
  LD A,(IY+$01)
  AND $F8
  ADD A,$05
  LD C,A
  LD D,$08
  CALL SpawnFragments
  JP RemoveActor

; Z when the actor IY stands where the hero's strike lands
;
; The actor's column must be the hero's column $74E0 + 2 when the hero faces
; right ($74E9 bit 7 clear), - 2 when
;
; he faces left, and its line within 24 ($18) of the hero's line $74E1
; (AbsDiffBelow $A9B6). Out: Z (ReturnZ
;
; $B37A) in reach, NZ (ReturnNZ $B37F) not.
;
; Stage 1's InStrikeReach at $A816, the same instructions; the operands that
; differ: the reach, 2 columns here (SUB 2 at $AA26, ADD 2 at $AA30; stage 1:
; 3), and the addresses of AbsDiffBelow, ReturnZ and ReturnNZ ($AA3E, $AA43,
; $AA46).
;
; Witness: L1 28 (rzx-r3).
InStrikeReach:
  LD E,(IY+$00)
  LD A,(HeroFlags)
  BIT 7,A
  JR Z,InStrikeReachRight
  LD A,(HeroRecord)
  SUB $02
  CP E
  JR Z,InStrikeReachLine
  JR InStrikeReachMiss
InStrikeReachRight:
  LD A,(HeroRecord)
  ADD A,$02
  CP E
  JR NZ,InStrikeReachMiss
InStrikeReachLine:
  LD E,(IY+$01)
  LD A,(HeroY)
  LD D,A
  LD A,$18
  CALL AbsDiffBelow
  JR NC,InStrikeReachMiss
  JP ReturnZ
InStrikeReachMiss:
  JP ReturnNZ

; Start D fragment actors at column B, line C
;
; Seeds the random pointer RandomPointer $FE0A with $07CF (so every burst looks
; the same), writes B and C into the
;
; LD D / LD E at FragmentColumn $AA60 and FragmentLine $AA62, and for each of
; the D fragments takes a free actor
;
; record (FindFreeActor $8BE3; it stops quietly when none is free), random
; parameters (RandomFragmentParams $AA70)
;
; and starts it (InitFragment $AA7E). IY is kept.
;
; Stage 1's SpawnFragments at $A846 is the same code.
;
; Witness: L1 2 (rzx-r3).
SpawnFragments:
  LD HL,$07CF
  LD (RandomPointer),HL
  LD A,B
  LD (FragmentColumn+$0001),A
  LD A,C
  LD (FragmentLine+$0001),A
  PUSH IY
  LD B,D
SpawnFragmentsLoop:
  PUSH BC
  CALL FindFreeActor
  JR NZ,SpawnFragmentsNext
FragmentColumn:
  LD D,$00                ; LD D,n: n = the column, written by SpawnFragments
FragmentLine:
  LD E,$00                ; LD E,n: n = the line, written by SpawnFragments
  CALL RandomFragmentParams
  CALL InitFragment
SpawnFragmentsNext:
  POP BC
  DJNZ SpawnFragmentsLoop
  POP IY
  RET

; B = its arc (0-3), C = its speed (0-3), A = its facing (bit 7)
;
; From two Random $8A26 bytes: B = the first AND 3, C = the second AND 3, A =
; the second AND $80.
;
; Stage 1's RandomFragmentParams at $A86D is the same code.
;
; Witness: L1 15 (rzx-r3).
RandomFragmentParams:
  CALL Random
  AND $03
  LD B,A
  LD A,(HL)
  AND $03
  LD C,A
  LD A,(HL)
  AND $80
  RET

; Fill the actor record IY as a fragment and run its first step
;
; Copies the fragment template $9CA6 into the record (InitActor $A6AF with D, E
; the column and line), then the
;
; record's +9 = A (facing), +$0A = B (the arc), +8 = C (the speed in pixels a
; step), and goes on into FragmentActor.
;
; Called by SpawnFragments ($AA67), once a fragment.
;
; Stage 1's InitFragment at $A87B is the same code.
;
; Witness: L1 15 (rzx-r3).
InitFragment:
  PUSH BC
  PUSH AF
  LD HL,FragmentTemplate
  CALL SpawnActor
  POP AF
  POP BC
  LD (IY+$09),A
  LD (IY+$0A),B
  LD (IY+$08),C
  JP FragmentActor

; Per-pass handler of a fragment: fly an arc, land, lie, sink, be picked up
;
; The handler word of the fragment template `$9CA6` (`$9CAC`). IY = the
; fragment. Its colour alternates (ColourRedMagenta `$B411`). The step counter
; +$0B runs from 0: steps 5, `$0E`, `$14` and `$17` play effect 3 (a bounce);
; each step moves it +8 pixels a pass across (MoveFragment `$AB82`, reversed
; when facing left) and down by the step's entry of FragmentArc0 `$ABD2` (arc
; +$0A = 0) or FragmentArc1 `$ABEE` (other arcs; doubled when +$0A bit 1 is
; set); from step `$18` it no longer moves across. At steps 9, `$10`, `$15` and
; `$17` it looks at the cell under it (column + 2, line + `$16`, `$14`, `$14`
; or `$0E`; CellAt `$B1F6`): no solid ground there makes it fall (step `$1C`: 7
; lines a pass, removed at line `$90` and below). Step `$1B` is the rest
; (FragmentRest): +$0E counts down; under 6 it sinks 3 lines a pass and at 0 it
; is removed. A fragment the hero touches (its column the hero's + 1, + 0 or -
; 1, his line within `$20`) is taken: EnergyChange `$FE51` + 6, AddScore
; `$7B41` 25, effect 5, and it is removed.
;
; The same job as stage 1's FragmentActor; stage 3's touch test takes three
; columns (stage 1 two). rzx-r3 broke two urns into fragments (ShatterActor 2
; runs) and took 9 fragments.
;
; Witness: L1 1239 (rzx-r3).
FragmentActor:
  CALL ColourRedMagenta
  LD (IY+$0C),C
  LD A,(IY+$0B)
  CP $1C
  JP Z,FragmentFall
  CP $1B
  JR Z,FragmentRest
  INC (IY+$0B)
  LD A,(IY+$0B)
  CP $05
  JR Z,FragmentBounce
  CP $0E
  JR Z,FragmentBounce
  CP $14
  JR Z,FragmentBounce
  CP $17
  JR NZ,FragmentStep
FragmentBounce:
  LD DE,$0003
  CALL PlaySoundVector
FragmentStep:
  LD C,(IY+$0B)
  LD B,$00
  LD HL,FragmentArc0
  LD A,(IY+$0A)
  CP $00
  JR Z,FragmentArcEntry
  LD HL,FragmentArc1
FragmentArcEntry:
  ADD HL,BC
  LD A,(IY+$0B)
  CP $18
  JR C,FragmentDrop
  LD E,$00
  JR FragmentMove
FragmentDrop:
  LD E,(IY+$08)
  LD A,(IY+$01)
  ADD A,(HL)
  BIT 1,(IY+$0A)
  JR Z,FragmentSetLine
  ADD A,(HL)
FragmentSetLine:
  LD (IY+$01),A
FragmentMove:
  CALL MoveFragment
  LD A,(IY+$0B)
  LD C,$16
  CP $09
  JR Z,FragmentGround
  LD C,$14
  CP $10
  JR Z,FragmentGround
  CP $15
  JR Z,FragmentGround
  LD C,$0E
  CP $17
  RET NZ
FragmentGround:
  LD A,(IY+$00)
  ADD A,$02
  LD E,A
  LD A,(IY+$01)
  ADD A,C
  LD D,A
  CALL CellAt
  RET NZ
  LD (IY+$0B),$1C
  RET
FragmentRest:
  LD A,(IY+$0E)
  CP $00
  JR Z,FragmentTouch
  DEC A
  LD (IY+$0E),A
  CP $06
  JR NC,FragmentTouch
  CP $00
  JP Z,RemoveActor
  LD A,(IY+$01)
  ADD A,$03
  LD (IY+$01),A
FragmentTouch:
  LD A,(HeroRecord)
  INC A
  LD E,A
  LD A,(IY+$00)
  CP E
  JR Z,FragmentTouchLine
  DEC E
  CP E
  JR Z,FragmentTouchLine
  DEC E
  CP E
  RET NZ
FragmentTouchLine:
  LD A,(HeroY)
  LD E,A
  LD D,(IY+$01)
  LD A,$20
  CALL AbsDiffBelow
  RET NC
  LD A,(EnergyChange)
  ADD A,$06
  LD (EnergyChange),A
  LD BC,$0019
  CALL AddScore
  LD DE,$0005
  CALL PlaySoundVector
  JP RemoveActor
FragmentFall:
  LD A,(IY+$01)
  ADD A,$07
  LD (IY+$01),A
  CP $90
  JP NC,RemoveActor
  LD E,(IY+$08)

; Move the fragment E pixels across and point it at its pre-shifted image
;
; IY = the fragment, E = the pixels (negated when it faces left, +9 bit 7). The
; pixel column (+0 x 8 + the
;
; sub-column +$0D) moves by E; +0 and +$0D take the new column and pixel. The
; image pointer +4/+5 = $E8F8 + $21 x
;
; the shift (Multiply $89C5; the shift is the pixel, or 7 - the pixel when it
; faces left): eight pre-shifted copies
;
; of 33 bytes. A fragment that reaches column 0 or 31 is removed (RemoveActor
; $B3F8).
;
; Stage 1's MoveFragment at $A97A is the same code.
;
; Witness: L1 415 (rzx-r3).
MoveFragment:
  LD A,(IY+$00)
  SLA A
  SLA A
  SLA A
  ADD A,(IY+$0D)
  LD D,A
  LD A,E
  BIT 7,(IY+$09)
  JR Z,MoveFragmentColumn
  NEG
MoveFragmentColumn:
  ADD A,D
  LD D,A
  AND $07
  LD (IY+$0D),A
  SRL D
  SRL D
  SRL D
  LD (IY+$00),D
  LD A,(IY+$0D)
  BIT 7,(IY+$09)
  JR Z,MoveFragmentImage
  LD C,A
  LD A,$07
  SUB C
MoveFragmentImage:
  LD B,$21
  CALL Multiply
  LD BC,FragmentSprites
  ADD HL,BC
  LD (IY+$04),L
  LD (IY+$05),H
  LD A,(IY+$00)
  CP $01
  JP C,RemoveActor
  CP $1F
  JP NC,RemoveActor
  RET

; The line change of each step of a fragment's arc 0 (28 signed bytes)
;
; Read by FragmentActor `$AA94` (+$0B the step): up 8, 6, 4, 2, 1 lines, then
; down 1, 2, 4, 6, 8, a short second hop and the rest. rw3.py: 48 of the 56
; bytes of both arcs read in rzx-r3.
FragmentArc0:
  DEFB $F8,$FA,$FC,$FE,$FF,$00,$01
  DEFB $02,$04,$06,$08,$FC,$FE,$FF
  DEFB $00,$01,$02,$04,$FE,$FF,$00
  DEFB $01,$02,$00,$00,$01,$01,$00
FragmentArc1:
  DEFB $FB,$FC,$FD,$FE,$FF,$00,$01 ; the arcs 1-3 (doubled for 2 and 3): a
  DEFB $02,$03,$04,$05,$FD,$FE,$FF ; lower hop
  DEFB $00,$01,$02,$03,$FE,$FF,$00
  DEFB $01,$02,$00,$00,$01,$01,$00

  ORG $B244

; Eight missiles from the actor IY: four of kind 4 at its right, four of kind 5
; at its left (no caller)
;
; D = column + 3, E = line + `$14`: kind 4 with B = `$FF`, 1, 3, 4 at the
; columns D, D + 1, D, D - 1; then D = column - 2: kind 5 with B = `$FF`, 1, 3,
; 4 at D, D - 1, D, D + 1 (AddMissile `$B32B`; A, the missiles' +5, as the
; caller left it). Stage 1's BossBurst (the winged demon's burst) did the same
; with effect 6; stage 3 has no code reaching it (ref search: no CALL, JP or
; word `$B244`; rw3.py: 0 reads).
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
; known only from the code.
BossBurst:
  LD A,(IY+$00)
  ADD A,$03
  LD D,A
  LD A,(IY+$01)
  ADD A,$14
  LD E,A
  LD C,$04
  LD B,$FF
  CALL AddMissile
  INC D
  LD B,$01
  CALL AddMissile
  DEC D
  LD B,$03
  CALL AddMissile
  DEC D
  LD B,$04
  CALL AddMissile
  LD A,(IY+$00)
  SUB $02
  LD D,A
  LD C,$05
  LD B,$FF
  CALL AddMissile
  DEC D
  LD B,$01
  CALL AddMissile
  INC D
  LD B,$03
  CALL AddMissile
  INC D
  LD B,$04
  CALL AddMissile
  RET

; Four missiles of kind 5 from the actor IY (no caller)
;
; D = column + 3, E = line + 4: B = 1; then D - 1, E + 2: B = 2, 3; then D + 1:
; B = 4 (AddMissile `$B32B`). Stage 1's BossShots added pairs of kind 5 with
; effect 8. No CALL, JP or word in the image reaches `$B289`.
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
; known only from the code.
BossShots:
  LD A,(IY+$00)
  ADD A,$03
  LD D,A
  LD A,(IY+$01)
  ADD A,$04
  LD E,A
  LD C,$05
  LD B,$01
  CALL AddMissile
  DEC D
  LD A,E
  ADD A,$02
  LD E,A
  LD B,$02
  CALL AddMissile
  LD B,$03
  CALL AddMissile
  INC D
  LD B,$04
  CALL AddMissile
  RET

; A shot of type 2 at the actor IY with a random +5 ($FA asks AddMissile for
; one); effect 6
;
; No CALL, JP or word in the image reaches it.
;
; Stage 1's AimedShot at $B214 is the same code.
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
; known only from the code.
AimedShot:
  LD A,(IY+$01)
  LD E,A
  LD A,(IY+$00)
  LD D,A
  LD C,$02
  LD B,$01
  LD A,$FA
  CALL AddMissile
  LD DE,$0006
  JP PlaySoundVector
