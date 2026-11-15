; --------------------------------------------------------------------------------------------------------------------
; objects.asm: The objects: the enemies, the pods, their moves, their shots, the explosions
; --------------------------------------------------------------------------------------------------------------------

  ORG $BC48

; Update every object of the room (falls into UpdateObject)
;
; As REX 1's UpdateObjects $BA5C (src/game/objects.asm).
;
; Witness: L1 10869 (c2, p2-room20, rzx-p2- x21).
UpdateObjects:
  LD IX,$5E66
  LD A,(ObjectCount)
  LD B,A

; One object at IX: skip a dead one; kind 0 picks the walker picture (falling
; or exploding: ExplosionPicture $9180); a walker or a hopper at random shoots
; two shots; draw it
;
; Changed from REX 1's UpdateObject $BA64 (src/game/objects.asm).
;
; Witness: L1 112141 (c2, p2-room20, rzx-p2- x21).
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
  LD HL,ExplosionPicture  ; the explosion picture $9180
ObjectPicture:
  LD (IX+$16),L
  LD (IX+$17),H
  LD A,(IX+$12)
  CP $02
  JP Z,DrawObject
  BIT 7,(IX+$09)
  JP Z,ObjectShoot
ObjectShootBusy:
  CALL Random             ; a busy (bit 7) object: 1 in 16
  CP $F0
  JP C,DrawObject
  JP ObjectShootSlot
ObjectShoot:
  CALL Random             ; else 1 in 128
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
  JP Z,ObjectShootTwo
  LD A,$11
ObjectShootTwo:
  PUSH AF                 ; two shots: type $0E (or $11 for a busy object) and
                          ; the next but one
  CALL EnemyShot
  LD (IY+$05),$00
  CALL FindEnemySlot
  POP AF
  INC A
  INC A
ObjectShootDo:
  CALL EnemyShot
  LD (IY+$05),$00

; Draw the object at IX (SpriteX/Y, size, mirror, picture, frame list),
; dissolve it, start a fall, maybe make a jumper, and dispatch: exploding, the
; hopper
;
; Changed from REX 1's DrawObject $BAD0 (src/game/objects.asm).
;
; Witness: L1 47643 (c2, p2-room20, rzx-p2- x20).
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
DrawObjectKind:
  LD A,(IX+$09)           ; kind 8 never mirrored
  AND $7F
  CP $08
  JP NZ,DrawObjectMirror
DrawObjectPlain:
  XOR A
  JP DrawObjectDraw
DrawObjectMirror:
  LD A,(IX+$02)
DrawObjectDraw:
  CALL DrawSprite         ; draw it; then its dissolve, its timers, the jumper
DrawObjectDo:
  CALL ObjectDissolve
  CALL JumperTimer
  CALL MaybeJumper
  LD A,(IX+$09)
  CP $FF
  JP Z,BlowUp
  CP $06
  JP Z,RamTurn

; By kind: the pods' frames; kinds 9, 4, 3, 2, 5 their own behaviours; else
; jump, fall, the cell under it and the move; then against Rex
;
; Changed from REX 1's ObjectBehaviour $BB39 (src/game/objects.asm).
;
; Witness: L1 45603 (c2, p2-room20, rzx-p2- x20).
ObjectBehaviour:
  LD A,(IX+$09)
  CP $FE
  CALL Z,AnimatePod
  LD A,(IX+$09)
  AND $7F
  CP $09
  JP Z,Kind9Fan
  CP $04
  JP Z,Kind4Crawl
  CP $03
  JP Z,Kind3Grow
  CP $02
  JP Z,Kind2Drop
  CP $05
  JP Z,Kind5Burst
  CALL ObjectJump
  CALL ObjectFall
  CALL ObjectCell
  CALL ObjectMove

; ObjectHitsRex for the object at IX
;
; As REX 1's ObjectCollide $BB66 (src/game/objects.asm).
;
; Witness: L1 45603 (c2, p2-room20, rzx-p2- x20).
ObjectCollide:
  CALL ObjectHitsRex

; The next object record (24 bytes on), until all are done
;
; As REX 1's NextObject $BB69 (src/game/objects.asm).
;
; Witness: L1 112141 (c2, p2-room20, rzx-p2- x21).
NextObject:
  LD DE,$001B
  ADD IX,DE
  POP BC
  DEC B
  JP NZ,UpdateObject
  RET

