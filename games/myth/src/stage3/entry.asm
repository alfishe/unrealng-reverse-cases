; --------------------------------------------------------------------------------------------------------------------
; entry.asm: The stage's entry and set-up
; --------------------------------------------------------------------------------------------------------------------

; Start the stage: lives from H, variables, HUD, the first room, the hero
; placed, then the main loop
;
; Called by the resident stage loader with H = the lives left. Stores H in
; Lives, then: InitStageState $9D00 (the variables, the carried items from
; StartItems), StageSetUp $970D (the title, the HUD), ClearActors $959F and
; ResetObjectLists $95B0, RoomGrid = $9B37 (grid 0, the longship) with
; Placements = $9B62 (grid 0's placements), ReviveAllPlacements $A69F and
; PlaceHeroAtStart $A672, GridNumber = 0, RoomNumber = 1, StartGrid $A639
; (builds the room), ClearBuffer, RunActorHandlers $A7BB, DrawActors $A7DD and
; CopyBuffer, StageFadeIn $9785; then the hero record: $74E3 (+3, the height) =
; $16, the state $74EA = 0, the base column $74ED = $0D; runs on into MainLoop.
;
; Stage 1's StageEntry ($7800) has the same job but enters grid 0 at room 2,
; with no StageFadeIn call and no hero fields of its own (known from the code
; at $7826 and $7839-$7847).
;
; Witness: L1 2 (rzx-r3, s3-right).
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
  XOR A
  LD (GridNumber),A
  INC A
  LD (RoomNumber),A
  CALL StartGrid
  CALL ClearBuffer
  CALL RunActorHandlers
  CALL DrawActors
  CALL CopyBuffer
  CALL StageFadeIn
  LD A,$16
  LD (HeroHeight),A
  XOR A
  LD (HeroState),A
  LD A,$0D
  LD (HeroBaseX),A

; One pass: pace, HUD, input, actors, the stage's hazards, draw, copy; SPACE
; opens the item window
;
; The pass, in order: PacePass, ShowPieceTaken, FlashPieces, CheckPause
; (ENTER), SpawnTimer, RedrawItemsIfChanged, ClearBuffer, CheckStageExit (may
; leave to EndStage), $A3FD, $A41E, UpdateMissiles $B384, RunActorHandlers
; $A7BB, DrawActors $A7DD, DrawDragon (grid 1 room 8), $9514 (grid 2: the
; throne giant's picture and its fireballs), UpdateBurst $A201, KeyHook, $A588
; (grid 0: the lightning), UpdateAttributes (attributes and CopyBuffer),
; PassTick $9815 (energy, lives flash, game over step), ShowScore, then the
; SPACE test TestSpaceKey.
;
; SPACE with CAPS SHIFT ends the stage with E = 1 (QuitStage); SPACE alone
; opens ItemWindow while HeroFreeze is 0. The loop goes on while Lives is not 0
; or the hero's state $74EA is not 0; with no lives and the hero back in state
; 0 it runs on into GameOverExit (E = 0).
;
; Stage 1's MainLoop at $7839 has the same frame; it calls DrawArenaPicture,
; ZoneDamage and DrawRoomPicture where stage 3 calls DrawDragon, $9514 and
; $A588, and tests the hero's state $0F (not HeroFreeze) before the item
; window.
;
; Witness: L1 6279 (rzx-r3, s3-right).
MainLoop:
  CALL PacePass
  CALL ShowPieceTaken
  CALL FlashPieces
  CALL CheckPause
  CALL SpawnTimer
  CALL RedrawItemsIfChanged
  CALL ClearBuffer
  CALL CheckStageExit
  CALL RainChance
  CALL UpdateRain
  CALL UpdateMissiles
  CALL RunActorHandlers
  CALL DrawActors
  CALL DrawDragon
  CALL ThroneBossStep
  CALL UpdateBurst
  CALL KeyHook
  CALL LightningStep
  CALL UpdateAttributes
  CALL PassTick
  CALL ShowScore
  CALL TestSpaceKey
  JR NZ,MainLoopNext
MainLoopSpace:
  LD BC,$FEFE             ; SPACE pressed: CAPS SHIFT too quits, else the item
                          ; window while HeroFreeze is 0
  IN A,(C)
  BIT 0,A
  JP Z,QuitStage
  LD A,(HeroFreeze)
  CP $00
  CALL Z,ItemWindow
MainLoopNext:
  LD A,(Lives)            ; go on while lives are left or the hero is not back
                          ; in state 0
  CP $00
  JR NZ,MainLoop
  LD A,(HeroState)
  CP $00
  JP NZ,MainLoop

  ORG $970D

; Set up the stage's screen: the HUD, its colours, the score and the items
;
; Clears the screen and the shadow, copies the HUD's colours $7600 (6 rows)
; into the shadow and shows them,
;
; dissolves the HUD's picture $7000 in (DissolveHud), paints the HUD's boxes
; (FillShadowAttributes x 4), then draws
;
; the items with $7D24 / $7C73 three times (with $7CDB patched to RET and
; ItemSelected = 3), the score, the score's
;
; reveal (RevealScore) and the lives (JP $7DBB).
;
; Stage 1's StageSetUp at $97AC is the same code.
;
; Witness: L1 2 (rzx-r3, s3-right).
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
; Stage 1's StageFadeIn at $9824 is the same code.
;
; Witness: L1 2 (rzx-r3, s3-right).
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

; A second fade-in from the screen's own attributes: no code reaches it
;
; SaveAttributes `$B238`, then 7 rounds of 5 passes (PassCounter from 0, a HALT
; and FadeInLeftoverStep each), then WaitFrames `$8AD6` with BC = `$64`. No
; CALL, JP or word in the image reaches `$97A3` (ref search of the image's
; bytes `$A3 $97`).
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
; known only from the code.
FadeInFromScreen:
  CALL SaveAttributes
  LD B,$07
FadeInFromScreenRound:
  PUSH BC
  XOR A
  LD (PassCounter),A
  LD B,$05
FadeInFromScreenPass:
  PUSH BC
  HALT
  CALL FadeInLeftoverStep
  LD HL,PassCounter
  INC (HL)
  POP BC
  DJNZ FadeInFromScreenPass
  POP BC
  DJNZ FadeInFromScreenRound
  LD BC,$0064
  CALL WaitFrames
  RET

; One fade step over the 576 play-area attributes, ink and paper (called only
; by FadeInFromScreen)
;
; From `$58C2` against the shadow `$6DC2`, `$0240` cells: where the shadow is
; not 0, on odd passes the ink steps up, on even ones down toward 0, then the
; paper (bits 3-5) the same way by 8. FadeInStep `$96DF`'s job with the paper
; too. Called by FadeInFromScreen only.
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
; known only from the code.
FadeInLeftoverStep:
  LD HL,Attributes+194
  LD DE,PlayAttributesCell
  LD BC,$0240
FadeInLeftoverCell:
  PUSH BC
  LD A,(DE)
  CP $00
  JR Z,FadeInLeftoverNext
  LD A,(PassCounter)
  AND $01
  JR Z,FadeInLeftoverInkDown
  INC (HL)
  JR FadeInLeftoverPaper
FadeInLeftoverInkDown:
  LD A,(HL)
  AND $07
  CP $00
  JR Z,FadeInLeftoverPaper
  DEC (HL)
FadeInLeftoverPaper:
  LD A,(DE)
  AND $38
  JR Z,FadeInLeftoverNext
  LD A,(PassCounter)
  AND $01
  JR Z,FadeInLeftoverPaperDown
  LD A,(HL)
  ADD A,$08
  LD (HL),A
  JR FadeInLeftoverNext
FadeInLeftoverPaperDown:
  LD A,(HL)
  AND $38
  JR Z,FadeInLeftoverNext
  LD A,(HL)
  SUB $08
  LD (HL),A
FadeInLeftoverNext:
  INC DE
  INC HL
  POP BC
  DEC BC
  LD A,B
  OR C
  JR NZ,FadeInLeftoverCell
  RET

; B x (3 HALTs + PassTick)
;
; Stage 1's IdlePasses at $9842 is the same code.
;
; Witness: L1 60 (rzx-r3, s3-right).
IdlePasses:
  PUSH BC
  HALT
  HALT
  HALT
  CALL PassTick
  POP BC
  DJNZ IdlePasses
  RET

  ORG $9825

; Raise the score's digits into the HUD line by line (8 steps)
;
; Draws 1 to 8 lines of the digit buffer $7640 at columns 6 (6 wide) and 15 (2
; wide), one line higher each step.
;
; Stage 1's RevealScore at $985D is the same code.
;
; Witness: L1 2 (rzx-r3, s3-right).
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
