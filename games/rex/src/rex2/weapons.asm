; --------------------------------------------------------------------------------------------------------------------
; weapons.asm: The weapons: firing, the bullets, the power level
; --------------------------------------------------------------------------------------------------------------------

; The double fire station: HasDoubleFire $A1E9 = 1, then GiveWeapon
;
; As REX 1's GiveDoubleFire $A78B (src/game/weapons.asm).
;
; Known only from the code: no room of REX 2 holds a weapon station. The
; characters whose CharFlags $6506 type is $0A-$0D appear in no block of the 26
; rooms' maps (the recharger $08 does, in rooms 4, 9, 12, 15, 20, 21 and 22),
; so GiveDoubleFire, GiveLaser, GiveMultiple, GiveSpray and WeaponPanel $D609
; are REX 1's code kept; the weapons come from the access code (EnterCode
; $DB27).
;
; Witness: L1 0 ().
GiveDoubleFire:
  LD HL,HasDoubleFire
  JP GiveWeapon

; The laser station: HasLaser $A1EA = 1
;
; As REX 1's GiveLaser $A791 (src/game/weapons.asm).
;
; Known only from the code: no recording runs it.
;
; Witness: L1 0 ().
GiveLaser:
  LD HL,HasLaser
  JP GiveWeapon

; The multiple station: HasMultiple $A1EB = 1
;
; As REX 1's GiveMultiple $A797 (src/game/weapons.asm).
;
; Known only from the code: no recording runs it.
;
; Witness: L1 0 ().
GiveMultiple:
  LD HL,HasMultiple
  JP GiveWeapon

; The spray station: HasSpray $A1EC = 1; GiveWeapon: the icons shown, the best
; weapon chosen (BestWeapon $BA52)
;
; As REX 1's GiveSpray $A79D (src/game/weapons.asm).
;
; Known only from the code: no recording runs it.
;
; Witness: L1 0 ().
GiveSpray:
  LD HL,HasSpray
; This entry point is used by the routines at GiveDoubleFire, GiveLaser and
; GiveMultiple.
GiveWeapon:
  LD (HL),$01             ; the icons and the best weapon
  CALL ShowWeaponIcons
  CALL BestWeapon
  RET

; Roll an 8-byte character at HL one line up (REX 1's conveyor roll; nothing
; calls it in part 2)
;
; Witness: L1 0 ().
RollCharRight:
  PUSH HL
  LD C,(HL)
  LD E,L
  LD D,H
  INC HL
  LD B,$07
RollUpLoop:
  LD A,(HL)               ; each line
  LD (DE),A
  INC DE
  INC HL
  DJNZ RollUpLoop
  LD A,C
  LD (DE),A
  POP HL
  RET

; Roll an 8-byte character at HL one line down (nothing calls it in part 2)
;
; Witness: L1 0 ().
RollCharLeft:
  PUSH HL
  LD DE,$0007
  ADD HL,DE
  LD C,(HL)
  LD E,L
  LD D,H
  DEC HL
  LD B,$07
RollDownLoop:
  LD A,(HL)               ; each line
  LD (DE),A
  DEC DE
  DEC HL
  DJNZ RollDownLoop
  POP HL
  LD (HL),C
  RET

  ORG $B452

; Double fire's second shot
;
; As REX 1's FireDouble $B40C (src/game/weapons.asm).
;
; Witness: L1 2 (c2).
FireDouble:
  CALL FindShotSlot
  LD A,$13
  LD (Temp4),A
  LD A,(Weapon)
  RES 7,A
  CALL SetupShot
  RET

; The laser's beam
;
; As REX 1's FireLaser $B41D (src/game/weapons.asm).
;
; Witness: L1 74 (c2, rzx-p2-00000, rzx-p2-02000, rzx-p2-04000).
FireLaser:
  CALL RexShot
  LD (IY+$05),$00
  LD (IY+$0C),$08
  LD A,(IY+$00)
  LD (IY+$0D),A
  LD A,(FireDelay)
  DEC A
  LD (IY+$0E),A
  RET

