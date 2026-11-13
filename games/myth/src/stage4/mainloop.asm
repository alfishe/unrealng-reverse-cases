; --------------------------------------------------------------------------------------------------------------------
; mainloop.asm: The main loop and its pass
; --------------------------------------------------------------------------------------------------------------------

  ORG $7837

; One pass: pace, HUD, input, actors, draw, copy; SPACE opens the item window
;
; The pass, in order: PacePass, ShowPieceTaken, FlashPieces, CheckPause
; (ENTER), SpawnTimer $9245, RedrawItemsIfChanged, ClearBuffer $9A28,
; CheckStageExit (may leave to StageExit), UpdateMissiles $B4AC, TrapChainStep,
; RunActorHandlers $A746, LinkTrapSlots, DrawBossPicture, DrawActors $A768,
; $B412, $A41D, KeyHook, UpdateAttributes (attributes and CopyBuffer), PassTick
; $97BD (energy, lives flash, game over step), ShowScore, then the SPACE test
; TestSpaceKey.
;
; SPACE with CAPS SHIFT (port $FEFE bit 0) ends the stage with E = 1
; (QuitStage); SPACE alone opens ItemWindow (stage 1 also refused it while the
; hero was dying; stage 4 does not test the hero's state). The loop goes on
; while Lives is not 0 or the hero's state $74EA is not 0; with no lives and
; the hero back in state 0 it falls into GameOverExit. s4-right ran 945 passes
; and ended at the game over (217 passes with no lives left before the hero's
; state came back to 0); rzx-r4 ran 7675 passes, opened the item window 20
; times and left through CheckStageExit.
;
; Witness: L1 8620 (rzx-r4, s4-right).
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
  CALL TrapChainStep
  CALL RunActorHandlers
  CALL LinkTrapSlots
  CALL DrawBossPicture
  CALL DrawActors
  CALL HeadShots
  CALL UpdateBurst
  CALL KeyHook
  CALL UpdateAttributes
  CALL PassTick
  CALL ShowScore
  CALL TestSpaceKey
  JR NZ,MainLoopNext
MainLoopSpace:
  LD BC,$FEFE             ; SPACE held: CAPS SHIFT too quits, else the item
                          ; window
  IN A,(C)
  BIT 0,A
  JR Z,QuitStage
  CALL ItemWindow
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
; Witness: L1 1 (s4-right).
GameOverExit:
  LD E,$00
  JR EndStage

; CAPS SHIFT + SPACE: end the stage with E = 1
;
; Reached from MainLoop ($787F) when SPACE and CAPS SHIFT are held. E = 1, then
; EndStage.
;
; Not executed in any recording (the recordings checked: rzx-r4, s4-right);
; known only from the code ($787F).
QuitStage:
  LD E,$01

; Leave the stage: hide the pieces boxes, then EndStageSave (save the HUD,
; fade) returns E, H = lives, BC = the score's digits
;
; E (pushed) is the outcome: 0 game over (GameOverExit), 1 quit (QuitStage), 2
; stage completed (StageExit $7A72). ClearBuffer $9A28, then the pieces boxes'
; attributes (rows 3 and 4, columns 25-30: $5879 and $5899, 6 cells each) set
; to 1 with two LDIRs. Stage 1 hid the lives boxes too with two inline
; FillAttributes records; stage 4 hides only the pieces boxes and falls
; straight into EndStageSave.
;
; Witness: L1 2 (rzx-r4, s4-right).
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
; Saves the HUD's attributes (rows 0-5, 192 bytes) to $7600. Clears five HUD
; fields with CopyToScreen from the cleared play buffer $5B00 (stride 0): the
; score (column 6, line 8, 6 x 8), the fields at column $0E (4 x 8) and column
; $14 (6 x 8) of line 8, the item strip (column $0A, line $18, 12 x 16) and the
; pieces field (column $19, line $18, 6 x 16). Then CopyBlockToScreen puts the
; HUD picture as loaded ($7000, 32 x 48) back on lines 0-47, FlashFadeScreen,
; ClearScreen, WaitFrames 100. Returns with E = the outcome (popped), BC =
; ScoreDigitsHigh (the score's six digits as text) and H = Lives.
;
; Witness: L1 2 (rzx-r4, s4-right).
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

  ORG $7961

; Pad the pass with a busy wait taken from PaceWaits by grid and room
;
; BC = PaceWaits[GridNumber x 3 + RoomNumber], then BC is counted down to 0
; (PacePassWait, 26 T-states a round). Grid 0 room 0 waits $0258 rounds, grid 0
; room 1 $0640, grid 4 rooms 0 and 1 $04B0, every other place 1. Unlike stage
; 1's PacePass (which also reseeded RandomPointer from R every 64 passes and
; used DelayBC), stage 4's has its own loop and no reseed. The busy wait ran 1
; 498 000 rounds in s4-right's 945 passes (grid 0) and 1 099 377 in rzx-r4's
; 7675.
;
; Witness: L1 8620 (rzx-r4, s4-right).
PacePass:
  LD A,(GridNumber)
  SLA A
  LD C,A
  SLA A
  ADD A,C
  LD C,A
  LD A,(RoomNumber)
  SLA A
  ADD A,C
  LD C,A
  LD B,$00
  LD HL,PaceWaits
  ADD HL,BC
  LD C,(HL)
  INC HL
  LD B,(HL)
PacePassWait:
  DEC BC                  ; count BC down to 0
  LD A,B
  OR C
  JP NZ,PacePassWait
  RET

; The busy-wait rounds of each place: word GridNumber x 3 + RoomNumber (48
; words)
;
; Read by PacePass $7974 (LD HL,PaceWaits; the word at + 2 x (GridNumber x 3 +
; RoomNumber)). Words 0 and 1 (grid 0 rooms 0 and 1): $0258 and $0640; words 12
; and 13 (grid 4 rooms 0 and 1): $04B0; all the others 1. Three words a grid is
; fewer than the rooms of some grids (grid 3 has a room 3, grid 4 a room 4), so
; those rooms read the next grid's words; they are all 1 there. Read every pass
; in both recordings.
PaceWaits:
  DEFW $0258,$0640,$0001,$0001,$0001,$0001,$0001,$0001
  DEFW $0001,$0001,$0001,$0001,$04B0,$04B0,$0001,$0001
  DEFW $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
  DEFW $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
  DEFW $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
  DEFW $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001

; ENTER pauses: wait for its release, a second press and its release
;
; Reads port $BFFE bit 0 (ENTER). Not pressed: returns at once. Pressed: waits
; for the key's release, the next press and its release, so the game stands
; still between two presses. No other effect. As in stage 1 at `$79B1`. The
; wait loops from $79EA on ran in neither recording (ENTER never pressed).
;
; Witness: L1 8620 (rzx-r4, s4-right).
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

  ORG $97BD

; The pass's counters: PassCounter + 1, the energy, the timers and the lives'
; colours
;
; PassCounter + 1, then $7ED7 (the pending energy change), DrawEnergyBar $A54D,
; GameOverStep $8414 and LivesFlashStep $7E13. As in stage 1 at `$984D`.
;
; Witness: L1 8679 (rzx-r4, s4-right).
PassTick:
  LD HL,PassCounter
  INC (HL)
  CALL ApplyEnergyChange
  CALL DrawEnergyBar
  CALL GameOverStep
  JP LivesFlashStep
