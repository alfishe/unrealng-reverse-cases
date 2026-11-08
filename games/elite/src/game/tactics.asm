; --------------------------------------------------------------------------------------------------------------------
; tactics.asm: The title's ship and the ships' tactics: energy, launches, fleeing, the missile's homing, steering and firing
;
; Tactics run for a ship with bit 6 of its flags set, every fourth frame per slot (UpdateSlotAlive); a missile homes
; every frame. Each pass the ship regains energy, may launch a ship of its own (a trader's escape pod, the station's
; traffic or a Thargoid's Thargons), may flee or bail out when weak, then steers: TacticsSteer takes the unit vector
; to its target (the player at the origin, or away from the player), its dot products with the ship's three axes give
; the roll, the pitch and the acceleration, and a hostile ship facing the player close enough fires its laser.
;
; Random $B799 gives the numbers: a 16-bit additive generator at RandomSeed $B7AA.
; --------------------------------------------------------------------------------------------------------------------

; Two zero bytes no code reads (known from the code only)
RateSpare:
  DEFB $00,$00

; Turn the title's ship (slot 7) by fixed rates, tidy its roof and side axes
; and draw it
;
; Roll $94 (TurnRates) and pitch $8C (A) through MoveShip with the ship's own
; speed; 393 runs (the title of f1, w1, d1).
TurnTitleShip:
  LD IX,Slot7
  LD H,(IX+$24)
  LD L,(IX+$23)
  PUSH HL
  POP IY
  LD A,$94
  LD (TurnRates),A
  LD A,$8C
  CALL MoveShip
  CALL Orthogonalise
  LD IX,Slot7+$0009
  CALL TidyAxis
  CALL TidyAxis
  LD IX,Slot7
  JP DrawShip

; The vector to the target (three words), its length after Normalise ($A2BE)
TargetVector:
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00

; Energy, launches, fleeing or bailing out, the station's traffic, then
; steering
;
; Energy: one more a pass (four more above $F0 of the blueprint's maximum,
; +$07), up to it. A weak ship (energy x 2 below the maximum): with launches
; left (+$20 bits 0-2) and the random byte below $80 and no ECM it launches its
; payload: ship action 4 of the kind in the blueprint's +$0A high nibble (a
; Thargoid's Thargons, the station's ships), or a missile at the player (action
; 2) when the nibble is 0, a trader with a pod may bail out (action 7: the pod,
; then the ship becomes passive cargo), or cargo is dropped (action 6). The
; cloak ship (MissionShip $9CB2): 1 (cloaked) becomes 2 (seen) below $34
; energy, 2 goes back to 1 at $50 and more. While the player is cloaked
; (CloakOn $D041) no ship runs its tactics. The station (role bit 2) launches a
; ship at random when fewer than 4 are active: a Viper ($14 hostile, the
; station angry) or traffic ($24 / $44).
Tactics:
  LD A,(IY+$07)
  LD C,(IX+$22)
  INC C
  CP $F0
  JR C,TacticsEnergyMax
  INC C
  INC C
  INC C
TacticsEnergyMax:
  CP C
  JR C,TacticsEnergy
  LD A,C
TacticsEnergy:
  LD B,A
  LD A,(CloakOn)
  AND A
  RET NZ
  LD HL,MissionShip
  LD A,B
  CP $50
  LD A,(HL)
  JR C,TacticsMission
  CP $02
  JR NZ,TacticsMission
  DEC (HL)
TacticsMission:
  CP $01
  JR NZ,TacticsEnergyStore
  LD A,B
  CP $34
  JR NC,TacticsMissionWeak
  LD A,$02
  LD (HL),A
  JR TacticsEnergyStore
TacticsMissionWeak:
  SUB $02
  LD B,A
