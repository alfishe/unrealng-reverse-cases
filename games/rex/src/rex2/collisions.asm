; --------------------------------------------------------------------------------------------------------------------
; collisions.asm: The collisions: shots and objects against Rex, Rex's shots against objects, the pods
; --------------------------------------------------------------------------------------------------------------------

; Each enemy bullet in Rex's box: the shield takes it (faster drain), else Rex
; dies
;
; As REX 1's EnemyBulletsHitRex $D1B9 (src/game/collisions.asm).
;
; Witness: L1 10871 (c2, p2-room20, rzx-p2- x21).
EnemyBulletsHitRex:
  LD A,(Dying)
  OR A
  RET NZ
  LD A,(SparkleMode)
  OR A
  RET NZ
  LD IY,$5D22
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
  CALL RexDies
EnemyBulletNext:
  LD DE,$000F
  ADD IY,DE
  DEC B
  JP NZ,EnemyBulletLoop
  RET

; The object at IX against Rex: its box (written into the compares at $D00F,
; $D01A, $D01F, $D0A8, $D0B9; the mine smaller); the shield kills it, else Rex
; dies unless it dissolves; pods are taken; then Rex's bullets against it
;
; Changed from REX 1's ObjectHitsRex $D215 (src/game/collisions.asm).
;
; Witness: L1 45603 (c2, p2-room20, rzx-p2- x20).
ObjectHitsRex:
  LD A,(Dying)
  OR A
  RET NZ
  LD A,$1E
  LD (ObjectBoxTest+$0013),A
  LD A,$16
  LD (ObjectBoxTest+$0023),A
  LD A,$10
  LD (BulletBoxHeight+$0001),A
  LD (BulletBoxWidth+$0001),A
  LD A,$10
  LD (ObjectBoxTest+$001E),A
  LD A,(IX+$02)
  OR A
  JP Z,ObjectBoxKind
  LD A,$08
  LD (ObjectBoxTest+$001E),A
ObjectBoxKind:
  LD A,(IX+$09)           ; the box by kind
  AND $7F
  CP $0E
  JP Z,ObjectBoxSmall
  JP ObjectBoxTest
ObjectBoxSmall:
  LD A,$16                ; kinds 14, 15: a small box
  LD (ObjectBoxTest+$0013),A
  LD A,$0E
  LD (ObjectBoxTest+$0023),A
  LD A,$08
  LD (BulletBoxHeight+$0001),A
  LD (BulletBoxWidth+$0001),A
ObjectBoxTest:
  LD A,(SparkleMode)      ; the test against Rex's place
  OR A
  JP NZ,BulletsHitObject
  LD HL,RexY
  LD A,(IX+$01)
  SUB $10
  CP (HL)
  JR NC,BulletsHitObject
  ADD A,$1E
  CP (HL)
  JR C,BulletsHitObject
  LD HL,RexX
  LD A,(IX+$00)
  SUB $10
  CP (HL)
  JR NC,BulletsHitObject
  ADD A,$16
  CP (HL)
  JR C,BulletsHitObject
  LD A,(ShieldOn)
  OR A
  JP Z,ObjectHitsRexLive
  LD A,(IX+$09)
  CP $FE
  JP Z,ObjectHitsRexLive
  CP $FD
  JP Z,ObjectHitsRexLive
  CP $FC
  JP Z,ObjectHitsRexLive
  CALL KillObject
  LD A,(IX+$14)
  SLA A
  SLA A
  LD L,A
  CALL ShieldDrainFast
  JP ObjectTakePod
ObjectHitsRexLive:
  LD A,(IX+$18)           ; a dissolving object: only the bullets
  OR A
  JP NZ,BulletsHitObject
  LD A,(IX+$09)
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

; Rex's 30 bullets against the object at IX: kind $82 is immune, kind $84 only
; while open; a hit object takes damage or is killed
;
; Witness: L1 36506 (c2, p2-room20, rzx-p2- x20).
BulletsHitObject:
  LD A,(IX+$09)
  CP $82
  RET Z
  CP $84
  JP NZ,BulletsScan
  LD A,(IX+$12)
  OR A
  RET Z
BulletsScan:
  LD IY,$5B60             ; the bullets from $5B60
  LD B,$1E

; Rex's bullets against the object at IX: the laser goes through, the others
; flash; kind 6 HitObjectHard; each hit counts down its hits; the last on a
; kind 0 from the front turns it (HitObject), from behind or any other kind
; kills it
;
; Changed from REX 1's BulletLoop $D2FC (src/game/collisions.asm).
;
; Witness: L1 846205 (c2, p2-room20, rzx-p2- x20).
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
  JP NZ,BulletHitDir
  JP BulletKill
BulletHitStrong:
  LD A,(IY+$04)
  BIT 7,A
  JP NZ,BulletKill
BulletHitDir:
  CALL HitObject          ; by the bullet's direction (IY+4 bit 7)
  JP NextBullet
BulletKill:
  CALL KillObject

; The next bullet record; a hit that is not the last pauses a kind 8 (timer 4)
;
; Changed from REX 1's NextBullet $D3A7 (src/game/collisions.asm).
;
; Witness: L1 846207 (c2, p2-room20, rzx-p2- x20).
NextBullet:
  LD DE,$000F
  ADD IY,DE
  DEC B
  JP NZ,BulletLoop
  RET
