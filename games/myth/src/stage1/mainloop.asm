; --------------------------------------------------------------------------------------------------------------------
; mainloop.asm: The main loop and its pass
;
; MainLoop $7839 runs one game step a pass, with no frame sync: about 3 frames a pass in c1's play window, 18 at a
; room change (WALKTHROUGH 1.2). PacePass pads the light rooms with a busy wait. A pass ends with SPACE (the item
; window), CAPS SHIFT + SPACE (quit) or the end of the lives.
; --------------------------------------------------------------------------------------------------------------------

  ORG $7839

; One pass: pace, HUD, input, actors, draw, copy; SPACE opens the item window
;
; The pass, in order: PacePass, ShowPieceTaken, FlashPieces, CheckPause
; (ENTER), $8D1D, RedrawItemsIfChanged, ClearBuffer, CheckStageExit (may leave
; to EndStage), the missiles $B2E6, $A5BD, $A5DF (the actors drawn into the
; buffer), $89BB, $8A2E, $8930, $A28B, KeyHook, $8CAA (attributes and
; CopyBuffer), $984D (energy, lives flash, game over step), ShowScore, then the
; SPACE test $8A54.
;
; SPACE with CAPS SHIFT ends the stage with E = 1 (QuitStage); SPACE alone
; opens ItemWindow unless the hero is in state $0F (dying; the hero record's
; +$0A at $74EA). The loop goes on while Lives is not 0 or the hero's state is
; not 0; with no lives and the hero back in state 0 it ends with E = 0
; (GameOverExit).
;
; Witness: L1 10187 (c1o, deaths, s1-idle, s1-right).
MainLoop:
  CALL PacePass
  CALL ShowPieceTaken
  CALL FlashPieces
  CALL CheckPause
  CALL SpawnTimer
  CALL RedrawItemsIfChanged
  CALL ClearBuffer
  CALL CheckStageExit
  CALL UpdateMissiles
  CALL RunActorHandlers
  CALL DrawActors
  CALL DrawArenaPicture
  CALL ZoneDamage
  CALL DrawRoomPicture
  CALL UpdateBurst
  CALL KeyHook
  CALL UpdateAttributes
  CALL PassTick
  CALL ShowScore
  CALL TestSpaceKey
  JR NZ,MainLoopNext
MainLoopSpace:
  LD BC,$FEFE             ; SPACE pressed: CAPS SHIFT too quits, else the item
                          ; window
  IN A,(C)
  BIT 0,A
  JP Z,QuitStage
  LD A,(HeroState)
  CP $0F
  CALL NZ,ItemWindow
MainLoopNext:
  LD A,(Lives)            ; go on while lives are left or the hero is not back
                          ; in state 0
  CP $00
  JR NZ,MainLoop
  LD A,(HeroState)
  CP $00
  JR NZ,MainLoop

; No lives: end the stage with E = 0
;
; Reached from MainLoop when Lives and the hero's state $74EA are both 0. E =
; 0, then EndStage.
;
; Witness: L1 1 (s1-right).
GameOverExit:
  LD E,$00
  JP EndStage

; CAPS SHIFT + SPACE: end the stage with E = 1
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code ($787E).
QuitStage:
  LD E,$01

; Leave the stage: hide the HUD boxes, save the HUD, fade, return E, H = lives,
; BC = the score's digits
;
; E (pushed) is the outcome: 0 game over (GameOverExit), 1 quit (QuitStage), 2
; stage completed (StageExit). Clears the play buffer, hides the pieces boxes
; and the lives boxes with two inline attribute fills ($8C3D), saves the HUD
; attributes (rows 0-5) to $7600, clears the score, the two middle HUD fields,
; the item strip and the pieces field with CopyToScreen from the cleared buffer
; (stride 0), saves the HUD bitmap (lines 0-47) to $7000 ($8A89), fades the
; screen (FlashFadeScreen), clears it ($8B92), waits 100 frames ($8C35) and
; returns to the stage loader with E, BC = ScoreDigitsHigh (the six score
; digits) and H = Lives.
;
; Witness: L1 1 (s1-right).
EndStage:
  PUSH DE
  CALL ClearBuffer
  CALL FillAttributes

; $8C3D's inline record: column 25, line 24, 6 x 2 cells, attribute 1 (the
; pieces boxes hidden)
EndPiecesBox:
  DEFB $19,$18,$06,$02,$01

; EndStage, continued: hide the lives boxes
;
; Part of EndStage, after the first inline record.
;
; Witness: L1 1 (s1-right).
EndStageLives:
  CALL FillAttributes

; $8C3D's inline record: column 1, line 24, 6 x 2 cells, attribute 1 (the lives
; boxes hidden)
EndLivesBox:
  DEFB $01,$18,$06,$02,$01