TacticsEnergyStore:
  LD A,B
  LD (IX+$22),A
  LD B,(IY+$07)
  ADD A,A
  JR C,TacticsHermit
  CP B
  JR NC,TacticsHermit
  ADD A,A
  JR C,TacticsLaunch
  ADD A,A
  JR C,TacticsLaunch
  CP B
  JR C,TacticsWeak
TacticsLaunch:
  LD A,(IX+$20)
  AND $07
  JR Z,TacticsHermit
  CALL Random
  CP $80
  JR NC,TacticsHermit
  LD A,(ECMActive)
  AND A
  JR NZ,TacticsHermit
  LD A,(IY+$0A)
  AND $F0
  JR NZ,TacticsLaunchShip
  OR $06
TacticsLaunchShip:
  XOR $04
  LD B,A
  PUSH BC
  CALL LaunchFromShip
  POP BC
  JR NZ,TacticsHermit
  DEC (IX+$20)
  LD A,B
  CP $02
  JR NZ,TacticsHermit
  LD HL,Messages+$0002
  SET 7,(HL)
  JR TacticsHermit
TacticsWeak:
  CALL Random
  CP (IX+$25)
  JR C,TacticsECM
  BIT 7,(IX+$20)
  JR Z,TacticsDrop
  LD A,$07
  CALL LaunchFromShip
  JR NZ,TacticsHermit
  RES 7,(IX+$20)
  RES 6,(IX+$20)
  RET
TacticsDrop:
  LD A,(IY+$00)
  AND A
  JR Z,TacticsHermit
  LD A,$06
  CALL LaunchFromShip
TacticsHermit:
  LD A,(IY+$12)
  CP $04
  JR NZ,TacticsECM
  PUSH IX
  LD IX,ShipSlots
  LD DE,$0027
  LD B,$06
TacticsHermitLoop:
  ADD IX,DE
  LD A,(IX+$22)
  AND A
  JR Z,TacticsHermitNext
  LD A,(IX+$21)
  SUB $0C
  JR Z,TacticsHermitDone
TacticsHermitNext:
  DJNZ TacticsHermitLoop
  INC A
TacticsHermitDone:
  POP IX
  JP Z,TacticsSteer
  RES 6,(IX+$20)
  SET 1,(IX+$26)
  SRL (IX+$1B)
  RET
TacticsECM:
  BIT 0,(IX+$25)
  JR Z,TacticsStation
  LD A,(MissionState)
  CP $04
  JR NZ,TacticsGetECMActive
  LD A,(MissionFlags)
  BIT 7,A
  JR NZ,TacticsStation
TacticsGetECMActive:
  LD A,(ECMActive)
  AND A
  JR NZ,TacticsStation
  LD HL,Slot7+$0022
  LD A,(HL)
  AND A
  JR Z,TacticsStation
  BIT 2,(IX+$26)
  JR NZ,TacticsECMOn
  CALL Random
  CP $A0
TacticsECMOn:
  LD A,$0A
  LD (ECMActive),A
TacticsStation:
  BIT 2,(IX+$26)
  JR Z,TacticsSteer
  LD A,(ActiveShips)
  CP $04
  RET NC
  CALL Random
  BIT 2,(IX+$21)
  JR Z,TacticsStationTraffic
  CP $24
  RET NC
  LD A,(MissionState)
  CP $04
  LD A,$14
  JR NZ,LaunchFromShip
  CALL Random
  CP $88
  RET NC
  LD A,$44
  JR LaunchFromShip
TacticsStationTraffic:
  CP $02
  RET NC
  LD A,$24

; ShipAction A with IX and IY kept: a ship launched from this one
;
; Used by the routine at Tactics.
LaunchFromShip:
  PUSH IY
  PUSH IX
  CALL ShipAction
  POP IX
  POP IY
  RET

