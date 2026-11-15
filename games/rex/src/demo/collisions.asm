; --------------------------------------------------------------------------------------------------------------------
; collisions.asm: The collisions: shots and objects against Rex, Rex's shots against objects, the pods
; --------------------------------------------------------------------------------------------------------------------

; Each enemy bullet in Rex's box: the shield takes it (faster drain), else Rex
; dies
;
; As REX 1's EnemyBulletsHitRex $D1B9 (src/game/collisions.asm).
;
; Witness: L1 6752 (d1, demo-cycle).
EnemyBulletsHitRex:
  LD A,(Dying)
  OR A
  RET NZ
  LD A,(SparkleMode)
  OR A
  RET NZ
  LD IY,$5D57
  LD B,$14
EnemyBulletLoop:
  LD A,(IY+$06)           ; each enemy bullet
  CP $01
  JP NZ,EnemyBulletNext
  LD A,(RexY)
  ADD A,$05
  CP (IY+$01)
  JP NC,EnemyBulletNext
  ADD A,$11
  CP (IY+$01)
  JP C,EnemyBulletNext
  LD A,(RexX)
  CP (IY+$00)
  JP NC,EnemyBulletNext
  ADD A,$10
  CP (IY+$00)
  JP C,EnemyBulletNext
  LD (IY+$06),$02
  LD A,(ShieldOn)
  OR A
  JP Z,EnemyBulletKills
  LD L,$05
  CALL ShieldDrainFast
  JP EnemyBulletNext
EnemyBulletKills:
  CALL ShieldHitSound
EnemyBulletNext:
  LD DE,$000F
  ADD IY,DE
  DEC B
  JP NZ,EnemyBulletLoop
  RET

