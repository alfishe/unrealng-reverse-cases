; --------------------------------------------------------------------------------------------------------------------
; enemies.asm: The resident enemy support: the hit test, kills, debris, the score of a kill
;
; The enemies' behaviour is code in the mission block ($E381 on for mission 1, through the vectors $67BE-$67FD); what
; stays resident is the hit test and the kill: HitTest $B660, the debris, the score of the kill to $68E2-$68E5.
; --------------------------------------------------------------------------------------------------------------------

  ORG $B611

; A RET used as a null handler
;
; The collision handler of objects that ignore collisions; vector `$67EB`
; points here.
NullHandler:
  DEFB $C9

; The hit handler of the trees (types 0, 1) and some scenery: any collider
; kills it
;
; HitPoints `$B6B1` with no weapon test, so any collider, the tank included
; (damage 0 against a tree's 0 hit points), knocks it down; on a kill
; unregisters the collision (`$67CD`), makes debris (`$67DF`) and joins `$B677`
; (+2 = 0, then AddKillScore), bypassing KillMissionObject, so the list record
; is not marked destroyed. Users: types 0 and 1 in all ten missions, mission 5
; types 23-25, mission 6 types 27-29, mission 10 types 23-25, 30, 31, and the
; aircraft missiles at the end of their life (`$E632`) (docs/07-objects.md 7.5,
; 7.14).
;
; Witness: L1 2 (armour, death).
KillTree:
  CALL HitPoints
  RET NC
  CALL ApiVector05
  CALL ApiVector11
  JR l_B677

; A collision handler no recording runs: hit, then switch a segment off
;
; HitTest through `$67DC`; on a kill, when the header's first switch object
; `$DBDD` is not 0: c = the list index (+0) - (`$DBDD`), two segment numbers
; from the table at ($DBDF) + c, each minus the first switchable segment
; ($DBDE), and the two switch flags at `$7BFD` + n cleared, so the bridge or
; post it guards vanishes from the map. Users: mission 5 type 29, mission 8
; types 8 and 9 (the templates' hit handler word).
KillSwitchObject:
  CALL ApiVector10
  RET NC
  LD HL,MissionHeader+$0018
  LD A,(HL)
  AND A
  RET Z
  LD A,(IX+$00)
  SUB (HL)
  LD B,$00
  LD C,A
  LD HL,(MissionHeader+$001A)
  ADD HL,BC
  LD A,(HL)
  INC HL
  EX AF,AF'
  LD A,(HL)
  LD HL,MissionHeader+$0019
  SUB (HL)
  EX AF,AF'
  SUB (HL)
  LD BC,$7BFD
  LD H,$00
  LD L,A
  ADD HL,BC
  LD (HL),$00
  EX AF,AF'
  LD H,$00
  LD L,A
  ADD HL,BC
  LD (HL),$00
  RET

; The bridge's hit handler (mission 2 type 3): hit, then TANK DESTROYED ON
; BRIDGE if the tank touches a type 4 object
;
; HitTest `$B660`; no kill returns. On a kill, when PlayerStep's JR operand
; `$A8C8` is not 0 (HitObstacle `$CB6C` sets it to `$25` when the tank touches
; a type 4 object in the pass; PlayLoop clears it at `$6A37`), HL = `$CD01`
; ("TANK DESTROYED ON BRIDGE") and `JP $CB46`, the failure path of PlayerHit
; (docs/10-gameplay-logic.md 10.10).
BridgeHit:
  LD A,(IX+$02)
  CALL HitTest
  RET NC
  LD A,(PlayerStep+$0001)
  AND A
  RET Z
  LD HL,l_CCEB+$0016
  JP l_CB46

; Damage IX by IY's damage; on a kill score and remove (vector $67DC)
;
; Input IX = the hit object, IY = the hitter. HitPoints `$B6B1` (+$13 -= the
; hitter's +$14); no kill returns NC. On a kill: UnregisterCollision `$CA3B`,
; Debris `$B6D1`; an object from the mission list (+0 != `$FF`) goes to
; KillMissionObject `$B67D`, the others are freed at `$B677`. Then AddKillScore
; `$B692`.
;
; Witness: L1 1132 (armour, death, m1complete, m4complete, missions, play2).
HitTest:
  LD A,(IY+$03)
  AND $40
  RET Z
  CALL HitPoints
  RET NC
  CALL ApiVector05
  CALL ApiVector11
  LD A,(IX+$00)
  AND A
  JP P,KillMissionObject
; This entry point is used by the routine at KillTree.
l_B677:
  LD (IX+$02),$00
  JR AddKillScore

; A killed mission object: mark it in the list, leave the wreck
;
; MarkDestroyed `$B6BD`, sets the wreck bit 6 of +2 (the wreck model +8/+9 is
; drawn), clears the step handler bit.
;
; Witness: L1 9 (death, m1complete, m4complete).
KillMissionObject:
  CALL ApiVector13
  LD A,(IX+$02)
  AND $FB
  OR $40
  LD (IX+$02),A
  LD A,(IX+$03)
  AND $FA
  LD (IX+$03),A

; Add the object's score (+$1E/+$1F) to the 32-bit score $68E2
;
; Adds the word to `$68E2`-`$68E5` and calls the kill sound `$D873`. Death: the
; score goes 0, `$FA`, `$1F4` (two kills of a 250-point type).
;
; Witness: L1 12 (armour, death, m1complete, m4complete).
AddKillScore:
  CALL SoundKill
  LD L,(IX+$1E)
  LD H,(IX+$1F)
  LD BC,(MissionScore)
  ADD HL,BC
  LD (MissionScore),HL
  LD BC,(MissionScore+$0002)
  LD HL,$0000
  ADC HL,BC
  LD (MissionScore+$0002),HL
  SCF
  RET

; Subtract the hitter's damage from the hit points; carry = killed
;
; +$13 of IX -= +$14 of IY.
;
; Witness: L1 23 (armour, death, m1complete, m4complete).
HitPoints:
  LD A,(IX+$13)
  SBC A,(IY+$14)
  LD (IX+$13),A
  RET NZ
  SCF
  RET

; Mark a mission object destroyed in the list (vector $67E5)
;
; Record ($DBDA) + 8 * (+0): sets bit 1 (destroyed), clears bit 7 (alive), so
; it is never spawned again. The goal hooks read this bit.
;
; Witness: L1 9 (death, m1complete, m4complete).
MarkDestroyed:
  LD DE,(MissionHeader+$0015)
  LD H,$00
  LD L,(IX+$00)
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  LD A,(HL)
  AND $7F
  OR $02
  LD (HL),A
  RET

; Throw 8 debris particles from the object (vector $67DF)
;
; Fills the bank 3 particle list at `$CFEC` (8 records of 20 bytes): the
; object's position, random velocities (DebrisVelocity `$B74B` / `$B75C`).
;
; Witness: L1 36 (armour, death, m1complete, m4complete, play2).
Debris:
  LD A,(IX+$02)
  AND $20
  RET Z
  CALL SaveBank
  CALL PageBank3
  LD B,(IX+$0A)
l_B6E0:
  EXX
  LD HL,SetMineTimer+$0003
  LD DE,$0014
  LD B,$08
l_B6E9:
  LD A,(HL)
  AND A
  JR Z,l_B6F2
  ADD HL,DE
  DJNZ l_B6E9
  JR l_B748
l_B6F2:
  PUSH HL
  POP IY
  LD C,(IX+$23)
  LD B,(IX+$24)
  LD A,(IX+$25)
  LD (IY+$01),C
  LD (IY+$02),B
  LD (IY+$03),A
  LD C,(IX+$26)
  LD B,(IX+$27)
  LD A,(IX+$28)
  LD (IY+$04),C
  LD (IY+$05),B
  LD (IY+$06),A
  LD C,(IX+$05)
  LD B,(IX+$06)
  LD (IY+$07),C
  LD (IY+$08),B
  LD (IY+$00),$FF
  PUSH IY
  POP DE
  LD HL,$000F
  ADD HL,DE
  CALL DebrisVelocityB
  CALL DebrisVelocityB
  CALL ApiVector06
  AND $1F
  ADD A,$20
  LD (HL),A
  INC HL
  CALL DebrisVelocity
  CALL DebrisVelocity
  EXX
  DJNZ l_B6E0
l_B748:
  JP RestoreBank

; A random velocity component for a particle
;
; Random through `$67D0`.
;
; Witness: L1 196 (armour, death, m1complete, m4complete, play2).
DebrisVelocity:
  CALL ApiVector06
  SRA A
  SRA A
  OR $07
  JP P,l_B759
  AND $F8
l_B759:
  LD (HL),A
  INC HL
  RET

; The second component (shares the code)
;
; The entry DebrisVelocity's second call uses for the other axis.
;
; Witness: L1 196 (armour, death, m1complete, m4complete, play2).
DebrisVelocityB:
  CALL ApiVector06
  SRA A
  SRA A
  LD (HL),A
  INC HL
  RET
