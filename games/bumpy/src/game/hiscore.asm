; --------------------------------------------------------------------------------------------------------------------
; hiscore.asm: Game over, the hall of fame and the return to the menu
;
; The end of a player's game: the hall of fame check, the two-player hand-over and the way back to the menu.
;
; The hall of fame is four PrintText strings of 32 bytes (HallOfFame $EEB3): AT, attribute, double height, a three-
; letter name, " : ", five digits and the score word. A player whose score is not below the lowest entry ($EF25)
; enters it when his game ends (GameOver $B755, EnterHallOfFame $EC40).
; --------------------------------------------------------------------------------------------------------------------

  ORG $B755

; A player has lost his last ball: hall of fame, mark him out, hand over or end
; the game
;
; Entered from LoseLife $BA93 when the lives ($AB01) are 0. IX = the record of
; the player in play: $AB09 for player 1 ($ADDB = 1), $AB10 for player 2. When
; the score ($AAFB) is not below the lowest hall of fame score (the word at
; $EF25), NameEntry $EC40 runs. Then the record's lives byte (IX+6) is set to
; $FA, the mark of a player out of the game.
;
; One player ($ADDC = 1), or the other player already out ($FA in his record):
; GameOverPause $B7A9 and back to the menu. Otherwise the game passes to the
; other player through LoseLife's hand-over ($BADF or $BAF1). Witness: the
; game-over recording (stage1/gameover) ends here; the RZX never loses its last
; life; the two-player branches ran in stage2/rec/twoname (both players to the
; end: player 1 out, the hand-over $BADF/$BAF1 to player 2, then the menu).
;
; Witness: L1 4 (gameover, twoname).
GameOver:
  LD IX,Player1Record
  LD A,(CurrentPlayer)
  CP $01
  JR Z,GameOverHiScore
  LD IX,Player2Record
GameOverHiScore:
  PUSH IX                 ; compare the score with the hall of fame's last
                          ; entry
  PUSH AF
  AND A
  LD HL,(Score)
  LD IX,HallOfFame+$0072
  LD D,(IX+$01)
  LD E,(IX+$00)
  SBC HL,DE
  CALL NC,EnterHallOfFame
GameOverMarkOut:
  AND A                   ; mark the player out ($FA)
  POP AF
  POP IX
  LD (IX+$06),$FA
  LD IX,Player1Record
  CP $01
  JR Z,GameOverPlayer1
  LD A,(IX+$06)
  CP $FA
  JP Z,GameOverPause
  AND A
  JP SwitchToPlayer1
GameOverPlayer1:
  LD A,(PlayerCount)      ; player 1 was in play: is player 2 still in?
  CP $01
  JR Z,GameOverPause
  LD A,(IX+$0D)
  CP $FA
  JP Z,GameOverPause
  AND A
  JP SwitchToPlayer2

; Wait about 2.5 seconds, then back to the menu
;
; Twenty times GameOverDelay $C4D5 (each about 40 000 delay loops and a frame),
; then BackToMenu $B7B2. Entered from GameOver $B755 and from the end of the
; demo ($B3A8).
;
; Witness: L1 3 (gameover, menu, twoname).
GameOverPause:
  LD B,$14
GameOverPauseLoop:
  PUSH BC
  CALL GameOverDelay
  POP BC
  DJNZ GameOverPauseLoop

; Wait up to a second for a key, then restart at the menu
;
; WaitKeyOrSecond $B7B8, then JP $AB7D (the menu and a new game). Entered from
; GameOverPause and from MainLoop when the quit key ($2B, see $ACEC) is down.
;
; Witness: L1 6 (gameover, menu, twoname).
BackToMenu:
  CALL WaitKeyOrSecond
  JP GameRestart

  ORG $C4D5

; Two Delay(200) and a frame: about 2 × 130 000 T-states
;
; Called 20 times by GameOverPause $B7A9.
;
; Witness: L1 60 (gameover, menu, twoname).
GameOverDelay:
  LD B,$C8
  CALL Delay
  LD B,$C8
  CALL Delay
  EI
  HALT
  RET

  ORG $EC40

