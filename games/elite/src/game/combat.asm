; --------------------------------------------------------------------------------------------------------------------
; combat.asm: Collisions and scooping, the player's laser and the gunsight, the ECM, the ship actions and spawning, face visibility
;
; ShipAction $B867 does every creation: A's low nibble is the action and the high nibble its argument C. 0 a new ship
; in the system (SpawnShip), 1 a group of Thargoids, 2 a missile (C = 0: from the ship at IX at the player; else the
; player's at slot C's ship), 3 nothing, 4 a ship launched from IX (C picks the kind), 5 alloy plates, 6 a cargo
; canister, 7 an escape pod (C = 1: the player's own Cobra flying off), 8 two splinters, 9 the title's ship C + 2 in
; slot 7. A new ship (CreateShip) is the 31-byte template ShipTemplate plus its blueprint's energy, behaviour,
; payload, half its top speed, the tactics state $7E and a random position near $3200 on each axis unless it is
; hostile.
; --------------------------------------------------------------------------------------------------------------------

; The laser fired last frame (LaserCooling); B4D6 the beam's random bits
LaserFired:
  DEFB $00

; A ship inside the player's box: scooped, docked, or both hit
;
; The box is the blueprint's size (+$01; 180 for scoopables; z one more page
; for a missile with no target) on each axis, with z ahead only. Scoopable and
; below (y negative) with the fuel scoop ($D088): the slot is freed and the
; hold gains one of the cargo in the blueprint's +$00 high nibble (or a random
; 0-7, or the mission's item) through AddCargo $D0E4, if the hold has room
; ($D07C). The station: ahead, upright (its nose's z negative, the roof's
; within $3C) and not hostile docks (Docked = 1); else a crash costs the front
; shield $0C + 2 x speed. Anything else is destroyed and its size hits the
; front or aft shield. The sun or the planet too near (TooClose) skips this. dk
; docked at frame 2190, cs scooped a plate at 910 (AddCargo); a crash is known
; from the code only.
Collide:
  LD A,(TooClose)
  AND A
  RET NZ
  LD D,$00
  LD E,(IY+$01)
  BIT 0,(IX+$26)
  JR Z,CollideScoopable
  LD A,(IX+$25)
  AND A
  JR NZ,CollideScoopable
  LD D,$01
CollideScoopable:
  BIT 1,(IX+$26)
  JR Z,CollideBox
  LD E,$B4
CollideBox:
  LD L,(IX+$00)
  LD H,(IX+$01)
  SBC HL,DE
  RET NC
  AND A
  LD L,(IX+$03)
  LD H,(IX+$04)
  SBC HL,DE
  RET NC
  AND A
  LD L,(IX+$06)
  LD H,(IX+$07)
  SBC HL,DE
  RET NC
  LD A,(IX+$08)
  ADD A,A
  RET NZ
CollideInside:
  BIT 1,(IX+$26)
  JR Z,CollideStation
  BIT 7,(IX+$05)
  JP Z,CollideShip
  LD A,(Equipment+$0004)
  AND A
  JR Z,CollideShip
  XOR A
  LD (IX+$22),A
  CALL RemoveShip
  LD A,(FreeSpace)
  AND A
  JR Z,CollideShip
CollideScoopCargo:
  LD A,(IY+$00)
  AND $F0
  JR Z,CollideScoopMission
  RRCA
  RRCA
  RRCA
  RRCA
  INC A
  JR CollideScoopAdd
CollideScoopMission:
  LD A,(MissionShip)
  SUB $03
  JR NZ,CollideScoopRandom
  LD (MissionShip),A
  DEC A
  JR CollideScoopAdd
CollideScoopRandom:
  CALL Random
  AND $07
CollideScoopAdd:
  JP AddCargoVector
CollideStation:
  BIT 2,(IX+$26)
  JR Z,CollideShip
  BIT 7,(IX+$0E)
  JR Z,CollideTooHard
  BIT 7,(IX+$08)
  JR NZ,CollideTooHard
  BIT 2,(IX+$21)
  JR NZ,CollideTooHard
  LD A,(IX+$0A)
  ADD A,A
  CP $DC
  JR NC,CollideTooHard
  LD B,A
  LD A,(IX+$0C)
  ADD A,A
  CP $DC
  JR NC,CollideTooHard
  CP $3C
  JR NC,CollideStationCrash
  LD A,B
  CP $3C
  JR NC,CollideStationCrash
  LD A,$01
  LD (Docked),A
  RET
CollideStationCrash:
  LD HL,SoundRequests
  SET 6,(HL)
  LD HL,SpeedRate
  LD A,(FrontHits)
  ADD A,$0C
  ADD A,(HL)
  ADD A,(HL)
  LD (FrontHits),A
  RET
