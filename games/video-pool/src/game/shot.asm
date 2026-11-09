; --------------------------------------------------------------------------------------------------------------------
; shot.asm: The balls in motion: the redraw task, the draw list, the end of a shot, the start of the aim
;
; When the shot is played (AimPower $8506 on the release of fire) the aim tasks go and MovingTasks $84BA come in:
; BallRedraw $827E, the physics $86C1, ShotEnd $8357 and the message task $9CB7, every interrupt. ShotEnd waits until
; no ball moves, then scores the shot, ends the frame or the life, and starts the next aim with StartAim $8425.
; --------------------------------------------------------------------------------------------------------------------

; The redraw task: each ball of DrawList, top to bottom, erased and drawn again
; where it moved
;
; Task of MovingTasks (period 0; w1 2839 runs, frames 1086-11 615). For the 7
; entries of DrawList $869E (sorted by y by BuildDrawList): A = the ball's
; number (0 = the cue ball), IX = its record, RedrawBall.
BallRedraw:
  LD HL,DrawList
  LD B,$07
BallRedrawLoop:
  PUSH BC                 ; the next entry: number, (y), record address
  LD A,(HL)
  INC HL
  INC HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  PUSH BC
  POP IX
  PUSH HL
  CALL RedrawBall
  POP HL
  POP BC
  DJNZ BallRedrawLoop
  RET

; Erase and redraw one ball if it moved; a potted ball goes to the row at the
; top
;
; IX = the ball record ($8A88 + 14n), A = n. Only for a ball with record +13
; bit 7 (on the table) and bit 4 (moved): erases the sprite at its old screen
; position (+10/+11 into $95D8, XOR draw $9548), then, unless bit 5 (potted) is
; set, computes the new sprite position from x and y ($9F36), stores it in
; +10/+11 and $95D8, clears bit 4 and draws it again ($9548 XOR). w1 19 873
; calls.
;
; A potted ball (bit 5; RedrawPotted, w1 18 times): +13 = 0 (off the table);
; the cue ball (n = 0) stays off; ball n >= 1 is put at x = 24(n-1) + 7, y = 27
; (integer bytes, fractions 0: the row of potted balls above the table) and
; drawn there when the message counter $9F50 is 0 or $50.
RedrawBall:
  BIT 7,(IX+$0D)
  RET Z
  BIT 4,(IX+$0D)
  RET Z
  LD L,(IX+$0A)
  LD H,(IX+$0B)
  LD (SpritePos),HL
  PUSH AF
  PUSH IX
  CALL DrawBall
  POP IX
  BIT 5,(IX+$0D)
  JR NZ,RedrawPotted
  CALL SpriteFromBall
  LD (SpritePos),HL
  LD (IX+$0A),L
  LD (IX+$0B),H
  RES 4,(IX+$0D)
  POP AF
  JP DrawBall
RedrawPotted:
  LD (IX+$0D),$00         ; potted: off the table; balls 1-6 to the top row
  POP AF
  LD B,A
  DEC A
  RET M
  ADD A,A
  ADD A,A
  ADD A,A
  LD C,A
  ADD A,A
  ADD A,C
  ADD A,$07
  LD (IX+$01),A
  LD (IX+$00),$00
  LD (IX+$03),$1B
  LD (IX+$02),$00
  CALL SpriteFromBall
  LD (SpritePos),HL
  LD (IX+$0A),L
  LD (IX+$0B),H
  LD A,(MessageStep)
  OR A
  JR Z,RedrawPottedDraw
  CP $50
  RET NZ
RedrawPottedDraw:
  LD A,B
  JP DrawBall

; DrawList from the ball records, sorted by y
;
; Writes the 7 entries of DrawList: the ball's number, its y (record +3, the
; integer byte), the record's address; then a bubble sort (6 passes) by y, so
; BallRedraw draws the balls from the top of the screen down. Called by
; ShotReset (w1 3451 calls also from the physics, frames 706-11 615).
BuildDrawList:
  LD HL,DrawList
  LD IX,BallRecords
  LD DE,$000E
  XOR A
DrawListFill:
  LD (HL),A               ; one entry a ball: number, y, address
  INC HL
  LD B,(IX+$03)
  LD (HL),B
  INC HL
  PUSH IX
  POP BC
  LD (HL),C
  INC HL
  LD (HL),B
  INC HL
  ADD IX,DE
  INC A
  CP $07
  JR NZ,DrawListFill
  LD DE,DrawList
  LD B,$06
DrawListSortPass:
  PUSH BC                 ; the sort: swap neighbours with the larger y first
  LD H,D
  LD L,E
  INC HL
  INC HL
  INC HL
  INC HL
DrawListSortStep:
  PUSH BC
  INC HL
  INC DE
  LD A,(DE)
  CP (HL)
  DEC HL
  DEC DE
  JR C,DrawListSortNext
  PUSH HL
  PUSH DE
  LD B,$04
DrawListSwap:
  LD C,(HL)               ; swap two 4-byte entries
  LD A,(DE)
  LD (HL),A
  LD A,C
  LD (DE),A
  INC HL
  INC DE
  DJNZ DrawListSwap
  POP DE
  POP HL
