; --------------------------------------------------------------------------------------------------------------------
; hiscore.asm: The high-score table, the name entry, the game-over screen and the scroller
;
; HiScoreTable $FD14 holds 5 records of 15 bytes: 6 score digits (0-9 a byte, not ASCII) and a 9-character name. After
; a game GameOver $7FF3 compares ScoreDigits $FD94 with each record from the top (HiScoreCompare $7F60); the first
; record the score is not below takes it (HiScoreInsert $7F7A): the lower records move down one, the fifth is lost,
; and the name is typed in (EnterName $7F00). Then the game-over screen (GameOverScreen $8BD5).
;
; When the title tune runs out, the menu shows the table (ShowHiScores $B2E4) and runs the scroller ScrollerText $6D42
; along the bottom line until a key of half row 1-5 is pressed or the text ends.
; --------------------------------------------------------------------------------------------------------------------

; The menu scroller's text: 433 ASCII characters and a 0 end mark
;
; RunScroller $8AEB prints one character a step at the right end of the bottom
; line and scrolls the line left 8 pixels (ScrollBottomLine $8AAC) between
; characters. The text names the 1990 features (anti-gravity, 4D teleport,
; forcefields, bubbles, elixirs, "jumping jelly beans"), the keys G (abort), H
; (quit screen) and F (map), and "(C) 1990 MICHAEL BATTY".
;
; Witness: the menu build reads $6D42-$6D45 before its key press; the rest is
; read only by the same loop (known only from the code).
ScrollerText:
  INCBIN "res/texts/scroller.bin",$0000,434

  ORG $7F00

; Type a name into a high-score record
;
; HL = the record's name field (9 bytes), B = the record (1-5; the screen row
; is 2B + 10). Each key comes from WaitKey $8C1D (KeyTable $A900 gives its
; character) and is printed and stored; '0' deletes the last character, 'e'
; (ENTER) ends. Writes the name in place.
;
; Witness: L1 1 (hiscore).
EnterName:
  LD A,B
  RLCA
  ADD A,$0A
  LD HL,HiScoreTable-9
  LD DE,$000F
EnterNameLoop:
  ADD HL,DE
  DJNZ EnterNameLoop
  PUSH HL
  POP DE
  LD B,A
  LD C,$0F
EnterNameLoop2:
  PUSH BC
  PUSH DE
  CALL WaitKey
  POP DE
  POP BC
  INC HL
  LD A,(HL)
  CP $30
  JR NZ,EnterNameSkip2
  LD A,C
  CP $0F
  JR Z,EnterNameSkip
  DEC DE
  DEC C
EnterNameSkip:
  LD A,$20
  LD (DE),A
  PUSH DE
  PUSH BC
  LD D,$01
  LD HL,EnterPasswordText+$0005
  CALL PrintText
  POP BC
  POP DE
  CALL KeyClick
  JR EnterNameLoop2
EnterNameSkip2:
  CP $65
  RET Z
  CP $20
  JR Z,EnterNameSkip3
  CP $40
  JR C,EnterNameLoop2
  CP $5B
  JR NC,EnterNameLoop2
EnterNameSkip3:
  LD (DE),A
  PUSH DE
  POP HL
  PUSH DE
  LD D,$01
  PUSH BC
  CALL PrintText
  POP BC
  POP DE
  CALL KeyClick
  INC C
  INC DE
  LD A,C
  CP $18
  JR NZ,EnterNameLoop2
  RET

; Compare the score with high-score record B
;
; B = the record (1-5). HL = HiScoreTable + 15 x (B - 1), DE = ScoreDigits
; $FD94; the 6 digits are compared from the first. Out: carry set when the
; score is below the record, else carry clear.
;
; Witness: L1 9 (hiscore, lives).
HiScoreCompare:
  LD HL,HiScoreTable-15
  LD DE,$000F
HiScoreCompareLoop:
  ADD HL,DE
  DJNZ HiScoreCompareLoop
  LD DE,ScoreDigits
  LD C,$06
HiScoreCompareLoop2:
  LD A,(DE)
  CP (HL)
  RET C
  JR Z,HiScoreCompareSkip
  RET
HiScoreCompareSkip:
  INC HL
  INC DE
  DEC C
  JR NZ,HiScoreCompareLoop2
  RET

; Put the score into the table if it is not below a record
;
; Tries records 1-5 with HiScoreCompare $7F60. At the first the score is not
; below: ClearScreen, the lower records move down one (the fifth is lost), the
; score digits and a blank name go in, EnterName $7F00. Returns with no change
; when every record is above the score.
;
; Witness: L1 2 (hiscore, lives).
HiScoreInsert:
  LD B,$01
HiScoreInsertLoop:
  PUSH BC
  CALL HiScoreCompare
  POP BC
  JR NC,HiScoreInsertSkip
  INC B
  LD A,B
  CP $06
  JR NZ,HiScoreInsertLoop
  RET
