; --------------------------------------------------------------------------------------------------------------------
; collisions.asm: The collisions: shots and objects against Rex, Rex's shots against objects, the pods
; --------------------------------------------------------------------------------------------------------------------

; Each enemy bullet in Rex's box: the shield takes it (faster drain), else Rex
; dies
;
; Witness: L1 18613 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x32).
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

; The object at IX against Rex: its box (written into the compares at $D28E,
; $D29E, $D299, $D310, $D321 by kind); the shield kills it, else Rex dies; pods
; are taken; then Rex's bullets against it
;
; Witness: L1 82130 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x32).
ObjectHitsRex:
  LD A,(Dying)
  OR A
  RET NZ
  LD A,$1E
  LD (BoxHeightAdd+$0001),A
  LD A,$16
  LD (BoxWidthAdd+$0001),A
  LD A,$10
  LD (BulletBoxHeight+$0001),A
  LD (BulletBoxWidth+$0001),A
  LD A,$10
  LD (BoxLeftSub+$0001),A
  LD A,(IX+$02)
  OR A
  JP Z,ObjectBoxKind
  LD A,$08
  LD (BoxLeftSub+$0001),A
ObjectBoxKind:
  LD A,(IX+$09)           ; the box by kind
  AND $7F
  CP $10
  JP Z,ObjectBoxBig
  CP $0E
  JP Z,ObjectBoxSmall
  CP $0F
  JP Z,ObjectBoxSmall
  JP ObjectBoxTest
ObjectBoxBig:
  LD A,$3E                ; kind 16: a big box
  LD (BoxHeightAdd+$0001),A
  LD A,$36
  LD (BoxWidthAdd+$0001),A
  LD A,$30
  LD (BulletBoxHeight+$0001),A
  LD (BulletBoxWidth+$0001),A
  JP ObjectBoxTest
ObjectBoxSmall:
  LD A,$16                ; kinds 14, 15: a small box
  LD (BoxHeightAdd+$0001),A
  LD A,$0E
  LD (BoxWidthAdd+$0001),A
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
  CALL KillObject
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

; Rex's 30 bullets against the object at IX: a hit object takes damage
; (HitObject, HitObjectHard) or is killed
;
; Witness: L1 76882 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x32).
BulletsHitObject:
  LD IY,$5B60
  LD B,$1E

; BulletLoop
;
; Used by the routine at NextBullet.
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
  JP NZ,BulletHitDo
  JP BulletKill
BulletHitStrong:
  LD A,(IY+$04)
  BIT 7,A
  JP NZ,BulletKill
BulletHitDo:
  CALL HitObject
  JP NextBullet
BulletKill:
  CALL KillObject

; The next bullet record
;
; Witness: L1 2344896 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x32).
NextBullet:
  LD DE,$000F
  ADD IY,DE
  DEC B
  JP NZ,BulletLoop
  RET

; A hit that is not the object's last: a kind 8 pauses (its timer IX+$10 = 4);
; then the next bullet
;
; Witness: L1 951 (c1, p1-code, p1-gameover, p1-poke41241, p1-shots,
; p1-speedup, p1-room24, p1-room30, rzx-p1- x30).
HitNotLast:
  LD A,(IX+$09)
  AND $7F
  CP $08
  JP NZ,NextBullet
  LD (IX+$10),$04
  JP NextBullet

; A hit: the flash picture SpriteHitFlash $8632, the combo score (ComboCount
; $A03B; none for the spray, Weapon 4), the object killed after its hits (the
; laser, Weapon 2, kills at once)
;
; Witness: L1 76 (p1-speedup, p1-room30, rzx-p1- x20).
HitObject:
  LD A,(Weapon)
  CP $02
  JP Z,KillObject
  CP $04
  CALL Z,StartFall
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
; Witness: L1 90 (p1-speedup, p1-room30, rzx-p1- x13).
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
; Witness: L1 139 (p1-speedup, p1-room30, rzx-p1- x27).
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
; Witness: L1 3 (p1-room30, rzx-p1-52000, rzx-p1-54000).
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
  DEFW BonusTexts,ShieldLossText,BonusPointsText,EnergyLossText,RapidShotsText

; The bonus pod ($FC): a panel cycles through the five prizes until fire (or it
; slows to a stop); the prize given
;
; SPEED UP ($A072 = 1, 200 passes), SHIELD LOSS (drain 20), 1000 BONUS
; (AddScore 10), ENERGY LOSS (LosePower, the HUD), 100 RAPID SHOTS ($A040 = 1,
; $A041 = 100). The screen is saved first (SaveScreen $D8A3) and restored
; after.
;
; Witness: L1 3 (p1-speedup, rzx-p1-50000, rzx-p1-56000).
BonusRoulette:
  LD (IX+$0C),$00
  PUSH IX
  PUSH BC
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
; Witness: L1 10 (p1-code, rzx-p1- x9).
ExtraLife:
  LD A,(Lives)
  INC A
  CP $0A
  RET Z
  LD (Lives),A
  CALL ShowLives
  RET
