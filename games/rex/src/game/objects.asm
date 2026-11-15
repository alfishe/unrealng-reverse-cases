; --------------------------------------------------------------------------------------------------------------------
; objects.asm: The objects: the enemies, the pods, their moves, their shots, the explosions
;
; A room holds up to 31 objects in records of 24 bytes at ObjectTable $5E66 (ObjectCount $A092): +0 X, +1 Y, +2
; direction (0 right), +3 falling, +4/+5 picture (or the swing gun's angle picture), +6 fall speed, +9 kind (bit 7: a
; variant), +$0A/+$0B frame list, +$0C alive, +$0D/+$0E/+$0F size, +$10 speed, +$11/+$12 timers, +$13, +$14 score,
; +$15 a pod's extra, +$16/+$17 the picture base. UpdateObjects walks them: draw (DrawObject $BAD0), the kind's own
; behaviour, then the walk, fall and jump common to the walkers, then the collision with Rex (ObjectHitsRex $D215).
;
; The kinds (the menu's roll call names ten of them): 0 foot man, 1 stomper, 2-7 walkers and people (4, 5, 6, 7 count
; as humans), 8 scanner, 9 swing gun (a turret that fires in 8 angles), 10 shooters (two shots at once), 11 launcher,
; 12 ramming pod, 13 mine layer (drops mines), 14 mine, 15 blob, 16 the big gun; $FE a power pod, $FD a bomb pod, $FC
; the bonus pod, $FF the points sign. A killed enemy explodes into six shards (BlowUp $BD6B, the border clicks) and
; may leave a pod.
; --------------------------------------------------------------------------------------------------------------------

  ORG $BA5C

; Update every object of the room (falls into UpdateObject)
;
; Witness: L1 16932 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
UpdateObjects:
  LD IX,$5E66
  LD A,(ObjectCount)
  LD B,A

; One object at IX: skip a dead one; pick its picture (exploding: $6018); draw
; it; its behaviour
;
; Witness: L1 182219 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
UpdateObject:
  PUSH BC
  LD A,(IX+$0C)
  OR A
  JP Z,NextObject
  LD A,(IX+$09)
  AND $7F
  OR A
  JP NZ,DrawObject
  LD HL,Sprites
  LD A,(IX+$03)
  OR A
  JP NZ,ObjectExploding
  LD A,(IX+$06)
  OR A
  JP Z,ObjectPicture
ObjectExploding:
  LD HL,DevLinkStub       ; the explosion picture $6018
ObjectPicture:
  LD (IX+$16),L
  LD (IX+$17),H
  LD A,(IX+$12)
  CP $02
  JP Z,DrawObject
  BIT 7,(IX+$09)
  JP Z,ObjectShoot
  CALL Random
  CP $F0
  JP C,DrawObject
  JP ObjectShootSlot
ObjectShoot:
  CALL Random             ; a random shot
  CP $FE
  JP C,DrawObject
ObjectShootSlot:
  CALL FindEnemySlot
  LD A,(IX+$00)
  LD (Temp1),A
  XOR A
  LD (EnemyShotKind),A
  LD A,$0E
  BIT 7,(IX+$09)
  JP Z,ObjectShootDo
  LD A,$11
ObjectShootDo:
  CALL EnemyShot
  LD (IY+$05),$00

; Draw the object at IX (SpriteX/Y, size, mirror, picture, frame list) and
; dispatch: exploding, ramming turn, shooting kinds
;
; Witness: L1 77347 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
DrawObject:
  LD A,(IX+$00)
  LD (SpriteX),A
  LD A,(IX+$01)
  LD (SpriteY),A
  LD A,(IX+$0E)
  LD (SpriteWidth),A
  LD A,(IX+$0F)
  LD (SpriteHeight),A
  LD A,(IX+$09)
  LD (SpriteMirror),A
  LD L,(IX+$04)
  LD H,(IX+$05)
  LD (SpritePicture),HL
  LD L,(IX+$0A)
  LD H,(IX+$0B)
  LD E,(IX+$16)
  LD D,(IX+$17)
  LD A,(IX+$09)
  AND $7F
  CP $01
  JP Z,DrawObjectPlain
  CP $08
  JP NZ,DrawObjectMirror
DrawObjectPlain:
  XOR A
  JP DrawObjectDo
DrawObjectMirror:
  LD A,(IX+$02)
DrawObjectDo:
  CALL DrawSprite
  CALL JumperTimer
  CALL MaybeJumper
  LD A,(IX+$09)
  CP $FF
  JP Z,BlowUp
  CP $06
  JP Z,RamTurn
  CP $05
  JP Z,ShootForward
  CP $04
  JP Z,ShootBoth

; By kind: the power pod's frames, the swing gun, the shooters, the launcher,
; the big gun; else walk, fall, jump, the grid cell and the walk kinds' moves
;
; Witness: L1 73519 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
ObjectBehaviour:
  LD A,(IX+$09)
  CP $FE
  CALL Z,AnimatePod
  LD A,(IX+$09)
  AND $7F
  CP $09
  JP Z,SwingGun
  CP $0A
  JP Z,ShootersFire
  CP $0B
  JP Z,LauncherFire
  CP $10
  JP Z,BigGun
  CALL ObjectJump
  CALL ObjectFall
  CALL ObjectCell
  CALL ObjectMove

; ObjectHitsRex for the object at IX
;
; Witness: L1 73516 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
ObjectCollide:
  CALL ObjectHitsRex

; The next object record (24 bytes on), until all are done
;
; Witness: L1 182217 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
NextObject:
  LD DE,$0018
  ADD IX,DE
  POP BC
  DEC B
  JP NZ,UpdateObject
  RET

; Kind 16: hangs above line $90; at random fires shots and drops a mine
; (DropMine $C1F4)
;
; Witness: L1 814 (rzx-p1-22000, rzx-p1-24000).
BigGun:
  LD A,(IX+$01)
  CP $90
  JP NC,BigGunBelow
  LD A,(IX+$11)
  OR A
  JP NZ,BigGunMove
  LD A,(IX+$13)
  OR A
  JP NZ,BigGunMove
  CALL Random
  CP $F0
  JP C,BigGunMove
  LD A,(IX+$00)
  ADD A,$08
  LD (Temp1),A
  LD A,(IX+$01)
  ADD A,$30
  LD (Temp2),A
  CALL DropMine
