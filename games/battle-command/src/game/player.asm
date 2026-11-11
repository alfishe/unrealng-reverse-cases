; --------------------------------------------------------------------------------------------------------------------
; player.asm: The player's tank: steering, fuel, armour, terrain and boundary checks, the weapons and their projectiles
;
; The player is record 0 ($75F0): speed $75F7, heading $7612, X $7613-$7615, Y $7616-$7618, height $75F5, step handler
; $7608 (PlayerStep $A8C7), collision handler PlayerHit $CAA5. Fuel $7C57, armour $8301-$8303 (sides) and $8304 (top),
; the four loaded weapon slots $8368 (6 bytes: +0 store type, +5 ammunition), the current slot $C53C.
; --------------------------------------------------------------------------------------------------------------------

  ORG $A8C7

; The player's step handler: terrain, boundary, fuel, the turret
;
; Record 0's step handler (+$18 = `$A8C7`, run by RunObjectHandlers `$C026`
; with IX = `$75F0`). Calls TerrainCollision through `$67F1`; on a hit the
; terrain type `$CE69` decides: 2 or `$80` (a wall) negates the speed and sets
; the handler to BounceDecay `$CC09`; 0 or 6 (rough ground) stores 1.25 x the
; speed (signed) in `$7E8E`; IX+7 is restored at once, so the tank's speed does
; not change and nothing resident reads `$7E8E` (`$A8F0`-`$A934`,
; docs/10-gameplay-logic.md 10.2). Then BoundaryCheck `$D4B8`, then the fuel:
; `$7C57` -= (|speed| >> 4) OR 1; on an underflow `$A94E` sets the failure
; reason `$7BF9` = `$CCED` ("RAN OUT OF FUEL") and calls `$7047`. The Infinite
; Fuel POKE writes 42 at `$A958` (`LD ($7C57),HL` becomes `LD HL,($7C57)`).
; Then the turret and speed against the control state `$985F`.
;
; Witness: L1 3503 (death, m2erbe, missions, play, play2).
PlayerStep:
  JR l_A8C9
l_A8C9:
  CALL ApiVector17
  JR NC,l_A8ED
  LD A,(TerrainType)
  CP $02
  JR Z,l_A8D9
  CP $80
  JR NZ,l_A8F2
l_A8D9:
  LD A,(IX+$07)
  NEG
  LD (IX+$07),A
  CALL ApiVector00
  LD (IX+$18),$09
  LD (IX+$19),$CC
  RET
l_A8ED:
  LD A,$03
  LD (TerrainType),A
l_A8F2:
  LD A,(KeyState)
  AND $02
  JR Z,l_A901
  LD A,(KeyCode)
  CP $53
  JP Z,l_A9C0
l_A901:
  LD A,(TerrainType)
  CP $00
  JR Z,l_A90C
  CP $06
  JR NZ,l_A92F
l_A90C:
  LD A,(IX+$07)
  AND A
  PUSH AF
  PUSH AF
  CALL ApiVector08
  LD C,A
  SRL A
  SRL A
  ADD A,C
  LD C,A
  POP AF
  LD A,C
  JP P,l_A923
  NEG
l_A923:
  LD (MissionParams+$000C),A
  LD (IX+$07),A
  POP AF
  LD (IX+$07),A
  JR l_A935
l_A92F:
  LD A,(IX+$07)
  LD (MissionParams+$000C),A
l_A935:
  CALL ApiVector08
  JR Z,l_A961
  SRL A
  SRL A
  SRL A
  SRL A
  OR $01
  LD B,$00
  LD C,A
  LD HL,(Fuel)
  SBC HL,BC
  JR NC,l_A958
OutOfFuel:
  LD HL,l_CCEB+$0002      ; fuel underflow: $7BF9 = $CCED "RAN OUT OF FUEL",
                          ; CALL $7047 (witness: the fuel recording, POKE Fuel
                          ; = 32, frame 7860, T 60 751-60 872)
  LD (FailReason),HL
  CALL ScreenSix
  RET
l_A958:
  LD (Fuel),HL            ; the Infinite Fuel POKE writes 42 here
  CALL BoundaryCheck
  CALL ApiVector00
l_A961:
  LD A,(StepY)
  NEG
  ADD A,(IX+$07)
  PUSH AF
  LD C,$30
  AND A
  JP P,l_A972
  SRL C
l_A972:
  CALL ApiVector08
  CP C
  JR C,l_A982
  DEC C
  POP AF
  LD A,C
  JP P,l_A983
  NEG
  JR l_A983
l_A982:
  POP AF
l_A983:
  LD (IX+$07),A

; Steering and the fire key: heading += turn / 2, the fire cooldown
;
; Adds half the turn input `$985E` to the heading `$7612`; counts down the fire
; cooldown `$A9FD`; when it is zero and the fire key bit of `$6D43` is set,
; calls the current weapon's fire routine through the operand at `$A9B9` (set
; from the store-type table `$7B89` + 8 * type, word 3). Output: a projectile
; record, the cooldown restarted.
;
; Witness: L1 3521 (death, m2erbe, missions, play, play2).
PlayerSteering:
  LD A,(StepX)
  SRA A
  ADD A,(IX+$22)
  LD (IX+$22),A
  LD A,(FireCooldown)
  AND A
  JR Z,l_A9A0
  DEC A
  LD (FireCooldown),A
  XOR A
  LD (PointerZones+$0001),A
  RET
l_A9A0:
  LD HL,PointerZones+$0001
  LD A,(HL)
  AND A
  RET Z
  LD (HL),$00
  LD A,(l_BA1F+$0008)
  AND A
  RET NZ
  LD HL,(NextView+$0008)
  LD BC,StartMission
  AND A
  SBC HL,BC
  JR NZ,l_A9BB
  CALL NoAction
l_A9BB:
  XOR A
  LD (PolyClipVars+$0002),A
  RET
; This entry point is used by the routine at PlayerStep.
l_A9C0:
  LD (IX+$18),$C9
  LD (IX+$19),$A9
  RET