CollideShip:
  XOR A
  LD (IX+$22),A
  LD B,(IY+$01)
  BIT 6,(IX+$26)
  JR Z,CollideShipSound
  LD A,(MissionShip)
  AND A
  JR Z,CollideShipSound
  XOR A
  LD (MissionShip),A
CollideShipSound:
  LD HL,SoundRequests
  SET 2,(HL)
  BIT 7,(IX+$08)
  JR Z,CollideShipFront
  LD A,(AftHits)
  ADD A,B
  LD (AftHits),A
  JR RemoveShip
CollideTooHard:
  INC A
  LD (TooClose),A
  RET
CollideShipFront:
  LD A,(FrontHits)
  ADD A,B
  LD (FrontHits),A

; A ship gone: every missile aimed at it explodes, and the player's missile
; loses its lock on it
;
; Used by the routines at UpdateSlot, UpdateShip and Collide.
RemoveShip:
  LD A,(ShipLoopCount)
  LD H,A
  PUSH IY
  LD IY,ShipSlots
  LD DE,$0027
  LD B,$07
RemoveShipLoop:
  ADD IY,DE
  LD A,(IY+$22)
  AND A
  JR Z,RemoveShipNext
  LD A,(IY+$25)
  CP H
  JR NZ,RemoveShipNext
  SET 4,(IY+$20)
RemoveShipNext:
  DJNZ RemoveShipLoop
  POP IY
  LD A,(MissileState)
  CP $02
  RET NZ
  LD A,(MissileTarget)
  SUB H
  RET NZ
  LD (MissileState),A
  LD HL,Messages+$0004
  SET 7,(HL)
  RET

; The player's death: the explosion's sound, the front view, every slot free,
; then a canister and two plates near (actions $16 and $15)
;
; Used by the routine at ResetShipsVector.
ShipsWreck:
  LD HL,SoundRequests
  SET 2,(HL)
  XOR A
  LD (ViewIndex),A
  LD IX,ShipSlots-$27
  LD DE,$0027
  LD B,$08
ShipsWreckLoop:
  ADD IX,DE
  LD (IX+$22),A
  DJNZ ShipsWreckLoop
  LD A,$16
  CALL ShipAction
  LD A,$15
  CALL ShipAction
  RET

