; --------------------------------------------------------------------------------------------------------------------
; weapons.asm: the side weapons, the pod actions, the sight, the laser shot, the plasma, the missile, the seeker
;
; The side weapon fires from its frame routine (table $80EA, called by PlayerHandler with +$08 - 2) on a count of the
; frames fire is held ($8184), so a tap fires the laser only: plasma at 3 frames, a homing missile from 1 frame when a
; target is locked, the seeker at 7 frames. Slot $F5D4 is the side weapon's shot, $F5A8 the second plasma ball of the
; double plasma, $F600 the homing sight.
;
; The pod actions (table $80F0, called by the pod handler $A1FD with the selector +$07 when the ship scoops a pod with
; fire held): 0 PodSpeedUp, 1 PodLaser, 2 PodPlasma, 3 PodHoming, 4 PodSeeker. A second plasma pod gives the double
; plasma.
;
; The hit masks of a frame (cleared by RunObjects, read by the enemy handlers): $80BB the player and the lasers (one
; hit point a frame), $80E5 the plasma balls and the seeker (a kill), $80E3 the homing missile, $80E4 the sight. The
; homing lock: the first lockable enemy (kinds 8 and 12) under the sight is stored in $80E0 (its record) and $80E2
; (its bit); the missile kills the locked enemy only.
; --------------------------------------------------------------------------------------------------------------------

; side weapon 2: a plasma ball after 3 frames of fire
;
; Fire held exactly 3 frames: $F5D4 when free, else with the double plasma
; (+$09 = 1) $F5A8 when free; active, Vy = 0, 3 bounces (+$26), PlaceAtPlayer.
; Not run in c1/c2.
PlasmaFrame:
  LD C,(IX+$09)
  LD A,(FireHeld)
  CP $03
  RET NZ
  LD IX,SideShot
  BIT 7,(IX+$08)
  JR Z,PlasmaLaunch
  DEC C
  RET NZ
  LD IX,PlasmaBall2
  BIT 7,(IX+$08)
  RET NZ
PlasmaLaunch:
  SET 7,(IX+$08)          ; the ball into play
  XOR A
  LD (IX+$12),A           ; GS: the installer writes CALL PlasmaLaunchHook
                          ; ($FF56) here: FX 4 (note $2A), a plasma ball
                          ; launched
  LD (IX+$13),A
  LD (IX+$26),$03

; the object IX two columns ahead of the ship, one row down
;
; Copies the ship's X (+2 columns) and Y (+1 row) from $F36F. Used by
; PlasmaFrame, HomingFrame, SeekerFrame. Not run in c1/c2.
PlaceAtPlayer:
  LD HL,PlayerObject+$0003
  LD A,(HL)
  INC HL
  LD (IX+$03),A
  LD A,(HL)
  INC HL
  ADD A,$02
  LD (IX+$04),A
  LD A,(HL)
  INC HL
  LD (IX+$05),A
  LD A,(HL)
  INC A
  LD (IX+$06),A
  RET

; side weapon 3: a homing missile at the locked target
;
; Fire held, $F5D4 free and a lock ($80E2 not 0): active, the target +$29 =
; ($80E0), colour $38, direction 0 (ahead), life +$26 = $4B (75 frames), the
; turn interval 1. Not run in c1/c2.
HomingFrame:
  LD A,(FireHeld)
  AND A
  RET Z
  LD IX,SideShot
  BIT 7,(IX+$08)
  RET NZ
  LD A,(LockMask)
  AND A
  RET Z
  SET 7,(IX+$08)
  LD HL,(LockTarget)
  LD (IX+$29),L
  LD (IX+$2A),H
  LD (IX+$25),$38
  LD (IX+$16),$00
  LD (IX+$26),$4B
  LD (IX+$27),$01
  CALL PlaceAtPlayer      ; GS: the installer points this CALL at
                          ; MissileLaunchHook ($FF4D): FX 5, a homing missile
                          ; launched
  RET

