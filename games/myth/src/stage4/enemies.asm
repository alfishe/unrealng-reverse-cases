; --------------------------------------------------------------------------------------------------------------------
; enemies.asm: The enemies, the hazards and the bosses
; --------------------------------------------------------------------------------------------------------------------

  ORG $8260

; A piece of the artefact: takes 6 hits, rises, bobs and then waits to be taken
; (1200 points)
;
; IY = the actor (18-byte record). Colour from the cycle (SetCycleColour
; $B5A8). +$0B not 0 (the sparkle record): frames 2-9 in turn. Else by +$0A: 6
; PieceRises, 7 PieceWaitsPickup; 0-5: each hit (+$09 bit 4, set by a shot or
; the hero's blow) clears the flag and adds 1 to +$0A; at 6 the next record's
; +0 is set $FF (the sparkle freed). Frame 0 otherwise. As stage 1's
; UpdatePieceActor `$8233`.
;
; Witness: L1 2415 (rzx-r4).
UpdatePieceActor:
  CALL SetCycleColour
  LD A,(IY+$0B)
  CP $00
  JR NZ,PieceActorAnimate
  LD A,(IY+$0A)
  CP $06
  JR Z,PieceRises
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
  LD A,$00
  JR PieceActorDraw
PieceActorAnimate:
  LD A,(IY+$08)
  INC A
  AND $07
  LD (IY+$08),A
  ADD A,$02

; PieceActorDraw
;
; Used by the routines at UpdatePieceActor, PieceRises and PieceWaitsPickup.
PieceActorDraw:
  CALL SetActorFrame

; SetActorFrame's inline words: the frame table $E367 and the graphics base
; $E27F
;
; Ten frame records: 0 and 1 the piece (2 x 14), 2-9 the sparkle. Read by
; SetActorFrame $ABBD after the CALL at $829D. Read in rzx-r4.
PieceFrames:
  DEFW $E367,PieceSprites

; State 6: rise and bob along RiseSteps for 30 steps (effect 3 at steps 16 and
; 25), then state 7
;
; +8 + 1 a pass, StartTrapChain, y +$0E += RiseSteps[+8]; at step $1E state 7
; (PieceRisesDone). PlaySoundVector 3 at steps $10 and $19.
;
; Witness: L1 155 (rzx-r4).
PieceRises:
  INC (IY+$08)
  CALL StartTrapChain
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
; Read by PieceRises $82C6 (+ the step). Ten 0s, then up 1 to 6, down 4 to up
; 4, down 2 to up 2. Read in rzx-r4.
RiseSteps:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$01,$02,$03,$04,$05,$06
  DEFB $FC,$FD,$FE,$FF,$00,$01,$02,$03
  DEFB $04,$FE,$FF,$00,$01,$02

; Grid 3: when a rising piece reaches step $0A, start the chain of grid 3's
; traps
;
; Only in grid 3 (GridNumber) and at +8 = $0A: TrapChainTimer = $1C. Called by
; PieceRises $82A7.
;
; Witness: L1 155 (rzx-r4).
StartTrapChain:
  LD A,(GridNumber)
  CP $03
  RET NZ
  LD A,(IY+$08)
  CP $0A
  RET NZ
  LD A,$1C
  LD (TrapChainTimer),A
  RET

; While TrapChainTimer runs: set grid 3's trap slots 6 to 0 to 1, one every 4
; passes
;
; Every pass (MainLoop $7852). TrapChainTimer 0: nothing. Else - 1, and the
; slot $9DDB + TrapChainTimer / 4 (grid 3's slots, TrapSlotAddress) = 1: the
; switched traps of grid 3 go off one after another.
;
; Witness: L1 8619 (rzx-r4, s4-right).
;
; In s4-right TrapChainTimer stayed 0; in rzx-r4 the chain ran once (28 passes,
; grid 3).
TrapChainStep:
  LD A,(TrapChainTimer)
  CP $00
  RET Z
  DEC A
  LD (TrapChainTimer),A
  SRL A
  SRL A
  LD C,A
  LD B,$00
  LD HL,TrapSlotsGrid3
  ADD HL,BC
  LD (HL),$01
  RET

; Every pass: in grids 3, 4 and 5 a triggered slot sets its linked slots
;
; Grid 3: slot 12 ($9DE7) = 1 when any of slots 12-15 is not 0. Grid 4: when
; any of slots 5-10 ($9DF0-$9DF5) is not 0, all six = 1. Grid 5: when slot 4
; ($9DFF) is not 0, slots 4-6 = 1. A slot of 2 (done) in a linked group is set
; back to 1 too. Called by MainLoop $7858.
;
; Witness: L1 8619 (rzx-r4, s4-right).
;
; In s4-right GridNumber was 0 every pass. In rzx-r4 the grid-3 link ran (1047
; passes, 473 with a slot set); the grid-4 and grid-5 links tested their slots
; (1581 and 1308 passes) but never found one set, so their set loops $8356 and
; $8368 are known only from the code.
LinkTrapSlots:
  LD A,(GridNumber)
  CP $04
  JP Z,LinkGrid4
  CP $05
  JP Z,LinkGrid5
  CP $03
  RET NZ
  LD HL,TrapSlotsGrid3Linked
  LD B,$03
  LD A,(HL)
LinkGrid3Sum:
  INC HL
  ADD A,(HL)
  DJNZ LinkGrid3Sum
  CP $00
  JP Z,LinkGrid3Set
  LD A,$01
LinkGrid3Set:
  LD (TrapSlotsGrid3Linked),A
  RET
LinkGrid4:
  LD HL,TrapSlotsGrid4Linked
  LD B,$06
  XOR A
LinkGrid4Sum:
  ADD A,(HL)
  INC HL
  DJNZ LinkGrid4Sum
  CP $00
  RET Z
  LD HL,TrapSlotsGrid4Linked
  LD B,$06
LinkGrid4Set:
  LD (HL),$01
  INC HL
  DJNZ LinkGrid4Set
  RET
LinkGrid5:
  LD HL,TrapSlotsGrid5Linked
  LD A,(HL)
  CP $00
  RET Z
  LD HL,TrapSlotsGrid5Linked
  LD B,$03
LinkGrid5Set:
  LD (HL),$01
  INC HL
  DJNZ LinkGrid5Set
  RET

; State 7: when the hero touches it at its column (or the next): 1200 points,
; the piece's bit, freed
;
; HeroWithinY $A37A (C = $14); then the hero's x ($74E0) equal to +0 or +0 + 1:
; AddScore 1200, PieceTakenFlag = 1, PiecesMask |= +$10, freed (RemoveActor
; $B520). Else frame 0. As in stage 1 at `$82CC`.
;
; Witness: L1 299 (rzx-r4).
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

  ORG $8629

; Kind 4: the water's surface, three frames of 4 x 2 bytes in turn
;
; IY = the actor. Every other pass (PassCounter bit 0) +8 steps 0, 1, 2; the
; frame is $D005 + 8 x +8: 4 bytes wide, 2 lines (+2, +3), a ripple pattern.
; Kind 4's attribute $0D (bright cyan on blue). No collision and no damage.
;
; Witness: L1 379 (rzx-r4, s4-right).
;
; The beach rooms of grid 0.
WaterRipple:
  LD A,(PassCounter)
  AND $01
  JR Z,WaterRippleFrame
  LD A,(IY+$08)
  INC A
  CP $03
  JP NZ,WaterRippleStep
  XOR A
WaterRippleStep:
  LD (IY+$08),A
WaterRippleFrame:
  LD A,(IY+$08)
  SLA A
  SLA A
  SLA A
  LD C,A
  LD B,$00
  LD HL,WaterBitmaps
  ADD HL,BC
  LD (IY+$04),L
  LD (IY+$05),H
  LD (IY+$02),$04
  LD (IY+$03),$02
  RET

; Kind 5: a floor slab the hero presses by standing on it; it sets its trap
; slot to 1
;
; IY = the actor, +$10 / 2 its trap slot (TrapSlotAddress). MarkSlabSolid every
; pass. When the hero's x ($74E0) is the actor's and the hero is not jumping
; (state 2) or leaping up (state 9) and +$0B is not 1: +$0B = the hero's state
; (an unused copy) and PressSwitch (+$0A = 1, the slot 1 unless it is 2). Else
; ReleaseSwitch (+$0A = 0). y +$0E = (+$0E & $F8) + +$0A, so a pressed slab
; sits one line lower. Frame 0 of FloorSwitchFrames (FloorSwitchDraw).
;
; Witness: L1 11448 (rzx-r4).
FloorSwitch:
  CALL MarkSlabSolid
  LD A,(HeroRecord)
  CP (IY+$00)
  JP Z,FloorSwitchPressed
  LD (IY+$0B),$00
  CALL ReleaseSwitch
  JP FloorSwitchSink
FloorSwitchPressed:
  LD A,(HeroState)
  CP $02
  JP Z,FloorSwitchSink
  CP $09
  JP Z,FloorSwitchSink
  LD A,(IY+$0B)
  CP $01
  JP Z,FloorSwitchSink
  LD (IY+$0B),A
  CALL PressSwitch
FloorSwitchSink:
  LD A,(IY+$0E)
  AND $F8
  ADD A,(IY+$0A)
  LD (IY+$0E),A
  JP FloorSwitchDraw

; Kind 8: a slab that crumbles once stepped on and turns into a pit of spikes
;
; IY = the actor. $9649 (from counter $1C on: 4 damage to the hero in its
; column unless high in a jump), MarkSlabSolid, then its trap slot: 2 (done)
; sets +8 = $20 (the spikes); else the hero standing on it (as FloorSwitch)
; presses it, and once +$0A is 1 the counter +8 runs to $20 (then the slot =
; 2). Frame +8 / 2 of the set at $CB0B: 0-8 the slab crumbling, 9-16 spikes
; rising. The cells stay solid (the hero stands on the spikes).
;
; Witness: L1 7610 (rzx-r4).
CrumblingSlab:
  CALL TouchDamage4
  CALL MarkSlabSolid
  CALL TrapSlotAddress
  LD A,(HL)
  CP $02
  JP NZ,CrumblingSlabTest
  LD (IY+$08),$20
  JP CrumblingSlabDraw
CrumblingSlabTest:
  LD A,(HeroRecord)
  CP (IY+$00)
  JP Z,CrumblingSlabPressed
  LD A,(IY+$0A)
  CP $00
  JP Z,CrumblingSlabDraw
  JP CrumblingSlabStep
CrumblingSlabPressed:
  LD A,(HeroState)
  CP $02
  JP Z,CrumblingSlabDraw
  CP $09
  JP Z,CrumblingSlabDraw
  LD A,(IY+$0B)
  CP $01
  JP Z,CrumblingSlabDraw
  LD (IY+$0B),A
  CALL PressSwitch
CrumblingSlabStep:
  LD A,(IY+$08)
  CP $20
  JP Z,CrumblingSlabDone
  INC (IY+$08)
  JP CrumblingSlabDraw
CrumblingSlabDone:
  CALL TrapSlotAddress
  LD (HL),$02
CrumblingSlabDraw:
  LD A,(IY+$08)
  SRL A
  CALL SetActorFrame

; SetActorFrame's inline words: the frame table $CB0B and the graphics base
; $C825
;
; Read by SetActorFrame $ABBD after the CALL at $86F8. The set has 25 records:
; 0-8 the slab crumbling (2 x 7), 9-16 spikes rising (2 x 3 to 2 x 9), 17 a
; column 2 x 63, 18 its lower half 2 x 29, 19-24 the dust at a column's foot (4
; x 1 to 4 x 4). Read in rzx-r4.
CrumblingSlabFrames:
  DEFW $CB0B,TrapSprites

; Kind 9: spikes that a switch's trap slot lowers under a slab
;
; IY = the actor, +8 starts at $1A (frame 13, the spikes up). $9669 (at counter
; $1A: 2 damage to the hero in its column unless high in a jump; in grid 3 room
; 2 LoseLife instead), MarkSlabSolid, then TrapSlotState: 2 (done): +8 = 0
; (SwitchedSpikesOpen); 1: +$0A = 2. With +$0A 2 the counter +8 runs down to 0
; and then sets the slot to 2. Frame +8 / 2 of the set at $CB0B (13 spikes up
; ... 0 the whole slab).
;
; Witness: L1 2624 (rzx-r4).
SwitchedSpikes:
  CALL TouchDamage2
  CALL MarkSlabSolid
  CALL TrapSlotState
  CP $02
  JP Z,SwitchedSpikesOpen
  CP $01
  JP NZ,SwitchedSpikesState
  LD (IY+$0A),$02
SwitchedSpikesState:
  LD A,(IY+$0A)
  CP $FF
  JP Z,SwitchedSpikesDraw
  CP $00
  JP Z,SwitchedSpikesDraw
  LD A,(IY+$08)
  CP $00
  JP NZ,SwitchedSpikesLower
  CALL TrapSlotAddress
  LD (HL),$02
  JP SwitchedSpikesDraw
SwitchedSpikesLower:
  DEC (IY+$08)
; This entry point is used by the routine at SwitchedSpikesOpen.
SwitchedSpikesDraw:
  LD A,(IY+$08)
  SRL A
  CALL SetActorFrame

; SetActorFrame's inline words: the frame table $CB0B and the graphics base
; $C825
;
; The inline words after the CALL at $873B, read by SetActorFrame $ABBD (it
; returns past them). Read in rzx-r4 (2624 calls).
SwitchedSpikesFrames:
  DEFW $CB0B,TrapSprites

; SwitchedSpikes, continued: the slot is done, the slab shown whole
;
; +8 = 0, then the frame (JP SwitchedSpikesDraw).
;
; Witness: L1 1339 (rzx-r4).
SwitchedSpikesOpen:
  LD (IY+$08),$00
  JP SwitchedSpikesDraw

; Make the two cells under a slab actor solid (7), except on its first pass
;
; +$0A = $FF (as placed): +$0A = 0 and nothing else. Else the cells Cells +
; ActorCellOffset and the next one = 7 (solid). Callers: FloorSwitch,
; CrumblingSlab, SwitchedSpikes.
;
; Witness: L1 21682 (rzx-r4).
MarkSlabSolid:
  LD A,(IY+$0A)
  CP $FF
  JP Z,MarkSlabFirst
  CALL ActorCellOffset
  LD BC,Cells
  ADD HL,BC
  LD (HL),$07
  INC L
  LD (HL),$07
  RET
MarkSlabFirst:
  LD (IY+$0A),$00
  RET

; HL = (Y & $F8) x 4 + X: the actor IY's cell in a 32-wide map
;
; L wraps within the row (ADD A, no carry into H): the column is +0, the row
; the line +1 / 8. Added to Cells ($7280) for the room cells or to $58C0 for
; the attributes. Callers: MarkSlabSolid, AltarDisc, CrumblingLedge,
; BridgeLedgeForming, BridgeLedge.
;
; Witness: L1 25609 (rzx-r4).
ActorCellOffset:
  LD H,$00
  LD A,(IY+$01)
  AND $F8
  LD L,A
  ADD HL,HL
  ADD HL,HL
  LD A,L
  ADD A,(IY+$00)
  LD L,A
  RET

; +$0A = 1 and the actor's trap slot = 1, unless the slot is already 2 (done)
;
; Callers: FloorSwitch $868A, CrumblingSlab $86DD.
;
; Witness: L1 388 (rzx-r4).
PressSwitch:
  LD (IY+$0A),$01
  CALL TrapSlotAddress
  LD A,(HL)
  CP $02
  RET Z
  LD (HL),$01
  RET

; +$0A = 0 (the switch let go)
;
; Called by FloorSwitch $866C.
;
; Witness: L1 11071 (rzx-r4).
ReleaseSwitch:
  LD (IY+$0A),$00
  RET

; HL = the actor's trap slot: $9DAB + GridNumber x 16 + (+$10) / 2
;
; The trap slots are 16 bytes a grid in the area $9DAB-$9E1A that
; InitStageState clears: 0 idle, 1 triggered, 2 done. Switches set them
; (PressSwitch), the traps read them (TrapSlotState), TrapChainStep and
; LinkTrapSlots set them in groups. DE and IY kept; BC = (+$10) / 2.
;
; Witness: L1 24278 (rzx-r4).
TrapSlotAddress:
  PUSH DE
  LD C,(IY+$10)
  SRL C
  LD B,$00
  LD HL,TrapSlots
  LD A,(GridNumber)
  SLA A
  SLA A
  SLA A
  SLA A
  LD E,A
  LD D,$00
  ADD HL,DE
  ADD HL,BC
  POP DE
  RET

; FloorSwitch, continued: frame 0
;
; Witness: L1 11448 (rzx-r4).
FloorSwitchDraw:
  LD A,$00
  CALL SetActorFrame

; SetActorFrame's inline words: the frame table $CB0B and the graphics base
; $C825
;
; The inline words after the CALL at $87A5, read by SetActorFrame $ABBD (it
; returns past them). Read in rzx-r4 (11448 calls).
FloorSwitchFrames:
  DEFW $CB0B,TrapSprites

; Kind 7: a stone column that falls when its trap slot is set, bounces twice
; and stays down
;
; IY = the actor (placed 23 lines up). ColumnHurts every pass. TrapSlotState 2
; (done) and +$0A not 2: +$0A = 2 and y +$0E + $38 (it lies down at once, a
; room entered after the fall). +$0B $0E: ColumnDust with C = 5; +$0B $1A:
; ColumnDust with C = 0. +$0A 0: waits for the slot (TrapSlotState Z) and then
; +$0A = 1. +$0A 1: +$0B + 1 a pass and y += ColumnDropSteps[+$0B] (an
; accelerating fall, two bounces); at the end mark the slot = 2 and +$0A = 2.
; Frame $11 (the whole column, 2 x 63) while +$0E is under $64, else $12 (its
; lower half, 2 x 29), of the set at $CB0B.
;
; Witness: L1 8055 (rzx-r4).
FallingColumn:
  CALL ColumnHurts
  CALL TrapSlotState
  CP $02
  JP NZ,FallingColumnDust1
  LD A,(IY+$0A)
  CP $02
  JP Z,FallingColumnDraw
  LD (IY+$0A),$02
  LD A,(IY+$0E)
  ADD A,$38
  LD (IY+$0E),A
FallingColumnDust1:
  LD A,(IY+$0B)
  CP $0E
  JP NZ,FallingColumnDust2
  LD C,$05
  CALL ColumnDust
FallingColumnDust2:
  CP $1A
  JP NZ,FallingColumnWait
  LD C,$00
  CALL ColumnDust
FallingColumnWait:
  LD A,(IY+$0A)
  CP $00
  JP NZ,FallingColumnFall
  CALL TrapSlotState
  JP NZ,FallingColumnDraw
  LD (IY+$0A),$01
FallingColumnFall:
  LD A,(IY+$0A)
  CP $02
  JP Z,FallingColumnDraw
  INC (IY+$0B)
  LD C,(IY+$0B)
  LD B,$00
  LD HL,ColumnDropSteps
  ADD HL,BC
  LD A,(HL)
  CP $64
  JP NZ,FallingColumnMove
  CALL TrapSlotAddress
  LD (HL),$02
  INC (IY+$0A)
  JP FallingColumnDraw
FallingColumnMove:
  ADD A,(IY+$0E)
  LD (IY+$0E),A
  JP FallingColumnDraw

; The falling column's y change at each step 1-33, $64 ends
;
; Read by FallingColumn $8804 (+ +$0B): 1, 1, 2, 2, ... 8 (the fall), then -6
; to 6 and -3 to 3 (the bounces), $64 at $8844. Read in rzx-r4.
ColumnDropSteps:
  DEFB $01,$01,$02,$02,$03,$03,$04,$04
  DEFB $05,$05,$06,$06,$07,$08,$FA,$FB
  DEFB $FC,$FD,$FE,$FF,$00,$01,$02,$03
  DEFB $04,$05,$06,$FD,$FE,$FF,$00,$01
  DEFB $02,$03,$64

; While the column falls (+$0B 5 to $1F): 4 damage to the hero in its column
;
; Called by FallingColumn $87AC; JP DamageHero with C = 4.
;
; Witness: L1 8055 (rzx-r4).
ColumnHurts:
  LD A,(IY+$0B)
  CP $05
  RET C
  CP $20
  RET NC
  LD A,(HeroRecord)
  CP (IY+$00)
  RET NZ
  LD C,$04
  JP DamageHero

; Effect 1 and a puff of dust (template $9F29) at the column's foot, C lines
; below its base
;
; PlaySoundVector 1, then FindFreeActor $93E9 and SpawnActor $A639 with the
; template $9F29 (handler ColumnDustActor) at D = +$0D, E = +$0E + C. IY kept.
;
; Witness: L1 38 (rzx-r4).
ColumnDust:
  LD DE,$0001
  CALL PlaySoundVector
  LD D,(IY+$0D)
  LD A,(IY+$0E)
  ADD A,C
  LD E,A
  PUSH IY
  PUSH DE
  CALL FindFreeActor
  POP DE
  JP NZ,ColumnDustDone
  LD HL,ColumnDustTemplate
  CALL SpawnActor
ColumnDustDone:
  POP IY
  RET

; FallingColumn, continued: the whole column or its lower half
;
; Witness: L1 8055 (rzx-r4).
FallingColumnDraw:
  LD E,$12
  LD A,(IY+$0E)
  CP $64
  JP NC,FallingColumnFrame
  LD E,$11
FallingColumnFrame:
  LD A,E
  CALL SetActorFrame

; SetActorFrame's inline words: the frame table $CB0B and the graphics base
; $C825
;
; The inline words after the CALL at $8888, read by SetActorFrame $ABBD (it
; returns past them). Read in rzx-r4 (8055 calls).
FallingColumnFrames:
  DEFW $CB0B,TrapSprites

; Kinds 6 and 10: a spiked ball on a chain that swings once its trap slot is
; set; 2 damage
;
; IY = the actor (kind 6 faces left, 10 right). PendulumHurts. +$0A 0: waits
; for the slot (TrapSlotState Z), then +$0A = 1. +$0A 1: +$0B + 1 a pass, from
; $19 back to 3 (the swing). The frame PendulumSequence[+$0B] of PendulumFrames
; (15 records, 3 x 17 to 3 x 21).
;
; Witness: L1 1774 (rzx-r4).
Pendulum:
  CALL PendulumHurts
  LD A,(IY+$0A)
  CP $00
  JP NZ,PendulumSwing
  CALL TrapSlotState
  JP NZ,PendulumDraw
  LD (IY+$0A),$01
PendulumSwing:
  INC (IY+$0B)
  LD A,(IY+$0B)
  CP $19
  JP NZ,PendulumDraw
  LD (IY+$0B),$03
PendulumDraw:
  LD C,(IY+$0B)
  LD B,$00
  LD HL,PendulumSequence
  ADD HL,BC
  LD A,(HL)
  CALL SetActorFrame

; SetActorFrame's inline words: the frame table $CECF and the graphics base
; $CBAD
;
; The inline words after the CALL at $88BD, read by SetActorFrame $ABBD (it
; returns past them). Read in rzx-r4 (1774 calls).
PendulumFrames:
  DEFW $CECF,PendulumSprites

; The pendulum's frame at each step +$0B: 0-11, 10 down to 3 (steps 0-19), then
; 14, 13, 12, 13, 14 (steps 20-24)
;
; Read by Pendulum $88B8 (+ +$0B). Steps 3-24 are the swing loop. Read in
; rzx-r4.
PendulumSequence:
  DEFB $00,$01,$02,$03,$04,$05,$06,$07
  DEFB $08,$09,$0A,$0B,$0A,$09,$08,$07
  DEFB $06,$05,$04,$03,$0E,$0D,$0C,$0D
  DEFB $0E

; Once swinging (+$0B 4 and up): 2 damage to the hero at the pendulum's column
; or up to 2 columns left of it
;
; Called by Pendulum; DamageHero with C = 2.
;
; Witness: L1 1774 (rzx-r4).
PendulumHurts:
  LD A,(IY+$0B)
  CP $04
  RET C
  LD A,(HeroRecord)
  CP (IY+$00)
  JP Z,PendulumHit
  INC A
  CP (IY+$00)
  JP Z,PendulumHit
  INC A
  CP (IY+$00)
  RET NZ
PendulumHit:
  LD C,$02
  CALL DamageHero
  RET

; Template 4: the dust at a fallen column's foot, frames $13-$18, then freed
;
; +8 + 1 a pass from $12; at $19 freed (RemoveActor $B520). Frames of the set
; at $CB0B (4 bytes wide, 1-4 lines).
;
; Witness: L1 254 (rzx-r4).
ColumnDustActor:
  INC (IY+$08)
  LD A,(IY+$08)
  CP $19
  JP Z,RemoveActor
  CALL SetActorFrame

; SetActorFrame's inline words: the frame table $CB0B and the graphics base
; $C825
;
; The inline words after the CALL at $8909, read by SetActorFrame $ABBD (it
; returns past them). Read in rzx-r4 (219 calls).
ColumnDustFrames:
  DEFW $CB0B,TrapSprites

; A = the actor's trap slot (0 idle, 1 triggered, 2 done); Z when it is 1
;
; Callers: SwitchedSpikes, FallingColumn, Pendulum.
;
; Witness: L1 16245 (rzx-r4).
TrapSlotState:
  CALL TrapSlotAddress
  LD A,(HL)
  CP $01
  RET

; Kind 12: a flame on a stand, four frames, its colour cycling
;
; +$0C = the colour from $B580; +8 counts 0-15 and the frame is +8 / 4 of
; BrazierFrames (2 x 20 to 2 x 22). No damage.
;
; Witness: L1 5259 (rzx-r4).
Brazier:
  CALL ColourRedYellowCycle
  LD (IY+$0C),C
  LD A,(IY+$08)
  INC A
  AND $0F
  LD (IY+$08),A
  SRL A
  SRL A
  CALL SetActorFrame

; SetActorFrame's inline words: the frame table $C80D and the graphics base
; $C763
;
; The inline words after the CALL at $892A, read by SetActorFrame $ABBD (it
; returns past them). Read in rzx-r4 (5259 calls).
BrazierFrames:
  DEFW $C80D,BrazierSprites

; Kind 13: a solid 2 x 2-cell block showing the disc; with four urns carried it
; sets UrnsComplete and flashes
;
; IY = the actor. FindUrnCount; a count of 4: UrnsComplete = 1. First pass
; (+$0B 0): +$0B = 1 only; then the four cells under it (2 x 2 from
; ActorCellOffset) are solid (7). The sprite is the 2 x 16 picture $D66F (item
; 6's disc), set straight into +2 to +5; while UrnsComplete is 1 its colour
; cycles (SetCycleColour $B5A8). Its +$0C is written to its 2 x 2 attributes
; ($58C0 + the cell offset) every pass.
;
; Witness: L1 312 (rzx-r4).
AltarDisc:
  CALL FindUrnCount
  LD A,(HL)
  CP $04
  JP NZ,AltarDiscSolid
  LD A,$01
  LD (UrnsComplete),A
AltarDiscSolid:
  CALL ActorCellOffset
  LD A,(IY+$0B)
  CP $00
  JP NZ,AltarDiscCells
  LD (IY+$0B),$01
  JP AltarDiscShow
AltarDiscCells:
  LD BC,Cells
  ADD HL,BC
  LD (HL),$07
  INC HL
  LD (HL),$07
  LD BC,$001F
  ADD HL,BC
  LD (HL),$07
  INC HL
  LD (HL),$07
AltarDiscShow:
  LD HL,DiscBitmap
  LD (IY+$04),L
  LD (IY+$05),H
  LD (IY+$02),$02
  LD (IY+$03),$10
  LD A,(UrnsComplete)
  CP $01
  JP NZ,AltarDiscColour
  CALL SetCycleColour
AltarDiscColour:
  CALL ActorCellOffset
  LD BC,Attributes+192
  ADD HL,BC
  LD A,(IY+$0C)
  LD (HL),A
  INC L
  LD (HL),A
  LD BC,$001F
  ADD HL,BC
  LD (HL),A
  INC L
  LD (HL),A
  RET

; HL = the address of item 9's count in CarriedCounts (CarriedCounts' slot 0
; when no slot holds item 9)
;
; Searches CarriedItems for kind 9; found: HL + 12 (its count). Not found: HL
; is left past CarriedItems, which is CarriedCounts + 0 (a 0). Callers:
; AltarDisc, UrnMarker.
;
; Witness: L1 4996 (rzx-r4).
FindUrnCount:
  LD HL,CarriedItems
  LD B,$0C
FindUrnNext:
  LD A,(HL)
  CP $09
  JP Z,FindUrnFound
  INC HL
  DJNZ FindUrnNext
  RET
FindUrnFound:
  LD BC,$000C
  ADD HL,BC
  RET

; Kinds 14 and 15: a 3-cell ledge; kind 14 crumbles away 5 frames after the
; hero steps on it
;
; First pass (+$0B 0): +$0B = 1 only. Then its three cells are solid (7). +$0A
; $64 (kind 15): never crumbles. +$0A 0: when the hero stands on it (its y -
; the hero's y is 23, the hero's x the ledge's or up to 2 columns right) +$0A =
; 1. +$0A 1: +8 + 1 a pass; at 5 the cells are cleared, the placement marked
; done (MarkPlacementDone $A616) and the actor freed. Frame +8 of LedgeFrames
; (3 x 14 down to 3 x 9).
;
; Witness: L1 3207 (rzx-r4).
CrumblingLedge:
  LD A,(IY+$0B)
  CP $01
  JP Z,LedgeSolid
  LD (IY+$0B),$01
  JP LedgeDraw
LedgeSolid:
  CALL ActorCellOffset
  LD BC,Cells
  ADD HL,BC
  LD (HL),$07
  INC L
  LD (HL),$07
  INC L
  LD (HL),$07
  LD A,(IY+$0A)
  CP $01
  JP Z,LedgeCrumble
  LD A,(IY+$0A)
  CP $64
  JP Z,LedgeDraw
  LD A,(HeroY)
  SUB (IY+$01)
  CP $E9
  JP NZ,LedgeDraw
  LD E,(IY+$00)
  LD A,(HeroRecord)
  CP E
  JP Z,LedgeStart
  INC E
  CP E
  JP Z,LedgeStart
  INC E
  CP E
  JP NZ,LedgeDraw
LedgeStart:
  INC (IY+$0A)
LedgeCrumble:
  INC (IY+$08)
  LD A,(IY+$08)
  CP $05
  JP NZ,LedgeDraw
  CALL ActorCellOffset
  LD BC,Cells
  ADD HL,BC
  LD (HL),$00
  INC L
  LD (HL),$00
  INC L
  LD (HL),$00
  CALL MarkPlacementDone
  JP RemoveActor
LedgeDraw:
  LD A,(IY+$08)
  CALL SetActorFrame

; SetActorFrame's inline words: the frame table $D651 and the graphics base
; $D5A0
;
; The inline words after the CALL at $8A1B, read by SetActorFrame $ABBD (it
; returns past them). Read in rzx-r4 (3207 calls).
LedgeFrames:
  DEFW $D651,LedgeSprites

; Template 5: a ledge of the bridge after the boss, appearing when its delay
; runs out
;
; +$0A (from $1E) counts down a pass until it equals the ledge's x, so the
; ledges at other columns appear one after another; then +8 (from 4) counts
; down to 0 and at 0 the three cells are made solid. Frame +8 of the ledge set
; (crumbled to whole). Spawned four times by $A24C (the boss beaten, at line
; $70).
;
; Witness: L1 1268 (rzx-r4).
BridgeLedgeForming:
  LD A,(IY+$0A)
  CP (IY+$00)
  JP Z,BridgeLedgeGrow
  DEC (IY+$0A)
  RET
BridgeLedgeGrow:
  LD A,(IY+$08)
  CP $00
  JP Z,BridgeLedgeFormingDraw
  DEC A
  LD (IY+$08),A
  CP $00
  JP NZ,BridgeLedgeFormingDraw
  CALL ActorCellOffset
  LD BC,Cells
  ADD HL,BC
  LD (HL),$07
  INC L
  LD (HL),$07
  INC L
  LD (HL),$07
BridgeLedgeFormingDraw:
  LD A,(IY+$08)
  CALL SetActorFrame

; SetActorFrame's inline words: the frame table $D651 and the graphics base
; $D5A0
;
; The inline words after the CALL at $8A52, read by SetActorFrame $ABBD (it
; returns past them). Read in rzx-r4 (1246 calls).
BridgeLedgeFormingFrames:
  DEFW $D651,LedgeSprites

; Kind 18: a ledge of the bridge, there only once the boss is beaten
;
; BossPhase not 2: freed at once. First pass: +$0A = 1 only; then its three
; cells are solid. Frame 0 of the ledge set.
;
; Witness: L1 268 (rzx-r4).
BridgeLedge:
  LD A,(BossPhase)
  CP $02
  JP NZ,RemoveActor
  LD A,(IY+$0A)
  CP $00
  JP NZ,BridgeLedgeSolid
  LD (IY+$0A),$01
  JP BridgeLedgeShow
BridgeLedgeSolid:
  CALL ActorCellOffset
  LD BC,Cells
  ADD HL,BC
  LD (HL),$07
  INC L
  LD (HL),$07
  INC L
  LD (HL),$07
BridgeLedgeShow:
  LD A,$00
  CALL SetActorFrame

; SetActorFrame's inline words: the frame table $D651 and the graphics base
; $D5A0
;
; The inline words after the CALL at $8A81, read by SetActorFrame $ABBD (it
; returns past them). Read in rzx-r4 (260 calls).
BridgeLedgeFrames:
  DEFW $D651,LedgeSprites

; Kind 19: standing at it with item 8 selected for 44 passes gives a life (up
; to 6)
;
; +$0C = 2. With the hero's x the shrine's and item 8 selected
; (GetSelectedItem): +$0B + 1; while (+$0B & $3F) is under $2D the colour
; cycles ($B5B4 with +$0B & 7), and at $2C, with Lives under 6: Lives + 1 and
; StartLivesFlash. So one life every 64 passes of standing there. Then +8 = 8
; and the strikeable actors' draw tail $A98D (frame 8 of the object set $D74F:
; the ankh-like cross of item 8's icon).
;
; Witness: L1 432 (rzx-r4).
AnkhShrine:
  LD (IY+$0C),$02
  LD A,(HeroRecord)
  CP (IY+$00)
  JP NZ,AnkhShrineDraw
  CALL GetSelectedItem
  CP $08
  JP NZ,AnkhShrineDraw
  LD A,(IY+$0B)
  INC A
  LD (IY+$0B),A
  AND $3F
  CP $2D
  JP NC,AnkhShrineDraw
  CP $2C
  JP NZ,AnkhShrineColour
  LD A,(Lives)
  CP $06
  JP Z,AnkhShrineColour
  INC A
  LD (Lives),A
  CALL StartLivesFlash
  JP AnkhShrineDraw
AnkhShrineColour:
  LD A,(IY+$0B)
  AND $07
  CALL CycleColourA
  LD (IY+$0C),A
AnkhShrineDraw:
  LD (IY+$08),$08
  JP StrikeableActorFrame

; Kind 16: the boss's mouth (grid 8 room 2): opens and shuts while the boss is
; awake, flashes when hit
;
; +$0C = $46; while BossFlash runs: BossFlash - 1 and +$0C = 1. BossPhase 2:
; freed. BossPhase 1: +8 counts 0-15; the frame is BossMouthSequence[+8 / 2] of
; BossMouthFrames (2 x 16: the mouth shut, then opening). BossPhase 0: frame 0.
;
; Witness: L1 460 (rzx-r4).
BossMouth:
  LD (IY+$0C),$46
  LD A,(BossFlash)
  CP $00
  JP Z,BossMouthPhase
  DEC A
  LD (BossFlash),A
  LD (IY+$0C),$01
BossMouthPhase:
  LD A,(BossPhase)
  CP $02
  JP Z,RemoveActor
  CP $00
  JP Z,BossMouthDraw
  LD A,(IY+$08)
  INC A
  AND $0F
  LD (IY+$08),A
BossMouthDraw:
  LD A,(IY+$08)
  SRL A
  LD C,A
  LD B,$00
  LD HL,BossMouthSequence
  ADD HL,BC
  LD A,(HL)
  CALL SetActorFrame

; SetActorFrame's inline words: the frame table $D588 and the graphics base
; $D508
;
; The inline words after the CALL at $8B0B, read by SetActorFrame $ABBD (it
; returns past them). Read in rzx-r4 (458 calls).
BossMouthFrames:
  DEFW $D588,BossMouthSprites

; The mouth's frame at each step +8 / 2: 0, 0, 0, 1, 2, 3, 2, 1
;
; Read by BossMouth $8B06. Read in rzx-r4.
BossMouthSequence:
  DEFB $00,$00,$00,$01,$02,$03,$02,$01

; Kind 17: one of four urns (+$10 = 0-3) that flashes while that many urns are
; still missing
;
; +$0C = $41. FindUrnCount; while 4 - the count is +$10 + 1 or more, the colour
; cycles (SetCycleColour $B5A8). Frame 7 of the object set $D74F (the urn of
; item 9's icon).
;
; Witness: L1 4684 (rzx-r4).
UrnMarker:
  CALL FindUrnCount
  LD (IY+$0C),$41
  LD A,(IY+$10)
  INC A
  LD B,A
  LD A,$04
  SUB (HL)
  CP B
  JP C,UrnMarkerDraw
  CALL SetCycleColour
UrnMarkerDraw:
  LD A,$07
  CALL SetActorFrame

; SetActorFrame's inline words: the frame table $D74F and the graphics base
; $D68F
;
; The inline words after the CALL at $8B32, read by SetActorFrame $ABBD (it
; returns past them). Read in rzx-r4 (4684 calls).
UrnMarkerFrames:
  DEFW $D74F,ObjectSprites

; Kind 11: a handler that does nothing (the actor keeps the frame it was placed
; with)
;
; A single RET.
;
; Witness: L1 220 (rzx-r4).
InertActor:
  RET

  ORG $8F2B

; Grid 8 room 2: draw the boss's picture and its colours, count its hits
;
; Only in grid 8 room 2 while BossPhase is not 2. Draws the 104-row picture at
; $C4A5 into the play buffer at $5F17 (DrawRowPicture), every pass since the
; buffer is cleared every pass. Then copies a block of 8 x 13 attributes into
; the shadow at $6E58 (rows 10-22 of the shadow's 32-wide map, columns
; $18-$1F): the picture's colours $C693, or, while BossFlash runs, the hit
; colours $C6FB with BossFlash - 1 and BossHits - 1 (at 0: $A24C, the boss
; beaten). Called by MainLoop $785B. Stage 1 drew its room picture and its
; arena picture with DrawRoomPicture and DrawArenaPicture; stage 4 has this one
; boss picture.
;
; Witness: L1 8619 (rzx-r4, s4-right).
;
; In s4-right only the first test ran (grid 0). In rzx-r4 the picture was drawn
; 458 passes, 20 of them with the hit colours (BossHits' 20 counts: 10 bolts,
; each counted twice, at column $18 and at $19 where it is freed: HeroBoltBoss
; $8146 20 runs, $8150 taken 10; the last count calls $A24C at frame 21921).
DrawBossPicture:
  LD A,(GridNumber)
  CP $08
  RET NZ
  LD A,(RoomNumber)
  CP $02
  RET NZ
  LD A,(BossPhase)
  CP $02
  RET Z
  LD HL,BossPicture
  LD DE,PlayBuffer+1047
  LD B,$68
  CALL DrawRowPicture
  LD HL,BossColours
  LD A,(BossFlash)
  CP $00
  JP Z,BossPictureColours
  DEC A
  LD (BossFlash),A
  LD A,(BossHits)
  DEC A
  LD (BossHits),A
  CALL Z,BossBeaten
  LD HL,BossHitColours
BossPictureColours:
  LD B,$0D
  LD DE,PlayAttributesCell+$0096
BossPictureColourRow:
  PUSH BC
  LD BC,$0008
  LDIR
  EX DE,HL
  LD BC,$0018
  ADD HL,BC
  EX DE,HL
  POP BC
  DJNZ BossPictureColourRow
  RET

  ORG $92F7

; Spawn a scorpion at column $1A, line E, crawling left (template $9F4D)
;
; Jumped to from the random spawn `$92B5` (SpawnTimer $9245's draw: E = the
; grid and room's line from the table $92BB, x 8). FindFreeActor $93E9; with a
; free record, SpawnActor $A639 with the template $9F4D (1 x 8, handler
; ScorpionActor) at D = $1A, E. Preserves DE. The creature is the small magenta
; crawler on the tombs' floors (its frames at $D451; the screens of the rzx-r4
; run): read as a scorpion.
;
; Witness: L1 28 (rzx-r4).
SpawnScorpion:
  PUSH DE
  CALL FindFreeActor
  POP DE
  RET NZ
  LD D,$1A
  LD HL,ScorpionTemplate
  CALL SpawnActor
  RET

; Spawn a scorpion at column $FF facing left (in effect never: the column is
; the free mark)
;
; As SpawnScorpion with D = $FF and +9 bit 7 set. A record whose column is $FF
; counts as free, so it never runs. The jump to it at `$92B8` is never taken
; either: the test before it is `LD A,0`, `AND 1` (always Z, to SpawnScorpion).
;
; Not executed in any recording (the recordings checked: s4-right, rzx-r4);
; known only from the code.
SpawnScorpionLeft:
  PUSH DE
  CALL FindFreeActor
  POP DE
  RET NZ
  LD D,$FF
  LD HL,ScorpionTemplate
  CALL SpawnActor
  SET 7,(IY+$09)
  RET

; Per-pass handler of a scorpion: crawl 2 columns every 10 passes, gone at the
; edge
;
; The handler word of the template $9F4D. IY = the scorpion. Facing right (+9
; bit 7 clear): removed (RemoveActor $B520) at a column under 2; facing left:
; removed at $1F and over. The step +8 counts 0-9; at $0A it restarts and the
; base column moves by -2 (MoveBaseX $B2C0: to the left when facing right, the
; sprite's own direction). Then frame +8 of ScorpionSet. It has no contact or
; hit test of its own.
;
; Witness: L1 2195 (rzx-r4).
ScorpionActor:
  BIT 7,(IY+$09)
  JP NZ,ScorpionActorLeft
  LD A,(IY+$00)
  CP $02
  JP C,RemoveActor
  JP ScorpionActorStep
ScorpionActorLeft:
  LD A,(IY+$00)
  CP $1F
  JP NC,RemoveActor
ScorpionActorStep:
  INC (IY+$08)
  LD A,(IY+$08)
  CP $0A
  JP NZ,ScorpionActorShow
  LD (IY+$08),$00
  LD E,$FE
  CALL MoveBaseX
ScorpionActorShow:
  LD A,(IY+$08)
  CALL SetActorFrame

; SetActorFrame's parameters: the frame table $D4CC, the graphics $D451 (10
; frames)
;
; Two inline words after ScorpionActor's CALL SetActorFrame $ABBD, which skips
; them on return. Read in rzx-r4 (2189 passes of the scorpions); not in
; s4-right.
ScorpionSet:
  DEFW $D4CC,ScorpionSprites

; Per-pass handler of the mummy of grid 10: walk left, kill the hero it
; reaches, three shots destroy it
;
; The handler word of the template $9F5F (spawned at column $18, line $50 by
; SpawnTimer $9245 in grid 10, every $50-$8F passes). IY = the mummy. Colour
; $46 (bright yellow). A shot's hit (+9 bit 4, set by ShotHitsActor $85CC) is
; cleared, flashes it red (2) for a pass and counts in +$0B; the third hit
; scores 80 and bursts it (ScoreBurst80 $A1FB). When the hero stands in its
; column (and at column 5 or more) the hero loses a life ($7F05). The step +8
; counts 0-$27; at $28 it restarts and the base column moves 3 to the left
; (MoveBaseX), or it is removed at column 0. Then frame MummyFrames[+8] of
; MummySet (the bandaged walker of the frames at $D115).
;
; Witness: L1 325 (rzx-r4).
MummyActor:
  LD (IY+$0C),$46
  BIT 4,(IY+$09)
  JP Z,MummyActorTouch
  RES 4,(IY+$09)
  LD (IY+$0C),$02
  INC (IY+$0B)
  LD A,(IY+$0B)
  CP $03
  JP Z,ScoreBurst80
MummyActorTouch:
  LD A,(HeroRecord)
  CP (IY+$00)
  JP NZ,MummyActorStep
  LD A,(HeroRecord)
  CP $05
  JP C,MummyActorStep
  CALL LoseLife
MummyActorStep:
  LD A,(IY+$08)
  INC A
  LD (IY+$08),A
  CP $28
  JP NZ,MummyActorShow
  LD (IY+$08),$00
  LD A,(IY+$00)
  CP $00
  JP Z,RemoveActor
  LD E,$FD
  CALL MoveBaseX
MummyActorShow:
  LD A,(IY+$08)
  LD C,A
  LD B,$00
  LD HL,MummyFrames
  ADD HL,BC
  LD A,(HL)
  CALL SetActorFrame

; SetActorFrame's parameters: the frame table $D421, the graphics $D115 (8
; frames of 30 lines)
;
; Inline after MummyActor's CALL SetActorFrame $ABBD. Read in rzx-r4 (321
; passes of the mummy in grid 10); not in s4-right.
MummySet:
  DEFW $D421,MummySprites

; The mummy's frame for each of its 40 steps: 0, 0, 1, 1, 2 (x 18), 3, 3, 4, 4,
; 5, 5, 6 (x 12), 7, 7
;
; Read by MummyActor (LD HL,MummyFrames, + the step) before SetActorFrame. Read
; in rzx-r4 (321 passes); not in s4-right.
MummyFrames:
  DEFB $00,$00,$01,$01,$02,$02,$02,$02
  DEFB $02,$02,$02,$02,$02,$02,$02,$02
  DEFB $02,$02,$03,$03,$04,$04,$05,$05
  DEFB $06,$06,$06,$06,$06,$06,$06,$06
  DEFB $06,$06,$06,$06,$06,$06,$07,$07

  ORG $9649

; From step $1C on, drain 4 energy from the hero standing in the actor's column
;
; IY = the actor (called from the kind-8 handler `$869B`). Nothing before +8 =
; $1C, when the hero's column differs, or while he jumps (state 2) at frame 3
; or more; else DamageHero $861B with C = 4.
;
; Witness: L1 7610 (rzx-r4).
TouchDamage4:
  LD A,(IY+$08)
  CP $1C
  RET C
  LD A,(HeroRecord)
  CP (IY+$00)
  RET NZ
  LD A,(HeroState)
  CP $02
  JP NZ,TouchDamage4Hit
  LD A,(HeroFrame)
  CP $03
  RET NC
TouchDamage4Hit:
  LD C,$04
  JP DamageHero

; At step $1A, drain 2 energy from the hero in the actor's column (in grid 3
; room 2 he dies)
;
; IY = the actor (called from the kind-9 handler `$86FF`). Only at +8 = $1A,
; with the hero in the actor's column and not jumping at frame 3 or more. Grid
; 3 room 2: the hero loses a life ($7F05); elsewhere DamageHero $861B with C =
; 2.
;
; Witness: L1 2624 (rzx-r4).
TouchDamage2:
  LD A,(IY+$08)
  CP $1A
  RET NZ
  LD A,(HeroRecord)
  CP (IY+$00)
  RET NZ
  LD A,(HeroState)
  CP $02
  JP NZ,TouchDamage2Hit
  LD A,(HeroFrame)
  CP $03
  RET NC