; The laser temperature falls by 2 a frame; A (the fire key, KeyCombat bit 0)
; fires the view's laser below $90
;
; LaserMounts $D07D (one byte per view): 1 pulse, 2 beam, 3 military, 4 mining
; (EquipLaser). A press fires at once; held, a pulse laser fires every other
; pass and a mining one every eighth (JumpEncounter's low bits, D = 1 or 7), a
; beam or military laser every pass. Each shot is drain 1, the laser sound and
; heat $08 (pulse, mining) or $0A (beam, military), capped at $A0. The power is
; $0F (pulse, beam), $17 (military), $32 (mining). A hit on SightTarget turns
; it hostile, its tactics state down by 14, and its energy down by the power;
; at 0 it is destroyed ($FF), and gives a canister of alloys (action 6), an
; asteroid splinters (5), the mining laser on a Rock Hermit or a boulder plates
; (8), or ends the mission ship (3). 30 recorded frames fired; none hit.
LaserCooling:
  LD A,(LaserFired)
  LD C,A
  XOR A
  LD (LaserFired),A
  LD A,(BarLaserTemp)
  CP $02
  JR NC,LaserCool
  LD A,$02
LaserCool:
  SUB $02
  LD (BarLaserTemp),A
  LD HL,KeyCombat
  BIT 0,(HL)
  RET Z
  RES 0,(HL)
  CP $90
  RET NC
  LD B,A
  LD A,(ViewIndex)
  LD HL,LaserMounts
  LD D,$00
  LD E,A
  ADD HL,DE
  LD A,(HL)
  AND A
  RET Z
  LD E,C
  LD C,A
  DEC A
  JR NZ,LaserKind
  LD D,$01
LaserKind:
  SUB $03
  JR NZ,LaserRate
  LD D,$07
LaserRate:
  LD A,E
  AND E
  LD A,$01
  LD (LaserFired),A
  JR Z,LaserShot
  LD A,(JumpEncounter)
  AND D
  RET NZ
LaserShot:
  LD A,(EnergyDrain)
  INC A
  LD (EnergyDrain),A
  LD HL,SoundRequests
  SET 4,(HL)
  LD A,C
  SUB $03
  LD A,$0F
  JR C,LaserPower
  JR Z,LaserPowerBeam
  ADD A,$1B
LaserPowerBeam:
  ADD A,$08
LaserPower:
  LD C,A
  LD A,D
  DEC A
  AND $01
  RLA
  ADD A,$08
  ADD A,B
  CP $A0
  JR C,LaserHeat
  LD A,$A0
LaserHeat:
  LD (BarLaserTemp),A
  LD A,(SightTarget)
  AND A
  JP Z,LaserBeams
  DEC A
  SUB $09
  CPL
  LD IX,ShipSlots
  LD DE,$0027
LaserTarget:
  DEC A
  JR Z,LaserHit
  ADD IX,DE
  JR LaserTarget
LaserHit:
  SET 2,(IX+$21)
  LD HL,SoundRequests
  SET 3,(HL)
  BIT 2,(IX+$26)
  JR NZ,LaserBeams
  BIT 5,(IX+$20)
  JR NZ,LaserBeams
  LD A,(IX+$25)
  LD B,A
  SUB $0E
  JR NC,LaserHitState
  AND $01
  ADD A,$06
LaserHitState:
  RLA
  SLA B
  RRA
  LD (IX+$25),A
  LD A,(IX+$22)
  CP $FF
  JR Z,LaserBeams
  SUB C
  LD (IX+$22),A
  JR Z,LaserKill
  JR NC,LaserBeams
LaserKill:
  XOR A
  DEC A
  SET 4,(IX+$20)
  LD (IX+$22),A
  BIT 6,(IX+$26)
  JR Z,LaserKillDebris
  LD A,(MissionShip)
  AND A
  JR Z,LaserKillDebris
  CP $03
  JR Z,LaserKillDebris
  LD A,$03
  LD (MissionShip),A
  ADD A,A
  JR LaserKillAction
LaserKillDebris:
  LD H,(IX+$24)
  LD L,(IX+$23)
  LD A,(HL)
  AND $0F
  LD A,$06
  JR NZ,LaserKillAction
  LD DE,$0007
  ADD HL,DE
  LD A,(HL)
  CP $55
  LD A,$05
  JR NC,LaserKillAction
  LD A,(HL)
  CP $3C
  JR NZ,LaserBeams
  LD A,C
  CP $32
  JR NZ,LaserBeams
  LD A,$08
LaserKillAction:
  CALL ShipAction

; Two or four random lines from the bottom corners ($543F, $403F) towards the
; centre: the beam
;
; Used by the routine at LaserCooling.
LaserBeams:
  CALL Random
  LD B,A
  AND $0C
  LD C,A
  LD (LaserBeam),A
  LD A,B
  AND $03
  OR $01
  SUB $01
  LD D,A
  RLC B
  RLC B
  LD A,B
  AND $03
  OR $01
  SUB $01
  LD E,A
  PUSH DE
  LD A,C
  OR $03
  LD C,A
  LD HL,$543F
  PUSH HL
  CALL DrawLine
  POP HL
  POP DE
  LD A,(LaserBeam)
  OR $01
  LD C,A
  PUSH DE
  CALL DrawLine
  POP DE
  LD HL,$403F
  LD A,(LaserBeam)
  OR $03
  LD C,A
  PUSH HL
  PUSH DE
  CALL DrawLine
  POP DE
  POP HL
  LD A,(LaserBeam)
  OR $01
  LD C,A
  JP DrawLine

; A = a random byte: the seed's two bytes added with the carry
;
; Used by the routines at Tactics, TacticsAim, DrawWireframe, Collide,
; LaserBeams, CreateShip, ActionThargoids, ActionLaunch, RandomRoll,
; DebrisNear, SpawnShip and SpawnMissionDone.
Random:
  PUSH HL
  PUSH BC
  LD HL,(RandomSeed)
  LD A,H
  ADC A,A
  LD B,A
  ADC A,L
  LD H,A
  LD L,B
  LD (RandomSeed),HL
  POP BC
  POP HL
  RET

; RandomSeed
RandomSeed:
  DEFW $F562

; Dead: two bytes of the market ($7043, $7044) zeroed
;
; Used by the routine at Gunsight.
ClearFirearmPrices:
  XOR A
  LD (Commodities+$0028),A
  LD (Commodities+$0029),A
  RET

; The four lines of the cross when the view has a laser, the laser, then the
; ECM (E)
;
; The ECM on (ECMActive, 10 frames): each frame drain 1 and the ECM sound; at 0
; the ECM is off. E (KeyCombat bit 4) turns it on with an ECM system fitted
; ($D085, bit 7 its state). It is not offered in mission state 4 with the
; mission flag set ($D0B0 bit 7).
Gunsight:
  LD A,(TooClose)
  AND A
  JR NZ,ClearFirearmPrices
  LD A,(ViewIndex)
  CP $04
  RET NC
  LD HL,LaserMounts
  LD D,$00
  LD E,A
  ADD HL,DE
  LD A,(HL)
  AND A
  JR Z,GunsightECM
  LD HL,$0800
  LD DE,$1000
  LD C,$0A
  PUSH DE
  PUSH HL
  CALL DrawLine
  POP HL
  POP DE
  LD C,E
  CALL DrawLine
  LD HL,$0010
  LD DE,$0008
  LD C,D
  PUSH DE
  PUSH HL
  CALL DrawLine
  POP HL
  POP DE
  LD C,$05
  CALL DrawLine
  CALL LaserCooling
GunsightECM:
  LD A,(MissionFlags)
  BIT 7,A
  JR Z,GunsightECMKey
  LD A,(MissionState)
  CP $04
  RET Z
GunsightECMKey:
  LD HL,KeyCombat
  LD B,(HL)
  RES 4,(HL)
  LD A,(Equipment+$0001)
  LD C,A
  LD A,(ECMActive)
  AND A
  JR Z,GunsightECMOff
  DEC A
  LD (ECMActive),A
  JR NZ,GunsightECMOn
  RES 7,C
GunsightECMOn:
  LD HL,SoundRequests
  SET 5,(HL)
  LD A,C
  AND A
  RET Z
  LD (Equipment+$0001),A
  LD A,(EnergyDrain)
  INC A
  LD (EnergyDrain),A
  RET
GunsightECMOff:
  LD A,C
  AND A
  RET Z
  BIT 4,B
  RET Z
  OR $80
  LD (Equipment+$0001),A
  LD A,$0A
  LD (ECMActive),A
  RET

; ShipTemplateSpare
ShipTemplateSpare:
  DEFB $00

; The first 31 bytes of every new ship: the position $3200 on each axis, the
; unit axes, zeros
ShipTemplate:
  DEFB $00,$32,$00,$00,$32,$00,$00,$32,$00
  DEFB $00,$00,$00,$00,$FF,$FF,$00,$00,$FF
  DEFB $7F,$00,$00,$FF,$FF,$00,$00,$00,$00
  DEFB $00,$00,$00,$00

; The title ship's nine axis high bytes
TitleShipAxes:
  DEFB $58,$44,$41,$98,$64,$CB,$5A,$A7,$D1

; FlipShip's two ways, in turn
FlipToggle:
  DEFB $00

; Do ship action A (low nibble) with argument C (high nibble)
;
; Used by the routines at ShipActionVector, UpdateShips, LaunchFromShip,
; ShipsWreck and LaserCooling.
ShipAction:
  LD C,A
  SRL C
  SRL C
  SRL C
  SRL C
  AND $0F
  JP Z,SpawnShip
  DEC A
  JP Z,ActionThargoids
  DEC A
  JP Z,ActionMissile
  DEC A
  RET Z
  DEC A
  JP Z,ActionLaunch
  DEC A
  JP Z,ActionPlates
  DEC A
  JP Z,ActionCanister
  DEC A
  JP Z,ActionPod
  DEC A
  JP Z,ActionSplinters
  DEC A
  JP Z,ActionTitleShip
  RET

; Fill slot IX for blueprint A (bits 0-5): the template, the blueprint's
; values, a random position unless hostile
;
; Used by the routines at LaunchShip, CreateHere, ActionThargoids,
; ActionTitleShip and SpawnMissionDone.
CreateShip:
  LD HL,Blueprints
  LD B,A
  AND $3F
  ADD A,A
  ADD A,A
  ADD A,L
  LD L,A
  JR NC,CreateShipBlueprint
  INC H
CreateShipBlueprint:
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  PUSH DE
  POP IY
  LD (IX+$24),D
  LD (IX+$23),E
  PUSH IX
  POP DE
  LD BC,$001F
  LD HL,ShipTemplate
  LDIR
  LD A,(IY+$07)
  LD (IX+$22),A
  LD A,(IY+$12)
  LD C,A
  AND $6F
  LD (IX+$21),A
  LD A,(IY+$0A)
  AND $07
  RLA
  RL C
  RRA
  LD (IX+$20),A
  LD A,(IY+$06)
  SRL A
  LD (IX+$1B),A
  LD A,$7E
  LD (IX+$25),A
  XOR A
  LD (IX+$26),A
  SET 6,(IX+$20)
  BIT 2,(IX+$21)
  JR NZ,CreateShipPosition
  CALL Random
  AND $07
  LD (IX+$01),A
  CALL Random
  AND $07
  LD (IX+$04),A
CreateShipPosition:
  CALL Random
  LD (IX+$00),A
  CALL Random
  LD (IX+$03),A
  CALL Random
  RRA
  RR (IX+$02)
  RRA
  RR (IX+$05)
  XOR A
  RET

; Create blueprint A in a free slot at ship IX's position and axes (27 bytes
; copied); NZ when no slot is free
;
; Used by the routines at ActionMissile, ActionLaunch, ActionPod and
; DebrisFromShip.
LaunchShip:
  LD C,A
  PUSH IX
  CALL FreeSlot
  POP HL
  RET NZ
  PUSH HL
  LD A,C
  CALL CreateShip
  POP HL
  PUSH IX
  POP DE
  LD BC,$001B
  LDIR
  XOR A
  RET

