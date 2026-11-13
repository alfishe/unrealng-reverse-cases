; --------------------------------------------------------------------------------------------------------------------
; entry.asm: The stage's entry and set-up
;
; Stage 1's block is entered at $7800 by the resident stage loader with H = the lives. StageEntry sets up the stage
; (variables, title, HUD, the first room) and falls into the main loop; EndStage returns to the loader with E = the
; outcome (0 game over, 1 quit, 2 stage completed), H = the lives and BC = the score's digits.
; --------------------------------------------------------------------------------------------------------------------

; Start the stage: lives from H, variables, HUD, the first room, then the main
; loop
;
; Called by the resident stage loader with H = the lives left. Stores H in
; Lives, then: $9DA1 (clears $FE08-$FE5F, the carried items from StartItems,
; the item window at slot 6, the energy refill $2E), $97AC (the title, the
; HUD), $921E and $922F, RoomGrid = $9B6F (grid 0) with the actor list pointer
; $FE25 = $9BA0, $A4A1 and $A47D (the room's actors), RoomNumber = 2, $A444
; (clears the room cells), ClearBuffer, $A5BD, $A5DF (draws the actors) and
; CopyBuffer, then runs on into MainLoop.
;
; Witness: L1 2 (s1-idle, s1-right).
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
  LD A,$02
  LD (RoomNumber),A
  CALL StartGrid
  CALL ClearBuffer
  CALL RunActorHandlers
  CALL DrawActors
  CALL CopyBuffer
  CALL StageFadeIn

  ORG $97AC

; Set up the stage's screen: the HUD, its colours, the score and the items
;
; Clears the screen and the shadow, copies the HUD's colours $7600 (6 rows)
; into the shadow and shows them,
;
; dissolves the HUD's picture $7000 in (DissolveHud), paints the HUD's boxes
; (FillShadowAttributes x 4), then draws
;
; the items with $7D36 / $7C85 three times (with $7CED patched to RET and
; ItemSelected = 3), the score, the score's
;
; reveal (RevealScore) and the lives (JP $7DCD).
;
; Witness: L1 2 (s1-idle, s1-right).
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

; FillShadowAttributes' data: column, line, width, height, colour
HudBox1:
  DEFB $06,$08,$06,$01,$41

; HudBoxPaint2
HudBoxPaint2:
  CALL FillShadowAttributes ; the code resumes after the 5 bytes

; the score box: white on blue
HudBox2:
  DEFB $0A,$18,$0C,$02,$41

; HudBoxPaint3
HudBoxPaint3:
  CALL FillShadowAttributes

; the item box
HudBox3:
  DEFB $0F,$08,$02,$01,$41

; HudBoxPaint4
HudBoxPaint4:
  CALL FillShadowAttributes

; the play area: black
HudBox4:
  DEFB $02,$30,$1C,$12,$00

; StageSetUpItems
StageSetUpItems:
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
  XOR A
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
; Witness: L1 2 (s1-idle, s1-right).
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
; Witness: L1 60 (s1-idle, s1-right).
IdlePasses:
  PUSH BC
  HALT
  HALT
  HALT
  CALL PassTick
  POP BC
  DJNZ IdlePasses
  RET

  ORG $985D

; Raise the score's digits into the HUD line by line (8 steps)
;
; Draws 1 to 8 lines of the digit buffer $7640 at columns 6 (6 wide) and 15 (2
; wide), one line higher each step.
;
; Witness: L1 2 (s1-idle, s1-right).
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