TouchDamage2Hit:
  LD A,(GridNumber)
  CP $03
  JP NZ,TouchDamage2Drain
  LD A,(RoomNumber)
  CP $02
  JP NZ,TouchDamage2Drain
  JP LoseLife
TouchDamage2Drain:
  LD C,$02
  JP DamageHero

  ORG $96CB

; Kind 20: the block of grid 0 room 1's barrier; shot, it bursts (score 200)
; and BarrierState = 1
;
; The handler word of the kind table's row 20 (`$9ECF`). IY = the block.
; Removed once BarrierState is not 0. A shot's hit (+9 bit 4) jumps to
; ScoreBurst200 $A221. Else frame +8 (0, the 2 x 15 block) of BarrierSet.
;
; Witness: L1 970 (rzx-r4, s4-right).
BarrierBlockActor:
  LD A,(BarrierState)
  CP $00
  JP NZ,RemoveActor
  BIT 4,(IY+$09)
  JP Z,BarrierFrame
  JP ScoreBurst200

; Kind 21: the barrier's pillar; hit, it sinks in four steps and the way opens
; (BarrierState = 2)
;
; The handler word of the kind table's row 21 (`$9ED8`; +8 starts at 1).
; Removed once BarrierState = 2. A hit (+9 bit 4) sets +$0B = 1; from then +8
; goes up a pass (frames 1-4: the 1 x 31 pillar ever lower); at 5 BarrierState
; = 2 and it is removed. CheckWalkBarriers $8175 throws the hero back at column
; 10 until then; CheckGridPassages $ACE0 lets him through at column $0C after.
;
; Witness: L1 997 (rzx-r4, s4-right).
BarrierPillarActor:
  LD A,(BarrierState)
  CP $02
  JP Z,RemoveActor
  BIT 4,(IY+$09)
  JP Z,BarrierPillarSinking
  LD (IY+$0B),$01