; IX = the first free slot of 1-6 (Z), NZ when none
;
; Used by the routines at LaunchShip, CreateAtOrigin, ActionThargoids,
; ActionMissile, SpawnShip and SpawnMissionDone.
FreeSlot:
  LD IX,ShipSlots
  LD DE,$0027
  LD B,$06
FreeSlotLoop:
  ADD IX,DE
  LD A,(IX+$22)
  AND A
  RET Z
  DJNZ FreeSlotLoop
  INC B
  RET

; Create blueprint A in a free slot at the origin
;
; Used by the routine at DebrisNear.
CreateAtOrigin:
  LD C,A
  CALL FreeSlot
  RET NZ
  LD A,C

; Create blueprint A in IX at the origin, its nose and side turned
;
; Used by the routines at ActionMissile and ActionPod.
CreateHere:
  CALL CreateShip
  RES 7,(IX+$0E)
  RES 7,(IX+$16)
  LD (IX+$00),A
  LD (IX+$01),A
  LD (IX+$04),A
  LD (IX+$06),A
  LD (IX+$07),A
  RET

; Action 1: three or four Thargoids with ECM, ahead at random
;
; Used by the routine at ShipAction.
ActionThargoids:
  CALL Random
  AND $01
  ADD A,$03
  LD C,A
