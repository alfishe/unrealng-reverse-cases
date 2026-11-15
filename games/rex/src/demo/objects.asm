; --------------------------------------------------------------------------------------------------------------------
; objects.asm: The objects: the enemies, the pods, their moves, their shots, the explosions
; --------------------------------------------------------------------------------------------------------------------

  ORG $C311

; Update every object of the room (falls into UpdateObject)
;
; As REX 1's UpdateObjects $BA5C (src/game/objects.asm).
;
; Witness: L1 6752 (d1, demo-cycle).
UpdateObjects:
  LD IX,ObjectTable
  LD A,(ObjectCount)
  LD B,A

; One object at IX (records of 23 bytes): skip a dead one; draw it (kinds 1 and
; 8 never mirrored); exploding BlowUp, kind 6 its turn, the power pod's frames;
; kinds 9, 10, 11 shoot; else jump, fall, the cell under it and the move; then
; against Rex (ObjectHitsRex)
;
; Changed from REX 1's UpdateObject $BA64 (src/game/objects.asm).
;
; Witness: L1 49655 (d1, demo-cycle).
UpdateObject:
  PUSH BC
  LD A,(IX+$0C)
  OR A
  JP Z,NextObject
DrawObject:
  LD A,(IX+$00)           ; Draw the object at IX (SpriteX/Y, size, mirror,
                          ; picture, frame list) and dispatch: exploding,
                          ; ramming turn, shooting kinds
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
  LD A,(IX+$09)
  AND $7F
  CP $01
  JP Z,DrawObjectPlain
  CP $08
  JP NZ,l_C361
DrawObjectPlain:
  XOR A
  JP DrawObjectDo
l_C361:
  LD A,(IX+$02)
DrawObjectDo:
  CALL DrawSprite
  LD A,(IX+$09)
  CP $FF
  JP Z,BlowUp
  CP $06
  JP Z,RamTurn

; ObjectBehaviour
;
; Used by the routine at RamTurn.
ObjectBehaviour:
  LD A,(IX+$09)           ; By kind: the power pod's frames, the swing gun, the
                          ; shooters, the launcher, the big gun; else walk,
                          ; fall, jump, the grid cell and the walk kinds' moves
  CP $FE
  CALL Z,AnimatePod
  LD A,(IX+$09)
  AND $7F
  CP $09
  JP Z,SwingGun
  CP $0A
  JP Z,Kind10Shoot
  CP $0B
  JP Z,Kind11Shoot
  CALL ObjectJump
  CALL ObjectFall
  CALL ObjectCell
  CALL ObjectMove

; ObjectHitsRex for the object at IX
;
; As REX 1's ObjectCollide $BB66 (src/game/objects.asm).
;
; Witness: L1 21382 (d1, demo-cycle).
ObjectCollide:
  CALL ObjectHitsRex

; The next object record (24 bytes on), until all are done
;
; As REX 1's NextObject $BB69 (src/game/objects.asm).
;
; Witness: L1 49655 (d1, demo-cycle).
NextObject:
  LD DE,$0017
  ADD IX,DE
  POP BC
  DEC B
  JP NZ,UpdateObject
  RET

; Kind 11 (launcher): at random its timer down; at 0 a long shot (type 7, $87)
; up from its X
;
; Witness: L1 3180 (d1, demo-cycle).
Kind11Shoot:
  CALL Random2
  CP $64
  JP C,ObjectCollide
  DEC (IX+$11)
  JP NZ,ObjectCollide
  LD A,(IX+$12)
  LD (IX+$11),A
ObjectShootSlot:
  CALL FindEnemySlot
  LD A,(IX+$00)
  LD (Temp1),A
  LD A,$08
  CALL EnemyShot
  LD (IY+$0B),$87
  LD (IY+$0C),$00
  JP ObjectCollide

; Kind 10 (shooters): at random its timer down; at 0 two shots, left and right
; (Kind10Shot)
;
; Witness: L1 2594 (d1, demo-cycle).
Kind10Shoot:
  CALL Random2
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
  CALL Kind10Shot
  CALL FindEnemySlot
  LD A,$01
  LD (Temp3),A
  LD A,(IX+$00)
  SUB $08
  CALL Kind10Shot
  JP ObjectCollide