DrawListSortNext:
  INC HL
  INC HL
  INC HL
  INC HL
  POP BC
  DJNZ DrawListSortStep
  INC DE
  INC DE
  INC DE
  INC DE
  POP BC
  DJNZ DrawListSortPass
  RET

; The end-of-shot task: frame cleared, or all balls still: foul, shots, next
; aim
;
; Task of MovingTasks (w1 2860 runs). If no object ball is on the table (record
; +13 bit 7 clear for balls 1-6): StopShotTasks, WaitMessages, the score $98F9,
; $9754 when the foul flag $8E80 is set or the cue ball is off; erase the cue
; ball; $9BB8, the racking $9F69 and StartAim (the next frame; witness w1
; frames 1-3 won).
;
; Otherwise (ShotEndStill) it returns while any ball has a bit of $70 in +13
; (moving, moved or potted). When all are still: StopShotTasks and
; WaitMessages; then, if no foul and the cue ball is on the table: no ball
; touched ($89BB = 0) is a foul ($8E80 = 1, ShotFoul); a ball touched but none
; potted (record +12 = 0 for all six) costs a shot ($9F4D - 1; at 0 the same
; foul flag). Then the score $98F9, the foul / life code $9754 if $8E80 or the
; cue ball is off, $93FF (put the cue ball back) when the cue ball is off and
; lives $9F4E are left, $9DC3 with A = 3, and StartAim.
;
; ScoreTally runs before LoseLife, so a foul pot still scores: v1 frames
; 3045-3375, ball 5 into pocket 3 in variation 2, 150 paid, then a life lost
; (docs 10.9).
ShotEnd:
  LD IX,BallRecords
  LD DE,$000E
  ADD IX,DE
  LD B,$06
ShotEndBallsLeft:
  BIT 7,(IX+$0D)          ; any object ball left on the table?
  JR NZ,ShotEndStill
  ADD IX,DE
  DJNZ ShotEndBallsLeft
  CALL StopShotTasks
  CALL WaitMessages
  CALL ScoreShot
  LD A,(FoulCode)
  OR A
  JR NZ,ShotEndFoul
  LD IX,BallRecords
  BIT 7,(IX+$0D)
  JR NZ,ShotEndCueOff
ShotEndFoul:
  CALL LoseLife           ; a foul or the cue ball potted
ShotEndCueOff:
  LD IX,BallRecords       ; the cue ball off the screen
  BIT 7,(IX+$0D)
  JR Z,ShotEndNextFrame
  LD L,(IX+$0A)
  LD H,(IX+$0B)
  LD (SpritePos),HL
  XOR A
  CALL DrawBall
ShotEndNextFrame:
  CALL NextFrame          ; the next frame: rack and aim
  CALL Rack
  JR StartAim
ShotEndStill:
  LD IX,BallRecords       ; any ball still moving: wait
  LD B,$07
ShotEndMovingTest:
  LD A,(IX+$0D)
  AND $70
  RET NZ
  ADD IX,DE
  DJNZ ShotEndMovingTest
  CALL StopShotTasks
  CALL WaitMessages
  LD A,(FoulCode)
  OR A
  JR NZ,ShotEndScore
  LD IX,BallRecords
  BIT 7,(IX+$0D)
  JR Z,ShotEndScore
  LD A,(BallHitFlag)
  OR A
  JR Z,ShotFoul
  LD IX,BallRecords
  LD DE,$000E
  LD B,$06
ShotEndPottedTest:
  ADD IX,DE               ; was a ball potted this shot?
  LD A,(IX+$0C)
  OR A
  JR NZ,ShotEndScore
  DJNZ ShotEndPottedTest
  LD A,(ShotsLeft)        ; one shot fewer
  DEC A
  LD (ShotsLeft),A
  JR NZ,ShotEndScore
ShotFoul:
  LD A,$01                ; the foul flag $8E80 = 1
  LD (FoulCode),A
  CALL WaitMessages
ShotEndScore:
  CALL ScoreShot          ; the score of the shot
  LD A,(FoulCode)
  OR A
  JR NZ,ShotEndFoulStill
  LD IX,BallRecords
  BIT 7,(IX+$0D)
  JR NZ,ShotEndCueBack
ShotEndFoulStill:
  CALL LoseLife
ShotEndCueBack:
  LD IX,BallRecords       ; the cue ball off: put it back if a life is left
  BIT 7,(IX+$0D)
  JR NZ,ShotEndAim
  LD A,(LivesLeft)
  OR A
  CALL P,RespotCueBall
ShotEndAim:
  LD A,$03                ; back to the aim
  CALL PrintHudNumber
  JR StartAim

