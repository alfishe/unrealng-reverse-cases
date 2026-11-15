; --------------------------------------------------------------------------------------------------------------------
; weapons.asm: The weapons: firing, the bullets, the power level
; --------------------------------------------------------------------------------------------------------------------

  ORG $A25F

; The double fire station: HasDoubleFire $5ED9 = 1, then GiveWeapon
;
; As REX 1's GiveDoubleFire $A78B (src/game/weapons.asm).
;
; Witness: L1 103 (d1, demo-cycle).
GiveDoubleFire:
  LD HL,HasDoubleFire
  JP GiveWeapon

; The laser station: HasLaser $5EDA = 1
;
; As REX 1's GiveLaser $A791 (src/game/weapons.asm).
;
; Witness: L1 76 (d1, demo-cycle).
GiveLaser:
  LD HL,HasLaser
  JP GiveWeapon

; The multiple station: HasMultiple $5EDB = 1
;
; As REX 1's GiveMultiple $A797 (src/game/weapons.asm).
;
; Witness: L1 30 (demo-cycle).
GiveMultiple:
  LD HL,HasMultiple
  JP GiveWeapon

; The spray station: HasSpray = 1, then GiveWeapon
;
; Changed from REX 1's GiveSpray $A79D (src/game/weapons.asm).
;
; Witness: L1 35 (demo-cycle).
GiveSpray:
  LD HL,HasSpray

; The weapon flag at HL = 1, the icons shown (ShowWeaponIcons), the best weapon
; chosen (BestWeapon)
;
; Changed from REX 1's GiveWeapon $A7A0 (src/game/weapons.asm).
;
; Witness: L1 244 (d1, demo-cycle).
GiveWeapon:
  LD (HL),$01
  CALL ShowWeaponIcons
  CALL BestWeapon
  RET

  ORG $BC31

; Fire: a shot of the current weapon if a slot is free (once a press, only
; while Rex is present)
;
; As REX 1's FireWeapon $B372 (src/game/weapons.asm).
;
; Witness: L1 575 (d1, demo-cycle).
FireWeapon:
  LD A,(FireLatch)
  OR A
  RET NZ
  LD A,(RexPresent)
  OR A
  RET Z
  LD A,$01
  LD (FireLatch),A
  CALL FindShotSlot
  LD A,(Weapon)
  AND $03
  LD A,(RapidShotsOn)
  OR A
  JP Z,FireByWeapon
  LD A,(RapidShotsLeft)
  DEC A
  LD (RapidShotsLeft),A
  OR A
  JP NZ,FireByWeapon
  XOR A
  LD (RapidShotsOn),A
FireByWeapon:
  LD A,(Weapon)            ; the shot by weapon
  CP $04
  JP Z,FireSpray
  CP $02
  JP Z,FireLaser
  CALL RexShot
  LD (IY+$05),$00
  LD A,(Weapon)
  CP $01
  JP Z,FireDouble
  CP $03
  RET NZ
  LD A,(SparkleMode)
  OR A
  RET NZ
  LD A,(PowerLevel)
  ADD A,$03
  LD B,A
  LD HL,$5E83
FireDroneShots:
  PUSH BC                 ; one shot from each drone
  CALL FindShotSlot
  LD A,(HL)
  LD (Temp1),A
  LD A,(RexFacing)
  LD A,$01
  LD (Temp3),A
  LD A,(RexX)
  CP (HL)
  JP NC,FireDroneDir
  XOR A
  LD (Temp3),A
FireDroneDir:
  LD A,(HL)               ; the shot's direction
  INC HL
  CP $F0
  JP NC,FireDroneNext
  LD A,(HL)
  LD (Temp2),A
  LD A,$03
  LD (Temp4),A
  XOR A
BigGunShot:
  PUSH HL
  CALL SetupShot
  POP HL
FireDroneNext:
  LD DE,$0002             ; the next drone
  ADD HL,DE
  POP BC
  DJNZ FireDroneShots
  RET

