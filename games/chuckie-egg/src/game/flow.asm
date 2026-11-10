; --------------------------------------------------------------------------------------------------------------------
; flow.asm: The menu, the turns, the level end, a life lost, the game over
;
; Start is the entry from the loader. The title loop runs the scroller and waits for S, R or I; StartGame takes the
; players; PlayLevel calls SetupLevel, which runs MainLoop, and acts on its return: the level complete, or a life
; lost.
; --------------------------------------------------------------------------------------------------------------------

; The entry: key type 1, IM 2, the title page
;
; Entered by the loader's JP $A410 (c1 frame 5292) and by the abort key.
; KeyType 6, TitleTuneDone 0, I = $B2 (VectorTable), IM 2. Witness: c1 1.
Start:
  LD HL,KeyType
  LD (HL),$06
  LD HL,TitleTuneDone
  LD (HL),$00
  LD A,$B2
  LD I,A
  IM 2

; Draw the title page and the high scores
;
; ClearScreen, TitleText at rows 2-23 columns 0-13, DrawHiScores, the colours
; of the left half (magenta, yellow, green bands), the title tune and phrase 20
; the first time only (TitleTuneDone), row 23 cyan, TextIndex at the end of the
; text. Then TitleLoop. Witness: 4 calls.
TitlePage:
  CALL ClearScreen
  LD H,$02
  LD BC,TitleText
TitlePageRow:
  LD L,$00
TitlePageChar:
  LD A,(BC)
  CALL PrintChar
  INC BC
  INC L
  LD A,L
  CP $0E
  JR NZ,TitlePageChar
  INC H
  LD A,H
  CP $18
  JR NZ,TitlePageRow
  CALL DrawHiScores
  LD HL,Attributes
  LD B,$0E
  LD C,$04
  LD A,$03
  CALL FillAttrBlock
  LD C,$07
  LD A,$06
  CALL FillAttrBlock
  LD C,$0A
  LD A,$04
  CALL FillAttrBlock
  LD HL,TitleTune
  LD A,(TitleTuneDone)
  AND A
  JR NZ,TitleScrollerStart
  CALL PlayTune
  LD A,$14
  CALL StartPhrase
  LD A,$01
  LD (TitleTuneDone),A
; This entry point is used by the routine at RedefineKeys.
TitleScrollerStart:
  LD HL,Attributes+736
  LD B,$20
TitleScrollerColour:
  LD (HL),$05
  INC HL
  DJNZ TitleScrollerColour
  LD HL,TextIndex
  LD (HL),$4E

; Scroll the title text; S starts, R redefines, I shows the instructions
;
; ScrollLine at the bottom row, Delay 500; every 8 shifts the next of
; TitleScroller's 78 characters enters at column 30. Keys: S StartGame, R
; RedefineKeys, I InstructionsPage. Witness: every build starts here.
TitleLoop:
  LD HL,Screen+4321
  CALL ScrollLine
  LD BC,$01F4
  CALL Delay
  LD HL,ScrollDelay
  DEC (HL)
  JR NZ,TitleLoopKeys
  LD (HL),$08
  LD HL,TitleScroller
  LD A,(TextIndex)
  INC A
  CP $4E
  JR C,TitleLoopChar
  XOR A
TitleLoopChar:
  LD (TextIndex),A
  LD E,A
  LD D,$00
  ADD HL,DE
  LD A,(HL)
  LD HL,$001E
  CALL PrintChar
TitleLoopKeys:
  LD A,$FD
  IN A,($FE)
  BIT 1,A
  JP Z,StartGame
  LD A,$FB
  IN A,($FE)
  BIT 3,A
  JP Z,RedefineKeys
  LD A,$DF
  IN A,($FE)
  BIT 2,A
  JR Z,InstructionsPage
  JP TitleLoop

; Draw the instructions page, scroll its text, take the key type
;
; ClearScreen; InstructionsText's 11 rows at rows 3, 5 .. 23; the colour bands;
; TextIndex at the end, KeyType 10 (no type shown, so the first key 1-3 marks
; one); WaitPhrase and phrase 24. The loop scrolls InstructionsScroller (87
; characters); S (once the phrase ends) StartGame, R RedefineKeys; keys 1, 2, 3
; set KeyType and move the flashing bar to the type's row ($5940, $5980,
; $59C0). A KeyType of 10 left as it is plays as type 1 (SetupLevel takes $8250
; for anything but 5 and 3).
;
; Witness: c1, idle-1p, tour-type2 (key 2, $A56D), tour-redefine.
InstructionsPage:
  CALL ClearScreen
  LD H,$03
  LD BC,InstructionsText
