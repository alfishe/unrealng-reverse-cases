; --------------------------------------------------------------------------------------------------------------------
; tally.asm: The score of a shot: frame x ball x pocket multiplier x 10, printed term by term and counted up into the score
;
; Score of one potted ball = frame number x ball number x the pocket's multiplier (PocketMultiplierCells), shown as
; "FxBxMx10" and stored without the x 10; a shot's terms are added and counted into the player's score with a falling
; beep (v1: "1x5x3x10=150").
; --------------------------------------------------------------------------------------------------------------------

; Run ScoreTally with the tasks stopped (WaitFrame $80DE)
;
; From the end-of-shot task $8357 twice per shot end (game 4, w1 21, f1 9, p2
; 6, v1 4, m1 1).
ScoreShot:
  LD HL,ScoreTally
  JP WaitFrameNoTasks

; Score the balls potted in the last shot (+12 <> 0): print each term, the
; total, count it into the score, refill the shots
;
; ShotScore $9B2C = 0. Ball 1-6 with a pocket number in +12: the first sets
; PotBall $9B2F and PotMultiplier $9B2E (PocketTurn $9F43 + pocket, 7..12 minus
; 6), waits 15 frames and clears the message rows (unless MessageStep is $4F);
; every further one first prints the pending term with "+" (TallyTermPlus
; $9A01), waits, clears, takes its own ball and multiplier. The last term is
; printed with "=" and the total (TallyTermTotal $9A1A).
;
; The count: TallyPitch $9B34 = 1200, step DE = ShotScore / 64 + 1 (ShotScore x
; 4, high byte, plus 1 with the carry); up to 45 frames each moves one step
; from ShotScore into the player's score (AddScoreStep $99C1, printed with a
; beep), then the remainder in one go and the rest of the 45 frames waited.
; Then ClearMessageRows, DrawPottedRow $9AB5, ShotsLeft = ShotsForFrame $9BE6,
; wait 5 frames.
;
; Returns at once when nothing was potted. Witness: AddScoreStep w1 287 calls
; (frames 1329-10175), p2 38, v1 72; TallyTermPlus (a double pot) w1, f1, v1
; once each.
ScoreTally:
  LD HL,$0000
  LD (ShotScore),HL
  LD IX,BallRecords
  LD A,$01
TallyFindFirst:
  PUSH AF
  LD BC,$000E
  ADD IX,BC
  LD A,(IX+$0C)
  OR A
  JR NZ,TallyFirstBall
  POP AF
  INC A
  CP $07
  JR NZ,TallyFindFirst
  RET
TallyFirstBall:
  POP AF
  PUSH AF
  LD (PotBall),A
  LD A,(PlayerVars)
  ADD A,(IX+$0C)
  CP $07
  JR C,TallyFirstMultiplier
  SUB $06
TallyFirstMultiplier:
  LD (PotMultiplier),A
  CALL TallyPause
  LD A,(MessageStep)
  CP $4F
  CALL NZ,ClearMessageRows
  JR TallyNextBall
TallyFindNext:
  PUSH AF
  LD BC,$000E
  ADD IX,BC
  LD A,(IX+$0C)
  OR A
  JR NZ,TallyMoreBalls
TallyNextBall:
  POP AF
  INC A
  CP $07
  JR NZ,TallyFindNext
  CALL TallyTermTotal
  JR TallyCount
TallyMoreBalls:
  CALL TallyTermPlus
  CALL TallyPause
  CALL ClearMessageRows
  POP AF
  PUSH AF
  LD (PotBall),A
  LD A,(PlayerVars)
  ADD A,(IX+$0C)
  CP $07
  JR C,TallyMoreMultiplier
  SUB $06
TallyMoreMultiplier:
  LD (PotMultiplier),A
  JR TallyNextBall
TallyCount:
  LD HL,$04B0
  LD (TallyPitch),HL
  LD HL,(ShotScore)
  SLA L
  RL H
  LD A,H
  SLA L
  ADC A,$01
  LD D,$00
  LD E,A
  LD B,$2D
TallyCountStep:
  LD HL,(ShotScore)
  XOR A
  SBC HL,DE
  JR C,TallyCountLast
  LD (ShotScore),HL
  CALL AddScoreStep
  HALT
  DEC B
  JR TallyCountStep
TallyCountLast:
  LD DE,(ShotScore)
  CALL AddScoreStep
  LD A,B
  OR A
  JR Z,TallyDone
  JP M,TallyDone