; The aim: cursor and power reset, AimTasks in, the three periodic HUD tasks
;
; AimCursorReset, AimPowerReset, InstallTasks AimTasks, then AddTask $96E6
; period 20, $970E period 25 and $9CA7 period 25 (with $9B31 / $9B32 = 0).
; Called at the game's start, after each shot and each frame (w1 21 times,
; frames 877-11 386).
StartAim:
  CALL AimCursorReset
  CALL AimPowerReset
  LD DE,AimTasks
  CALL InstallTasks
  XOR A
  LD (UpBlink),A
  LD C,$14
  LD HL,UpBlinkTask
  CALL AddTask
  XOR A
  LD (LastShotBlink),A
  LD C,$19
  LD HL,ShotsBlinkTask
  CALL AddTask
  LD C,$19
  LD HL,LastShotBeepTask
  JP AddTask

; Wait with the tasks stopped until the message on show is done
;
; WaitFrameNoTasks with WaitMessagesLoop. Called by ShotEnd twice and ShotFoul
; (w1 25 calls).
WaitMessages:
  LD HL,WaitMessagesLoop
  JP WaitFrameNoTasks

; Run the message task once a frame until the message counter allows play
;
; With the tasks stopped (WaitFrameNoTasks): while the message counter $9F50 is
; 1-$4E, or is $4F and no ball was potted, or is 0 with the foul flag $8E80
; set: HALT, the message task $9CB7, again. Returns when $9F50 >= $50, or 0
; with no foul. w1: 345 passes (320 HALTs).
WaitMessagesLoop:
  LD A,(MessageStep)
  OR A
  JR Z,WaitMessagesFoul
  CP $50
  RET NC
  CP $4F
  JR NZ,WaitMessagesHalt
  LD IX,BallRecords
  LD DE,$000E
  LD B,$06
WaitMessagesPotted:
  ADD IX,DE
  LD A,(IX+$0C)
  OR A
  RET NZ
  DJNZ WaitMessagesPotted
  JR WaitMessagesHalt
WaitMessagesFoul:
  LD A,(FoulCode)         ; no message: wait only for a foul
  OR A
  RET Z
WaitMessagesHalt:
  HALT                    ; one frame, one step of the message
  CALL MessagesTask
  JR WaitMessagesLoop

; Remove MovingTasks and the two HUD tasks, silence the sound
;
; RemoveTasks MovingTasks; RemoveTask $96E6 and $970E, each run once more with
; $9B31 / $9B32 = $FF (their final state); SoundRequest = 0. w1 21 calls.
;
; The clear ($84A6): 4 of its 21 clears in w1 come while a pocket tone plays
; (frames 2917, 3895, 6745, 10068): the tone is frozen with the foreground
; until the end-of-shot sequence returns, then aborted ($80A8; docs 9.3).
StopShotTasks:
  LD DE,MovingTasks
  CALL RemoveTasks
  LD HL,UpBlinkTask
  CALL RemoveTask
  LD A,$FF
  LD (UpBlink),A
  CALL UpBlinkTask
  LD HL,ShotsBlinkTask
  CALL RemoveTask
  LD A,$FF
  LD (LastShotBlink),A
  CALL ShotsBlinkTask
  XOR A
  LD (SoundRequest),A
  RET

; The aim's tasks, period 0 each: power, power bar, cursor move, cursor draw,
; input
;
; (period, routine) triples, $FF ends. Installed by StartAim, removed by
; AimPower when the shot is played. AimPower $8506, the power bar $934D,
; AimCursorMove $8546, AimCursorDraw $85EB, ReadInput $8106.
AimTasks:
  DEFB $00,$06,$85
  DEFB $00,$4D,$93
  DEFB $00,$46,$85
  DEFB $00,$EB,$85
  DEFB $00,$06,$81
  DEFB $FF                ; the end

; The tasks of the balls in motion, period 0 each: redraw, physics, shot end,
; messages
;
; Installed by AimPower ($8532), removed by StopShotTasks. BallRedraw $827E,
; the physics $86C1, ShotEnd $8357, the message task $9CB7.
MovingTasks:
  DEFB $00,$7E,$82
  DEFB $00,$C1,$86
  DEFB $00,$57,$83
  DEFB $00,$B7,$9C
  DEFB $FF                ; the end

; Before a shot: clear the shot's flags, the velocities and friction steps of
; the 7 balls
;
; Called by AimPower on the release of fire (w1 21). Clears $89BB (a ball was
; touched), the foul flag $8E80, the message counter $9F50, SoundRequest and
; $8B4C; for each ball record +4..+9 (velocities and friction steps) and +12,
; and +13 down to bit 7; then BuildDrawList.
ShotReset:
  XOR A
  LD (BallHitFlag),A
  LD (FoulCode),A
  LD (MessageStep),A
  LD (SoundRequest),A
  LD (FrictionTurn),A
  LD IX,BallRecords
  LD DE,$000E
  LD BC,$0700
ShotResetBall:
  LD (IX+$04),C
  LD (IX+$05),C
  LD (IX+$06),C
  LD (IX+$07),C
  LD (IX+$08),C
  LD (IX+$09),C
  LD (IX+$0C),C
  LD A,(IX+$0D)
  AND $80
  LD (IX+$0D),A
  ADD IX,DE
  DJNZ ShotResetBall
  CALL BuildDrawList
  RET