BarrierPillarSinking:
  LD A,(IY+$0B)
  CP $01
  JP NZ,BarrierFrame
  INC (IY+$08)
  LD A,(IY+$08)
  CP $05
  JP NZ,BarrierFrame
  LD A,$02
  LD (BarrierState),A
  JP RemoveActor

; Show frame +8 of BarrierSet (jumped to by both barrier handlers)
;
; Witness: L1 1965 (rzx-r4, s4-right).
BarrierFrame:
  LD A,(IY+$08)
  CALL SetActorFrame

; SetActorFrame's parameters: the frame table $D0F7, the graphics $D05D (5
; frames: the block, the pillar at four heights)
;
; Inline after BarrierFrame's CALL SetActorFrame $ABBD. Read in s4-right (1864
; passes) and rzx-r4 (101).
BarrierSet:
  DEFW $D0F7,BarrierSprites

  ORG $A24C

; The boss beaten: four new actors, BossPhase + 1, score 1400, a burst over the
; head
;
; Called from `$8F5E` when the last of BossHits is counted off. Four actors of
; the template $9F3B (its handler $8A22) at line $70, columns $14, $17, $1A and
; $1D (FindFreeActor $93E9 and SpawnActor $A639 each; IY kept), BossPhase + 1
; (to 2: HeadShots stops), AddScore $7B94 with $578 (1400), a big burst of the
; shape $E93D at column $18, row 5, colours 3 and 2 (StartBurst), then
; RoomEvents (JP $81A8).
;
; Witness: L1 1 (rzx-r4).
BossBeaten:
  PUSH IY
  CALL FindFreeActor
  LD HL,BridgeLedgeTemplate
  LD D,$14
  LD E,$70
  CALL SpawnActor
  CALL FindFreeActor
  LD HL,BridgeLedgeTemplate
  LD D,$17
  LD E,$70
  CALL SpawnActor
  CALL FindFreeActor
  LD HL,BridgeLedgeTemplate
  LD D,$1A
  LD E,$70
  CALL SpawnActor
  CALL FindFreeActor
  LD HL,BridgeLedgeTemplate
  LD D,$1D
  LD E,$70
  CALL SpawnActor
  POP IY
  LD A,(BossPhase)
  INC A
  LD (BossPhase),A
  LD BC,$0578
  CALL AddScore
  LD D,$18
  LD E,$05
  LD IX,BossBurstShape
  LD B,$03
  LD C,$02
  LD A,$00
  CALL StartBurst
  JP RoomEvents

  ORG $A92A

