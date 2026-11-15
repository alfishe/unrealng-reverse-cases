; --------------------------------------------------------------------------------------------------------------------
; entry.asm: The entry, a new game, the waits for fire
; --------------------------------------------------------------------------------------------------------------------

; The code block's entry (USR 38010): DI, the menu, the high score, then
; NewGame
;
; As REX 1's GameEntry $947A (src/game/entry.asm).
;
; Witness: L1 1 (c2).
GameEntry:
  DI
  XOR A
  LD (ControlXor),A
  LD (AttractFlag),A
  CALL TitleMenu
  LD HL,TitleScreen
  LD DE,TitleScreen+$0001
  LD BC,$02FF
  LD (HL),$00
  LDIR
  LD HL,$000A
  LD (HiScore),HL

; A new game: the variables reset, score, lives, bombs and shield from the code
; ($A263, $A267, $A266, $A265), StartWeapon, PHASE TWO:ENTER THE LIVING TOWER
; TO REACH ZENITH and PRESS FIRE TO BEGIN, the wait for fire, Rex materialises
;
; Changed from REX 1's NewGame $9498 (src/game/entry.asm).
;
; Witness: L1 5 (c2, rzx-p2-00000).
NewGame:
  CALL InitDrones
  LD A,$08
  LD (FireDelay),A
  XOR A
  OUT ($FE),A
  LD (Immune),A
  LD A,$00
  LD (Room),A
  XOR A
  LD (BossDying),A
  LD (AnimCount1),A
  LD (AnimCount2),A
  LD (AnimCount4),A
  LD (AnimCount1),A
  LD (AnimCount3),A
  LD (RestartRoom),A
  LD (RestartFacing),A
  LD (SpeedUp),A
  LD (SpeedUpPhase),A
  LD (DoubleFireText),A
  LD (LaserText),A
  LD (MultipleText),A
  LD (SprayText),A
  LD (Dying),A
  XOR A
  LD (SweepPos),A
  LD (SweepDir),A
  LD HL,$0313
  LD (RandomSeed),HL
  LD A,$11
  LD (RandomSeed2),A
  LD HL,(CodeScore)
  LD (Score),HL
  LD (GrowthsKilled),HL
  LD A,(CodeLives)
  LD (Lives),A
  LD A,(CodeBombs)
  LD (Bombs),A
  CALL StartWeapon
  LD A,(CodeShield)
  LD (ShieldEnergy),A
  LD A,$02
  LD (ShieldDrainRate),A
  LD HL,(Score)
  LD DE,$0064
NewGameScore:
  AND A                   ; Score - 100
  SBC HL,DE
  JP NC,NewGameScore
  ADD HL,DE
  LD (ExtraLifeCount),HL
  LD A,$01
  LD (WeaponIcon),A
  XOR A
  LD (RapidShotsOn),A
  LD (ObjectHitCount),A
  LD (SmartBombOn),A
  LD (RexFrame),A
  LD (ShieldOn),A
  LD A,$70
  LD (RexX),A
  LD (RestartX),A
  LD A,$30
  LD (RexY),A
  LD (RestartY),A
  XOR A
  LD (RexFacing),A
  LD (Jumping),A
  LD (RexSpeed),A
  LD (FallSpeed),A
  XOR A
  LD (PowerCount),A
  LD A,$FF
  LD (FadeStepIndex),A
  LD A,$00
  CALL ClearScreen
  CALL DrawHud
  CALL ShowLives
  CALL ShowScore
  CALL SaveAttrs
  LD IX,GameTexts
  LD B,$03
  CALL PrintBoxed
  CALL WaitFireOrAttract
  LD IX,PressFireText
  LD B,$02
  CALL PrintBoxed
  CALL WaitFireOrAttract
  LD A,(Temp1)
  OR A
  JP Z,Attract
  CALL SoundReset
  CALL Materialise

  ORG $97AB

; Wait for fire for up to 50000 polls; none starts the attract mode
;
; As REX 1's WaitFireOrAttract $97C3 (src/game/entry.asm).
;
; Witness: L1 10 (c2, rzx-p2-00000).
WaitFireOrAttract:
  XOR A
  LD (Temp1),A
  CALL SoundSilence
  LD DE,50000
WaitFireCount:
  DEC DE                  ; the 50000-poll count
  LD A,D
  OR E
  RET Z
  LD B,$1E
WaitFireDelay:
  DJNZ WaitFireDelay      ; a short delay between polls
  CALL ReadFire
  JP NZ,WaitFireCount
WaitFireRelease:
  CALL ReadFire           ; fire must be released first
  JP Z,WaitFireRelease
  CALL SoundReset
  LD A,$01
  LD (Temp1),A
  RET

; Wait for fire up, then for fire (no timeout): after the game over and the
; CODE panel
;
; As REX 1's WaitFire $97EA (src/game/entry.asm).
;
; Known only from the code: no recording runs it.
;
; Witness: L1 0 ().
WaitFire:
  CALL SoundSilence
WaitFireUp:
  CALL ReadFire           ; wait for fire up
  JP NZ,WaitFireUp
WaitFireDown:
  CALL ReadFire           ; wait for fire
  JP Z,WaitFireDown
  CALL SoundReset
  RET

; REX 1's ShowPoints (the points sign SpritePoints $84D8, kind $FF); KillObject
; does it inline, nothing calls this (leftover)
;
; Witness: L1 0 ().
ShowPointsUnused:
  LD HL,SpritePoints
  LD (IX+$04),L
  LD (IX+$05),H
  LD (IX+$0D),$08
  LD (IX+$0F),$18
  LD (IX+$0E),$03
  LD (IX+$09),$FF
  LD (IX+$02),$00
  LD (IX+$03),$00
  RET
