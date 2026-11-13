; --------------------------------------------------------------------------------------------------------------------
; enemies.asm: The enemies, the hazards and the bosses
;
; Stage 2's enemies and bosses: the harpy (SpawnHarpy $8DA4 brings it when HarpyPhase allows, HarpyActor $8DE8 with
; its wings HarpyWingsActor $8DD2; it rises, attacks with AimedShot, bobs, then flies off), the spirits that float
; over the temple floor (SpawnRandomEnemy $8F8C, SpiritActor $9028, at most 2), Medusa's statue (MedusaActor $814E)
; and her head (MedusaHeadActor $8179: struck by the high strike at column $17, it falls and lies on the floor as an
; actor; with item kind 2, which the smashed warrior statue drops (BreakStatue1 $9A14), selected for 20 passes, it
; turns into item kind 6: MedusaHeadLies $8215), the statues that break into items (BreakStatue0 $9A41, BreakStatue1
; $9A14), the urns, the pool's ripple (WaterActor $8782) and the hydra of grid 1 (three heads on necks moved by $9EAE:
; HydraHead1Actor $7FB5 to HydraHead1LowActor $805B, 9 hits a head (HydraHeadHit $8092), each head cut bursts
; (CutHydraHead1 $80C1); with all three gone HydraDefeated $9BB4 ends the fight). In rzx-r2 the harpy is fought at
; frames 3199-4467, Medusa at 7462-8677 (grid 2) and the hydra at 10427-14318 (grid 1, rooms 3 and 7).
; --------------------------------------------------------------------------------------------------------------------

  ORG $7FB5

; The hydra's head 1 (actor kind 7): hits, the cut, the fire, placed at the end
; of neck 1
;
; IY = the actor. Hydra1Neck = $80 (cut): RemoveActor. Else HydraHeadHit counts
; the hits; when the state +$0A becomes $2A (the 9th hit) CutHydraHead1 bursts
; it, Hydra1Neck gets bit 7 and the actor is removed. Else $B31C (a fire shot
; and effect 6 when Hydra1Step is 4, 8 or 12) and PlaceHydraHead with E =
; Hydra1X + $18, D = Hydra1Pose and A = Hydra1Y. The neck's step, pose and end
; are moved by $9EAE. In rzx-r2 it runs at frames 12590-14318 (grid 1 room 7)
; and is cut at frame 14317.
;
; Witness: L1 339 (rzx-r2).
HydraHead1Actor:
  LD A,(Hydra1Neck)
  CP $80
  JP Z,RemoveActor
  CALL HydraHeadHit
  LD A,(IY+$0A)
  CP $2A
  JR NZ,HydraHead1Alive
  CALL CutHydraHead1
  LD A,(Hydra1Neck)
  OR $80
  LD (Hydra1Neck),A
  JP RemoveActor
HydraHead1Alive:
  LD A,(Hydra1Step)            ; fire, then place the head on its neck
  CALL HydraHeadShot
  LD A,(Hydra1X)
  ADD A,$18
  LD E,A
  LD A,(Hydra1Pose)
  LD D,A
  LD A,(Hydra1Y)
  JP PlaceHydraHead

; The hydra's head 2 (actor kind 8), as HydraHead1Actor with neck 2 and Y + $29
;
; As HydraHead1Actor with Hydra2Neck, Hydra2Step, Hydra2X, Hydra2Pose and
; Hydra2Y + $29; the cut is CutHydraHead2. rzx-r2: frames 10427-11132 (grid 1
; room 3), cut at frame 11132.
;
; Witness: L1 131 (rzx-r2).
HydraHead2Actor:
  LD A,(Hydra2Neck)
  CP $80
  JP Z,RemoveActor
  CALL HydraHeadHit
  LD A,(IY+$0A)
  CP $2A
  JR NZ,HydraHead2Alive
  CALL CutHydraHead2
  LD A,(Hydra2Neck)
  OR $80
  LD (Hydra2Neck),A
  JP RemoveActor
HydraHead2Alive:
  LD A,(Hydra2Step)
  CALL HydraHeadShot
  LD A,(Hydra2X)
  ADD A,$18
  LD E,A
  LD A,(Hydra2Pose)
  LD D,A
  LD A,(Hydra2Y)
  ADD A,$29
  JP PlaceHydraHead

; The hydra's head 3 (actor kind 9), as HydraHead1Actor with neck 3 and Y + $27
;
; As HydraHead1Actor with Hydra3Neck, Hydra3Step, Hydra3X, Hydra3Pose and
; Hydra3Y + $27; the cut is CutHydraHead3. rzx-r2: frames 12590-14130 (room 7),
; cut at frame 13532.
;
; Witness: L1 210 (rzx-r2).
HydraHead3Actor:
  LD A,(Hydra3Neck)
  CP $80
  JP Z,RemoveActor
  CALL HydraHeadHit
  LD A,(IY+$0A)
  CP $2A
  JR NZ,HydraHead3Alive
  CALL CutHydraHead3
  LD A,(Hydra3Neck)
  OR $80
  LD (Hydra3Neck),A
  JP RemoveActor
HydraHead3Alive:
  LD A,(Hydra3Step)
  CALL HydraHeadShot
  LD A,(Hydra3X)
  ADD A,$18
  LD E,A
  LD A,(Hydra3Pose)
  LD D,A
  LD A,(Hydra3Y)
  ADD A,$27
  JP PlaceHydraHead

; Head 1 as placed in the hydra's first room (actor kind 10): neck 1 with Y +
; $58
;
; As HydraHead1Actor (the same Hydra1Neck, step and pose) with Hydra1Y + $58:
; the head as seen from grid 1 room 3, where the hydra stands lower in the
; window. rzx-r2: frames 10427-11269; it was never cut there (the cut code at
; $806D did not run).
;
; Witness: L1 166 (rzx-r2).
HydraHead1LowActor:
  LD A,(Hydra1Neck)
  CP $80
  JP Z,RemoveActor
  CALL HydraHeadHit
  LD A,(IY+$0A)
  CP $2A
  JR NZ,HydraHead1LowAlive
  CALL CutHydraHead1
  LD A,(Hydra1Neck)
  OR $80
  LD (Hydra1Neck),A
  JP RemoveActor
HydraHead1LowAlive:
  LD A,(Hydra1Step)
  CALL HydraHeadShot
  LD A,(Hydra1X)
  ADD A,$18
  LD E,A
  LD A,(Hydra1Pose)
  LD D,A
  LD A,(Hydra1Y)
  ADD A,$58
  JR PlaceHydraHead

; Count a thrown weapon's hit on a hydra head and flash it
;
; IY = the head. +9 bit 5 (set by ThrownHitsActor) is a hit: the attribute +$0C
; = 1 (the flash), +$0B - 1 (the hits left, 9 from ActorKinds) and at 0 the
; state +$0A = $2A (cut) and the attribute $44; bit 5 cleared. Then the flash
; steps the attribute 1 to 4 and 4 to $44 (bright green). rzx-r2: 27 hits on
; the three heads (9 each).
;
; Witness: L1 845 (rzx-r2).
HydraHeadHit:
  BIT 5,(IY+$09)
  JP Z,HydraHeadFlash
  LD (IY+$0C),$01
  DEC (IY+$0B)
  JR NZ,HydraHeadHitDone
  LD (IY+$0A),$2A
  LD (IY+$0C),$44
HydraHeadHitDone:
  RES 5,(IY+$09)          ; clear the hit bit
HydraHeadFlash:
  LD A,(IY+$0C)           ; the attribute's flash steps
  CP $01
  JR NZ,HydraHeadFlash4
  LD (IY+$0C),$04
HydraHeadFlash4:
  CP $04
  RET NZ
  LD (IY+$0C),$44
  RET

; Head 1 cut: HydraHeads - 1 and a burst at 5, 4
;
; HydraHeads - 1, then StartBurst at D = 5, E = 4 with the shape $EEAA, B = 4,
; C = 5 (the colours), A = 0. rzx-r2 frame 14317.
;
; Witness: L1 1 (rzx-r2).
CutHydraHead1:
  LD HL,HydraHeads
  DEC (HL)
  LD D,$05
  LD E,$04
  LD IX,BurstShapes
  LD B,$04
  LD C,$05
  LD A,$00
  JP StartBurst

; Head 2 cut: HydraHeads - 1 and a burst at 5, 4
;
; As CutHydraHead1. rzx-r2 frame 11132.
;
; Witness: L1 1 (rzx-r2).
CutHydraHead2:
  LD HL,HydraHeads
  DEC (HL)
  LD D,$05
  LD E,$04
  LD IX,BurstShapes
  LD B,$04
  LD C,$05
  LD A,$00
  JP StartBurst

; Head 3 cut: HydraHeads - 1 and a burst at 5, 8
;
; As CutHydraHead1 with E = 8. rzx-r2 frame 13532.
;
; Witness: L1 1 (rzx-r2).
CutHydraHead3:
  LD HL,HydraHeads
  DEC (HL)
  LD D,$05
  LD E,$08
  LD IX,BurstShapes
  LD B,$04
  LD C,$05
  LD A,$00
  JP StartBurst

; Place a hydra head: Y = A - 10, X and the shift from E + 2, the frame by pose
; D
;
; IY = the head, A = the Y, E = the X in pixels - 2, D = the pose. +1 = A - 10;
; +0 = (E + 2) / 8 and +$11 = (E + 2) & 7 (drawn shifted by PreShiftSprite);
; the frame (3 bytes x 22 lines) is $D605 for pose 0-4, $D5C3 for 5-6 and $D581
; for 7 and up. Reached by a JP from the four head handlers (842 times in
; rzx-r2).
;
; Witness: L1 842 (rzx-r2).
PlaceHydraHead:
  SUB $0A
  LD (IY+$01),A
  LD A,E
  ADD A,$02
  LD E,A
  SRL A
  SRL A
  SRL A
  LD (IY+$00),A
  LD A,E
  AND $07
  LD (IY+$11),A
  LD HL,HydraHeadSprites+$0084
  LD BC,$FFBE
  LD A,D
  CP $05
  JR C,PlaceHydraHeadPose7
  ADD HL,BC
PlaceHydraHeadPose7:
  CP $07
  JR C,PlaceHydraHeadSet
  ADD HL,BC
PlaceHydraHeadSet:
  LD (IY+$04),L
  LD (IY+$05),H
  LD (IY+$02),$03
  LD (IY+$03),$16
  RET

; Medusa's statue struck: MedusaState = 1 and a burst at 21, 7
;
; MedusaState = 1 (the head falls: MedusaHeadActor), then StartBurst at D =
; $15, E = 7 with the shape $EEB8, colours 4 and 5, mode 0. Reached from
; MedusaActor ($8167) when the hero strikes it. rzx-r2: once, frame 8345 (the
; statue room of grid 2, screen 008525.png shows the head on the floor
; afterwards).
;
; Witness: L1 1 (rzx-r2).
MedusaStruck:
  LD A,$01
  LD (MedusaState),A
  LD D,$15
  LD E,$07
  LD IX,BurstShapeMedusa
  LD B,$04
  LD C,$05
  LD A,$00
  JP StartBurst

; Medusa's statue (actor kind 11): struck by the hero's sword from the left, it
; loses its head
;
; IY = the actor. MedusaState not 0: RemoveActor. Else when the hero stands at
; x $17, faces right ($74E9 bit 7 clear) and IsHeroStrikeFrame gives Z:
; MedusaStruck. Else frame 0 (MedusaSetFrame). Placed by Grid2Placements;
; rzx-r2 runs it 341 times (frames 7462-16453).
;
; Witness: L1 341 (rzx-r2).
MedusaActor:
  LD A,(MedusaState)
  CP $00
  JP NZ,RemoveActor
  LD A,(HeroRecord)
  CP $17
  JR NZ,MedusaActorDraw
  LD A,(HeroFlags)
  BIT 7,A
  JR NZ,MedusaActorDraw
  CALL IsHeroStrikeFrame
  JR Z,MedusaStruck
