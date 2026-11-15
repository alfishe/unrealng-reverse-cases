; --------------------------------------------------------------------------------------------------------------------
; weapons.asm: The weapons: firing, the bullets, the power level
;
; Fire shoots the current Weapon $A013: 0 the gun, 1 double fire (two shots, up and down), 2 laser (one long shot), 3
; multiple (Rex's shot plus one from each drone), 4 spray (8 shots fanned by SprayDirections $B436). PowerLevel $A014
; (1-6) sets how many shots may be in the air (FindShotSlot) and is used up by firing (PowerDrain $B9EF) and gained by
; power pods (PowerGain $B98E); at 1 the weapon falls back to the best one held (BestWeapon $B9D7). The power bar in
; the HUD shows it.
;
; Rex's bullets live in 30 records of 15 bytes at $5B60, the enemies' in 20 at $5D22: [X][Y][grid
; pointer][flags][dX][dY][live][speed][..][type][count][..]. MoveBullets steps them by type: the gun's bullet, the
; long laser beam, a spray dot, an enemy shot; a bullet that meets a solid cell stops, and the cells 4, 5 and 6 are
; damaged (BulletHitsCell $B707).
; --------------------------------------------------------------------------------------------------------------------

  ORG $A78B

; The double fire station: HasDoubleFire $A050 = 1, then GiveWeapon
;
; Witness: L1 11 (rzx-p1-00000).
GiveDoubleFire:
  LD HL,HasDoubleFire
  JP GiveWeapon

; The laser station: HasLaser $A051 = 1
;
; Witness: L1 31 (rzx-p1-10000).
GiveLaser:
  LD HL,HasLaser
  JP GiveWeapon

; The multiple station: HasMultiple $A052 = 1
;
; Witness: L1 23 (rzx-p1-18000).
GiveMultiple:
  LD HL,HasMultiple
  JP GiveWeapon

; The spray station: HasSpray $A053 = 1; GiveWeapon: the icons shown, the best
; weapon chosen (BestWeapon $B9D7)
;
; Witness: L1 30 (rzx-p1- x5).
GiveSpray:
  LD HL,HasSpray
; This entry point is used by the routines at GiveDoubleFire, GiveLaser and
; GiveMultiple.
GiveWeapon:
  LD (HL),$01             ; the icons and the best weapon
  CALL ShowWeaponIcons
  CALL BestWeapon
  RET

  ORG $B372

; Fire: a shot of the current weapon if a slot is free (once a press, only
; while Rex is present)
;
; Witness: L1 2643 (c1, p1-code, p1-cursor, p1-define, p1-kempston, p1-room x5,
; rzx-p1- x32).
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
  OR A
  JP Z,FireGun
  LD A,$01
FireGun:
  CALL PowerDrain         ; the gun
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
  LD A,(Weapon)           ; the shot by weapon
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
  LD HL,$5E4E
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
; Witness: L1 67 (p1-room14, rzx-p1-04000, rzx-p1-10000, rzx-p1-12000).
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
; Witness: L1 180 (p1-room24, rzx-p1- x6).
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

; The spray's 8 directions: [dX word][dY][..], read by FireSpray and by the
; mine layer's burst (MineBurst $C03A)
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
; Witness: L1 961 (p1-code, p1-room30, rzx-p1- x17).
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
; Witness: L1 5156 (p1-code, p1-room30, rzx-p1- x16).
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
; Witness: L1 8212 (c1, p1-code, p1-cursor, p1-kempston, p1-room26, p1-room27,
; p1-room30, rzx-p1- x25).
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
; Witness: L1 9961 (c1, p1-code, p1-cursor, p1-define, p1-kempston, p1-room x5,
; rzx-p1- x32).
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

; Search E slots from IY for a free one; the shot's sound by weapon (gun $D763,
; laser $D775, spray $D77E; the enemies' $D76C)
;
; Witness: L1 14309 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
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

; DE = the laser's sound $D775
;
; Witness: L1 973 (p1-room24, rzx-p1- x6).
LaserSound:
  LD DE,SfxLaser
  RET

; DE = the spray's sound $D77E
;
; Witness: L1 6544 (p1-code, p1-room30, rzx-p1- x17).
SpraySound:
  LD DE,SfxSpray
  RET

; The enemies' shot sound $D76C, if channel 2 is free
;
; Witness: L1 4342 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-room
; x5, rzx-p1- x32).
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
; Witness: L1 4348 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-room
; x5, rzx-p1- x32).
FindEnemySlot:
  LD A,$01
  LD (ShotSide),A
  LD IY,$5D22
  LD E,$14
  JP FindSlot

; An enemy shot from IX's X - 16
;
; Witness: L1 16 (rzx-p1-20000, rzx-p1-56000).
EnemyShotFrom:
  LD A,(IX+$00)
  SUB $10
  JP EnemyShotA