; Kind 2: waits, unfolds (3 frames), drops 8 lines a pass to the floor (off the
; bottom it dies), folds (4 frames)
;
; Witness: L1 7099 (c2, p2-room20, rzx-p2- x16).
Kind2Drop:
  LD A,(IX+$11)
  OR A
  JP Z,Kind2Wait
  CP $01
  JP Z,Kind2Frames
  CP $02
  JP Z,Kind2Fall
  CP $03
  JP Z,Kind2Frames
  JP ObjectCollide
Kind2Fall:
  LD A,(IX+$01)           ; dropping 8 lines a pass
  ADD A,$08
  LD (IX+$01),A
  CP $B0
  JP NC,Kind2Gone
  CALL ObjectCell
  LD A,(HL)
  CALL IsPassable
  JP NZ,Kind2Landed
  INC HL
  LD A,(HL)
  CALL IsPassable
  JP Z,ObjectCollide
Kind2Landed:
  LD (IX+$11),$03         ; landed: fold, 4 frames
  LD (IX+$12),$04
  JP ObjectCollide
Kind2Frames:
  LD L,(IX+$04)           ; a frame on (unfold or fold)
  LD H,(IX+$05)
  LD DE,$0020
  ADD HL,DE
  LD (IX+$04),L
  LD (IX+$05),H
  DEC (IX+$12)
  JP NZ,ObjectCollide
Kind2Down:
  LD A,(IX+$11)           ; frames on
  CP $03
  JP Z,Kind2Fold
  LD (IX+$11),$02
  JP ObjectCollide
Kind2Fold:
  LD (IX+$11),$04         ; landed: fold
  LD (IX+$12),$03
  JP ObjectCollide

; Kind 2 at rest: its timer, then it unfolds
;
; Witness: L1 4146 (c2, p2-room20, rzx-p2- x15).
Kind2Wait:
  DEC (IX+$12)
  JP NZ,ObjectCollide
  LD (IX+$11),$01
  LD (IX+$12),$03
  JP ObjectCollide
; This entry point is used by the routine at Kind2Drop.
Kind2Gone:
  LD (IX+$0C),$00         ; off the bottom: dead
  JP ObjectCollide

; Kind 3: every 4 passes its picture one frame back, until the first
;
; Witness: L1 3447 (rzx-p2- x10).
Kind3Grow:
  LD A,(IX+$12)
  DEC A
  LD (IX+$12),A
  OR A
  JP NZ,ObjectCollide
  LD (IX+$12),$04
  LD A,(IX+$11)
  DEC A
  CP $FF
  JP Z,ObjectCollide
  LD (IX+$11),A
  LD L,(IX+$04)
  LD H,(IX+$05)
  LD DE,$0020
  AND A
  SBC HL,DE
  LD (IX+$04),L
  LD (IX+$05),H
  JP ObjectCollide

; Kind 4: crawls up or down a line a pass; a solid cell or the area's edge
; turns it; at random it stops, opens and closes
;
; Witness: L1 8437 (c2, p2-room20, rzx-p2- x16).
Kind4Crawl:
  LD A,(IX+$11)
  OR A
  JP Z,Kind4Down
  CP $01
  JP Z,Kind4Up
Kind4State:
  LD A,(IX+$12)           ; by state
  CP $02
  JP Z,Kind4Open
  CP $03
  JP Z,Kind4Close
  CP $04
  JP Z,Kind4Wait
  JP ObjectCollide
Kind4Down:
  LD A,(IX+$01)           ; moving down a line
  INC A
  LD (IX+$01),A
  CP $A8
  JP NC,Kind4Turn
  CALL Kind4MaybeStop
  CALL ObjectCell
Kind4Ahead:
  INC HL                  ; the cells ahead
  LD A,(HL)
  OR A
  JP NZ,Kind4Turn
  INC HL
  LD A,(HL)
  JP Z,Kind4State
Kind4Turn:
  LD A,(IX+$11)           ; turn
  XOR $01
  LD (IX+$11),A
  JP Kind4State
Kind4Up:
  LD A,(IX+$01)           ; moving up a line
  DEC A
  LD (IX+$01),A
  CP $10
  JP C,Kind4Turn
  CALL Kind4MaybeStop
  CALL ObjectCell
  LD DE,$0040
  AND A
  SBC HL,DE
  JP Kind4Ahead
