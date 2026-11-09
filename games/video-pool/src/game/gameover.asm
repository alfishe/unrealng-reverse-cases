; --------------------------------------------------------------------------------------------------------------------
; gameover.asm: A life lost, the foul jingle, GAME OVER, the hi score and the hall of fame hand-over
; --------------------------------------------------------------------------------------------------------------------

; A foul or no ball potted with the last shot: the foul jingle, one life less,
; erase one life ball; at none left GAME OVER
;
; Called by the end-of-shot task $8357 when the foul code $8E80 is set or the
; cue ball is off the table (game 4 at frames 6543-8811, w1 4, f1 4, p2 1, v1
; 3). With InfiniteLives $B8C4 <> 0 (the four-key cheat, flipped at $B3A1 in
; WaitNoKeyHeld) it goes straight to NextTurn $97CD: no jingle, no life lost.
; No recording of the case set it; the experiment f1c (f1 with CAPS SHIFT +
; SPACE + 1 + 0 held at frame 500, docs/10-gameplay-logic.md 10.10) flips it at
; frame 510 and keeps 3 lives through two fouls.
;
; Lives $9F4E - 1; negative: GameOver $97A2. Else the leftmost life ball is
; XORed off: a cue ball sprite at x = $E8 - 24 n (n = the lives before the
; loss: 3 -> x 160), y 20; then NextTurn.
LoseLife:
  LD A,(InfiniteLives)
  OR A
  JP NZ,NextTurn
  CALL FoulJingle
  LD A,(LivesLeft)
  DEC A
  LD (LivesLeft),A
  JP M,GameOver
  INC A
  ADD A,A
  ADD A,A
  ADD A,A
  LD B,A
  ADD A,A
  ADD A,B
  LD B,A
  LD A,$E8
  SUB B
  LD H,$14
  LD L,A
  LD (SpritePos),HL
  XOR A
  CALL DrawBall
  JP NextTurn

; Play the foul jingle with the tasks stopped (WaitFrame $80DE with
; FoulJingleNotes)
;
; LoseLife $9754 only (game 4, w1 4, f1 4, p2 1 at frame 1668, v1 3).
FoulJingle:
  LD HL,FoulJingleNotes
  JP WaitFrameNoTasks

; Wait 10 frames, BEEPER HL $209E DE 26, wait 5 frames, BEEPER HL $29FE DE 23
;
; Two low notes: the ROM's BEEPER pitch 437500 / (HL + 30.125): about 52 Hz for
; DE 26, 27 cycles (0.51 s), then about 41 Hz for DE 23, 24 cycles (0.58 s).
; Run by FoulJingle through $80DE (game 4).
FoulJingleNotes:
  LD B,$0A
JingleWaitOne:
  HALT
  DJNZ JingleWaitOne
  LD HL,$209E
  LD DE,$001A
  CALL BEEPER
  LD B,$05
JingleWaitTwo:
  HALT
  DJNZ JingleWaitTwo
  LD HL,$29FE
  LD DE,$0017
  JP BEEPER

; No life left: erase the balls under the banner, print GAME OVER (and PLAYER
; n), then the other player's turn or the end
;
; From LoseLife $9754 (game 1 at frame 8811, w1 11768, f1 4445).
; EraseBallsUnderBanner $98B5, GameOverText at row 9. One player: GameOverEnd
; $9825. Two players: "PLAYER 1" / "PLAYER 2" at row 11 by CurrentPlayer; the
; other player's lives ($9F4F) negative too: GameOverEnd; else wait 125 frames
; (WaitFramesB $988C through $9886) and NextTurn $97CD (known only from the
; code: p2 never ran out of lives).
GameOver:
  CALL EraseBallsUnderBanner
  LD HL,GameOverTexts
  CALL PrintText
  LD A,(Players)
  DEC A
  JR Z,GameOverEnd
  LD A,(CurrentPlayer)
  LD HL,GameOverPlayer1
  DEC A
  JR Z,GameOverPlayer
  LD HL,GameOverPlayer2
GameOverPlayer:
  CALL PrintText
  LD HL,(LivesLeft)
  LD A,H
  OR A
  JP M,GameOverEnd
  LD B,$7D
  CALL WaitFramesBStopped

; After a life lost: the turn swap; with two players, rack or go on for the new
; player
;
; From LoseLife and GameOver (game 3, w1 3, f1 3, p2 1 at frame 1738, v1 3).
; TurnSwapStart $9C0F; one player: RET (back to $8357, which racks or aims).
; Two players: drops the return; when the player now at the table (the other
; one after a swap, the same one when TurnSwap found the other out of lives,
; $9C2B) has no object ball on the table (his set never racked): DrawAllBalls
; $9520 (XOR: erases the parked row), DrawLives $9AD9, NextFrame $9BB8 if
; Player2Racked $9B33 is set, Player2Racked = 1, Rack $9F69, StartAim $8425 (p2
; frame 1780).
;
; Else (NextTurnResume $9801, known only from the code): wait 100 frames, blank
; row 9 (FrameBannerBlank), DrawAllBalls, DrawLives, RespotCueBall if the cue
; ball is off, StartAim.
NextTurn:
  CALL TurnSwapStart
  LD A,(Players)
  DEC A
  RET Z
  POP HL
  LD IX,BallRecords
  LD DE,$000E
  LD B,$06