; Carry when |x| and |y| are below DE and |z| below DE + $200: the ship is near
; the player
;
; Used by the routine at TacticsSteer.
NearBox:
  LD H,(IX+$01)
  LD L,(IX+$00)
  AND A
  SBC HL,DE
  RET NC
  LD H,(IX+$04)
  LD L,(IX+$03)
  AND A
  SBC HL,DE
  RET NC
  LD H,(IX+$07)
  LD L,(IX+$06)
  INC D
  INC D
  AND A
  SBC HL,DE
  RET

; Choose the target: towards the player (hostile, not fleeing) or away from it,
; then TacticsAim
;
; A legal-sensitive ship (+$21 bit 1) turns hostile when $D060 (the combat
; score's low byte, the record's +$0C) is $28 or more. Near the player (within
; $200, or $A00 with avoidance) a ship steers away; a hostile ship flees (+$25
; bit 7) when its state is below 8 with no station about or in mission state 4.
TacticsSteer:
  BIT 1,(IX+$21)
  JR Z,TacticsSteerNear
  LD A,(CombatScore)
  CP $28
  JR C,TacticsSteerNear
  SET 2,(IX+$21)
TacticsSteerNear:
  LD DE,$0200
  CALL NearBox
  JR C,TacticsSteerAway
  BIT 5,(IX+$26)
  JR Z,TacticsSteerHostile
  LD D,$0A
  CALL NearBox
  JR C,TacticsSteerAway
TacticsSteerHostile:
  BIT 2,(IX+$21)
  RET Z
  LD A,(MissionState)
  CP $04
  JR Z,TacticsSteerFlee
  LD A,(ShipSlots+$0022)
  AND A
  JR Z,TacticsSteerFlee
  BIT 3,(IX+$21)
  JR Z,TacticsSteerTowards
  JR TacticsSteerAway
TacticsSteerFlee:
  LD A,(IX+$25)
  AND $7F
  CP $08
  JR NC,TacticsSteerTowards
  SET 7,(IX+$25)
TacticsSteerAway:
  PUSH IX
  CALL TowardsPart
  LD (TargetVector),HL
  CALL TowardsPart
  LD (TargetVector+$0002),HL
  CALL TowardsPart
  LD (TargetVector+$0004),HL
  POP IX
  SET 5,(IX+$26)
  JR TacticsAimNow
; This entry point is used by the routine at MissileHoming.
TacticsSteerTowards:
  PUSH IX
  CALL AwayPart
  LD (TargetVector),HL
  CALL AwayPart
  LD (TargetVector+$0002),HL
  CALL AwayPart
  LD (TargetVector+$0004),HL
  POP IX
  RES 5,(IX+$26)
; This entry point is used by the routine at MissileHoming.
TacticsAimNow:
  JP TacticsAim

; The missile: an ECM destroys it; else it aims at its target and explodes when
; within $40 of it
;
; The target is +$25 (0 the player, else 8 - slot). Hitting the station in
; mission state 4 ends the mission's station (role bit 7, $D0AF bit 3) and
; takes a large combat score. k2's missile ran here once (frame 2571) before a
; Thargoid's E.C.M. destroyed it; m2 and fs had missiles fired at the player
; (37 and 1926 runs). Hitting the station is known from the code only.
MissileHoming:
  LD A,(ECMActive)
  AND A
  JR Z,MissileSeek
  RES 6,(IX+$20)
  SET 4,(IX+$20)
  RET
MissileSeek:
  LD A,(IX+$25)
  AND A
  JR Z,TacticsSteerTowards
  PUSH IY
  LD IY,ShipSlots-$27
  LD DE,$0027
  SUB $0A
  CPL
  LD B,A