; side weapon 4: the seeker after 7 frames of fire
;
; Fire held exactly 7 frames and the weapon still 4: a new seeker at the ship
; flying ahead (direction 0, the speed +$17); an active one with +$26 = 0 is
; re-armed. +$26 = 1 and the target = the first enemy slot $F398: SeekerHandler
; hunts from there. Not run in c1/c2.
SeekerFrame:
  LD A,(FireHeld)
  CP $07
  RET NZ
  LD IX,(PlayerRecord)
  LD A,(IX+$08)
  CP $04
  RET NZ
  LD IX,SideShot
  BIT 7,(IX+$08)
  JR Z,SeekerLaunch
  LD A,(IX+$26)
  AND A
  RET NZ
  JR SeekerTargetFirst
SeekerLaunch:
  CALL PlaceAtPlayer      ; a new seeker: the position and velocities (GS: the
                          ; installer writes CALL MissileLaunchHook ($FF4D)
                          ; here: FX 5, a seeker launched)
  SET 7,(IX+$08)
  LD A,(IX+$28)
  LD (IX+$27),A
  PUSH IY
  PUSH IX
  POP IY
  XOR A
  LD (IX+$16),A
  LD B,(IX+$17)
  CALL SetVelocity
  POP IY
SeekerTargetFirst:
  LD (IX+$26),$01         ; hunt from slot $F398
  LD HL,EnemyObjects
  LD (IX+$29),L
  LD (IX+$2A),H
  RET

; pod 0: fuel $BB and the speed one step up, to $A0
;
; Not run in c1/c2.
PodSpeedUp:
  LD HL,Fuel
  LD (HL),$BB
  LD A,(IX+$0B)
  CP $A0
  RET Z
  ADD A,$20
  LD (IX+$0B),A
  RET

; pod 1: the laser one level up, to 3
;
; Not run in c1/c2.
PodLaser:
  LD A,(IX+$0A)
  INC A
  CP $04
  RET Z
  LD (IX+$0A),A
  RET

; pod 2: plasma (a second plasma pod: double)
;
; +$09 = 1 when the weapon is already plasma; +$08 = 2; the sight $F600 off;
; both slots $F5D4 and $F5A8 set up as plasma balls (ResetPlasmaBall). Not run
; in c1/c2.
PodPlasma:
  LD A,(IX+$08)
  CP $02
  JR NZ,PodPlasmaSetup
  LD (IX+$09),$01
PodPlasmaSetup:
  LD (IX+$08),$02         ; the weapon, the sight off, the two balls
  LD HL,SightObject+$0008
  RES 7,(HL)
  LD IX,SideShot
  CALL ResetPlasmaBall
  LD IX,PlasmaBall2

; the slot IX as an idle plasma ball
;
; Inactive, kind 9, Vx = $40, the X acceleration 0, the Y acceleration $10 (its
; gravity). Not run in c1/c2.
ResetPlasmaBall:
  RES 7,(IX+$08)
  XOR A
  LD (IX+$10),A
  LD (IX+$11),A
  LD (IX+$14),$10
  LD (IX+$15),A
  LD (IX+$0E),$40
  LD (IX+$0F),A
  LD (IX+$07),$09
  RET

; pod 3: homing missiles and the sight
;
; +$08 = 3, no double, the slot $F5A8 off; $F5D4 idle as kind 10 with speed 4,
; the turn interval 1 and the turn rate 2; the sight $F600 on (PlaceSight); no
; lock ($80E0 = 0, $80E2 = 0). Not run in c1/c2.
PodHoming:
  LD (IX+$08),$03
  LD (IX+$09),$00
  LD HL,PlasmaBall2+$0008
  RES 7,(HL)
  LD IX,SideShot
  RES 7,(IX+$08)
  LD (IX+$07),$0A
  LD (IX+$17),$04
  LD (IX+$28),$01
  LD (IX+$2B),$02
  LD HL,SightObject+$0008
  SET 7,(HL)
  CALL PlaceSight
  LD HL,$0000
  LD (LockTarget),HL
  XOR A
  LD (LockMask),A
  RET