; Carry when |E - D| is A or less
;
; In: A = the limit, D and E the two values. Out: A = |E - D|; carry when it is
; under the limit, and also when it equals it (CCF at `$A936`). The limit is
; stored into AbsDiffLimit's compare. Used by HeroWithinY, InStrikeReach,
; FragmentActor and `$8617`. As in stage 1 at `$A7B8`.
;
; Witness: L1 784 (rzx-r4).
AbsDiffBelow:
  LD (AbsDiffLimit+$0001),A
  LD A,E
  SUB D
  JR NC,AbsDiffLimit
  NEG
AbsDiffLimit:
  CP $00                  ; CP n: n = the limit, written by the first
                          ; instruction
  RET NZ
  CCF
  RET

; Kinds 0-2: an urn or chest that the hero's low strike breaks in two hits; it
; may leave an item
;
; The handler word of the kind table's rows 0-2 (`$9E1C`; +8 starts at 5, 3 or
; 1: the three objects of the strikeable set). IY = the object. A strike that
; lands this pass (IsHeroHitFrame7 $802E) and reaches it (InStrikeReach): +8 +
; 1; even (the first hit): PlaySoundVector 2 and on with the cracked frame. Odd
; (the second): ScoreBurst20, MarkPlacementDone and a drop: grid 3 room 1 item
; kind 6 (DropItemKind6); grid 4 room 2 kind 3, room 4 kind 8; else by the
; placement index +$10 AND 3: 1 kind 1, 2 kind 2, else ShatterActor. (In grid 3
; the other rooms reach `$A96A` with RoomNumber in A, so room 4 leaves kind 8
; there too.) Then frame +8 of StrikeableActorSet. As in stage 1 at `$A7C4`,
; which leaves other items.
;
; Witness: L1 3670 (rzx-r4).
StrikeableActor:
  CALL IsHeroHitFrame7
  JR NZ,StrikeableActorFrame
  CALL InStrikeReach
  JR NZ,StrikeableActorFrame
  INC (IY+$08)
  LD A,(IY+$08)
  AND $01
  JR NZ,StrikeableActorDies
  LD DE,$0002
  CALL PlaySoundVector
  JR StrikeableActorFrame