MissileSeekLoop:
  ADD IY,DE
  DJNZ MissileSeekLoop
  PUSH IX
  PUSH IY
  CALL RelativePart
  LD (TargetVector),HL
  CALL RelativePart
  LD (TargetVector+$0002),HL
  CALL RelativePart
  LD (TargetVector+$0004),HL
  POP IY
  POP IX
  CALL FarPart
  JR NZ,MissileAim
  LD HL,(TargetVector+$0002)
  CALL FarPart
  JR NZ,MissileAim
  LD HL,(TargetVector)
  CALL FarPart
  JR NZ,MissileAim
  BIT 2,(IY+$26)
  JR Z,MissileHit
  LD HL,MissionState
  LD A,(HL)
  CP $04
  JR NZ,MissileExplode
  SET 3,(HL)
  DEC L
  XOR A
  LD (HL),A
  LD DE,$FFFF
  CALL AddCombatVector
  SET 7,(IY+$26)
MissileHit:
  SET 4,(IY+$20)
MissileExplode:
  POP IY
  SET 4,(IX+$20)
  RET
MissileAim:
  POP IY
  JP TacticsAimNow

; NZ when a part (HL, doubled) is $40 or more: not yet at the target
;
; Used by the routine at MissileHoming.
FarPart:
  ADD HL,HL
  LD A,H
  AND A
  RET NZ
  LD A,L
  AND $C0
  RET

; One part of (target - missile) / 2, through SubtractSigned $AFC9
;
; Used by the routine at MissileHoming.
RelativePart:
  LD L,(IY+$00)
  LD H,(IY+$01)
  LD C,(IY+$02)
  LD E,(IX+$00)
  LD D,(IX+$01)
  LD B,(IX+$02)
  SLA C
  RR H
  RR L
  SLA B
  RR D
  RR E
  CALL SubtractSigned
  LD DE,$0003
  ADD IX,DE
  ADD IY,DE
  RET

; One part of the ship's position, its sign flipped: the vector away from the
; player, halved
;
; Used by the routine at TacticsSteer.
AwayPart:
  LD A,(IX+$02)
  XOR $80
  JR TowardsPartNow

; One part of the ship's position, halved, its sign in bit 7: the vector to
; steer along
;
; Used by the routine at TacticsSteer.
TowardsPart:
  LD A,(IX+$02)

; TowardsPartNow
;
; Used by the routine at AwayPart.
TowardsPartNow:
  LD L,(IX+$00)
  LD H,(IX+$01)
  SRL H
  RR L
  RLA
  RR H
  RR L
  LD DE,$0003
  ADD IX,DE
  RET

