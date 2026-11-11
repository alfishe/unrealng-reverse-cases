; --------------------------------------------------------------------------------------------------------------------
; mainloop.asm: The main loop, the end of a game and the restart after a lost life
; --------------------------------------------------------------------------------------------------------------------

; The main loop: one pass of the game, no frame sync
;
; One pass: `$5BA0` = 1 (`$AF81` clears it on the lift); IX = the hero record
; `$5B04`; when Room `$5C01` equals the lift's room `$5B9E`, `$AF81` (the
; lift); `$A3E1` (the hero: input, movement, the Status handlers); when
; LifeLost `$5C2A` is set, Respawn `$9090`; else `$B9FA` (the items),
; RoomEffects `$91C0`, CountDown `$935D` (one minute a pass), `$BE98` (the
; creatures), `$9B22` (the sprites; it calls ShowCapsules `$92BD`); GameOver
; `$5BFF` set ends the game (EndGame `$906D`); PassCount `$5C02` + 1.
;
; The keys at the end of a pass: Q held with CAPS SHIFT ends the game (the
; abort: c1 and explorers, 6 runs of `$9059`); Q held with A held freezes the
; game until A is let go (`$9062`, not executed in any recording); Q alone does
; nothing.
;
; There is no HALT: a pass takes as long as its work. In the rzx segments the
; day rolls over (`$936B`, 13 runs, one in every segment of about 4000 frames)
; every 1440 passes, so a pass is about 2.8 frames (WALKTHROUGH 1: 2.4 to 3.3).
;
; Witness: L1 26517 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
MainLoop:
  LD A,$01                ; $5BA0 = 1 every pass ($AF81 clears it)
  LD (NotOnLift),A
  LD IX,Hero
  LD A,(Room)            ; in the lift's room ($5B9E)? the lift $AF81
  LD HL,LiftRoom
  CP (HL)
  CALL Z,LiftPlatform
  CALL HeroUpdate         ; the hero: input, movement, Status
  LD A,(LifeLost)            ; a life lost ($5C2A set by $A9EE)? respawn
  OR A
  JR NZ,Respawn
  CALL ItemsPass
  CALL RoomEffects        ; the flames, beams and capsules
  CALL CountDown          ; one minute off the countdown every pass
  CALL RunCreatures
  CALL RenderPass
  LD A,(GameOver)            ; GameOver set (the space scene ended, or the
                          ; ending)?
  OR A
  JR NZ,EndGame
  LD A,(PassCount)            ; PassCount + 1
  INC A
  LD (PassCount),A
  LD A,$FB                ; Q held?
  IN A,($FE)
  AND $01
  JP NZ,MainLoop
  LD BC,$FEFE             ; and CAPS SHIFT: abort
  IN A,(C)
  AND $01
  JR Z,EndGame
FreezeWhileA:
  LD A,$FD                ; Q without CAPS SHIFT: wait while A is held
  IN A,($FE)
  AND $01
  JR Z,FreezeWhileA
  JP MainLoop

; End a game: the high score, the panel saved, the base tile set back, the menu
;
; Reached from MainLoop `$9018` when GameOver `$5BFF` is set (gameover frame
; 1962 after the space scene; rzx50000 frame 732 after the ending) or on CAPS
; SHIFT + Q (c1, explorers).
;
; `$BD50` keeps the score as the high score when it is higher; then the panel
; (the screen's bottom third `$5000-$57FF` and its attributes `$5A00-$5AFF`) is
; saved to `$E000-$E7FF` and `$E800-$E8FF`, where DeviceMenu `$93AF` takes its
; frame pieces from and InitGame `$8F69` restores it; when the alternate tile
; set is in (AltTileset `$918C` not 0), SwapTileset `$918D` puts the base set
; back (not executed in any recording: every game ended in a base-set room);
; `JP $8F47`.
;
; Witness: L1 8 (c1, explorers, gameover, rzx).
EndGame:
  CALL NewHiScore
  LD HL,Screen+4096             ; the panel's bitmap to $E000
  LD DE,BackBuffer
  LD BC,$0800
  LDIR
  LD HL,Attributes+512             ; its attributes to $E800
  LD DE,SavedPanelAttrs
  LD BC,$0100
  LDIR
  LD A,(AltTileset)       ; the base tile set back for the next game
  OR A
  CALL NZ,SwapTileset
  JP NewGame

; Restart after a lost life from the respawn state
;
; Reached from MainLoop `$9018` when LifeLost `$5C2A` is set (`$A9EE` sets it
; to `$32` when StatusTimer `$5C07` reaches 50 and takes a life). gameover
; frame 1509 (the last life; `$A9EE` went on to LoseGame `$9372`, which put
; room `$28` and Status `$1D` in the respawn state, so this respawn starts the
; space scene), rzx 4 runs.
;
; Clears LifeLost and `$5C05`; copies the respawn state back: Status `$5C06`
; from `$5C2B`, StatusTimer `$5C07` from `$5C2C`, the hero record `$5B04-$5B07`
; from `$5C2E-$5C31`, Room `$5C01` from `$5C2D`, the lift `$5B9E-$5B9F` from
; `$5C32-$5C33` (`$9AA1` writes the state on every room entry); the room set-up
; `$9855`; `$5B9B` = `$FE`; back to MainLoop.
;
; Witness: L1 5 (gameover, rzx, rzx, rzx, rzx).
Respawn:
  XOR A
  LD (LifeLost),A
  LD (FallPasses),A
  LD A,(RespawnStatus)
  LD (Status),A
  LD A,(RespawnTimer)
  LD (StatusTimer),A
  LD HL,(RespawnXY)
  LD (Hero),HL
  LD HL,(RespawnFrame)
  LD (Hero+2),HL
  LD A,(RespawnRoom)
  LD (Room),A
  LD HL,(RespawnLift)
  LD (LiftRoom),HL
  CALL SetUpRoom
  LD A,$FE
  LD (Thought+2),A
  JP MainLoop
