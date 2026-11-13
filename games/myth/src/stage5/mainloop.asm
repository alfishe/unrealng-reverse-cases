; --------------------------------------------------------------------------------------------------------------------
; mainloop.asm: The main loop and its pass
;
; MainLoop $7843 runs one step a pass with a HALT at its head, so stage 5 is frame-synced (stages 1-4 are not).
; s5-right: 3730 passes in 7940 frames, about 2.1 frames a pass. While a text page is up (the phase DuelPhase $FE43 is
; $FF before the duel, 4 after it) each pass adds TextPassDelay's $07D0 rounds; in form 3 and after the duel
; PaceLateForms adds $0320 or $07D0 rounds. The loop ends only on no lives (the hero's game-over count
; HeroGameOverCount $BA84 at 0: E = 0) or CAPS SHIFT + SPACE (E = 1); winning the duel leaves the ending text on
; screen and the loop running.
;
; PassTick is stage 1's per-pass tick with stage 5's routines.
; --------------------------------------------------------------------------------------------------------------------

  ORG $7843

; One pass: HALT, the hero, the shots, the stars, Dameron, the HUD, the
; missiles, the colours; CAPS SHIFT + SPACE quits
;
; The pass, in order: PassCounter $FE4D + 1, HALT, HeroControl, HeroFire,
; MoveShots, DrawShots, MoveStars, DameronFire, ApplyEnergyChange,
; DrawEnergyBar $9744 (the energy bar), LivesFlashStep, DrawStars, DuelStep
; (the texts or Dameron), UpdateBurst $9076 (the burst particles); then writes
; $02 and $FF to the screen bytes $4200-$4201 (pixel line 2, columns 0-1, in
; the HUD); TextPassDelay when the phase DuelPhase $FE43 is $FF (the intro) and
; again when it is 4 (won); DrawHero, UpdateDameronMissiles, ColourPlayArea
; (which ends in DuelHit).
;
; Then: the hero's game-over count HeroGameOverCount $BA84 at 0 ends the stage
; with E = 0 (GameOverExit). CAPS SHIFT (port $FEFE bit 0) and SPACE (port
; $7FFE bit 0) both held end it with E = 1 (QuitStage). SPACE alone does
; nothing: stage 5 has no item window (ItemWindow has no caller).
;
; Witness: L1 11697 (ending, rzx-r5, s5-right).
MainLoop:
  LD HL,PassCounter
  INC (HL)
  HALT
  CALL HeroControl
  CALL HeroFire
  CALL MoveShots
  CALL DrawShots
  CALL MoveStars
  CALL DameronFire
  CALL ApplyEnergyChange
  CALL DrawEnergyBar
  CALL LivesFlashStep
  CALL DrawStars
  CALL DuelStep
  CALL UpdateBurst
  LD A,$FF
  LD (Screen+513),A
  LD A,$02
  LD (Screen+512),A
  LD A,(DuelPhase)
  CP $FF
  CALL Z,TextPassDelay
  LD A,(DuelPhase)
  CP $04
  CALL Z,TextPassDelay
  CALL DrawHero
  CALL UpdateDameronMissiles
  CALL ColourPlayArea
  LD A,(HeroGameOverCount)
  CP $00
  JP Z,GameOverExit
  LD BC,$FEFE
  IN A,(C)
  BIT 0,A
  JP NZ,MainLoop
MainLoopCaps:
  LD BC,$7FFE             ; CAPS SHIFT held: SPACE too quits
  IN A,(C)
  BIT 0,A
  JP Z,QuitStage
  JP MainLoop

; No lives: end the stage with E = 0
;
; Reached from MainLoop when the hero's game-over count HeroGameOverCount $BA84
; reaches 0 (HeroControl counts it down in state 3, after the last life). E =
; 0, then EndStage.
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
GameOverExit:
  LD E,$00
  JP EndStage

; CAPS SHIFT + SPACE: end the stage with E = 1
;
; Reached from MainLoop ($78A8); falls into EndStage with E = 1.
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
QuitStage:
  LD E,$01

