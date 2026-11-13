; --------------------------------------------------------------------------------------------------------------------
; setup.asm: Start-up and the start of a game and of each life: players, records, the cheat, the "ready?" screen
;
; GameStart ($AB7C, the BASIC's RANDOMIZE USR 43900) disables interrupts and enters the menu loop at GameRestart: the
; menu (Menu $EF33) returns the choice in $B3B1 (0 one player, 1 the demo, 2 two players). A game clears the screen,
; draws the side panels, zeroes both player records ($AB09, $AB10: score word, water, keys, hammers, level, lives),
; offers the cheat (R, SPACE and V held at once) and starts the first life at LifeStart.
;
; LifeStart runs at the start of every level and after every life lost: it resets the ball, sets the timer to 1000,
; copies the current player's record to the working copy at $AAFB, builds the level (CF2E), prints "ready?" and waits
; for a key, whose direction sets the first move. The main loop follows.
; --------------------------------------------------------------------------------------------------------------------

; The code block's entry (USR 43900): DI, then GameRestart
;
; The BASIC's RANDOMIZE USR 43900 lands here; it disables the interrupts for
; good (the game waits for frames with EI: HALT, WaitFrame $B6E4) and falls
; into GameRestart. Nothing jumps back here.
;
; Witness: L1 1 (c1).
GameStart:
  DI

; The menu, then a new game or the demo by the menu's choice $B3B1
;
; Calls Menu $EF33, then clears the demo flag $ABA6 and the cheat-mode flag
; $ADDD. By $B3B1: 0 starts a one-player game ($ADDC = 1), 2 a two-player game
; ($ADDC = 2), 1 the demo ($ABA6 = 1, the demo input pointer $ABA4 = $D25A, one
; byte before the demo's moves at $D25B; the demo plays one player). Quitting a
; game (R in MainLoop, QuitToMenu $B7B2) and the end of the demo come back
; here.
;
; Witness: L1 7 (c1, gameover, menu, twoname).
GameRestart:
  CALL Menu

; Back from the menu: start what $B3B1 chose
;
; GameRestart's tail, where Menu returns. It is an entry of its own because the
; recordings that start inside the menu
; (work/stage1/probe/load-fast-nokemp/end.szx: menu, gameover, twoname) reach
; it by Menu's RET with no CALL seen. Clears DemoFlag $ABA6 and CheatMode $ADDD
; and branches on MenuChoice $B3B1 as GameRestart says.
;
; Witness: runs after every Menu call (GameRestart L1 7: c1, gameover, menu,
; twoname).
GameRestartChoice:
  LD A,$00
  LD (DemoFlag),A
  LD (CheatMode),A
  LD A,(MenuChoice)
  CP $00
  JP Z,NewGameOnePlayer
  CP $02
  JP Z,NewGameTwoPlayers
  LD A,$01
  LD (DemoFlag),A
  LD HL,DemoMoves
  LD (DemoInputPtr),HL
  JP NewGameOnePlayer

; One byte ($01) between the JP and the demo variables; nothing reads it
; (leftover)
UnusedByteABA3:
  DEFB $01

; The demo's input pointer: the last move state read from $D25B+ (BallStopped
; $B11A)
DemoInputPtr:
  DEFW $0000

; 1 while the demo plays, 0 in a game: no keys are read, the "ready?" text is
; skipped
DemoFlag:
  DEFB $00

; A flag the object handlers ($B9A7-$B9FD) read; no recording writes it (always
; 0 in the image)
ObjectFlag:
  DEFB $00

; One player ($ADDC = 1); NewGame follows
;
; Witness: L1 7 (c1, gameover, menu).
;
; NewGame: ClearAttrs $B471 (ink 7, black border), DrawSides $B488, InitPlayers
; $BB96 (both records zeroed, 2 lives each by $BBA8). Then the cheat: TestKey
; $B6CB for R ($2B), SPACE ($00) and V ($3C); all three held calls $BB56 (99
; water, keys, hammers and lives for player 1). The current player $ADDB = 1.
; Witness of the cheat test: $ABCB (V tested once R and SPACE are held) ran
; once, in the menu build.
NewGameOnePlayer:
  LD A,$01
  LD (PlayerCount),A
  JR NewGame
; This entry point is used by the routine at GameRestartChoice.
NewGameTwoPlayers:
  LD A,$02                ; two players ($ADDC = 2)
  LD (PlayerCount),A
NewGame:
  CALL ClearAttrs         ; white ink on black, the side panels, zeroed
                          ; records, the cheat test
  CALL DrawSides
  CALL InitPlayers
  LD A,$2B
  CALL TestKey
  JR Z,FirstPlayer
  LD A,$00
  CALL TestKey
  JR Z,FirstPlayer
  LD A,$3C
  CALL TestKey
  CALL NZ,CheatStock
FirstPlayer:
  LD A,$01                ; the current player $ADDB = 1
  LD (CurrentPlayer),A

; The start of a level or of a new life: resets the ball, the timer and the
; player's working copy, builds the level, "ready?"
;
; Entered from NewGame, from the level end (LevelEnd $B2C2 through $B3AE) and
; after a life lost (LoseLife $BA93). If the cheat mode $ADDD is on (never: its
; switch is gone, see CheatModeOn $ADE0) $BB7D refills the stores.
; ClearPlayArea $B4CE, then zeroes the ball state $AA00, BallStep $A9FF,
; SpringArmed $AA13, the animation flags $AA12, $AB33, $AB2B, $AA15, $AA14,
; $AA1D, the platform under the ball $AB1C and $A9FD; the timer $AB04 = 1000
; ($03E8: the frames the level allows).
;
; The players: the current player $ADDB is kept in $ADDE. With two players
; ($ADDC = 2) the code copies player 2's record ($AB10) to the working copy
; $AAFB and sets $ADDB = 2, then player 1's ($AB09) and $ADDB = 1, each time
; testing lives = $FA (the mark of a player out) with a JR Z to the very next
; line: the test does nothing (known only from the code). Then $ADDB = $ADDE
; again and the record of the current player is copied to $AAFB (7 bytes: score
; word, water, keys, hammers, level, lives), with the text to show: ReadyText
; $AD3B (one player), Player1ReadyText $AD48 or Player2ReadyText $AD84.
;
; In a game: ClearPlayArea, BuildLevel $CF2E, PrintText $E667 of that text; in
; the demo BuildLevel only. Then water, keys and hammers are kept in
; $AB06-$AB08 (the stores at the level's start), $BB32 reads the platform under
; the ball, and D ($32) calls CheatModeSwitch $ADDF (a RET). A game then draws
; the HUD ($E58B), waits for all keys up (WaitRelease $B401) and for a key
; (WaitPressHeld $B6DD), and the key sets the first move (DecideMove $B7E4).
; Last, in both: ClearPlayArea and BuildLevel again (the text goes), the HUD
; and WaitFrame $B6E4; MainLoop follows.
;
; Witness: L1 57 (c1, fire, gameover, menu, twoname, l51, l59, l96, l98, rzx
; x24).
LifeStart:
  LD A,(CheatMode)
  CP $00
  CALL NZ,PracticeStock
  CALL ClearPlayArea
  LD A,$00
  LD (BallState),A
  LD (ExitOpen),A
  LD (BrickActive),A
  LD (FireOutActive),A
  LD (CrumbleActive),A
  LD (CrumblePending),A
  LD (LockActive),A
  LD (BallStep),A
  LD (SpringArmed),A
  LD (CellPlatform),A
  LD (TakeoffDrawn),A
  LD HL,$03E8
  LD (Timer),HL
  LD A,(CurrentPlayer)
  LD (SavedPlayer),A
  LD A,(PlayerCount)
  CP $01
  JR Z,LifeStartPlayer1
  LD HL,Player2Record     ; two players: player 2's record to the working copy,
                          ; $ADDB = 2
  LD DE,Score
  LD BC,$0007
  LDIR
  LD A,$02
  LD (CurrentPlayer),A
  LD A,(Lives)
  CP $FA
  JR Z,LifeStartPlayer1
LifeStartPlayer1:
  LD HL,Player1Record     ; player 1's record to the working copy, $ADDB = 1
  LD DE,Score
  LD BC,$0007
  LDIR
  LD A,$01
  LD (CurrentPlayer),A
  LD A,(Lives)
  CP $FA
  JR Z,LifeStartCurrent
LifeStartCurrent:
  LD A,(SavedPlayer)      ; the current player back from $ADDE; pick the record
                          ; and the text
  LD (CurrentPlayer),A
  LD HL,Player1Record
  LD DE,ReadyText
  CP $01
  JR NZ,LifeStartPlayer2
  LD A,(PlayerCount)
  CP $01
  JR Z,LifeStartCopy
  LD DE,Player1ReadyText
  JR LifeStartCopy
LifeStartPlayer2:
  LD HL,Player2Record     ; player 2: record $AB10, text Player2ReadyText (no
                          ; recording ran it)
  LD DE,Player2ReadyText
LifeStartCopy:
  PUSH DE                 ; the record to the working copy $AAFB
  LD DE,Score
  LD BC,$0007
  LDIR
  POP HL
  LD A,(DemoFlag)
  AND A
  JR NZ,LifeStartDemo
  PUSH HL
  CALL ClearPlayArea
  CALL BuildLevel
  POP HL
  CALL PrintText
  JR LifeStartStores
LifeStartDemo:
  CALL BuildLevel         ; the demo: BuildLevel without the text
LifeStartStores:
  AND A                   ; keep water, keys and hammers in $AB06-$AB08
  LD A,(Water)
  LD (WaterAtStart),A
  LD A,(Keys)
  LD (KeysAtStart),A
  LD A,(Hammers)
  LD (HammersAtStart),A
  CALL ReadCell
  LD A,$32
  CALL TestKey
  CALL NZ,CheatModeSwitch
  LD A,(DemoFlag)
  CP $00
  JR Z,LifeStartReady
  JR LifeStartGo
LifeStartReady:
  CALL DrawHud            ; the HUD, wait for no key, then for a key;
                          ; DecideMove
  CALL WaitRelease
  CALL WaitPressHeld
  CALL ChooseNextState
LifeStartGo:
  CALL ClearPlayArea      ; the play area again without the text, the HUD, one
                          ; frame
  CALL BuildLevel
  CALL DrawHud
  CALL WaitFrame

  ORG $BB96

; Clear both player records: 2 lives each; the demo gets level 10 and 2 of each
; tool
;
; Zeroes the 14 bytes $AB09-$AB16, lives 2 for both players. In the demo ($ABA6
; not 0) player 1 gets water, keys and hammers 2 and level 10. Called by
; GameStart ($ABBA).
;
; Witness: L1 9 (c1, gameover, menu, twoname).
InitPlayers:
  LD IX,Player1Record
  LD B,$0E
InitPlayersClear:
  LD (IX+$00),$00
  INC IX
  DJNZ InitPlayersClear
  LD IX,Player1Record
  LD (IX+$06),$02
  LD (IX+$0D),$02
  LD A,(DemoFlag)
  CP $00
  JR NZ,InitPlayersDemo
  RET
InitPlayersDemo:
  LD IX,Player1Record
  LD (IX+$02),$02
  LD (IX+$03),$02
  LD (IX+$04),$02
  LD (IX+$05),$0A
  RET