; EndStage, continued: save the HUD, clear its fields, fade, return
;
; Part of EndStage, after the second inline record.
;
; Witness: L1 1 (s1-right).
EndStageSave:
  LD HL,Attributes
  LD DE,HudColours
  LD BC,$00C0
  LDIR
  LD HL,PlayBuffer
  LD BC,$0608
  LD DE,$0608
  LD A,$00
  CALL CopyToScreen
  LD HL,PlayBuffer
  LD BC,$0E08
  LD DE,$0408
  LD A,$00
  CALL CopyToScreen
  LD HL,PlayBuffer
  LD BC,$1408
  LD DE,$0608
  LD A,$00
  CALL CopyToScreen
  LD HL,PlayBuffer
  LD BC,$0A18
  LD DE,$0C10
  LD A,$00
  CALL CopyToScreen
  LD HL,PlayBuffer
  LD BC,$1918
  LD DE,$0610
  LD A,$00
  CALL CopyToScreen
  LD HL,HudPicture
  LD BC,$0000
  LD D,$20
  LD E,$30
  CALL CopyBlockToScreen
  CALL FlashFadeScreen
  CALL ClearScreen
  LD BC,$0064
  CALL WaitFrames
  POP DE
  LD BC,ScoreDigitsHigh
  LD A,(Lives)
  LD H,A
  RET

  ORG $795D

; Reseed the random pointer every 64 passes and pad the pass with a busy wait
; in the light rooms
;
; When PassCounter & $3F is 0, the high byte of RandomPointer is set from R.
; Then: in grid 0 (GridNumber 0), rooms 0-5 wait $044C rounds of DelayBC; in
; grid 1, room 0 waits $0640 (PaceShaftRoom); every other room goes on at once.
; The wait evens out the pass time of rooms with few actors (8978 of the 10187
; passes in the stage-1 recordings waited).
;
; Witness: L1 10187 (c1o, deaths, s1-idle, s1-right).
PacePass:
  LD A,(PassCounter)
  AND $3F
  JR NZ,PacePassRoom
  LD BC,(RandomPointer)
  LD A,R
  LD B,A
  LD (RandomPointer),BC
PacePassRoom:
  LD A,(GridNumber)
  CP $00
  JR NZ,PaceShaftRoom
  LD A,(RoomNumber)
  CP $06
  RET NC
  LD BC,$044C
  JP DelayBC

; A pacing variant no code calls: rooms 0 and 5 wait $03E8, room $0B waits a
; count left in BC
;
; No caller in the image (no CALL, JP or pointer to $7982). Reads RoomNumber: 0
; or 5 wait $03E8 rounds of DelayBC, $0B waits BC as it stands (the LD HL,$16A8
; before it sets HL, not BC), others return. A leftover of another stage's
; pacing.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
PacePassUnused:
  LD A,(RoomNumber)
  CP $00
  JR Z,PacePassUnusedWait
  CP $05
  JR Z,PacePassUnusedWait
  LD HL,$16A8
  CP $0B
  JP Z,DelayBC
  RET
PacePassUnusedWait:
  LD BC,$03E8
  JP DelayBC

; Grid 1, room 0: wait $0640 rounds
;
; Reached from PacePass when GridNumber is not 0: in grid 1 room 0 waits $0640
; rounds of DelayBC, else returns.
;
; Not executed in any recording (the recordings checked: c1o, deaths, s1-idle,
; s1-right); known only from the code.
PaceShaftRoom:
  LD A,(GridNumber)
  CP $01
  RET NZ
  LD A,(RoomNumber)
  CP $00
  RET NZ
  LD BC,$0640

  ORG $79B1

; ENTER pauses: wait for its release, a second press and its release
;
; Reads port $BFFE bit 0 (ENTER). Not pressed: returns at once. Pressed: waits
; for the key's release, the next press and its release, so the game stands
; still between two presses. No other effect.
;
; Witness: L1 10189 (c1o, deaths, s1-idle, s1-right).
CheckPause:
  LD BC,$BFFE
  IN A,(C)
  BIT 0,A
  RET NZ
PauseRelease:
  IN A,(C)
  BIT 0,A
  JR Z,PauseRelease
PausePress:
  IN A,(C)
  BIT 0,A
  JR NZ,PausePress
PauseRelease2:
  IN A,(C)
  BIT 0,A
  JR Z,PauseRelease2
  RET

  ORG $984D

; The pass's counters: PassCounter + 1, the energy, the timers and the lives'
; colours
;
; PassCounter + 1, then $7E9F, $A3C5, $836D and $7DD2.
;
; Witness: L1 10246 (c1o, deaths, s1-idle, s1-right).
PassTick:
  LD HL,PassCounter
  INC (HL)
  CALL ApplyEnergyChange
  CALL DrawEnergyBar
  CALL GameOverStep
  JP LivesFlashStep
