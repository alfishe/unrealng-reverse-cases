; --------------------------------------------------------------------------------------------------------------------
; entry.asm: The stage's entry and set-up
;
; Stage 5's block is entered at StageEntry $7800 by the resident stage loader with H = the lives. StageEntry sets up
; the stage (the work space $FE08-$FE56, the HUD, the duel's variables, the two text pages, the hero, the shot and
; missile tables, the stars) and falls into MainLoop. Stage 5 has no stage-completed exit: it returns to the loader
; only with E = 0 (no lives) or E = 1 (CAPS SHIFT + SPACE).
;
; StageEntry $7800 calls InitStageState, StageSetUp and QuietPasses before the texts are drawn; RevealScore and the
; HUD's boxes are stage 1's.
; --------------------------------------------------------------------------------------------------------------------

  ORG $7800

; Start the stage: lives from H, variables, HUD, duel, texts, hero, stars, then
; the main loop
;
; Called by the resident stage loader with H = the lives left. Stores H in
; Lives ($FE58), then: InitStageState $96DD (clears $FE08-$FE56, the carried
; items from StartItems, the energy refill $2E in EnergyChange $FE53),
; StageSetUp $95E4 (the title, the HUD, the item strip rolled in, the score
; revealed), QuietPasses $965D (30 idle passes of 3 frames: the HUD's energy
; refill and lives flash run). Then FireLatch $FE3A = 0, Dameron's X DameronX
; $FE3E = 0 and Y DameronY $FE3F = $8E (below the play area), the path index
; DameronPathIndex $FE40 = $FF, the phase DuelPhase $FE43 = $FF (the intro
; text), the text timer DuelTimer $FE45 = $044C, the burst timer BurstTimer
; $FE49 = $65 (idle).
;
; Then DrawIntroText $8DAF and DrawEndingText $8DDE (the intro and the ending
; texts drawn into the play buffer at PlayBuffer $5B00 and $6200),
; ClearHeroShots, InitHero, ClearMissiles, InitStars, and falls into MainLoop.
;
; Witness: L1 3 (ending, rzx-r5, s5-right).
StageEntry:
  LD A,H
  LD (Lives),A
  CALL InitStageState
  CALL StageSetUp
  CALL QuietPasses
  LD A,$00
  LD (FireLatch),A
  LD A,$00
  LD (DameronX),A
  LD A,$8E
  LD (DameronY),A
  LD A,$FF
  LD (DameronPathIndex),A
  LD A,$FF
  LD (DuelPhase),A
  LD HL,$044C
  LD (DuelTimer),HL
  LD A,$65
  LD (BurstTimer),A
  CALL DrawIntroText
  CALL DrawEndingText
  CALL ClearHeroShots
  CALL InitHero
  CALL ClearMissiles
  CALL InitStars

  ORG $95E4

; Set up the stage's screen: the HUD, its colours, the score and the items
;
; ClearScreen, ClearShadowAttributes, the HUD's colours HudColours $7600 (192
; bytes, rows 0-5) into the shadow and shown (ShowShadowAttributes), WaitFrames
; 50, DissolveHud with the picture HudPicture $7000, WaitFrames 50, the four
; boxes (FillShadowAttributes with HudBox1-HudBox4), ShowShadowAttributes. Then
; ItemSelected $FE35 = 3, CycleWindowFrame $7C99 patched to RET, DrawItemStrip
; $7CE3 and ScrollItemsLeft $7C31 three times, CycleWindowFrame $7C99 back to 0
; (NOP), RenderScore $7B14 (the score), RevealScore, FlashSelectedBox $7C1A,
; SaveAttributes and JP StartLivesFlash $7D7F. Called once from $7807. As stage
; 1's StageSetUp $97AC.
;
; Witness: L1 3 (ending, rzx-r5, s5-right).
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

; FillShadowAttributes' data: column 6, line 8, width 6, height 1, colour $41
; (bright blue on black)
HudBox1:
  DEFB $06,$08,$06,$01,$41