BigGunMove:
  LD A,R
  AND $0F
  OR A
  JP NZ,BigGunBelow
  LD HL,BigGunShots
  LD A,(IX+$12)
  CP $01
  JP NZ,BigGunShot
  LD HL,BigGunShots+$0003
BigGunShot:
  PUSH HL
  CALL FindEnemySlot
  POP HL
  LD A,(IX+$00)
  ADD A,$20
  LD (Temp1),A
  LD A,(HL)
  CP $FF
  JP Z,BigGunBelow
  PUSH HL
  CALL EnemyShot
  POP HL
  INC HL
  LD (IY+$0B),$00
  JP BigGunShot
BigGunBelow:
  LD A,(IX+$11)           ; below line $90
  OR A
  JP Z,BigGunUp
  JP BigGunDown
BigGunUp:
  LD A,(IX+$01)
  SUB (IX+$12)
  LD (IX+$01),A
  CP $40
  JP NC,ObjectCollide
  LD (IX+$11),$01
  JP ObjectCollide
BigGunDown:
  LD A,(IX+$01)
  ADD A,(IX+$12)
  LD (IX+$01),A
  CP $78
  JP C,ObjectCollide
  LD (IX+$11),$00
  JP ObjectCollide

; A walker's random shot forward (1 in 16)
;
; Witness: L1 507 (c1, rzx-p1-04000, rzx-p1-06000, rzx-p1-08000, rzx-p1-12000).
ShootForward:
  CALL Random
  CP $F0
  JP C,ObjectBehaviour
  CALL FindEnemySlot
  LD A,(IX+$00)
  LD (Temp1),A
  XOR A
  LD (EnemyShotKind),A
  LD A,$0F
  CALL EnemyShot
  LD (IY+$05),$00
  JP ObjectBehaviour

; A random pair of shots, one each way
;
; Witness: L1 444 (c1, rzx-p1- x5).
ShootBoth:
  CALL Random
  CP $F0
  JP C,ObjectBehaviour
  CALL FindEnemySlot
  LD (IX+$02),$00
  LD A,(IX+$00)
  LD (Temp1),A
  XOR A
  LD (EnemyShotKind),A
  LD A,$0E
  CALL EnemyShot
  LD (IY+$05),$00
  CALL FindEnemySlot
  LD A,$10
  CALL EnemyShot
  LD (IY+$05),$00
  LD (IX+$02),$01
  JP ObjectBehaviour

; Kind 11, the launcher: every few passes a shot that climbs (type $87)
;
; Witness: L1 2885 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston,
; p1-room14, p1-room24, p1-room26, p1-room30, rzx-p1- x16).
LauncherFire:
  CALL Random2
  CP $64
  JP C,ObjectCollide
  DEC (IX+$11)
  JP NZ,ObjectCollide
  LD A,(IX+$12)
  LD (IX+$11),A
  CALL FindEnemySlot
  LD A,(IX+$00)
  LD (Temp1),A
  LD A,$08
  CALL EnemyShot
  LD (IY+$0B),$87
  LD (IY+$0C),$00
  JP ObjectCollide

; Kind 10, the shooters: every few passes two shots, right and left
;
; Witness: L1 3386 (c1, p1-room14, p1-room24, p1-room26, p1-room30, rzx-p1-
; x17).
ShootersFire:
  CALL Random
  CP $64
  JP C,ObjectCollide
  DEC (IX+$11)
  JP NZ,ObjectCollide
  LD A,(IX+$12)
  LD (IX+$11),A
  CALL FindEnemySlot
  XOR A
  LD (Temp3),A
  LD A,(IX+$00)
  CALL ShootFromObject
  CALL FindEnemySlot
  LD A,$01
  LD (Temp3),A
  LD A,(IX+$00)
  SUB $08
  CALL ShootFromObject
  JP ObjectCollide

; A shot from IX at X A, Y IX+1, speed 15
;
; Witness: L1 178 (c1, p1-room14, p1-room24, p1-room26, p1-room30, rzx-p1-
; x13).
ShootFromObject:
  LD (Temp1),A
  LD A,$0F
  LD (Temp4),A
  LD A,(IX+$01)
  LD (Temp2),A
  XOR A
  CALL SetupShot
  LD (IY+$05),$00
  RET

; Kind 9, the swing gun: its angle picture (SwingGunFrames $BECB), at random a
; shot in its angle's direction
;
; Witness: L1 9826 (c1, p1-cursor, p1-kempston, p1-room26, p1-room27,
; p1-room30, rzx-p1- x22).
SwingGun:
  LD E,(IX+$11)
  LD D,$00
  LD HL,SwingGunFrames
  ADD HL,DE
  LD E,(HL)
  LD D,$00
  LD HL,SpriteSwingGun
  ADD HL,DE
  LD (IX+$04),L
  LD (IX+$05),H
  LD A,(IX+$12)
  OR A
  JP Z,SwingGunFire
  CALL Random
  CP $14
  JP NC,SwingGunTurn
SwingGunFire:
  LD A,$04
  LD (EnemyShotKind),A
  CALL FindEnemySlot
  LD A,(IX+$11)
  OR A
  CALL Z,SwingShotUpLeft
  CP $01
  CALL Z,SwingShotLeft
  CP $03
  CALL Z,SwingShotRight
  CP $04
  CALL Z,SwingShotUpRight
  CP $05
  CALL Z,SwingShotRight
  CP $07
  CALL Z,SwingShotLeft
SwingGunTurn:
  LD A,(IX+$12)
  OR A
  JP NZ,ObjectCollide
  LD A,(IX+$11)
  INC A
  LD (IX+$11),A
  CP $08
  JP NZ,ObjectCollide
  LD (IX+$11),$00
  JP ObjectCollide