ActionThargoidsLoop:
  CALL FreeSlot
  RET NZ
  LD A,$0F
  PUSH BC
  CALL CreateShip
  SET 0,(IX+$25)
  CALL Random
  AND $0F
  OR $04
  LD (IX+$07),A
  RRA
  RRA
  RRA
  AND $01
  LD (IX+$01),A
  XOR A
  LD (IX+$04),A
  CALL RandomRoll
  POP BC
  DEC C
  JR NZ,ActionThargoidsLoop
  RET

; Action 2: a missile. C = 0: from ship IX at the player; else the player's,
; slot 7, below the view aimed at target C
;
; Used by the routine at ShipAction.
ActionMissile:
  LD A,C
  AND A
  JR Z,ActionMissileShip
  LD IX,ShipSlots
  LD DE,$0111
  ADD IX,DE
  LD A,(IX+$22)
  AND A
  JR Z,ActionMissilePlayer
  CALL FreeSlot
  RET NZ
ActionMissilePlayer:
  LD A,$01
  PUSH BC
  CALL CreateHere
  POP BC
  LD A,$6A
  LD (IX+$06),A
  LD A,$29
  LD (IX+$03),A
  LD A,$80
  LD (IX+$05),A
  LD A,C
  JR ActionMissileTarget
ActionMissileShip:
  LD A,$01
  CALL LaunchShip
  RET NZ
  LD A,(SpeedRate)
  ADD A,(IX+$1B)
  LD (IX+$1B),A
ActionMissileTarget:
  LD (IX+$25),C
  SET 0,(IX+$26)
  XOR A
  RET

; Action 4: a ship from IX; C 1 a Viper, 2 a trader (Cobra or Python), 3 a
; Thargon, 4 a Thargoid, 5 a Sidewinder or a Krait
;
; The new ship is turned about (FlipShip) unless it leaves the station, and is
; hostile when its launcher is.
ActionLaunch:
  LD A,$08
  DEC C
  JR Z,ActionLaunchNow
  CALL Random
  AND $01
  ADD A,$09
  DEC C
  JR Z,ActionLaunchNow
  LD A,$12
  DEC C
  JR Z,ActionLaunchNow
  LD A,$0F
  DEC C
  JR Z,ActionLaunchNow
  DEC C
  RET NZ
  CALL Random
  BIT 0,A
  LD A,$10
  JR Z,ActionLaunchNow
  LD A,$11
ActionLaunchNow:
  PUSH IX
  CALL LaunchShip
  POP IY
  RET NZ
  BIT 2,(IY+$26)
  CALL Z,FlipShip
  BIT 2,(IY+$21)
  RET Z
  SET 2,(IX+$21)
  XOR A
  RET

; Turn a launched ship about one way or the other (in turn)
;
; Used by the routines at ActionLaunch and DebrisFromShip.
FlipShip:
  LD A,(FlipToggle)
  XOR $01
  LD (FlipToggle),A
  JR Z,FlipShipOther
  PUSH IX
  CALL SwapAxisPair
  CALL SwapAxisPair
  CALL SwapAxisPair
  POP IX
  RET

; One pair of nose and roof parts swapped, the side's sign flipped
;
; Used by the routine at FlipShip.
SwapAxisPair:
  LD A,(IX+$0A)
  LD B,(IX+$10)
  LD (IX+$10),A
  LD (IX+$0A),B
  LD A,(IX+$16)
  XOR $80
  LD (IX+$16),A
  INC IX
  INC IX
  RET