; Leave the stage: hide the HUD boxes, save the HUD, fade, return E, H = lives,
; BC = the score's digits
;
; As in stage 1 at $789E, the same code with stage 5's addresses. E (pushed) is
; the outcome: 0 game over (GameOverExit), 1 quit (QuitStage). Clears the play
; buffer (ClearBuffer $96AC), hides the pieces boxes and the lives boxes with
; two inline attribute fills (FillAttributes $954E, EndPiecesBox and
; EndLivesBox), copies the HUD attributes (rows 0-5, $5800-$58BF) to HudColours
; $7600, clears the score (column 6, line 8, 6 x 8 bytes), the two middle HUD
; fields (column 14, 4 x 8; column 20, 6 x 8), the item strip (column 10, line
; 24, 12 x 16) and the pieces field (column 25, line 24, 6 x 16) with
; CopyToScreen from the cleared buffer PlayBuffer $5B00 (stride 0).
;
; Then saves the HUD bitmap (lines 0-47, 32 bytes wide) to HudPicture $7000
; with CopyScreenToBlock $93F3 (over the missile records, no longer needed),
; fades the screen (FlashFadeScreen), clears it (ClearScreen $949F), waits 100
; frames (WaitFrames $9546) and returns to the stage loader with E, BC =
; ScoreDigitsHigh (the six score digits) and H = Lives.
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
EndStage:
  PUSH DE
  CALL ClearBuffer
  CALL FillAttributes

; $954E's inline record: column 25, line 24, 6 x 2 cells, attribute 1 (the
; pieces boxes hidden)
;
; Read by FillAttributes $954E (@inline 5) after the CALL at $78B9: column,
; line, width and height in cells, attribute.
EndPiecesBox:
  DEFB $19,$18,$06,$02,$01

; EndStage, continued: hide the lives boxes
;
; Part of EndStage, after the first inline record.
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
EndStageLives:
  CALL FillAttributes

; $954E's inline record: column 1, line 24, 6 x 2 cells, attribute 1 (the lives
; boxes hidden)
;
; Read by FillAttributes $954E after the CALL at EndStageLives $78C1, in
; EndPiecesBox's format.
EndLivesBox:
  DEFB $01,$18,$06,$02,$01

; EndStage, continued: save the HUD, clear its fields, fade, return
;
; Part of EndStage, after the second inline record.
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
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
  CALL CopyScreenToBlock
  CALL FlashFadeScreen
  CALL ClearScreen
  LD BC,$0064
  CALL WaitFrames
  POP DE
  LD BC,ScoreDigitsHigh
  LD A,(Lives)
  LD H,A
  RET

  ORG $7ABB

; Pad the pass in Dameron's form 3 and after: wait $0320 rounds (phase 3) or
; $07D0 (phase 4)
;
; Reached by a JP from DuelStep ($8855) with A = the phase DuelPhase $FE43, 3
; or more: form 3 (no face drawn) and the end cost less, so the pass is padded
; with a busy count of HL down to 0 (26 T-states a round): $07D0 when A is 4,
; else $0320. Returns to DuelStep's caller.
;
; Witness: L1 472 (ending, rzx-r5).
PaceLateForms:
  LD HL,$0320
  CP $04
  JP NZ,PaceLateFormsLoop
  LD HL,$07D0
PaceLateFormsLoop:
  DEC HL
  LD A,L
  OR H
  JP NZ,PaceLateFormsLoop
  RET

; Busy wait $07D0 rounds: the pass pacing while the intro or the ending text is
; up
;
; Called by MainLoop when the phase DuelPhase $FE43 is $FF (the intro) and when
; it is 4 (won). Counts HL from $07D0 to 0 (about 52 000 T-states, 0.75 frame).
; Destroys A, HL.
;
; Witness: L1 5537 (ending, rzx-r5, s5-right).
TextPassDelay:
  LD HL,$07D0
TextPassDelayLoop:
  DEC HL
  LD A,L
  OR H
  JP NZ,TextPassDelayLoop
  RET

  ORG $7EE2

; Blue border, then the resident's abort ($FCE3: DI, IM 0, the loader's SP and
; return address)
;
; Writes 1 to port $FE (a blue border) and jumps to $FCE3, the resident's exit
; that KeyHook takes when its key is pressed (it restores SP from $FE04 and
; returns through $FE06).
;
; No caller in stage 5's code: no CALL, JP or pointer to $7EE2 in list-all.txt.
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
AbortGame:
  LD A,$01
  OUT ($FE),A
  JP $FCE3

  ORG $966E

; The pass's counters: PassCounter + 1, the energy, the bar, the timers and the
; lives' colours
;
; PassCounter $FE4D + 1, then ApplyEnergyChange $7E17, DrawEnergyBar,
; GameOverStep $7E9D and JP LivesFlashStep $7D85. Called by IdlePasses. As
; stage 1's PassTick $984D.
;
; Witness: L1 90 (ending, rzx-r5, s5-right).
PassTick:
  LD HL,PassCounter
  INC (HL)
  CALL ApplyEnergyChange
  CALL DrawEnergyBar
  CALL GameOverStep
  JP LivesFlashStep