MedusaActorDraw:
  LD A,$00                ; frame 0
  JR MedusaSetFrame

; Z when the hero is in state 6 (the strike) at frame 7, the frame the blow
; lands
;
; Reads the hero's state $74EA and frame $74E8. Z when the state is 6 and the
; frame 7; NZ otherwise. Called by MedusaActor and the statues and urns ($A708,
; $A748, $A9B8): 1915 calls in rzx-r2, 1922 in s2-right.
;
; Witness: L1 4121 (rzx-r2, s2-right, stageload).
IsHeroStrikeFrame:
  LD A,(HeroState)
  CP $06
  RET NZ
  LD A,(HeroFrame)
  CP $07
  RET

; Medusa's head (actor kind 12): looks about and spits, falls when struck, lies
; until item 2 turns it into item 6
;
; IY = the actor. By MedusaState: 4 RemoveActor; 2 MedusaHeadLies; 1
; MedusaHeadFalls; 0 the head on the statue: +8 counts 0-$37 and the frame is
; MedusaHeadFrames[+8 / 2] (MedusaSetFrame); at +8 = $0A it spits a shot
; (KindTwelveShot $B3A4: a missile of type 4 at the head, effect 11). rzx-r2:
; 427 runs (frames 7462-16453), 6 shots.
;
; Witness: L1 427 (rzx-r2).
MedusaHeadActor:
  LD A,(MedusaState)
  CP $04
  JP Z,RemoveActor
  CP $02
  JP Z,MedusaHeadLies
  CP $00
  JR NZ,MedusaHeadFalls
  LD A,(IY+$08)
  INC A
  CP $38
  JR NZ,MedusaHeadLook
  XOR A
MedusaHeadLook:
  LD (IY+$08),A
  SRL A
  LD C,A
  LD B,$00
  LD HL,MedusaHeadFrames
  ADD HL,BC
  LD A,(HL)
  CALL MedusaSetFrame
  LD A,(IY+$08)
  CP $0A
  RET NZ
  JP KindTwelveShot

; The head's frame at each of its 28 steps (frames 1-6 of the set at $D36C)
;
; Read by MedusaHeadActor ($819B) with the step +8 / 2.
MedusaHeadFrames:
  DEFB $02,$03,$01,$03,$01,$03,$02,$01
  DEFB $03,$02,$01,$02,$03,$02,$01,$02
  DEFB $03,$04,$05,$06,$05,$06,$05,$06
  DEFB $05,$04,$03,$01

; SetActorFrame A with Medusa's frame table $D4D3 and set $D36C
;
; A = the frame. CALL SetActorFrame with the four bytes MedusaFrameSet after
; it; returns past them. Called by MedusaActor, MedusaHeadActor and
; MedusaHeadDraw (763 times in rzx-r2, frames 7462-8675).
;
; Witness: L1 763 (rzx-r2).
MedusaSetFrame:
  CALL SetActorFrame

; SetActorFrame's inline words: the frame table $D4D3, the set $D36C
MedusaFrameSet:
  DEFB $D3,$D4,$6C,$D3

; The struck head falls: 26 steps down and left, then it lies (MedusaState 2,
; 20 passes to wait)
;
; +$0B is the step. At $1A: MedusaState = 2, +$0B = $14, then MedusaHeadDraw.
; Else +$0B + 1, +$0E (the base Y) += MedusaHeadFallSteps[+$0B] and
; StepFineLeft 3 (3 pixels left), then MedusaHeadDraw. rzx-r2: 27 runs from
; frame 8345.
;
; Witness: L1 27 (rzx-r2).
MedusaHeadFalls:
  LD A,(IY+$0B)
  CP $1A
  JR NZ,MedusaHeadFallStep
  LD A,$02
  LD (MedusaState),A
  LD (IY+$0B),$14
  JR MedusaHeadDraw
MedusaHeadFallStep:
  INC A
  LD (IY+$0B),A
  LD C,A
  LD B,$00
  LD HL,MedusaHeadFallSteps
  ADD HL,BC
  LD A,(HL)
  ADD A,(IY+$0E)
  LD (IY+$0E),A
  LD A,$03
  CALL StepFineLeft
  JR MedusaHeadDraw

; The falling head's Y change at steps 1-26 (up, then down, a bounce at the
; end)
;
; Read by MedusaHeadFalls ($81E8) with the step 1-$1A; the byte at index 0 is
; not read.
MedusaHeadFallSteps:
  DEFB $F8,$F9,$FA,$FB,$FC,$FD,$FE,$FF
  DEFB $00,$01,$02,$03,$04,$05,$06,$06
  DEFB $07,$08,$FD,$FE,$FF,$00,$01,$02
  DEFB $03,$00,$00

; The head on the floor: with item 2 selected for 20 passes it becomes item
; kind 6
;
; When GetSelectedItem gives 2: +$0B - 1 each pass; at 0 MedusaState = 4,
; RemoveActor and SpawnItem kind 6 (icon $DEC5) at D = $11, E = $50. Without
; item 2 (or while counting) MedusaHeadDraw. rzx-r2: frames 8423-8677; item 6
; appears at frame 8677.
;
; Witness: L1 60 (rzx-r2).
MedusaHeadLies:
  CALL GetSelectedItem
  CP $02
  JR NZ,MedusaHeadDraw
  LD A,(IY+$0B)
  CP $00
  JR Z,MedusaHeadToItem
  DEC (IY+$0B)
  JR MedusaHeadDraw
MedusaHeadToItem:
  LD A,$04
  LD (MedusaState),A
  CALL RemoveActor
  LD D,$11
  LD E,$50
  LD L,$06
  LD H,$00
  LD BC,ItemIconKind6
  JP SpawnItem

; Draw the fallen head (frames 1-2 alternating) and hurt the hero who touches
; it
;
; In MedusaState 2 the base X, Y = $0E, $3E. When the hero's x ($74E0) is the
; head's x or x + 1: DamageHero with C = 2. +8 counts 0-3 and the frame is +8 /
; 2 + 1 (MedusaSetFrame, JP). rzx-r2: 86 runs, 6 hurts.
;
; Witness: L1 86 (rzx-r2).
MedusaHeadDraw:
  LD A,(MedusaState)
  CP $02
  JR NZ,MedusaHeadTouch
  LD (IY+$0D),$0E
  LD (IY+$0E),$3E
MedusaHeadTouch:
  LD E,(IY+$00)
  LD A,(HeroRecord)
  CP E
  JR Z,MedusaHeadHurts
  DEC A
  CP E
  JR NZ,MedusaHeadAnimate
MedusaHeadHurts:
  LD C,$02
  CALL DamageHero
MedusaHeadAnimate:
  LD A,(IY+$08)
  INC A
  AND $03
  LD (IY+$08),A
  SRL A
  ADD A,$01
  JP MedusaSetFrame

  ORG $842E

; An actor that takes 6 hits, rises, bobs and then waits to be taken as a piece
; (1200 points)
;
; IY = the actor (18-byte record). Colour from the cycle (SetCycleColour). +$0B
; not 0: animates frames 2-9. Else by +$0A: 6 PieceRises, 7 PieceWaitsPickup;
; 0-5: each hit (+$09 bit 4, set by a shot or the hero's blow) clears the flag
; and adds 1 to +$0A; at 6 the next record's +0 is set $FF (the record after it
; freed). Frame 0. Draws with SetActorFrame (PieceFrames: frames $DE29,
; graphics $DD41). Its template is PieceTemplate $9742 (SpawnBonus). rzx-r2:
; 3200 runs, 30 hits, 5 pieces raised; s2-right: 1108 runs, none hit.
;
; As in stage 1 at $8233.
;
; Witness: L1 4470 (rzx-r2, s2-right, stageload).
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
; This entry point is used by the routines at PieceRises and PieceWaitsPickup.
PieceActorDraw:
  CALL SetActorFrame

; SetActorFrame's inline operands: the frame table $DE29 and the graphics base
; $DD41
PieceFrames:
  DEFB $29,$DE,$41,$DD

; State 6: rise and bob along RiseSteps for 30 steps (effect 3 at steps 16 and
; 25), then state 7
;
; Jumped to from UpdatePieceActor ($843D).
;
; As in stage 1 at $8279, the same code.
;
; Witness: L1 155 (rzx-r2).
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
; 30 signed bytes: 10 zeros, then up 1-6, back -4 to 4, -2 to 2 (the bob). Read
; by PieceRises ($8491) with the step.
RiseSteps:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$01,$02,$03,$04,$05,$06
  DEFB $FC,$FD,$FE,$FF,$00,$01,$02,$03
  DEFB $04,$FE,$FF,$00,$01,$02

; State 7: when the hero touches it at its column (or the next): 1200 points,
; the piece's bit, freed
;
; $9B77 (the hero within $14 lines); then the hero's x ($74E0) equal to +0 or
; +0 + 1: AddScore 1200, PieceTakenFlag = 1, PiecesMask |= +$10, freed ($B489).
;
; As in stage 1 at $82CC, the same code.
;
; Witness: L1 46 (rzx-r2).
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

  ORG $8782

; The pool's ripple (actor kind 20): a random frame 0-2 of a 4 x 2 strip every
; other pass
;
; IY = the actor. On odd passes (PassCounter bit 0) a new frame: NextSeed & 3
; (3 retried); the same frame as now becomes the one before it (0 becomes 2).
; Every pass: +4/+5 = $C62C + frame x 8, +2 = 4 bytes, +3 = 2 lines. Runs in
; the rooms with a pool: 5240 times in rzx-r2 (frames 260-18525), 3115 in
; s2-right.
;
; Witness: L1 8944 (rzx-r2, s2-right, stageload).
WaterActor:
  LD A,(PassCounter)
  AND $01
  JR Z,WaterActorDraw
WaterActorPick:
  CALL NextSeed           ; a random frame 0-2
  AND $03
  CP $03
  JR Z,WaterActorPick
  CP (IY+$08)
  JP NZ,WaterActorSet
  DEC A
  CP $FF
  JP NZ,WaterActorSet
  LD A,$02
WaterActorSet:
  LD (IY+$08),A
WaterActorDraw:
  LD A,(IY+$08)
  SLA A
  SLA A
  SLA A
  LD C,A
  LD B,$00
  LD HL,RippleSprites
  ADD HL,BC
  LD (IY+$04),L
  LD (IY+$05),H
  LD (IY+$02),$04
  LD (IY+$03),$02
  RET

  ORG $88B6

; RowPlotters' entries for width 0 and the mirrored width 7: flash the border
; from R for ever
;
; LD A,R; OUT ($FE),A; CALL KeyHook; JR back. Entries 0, 1 and 15 of
; RowPlotters point here; a frame never has width 0 or a mirrored width 7, so
; it is not reached. Not executed in any recording (the recordings checked:
; s2-right, rzx-r2); known only from the code (RowPlotters $8A59).
HangFlashBorder:
  LD A,R
  OUT ($FE),A
  CALL KeyHook
  JR HangFlashBorder

  ORG $8DA4