; Double fire's second shot
;
; As REX 1's FireDouble $B40C (src/game/weapons.asm).
;
; Witness: L1 76 (d1, demo-cycle).
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
; Witness: L1 35 (d1, demo-cycle).
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

; The spray: at power 1-3 a fan of 3, 5 or 7 shots ahead (from $BDB3); at power
; 4 the four directions, at 5-6 all eight
;
; Witness: L1 58 (demo-cycle).
FireSpray:
  LD A,(PowerLevel)
  CP $04
  JP C,SprayShot
  CALL RexShot
  LD (IY+$07),$01
  LD (IY+$08),$00
  LD (IY+$04),$08
  LD (IY+$05),$00
  CALL FindShotSlot
  CALL RexShot
  LD HL,$FFFF
  LD (IY+$07),L
  LD (IY+$08),H
  LD (IY+$04),$F8
  LD (IY+$05),$00
  CALL FindShotSlot
  CALL RexShot
  LD (IY+$07),$00
  LD (IY+$08),$00
  LD (IY+$04),$00
  LD A,$08
  CALL SetShotSpeed
  CALL FindShotSlot
  CALL RexShot
  LD (IY+$07),$00
  LD (IY+$08),$00
  LD (IY+$04),$00
  LD A,$F8
  CALL SetShotSpeed
  LD A,(PowerLevel)
  CP $04
  RET Z
  CALL FindShotSlot
  CALL RexShot
  LD (IY+$07),$01
  LD (IY+$08),$00
  LD (IY+$04),$08
  LD A,$08
  CALL SetShotSpeed
  CALL FindShotSlot
  CALL RexShot
  LD (IY+$07),$01
  LD (IY+$08),$00
  LD (IY+$04),$08
  LD A,$F8
  CALL SetShotSpeed
  CALL FindShotSlot
  CALL RexShot
  LD HL,$FFFF
  LD (IY+$07),L
  LD (IY+$08),H
  LD (IY+$04),$F8
  LD A,$08
  CALL SetShotSpeed
  CALL FindShotSlot
  CALL RexShot
  LD HL,$FFFF
  LD (IY+$07),L
  LD (IY+$08),H
  LD (IY+$04),$F8
  LD A,$F8
  CALL SetShotSpeed
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

; A shot's speed A into its record (dY x 32 added to the grid step)
;
; As REX 1's SetShotSpeed $B4EA (src/game/weapons.asm).
;
; Witness: L1 2318 (d1, demo-cycle).
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
; Witness: L1 1157 (d1, demo-cycle).
FindShotSlot:
  XOR A
  LD (ShotSide),A
  LD IY,$5B95
  LD E,$1E
RouletteGive:
  LD A,(Weapon)            ; give the prize shown
  OR A
  JP Z,SlotsByPower
  CP $01
  JP Z,SlotsByPower
  JP FindSlot
SlotsByPower:
  LD A,(PowerLevel)            ; E = power x 4 + 1; FindSlot searches E - 1 = power
                          ; x 4 slots (the other weapons 29 of the 30)
  SLA A
  SLA A
  INC A
  LD E,A

; Search E slots from IY for a free one; the shot's sound by weapon (gun $D967,
; laser $D979, spray $D982; the enemies' $D970)
;
; As REX 1's FindSlot $B528 (src/game/weapons.asm).
;
; Witness: L1 4507 (d1, demo-cycle).
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

; DE = the laser's sound $D979
;
; As REX 1's LaserSound $B55A (src/game/weapons.asm).
;
; Witness: L1 142 (d1, demo-cycle).
LaserSound:
  LD DE,SfxLaser
  RET

; DE = the spray's sound $D982
;
; As REX 1's SpraySound $B55E (src/game/weapons.asm).
;
; Witness: L1 272 (demo-cycle).
SpraySound:
  LD DE,SfxSpray
  RET

