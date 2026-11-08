; --------------------------------------------------------------------------------------------------------------------
; mainloop.asm: The start of a game, the main loop and the HUD frame
; --------------------------------------------------------------------------------------------------------------------

; Starts a game: the player reset, ammunition 99, grenades 10, the HUD, the
; first screen; then the main loop
;
; Silences the AY ($B753), clears the screen, sets $8269 = $FF, turns the
; player's frames back to facing right when PlayerFlipped $7BDA is set
; (FlipPlayerFrames), $82F7 = 0, $82FA = 1, the player's X, Y ($82F5, $82F6)
; and the restart X, Y ($82F3, $82F4) = $10, $70 (the LD HL is the constant
; $7010, not an address), ammunition $8E5A = 99, grenades $8E66 = 10. DrawHud
; $7690, then $8494 builds the screen (the screen number $8523 is what Start
; left: 0).
;
; MainLoop: one pass of the game, about 2 frames (x2: the fire count rises one
; every 2 frames). It zeroes $9E98 and $9EAE, then calls in order: $BF7E (the
; AY sound step), ReadControls $7B72, $81A4, $8485, $8338, $83DD, $90A2, $9CE3,
; $9152, $9208, $925F, $83DD, $9A23, $9C15, $9835, $9118, $9942, $955D, $83DD,
; $98BA, $BF7E, $925F when $925A < $13 (a grenade in its first frames), $83DD,
; $90A2, $8F54, $8F95, $83DD, $925F again under the same test, $9D7F, $9DD6,
; $9EC1, $9EEE, $A553, $9FBD, $9F2D, $A26B, $A30B, $A360, $A7D6, $A817, $ABCF,
; $AC59, $AC7D, $90EA, $9BB4, $9C8B, $9E64, $A5F4, $AD21 (the pause), $9A19, a
; delay of $01F4 ($B0B7), $BF7E, $9E85, $9E99.
;
; At the end of a pass: ImmunityCount $768D down by one while non-zero,
; PassCount $768C up by one, the 16-bit pass count of the screen $AC7B up by
; one. It never leaves: GAME OVER and the round end jump out from the routines
; it calls. c1: 3263 passes, c128 4181, the warp runs 70 867.
StartGame:
  DI
  CALL AySilence
  CALL ClearScreen        ; a clear screen
  LD A,$FF
  LD (PlayerFrameShown),A
  LD A,(PlayerFlipped)    ; the player's frames facing right again
  OR A
  CALL NZ,FlipPlayerFrames
  XOR A
  LD (JumpStep),A
  INC A
  LD (Facing),A
  LD HL,DefineKeyNotEnter ; X = $10, Y = $70: the player's start and restart
                          ; place
  LD (PlayerX),HL
  LD (RestartX),HL
  LD A,$63                ; 99 shots, 10 grenades
  LD (Ammo),A
  LD A,$0A
  LD (Grenades),A
  CALL DrawHud            ; the HUD, then the screen built ($8494)
  CALL BuildScreen