StrikeableActorDies:
  CALL ScoreBurst20       ; the second hit: score, burst, the done mark, then
                          ; the drop
  CALL MarkPlacementDone
  LD A,(GridNumber)
  CP $03
  JP NZ,StrikeableActorGrid4
  LD A,(RoomNumber)
  CP $01
  JP Z,DropItemKind6
StrikeableActorGrid4:
  CP $04
  JP NZ,StrikeableActorDrop
  LD A,(RoomNumber)
  CP $02
  JP Z,DropItemKind3
  CP $04
  JP Z,DropItemKind8
StrikeableActorDrop:
  LD A,(IY+$10)
  AND $03
  CP $01
  JP Z,DropItemKind1
  CP $02
  JP Z,DropItemKind2
  JR ShatterActor

; StrikeableActorFrame
;
; Used by the routines at AnkhShrine, StrikeableActor and StrikeableKind9.
StrikeableActorFrame:
  LD A,(IY+$08)
  CALL SetActorFrame

; SetActorFrame's parameters: the frame table $D74F, the graphics $D68F (9
; frames)
;
; Inline after StrikeableActor's CALL SetActorFrame $ABBD (the column dust and
; the other actors the hero's strike hits). Read in rzx-r4 (4488 passes); not
; in s4-right.
StrikeableActorSet:
  DEFW $D74F,ObjectSprites