; The ramming pod's turn: the turning pictures, then kind 7 again
;
; Witness: L1 382 (p1-room30, rzx-p1- x18).
RamTurn:
  LD A,(IX+$11)
  CP $04
  JP NZ,RamTurnCount
  LD HL,ShiftFrames6
  LD (IX+$0A),L
  LD (IX+$0B),H
  LD HL,SpriteRamTurn
  LD (IX+$16),L
  LD (IX+$17),H
RamTurnCount:
  DEC (IX+$11)
  JP NZ,ObjectBehaviour
  LD (IX+$09),$07
  JP ObjectBehaviour

; An object explodes: the six shards drawn (DrawShard), the attribute flash; at
; the end it leaves a pod or the points
;
; Witness: L1 3827 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room24, p1-room30, rzx-p1- x32).
BlowUp:
  LD HL,ShardPaths
  CALL DrawShard
  LD HL,ShardPaths+$0010
  CALL DrawShard
  LD HL,ShardPaths+$0020
  CALL DrawShard
  LD HL,ShardPaths+$0030
  CALL DrawShard
  LD HL,ShardPaths+$0040
  CALL DrawShard
  LD HL,ShardPaths+$0050
  CALL DrawShard
  INC (IX+$03)
  LD A,(IX+$00)
  LD (SpriteX),A
  LD A,(IX+$01)
  LD (SpriteY),A
  CALL FlashCells
  LD L,(IX+$04)
  LD H,(IX+$05)
  LD DE,$0048
  ADD HL,DE
  LD (IX+$04),L
  LD (IX+$05),H
  DEC (IX+$0D)
  JP NZ,NextObject
  LD HL,(Temp1)
  LD DE,(Temp2)
  CALL CopyCells3
  LD A,(IX+$00)
  CP $18
  JP C,BlowUpEnd
  LD (IX+$09),$FE
  LD (IX+$0F),$10
  LD (IX+$0E),$02
  LD A,(IX+$01)
  ADD A,$08
  LD (IX+$01),A
  LD (IX+$03),$00
  LD (IX+$06),$00
  LD (IX+$11),$64
  LD (IX+$10),$00
  LD HL,SpritePodA
  LD (IX+$12),L
  LD (IX+$13),H
  LD (IX+$04),L
  LD (IX+$05),H
  LD A,(IX+$15)
  CP $FF
  JP Z,BlowUpEnd
  CALL Random
  CP $03
  JP C,BlowUpBombPod
  CP $06
  JP C,BlowUpBonusPod
  LD A,(IX+$15)
  OR A
  JP NZ,NextObject
  LD HL,SpritePodB
  LD (IX+$12),L
  LD (IX+$13),H
  LD (IX+$11),$8C
  LD (IX+$04),L
  LD (IX+$05),H
  JP NextObject
BlowUpEnd:
  LD (IX+$0C),$00         ; the explosion over
  JP NextObject
BlowUpBombPod:
  LD (IX+$09),$FD         ; leaves a bomb pod
  LD HL,SpriteBonusPod
  JP BlowUpPodPicture
BlowUpBonusPod:
  LD (IX+$09),$FC         ; leaves the bonus pod
  LD HL,SpriteBonusPod2
BlowUpPodPicture:
  LD (IX+$04),L
  LD (IX+$05),H
  LD (IX+$02),$01
  JP NextObject

; The big gun's shot timings: $10, $20, $22, $19, $1D, $31, $34, $FF
BigGunShots:
  DEFB $10,$20,$22,$19,$1D,$31,$34,$FF

; A swing gun shot up and left
;
; Witness: L1 508 (p1-room26, p1-room27, p1-room30, rzx-p1- x17).
SwingShotUpLeft:
  PUSH AF
  LD A,(IX+$00)
  SUB $18
  LD (Temp1),A
  LD A,$14
  CALL EnemyShot
  LD HL,$FFFF
  LD (IY+$04),$F8
  LD A,$05
  JP SwingShotSet

; A swing gun shot left
;
; Witness: L1 899 (c1, p1-cursor, p1-kempston, p1-room26, p1-room27, p1-room30,
; rzx-p1- x20).
SwingShotLeft:
  PUSH AF
  LD A,(IX+$00)
  SUB $18
  LD (Temp1),A
  LD A,$19
  CALL EnemyShot
  LD HL,$FFFF
  LD (IY+$04),$F8
  LD A,$08

; The shot's dX (HL) and speed
;
; Witness: L1 2526 (c1, p1-cursor, p1-kempston, p1-room26, p1-room27,
; p1-room30, rzx-p1- x22).
SwingShotSet:
  LD (IY+$07),L
  LD (IY+$08),H
  LD (IY+$05),$00
  CALL SetShotSpeed
  POP AF
  RET

; A swing gun shot right
;
; Witness: L1 736 (c1, p1-cursor, p1-kempston, p1-room26, p1-room27, p1-room30,
; rzx-p1- x19).
SwingShotRight:
  PUSH AF
  LD A,(IX+$00)
  LD (Temp1),A
  LD A,$19
  CALL EnemyShot
  LD HL,$0001
  LD (IY+$04),$08
  LD A,$08
  JP SwingShotSet

; A swing gun shot up and right
;
; Witness: L1 383 (c1, p1-cursor, p1-kempston, p1-room26, p1-room27, p1-room30,
; rzx-p1- x16).
SwingShotUpRight:
  PUSH AF
  LD A,(IX+$00)
  LD (Temp1),A
  LD A,$14
  CALL EnemyShot
  LD HL,$0001
  LD (IY+$04),$08
  LD A,$05
  JP SwingShotSet

; The swing gun's picture offsets by angle: $00, $20, $40, $60, $80, $60, $40,
; $20
SwingGunFrames:
  DEFB $00,$20,$40,$60,$80,$60,$40,$20