; The spray's 8 directions: [dX word][dY][..], read by FireSpray (and by part
; 1's mine layer burst, a leftover in ObjectMoveCode $C30A)
;
; As REX 1's SprayDirections $B436 (src/game/weapons.asm).
SprayDirections:
  DEFB $01,$00,$08,$00
  DEFB $FF,$FF,$F8,$00
  DEFB $00,$00,$00,$08
  DEFB $00,$00,$00,$F8
  DEFB $01,$00,$08,$08
  DEFB $01,$00,$08,$F8
  DEFB $FF,$FF,$F8,$08
  DEFB $FF,$FF,$F8,$F8

; The spray: 8 shots in the 8 directions of SprayDirections, as many as the
; power level allows
;
; As REX 1's FireSpray $B456 (src/game/weapons.asm).
;
; Witness: L1 623 (rzx-p2- x15).
FireSpray:
  LD A,(PowerLevel)
  CP $04
  JP C,SprayShot
  LD B,$04
  LD HL,SprayDirections
  LD A,(PowerLevel)
  CP $04
  JP Z,SprayLoop
  LD B,$08
SprayLoop:
  PUSH BC                 ; each of the 8 directions
  PUSH HL
  CALL FindShotSlot
  CALL RexShot
  POP HL
  CALL SetShotDirection
  POP BC
  DJNZ SprayLoop
  RET
SprayShot:
  CALL RexShot            ; the shot
  LD (IY+$05),$00
  CALL FindShotSlot
  CALL RexShot
  LD A,$01
  CALL SetShotSpeed
  CALL FindShotSlot
  CALL RexShot
  LD A,$FF
  CALL SetShotSpeed
  LD A,(PowerLevel)
  CP $01
  RET Z
  CALL FindShotSlot
  CALL RexShot
  LD A,$02
  CALL SetShotSpeed
  CALL FindShotSlot
  CALL RexShot
  LD A,$FE
  CALL SetShotSpeed
  LD A,(PowerLevel)
  CP $02
  RET Z
  CALL FindShotSlot
  CALL RexShot
  LD A,$03
  CALL SetShotSpeed
  CALL FindShotSlot
  CALL RexShot
  LD A,$FD
  CALL SetShotSpeed
  RET

; A shot's direction from the record at HL: dX word, dY, its picture
;
; As REX 1's SetShotDirection $B4D3 (src/game/weapons.asm).
;
; Witness: L1 2716 (rzx-p2- x13).
SetShotDirection:
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (IY+$07),E
  LD (IY+$08),D
  INC HL
  LD A,(HL)
  LD (IY+$04),A
  INC HL
  LD A,(HL)
  INC HL
  PUSH HL
  CALL SetShotSpeed
  POP HL
  RET

; A shot's speed A into its record (dY x 32 added to the grid step)
;
; As REX 1's SetShotSpeed $B4EA (src/game/weapons.asm).
;
; Witness: L1 4181 (c2, rzx-p2- x19).
SetShotSpeed:
  LD (IY+$05),A
  LD E,A
  LD L,E
  RL E
  SBC A,A
  LD H,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD E,(IY+$07)
  LD D,(IY+$08)
  ADD HL,DE
  LD (IY+$07),L
  LD (IY+$08),H
  RET

; IY = a free slot among Rex's bullets (as many as the power level allows for
; the gun and double fire); none: IY = $03E8
;
; As REX 1's FindShotSlot $B506 (src/game/weapons.asm).
;
; Witness: L1 6432 (c2, p2-room20, rzx-p2- x21).
FindShotSlot:
  XOR A
  LD (ShotSide),A
  LD IY,$5B60
  LD E,$1E
  LD A,(Weapon)
  OR A
  JP Z,SlotsByPower
  CP $01
  JP Z,SlotsByPower
  JP FindSlot
SlotsByPower:
  LD A,(PowerLevel)       ; power x 4 + 1 slots
  SLA A
  SLA A
  INC A
  LD E,A

; Search E slots from IY for a free one; the shot's sound by weapon (gun $D4FB,
; laser $D50D, spray $D516; the enemies' $D504)
;
; As REX 1's FindSlot $B528 (src/game/weapons.asm).
;
; Witness: L1 7579 (c2, p2-room20, rzx-p2- x21).
FindSlot:
  DEC E
  LD B,E