InstructionsRow:
  LD L,$00
InstructionsChar:
  LD A,(BC)
  CALL PrintChar
  INC BC
  INC L
  LD A,L
  CP $20
  JR NZ,InstructionsChar
  INC H
  INC H
  LD A,H
  CP $19
  JR NZ,InstructionsRow
  LD HL,Attributes
  LD B,$20
  LD C,$06
  LD A,$05
  CALL FillAttrBlock
  LD C,$09
  LD A,$17
  CALL FillAttrBlock
  LD C,$06
  LD A,$05
  CALL FillAttrBlock
  LD C,$03
  LD A,$04
  CALL FillAttrBlock
  LD HL,TextIndex
  LD (HL),$57
  INC HL
  LD (HL),$0A
  CALL WaitPhrase
  LD A,$18
  CALL StartPhrase
InstructionsLoop:
  LD HL,Screen+4321
  CALL ScrollLine
  LD BC,$01F4
  CALL Delay
  LD HL,ScrollDelay
  DEC (HL)
  JR NZ,InstructionsKeys
  LD (HL),$08
  LD HL,InstructionsScroller
  LD A,(TextIndex)
  INC A
  CP $57
  JR C,InstructionsNextChar
  XOR A
InstructionsNextChar:
  LD (TextIndex),A
  LD E,A
  LD D,$00
  ADD HL,DE
  LD A,(HL)
  LD HL,$001E
  CALL PrintChar
InstructionsKeys:
  LD A,(PhraseTimer)
  XOR $FF
  JR NZ,InstructionsRedefine
  LD A,$FD
  IN A,($FE)
  BIT 1,A
  JP Z,StartGame
InstructionsRedefine:
  LD A,$FB
  IN A,($FE)
  BIT 3,A
  JP Z,RedefineKeys
  LD A,$F7
  IN A,($FE)
  AND $07
  CP $07
  JR Z,InstructionsLoopNext
  LD B,A
  LD A,(KeyType)
  CP B
  JR Z,InstructionsLoopNext
  LD HL,Attributes+384
  CP $05
  JR Z,InstructionsBar
  LD HL,Attributes+448
  JR C,InstructionsBar
  LD HL,Attributes+320
InstructionsBar:
  LD A,B
  LD (KeyType),A
  CP $05
  LD DE,Attributes+384
  JR Z,InstructionsBarPaint
  LD DE,Attributes+448
  JR C,InstructionsBarPaint
  LD DE,Attributes+320
InstructionsBarPaint:
  LD B,$20
  LD A,$97
InstructionsBarCell:
  LD (HL),$17
  LD (DE),A
  INC HL
  INC DE
  DJNZ InstructionsBarCell
InstructionsLoopNext:
  JP InstructionsLoop

; Take the number of players and set up the game
;
; BoxWipe in colours, the screen cleared, BoxWipe in black; the players prompt
; scrolls in and keys 1-4 set Players (Player 1). Five copies of level 1's map
; into LiveMap; the scores 0, levels 0, eggs 12, lives 5; LevelDigits "01"
; ($9F9E: the HUD codes of 0 and 1); WaitPhrase. Then PlayerTurn. Witness: 7
; games in the eight builds.
StartGame:
  LD IXH,$02
  CALL BoxWipe
  LD HL,Screen
  LD BC,$1800
StartGameClear:
  LD (HL),$00
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,StartGameClear
  LD IXH,$01
  CALL BoxWipe
  LD C,$E8
  LD DE,PlayersPrompt
  LD B,$01
StartGamePrompt:
  DJNZ StartGameScroll
  LD A,(DE)
  INC DE
  LD HL,$0C1E
  CALL PrintChar
  LD B,$08
StartGameScroll:
  LD HL,Screen+2145
  CALL ScrollLine
  DEC C
  JR NZ,StartGamePrompt
StartGameKey:
  LD A,$F7
  IN A,($FE)
  AND $0F
  CP $0F
  JR Z,StartGameKey
  LD B,$00
StartGameCount:
  INC B
  SRL A
  JR C,StartGameCount
  LD L,B
  LD H,$01
  LD (Players),HL
  LD B,$F0
StartGameScrollOut:
  LD HL,Screen+2145
  CALL ScrollLine
  DJNZ StartGameScrollOut
  LD A,$05
  LD DE,LiveMap
StartGameMaps:
  LD BC,$02A0
  LD HL,LevelMaps
  LDIR
  DEC A
  JR NZ,StartGameMaps
  LD HL,Score
  LD B,$1E