; The power pod's frames (PodFrames $BF5B); a pod not taken in time goes
;
; Witness: L1 17077 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room24, p1-room30, rzx-p1- x30).
AnimatePod:
  LD A,(IX+$10)
  INC A
  LD (IX+$10),A
  LD E,A
  LD D,$00
  LD HL,PodFrames
  ADD HL,DE
  LD A,(HL)
  CP $FF
  JP NZ,PodFrame
  LD (IX+$10),$01
  XOR A
PodFrame:
  LD E,A
  LD D,$00
  LD L,(IX+$12)
  LD H,(IX+$13)
  ADD HL,DE
  LD A,(IX+$06)
  OR A
  JP NZ,PodPicture
  LD A,(IX+$11)
  CP $14
  JP C,PodTimer
  JP PodSet
PodTimer:
  LD A,(IX+$11)
  CP $02
  JP Z,PodFrame3
  CP $03
  JP Z,PodFrame2
  CP $04
  JP Z,PodFrame1
  CP $05
  JP Z,PodFrame0
  LD A,(IX+$10)
  CP $02
  JP NZ,PodSet
  DEC (IX+$10)
PodPicture:
  LD L,(IX+$12)
  LD H,(IX+$13)
  LD DE,$0040
  ADD HL,DE
PodSet:
  LD (IX+$04),L
  LD (IX+$05),H
  DEC (IX+$11)
  RET NZ
  LD (IX+$0C),$00
  RET
PodFrame0:
  LD HL,SpritePowerPod
  JP PodSet
PodFrame1:
  LD HL,SpritePowerPod+$0020
  JP PodSet
PodFrame2:
  LD HL,SpritePowerPod+$0040
  JP PodSet
PodFrame3:
  LD HL,SpritePowerPod+$0060
  JP PodSet

; The pod's frame offsets: $00-$A0 and back, $FF
PodFrames:
  DEFB $00,$20,$40,$60,$80,$A0,$80,$60,$40,$20,$FF

; One shard of an explosion along its path at HL: the border's speaker bit
; random (the explosion's crackle), the shard ORed into the buffer
;
; Witness: L1 22962 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room24, p1-room30, rzx-p1- x32).
DrawShard:
  LD A,R
  SLA A
  AND $F8
  OUT ($FE),A
  LD A,(IX+$03)
  SLA A
  LD (Temp1),A
  LD E,A
  LD D,$00
  ADD HL,DE
  LD A,(IX+$00)
  SRL A
  SRL A
  SRL A
  ADD A,(HL)
  SUB $07
  CP $01
  JP C,ShardOff
  CP $1E
  JP NC,ShardOff
ShardX:
  LD (SpriteX),A
  INC HL
  LD A,(HL)
  ADD A,(IX+$01)
  SUB $30
  CP $08
  JP C,ShardDraw
  CP $A0
  JP NC,ShardDraw
ShardY:
  LD (SpriteY),A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,(SpriteX)
  LD E,A
  LD D,$00
  ADD HL,DE
  LD DE,BufferPlayOrigin
  ADD HL,DE
  PUSH HL
  LD A,(Temp1)
  SLA A
  SLA A
  LD E,A
  LD D,$00
  LD HL,ShardPictures
  ADD HL,DE
  EX DE,HL
  POP HL
  CALL OrChar
  RET
ShardOff:
  XOR A                   ; off the play area
  LD (SpriteX),A
  LD A,$20
  LD (SpriteY),A
  JP ShardX
ShardDraw:
  LD A,$20
  LD (SpriteY),A
  XOR A
  LD (SpriteX),A
  JP ShardY

; The attributes of the explosion's flash: $02, $03, $06, $42, $43, $46, $06,
; $02
FlashAttrs:
  DEFB $02,$03,$06,$42,$43,$46,$06,$02

; The kinds' moves: pods none; 8 scanner, 12/13 the ground walkers, 14 the
; mine, 15 the blob, 2 the mine layer's burst; the others walk right or left
;
; Witness: L1 56609 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
ObjectMove:
  LD A,(IX+$09)
  CP $FE
  RET Z
  CP $FD
  RET Z
  CP $FC
  RET Z
  AND $7F
  CP $08
  JP Z,Scanner
  CP $0C
  JP Z,GroundWalker
  CP $0D
  JP Z,GroundWalker
  CP $0E
  JP Z,Blob
  CP $0F
  JP Z,Mine
  CP $02
  JP Z,ObjectMoveBurst
  OR A
  JP NZ,ObjectMoveWalk
ObjectMoveWalk:
  LD A,(IX+$02)           ; walk right or left
  OR A
  JP Z,WalkRight
  JP WalkLeft
ObjectMoveBurst:
  XOR A                   ; kind 2: the burst
  LD (IX+$02),A
  LD A,(RexX)
  CP (IX+$00)
  RET NC
  LD A,$01
  LD (IX+$02),A
  RET

; At random (1 in 7) a burst of 8 shots in the spray's directions
;
; Witness: L1 21 (rzx-p1-04000, rzx-p1-18000, rzx-p1-20000, rzx-p1-56000).
MineBurst:
  CALL Random
  CP $23
  RET NC
  LD A,$04
  LD (EnemyShotKind),A
  LD HL,SprayDirections
  LD B,$08
MineBurstLoop:
  PUSH BC                 ; each shot
  PUSH HL
  CALL FindEnemySlot
  CALL EnemyShotFrom
  POP HL
  CALL SetShotDirection
  POP BC
  DJNZ MineBurstLoop
  RET

; Kinds 12 and 13: rise by the speed until a solid cell above
;
; Witness: L1 3987 (p1-code, p1-gameover, p1-room30, rzx-p1- x16).
Climb:
  LD A,(IX+$11)
  OR A
  JP NZ,ClimbStep
  LD A,(IX+$01)
  SUB (IX+$12)
  LD (IX+$01),A
  CALL ObjectCell
  LD DE,$0040
  AND A
  SBC HL,DE
  CALL IsSolid
  JP Z,ClimbDown
  INC HL
  CALL IsSolid
  JP Z,ClimbDown