; One enemy shot from (A, IX+1), speed 16 (SetupShot)
;
; Witness: L1 248 (d1, demo-cycle).
Kind10Shot:
  LD (Temp1),A
  LD A,$10
  LD (Temp4),A
  LD A,(IX+$01)
  LD (Temp2),A
  XOR A
  CALL SetupShot
  LD (IY+$05),$00
  RET

; Kind 9, the swing gun: its picture by angle (SwingGunFrames), at angles 0, 1,
; 3, 4, 5, 7 a shot that way, the next angle of 8; from $C473 kind 6's turn
;
; Changed from REX 1's SwingGun $BCDD (src/game/objects.asm).
;
; Witness: L1 2726 (d1, demo-cycle).
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
  LD A,(IX+$11)
  INC A
  LD (IX+$11),A
  CP $08
  JP NZ,ObjectCollide
  LD (IX+$11),$00
  JP ObjectCollide

; RamTurn
;
; Used by the routine at UpdateObject.
RamTurn:
  LD A,(IX+$11)           ; The hit foot man's turn (kind 6, from DrawObject):
                          ; the turning frames (FramesTurn) at count +$11 = 4,
                          ; kind 7 at 0
  CP $04
  JP NZ,RamTurnCount
  LD HL,FramesTurn
  LD (IX+$0A),L
  LD (IX+$0B),H
RamTurnCount:
  DEC (IX+$11)
  JP NZ,ObjectBehaviour
  LD HL,FramesTurn
  LD (IX+$0A),L
  LD (IX+$0B),H
  LD (IX+$09),$07
  JP ObjectBehaviour

; An exploding object (kind $FF): the six shards (ShardPaths $A332-$A382,
; DrawShard), the flash, the picture stepped; at the end the cells back and
; maybe a pod: a power pod $FE (SpritePodPower; a big one SpritePodBig), a bomb
; pod $FD or the bonus pod $FC
;
; Witness: L1 504 (d1, demo-cycle).
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
  LD A,(IX+$15)
  OR A
  JP Z,l_C4FF
  LD A,(IX+$00)
  CP $10
  JP C,BlowUpEnd
l_C4FF:
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
  LD HL,SpritePodPower
  LD (IX+$12),L
  LD (IX+$13),H
  LD (IX+$04),L
  LD (IX+$05),H
  LD A,(IX+$15)
  CP $FF
  JP Z,BlowUpEnd
  CALL Random2
  CP $02
  JP C,BlowUpBombPod
  CP $02
  JP C,BlowUpBonusPod
  LD A,(IX+$15)
  OR A
  JP NZ,NextObject
  LD HL,SpritePodBig
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
  LD HL,SpriteBombPod
  JP BlowUpPodPicture
BlowUpBonusPod:
  LD (IX+$09),$FC         ; leaves the bonus pod
  LD HL,SpriteBonusPod
BlowUpPodPicture:
  LD (IX+$04),L
  LD (IX+$05),H
  LD (IX+$02),$01
  JP NextObject

; Leftover: 8 bytes no code reads ($10 $20 $22 $19 $1D $31 $34 $FF)
SprayLeftover:
  DEFB $10,$20,$22,$19,$1D,$31,$34,$FF

; The swing gun's shot left and up
;
; Changed from REX 1's SwingShotUpLeft $BE5B (src/game/objects.asm).
;
; Witness: L1 342 (d1, demo-cycle).
SwingShotUpLeft:
  PUSH AF
  CALL EnemyShotFrom
  LD HL,$FFFF
  LD (IY+$04),$F8
  LD A,$06
  JP SwingShotSet

; The swing gun's shot left: dX -8, speed 8
;
; Witness: L1 679 (d1, demo-cycle).
SwingShotLeft:
  PUSH AF
  CALL EnemyShotFrom
  LD HL,$FFFF
  LD (IY+$04),$F8
  LD A,$08

