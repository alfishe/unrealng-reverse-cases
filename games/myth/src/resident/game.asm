; --------------------------------------------------------------------------------------------------------------------
; game.asm: The game: the stage chain, PlayStage, the game over menu
;
; NewGame starts a game with 5 lives and 4 credits, then plays the five stages in order: a stage completed (E = 2 from
; the stage's code) goes on to the next; a lost one goes to GameOver, which retries it (RESTART THIS STAGE, a credit
; less) or jumps to RestartFromStageOne. Stage 5 loops on itself.
; --------------------------------------------------------------------------------------------------------------------

; Score and amount 0, lives 5, credits 4, then the five stages in turn
;
; Reached from the front's StartGame by RET (front notes). Witness: L1 4 (c1,
; joystick, menu, rzx-r0).
NewGame:
  LD HL,$0000
  LD (Score),HL
  XOR A
  LD (ScoreHigh),A
  LD A,$05
  LD (Lives),A
  LD A,$04
  LD (Credits),A
PlayStage1:
  LD IY,StageTable        ; stage 1 until completed
  CALL PlayStage
  JR Z,PlayStage2
  CALL GameOver
  JR PlayStage1
PlayStage2:
  LD IY,StageRecord2
  CALL PlayStage
  JR Z,PlayStage3
  CALL GameOver
  JR PlayStage2
PlayStage3:
  LD IY,StageRecord3
  CALL PlayStage
  JR Z,PlayStage4
  CALL GameOver
  JR PlayStage3
PlayStage4:
  LD IY,StageRecord4
  CALL PlayStage
  JR Z,PlayStage5
  CALL GameOver
  JR PlayStage4
PlayStage5:
  LD IY,StageRecord5      ; stage 5: the same either way
  CALL PlayStage
  JR Z,PlayStage5
  CALL GameOver
  JR PlayStage5

; The five stages: the load parameters, then the two title lines as Print data
;
; A record: D, E (not read by the resident: LoadStage keeps B, H, L; known only
; from the code), C the stage number (StageLoaded, StageCheck), H, L and B (the
; length: 2 x (9B + H + L) pages of 256 bytes, 132 = 33 792 bytes for every
; stage), then two Print strings (column byte, bit, row, text, 0): STAGE N and
; its title. Read by PlayStage (c1: stage 1; sN-right: stages 2-5).
StageTable:
  INCBIN "res/resident/stages.bin",$0000,39
StageRecord2:
  INCBIN "res/resident/stages.bin",$0027,45
StageRecord3:
  INCBIN "res/resident/stages.bin",$0054,52
StageRecord4:
  INCBIN "res/resident/stages.bin",$0088,47
StageRecord5:
  INCBIN "res/resident/stages.bin",$00B7,41

; Show the titles, load the stage at IY (unless loaded), run it; Z when it was
; completed
;
; Input: IY a StageTable record. ClearScreen; if StageLoaded is not the
; record's stage, PRESS PLAY ON TAPE, WaitFrames, and the line cleared again.
; The two titles with PrintRecord. Then StageLoadLoop: LoadStage until it gives
; Z (the right block, StageCheck), each failure marking no stage loaded.
; SilenceAy, ClearScreen, H := Lives, CALL GameMain (the stage), Lives := H, CP
; E with 2, SilenceAy. Output: Z when the stage ended with E = 2 (completed),
; BC the address of the stage's score digits for GameOver. Witness: L1 8 (c1,
; joystick, menu, rzx-r0-rzx-r4).
PlayStage:
  PUSH IY
  CALL ClearScreen
  LD A,(StageLoaded)
  POP IY
  PUSH IY
  CP (IY+$02)
  JP Z,PlayStageTitles
  CALL Print              ; Print: the text follows

; The text: column byte 8, bit 2, row 52, PRESS PLAY ON TAPE
TextPressPlay:
  INCBIN "res/resident/text-press-play.bin",$0000,22

; wait, then clear the line
PlayStage2nd:
  CALL WaitFrames
  CALL Print

; The text: column byte 8, bit 2, row 52, a space (clears the line:
; TextToBuffer clears the buffer)
TextClearLine:
  INCBIN "res/resident/text-clear-line.bin",$0000,5

; the record's two title lines
;
; Used by the routine at PlayStage.
PlayStageTitles:
  POP IY
  PUSH IY
  LD BC,$0006
  ADD IY,BC
  CALL PrintRecord
  CALL PrintRecord
  POP IY
StageLoadLoop:
  LD D,(IY+$00)           ; load until the block is the stage's
  LD E,(IY+$01)
  LD C,(IY+$02)
  LD H,(IY+$03)
  LD L,(IY+$04)
  LD B,(IY+$05)
  CALL LoadStage
  JR Z,StageRun
  LD A,$FF
  LD (StageLoaded),A
  JR StageLoadLoop
StageRun:
  CALL SilenceAy          ; the stage itself
  CALL ClearScreen
  LD A,(Lives)
  LD H,A
  CALL GameMain
  LD A,H
  LD (Lives),A
  LD A,E
  CP $02
  PUSH AF
  PUSH BC
  CALL SilenceAy
  POP BC
  POP AF
  RET