ClimbBlocked:
  JP Z,ClimbStep
  LD A,(IX+$01)
  CP $18
  JP C,ClimbDown
  CP $A8
  JP NC,ClimbUp
  CALL Random
  CP $07
  JP C,ClimbTurn
  LD A,(IX+$09)
  CP $0D
  RET Z
  LD A,(IX+$12)
  INC A
  CP $05
  RET Z
  LD (IX+$12),A
  RET
ClimbTurn:
  LD A,(IX+$02)
  XOR $01
  LD (IX+$02),A
  RET
ClimbUp:
  LD (IX+$11),$00
  LD (IX+$12),$01
  RET
ClimbDown:
  LD (IX+$11),$01
  LD (IX+$12),$01
  RET
ClimbStep:
  LD A,(IX+$01)
  ADD A,(IX+$12)
  LD (IX+$01),A
  CALL ObjectCell
  CALL IsSolid
  JP Z,ClimbUp
  INC HL
  CALL IsSolid
  JP Z,ClimbUp
  JP ClimbBlocked

; A flyer's step: inside the play area move by its speed; at an edge turn
;
; Witness: L1 7555 (p1-room14, p1-room24, p1-room26, rzx-p1- x7).
FlyBounce:
  LD A,(IX+$01)
  CP $A0
  JP NC,FlyTurn
  CP $10
  JP C,FlyTurn
  LD A,(IX+$00)
  CP $F0
  JP NC,FlyTurn
  CP $10
  JP C,FlyTurn
  LD A,(IX+$00)
  ADD A,(IX+$04)
  LD (SpriteX),A
  LD A,(IX+$01)
  ADD A,(IX+$05)
  LD (SpriteY),A
  LD A,(IX+$02)
  CALL CellPointer
  LD DE,$0021
  ADD HL,DE
  LD A,(HL)
  OR A
  RET Z
FlyTurn:
  LD A,(IX+$04)           ; at an edge: turn
  NEG
  LD (IX+$04),A
  LD A,(IX+$05)
  NEG
  LD (IX+$05),A
  LD (IX+$11),$04
  RET

; A random direction: dX and dY each +1 or -1
;
; Witness: L1 526 (p1-room14, p1-room24, p1-room26, rzx-p1- x7).
RandomFlight:
  CALL RandomSign
  LD (IX+$04),A
  CALL RandomSign
  LD (IX+$05),A
  RET

; A = +1 or -1 at random (Signs $C149)
;
; Witness: L1 1052 (p1-room14, p1-room24, p1-room26, rzx-p1- x7).
RandomSign:
  CALL Random2
  AND $01
  LD E,A
  LD D,$00
  LD HL,Signs
  ADD HL,DE
  LD A,(HL)
  RET

; $FF, $01, $FF, $01
Signs:
  DEFB $FF,$01,$FF,$01

; Kind 15's first step: FlyBounce, then Blob
;
; Witness: L1 7555 (p1-room14, p1-room24, p1-room26, rzx-p1- x7).
Mine:
  CALL FlyBounce

; Kinds 14 and 15: drift by dX, dY; a solid cell turns it, or kills a mine
;
; Witness: L1 12652 (p1-code, p1-room14, p1-room24, p1-room26, p1-room30,
; rzx-p1- x16).
Blob:
  LD A,(IX+$00)
  ADD A,(IX+$04)
  LD (IX+$00),A
  LD A,(IX+$01)
  ADD A,(IX+$05)
  LD (IX+$01),A
  LD A,(IX+$09)
  CP $0F
  JP Z,BlobTimer
  LD HL,(ObjectCellPtr)
  LD DE,$0020
  AND A
  SBC HL,DE
  CALL IsSolid
  JP Z,KillObject
BlobTimer:
  DEC (IX+$11)
  RET NZ
  LD A,R
  AND $03
  ADD A,$02
  LD (IX+$11),A
  LD A,(IX+$09)
  CP $0F
  JP Z,BlobRandom
  LD A,(IX+$12)
  XOR $01
  LD (IX+$12),A
  OR A
  RET Z
BlobRandom:
  LD A,R
  AND $07
  ADD A,$08
  LD (IX+$11),A
  LD A,(IX+$09)
  CP $0F
  JP Z,RandomFlight
  LD (IX+$04),$01
  LD A,(RexX)
  CP (IX+$00)
  JP NC,BlobDown
  LD (IX+$04),$FF
BlobDown:
  LD (IX+$05),$01
  LD A,(RexY)
  CP (IX+$01)
  RET NC
  LD (IX+$05),$FF
  RET

; Kinds 12 and 13: walk right or left; the mine layer drops a mine at random
;
; Witness: L1 3987 (p1-code, p1-gameover, p1-room30, rzx-p1- x16).
GroundWalker:
  LD A,(IX+$02)
  OR A
  CALL Z,WalkRight
  LD A,(IX+$02)
  OR A
  CALL NZ,WalkLeft
  LD A,(IX+$09)
  CP $0D
  RET NZ
  CALL Random
  CP $F0
  RET C
  LD A,(IX+$00)
  ADD A,$08
  LD (Temp1),A
  LD A,(IX+$01)
  ADD A,$04
  LD (Temp2),A

; Make a mine (kind 14) at Temp1, Temp2 in a free object record
;
; Witness: L1 158 (p1-code, p1-room30, rzx-p1- x10).
DropMine:
  PUSH IX
  CALL FindFreeObject
  CALL InitKind14
  LD (IX+$09),$0E
  LD (IX+$0C),$01
  LD A,(Temp1)
  LD (IX+$00),A
  LD A,(Temp2)
  LD (IX+$01),A
  POP IX
  RET

; Kind 8 moving up: its timer steps, then the turn
;
; Witness: L1 917 (p1-room30, rzx-p1- x5).
ScannerUp:
  LD A,(IX+$11)
  CP $02
  RET NZ
  DEC (IX+$12)
  JP Z,ScannerTurn
  LD A,(IX+$01)
  SUB (IX+$10)
  LD (IX+$01),A
  LD L,(IX+$04)
  LD H,(IX+$05)
  LD DE,$0020
  ADD HL,DE
  LD (IX+$04),L
  LD (IX+$05),H
  RET