; Bring the harpy: two records, the wings ($96E8) at $12, $4E and the body
; ($96FA) at $13, $62
;
; FindFreeActorPair (NZ: no pair, nothing). The pair's first record, saved in
; InitOnly10 ($FE10, used here as an IY save word), gets the Harpy template at
; D = $13, E = $62 with +$0D = 0 and +$0E = $FF (the bob step and the passes
; left); the next record the HarpyWings template at $12, $4E. Called once by
; the harpy's statue handler $A7F6 ($A85C): s2-right frame 1903, rzx-r2 frame
; 3199 (screen 003517.png shows the harpy over the temple).
;
; Witness: L1 2 (rzx-r2, s2-right).
SpawnHarpy:
  CALL FindFreeActorPair
  RET NZ
  LD (InitOnly10),IY
  LD BC,$0012
  ADD IY,BC
  LD HL,HarpyWingsTemplate
  LD D,$12
  LD E,$4E
  CALL SpawnActor
  LD IY,(InitOnly10)
  LD HL,HarpyTemplate
  LD D,$13
  LD E,$62
  CALL SpawnActor
  LD (IY+$0D),$00
  LD (IY+$0E),$FF
  RET

; The harpy's wings: frames 0-4, two passes each; HarpyActor places them
;
; IY = the wings. +8 counts 0-9 and the frame is +8 / 2 (SetActorFrame with
; HarpyWingsFrameSet). Their place (+$0D, +$0E) and colour (+$0C) are written
; by the body's HarpyPlaceWings. rzx-r2: frames 3201-4467, s2-right 1905-2883.
;
; Witness: L1 770 (rzx-r2, s2-right).
HarpyWingsActor:
  LD A,(IY+$08)
  INC A
  CP $0A
  JR NZ,HarpyWingsFrame
  LD A,$00
HarpyWingsFrame:
  LD (IY+$08),A
  SRL A
  CALL SetActorFrame

; SetActorFrame's inline words: the frame table $D949, the set $D797
HarpyWingsFrameSet:
  DEFB $49,$D9,$97,$D7

; The harpy: rises out of its statue, swoops and shoots, bobs for 255 passes,
; then flies off
;
; IY = the body, IY + $12 the wings. Touch: the hero's x not left of the harpy
; and the harpy's y $50-$C7 (low over the floor): DamageHero 4. +$0B + 1 each
; pass and CycleItemInk colours the wings (+$1E). By the state +$0A: 3 (just
; out) rises a line a pass until its y is under +$0B, then attacks; 1 (attack)
; steps +8: AimedShot at steps 4 and 8, at step 9 three times in four back to
; step 0, at step $0E state 2; its frame from HarpyAttackFrames; 2 (hover)
; starts an attack at random (1 in 32 passes). Then the bob: +$0D counts 0-9
; and while +$0E (255 passes) counts down Y += HarpyBobSteps[+$0D / 2]; at 0
; HarpyPhase = $FA (gone for good) and it flies up a line a pass until Y = $F0
; (RemoveActor). Every pass HarpyPlaceWings. rzx-r2: frames 3201-4352 (6
; attacks), s2-right: 1905-2883 (7 hits on the hero).
;
; Witness: L1 718 (rzx-r2, s2-right).
HarpyActor:
  LD A,(HeroRecord)
  CP (IY+$00)
  JP C,HarpyMove
  LD A,(IY+$01)
  CP $50
  JP C,HarpyMove
  CP $C8
  JP NC,HarpyMove
  LD C,$04
  CALL DamageHero
HarpyMove:
  INC (IY+$0B)
  CALL CycleItemInk
  LD (IY+$1E),A
  LD A,(IY+$0A)
  CP $03
  JR NZ,HarpyNotRising
  DEC (IY+$01)
  LD A,(IY+$01)
  CP (IY+$0B)
  JP NC,HarpyPlaceWings
  JR HarpyStartAttack
HarpyNotRising:
  CP $01
  JR Z,HarpyAttackStep
  CALL Random
  AND $1F
  JR NZ,HarpyBob
HarpyStartAttack:
  CALL Random
  AND $3F
  LD (IY+$0A),$01
  LD (IY+$08),$01
HarpyAttackStep:
  INC (IY+$08)
  LD A,(IY+$08)
  CP $09
  JR NZ,HarpyShoot
  CALL Random
  AND $03
  JR Z,HarpyShoot
  LD (IY+$08),$00
HarpyShoot:
  LD A,(IY+$08)
  CP $04
  CALL Z,AimedShot
  CP $08
  CALL Z,AimedShot
  LD A,(IY+$08)
  CP $0E
  JR NZ,HarpyAttackFrame
  LD (IY+$0A),$02
  JR HarpyBob
HarpyAttackFrame:
  AND $FE
  LD C,A
  LD B,$00
  LD HL,HarpyAttackFrames
  ADD HL,BC
  LD A,(HL)
  LD (IY+$04),A
  INC HL
  LD A,(HL)
  LD (IY+$05),A
HarpyBob:
  LD A,(IY+$0D)
  INC A
  CP $0A
  JR NZ,HarpyBobStep
  LD A,$00
HarpyBobStep:
  LD (IY+$0D),A
  LD A,(IY+$0E)
  CP $00
  JR Z,HarpyFliesOff
  DEC (IY+$0E)
  LD A,(IY+$0D)
  SRL A
  LD C,A
  LD B,$00
  LD HL,HarpyBobSteps
  ADD HL,BC
  LD E,(HL)
  LD A,(IY+$01)
  ADD A,E
  LD (IY+$01),A
  JR HarpyPlaceWings
HarpyFliesOff:
  LD A,$FA
  LD (HarpyPhase),A
  DEC (IY+$01)
  LD A,(IY+$01)
  CP $F0
  JP NZ,HarpyPlaceWings
  JP RemoveActor

; The harpy's Y change at bob steps 0-4: 1, 0, -1, -1, 1
;
; Read by HarpyActor ($8E99) with +$0D / 2.
HarpyBobSteps:
  DEFB $01,$00,$FF,$FF,$01

; The harpy's frame at attack steps 0-13 (by pairs): $D647, $D6B7, $D727 x 3,
; $D6B7, $D647
;
; Read by HarpyActor ($8E6D) with +8 AND $FE; the word goes to +4/+5.
HarpyAttackFrames:
  DEFW HarpySprites,HarpySprite1,HarpySprite2,HarpySprite2,HarpySprite2,HarpySprite1,HarpySprites

; Put the wings over the body: X - 1 (+1 facing left), Y - $14
;
; IY = the body. The wings' +$0D = the body's X + NegateIfFacingLeft(-1), +$0E
; = the body's Y - $14. Reached from every path of HarpyActor (366 times in
; rzx-r2).
;
; Witness: L1 717 (rzx-r2, s2-right).
HarpyPlaceWings:
  LD A,$FF
  CALL NegateIfFacingLeft
  ADD A,(IY+$00)
  LD (IY+$1F),A
  LD A,(IY+$01)
  SUB $14
  LD (IY+$20),A
  RET

  ORG $8F8C