; pod 4: the seeker
;
; The sight off, +$08 = 4, no double; $F5D4 idle as kind 7, speed 4, the turn
; interval 1, the turn rate 2. The second plasma slot $F5A8 is not cleared here
; (PodHoming does it). Not run in c1/c2.
PodSeeker:
  LD HL,SightObject+$0008
  RES 7,(HL)
  LD (IX+$08),$04
  LD (IX+$09),$00
  LD IX,SideShot
  RES 7,(IX+$08)
  LD (IX+$07),$07
  LD (IX+$17),$04
  LD (IX+$28),$01
  LD (IX+$2B),$02
  RET

; kind 6: the homing sight ahead of the ship
;
; Colour $78 without a lock, $70 with one; its overlap mask +$0D into $80E4
; (the lockable enemies test it); then PlaceSight. Not run in c1/c2.
SightHandler:
  LD A,(LockMask)
  AND A
  LD A,$78
  JR Z,SightColour
  LD A,$70
SightColour:
  LD (IY+$25),A           ; the colour and the mask
  LD A,(IY+$0D)
  LD (SightMask),A

; the sight at the ship's position of the history ring, 10 columns ahead
;
; The entry of the ring $80C0 at the index $80BF (the oldest one: the sight
; lags the ship by 8 moves) into $F603-$F606, X + 10 columns.
PlaceSight:
  LD A,(ShipHistoryIndex)
  ADD A,A
  ADD A,A
  LD HL,ShipHistory
  LD E,A
  LD D,$00
  ADD HL,DE
  LD DE,SightObject+$0003
  LDI
  LD A,(HL)
  INC HL
  ADD A,$0A
  LD (DE),A
  INC DE
  LDI
  LDI
  RET

; kind 1: a laser shot
;
; Gone on an enemy in its overlap mask (the harmless enemies of $80BD/$80BE and
; bits 5-7 excepted) or scenery (SceneryAt2), and at column 48: $80BA + 1 (the
; shot back). Else X + $140/256 (1.25 columns) a frame. 882 executions in c2.
LaserHandler:
  LD A,(HarmlessMaskA)
  LD HL,HarmlessMaskB
  OR (HL)
  CPL
  AND $1F
  AND (IY+$0D)
  JR NZ,LaserRemove
  CALL SceneryAt2
  JR C,LaserRemove
  LD L,(IY+$03)
  LD H,(IY+$04)
  LD DE,$0140
  ADD HL,DE
  LD A,H
  AND $7F
  CP $30
  JR C,LaserStore
LaserRemove:
  RES 7,(IY+$08)          ; off, the shot back to $80BA
  LD HL,LaserShotsFree
  INC (HL)
  RET
LaserStore:
  LD (IY+$03),L           ; the new X
  LD (IY+$04),A
  RET

; kind 9: a plasma ball, falling and bouncing
;
; Flashes every second frame; its mask into $80E5 (a kill for any enemy it
; overlaps). Gone at column 48, below row 16 or after its bounces (+$26, 3).
; Each frame Vy + the gravity; a landing on scenery (SceneryAt1): sound effect
; 3, Vy = -Vy / 2, a bounce counted; still in the scenery after the bounce:
; gone. Not run in c1/c2.
PlasmaHandler:
  LD A,(PassCount)
  AND $01
  JR Z,PlasmaMove
  CALL CycleColour
PlasmaMove:
  LD A,(IY+$0D)           ; fall
  LD HL,PlasmaHitMask
  OR (HL)
  LD (HL),A
  LD A,(IY+$04)
  CP $30
  JR NC,PlasmaRemove
  LD L,(IY+$05)
  LD H,(IY+$06)
  LD E,(IY+$12)
  LD D,(IY+$13)
  PUSH HL
  PUSH DE
  LD C,$20
  CALL PathOpAccelerate
  LD A,(IY+$06)
  CP $11
  JR NC,PlasmaOffBottom
  CALL SceneryAt1
  POP DE
  POP BC
  LD A,$00
  JR NC,PlasmaBounceDone
  LD A,$03
  CALL RequestEffect      ; sound effect 3: the bounce (GS: the installer
                          ; points this CALL at PlasmaBounceHook ($FF69): FX 6,
                          ; a plasma ball bounces)
  LD HL,$0000
  AND A
  SBC HL,DE
  SRA H
  RR L
  LD (IY+$12),L
  LD (IY+$13),H
  ADD HL,BC
  LD (IY+$05),L
  LD (IY+$06),H
  DEC (IY+$26)
  CALL SceneryAt1
  SBC A,A