; This entry point is used by the routine at Scanner.
ScannerUpStep:
  DEC (IX+$12)
  JP Z,ScannerTurn
  LD A,(IX+$13)
  AND $0F
  SLA A
  LD E,A
  LD D,$00
  LD HL,ScannerFrames
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (IX+$04),E
  LD (IX+$05),D
  INC (IX+$13)
  RET

; The scanner's picture words: $8A5A, $8B1A, $8B3A, repeated
ScannerFrames:
  DEFB $5A,$8A,$1A,$8B,$3A,$8B
  DEFB $5A,$8A,$1A,$8B,$3A,$8B
  DEFB $5A,$8A,$1A,$8B,$3A,$8B
  DEFB $5A,$8A,$1A,$8B,$3A,$8B
  DEFB $5A,$8A,$1A,$8B,$3A,$8B
  DEFB $5A,$8A,$1A,$8B,$3A,$8B

; Kind 8: stalks Rex, rising and sinking at his height; walks his way when he
; stands
;
; Witness: L1 917 (p1-room30, rzx-p1- x5).
Scanner:
  LD A,(IX+$00)
  AND $07
  OR A
  JP NZ,ScannerMove
  LD A,(Jumping)
  OR A
  JP NZ,ScannerHeight
  LD A,(FallSpeed)
  OR A
  JP NZ,ScannerHeight
  CALL ReadRight
  JP Z,ScannerHeight
  CALL ReadLeft
  JP Z,ScannerHeight
  JP ScannerMove
ScannerHeight:
  LD A,(RexY)             ; level with Rex?
  ADD A,$04
  CP (IX+$01)
  JP C,ScannerSide
  SUB $10
  CP (IX+$01)
  JP NC,ScannerSide
  CALL ScannerReset
  LD (IX+$12),$14
  CALL MineBurst
ScannerSide:
  LD A,(RexX)             ; his side
  ADD A,$04
  CP (IX+$00)
  JP C,ScannerMove
  SUB $10
  CP (IX+$00)
  JP NC,ScannerMove
  CALL ScannerReset
  LD (IX+$12),$14
  CALL MineBurst
ScannerMove:
  LD A,(IX+$11)
  CP $03
  JP Z,ScannerUpStep
  OR A
  RET NZ
  LD A,(IX+$02)
  OR A
  CALL Z,WalkRight
  LD A,(IX+$02)
  OR A
  CALL NZ,WalkLeft
  DEC (IX+$12)
  JP Z,ScannerTurn
  RET

; Kind 8 moving down
;
; Witness: L1 917 (p1-room30, rzx-p1- x5).
ScannerDown:
  LD A,(IX+$11)
  CP $01
  RET NZ
  DEC (IX+$12)
  JP Z,ScannerTurn
  LD A,(IX+$01)
  ADD A,(IX+$10)
  LD (IX+$01),A
  RET

; Kind 8 at a cell edge: its next direction from the grid round it
;
; Witness: L1 109 (p1-room30, rzx-p1- x5).
ScannerTurn:
  LD (IX+$12),$07
  LD A,(IX+$00)
  AND $07
  OR A
  RET NZ
  RES 7,(IX+$09)
  LD (IX+$0F),$0B
  LD A,(IX+$00)
  LD (SpriteX),A
  LD A,(IX+$01)
  CP $18
  JP C,ScannerTop
  CP $A0
  JP NC,ScannerBottom
  LD (SpriteY),A
  LD A,(IX+$02)
  CALL CellPointer
  INC HL
  CALL IsSolid
  JP Z,ScannerTop
  INC HL
  CALL IsSolid
  JP Z,ScannerTop
  LD DE,$0060
  ADD HL,DE
  CALL IsSolid
  JP Z,ScannerBottom
  DEC HL
  CALL IsSolid
  JP Z,ScannerBottom
  LD A,R
  AND $03
  CP $00
  JP Z,ScannerTop
  CP $01
  JP Z,ScannerGoDown
  CP $02
  JP Z,ScannerGoUp
  JP ScannerBottom
ScannerGoUp:
  LD (IX+$12),$08
  LD A,(IX+$11)
  LD (IX+$11),$00
  LD (IX+$02),$01
  RET
ScannerGoDown:
  LD (IX+$12),$08
  LD A,(IX+$11)
  LD (IX+$11),$00
  LD (IX+$02),$00
  RET
ScannerTop:
  LD (IX+$12),$07         ; at the top
  LD (IX+$11),$01
  RET
ScannerBottom:
  LD (IX+$02),$00         ; at the bottom
  LD (IX+$12),$06
  LD (IX+$0F),$10
  LD (IX+$11),$02
  LD HL,SpriteScanner
  LD (IX+$04),L
  LD (IX+$05),H
  SET 7,(IX+$09)
  RET

; Kind 8's start state
;
; Witness: L1 21 (rzx-p1-04000, rzx-p1-18000, rzx-p1-20000, rzx-p1-56000).
ScannerReset:
  LD (IX+$02),$00
  LD (IX+$12),$11
  LD (IX+$0F),$10
  LD (IX+$11),$03
  LD (IX+$13),$00
  LD HL,SpriteScanner
  LD (IX+$04),L
  LD (IX+$05),H
  SET 7,(IX+$09)
  RET

; A walker's step right: a solid cell ahead turns it (or kills a person, or
; stops the jumper)
;
; Witness: L1 10523 (p1-code, p1-gameover, p1-room x5, rzx-p1- x29).
WalkRight:
  LD HL,(ObjectCellPtr)
  LD DE,$0040
  AND A
  SBC HL,DE
  INC HL
  INC HL
  CALL IsSolid
  JP Z,BlockedRight
  LD DE,$0020
  ADD HL,DE
  CALL IsSolid
  JP Z,BlockedRight
  LD A,(IX+$09)
  OR A
  JP Z,WalkRightStep
  LD A,(IX+$00)
  ADD A,(IX+$10)
  CP $E8
  JP NC,EdgeLeft
  JP WalkRightStore