HiScoreInsertSkip:
  PUSH BC
  CALL ClearScreen
  POP BC
  PUSH BC
  LD HL,HiScoreTable-15
  LD DE,$000F
HiScoreInsertLoop2:
  ADD HL,DE
  DJNZ HiScoreInsertLoop2
  POP BC
  PUSH BC
  PUSH HL
  POP DE
  PUSH DE
  LD A,$05
  SUB B
  JR Z,HiScoreInsertSkip2
  LD B,A
  LD HL,HiScoreTable+$002D
  LD DE,HiScoreTable+$003C
HiScoreInsertLoop3:
  PUSH BC
  PUSH HL
  PUSH DE
  LD BC,$000F
  LDIR
  POP DE
  POP HL
  POP BC
  LD A,L
  SUB $0F
  LD L,A
  LD A,E
  SUB $0F
  LD E,A
  DJNZ HiScoreInsertLoop3
HiScoreInsertSkip2:
  POP DE
  LD HL,ScoreDigits
  LD BC,$0006
  LDIR
  CALL ColourHiScores
  POP BC
  PUSH BC
  LD A,B
  RLCA
  ADD A,$0A
  LD B,A
  LD C,$0F
  LD D,$09
  LD HL,NameBuffer
  CALL PrintText
  POP BC
  PUSH BC
  LD HL,HiScoreTable-9
  LD DE,$000F
HiScoreInsertLoop4:
  ADD HL,DE
  DJNZ HiScoreInsertLoop4
  LD B,$09
HiScoreInsertLoop5:
  LD (HL),$20
  INC HL
  DJNZ HiScoreInsertLoop5
  POP BC
  CALL EnterName
  RET

; The end of a game: the high-score check, then the game-over screen
;
; HiScoreInsert $7F7A, GameOverScreen $8BD5. Called from NewGame $8BE5 after
; the last life.
;
; Witness: L1 2 (hiscore, lives).
GameOver:
  CALL HiScoreInsert
  CALL GameOverScreen
  RET

  ORG $8AAC

; Scroll the bottom character line one pixel left
;
; Witness: L1 3472 (menu).
ScrollBottomLine:
  LD HL,Screen+4351
  LD B,$08
ScrollBottomLineLoop:
  PUSH BC
  PUSH HL
  LD B,$1F
  RL (HL)
  LD A,(HL)
  DEC HL
ScrollBottomLineLoop2:
  RL (HL)
  DEC HL
  DJNZ ScrollBottomLineLoop2
  DEC HL
  POP HL
  LD BC,$0100
  ADD HL,BC
  POP BC
  DJNZ ScrollBottomLineLoop
  RET

; Clear the screen, print and colour the menu, show the logo
;
; Pixels 0, attributes $47, the last attribute 0; ShowMenuTexts $8A3C,
; ColourMenuTexts $8A83, ShowLogo $9091.
;
; Witness: L1 9 (c1, lives, menu).
DrawTitle:
  LD HL,Screen
  LD DE,Screen+1
  LD BC,$1800
  LD (HL),$00
  LDIR
  LD BC,$02FF
  LD (HL),$47
  LDIR
  LD HL,Attributes+767
  LD (HL),$00
  CALL ShowMenuTexts
  CALL ColourMenuTexts
  CALL ShowLogo
  RET

; Run the scroller until a key 1-5 or the text's end
;
; Out: the zero flag clear when a key stopped it.
;
; Witness: L1 1 (menu).
RunScroller:
  LD HL,ScrollerText
RunScrollerLoop:
  LD A,$F7
  OUT ($FF),A
  IN A,($FE)
  AND $1F
  CP $1F
  RET NZ
  PUSH HL
  LD B,$08
RunScrollerLoop2:
  PUSH BC
  CALL ScrollBottomLine
  LD DE,$0500
RunScrollerLoop3:
  DEC DE
  LD A,D
  OR E
  JR NZ,RunScrollerLoop3
  POP BC
  DJNZ RunScrollerLoop2
  POP HL
  PUSH HL
  LD BC,$171F
  LD D,$01
  CALL PrintText
  POP HL
  INC HL
  LD DE,ScrollerText+434
  SBC HL,DE
  RET Z
  ADD HL,DE
  JR RunScrollerLoop

  ORG $8B78

; Play GameOverTune $AA00
;
; Witness: L1 2 (hiscore, lives).
PlayGameOverTune:
  LD HL,GameOverTune
  CALL PlayTune
  RET