Kind4Open:
  LD L,(IX+$04)           ; opening, a frame a pass; then a random wait 4-11
  LD H,(IX+$05)
  LD DE,$0020
  ADD HL,DE
  LD (IX+$04),L
  LD (IX+$05),H
  DEC (IX+$13)
  JP NZ,ObjectCollide
  LD (IX+$12),$04
  CALL Random
  AND $07
  ADD A,$04
  LD (IX+$13),A
  JP ObjectCollide

; At random (1 in 13) a moving kind 4 stops and opens (state 2, 2 frames)
;
; Witness: L1 8407 (c2, p2-room20, rzx-p2- x16).
Kind4MaybeStop:
  LD A,(IX+$12)
  OR A
  RET NZ
  CALL Random
  CP $14
  RET NC
  LD (IX+$13),$02
  LD (IX+$12),$02
  RET

; Kind 4 closes, a frame a pass, then moves again
;
; Witness: L1 656 (c2, p2-room20, rzx-p2- x16).
Kind4Close:
  LD L,(IX+$04)
  LD H,(IX+$05)
  LD DE,$0020
  AND A
  SBC HL,DE
  LD (IX+$04),L
  LD (IX+$05),H
  DEC (IX+$13)
  JP NZ,ObjectCollide
  LD (IX+$12),$00
  JP ObjectCollide

; Kind 4 open: its timer, then it closes
;
; Witness: L1 2569 (c2, p2-room20, rzx-p2- x16).
Kind4Wait:
  DEC (IX+$13)
  JP NZ,ObjectCollide
  LD (IX+$13),$02
  LD (IX+$12),$03
  JP ObjectCollide

; Kind 5: at rest, at random it opens (6 frames) and fires 1-8 climbing shots
; (type $87) in random directions, then closes
;
; Witness: L1 3601 (c2, rzx-p2- x13).
Kind5Burst:
  LD A,(IX+$11)
  OR A
  JP Z,Kind5Rest
  CP $01
  JP Z,Kind5Open
  CP $02
  JP Z,Kind5Close
  JP ObjectCollide
Kind5Open:
  LD L,(IX+$04)           ; opening; at the end the burst
  LD H,(IX+$05)
  LD DE,$0020
  ADD HL,DE
  LD (IX+$04),L
  LD (IX+$05),H
  DEC (IX+$12)
  JP NZ,ObjectCollide
  LD (IX+$11),$02
  LD (IX+$12),$06
  LD A,$04
  LD (EnemyShotKind),A
  CALL Random
  AND $07
  INC A
  LD B,A
BurstLoop:
  PUSH BC                 ; each shot
  CALL Random2
  AND $03
  LD E,A
  LD D,$00
  LD HL,BurstSpeeds
  ADD HL,DE
  LD E,(HL)
  CALL Random2
  AND $03
  CALL BurstShot
  POP BC
  DJNZ BurstLoop
  JP ObjectCollide

; The burst shots' horizontal speeds: $F8, $FC, $04, $08
BurstSpeeds:
  DEFB $F8,$08,$F8,$00

; One climbing shot from IX's X - 8: speed E, type $87, its rise A x 4
;
; Witness: L1 448 (c2, rzx-p2- x13).
BurstShot:
  PUSH AF
  PUSH DE
  CALL FindEnemySlot
  LD A,(IX+$00)
  SUB $08
  LD (Temp1),A
  LD A,$08
  CALL EnemyShot
  LD (IY+$0B),$87
  LD (IY+$0C),$00
  POP DE
  LD (IY+$04),E
  POP AF
  SLA A
  SLA A
  LD (IY+$0E),A
  RET

; Kind 5 closes, a frame a pass, then rests
;
; Witness: L1 570 (c2, rzx-p2- x13).
Kind5Close:
  LD L,(IX+$04)
  LD H,(IX+$05)
  LD DE,$0020
  AND A
  SBC HL,DE
  LD (IX+$04),L
  LD (IX+$05),H
  DEC (IX+$12)
  JP NZ,ObjectCollide
  LD (IX+$11),$00
  JP ObjectCollide

; Kind 5 at rest: 1 in 25 it opens
;
; Witness: L1 2450 (c2, rzx-p2- x13).
Kind5Rest:
  CALL Random
  CP $0A
  JP NC,ObjectCollide
  LD (IX+$11),$01
  LD (IX+$12),$06
  JP ObjectCollide

