; --------------------------------------------------------------------------------------------------------------------
; menudata.asm: The tunes, the screen scroller, the high score page, the menu texts
;
; PlayTune plays (duration, pitch) pairs with the ROM's BEEP; the texts are in src/res/text.
; --------------------------------------------------------------------------------------------------------------------

; Play the tune at HL through the ROM's BEEP
;
; Each note: C the duration in tenths of a second (0 ends), B the pitch in
; semitones; STACK-A C, the calculator divides it by 10 (TuneCalc), STACK-A B,
; BEEP. Interrupts are off while BEEP runs. Witness: 393 notes (TitleTune in c1
; and after a game, DeathTune at a life lost).
PlayTune:
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD A,C
  AND A
  RET Z
  PUSH HL
  PUSH BC
  CALL STACK_A
  RST $28

; The calculator's program: stk-ten, division, end-calc
;
; Run by RST $28 at $AB6C (read by the ROM's calculator).
TuneCalc:
  DEFB $A4,$05,$38

; The pitch, BEEP, the next note
;
; Witness: 379 calls.
PlayTuneNote:
  POP BC
  LD A,B
  CALL STACK_A
  CALL BEEP
  POP HL
  JR PlayTune

; Shift a character row of 30 bytes from HL one pixel left
;
; Eight lines, each byte takes bit 7 of the next. Registers kept. Witness: 49
; 502 calls (the scrollers and the messages).
ScrollLine:
  PUSH DE
  PUSH BC
  PUSH AF
  LD D,$08
ScrollLineLine:
  PUSH HL
  POP BC
  INC BC
  LD E,$1E
ScrollLineByte:
  SLA (HL)
  LD A,(BC)
  BIT 7,A
  JR Z,ScrollLineNext
  SET 0,(HL)
ScrollLineNext:
  INC HL
  INC BC
  DEC E
  JR NZ,ScrollLineByte
  LD BC,$00E2
  ADD HL,BC
  DEC D
  JR NZ,ScrollLineLine
  POP AF
  POP BC
  POP DE
  RET

; Clear the 6912 bytes of the screen
;
; Witness: 20 calls.
ClearScreen:
  LD HL,Attributes+767
  LD BC,$1B00
ClearScreenByte:
  LD (HL),$00
  DEC BC
  DEC HL
  LD A,C
  OR B
  JR NZ,ClearScreenByte
  RET

; Print the high score table on the right half
;
; MenuTexts' title at row 23 column 16, the ten entries at rows 21, 19 .. 3,
; attribute $17 on columns 16-31 of rows 0-20. Witness: 4 calls.
DrawHiScores:
  LD DE,MenuTexts
  LD H,$17
  LD L,$10
  LD B,$10
DrawHiScoresTitle:
  LD A,(DE)
  CALL PrintChar
  INC L
  INC DE
  DJNZ DrawHiScoresTitle
  LD H,$15
  LD DE,HiScoreTable
DrawHiScoresRow:
  LD L,$10
  LD B,$10
DrawHiScoresChar:
  LD A,(DE)
  CALL PrintChar
  INC L
  INC DE
  DJNZ DrawHiScoresChar
  DEC H
  DEC H
  LD A,H
  CP $02
  JR NC,DrawHiScoresRow
  LD HL,Attributes+16
  LD DE,$0010
  LD C,$15
DrawHiScoresAttrRow:
  LD B,$10
DrawHiScoresAttr:
  LD (HL),$17
  INC HL
  DJNZ DrawHiScoresAttr
  ADD HL,DE
  DEC C
  JR NZ,DrawHiScoresAttrRow
  RET

; The phrases DeathPhrase picks from
;
; Read at DeathPhrases + (R AND 7). The editable form is
; src/res/tables/DeathPhrases.csv.
DeathPhrases:
  INCBIN "res/tables/DeathPhrases.bin",$0000,8

; The menu's texts: the high score title, the redefine page, the scrollers, the
; messages
;
; The editable form is src/res/text/MenuTexts.txt. The code writes
; PlayerMessage + 7 (the player's digit, PlayerTurn) and LevelDigits
; (PlayLevel).
MenuTexts:
  INCBIN "res/text/MenuTexts.bin",$0000,16
RedefinePrompt:
  INCBIN "res/text/MenuTexts.bin",$0010,32
KeyLabels:
  INCBIN "res/text/MenuTexts.bin",$0030,50
KeyNames:
  INCBIN "res/text/MenuTexts.bin",$0062,40
TitleScroller:
  INCBIN "res/text/MenuTexts.bin",$008A,78
InstructionsScroller:
  INCBIN "res/text/MenuTexts.bin",$00D8,87
PlayersPrompt:
  INCBIN "res/text/MenuTexts.bin",$012F,30
GameOverMessage:
  INCBIN "res/text/MenuTexts.bin",$014D,10
PlayerMessage:
  INCBIN "res/text/MenuTexts.bin",$0157,9
LevelMessage:
  INCBIN "res/text/MenuTexts.bin",$0160,6
LevelDigits:
  INCBIN "res/text/MenuTexts.bin",$0166,2
OutOfTimeMessage:
  INCBIN "res/text/MenuTexts.bin",$0168,13

; The name entry page: 11 rows of 15
;
; EnterHiScore prints row k at row 23 - 2k; GameOver writes the player's digit
; at $AD72. The editable form is src/res/text/Congratulations.txt.
Congratulations:
  INCBIN "res/text/Congratulations.bin",$0000,165

; The title tune: 46 (duration, pitch) notes, 0 0
;
; The editable form is src/res/sound/TitleTune.txt.
TitleTune:
  INCBIN "res/sound/TitleTune.bin",$0000,94

; The tune of a life lost: 24 notes, 0 0
;
; The editable form is src/res/sound/DeathTune.txt.
DeathTune:
  INCBIN "res/sound/DeathTune.bin",$0000,50