; The shot's dX (HL) and speed
;
; As REX 1's SwingShotSet $BE8C (src/game/objects.asm).
;
; Witness: L1 2044 (d1, demo-cycle).
SwingShotSet:
  LD (IY+$07),L
  LD (IY+$08),H
  LD (IY+$05),$00
  CALL SetShotSpeed
  POP AF
  RET

; The swing gun's shot right
;
; Changed from REX 1's SwingShotRight $BE9B (src/game/objects.asm).
;
; Witness: L1 683 (d1, demo-cycle).
SwingShotRight:
  PUSH AF
  LD A,(IX+$00)
  SUB $08
  CALL EnemyShotA
  LD HL,$0001
  LD (IY+$04),$08
  LD A,$08
  JP SwingShotSet

; The swing gun's shot right and up
;
; Changed from REX 1's SwingShotUpRight $BEB3 (src/game/objects.asm).
;
; Witness: L1 340 (d1, demo-cycle).
SwingShotUpRight:
  PUSH AF
  LD A,(IX+$00)
  SUB $08
  CALL EnemyShotA
  LD HL,$0001
  LD (IY+$04),$08
  LD A,$06
  JP SwingShotSet

; The swing gun's picture offsets by angle: $00, $20, $40, $60, $80, $60, $40,
; $20
;
; As REX 1's SwingGunFrames $BECB (src/game/objects.asm).
SwingGunFrames:
  DEFB $00,$20,$40,$60,$80,$60,$40,$20

; The power pod's frames (PodFrames $C677); a pod not taken in time goes
;
; As REX 1's AnimatePod $BED3 (src/game/objects.asm).
;
; Witness: L1 3330 (d1, demo-cycle).
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
  JP Z,l_C65F
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
l_C65F:
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
;
; As REX 1's PodFrames $BF5B (src/game/objects.asm).
PodFrames:
  DEFB $00,$20,$40,$60,$80,$A0,$80,$60,$40,$20,$FF

; One shard of an explosion: its path step (HL + 2 x IX+3) from the object's
; place, clipped to the play area, its 4-byte picture from ShardPictures $A392
; ORed into the buffer (OrChar)
;
; Witness: L1 3024 (d1, demo-cycle).
DrawShard:
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
Random:
  PUSH HL                 ; A = a random byte: the byte at RandomSeed $5B6E
                          ; (walking $0000-$3FFF, the ROM) plus R
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

; The explosion flash's attributes (FlashCells): 2, 3, 6, $42, $43, $46, 6, 2
FlashAttrs:
  DEFB $02,$03,$06,$42,$43,$46,$06,$02

; The kinds' moves: pods none; 8 the scanner, 12/13 GroundWalker; 2 turns to
; face Rex; the others walk right or left
;
; Witness: L1 12882 (d1, demo-cycle).
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
; As REX 1's MineBurst $C03A (src/game/objects.asm).
;
; Witness: L1 32 (demo-cycle).
MineBurst:
  CALL Random2
  CP $23
  RET NC
  LD A,$04
  LD (EnemyShotKind),A
  CALL FindEnemySlot
  CALL EnemyShotFrom
  LD (IY+$07),$01
  LD (IY+$08),$00
  LD (IY+$04),$08
  LD (IY+$05),$00
  CALL FindEnemySlot
  CALL EnemyShotFrom
  LD HL,$FFFF
  LD (IY+$07),L
  LD (IY+$08),H
  LD (IY+$04),$F8
  LD (IY+$05),$00
  CALL FindEnemySlot
  CALL EnemyShotFrom
  LD (IY+$07),$00
  LD (IY+$08),$00
  LD (IY+$04),$00
  LD A,$08
  CALL SetShotSpeed
  CALL FindEnemySlot
  CALL EnemyShotFrom
  LD (IY+$07),$00
  LD (IY+$08),$00
  LD (IY+$04),$00
  LD A,$F8
  CALL SetShotSpeed
  CALL FindEnemySlot
  CALL EnemyShotFrom
  LD (IY+$07),$01
  LD (IY+$08),$00
  LD (IY+$04),$08
  LD A,$08
  CALL SetShotSpeed
  CALL FindEnemySlot
  CALL EnemyShotFrom
  LD (IY+$07),$01
  LD (IY+$08),$00
  LD (IY+$04),$08
  LD A,$F8
  CALL SetShotSpeed
  CALL FindEnemySlot
  CALL EnemyShotFrom
  LD HL,$FFFF
  LD (IY+$07),L
  LD (IY+$08),H
  LD (IY+$04),$F8
  LD A,$08
  CALL SetShotSpeed
  CALL FindEnemySlot
  CALL EnemyShotFrom
  LD HL,$FFFF
  LD (IY+$07),L
  LD (IY+$08),H
  LD (IY+$04),$F8
  LD A,$F8
  CALL SetShotSpeed
  RET

