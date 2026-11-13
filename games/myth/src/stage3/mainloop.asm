; --------------------------------------------------------------------------------------------------------------------
; mainloop.asm: The main loop and its pass
; --------------------------------------------------------------------------------------------------------------------

  ORG $78AF

; No lives: end the stage with E = 0
;
; Reached from MainLoop when Lives and the hero's state $74EA are both 0. E =
; 0, then EndStage.
;
; Stage 1's GameOverExit at $7897 is the same code.
;
; Witness: L1 1 (s3-right).
GameOverExit:
  LD E,$00
  JP EndStage

; CAPS SHIFT + SPACE: end the stage with E = 1
;
; Stage 1's QuitStage at $789C is the same code (LD E,1, then on into
; EndStage).
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
; known only from the code.
QuitStage:
  LD E,$01

; Leave the stage: hide the HUD boxes, save the HUD, fade, return E, H = lives,
; BC = the score's digits
;
; E (pushed) is the outcome: 0 game over (GameOverExit), 1 quit (QuitStage), 2
; stage completed (StageExit). Clears the play buffer, hides the pieces boxes
; and the lives boxes with two inline attribute fills ($8ADE), saves the HUD
; attributes (rows 0-5) to $7600, clears the score, the two middle HUD fields,
; the item strip and the pieces field with CopyToScreen from the cleared buffer
; (stride 0), saves the HUD bitmap (lines 0-47) to $7000 ($892A), fades the
; screen (FlashFadeScreen), clears it ($8A33), waits 100 frames ($8AD6) and
; returns to the stage loader with E, BC = ScoreDigitsHigh (the six score
; digits) and H = Lives.
;
; Stage 1's EndStage at $789E is the same code.
;
; Witness: L1 2 (rzx-r3, s3-right).
EndStage:
  PUSH DE
  CALL ClearBuffer
  CALL FillAttributes

; FillAttributes' inline record: column 25, line 24, 6 x 2 cells, attribute 1
; (the pieces boxes hidden)
;
; Read by FillAttributes $8ADE after the CALL at $78BA. Stage 1's EndPiecesBox
; at $78A5 holds the same bytes.
EndPiecesBox:
  DEFB $19,$18,$06,$02,$01

; EndStage, continued: hide the lives boxes
;
; Part of EndStage, after the first inline record.
;
; Stage 1's EndStageLives at $78AA, the same instructions; the operand that
; differs is the CALL's at $78C2: stage 3's FillAttributes $8ADE.
;
; Witness: L1 2 (rzx-r3, s3-right).
EndStageLives:
  CALL FillAttributes

; FillAttributes' inline record: column 1, line 24, 6 x 2 cells, attribute 1
; (the lives boxes hidden)
;
; Read by FillAttributes $8ADE after the CALL at $78C2. Stage 1's EndLivesBox
; at $78AD holds the same bytes.
EndLivesBox:
  DEFB $01,$18,$06,$02,$01

; EndStage, continued: save the HUD, clear its fields, fade, return
;
; Part of EndStage, after the second inline record.
;
; Stage 1's EndStageSave at $78B2 is the same code.
;
; Witness: L1 2 (rzx-r3, s3-right).
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

  ORG $7975

; Reseed the random pointer every 64 passes and pad the pass with a busy wait
; in grid 1's room 10
;
; When PassCounter & $3F is 0, the high byte of RandomPointer is set from R.
; Then: in grid 1 (GridNumber 1), room 10 waits $044C rounds of DelayBC (it
; runs on into it); every other room goes on at once. Stage 1 waits in grid 0's
; rooms 0-5 and grid 1's room 0 (PacePass, PacePassUnused and PaceShaftRoom);
; stage 3 has only this test. The wait ran 120 times (rzx-r3).
;
; Witness: L1 6279 (rzx-r3, s3-right).
PacePass:
  LD A,(PassCounter)
  AND $3F
  JR NZ,PacePassRoom
  LD BC,(RandomPointer)
  LD A,R
  LD B,A
  LD (RandomPointer),BC
PacePassRoom:
  LD A,(GridNumber)            ; grid 1 room 10 only
  CP $01
  RET NZ
  LD A,(RoomNumber)
  CP $0A
  RET NZ
  LD BC,$044C
  JP DelayBC

  ORG $799F

; ENTER pauses: wait for its release, a second press and its release
;
; Reads port $BFFE bit 0 (ENTER). Not pressed: returns at once. Pressed: waits
; for the key's release, the next press and its release, so the game stands
; still between two presses. No other effect.
;
; Stage 1's CheckPause at $79B1 is the same code.
;
; Witness: L1 6279 (rzx-r3, s3-right).
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

  ORG $9815

; The pass's counters: PassCounter + 1, the energy, the timers and the lives'
; colours
;
; PassCounter + 1, then $7E84, $A33B, $83F2 and $7DC0.
;
; Stage 1's PassTick at $984D is the same code.
;
; Witness: L1 6338 (rzx-r3, s3-right).
PassTick:
  LD HL,PassCounter
  INC (HL)
  CALL ApplyEnergyChange
  CALL DrawEnergyBar
  CALL GameOverStep
  JP LivesFlashStep