WalkRightStep:
  LD A,(IX+$00)
  ADD A,(IX+$10)
  CP $F8
  JP NC,EdgeLeft
WalkRightStore:
  LD (IX+$00),A
  LD (IX+$02),$00
  LD A,(IX+$03)
  OR A
  RET NZ
  LD A,(IX+$06)
  OR A
  RET NZ
  LD A,(IX+$09)
  OR A
  JP NZ,WalkRightFloor
  LD HL,(ObjectCellPtr)
  LD DE,$001F
  AND A
  SBC HL,DE
  LD A,(HL)
  CP $0F
  JP Z,StartFall
  CP $0E
  JP Z,HopTimer
  CP $10
  CALL Z,MaybeJumpRight
  CP $11
  CALL Z,MaybeJumpLeft
WalkRightFloor:
  LD HL,(ObjectCellPtr)   ; the floor ahead
  INC HL
  INC HL
  LD A,(HL)
  OR A
  RET NZ
  LD A,(IX+$09)
  AND $7F
  OR A
  RET Z
  CP $08
  RET Z
  CP $0C
  RET Z
  CP $0D
  RET Z

; Blocked: kinds 6 and 7 stay, the others turn
;
; Witness: L1 273 (p1-code, p1-room14, p1-room24, p1-room30, rzx-p1- x28).
BlockedRight:
  LD A,(IX+$09)
  CP $07
  RET Z
  CP $06
  RET Z

; Direction ^ 1
;
; Witness: L1 278 (p1-code, p1-room14, p1-room24, p1-room30, rzx-p1- x28).
TurnAround:
  LD A,(IX+$02)
  XOR $01
  LD (IX+$02),A

; Kinds 6 and 7 off the edge die; 3, 4, 5 stop
;
; Witness: L1 476 (p1-code, p1-gameover, p1-room14, p1-room24, p1-room26,
; p1-room30, rzx-p1- x29).
WalkOff:
  LD A,(IX+$09)
  CP $07
  JP Z,KillObject
  CP $06
  JP Z,KillObject
  CP $03
  JP Z,ObjectGone
  CP $04
  JP Z,ObjectGone
  CP $05
  JP Z,ObjectGone
  RET

; The object is dead (alive = 0)
;
; Witness: L1 27 (rzx-p1- x8).
ObjectGone:
  LD (IX+$0C),$00
  RET

; At the left edge: kind 0 dies, the others turn
;
; Witness: L1 80 (p1-code, p1-room30, rzx-p1- x18).
EdgeLeft:
  LD A,(IX+$09)
  OR A
  JP Z,ObjectGone
  JP TurnAround

; A walker's step left
;
; Witness: L1 15127 (c1, p1-code, p1-gameover, p1-room14, p1-room24, p1-room26,
; p1-room30, rzx-p1- x30).
WalkLeft:
  LD HL,(ObjectCellPtr)
  LD DE,$0040
  AND A
  SBC HL,DE
  DEC HL
  CALL IsSolid
  JP Z,WalkLeftBlocked
  LD DE,$0020
  ADD HL,DE
  CALL IsSolid
  JP Z,WalkLeftBlocked
  LD A,(IX+$00)
  SUB (IX+$10)
  CP $E8
  JP NC,EdgeLeft
  LD (IX+$00),A
  LD (IX+$02),$01
  LD A,(IX+$03)
  OR A
  RET NZ
  LD A,(IX+$06)
  OR A
  RET NZ
  LD A,(IX+$09)
  OR A
  JP NZ,WalkLeftFloor
  LD HL,(ObjectCellPtr)
  LD DE,$0020
  AND A
  SBC HL,DE
  LD A,(HL)
  CP $0F
  JP Z,StartFallIfIdle
  CP $0E
  JP Z,HopTimer
  CP $10
  CALL Z,MaybeJumpRight
  CP $11
  CALL Z,MaybeJumpLeft
WalkLeftFloor:
  LD HL,(ObjectCellPtr)
  DEC HL
  LD A,(HL)
  OR A
  RET NZ
  LD A,(IX+$09)
  AND $7F
  OR A
  RET Z
  CP $03
  RET Z
  CP $04
  RET Z
  CP $05
  RET Z
  CP $08
  RET Z
  CP $0C
  RET Z
  CP $0D
  RET Z
WalkLeftBlocked:
  LD A,(IX+$09)
  CP $06
  RET Z
  CP $07
  RET Z
  LD (IX+$02),$00
  JP WalkOff

; At random a jump instead of the step
;
; Witness: L1 226 (p1-room30, rzx-p1- x16).
MaybeJumpRight:
  PUSH AF
  CALL Random
  CP $80
  JP C,StartHop
  LD (IX+$11),$04
  POP AF
  RET

; At random a jump
;
; Witness: L1 297 (rzx-p1- x18).
MaybeJumpLeft:
  CALL Random
  CP $80
  JP C,StartFallIfIdle
  LD (IX+$11),$04
  RET

; A hop: the jumper's picture $8E8A
;
; Witness: L1 113 (p1-room30, rzx-p1- x16).
StartHop:
  POP DE
; This entry point is used by the routines at WalkRight and WalkLeft.
HopTimer:
  LD A,(IX+$11)
  OR A
  RET NZ
  LD HL,SpriteKind6

; The hop's state: picture HL, speed, timers, bit 7 of the kind
;
; Witness: L1 48 (p1-room26, rzx-p1- x18).
SetHop:
  LD (IX+$10),$00
  LD (IX+$04),L
  LD (IX+$05),H
  LD (IX+$0E),$02
  LD (IX+$12),$01
  CALL Random
  AND $0F
  ADD A,$10
  LD (IX+$11),A
  SET 7,(IX+$09)
  RET