; This entry point is used by the routine at FlipShip.
FlipShipOther:
  LD A,(IX+$10)
  XOR $80
  LD B,(IX+$0A)
  LD (IX+$0A),A
  LD (IX+$10),B
  LD A,(IX+$12)
  XOR $80
  LD B,(IX+$0C)
  LD (IX+$0C),A
  LD (IX+$12),B
  LD A,(IX+$14)
  XOR $80
  LD B,(IX+$0E)
  LD (IX+$0E),A
  LD (IX+$14),B
  RET

; Random roll and pitch counters (bits 0-2 and 7)
;
; Used by the routines at ActionThargoids, DebrisNear and ActionPod.
RandomRoll:
  CALL Random
  AND $87
  LD (IX+$0A),A
  CALL Random
  AND $87
  LD (IX+$0C),A
  RET

; Action 5: two alloy plates; C bit 0 near the origin (PlateNear called, then
; fallen into), else from IX
;
; Used by the routine at ShipAction.
ActionPlates:
  BIT 0,C
  JR Z,ActionPlatesTwo
  CALL PlateNear
  RET NZ

; A plate at a random place just ahead
;
; Used by the routine at ActionPlates.
PlateNear:
  LD A,$03

; Debris A at a random place ahead ($10-$4F across, $19 deep), spinning, at a
; random speed
;
; Used by the routine at ActionCanister.
DebrisNear:
  CALL CreateAtOrigin
  RET NZ
  CALL RandomRoll
  RES 6,(IX+$20)
  CALL Random
  AND $3F
  OR $10
  LD (IX+$00),A
  LD A,(IX+$0A)
  AND $80
  XOR $80
  LD (IX+$02),A
  CALL Random
  AND $3F
  OR $10
  LD (IX+$03),A
  LD A,(IX+$0C)
  AND $80
  XOR $80
  LD (IX+$05),A
  LD A,$19
  LD (IX+$06),A
  CALL Random
  LD (IX+$1D),A
  CALL Random
  AND $1F
  OR $08
  LD (IX+$1B),A
  XOR A
  RET
; This entry point is used by the routine at ActionPlates.
ActionPlatesTwo:
  LD A,$03
  CALL DebrisFromShip
  RET NZ
  LD A,$03
  JR DebrisFromShip

; Action 6: a canister; C bit 0 near, else from IX
;
; Used by the routine at ShipAction.
ActionCanister:
  BIT 0,C
  LD A,$04
  JR Z,ActionPodFromShip
  JR DebrisNear

; Action 7: the escape pod; C bit 0 the player's Cobra flying off in slot 6,
; else a pod from IX
;
; Used by the routine at ShipAction.
ActionPod:
  BIT 0,C
  LD A,$02
  JR Z,ActionPodFromShip
  LD A,$09
  LD IX,ShipSlots+$00EA
  CALL CreateHere
  CALL RandomRoll
  LD A,$80
  LD (IX+$05),A
  LD A,$1C
  LD (IX+$03),A
  RES 6,(IX+$20)
  LD A,$4C
  LD (IX+$06),A
  LD A,$C0
  LD (IX+$1E),A
  LD A,(SpeedRate)
  ADD A,(IX+$1B)
  LD (IX+$1B),A
  XOR A
  RET
; This entry point is used by the routine at ActionCanister.
ActionPodFromShip:
  PUSH IX
  CALL LaunchShip
  EX (SP),IX
  POP HL
  RET NZ
  PUSH HL
  EX (SP),IX
  RES 6,(IX+$20)
  LD A,$0A
  LD (IX+$26),A
  LD A,$80
  LD (IX+$1D),A
  XOR A
  POP IX
  RET

; Action 8: two splinters from IX
;
; Used by the routine at ShipAction.
ActionSplinters:
  LD A,$05
  CALL DebrisFromShip
  RET NZ
  LD A,$05

; Debris A from IX, turned, passive, spinning for ever
;
; Used by the routines at DebrisNear and ActionSplinters.
DebrisFromShip:
  PUSH IX
  CALL LaunchShip
  EX (SP),IX
  POP HL
  RET NZ
  PUSH HL
  EX (SP),IX
  CALL FlipShip
  LD A,$0A
  LD (IX+$26),A
  RES 6,(IX+$20)
  SET 7,(IX+$1D)
  POP IX
  XOR A
  RET

; Action 9: blueprint C + 2 in slot 7 for the title, its axes from
; TitleShipAxes, spinning
;
; Used by the routine at ShipAction.
ActionTitleShip:
  LD IX,Slot7
  LD A,C
  ADD A,$02
  CALL CreateShip
  LD A,$C0
  LD (IX+$1D),A
  LD (IX+$1E),A
  XOR A
  LD (IX+$06),A
  LD (IX+$00),A
  LD (IX+$01),A
  LD (IX+$03),A
  LD (IX+$04),A
  LD (IX+$08),A
  LD (IX+$1B),A
  RES 6,(IX+$20)
  INC A
  INC A
  LD (IX+$07),A
  PUSH IX
  POP HL
  LD DE,$0009
  LD B,D
  LD C,E
  ADD HL,DE
  EX DE,HL
  LD HL,TitleShipAxes