; Normalise the target vector, the dot products with the nose, the roof and the
; side: the roll, the pitch, the speed, the laser
;
; Roll from the side's product (up to 15 steps, its sign against the roof),
; pitch from the roof's when the roll is small, the acceleration 2 when
; fleeing. Ahead (the nose's product positive): accelerate when far (1 or 2),
; and a hostile ship facing the player (z and the nose's z of opposite signs)
; fires when a random byte is below its laser power (+$02 of the blueprint,
; halved while $D062, the combat score's high byte, is 0) and the product is
; above $0C: the player is hit on the front or aft shield (7 more), the laser
; sound requested. Behind: brake (-1 or -2).
TacticsAim:
  PUSH IY
  LD IY,TargetVector
  PUSH IX
  LD IX,TargetVector
  CALL Normalise
  POP IX
  LD (TargetVector+$0006),DE
  PUSH IX
  LD DE,$0009
  ADD IX,DE
  CALL DotProduct
  LD DE,$0006
  ADD IX,DE
  LD H,A
  PUSH HL
  CALL DotProduct
  POP HL
  LD L,A
  PUSH HL
  LD DE,$0006
  ADD IX,DE
  CALL DotProduct
  POP HL
  POP IX
  POP IY
  LD D,A
  AND $7F
  JR Z,TacticsAimPitch
TacticsAimRoll:
  LD C,A
  SRL C
  SRL C
  SRL C
  ADC A,C
  SRL A
  SRL A
  CP $0F
  JR C,TacticsAimRollStore
  LD A,$0F
TacticsAimRollStore:
  LD B,A
  LD A,D
  XOR L
  AND $80
  RRA
  OR B
  LD (IX+$1D),A
  AND $3F
  CP $04
  JR NC,TacticsAimSpeed
TacticsAimPitch:
  LD A,H
  BIT 7,A
  JR Z,TacticsAimPitchMax
  AND $7F
  ADD A,$50
  SRL A
  CPL
  ADD A,$68
  SRL A
  CP $40
  JR C,TacticsAimPitchStore
TacticsAimPitchMax:
  LD A,$3F
TacticsAimPitchStore:
  SLA L
  RRA
  SRL A
  LD (IX+$1E),A
TacticsAimSpeed:
  XOR A
  BIT 7,(IX+$25)
  JR Z,TacticsAimAccel
  LD A,$02
TacticsAimAccel:
  LD (IX+$1C),A
  RET NZ
  LD DE,(TargetVector+$0006)
  LD A,D
  SLA H
  JR NC,TacticsAimBehind
  LD B,$0A
  BIT 0,(IX+$26)
  JR Z,TacticsAimAhead
  LD B,$02
TacticsAimAhead:
  CP B
  JR C,TacticsAimFire
  LD B,$01
  CP $10
  JR NC,TacticsAimAccelStore
  INC B
TacticsAimAccelStore:
  LD (IX+$1C),B
TacticsAimFire:
  BIT 2,(IX+$21)
  RET Z
  LD A,(IX+$08)
  XOR (IX+$0E)
  AND $80
  RET Z
  LD B,(IY+$02)
  LD A,(CombatScore+$0002)
  AND A
  JR NZ,TacticsAimFireRoll
  SRL B
TacticsAimFireRoll:
  CALL Random
  CP B
  RET NC
  LD A,(IX+$26)
  AND $0F
  RET NZ
  LD A,D
  CP $0C
  RET NC
  SLA H
  RET NC
  SET 3,(IX+$20)
  LD A,D
  CP $04
  JR C,TacticsAimHit
  SLA H
  RET NC
TacticsAimHit:
  LD HL,SoundRequests
  SET 6,(HL)
  BIT 7,(IX+$08)
  JR Z,TacticsAimHitFront
  LD A,(AftHits)
  ADD A,$07
  LD (AftHits),A
  RET
TacticsAimHitFront:
  LD A,(FrontHits)
  ADD A,$07
  LD (FrontHits),A
  RET
TacticsAimBehind:
  LD B,$0B
  BIT 0,(IX+$26)
  JR Z,TacticsAimBrake
  LD B,$03
TacticsAimBrake:
  CP B
  RET C
  LD B,$FF
  CP $12
  JR C,TacticsAimBrakeStore
  DEC B
TacticsAimBrakeStore:
  LD (IX+$1C),B
  RET

; HL: H = the sign, A = -4 x A x B / 256 (the high bytes of two parts)
;
; Used by the routine at DotProduct.
MultiplyHigh4:
  LD C,A
  XOR B
  XOR $80
  SLA B
  SLA C
  PUSH AF
  CALL Multiply8High
  POP HL
  LD L,A
  RET

; A = the dot product of the axis at IX and the target vector at IY from their
; high bytes, sign in bit 7
;
; Used by the routines at TacticsAim and Orthogonalise.
DotProduct:
  LD B,(IX+$01)
  LD A,(IY+$01)
  CALL MultiplyHigh4
  PUSH HL
  LD B,(IX+$03)
  LD A,(IY+$03)
  CALL MultiplyHigh4
  PUSH HL
  LD B,(IX+$05)
  LD A,(IY+$05)
  CALL MultiplyHigh4
  POP DE
  CALL AddSignedBytes
  JR NC,DotProductSecond
  LD A,$FF
DotProductSecond:
  POP DE
  LD L,A
  CALL AddSignedBytes
  JR NC,DotProductDone
  LD A,$FF
DotProductDone:
  RL H
  RRA
  RET

; DotProductSpare
DotProductSpare:
  DEFB $00