FindSlotLoop:
  LD A,(IY+$06)           ; each slot
  OR A
  JP Z,FindSlotFound
  LD DE,$000F
  ADD IY,DE
  DJNZ FindSlotLoop
  LD IY,$03E8
  RET
FindSlotFound:
  PUSH HL                 ; free: the sound
  LD A,(ShotSide)
  OR A
  JP NZ,EnemyShotSound
  LD DE,SfxGun
  LD A,(Weapon)
  CP $02
  CALL Z,LaserSound
  CP $04
  CALL Z,SpraySound
  CALL StartSfx
  POP HL
  RET

; DE = the laser's sound $D50D
;
; As REX 1's LaserSound $B55A (src/game/weapons.asm).
;
; Witness: L1 412 (c2, rzx-p2-00000, rzx-p2-02000, rzx-p2-04000).
LaserSound:
  LD DE,SfxLaser
  RET

; DE = the spray's sound $D516
;
; As REX 1's SpraySound $B55E (src/game/weapons.asm).
;
; Witness: L1 3998 (rzx-p2- x15).
SpraySound:
  LD DE,SfxSpray
  RET

; The enemies' shot sound $D504, if channel 2 is free
;
; As REX 1's EnemyShotSound $B562 (src/game/weapons.asm).
;
; Witness: L1 1121 (c2, p2-room20, rzx-p2- x19).
EnemyShotSound:
  POP HL
  LD A,(Channels+$0010)
  CP $FF
  RET NZ
  LD DE,SfxEnemyShot
  CALL StartSfx
  RET

; IY = a free slot among the enemies' 20 bullets
;
; As REX 1's FindEnemySlot $B570 (src/game/weapons.asm).
;
; Witness: L1 1147 (c2, p2-room20, rzx-p2- x19).
FindEnemySlot:
  LD A,$01
  LD (ShotSide),A
  LD IY,$5D22
  LD E,$14
  JP FindSlot

; An enemy shot from IX's X - 16 (REX 1's; nothing calls it in part 2)
;
; Witness: L1 0 ().
EnemyShotFrom:
  LD A,(IX+$00)
  SUB $10
  JP EnemyShotA

; LD A,(IX+0) then into EnemyShotA: no instruction reaches these 3 bytes
; (leftover)
;
; Witness: L1 0 ().
EnemyShotFromX:
  LD A,(IX+$00)

; An enemy shot at X A, speed 15 (nothing calls it in part 2)
;
; Witness: L1 0 ().
EnemyShotA:
  LD (Temp1),A
  LD A,$0F