; HudBoxPaint2
HudBoxPaint2:
  CALL FillShadowAttributes ; the code resumes after the 5 bytes

; column 10, line 24, width 12, height 2, colour $41
HudBox2:
  DEFB $0A,$18,$0C,$02,$41

; HudBoxPaint3
HudBoxPaint3:
  CALL FillShadowAttributes

; column 15, line 8, width 2, height 1, colour $41
HudBox3:
  DEFB $0F,$08,$02,$01,$41

; HudBoxPaint4
HudBoxPaint4:
  CALL FillShadowAttributes

; the play area: column 2, line 48, width 28, height 18, colour 0 (black)
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
  LD A,$00
  LD (CycleWindowFrame),A
  CALL RenderScore
  CALL RevealScore
  CALL FlashSelectedBox
  CALL SaveAttributes
  JP StartLivesFlash

; Run 30 quiet passes (IdlePasses with B = 30)
;
; Called once from $780A. Stage 1's StageFadeIn $9824 ran the same 30 passes
; and then faded the room in; stage 5 has no fade.
;
; Witness: L1 3 (ending, rzx-r5, s5-right).
QuietPasses:
  LD B,$1E
  CALL IdlePasses
  RET

; B x (3 HALTs + PassTick)
;
; As in stage 1 at $9842, the same code.
;
; Witness: L1 90 (ending, rzx-r5, s5-right).
IdlePasses:
  PUSH BC
  HALT
  HALT
  HALT
  CALL PassTick
  POP BC
  DJNZ IdlePasses
  RET

  ORG $967E

; Raise the score's digits into the HUD line by line (8 steps)
;
; Draws 1 to 8 lines of the digit buffer DigitBuffer $7640 at column 6 (6 wide)
; and column 15 (2 wide) through CopyToScreen $7979, from pixel line 15 up, one
; line higher and one line more each step, a HALT a step. Called by StageSetUp.
; As in stage 1 at $985D, the same code.
;
; Witness: L1 3 (ending, rzx-r5, s5-right).
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

  ORG $96DD

; Clear and set the stage variables at the start of the stage
;
; Clears $FE08-$FE56 (79 bytes), copies the 12 starting carried-object kinds
; from StartItems $7E7F to CarriedItems $7E67, seeds RandomPointer $FE0A from R
; (overwritten below), then: InitOnly51 $FE51 = 1, InitOnly50 $FE50 = $0D,
; LineCount $FE30 = 2, InitOnly32 $FE32 = 1, InitOnly4E $FE4E = $10, ItemFirst
; $FE37 = 6, ItemSelected $FE35 = 6, ItemLast $FE36 = 6, RandomSeed $FE08 and
; RandomPointer $FE0A = $07CF, EnergyChange $FE53 = $2E (the energy fills up to
; full). Called once from $7804.
;
; Stage 1's InitStageState $9DA1 in the same order with stage 5's addresses;
; stage 5 drops SpawnDelay, BurstTimer (StageEntry sets BurstTimer $FE49 = $65
; itself), RespawnShiftX and the bosses' counters.
;
; Witness: L1 3 (ending, rzx-r5, s5-right).
InitStageState:
  LD HL,RandomSeed
  LD DE,RandomSeed+1
  LD BC,$004E
  LD (HL),$00
  LDIR
  LD HL,StartItems
  LD DE,CarriedItems
  LD BC,$000C
  LDIR
  LD A,R
  LD C,A
  LD A,R
  LD B,A
  LD (RandomPointer),BC
  LD A,$01
  LD (InitOnly51),A
  LD A,$0D
  LD (InitOnly50),A
  LD A,$02
  LD (LineCount),A
  LD A,$01
  LD (InitOnly32),A
  LD A,$10
  LD (InitOnly4E),A
  LD A,$06
  LD (ItemFirst),A
  LD A,$06
  LD (ItemSelected),A
  LD A,$06
  LD (ItemLast),A
  LD HL,$07CF
  LD (RandomSeed),HL
  LD (RandomPointer),HL
  LD A,$2E
  LD (EnergyChange),A
  RET