StartGameZero:
  LD (HL),$00
  INC HL
  DJNZ StartGameZero
  LD B,$05
StartGameEggs:
  LD (HL),$0C
  INC HL
  DJNZ StartGameEggs
  LD B,$05
StartGameLevels:
  LD (HL),$00
  INC HL
  DJNZ StartGameLevels
  LD B,$04
StartGameLives:
  LD (HL),$05
  INC HL
  DJNZ StartGameLives
  LD HL,$9F9E
  LD (LevelDigits),HL
  CALL WaitPhrase

; Announce the player (two players or more) and play
;
; With more than one player: phrase 25 + player, "PLAYER n" scrolled in
; (Message), Delay 65536. Then PlayLevel. The LD BC,$AD49 at $A63A is
; overwritten at once (C = 8): a leftover. Witness: 14 calls.
PlayerTurn:
  LD A,(Players)
  DEC A
  JR Z,PlayLevel
  LD A,(Player)
  ADD A,$19
  CALL StartPhrase
  LD BC,PlayerMessage
  LD A,(Player)
  ADD A,$30
  LD (PlayerMessage+$0007),A
  LD C,$08
  LD DE,PlayerMessage
  CALL Message
  LD BC,$0000
  CALL Delay

; Play a level: SetupLevel and MainLoop; then the level end or the life lost
;
; CALL SetupLevel (which jumps to MainLoop); MainLoop returns here at $A656.
; WaitPhrase, the score into the player's slot, IM 2 (again after a name
; entry). Eggs left: LifeLost. Else the bonus is counted into the score
; (CountDown, then AddScore 10, a beep, on every step: the step that takes the
; bonus past 000 still adds 10, so a bonus of N is paid as N + 10), a pause,
; BoxZoom; the level + 1, "LEVEL nn" (the number is level + 1 mod 100), the
; next map (LevelMaps + 672 x (Level AND 7)) into the map in play, 12 eggs, and
; the next level.
;
; Witness: 5 375 bonus steps ($A675); 16 levels completed.
PlayLevel:
  CALL SetupLevel
  CALL WaitPhrase
  LD BC,$0006
  LD HL,Score
  LD A,(Player)
PlayLevelSave:
  ADD HL,BC
  DEC A
  JR NZ,PlayLevelSave
  EX DE,HL
  LD HL,Score
  LDIR
  IM 2
  LD A,(EggsLeft)
  AND A
  JP NZ,LifeLost
PlayLevelBonus:
  LD A,(BonusRunning)
  AND A
  JR Z,PlayLevelPause
  LD B,$00
  CALL CountDown
  LD B,$01
  CALL AddScore
  LD HL,$1E04
  CALL Beep
  JR PlayLevelBonus
PlayLevelPause:
  LD D,$02
PlayLevelPauseLoop:
  LD BC,$0000
  CALL Delay
  DEC D
  JR NZ,PlayLevelPauseLoop
  CALL BoxZoom
  LD BC,$0006
  LD HL,Score
  LD A,(Player)
PlayLevelSave2:
  ADD HL,BC
  DEC A
  JR NZ,PlayLevelSave2
  EX DE,HL
  LD HL,Score
  LDIR
  LD HL,Level
  INC (HL)
  LD A,(HL)
  INC A
  CP $C8
  JR C,PlayLevelNumber
  SUB $C8
  JR PlayLevelTens
PlayLevelNumber:
  CP $64
  JR C,PlayLevelTens
  SUB $64
PlayLevelTens:
  LD B,$00
PlayLevelTensLoop:
  SUB $0A
  JR C,PlayLevelUnits
  INC B
  JR PlayLevelTensLoop
PlayLevelUnits:
  ADD A,$A8
  LD (LevelDigits+$0001),A
  LD A,B
  AND A
  JR Z,PlayLevelMessage
  ADD A,$9E
PlayLevelMessage:
  LD (LevelDigits),A
  LD DE,LevelMessage
  LD C,$08
  CALL Message
  LD DE,LiveMap
  LD BC,$02A0
  LD HL,LevelMaps-$02A0
  LD A,(Level)
  AND $07
  INC A
PlayLevelMap:
  ADD HL,BC
  DEC A
  JR NZ,PlayLevelMap
  LDIR
  LD A,$0C
  LD (EggsLeft),A
  JP PlayLevel