; Spawn a spirit at a random place of the room, when the room allows (at most
; 2)
;
; Not in grid 2. Needs a free record (FindFreeActor). E = $20 + Random & $1F
; (the line), D = Random & 7 (a place); IsSpawnBarred may drop the call. The
; place's column is D x 4 - 1 (places 0 and 7: none); the cell at it ($20 + the
; line, column + 5; CellAt) must be 0 (open). Then SpiritCount under 2:
; SpiritCount + 1; none of the first 5 records may have the same base column
; (+$0D), else it returns with the count already raised; SpawnActor of the
; Spirit template $96D6 at D, E (JP). rzx-r2: 190 tries, 3 spirits (frames
; 1187-1959); s2-right 72 tries, 9 spirits. Stage 1 spawns a warrior here.
;
; As in stage 1 at $9353 (the job: a random enemy; stage 2's enemy and test).
;
; Witness: L1 271 (rzx-r2, s2-right, stageload).
SpawnRandomEnemy:
  LD A,(GridNumber)
  CP $02
  RET Z
  CALL FindFreeActor
  RET NZ
  CALL Random
  AND $1F
  ADD A,$20
  LD E,A
  CALL Random
  AND $07
  LD D,A
  CALL IsSpawnBarred
  LD A,D
  SLA A
  SLA A
  CP $00
  RET Z
  CP $1C
  RET Z
  SUB $01
  LD D,A
  PUSH DE
  LD A,D
  LD D,E
  ADD A,$05
  LD E,A
  LD A,D
  ADD A,$20
  LD D,A
  CALL CellAt
  POP DE
  CP $00
  RET NZ
  LD A,(SpiritCount)
  CP $02
  RET Z
  INC A
  LD (SpiritCount),A
  LD B,$05
  LD IX,Actors
SpawnSpiritCheck:
  LD A,(IX+$00)           ; is a record already at this column?
  CP $FF
  JR Z,SpawnSpiritNext
  LD A,(IX+$0D)
  CP D
  RET Z
SpawnSpiritNext:
  PUSH BC
  LD BC,$0012
  ADD IX,BC
  POP BC
  DJNZ SpawnSpiritCheck
  LD HL,SpiritTemplate
  JP SpawnActor

; Drop SpawnRandomEnemy's call where no enemy may appear (POP HL, RET)
;
; D = the place 0-7. Grid 0: barred when D is NoSpawnColumns[RoomNumber]. Grid
; 2: barred when D is 6 or more (never reached: SpawnRandomEnemy returns in
; grid 2 first; known only from the code, $900B). Grid 1: barred in rooms 3, 4
; and 7 (the hydra's rooms). Barred: drops its return address and returns from
; SpawnRandomEnemy. rzx-r2: 164 calls, 45 barred.
;
; Witness: L1 245 (rzx-r2, s2-right, stageload).
IsSpawnBarred:
  LD A,(GridNumber)
  CP $00
  JR NZ,IsSpawnBarredGrid2
  LD A,(RoomNumber)
  LD C,A
  LD B,$00
  LD HL,NoSpawnColumns
  ADD HL,BC
  LD A,(HL)
  CP D
  JR Z,SpawnBarred
  RET
IsSpawnBarredGrid2:
  CP $02
  JR NZ,IsSpawnBarredGrid1
  LD A,D
  CP $06
  JR NC,SpawnBarred
  RET
IsSpawnBarredGrid1:
  LD A,(RoomNumber)
  CP $03
  JR Z,SpawnBarred
  CP $04
  JP Z,SpawnBarred
  CP $07
  RET NZ
SpawnBarred:
  POP HL                  ; drop the caller's return
  RET

; The place no spirit may take in each room 0-5 of grid 0: 5, 5, 6, 5, 0, 0
;
; Read by IsSpawnBarred ($8FFE) with RoomNumber.
NoSpawnColumns:
  DEFB $05,$05,$06,$05,$00,$00

; A spirit: grows out of the floor, floats, spits six shots every 16 passes,
; fades away or bursts when hit
;
; IY = the actor. SetCycleColour. Acts on odd passes (PassCounter bit 0); by
; +$0A: 0 grows (+8 frames 0-6, then state 1), 1 SpiritFloat, 2 SpiritShrinks.
; Draws frame +8 with SetActorFrame (SpiritFrameSet). The template is $96D6
; (SpawnRandomEnemy). s2-right: 579 runs (frames 784-3339), rzx-r2: 233 (frames
; 1264-1959; screen 001517.png).
;
; Witness: L1 1066 (rzx-r2, s2-right, stageload).
SpiritActor:
  CALL SetCycleColour
  LD A,(PassCounter)
  AND $01
  JR Z,SpiritDraw
  LD A,(IY+$0A)
  CP $01
  JR Z,SpiritFloat
  CP $02
  JR Z,SpiritShrinks
  INC (IY+$08)
  LD A,(IY+$08)
  CP $06
  JR NZ,SpiritDraw
  INC (IY+$0A)
; This entry point is used by the routines at SpiritFloat and SpiritShrinks.
SpiritDraw:
  LD A,(IY+$08)
  CALL SetActorFrame

; SetActorFrame's inline words: the frame table $C5A0, the set $C3D5
SpiritFrameSet:
  DEFB $A0,$C5,$D5,$C3

; State 1: flap (frames 6 and 7), bob along SpiritBobSteps, fire, burst when
; hit, at random fade
;
; +8 XOR 1; +$0B counts 0-19 and +$0E (the base Y) += SpiritBobSteps[+$0B]. Hit
; (+9 bit 4, by the hero's sword or bolt): SpiritBurst. SpiritFires. With the
; hero dying (state $0F) one pass in four goes to state 2, else one in 32
; (Random & $1F = $1B). Then SpiritDraw.
;
; Witness: L1 403 (rzx-r2, s2-right, stageload).
SpiritFloat:
  LD A,(IY+$08)
  XOR $01
  LD (IY+$08),A
  LD A,(IY+$0B)
  INC A
  CP $14
  JR NZ,SpiritBob
  XOR A
SpiritBob:
  LD (IY+$0B),A
  LD C,A
  LD B,$00
  LD HL,SpiritBobSteps
  ADD HL,BC
  LD A,(IY+$0E)
  ADD A,(HL)
  LD (IY+$0E),A
  BIT 4,(IY+$09)
  JP NZ,BurstSpirit
  CALL SpiritFires
  LD A,(HeroState)
  CP $0F
  JR NZ,SpiritMayFade
  CALL Random
  AND $03
  JR NZ,SpiritDraw
  INC (IY+$0A)
  JR SpiritDraw
SpiritMayFade:
  CALL Random
  AND $1F
  CP $1B
  JR NZ,SpiritDraw
  INC (IY+$0A)
  JR SpiritDraw

; The spirit's Y change at bob steps 0-19 (down 1-3, back up)
;
; Read by SpiritFloat ($906B).
SpiritBobSteps:
  DEFB $01,$01,$02,$02,$03,$03,$02,$02,$01,$01,$FF,$FF,$FE,$FE,$FD,$FD,$FE,$FE,$FF,$FF

; State 2: frames back down to 0, then SpiritCount - 1 and the record freed
;
; +8 - 1 each acting pass; at 0 SpiritCount - 1 and RemoveActor. s2-right: 7
; spirits faded, rzx-r2: 1.
;
; Witness: L1 54 (rzx-r2, s2-right, stageload).
SpiritShrinks:
  DEC (IY+$08)
  JR NZ,SpiritDraw
  LD HL,SpiritCount
  DEC (HL)
  JP RemoveActor

; Every 16 passes (by the spirit's column) six shots in the directions of
; SpiritShotDirections, effect 6
;
; When (PassCounter + X) & 15 is 0: six missiles of kind 1 (UpdateAimedShot)
; from X + 1, (Y + 4) AND $F8 with the directions 1, 2, 3, 5, 6, 7 ($B3BD, C =
; 1, B = the direction), then PlaySoundVector 6. s2-right: 26 volleys, rzx-r2:
; 13.
;
; Witness: L1 403 (rzx-r2, s2-right, stageload).
SpiritFires:
  LD A,(PassCounter)
  ADD A,(IY+$00)
  AND $0F
  RET NZ
  LD B,$06
  LD HL,SpiritShotDirections
SpiritFiresNext:
  PUSH HL
  PUSH BC
  LD D,(IY+$00)
  INC D
  LD A,(IY+$01)
  ADD A,$04
  AND $F8
  LD E,A
  LD C,$01
  LD B,(HL)
  CALL AddMissile
  POP BC
  POP HL
  INC HL
  DJNZ SpiritFiresNext
  LD DE,$0006
  CALL PlaySoundVector
  RET

; The six directions of a spirit's volley (ShotDirections' numbers; no straight
; up or down)
;
; Read by SpiritFires ($90CC).
SpiritShotDirections:
  DEFB $01,$02,$03,$05,$06,$07

  ORG $9E21

; Draw the hydra's body picture into the play buffer: all of it in room 7, its
; top in room 3
;
; Called every pass from the main loop ($785E) and by LeaveRoomRight ($9829,
; before the room appears). Only in grid 1 (GridNumber $FE54 = 1) while the
; hydra lives (HydraHeadsLeft $FE5F not $64). Room 7: DrawRowPicture $8B2A
; draws the row-packed picture HydraBodyPicture $D967 from the buffer address
; $5C12 (line 8, byte column $12), 112 lines. Room 3 (the room above it): the
; same picture from $6712 (line 96), 48 lines: its top shows at the bottom of
; room 3.
;
; In rzx-r2 it draws in room 7 343 times and in room 3 166 times (screens
; 010562.png, 011021.png: room 3 with the body's top; 013279.png, 013504.png:
; room 7).
;
; Witness: L1 8050 (rzx-r2, s2-right, stageload).
DrawHydraBody:
  LD A,(GridNumber)
  CP $01
  RET NZ
  LD A,(HydraHeads)
  CP $64
  RET Z
  LD A,(RoomNumber)
  CP $07
  JR Z,DrawHydraBodyRoom7
  CP $03
  JR Z,DrawHydraBodyRoom3
  RET
DrawHydraBodyRoom3:
  LD HL,HydraBodyPicture
  LD DE,PlayBuffer+3090
  LD B,$30
  JP DrawRowPicture
DrawHydraBodyRoom7:
  LD HL,HydraBodyPicture
  LD DE,PlayBuffer+274
  LD B,$70
  JP DrawRowPicture

; Colour the hydra's body in the shadow attributes: a speckle of green and
; cyan, its eyes and mouth
;
; Called every pass from the main loop ($7858) and by LeaveRoomRight ($982C).
; Only in grid 1. Room 7: 13 rows of 15 cells from $6DCF (screen row 6, column
; 15) get green or cyan at random (SpeckleHydra $9E94); then, while the hydra
; lives (HydraHeadsLeft $FE5F not $64), FillShadowAttributes $8C93 with its
; five bytes $17, $90, 6, 3, $41 and the cells $6F37 = $41 (blue on red) and
; $6F58, $6F59, $6F78, $6F79, $6F98 = $44 (bright green). Room 3: 13 rows of 15
; cells from $6E70 (row 11, column 16) speckled.
;
; The speckle keeps colouring room 7 after the hydra is beaten; DrawHydraBody
; draws no body then.
;
; Witness: L1 8050 (rzx-r2, s2-right, stageload).
ColourHydra:
  LD A,(GridNumber)
  CP $01
  RET NZ
  LD A,(RoomNumber)
  CP $03
  JR Z,ColourHydraRoom3
  CP $07
  RET NZ
  LD HL,PlayAttributesCell+$000D
  LD B,$0D
  CALL SpeckleHydra
  LD A,(HydraHeads)
  CP $64
  RET Z
  CALL FillShadowAttributes
  DEFB $17,$90,$06,$03,$41
  LD HL,PlayAttributesCell+$0175
  LD (HL),$41
  LD A,$44
  LD HL,PlayAttributesCell+$0196
  LD (HL),A
  INC L
  LD (HL),A
  LD BC,$001F
  ADD HL,BC
  LD (HL),A
  INC L
  LD (HL),A
  LD BC,$0020
  ADD HL,BC
  LD (HL),A
  RET
ColourHydraRoom3:
  LD HL,PlayAttributesCell+$00AE
  LD B,$0D

; Colour B rows of 15 shadow cells from HL with 4 or 5 (green or cyan) at
; random
;
; The colours come from the ROM bytes from $0000 (DE = 0, bit 0 of each byte):
; the same speckle every pass, since DE
;
; starts at 0 each call. HL steps 32 a row. Called by ColourHydra $9E64 (room
; 7, 764 calls in rzx-r2) and $9E92
;
; (room 3, 166).
;
; Witness: L1 930 (rzx-r2).
SpeckleHydra:
  LD DE,$0000
SpeckleHydraRow:
  PUSH BC
  PUSH HL
  LD B,$0F
SpeckleHydraCell:
  LD A,(DE)
  INC E
  AND $01
  ADD A,$04
  LD (HL),A
  INC L
  DJNZ SpeckleHydraCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  POP BC
  DJNZ SpeckleHydraRow
  RET

; Move the hydra's three necks a step, draw them and put each head at its
; neck's end
;
; Called every pass from the main loop ($7852). Only in grid 1, rooms 7 and 3.
; Runs the second neck (HydraNeck2Step $9F31), the first (HydraNeck1Step $9EEC)
; and the third (HydraNeck3Step $9F75); after each, IX points past the neck's
; last drawn point and the point (IX-2: the column in pixels from the play
; area's left, IX-1: the line) is kept for the head's handler: neck 1 in
; HydraHead1X/Y $FE4D/$FE4E, neck 2 in $FE4F/HydraHead2Y $FE50, neck 3 in
; HydraHead3X/Y $FE51/$FE52.
;
; The heads are actors of the kinds 7 and 9 (room 7) and 8 and 10 (room 3)
; whose handlers ($7FB5, $7FEB, $8023, $805B) read these bytes (+$18 across,
; the line - $0A: $8100). In room 3 the third neck is not drawn and its head
; bytes take the second neck's point (IX is left from it).
;
; In rzx-r2: 930 passes (764 in room 7, 166 in room 3); s2-right never enters
; grid 1's rooms 3 and 7.
;
; Witness: L1 8031 (rzx-r2, s2-right, stageload).
UpdateHydraNecks:
  LD A,(GridNumber)
  CP $01
  RET NZ
  LD A,(RoomNumber)
  CP $07
  JR Z,UpdateHydraNecksDraw
  CP $03
  RET NZ
UpdateHydraNecksDraw:
  CALL HydraNeck2Step
  LD A,(IX-$02)
  LD (Hydra2X),A
  LD A,(IX-$01)
  LD (Hydra2Y),A
  CALL HydraNeck1Step
  LD A,(IX-$02)
  LD (Hydra1X),A
  LD A,(IX-$01)
  LD (Hydra1Y),A
  CALL HydraNeck3Step
  LD A,(IX-$02)
  LD (Hydra3X),A
  LD A,(IX-$01)
  LD (Hydra3Y),A
  RET

; The first neck: its step, its pose, its length, then draw it
;
; The step $FE43 counts 0 to $14 a pass; past $14 it starts again at $0E (a
; sway), or at 0 (the long strike) one time
;
; in four (Random $8BAC AND 3 = 0). The pose $FE44 = HydraNeck1Poses[step]
; (0-9). The length byte $FE5C goes through
;
; NeckLength $9FB3 (E = the segments, 7 at most). IX = HydraNeck1Points + pose
; x 14; room 3 draws it 80 lines lower
;
; (DrawNeckLow $A0B5, C = $50), room 7 8 lines higher (DrawNeckHigh $9FC4, C =
; $F8).
;
; Witness: L1 930 (rzx-r2).
HydraNeck1Step:
  LD A,(Hydra1Step)
  INC A
  CP $15
  JR NZ,HydraNeck1Pose
  CALL Random
  AND $03
  JR Z,HydraNeck1Restart
  LD A,$0E
  JR HydraNeck1Pose
HydraNeck1Restart:
  LD A,$00
HydraNeck1Pose:
  LD (Hydra1Step),A
  LD C,A
  LD B,$00
  LD HL,HydraNeck1Poses
  ADD HL,BC
  LD A,(HL)
  LD (Hydra1Pose),A
  LD B,$07
  LD A,(Hydra1Neck)
  CALL NeckLength
  LD (Hydra1Neck),A
  LD IX,HydraNeck1Points
  LD A,(RoomNumber)
  CP $03
  JR Z,HydraNeck1Room3
  LD C,$F8
  LD A,(HL)
  JP DrawNeckHigh
HydraNeck1Room3:
  LD C,$50
  LD A,(HL)
  JP DrawNeckLow

; The second neck: its step, its pose, its length, then draw it
;
; As HydraNeck1Step $9EEC with the step $FE45 (0 to $13, then $0E, or 0 one
; time in two), the pose $FE46 =
;
; HydraNeck2Poses[step] (1-9), the length byte $FE5D (11 segments at most),
; HydraNeck2Points (22 bytes a pose);
;
; room 3 draws it 32 lines lower (C = $20), room 7 56 lines higher (C = $C8:
; clipped at the top, DrawNeckHigh).
;
; Witness: L1 930 (rzx-r2).
HydraNeck2Step:
  LD A,(Hydra2Step)
  INC A
  CP $14
  JR NZ,HydraNeck2Pose
  CALL Random
  AND $01
  JR Z,HydraNeck2Restart
  LD A,$0E
  JR HydraNeck2Pose
HydraNeck2Restart:
  LD A,$00
HydraNeck2Pose:
  LD (Hydra2Step),A
  LD C,A
  LD B,$00
  LD HL,HydraNeck2Poses
  ADD HL,BC
  LD A,(HL)
  LD (Hydra2Pose),A
  LD B,$0B
  LD A,(Hydra2Neck)
  CALL NeckLength
  LD (Hydra2Neck),A
  LD IX,HydraNeck2Points
  LD A,(RoomNumber)
  CP $03
  JR Z,HydraNeck2Room3
  LD C,$C8
  LD A,(HL)
  JR DrawNeckHigh
HydraNeck2Room3:
  LD C,$20
  LD A,(HL)
  JP DrawNeckLow

; The third neck: its step, its pose, its length, then draw it (room 7 only)
;
; The step $FE41 (0 to $12, then $0E, or 0 one time in eight), the pose $FE42 =
; HydraNeck3Poses[step] (0-7), the
;
; length byte $FE5E (7 segments at most), HydraNeck3Points (14 bytes a pose),
; drawn 32 lines lower (DrawNeckLow, C =
;
; $20). Not drawn in room 3 (RET Z at $9FA8 after the length).
;
; Witness: L1 930 (rzx-r2).
HydraNeck3Step:
  LD A,(Hydra3Step)
  INC A
  CP $13
  JR NZ,HydraNeck3Pose
  CALL Random
  AND $07
  JR Z,HydraNeck3Restart
  LD A,$0E
  JR HydraNeck3Pose
HydraNeck3Restart:
  LD A,$00
HydraNeck3Pose:
  LD (Hydra3Step),A
  LD C,A
  LD B,$00
  LD HL,HydraNeck3Poses
  ADD HL,BC
  LD A,(HL)
  LD (Hydra3Pose),A
  LD B,$07
  LD A,(Hydra3Neck)
  CALL NeckLength
  LD (Hydra3Neck),A
  LD A,(RoomNumber)
  CP $03
  RET Z
  LD C,$20
  LD A,(HL)
  LD IX,HydraNeck3Points
  JP DrawNeckLow

; E = the neck's segments from its length byte A; a cut neck (bit 7) shrinks
; one a pass
;
; A = the length byte ($FE5C, $FE5D or $FE5E: twice the segments). With bit 7
; set (the head was killed: $7FCD, $8003,
;
; $803B) and above $80, A - 1. Out: C = A = the new byte (the caller stores
; it), E = (A AND $7F) / 2.
;
; Called by the three neck steps ($9F14, $9F59, $9F9D), 930 times each in
; rzx-r2.
;
; Witness: L1 2790 (rzx-r2).
NeckLength:
  BIT 7,A
  JR Z,NeckLengthSplit
  CP $80
  JR Z,NeckLengthSplit
  DEC A
NeckLengthSplit:
  LD C,A
  AND $7F
  SRL A
  LD E,A
  LD A,C
  RET

; Draw E segments of a neck from the pose IX, the lines less n (clipped at the
; top)
;
; In: A = the pose, B = the points of a pose, IX = the neck's points, C = the
; line change (its negative n is written
;
; into the SUB n at NeckLineUp $9FF3), E = the segments. IX = IX + pose x 2B
; (the multiply $8B4B). Each segment: a
;
; point (+0 the pixel column from the play area's left, +1 the line); the image
; is NeckSegments $C684 + (column AND
;
; 7) x 16 (2 bytes x 8 lines, pre-shifted); at line - n it is ORed into the
; play buffer at $5B00 + line x 32 +
;
; column / 8 + 6 (OrNeckSegment $A066). A segment 1-7 lines above the top is
; drawn from the line it shows: the CALL
;
; at $A034 is aimed past the hidden rows (NeckSkipCall), DE past their bytes;
; one higher is skipped.
;
; Used for the first neck (n = 8) and the second (n = $38) in room 7: 764 calls
; each in rzx-r2. The top clip
;
; ($9FF8-$A037) is not executed in any recording (the recordings checked:
; s2-right, rzx-r2); known only from the code.
;
; Witness: L1 1528 (rzx-r2).
DrawNeckHigh:
  PUSH BC
  PUSH DE
  SLA B
  PUSH IX
  CALL Multiply
  POP BC
  ADD HL,BC
  PUSH HL
  POP IX
  POP DE
  POP BC
  LD A,C
  NEG
  LD (NeckLineUp+$0001),A
  LD A,E
  CP $00
  RET Z
  LD B,E

; DrawNeckHighLoop
DrawNeckHighLoop:
  PUSH BC
  LD A,(IX+$00)
  AND $07
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,NeckSegments
  ADD HL,BC
  LD A,(IX+$01)
NeckLineUp:
  SUB $00                 ; SUB n: n = the line change (written above)
  LD E,A
  JR NC,DrawNeckHighFull
  CP $F9
  JR C,DrawNeckHighNext
DrawNeckHighClip:
  PUSH HL                 ; the segment starts above the top: skip its hidden
                          ; rows
  LD HL,PlayBuffer
  LD A,(IX+$00)
  SRL A
  SRL A
  SRL A
  ADD A,$06
  LD C,A
  LD B,$00
  ADD HL,BC
  PUSH HL
  LD A,E
  NEG
  LD E,A
  JR Z,DrawNeckHighNext
  LD L,A
  LD H,$00
  ADD HL,HL
  PUSH HL
  ADD HL,HL
  ADD HL,HL
  POP BC
  ADD HL,BC
  LD BC,OrNeckSegment
  ADD HL,BC
  LD (NeckSkipCall+$0001),HL
  LD A,E
  SLA A
  LD C,A
  LD B,$00
  POP HL
  POP DE
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  LD BC,$001F
NeckSkipCall:
  CALL OrNeckSegment      ; CALL n: n = OrNeckSegment + 10 x the hidden rows
                          ; (written above)
  JR DrawNeckHighNext
DrawNeckHighFull:
  PUSH HL
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,(IX+$00)
  SRL A
  SRL A
  SRL A
  ADD A,$06
  LD C,A
  LD B,$00
  ADD HL,BC
  LD BC,PlayBuffer
  ADD HL,BC
  POP DE
  LD BC,$001F
  CALL OrNeckSegment
DrawNeckHighNext:
  INC IX
  INC IX
  POP BC
  DEC B
  JP NZ,DrawNeckHighLoop
  RET

; OR 2 bytes x 8 lines from DE into the play buffer at HL (BC = 31)
;
; Unrolled: 10 bytes of code a row, so an entry 10 x k bytes in skips k rows
; (DrawNeckHigh's top clip). E steps
;
; through the image (it must not cross a 256-byte page). 6560 calls in rzx-r2.
;
; Witness: L1 6560 (rzx-r2).
OrNeckSegment:
  LD A,(DE)
  OR (HL)
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  OR (HL)
  LD (HL),A
  ADD HL,BC
  INC E
  LD A,(DE)
  OR (HL)
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  OR (HL)
  LD (HL),A
  ADD HL,BC
  INC E
  LD A,(DE)
  OR (HL)
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  OR (HL)
  LD (HL),A
  ADD HL,BC
  INC E
  LD A,(DE)
  OR (HL)
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  OR (HL)
  LD (HL),A
  ADD HL,BC
  INC E
  LD A,(DE)
  OR (HL)
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  OR (HL)
  LD (HL),A
  ADD HL,BC
  INC E
  LD A,(DE)
  OR (HL)
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  OR (HL)
  LD (HL),A
  ADD HL,BC
  INC E
  LD A,(DE)
  OR (HL)
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  OR (HL)
  LD (HL),A
  ADD HL,BC
  INC E
  LD A,(DE)
  OR (HL)
  LD (HL),A
  INC L
  INC E
  LD A,(DE)
  OR (HL)
  LD (HL),A
  RET

; Draw E segments of a neck from the pose IX, the lines plus n (cut at the play
; area's bottom)
;
; As DrawNeckHigh $9FC4, with C written into the ADD A,n at NeckLineDown $A0E2;
; a segment at line $90 and below is
;
; not drawn. Used in room 3 for the first neck (n = $50) and the second (n =
; $20), in room 7 for the third (n =
;
; $20): 1096 calls in rzx-r2.
;
; Witness: L1 1096 (rzx-r2).
DrawNeckLow:
  PUSH BC
  PUSH DE
  SLA B
  PUSH IX
  CALL Multiply
  POP BC
  ADD HL,BC
  PUSH HL
  POP IX
  POP DE
  POP BC
  LD A,C
  LD (NeckLineDown+$0001),A
  LD A,E
  CP $00
  RET Z
  LD B,E
DrawNeckLowLoop:
  PUSH BC
  LD A,(IX+$00)
  AND $07
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,NeckSegments
  ADD HL,BC
  LD A,(IX+$01)
NeckLineDown:
  ADD A,$00               ; ADD A,n: n = the line change (written above)
  CP $90
  JR NC,DrawNeckLowNext
  PUSH HL
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,(IX+$00)
  SRL A
  SRL A
  SRL A
  ADD A,$06
  LD C,A
  LD B,$00
  ADD HL,BC
  LD BC,PlayBuffer
  ADD HL,BC
  POP DE
  LD BC,$001F
  CALL OrNeckSegment
DrawNeckLowNext:
  INC IX
  INC IX
  POP BC
  DJNZ DrawNeckLowLoop
  RET

; The first neck's pose (0-9) at each step 0-$14
;
; Read by HydraNeck1Step $9F0B: 4, 5, 6, 7, 8, 9, 9, 9, 9, 8, 7, 6, 5, 4, 3, 2,
; 1, 0, 1, 2, 3 (the long strike from
;
; step 0, the sway from $0E).
HydraNeck1Poses:
  DEFB $04,$05,$06,$07,$08,$09,$09,$09,$09,$08,$07,$06,$05,$04,$03,$02,$01,$00,$01,$02,$03

; The first neck's 10 poses: 7 points (pixel column, line) each, from the body
; out
;
; Read by DrawNeckHigh / DrawNeckLow through IX (HydraNeck1Step $9F1A). The
; last point drawn is the head's place.
HydraNeck1Points:
  DEFB $58,$42,$54,$3A,$54,$31,$57,$29,$5A,$21,$59,$19,$52,$14
  DEFB $57,$41,$54,$38,$56,$30,$5A,$28,$5C,$20,$58,$18,$50,$14
  DEFB $57,$3F,$55,$37,$57,$2E,$5B,$26,$5C,$1D,$57,$16,$4E,$14
  DEFB $58,$3E,$55,$36,$56,$2D,$5A,$25,$59,$1C,$54,$16,$4C,$13
  DEFB $58,$3D,$53,$36,$53,$2D,$57,$25,$57,$1C,$52,$15,$4A,$13
  DEFB $59,$3B,$54,$34,$52,$2B,$53,$22,$51,$19,$49,$15,$40,$15
  DEFB $5B,$39,$56,$32,$54,$2A,$51,$22,$4B,$1C,$43,$19,$3A,$19
  DEFB $5D,$38,$58,$31,$53,$2A,$4D,$24,$46,$20,$3E,$1E,$35,$1E
  DEFB $5E,$38,$5B,$30,$56,$29,$4F,$24,$46,$22,$3D,$22,$34,$24
  DEFB $60,$37,$5C,$2F,$56,$28,$4E,$24,$45,$22,$3C,$23,$33,$26

; The second neck's pose (1-9) at each step 0-$13
;
; Read by HydraNeck2Step $9F50.
HydraNeck2Poses:
  DEFB $04,$05,$06,$07,$08,$09,$09,$09,$09,$09,$08,$07,$06,$05,$04,$03,$02,$01,$02,$03

; The second neck's poses 0-10: 11 points (pixel column, line) each
;
; Read through IX from HydraNeck2Step $9F5F. The poses are 1-9: pose 0
; ($A1C8-$A1DD) is read only at its last point
;
; ($A1DC-$A1DD, the head's place when no segment shows) and pose 10
; ($A2A4-$A2B9) is never read (the recordings
;
; checked: s2-right, rzx-r2; no pose table holds 10).
HydraNeck2Points:
  DEFB $11,$04,$0C,$0B,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$72,$12
  DEFB $6A,$4A,$6D,$41,$72,$3A,$79,$35,$80,$2F,$86,$28,$89,$20,$88,$17,$82,$11,$79,$10,$70,$11
  DEFB $6B,$49,$6E,$40,$73,$38,$7A,$32,$82,$2D,$88,$26,$8A,$1D,$88,$14,$81,$0F,$78,$0E,$6F,$11
  DEFB $6C,$48,$6E,$3F,$73,$37,$7B,$32,$83,$2D,$87,$25,$89,$1C,$87,$13,$7F,$0E,$76,$0E,$6D,$11
  DEFB $6D,$47,$6F,$3E,$75,$37,$7C,$32,$83,$2C,$87,$24,$88,$1B,$84,$13,$7C,$0E,$73,$0E,$6A,$11
  DEFB $6F,$47,$71,$3E,$76,$37,$7C,$31,$81,$2A,$82,$21,$7F,$19,$79,$12,$71,$0F,$68,$10,$5F,$12
  DEFB $71,$47,$72,$3E,$76,$36,$7B,$2F,$7F,$27,$7F,$1E,$7B,$17,$74,$11,$6B,$10,$62,$11,$59,$14
  DEFB $72,$47,$73,$3E,$76,$36,$7B,$2E,$7D,$25,$7B,$1C,$75,$15,$6E,$11,$66,$0F,$5D,$11,$55,$14
  DEFB $73,$47,$74,$3F,$78,$37,$7B,$2F,$7B,$26,$77,$1E,$72,$17,$6A,$13,$61,$11,$58,$13,$4F,$17
  DEFB $75,$48,$78,$40,$79,$37,$78,$2E,$75,$26,$70,$1F,$69,$1A,$61,$17,$59,$16,$50,$17,$47,$1A
  DEFB $76,$49,$79,$40,$78,$37,$74,$2F,$6E,$28,$67,$22,$5F,$1E,$56,$1B,$4D,$1A,$43,$1B,$3A,$1E

; The third neck's pose (0-7) at each step 0-$12
;
; Read by HydraNeck3Step $9F94.
HydraNeck3Poses:
  DEFB $03,$04,$05,$06,$07,$07,$07,$07,$07,$07,$06,$05,$04,$03,$02,$01,$00,$01,$02

; The third neck's 8 poses: 7 points (pixel column, line) each
;
; Read through IX from HydraNeck3Step $9FAC.
HydraNeck3Points:
  DEFB $60,$40,$58,$42,$51,$3D,$51,$34,$55,$2C,$53,$24,$4B,$22
  DEFB $5F,$40,$57,$42,$50,$3D,$50,$35,$53,$2D,$4F,$25,$47,$22
  DEFB $5E,$3F,$56,$43,$4E,$40,$4D,$37,$4F,$2F,$4D,$26,$45,$22
  DEFB $5D,$3D,$55,$41,$4D,$3E,$4B,$36,$4D,$2D,$4B,$25,$43,$22
  DEFB $5D,$3C,$55,$3C,$4F,$36,$4D,$2F,$4B,$28,$47,$21,$3F,$1F
  DEFB $5D,$3B,$55,$39,$4F,$33,$4D,$2B,$4A,$24,$43,$1F,$3B,$1E
  DEFB $5C,$3A,$55,$36,$50,$2F,$4C,$27,$46,$21,$3E,$1E,$35,$1E
  DEFB $5C,$39,$56,$33,$50,$2D,$4A,$27,$43,$22,$3B,$1F,$32,$1E

  ORG $A6EC

; Kind 0: the kneeling statue in the temple's first room; the high strike
; breaks it into an item
;
; The handler of ActorKinds kind 0 ($9608), placed in grid 0 at cells 20, 9.
; Removed once KneelStatueBroken $FE55 is 1. It shows frame 3 (3 bytes x 35
; lines) of the statues' set (StatueFrame $A70E). When the hero's column + 4 or
; + 3 is its column and the hero's high strike is at its hitting frame ($816D:
; state 6, frame 7), $9A41 breaks it: KneelStatueBroken = 1, a burst of the
; shape $EECA, item kind 1 (amount $24) at column $14, line $60 (SpawnItem
; $9A6E), five fragments at $13, $75.
;
; In s2-right it shows 32 passes (screen 000500.scr), in rzx-r2 330
; (000520.png: the white kneeling figure on its plinth); rzx-r2 breaks it once.
;
; Witness: L1 443 (rzx-r2, s2-right, stageload).
KneelingStatueActor:
  LD A,(Statue0Broken)
  CP $01
  JP Z,RemoveActor
  LD (IY+$08),$03
  LD A,(HeroRecord)
  ADD A,$04
  CP (IY+$00)
  JR Z,StatueFrame
  DEC A
  CP (IY+$00)
  JR NZ,StatueFrame
  CALL IsHeroStrikeFrame
  JP Z,BreakStatue0

; Show the actor's frame +8 of the statues' set (StatueSet)
;
; The common end of KneelingStatueActor $A6EC and WarriorStatueActor $A718:
; SetActorFrame $AC52 with the four bytes
;
; after the CALL, returning to the handler's caller.
;
; Witness: L1 1960 (rzx-r2, s2-right, stageload).
StatueFrame:
  LD A,(IY+$08)
  CALL SetActorFrame

; SetActorFrame's parameters: the statues' frame table $E0A4, their graphics
; $DF45
;
; Four frames: 0 the warrior's head (3 x 14), 1 his body with the shield (5 x
; 30), 2 his legs (3 x 18), 3 the kneeling
;
; statue (3 x 35).
StatueSet:
  DEFW StatueFrameTable,StatueSprites

; Kinds 1, 14, 15: a part of the warrior statue; six strikes on it smash all
; three parts
;
; The handler of ActorKinds kinds 1, 14 and 15 ($9611, $9686, $968F), all
; placed in grid 0 at cells 41, 6: frames 0, 1 and 2 of StatueSet (+8 from the
; kind), colour $47 (white). WarriorStatueState $FE56: 0 standing, 1-3 the hit
; flash (colour $43, magenta, one pass each), $C8 smashed (each part removes
; itself).
;
; Only the part with +$0F bit 3 (kind 15) takes the strike: when the hero's
; column + 3 or + 4 is its column and the high strike is at its hitting frame
; ($816D), effect 2 (PlaySoundVector) and +$0B (6 at the start) - 1; at 0 $9A14
; smashes the statue: WarriorStatueState = $C8, a burst of the shape $EECA,
; item kind 2 (amount 1, picture $DEE5) at column $14, line $60, seven
; fragments at $14, $75; else the flash (WarriorStatueState = 3).
;
; In s2-right 735 passes (the statue stands); in rzx-r2 438 passes, six hits
; and the smash (screens 002017.png: the white warrior with the shield,
; 002530.png: only the plinth is left).
;
; Witness: L1 1527 (rzx-r2, s2-right, stageload).
WarriorStatueActor:
  LD (IY+$0C),$47
  LD A,(Statue1State)
  CP $C8
  JP Z,RemoveActor
  CP $00
  JR Z,WarriorStatueHit
  DEC A
  LD (Statue1State),A
  LD (IY+$0C),$43
  JR StatueFrame
WarriorStatueHit:
  BIT 3,(IY+$0F)
  JR Z,StatueFrame
  LD A,(HeroRecord)
  ADD A,$03
  CP (IY+$00)
  JR Z,WarriorStatueStrike
  INC A
  CP (IY+$00)
  JR NZ,StatueFrame
WarriorStatueStrike:
  CALL IsHeroStrikeFrame
  JR NZ,StatueFrame
  LD DE,$0002
  CALL PlaySoundVector
  DEC (IY+$0B)
  JP Z,BreakStatue1
  LD A,$03
  LD (Statue1State),A
  JR StatueFrame

; Kind 13: the flame of the lamp the harpy comes from; it wakes the harpy when
; the hero walks by
;
; The handler of ActorKinds kind 13 ($967D), placed in grid 0 at cells 84, 10
; with the kinds 2 and 3 (the lamp and the
;
; harpy). Removed once HarpyPhase $FE5A is not 0. HeroNearGlow $B4AF sets its
; colour: white ($47) while the hero is left
;
; of column 9, the frame is then 5 (1 x 3: a spark); else +8 counts 0-$4F and
; the frame is HarpyFlameFrames[+8 / 2]
;
; (5, then 6-$0B: the flame flickers). +$0B (12 at the start) counts down a
; pass; at 0, with +8 under $30 and the hero
;
; walking or jumping (state 1 or 2), HarpyPhase = 1 (the harpy wakes) and the
; flame is removed.
;
; In s2-right 28 passes and the wake once; rzx-r2 37 passes and the wake.
;
; Witness: L1 65 (rzx-r2, s2-right).
HarpyFlameActor:
  LD A,(HarpyPhase)
  CP $01
  JP NC,RemoveActor
  CALL HeroNearGlow
  LD A,(IY+$0C)
  CP $47
  JR NZ,HarpyFlameStep
  LD A,$05
  JR HarpyLampFrame
HarpyFlameStep:
  INC (IY+$08)
  LD A,(IY+$08)
  CP $50
  JR NZ,HarpyFlameCount
  LD (IY+$08),$00
HarpyFlameCount:
  LD A,(IY+$0B)
  CP $00
  JR Z,HarpyFlameWake
  DEC A
  LD (IY+$0B),A
  JR HarpyFlameShow
HarpyFlameWake:
  LD A,(IY+$08)
  CP $30
  JR NC,HarpyFlameShow
  LD A,(HeroState)
  CP $00
  JR Z,HarpyFlameShow
  CP $03
  JR NC,HarpyFlameShow
  LD A,$01
  LD (HarpyPhase),A
  JP RemoveActor
HarpyFlameShow:
  LD A,(IY+$08)
  SRL A
  LD C,A
  LD B,$00
  LD HL,HarpyFlameFrames
  ADD HL,BC
  LD A,(HL)
  JR HarpyLampFrame

; The flame's frame (of HarpyLampSet) for each pair of passes 0-$27
;
; Read by HarpyFlameActor $A7B7: 24 x 5, then 6, 7, 8, 9, $0A, $0B, $0A, 9, 8,
; 9, $0A, $0B, $0A, 9, 7, 6. In the
;
; two recordings only $A7BA-$A7BF were read.
HarpyFlameFrames:
  DEFB $05,$05,$05,$05,$05,$05,$05,$05
  DEFB $05,$05,$05,$05,$05,$05,$05,$05
  DEFB $05,$05,$05,$05,$05,$05,$05,$05
  DEFB $06,$07,$08,$09,$0A,$0B,$0A,$09
  DEFB $08,$09,$0A,$0B,$0A,$09,$07,$06

; Kind 2: the lamp hanging from the ceiling (frame 0 of HarpyLampSet, 4 x 12)
;
; The handler of ActorKinds kind 2 ($961A). Removed once HarpyPhase $FE5A is
; not 0. Its colour by HeroNearGlow $B4AF.
;
; In s2-right 29 passes, rzx-r2 38.
;
; Witness: L1 67 (rzx-r2, s2-right).
HarpyLampActor:
  LD A,(HarpyPhase)
  CP $01
  JP NC,RemoveActor
  CALL HeroNearGlow
  LD A,$00

; Show frame A of HarpyLampSet
;
; The common end of HarpyFlameActor, HarpyLampActor and HarpyRiseActor; also
; jumped to from $9B4C (another range).
;
; Witness: L1 288 (rzx-r2, s2-right).
HarpyLampFrame:
  CALL SetActorFrame

; SetActorFrame's parameters: the frame table $E54F (22 frames), the graphics
; $E229
;
; Frame 0 the lamp (4 x 12), 1-4 the harpy asleep (3 x 8), 5-$0B the flame (1 x
; 3 to 2 x 8).
HarpyLampSet:
  DEFW HarpyLampFrameTable,HarpyLampSprites

; Kind 3: the harpy under the lamp; it rises (HarpyPhase 1) into the flying
; harpy
;
; The handler of ActorKinds kind 3 ($9623), placed with the lamp. By HarpyPhase
; $FE5A: 4 and up, removed; under the
;
; hero's column a touch costs 4 energy (DamageHero $8774, when the hero's
; column is not under its own: $A80D).
;
; Phase 0 ($A87D): asleep: +8 counts 0-7, the frame 1 while white (HeroNearGlow
; $B4AF), else +8 / 2 + 1 (frames 1-4 of
;
; HarpyLampSet). The hero in the middle strike (state 5) at base column $0F or
; more with its pass counter +$10 at $0E
;
; sets phase 2 (not executed in any recording).
;
; Phase 1 (the wake, set by the flame): its colour cycles (CycleItemInk $A8EB),
; +$0B counts 0-$16 and the frame is
;
; HarpyRiseFrames[+$0B] of HarpyRiseSet (4 x 20, 3 x 28, 3 x 27, 4 x 24: it
; stands up); at $17 HarpyPhase = 3, $8DA4
;
; spawns the flying harpy (two records from the templates $96E8 and $96FA at
; columns $12-$13, lines $4E and $62) and
;
; this record is removed.
;
; Phases 2 and $0A ($A817): +8 counts from $13 to $16 again and again, the base
; line goes 8 up each round ($8F84),
;
; HarpyPhase = $0A, the frames come from HarpyRiseFrames + $17 (from $0C) of
; HarpyLampSet; it vanishes (RET, no frame)
;
; once its line is under 8. The recordings checked (s2-right, rzx-r2) never run
; $A817-$A845: phase 2 is known only
;
; from the code.
;
; In s2-right 50 passes and the rise (screen 000500.scr: the green figure under
; the lamp), in rzx-r2 59.
;
; Witness: L1 109 (rzx-r2, s2-right).
HarpyRiseActor:
  LD A,(HarpyPhase)
  CP $0A
  JR Z,HarpyRiseUp
  CP $04
  JP NC,RemoveActor
  LD A,(HeroRecord)
  CP (IY+$00)
  JP C,HarpyRisePhase
  LD C,$04
  CALL DamageHero
HarpyRisePhase:
  LD A,(HarpyPhase)
  CP $02
  JR NZ,HarpyRiseWake
HarpyRiseUp:
  INC (IY+$08)
  LD A,(IY+$08)
  CP $17
  JR NZ,HarpyRiseUpFrame
  LD (IY+$08),$13
  DEC (IY+$0D)
  LD C,$F8
  CALL MoveActorY
  LD A,$0A
  LD (HarpyPhase),A
  LD A,(IY+$01)
  CP $08
  JR C,HarpyRiseGone
HarpyRiseUpFrame:
  LD C,(IY+$08)
  LD B,$00
  LD HL,HarpyFallFrames
  ADD HL,BC
  LD A,(HL)
  JR HarpyLampFrame
HarpyRiseGone:
  RET
HarpyRiseWake:
  CP $01
  JR NZ,HarpyRiseAsleep
  CALL CycleItemInk
  LD A,(IY+$0B)
  INC A
  CP $17
  JR NZ,HarpyRiseWakeFrame
  LD A,$03
  LD (HarpyPhase),A
  PUSH IY
  CALL SpawnHarpy
  POP IY
  JP RemoveActor
HarpyRiseWakeFrame:
  LD (IY+$0B),A
  LD C,A
  LD B,$00
  LD IX,HarpyRiseFrames
  ADD IX,BC
  LD A,(IX+$00)
  LD (IY+$08),A
  CALL SetActorFrame

; SetActorFrame's parameters: the frame table $E211 (4 frames), the graphics
; $E0BC
HarpyRiseSet:
  DEFW HarpyRiseFrameTable,HarpyRiseSprites

; HarpyRiseActor's phase 0: wait under the lamp; the middle strike next to it
; starts phase 2
;
; Reached from HarpyRiseActor $A848. See there.
;
; Witness: L1 62 (rzx-r2, s2-right).
HarpyRiseAsleep:
  LD A,(HeroState)
  CP $05
  JR NZ,HarpyRiseAsleepStep
  LD A,(HeroBaseX)
  CP $0F
  JR C,HarpyRiseAsleepStep
  LD A,(HeroCounter)
  CP $0E
  JR NZ,HarpyRiseAsleepStep
  LD A,$02
  LD (HarpyPhase),A
  LD (IY+$08),$00
HarpyRiseAsleepStep:
  LD A,(IY+$08)
  INC A
  AND $07
  LD (IY+$08),A
  CALL HeroNearGlow
  LD A,(IY+$0C)
  CP $47
  JR NZ,HarpyRiseAsleepFrame
  LD A,$01
  JP HarpyLampFrame
HarpyRiseAsleepFrame:
  LD A,(IY+$08)
  SRL A
  ADD A,$01
  JP HarpyLampFrame

; The rising harpy's frame (of HarpyRiseSet) at each step 0-$16, then 23 bytes
; for phase 2
;
; Read by HarpyRiseActor $A870 (+$0B the step): 0, 1, 0, 1, 0, 1, 0, 1, 2, 1,
; 2, 1, 2, 1, 2, 3, 3, 2, 3, 2, 3, 2, 3.
;
; $A8D4 on: the frames $0C-$15 that phase 2 reads at $A83E (with +8 at $13-$16:
; $A8E7-$A8EA), not executed. Read in
;
; the recordings: $A8BE-$A8D3.
HarpyRiseFrames:
  DEFB $00,$01,$00,$01,$00,$01,$00,$01
  DEFB $02,$01,$02,$01,$02,$01,$02,$03
  DEFB $03,$02,$03,$02,$03,$02,$03
HarpyFallFrames:
  DEFB $0C,$0C,$0C,$0C,$0D,$0D,$0D,$0E ; phase 2's frames (HarpyRiseUp $A83E)
  DEFB $0E,$0E,$0F,$0F,$0F,$10,$10,$10
  DEFB $11,$11,$11,$12,$13,$14,$15

  ORG $A91B

; Carry when |E - D| is at most A
;
; In: A the limit, D and E the two values. Out: A = |E - D|, carry set when it
; is under the limit or equal to it. The limit goes into its own compare at
; AbsDiffLimit $A924. Stage 1's AbsDiffBelow $A7B8 had no equal case: stage 2
; adds RET NZ / CCF (carry on equal).
;
; Used for the hero's distances: DamageIfTouching $8760 (the touches),
; InStrikeReach $AA06, DropActorTouch $A999, the fragments ($AB3F), $9B61 and
; $9B77.
;
; Witness: L1 598 (rzx-r2, s2-right, stageload).
AbsDiffAtMost:
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

; Kind 6: a drop that falls from the ceiling, splashes and comes again
;
; The handler of ActorKinds kind 6 ($963E), placed in grid 1 at line 2 of six
; columns. Colour red or magenta (ColourRedMagenta $B499). The frame +8
; (DropSet, from $ED59 over $ECE6) is the state: 0-5 the drop forming (a step a
; pass, DropActorWait), 6 the fall: 4 lines a pass ($8F84) until the cell under
; it (column + 3, line + $0C: CellAt $B2DC) is solid, then 7-$0B the splash
; (effect $0A, PlaySoundVector, at frame $0A), $0C the end: the line back to
; $10 (+$0E), a random wait $0A-$29 (+$0A) at frame $0D, then 0 again. In the
; fall it costs the hero 4 energy when he stands in its column and within $0C
; lines (DropActorTouch $A999).
;
; In s2-right 1086 passes (the blue rooms of grid 1 before the game over), in
; rzx-r2 2255 (the red drops in the screens of grid 1).
;
; Witness: L1 3341 (rzx-r2, s2-right).
DropActor:
  CALL ColourRedMagenta
  LD (IY+$0C),C
  LD A,(IY+$08)
  CP $0C
  JR NZ,DropActorWaitCount
  CALL Random
  AND $1F
  ADD A,$0A
  LD (IY+$0A),A
  INC (IY+$08)
DropActorWaitCount:
  LD A,(IY+$08)
  CP $0D
  JR NZ,DropActorFall
  DEC (IY+$0A)
  JR NZ,DropActorFrame
  LD (IY+$08),$00
DropActorFall:
  CALL DropActorTouch
  LD A,(IY+$08)
  CP $06
  JR NZ,DropActorWait
  LD C,$04
  CALL MoveActorY
  LD A,(IY+$01)
  ADD A,$0C
  LD D,A
  LD A,(IY+$00)
  ADD A,$03
  LD E,A
  CALL CellAt
  JR Z,DropActorFrame
  INC (IY+$08)
; This entry point is used by the routine at DropActorWait.
DropActorFrame:
  LD A,(IY+$08)
  CP $0C
  JR C,DropActorSplash
  LD A,$00
  LD (IY+$0E),$10
DropActorSplash:
  CP $0A
  JR NZ,DropActorShow
  LD DE,$000A
  CALL PlaySoundVector
DropActorShow:
  CALL SetActorFrame

; SetActorFrame's parameters: the frame table $ED59, the graphics $ECE6
DropSet:
  DEFW DropFrameTable,DropSprites

; DropActor's frames 0-5 and 7-$0B: one frame a pass
;
; Reached from DropActor $A95B. See there.
;
; Witness: L1 620 (rzx-r2, s2-right).
DropActorWait:
  INC (IY+$08)
  JR DropActorFrame

; DamageHero (4) when the hero is in the drop's column (or the one right of it)
; and within $0C lines
;
; Called by DropActor $A953 at each pass of the fall. AbsDiffAtMost $A91B on
; the lines, DamageHero $8774 with C = 4.
;
; Witness: L1 1621 (rzx-r2, s2-right).
DropActorTouch:
  LD A,(HeroRecord)
  CP (IY+$00)
  JR Z,DropActorTouchLine
  DEC A
  CP (IY+$00)
  RET NZ
DropActorTouchLine:
  LD A,(HeroY)
  LD E,A
  LD D,(IY+$01)
  LD A,$0C
  CALL AbsDiffAtMost
  RET NC
  LD C,$04
  JP DamageHero

; Kinds 16-19: an urn or a jar that the hero's high strike breaks (two hits)
;
; The handler of ActorKinds kinds 16-19 ($9698, $96A1, $96AA, $96B3; frames 6,
; 4, 2, 0 of StrikeableSet): urns in grid 0 and grid 1. IY = the actor record.
; When the hero's high strike is at its hitting frame ($816D: state 6, frame 7)
; and InStrikeReach $AA06 says the actor is in front of the hero, the hit count
; (+8, also the frame) goes up: an odd count plays effect 2 and shows the
; cracked frame; an even one destroys it: score +20 and a burst (ScoreBurst20
; $99E1), the placement marked done (MarkPlacementDone $A3F3), then by +$10
; bits 0-1: 1 the item at $9ABA, 2 the item at $9A99, else eight-odd fragments
; (ShatterActor $A9F5).
;
; Stage 1's StrikeableActor was hit by the low strike ($7FEE); stage 2's test
; $816D is the high strike's.
;
; In s2-right 1915 passes, 1 hit; in rzx-r2 1828 passes, 20 hits, 10 urns
; broken (3 items at $9ABA, 2 at $9A99, 5 shattered).
;
; As in stage 1 at $A7C4, the same instructions apart from the hit test and the
; drops.
;
; Witness: L1 4019 (rzx-r2, s2-right, stageload).
StrikeableActor:
  CALL IsHeroStrikeFrame
  JR NZ,StrikeableActorFrame
  CALL InStrikeReach
  JR NZ,StrikeableActorFrame
  INC (IY+$08)
  LD A,(IY+$08)
  AND $01
  JR Z,StrikeableActorDies
  LD DE,$0002
  CALL PlaySoundVector
  JR StrikeableActorFrame
StrikeableActorDies:
  CALL ScoreBurst20       ; the second hit: score, burst, the done mark, then
                          ; the drop by +$10
  CALL MarkPlacementDone
  LD A,(IY+$10)
  AND $03
  CP $01
  JP Z,DropUrnItem
  CP $02
  JP Z,ReleaseExtraLife
  JR ShatterActor
StrikeableActorFrame:
  LD A,(IY+$08)
  CALL SetActorFrame

; SetActorFrame's parameters: the urns' frame table $C7CE, their graphics $C704
StrikeableSet:
  DEFW StrikeableFrameTable,StrikeableSprites

; Burst the actor into fragments and remove it
;
; IY = the actor. B = its column, C = its line rounded down to 8, + 5;
; SpawnFragments $AA37, then RemoveActor $B489. Unlike stage 1 ($A803, D = 8) D
; is not set: it is what ScoreBurst20 $99E1 left, the actor's column - 7
; (StartBurst keeps D), so an urn further right breaks into more fragments.
;
; In rzx-r2 5 urns shattered (27 fragments).
;
; Witness: L1 5 (rzx-r2).
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
; The actor's column must be the hero's column $74E0 + 3 when the hero faces
; right ($74E9 bit 7 clear), - 3 when he faces left, and its line within 24
; ($18) of the hero's line $74E1 (AbsDiffAtMost $A91B). Out: Z (ReturnZ $B40B)
; in reach, NZ (ReturnNZ $B410) not. Called by StrikeableActor $A9BD (5 times
; in s2-right, 22 in rzx-r2).
;
; As in stage 1 at $A816, the same instructions.
;
; Witness: L1 27 (rzx-r2, s2-right).
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
  CALL AbsDiffAtMost
  JP NC,InStrikeReachMiss
  JP ReturnZ
InStrikeReachMiss:
  JP ReturnNZ

; Start D fragment actors at column B, line C
;
; Seeds RandomPointer $FE0A with $07CF (so every burst looks the same), writes
; B and C into the LD D / LD E at FragmentColumn $AA4E and FragmentLine $AA50,
; and for each of the D fragments takes a free actor record (FindFreeActor
; $8D71; it stops quietly when none is free), random parameters
; (RandomFragmentParams $AA5E) and starts it (InitFragment $AA6C). IY is kept.
;
; Called by ShatterActor $AA00 and the statues' smashes $9A3E, $9A6B: 7 calls
; in rzx-r2, 39 fragments started.
;
; As in stage 1 at $A846, the same code.
;
; Witness: L1 7 (rzx-r2).
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
; From two Random $8BAC bytes: B = the first AND 3, C = the second AND 3, A =
; the second AND $80.
;
; As in stage 1 at $A86D, the same code.
;
; Witness: L1 39 (rzx-r2).
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
; Copies the fragment template $9754 into the record (SpawnActor $A416 with D,
; E the column and line), then the record's +9 = A (facing), +$0A = B (the
; arc), +8 = C (the speed in pixels a step), and goes on into FragmentActor
; $AA81. 39 calls in rzx-r2.
;
; As in stage 1 at $A87B, the same instructions (its own template).
;
; Witness: L1 39 (rzx-r2).
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
; The handler word of the fragment template ($975A). IY = the fragment. Its
; colour alternates (ColourRedMagenta $B499). The step counter +$0B runs from
; 0: steps 5, $0E, $14 and $17 play effect 3 (a bounce); each step moves it by
; +8 pixels a pass across (MoveFragment $AB6A, reversed when facing left) and
; down by the step's entry of FragmentArc0 $ABBA (arc +$0A = 0) or FragmentArc1
; $ABD6 (other arcs; doubled when +$0A bit 1 is set); from step $18 it no
; longer moves across. At steps 9, $10, $15 and $17 it looks at the cell under
; it (column + 2, line + $16, $14 or $0E; CellAt $B2DC): no solid ground there
; makes it fall (step $1C: 7 lines a pass, removed under line $90). Step $1B is
; the rest (FragmentRest $AB0D): +$0E counts down; under 6 it sinks 3 lines a
; pass and at 0 it is removed. A fragment the hero touches (his column or the
; one right of it, his line within $20) is taken: EnergyChange $FE59 + 6, score
; +25 ($7B1F), effect 5, and it is removed.
;
; In rzx-r2 1383 passes (the urns' and the statues' fragments); none in
; s2-right.
;
; As in stage 1 at $A891, the same instructions; the touch looks at the column
; right of the hero's (INC E at $AB33, stage 1 DEC E).
;
; Witness: L1 1383 (rzx-r2).
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
  INC E
  CP E
  RET NZ
FragmentTouchLine:
  LD A,(HeroY)
  LD E,A
  LD D,(IY+$01)
  LD A,$20
  CALL AbsDiffAtMost
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
; pixel column (+0 x 8 + the sub-column +$0D) moves by E; +0 and +$0D take the
; new column and pixel. The image pointer +4/+5 = FragmentSprites $D264 + $21 x
; the shift (the multiply $8B4B; the shift is the pixel, or 7 - the pixel when
; it faces left): eight pre-shifted copies of 33 bytes. A fragment that reaches
; column 0 or 31 is removed (RemoveActor $B489).
;
; As in stage 1 at $A97A, the same code.
;
; Witness: L1 873 (rzx-r2).
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
; Read by FragmentActor $AAB4 (+$0B the step): up 8, 6, 4, 2, 1 lines, then
; down 1, 2, 4, 6, 8, a short second hop
;
; and the rest. Read in rzx-r2: $ABBA-$ABD1 (44 reads); its last four bytes no
; recording read.
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

; Kinds 4 and 5: a stretch of the bubbling pool's surface (kind 5 mirrored)
;
; The handler of ActorKinds kinds 4 and 5 ($962C, $9635): 18 placements on line
; 25 (cells) of grid 1, under rooms 4-7 (the magenta pool of screens 012551.png
; and 014074.png). Every second pass the frame +$0B goes up one; when the
; countdown +8 reaches 0 a random entry of PoolPicks (Random $8BAC AND $0F)
; picks a run of PoolRuns: the first frame into +$0B, twice the length into +8;
; the run 2 (frames 6-$0B) plays effect 9 (PlaySoundVector). The frames of
; PoolSet ($E82C over $E61C).
;
; In rzx-r2 3268 passes; none in s2-right.
;
; Witness: L1 3268 (rzx-r2).
PoolActor:
  DEC (IY+$08)
  LD A,(IY+$08)
  AND $01
  RET NZ
  INC (IY+$0B)
  LD A,(IY+$08)
  CP $00
  JR NZ,PoolActorShow
  CALL Random
  AND $0F
  LD C,A
  LD B,$00
  LD HL,PoolPicks
  ADD HL,BC
  LD C,(HL)
  SLA C
  LD A,C
  CP $04
  JR NZ,PoolActorRun
  LD DE,$0009
  CALL PlaySoundVector
PoolActorRun:
  LD HL,PoolRuns
  ADD HL,BC
  LD A,(HL)
  LD (IY+$0B),A
  INC HL
  LD A,(HL)
  SLA A
  LD (IY+$08),A
PoolActorShow:
  LD A,(IY+$0B)
  CALL SetActorFrame

; SetActorFrame's parameters: the frame table $E82C, the graphics $E61C
PoolSet:
  DEFW PoolFrameTable,PoolSprites

; Five runs of the pool's frames: the first frame and the length (0, 3), (3,
; 3), (6, 6), ($0C, 3), ($0F, 3)
;
; Read by PoolActor $AC23 at the index (0-3) PoolPicks gives: the fifth run
; ($AC40-$AC41) no pick selects (never
;
; read).
PoolRuns:
  DEFB $00,$03,$03,$03,$06,$06,$0C,$03,$0F,$03

; The run (0-3) for each random 0-15: 0 ten times, 1 four, 2 and 3 once each
;
; Read by PoolActor $AC11.
PoolPicks:
  DEFB $00,$00,$01,$00,$00,$01,$00,$00,$03,$00,$01,$02,$00,$01,$00,$03

  ORG $B305

; A shot of type 2 at the actor IY with a random +5 ($FA asks AddMissile for
; one); effect 6
;
; D = the column, E = the line + 4, C = 2, B = 1, A = $FA (AddMissile $B3BD),
; then effect 6 (PlaySoundVector). In stage 1 nothing called it; in stage 2 the
; flying harpy does ($8E53, $8E58): 32 shots in s2-right, 61 in rzx-r2
; (UpdateDriftLeft $B639 flies them).
;
; As in stage 1 at $B214, the same code.
;
; Witness: L1 93 (rzx-r2, s2-right).
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

; A hydra head breathes a shot of type 3 at its steps 4, 8 and $0C
;
; A = the neck's step ($FE43, $FE45 or $FE41). For a step 3-$0D that is a
; multiple of 4: D = the head's column - 1, E = its line + 4, C = 3, B = 1, A =
; $FA (a random +5) (AddMissile $B3BD), then effect 6 (PlaySoundVector). Called
; by the four head handlers ($7FD8, $800E, $8046, $807E): 842 calls, 71 shots
; in rzx-r2.
;
; Witness: L1 842 (rzx-r2).
HydraHeadShot:
  CP $03
  RET C
  CP $0E
  RET NC
  AND $03
  RET NZ
  LD A,(IY+$01)
  ADD A,$04
  LD E,A
  LD A,(IY+$00)
  SUB $01
  LD D,A
  LD C,$03
  LD B,$01
  LD A,$FA
  CALL AddMissile
  LD DE,$0006
  JP PlaySoundVector

  ORG $B3A4

; Kind 12's shot: a missile of type 4 from its column, line + 8; effect $0B
;
; D = the column, E = the line + 8, C = 4, B = 1, A = 1 (AddMissile $B3BD),
; effect $0B (PlaySoundVector). Jumped to by
;
; kind 12's handler $8179 (grid 2's single room) at its pass $0A: 6 shots in
; rzx-r2. UpdateFloorShot $B511 flies it.
;
; Witness: L1 6 (rzx-r2).
KindTwelveShot:
  LD A,(IY+$01)
  ADD A,$08
  LD E,A
  LD A,(IY+$00)
  LD D,A
  LD C,$04
  LD B,$01
  LD A,$01
  CALL AddMissile
  LD DE,$000B
  JP PlaySoundVector