; The object at IX against Rex: its box; with the shield on it dies (points,
; the shield drained), else Rex dies unless a pod; pods are taken; then Rex's
; 30 bullets against it (as part 1's BulletsHitObject); the last hit on a kind
; 0 from behind turns it
;
; Witness: L1 21382 (d1, demo-cycle).
ObjectHitsRex:
  LD A,(Dying)
  OR A
  RET NZ
ObjectBoxTest:
  LD A,(SparkleMode)            ; the test against Rex's place
  OR A
  JP NZ,BulletsHitObject
  LD HL,RexY
  LD A,(IX+$01)
  SUB $10
  CP (HL)
  JR NC,BulletsHitObject
BoxHeightAdd:
  ADD A,$1E               ; ADD A,n: the box's height by kind
  CP (HL)
  JR C,BulletsHitObject
  LD HL,RexX
  LD A,(IX+$00)
BoxLeftSub:
  SUB $10                 ; SUB n: the box's left offset by direction
  CP (HL)
  JR NC,BulletsHitObject
BoxWidthAdd:
  ADD A,$16               ; ADD A,n: the box's width by kind
  CP (HL)
  JR C,BulletsHitObject
  LD A,(ShieldOn)
  OR A
  JP Z,ObjectHitsUnshielded
  LD A,(IX+$09)
  CP $FE
  JP Z,ObjectHitsUnshielded
  CP $FD
  JP Z,ObjectHitsUnshielded
  CP $FC
  JP Z,ObjectHitsUnshielded
  CALL ShowPoints
  LD A,(IX+$14)
  SLA A
  SLA A
  LD L,A
  CALL ShieldDrainFast
  JP ObjectTakePod
ObjectHitsUnshielded:
  LD A,(IX+$09)           ; no shield: Rex dies unless a pod
  CP $FE
  JP Z,ObjectTakePod
  CP $FD
  JP Z,ObjectTakePod
  CP $FC
  JP Z,ObjectTakePod
  CALL RexDies
ObjectTakePod:
  LD A,(IX+$09)           ; a pod is taken
  CP $FE
  CALL Z,TakePowerPod
  CP $FD
  CALL Z,TakeBombPod
  LD A,(IX+$09)
  CP $FC
  CALL Z,BonusRoulette
BulletsHitObject:
  LD IY,$5B95             ; Rex's 30 bullets against the object at IX: a hit
                          ; object takes damage (HitObject, HitObjectHard) or
                          ; is killed
  LD B,$1E
BulletLoop:
  LD A,(IY+$06)
  CP $01
  JP NZ,NextBullet
  LD A,(IX+$01)
  ADD A,$05
  CP (IY+$01)
  JP NC,NextBullet
BulletBoxHeight:
  ADD A,$10               ; ADD A,n: the bullet test's height by kind
  CP (IY+$01)
  JP C,NextBullet
  LD A,(IX+$00)
  CP (IY+$00)
  JP NC,NextBullet
BulletBoxWidth:
  ADD A,$10               ; ADD A,n: the bullet test's width by kind
  CP (IY+$00)
  JP C,NextBullet
  LD A,(IX+$09)
  CP $FE
  JP Z,NextBullet
  CP $FD
  JP Z,NextBullet
  CP $FC
  JP Z,NextBullet
  LD A,(Weapon)
  CP $02
  JP NZ,BulletHit
  LD (IY+$06),$00
  JP BulletHitKind
BulletHit:
  LD (IY+$06),$02
  LD A,(Channels+$0010)
  CP $FF
  JP NZ,BulletHitKind
  LD DE,SfxHitWall
  CALL StartSfx
BulletHitKind:
  LD A,(IX+$09)
  CP $06
  CALL Z,HitObjectHard
  LD A,(IX+$09)
  CP $06
  JP Z,NextBullet
  LD A,(IX+$14)
  OR A
  JP Z,NextBullet
  DEC A
  LD (IX+$14),A
  CP $01
  JP NZ,HitNotLast
  LD A,(IX+$09)
  AND $7F
  OR A
  JP NZ,BulletKill
  LD A,(IX+$02)
  OR A
  JP NZ,BulletHitStrong
  LD A,(IY+$04)
  BIT 7,A
  JP NZ,l_D610
  JP BulletKill
BulletHitStrong:
  LD A,(IY+$04)
  BIT 7,A
  JP NZ,BulletKill
l_D610:
  CALL HitObject
  JP NextBullet
BulletKill:
  CALL ShowPoints
NextBullet:
  LD DE,$000F             ; The next bullet record
  ADD IY,DE
  DEC B
  JP NZ,BulletLoop
  RET
HitNotLast:
  LD A,(IX+$09)           ; A hit that is not the object's last: a kind 8
                          ; pauses (its timer IX+$10 = 4); then the next bullet
  AND $7F
  CP $08
  JP NZ,NextBullet
  LD (IX+$10),$03
  JP NextBullet

; A hit: the flash picture, the object turned and paused; no combo score
;
; Changed from REX 1's HitObject $D3C2 (src/game/collisions.asm).
;
; Witness: L1 14 (demo-cycle).
HitObject:
  LD A,(Weapon)
  CP $02
  JP Z,ShowPoints
  CP $04
  CALL Z,StartFall
TurnAround:
  LD A,(IX+$02)           ; Direction ^ 1
  XOR $01
  LD (IX+$02),A
  LD A,$04
  LD (IX+$10),A
  LD HL,FramesHit
  LD (IX+$0A),L
  LD (IX+$0B),H
  LD (IX+$09),$06
  LD (IX+$11),$06
  LD (IX+$14),$02
  LD (IX+$0E),$03
  LD A,(Weapon)
  CP $04
  RET Z
  CP $02
  RET Z
  LD HL,$5843
  LD (KillFlashPtr),HL
  LD A,$09
  LD (ComboCount),A
  LD HL,$0002
  LD (ComboTimer),HL
  LD DE,$0001
  CALL AddScore
  RET

; A hit on an armoured object (kind 6): the flash, more hits needed
;
; Changed from REX 1's HitObjectHard $D41F (src/game/collisions.asm).
;
; Witness: L1 10 (demo-cycle).
HitObjectHard:
  LD A,(Weapon)
  CP $04
  RET Z
  LD A,$04
  LD (IX+$10),A
  LD HL,FramesHit
  LD (IX+$0A),L
  LD (IX+$0B),H
  LD (IX+$09),$06
  LD (IX+$11),$06
  LD (IX+$14),$02
  LD A,(ComboCount)
  DEC A
  RET Z
  LD (ComboCount),A
  LD DE,(ComboTimer)
  CALL AddScore
  LD HL,(ComboTimer)
  LD DE,$0001
  ADD HL,DE
  LD (ComboTimer),HL
  LD HL,(KillFlashPtr)
  LD DE,$0003
  ADD HL,DE
  LD (KillFlashPtr),HL
  RET

; The power pod ($FE): PowerGain, twice for a big one, the pod sound
;
; Changed from REX 1's TakePowerPod $D46C (src/game/collisions.asm).
;
; Witness: L1 22 (d1, demo-cycle).
TakePowerPod:
  PUSH AF
  LD DE,SfxPowerPod
  CALL StartSfx
  LD (IX+$0C),$00
  LD A,$50
  CALL PowerGain
  XOR A
  LD (FadeStepIndex),A
  LD A,(IX+$15)
  OR A
  JP Z,TakePowerPodEnd
  LD A,$A0
  CALL PowerGain
  LD DE,SfxBigPod
  CALL StartSfx
TakePowerPodEnd:
  POP AF
  RET

; The bomb pod ($FD): Bombs + 1 up to 3, the HUD, the sound
;
; As REX 1's TakeBombPod $D494 (src/game/collisions.asm).
;
; Witness: L1 3 (d1, demo-cycle).
TakeBombPod:
  LD (IX+$0C),$00
  LD A,(Bombs)
  INC A
  CP $04
  RET Z
  LD (Bombs),A
  CALL ShowBombs
  LD DE,SfxBombPod
  CALL StartSfx
  RET

; The bonus roulette's five panels: SPEED UP, SHIELD LOSS, 1000 BONUS, ENERGY
; LOSS, 100 RAPID SHOTS
BonusTextTable:
  DEFW BonusTexts,$A3E5,$A3F8,$A40B,RapidShotsText

; The bonus pod ($FC): the panel spins by itself and slows to a stop (no fire
; key); only 100 RAPID SHOTS gives anything, the other prizes show and pass
;
; Changed from REX 1's BonusRoulette $D4B6 (src/game/collisions.asm).
;
; Witness: L1 1 (demo-cycle).
BonusRoulette:
  LD (IX+$0C),$00
  PUSH IX
  PUSH BC
  CALL SoundSilence
  CALL SaveScreen
GameOverTexts:
  LD IX,BonusTexts        ; the game over panel's texts
  LD B,$01
  CALL PrintBoxed
  LD HL,$1388
  LD (BonusDelay),HL
  CALL Random2
  AND $03
  INC A
  LD (BonusRoll),A
  SLA A
  LD E,A
  LD D,$00
  LD HL,BonusTextTable
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  PUSH DE
  POP IX
RouletteShow:
  CALL PrintText          ; show a prize
  INC IX
  LD BC,(BonusDelay)
l_D753:
  PUSH BC
  LD B,$08
l_D756:
  DJNZ l_D756
  POP BC
  DEC BC
  LD A,B
  OR C
  JP NZ,l_D753
  LD HL,(BonusDelay)
  LD DE,$00C8
  AND A
  SBC HL,DE
  LD (BonusDelay),HL
  LD A,H
  OR A
  JP Z,l_D787
  LD A,(BonusRoll)
  INC A
  LD (BonusRoll),A
  CP $05
  JP NZ,RouletteShow
  LD IX,BonusTexts
  XOR A
  LD (BonusRoll),A
  JP RouletteShow
l_D787:
  LD A,(BonusRoll)
  CP $04
  JP Z,PrizeRapidShots
RouletteEnd:
  LD BC,$4E20             ; the screen back
  CALL Delay
  CALL SoundReset
  POP BC
  POP IX
  CALL BufferToScreen
  CALL CopyAttrs
  RET
PrizeRapidShots:
  LD A,$01
  LD (RapidShotsOn),A
  LD A,$64
  LD (RapidShotsLeft),A
  LD HL,RapidShotsText
  JP RouletteEnd