ActionTitleShipAxes:
  INC DE
  LDI
  JP PE,ActionTitleShipAxes
  RET

; Action 0: maybe a new ship: the mission's Asp, an asteroid, pirates, traders,
; hunters or Thargoids
;
; The danger C is (slaves + narcotics) x 2 + firearms in the hold ($D06E,
; $D071, $D075). A random byte below $1E with the mission's conditions ($D0B0
; AND $42 = 2) brings the mission's Asp. Else a random byte less the danger:
; 80-89 an asteroid, 90 and up nothing; below 80, or below the danger (a
; borrow), SpawnDanger: a Thargoid in mission state 4, a Python in state 1,
; else by the government ($D09D: anarchies always) a lone pirate ($0B-$0F, the
; rarer the stronger, one in five with ECM), a trader or a Rock Hermit, or a
; group of two or three Sidewinders and Kraits.
SpawnShip:
  LD A,(CargoHold+$0003)
  LD C,A
  LD A,(CargoHold+$0006)
  ADD A,C
  ADD A,A
  LD C,A
  LD A,(CargoHold+$000A)
  ADD A,C
  LD C,A
  LD A,(MissionShip)
  AND A
  JR NZ,SpawnRandom
  CALL Random
  CP $1E
  JR NC,SpawnRandom
  LD A,(MissionFlags)
  AND $42
  CP $02
  JR NZ,SpawnRandom
  DEC A
  LD (MissionShip),A
  LD A,$0F
  LD HL,SpawnMissionDone
  PUSH HL
  PUSH AF
  CALL FreeSlot
  RET NZ
  LD A,$0D
  JR SpawnMissionDoneCallCreateShip

; The Asp's own state after the mission spawn (m2 frame 7922: the cloak ship's
; Asp, MissionFlags $07)
SpawnMissionDone:
  SET 6,(IX+$26)
  SET 2,(IX+$20)
  JP SpawnGroup
; This entry point is used by the routine at SpawnShip.
SpawnRandom:
  CALL Random
  SUB C
  JR C,SpawnDanger
  CP $5A
  RET NC
  CP $50
  JR C,SpawnDanger
  CALL FreeSlot
  RET NZ
  LD A,$06
  CALL CreateShip
  SET 7,(IX+$0E)
  RES 6,(IX+$20)
  LD A,$C0
  LD (IX+$1D),A
  RET
SpawnDanger:
  LD B,A
  AND $07
  LD E,A
  LD A,(MissionState)
  CP $04
  LD D,A
  LD C,$0F
  JR Z,SpawnMission
  LD A,D
  CP $01
  LD C,$0A
  JR Z,SpawnMission
  LD A,(Seeds+$000F)
  AND $07
  JR Z,SpawnGovernment
  INC E
  CP E
  RET NC
SpawnGovernment:
  LD C,A
  BIT 3,B
  JP Z,SpawnTrader
SpawnPirate:
  CALL FreeSlot
  RET NZ
  CALL Random
  AND $3F
  LD B,$0F
  JR Z,SpawnPirateKind
  DEC B
  SUB $0C
  JR C,SpawnPirateKind
  DEC B
  SUB $12
  JR C,SpawnPirateKind
  DEC B
  SUB $10
  JR C,SpawnPirateKind
  DEC B
SpawnPirateKind:
  LD A,B
SpawnCreate:
  PUSH AF
; This entry point is used by the routine at SpawnShip.
SpawnMissionDoneCallCreateShip:
  CALL CreateShip
  POP AF
  CP $0F
  JR Z,SpawnECM
  CALL Random
  CP $33
  RET NC
SpawnECM:
  SET 0,(IX+$25)
  RET
SpawnMission:
  CALL FreeSlot
  RET NZ
  LD A,C
  JR SpawnCreate
SpawnTrader:
  CALL Random
  LD B,A
  AND $07
  CP E
  JR NC,SpawnGroup
  RLC B
  RLC B
  RLC B
  LD C,B
  CALL FreeSlot
  RET NZ
  LD A,C
  AND $07
  CP $02
  JR C,SpawnTraderOther
  DEC A
  SRL A
  SRL A
  ADD A,$09
  JR SpawnCreate
SpawnTraderOther:
  LD A,C
  RLCA
  AND $01
  ADD A,$07
  JR SpawnCreate
SpawnGroup:
  CALL Random
  AND $03
  RRA
  ADC A,$02
  LD C,A
SpawnGroupLoop:
  CALL FreeSlot
  RET NZ
  PUSH BC
  CALL Random
  AND $01
  ADD A,$10
  CALL CreateShip
  POP BC
  DEC C
  JR NZ,SpawnGroupLoop
  RET