; Kind 9: at rest, at random it opens (5 frames) and fires a fan of five shots
; (up left, left, straight, right, up right), then closes
;
; Witness: L1 3493 (c2, rzx-p2- x9).
Kind9Fan:
  LD A,(IX+$11)
  OR A
  JP Z,Kind9Rest
  CP $01
  JP Z,Kind9Open
  CP $02
  JP Z,Kind9Close
  JP ObjectCollide
Kind9Open:
  LD L,(IX+$04)           ; opening; at the end the fan
  LD H,(IX+$05)
  LD DE,$0020
  ADD HL,DE
  LD (IX+$04),L
  LD (IX+$05),H
  DEC (IX+$12)
  JP NZ,ObjectCollide
  LD (IX+$11),$02
  LD (IX+$12),$05
  LD A,$04
  LD (EnemyShotKind),A
  CALL FindEnemySlot
  CALL SwingShotUpLeft
  CALL FindEnemySlot
  CALL SwingShotLeft
  CALL FindEnemySlot
  CALL SwingShotStraight
  CALL FindEnemySlot
  CALL SwingShotRight
  CALL FindEnemySlot
  CALL SwingShotUpRight
  JP ObjectCollide

; Kind 9 closes, a frame a pass, then rests
;
; Witness: L1 534 (c2, rzx-p2- x8).
Kind9Close:
  LD L,(IX+$04)
  LD H,(IX+$05)
  LD DE,$0020
  AND A
  SBC HL,DE
  LD (IX+$04),L
  LD (IX+$05),H
  DEC (IX+$12)
  JP NZ,ObjectCollide
  LD (IX+$11),$00
  JP ObjectCollide

; Kind 9 at rest: 1 in 25 it opens
;
; Witness: L1 2413 (c2, rzx-p2- x9).
Kind9Rest:
  CALL Random
  CP $0A
  JP NC,ObjectCollide
  LD (IX+$11),$01
  LD (IX+$12),$05
  JP ObjectCollide

; The hit foot man's turn (kind 6, from DrawObject): the turning picture at
; count +$11 = 4, kind 7 at 0
;
; As REX 1's RamTurn $BD44 (src/game/objects.asm).
;
; Witness: L1 86 (rzx-p2- x8).
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
; As REX 1's BlowUp $BD6B (src/game/objects.asm).
;
; Witness: L1 2038 (c2, p2-room20, rzx-p2- x20).
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

; A swing gun shot up and left
;
; As REX 1's SwingShotUpLeft $BE5B (src/game/objects.asm).
;
; Witness: L1 109 (c2, rzx-p2- x8).
SwingShotUpLeft:
  PUSH AF
  LD A,(IX+$00)
  SUB $18
  LD (Temp1),A
  LD A,$14
  CALL EnemyShot
  LD HL,$FFFF
  LD (IY+$04),$F8
  LD A,$02
  JP SwingShotSet

; A swing gun shot left
;
; As REX 1's SwingShotLeft $BE75 (src/game/objects.asm).
;
; Witness: L1 109 (c2, rzx-p2- x8).
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
; As REX 1's SwingShotSet $BE8C (src/game/objects.asm).
;
; Witness: L1 545 (c2, rzx-p2- x8).
SwingShotSet:
  LD (IY+$07),L
  LD (IY+$08),H
  LD (IY+$05),$00
  CALL SetShotSpeed
  POP AF
  RET

; A swing gun shot from X - 16 with no sideways step (dX 0)
;
; Witness: L1 109 (c2, rzx-p2- x8).
SwingShotStraight:
  PUSH AF
  LD A,(IX+$00)
  SUB $10
  LD (Temp1),A
  LD A,$19
  CALL EnemyShot
  LD HL,$0000
  LD (IY+$04),$00
  LD A,$08
  JP SwingShotSet

; A swing gun shot right
;
; As REX 1's SwingShotRight $BE9B (src/game/objects.asm).
;
; Witness: L1 109 (c2, rzx-p2- x8).
SwingShotRight:
  PUSH AF
  LD A,(IX+$00)
  LD (Temp1),A
  LD A,$19
  CALL EnemyShot
  LD HL,$0001
  LD (IY+$04),$08
  LD A,$06
  JP SwingShotSet