; LD A,(IX+0) then into EnemyShotA: no instruction reaches these 3 bytes
; (leftover)
;
; Known only from the code.
;
; Witness: L1 0 ().
EnemyShotFromX:
  LD A,(IX+$00)

; An enemy shot at X A, speed 15
;
; Witness: L1 16 (rzx-p1-20000, rzx-p1-56000).
EnemyShotA:
  LD (Temp1),A
  LD A,$0F

; An enemy shot from IX: X Temp1, Y IX+1, speed A, kind EnemyShotKind $A054
; (bit 7: an enemy's)
;
; Witness: L1 3486 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston, p1-room
; x5, rzx-p1- x32).
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
; Witness: L1 6714 (c1, p1-code, p1-cursor, p1-define, p1-kempston, p1-room x5,
; rzx-p1- x32).
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
; Witness: L1 12707 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
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
  LD DE,ShotBufferOrigin
  ADD HL,DE
  LD (IY+$02),L
  LD (IY+$03),H
  RET

; Move the enemies' 20 bullets
;
; Witness: L1 16954 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
MoveEnemyBullets:
  LD IX,$5D22
  LD B,$14
  JP MoveShots

; Move Rex's 30 bullets (falls into MoveShots)
;
; Witness: L1 16842 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
MoveBullets:
  LD IX,$5B60
  LD B,$1E

; Move B bullets from IX: by state (live, hit flash 2 and 3) and type (gun,
; beam, spray dot, enemy shot, bouncing, drone shot)
;
; Witness: L1 844313 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
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
; Witness: L1 84287 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
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
; Witness: L1 844312 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
NextShot:
  LD DE,$000F
  ADD IX,DE
  DEC B
  JP NZ,MoveShots
  RET

; The bullet ends (live = 0)
;
; Witness: L1 2795 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x30).
EndShot:
  LD (IX+$06),$00
  JP NextShot

; A bullet hits a cell 4, 5 or 6: the cell's character goes one step on (its
; animated record in AnimCellList), the room's look changes
;
; Witness: L1 290 (c1, rzx-p1- x7).
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
  LD DE,AnimCellList
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
  LD DE,TitleScreen
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
; hit sound $D787
;
; Witness: L1 7903 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
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
; Witness: L1 8456 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x31).
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
; Witness: L1 8440 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x31).
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

; The long beam (type 7): its frames from BeamPath $A9AF
;
; Witness: L1 3449 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston,
; p1-room14, p1-room24, p1-room26, p1-room30, rzx-p1- x16).
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
  LD HL,BeamEnd
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
BeamByte:
  LD A,(DE)
  LD (HL),A
  INC DE
  PUSH DE
  LD DE,$0020
  ADD HL,DE
  POP DE
  DJNZ BeamByte
  POP BC
  INC (IX+$0C)
  INC (IX+$0C)
  JP StepShot

; Draw a type 4 bullet: a 4-line dot (Rex's or an enemy's shape)
;
; Witness: L1 46274 (c1, p1-code, p1-cursor, p1-kempston, p1-room26, p1-room27,
; p1-room30, rzx-p1- x25).
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
; Witness: L1 23803 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston,
; p1-room x5, rzx-p1- x32).
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
; Witness: L1 1537 (p1-room24, rzx-p1- x6).
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

; A spark (type 6): random dots by its count (SparkMasks $B943), it fades out
;
; Witness: L1 9224 (p1-room24, rzx-p1- x6).
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
SparkMasks:
  DEFB $00,$04,$44,$54,$55,$D5,$DD,$DF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

; Draw the power bar: its end colour flashes by FadeStepIndex
;
; Witness: L1 16927 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
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
; Witness: L1 29628 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
PowerBarColour:
  LD A,(PowerLevel)
  INC A
  INC A

; Write A into a 2 x 2 patch at HL
;
; Witness: L1 29648 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
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

; A power pod: PowerCount $A018 counts, every few the PowerLevel + 1 up to 6,
; the bar redrawn, the fire faster
;
; Witness: L1 206 (p1-room30, rzx-p1- x27).
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

; Weapon = the best one held (WeaponRank $A06E), WeaponIcon updated
;
; Witness: L1 108 (p1-room24, rzx-p1- x15).
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
; Witness: L1 1957 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
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
; Witness: L1 42 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston,
; p1-room24, p1-room30, rzx-p1- x18).
LosePower:
  LD B,$02
LosePowerDo:
  PUSH BC
  LD A,$32
  CALL PowerDrain
  POP BC
  DJNZ LosePowerDo
  RET

; Weapon 0, PowerLevel 1, the bar's pointer, WeaponRank 0
;
; Witness: L1 9 (c1, p1-code, p1-cursor, p1-define, p1-kempston, rzx-p1-00000,
; rzx-p1-64000).
ResetPower:
  XOR A
  LD (WeaponRank),A
  LD (Weapon),A
  LD A,$01
  LD (PowerLevel),A
  LD HL,$5801
  LD (PowerBarPtr),HL
  RET