; FaceVisibility's work: the blueprint, the normals' scale, the rotated normal
; and its signs
FaceBlueprint:
  DEFW $0000

; FaceScale
FaceScale:
  DEFB $00

; FaceNormal
FaceNormal:
  DEFB $00,$00,$00,$00,$00,$00

; FaceSigns
FaceSigns:
  DEFB $00,$00,$00

; Each face: visible when its rotated normal points at the player (the dot
; product with the ship's position is negative)
;
; A face whose visibility distance passes is tested; one that fails is hidden.
; A ship with no faces (+$05 = 0) shows everything. 608 runs.
FaceVisibility:
  PUSH IX
  PUSH IY
  PUSH IY
  EX (SP),IX
  POP HL
  LD (FaceBlueprint),HL
  LD D,(IX+$11)
  LD E,(IX+$10)
  ADD IX,DE
  LD DE,FaceVisible
  LD A,(IY+$13)
  LD (FaceScale),A
  LD A,(IY+$05)
  AND A
  LD IY,ViewMatrix
  JR NZ,FaceVisibilityLoop
  INC A
  LD (DE),A
  JR FaceVisibilityDone
FaceVisibilityLoop:
  PUSH AF
  PUSH DE
  LD A,(IX+$03)
  AND $1F
  CP $1F
  JR Z,FaceVisibilityTest
  LD B,A
  LD A,(ShipDistance)
  CP B
  JR C,FaceVisibilityTest
  POP DE
  XOR A
  JR FaceVisibilityStore
FaceVisibilityTest:
  PUSH IY
  LD HL,(FaceBlueprint)
  PUSH HL
  CALL NormalPart
  LD (FaceSigns),A
  LD (FaceNormal),HL
  CALL NormalPart
  LD (FaceSigns+$0001),A
  LD (FaceNormal+$0002),HL
  CALL NormalPart
  LD (FaceSigns+$0002),A
  LD (FaceNormal+$0004),HL
  POP HL
  PUSH IX
  LD IY,FaceNormal
  LD IX,FaceSigns
  CALL FaceDot
  POP IX
  POP IY
  POP DE
  XOR A
  SLA H
  JR NC,FaceVisibilityStore
  INC A
FaceVisibilityStore:
  LD (DE),A
  INC DE
  LD BC,$0004
  ADD IX,BC
  POP AF
  DEC A
  JR NZ,FaceVisibilityLoop
FaceVisibilityDone:
  POP IY
  POP IX
  RET

; The dot product of the rotated normal and the position, three terms summed
;
; Used by the routine at FaceVisibility.
FaceDot:
  LD E,(IY+$01)
  LD C,(IY+$00)
  LD A,(IX+$00)
  CALL MultiplyWord
  PUSH HL
  LD E,(IY+$03)
  LD C,(IY+$02)
  LD A,(IX+$01)
  CALL MultiplyWord
  PUSH HL
  LD E,(IY+$05)
  LD C,(IY+$04)
  LD A,(IX+$02)
  CALL MultiplyWord
  POP DE
  CALL AddSignedHalf
  ADC HL,HL
  BIT 7,B
  JR Z,FaceDotLast
  SET 7,H
FaceDotLast:
  POP DE
  JP AddSignedHalf

; A (sign and magnitude) times the word C E: two products summed
;
; Used by the routine at FaceDot.
MultiplyWord:
  LD B,A
  SLA B
  AND $80
  XOR E
  LD E,A
  CALL Multiply8High
  LD D,E
  LD E,A
  LD C,D
  RES 7,C
  PUSH DE
  CALL Multiply8
  POP DE
  LD A,D
  LD D,$00
  ADD HL,DE
  ADD HL,HL
  RLA
  RR H
  RR L
  RET

; One rotated part of the normal, scaled by the blueprint's +$13, the ship's
; position part added
;
; Used by the routine at FaceVisibility.
NormalPart:
  CALL RotateNormal
  POP BC
  EX (SP),IX
  LD E,(IX+$00)
  LD D,(IX+$01)
  LD A,(IX+$02)
  INC IX
  INC IX
  INC IX
  EX (SP),IX
  PUSH BC
  LD C,A
  LD A,(FaceScale)
  SLA L
  PUSH HL
  LD B,A
  INC B
NormalPartScale:
  SRL L
  DJNZ NormalPartScale
  RL L
  LD A,C
  XOR H
  SLA H
  RLA
  JR C,NormalPartSub
  ADD HL,DE
  JR NormalPartDone
NormalPartSub:
  EX DE,HL
  AND A
  SBC HL,DE
  JR NC,NormalPartDone
  ADD HL,DE
  EX DE,HL
  AND A
  SBC HL,DE
  LD A,C
  XOR $80
  LD C,A
NormalPartDone:
  SLA C
  RR H
  RR L
  POP DE
  LD A,E
  RL D
  RRA
  RET