; GAME OVER: a credit less, the menu RESTART THIS STAGE / RESTART FROM STAGE
; ONE, SPACE chooses
;
; Input: BC the address of the stage's six score digits (copied into the menu's
; SCORE). Credits := Credits - 1 (the POKE "credits 62045,0" is the DEC A at
; $F25D, src/tape notes), shown as a digit. ClearScreen, GAME OVER, PRESS SPACE
; TO SELECT, 20 rounds of HALT + CycleColours (which HALTs again): 40 frames,
; the menu. Every 64 frames (32 rounds of two HALTs, FrameCounter AND $1F = 0)
; the highlight moves to the other line (with no credit left it stays on
; RESTART FROM STAGE ONE); SPACE takes the highlighted one: RESTART THIS STAGE
; sets Lives := 5 and returns (PlayStage again), RESTART FROM STAGE ONE drops
; the return and jumps to RestartFromStageOne. Witness: L1 4 (s1-right,
; s2-right, s3-right, s4-right).
GameOver:
  PUSH BC
  POP HL
  LD DE,ScoreDigits
  LD BC,$0006
  LDIR
  LD A,$FC
  LD (FrameCounter),A
  LD A,(Credits)
CreditsDec:
  DEC A                   ; DEC A: the credit a game over costs
  LD (Credits),A
  ADD A,$30
  LD (CreditsDigit),A
  CALL ClearScreen
  CALL Print              ; Print: the text follows

; The text: column byte 12, bit 0, row 40, GAME OVER
TextGameOver:
  INCBIN "res/resident/text-game-over.bin",$0000,13

; Print the second line
GameOver2:
  CALL Print

; The text: column byte 7, bit 0, row 52, PRESS SPACE TO SELECT
TextPressSpace:
  INCBIN "res/resident/text-press-space.bin",$0000,25

; 40 frames of colours (20 rounds of two HALTs), the menu, then the choice
GameOver3:
  LD B,$14
GameOverPause:
  PUSH BC
  HALT
  CALL CycleColours
  POP BC
  DJNZ GameOverPause
  CALL PrintGameOverMenu
  LD A,$01
  LD (GameOverOption),A
; This entry point is used by the routine at GameOver4.
GameOverLoop:
  HALT                    ; one frame; GameOver4's CycleColours HALTs again, so
                          ; a round is two frames
  LD A,(FrameCounter)
  AND $1F
  JR NZ,GameOver4
  LD E,$00
  LD A,(Credits)
  CP $00
  JR NZ,GameOverToggle
  LD E,$01
GameOverToggle:
  LD A,(GameOverOption)
  INC A
  CP $02
  JR NZ,GameOverSetOption
  LD A,E
GameOverSetOption:
  LD (GameOverOption),A
  SLA A
  ADD A,$0A
  LD (HighlightRow),A
  CALL SetMenuBands
  CALL AttrBox            ; AttrBox: the highlight bar, its row patched above

; AttrBox data: column 0, row (10 + 2 x option, written at $F2CA), 32 wide, 1
; high, attribute $43
HighlightBox:
  DEFB $00
HighlightRow:
  DEFB $00,$20,$01,$43    ; the row, written by GameOver

; CycleColours, then SPACE (port $7FFE bit 0)
;
; Used by the routine at GameOver3.
GameOver4:
  CALL CycleColours
  LD BC,$7FFE
  IN A,(C)
  BIT 0,A
  JR NZ,GameOverLoop
  LD A,(GameOverOption)
  CP $00
  JR Z,GameOverRetry
  POP HL
  CP $01
  JP Z,RestartFromStageOne
GameOverRetry:
  LD A,$05                ; RESTART THIS STAGE: Lives := 5, return
  LD (Lives),A
  RET

; Print the two options and the credits and score line
;
; Witness: L1 4 (s1-right, s2-right, s3-right, s4-right).
PrintGameOverMenu:
  CALL Print

; The text: column byte 8, bit 5, row 84, RESTART THIS STAGE
TextRestartStage:
  INCBIN "res/resident/text-restart-stage.bin",$0000,22

; PrintGameOverMenu2
PrintGameOverMenu2:
  CALL Print

; The text: column byte 6, bit 3, row 100, RESTART FROM STAGE ONE
TextRestartFromOne:
  INCBIN "res/resident/text-restart-from-one.bin",$0000,26

; PrintGameOverMenu3
PrintGameOverMenu3:
  CALL Print

; The text: column byte 1, bit 6, row 148, GAME CREDITS n   SCORE nnnnnn (n
; written by GameOver)
TextCreditsScore:
  INCBIN "res/resident/text-credits-score.bin",$0000,16
CreditsDigit:
  INCBIN "res/resident/text-credits-score.bin",$0010,14
ScoreDigits:
  INCBIN "res/resident/text-credits-score.bin",$001E,7

; PrintGameOverMenuEnd
PrintGameOverMenuEnd:
  RET

  ORG $F5D9

; B times 50 000 loop passes
;
; Not executed in any recording (all checked); stage 4's code refers to it
; (known only from the code: work/stage2/loader/xref.txt).
DelayB:
  LD HL,50000
DelayBLoop:
  DEC HL
  LD A,H
  OR L
  JR NZ,DelayBLoop
  DJNZ DelayB
  RET
