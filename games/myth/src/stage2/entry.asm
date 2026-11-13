; --------------------------------------------------------------------------------------------------------------------
; entry.asm: The stage's entry and set-up
;
; Stage 2's block is entered at $7800 by the resident stage loader with H = the lives. StageEntry sets up the stage
; (variables, title, HUD, the first room of grid 0) and falls into the main loop; EndStage returns to the loader with
; E = the outcome (0 game over, 1 quit, 2 stage completed), H = the lives and BC = the score's digits. In rzx-r2 the
; stage runs from frame 26 to frame 19011 (EndStage with E = 2 after the exit effect at frame 18721); in s2-right it
; ends in game over (EndStage at frame 5826).
; --------------------------------------------------------------------------------------------------------------------

; Start the stage: lives from H, variables, HUD, the first room, then the main
; loop
;
; Called by the resident stage loader ($F239) with H = the lives left. Stores H
; in Lives, then: InitStageState $9766 (clears $FE08-$FE6D, the carried items
; from StartItems, the energy refill), StageSetUp (the title, the HUD),
; ClearActors $8EEA, ResetObjectLists, RoomGrid = $953E (grid 0) and Placements
; = Grid0Placements, ReviveAllPlacements, $A396, StartGrid, RoomEvents $8381
; (the first room's bonus checks), ClearBuffer, RunActorHandlers, DrawActors,
; CopyBuffer and StageFadeIn, then runs on into MainLoop.
;
; As in stage 1 at $7800 with stage 2's own set-up calls; stage 1's RoomNumber
; = 2 start is done by StartGrid here.
;
; Witness: L1 3 (rzx-r2, s2-right, stageload).
StageEntry:
  LD A,H
  LD (Lives),A
  CALL InitStageState
  CALL StageSetUp
  CALL ClearActors
  CALL ResetObjectLists
  LD HL,Grid0
  LD (RoomGrid),HL
  LD HL,Grid0Placements
  LD (Placements),HL
  CALL ReviveAllPlacements
  CALL PlaceHeroAtStart
  CALL StartGrid
  CALL RoomEvents
  CALL ClearBuffer
  CALL RunActorHandlers
  CALL DrawActors
  CALL CopyBuffer
  CALL StageFadeIn

  ORG $9177

; Set up the stage's screen: the HUD, its colours, the score and the items
;
; Clears the screen and the shadow, copies the HUD's colours $7600 (6 rows)
; into the shadow and shows them,
;
; dissolves the HUD's picture $7000 in (DissolveHud), paints the HUD's boxes
; (FillShadowAttributes x 4), then draws
;
; the items with $7D01 / $7C50 three times (with $7CB8 patched to RET and
; ItemSelected = 3), the score, the score's
;
; reveal (RevealScore) and the lives (JP $7D98).
;
; As in stage 1 at $97AC, the same code.
;
; Witness: L1 3 (rzx-r2, s2-right, stageload).
StageSetUp:
  CALL ClearScreen
  CALL ClearShadowAttributes
  LD HL,HudColours
  LD DE,ShadowAttributes
  LD BC,$00C0
  LDIR
  CALL ShowShadowAttributes
  LD BC,$0032
  CALL WaitFrames
  LD DE,HudPicture
  CALL DissolveHud
  LD BC,$0032
  CALL WaitFrames
  CALL FillShadowAttributes
  DEFB $06,$08,$06,$01,$41
  CALL FillShadowAttributes
  DEFB $0A,$18,$0C,$02,$41
  CALL FillShadowAttributes
  DEFB $0F,$08,$02,$01,$41
  CALL FillShadowAttributes
  DEFB $02,$30,$1C,$12,$00
  CALL ShowShadowAttributes
  LD A,$03
  LD (ItemSelected),A
  LD A,$C9
  LD (CycleWindowFrame),A
  CALL DrawItemStrip
  CALL ScrollItemsLeft
  CALL DrawItemStrip
  CALL ScrollItemsLeft
  CALL DrawItemStrip
  CALL ScrollItemsLeft
  LD A,$00
  LD (CycleWindowFrame),A
  CALL RenderScore
  CALL RevealScore
  CALL FlashSelectedBox
  CALL SaveAttributes
  JP StartLivesFlash

; Run 30 quiet passes, then fade the room's colours in
;
; 30 x (3 HALTs + PassTick), then 7 x 5 steps of FadeInStep a HALT each.
;
; As in stage 1 at $9824, the same code.
;
; Witness: L1 3 (rzx-r2, s2-right, stageload).
StageFadeIn:
  LD B,$1E
  CALL IdlePasses
  LD B,$07
FadeInRound:
  PUSH BC
  XOR A
  LD (PassCounter),A
  LD B,$05
FadeInFrame:
  PUSH BC
  HALT
  CALL FadeInStep
  LD HL,PassCounter
  INC (HL)
  POP BC
  DJNZ FadeInFrame
  POP BC
  DJNZ FadeInRound
  RET

; B x (3 HALTs + PassTick)
;
; Called by StageFadeIn ($91F2).
;
; As in stage 1 at $9842, the same code.
;
; Witness: L1 90 (rzx-r2, s2-right, stageload).
IdlePasses:
  PUSH BC
  HALT
  HALT
  HALT
  CALL PassTick
  POP BC
  DJNZ IdlePasses
  RET

  ORG $9229

; Raise the score's digits into the HUD line by line (8 steps)
;
; Draws 1 to 8 lines of the digit buffer $7640 at columns 6 (6 wide) and 15 (2
; wide), one line higher each step.
;
; As in stage 1 at $985D, the same code.
;
; Witness: L1 3 (rzx-r2, s2-right, stageload).
RevealScore:
  LD B,$08
  LD C,$0F
  LD D,$06
  LD E,$01
RevealScoreStep:
  PUSH BC
  PUSH DE
  HALT
  LD HL,DigitBuffer
  LD B,$06
  PUSH BC
  PUSH DE
  LD A,$06
  CALL CopyToScreen
  POP DE
  POP BC
  LD A,B
  ADD A,$09
  LD B,A
  LD D,$02
  LD HL,DigitBuffer
  LD A,$06
  CALL CopyToScreen
  POP DE
  POP BC
  DEC C
  INC E
  DJNZ RevealScoreStep
  RET