; A life lost: the tune, the next player with lives, or the game over
;
; DeathTune, DeathPhrase, WaitPhrase, a pause, ClearScreen; OUT OF TIME when
; the time digits are $FF 9 9; the map in play into the player's slot, the eggs
; and the level into his; lives - 1; at 0 "GAME OVER" (with "PLAYER n" when
; more play). Then the next player with lives (in turn) is loaded (level, eggs,
; score, map) and PlayerTurn; none left: GameOver.
;
; Witness: 14 lives lost ($A6FE), out of time 1 ($A725, tour-redefine), game
; over 2 ($A7BC: idle-1p, gameover-name).
LifeLost:
  LD HL,DeathTune
  CALL PlayTune
  CALL DeathPhrase
  CALL WaitPhrase
  LD BC,$0000
  CALL Delay
  CALL ClearScreen
  LD HL,TimeDigits
  LD A,(HL)
  CP $FF
  JR NZ,LifeLostSave
  INC HL
  LD A,$09
  CP (HL)
  JR NZ,LifeLostSave
  INC HL
  CP (HL)
  JR NZ,LifeLostSave
  LD DE,OutOfTimeMessage
  LD C,$0D
  CALL Message
LifeLostSave:
  LD HL,LiveMap
  LD BC,$02A0
  PUSH HL
  POP DE
  LD A,(Player)
LifeLostSlot:
  ADD HL,BC
  DEC A
  JR NZ,LifeLostSlot
  EX DE,HL
  LDIR
  LD A,(Player)
  LD E,A
  LD D,$00
  LD HL,EggsLeft
  LD A,(HL)
  ADD HL,DE
  LD (HL),A
  LD HL,Level
  LD A,(HL)
  ADD HL,DE
  LD (HL),A
  LD HL,PlayerLives-$0001
  ADD HL,DE
  DEC (HL)
  JR NZ,LifeLostNext
  LD C,$12
  LD A,(Players)
  DEC A
  JR NZ,LifeLostGameOver
  LD C,$09
LifeLostGameOver:
  LD DE,GameOverMessage
  CALL Message
LifeLostNext:
  LD B,$05
LifeLostNextLoop:
  LD HL,(Players)
  LD A,H
  CP L
  JR NZ,LifeLostNextPlayer
  XOR A
LifeLostNextPlayer:
  INC A
  LD (Player),A
  LD HL,PlayerLives-$0001
  LD E,A
  LD D,$00
  ADD HL,DE
  LD A,(HL)
  AND A
  JR NZ,LifeLostLoad
  DJNZ LifeLostNextLoop
  JR GameOver
LifeLostLoad:
  LD BC,$0004
  AND A
  SBC HL,BC
  LD A,(HL)
  LD (Level),A
  INC BC
  AND A
  SBC HL,BC
  LD A,(HL)
  LD (EggsLeft),A
  LD A,(Player)
  INC BC
  LD HL,Score
LifeLostLoadScore:
  ADD HL,BC
  DEC A
  JR NZ,LifeLostLoadScore
  LD DE,Score
  LDIR
  LD A,(Player)
  LD HL,LiveMap
  LD BC,$02A0
LifeLostLoadMap:
  ADD HL,BC
  DEC A
  JR NZ,LifeLostLoadMap
  LD DE,LiveMap
  LDIR
  JP PlayerTurn

; The end of the game: each player's score against the table
;
; BoxWipe, the pixels cleared, BoxWipe; the 24 score digits become ASCII; for
; each player his digit at $AD72 (Congratulations) and EnterHiScore; BoxZoom
; after an entry. Then TitlePage. Witness: 2 calls.
GameOver:
  LD IXH,$02
  CALL BoxWipe
  LD HL,Screen
  LD BC,$0018
GameOverClear:
  LD (HL),$00
  INC HL
  DJNZ GameOverClear
  DEC C
  JR NZ,GameOverClear
  LD IXH,$01
  CALL BoxWipe
  LD HL,PlayerScores
  LD B,$18
GameOverAscii:
  LD A,(HL)
  ADD A,$30
  LD (HL),A
  INC HL
  DJNZ GameOverAscii
  LD A,$01
  LD HL,PlayerScores
GameOverPlayer:
  ADD A,$30
  LD (Congratulations+$000B),A
  SUB $30
  CALL EnterHiScore
  DEC D
  JR Z,GameOverNext
  PUSH AF
  PUSH HL
  CALL BoxZoom
  POP HL
  POP AF
GameOverNext:
  LD DE,$0006
  ADD HL,DE
  LD IX,HarryX
  CP (IX+$62)
  JP Z,TitlePage
  INC A
  JR GameOverPlayer
