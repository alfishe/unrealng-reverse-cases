; --------------------------------------------------------------------------------------------------------------------
; mainloop.asm: The main loop and its pass
;
; MainLoop $7837 runs one game step a pass, with no frame sync: rzx-r2 makes 5806 passes in frames 402-18721 (about
; 3.2 frames a pass), s2-right 1951 passes in frames 402-5823 (2.8). Stage 2 has no busy-wait pacing: PacePassEmpty is
; a bare RET. A pass ends with SPACE (the item window), CAPS SHIFT + SPACE (quit) or the end of the lives.
; --------------------------------------------------------------------------------------------------------------------

  ORG $7837

; One pass: HUD, input, actors, draw, copy; SPACE opens the item window
;
; The pass, in order: PacePassEmpty, ShowPieceTaken, FlashPieces, CheckPause
; (ENTER), SpawnTimer $8D45, RedrawItemsIfChanged, ClearBuffer, CheckStageExit
; (may leave to EndStage), UpdateMissiles, $9EAE, RunActorHandlers, $9E4F,
; DrawActors, $9E21, $9C92, HydraDefeated $9BB4, KeyHook, UpdateAttributes
; $8CD0 (attributes and CopyBuffer), PassTick (energy, lives flash, game over
; step), ShowScore, then the SPACE test TestSpaceKey.
;
; SPACE with CAPS SHIFT ends the stage with E = 1 (QuitStage); SPACE alone
; opens ItemWindow unless the hero is in state $0F (dying; the hero record's
; +$0A at $74EA). The loop goes on while Lives is not 0 or the hero's state is
; not 0; with no lives and the hero back in state 0 it ends with E = 0
; (GameOverExit). rzx-r2 opened the item window 18 times; s2-right ends in game
; over at frame 5823.
;
; Witness: L1 8032 (rzx-r2, s2-right, stageload).
MainLoop:
  CALL PacePassEmpty
  CALL ShowPieceTaken
  CALL FlashPieces
  CALL CheckPause
  CALL SpawnTimer
  CALL RedrawItemsIfChanged
  CALL ClearBuffer
  CALL CheckStageExit
  CALL UpdateMissiles
  CALL UpdateHydraNecks
  CALL RunActorHandlers
  CALL ColourHydra
  CALL DrawActors
  CALL DrawHydraBody
  CALL UpdateBurst
  CALL HydraDefeated
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
  JR Z,QuitStage
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
; 0, then EndStage. s2-right ends so (frame 5823).
;
; Witness: L1 1 (s2-right).
GameOverExit:
  LD E,$00
  JR EndStage

; CAPS SHIFT + SPACE: end the stage with E = 1
;
; Not executed in any recording (the recordings checked: s2-right, rzx-r2);
; known only from the code ($787F).
QuitStage:
  LD E,$01

; Leave the stage: hide the pieces boxes, then save the HUD and return
; (EndStageSave)
;
; E (pushed) is the outcome: 0 game over (GameOverExit), 1 quit (QuitStage), 2
; stage completed (StageExit). Clears the play buffer, then sets the attributes
; of the two rows of the pieces boxes (cells $5879-$587E and $5899-$589E) to 1
; (blue on black) with two LDIR fills where stage 1 used FillAttributes; runs
; on into EndStageSave. Reached in rzx-r2 at frame 18883 (from StageExit) and
; in s2-right at the game over.
;
; Witness: L1 2 (rzx-r2, s2-right).
EndStage:
  PUSH DE
  CALL ClearBuffer
  LD HL,Attributes+121
  LD DE,Attributes+122
  LD BC,$0005
  LD (HL),$01
  LDIR
  LD HL,Attributes+153
  LD DE,Attributes+154
  LD BC,$0005
  LD (HL),$01
  LDIR

; EndStage, continued: save the HUD, clear its fields, fade, return
;
; Part of EndStage, after the second inline record.
;
; As in stage 1 at $78B2, the same code.
;
; Witness: L1 2 (rzx-r2, s2-right).
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

  ORG $7966

; The pass's pacing slot: a bare RET in stage 2
;
; MainLoop calls it first in every pass, where stage 1 calls PacePass (the
; random reseed and the busy wait of the light rooms). Stage 2 has neither: the
; byte is a RET.
;
; Witness: L1 8032 (rzx-r2, s2-right, stageload).
PacePassEmpty:
  RET

; ENTER pauses: wait for its release, a second press and its release
;
; Reads port $BFFE bit 0 (ENTER). Not pressed: returns at once. Pressed: waits
; for the key's release, the next press and its release, so the game stands
; still between two presses. No other effect.
;
; As in stage 1 at $79B1, the same code.
;
; Witness: L1 8032 (rzx-r2, s2-right, stageload).
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

  ORG $9219

; The pass's counters: PassCounter + 1, the energy, the timers and the lives'
; colours
;
; PassCounter + 1, then $7E62, $9DC2, $8566 and $7D9E.
;
; As in stage 1 at $984D, the same code.
;
; Witness: L1 8120 (rzx-r2, s2-right, stageload).
PassTick:
  LD HL,PassCounter
  INC (HL)
  CALL ApplyEnergyChange
  CALL DrawEnergyBar
  CALL GameOverStep
  JP LivesFlashStep