TallyWaitRest:
  HALT
  DJNZ TallyWaitRest
TallyDone:
  CALL ClearMessageRows
  CALL DrawPottedRow
  CALL ShotsForFrame
  LD (ShotsLeft),A
  LD B,$05
TallyEndWait:
  HALT
  DJNZ TallyEndWait
  RET

; Add DE to the current player's score, print it, beep at TallyPitch and lower
; the pitch by 10
;
; CurrentPlayer 1: ScorePlayer1 $9F45, 2: ScorePlayer2 $9F47; PrintHudNumber 0
; / 1. The beep: BEEPER with HL = TallyPitch, DE = 6000 / TallyPitch cycles
; (1200: about 356 Hz, 5 cycles, 14 ms), a tick that rises in pitch step by
; step; TallyPitch - 10 unless it would go below zero. w1 287 runs.
AddScoreStep:
  LD A,(CurrentPlayer)
  DEC A
  JR NZ,AddScorePlayer2
  LD HL,(ScorePlayer1)
  ADD HL,DE
  LD (ScorePlayer1),HL
  JR AddScorePrint
AddScorePlayer2:
  LD HL,(ScorePlayer2)
  ADD HL,DE
  LD (ScorePlayer2),HL
AddScorePrint:
  PUSH BC
  PUSH DE
  CALL PrintHudNumber
  LD HL,$1770
  LD BC,(TallyPitch)
  LD DE,$FFFF
AddScoreCycles:
  INC DE
  OR A
  SBC HL,BC
  JR NC,AddScoreCycles
  LD HL,(TallyPitch)
  CALL BEEPER
  LD HL,(TallyPitch)
  LD DE,$FFF6
  ADD HL,DE
  JR NC,AddScoreDone
  LD (TallyPitch),HL
AddScoreDone:
  POP DE
  POP BC
  RET

; Add the pending term to ShotScore and print "FxBxMx10+" at row 3 (col 6, 7
; for a one-digit frame)
;
; Double-width text, attr $38 (C = $B8). w1, f1, v1 once each (the double
; pots).
TallyTermPlus:
  CALL AddTerm
  LD DE,$0306
  LD A,(FrameNumber)
  CP $0A
  JR NC,TallyTermPlusPrint
  INC E
TallyTermPlusPrint:
  CALL PrintTerm
  LD C,$B8
  EX DE,HL
  LD A,$2B
  JP PrintChar

; Add the last term and print "FxBxMx10=" and ShotScore x 10, centred on row 3
;
; The column starts at 1, plus one each for a frame < 10 and a total < 1000, <
; 100, < 10. Each term waits 15 frames (TallyPause $9B07) before its "x". w1
; 17, f1 1, p2 2, v1 4.
TallyTermTotal:
  CALL AddTerm
  LD DE,$0301
  LD A,(FrameNumber)
  CP $0A
  JR NC,TallyCentre1000
  INC E
TallyCentre1000:
  LD HL,(ShotScore)
  LD BC,$03E8
  XOR A
  SBC HL,BC
  JR NC,TallyCentre100
  INC E
TallyCentre100:
  ADD HL,BC
  LD BC,$0064
  XOR A
  SBC HL,BC
  JR NC,TallyCentre10
  INC E
TallyCentre10:
  ADD HL,BC
  LD BC,$000A
  XOR A
  SBC HL,BC
  JR NC,TallyTotalPrint
  INC E
TallyTotalPrint:
  CALL PrintTerm
  CALL TallyPause
  LD C,$B8
  EX DE,HL
  LD A,$3D
  CALL PrintChar
  INC L
  INC L
  EX DE,HL
  LD HL,(ShotScore)
  LD B,$00
  CALL PrintNumber
  EX DE,HL
  LD A,$30
  JP PrintChar

; ShotScore += frame x PotBall x PotMultiplier (ScoreTerm $9B2A as the product)
;
; Used by the routines at TallyTermPlus and TallyTermTotal.
AddTerm:
  LD HL,(FrameNumber)
  LD H,$00
  LD (ScoreVars),HL
  LD A,(PotBall)
  CALL MultiplyTerm
  LD A,(PotMultiplier)
  CALL MultiplyTerm
  LD HL,(ShotScore)
  LD BC,(ScoreVars)
  ADD HL,BC
  LD (ShotScore),HL
  RET