; Kinds 12 and 13: rise by the speed until a solid cell above or the top; at
; random turn; then sink back
;
; Witness: L1 868 (demo-cycle).
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
  CALL Random2
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

; Kinds 12 and 13 on the ground: walk right or left by direction
;
; Witness: L1 868 (demo-cycle).
GroundWalker:
  LD A,(IX+$02)
  OR A
  CALL Z,WalkRight
  LD A,(IX+$02)
  OR A
  CALL NZ,WalkLeft
  RET

; Kind 8 moving up: its timer steps, the picture stepped, then the turn
;
; Witness: L1 138 (demo-cycle).
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

; Kind 8: its timer down (at 0 ScannerTurn), its picture from ScannerFrames by
; its step
;
; Witness: L1 100 (demo-cycle).
ScannerAnimate:
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

; The scanner's picture words: $82B4, $8374, $8394, repeated (ScannerAnimate)
;
; As REX 1's ScannerFrames $C25A (src/game/objects.asm).
ScannerFrames:
  DEFB $B4,$82,$74,$83,$94,$83
  DEFB $B4,$82,$74,$83,$94,$83
  DEFB $B4,$82,$74,$83,$94,$83
  DEFB $B4,$82,$74,$83,$94,$83
  DEFB $B4,$82,$74,$83,$94,$83
  DEFB $B4,$82,$74,$83,$94,$83

; Kind 8, the scanner: when Rex moves (walks, jumps or falls) at its height or
; column it turns to stalk him (ScannerReset, MineBurst); then walks, rises or
; sinks by its state; at a cell edge ScannerTurn
;
; Changed from REX 1's Scanner $C27E (src/game/objects.asm).
;
; Witness: L1 138 (demo-cycle).
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
  CALL TutorKeyRight
  JP Z,ScannerHeight
  CALL TutorKeyLeft
  JP Z,ScannerHeight
  JP ScannerMove
ScannerHeight:
  LD A,(RexY)            ; level with Rex?
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
  LD A,(RexX)            ; his side
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
  JP Z,ScannerAnimate
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
; Witness: L1 138 (demo-cycle).
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

; Kind 8 at a cell edge: its next direction from the grid round it, at random
; among the free ones
;
; Witness: L1 6 (demo-cycle).
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
  CALL Random2
  AND $07
  CP $01
  JP Z,ScannerTop
  CP $02
  JP Z,ScannerGoDown
  CP $03
  JP Z,ScannerGoUp
  CP $04
  JP Z,ScannerBottom
  JP ScannerReset
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
; As REX 1's ScannerReset $C3BE (src/game/objects.asm).
;
; Witness: L1 35 (demo-cycle).
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

; A walker's step right: a solid cell ahead turns it; off the edge WalkOff
;
; Changed from REX 1's WalkRight $C3E0 (src/game/objects.asm).
;
; Witness: L1 3549 (d1, demo-cycle).
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
  LD A,(IX+$00)
  ADD A,(IX+$10)
  CP $E8
  JP NC,l_CADF
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
  CP $14
  CALL Z,MaybeJumper
WalkRightFloor:
  LD HL,(ObjectCellPtr)           ; the floor ahead
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
BlockedRight:
  LD A,(IX+$09)           ; Blocked: kinds 6 and 7 stay, the others turn
  CP $07
  RET Z
  CP $06
  RET Z
