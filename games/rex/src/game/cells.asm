; --------------------------------------------------------------------------------------------------------------------
; cells.asm: The cells under Rex: ladders, restart markers, the shield recharger, the weapon stations
;
; CellsUnderRex reads the grid under Rex's feet (RexCellPtr $A019 + $60, + $61). A ladder or lift ($12) stops his fall
; and lifts him; a restart marker ($07) saves the restart point; the recharger ($08) gives a unit of shield a pass;
; the four weapon stations ($0D double fire, $0A laser, $0B multiple, $0C spray) give the weapon and show its panel
; once.
; --------------------------------------------------------------------------------------------------------------------

; Test the cells under Rex and act: lift, restart marker, recharger, weapon
; stations
;
; Witness: L1 16633 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x32).
CellsUnderRex:
  XOR A
  LD (OnLift),A
  LD HL,(RexCellPtr)
  LD DE,$0060
  ADD HL,DE
  LD A,(HL)
  CP $12
  JP Z,OnLadder
  LD HL,(RexCellPtr)
  LD DE,$0061
  ADD HL,DE
  LD A,(HL)
  CP $07
  JP Z,SaveRestart
  CP $08
  JP Z,Recharge
  CP $0D
  JP Z,StationDouble
  CP $0A
  JP Z,StationLaser
  CP $0B
  JP Z,StationMultiple
  CP $0C
  JP Z,StationSpray
  RET
OnLadder:
  XOR A                   ; a ladder or lift: no fall, Rex lifted
  LD (RexSpeed),A
  LD A,$01
  LD (OnLift),A
  LD A,(RexY)
  AND $07
  OR A
  RET NZ
  XOR A
  LD (FallSpeed),A
  CALL Land
  CALL StartJump
  RET
StationDouble:
  INC HL                  ; the double fire station
  LD A,(HL)
  CP $0D
  RET NZ
  CALL GiveDoubleFire
  LD HL,DoubleFireText
  CALL WeaponPanel
  RET
StationLaser:
  INC HL                  ; the laser station
  LD A,(HL)
  CP $0A
  RET NZ
  CALL GiveLaser
  LD HL,LaserText
  CALL WeaponPanel
  RET
StationMultiple:
  INC HL                  ; the multiple station
  LD A,(HL)
  CP $0B
  RET NZ
  CALL GiveMultiple
  LD HL,MultipleText
  CALL WeaponPanel
  RET

; The spray station ($0C): GiveSpray $A79D and the SPRAY panel (SprayText
; $ABCA)
;
; Witness: L1 69 (rzx-p1- x5).
StationSpray:
  INC HL
  LD A,(HL)
  CP $0C
  RET NZ
  CALL GiveSpray
  LD HL,SprayText
  CALL WeaponPanel
  RET

; The recharger ($08): ShieldEnergy + 1 up to 99 while the shield is off, the
; recharge sound
;
; Witness: L1 990 (p1-speedup, rzx-p1- x18).
Recharge:
  INC HL
  LD A,(HL)
  CP $08
  RET NZ
  LD A,(ShieldOn)
  OR A
  RET NZ
  LD A,(ShieldEnergy)
  INC A
  CP $64
  RET Z
  LD (ShieldEnergy),A
  CALL ShowShield
  LD A,(Channels+$0008)
  CP $FF
  RET NZ
  LD DE,SfxRecharge
  CALL StartSfx
  RET