MainLoop:
  XOR A                   ; one pass of the game, about two frames
  LD (XorSpriteCount),A
  LD (SlotSpriteCount),A
  CALL SoundEffectsTick   ; the AY sound step (three times a pass)
  CALL ReadControls       ; the controls into ControlLeft..ControlFire
  CALL MovePlayer
  CALL ScreenChangeCheck
  CALL FireControl
  CALL MoveShots
  CALL MoveShells
  CALL PlayerDeath
  CALL Mines
  CALL ThrowGrenade
  CALL MoveGrenade
  CALL MoveShots
  CALL MoveBalls
  CALL Traps
  CALL AnimatePuffs
  CALL ColourCycle
  CALL Pods
  CALL MoveDebris
  CALL MoveShots
  CALL Teleports
  CALL SoundEffectsTick
  LD A,(GrenadeTimer)     ; a grenade under way gets an extra step ($925F)
                          ; twice more a pass
  CP $13
  CALL C,MoveGrenade
  CALL MoveShots
  CALL MoveShells
  CALL AnimateFlames
  CALL AnimateTurrets
  CALL MoveShots
  LD A,(GrenadeTimer)
  CP $13
  CALL C,MoveGrenade
  CALL Guns
  CALL MoveGunShots
  CALL PayBonusTick
  CALL RunSparkles
  CALL AlienSpawn
  CALL RunBlasts
  CALL ExoSuitBooth
  CALL HomingMissileStep
  CALL PickupsVsPlayer
  CALL AliensStep
  CALL FlickerPadStep
  CALL ZoneEnd
  CALL ForceFieldStep
  CALL IdleMissileStart
  CALL IdleMissileStep
  CALL ShellsHitPlayer
  CALL BallsTouchPlayer
  CALL TrapContact
  CALL ShellsVsPlayer
  CALL AliensVsPlayer
  CALL PauseKey           ; the pause key 3 ($AD21, PauseKey)
  CALL AbortKeys
  LD BC,$01F4             ; the pass's fixed delay
  CALL Delay
  CALL SoundEffectsTick
  CALL PadXorSprites
  CALL PadSlotSprites
  LD A,(ImmunityCount)    ; the immunity after a restart counts down
  OR A
  JR Z,MainLoopCount
  DEC A
  LD (ImmunityCount),A
MainLoopCount:
  LD HL,PassCount         ; PassCount and the screen's pass count $AC7B
  INC (HL)
  LD HL,(IdleTime)
  INC HL
  LD (IdleTime),HL
  JP MainLoop

; The main loop's pass count (8 bits): its low 3 bits cycle the flashing
; colours of $912A and $ABE8
;
; Raised once a MainLoop pass ($767E).
PassCount:
  DEFB $00
ImmunityCount:
  DEFB $00                ; passes of immunity left after a restart: set to $42
                          ; by the death at $9CCF, zeroed by the screen build
                          ; $849E; while non-zero $9CB4 returns before the hit
                          ; test (the ZXDB immunity POKE is the RET at $9CB8)

; A lone RETI: no interrupt runs here (the game keeps DI) and no code jumps
; here
;
; Never ran in any recording. $A897 loads its address into HL (LD HL,$768E)
; before code that does not seem to use it; perhaps an interrupt handler of a
; version with IM 2 (see SetupIm2 $7BDB). Unsure.
StrayReti:
  RETI

; Draws the HUD: AMMO GRENADES POINTS LIVES ZONES on row 22, the score on row
; 23, then the four counters
;
; Prints HudText $76A2, then $8E4F, $8E5B, $8E67 and $8E7B print the
; ammunition, grenades, lives and the screen number (ZONES). Called by
; StartGame and by the round end ($A8BB).
DrawHud:
  LD HL,HudText
  CALL PrintString
  CALL PrintAmmo
  CALL PrintGrenades
  CALL PrintLives
  JP PrintZone

; The HUD text: the labels on row 22 in their colours, row 23 cleared, the
; score sub-string $AD82
;
; AT 22,0, the font $D7E0, the occupancy value 1 and the foreground value 0 for
; these cells ($E8 01, $E9), AMMO bright cyan, GRENADES bright yellow, POINTS
; bright green, LIVES bright white, ZONES bright magenta; AT 23,0, 32 spaces,
; then the sub-string $AD82 (the score digits $AD8A at their place).
HudText:
  DEFB $DF,$16,$00,$E6,$E0,$D7,$E8,$01
  DEFB $E9,$DC,$41,$4D,$4D,$4F,$20,$DD
  DEFB $47,$52,$45,$4E,$41,$44,$45,$53
  DEFB $20,$DB,$50,$4F,$49,$4E,$54,$53
  DEFB $20,$DE,$4C,$49,$56,$45,$53,$20
  DEFB $DA,$5A,$4F,$4E,$45,$53,$DF,$17
  DEFB $00,$E4,$20,$20,$E3,$82,$AD,$FF
