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

; The collision handler of type $0E (gun emplacement): hit, kill, debris
;
; HitPoints `$B6B1`; on a kill unregisters the collision (`$67CD`), makes
; debris (`$67DF`) and joins the common kill path `$B677`. Witness: one kill in
; death.
;
; Witness: L1 1 (death).
KillGunEmplacement:
  CALL HitPoints
  RET NC
  CALL ApiVector05
  CALL ApiVector11
  JR l_B677

; A collision handler no recording runs: hit, then switch a segment off
;
; Code: HitTest through `$67DC`; on a kill reads the segment pointer at ($DBDF)
; and the first switchable index ($DBDE) and clears a switch flag at `$7BFD`,
; so the bridge or gate it guards vanishes from the map. Reached only through a
; template's handler word.
KillSwitchObject:
  DEFB $CD,$DC,$67,$D0,$21,$DD,$DB,$7E
  DEFB $A7,$C8,$DD,$7E,$00,$96,$06,$00
  DEFB $4F,$2A,$DF,$DB,$09,$7E,$23,$08
  DEFB $7E,$21,$DE,$DB,$96,$08,$96,$01
  DEFB $FD,$7B,$26,$00,$6F,$09,$36,$00
  DEFB $08,$26,$00,$6F,$09,$36,$00,$C9
  DEFB $DD,$7E,$02,$CD,$60,$B6,$D0,$3A
  DEFB $C8,$A8,$A7,$C8,$21,$01,$CD,$C3
  DEFB $46,$CB

; Damage IX by IY's damage; on a kill score and remove (vector $67DC)
;
; Input IX = the hit object, IY = the hitter. HitPoints `$B6B1` (+$13 -= the
; hitter's +$14); no kill returns NC. On a kill: UnregisterCollision `$CA3B`,
; Debris `$B6D1`; an object from the mission list (+0 != `$FF`) goes to
; KillMissionObject `$B67D`, the others are freed at `$B677`. Then AddKillScore
; `$B692`.
;
; Witness: L1 153 (death, missions, play2).
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
; This entry point is used by the routine at KillGunEmplacement.
l_B677:
  LD (IX+$02),$00
  JR AddKillScore

; A killed mission object: mark it in the list, leave the wreck
;
; MarkDestroyed `$B6BD`, sets the wreck bit 6 of +2 (the wreck model +8/+9 is
; drawn), clears the step handler bit.
;
; Witness: L1 4 (death).
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
; Witness: L1 5 (death).
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
; Witness: L1 7 (death).
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
; Witness: L1 4 (death).
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
; Witness: L1 13 (death, play2).
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
; Witness: L1 64 (death, play2).
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
; Witness: L1 64 (death, play2).
DebrisVelocityB:
  CALL ApiVector06
  SRA A
  SRA A
  LD (HL),A
  INC HL
  RET