; Print GAME OVER, the score and the level reached
;
; Witness: L1 2 (hiscore, lives).
ShowGameOver:
  LD HL,GameOverTexts
  LD BC,$080C
  LD D,$09
  CALL PrintText
  LD HL,YouScoredText
  LD BC,$0A08
  LD D,$0A
  CALL PrintText
  LD BC,$0A18
  LD D,$06
  LD HL,ScoreDigits+$0005
  CALL PrintDigits
  LD HL,ReachedLevelText
  LD BC,$0C07
  LD D,$11
  CALL PrintText
  LD BC,$0C1A
  LD D,$02
  LD HL,CaveDigits+$0001
  CALL PrintDigits
  LD BC,$080C
  LD D,$09
  LD A,$44
  CALL FillAttrs
  LD BC,$0A08
  LD D,$0A
  LD A,$45
  CALL FillAttrs
  LD BC,$0C07
  LD D,$11
  LD A,$45
  CALL FillAttrs
  RET

; The game-over screen: clear, the texts, the tune, wait for a key
;
; ClearScreen, ShowGameOver $8B7F, PlayGameOverTune $8B78, ROM KEY-SCAN until a
; key.
;
; Witness: L1 2 (hiscore, lives).
GameOverScreen:
  CALL ClearScreen
  CALL ShowGameOver
  CALL PlayGameOverTune
GameOverScreenLoop:
  CALL RomKeyScan
  INC E
  JR Z,GameOverScreenLoop
  RET

  ORG $8D5D

; "HI-SCORES"
HiScoresTitle:
  DEFM "HI-SCORES"

  ORG $AA00

; The game-over tune
GameOverTune:
  INCBIN "res/music/game-over.bin",$0000,78

; "GAME OVER", "YOU SCORED", "AND REACHED LEVEL"
GameOverTexts:
  INCBIN "res/texts/game-over.bin",$0000,9
YouScoredText:
  INCBIN "res/texts/game-over.bin",$0009,10
ReachedLevelText:
  INCBIN "res/texts/game-over.bin",$0013,17

; A blank cell graphic (36 zeros): the high-score area is cleared with it
BlankGraphic:
  INCBIN "res/graphics/blank.bin",$0000,36

; Zeros (106 bytes)
GameOverPad:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $31,$20,$2E,$2E,$2E,$2E,$2E,$20
  DEFB $53,$54

  ORG $B26C

; Print the 5 records' scores and names
;
; Witness: L1 2 (hiscore, menu).
ShowHiScoreTable:
  LD HL,HiScoreTable+$0005
  LD B,$05
ShowHiScoreTableLoop:
  PUSH BC
  PUSH HL
  LD C,$0D
  LD A,$06
  SUB B
  RLCA
  ADD A,$0A
  LD B,A
  LD D,$06
  CALL PrintDigits
  POP HL
  PUSH HL
  LD D,$09
  INC HL
  LD C,$0F
  CALL PrintText
  POP HL
  POP BC
  LD DE,$000F
  ADD HL,DE
  DJNZ ShowHiScoreTableLoop
  RET

; Print HI-SCORES and the table
;
; Witness: L1 2 (hiscore, menu).
ShowHiScoreTitle:
  LD HL,HiScoresTitle
  LD D,$09
  LD BC,$0A0B
  CALL PrintText
  CALL ShowHiScoreTable
  RET

; Colour and print the high-score lines
;
; Witness: L1 2 (hiscore, menu).
ColourHiScores:
  LD B,$05
ColourHiScoresLoop:
  PUSH BC
  LD C,$08
  LD A,$06
  SUB B
  RLCA
  ADD A,$0A
  LD E,A
  LD D,$10
  LD A,$41
  ADD A,B
  LD B,E
  CALL FillAttrs
  POP BC
  DJNZ ColourHiScoresLoop
  CALL ShowHiScoreTitle
  LD BC,$0A0B
  LD D,$09
  LD A,$47
  CALL FillAttrs
  RET

; Clear rows 8-21 with BlankGraphic
;
; Witness: L1 2 (menu).
ClearHiScoreArea:
  LD C,$20
ClearHiScoreAreaLoop:
  PUSH BC
  LD B,$15
ClearHiScoreAreaLoop2:
  PUSH BC
  LD DE,BlankGraphic
  CALL PrintGlyph
  POP BC
  DEC B
  LD A,B
  CP $08
  JR NZ,ClearHiScoreAreaLoop2
  POP BC
  DEC C
  LD A,C
  CP $FF
  JR NZ,ClearHiScoreAreaLoop
  RET

; The high scores with the scroller, then the menu again
;
; Witness: L1 1 (menu).
ShowHiScores:
  CALL ClearHiScoreArea
  CALL ColourHiScores
  CALL RunScroller
  PUSH AF
  CALL ClearHiScoreArea
  CALL ShowMenuTexts
  CALL ColourMenuTexts
  POP AF
  RET

; Zeros (7 bytes)
ShowHiScoresPad:
  DEFS $07