; A kind 0 walker at random becomes a jumper (SpriteJumper $91B2)
;
; Witness: L1 77346 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
MaybeJumper:
  LD A,(IX+$09)
  OR A
  RET NZ
  LD A,(IX+$02)
  OR A
  JP NZ,MaybeJumperLeft
  LD A,(IX+$00)
  AND $07
  CP $02
  RET NZ
  JP MaybeJumperRoll
MaybeJumperLeft:
  LD A,(IX+$00)
  AND $07
  CP $04
  RET NZ
MaybeJumperRoll:
  CALL Random
  CP $FA
  RET C
  LD A,(IX+$06)
  OR A
  RET NZ
  LD A,(IX+$03)
  OR A
  RET NZ
  LD A,(IX+$11)
  OR A
  RET NZ
  LD HL,SpriteJumper
  CALL SetHop
  LD (IX+$12),$02
  RET

; The jumper's timer; at its end it walks again
;
; Witness: L1 77346 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
JumperTimer:
  LD A,(IX+$09)
  AND $7F
  OR A
  RET NZ
  LD A,(IX+$12)
  OR A
  JP Z,JumperCount
  LD A,(IX+$11)
  CP $C8
  RET Z
  DEC (IX+$11)
  RET NZ
  LD (IX+$10),$02
  RES 7,(IX+$09)
  LD (IX+$0E),$03
  LD (IX+$11),$09
  LD A,(IX+$12)
  CP $02
  JP NZ,JumperStop
  LD (IX+$11),$01
JumperStop:
  LD (IX+$12),$00
  RET
JumperCount:
  LD A,(IX+$11)
  DEC A
  CP $FF
  RET Z
  LD (IX+$11),A
  RET

; Leftover: RET: RET: RET ($C9 x 3) that no instruction reaches
;
; Known only from the code: JumperTimer $C5B6 ends with its own RET just
; before; no jump, call or table names $C5FA-$C5FC.
ThreeReturns:
  DEFB $C9,$C9,$C9

; If the timer is 0, StartFall
;
; Witness: L1 174 (rzx-p1- x20).
StartFallIfIdle:
  LD A,(IX+$11)
  OR A
  RET NZ

; An object not falling and below line 24 starts to fall (JumpSteps $D0D8)
;
; Witness: L1 156 (p1-room30, rzx-p1- x21).
StartFall:
  LD A,(IX+$06)
  OR A
  RET NZ
  LD A,(IX+$01)
  CP $18
  RET C
  LD A,(IX+$03)
  OR A
  RET NZ
  LD (IX+$03),$01
  LD HL,JumpSteps
  LD (IX+$04),L
  LD (IX+$05),H
  RET

; The jump of a walker by its jump table; kinds 8 and 12/13 their own; a solid
; cell above ends it
;
; Witness: L1 56608 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
ObjectJump:
  LD A,(IX+$09)
  CP $FE
  RET Z
  CP $FD
  RET Z
  CP $FC
  RET Z
  AND $7F
  CP $08
  JP Z,ScannerUp
  CP $0C
  JP Z,Climb
  CP $0D
  JP Z,Climb
  CP $0E
  RET Z
  CP $0F
  RET Z
  LD A,(IX+$03)
  OR A
  RET Z
  LD A,(IX+$00)
  LD (SpriteX),A
  LD A,(IX+$01)
  LD (SpriteY),A
  LD A,(IX+$02)
  CALL CellPointer
  INC HL
  CALL IsSolid
  JP Z,JumpKind
  INC HL
  CALL IsSolid
  JP Z,JumpKind
  LD A,(IX+$01)
  LD L,(IX+$04)
  LD H,(IX+$05)
  LD E,(HL)
  SUB E
  CP $08
  JP C,JumpEnd
  LD (IX+$01),A
  INC HL
  LD (IX+$04),L
  LD (IX+$05),H
  LD A,(HL)
  CP $FF
  RET NZ
  LD (IX+$03),$00
  RET
JumpEnd:
  LD (IX+$03),$00
  LD (IX+$06),$02
  LD A,(IX+$09)
  CP $07
  JP Z,KillObject
  CP $06
  JP Z,KillObject
  RET
JumpKind:
  LD A,(IX+$09)
  CP $07
  JP Z,KillObject
  CP $06
  JP Z,KillObject
  LD (IX+$06),$02
  LD (IX+$03),$00
  LD A,(IX+$01)
  AND $07
  OR A
  RET NZ
  LD (IX+$06),$00
  RET

; The fall: by the fall speed until a solid cell; below line $B8 the object
; dies (a person counts)
;
; Witness: L1 56608 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
ObjectFall:
  LD A,(IX+$09)
  AND $7F
  CP $08
  JP Z,ScannerDown
  CP $0C
  RET Z
  CP $0D
  RET Z
  CP $0E
  RET Z
  CP $0F
  RET Z
  LD A,(IX+$03)
  OR A
  RET NZ
  LD A,(IX+$01)
  ADD A,(IX+$06)
  CP $B8
  JP NC,FallOut
  LD (IX+$01),A
  AND $07
  OR A
  RET NZ
  CALL ObjectCell
  LD A,(HL)
  CALL IsPassable
  JP NZ,FallLand
  INC HL
  LD A,(HL)
  CALL IsPassable
  JP NZ,FallLand
  LD A,(IX+$06)
  ADD A,$02
  CP $06
  RET Z
  LD (IX+$06),A
  RET
FallLand:
  LD (IX+$06),$00         ; landed
  LD A,(IX+$09)
  CP $07
  JP Z,KillObject
  RET
FallOut:
  LD (IX+$0C),$00         ; below the play area: dead
  LD HL,ObjectBufferOrigin
  LD (KillFlashPtr),HL
  LD HL,$0000
  LD (ComboTimer),HL
  RET

; ObjectCellPtr $A01B = the grid cell of the object at IX
;
; Witness: L1 95878 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
ObjectCell:
  LD A,(IX+$00)
  LD (SpriteX),A
  LD A,(IX+$01)
  LD (SpriteY),A
  LD A,(IX+$02)
  CALL CellPointer
  LD DE,$0061
  ADD HL,DE
  LD (ObjectCellPtr),HL
  RET