NextTurnCheckBalls:
  ADD IX,DE
  BIT 7,(IX+$0D)
  JR NZ,NextTurnResume
  DJNZ NextTurnCheckBalls
  CALL DrawAllBalls
  CALL DrawLives
  LD A,(Player2Racked)
  OR A
  LD A,$01
  LD (Player2Racked),A
  CALL NZ,NextFrame
  CALL Rack
  JP StartAim
NextTurnResume:
  LD B,$64                ; not executed in any build
  CALL WaitFramesBStopped
  LD A,$09
  LD (FrameBannerBlank),A
  LD HL,FrameBannerBlank
  CALL PrintText
  CALL DrawAllBalls
  CALL DrawLives
  LD IX,BallRecords
  BIT 7,(IX+$0D)
  CALL Z,RespotCueBall
  JP StartAim
; This entry point is used by the routine at GameOver.
GameOverEnd:
  LD HL,(ScorePlayer1)    ; the hi score = the larger of it and both scores,
                          ; printed; then the hall of fame
  LD DE,(HiScore)
  SCF
  SBC HL,DE
  JR C,GameOverScore2
  SCF
  ADC HL,DE
  LD (HiScore),HL
GameOverScore2:
  LD HL,(ScorePlayer2)
  LD DE,(HiScore)
  SCF
  SBC HL,DE
  JR C,GameOverScore
  SCF
  ADC HL,DE
  LD (HiScore),HL
GameOverScore:
  LD A,$02                ; PrintHudNumber 2, then GameOverWait through $80DE
  CALL PrintHudNumber
  LD HL,GameOverWait
  CALL WaitFrameNoTasks
GameOverRestart:
  JP BreakRestart         ; back to the menu ($80B0)

; Wait 250 frames or a key, the hall of fame $A702, wait 500 frames or a key
;
; Run through WaitFrame $80DE by GameOverEnd (game 1 at frame 8811-9061, w1
; 11768-14232, f1 4445-5195). The second wait is the tail call into
; WaitFramesOrKey from $9860.
GameOverWait:
  LD BC,$00FA
  CALL WaitFramesOrKey
  CALL GameOverHallOfFame
GameOverWaitAfter:
  LD BC,$01F4             ; BC = 500 frames
  JR WaitFramesOrKey

; Wait up to BC frames; stop early on fire ($827C bit 4 after $8106) or any key
; (KEY_SCAN, K_TEST)
;
; game 279 frames over 2 calls (8811-9090), w1 750, f1 750.
WaitFramesOrKey:
  HALT
  PUSH BC
  CALL ReadInput
  LD A,(InputState)
  AND $10
  JR NZ,WaitFramesOrKeyDone
  CALL KEY_SCAN
  JR NZ,WaitFramesOrKeyDone
  CALL K_TEST
  CP $FF
  JR NZ,WaitFramesOrKeyDone
  POP BC
  DEC BC
  LD A,B
  OR C
  JR NZ,WaitFramesOrKey
  RET
WaitFramesOrKeyDone:
  POP BC
  RET

; Wait B frames with the tasks stopped: WaitFrame $80DE with WaitFramesB
;
; From GameOver $97CA (B 125) and NextTurnResume $9801 (B 100): not executed in
; any build.
WaitFramesBStopped:
  LD HL,WaitFramesB
  JP WaitFrameNoTasks

; HALT B times
;
; Code inside the text block (bytes $76 $10 $FD $C9). Not executed in any build
; (no two-player game over with the other player alive, no turn change to a
; racked set).
WaitFramesB:
  HALT
  DJNZ WaitFramesB
  RET

; GAME OVER and the losing player (PrintText records, double width, attr $60)
;
; GameOverText read by game, w1, f1; the two player lines are not read in any
; build (the recordings' games over were one-player or ended by BREAK).
GameOverTexts:
  INCBIN "res/text/GameOverTexts.bin",$0000,13
GameOverPlayer1:
  INCBIN "res/text/GameOverTexts.bin",$000D,12
GameOverPlayer2:
  INCBIN "res/text/GameOverTexts.bin",$0019,12

; Erase the balls on the table that the GAME OVER banner covers and take them
; off the table
;
; GameOver $97A2 (game, w1, f1 once each). A ball with bit 7 of +13 set and its
; sprite at x 41-199, y 57 up to 88 (one player) or 104 (two) is XORed off and
; its bit 7 cleared. The erase branch ran in no build (no ball sat there at the
; game overs).
EraseBallsUnderBanner:
  LD IX,BallRecords
  XOR A
EraseBannerLoop:
  PUSH AF
  BIT 7,(IX+$0D)
  JR Z,EraseBannerNext
  LD L,(IX+$0A)
  LD A,L
  CP $29
  JR C,EraseBannerNext
  CP $C8
  JR NC,EraseBannerNext
  LD H,(IX+$0B)
  LD A,H
  CP $39
  JR C,EraseBannerNext
  LD A,(Players)
  ADD A,A
  ADD A,$09
  ADD A,A
  ADD A,A
  ADD A,A
  CP H
  JR C,EraseBannerNext
  POP AF
  PUSH AF
  LD (SpritePos),HL
  CALL DrawBall
  RES 7,(IX+$0D)
EraseBannerNext:
  POP AF
  LD DE,$000E
  ADD IX,DE
  INC A
  CP $07
  JR NZ,EraseBannerLoop
  RET