l_CADF:
  LD (IX+$02),$01

; Kinds 6 and 7 off the edge die (KillObject); 3, 4, 5 vanish (ObjectGone:
; alive 0, no score)
;
; As REX 1's WalkOff $C47A (src/game/objects.asm).
;
; Witness: L1 235 (d1, demo-cycle).
WalkOff:
  LD A,(IX+$09)
  CP $07
  JP Z,ShowPoints
  CP $06
  JP Z,ShowPoints
  CP $03
  JP Z,l_CB00
  CP $04
  JP Z,l_CB00
  CP $05
  JP Z,l_CB00
  RET
l_CB00:
  LD (IX+$0C),$00
  RET

; A walker's step left (as WalkRight)
;
; Changed from REX 1's WalkLeft $C4A6 (src/game/objects.asm).
;
; Witness: L1 4332 (d1, demo-cycle).
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
  CP $09
  JP C,l_CB71
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
  CP $14
  CALL Z,MaybeJumper
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
l_CB71:
  LD (IX+$02),$00
  JP WalkOff

; The hop's state: picture HL, speed, timers, bit 7 of the kind
;
; As REX 1's SetHop $C556 (src/game/objects.asm).
;
; Witness: L1 9 (demo-cycle).
SetHop:
  LD (IX+$10),$00
  LD (IX+$04),L
  LD (IX+$05),H
  LD (IX+$0E),$02
  LD (IX+$12),$01
  CALL Random2
  AND $0F
  ADD A,$10
  LD (IX+$11),A
  SET 7,(IX+$09)
  RET

; A kind 0 walker at X & 7 = 2 (right) or 4 (left), standing, becomes a jumper
; (SpriteJumper, SetHop)
;
; Changed from REX 1's MaybeJumper $C577 (src/game/objects.asm).
;
; Witness: L1 9 (demo-cycle).
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
  JP l_CBB8
MaybeJumperLeft:
  LD A,(IX+$00)
  AND $07
  CP $04
  RET NZ
l_CBB8:
  LD A,(IX+$06)
  OR A
  RET NZ
  LD A,(IX+$03)
  OR A
  RET NZ
HopTimer:
  LD A,(IX+$11)
  OR A
  RET NZ
  LD HL,SpriteJumper
  CALL SetHop
  LD (IX+$12),$02
  LD (IX+$11),$C8
  RET

; Leftover: LD A,(IX+$11): OR A: RET NZ after MaybeJumper; nothing reaches it
;
; Witness: L1 0 ().
MaybeJumperEnd:
  LD A,(IX+$11)
  OR A
  RET NZ

; An object not falling, below line 32 and not on the floor starts to fall
; (JumpSteps $D3C8)
;
; Witness: L1 3 (demo-cycle).
StartFall:
  LD A,(IX+$06)
  OR A
  RET NZ
  LD A,(IX+$01)
  CP $20
  RET C
  LD A,(IX+$03)
  OR A
  RET NZ
  LD (IX+$03),$01
  LD HL,JumpSteps
  LD (IX+$04),L
  LD (IX+$05),H
  RET

; The jump of an object by its jump table (pods, 14, 15 none; 8 and 12/13 their
; own); a solid cell above ends it and kinds 6 and 7 die
;
; Witness: L1 12882 (d1, demo-cycle).
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
  JP Z,ShowPoints
  CP $06
  JP Z,ShowPoints
  RET
JumpKind:
  LD A,(IX+$09)
  CP $07
  JP Z,ShowPoints
  CP $06
  JP Z,ShowPoints
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
; As REX 1's ObjectFall $C6C2 (src/game/objects.asm).
;
; Witness: L1 12882 (d1, demo-cycle).
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
  JP NC,l_CCF3
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
  JP Z,ShowPoints
  RET
l_CCF3:
  LD (IX+$0C),$00
  RET

; ObjectCellPtr $5EA4 = the grid cell of the object at IX
;
; As REX 1's ObjectCell $C72B (src/game/objects.asm).
;
; Witness: L1 25406 (d1, demo-cycle).
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