; A swing gun shot up and right
;
; As REX 1's SwingShotUpRight $BEB3 (src/game/objects.asm).
;
; Witness: L1 109 (c2, rzx-p2- x8).
SwingShotUpRight:
  PUSH AF
  LD A,(IX+$00)
  LD (Temp1),A
  LD A,$14
  CALL EnemyShot
  LD HL,$0001
  LD (IY+$04),$08
  LD A,$04
  JP SwingShotSet

; The power pod's frames (PodFrames $C253); a pod not taken in time goes
;
; As REX 1's AnimatePod $BED3 (src/game/objects.asm).
;
; Witness: L1 9414 (c2, p2-room20, rzx-p2- x20).
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
  JP Z,PodFrame4
  CP $03
  JP Z,PodFrame3
  CP $04
  JP Z,PodFrame2
  CP $05
  JP Z,PodFrame1
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
PodFrame1:
  LD HL,SpritePowerPod    ; timer 5: the frame $8898
  JP PodSet
PodFrame2:
  LD HL,SpritePowerPod+$0020 ; timer 4: $88B8
  JP PodSet
PodFrame3:
  LD HL,SpritePowerPod+$0040 ; timer 3: $88D8
  JP PodSet
PodFrame4:
  LD HL,SpritePowerPod+$0060 ; timer 2: $88F8
  JP PodSet

; The pod's frame offsets: $00-$A0 and back, $FF
;
; As REX 1's PodFrames $BF5B (src/game/objects.asm).
PodFrames:
  DEFB $00,$20,$40,$60,$80,$A0,$80,$60,$40,$20,$FF