; Print frame, "x", ball, "x", multiplier, "x", "10" at DE (double width, attr
; $38)
;
; Used by the routines at TallyTermPlus and TallyTermTotal.
PrintTerm:
  LD C,$B8
  LD HL,(FrameNumber)
  CALL PrintTermFactor
  LD HL,(PotBall)
  CALL PrintTermFactor
  LD HL,(PotMultiplier)
  CALL PrintTermFactor
  LD HL,$000A
  LD B,H
  JP PrintNumber

; Print HL as a number at DE, wait 15 frames, then "x"; DE past it
;
; Used by the routine at PrintTerm.
PrintTermFactor:
  LD H,$00
  LD B,H
  CALL PrintNumber
  CALL TallyPause
  EX DE,HL
  LD A,$78
  CALL PrintChar
  INC L
  INC L
  EX DE,HL
  RET

; XOR the potted balls (bit 7 of +13 clear) at their place in the potted row,
; then the lives
;
; After ClearMessageRows wiped rows 2-4: ScoreTally and MessagesTask step $4F.
; game 4, w1 21, f1 4, p2 3, v1 7. Falls into DrawLives.
DrawPottedRow:
  LD IX,BallRecords
  LD A,$01
PottedRowLoop:
  LD DE,$000E
  ADD IX,DE
  BIT 7,(IX+$0D)
  JR NZ,PottedRowNext
  LD L,(IX+$0A)
  LD H,(IX+$0B)
  LD (SpritePos),HL
  PUSH AF
  CALL DrawBall
  POP AF
PottedRowNext:
  INC A
  CP $07
  JR NZ,PottedRowLoop

; XOR one cue ball per life (LivesLeft $9F4E, 1-3) in the potted row at x 160,
; 184, 208 (right-aligned to 208), y 20
;
; The first x = $88 + 24 (4 - lives). Lives 0 or negative: nothing. Called by
; DrawPottedRow, NextTurn, TurnSwap and the game start $8013: game 5, w1 22, p2
; 6.
DrawLives:
  LD A,(LivesLeft)
  OR A
  RET Z
  RET M
  NEG
  ADD A,$04
  LD B,A
  LD HL,$1488
  LD DE,$0018
LivesFirstX:
  ADD HL,DE
  DJNZ LivesFirstX
  LD (SpritePos),HL
  LD A,(LivesLeft)
  LD B,A
LivesLoop:
  PUSH BC
  XOR A
  CALL DrawBall
  POP BC
  LD HL,(SpritePos)
  LD DE,$0018
  ADD HL,DE
  LD (SpritePos),HL
  DJNZ LivesLoop
  RET

; Wait 15 frames (HALT)
;
; Used by the routines at ScoreTally, TallyTermTotal and PrintTermFactor.
TallyPause:
  LD B,$0F
TallyPauseLoop:
  HALT
  DJNZ TallyPauseLoop
  RET

; ScoreTerm $9B2A = ScoreTerm x A (16 x 8 bits, shift and add)
;
; Used by the routine at AddTerm.
MultiplyTerm:
  PUSH BC
  PUSH DE
  PUSH HL
  LD HL,$0000
  LD DE,(ScoreVars)
  LD B,$08
MultiplyLoop:
  RRA
  JR NC,MultiplyShift
  ADD HL,DE
MultiplyShift:
  SLA E
  RL D
  DJNZ MultiplyLoop
  LD (ScoreVars),HL
  POP HL
  POP DE
  POP BC
  RET

; The tally's and the turns' variables
;
; Readers and writers: the tally routines; CurrentPlayer by the game start
; $8052, TurnSwap $9C34 and the hall of fame $A79C / $A7C2 / $AD1C; UpBlink by
; StartAim $8432 / $8483; LastShotBlink $843E / $849F.
ScoreVars:
  DEFB $00,$00            ; word: the product of one term (frame x ball x
                          ; multiplier)
ShotScore:
  DEFB $00,$00            ; word: the shot's score (without the x 10), counted
                          ; down into the player's score
PotMultiplier:
  DEFB $00                ; the pending term's pocket multiplier 1-6
PotBall:
  DEFB $00                ; the pending term's ball number 1-6
CurrentPlayer:
  DEFB $00                ; 1 or 2
UpBlink:
  DEFB $00                ; 0 = print the 1up / 2up blank next, else the word
LastShotBlink:
  DEFB $00                ; 0 "last", 1 "shot", $FF restore "shots"
Player2Racked:
  DEFB $00                ; 0 until the second player's set was racked once
                          ; (two players)
TallyPitch:
  DEFB $00,$00            ; word: the count-up beep's BEEPER period, 1200 down
                          ; by 10 a step