PlasmaBounceDone:
  INC A                   ; out of the scenery and bounces left: stay
  JR Z,PlasmaRemove
  LD A,(IY+$26)
  AND A
  RET NZ
PlasmaRemove:
  RES 7,(IY+$08)          ; off
  RET
PlasmaOffBottom:
  POP DE                  ; below the playfield
  POP BC
  JR PlasmaRemove

; kind 10: the homing missile
;
; Life +$26 - 1, flashing. No lock: it burns out (MissileFade). Its mask into
; $80E3; overlapping the locked enemy ($80E2): gone (the enemy handler sees the
; hit in $80E3). Else PathOpHome on the target, ClampRow, gone outside columns
; 16-47. Not run in c1/c2.
MissileHandler:
  DEC (IY+$26)
  JP M,MissileFade
  CALL CycleColour
  LD A,(LockMask)
  AND A
  JR Z,MissileExpire
  AND (IY+$0D)
  LD A,(IY+$0D)
  LD (MissileHitMask),A   ; $80E3: the missile's overlap mask
  JR NZ,MissileRemove
  CALL PathOpHome
  CALL ClampRow
  LD A,(IY+$04)
  SUB $10
  CP $20
  RET C
MissileExpire:
  LD (IY+$26),$FF         ; burn out
MissileFade:
  LD A,(IY+$25)           ; the colour one step down a frame; 0: gone
  AND $38
  SUB $08
  LD (IY+$25),A
  RET NZ
MissileRemove:
  RES 7,(IY+$08)          ; off
  RET

; kind 7: the seeker, killing enemy after enemy
;
; Flashes. A target (+$29) that is active and of kind 2: PathOpHome on it, its
; mask into $80E5 (a kill), ClampRow, gone on scenery or outside columns 16-47.
; A lost target with +$26 not 0: the next active kind-2 slot after +$26 (up to
; 5) becomes the target, none: the player, +$26 = 0 (it comes home). The kind
; test is written twice (CP $02 ... CP $02): the second was probably meant for
; another kind (11 shares the handler of 2). Not run in c1/c2.
SeekerHandler:
  CALL CycleColour
  LD L,(IY+$29)
  LD H,(IY+$2A)
  PUSH HL
  POP IX
  BIT 7,(IX+$08)
  JR Z,SeekerRetarget
  LD A,(IX+$07)
  CP $02                  ; kind 2? (the same test again at $9F2C)
  JR Z,SeekerHome
  CP $02
  JR NZ,SeekerRetarget
SeekerHome:
  LD HL,PlasmaHitMask     ; home, kill, clamp
  LD A,(IY+$0D)
  OR (HL)
  LD (HL),A
  CALL PathOpHome
  CALL ClampRow
  CALL SceneryAt1
  JR C,SeekerRemove
  LD A,(IY+$04)
  SUB $10
  CP $20
  RET C
SeekerRemove:
  RES 7,(IY+$08)          ; off
  RET
SeekerRetarget:
  LD A,(IY+$26)           ; the target is gone
  AND A
  JR Z,SeekerHome
  LD DE,$002C
SeekerSearch:
  INC A                   ; the next slot number
  CP $06
  JR NZ,SeekerSearchSlot
  LD HL,PlayerObject
  LD C,$00
  JR SeekerSetTarget
SeekerSearchSlot:
  ADD IX,DE               ; active and of kind 2?
  BIT 7,(IX+$08)
  JR Z,SeekerSearch
  LD C,A
  LD A,(IX+$07)
  CP $02
  JR Z,SeekerFound
  CP $02
  LD A,C
  JR NZ,SeekerSearch
SeekerFound:
  PUSH IX                 ; the new target
  POP HL
SeekerSetTarget:
  LD (IY+$29),L           ; +$29/+$2A and the slot number +$26
  LD (IY+$2A),H
  LD (IY+$26),C
  JR SeekerHome