; This entry point is used by the routine at BulletLoop.
HitNotLast:
  LD A,(IX+$09)           ; a hit that is not the last: a kind 8 pauses (timer
                          ; IX+$10 = 4)
  AND $7F
  CP $08
  JP NZ,NextBullet
  LD (IX+$10),$04
  JP NextBullet

; A hit: the flash picture SpriteHitFlash $8258, the combo score (ComboCount
; $A1D4), the object killed after its hits
;
; As REX 1's HitObject $D3C2 (src/game/collisions.asm).
;
; Witness: L1 16 (rzx-p2- x10).
HitObject:
  LD A,(Weapon)
  CP $02
  JP Z,KillObject
  CP $04
  CALL Z,StartFall
ClimbTurn:
  LD A,(IX+$02)
  XOR $01
  LD (IX+$02),A
  LD A,$04
  LD (IX+$10),A
  LD HL,ShiftFrames6
  LD (IX+$0A),L
  LD (IX+$0B),H
  LD HL,SpriteHitFlash
  LD (IX+$16),L
  LD (IX+$17),H
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

; A hit on an armoured object: the flash, more hits needed
;
; As REX 1's HitObjectHard $D41F (src/game/collisions.asm).
;
; Witness: L1 14 (rzx-p2- x5).
HitObjectHard:
  LD A,(Weapon)
  CP $04
  RET Z
  LD A,$04
  LD (IX+$10),A
  LD HL,ShiftFrames6
  LD (IX+$0A),L
  LD (IX+$0B),H
  LD HL,SpriteHitFlash
  LD (IX+$16),L
  LD (IX+$17),H
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

; The power pod ($FE): PowerGain twice if it is a big one, the pod sound
;
; As REX 1's TakePowerPod $D46C (src/game/collisions.asm).
;
; Witness: L1 44 (rzx-p2- x14).
TakePowerPod:
  PUSH AF
  LD DE,SfxPowerPod
  CALL StartSfx
  LD (IX+$0C),$00
  LD A,$26
  CALL PowerGain
  XOR A
  LD (FadeStepIndex),A
  LD A,(IX+$15)
  OR A
  JP Z,TakePowerPodEnd
  LD A,$26
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
; Known only from the code: no recording runs it.
;
; Witness: L1 0 ().
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

; The bonus panels' texts: $ABFE, $AC11, $AC24, $AC37, $AC4A
BonusTextTable:
  DEFW BonusTexts,ShieldLossText,BonusPointsText,EnergyLossText,RapidShotsText

; The bonus pod ($FC): a panel cycles through the five prizes until fire (or it
; slows to a stop); the prize given
;
; As REX 1's BonusRoulette $D4B6 (src/game/collisions.asm).
;
; Known only from the code: no recording runs it.
;
; Witness: L1 0 ().
BonusRoulette:
  LD (IX+$0C),$00
  PUSH IX
KillHumanSet:
  PUSH BC                 ; its picture and size
  CALL SoundSilence
  CALL SaveScreen
  LD BC,$4E20
  CALL Delay
  LD IX,BonusTexts
  LD B,$01
  CALL PrintBoxed
  LD HL,$1CE8
  LD (BonusDelay),HL
  CALL Random
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
RouletteWait:
  PUSH BC                 ; wait for fire, slowing down
  CALL ReadFire
  POP BC
  JP Z,RouletteGive
  DEC BC
  LD A,B
  OR C
  JP NZ,RouletteWait
  LD HL,(BonusDelay)
  LD DE,$00C8
  AND A
  SBC HL,DE
  LD (BonusDelay),HL
  LD A,H
  OR A
  JP Z,RouletteGive
  LD A,(BonusRoll)
  INC A
  LD (BonusRoll),A
  CP $05
  JP NZ,RouletteShow
  LD IX,BonusTexts
  XOR A
  LD (BonusRoll),A
  JP RouletteShow
RouletteGive:
  LD A,(BonusRoll)        ; give the prize shown
  OR A
  JP Z,PrizeSpeedUp
  CP $01
  JP Z,PrizeShieldLoss
  CP $02
  JP Z,PrizeBonus
  CP $03
  JP Z,PrizeEnergyLoss
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
PrizeSpeedUp:
  LD A,$01
  LD (SpeedUp),A
  LD A,$C8
  LD (SpeedUpPhase),A
  LD HL,BonusTexts
  JP RouletteEnd
PrizeShieldLoss:
  LD L,$14
  CALL ShieldDrainFast
  LD HL,ShieldLossText
  JP RouletteEnd
PrizeBonus:
  LD DE,$000A
  CALL AddScore
  LD HL,BonusPointsText
  JP RouletteEnd
PrizeEnergyLoss:
  CALL LosePower
  CALL DrawHud
  LD HL,EnergyLossText
  JP RouletteEnd
PrizeRapidShots:
  LD A,$01
  LD (RapidShotsOn),A
  LD A,$64
  LD (RapidShotsLeft),A
  LD HL,RapidShotsText
  JP RouletteEnd

; Lives + 1 up to 9, ShowLives
;
; As REX 1's ExtraLife $D5A0 (src/game/collisions.asm).
;
; Witness: L1 1 (rzx-p2-10000).
ExtraLife:
  LD A,(Lives)
  INC A
  CP $0A
  RET Z
  LD (Lives),A
  CALL ShowLives
  RET