; The brake (the S key): the player's step handler while S is down: |speed| - 8
; each pass, then 0 and PlayerStep again
;
; The S key (code `$53`) sets record 0's handler (+`$18`) to `$A9C9`. `LD
; A,(IX+7)` / `ABS` through `$67D6`, stores `$7E8E`; above 8 the speed loses 8
; with its sign kept, then PlayerSteering; below 8 the speed is 0 and the
; handler is PlayerStep `$A8C7` again (docs/05-controls.md 5.9).
;
; Known only from the code: no recording presses S in play (no L1 block of
; `$A9C9-$A9F6` in any recording).
BrakeKey:
  LD A,(IX+$07)
  AND A
  PUSH AF
  CALL ApiVector08
  LD (MissionParams+$000C),A
  SUB $08
  JR C,l_A9E9
  LD C,A
  POP AF
  LD A,C
  JP P,l_A9E0
  NEG
l_A9E0:
  LD (IX+$07),A
  CALL ApiVector00
  JP PlayerSteering
l_A9E9:
  POP AF
  XOR A
  LD (IX+$07),A
  LD (IX+$18),$C7
  LD (IX+$19),$A8
  RET

; Set the fire cooldown to 8 passes
;
; Writes 8 to the cooldown byte `$A9FD`, the delay before the next shot. Called
; by the fire routines after a launch.
;
; Witness: L1 69 (death, play, play2).
SetFireCooldown:
  LD A,$08
  LD (FireCooldown),A
  RET

; The fire cooldown, passes until the next shot
;
; Counted down by PlayerSteering `$A986`, set by SetFireCooldown `$A9F7`.
FireCooldown:
  DEFB $08

  ORG $B550

; Take one round from the current slot; find a slot for the projectile
;
; Reads the slot's ammunition pointer (`$B551`, from SelectAmmoPointer
; `$D3C6`), DEC A and stores it (the Infinite Ammo POKE writes 0 at `$B554`,
; the DEC A becomes NOP). Returns M when empty. Then FindFreeObject `$BCD6`,
; the fire sound `$D898`, and prints the count at `$C527`.
;
; Witness: L1 70 (death, play, play2).
ConsumeAmmo:
  LD HL,$0000
  LD A,(HL)
  DEC A                   ; the Infinite Ammo POKE writes 0 here (DEC A becomes
                          ; NOP)
  RET M
  EXX
  EX AF,AF'
  CALL FindProjectileSlot
  RET NC
  CALL SoundFire
  EXX
  EX AF,AF'
  LD (HL),A
  LD (WeaponVars),A
  EXX
  EX AF,AF'
  RET

; Fire the turret cannon (store type 4): projectile $81
;
; Ammunition, then ObjectSetType with `$81`, the position and heading of the
; player, +31 lifetime.
;
; Witness: L1 61 (death, play2).
FireCannon:
  LD A,(CurrentSlot)
  CALL SelectAmmoPointer
  CALL ConsumeAmmo
  RET NC
  RET M
  EX DE,HL
  PUSH DE
  POP IX
  INC DE
  LD A,$81
  CALL ApiVector03
  CALL ApiVector04
  LD BC,$0008
  LD HL,WorldVars+$0003
  LDIR
  LD (IX+$31),$64
  CALL PrintAmmo
  JP SetFireCooldown

; Step of a cannon shell: move, lifetime 100
;
; MoveObject `$BFD1`, counts +$31 down from 100, removes the shell at 0
; (RemoveObject `$B8B1`).
;
; Witness: L1 5682 (death, play2).
CannonShellStep:
  LD A,(IX+$31)
  DEC A
  JP Z,RemoveObject
  LD (IX+$31),A
  JP ApiVector00

; Fire the K-40 mortar (store type 3): projectile $80
;
; SelectAmmoPointer, A = `$80`, then LaunchProjectile `$B5A7`.
;
; Witness: L1 2 (play).
FireMortar:
  LD A,(CurrentSlot)
  CALL SelectAmmoPointer
  LD A,$80

; Spawn projectile type A at the player with the aim's elevation
;
; Input A = the template type (`$80`-`$8B`). ConsumeAmmo `$B550`, ObjectSetType
; `$BD41`, copies the player's heading and X / Y, the elevation from `$B5C5` /
; `$B5C8` (SetElevation `$CF32`). Returns M when out of rounds.
;
; Witness: L1 7 (play, play2).
LaunchProjectile:
  LD (LaunchProjectile+$000E),A
  CALL ConsumeAmmo
  RET NC
  RET M
  EX DE,HL
  PUSH DE
  POP IX
  INC DE
  LD A,$00
  CALL ApiVector03
  CALL ApiVector04
  LD BC,$0008
  LD HL,WorldVars+$0003
  LDIR
  LD A,$00
  EX AF,AF'
  LD A,$00
  CALL ApiVector08
  LD (IX+$07),A
  EX AF,AF'
  LD (IX+$31),A
  LD (IX+$2A),$00
  LD A,(IX+$03)
  OR $40
  LD (IX+$03),A
  CALL PrintAmmo
  CALL SetFireCooldown
  XOR A
  SCF
  RET

; Step of a mortar shell: ballistic flight, burst at the ground
;
; Height += vertical speed (+$31), the speed falls each pass; at height 0 the
; shell bursts (Explode `$B8AB`).
;
; Witness: L1 68 (play).
MortarShellStep:
  CALL ApiVector00
  LD D,$00
  LD A,(IX+$31)
  AND A
  JP P,l_B5F5
  DEC D
l_B5F5:
  LD E,A
  LD L,(IX+$05)
  LD H,(IX+$06)
  AND A
  ADC HL,DE
  JP M,RemoveObject
  LD (IX+$05),L
  LD (IX+$06),H
  LD E,$05
  AND A
  SBC A,E
  RET PE
  LD (IX+$31),A
  RET

  ORG $B8AB

; Explode a projectile: debris and the explosion sound
;
; Debris `$B6D1`, the sound `$D86B`, then RemoveObject.
;
; Witness: L1 8 (death, play2).
Explode:
  CALL ApiVector11
  CALL SoundExplosion

  ORG $B8B9

; Raise the mortar elevation (no recording runs it)
;
; `LD A,n` / `INC A` / `CP $40` / `RET NC` / `LD ($B8BA),A`: the elevation is
; the operand at `$B8BA`, 32 at start. Only the down key ran in the recordings.
MortarElevationUp:
  DEFB $3E,$20,$3C,$FE,$40,$D0,$32,$BA,$B8,$18,$08

; Lower the mortar elevation
;
; Decrements the elevation `$B8BA` (play: 4 runs, the K-40 aim).
;
; Witness: L1 4 (play).
MortarElevationDown:
  LD A,(MortarElevationUp+$0001)
  DEC A
  RET Z
  LD (MortarElevationUp+$0001),A

; Print the mortar range for the elevation
;
; Prints the elevation's range in the HUD (play: 5 runs).
;
; Witness: L1 5 (play).
ShowMortarRange:
  ADD A,$C0
  CALL ApiVector14
  LD (LaunchProjectile+$0021),A
  EX AF,AF'
  LD (LaunchProjectile+$001E),A
  CALL ApiVector08
  LD E,A
  EX AF,AF'
  CALL ApiVector08
  CALL MulFrac
  LD (IrViewHeight),HL
  LD A,(MortarElevationUp+$0001)
  LD H,A
  LD L,$00
  LD DE,$00B6
  CALL Divide
  LD A,H
  LD (MissionHeader+$2233),A
  LD HL,MissionHeader+$2226
  JP PrintString

; The height used by the IR view, and its setter
;
; `$B8FC`-`$B8FD` are spare, `$B8FE` `LD HL,0` (its operand `$B8FF` the IR
; camera height), `$B901` adds 8 and stores it: raise the IR view. AimLimit
; `$B909` lowers it.
IrViewHeight:
  DEFB $00,$00,$21,$00,$00,$01,$08,$00,$09,$22,$FF,$B8,$C9

; Clamp the aim within the weapon's limit
;
; `$B8FF` -= 8 unless it would go below 0 (play2: 5 runs). Lowers the camera of
; the IR view (Banshee IRSS).
;
; Witness: L1 5 (play2).
AimLimit:
  LD HL,(IrViewHeight+$0003)
  LD BC,$0008
  SBC HL,BC
  RET C
  LD (IrViewHeight+$0003),HL
  RET

  ORG $BF24

; Search the depth tree for a missile target
;
; Returns at once when `$66D4` is 0; else walks the nodes at `$6800` (the
; target search of TargetInCone `$C197`).
;
; Witness: L1 8 (play, play2).
FindMissileTarget:
  LD A,(PolyWorkSpare+$0005)
  AND A
  RET Z
  LD HL,$0000
  PUSH HL
  LD HL,PlayWork
l_BF30:
  INC L
  INC L
  LD A,(HL)
  AND A
  JP Z,l_BF3C
  PUSH HL
  LD L,A
  JP l_BF30
l_BF3C:
  INC L
  PUSH HL
  INC L
  CALL TargetInCone
  POP HL
  LD A,(HL)
  AND A
  JP Z,l_BF4C
  LD L,A
  JP l_BF30
l_BF4C:
  POP HL
  INC H
  DEC H
  RET Z
  JP l_BF3C

  ORG $C113

; A print of the weight and its text
;
; `LD HL,$C119` / `JP $6FB3` then the string at `$C119`: code the recordings do
; not run, with the operand `$C11B` (the stores weight, used by bank 6's stores
; screen).
WeightText:
  DEFB $21,$19,$C1,$C3,$FB,$6C,$47,$05
  DEFB $16,$05,$11

; Select a Phoenix (store types 1 and 5): the IR view on ($BA13)
;
; The select of store types 1 and 5 in the store-type table `$7B89`. Prints the
; name (`$FDC0`), sets the sight overlay `$C4DC` and the IR view flag `$BA13`
; (play2: 2 runs).
;
; Witness: L1 2 (play2).
SelectPhoenix:
  LD A,$FF
  LD (l_C4DB+$0001),A
  LD (SetCamera+$001D),A

; Print the selected weapon's name
;
; `LD HL,$FDC0` / `JP $6FB3`.
;
; Witness: L1 8 (play, play2).
WeaponSelectText:
  LD HL,MissionHeader+$21FB
  JP PrintString

; Select a store with no aim (types 2, 6, 7)
;
; The select of the Banshee RRSS, the Banshee IRSS and the Dragonfly in the
; store-type table `$7B89`. Prints the name, sets `$C4DC`, clears `$BA13`
; (play, play2).
;
; Witness: L1 3 (play, play2).
SelectPlain:
  LD HL,MissionHeader+$21FB
  CALL PrintString
  LD A,$FF
  LD (l_C4DB+$0001),A
  XOR A
  LD (SetCamera+$001D),A
  JP WeaponSelectText

; Fire the Phoenix RRSA: projectile $83
;
; Store type 1 in the store-type table `$7B89`; `$83` is the Phoenix RR
; resident type (step `$C4A5`, guided). SelectAmmoPointer, A = `$83`,
; LaunchProjectile `$B5A7` (play2: 2 runs).
;
; Witness: L1 2 (play2).
FirePhoenixRr:
  LD A,(CurrentSlot)
  CALL SelectAmmoPointer
  LD A,$83
  LD (l_C408+$0015),A
  LD A,$39
  JR l_C15A

; Fire the Banshee RRSS: projectile $82
;
; A = `$82`, LaunchProjectile (play: 2 runs).
;
; Witness: L1 2 (play).
FireBansheeRr:
  LD A,(CurrentSlot)
  CALL SelectAmmoPointer
  LD A,$82
  LD (l_C408+$0015),A
  LD A,$39
; This entry point is used by the routine at FirePhoenixRr.
l_C15A:
  EX AF,AF'
  LD HL,TargetInCone
  LD A,(TargetInCone+$0001)
  AND A
  JR Z,l_C16E
  LD (l_BF3C+$0004),HL
  EX AF,AF'
  LD (TargetInCone+$0001),A
  JP FindMissileTarget
l_C16E:
  LD DE,$0000
  JP LaunchMissile

; Find a present object of type C in the cone (no recording runs it)
;
; Called from `$C254` (the lock path).
;
; Known only from the code: no recording runs it (static walk).
FindTypeInCone:
  LD IY,PlayerY+$0016
  LD DE,$003C
  LD B,$17
l_C17D:
  LD A,(IY+$02)
  AND $A0
  CP $A0
  JR NZ,l_C191
  LD A,(IY+$01)
  CP C
  JR NZ,l_C191
  PUSH IY
  POP DE
  SCF
  RET
l_C191:
  ADD IY,DE
  DJNZ l_C17D
  AND A
  RET

; Look for a target within +-6 of the heading (gated: JR to RET or on)
;
; `JR d` whose d (`$C198`) is 0 (to the RET at `$C199`) or 1 (to the body
; `$C19A`); ResetSightTimer `$C506` writes 1. Recordings play and play2: 18
; runs, the body never.
;
; Witness: L1 18 (play, play2).
TargetInCone:
  JR TargetInConeBody

; The RET the gate jumps to
;
; `RET`.
TargetInConeRet:
  DEFB $C9

; The body of TargetInCone (no recording runs it)
;
; Reads a node of the depth tree, IY = its record, checks the bearing within
; +-6 of `$7612` (BearingTo through `$67C1`) and the height.
;
; Known only from the code: no recording runs it (static walk).
TargetInConeBody:
  LD E,(HL)
  INC L
  LD D,(HL)
  PUSH DE
  POP IY
  LD (l_C16E+$0001),DE
  LD IX,ObjectTable
l_C1A8:
  LD A,(IY+$02)
  AND A
  RET Z
  CALL ApiVector01
  LD C,A
  LD A,(PlayerHeading)
  AND A
  SBC A,C
  CALL ApiVector08
  CP $06
  RET NC
  LD A,(IY+$03)
  AND $50
  RET NZ
  LD A,(IY+$02)
  AND $40
  RET NZ
  XOR A
  LD (TargetInCone+$0001),A
; This entry point is used by the routine at MissileLock.
l_C1CC:
  LD A,$10
  LD (DrawSightOverlay+$0001),A
  RET
  LD E,(HL)
  INC L
  LD D,(HL)
  PUSH DE
  LD (l_C16E+$0001),DE
  POP IY
  LD IX,ObjectTable
  LD L,(IY+$05)
  LD H,(IY+$06)
  CALL TargetBearingCheck
  JP M,l_C1A8
  RET

; Check a candidate's bearing and height
;
; Called for each candidate: |bearing - heading| < 6, height against `$C276`.
;
; Witness: L1 28 (play, play2).
TargetBearingCheck:
  LD BC,(WorldVars+$000B)
  AND A
  SBC HL,BC
  JP P,l_C1FA
  CALL NegHL
l_C1FA:
  EX DE,HL
  LD L,(IY+$0D)
  LD H,(IY+$0E)
  LD C,(IX+$0D)
  LD B,(IX+$0E)
  ADD HL,BC
  EX DE,HL
  AND A
  SBC HL,DE
  RET

; Fire the Phoenix (IR): projectile $85
;
; A = `$85`, the height limit `$C276` = `$FF` (any height), MissileLock
; (play2).
;
; Witness: L1 2 (play2).
FirePhoenixIr:
  LD A,(CurrentSlot)
  CALL SelectAmmoPointer
  LD A,$85
  EX AF,AF'
  LD A,$FF
  LD HL,TurnTowardTail
  JR MissileLock

; Fire the Banshee IRSS: projectile $84
;
; Store type 6 in the store-type table `$7B89`; `$84` is the Banshee IR
; resident type (step `$C4A5`). A = `$84` (play2).
;
; Witness: L1 2 (play2).
FireBansheeIr:
  LD A,(CurrentSlot)
  CALL SelectAmmoPointer
  LD A,$84
  EX AF,AF'
  XOR A

; Lock a missile on the target found
;
; Stores the limit `$C276` and the type `$C41D`, hooks MissileSeek into the
; tree walk (`$BF40` = `$C267`), searches (FindMissileTarget `$BF24`).
;
; Witness: L1 4 (play2).
MissileLock:
  LD (MissileSeek+$000F),A
  EX AF,AF'
  LD (l_C408+$0015),A
  LD A,$00
  AND A
  JR NZ,l_C252
  PUSH IX
  LD HL,MissileSeek
  LD (l_BF3C+$0004),HL
  XOR A
  LD (MissileSeek),A
  LD (MissileSeek+$0001),A
  CALL FindMissileTarget
  LD A,(MissileSeek+$0001)
  AND A
  POP IX
  RET Z
  LD (MissileLock+$0008),A
  JP l_C1CC
l_C252:
  LD C,$8B
  CALL FindTypeInCone
  JR C,l_C25C
  LD DE,$0000
l_C25C:
  CALL LaunchMissile
  XOR A
  LD (MissileLock+$0008),A
  LD (MissileSeek+$0001),A
  RET

; A guided missile's step: turn toward the target
;
; Called by the tree walk for each node: a target that passes
; TargetBearingCheck is taken (play2: 19 runs).
;
; Witness: L1 19 (play2).
MissileSeek:
  NOP
  NOP
  LD E,(HL)
  INC L
  LD D,(HL)
  PUSH DE
  POP IX
  LD A,(IX+$02)
  AND A
  RET Z
  PUSH DE
  LD A,$00
  AND A
  JR Z,l_C28C
  LD L,(IX+$05)
  LD H,(IX+$06)
  LD IY,ObjectTable
  CALL TargetBearingCheck
  JP M,l_C28C
  POP DE
  RET
l_C28C:
  LD L,(IX+$2F)
  LD H,(IX+$30)
  LD B,$06
l_C294:
  SRA H
  RR L
  DJNZ l_C294
  LD B,H
  LD C,L
  CALL OnScreenX
  POP DE
  RET C
  LD A,(IX+$03)
  AND $20
  JR Z,l_C2B6
  LD (l_C252+$0008),DE
  LD A,$C9
  LD (MissileSeek+$0001),A
  XOR A
  LD (MissileSeek),A
  RET
l_C2B6:
  LD A,$C9
  LD (MissileSeek),A
  RET

; Launch the Dragonfly: projectile $86, the camera follows it
;
; Spawns `$86`, the camera record `$B9F4` = the Dragonfly, the fire routine
; `$A9B9` = RecallDragonfly (play: 1 run).
;
; Witness: L1 1 (play).
LaunchDragonfly:
  LD A,(CurrentSlot)
  CALL SelectAmmoPointer
  CALL ConsumeAmmo
  RET NC
  RET M
  PUSH IX
  EX DE,HL
  LD (LaunchDragonfly+$0046),DE
  PUSH DE
  POP IX
  INC DE
  LD A,$86
  CALL ApiVector03
  CALL ApiVector04
  LD BC,$0008
  LD HL,WorldVars+$0003
  LDIR
  LD A,(PlayerHeading)
  LD (IX+$22),A
  LD A,(IX+$03)
  OR $40
  LD (IX+$03),A
  LD (IX+$31),$64
  LD A,$FF
  LD (IX+$00),A
  POP IX
  LD HL,DragonflyCode
  LD (l_A9A0+$0019),HL
  LD HL,$0000
  LD (BearingTable+$0016),HL
  LD A,(ObjectTable+$0003)
  AND $FE
  LD (ObjectTable+$0003),A
  LD HL,MapLoop
  LD (NextView+$0008),HL
  LD A,$FF
  LD (ViewChangeFlag+$0001),A
  RET

; Dragonfly code no recording runs
;
; The Dragonfly's set-up bytes: `$C33E` into `$A9B9`, handler `$C391`.
DragonflyCode:
  DEFB $CD,$0F,$C3,$21,$3E,$C3,$22,$B9
  DEFB $A9,$2A,$02,$C3,$22,$F4,$B9,$E5
  DEFB $FD,$E1,$FD,$36,$18,$91,$FD,$36
  DEFB $19,$C3,$3A,$F3,$75,$E6,$FE,$32
  DEFB $F3,$75,$C9

; Recall the Dragonfly
;
; The fire key with the Dragonfly out: `$A9B9` = LaunchDragonfly again, its
; handler `$67BE`, the screen routine `$694B`, the view flag `$6A6D`,
; CameraToPlayer (play: 1 run).
;
; Witness: L1 1 (play).
RecallDragonfly:
  LD HL,LaunchDragonfly
  LD (l_A9A0+$0019),HL
  LD (IX+$18),$BE
  LD (IX+$19),$67
  LD HL,StartMission
  LD (NextView+$0008),HL
  LD A,$FF
  LD (ViewChangeFlag+$0001),A

; Point the camera back at the player
;
; `$B9F4` = `$75F0`. Also called when a mission starts (15 runs over five
; recordings).
;
; Witness: L1 15 (death, m2erbe, missions, play, play2).
CameraToPlayer:
  LD HL,ObjectTable
  LD (BearingTable+$0016),HL
  INC HL
  INC HL
  INC HL
  LD A,(HL)
  OR $01
  LD (HL),A
  RET
; This entry point is used by the routine at DragonflyStep.
l_C365:
  CALL ApiVector05
  LD (IX+$02),$00
  LD HL,(NextView+$0008)
  LD BC,StartMission
  AND A
  SBC HL,BC
  JR Z,l_C37A
  CALL RecallDragonfly
l_C37A:
  LD HL,(l_A9A0+$0019)
  LD BC,DragonflyCode
  AND A
  SBC HL,BC
  JR NZ,l_C38B
  LD HL,LaunchDragonfly
  LD (l_A9A0+$0019),HL
l_C38B:
  LD A,$08
  LD (FireCooldown),A
  RET

; The Dragonfly's flight: steered by the controls
;
; Turns by the control input, MoveObject, height from the up / down keys (play:
; 25 runs).
;
; Witness: L1 25 (play).
DragonflyStep:
  LD HL,PointerZones+$0001
  LD A,(HL)
  AND A
  JR Z,l_C39D
  LD (HL),$00
  JP RecallDragonfly
l_C39D:
  LD A,(IX+$31)
  DEC A
  JR Z,l_C365
  LD (IX+$31),A
  LD A,(StepX)
  SRA A
  ADD A,(IX+$22)
  LD (IX+$22),A
  LD L,(IX+$05)
  LD H,(IX+$06)
  LD A,(StepY)
  ADD A,A
  NEG
  LD C,A
  SRA A
  JP P,l_C3CD
  LD B,$FF
  AND A
  ADC HL,BC
  JP P,l_C3D5
  JR l_C3DB
l_C3CD:
  LD B,$00
  ADD HL,BC
  LD A,H
  CP $02
  JR NC,l_C3DB
l_C3D5:
  LD (IX+$05),L
  LD (IX+$06),H
l_C3DB:
  JP ApiVector00

; Launch a guided missile (no recording runs it)
;
; Reached from `$C171` and `$C25C` when a target was locked.
;
; Known only from the code: no recording runs it (static walk).
LaunchMissile:
  PUSH DE
  LD HL,(ConsumeAmmo+$0001)
  LD A,(HL)
  DEC A
  JP M,l_C406
  PUSH HL
  CALL FindProjectileSlot
  JR NC,l_C405
  EX DE,HL
  POP HL
  PUSH DE
  LD A,(HL)
  DEC A                   ; the Infinite Missiles POKE writes 0 here
  LD (HL),A
  LD (WeaponVars),A
  LD HL,MissionHeader+$21FB
  CALL PrintString
  LD HL,(PlayerHeight)
  LD (IrViewHeight+$0003),HL
  POP HL
  JR l_C408
l_C405:
  POP HL
l_C406:
  POP DE
  RET
l_C408:
  EX DE,HL
; This entry point is used by the routine at Entry.
  PUSH DE
  POP IX
  POP BC
  LD (IX+$32),C
  LD (IX+$33),B
  LD HL,$0020
  ADD HL,BC
  LD A,(HL)
  LD (IX+$35),A
  INC DE
  LD A,$00
  CALL ApiVector03
  CALL ApiVector04
  LD BC,$0008
  LD HL,WorldVars+$0003
  LDIR
  LD A,$00
  LD A,(PlayerHeading)
  LD (IX+$22),A
  LD A,(IX+$03)
  OR $40
  LD (IX+$03),A
  LD A,$46
  LD (IX+$31),A
  LD A,$FF
  LD (IX+$00),A
  LD A,$01
  LD (TargetInCone+$0001),A
  LD A,$10
  LD (FireCooldown),A
  JP SoundEffect687

; Missile step code no recording runs
;
; Missile step: MoveObject, turn toward the target (TurnToward `$C485`),
; lifetime +$31.
MissileCode:
  DEFB $CD,$BE,$67,$CD,$7C,$C4,$CD,$65
  DEFB $C4,$C9,$DD,$7E,$35,$FD,$BE,$20
  DEFB $20,$0F,$DD,$7E,$31,$3D,$DD,$77
  DEFB $31,$CA,$74,$C4,$FD,$7E,$02,$A7
  DEFB $C0,$CD,$1E,$B6,$DD,$36,$02,$00
  DEFB $C9,$DD,$5E,$32,$DD,$56,$33,$D5
  DEFB $FD,$E1

  ORG $C510

; Print the current slot's rounds when it is the one shown
;
; When the slot shown (`$D114`) is the current `$C53C`, falls into PrintAmmoAt.
;
; Witness: L1 86 (death, play, play2).
PrintAmmo:
  LD A,(SlotShown)
  LD C,A
  LD A,(CurrentSlot)
  CP C
  RET NZ

; Print the rounds at $FDC0
;
; Converts the rounds at `$C527` and prints at `$FDC0`.
;
; Witness: L1 87 (death, play, play2).
PrintAmmoAt:
  LD HL,MissionHeader+$21FB
  JP PrintString

; Print the slot's status
;
; Clears `$BA13` and `$C4DC` (the IR view and the sight overlay off) when a
; weapon is deselected.
;
; Witness: L1 14 (death, play, play2).
PrintSlotStatus:
  XOR A
  LD (SetCamera+$001D),A
  LD (l_C4DB+$0001),A
  RET

; The weapon variables: the rounds shown, the ammunition pointers $C534, the
; current slot $C53C
;
; `$C534` holds the four pointers `$836D`, `$8373`, `$8379`, `$837F` (+5 of
; each slot), `$C53C` the slot 0-3, `$C53D` the slot record.
WeaponVars:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00
AmmoPointers:
  DEFB $6D,$83,$73,$83,$79,$83,$7F,$83 ; the four slots' ammunition bytes
                                       ; $836D, $8373, $8379, $837F
CurrentSlot:
  DEFB $00,$00,$00        ; 0-3

; Select a weapon slot with the keys 1-4
;
; Writes `$C53C`, the slot record `$C53D`, the select routine of the store type
; (`$7B89` + 8 * type, word 4); a slot whose status `$68C9` + 6n is 0 prints
; "DAMAGED IN COMBAT" (`$C618`).
;
; Witness: L1 14 (death, play, play2).
SelectWeapon:
  PUSH AF
  CALL SoundSelect
  POP AF
  LD (PlayKeys+$000A),A
  SUB $30
  LD B,A
  DEC A
  LD (CurrentSlot),A
  LD (SlotShown),A
  LD HL,PlayLoop+$003A
  LD E,A
  ADD A,A
  ADD A,A
  ADD A,E
  LD E,A
  LD D,$00
  ADD HL,DE
  LD (CurrentSlot+$0001),HL
  LD A,B
  DEC A
  ADD A,A
  LD HL,WeaponVars+$0005
  LD E,A
  ADD HL,DE
  LD (WeaponVars+$0003),HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (MineHudText+$0004),DE
  LD A,B
  LD DE,$0006
  LD HL,$0000
l_C578:
  ADD HL,DE
  DJNZ l_C578
  LD DE,DragonflyIcons+$0018
  ADD HL,DE
  EX AF,AF'
  LD A,(HL)
  LD (l_C5AA+$0028),A
  AND A
  RET Z
  EX AF,AF'
  PUSH AF
  LD DE,$0005
  ADD HL,DE
  LD (ConsumeAmmo+$0001),HL
  LD A,(HL)
  LD (WeaponVars),A
  LD A,(WeaponVars+$0002)
  AND A
  JR Z,l_C59F
  LD HL,ScreenRowTable
  CALL InvertPanelB
l_C59F:
  CALL FillPanelRows
  POP AF
  LD B,A
  LD DE,$0006
  LD HL,$0000
l_C5AA:
  ADD HL,DE
  DJNZ l_C5AA
  LD DE,GaugeRecords+$001C
  ADD HL,DE
  LD A,(HL)
  INC A
  LD (WeaponVars+$0002),A
  LD HL,ScreenRowTable
  CALL InvertPanelB
  LD A,(CurrentSlot)
  ADD A,A
  LD C,A
  ADD A,A
  ADD A,C
  LD B,$00
  LD C,A
  LD HL,SlotGauges
  ADD HL,BC
  LD A,(HL)
  LD (RefreshWeaponPanel+$000C),HL
  AND A
  JR Z,l_C605
  LD A,$00
  ADD A,A
  ADD A,A
  ADD A,A
  LD C,A
  LD B,$00
  LD HL,HelicarrierRecord+$00AD
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (PlayKeys+$001A),DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (PlayKeys+$0015),DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (l_A9A0+$0019),DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (l_C5AA+$0056),DE
  CALL PrintSlotStatus
  CALL $0000
  JP PrintAmmo
; This entry point is used by the routine at RefreshWeaponPanel.
l_C605:
  LD HL,DamagedText
  CALL PrintString
  LD HL,NoAction
  LD (l_A9A0+$0019),HL
  LD (PlayKeys+$0015),HL
  LD (PlayKeys+$001A),HL
  RET

; "DAMAGED IN COMBAT"
;
; PrintString text: `$07` position codes and "DAMAGED", "IN", "COMBAT".
DamagedText:
  DEFB $07,$05,$03,$44,$41,$4D,$41,$47,$45,$44,$07,$0B,$05
  DEFB $49,$4E,$07,$11,$03,$43,$4F,$4D,$42,$41,$54,$5B,$FF

; Redraw the weapon panel
;
; When `$C529` is set: InvertPanelB with `$6500`, then the slot's state at
; (`$0000` patched) chooses `$C605` (damaged) or WeaponSelectText.
;
; Witness: L1 26 (death, m2erbe, missions, play, play2).
RefreshWeaponPanel:
  LD A,(WeaponVars+$0002)
  AND A
  RET Z
  LD HL,ScreenRowTable
  CALL InvertPanelB
  LD HL,$0000
  LD A,(HL)
  AND A
  JP Z,l_C605
  JP WeaponSelectText

  ORG $CAA5

; The player's collision handler: armour and subsystem damage
;
; Type 4 goes to `$CB6C`. Height >= `$30`: the top armour `$8304` -= damage;
; else the side (HitSide `$CB4C`) `$8301` + L, then a random subsystem from the
; nine pointers at `$8338`. An underflow goes to `$CB38`: `$7BF9` = `$CCBE`
; "FAILED TO MAKE PICKUP" when `$68E8` is set, else `$CCAB` "UNIT DESTROYED",
; JP `$7047`. The Infinite Damage POKEs write OR (HL) at `$CAC8`, `$CAE8`,
; `$CB18`.
;
; Witness: L1 41 (death, play2).
PlayerHit:
  LD A,(IY+$02)
  AND $40
  RET NZ
  LD A,(IY+$01)
  CP $04
  JP Z,HitObstacle
  CALL SetMessage
  LD L,(IY+$05)
  LD H,(IY+$06)
  AND A
  LD BC,$0030
  SBC HL,BC
  JR C,l_CAD1
  LD A,(PlayVars+$0003)
  SUB (IY+$14)
  LD (PlayVars+$0003),A
  JR C,ArmourDestroyed
  JR l_CB1E
l_CAD1:
  LD L,(IY+$2F)
  LD H,(IY+$30)
  LD A,(l_BA1F+$0008)
  AND A
  JR Z,l_CAE0
  CALL NegHL
l_CAE0:
  CALL HitSide
  LD H,$83
  LD A,(HL)
  AND A
  SBC A,(IY+$14)
  JR C,ArmourDestroyed
  LD (HL),A
  LD C,A
  CALL ApiVector06
  LD E,$00
l_CAF3:
  SUB $55
  JR C,l_CAFA
  INC E
  JR l_CAF3
l_CAFA:
  LD H,$00
  LD D,H
  LD BC,$8338
  LD A,L
  SUB $01
  LD L,A
  SLA L
  ADD A,A
  ADD A,A
  ADD A,L
  LD L,A
  ADD HL,BC
  SLA E
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  LD A,(HL)
  AND A
  JP M,l_CB1E
  SUB (IY+$14)
  JR NC,l_CB1D
  XOR A
l_CB1D:
  LD (HL),A
l_CB1E:
  LD A,(IY+$03)
  BIT 4,A
  RET NZ
  BIT 1,A
  JR Z,l_CB28
l_CB28:
  LD A,(IX+$07)
  AND A
  RET Z
  NEG
  LD (IX+$07),A
  CALL ApiVector00
  JP SetBounce
ArmourDestroyed:
  LD A,(GoalFlag)         ; armour underflow: the failure reason ($CCBE or
                          ; $CCAB), JP $7047 (witness: the armour recording,
                          ; POKE armour = 1 at frame 7704, frame 18423)
  AND A
  JR Z,l_CB43
  LD HL,l_CC98+$0026
  JR l_CB46
l_CB43:
  LD HL,l_CC98+$0013
l_CB46:
  LD (FailReason),HL
  JP ScreenSix

; Which side was hit (1-3) from the bearing
;
; BearingTo the hitter minus the turret heading: front, left / right, rear
; (play2: 25 runs).
;
; Witness: L1 25 (play2).
HitSide:
  LD A,H
  LD C,A
  AND A
  JP P,l_CB56
  CALL NegHL
  AND A
l_CB56:
  EX DE,HL
  LD HL,$0060
  SBC HL,DE
  JR NC,l_CB69
  LD A,C
  AND A
  JP P,l_CB66
  LD L,$03
  RET
l_CB66:
  LD L,$01
  RET
l_CB69:
  LD L,$02
  RET
; This entry point is used by the routine at PlayerHit.
HitObstacle:
  LD A,$25                ; a type 4 hitter (static)
  LD (PlayerStep+$0001),A
  CALL PushBack
  JR C,l_CB86
  LD A,(IX+$07)
  NEG
  LD (IX+$07),A
  CALL ApiVector00
  LD (IX+$07),$00
  RET
l_CB86:
  LD A,(IY+$22)
  AND A
  JR Z,l_CB98
  EX AF,AF'
  LD A,(IX+$22)
  AND A
  JP P,l_CBA7
  SBC A,$80
  JR l_CBA7
l_CB98:
  EX AF,AF'
  LD A,(IX+$22)
  AND A
  CP $40
  JR C,l_CBA7
  CP $C0
  JR NC,l_CBA7
  SUB $80
l_CBA7:
  LD C,A
  EX AF,AF'
  SBC A,C
  LD B,A
  CALL ApiVector08
  CP $02
  RET C
  SRA B
  SRA B
  LD A,(IX+$22)
  ADD A,B
  LD (IX+$22),A
  RET

; Variables of PlayerHit
;
; `$FF` in the image.
HitVars:
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

; Push the player away from a type-4 obstacle (no recording runs it)
;
; Called from `$CB71`: adds -40 or 560 to the box side +$0B/+$0C by the heading
; of IY and stops the player.
;
; Known only from the code: no recording runs it (static walk).
PushBack:
  LD A,(IY+$22)
  LD L,(IX+$0B)
  LD H,(IX+$0C)
  AND A
  JR NZ,l_CBD7
  LD DE,data_FEBB+$011D
  JR l_CBDA
l_CBD7:
  LD DE,$0230
l_CBDA:
  ADD HL,DE
  EX DE,HL
  LD HL,(PushBackWork)
  AND A
  SBC HL,DE
  JP P,l_CC03
  LD L,(IX+$0F)
  LD H,(IX+$10)
  AND A
  JR NZ,l_CBF3
  LD DE,$0230
  JR l_CBF6
l_CBF3:
  LD DE,data_FEBB+$011D
l_CBF6:
  ADD HL,DE
  EX DE,HL
  LD HL,(PushBackWork+$0002)
  AND A
  SBC HL,DE
  JP P,l_CC03
  SCF
  RET
l_CC03:
  AND A
  RET

; Work bytes of PushBack
;
; Zero in the image.
PushBackWork:
  DEFB $00,$00,$00,$00

; After a wall: halve the speed until it is 0, then PlayerStep again
;
; +7 >>= 1 (SRA); when it reaches -1 or 0 ResetPlayerHandler (play2: 23 runs).
;
; Witness: L1 23 (play2).
BounceDecay:
  LD A,(IX+$07)
  SRA A
  LD (IX+$07),A
  CP $FF
  JR Z,ResetPlayerHandler
  AND A
  JR Z,ResetPlayerHandler
  CALL ApiVector00
  JP PlayerSteering

; Set the player's handler back to PlayerStep
;
; +$18/+$19 = `$A8C7`; also called when a mission starts (19 runs).
;
; Witness: L1 19 (death, m2erbe, m2ocean, missions, play, play2).
ResetPlayerHandler:
  LD (IX+$18),$C7
  LD (IX+$19),$A8
  LD (IX+$07),$00
  RET

; Code no recording runs (heading + $80)
;
; `CALL $67C1` / `ADD A,$80` / `LD (IX+$22),A`: turn away from the hitter.
HeadingAwayCode:
  DEFB $CD,$C1,$67,$C6,$80,$DD,$77,$22

; Set the handler to BounceDecay
;
; +$18/+$19 = BounceDecay (play2: 4 runs).
;
; Witness: L1 4 (play2).
SetBounce:
  LD (IX+$18),$09
  LD (IX+$19),$CC
  RET

  ORG $CF26

; Print the elevation
;
; Prints `$FDF9`, then A = `$1E` and SetElevation.
;
; Witness: L1 1 (play2).
PrintElevation:
  LD HL,MissionHeader+$2234
  CALL PrintString
  LD A,$1E
  JR SetElevation

; The elevation $14 for a launch
;
; A = `$14`, then SetElevation.
;
; Witness: L1 1 (play2).
ElevationZero:
  LD A,$14

; The elevation's sin / cos to $B5C5 / $B5C8
;
; A + `$C0` through `$67E8` (sin / cos) to `$B5C8` / `$B5C5`: the vertical and
; horizontal speed of the next launch.
;
; Witness: L1 4 (play, play2).
SetElevation:
  ADD A,$C0
  CALL ApiVector14
  LD (LaunchProjectile+$0021),A
  EX AF,AF'
  LD (LaunchProjectile+$001E),A
  RET

; Fire store type 8: projectile $87 (damage 127)
;
; SelectAmmoPointer, A = `$87`, LaunchProjectile (play2: 1 run).
;
; Witness: L1 1 (play2).
FireClusterBomb:
  LD A,(CurrentSlot)
  CALL SelectAmmoPointer
  LD A,$87
  JP LaunchProjectile

; The bomb rises
;
; Height up by +$31 while it lasts, then the parachute handler.
;
; Witness: L1 14 (play2).
ClusterRise:
  CALL ApiVector00
  LD D,$00
  LD A,(IX+$31)
  AND A
  JP M,l_CF6F
  LD E,A
  LD L,(IX+$05)
  LD H,(IX+$06)
  AND A
  ADC HL,DE
  LD (IX+$05),L
  LD (IX+$06),H
  LD E,$05
  AND A
  SBC A,E
  RET PE
  LD (IX+$31),A
  RET
l_CF6F:
  LD (IX+$18),$80
  LD (IX+$19),$CF
  LD (IX+$1C),$5B
  LD (IX+$1D),$7F
  RET

; The bomb comes down on its parachute
;
; Height down slowly to the burst height.
;
; Witness: L1 19 (play2).
ClusterParachute:
  LD L,(IX+$05)
  LD H,(IX+$06)
  LD BC,$0008
  AND A
  SBC HL,BC
  LD (IX+$05),L
  LD (IX+$06),H
  LD BC,$012C
  AND A
  SBC HL,BC
  RET NC
  LD (IX+$18),$AE
  LD (IX+$19),$CF
  LD (IX+$1C),$D0
  LD (IX+$1D),$D5
  LD (IX+$31),$08
  RET

; The blast grows, then Explode
;
; The radius +$16/+$17 grows each pass; at the end Explode `$B8AB`.
;
; Witness: L1 15 (play2).
ClusterBlast:
  LD BC,$00C8
  LD L,(IX+$0B)
  LD H,(IX+$0C)
  ADD HL,BC
  LD (IX+$0B),L
  LD (IX+$0C),H
  LD L,(IX+$0F)
  LD H,(IX+$10)
  ADD HL,BC
  LD (IX+$0F),L
  LD (IX+$10),H
  LD A,(IX+$31)
  ADD A,$08
  LD (IX+$31),A
  LD L,(IX+$05)
  LD H,(IX+$06)
  LD BC,$0014
  AND A
  SBC HL,BC
  LD (IX+$05),L
  LD (IX+$06),H
  JP M,Explode
  RET

; Set the Sleeper mine's timer 0-$78
;
; `LD A,n` / `INC A` / `CP $78`: the timer `$CFF5` 0-`$78`, wraps (play2: 4
; runs).
;
; Witness: L1 4 (play2).
SetMineTimer:
  LD A,(MineTimerCode+$0001)
  DEC A
  JP P,StoreMineTimer
  LD A,$78
  JR StoreMineTimer

; The mine timer up (not run)
;
; `LD A,n` (n = `$CFF5`, the mine timer), `INC A`, `CP $78`, `JR C`, `XOR A`:
; the up key's copy of SetMineTimer.
MineTimerCode:
  DEFB $3E,$00,$3C,$FE,$78,$38,$01,$AF

; Store the timer and print it
;
; `$CFF5` = A, prints `$FDF9` (play2: 4 runs).
;
; Witness: L1 4 (play2).
StoreMineTimer:
  LD (MineTimerCode+$0001),A
  LD HL,MissionHeader+$2234
  JP PrintString

; Drop a Sleeper mine behind: projectile $88
;
; SelectAmmoPointer, A = `$88`, LaunchProjectile; the mine is placed behind the
; tank (heading + `$80`) (play2: 2 runs).
;
; Witness: L1 2 (play2).
DropMine:
  LD A,(CurrentSlot)
  CALL SelectAmmoPointer
  LD A,$88
  CALL LaunchProjectile
  RET M
  RET NC
  LD A,(IX+$07)
  SRL A
  LD (IX+$07),A
  LD A,(IX+$31)
  SRL A
  LD (IX+$31),A
  LD A,(PlayerHeading)
  ADD A,$80
  LD (IX+$22),A
  LD HL,(CurrentSlot+$0001)
  LD (IX+$34),L
  LD (IX+$35),H
  PUSH IX
  POP HL
  LD BC,$0031
  ADD HL,BC
  EX DE,HL
  LD HL,(WeaponVars+$0003)
  LD (HL),E
  INC HL
  LD (HL),D
  LD (MineHudText+$0004),DE
  JP PrintAmmo

; The mine falls to the ground
;
; MoveObject, height -= +$31; at the ground MineArm.
;
; Witness: L1 40 (play2).
MineFall:
  CALL ApiVector00
  LD D,$00
  LD A,(IX+$31)
  AND A
  JP P,l_D055
  DEC D
l_D055:
  LD E,A
  LD L,(IX+$05)
  LD H,(IX+$06)
  AND A
  ADC HL,DE
  LD (IX+$05),L
  LD (IX+$06),H
  JP M,l_D071
  LD E,$05
  AND A
  SBC A,E
  RET PE
  LD (IX+$31),A
  RET
l_D071:
  LD (IX+$05),$20
  LD (IX+$06),$00
  LD L,(IX+$34)
  LD H,(IX+$35)
  LD (HL),$93
  INC HL
  LD (HL),$D0
  LD (IX+$18),$B2
  LD (IX+$19),$D0

; The timer to +$31
;
; +$31 = `$CFF5` (play2: 2 runs).
;
; Witness: L1 2 (play2).
MineArm:
  LD A,(MineTimerCode+$0001)
  LD (IX+$31),A
  RET

; Print the mine's timer
;
; Pops the return address into `$D0A9`; when the slot record `$C53D` is this
; weapon's, prints `$D0AB`.
;
; Witness: L1 23 (play2).
MineHud:
  POP DE
  LD (l_D0A8+$0001),DE
  LD HL,(CurrentSlot+$0001)
  DEC DE
  DEC DE
  AND A
  SBC HL,DE
  JR NZ,l_D0A8
  LD HL,MineHudText
  CALL PrintString
l_D0A8:
  JP $0000

; The mine HUD's text
;
; PrintString codes for the mine's HUD.
MineHudText:
  DEFB $07,$10,$07,$08,$00,$00,$FF

; The mine counts down and explodes
;
; +$31 counts down; at 0 the mine explodes (the slot's text reset `$B0`).
;
; Witness: L1 37 (play2).
MineCountdown:
  LD A,(IX+$31)
  AND A
  JR Z,l_D0BD
  DEC A
  LD (IX+$31),A
  RET
l_D0BD:
  LD L,(IX+$34)
  LD H,(IX+$35)
  LD (HL),$B0
  INC HL
  LD (HL),$6B
  LD (IX+$18),$EA
MineHandlerCode:
  LD (IX+$19),$D0         ; weapon code no recording runs: handler, box 8,
                          ; debris
  LD A,$08
  LD (IX+$0C),A
  LD (IX+$10),A
  LD (IX+$17),A
  LD (IX+$31),A
  CALL ApiVector11
  LD A,(IX+$02)
  AND $DF
  LD (IX+$02),A
  RET

; data_D0EA
data_D0EA:
  DEFB $DD,$7E,$31,$3D,$DD,$77,$31,$C0
  DEFB $C3,$AB,$B8,$2A,$3D,$C5,$11,$15
  DEFB $D1,$73,$23,$72,$21,$D7,$FD,$C3
  DEFB $B3,$6F

; Print the aim of store type 10
;
; Prints `$FDE1`, the slot record (`$C53D`) = `$6BB0` (a RET: type 10 has no
; fire routine) (play2: 3 runs).
;
; Witness: L1 3 (play2).
PrintAimType10:
  LD HL,MissionHeader+$221C
  CALL PrintString
  LD HL,(CurrentSlot+$0001)
  LD DE,NoAction
  LD (HL),E
  INC HL
  LD (HL),D
  RET

; The slot whose rounds are shown ($D114), then weapon code no recording runs
;
; PrintAmmo `$C510` compares `$D114` with the current slot `$C53C`; the code
; after it stores it and calls SelectAmmoPointer `$D3C6`.
SlotShown:
  DEFB $00,$F5,$CD,$1C,$D1,$C3,$DF,$D3
  DEFB $32,$14,$D1,$CD,$C6,$D3,$CD,$A0
  DEFB $D1,$3A,$1B,$D2,$A7,$F8,$2A,$51
  DEFB $B5,$7E,$3D,$F8,$77,$32,$27,$C5
  DEFB $CD,$10,$C5,$CD,$CF,$D1,$CD,$F5
  DEFB $D1,$21,$F0,$75,$47,$11,$3C,$00
  DEFB $19,$10,$FD,$E5,$E5,$DD,$E1,$CD
  DEFB $DF,$67,$DD,$36,$02,$00,$DD,$E1
  DEFB $DD,$6E,$2B,$DD,$66,$2C,$22,$02
  DEFB $FD,$DD,$6E,$2D,$DD,$66,$2E,$22
  DEFB $02,$FE,$DD,$6E,$2F,$DD,$66,$30
  DEFB $22,$02,$FF,$21,$D4,$FE,$22,$00
  DEFB $FD,$21,$2C,$01,$22,$04,$FD,$21
  DEFB $64,$00,$22,$00,$FE,$22,$04,$FE
  DEFB $21,$00,$00,$22,$00,$FF,$22,$04
  DEFB $FF,$22,$8E,$9A,$22,$B3,$9A,$22
  DEFB $6C,$9A,$DD,$21,$BB,$FE,$CD,$0F
  DEFB $99,$C3,$39,$D8

; Code no recording runs: LD HL,$762E / LD DE,60 / LD BC,$39, a pass over the
; records
RecordScanCode:
  DEFB $21,$2E,$76,$11,$3C,$00,$01,$39
  DEFB $00,$D9,$21,$1B,$D2,$06,$17,$D9
  DEFB $7E,$E6,$80,$28,$14,$23,$7E,$E6
  DEFB $50,$FE,$10,$2B,$20,$0B,$09,$7E
  DEFB $23,$D9,$77,$23,$10,$E9,$36,$FF
  DEFB $C9,$19,$D9,$10,$E2,$18,$F7

; Code no recording runs (the scan's second part)
RecordScanCodeB:
  DEFB $01,$8C,$C7,$D9,$21,$1B,$D2,$11
  DEFB $33,$D2,$7E,$23,$FE,$FF,$C8,$D9
  DEFB $87,$6F,$26,$00,$09,$5E,$23,$56
  DEFB $EB,$4E,$3A,$BD,$C7,$91,$CD,$D6
  DEFB $67,$D9,$12,$13,$18,$E4

; Code no recording runs: a sort of the list at $D21B, then its work area
RecordSortCode:
  DEFB $21,$1B,$D2,$D9,$21,$33,$D2,$11
  DEFB $00,$00,$4B,$D9,$7E,$23,$D9,$A7
  DEFB $FA,$12,$D2,$7E,$23,$BB,$30,$02
  DEFB $5F,$51,$0C,$18,$EE,$21,$1B,$D2
  DEFB $06,$00,$4A,$09,$7E,$C9,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00

; The select routine of store type 11 (none)
;
; `RET`: the select routine of store type 11.
;
; Witness: L1 1 (play2).
RetType11:
  RET

; Fire store type 11: projectile $89 behind
;
; SelectAmmoPointer, ConsumeAmmo, spawns `$89` behind (play2: 1 run).
;
; Witness: L1 1 (play2).
FireDecoy:
  LD A,(CurrentSlot)
  CALL SelectAmmoPointer
  CALL ConsumeAmmo
  RET NC
  RET M
  EX DE,HL
  PUSH DE
  POP IX
  INC DE
  LD A,$89
  CALL ApiVector03
  CALL ApiVector04
  LD BC,$0006
  LD HL,WorldVars+$0005
  INC DE
  INC DE
  LDIR
  LD A,(PlayerHeading)
  ADD A,$80
  LD (IX+$22),A
  LD (IX+$00),$FF
  LD (IX+$31),$08
  LD (IX+$32),$08
  LD (IX+$33),$0A
  CALL PrintAmmoAt
  JP SetFireCooldown

; The decoy's first leg
;
; MoveObject; +$31 counts the leg, +$33 the legs left; at 0 Explode.
;
; Witness: L1 13 (play2).
DecoyStart:
  CALL ApiVector00
  LD A,(IX+$31)
  DEC A
  LD (IX+$31),A
  RET P
  LD A,(IX+$33)
  DEC A
  LD (IX+$33),A
  JP M,Explode
  LD (IX+$31),$10
  LD (IX+$18),$AE
  LD (IX+$19),$D2
  RET

; The decoy's zig-zag
;
; MoveObject; the heading += +$32 each pass (the zig-zag), legs as DecoyStart.
;
; Witness: L1 26 (play2).
DecoyZigZag:
  CALL ApiVector00
  LD C,(IX+$22)
  LD A,(IX+$32)
  ADD A,C
  LD (IX+$22),A
  LD A,(IX+$31)
  DEC A
  LD (IX+$31),A
  RET P
  LD A,(IX+$33)
  CP $0A
  JR NZ,l_D2CE
  LD A,$07
  JR l_D2D0
l_D2CE:
  LD A,$0F
l_D2D0:
  LD (IX+$31),A
  LD (IX+$18),$8C
  LD (IX+$19),$D2
  LD A,(IX+$32)
  NEG
  LD (IX+$32),A
  RET

; Code no recording runs: the slot record set to $D3D6, the HUD text $FDD7
SlotSetupCode:
  DEFB $2A,$3D,$C5,$36,$D6,$23,$36,$D3
  DEFB $3E,$10,$32,$EB,$D3,$21,$D7,$FD
  DEFB $C3,$B3,$6F,$2A,$3D,$C5,$11,$24
  DEFB $D3,$73,$23,$72,$3E,$10,$32,$35
  DEFB $D3,$21,$D7,$FD,$C3,$B3,$6F

; Mark a slot without a fire routine
;
; The slot record = `$6BB0`, prints `$FDCD`.
;
; Witness: L1 7 (play, play2).
PrintSlotName:
  LD HL,(CurrentSlot+$0001)
  LD (HL),$B0
  INC HL
  LD (HL),$6B
  LD HL,MissionHeader+$2208
  JP PrintString

; Fire the Phantasm: projectile $8A
;
; A = the slot, JP LaunchPhantasm (play: 1 run).
;
; Witness: L1 1 (play).
FirePhantasm:
  LD A,(CurrentSlot)
  JP LaunchPhantasm

; Fire store type 13: projectile $8B
;
; A = the slot, JR LaunchCluster13 (play2: 1 run).
;
; Witness: L1 1 (play2).
FireCluster13:
  LD A,(CurrentSlot)
  JR LaunchCluster13

; Type 13 code no recording runs (the slot $D114 saved around $D330)
Cluster13Code:
  DEFB $08,$3A,$14,$D1,$F5,$08,$CD,$30
  DEFB $D3,$C3,$DF,$D3,$32,$14,$D1,$08
  DEFB $3E,$00,$3D,$32,$35,$D3,$F0,$3E
  DEFB $10,$32,$35,$D3,$08

; Launch the type 13 cluster
;
; SelectAmmoPointer, the elevation `$1E` (SetElevation), A = `$8B`,
; LaunchProjectile.
;
; Witness: L1 1 (play2).
LaunchCluster13:
  CALL SelectAmmoPointer
  LD A,$1E
  CALL SetElevation
  LD A,$8B
  JP LaunchProjectile

; Print a slot's name
;
; When the slot record is not `$D324`, prints `$FDCD` (play2: 1 run).
;
; Witness: L1 1 (play2).
PrintSlotAmmo:
  LD HL,(CurrentSlot+$0001)
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  LD BC,Cluster13Code
  AND A
  SBC HL,BC
  JR Z,l_D363
  LD HL,MissionHeader+$2208
  JP PrintString
l_D363:
  LD HL,MissionHeader+$2212
  JP PrintString

; The type 13 cluster's flight
;
; MoveObject; the height follows +$31 (rising, then falling).
;
; Witness: L1 19 (play2).
Cluster13Step:
  CALL ApiVector00
  LD D,$00
  LD A,(IX+$31)
  AND A
  JP M,l_D38E
  LD E,A
  LD L,(IX+$05)
  LD H,(IX+$06)
  AND A
  ADC HL,DE
  LD (IX+$05),L
  LD (IX+$06),H
  LD E,$05
  AND A
  SBC A,E
  RET PE
  LD (IX+$31),A
  RET
l_D38E:
  LD (IX+$18),$AD
  LD (IX+$19),$D3
  LD (IX+$1C),$5B
  LD (IX+$1D),$7F
  CALL ApiVector06
  AND $0F
  LD (IX+$07),A
  CALL ApiVector06
  LD (IX+$22),A
  RET

; A submunition falls
;
; Height -= 8 each pass; below 0 RemoveObject (the submunitions).
;
; Witness: L1 47 (play2).
Cluster13Burst:
  CALL ApiVector00
  LD L,(IX+$05)
  LD H,(IX+$06)
  LD BC,$0008
  AND A
  SBC HL,BC
  LD (IX+$05),L
  LD (IX+$06),H
  RET P
  JP RemoveObject

; The current slot's ammunition pointer to $B551
;
; A = the slot; `$C534` + 2A to `$B551` (78 runs).
;
; Witness: L1 78 (death, play, play2).
SelectAmmoPointer:
  ADD A,A
  LD HL,AmmoPointers
  LD B,$00
  LD C,A
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (ConsumeAmmo+$0001),DE
  RET

; Phantasm code no recording runs (the slot $D114 saved around $D3E6)
PhantasmCode:
  DEFB $08,$3A,$14,$D1,$F5,$08,$CD,$E6
  DEFB $D3,$F1,$32,$14,$D1,$C3,$C6,$D3
  DEFB $32,$14,$D1,$08,$3E,$00,$3D,$32
  DEFB $EB,$D3,$F0,$3E,$10,$32,$EB,$D3
  DEFB $08

; Launch the Phantasm
;
; SelectAmmoPointer, SetElevation `$1E`, A = `$8A`, LaunchProjectile.
;
; Witness: L1 1 (play).
LaunchPhantasm:
  CALL SelectAmmoPointer
  LD A,$1E
  CALL SetElevation
  LD A,$8A
  CALL LaunchProjectile
  RET

; The Phantasm's climb
;
; MoveObject; the height by +$31 until it turns negative, then PhantasmSpin.
;
; Witness: L1 19 (play).
PhantasmStep:
  CALL ApiVector00
  LD D,$00
  LD A,(IX+$31)
  AND A
  JP M,l_D42A
  LD E,A
  LD L,(IX+$05)
  LD H,(IX+$06)
  AND A
  ADC HL,DE
  LD (IX+$05),L
  LD (IX+$06),H
  LD E,$05
  AND A
  SBC A,E
  RET PE
  LD (IX+$31),A
  RET
l_D42A:
  LD (IX+$18),$3B
  LD (IX+$19),$D4
  LD (IX+$1C),$34
  LD (IX+$1D),$D9
  RET

; The Phantasm's spinning descent
;
; The heading += 2, height -= 4 each pass: a spinning descent (play: 104 runs).
;
; Witness: L1 104 (play).
PhantasmSpin:
  LD A,(IX+$22)
  ADD A,$02
  LD (IX+$22),A
  LD L,(IX+$05)
  LD H,(IX+$06)
  AND A
  LD BC,$0004
  SBC HL,BC
  LD (IX+$05),L
  LD (IX+$06),H
  RET P
  CALL ApiVector05
  LD (IX+$02),$00
  RET

; Select store type 10
;
; Prints `$FDE1` / `$FDD7` with the type 10 table `$D115` (play2: 1 run).
;
; Witness: L1 1 (play2).
SelectType10:
  LD DE,MissionHeader+$221C
  LD HL,MissionHeader+$2212
  EXX
  LD BC,$D115
  JR l_D474

; Print a slot's aim
;
; Prints `$FDCD` / `$FDD7` with `$D3D6` (play: 1 run).
;
; Witness: L1 1 (play).
PrintType10:
  LD DE,MissionHeader+$2208
  LD HL,MissionHeader+$2212
  EXX
  LD BC,PhantasmCode
; This entry point is used by the routine at SelectType10.
l_D474:
  LD HL,(CurrentSlot+$0001)
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  AND A
  SBC HL,BC
  EXX
  JR Z,l_D482
  EX DE,HL
l_D482:
  JP PrintString

; Code no recording runs: copy 24 rows to $FD00 through $D49B
HudCopyCode:
  DEFB $21,$00,$FD,$06,$18,$11,$FB,$6C
  DEFB $CD,$9B,$D4,$CD,$9B,$D4,$CD,$9B
  DEFB $D4,$26,$FD,$10,$F3,$C9,$1A,$13
  DEFB $77,$2C,$36,$00,$2C,$24,$C9

; Copy HUD glyphs to $FD00
;
; From the control-code table `$6F8F` into `$FD00`, 8 bytes and a zero per
; glyph.
;
; Witness: L1 47 (play).
CopyHudGlyphs:
  LD HL,ControlCodes
  LD DE,MissionHeader+$213B
  XOR A
  CALL CopyHudGlyphsB

; Copy one HUD glyph
;
; The 8-byte copy loop of CopyHudGlyphs.
;
; Witness: L1 94 (play).
CopyHudGlyphsB:
  LD B,$08
l_D4B0:
  LDI
  LD (DE),A
  INC E
  DJNZ l_D4B0
  INC D
  RET

; The map edge: AWOL warning, then desertion
;
; A NOP / RET gate byte at `$D4B8`. |`$BC12`| against (`$DBD0`) and |`$BC1D`|
; against (`$DBD1`): inside, the state `$7578` = 0; outside, "GOING AWOL"
; (`$D51F`); beyond the extent + 4, `$7BF9` = `$CCD8` "PLAYER DESERTION" and
; `$7047`.
;
; Witness: L1 3096 (death, m2erbe, missions, play, play2).
BoundaryCheck:
  NOP
  LD A,(l_BBFB+$0017)
  CALL ApiVector08
  LD C,A
  LD A,(MissionHeader+$000B)
  CALL ApiVector08
  CP C
  JR NC,l_D4F0
  ADD A,$04
  CP C
  JR NC,l_D4DD
; This entry point is used by the routine at SetAwolState.
l_D4CE:
  LD A,$02
  CALL SetAwolState
  RET Z
  LD HL,l_CCD8
  LD (FailReason),HL
  JP ScreenSix
; This entry point is used by the routine at SetAwolState.
l_D4DD:
  LD A,$01
  CALL SetAwolState
  RET Z
  LD HL,AwolWarningText+$0001
  JP PrintString

; Set the AWOL state AwolState $7578 (0 inside, 1 GOING AWOL, 2 desertion)
;
; `$7578` = A unless already equal.
;
; Witness: L1 3053 (death, m2erbe, missions, play, play2).
SetAwolState:
  LD HL,AwolState
  CP (HL)
  RET Z
  LD (HL),A
  RET
; This entry point is used by the routine at BoundaryCheck.
l_D4F0:
  LD A,(l_BBFB+$0022)
  CALL ApiVector08
  LD C,A
  LD A,(MissionHeader+$000C)
  CALL ApiVector08
  CP C
  JR NC,l_D507
  ADD A,$04
  CP C
  JR NC,l_D4DD
  JR l_D4CE
l_D507:
  XOR A
  CALL SetAwolState
  RET Z
  LD HL,AwolBlankText
  JP PrintString

; The blank that clears the AWOL warning, and the head of the warning
;
; PrintString text: `$07` `$8D` `$10`, ten blanks, `$FF` (the warning cleared);
; `$D51F` starts "GOING AWOL" (`$07` `$8D` `$10` then the text at `$D521`).
AwolBlankText:
  DEFB $07,$8D,$10,$3A,$3A,$3A,$3A,$3A
  DEFB $3A,$3A,$3A,$3A,$3A
AwolWarningText:
  DEFB $FF,$07,$8D,$10,$47,$4F,$49,$4E ; the start of "GOING AWOL"; its text
  DEFB $47,$3A,$41,$57,$4F,$4C,$FF     ; from $D521 on is taken as code by the
                                       ; walk (a bank 6 CALL target $D521 from
                                       ; $6B35)