; One shard of an explosion along its path at HL: the border's speaker bit
; random (the explosion's crackle), the shard ORed into the buffer
;
; As REX 1's DrawShard $BF66 (src/game/objects.asm).
;
; Witness: L1 12228 (c2, p2-room20, rzx-p2- x20).
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

; The random inks of the explosion pieces and of FlashCells: 2, 3, 6, 2, 3, 6,
; 2, 3
PieceInks:
  DEFB $02,$03,$06,$02,$03,$06,$06,$02

; The kinds' moves: pods none, 14 drifts (Blob), the others walk right or left
;
; Changed from REX 1's ObjectMove $BFEF (src/game/objects.asm).
;
; Witness: L1 19526 (c2, p2-room20, rzx-p2- x20).
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
  CP $0E
  JP Z,DriftObject
  OR A
  JP NZ,ObjectMoveWalk
ObjectMoveWalk:
  LD A,(IX+$02)           ; walk right or left
  OR A
  JP Z,WalkRight
  JP WalkLeft

; Code of ObjectMove's kinds that no recording reached; the kit keeps it as
; bytes
ObjectMoveCode:
  DEFB $AF,$DD,$77,$02,$3A,$4F,$A2,$DD,$BE,$00,$D0,$3E,$01,$DD,$77,$02
  DEFB $C9,$CD,$1D,$A5,$FE,$23,$D0,$3E,$04,$32,$ED,$A1,$21,$7C,$B4,$06
  DEFB $08,$C5,$E5,$CD,$B6,$B5,$CD,$C4,$B5,$E1,$CD,$19,$B5,$C1,$10,$F1
  DEFB $C9,$DD,$7E,$11,$B7,$C2,$A5,$C3,$DD,$7E,$01,$DD,$96,$12,$DD,$77
  DEFB $01,$CD,$94,$C7,$11,$40,$00,$A7,$ED,$52,$CD,$F5,$CD,$CA,$9C,$C3
  DEFB $23,$CD,$F5,$CD,$CA,$9C,$C3,$CA,$A5,$C3,$DD,$7E,$01,$FE,$18,$DA
  DEFB $9C,$C3,$FE,$A8,$D2,$93,$C3,$CD,$1D,$A5,$FE,$07,$DA,$8A,$C3,$DD
  DEFB $7E,$09,$FE,$0D,$C8,$DD,$7E,$12,$3C,$FE,$05,$C8,$DD,$77,$12,$C9
  DEFB $DD,$7E,$02,$EE,$01,$DD,$77,$02,$C9,$DD,$36,$11,$00,$DD,$36,$12
  DEFB $01,$C9,$DD,$36,$11,$01,$DD,$36,$12,$01,$C9,$DD,$7E,$01,$DD,$86
  DEFB $12,$DD,$77,$01,$CD,$94,$C7,$CD,$F5,$CD,$CA,$93,$C3,$23,$CD,$F5
  DEFB $CD,$CA,$93,$C3,$C3,$61,$C3

; Kind 14, the mine: drift by dX, dY; a solid cell above kills it; it rests and
; heads for Rex in turn, a few passes each
;
; Changed from REX 1's DriftObject $C150 (src/game/objects.asm).
;
; Witness: L1 3566 (c2, p2-room20, rzx-p2- x11).
DriftObject:
  LD A,(IX+$00)
  ADD A,(IX+$04)
  LD (IX+$00),A
  LD A,(IX+$01)
  ADD A,(IX+$05)
  LD (IX+$01),A
  LD A,(IX+$09)
  CP $0F
  JP Z,DriftTimer
  LD HL,(ObjectCellPtr)
  LD DE,$0020
  AND A
  SBC HL,DE
  CALL IsSolid
  JP Z,KillObject
DriftTimer:
  DEC (IX+$11)
  RET NZ
  LD A,R
  AND $03
  ADD A,$02
  LD (IX+$11),A
  LD A,(IX+$09)
  CP $0F
  JP Z,DriftRandom
  LD A,(IX+$12)
  XOR $01
  LD (IX+$12),A
  OR A
  RET Z
DriftRandom:
  LD A,R
  AND $07
  ADD A,$08
  LD (IX+$11),A
  LD (IX+$04),$01
  LD A,(RexX)
  CP (IX+$00)
  JP NC,DriftDown
  LD (IX+$04),$FF
DriftDown:
  LD (IX+$05),$01
  LD A,(RexY)
  CP (IX+$01)
  RET NC
  LD (IX+$05),$FF
  RET

; A walker's step right: a solid cell ahead turns it; off the edge WalkOff; a
; kind 0 on a cell $0F falls, $0E hops, $10 maybe jumps, $15 or $16 dissolves
;
; Changed from REX 1's WalkRight $C3E0 (src/game/objects.asm).
;
; Witness: L1 2953 (c2, p2-room20, rzx-p2- x17).
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
  LD DE,$001E
  AND A
  SBC HL,DE
  LD A,(HL)
  CP $0F
  JP Z,StartFall
  CP $0E
  JP Z,HopIfIdle
  CP $10
  CALL Z,MaybeJumpRight
  CP $11
  CALL Z,MaybeJumpLeft
  CP $15
  CALL Z,MaybeDissolve
  CP $16
  CALL Z,CellDissolve
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
; As REX 1's BlockedRight $C469 (src/game/objects.asm).
;
; Witness: L1 67 (rzx-p2- x15).
BlockedRight:
  LD A,(IX+$09)
  CP $07
  RET Z
  CP $06
  RET Z

; Direction ^ 1
;
; As REX 1's TurnAround $C472 (src/game/objects.asm).
;
; Witness: L1 63 (rzx-p2- x15).
TurnAround:
  LD A,(IX+$02)
  XOR $01
  LD (IX+$02),A

; Kinds 6 and 7 off the edge die (KillObject); 3, 4, 5 vanish (ObjectGone:
; alive 0, no score)
;
; Changed from REX 1's WalkOff $C47A (src/game/objects.asm).
;
; Witness: L1 114 (c2, rzx-p2- x16).
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
; This entry point is used by the routine at EdgeLeft.
ObjectGone:
  LD (IX+$0C),$00         ; The object is dead (alive = 0)
  RET

; At the left edge: kind 0 dies, the others turn
;
; As REX 1's EdgeLeft $C49C (src/game/objects.asm).
;
; Witness: L1 7 (c2, rzx-p2-02000, rzx-p2-04000, rzx-p2-10000).
EdgeLeft:
  LD A,(IX+$09)
  OR A
  JP Z,ObjectGone
  JP TurnAround

; A walker's step left (as WalkRight)
;
; Changed from REX 1's WalkLeft $C4A6 (src/game/objects.asm).
;
; Witness: L1 3105 (c2, p2-room20, rzx-p2- x18).
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
  LD DE,$0021
  AND A
  SBC HL,DE
  LD A,(HL)
  CP $0F
  JP Z,StartFallIfIdle
  CP $0E
  JP Z,HopIfIdle
  CP $10
  CALL Z,MaybeJumpRight
  CP $11
  CALL Z,MaybeJumpLeft
  CP $15
  CALL Z,MaybeDissolve
  CP $16
  CALL Z,CellDissolve
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
; As REX 1's MaybeJumpRight $C531 (src/game/objects.asm).
;
; Witness: L1 26 (rzx-p2-10000, rzx-p2-14000, rzx-p2-36000).
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
; As REX 1's MaybeJumpLeft $C540 (src/game/objects.asm).
;
; Witness: L1 4 (c2, rzx-p2-20000, rzx-p2-30000).
MaybeJumpLeft:
  CALL Random
  CP $80
  JP C,StartFallIfIdle
  LD (IX+$11),$04
  RET

; Walker on a cell $15: at random (1 in 2) it dissolves
;
; Witness: L1 8 (c2, rzx-p2-00000).
MaybeDissolve:
  CALL Random
  CP $80
  RET C

; Walker on a cell $16: it dissolves (ObjectFadeOut)
;
; Witness: L1 8 (c2, rzx-p2-00000, rzx-p2-16000, rzx-p2-28000, rzx-p2-32000).
CellDissolve:
  CALL ObjectFadeOut
  RET
; This entry point is used by the routine at MaybeJumpRight.
StartHop:
  POP DE                  ; a hop: the hopper's picture SpriteKind6 $8318
; This entry point is used by the routines at WalkRight and WalkLeft.
HopIfIdle:
  LD A,(IX+$11)           ; a cell $0E: a hop unless busy
  OR A
  RET NZ
  LD HL,SpriteKind6

; The hop's state: picture HL, speed, timers, bit 7 of the kind
;
; As REX 1's SetHop $C556 (src/game/objects.asm).
;
; Witness: L1 70 (c2, rzx-p2- x15).
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

; A kind 0 walker at X & 7 = 2 or 4 becomes a jumper one time in 43
; (MakeJumper)
;
; Changed from REX 1's MaybeJumper $C577 (src/game/objects.asm).
;
; Witness: L1 47642 (c2, p2-room20, rzx-p2- x20).
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

; A walker standing still becomes a jumper: SpriteJumper $8338, SetHop, timer 2
;
; Witness: L1 73 (c2, rzx-p2- x15).
MakeJumper:
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
; As REX 1's JumperTimer $C5B6 (src/game/objects.asm).
;
; Witness: L1 47642 (c2, p2-room20, rzx-p2- x20).
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

; Code: RET: RET: RET; no instruction reaches the last two (the static walk
; stops at the first)
ThreeReturns:
  DEFB $C9,$C9,$C9

; If the timer is 0, StartFall
;
; As REX 1's StartFallIfIdle $C5FD (src/game/objects.asm).
;
; Witness: L1 10 (c2, rzx-p2-10000, rzx-p2-16000, rzx-p2-20000, rzx-p2-30000).
StartFallIfIdle:
  LD A,(IX+$11)
  OR A
  RET NZ

; An object not falling and below line 24 starts to fall (JumpSteps $CE68)
;
; As REX 1's StartFall $C602 (src/game/objects.asm).
;
; Witness: L1 25 (c2, rzx-p2- x9).
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

; The jump of an object by its jump table (pods and the mine none); a solid
; cell above ends it and kinds 6 and 7 die
;
; Changed from REX 1's ObjectJump $C620 (src/game/objects.asm).
;
; Witness: L1 19526 (c2, p2-room20, rzx-p2- x20).
ObjectJump:
  LD A,(IX+$09)
  CP $FE
  RET Z
  CP $FD
  RET Z
  CP $FC
  RET Z
  AND $7F
  CP $0E
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

; The fall: by the fall speed until a solid cell; on a cell of type 3 the
; object dies; below line $B8 it is gone
;
; Witness: L1 19526 (c2, p2-room20, rzx-p2- x20).
ObjectFall:
  LD A,(IX+$09)
  AND $7F
  CP $0E
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
  LD A,(IX+$09)
  CP $FF
  JP Z,ObjectFallStep
  LD A,(CellFound)
  CP $03
  CALL Z,FallKill
ObjectFallStep:
  LD A,(IX+$06)           ; the fall speed + 2, up to 6
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

; The falling object dies on a cell of type 3: IX+$15 = $FF, KillObject
;
; Witness: L1 13 (rzx-p2- x6).
FallKill:
  LD (IX+$15),$FF
  CALL KillObject
  RET

; ObjectCellPtr $A1B4 = the grid cell of the object at IX
;
; As REX 1's ObjectCell $C72B (src/game/objects.asm).
;
; Witness: L1 42807 (c2, p2-room20, rzx-p2- x20).
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
