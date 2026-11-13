; --------------------------------------------------------------------------------------------------------------------
; entry.asm: The stage's entry and set-up
; --------------------------------------------------------------------------------------------------------------------

; Start the stage: lives from H, variables, HUD, the first room, then the main
; loop
;
; Called by the resident stage loader with H = the lives left. Stores H in
; Lives, then: InitStageState $9F71 (clears $FE08-$FE5B, the carried items from
; StartItems, the trap slots $9DAB-$9E1A, the start values), StageSetUp $9715
; (the HUD, the score, the item strip), $941C, ResetObjectLists $942B, RoomGrid
; = $9AE2 (grid 0) with Placements = $9B50, ReviveAllPlacements $A629, $A605,
; StartGrid $A5CC, RoomEvents $81A8, ClearBuffer $9A28, RunActorHandlers $A746,
; DrawActors $A768, CopyBuffer $9A4D and $978E; then falls into MainLoop.
; RoomNumber stays 0 (cleared by InitStageState).
;
; Witness: L1 2 (rzx-r4, s4-right).
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

  ORG $9715

; Set up the stage's screen: the HUD, its colours, the score and the items
;
; ClearScreen $90B9, ClearShadowAttributes $8F92, the HUD's colours $7600 (6
; rows, 192 bytes) into the shadow $6D00, ShowShadowAttributes $91C3, 50 frames
; ($915C), the HUD's picture $7000 dissolved in ($8FD6), 50 frames, the HUD's
; four boxes (FillShadowAttributes $9193 x 4, the inline 5-byte rectangles at
; `$973E`, `$9746`, `$974E`, `$9756`), ShowShadowAttributes; then ItemSelected
; = 3 and, with CycleWindowFrame $7D2D patched to RET, DrawItemStrip $7D76 and
; ScrollItemsLeft $7CC5 three times; $7D2D back to 0 (NOP), the score ($7BB5),
; RevealScore, FlashSelectedBox $7CAE, SaveAttributes $B380, and the lives'
; flash (JP $7E0D). As in stage 1 at `$97AC`.
;
; Witness: L1 2 (rzx-r4, s4-right).
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
; 30 x (3 HALTs + PassTick) (IdlePasses), then 7 rounds of 5 frames:
; PassCounter from 0, a HALT, FadeInStep, PassCounter + 1 and PlaySoundVector
; $0C each. Called from StageEntry `$7834`. As in stage 1 at `$9824`.
;
; Witness: L1 2 (rzx-r4, s4-right).
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
  LD DE,$000C
  CALL PlaySoundVector
  POP BC
  DJNZ FadeInFrame
  POP BC
  DJNZ FadeInRound
  RET

; B x (3 HALTs + PassTick)
;
; Witness: L1 60 (rzx-r4, s4-right).
IdlePasses:
  PUSH BC
  HALT
  HALT
  HALT
  CALL PassTick
  POP BC
  DJNZ IdlePasses
  RET

  ORG $97CD

; Raise the score's digits into the HUD line by line (8 steps)
;
; Draws 1 to 8 lines of the digit buffer $7640 at columns 6 (6 wide) and 15 (2
; wide) with CopyToScreen $79FD, one line higher each step, a HALT each.
;
; Witness: L1 2 (rzx-r4, s4-right).
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