; Game over: flash the border, put the score in the hall of fame and enter the
; name
;
; Called by the game over $B777. 250 x 8 border colours 7..0 with a delay
; ($B873, B = 2) between them. Then the place: the score $AAFB is compared with
; the scores (+$12) of records 1-3 only; at the first lower one, the records
; from there down to the third move one down (LDDR $EF12 to $EF32, $60 - 32 x
; place bytes) and the score goes in its place. A score below all three goes to
; record 4 without a compare (GameOver called this routine only because the
; score is not below record 4's, $EF25). In the gameover recording the score
; went to record 4 and the move at $EC8E never ran.
;
; The record gets the score, the name "..." ($2E), its digits (ScoreToDigits);
; then ShowHallOfFame and EnterName. Output: ($ED93) = the record.
;
; Witness: L1 3 (gameover, twoname).
EnterHallOfFame:
  LD B,$FA
EnterHallOfFameLoop:
  PUSH BC
  LD B,$08
EnterHallOfFameLoop2:
  PUSH BC
  DEC B
  LD A,B
  AND $07
  OUT ($FE),A
  LD B,$02
  CALL Delay
  POP BC
  DJNZ EnterHallOfFameLoop2
  POP BC
  DJNZ EnterHallOfFameLoop
  LD IX,HallOfFame
  DI
  PUSH IY
  LD IY,$0060
  LD B,$03
EnterHallOfFameLoop3:
  PUSH BC
  LD E,(IX+$12)
  LD D,(IX+$13)
  LD HL,(Score)
  AND A
  SBC HL,DE
  JR NC,EnterHallOfFameSkip
  LD BC,$0020
  AND A
  PUSH IX
  POP HL
  ADD HL,BC
  PUSH HL
  POP IX
  PUSH IY
  POP HL
  SBC HL,BC
  PUSH HL
  POP IY
  POP BC
  DJNZ EnterHallOfFameLoop3
  POP IY
  EI
  JR EnterHallOfFameSkip2
EnterHallOfFameSkip:
  POP BC
  LD DE,HallOfFame+$007F
  LD HL,HallOfFame+$005F
  PUSH IY
  POP BC
  LDDR
  POP IY
  EI
EnterHallOfFameSkip2:
  LD (NewRecordPtr),IX
  LD HL,(Score)
  LD (IX+$12),L
  LD (IX+$13),H
  LD (IX+$06),$2E
  LD (IX+$07),$2E
  LD (IX+$08),$2E
  CALL ScoreToDigits
  CALL ShowHallOfFame
  CALL EnterName
  RET

; The name entry: three letters, chosen by left and right, each confirmed by
; fire or up
;
; Waits for all keys up ($B401). For each of the three letters at record +6:
; the letter starts at "@" ($40); right ($F087, $B44E) steps it up and left
; ($F086, $B447) down; right wraps from "Y" to "@" (INC, CP $5A, JR C), left
; from "@" to "Z", so "Z" is reached only by left; fire or up ($F088 / $F084,
; $B463) waits for the keys up and goes to the next letter. The table is
; reprinted (PrintHallOfFame) after each test and 5 HALTs (0.1 s) pass. In the
; gameover recording no key was pressed: 394 rounds on the first letter. In
; stage2/rec/twoname both players typed their names (B U M by right, left and
; fire, then Z A P with Z by left from "@"): the polling once every 5 HALTs is
; why a 4-frame tap can be missed.
;
; Witness: L1 3 (gameover, twoname).
EnterName:
  CALL WaitRelease
  LD HL,(NewRecordPtr)
  LD BC,$0006
  ADD HL,BC
  LD (NameLetterPtr),HL
  LD B,$03
EnterNameLoop:
  LD (HL),$40
  PUSH BC
EnterNameLoop2:
  CALL TestUpOrFire
  JR NZ,EnterNameSkip5
  CALL TestRight
  JR Z,EnterNameSkip2
  LD HL,(NameLetterPtr)
  LD A,(HL)
  INC A
  CP $5A
  JR C,EnterNameSkip
  LD A,$40
EnterNameSkip:
  LD (HL),A
  JR EnterNameSkip4
EnterNameSkip2:
  CALL TestLeft
  JR Z,EnterNameSkip4
  LD HL,(NameLetterPtr)
  LD A,(HL)
  DEC A
  CP $40
  JR NC,EnterNameSkip3
  LD A,$5A
EnterNameSkip3:
  LD (HL),A
EnterNameSkip4:
  CALL PrintHallOfFame
  EI
  HALT
  EI
  HALT
  EI
  HALT
  EI
  HALT
  EI
  HALT
  JR EnterNameLoop2
EnterNameSkip5:
  CALL WaitRelease
  LD HL,(NameLetterPtr)
  INC HL
  LD (NameLetterPtr),HL
  POP BC
  DJNZ EnterNameLoop
  RET

; EnterName: the address of the letter being chosen
NameLetterPtr:
  DEFW $0000

; Clear the screen and draw the hall of fame: the lines, the title and the four
; records
;
; Border 0, ClearScreen $F0CB, DrawHofLines, PrintText HofTitleText $EDEF,
; PrintHallOfFame.
;
; Witness: L1 4 (gameover, menu, twoname).
ShowHallOfFame:
  XOR A
  OUT ($FE),A
  CALL ClearScreen
  CALL DrawHofLines
  LD HL,HofTitleText
  CALL PrintText
  CALL PrintHallOfFame
  RET

; Print the four records at rows 7, 10, 13 and 16
;
; Each record's row byte (+1) is set (7, 10, 13, 16), then PrintText.
;
; Witness: L1 714 (gameover, menu, twoname).
PrintHallOfFame:
  LD HL,HallOfFame
  LD B,$04
  LD A,$07
PrintHallOfFameLoop:
  PUSH BC
  PUSH HL
  PUSH HL
  POP IX
  LD (IX+$01),A
  PUSH AF
  CALL PrintText
  POP AF
  ADD A,$03
  POP HL
  LD BC,$0020
  ADD HL,BC
  POP BC
  DJNZ PrintHallOfFameLoop
  RET

; Write the new record's score (+$12) as five ASCII digits at +$0C-$10
;
; The record from ($ED93).
;
; Witness: L1 3 (gameover, twoname).
ScoreToDigits:
  LD IX,(NewRecordPtr)
  LD L,(IX+$12)
  LD H,(IX+$13)
  LD DE,$2710
  CALL DigitOf
  LD (IX+$0C),A
  LD DE,$03E8
  CALL DigitOf
  LD (IX+$0D),A
  LD DE,$0064
  CALL DigitOf
  LD (IX+$0E),A
  LD DE,$000A
  CALL DigitOf
  LD (IX+$0F),A
  LD DE,$0001
  CALL DigitOf
  LD (IX+$10),A
  RET

; A = "0" + HL div DE; HL = HL mod DE
;
; Witness: L1 15 (gameover, twoname).
DigitOf:
  LD C,$00
DigitOfLoop:
  AND A
  SBC HL,DE
  JR C,DigitOfSkip
  INC C
  JR DigitOfLoop
DigitOfSkip:
  ADD HL,DE
  LD A,$30
  ADD A,C
  RET

; The hall-of-fame record the last game entered
NewRecordPtr:
  DEFW $EF13

; Draw the hall of fame's perspective lines at the top and the bottom of the
; screen
;
; For each row n of HofLineRows (to $FF): screen line n gets 31 bytes of $88
; (dotted) and line n + 1 of $FF (solid) from column 0; line 192 - n gets $FF
; and the next $88: the lines draw closer towards the middle of the screen.
;
; Witness: L1 4 (gameover, menu, twoname).
DrawHofLines:
  LD IX,HofLineRows
  LD B,$64
DrawHofLinesLoop:
  PUSH BC
  LD A,(IX+$00)
  CP $FF
  JR Z,DrawHofLinesSkip
  LD L,A
  LD H,$00
  ADD HL,HL
  PUSH HL
  LD DE,SpectrumLines+$000E
  ADD HL,DE
  LD C,$88
  LD B,$FF
  CALL DrawLinePair
  POP DE
  LD HL,SpectrumLines+$018E
  AND A
  SBC HL,DE
  LD B,$88
  LD C,$FF
  CALL DrawLinePair
  INC IX
  POP BC
  DJNZ DrawHofLinesLoop
  RET
DrawHofLinesSkip:
  POP BC
  RET

; Fill the line at the table entry HL with C and the next line with B
;
; Witness: L1 104 (gameover, menu, twoname).
DrawLinePair:
  PUSH BC
  PUSH HL
  LD A,C
  CALL FillLine
  POP HL
  POP BC
  INC HL
  INC HL
  LD A,B

; Fill 31 bytes of the screen line whose address is at (HL) with A
;
; Witness: L1 208 (gameover, menu, twoname).
FillLine:
  LD E,(HL)
  INC HL
  LD D,(HL)
  PUSH DE
  POP HL
  INC DE
  LD (HL),A
  LD BC,$001E
  LDIR
  RET

; The lines of DrawHofLines: 0, 2, 5, 8, 12, 17, 23, 30, 38, 48, 60, 73, 87,
; then $FF
HofLineRows:
  DEFB $00,$02,$05,$08,$0C,$11,$17,$1E
  DEFB $26,$30,$3C,$49,$57,$FF

; The hall of fame screen: coloured bars, "B U M P Y" and "H A L L  O F  F A M
; E" (PrintText)
HofTitleText:
  INCBIN "res/texts/hall-of-fame-title.bin",$0000,196

; The hall of fame: four records of 32 bytes, PrintText strings with the score
; word
;
; Each record: $16 row col (AT; the row is set by PrintHallOfFame), $14 $0F
; (attribute), $02 (double height), three letters, " : ", five digits, $00,
; then the score as a word (+$12) and 12 zeros. The tape's table: PAP 16000,
; PEP 08000, PIP 04000, POP 01700.
HallOfFame:
  INCBIN "res/tables/hall-of-fame.bin",$0000,128