; Kind 3: an object that breaks at one strike and leaves item kind 9
;
; The handler word of the kind table's row 3 (`$9E37`; +8 = 0). A strike that
; lands this pass and reaches it (IsHeroHitFrame7 $802E, InStrikeReach):
; PlaySoundVector 2, ScoreBurst20, MarkPlacementDone, an item of kind 9, amount
; 1, image $E3A3 (SpawnItem) at its column and base line, RemoveActor $B520.
; Else its frame (StrikeableActorFrame).
;
; Witness: L1 403 (rzx-r4).
StrikeableKind9:
  CALL IsHeroHitFrame7
  JR NZ,StrikeableActorFrame
  CALL InStrikeReach
  JR NZ,StrikeableActorFrame
  LD DE,$0002
  CALL PlaySoundVector
  CALL ScoreBurst20
  CALL MarkPlacementDone
  LD D,(IY+$00)
  LD E,(IY+$0E)
  LD L,$09
  LD H,$01
  LD BC,ItemIconBitmaps
  CALL SpawnItem
  JP RemoveActor

; Burst the actor into eight fragments and remove it
;
; B = its column, C = its line rounded down to 8 + 5, SpawnFragments $AA02,
; RemoveActor $B520. The fragment count D is not loaded here (stage 1's routine
; loads 8): it is what the earlier calls left in D. Jumped to from
; StrikeableActor `$A98B` (placement index AND 3 = 0 or 3). As in stage 1 at
; `$A803`.
;
; Not executed in any recording (the recordings checked: s4-right, rzx-r4);
; known only from the code.
ShatterActor:
  LD B,(IY+$00)
  LD A,(IY+$01)
  AND $F8
  ADD A,$05
  LD C,A
  CALL SpawnFragments
  JP RemoveActor

