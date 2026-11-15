; --------------------------------------------------------------------------------------------------------------------
; cells.asm: The cells under Rex: ladders, restart markers, the shield recharger, the weapon stations
; --------------------------------------------------------------------------------------------------------------------

; Test the cells under Rex and act: the lift ($12), the restart marker (7), the
; shield recharger (8, up to 100), the weapon stations ($0A-$0D)
;
; Changed from REX 1's CellsUnderRex $9F5F (src/game/cells.asm).
;
; Witness: L1 8990 (c2, p2-room20, rzx-p2- x21).
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
StationSpray:
  INC HL                  ; The spray station ($0C): GiveSpray $A908 and the
                          ; SPRAY panel (SprayText $AC87)
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
; As REX 1's Recharge $9FEE (src/game/cells.asm).
;
; Witness: L1 516 (rzx-p2- x5).
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
