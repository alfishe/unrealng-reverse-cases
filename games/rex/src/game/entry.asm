; --------------------------------------------------------------------------------------------------------------------
; entry.asm: The entry, a new game, the waits for fire
;
; The BASIC's RANDOMIZE USR 38010 lands at GameEntry: interrupts off for good (the game never waits for a frame: one
; pass of the main loop is as long as its work), the title and menu (TitleMenu $DAC0), then the high score 10 and
; NewGame. NewGame resets every variable (4 lives, 3 smart bombs, shield 99), clears the screen, draws the HUD, prints
; PHASE ONE and PRESS FIRE TO BEGIN and waits for fire; no fire for 50000 polls starts the attract mode (Attract
; $A915). Rex then materialises in room 1 and the main loop runs.
; --------------------------------------------------------------------------------------------------------------------

; The code block's entry (USR 38010): DI, the menu, the high score, then
; NewGame
;
; Clears ControlXor $A0AE (keys, not Kempston) and AttractFlag $A0C2, calls
; TitleMenu $DAC0, clears the attribute shadow $E4FF-$E7FE (the title screen's
; bytes, no longer needed) and sets HiScore $A08B = 10. Falls into NewGame.
;
; Witness: L1 1 (c1).
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

; A new game: every variable reset, the HUD, PHASE ONE and PRESS FIRE TO BEGIN,
; the wait for fire, Rex materialises
;
; Also the target of ENTER in the main loop (restart), of the game over and of
; the attract mode. InitDrones $A628; border black; Lives $A063 = 4, Bombs
; $A06C = 3, ResetPower $BA49, ShieldEnergy $A04D = 99, the weapons held
; $A050-$A053 = 0, the score, HumansKilled $A089 and the extra life count 0,
; the random seeds $A0A1 = $0313, $A0A3 = $11; Rex at X $A0, Y $60 in room 1
; facing right, the restart point the same. Then ClearScreen $A3AE, DrawHud
; $A1A5, ShowLives $99BB, SaveAttrs $CF8F, the texts PhaseOneText $AAAE and
; PressFireText $AB25 (PrintBoxed $A13E) each followed by WaitFireOrAttract
; $97C3; SoundReset $D5AE and Materialise $9D1F. Falls into MainLoop.
;
; Witness: L1 9 (c1, p1-code, p1-cursor, p1-define, p1-kempston, rzx-p1-00000,
; rzx-p1-64000).
NewGame:
  CALL InitDrones
  LD A,$08
  LD (FireDelay),A
  XOR A
  OUT ($FE),A
  LD (Immune),A
  LD (Room),A
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
  LD HL,$0000
  LD (Score),HL
  LD (ExtraLifeCount),HL
  LD (HumansKilled),HL
  LD A,$04
  LD (Lives),A
  LD A,$03
  LD (Bombs),A
  CALL ResetPower
  LD A,$63
  LD (ShieldEnergy),A
  LD A,$02
  LD (ShieldDrainRate),A
  LD A,$01
  LD (WeaponIcon),A
  XOR A
  LD (HasDoubleFire),A
  LD (HasLaser),A
  LD (HasMultiple),A
  LD (HasSpray),A
  XOR A
  LD (RapidShotsOn),A
  LD (ObjectHitCount),A
  LD (SmartBombOn),A
  LD (RexFrame),A
  LD (ShieldOn),A
  LD A,$A0
  LD (RexX),A
  LD (RestartX),A
  LD A,$60
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

  ORG $97C3

; Wait up to 50000 polls for fire: Temp1 = 1 after a press and its release, 0
; when the count runs out
;
; Temp1 = 0 and the sound silenced, then DE = 50000 counted down, a DJNZ delay
; of 30 before each poll of ReadFire $A477. A press: wait for its release
; (WaitFireRelease), SoundReset $D5AE, Temp1 = 1, RET. The count out: RET with
; Temp1 0 and the sound still off. NewGame's second call tests Temp1 and jumps
; to Attract $A915 on 0; the weapon panel (WeaponPanel) ignores it.
;
; Witness: L1 20 (c1, p1-code, p1-cursor, p1-define, p1-kempston, rzx-p1- x5).
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

; Wait for fire, then for its release (no timeout): after the game over and the
; CODE panel
;
; Witness: L1 3 (c1, p1-code, p1-gameover).
WaitFire:
  CALL SoundSilence
WaitFireDown:
  CALL ReadFire           ; wait for fire pressed
  JP NZ,WaitFireDown
WaitFireUp:
  CALL ReadFire           ; wait for fire released
  JP Z,WaitFireUp
  CALL SoundReset
  RET