; The enemies' shot sound $D970, if channel C (the third, Channels+$10) is free
;
; As REX 1's EnemyShotSound $B562 (src/game/weapons.asm).
;
; Witness: L1 3350 (d1, demo-cycle).
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
; Witness: L1 3350 (d1, demo-cycle).
FindEnemySlot:
  LD A,$01
  LD (ShotSide),A
  LD IY,$5D57
  LD E,$14
  JP FindSlot

; An enemy shot from IX's X - 16
;
; As REX 1's EnemyShotFrom $B57E (src/game/weapons.asm).
;
; Witness: L1 1069 (d1, demo-cycle).
EnemyShotFrom:
  LD A,(IX+$00)
  SUB $10
  JP EnemyShotA

; LD A,(IX+0) then into EnemyShotA: no instruction reaches these 3 bytes
; (leftover, as REX 1's $B586)
;
; Known only from the code.
;
; Witness: L1 0 ().
EnemyShotFromX:
  LD A,(IX+$00)

; An enemy shot at X A, its Y 15 below the object's
;
; As REX 1's EnemyShotA $B589 (src/game/weapons.asm).
;
; Witness: L1 2092 (d1, demo-cycle).
EnemyShotA:
  LD (Temp1),A
  LD A,$0F

; An enemy shot from IX: X Temp1, Y IX+1 plus A (Temp4, the Y offset SetupShot
; adds), kind EnemyShotKind $5EDD (bit 7: an enemy's)
;
; As REX 1's EnemyShot $B58E (src/game/weapons.asm).
;
; Witness: L1 2420 (d1, demo-cycle).
EnemyShot:
  LD (Temp4),A
  LD A,(IX+$01)
  LD (Temp2),A
  LD A,(IX+$02)
  LD (Temp3),A
  LD A,(EnemyShotKind)
  SET 7,A
  JP SetupShot

; A shot from Rex: his X, Y + 17 (Temp4) and facing, type the weapon
;
; As REX 1's RexShot $B5A5 (src/game/weapons.asm).
;
; Witness: L1 718 (d1, demo-cycle).
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
; Witness: L1 3825 (d1, demo-cycle).
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
  LD DE,ShotBufferOrigin
  ADD HL,DE
  LD (IY+$02),L
  LD (IY+$03),H
  RET

; Move the enemies' 20 bullets
;
; As REX 1's MoveEnemyBullets $B645 (src/game/weapons.asm).
;
; Witness: L1 6753 (d1, demo-cycle).
MoveEnemyBullets:
  LD IX,$5D57
  LD B,$14
  JP MoveShots

; Move Rex's 30 bullets (falls into MoveShots)
;
; As REX 1's MoveBullets $B64E (src/game/weapons.asm).
;
; Witness: L1 6753 (d1, demo-cycle).
MoveBullets:
  LD IX,$5B95
  LD B,$1E

; Move B bullets from IX: by state (live, hit flash 2 and 3) and type (gun,
; beam, spray dot, enemy shot, bouncing, drone shot)
;
; As REX 1's MoveShots $B654 (src/game/weapons.asm).
;
; Witness: L1 337650 (d1, demo-cycle).
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
  JP Z,MoveBeam

; Move a bullet one step; off the play area it ends; a damaging cell (4, 5, 6)
; is hit; a solid cell stops it
;
; As REX 1's StepShot $B692 (src/game/weapons.asm).
;
; Witness: L1 31589 (d1, demo-cycle).
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
  JP Z,BulletHitsCell
  CP $05
  JP Z,BulletHitsCell
  CP $06
  JP Z,BulletHitsCell
  CALL IsPassable
  JP NZ,ShotStopped
; This entry point is used by the routine at BulletHitsCell.
StepShotType:
  LD A,(IX+$0B)           ; by type
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
; Witness: L1 337650 (d1, demo-cycle).
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
; Witness: L1 617 (d1, demo-cycle).
EndShot:
  LD (IX+$06),$00
  JP NextShot

; A bullet hits a cell 4, 5 or 6: the cell's character one step on (its record
; in SceneryCellList), its attribute ($47 for a 6), the cell emptied unless 4
; or 5
;
; Witness: L1 37 (demo-cycle).
BulletHitsCell:
  BIT 7,(IX+$0B)
  JP NZ,StepShotType
  LD (Temp1),A
  INC A
  LD (HL),A
  LD DE,RoomGrid
  AND A
  SBC HL,DE
  PUSH HL
  LD DE,CellIndexMap
  ADD HL,DE
  LD A,(HL)
  DEC A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD DE,SceneryCellList
  ADD HL,DE
  LD (Temp2),HL
  INC HL
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  PUSH HL
  LD HL,$0008
  ADD HL,DE
  EX DE,HL
  POP HL
  DEC HL
  LD (HL),E
  INC HL
  LD (HL),D
  EX DE,HL
  LD DE,CharGraphics
  AND A
  SBC HL,DE
  SRL H
  RR L
  SRL H
  RR L
  SRL H
  RR L
  LD DE,CharAttrs
  ADD HL,DE
  LD A,(HL)
  LD (Temp3),A
  LD A,(Temp1)
  CP $06
  JP NZ,CellHitDone
  LD A,$47
  LD (Temp3),A
CellHitDone:
  POP HL
  PUSH HL
  LD DE,$5800
  ADD HL,DE
  LD A,(Temp3)
  LD (HL),A
  POP HL
  PUSH HL
  LD DE,AttrShadow
  ADD HL,DE
  LD A,(Temp3)
  LD (HL),A
  POP HL
  LD A,(Temp1)
  CP $04
  JP Z,ShotStopped
  CP $05
  JP Z,ShotStopped
  LD DE,RoomGrid
  ADD HL,DE
  LD (HL),$00
  LD DE,(Temp2)
  XOR A
  LD (DE),A
  INC DE
  LD (DE),A

; A bullet meets a wall: a small flash (state 2) unless it is the laser, the
; hit sound $D98B
;
; As REX 1's ShotStopped $B794 (src/game/weapons.asm).
;
; Witness: L1 2620 (d1, demo-cycle).
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
; Witness: L1 2859 (d1, demo-cycle).
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
; Witness: L1 2848 (d1, demo-cycle).
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
DotEnemy:
  LD (HL),$00             ; an enemy's dot
  ADD HL,DE
  LD (HL),$10
  LD (IX+$06),$00
  JP NextShot

; The long beam (type 7): its frames from BeamPath $A2A7
;
; As REX 1's MoveBeam $B7FC (src/game/weapons.asm).
;
; Witness: L1 5735 (d1, demo-cycle).
MoveBeam:
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
  LD DE,ShotBufferOrigin
  ADD HL,DE
  LD (IX+$02),L
  LD (IX+$03),H
  PUSH HL
  LD A,(IX+$0C)
  LD E,A
  LD D,$00
  LD HL,BeamPath
  ADD HL,DE
  LD A,(HL)
  CP $1E
  JP NZ,BeamFrame
  DEC (IX+$0C)
  DEC (IX+$0C)
  LD HL,BeamPath+$001A
  LD A,$08
BeamFrame:
  LD (IX+$05),A           ; the beam's frame
  INC HL
  LD E,(HL)
  LD D,$00
  LD HL,SpriteLaserB
  BIT 7,(IX+$04)
  JP Z,BeamDraw
  LD HL,SpriteLaserA
BeamDraw:
  ADD HL,DE               ; draw it
  EX DE,HL
  POP HL
  PUSH BC
  LD B,$04
l_C16A:
  LD A,(DE)
  LD (HL),A
  INC DE
  PUSH DE
  LD DE,$0020
  ADD HL,DE
  POP DE
  DJNZ l_C16A
  POP BC
  INC (IX+$0C)
  INC (IX+$0C)
  JP StepShot

; Draw a type 4 bullet: a 4-line dot (Rex's or an enemy's shape)
;
; As REX 1's DrawShotDot $B867 (src/game/weapons.asm).
;
; Witness: L1 14210 (d1, demo-cycle).
DrawShotDot:
  LD DE,$0040
  AND A
  SBC HL,DE
  LD DE,$0020
  BIT 7,(IX+$0B)
  JP NZ,l_C19D
  LD (HL),$10
  ADD HL,DE
  LD (HL),$1C
  ADD HL,DE
  LD (HL),$38
  ADD HL,DE
  LD (HL),$08
  JP StepShot
l_C19D:
  LD (HL),$00
  ADD HL,DE
  LD (HL),$08
  ADD HL,DE
  LD (HL),$1C
  ADD HL,DE
  LD (HL),$08
  JP StepShot

; Draw a gun bullet: one byte by direction and side
;
; As REX 1's DrawShotByte $B893 (src/game/weapons.asm).
;
; Witness: L1 8688 (d1, demo-cycle).
DrawShotByte:
  BIT 7,(IX+$0B)
  JP NZ,l_C1C3
ByteEnemy:
  LD A,(IX+$04)           ; an enemy's bullet
  DEC A
  JP M,ByteRightUp
  LD (HL),$B7
  JP StepShot
ByteRightUp:
  LD (HL),$ED
  JP StepShot
l_C1C3:
  LD (HL),$14
  JP StepShot

; A splitting shot (type 2): every few steps it fires a new shot from where it
; is
;
; As REX 1's MoveSplitShot $B8BC (src/game/weapons.asm).
;
; Witness: L1 532 (d1, demo-cycle).
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

; A spark (type 6): random dots by its count (SparkMasks $C250), it fades out
;
; As REX 1's MoveSparkShot $B920 (src/game/weapons.asm).
;
; Witness: L1 2424 (d1, demo-cycle).
MoveSparkShot:
  EX DE,HL
  PUSH DE
  LD A,(IX+$0E)
  LD E,A
  LD D,$00
  LD HL,SparkMasks
  ADD HL,DE
  CALL Random2
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
; Witness: L1 6752 (d1, demo-cycle).
PowerBar:
  LD A,(FadeStepIndex)
  CP $FF
  RET NZ
  LD HL,(PowerBarPtr)
  CALL PowerBarColour
  LD HL,(PowerBarPtr)
  LD DE,ShadowOffset
  ADD HL,DE

; The 2 x 2 cells at HL in the colour PowerLevel + 2
;
; Changed from REX 1's PowerBarColour $B97E (src/game/weapons.asm).
;
; Witness: L1 12910 (d1, demo-cycle).
PowerBarColour:
  LD A,(PowerLevel)
  INC A
  INC A
  LD (HL),A
  INC HL
  LD (HL),A
  LD DE,$001F
  ADD HL,DE
  LD (HL),A
  INC HL
  LD (HL),A
  RET

; A power pod: PowerCount $5EA1 counts, every 120 the PowerLevel + 1 up to 5
; (at 5 GainRank raises WeaponRank and sets the level back to 1; at rank 5
; nothing), the fire faster
;
; As REX 1's PowerGain $B98E (src/game/weapons.asm).
;
; Witness: L1 474 (d1, demo-cycle).
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
AttractShow:
  LD (PowerCount),A            ; build and show it
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

; Weapon = the best one held (WeaponRank $6067), WeaponIcon updated
;
; As REX 1's BestWeapon $B9D7 (src/game/weapons.asm).
;
; Witness: L1 262 (d1, demo-cycle).
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

; The gun at power 1, the bar at $5801, WeaponRank 0
;
; Witness: L1 7 (d1, demo-cycle).
StartWeapon:
  LD A,$00
  LD (Weapon),A
  LD A,$01
  LD (PowerLevel),A
  LD HL,$5801
  LD (PowerBarPtr),HL
  XOR A
  LD (WeaponRank),A
  RET