; An enemy shot from IX: X Temp1, Y IX+1, speed A, kind EnemyShotKind $A1ED
; (bit 7: an enemy's)
;
; As REX 1's EnemyShot $B58E (src/game/weapons.asm).
;
; Witness: L1 1147 (c2, p2-room20, rzx-p2- x19).
EnemyShot:
  LD (Temp4),A
  LD A,(IX+$01)
  LD (Temp2),A
  LD A,(IX+$02)
  LD (Temp3),A
  LD A,(EnemyShotKind)
  SET 7,A
  JP SetupShot

; A shot from Rex: his X, Y and facing, speed 17, type the weapon
;
; As REX 1's RexShot $B5A5 (src/game/weapons.asm).
;
; Witness: L1 4167 (c2, p2-room20, rzx-p2- x21).
RexShot:
  LD A,(RexX)
  LD (Temp1),A
  LD A,(RexY)
  LD (Temp2),A
  LD A,(RexFacing)
  LD (Temp3),A
  LD A,$11
  LD (Temp4),A
  LD A,(Weapon)
  RES 7,A

; Fill the slot at IY: live, type A, Y Temp2 + Temp4, X Temp1 + 16, direction
; Temp3 (left: dX -1, -8 pixels), the grid pointer
;
; As REX 1's SetupShot $B5C1 (src/game/weapons.asm).
;
; Witness: L1 7115 (c2, p2-room20, rzx-p2- x21).
SetupShot:
  LD (IY+$06),$01
  LD (IY+$0B),A
  LD A,(Temp2)
  LD HL,Temp4
  ADD A,(HL)
  LD (IY+$01),A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,(Temp1)
  ADD A,$10
  LD (IY+$00),A
  LD A,(ShotSide)
  OR A
  JP NZ,ShotDirection
  LD A,(Temp1)
  AND $07
  CP $06
  JP Z,ShotOneUp
  OR A
  JP NZ,ShotDirection
ShotOneUp:
  DEC (IY+$01)            ; the shot one line up
ShotDirection:
  LD (IY+$04),$08         ; right: dX +1
  LD HL,$0001
  LD (IY+$07),L
  LD (IY+$08),H
  LD A,(Temp3)
  OR A
  JP Z,ShotPointer
  LD A,(IY+$00)
  SUB $10
  LD (IY+$00),A
  LD HL,$FFFF
  LD (IY+$07),L
  LD (IY+$08),H
  LD (IY+$04),$F8
ShotPointer:
  LD L,(IY+$01)           ; its grid pointer
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,(IY+$00)
  SRL A
  SRL A
  SRL A
  LD E,A
  LD D,$00
  ADD HL,DE
  LD DE,AttrShadowPlay+$02A0
  ADD HL,DE
  LD (IY+$02),L
  LD (IY+$03),H
  RET

; Move the enemies' 20 bullets
;
; As REX 1's MoveEnemyBullets $B645 (src/game/weapons.asm).
;
; Witness: L1 10885 (c2, p2-room20, rzx-p2- x21).
MoveEnemyBullets:
  LD IX,$5D22
  LD B,$14
  JP MoveShots

; Move Rex's 30 bullets (falls into MoveShots)
;
; As REX 1's MoveBullets $B64E (src/game/weapons.asm).
;
; Witness: L1 10440 (c2, p2-room20, rzx-p2- x21).
MoveBullets:
  LD IX,$5B60
  LD B,$1E

; Move B bullets from IX: by state (live, hit flash 2 and 3) and type (gun,
; beam, spray dot, enemy shot, bouncing, drone shot)
;
; As REX 1's MoveShots $B654 (src/game/weapons.asm).
;
; Witness: L1 530900 (c2, p2-room20, rzx-p2- x21).
MoveShots:
  LD A,(IX+$06)
  OR A
  JP Z,NextShot
  CP $02
  JP Z,ShotFlash1
  CP $03
  JP Z,ShotFlash2
  LD L,(IX+$02)
  LD H,(IX+$03)
  LD A,(IX+$0B)
  AND $7F
  OR A
  JP Z,DrawShotByte
  CP $01
  JP Z,DrawShotByte
  CP $04
  JP Z,DrawShotDot
  CP $02
  JP Z,MoveSplitShot
  CP $03
  JP Z,DrawShotByte
  CP $06
  JP Z,MoveSparkShot
  CP $07
  JP Z,MoveLob

; Move a bullet one step; off the play area it ends; the big squidgy thing's
; cell (4) is hit (BossHit); a cell not passable stops it
;
; Changed from REX 1's StepShot $B692 (src/game/weapons.asm).
;
; Witness: L1 52308 (c2, p2-room20, rzx-p2- x21).
StepShot:
  LD A,(IX+$00)
  ADC A,(IX+$04)
  LD (IX+$00),A
  LD (SpriteX),A
  CP $F8
  JP NC,EndShot
  CP $09
  JP C,EndShot
  LD A,(IX+$01)
  ADC A,(IX+$05)
  LD (IX+$01),A
  LD (SpriteY),A
  CP $C0
  JP NC,EndShot
  CP $18
  JP C,EndShot
  LD A,$01
  CALL CellPointer
  LD A,(HL)
  CP $04
  JP Z,BossHit
  CALL IsPassable
  JP NZ,ShotStopped

; A bullet's path by its type: type 7 keeps its own move, the others add their
; step to the path pointer
;
; Changed from REX 1's StepShotType $B6D9 (src/game/weapons.asm).
;
; Witness: L1 46518 (c2, p2-room20, rzx-p2- x21).
StepShotType:
  LD A,(IX+$0B)
  AND $7F
  CP $07
  JP Z,NextShot
  LD L,(IX+$02)
  LD H,(IX+$03)
  LD E,(IX+$07)
  LD D,(IX+$08)
  ADD HL,DE
  LD (IX+$02),L
  LD (IX+$03),H

; The next bullet record (15 bytes on)
;
; As REX 1's NextShot $B6F6 (src/game/weapons.asm).
;
; Witness: L1 530900 (c2, p2-room20, rzx-p2- x21).
NextShot:
  LD DE,$000F
  ADD IX,DE
  DEC B
  JP NZ,MoveShots
  RET

; The bullet ends (live = 0)
;
; As REX 1's EndShot $B700 (src/game/weapons.asm).
;
; Witness: L1 1073 (c2, rzx-p2- x21).
EndShot:
  LD (IX+$06),$00
  JP NextShot

; A bullet on a cell of type 4 (the big squidgy thing): unless it already dies,
; BossDying $A268 = 1, BossTimer 200, BossAreaPtr $9CF9, its colours (3, $43,
; 6) cleared from the shadow; the bullet flies on
;
; Witness: L1 1 (rzx-p2-40000).
BossHit:
  LD A,(BossDying)
  OR A
  JP NZ,BossHitDone
  LD A,$C8
  LD (BossTimer),A
  LD HL,ExplosionAreas+$0002
  LD (BossAreaPtr),HL
  LD A,$01
  LD (BossDying),A
  LD HL,AttrShadowPlay
  PUSH BC
  LD BC,$02A0
BossClearLoop:
  LD A,(HL)               ; each cell of the shadow's play rows
  CP $03
  JP Z,BossClearCell
  CP $43
  JP Z,BossClearCell
  CP $06
  JP Z,BossClearCell
  JP BossClearNext
BossClearCell:
  LD (HL),$00             ; one of the boss's colours: cleared
BossClearNext:
  INC HL                  ; the next cell
  DEC BC
  LD A,B
  OR C
  JP NZ,BossClearLoop
  POP BC
BossHitDone:
  JP StepShotType         ; the bullet flies on

; Leftover: POP HL: POP AF, the end of an instruction of REX 1's code; no
; instruction reaches it
ShotLeftover:
  DEFB $E1,$F1
  DEFB $DD,$CB
  DEFB $0B,$7E
  DEFB $C2,$15
  DEFB $B7,$32
  DEFB $2C,$A2
  DEFB $3C,$77
  DEFB $11,$9F
  DEFB $E1,$A7
  DEFB $ED,$52
  DEFB $E5,$11
  DEFB $9F,$DE
  DEFB $19,$7E
  DEFB $3D,$6F
  DEFB $26,$00
  DEFB $29,$29
  DEFB $11,$62
  DEFB $D9,$19
  DEFB $22,$2E
  DEFB $A2,$23
  DEFB $23,$5E
  DEFB $23,$56
  DEFB $E5,$21
  DEFB $08,$00
  DEFB $19,$EB
  DEFB $E1,$2B
  DEFB $73,$23
  DEFB $72,$EB
  DEFB $11,$06
  DEFB $66,$A7
  DEFB $ED,$52
  DEFB $CB,$3C
  DEFB $CB,$1D
  DEFB $CB,$3C
  DEFB $CB,$1D
  DEFB $CB,$3C
  DEFB $CB,$1D
  DEFB $11,$06
  DEFB $6E,$19
  DEFB $7E,$32
  DEFB $30,$A2
  DEFB $3A,$2C
  DEFB $A2,$FE
  DEFB $06,$C2
  DEFB $E0,$B7
  DEFB $3E,$47
  DEFB $32,$30
  DEFB $A2,$E1
  DEFB $E5,$11
  DEFB $00,$58
  DEFB $19,$3A
  DEFB $30,$A2
  DEFB $77,$E1
  DEFB $E5,$11
  DEFB $FF,$E4
  DEFB $19,$3A
  DEFB $30,$A2
  DEFB $77,$E1
  DEFB $3A,$2C
  DEFB $A2,$FE
  DEFB $04,$CA
  DEFB $10,$B8
  DEFB $FE,$05
  DEFB $CA,$10
  DEFB $B8,$11
  DEFB $9F,$E1
  DEFB $19,$36
  DEFB $00,$ED
  DEFB $5B,$2E
  DEFB $A2,$AF
  DEFB $12,$13
  DEFB $12

; A bullet meets a wall: a small flash (state 2) unless it is the laser, the
; hit sound $D51F
;
; As REX 1's ShotStopped $B794 (src/game/weapons.asm).
;
; Witness: L1 4717 (c2, p2-room20, rzx-p2- x21).
ShotStopped:
  LD L,(IX+$02)
  LD H,(IX+$03)
  LD (HL),$10
  LD (IX+$06),$00
  LD A,(Weapon)
  CP $02
  JP Z,NextShot
  LD (IX+$06),$02
  LD A,(Channels+$0010)
  CP $FF
  JP NZ,NextShot
  LD DE,SfxHitWall
  CALL StartSfx
  JP NextShot

; The flash's first frame: a cross of three bytes in the buffer
;
; As REX 1's ShotFlash1 $B7BD (src/game/weapons.asm).
;
; Witness: L1 5244 (p2-room20, rzx-p2- x21).
ShotFlash1:
  LD L,(IX+$02)
  LD H,(IX+$03)
  LD DE,$0020
  AND A
  SBC HL,DE
  LD (HL),$10
  ADD HL,DE
  LD (HL),$38
  ADD HL,DE
  LD (HL),$10
  LD (IX+$06),$03
  JP NextShot

; The flash's second frame, then the bullet ends
;
; As REX 1's ShotFlash2 $B7D8 (src/game/weapons.asm).
;
; Witness: L1 5247 (p2-room20, rzx-p2- x21).
ShotFlash2:
  LD L,(IX+$02)
  LD H,(IX+$03)
  LD DE,$0040
  AND A
  SBC HL,DE
  LD DE,$0020
  LD (HL),$10
  ADD HL,DE
  LD (HL),$00
  ADD HL,DE
  LD (HL),$44
  ADD HL,DE
  LD (HL),$00
  ADD HL,DE
  LD (HL),$10
  LD (IX+$06),$00
  JP NextShot

; A type 7 shot: its Y step from its path (LobPathTable by IX+$0E; at the end
; the repeat step), the 4-line LobPicture, then StepShot
;
; Witness: L1 4745 (c2, rzx-p2- x13).
MoveLob:
  LD L,(IX+$01)
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD E,(IX+$00)
  SRL E
  SRL E
  SRL E
  LD D,$00
  ADD HL,DE
  LD DE,AttrShadowPlay+$02A0
  ADD HL,DE
  LD (IX+$02),L
  LD (IX+$03),H
  PUSH HL
  LD A,(IX+$0E)
  LD E,A
  LD D,$00
  LD HL,LobPathTable
  ADD HL,DE
  LD (Temp1),HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  LD E,(IX+$0C)
  LD D,$00
  ADD HL,DE
  LD A,(HL)
  CP $1E
  JP NZ,LobDraw
  DEC (IX+$0C)
  LD HL,(Temp1)
  INC HL
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  LD A,$08
LobDraw:
  LD (IX+$05),A           ; the picture
  INC HL
  LD E,(HL)
  LD DE,LobPicture
  POP HL
  PUSH BC
  LD B,$04
LobDrawLoop:
  LD A,(DE)               ; 4 lines
  LD (HL),A
  INC DE
  PUSH DE
  LD DE,$0020
  ADD HL,DE
  POP DE
  DJNZ LobDrawLoop
  POP BC
  INC (IX+$0C)
  JP StepShot

; Draw a type 4 bullet: a 4-line dot (Rex's or an enemy's shape)
;
; As REX 1's DrawShotDot $B867 (src/game/weapons.asm).
;
; Witness: L1 28859 (c2, rzx-p2- x19).
DrawShotDot:
  LD DE,$0040
  AND A
  SBC HL,DE
  LD DE,$0020
  BIT 7,(IX+$0B)
  JP NZ,DotEnemy
  LD (HL),$10
  ADD HL,DE
  LD (HL),$1C
  ADD HL,DE
  LD (HL),$38
  ADD HL,DE
  LD (HL),$08
  JP StepShot
DotEnemy:
  LD (HL),$00             ; an enemy's dot
  ADD HL,DE
  LD (HL),$10
  ADD HL,DE
  LD (HL),$28
  ADD HL,DE
  LD (HL),$10
  JP StepShot

; Draw a gun bullet: one byte by direction and side
;
; As REX 1's DrawShotByte $B893 (src/game/weapons.asm).
;
; Witness: L1 14319 (c2, p2-room20, rzx-p2- x17).
DrawShotByte:
  BIT 7,(IX+$0B)
  JP NZ,ByteEnemy
  LD A,(IX+$04)
  DEC A
  JP M,ByteRightUp
  LD (HL),$B7
  JP StepShot
ByteRightUp:
  LD (HL),$ED
  JP StepShot
ByteEnemy:
  LD A,(IX+$04)           ; an enemy's bullet
  DEC A
  JP M,ByteEnemyLeft
  LD (HL),$97
  JP StepShot
ByteEnemyLeft:
  LD (HL),$E9
  JP StepShot

; A splitting shot (type 2): every few steps it fires a new shot from where it
; is
;
; As REX 1's MoveSplitShot $B8BC (src/game/weapons.asm).
;
; Witness: L1 590 (c2, rzx-p2-00000, rzx-p2-02000, rzx-p2-04000).
MoveSplitShot:
  LD A,(IX+$0E)
  DEC A
  LD (IX+$0E),A
  OR A
  JP NZ,SplitStep
  LD (IX+$06),$00
  JP StepShot
SplitStep:
  LD A,(IX+$0C)
  DEC A
  OR A
  JP Z,StepShot
  LD (IX+$0C),A
  LD A,(IX+$0D)
  INC A
  LD (Temp1),A
  LD A,(IX+$01)
  LD (Temp2),A
  LD A,$01
  LD (Temp3),A
  BIT 7,(IX+$04)
  JP NZ,SplitFire
  XOR A
  LD (Temp3),A
  LD A,(Temp1)
  SUB $10
  LD (Temp1),A
SplitFire:
  XOR A
  LD (Temp4),A
  PUSH IX
  PUSH BC
  CALL FindShotSlot
  XOR A
  CALL SetupShot
  LD A,(FireDelay)
  LD (IY+$0E),A
  LD (IY+$05),$00
  LD (IY+$0B),$06
  POP BC
  POP IX
  JP StepShot

; A spark (type 6): random dots by its count (SparkMasks $B9BE), it fades out
;
; As REX 1's MoveSparkShot $B920 (src/game/weapons.asm).
;
; Witness: L1 3795 (c2, rzx-p2-00000, rzx-p2-02000, rzx-p2-04000).
MoveSparkShot:
  EX DE,HL
  PUSH DE
  LD A,(IX+$0E)
  LD E,A
  LD D,$00
  LD HL,SparkMasks
  ADD HL,DE
  LD A,R
  AND (HL)
  POP DE
  LD (DE),A
  LD A,(IX+$0E)
  DEC A
  LD (IX+$0E),A
  OR A
  JP NZ,StepShot
  LD (IX+$06),$00
  JP StepShot

; The spark's masks by count: $00, $04, $44, $54, $55, $D5, $DD, $DF, then $FF
;
; As REX 1's SparkMasks $B943 (src/game/weapons.asm).
SparkMasks:
  DEFB $00,$04,$44,$54,$55,$D5,$DD,$DF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

; Draw the power bar: its end colour flashes by FadeStepIndex
;
; As REX 1's PowerBar $B96B (src/game/weapons.asm).
;
; Witness: L1 10871 (c2, p2-room20, rzx-p2- x21).
PowerBar:
  LD A,(FadeStepIndex)
  CP $FF
  RET NZ
  LD HL,(PowerBarPtr)
  CALL PowerBarColour
  LD HL,(PowerBarPtr)
  LD DE,SpritePowerBar
  ADD HL,DE

; A = PowerLevel + 2 (the bar's colour)
;
; As REX 1's PowerBarColour $B97E (src/game/weapons.asm).
;
; Witness: L1 20400 (c2, p2-room20, rzx-p2- x21).
PowerBarColour:
  LD A,(PowerLevel)
  INC A
  INC A

; Write A into a 2 x 2 patch at HL
;
; As REX 1's Fill2x2 $B983 (src/game/weapons.asm).
;
; Witness: L1 20424 (c2, p2-room20, rzx-p2- x21).
Fill2x2:
  LD (HL),A
  INC HL
  LD (HL),A
  LD DE,$001F
  ADD HL,DE
  LD (HL),A
  INC HL
  LD (HL),A
  RET

; A power pod: PowerCount $A1B1 counts, every few the PowerLevel + 1 up to 6,
; the bar redrawn, the fire faster
;
; As REX 1's PowerGain $B98E (src/game/weapons.asm).
;
; Witness: L1 78 (rzx-p2- x14).
PowerGain:
  LD HL,Temp1
  LD (HL),A
  LD A,(PowerLevel)
  CP $06
  RET Z
  LD A,(PowerCount)
  ADD A,(HL)
  LD (PowerCount),A
  CP $78
  RET C
  SUB $78
  LD (PowerCount),A
  LD A,(PowerLevel)
  INC A
  CP $06
  JP Z,GainRank
  LD (PowerLevel),A
  SLA A
  SLA A
  ADD A,$04
  LD (FireDelay),A
  CALL InitDrones
  RET
GainRank:
  LD A,(WeaponRank)
  INC A
  CP $05
  RET Z
  LD (WeaponRank),A
  LD HL,(PowerBarPtr)
  INC HL
  INC HL
  LD (PowerBarPtr),HL
  LD A,$01
  LD (PowerLevel),A

; Weapon = the best one held (WeaponRank $A207), WeaponIcon updated
;
; As REX 1's BestWeapon $B9D7 (src/game/weapons.asm).
;
; Witness: L1 52 (c2, p2-room20, rzx-p2- x16).
BestWeapon:
  LD HL,WeaponIcon
  LD A,(WeaponRank)
  INC A
  LD B,A
  LD E,$00
BestLoop:
  LD A,(HL)               ; each weapon held
  OR A
  JP Z,BestNext
  LD A,E
  LD (Weapon),A
BestNext:
  INC E
  INC HL
  DJNZ BestLoop
  RET

; A shot of a special weapon: PowerCount down; at 0 the PowerLevel - 1, the bar
; redrawn; at 1 BestWeapon
;
; As REX 1's PowerDrain $B9EF (src/game/weapons.asm).
;
; Witness: L1 1038 (c2, p2-room20, rzx-p2- x21).
PowerDrain:
  LD HL,Temp1
  LD (HL),A
  LD A,(PowerLevel)
  OR A
  RET Z
  LD A,(PowerCount)
  SUB (HL)
  LD (PowerCount),A
  RET P
  ADD A,$32
  LD (PowerCount),A
  LD A,(PowerLevel)
  DEC A
  OR A
  JP Z,DrainRank
  LD (PowerLevel),A
  RET
DrainRank:
  LD A,(WeaponRank)
  DEC A
  CP $FF
  RET Z
  LD (WeaponRank),A
  LD A,$01
  LD HL,(PowerBarPtr)
  CALL Fill2x2
  LD HL,(PowerBarPtr)
  LD DE,SpritePowerBar
  ADD HL,DE
  CALL Fill2x2
  LD HL,(PowerBarPtr)
  DEC HL
  DEC HL
  LD (PowerBarPtr),HL
  LD A,$05
  LD (PowerLevel),A
  JP BestWeapon

; A death: PowerDrain once
;
; Changed from REX 1's LosePower $BA3D (src/game/weapons.asm).
;
; Witness: L1 36 (c2, p2-room20, rzx-p2- x14).
LosePower:
  LD B,$02
LosePowerDo:
  PUSH BC
  LD A,$32
  CALL PowerDrain
  POP BC
  DJNZ LosePowerDo
  JP BestWeapon

; A new game's weapon: Weapon 2 (the laser), PowerLevel 3, the bar's end $5805,
; WeaponRank 2
;
; Witness: L1 5 (c2, rzx-p2-00000).
StartWeapon:
  LD A,$02
  LD (Weapon),A
  LD A,$03
  LD (PowerLevel),A
  LD HL,$5805
  LD (PowerBarPtr),HL
  LD A,$02
  LD (WeaponRank),A
  RET