; Z when the actor IY stands where the hero's strike lands
;
; The actor's column must be the hero's + 3 (facing right) or - 3 (facing
; left), and its line within $18 of his (AbsDiffBelow): ReturnZ $B4A2, else
; ReturnNZ $B4A7. As in stage 1 at `$A816`.
;
; Witness: L1 38 (rzx-r4).
InStrikeReach:
  LD E,(IY+$00)
  LD A,(HeroFlags)
  BIT 7,A
  JR Z,InStrikeReachRight
  LD A,(HeroRecord)
  SUB $03
  CP E
  JR Z,InStrikeReachLine
  JR InStrikeReachMiss
InStrikeReachRight:
  LD A,(HeroRecord)
  ADD A,$03
  CP E
  JR NZ,InStrikeReachMiss
InStrikeReachLine:
  LD E,(IY+$01)
  LD A,(HeroY)
  LD D,A
  LD A,$18
  CALL AbsDiffBelow
  JP NC,InStrikeReachMiss
  JP ReturnZ
InStrikeReachMiss:
  JP ReturnNZ

; Start D fragment actors at column B, line C
;
; Seeds RandomPointer with $07CF (every shatter looks the same), writes B and C
; into the LD D / LD E at FragmentColumn and FragmentLine, and for each of the
; D fragments takes a free record (FindFreeActor $93E9; it stops quietly when
; none is free), parameters (RandomFragmentParams) and starts it
; (InitFragment). IY is kept. Called by ShatterActor `$A9CB`. As in stage 1 at
; `$A846`.
;
; Not executed in any recording (the recordings checked: s4-right, rzx-r4);
; known only from the code.
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
; From one Random $90AC byte (A = the byte HL points at): B = the byte AND 3, C
; = the same AND 3, A = the same AND $80. As in stage 1 at `$A86D`.
;
; Not executed in any recording (the recordings checked: s4-right, rzx-r4);
; known only from the code.
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
; SpawnActor $A639 with the fragment template $9F17 at D, E, then +9 = A
; (facing), +$0A = B (the arc), +8 = C (the speed in pixels a step), and on
; into FragmentActor. Called by SpawnFragments `$AA20`.
;
; Not executed in any recording (the recordings checked: s4-right, rzx-r4);
; known only from the code.
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
  JR FragmentActor

; Per-pass handler of a fragment: fly an arc, land, lie, sink, be picked up
;
; The handler word of the template $9F17. Its colour alternates
; (ColourRedMagenta $B530). The step +$0B runs from 0: steps 5, $0E, $14 and
; $17 play effect 3 (a bounce); each step moves it +8 pixels across
; (MoveFragment) and down by the step's entry of FragmentArc0 (arc 0) or
; FragmentArc1 (other arcs; doubled when +$0A bit 1 is set); from step $18 it
; no longer moves across. At steps 9, $10, $15 and $17 it looks at the cell
; under it (CellAt $B346): no solid ground makes it fall (step $1C: 7 lines a
; pass, removed at line $90). Step $1B is the rest: +$0E counts down; under 6
; it sinks 3 lines a pass and at 0 it is removed. One the hero touches (his
; column or the one left of it, his line within $20) is taken: EnergyChange +
; 6, AddScore $7B94 with 25, effect 5, removed. As in stage 1 at `$A891`.
;
; Not executed in any recording (the recordings checked: s4-right, rzx-r4);
; known only from the code.
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
  LD E,A
  LD A,(IY+$00)
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
; IY = the fragment, E = the pixels (negated when it faces left). The pixel
; column (+0 x 8 + +$0D) moves by E; +0 and +$0D take the new column and pixel.
; The image +4/+5 = $E177 + $21 x the shift (Multiply $904B; the shift is the
; pixel, or 7 - the pixel facing left): eight pre-shifted copies of 33 bytes. A
; fragment at column 0 or 31 and up is removed (RemoveActor $B520). As in stage
; 1 at `$A97A`.
;
; Not executed in any recording (the recordings checked: s4-right, rzx-r4);
; known only from the code.
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
; Read by FragmentActor `$AA7F` (+$0B the step): up 8, 6, 4, 2, 1 lines, then
; down 1, 2, 4, 6, 8, a short second hop and the rest.
FragmentArc0:
  DEFB $F8,$FA,$FC,$FE,$FF,$00,$01
  DEFB $02,$04,$06,$08,$FC,$FE,$FF
  DEFB $00,$01,$02,$04,$FE,$FF,$00
  DEFB $01,$02,$00,$00,$01,$01,$00
FragmentArc1:
  DEFB $FB,$FC,$FD,$FE,$FF,$00,$01 ; arc 1-3: the same shape, flatter (up 5 to
  DEFB $02,$03,$04,$05,$FD,$FE,$FF ; 1, down 1 to 5), read from `$AA89`
  DEFB $00,$01,$02,$03,$FE,$FF,$00
  DEFB $01,$02,$00,$00,$01,$01,$00

; Set the actor IY to frame A of a frame table (the 4 bytes after the CALL)
;
; The CALL is followed by two words: the frame table DE and the graphics base
; BC; the routine pops them and returns to its caller's caller. A frame record
; is 6 bytes (FrameRecordAddress $B2E2: DE + 6A): +0 the column offset (negated
; when the actor faces left, +9 bit 7), +1 the line offset, +2 the width in
; bytes, +3 the height in lines, +4/+5 the offset of the image from the base.
; The actor's +0 = the offset + its base column +$0D, +1 = the line offset +
; its base line +$0E, +2 and +3 the size, +4/+5 the image address. As in stage
; 1 at `$AA02`.
;
; Witness: L1 62837 (rzx-r4, s4-right).
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

  ORG $B412

; The boss of grid 8 room 2 spits a shot every 4 passes while BossPhase is 1
;
; Called every pass by the main loop `$7861`. Only in grid 8, room 2, on passes
; with PassCounter AND 3 = 0, and BossPhase 1: AddMissile with C = 3
; (HeadShot), D = $19, E = $3A (the head's mouth), B =
; HeadShotDirections[(PassCounter / 4) AND 7], A = 1, then PlaySoundVector 6.
;
; Witness: L1 8619 (rzx-r4, s4-right).
HeadShots:
  LD A,(GridNumber)
  CP $08
  RET NZ
  LD A,(RoomNumber)
  CP $02
  RET NZ
  LD A,(PassCounter)
  AND $03
  RET NZ
  LD A,(BossPhase)
  CP $01
  RET NZ
  LD A,(PassCounter)
  SRL A
  SRL A
  AND $07
  LD C,A
  LD B,$00
  LD HL,HeadShotDirections
  ADD HL,BC
  LD B,(HL)
  LD D,$19
  LD E,$3A
  LD C,$03
  LD A,$01
  CALL AddMissile
  LD DE,$0006
  JP PlaySoundVector

; The direction (0-4) of each shot of the head in turn: 0, 1, 2, 3, 4, 3, 2, 1
;
; Read by HeadShots (LD HL,HeadShotDirections + the shot's number). Read in
; rzx-r4 (110 shots of the boss's head); not in s4-right.
HeadShotDirections:
  DEFB $00,$01,$02,$03,$04,$03,$02,$01
