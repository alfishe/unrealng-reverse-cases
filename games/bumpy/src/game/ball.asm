; --------------------------------------------------------------------------------------------------------------------
; ball.asm: The ball: the sprite routines, the move states, landing, the burst, falling out and the level end
;
; The ball is a CPC-style screen address $AA03 (the previous one in $AA05) and a sprite $AA01 (the round ball $67E8 or
; a rolling frame; player 2's sprites lie $280 higher). Each move state takes one step a frame from a table of address
; offsets: bounce in place (BallBounce, 16 steps, 18 lines up and back), left and right (16 steps: the same arc and 10
; CPC bytes, 5 Spectrum bytes, sideways), up and down (8 steps of 4 lines: 32 lines, one cell). Before each step a
; per-step check from the state's handler table ($AE9B, $AF15, $AF8F, $B044, $B0FA: routines at $C778-$CECC) tests the
; cells the ball crosses (walls, platforms, objects) and continues in the state's move routine.
;
; At the end of a move LandingCheck $B09E decides: on a platform, DecideMove $B7E4 picks the next state from the
; platform and the keys; in the air the ball falls (state 4); with no platform on the bottom row it falls out of the
; screen (state 7). The S key ($31) kills the ball in any move state (Suicide $BA71). Death by the burst (state 6) or
; by falling out (state 7) ends in LoseLife $BA93.
;
; What the ball does next at each landing, its rolling frames and its hit on a brick from below.
;
; The ball's tables and the step handlers of its five moving states. Each state (BallState $AA00, 0 bounce in place, 1
; left, 2 right, 3 up, 4 down) has a table of 16 (8 for up and down) step handlers in the main loop's range ($AE9B,
; $AF15, $AF8F, $B044, $B0FA); the handler for BallStep $A9FF runs once a frame, then the state's common tail moves
; and draws the ball. Step 0 of each state looks at the platform the ball leaves (the cell's platform type $AB1C,
; which $BB32 reads from $AA6B[ball cell $AA44]) and dispatches through a table of 13 handlers, one a platform type.
;
; The cells are a grid of 6 columns and 6 rows (cell = row x 6 + column, 0-35): the cell below is +6, the one above
; -6. The wall between a cell and the next one to the right has the cell's index in the wall array $AA8F.
; --------------------------------------------------------------------------------------------------------------------

  ORG $ADE6

; HL = the sprite at HL for the current player: + $280 for player 2
;
; Input HL a ball sprite (player 1's); output HL unchanged when CurrentPlayer
; $ADDB = 1, else HL + $280 (player 2's ball, a different pattern). Player 2's
; branch ran in no recording (no two-player game reached play).
;
; Witness: L1 218172 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
PlayerBallSprite:
  LD A,(CurrentPlayer)
  CP $01
  RET Z
  LD DE,$0280
  ADD HL,DE
  RET

; XOR the round ball ($67E8) at the ball's address $AA03
;
; Witness: L1 57057 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
DrawBallRound:
  LD HL,BallPictures
  CALL PlayerBallSprite
  LD DE,(BallScrAddr)
  EX DE,HL
  JR DrawBallXor

; XOR the ball's sprite $AA01 (a rolling frame) at $AA03
;
; Witness: L1 34344 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
DrawBallFrame:
  LD HL,(BallSprite)
  CALL PlayerBallSprite
  LD DE,(BallScrAddr)
  EX DE,HL
  JR DrawBallXor

; XOR the round ball at the previous address $AA05 (erases it)
;
; Witness: L1 200 (c1, gameover, menu, twoname, l10, l51, l68, l96, rzx x29).
DrawBallRoundOld:
  LD HL,BallPictures
  CALL PlayerBallSprite
  LD DE,(BallOldAddr)
  EX DE,HL
  JR DrawBallXor
; This entry point is used by the routine at BallStepMove.
EraseBallOld:
  LD HL,(BallSprite)      ; XOR the sprite $AA01 at the previous address $AA05
  CALL PlayerBallSprite
  LD DE,(BallOldAddr)
  EX DE,HL

; XOR a ball sprite: HL the CPC address, DE the sprite; 10 lines, $A9FE = 4
;
; Sets $A9FE = 4, B = 10 (lines), C = 7, and calls the XOR sprite routine
; $E3E5. The sprite routines above load HL and DE and come here.
;
; Witness: L1 182818 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
DrawBallXor:
  LD A,$04
  LD (SpriteWidth),A
  LD B,$0A
  LD C,$07
  CALL XorSpriteColoured
  RET

; Moves the ball one step: $AA05 = $AA03, $AA03 += IX[BallStep], erase at the
; old address
;
; Input IX the state's offset table (16 or 8 words). The new address is the old
; plus the step's offset (a CPC screen address delta: $0800 a pixel line, $0050
; a character row); then EraseBallOld at $AE18 removes the old picture. The
; caller draws the new one.
;
; Witness: L1 91187 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
BallStepMove:
  LD HL,(BallScrAddr)
  LD (BallOldAddr),HL
  LD A,(BallStep)
  RLA
  LD E,A
  LD D,$00
  ADD IX,DE
  LD E,(IX+$00)
  LD D,(IX+$01)
  ADD HL,DE
  LD (BallScrAddr),HL
  JR EraseBallOld

; Jumps to IX[BallStep]: the per-step check of the current move
;
; Input IX a state's handler table. Each check routine ($C778-$CECC) tests the
; cells, then goes on to the state's move routine (BallBounceMove $AE65 and the
; others) or to a crash.
;
; Witness: L1 91704 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
StepDispatch:
  LD A,(BallStep)
  RLA
  LD E,A
  LD D,$00
  ADD IX,DE
  LD E,(IX+$00)
  LD D,(IX+$01)
  PUSH DE
  POP IX
  JP (IX)

; State 0: the bounce in place, 16 steps (the checks in BounceChecks)
;
; Witness: L1 18987 (c1, fire, gameover, menu, twoname, l x11, rzx x94).
BallBounce:
  LD IX,BounceChecks
  JR StepDispatch

; State 0's step: round ball, the BounceOffsets step, S kills, after step 15
; LandingCheck
;
; Sprite = the round ball $67E8. BallStepMove with BounceOffsets $AEBB; in a
; game, S ($31) jumps to Suicide $BA71; DrawBallRound; BallStep + 1 and back to
; MainLoop, or after step 15 BallStep = 0 and LandingCheck $B09E. The 16
; offsets lift the ball 4, 8, 11, 14, 16, 17, 18, 18, 18, 17, 16, 14, 11, 8, 4
; and 0 lines above its rest line (pixel line 6 or 7 of a character row).
;
; Witness: L1 18987 (c1, fire, gameover, menu, twoname, l x11, rzx x94).
BallBounceMove:
  AND A
  LD HL,BallPictures
  LD (BallSprite),HL
  LD IX,BounceOffsets
  CALL BallStepMove
  LD A,(DemoFlag)
  CP $00
  JR NZ,BallBounceMoveSkip
  LD A,$31
  CALL TestKey
  JP NZ,SelfDestruct
BallBounceMoveSkip:
  CALL DrawBallRound
  LD A,(BallStep)
  CP $0F
  JR Z,BallBounceEnd
  INC A
  LD (BallStep),A
  JP MainLoop
BallBounceEnd:
  LD A,$00                ; step 15 done: LandingCheck
  LD (BallStep),A
  JP LandingCheck

; State 0's 16 per-step checks (routines $C778-$C822)
BounceChecks:
  DEFW BounceStep0,BounceStep1,BounceStepIdle,BounceStepIdle,BounceStepIdle,BounceStepIdle,BounceStepIdle,BounceStepIdle
  DEFW BounceStepIdle,BounceStep9,BounceStep10,BounceStep11,BounceStep12,BounceStep13,BounceStep14,BounceStep15

; State 0's 16 address offsets: the ball's arc, 18 lines up and back
BounceOffsets:
  DEFW $E000,$1FB0,$E800,$E800,$2FB0,$F800,$F800,$0000
  DEFW $0000,$0800,$0800,$D050,$1800,$1800,$E050,$2000

; State 1: the jump to the left, 16 steps (the checks in LeftChecks)
;
; Witness: L1 15425 (c1, fire, gameover, menu, twoname, l x11, rzx00-rzx18,
; rzx21-rzx81, rzx83-rzx86, rzx88-rzx99).
BallLeft:
  LD IX,LeftChecks
  JP StepDispatch

; State 1's step: LeftOffsets, S kills, the rolling frame ($B8A2), after step
; 15 LandingCheck
;
; As BallBounceMove with LeftOffsets $AF35 and the sprite picked by $B8A2 (the
; left-rolling frames). The ball moves 10 CPC bytes left (5 Spectrum bytes, one
; cell) on the same arc.
;
; Witness: L1 15478 (c1, fire, gameover, menu, twoname, l x11, rzx00-rzx18,
; rzx21-rzx81, rzx83-rzx86, rzx88-rzx99).
BallLeftMove:
  AND A
  LD IX,LeftOffsets
  CALL BallStepMove
  LD A,(DemoFlag)
  CP $00
  JR NZ,BallLeftMoveSkip
  LD A,$31
  CALL TestKey
  JP NZ,SelfDestruct
BallLeftMoveSkip:
  CALL DrawBallLeft
  CALL DrawBallFrame
  LD A,(BallStep)
  CP $0F
  JR Z,BallLeftEnd
  INC A
  LD (BallStep),A
  JP MainLoop
BallLeftEnd:
  LD A,$00                ; step 15 done: LandingCheck
  LD (BallStep),A
  JP LandingCheck

; State 1's 16 per-step checks (routines $C847-$CA57)
LeftChecks:
  DEFW LeftStep0,LeftStepIdle,LeftStepIdle,LeftStepIdle,LeftStepIdle,LeftStep5,LeftStepIdle2,LeftStepIdle2
  DEFW LeftStep8,LeftStep9,LeftStep10,LeftStep11,LeftStep12,LeftStep13,LeftStep14,LeftStep15

; State 1's 16 offsets: the arc and 10 CPC bytes to the left
LeftOffsets:
  DEFW $E000,$1FB0,$E7FF,$E7FF,$2FB0,$F7FF,$F7FF,$FFFF
  DEFW $0000,$07FF,$07FF,$D04F,$1800,$17FF,$E050,$1FFF

; State 2: the jump to the right, 16 steps (the checks in RightChecks)
;
; Witness: L1 18921 (c1, gameover, menu, twoname, l x12, rzx00-rzx99).
BallRight:
  LD IX,RightChecks
  JP StepDispatch

; State 2's step: RightOffsets, S kills, the rolling frame ($B882), after step
; 15 LandingCheck
;
; As BallLeftMove with RightOffsets $AFAF and the right-rolling frames ($B882).
;
; Witness: L1 18866 (c1, gameover, menu, twoname, l x12, rzx00-rzx99).
BallRightMove:
  AND A
  LD IX,RightOffsets
  CALL BallStepMove
  LD A,(DemoFlag)
  CP $00
  JR NZ,BallRightMoveSkip
  LD A,$31
  CALL TestKey
  JP NZ,SelfDestruct
BallRightMoveSkip:
  CALL DrawBallRight
  CALL DrawBallFrame
  LD A,(BallStep)
  CP $0F
  JR Z,BallRightEnd
  INC A
  LD (BallStep),A
  JP MainLoop
BallRightEnd:
  LD A,$00                ; step 15 done: LandingCheck
  LD (BallStep),A
  JP LandingCheck

; State 2's 16 per-step checks (routines $CA8D-$CC9A)
RightChecks:
  DEFW RightStep0,RightStepIdle,RightStepIdle,RightStepIdle,RightStepIdle,RightStep5,RightStepIdle2,RightStepIdle2
  DEFW RightStep8,RightStep9,RightStep10,RightStep11,RightStep12,RightStep13,RightStep14,RightStep15

; State 2's 16 offsets: the arc and 10 CPC bytes to the right
RightOffsets:
  DEFW $E001,$1FB0,$E801,$E800,$2FB1,$F801,$F801,$0000
  DEFW $0001,$0801,$0801,$D050,$1801,$1801,$E050,$2000

; State 3: the spring's jump up one cell, 8 steps (the checks in UpChecks)
;
; Witness: L1 18771 (c1, gameover, menu, twoname, l x12, rzx00-rzx77,
; rzx79-rzx99).
BallUp:
  LD IX,UpChecks
  JP StepDispatch

; State 3's step: 4 lines up, S kills; after step 7 DecideMove
;
; Round ball, UpOffsets $B054 (8 x 4 lines = 32 lines, one cell row). After
; step 7, BallStep = 0 and DecideMove $B7E4 picks the next state (the ball is
; on the platform above).
;
; Witness: L1 18254 (c1, gameover, menu, twoname, l x12, rzx00-rzx77,
; rzx79-rzx99).
BallUpMove:
  AND A
  LD HL,BallPictures
  LD (BallSprite),HL
  LD IX,UpOffsets
  CALL BallStepMove
  LD A,(DemoFlag)
  CP $00
  JR NZ,BallUpMoveSkip
  LD A,$31
  CALL TestKey
  JP NZ,SelfDestruct
BallUpMoveSkip:
  CALL DrawBallRound
  LD A,(BallStep)
  CP $07
  JR Z,BallUpEnd
  INC A
  LD (BallStep),A
  JP MainLoop
BallUpEnd:
  LD A,$00                ; step 7 done: DecideMove
  LD (BallStep),A
  CALL ChooseNextState
  JP MainLoop

; The ball hits a platform from below: two lines up and back, then it falls
; (state 4)
;
; Jumped to by the up checks ($CDAA, $CDC3) when the cell above is closed.
; Moves the ball 2 lines up ($F000 = minus $1000), redraws it, waits a frame
; ($B87E), moves it back ($1000) and sets BallState = 4 (down). 88 bumps in the
; recordings (its witness).
;
; Witness: L1 100 (c1, gameover, menu, twoname, l10, l51, l68, l96, rzx x29).
BallBumpCeiling:
  AND A
  LD HL,(BallScrAddr)
  LD (BallOldAddr),HL
  LD BC,$F000
  ADD HL,BC
  LD (BallScrAddr),HL
  CALL DrawBallRoundOld
  LD HL,(BallScrAddr)
  LD (BallOldAddr),HL
  CALL DrawBallRound
  CALL WaitOneFrame
  LD HL,(BallScrAddr)
  LD BC,$1000
  ADD HL,BC
  LD (BallScrAddr),HL
  CALL DrawBallRoundOld
  CALL DrawBallRound
  LD A,$04
  LD (BallState),A
  JP MainLoop

; State 3's 8 per-step checks (routines $CCD0-$CE10)
UpChecks:
  DEFW UpStep0,UpStep1,UpStep2,UpStep3,UpStep4,UpStep5,UpStep6,UpStep7

; State 3's 8 offsets: 4 lines up each ($E000 + $1FB0 = -$50 and so on, by the
; line in the character row)
UpOffsets:
  DEFW $E000,$1FB0,$E000,$1FB0,$E000,$1FB0,$E000,$1FB0

; State 4: the fall one cell down, 8 steps (the checks in DownChecks)
;
; Witness: L1 19600 (c1, gameover, menu, twoname, l x12, rzx00-rzx99).
BallDown:
  LD IX,DownChecks
  JP StepDispatch

; State 4's step: 4 lines down, S kills; after step 7 LandingCheck
;
; Witness: L1 19596 (c1, gameover, menu, twoname, l x12, rzx00-rzx99).
BallDownMove:
  AND A
  LD HL,BallPictures
  LD (BallSprite),HL
  LD IX,DownOffsets
  CALL BallStepMove
  LD A,(DemoFlag)
  CP $00
  JR NZ,BallDownMoveSkip
  LD A,$31
  CALL TestKey
  JP NZ,SelfDestruct
BallDownMoveSkip:
  CALL DrawBallRound
  LD A,(BallStep)
  CP $07
  JR Z,BallDownEnd
  INC A
  LD (BallStep),A
  JP MainLoop
BallDownEnd:
  LD A,$00                ; step 7 done
  LD (BallStep),A

; The end of a move: on a platform DecideMove, in the air fall, off the bottom
; row lost
;
; $AA44 is the ball's cell (0-35, six columns by six rows; 30-35 the bottom
; row) and $AB1C the platform in it. A platform: DecideMove $B7E4. No platform
; above the bottom row: BallState = 4 (fall one cell); if the cell below
; (CellPlatforms $AA6B + cell + 6) holds bricks ($0A) DecideMove runs at once.
; No platform on the bottom row: BallState = 7 (lost below), BallStep = 0.
; Witness: state 7 started 8 times in the recordings ($B0E0).
;
; Witness: L1 6101 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
LandingCheck:
  AND A
  LD A,(BallCell)
  CP $1E
  JR NC,LandingBottom
  AND A
  LD A,(CellPlatform)
  CP $00
  JR Z,LandingFall
  CALL ChooseNextState
  JP MainLoop
LandingFall:
  LD A,$04                ; in the air: fall (state 4), bricks below decide at
                          ; once
  LD (BallState),A
  LD A,(BallCell)
  ADD A,$06
  LD D,$00
  LD E,A
  LD HL,CellPlatforms
  ADD HL,DE
  LD A,(HL)
  CP $0A
  JP NZ,MainLoop
  CALL ChooseNextState
  JP MainLoop
LandingBottom:
  AND A                   ; on the bottom row
  LD A,(CellPlatform)
  CP $00
  JP Z,LandingLost
  CALL ChooseNextState
  JP MainLoop
LandingLost:
  LD A,$07                ; no platform on the bottom row: state 7
  LD (BallState),A
  LD A,$00
  LD (BallStep),A
  JP MainLoop

; Starts the burst (state 6, step 0): the ball hit a deadly platform
;
; Jumped to by the platform checks when the ball lands on platform 12 from
; above ($CA8A, $CF09) or hits it from below ($CCCD); the fire death (a flame
; without water) goes through it too. 5 bursts in the recordings (rzx45, rzx56,
; rzx68).
;
; Witness: L1 6 (fire, rzx45, rzx56, rzx68).
BallBurstStart:
  LD A,$06
  LD (BallState),A
  LD A,$00
  LD (BallStep),A
  JP MainLoop

; State 4's 8 per-step checks (routines $CE24-$CECC)
DownChecks:
  DEFW DownStep0,DownStepIdle,DownStepIdle,DownStep3,DownStep4,DownStep5,DownStepIdle2,DownStep7

; State 4's 8 offsets: 4 lines down each
DownOffsets:
  DEFW $E050,$2000,$E050,$2000,$E050,$2000,$E050,$2000

; State 5: the ball sits on a stopper platform (5) until left or right is
; pressed
;
; In the demo the next state is the next byte of the demo input ($ABA4 + 1,
; from $D25B). In a game S kills (Suicide $BA71), right sets state 2 ($B855),
; left state 1 ($B84F). Then a short busy wait (Delay $B873, B = 2) and
; MainLoop.
;
; Witness: L1 827 (menu, l x6, rzx x29).
BallStopped:
  LD A,(DemoFlag)
  CP $00
  JR Z,BallStoppedKeys
  LD HL,(DemoInputPtr)
  INC HL
  LD (DemoInputPtr),HL
  LD A,(HL)
  LD (BallState),A
  JR BallStoppedWait
BallStoppedKeys:
  LD A,$31                ; a game: S, right, left
  CALL TestKey
  JP NZ,SelfDestruct
  CALL TestRight
  CALL NZ,SetStateRight
  CALL TestLeft
  CALL NZ,SetStateLeft
BallStoppedWait:
  LD B,$02                ; the wait, then MainLoop
  CALL Delay
  JP MainLoop

; State 6: the burst, one frame of BurstSteps a pass (10 steps), then LoseLife
;
; Jumps to BurstSteps[BallStep] after BallStep + 1 and a frame wait ($B87E).
; The steps: the ball drawn at three places around the burst point $AB2D
; (BurstBall1-3), six burst pictures $81F5-$830D (56 bytes each, 14 lines), a
; blank ($6708), then LoseLife $BA93.
;
; Witness: L1 116 (fire, rzx x8).
BallBurst:
  AND A
  LD IX,BurstSteps
  LD A,(BallStep)
  SLA A
  LD D,$00
  LD E,A
  ADD IX,DE
  LD D,(IX+$01)
  LD E,(IX+$00)
  PUSH DE
  POP IX
  LD A,(BallStep)
  INC A
  LD (BallStep),A
  CALL WaitOneFrame
  JP (IX)

; Burst step 0: the ball at $AB2D + $FF62
;
; Witness: L1 6 (fire, rzx45, rzx56, rzx68).
BurstBall1:
  LD BC,$FF62
  CALL DrawBurstBall
  JP MainLoop

; Burst step 1: the ball at $AB2D + $FF62 (off) and + $2F12
;
; Witness: L1 6 (fire, rzx45, rzx56, rzx68).
BurstBall2:
  LD BC,$FF62
  CALL DrawBurstBall
  LD BC,$2F12
  CALL DrawBurstBall
  JP MainLoop

; Burst step 2: the ball at $AB2D + $2F12 (off) and + $2712
;
; Witness: L1 6 (fire, rzx45, rzx56, rzx68).
BurstBall3:
  LD BC,$2F12
  CALL DrawBurstBall
  LD BC,$2712
  CALL DrawBurstBall
  JP MainLoop

; Burst step 3: picture $81F5
;
; Witness: L1 14 (fire, rzx x8).
BurstFrame1:
  LD DE,BurstPictures
  CALL DrawBurstPicture
  JP MainLoop

; Burst step 4: picture $822D
;
; Witness: L1 14 (fire, rzx x8).
BurstFrame2:
  LD DE,BurstPictures+$0038
  CALL DrawBurstPicture
  JP MainLoop

; Burst step 5: picture $8265
;
; Witness: L1 14 (fire, rzx x8).
BurstFrame3:
  LD DE,BurstPictures+$0070
  CALL DrawBurstPicture
  JP MainLoop

; Burst step 6: picture $829D
;
; Witness: L1 14 (fire, rzx x8).
BurstFrame4:
  LD DE,BurstPictures+$00A8
  CALL DrawBurstPicture
  JP MainLoop

; Burst step 7: picture $82D5
;
; Witness: L1 14 (fire, rzx x8).
BurstFrame5:
  LD DE,BurstPictures+$00E0
  CALL DrawBurstPicture
  JP MainLoop

; Burst step 8: picture $830D
;
; Witness: L1 14 (fire, rzx x8).
BurstFrame6:
  LD DE,BurstPictures+$0118
  CALL DrawBurstPicture
  JP MainLoop

; Burst step 9: the blank picture $6708 over it, then LoseLife
;
; Witness: L1 14 (fire, rzx x8).
BurstEnd:
  LD DE,BlankPicture
  CALL DrawBurstPicture
  JP LoseLife

; Stores the picture at DE (14 lines, $A9FE = 4) at the burst point $AB2D +
; $1712
;
; Witness: L1 98 (fire, rzx x8).
DrawBurstPicture:
  LD HL,(CellScrAddr)
  LD BC,$1712
  ADD HL,BC
  EX DE,HL
  LD A,$04
  LD (SpriteWidth),A
  LD B,$0E
  CALL DrawSprite
  RET

; XOR the player's round ball at $AB2D + BC
;
; Witness: L1 30 (fire, rzx45, rzx56, rzx68).
DrawBurstBall:
  LD HL,BallPictures
  CALL PlayerBallSprite
  EX DE,HL
  LD HL,(CellScrAddr)
  ADD HL,BC
  CALL DrawBallXor
  RET

; State 6's ten steps: BurstBall1-3, BurstFrame1-6, BurstEnd
BurstSteps:
  DEFW BurstBall1,BurstBall2,BurstBall3,BurstFrame1,BurstFrame2,BurstFrame3,BurstFrame4,BurstFrame5,BurstFrame6,BurstEnd

; State 7: the ball sinks out through the bottom edge, one LostSteps routine a
; frame, then LoseLife
;
; Jumps to LostSteps[BallStep] after BallStep + 1, $A9FE = 4. Five steps: the
; ball moves down and is drawn with fewer lines (9, 5, 1), the last plays the
; sound $F4CB and calls LoseLife $BA93. Witness: 8 falls in the recordings.
;
; Witness: L1 40 (rzx x6).
BallFallOut:
  AND A
  LD IX,LostSteps
  LD A,(BallStep)
  RLA
  LD D,$00
  LD E,A
  ADD IX,DE
  LD D,(IX+$01)
  LD E,(IX+$00)
  PUSH DE
  POP IX
  LD A,(BallStep)
  INC A
  LD (BallStep),A
  LD A,$04
  LD (SpriteWidth),A
  JP (IX)

; A lone RET ($C9) nobody calls (leftover)
UnusedRetB22F:
  DEFB $C9

; Falling out, step 0: the round ball off, $AA03 + $E050, on again
;
; Witness: L1 8 (rzx x6).
LostStep1:
  CALL DrawBallRound
  LD HL,(BallScrAddr)
  LD BC,$E050
  ADD HL,BC
  LD (BallScrAddr),HL
  CALL DrawBallRound
  JP MainLoop

; Step 1: the ball off, the sprite kept in $AA01, $AA03 + $2000, 9 lines of it
; on
;
; Witness: L1 8 (rzx x6).
LostStep2:
  CALL DrawBallRound
  LD HL,BallPictures
  CALL PlayerBallSprite
  LD (BallSprite),HL
  EX DE,HL
  LD HL,(BallScrAddr)
  LD BC,$2000
  ADD HL,BC
  LD (BallScrAddr),HL
  LD B,$09
  CALL XorSprite
  JP MainLoop

; Step 2: 9 lines off, $AA03 + $E050, 5 lines on
;
; Witness: L1 8 (rzx x6).
LostStep3:
  LD HL,(BallScrAddr)
  LD DE,(BallSprite)
  LD B,$09
  CALL XorSprite
  LD HL,(BallScrAddr)
  LD BC,$E050
  ADD HL,BC
  LD (BallScrAddr),HL
  LD DE,(BallSprite)
  LD B,$05
  CALL XorSprite
  JP MainLoop

; Step 3: 5 lines off, $AA03 + $2000, 1 line on
;
; Witness: L1 8 (rzx x6).
LostStep4:
  LD HL,(BallScrAddr)
  LD DE,(BallSprite)
  LD B,$05
  CALL XorSprite
  LD HL,(BallScrAddr)
  LD BC,$2000
  ADD HL,BC
  LD (BallScrAddr),HL
  LD DE,(BallSprite)
  LD B,$01
  CALL XorSprite
  JP MainLoop

; Step 4: the last line off, the sound $F4CB, LoseLife
;
; Witness: L1 8 (rzx x6).
LostStep5:
  LD HL,(BallScrAddr)
  LD DE,(BallSprite)
  LD B,$01
  CALL XorSprite
  CALL SfxLifeLost
  JP LoseLife

; State 7's five steps
LostSteps:
  DEFW LostStep1,LostStep2,LostStep3,LostStep4,LostStep5

; State 8: the ball sinks into the exit, the timer counts into the score, the
; next level
;
; Reached when the ball lands on the exit (platform $0B: DecideMove sets state
; 8). With CheatMode $ADDD the level would come from a routine's L (CALL $B754,
; a RET; then L reduced below 100 by steps of 97: known only from the code).
; Else NextLevel $B2D5.
;
; Witness: L1 101 (menu, l x12, rzx x88).
;
; NextLevel: level 99 is followed by level 0 (witness: one run of $B2DE in the
; RZX). Then 9 times: two bytes of the ball's top line cleared ($C71F, $B515),
; the ball one line lower ($0800; $C050 more past a character row), the round
; ball stored there ($E318), a frame, the animations ($BD21, $BBCD, $BC30), a
; frame. Then the last line cleared, the sound $F49A and 15 HALTs. Then the
; rest of the timer $AB04 goes into the score one point a tick: the tick sound
; $F4F9, score $AAFB + 1, the score printed ($E60C), until the timer is 0. The
; working copy goes back to the player's record ($AB09; $AB10 for player 2),
; and the demo ends ($B7A9, back to the menu) or a game waits about a second
; ($B7B8) and starts the level at LifeStart.
LevelEnd:
  LD A,(CheatMode)
  CP $00
  JR Z,NextLevel
LevelEndCheat:
  CALL FirmwareStub5      ; the cheat mode's level choice (never runs)
  LD A,L
LevelEndCheatLoop:
  CP $64                  ; reduce below 100
  JR C,LevelEndSet
  SUB $61
  JR LevelEndCheatLoop
NextLevel:
  LD A,(Level)            ; Level $AB00 + 1, 100 becomes 0
  AND A
  INC A
  CP $64
  JR NZ,LevelEndSet
  LD A,$00
LevelEndSet:
  AND A                   ; store the level
  LD (Level),A
  LD B,$09
LevelEndSink:
  PUSH BC                 ; one line of the sinking ball
  PUSH BC
  LD HL,(BallScrAddr)
  CALL ScreenAddrToLine
  CALL LineAddress
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD A,(SpectrumColumn)
  OR L
  LD L,A
  LD (HL),$00
  INC HL
  LD (HL),$00
  POP BC
  LD IX,(BallScrAddr)
  LD DE,$0800
  ADD IX,DE
  JR NC,LevelEndSinkDraw
  LD DE,$C050
  ADD IX,DE
LevelEndSinkDraw:
  LD (BallScrAddr),IX     ; draw the ball one line lower
  LD HL,BallPictures
  CALL PlayerBallSprite
  LD DE,(BallScrAddr)
  LD A,$04
  LD (SpriteWidth),A
  CALL DrawSprite
  CALL WaitOneFrame
  CALL AnimateExit
  CALL AnimateFires
  CALL AnimateWalls
  CALL WaitOneFrame
  POP BC
  DJNZ LevelEndSink
  LD HL,(BallScrAddr)
  CALL ScreenAddrToLine
  CALL LineAddress
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD A,(SpectrumColumn)
  OR L
  LD L,A
  LD (HL),$00
  INC HL
  LD (HL),$00
  AND A
  CALL SfxLevelEnd
  LD B,$0F
LevelEndPause:
  PUSH BC                 ; 15 frames
  EI
  HALT
  POP BC
  DJNZ LevelEndPause
LevelEndTimer:
  LD HL,(Timer)           ; the timer into the score
  LD A,H
  CP $00
  JR Z,LevelEndTimerLow
LevelEndTick:
  DEC HL                  ; one point
  LD (Timer),HL
  CALL SfxTimerTick
  LD A,$03
  LD (HudColumn),A
  LD HL,(Score)
  INC HL
  LD (Score),HL
  CALL PrintNumber5
  JR LevelEndTimer
LevelEndTimerLow:
  LD A,L                  ; the timer's high byte is 0
  CP $00
  JP Z,LevelEndSave
  JR LevelEndTick
LevelEndSave:
  CALL FirmwareStub3      ; the working copy back to the record
  LD DE,Player1Record
  LD A,(CurrentPlayer)
  CP $01
  JR Z,LevelEndSaveSkip
  LD DE,Player2Record
LevelEndSaveSkip:
  LD HL,Score             ; copy 7 bytes
  LD BC,$0007
  LDIR
  AND A
  LD A,(DemoFlag)
  CP $00
  JP Z,LevelEndNext
  JP GameOverPause
LevelEndNext:
  CALL WaitKeyOrSecond    ; a game: the pause, then LifeStart
  JP LifeStart

  ORG $B7E4

; At a landing, choose the ball's next state from the platform and the keys
;
; Called by the bounce handlers ($ACB9, $B009, $B0AE, $B0CB, $B0DA) when the
; ball lands on a cell. In play ($ABA6 = 0), in this order: SpringArmed $AA13 =
; 1 gives state 3 (up); the cell's platform ($AB1C) $0B, the open exit, gives 8
; (level end); 7 gives 2 (right: conveyor); 6 gives 1 (left: conveyor); 5 gives
; 5 (stopped, waiting for left or right); $0A (bricks) keeps the state; the
; left key (KeySlots $F086, LeftKey $B447) gives 1; the right key ($F087,
; RightKey $B44E) gives 2; a ball going up (3) with the down key ($F085,
; DownKey $B45C) gives 0, and without it stays 3; anything else gives 0 (bounce
; in place).
;
; In the demo ($ABA6 not 0) the exit and the conveyors are checked first, then
; the next byte of the demo moves (the pointer $ABA4 is advanced) becomes
; BallState $AA00, and SpringArmed still forces 3. Output: BallState $AA00.
; Witness: every play recording (rzx x100, menu demo).
;
; Witness: L1 6161 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
ChooseNextState:
  LD A,(DemoFlag)
  CP $00
  JR Z,ChoosePlayState
  LD A,(CellPlatform)
  CP $0B
  JP Z,SetStateLevelEnd
  AND A
  CP $07
  JP Z,SetStateRight
  AND A
  CP $06
  JP Z,SetStateLeft
ChooseDemoState:
  LD HL,(DemoInputPtr)    ; demo: the next byte of the demo moves
  INC HL
  LD (DemoInputPtr),HL
  LD A,(HL)
  LD (BallState),A
  LD A,(SpringArmed)
  CP $01
  JR Z,SetStateUp
  RET
ChoosePlayState:
  LD A,(SpringArmed)
  CP $01
  JR Z,SetStateUp
  LD A,(CellPlatform)
  CP $0B
  JR Z,SetStateLevelEnd
  AND A
  CP $07
  JR Z,SetStateRight
  AND A
  CP $06
  JR Z,SetStateLeft
  AND A
  CP $05
  JR Z,SetStateStopped
  CP $0A
  RET Z
  CALL TestLeft
  JR NZ,SetStateLeft
  CALL TestRight
  JR NZ,SetStateRight
  LD A,(BallState)
  CP $03
  JR Z,ChooseUpOrBounce
SetStateBounce:
  LD A,$00                ; state 0
  LD (BallState),A
  RET
ChooseUpOrBounce:
  CALL TestDown           ; going up: the down key turns it into a bounce
  JR NZ,SetStateBounce
  RET

; BallState = 1 (moving left)
;
; Also the target of the left conveyor and of the stopped ball's left key
; ($B13F).
;
; Witness: L1 979 (c1, fire, gameover, menu, twoname, l x11, rzx00-rzx17,
; rzx21-rzx81, rzx83-rzx86, rzx88-rzx99).
SetStateLeft:
  LD A,$01
  LD (BallState),A
  RET

; BallState = 2 (moving right)
;
; Also the target of the right conveyor and of the stopped ball's right key
; ($B139).
;
; Witness: L1 1238 (c1, gameover, menu, twoname, l x12, rzx00-rzx99).
SetStateRight:
  LD A,$02
  LD (BallState),A
  RET
; This entry point is used by the routine at ChooseNextState.
SetStateUp:
  LD A,$03                ; state 3
  LD (BallState),A
  RET

; BallState = 4 (moving down): never called
;
; LD A,4: LD ($AA00),A: RET, like its neighbours, but no code jumps here (known
; only from the code: a leftover of ChooseNextState).
;
; Witness: L1 0 ().
SetStateDown:
  LD A,$04
  LD (BallState),A
  RET

; BallState = 5 (stopped on a type 5 platform)
;
; Witness: L1 141 (l x6, rzx x26).
SetStateStopped:
  LD A,$05
  LD (BallState),A
  RET
; This entry point is used by the routine at ChooseNextState.
SetStateLevelEnd:
  LD A,$08                ; state 8
  LD (BallState),A
  RET

  ORG $B882

; Draw the ball's frame for a move to the right
;
; Sets the width $A9FE to 4 bytes, takes the frame address for the step
; BallStep $A9FF from BallFramesRight $C4E2 into $AA01 and calls DrawBall
; $ADE6. Called by the right-move handler ($AF73).
;
; Witness: L1 18866 (c1, gameover, menu, twoname, l x12, rzx00-rzx99).
DrawBallRight:
  AND A
  LD A,$04
  LD (SpriteWidth),A
  LD A,(BallStep)
  RLA
  LD E,A
  LD D,$00
  LD IX,BallFramesRight
  ADD IX,DE
  LD H,(IX+$01)
  LD L,(IX+$00)
  LD (BallSprite),HL
  CALL PlayerBallSprite
  RET

; Draw the ball's frame for a move to the left
;
; As DrawBallRight with the table BallFramesLeft $C502. Called by the left-move
; handler ($AEF9).
;
; Witness: L1 15478 (c1, fire, gameover, menu, twoname, l x11, rzx00-rzx18,
; rzx21-rzx81, rzx83-rzx86, rzx88-rzx99).
DrawBallLeft:
  AND A
  LD A,$04
  LD (SpriteWidth),A
  LD A,(BallStep)
  RLA
  LD E,A
  LD D,$00
  LD IX,BallFramesLeft
  ADD IX,DE
  LD H,(IX+$01)
  LD L,(IX+$00)
  LD (BallSprite),HL
  CALL PlayerBallSprite
  RET

  ORG $B8D1

; The ball going up meets a brick: crumble a layer (a hammer for an intact
; brick) and send it down
;
; Called by the up-move handlers ($CCE9-$CE15) when the ball is under a brick
; cell. B = BrickContact $E1C1[BallStep]: the layer count a brick must have for
; the ball to touch it at this step (5, 4, 3, 2, 1, 8, 7, 6 for steps 0-7). HL
; = BrickLayers $AAD7 + the cell $AA44 (8 layers when the level is built,
; $D180); the address goes to $AA07, the count to $AA0B. No contact (count not
; B): return NZ.
;
; Contact: the screen address of the layer ($AA03 - $2002, wrapped into the CPC
; screen) goes to $AB31, BallState becomes 4 (down). At step 5 (an intact
; brick) a hammer is needed: Hammers $AAFF - 1 and the HUD ($E5E6); without one
; ($B952) BallStep becomes 3 and the brick is untouched. Else BallStep becomes
; 8 - step (the way down mirrors the way up), the crumble animation starts
; ($AB33 = 1, step $AB34 = 0, BrickStep $BE94), the layer count goes down by
; one and at 0 the cell's platform becomes 0 (the brick is gone). Witness: 369
; contacts in the recordings, 47 at step 5 (each with a hammer), 46 bricks
; gone.
;
; Witness: L1 1837 (l51, l59, l96, l98, rzx x27).
HitBrick:
  AND A
  LD HL,BrickSteps
  LD A,(BallStep)
  LD D,$00
  LD E,A
  ADD HL,DE
  LD A,(HL)
  LD B,A
  LD HL,BrickLayers
  LD A,(BallCell)
  LD D,$00
  LD E,A
  ADD HL,DE
  LD (CellIndex),HL
  LD A,(HL)
  LD (CellByte),A
  SUB B
  CP $00
  RET NZ
HitBrickContact:
  LD HL,(BallScrAddr)
  LD BC,$DFFE
  ADD HL,BC
  LD A,H
  CP $C0
  JR NC,HitBrickDown
  LD BC,$3FB0
  ADD HL,BC
HitBrickDown:
  LD (BrickLayerAddr),HL
  AND A
  LD A,$04
  LD (BallState),A
  LD A,(BallStep)
  CP $05
  JR NZ,HitBrickMirror
  LD A,(Hammers)
  CP $00
  JR Z,HitBrickNoHammer
  DEC A
  LD (Hammers),A
  CALL HammersToHud
HitBrickMirror:
  AND A
  LD A,(BallStep)
  CP $00
  JR Z,HitBrickMirrorSkip
  LD B,A
  LD A,$08
  SUB B
HitBrickMirrorSkip:
  LD (BallStep),A
  LD A,$01
  LD (BrickActive),A
  LD A,$00
  LD (BrickAnimStep),A
HitBrickLayer:
  LD A,(CellByte)
  DEC A
  LD HL,(CellIndex)
  LD (HL),A
  CP $00
  RET NZ
  LD A,(BallCell)
  LD D,$00
  LD E,A
  LD HL,CellPlatforms
  ADD HL,DE
  LD (HL),$00
  RET
HitBrickNoHammer:
  LD A,$03                ; never run: no hammer, the ball just turns back
  LD (BallStep),A
  RET

  ORG $C4E2

; The ball's picture for each of the 16 steps of the move right
;
; MoveRight's draw ($B882) sets the ball sprite $AA01 =
; BallFramesRight[BallStep]: the 15 rolling frames $6810-$6A40 (40 bytes
; apart), then the round ball $67E8 at step 15. Read 16 359 times in the
; recordings.
BallFramesRight:
  DEFW $6810,$6838,$6860,$6888,$68B0,$68D8,$6900,$6928,$6950,$6978,$69A0,$69C8,$69F0,$6A18,$6A40,BallPictures

; The ball's picture for each of the 16 steps of the move left
;
; The same frames in the reverse order ($6A40 down to $6810, then $67E8), read
; by $B8A2 for the move left (13 276 times).
BallFramesLeft:
  DEFW $6A40,$6A18,$69F0,$69C8,$69A0,$6978,$6950,$6928,$6900,$68D8,$68B0,$6888,$6860,$6838,$6810,BallPictures

; The four pictures of the flames on a burning platform
;
; $BD21 draws FireFrames[$AA0F - 1] ($80D5, $80F3, $8111, $812F; 30 bytes
; apart, 5 lines of 6 bytes) with ink $5E at the burning cell, every second
; frame (5672 times).
FireFrames:
  DEFW ExitFrames,$80F3,$8111,$812F

; The spring-press records of platform types 1-5 (24 bytes each at SpringPics)
;
; LoadSpring $BD73 copies the record of the ball's platform type (1-5) to $AB35
; when the up key or fire arms the spring. The records are at SpringPics $C5D6.
SpringCurves:
  DEFW SpringPics,SpringPics2,SpringPics3,SpringPics4,SpringPics5

  ORG $C5CC

; The take-off picture record of platform types 1-5 (18 bytes each at
; TakeoffPics)
;
; LeftTakeoff $C890 and RightTakeoff $CAD6 copy TakeoffTable[type - 1]'s record
; to $AB4D.
TakeoffTable:
  DEFW TakeoffPics,TakeoffPics2,TakeoffPics3,TakeoffPics4,TakeoffPics5

; The spring-press records of platform types 1-5, 24 bytes each
;
; Each record is four pictures, the frames of the platform pressed by the
; bouncing ball: four screen offsets from the cell's address (words), four
; picture addresses (words), four widths in bytes, four heights in lines. Type
; 1: offsets 0, $F800, $2FB0, $2FB0; pictures $7788, $7848, $7880, $78C8.
; LoadSpring $BD73 copies one to $AB35; $BDA6-$BDCE draw its frames.
SpringPics:
SpringPics1:
  DEFB $00,$00,$00,$F8,$B0,$2F,$B0,$2F,$88,$77,$48,$78,$80,$78,$C8,$78,$08,$08,$08,$08,$04,$07,$09,$07 ; type 1,
                                                                                                       ; the plain
                                                                                                       ; platform
SpringPics2:
  DEFB $00,$00,$00,$F8,$B0,$2F,$B0,$2F,$00,$79,$C0,$79,$F8,$79,$40,$7A,$08,$08,$08,$08,$04,$07,$09,$07 ; type 2,
                                                                                                       ; crumbling
                                                                                                       ; (first
                                                                                                       ; stage)
SpringPics3:
  DEFB $01,$00,$01,$F8,$01,$F8,$01,$F8,$78,$7A,$F0,$7A,$14,$7B,$3E,$7B,$06,$06,$06,$06,$04,$06,$07,$06 ; type 3,
                                                                                                       ; crumbling
                                                                                                       ; (second
                                                                                                       ; stage)
SpringPics4:
  DEFB $02,$00,$02,$00,$02,$00,$02,$F8,$62,$7B,$A2,$7B,$B6,$7B,$CE,$7B,$04,$04,$04,$04,$04,$05,$06,$05 ; type 4,
                                                                                                       ; crumbling
                                                                                                       ; (last
                                                                                                       ; stage)
SpringPics5:
  DEFB $00,$00,$00,$F8,$B0,$2F,$B0,$2F,$E2,$7B,$A2,$7C,$DA,$7C,$22,$7D,$08,$08,$08,$08,$04,$07,$09,$07 ; type 5,
                                                                                                       ; the
                                                                                                       ; stopping
                                                                                                       ; platform

; The take-off records of platform types 1-5, 18 bytes each
;
; Each record is three pictures: three screen offsets from the cell's address
; (words), three picture addresses (words), three widths, three heights.
; Picture 0 is the platform itself, picture 1 the one drawn when the ball
; leaves it to the left (the same picture as the conveyor 6, $77A8 for type 1),
; picture 2 the one for the right ($77F8, as the conveyor 7). $BE43 draws
; picture 0, $BE5E picture 1, $BE79 picture 2, all by XOR, so step 5 of the
; move draws them again to undo them.
TakeoffPics:
TakeoffPics1:
  DEFB $00,$00,$B0,$27,$B0,$27,$88,$77,$A8,$77,$F8,$77,$08,$08,$08,$04,$0A,$0A ; type 1
TakeoffPics2:
  DEFB $00,$00,$B0,$27,$B0,$27,$00,$79,$20,$79,$70,$79,$08,$08,$08,$04,$0A,$0A ; type 2
TakeoffPics3:
  DEFB $01,$00,$B1,$2F,$B1,$2F,$78,$7A,$90,$7A,$C0,$7A,$06,$06,$06,$04,$08,$08 ; type 3
TakeoffPics4:
  DEFB $02,$00,$02,$F8,$02,$F8,$62,$7B,$72,$7B,$8A,$7B,$04,$04,$04,$04,$06,$06 ; type 4
TakeoffPics5:
  DEFB $00,$00,$B0,$27,$B0,$27,$E2,$7B,$02,$7C,$52,$7C,$08,$08,$08,$04,$0A,$0A ; type 5

; Step 0 of the move left: the handler for each platform type 0-12 the ball
; leaves
;
; LeftStep0 $C847 jumps to LeftTakeoffTable[$AB1C]: 1 and 5 LeftTakeoff, 2-4
; LeftCrumble2-4, the others the plain step $AEE2.
LeftTakeoffTable:
  DEFW BallLeftMove,LeftTakeoff,LeftCrumble2,LeftCrumble3,LeftCrumble4,LeftTakeoff,BallLeftMove,BallLeftMove,BallLeftMove,BallLeftMove,BallLeftMove,BallLeftMove,BallLeftMove

; Step 0 of the move right: the handler for each platform type 0-12
;
; RightStep0 $CA8D: 1 and 5 RightTakeoff, 2-4 RightCrumble2-4, the others
; $AF5C.
RightTakeoffTable:
  DEFW BallRightMove,RightTakeoff,RightCrumble2,RightCrumble3,RightCrumble4,RightTakeoff,BallRightMove,BallRightMove,BallRightMove,BallRightMove,BallRightMove,BallRightMove,BallRightMove

; Step 0 of the jump: the handler for each platform type 0-12
;
; UpStep0 $CCD0: 1 and 5 UpSpringRelease, 2-4 UpCrumble2-4, the others $AFD6.
UpTakeoffTable:
  DEFW BallUpMove,UpSpringRelease,UpCrumble2,UpCrumble3,UpCrumble4,UpSpringRelease,BallUpMove,BallUpMove,BallUpMove,BallUpMove,BallUpMove,BallUpMove,BallUpMove

  ORG $C778

; Bounce in place, step 0: the landing sound, then the handler of the platform
; type
;
; The first handler of BounceSteps $AE9B. If $ABA7 is 4 (a fire was just put
; out) it is cleared and no sound plays; otherwise when the cell below holds
; bricks ($0A) or the ball's cell has a platform ($AB1C not 0), $ABA7 = 1 and
; the bounce sound $F3C8 plays. Then it jumps to BounceTypeTable[$AB1C] $C82D:
; types 2-4 start crumbling the platform, the others go to the state's tail
; $AE65.
;
; Witness: L1 1199 (c1, fire, gameover, menu, twoname, l x11, rzx x94).
BounceStep0:
  LD A,(ObjectFlag)
  CP $04
  JR Z,BounceQuiet
  AND A
  LD A,(BallCell)
  ADD A,$06
  LD D,$00
  LD E,A
  LD HL,CellPlatforms
  ADD HL,DE
  LD A,(HL)
  CP $0A
  JR Z,BounceSound
  AND A
  LD A,(CellPlatform)
  CP $00
  JR Z,BounceDispatch
BounceSound:
  LD A,$01
  LD (ObjectFlag),A
  CALL SfxLand
BounceDispatch:
  AND A
  LD A,(CellPlatform)
  RLA
  LD D,$00
  LD E,A
  LD IX,BounceTypeTable
  ADD IX,DE
  LD D,(IX+$01)
  LD E,(IX+$00)
  PUSH DE
  POP IX
  JP (IX)
BounceQuiet:
  LD A,$00
  LD (ObjectFlag),A
  JR BounceDispatch

; Bounce on a type-2 platform: it starts turning into type 3
;
; Calls $C3D5 (CrumbleSteps2), then the tail $AE65.
;
; Witness: L1 80 (l45, l56, l68, rzx x27).
BounceCrumble2:
  CALL StartWearTo3
  JP BallBounceMove

; Bounce on a type-3 platform: it starts turning into type 4
;
; Calls $C3F8 (CrumbleSteps3), then $AE65.
;
; Witness: L1 102 (l36, l45, l56, l68, rzx x38).
BounceCrumble3:
  CALL StartWearTo4
  JP BallBounceMove

; Bounce on a type-4 platform: it starts vanishing
;
; Calls $C41B (CrumbleSteps4), then $AE65.
;
; Witness: L1 210 (l x6, rzx x55).
BounceCrumble4:
  CALL StartFallAway
  JP BallBounceMove

; Bounce, step 1: start the crumble animation if one is pending
;
; If $AA14 is set (a crumble was started at step 0), $AA15 = $AA14, which lets
; $C19D play it. Then $AE65.
;
; Witness: L1 1197 (c1, fire, gameover, menu, twoname, l x11, rzx x94).
BounceStep1:
  LD A,(CrumblePending)
  CP $00
  JP Z,BallBounceMove
  LD (CrumbleActive),A

; Bounce, steps 2-8: nothing but the tail
;
; Jumps to $AE65; also the end of BounceStep1.
;
; Witness: L1 8710 (c1, fire, gameover, menu, twoname, l x11, rzx x94).
BounceStepIdle:
  JP BallBounceMove

; Bounce, step 9: arm the spring and draw its first frame
;
; In the demo ($ABA6 not 0) the spring is armed when the next demo move ($ABA4
; + 1) is 9; in play when $B463 finds up or fire pressed. Arming calls
; LoadSpring $BD73. If SpringArmed $AA13, $BDA6 draws the first press frame.
; Then $AE65.
;
; Witness: L1 1182 (c1, fire, gameover, menu, twoname, l x11, rzx x94).
BounceStep9:
  LD A,(DemoFlag)
  CP $00
  JR Z,BounceArmByKey
  LD HL,(DemoInputPtr)
  INC HL
  LD A,(HL)
  CP $09
  CALL Z,LoadSpring
  JR BounceSpringFrame
BounceArmByKey:
  CALL TestUpOrFire
  CALL NZ,LoadSpring
BounceSpringFrame:
  AND A
  LD A,(SpringArmed)
  CP $00
  CALL NZ,SpringStep1

; Bounce, step 10: nothing but the tail
;
; Witness: L1 2364 (c1, fire, gameover, menu, twoname, l x11, rzx x94).
BounceStep10:
  JP BallBounceMove

; Bounce, step 11: the second spring frame
;
; If SpringArmed, $BDAE draws it. Then $AE65.
;
; Witness: L1 1182 (c1, fire, gameover, menu, twoname, l x11, rzx x94).
BounceStep11:
  LD A,(SpringArmed)
  CP $00
  CALL NZ,SpringStep2

; Bounce, step 12: nothing but the tail
;
; Witness: L1 2364 (c1, fire, gameover, menu, twoname, l x11, rzx x94).
BounceStep12:
  JP BallBounceMove

; Bounce, step 13: take the object in the cell
;
; Calls TakeObject $B958, then $AE65.
;
; Witness: L1 1182 (c1, fire, gameover, menu, twoname, l x11, rzx x94).
BounceStep13:
  CALL TakeObject
  JP BallBounceMove

; Bounce, step 14: the third spring frame
;
; If SpringArmed, $BDB6. Then $AE65.
;
; Witness: L1 1182 (c1, fire, gameover, menu, twoname, l x11, rzx x94).
BounceStep14:
  LD A,(SpringArmed)
  CP $00
  CALL NZ,SpringStep3
  JP BallBounceMove

; Bounce, step 15: the last spring frame
;
; If SpringArmed, $BDBE. Then $AE65, whose end at step 15 calls ChooseNextState
; $B7E4.
;
; Witness: L1 1181 (c1, fire, gameover, menu, twoname, l x11, rzx x94).
BounceStep15:
  LD A,(SpringArmed)
  CP $00
  CALL NZ,SpringStep4
  JP BallBounceMove

; Bounce step 0: the handler for each platform type 0-12
;
; Types 2, 3, 4 BounceCrumble2-4, the others the tail $AE65. Only types 0-4 are
; read: the ball never bounces in place on the others (5 stops it, 6 and 7 push
; it, 8, 9 and 12 kill it, 10 and 11 end its moves another way).
BounceTypeTable:
  DEFW BallBounceMove,BallBounceMove,BounceCrumble2,BounceCrumble3,BounceCrumble4,BallBounceMove,BallBounceMove,BallBounceMove,BallBounceMove,BallBounceMove,BallBounceMove,BallBounceMove,BallBounceMove

; Move left, step 0: the sound, then the handler of the platform the ball
; leaves
;
; As BounceStep0 (the $ABA7 and $F3C8 sound rule), then it jumps to
; LeftTakeoffTable[$AB1C] $C6A8.
;
; Witness: L1 992 (c1, fire, gameover, menu, twoname, l x11, rzx00-rzx17,
; rzx21-rzx81, rzx83-rzx86, rzx88-rzx99).
LeftStep0:
  LD A,(ObjectFlag)
  CP $04
  JR Z,LeftQuiet
  AND A
  LD A,(BallCell)
  ADD A,$06
  LD D,$00
  LD E,A
  LD HL,CellPlatforms
  ADD HL,DE
  LD A,(HL)
  CP $0A
  JR Z,LeftSound
  AND A
  LD A,(CellPlatform)
  CP $00
  JR Z,LeftDispatch
LeftSound:
  LD A,$01
  LD (ObjectFlag),A
  CALL SfxLand
LeftDispatch:
  AND A
  LD A,(CellPlatform)
  RLA
  LD D,$00
  LD E,A
  LD IX,LeftTakeoffTable
  ADD IX,DE
  LD D,(IX+$01)
  LD E,(IX+$00)
  PUSH DE
  POP IX
  JP (IX)
LeftQuiet:
  LD A,$00
  LD (ObjectFlag),A
  JR LeftDispatch

; Leave a platform of type 1-5 to the left: draw it tilted
;
; Copies TakeoffTable[$AB1C - 1]'s 18-byte record to $AB4D, draws picture 0
; ($BE43) and picture 1 ($BE5E) by XOR, sets $A9FD = 1 (to be undone at step
; 5), then the left tail $AEE2.
;
; Witness: L1 553 (c1, fire, gameover, menu, twoname, l x11, rzx x85).
LeftTakeoff:
  LD A,(CellPlatform)
  RLA
  LD B,$02
  SUB B
  LD E,A
  LD D,$00
  LD IX,TakeoffTable
  ADD IX,DE
  LD H,(IX+$01)
  LD L,(IX+$00)
  LD DE,TakeoffRecord
  LD BC,$0012
  LDIR
  CALL TiltPart0
  CALL TiltPart1
  LD A,$01
  LD (TakeoffDrawn),A
  JP BallLeftMove

; Leave a type-2 platform to the left: start its crumbling
;
; Unless a crumble is already playing ($AA15), calls $C3D5, then LeftTakeoff;
; else the tail.
;
; Witness: L1 41 (menu, l10, l35, l51, l68, rzx x20).
LeftCrumble2:
  LD A,(CrumbleActive)
  CP $00
  JP NZ,BallLeftMove
  CALL StartWearTo3
  JP LeftTakeoff

; Leave a type-3 platform to the left
;
; As LeftCrumble2 with $C3F8.
;
; Witness: L1 84 (l x8, rzx x41).
LeftCrumble3:
  LD A,(CrumbleActive)
  CP $00
  JP NZ,BallLeftMove
  CALL StartWearTo4
  JP LeftTakeoff

; Leave a type-4 platform to the left
;
; As LeftCrumble2 with $C41B.
;
; Witness: L1 142 (l x7, rzx x58).
LeftCrumble4:
  LD A,(CrumbleActive)
  CP $00
  JP NZ,BallLeftMove
  CALL StartFallAway
  JP LeftTakeoff

; Move left, steps 1-4: the tail only
;
; Witness: L1 3968 (c1, fire, gameover, menu, twoname, l x11, rzx00-rzx17,
; rzx21-rzx81, rzx83-rzx86, rzx88-rzx99).
LeftStepIdle:
  JP BallLeftMove

; Move left, step 5: undo the take-off pictures and meet the wall on the left
;
; If $A9FD, picture 1 and 0 are XORed off and $A9FD = 0. A pending crumble
; starts ($AA15 = $AA14). Then the screen byte left of the ball ($AA03, through
; ScreenAddrToLine and $B515, column (ByteColumn - 2) / 2) is read: 0 means no
; wall, the move goes on. The pattern $7C (wall type 4), or no key (Keys $AAFE
; = 0), or a wall type that is no lock: sound $F43E and the ball turns back
; (LeftBounceBack). A lock (wall $AA8F[$AA44 - 1] of type 1-3) with a key: the
; lock becomes type - 1, its animation (LockOpenSteps1-3) starts at the wall's
; place ($AB2D + $2EBE), Keys - 1 (HUD $E5D3), and the ball turns back too.
;
; Witness: L1 992 (c1, fire, gameover, menu, twoname, l x11, rzx00-rzx17,
; rzx21-rzx81, rzx83-rzx86, rzx88-rzx99).
LeftStep5:
  LD A,(TakeoffDrawn)
  CP $00
  JP Z,LeftPendingCrumble
  CALL TiltPart1
  CALL TiltPart0
  LD A,$00
  LD (TakeoffDrawn),A
LeftPendingCrumble:
  LD A,(CrumblePending)
  CP $00
  JP Z,LeftWallCheck
  LD (CrumbleActive),A
LeftWallCheck:
  AND A
  LD HL,(BallScrAddr)
  PUSH IX
  CALL ScreenAddrToLine
  CALL LineAddress
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD A,(ByteColumn)
  SUB $02
  SRL A
  OR L
  LD L,A
  POP IX
  LD A,(HL)
  CP $00
  JP Z,BallLeftMove
  CP $7C
  JP Z,LeftWallBlocked
  AND A
  LD A,(Keys)
  CP $00
  JP Z,LeftWallBlocked
  AND A
  LD A,(BallCell)
  DEC A
  PUSH AF
  CALL WallScreenAddr
  POP AF
  LD D,$00
  LD E,A
  LD HL,CellWalls
  ADD HL,DE
  LD A,(HL)
  CP $01
  JR Z,LeftOpenLock1
  CP $02
  JR Z,LeftOpenLock2
  CP $03
  JR Z,LeftOpenLock3
  JR LeftWallBlocked
LeftOpenLock1:
  LD (HL),$00
  LD HL,LockOpenSteps1
  LD (LockAnimSteps),HL
  JR LeftUseKey
LeftOpenLock2:
  LD (HL),$01
  LD HL,LockOpenSteps2
  LD (LockAnimSteps),HL
  JR LeftUseKey
LeftOpenLock3:
  LD (HL),$02
  LD HL,LockOpenSteps3
  LD (LockAnimSteps),HL
LeftUseKey:
  AND A
  LD A,(Keys)
  DEC A
  LD (Keys),A
  CALL KeysToHud
  AND A
  LD HL,(CellScrAddr)
  LD BC,$2EBE
  ADD HL,BC
  LD (LockAnimAddr),HL
  LD A,$01
  LD (LockActive),A
  LD A,$00
  LD (LockStep),A
; This entry point is used by the routine at LeftWallBlocked.
LeftBounceBack:
  AND A                   ; BallStep = 11, BallState = 2: the ball comes back
                          ; to its cell moving right
  LD A,$0B
  LD (BallStep),A
  LD A,$02
  LD (BallState),A
  JP BallRightMove

; LeftWallBlocked
;
; Used by the routine at LeftStep5.
LeftWallBlocked:
  CALL SfxWallBounce      ; the bump sound $F43E
  JR LeftBounceBack

; Move left, steps 6 and 7: the tail only
;
; Witness: L1 1758 (c1, fire, gameover, menu, l x11, rzx x94).
LeftStepIdle2:
  JP BallLeftMove

; Move left, step 8: enter the cell on the left, unless bricks fill it
;
; If the brick counter $AAD7[$AA44 - 1] is not 0 the ball turns right
; (BallState 2) and stays in its cell; else $AA44 - 1.
;
; Witness: L1 879 (c1, fire, gameover, menu, l x11, rzx x94).
LeftStep8:
  LD A,(BallCell)
  DEC A
  LD D,$00
  LD E,A
  LD (CellByte),A
  LD HL,BrickLayers
  ADD HL,DE
  LD A,(HL)
  CP $00
  JR Z,LeftEnterCell
  LD A,$02
  LD (BallState),A
  JP BallRightMove
LeftEnterCell:
  LD A,(CellByte)
  LD (BallCell),A
  JP BallLeftMove

; Move left, step 9: arm the spring, put out a fire
;
; The spring as at BounceStep9 (demo move 9 or $B463, LoadSpring, $BDA6). If
; the platform $AB1C is on fire (8 or 9) and the ball holds a drop (Water
; $AAFD), Water - 1 (HUD $E5C0), $ABA7 = 4 and FireOutLeft starts at the cell's
; screen address (from $E131). Then $AEE2.
;
; Witness: L1 884 (c1, fire, gameover, menu, l x11, rzx x94).
LeftStep9:
  LD A,(DemoFlag)
  CP $00
  JR Z,LeftArmByKey
  LD HL,(DemoInputPtr)
  INC HL
  LD A,(HL)
  CP $09
  CALL Z,LoadSpring
  JR LeftSpringFrame
LeftArmByKey:
  CALL TestUpOrFire
  CALL NZ,LoadSpring
LeftSpringFrame:
  AND A
  LD A,(SpringArmed)
  CP $00
  CALL NZ,SpringStep1
  LD A,(CellPlatform)
  CP $08
  JR Z,LeftPutOutFire
  AND A
  CP $09
  JP NZ,BallLeftMove
LeftPutOutFire:
  LD A,(Water)
  CP $00
  JP Z,BallLeftMove
  DEC A
  LD (Water),A
  CALL WaterToHud
  LD A,$04
  LD (ObjectFlag),A
  AND A
  LD A,(BallCell)
  RLA
  LD E,A
  LD D,$00
  LD IX,CellAddresses
  ADD IX,DE
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD (FireOutAddr),HL
  LD A,$01
  LD (FireOutActive),A
  LD HL,FireOutLeft
  LD (FireOutSteps),HL
  LD A,$00
  LD (FireOutStep),A

; Move left, step 10: the tail only
;
; Witness: L1 896 (c1, fire, gameover, menu, l x11, rzx x94).
LeftStep10:
  JP BallLeftMove

; Move left, step 11: the second spring frame
;
; Witness: L1 884 (c1, fire, gameover, menu, l x11, rzx x94).
LeftStep11:
  LD A,(SpringArmed)
  CP $00
  CALL NZ,SpringStep2

; Move left, step 12: the tail only
;
; Witness: L1 1930 (c1, fire, gameover, menu, l x11, rzx00-rzx18, rzx21-rzx81,
; rzx83-rzx86, rzx88-rzx99).
LeftStep12:
  JP BallLeftMove

; Move left, step 13: take the object
;
; Witness: L1 1046 (c1, fire, gameover, menu, l x11, rzx00-rzx18, rzx21-rzx81,
; rzx83-rzx86, rzx88-rzx99).
LeftStep13:
  CALL TakeObject
  JP BallLeftMove

; Move left, step 14: the third spring frame
;
; Witness: L1 1046 (c1, fire, gameover, menu, l x11, rzx00-rzx18, rzx21-rzx81,
; rzx83-rzx86, rzx88-rzx99).
LeftStep14:
  LD A,(SpringArmed)
  CP $00
  CALL NZ,SpringStep3
  JP BallLeftMove

; Move left, step 15: the last spring frame, then death on fire or spikes
;
; If SpringArmed, $BDBE. Landing on a platform of type 8 or 9 (still burning:
; no water was left at step 9) plays $F483 and kills (stage2/rec/fire: level
; 38, Water POKEd to 0, left onto cell 31); type 12 (spikes) plays $F4B4 and
; kills: the ball is drawn at the step offsets $AF35 and the burst state begins
; ($B0ED). Otherwise the tail $AEE2. Witness: the spike death ran once
; (LeftSpikeDeath); the fire death once, in stage2/rec/fire (LeftFireDeath).
;
; Witness: L1 1046 (c1, fire, gameover, menu, l x11, rzx00-rzx18, rzx21-rzx81,
; rzx83-rzx86, rzx88-rzx99).
LeftStep15:
  LD A,(SpringArmed)
  CP $00
  CALL NZ,SpringStep4
  LD A,(CellPlatform)
  CP $08
  JR Z,LeftFireDeath
  AND A
  CP $09
  JR Z,LeftFireDeath
  AND A
  CP $0C
  JP Z,LeftSpikeDeath
  AND A
  JP BallLeftMove
LeftSpikeDeath:
  CALL SfxSpikeDeath      ; the spike sound
  JR LeftDeath
LeftFireDeath:
  CALL SfxFireDeath       ; the fire sound (stage2/rec/fire)
LeftDeath:
  AND A
  LD IX,LeftOffsets
  LD A,$04
  LD (SpriteWidth),A
  CALL BallStepMove
  JP BallBurstStart

; Move right, step 0: the sound, then the handler of the platform the ball
; leaves
;
; The mirror of LeftStep0, through RightTakeoffTable $C6C2.
;
; Witness: L1 1258 (c1, gameover, menu, twoname, l x12, rzx00-rzx99).
RightStep0:
  LD A,(ObjectFlag)
  CP $04
  JR Z,RightQuiet
  AND A
  LD A,(BallCell)
  ADD A,$06
  LD D,$00
  LD E,A
  LD HL,CellPlatforms
  ADD HL,DE
  LD A,(HL)
  CP $0A
  JR Z,RightSound
  AND A
  LD A,(CellPlatform)
  CP $00
  JR Z,RightDispatch
RightSound:
  LD A,$01
  LD (ObjectFlag),A
  CALL SfxLand
RightDispatch:
  AND A
  LD A,(CellPlatform)
  RLA
  LD D,$00
  LD E,A
  LD IX,RightTakeoffTable
  ADD IX,DE
  LD D,(IX+$01)
  LD E,(IX+$00)
  PUSH DE
  POP IX
  JP (IX)
RightQuiet:
  LD A,$00
  LD (ObjectFlag),A
  JR RightDispatch

; Leave a platform of type 1-5 to the right: draw it tilted
;
; As LeftTakeoff with picture 2 ($BE79), then the right tail $AF5C.
;
; Witness: L1 648 (c1, gameover, menu, twoname, l x12, rzx x89).
RightTakeoff:
  LD A,(CellPlatform)
  RLA
  LD B,$02
  SUB B
  LD E,A
  LD D,$00
  LD IX,TakeoffTable
  ADD IX,DE
  LD H,(IX+$01)
  LD L,(IX+$00)
  LD DE,TakeoffRecord
  LD BC,$0012
  LDIR
  CALL TiltPart0
  CALL TiltPart2
  LD A,$01
  LD (TakeoffDrawn),A
  JP BallRightMove

; Leave a type-2 platform to the right
;
; Witness: L1 46 (l x5, rzx x19).
RightCrumble2:
  LD A,(CrumbleActive)
  CP $00
  JP NZ,BallRightMove
  CALL StartWearTo3
  JP RightTakeoff

; Leave a type-3 platform to the right
;
; Witness: L1 80 (menu, l x7, rzx x36).
RightCrumble3:
  LD A,(CrumbleActive)
  CP $00
  JP NZ,BallRightMove
  CALL StartWearTo4
  JP RightTakeoff

; Leave a type-4 platform to the right
;
; Witness: L1 183 (l x7, rzx x61).
RightCrumble4:
  LD A,(CrumbleActive)
  CP $00
  JP NZ,BallRightMove
  CALL StartFallAway
  JP RightTakeoff

; Move right, steps 1-4: the tail only
;
; Witness: L1 5032 (c1, gameover, menu, twoname, l x12, rzx00-rzx99).
RightStepIdle:
  JP BallRightMove

; Move right, step 5: undo the take-off pictures and meet the wall on the right
;
; The mirror of LeftStep5: the screen byte at column (ByteColumn + 3) / 2, the
; pattern $3E for wall type 4, the wall $AA8F[$AA44], the animation at $AB2D +
; $2EC8; the ball turns back to the left (BallState 1, BallStep 11).
;
; Witness: L1 1258 (c1, gameover, menu, twoname, l x12, rzx00-rzx99).
RightStep5:
  LD A,(TakeoffDrawn)
  CP $00
  JP Z,RightPendingCrumble
  CALL TiltPart2
  CALL TiltPart0
  LD A,$00
  LD (TakeoffDrawn),A
RightPendingCrumble:
  LD A,(CrumblePending)
  CP $00
  JP Z,RightWallCheck
  LD (CrumbleActive),A
RightWallCheck:
  LD HL,(BallScrAddr)
  PUSH IX
  CALL ScreenAddrToLine
  CALL LineAddress
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD A,(ByteColumn)
  ADD A,$03
  SRL A
  OR L
  LD L,A
  POP IX
  LD A,(HL)
  CP $00
  JP Z,BallRightMove
  CP $3E
  JP Z,RightWallBlocked
  AND A
  LD A,(Keys)
  CP $00
  JP Z,RightWallBlocked
  LD A,(BallCell)
  PUSH AF
  CALL WallScreenAddr
  POP AF
  LD D,$00
  LD E,A
  LD HL,CellWalls
  ADD HL,DE
  LD A,(HL)
  CP $01
  JR Z,RightOpenLock1
  CP $02
  JR Z,RightOpenLock2
  CP $03
  JR Z,RightOpenLock3
  JR RightWallBlocked
RightOpenLock1:
  LD (HL),$00
  LD HL,LockOpenSteps1
  LD (LockAnimSteps),HL
  JR RightUseKey
RightOpenLock2:
  LD (HL),$01
  LD HL,LockOpenSteps2
  LD (LockAnimSteps),HL
  JR RightUseKey
RightOpenLock3:
  LD (HL),$02
  LD HL,LockOpenSteps3
  LD (LockAnimSteps),HL
RightUseKey:
  AND A
  LD A,(Keys)
  DEC A
  LD (Keys),A
  CALL KeysToHud
  AND A
  LD HL,(CellScrAddr)
  LD BC,$2EC8
  ADD HL,BC
  LD (LockAnimAddr),HL
  LD A,$01
  LD (LockActive),A
  LD A,$00
  LD (LockStep),A
RightBounceBack:
  AND A                   ; BallStep = 11, BallState = 1
  LD A,$0B
  LD (BallStep),A
  LD A,$01
  LD (BallState),A
  JP BallLeftMove
RightWallBlocked:
  CALL SfxWallBounce      ; the bump sound $F43E
  JR RightBounceBack

; Move right, steps 6 and 7: the tail only
;
; Witness: L1 2192 (c1, gameover, menu, twoname, l x12, rzx00-rzx99).
RightStepIdle2:
  JP BallRightMove

; Move right, step 8: enter the cell on the right, unless bricks fill it
;
; Witness: L1 1096 (c1, gameover, menu, twoname, l x12, rzx00-rzx99).
RightStep8:
  LD A,(BallCell)
  INC A
  LD D,$00
  LD E,A
  LD (CellByte),A
  LD HL,BrickLayers
  ADD HL,DE
  LD A,(HL)
  CP $00
  JR Z,RightEnterCell
  LD A,$01
  LD (BallState),A
  JP BallLeftMove
RightEnterCell:
  LD A,(CellByte)
  LD (BallCell),A
  JP BallRightMove

; Move right, step 9: arm the spring, put out a fire
;
; As LeftStep9 with FireOutRight.
;
; Witness: L1 1091 (c1, gameover, menu, twoname, l x12, rzx00-rzx99).
RightStep9:
  LD A,(DemoFlag)
  CP $00
  JR Z,RightArmByKey
  LD HL,(DemoInputPtr)
  INC HL
  LD A,(HL)
  CP $09
  CALL Z,LoadSpring
  JR RightSpringFrame
RightArmByKey:
  CALL TestUpOrFire
  CALL NZ,LoadSpring
RightSpringFrame:
  AND A
  LD A,(SpringArmed)
  CP $00
  CALL NZ,SpringStep1
  LD A,(CellPlatform)
  CP $08
  JR Z,RightPutOutFire
  AND A
  CP $09
  JP NZ,BallRightMove
RightPutOutFire:
  LD A,(Water)
  CP $00
  JP Z,BallRightMove
  DEC A
  LD (Water),A
  CALL WaterToHud
  LD A,$04
  LD (ObjectFlag),A
  AND A
  LD A,(BallCell)
  RLA
  LD E,A
  LD D,$00
  LD IX,CellAddresses
  ADD IX,DE
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD (FireOutAddr),HL
  LD A,$01
  LD (FireOutActive),A
  LD HL,FireOutRight
  LD (FireOutSteps),HL
  LD A,$00
  LD (FireOutStep),A

; Move right, step 10: the tail only
;
; Witness: L1 1116 (c1, gameover, menu, twoname, l x12, rzx00-rzx99).
RightStep10:
  JP BallRightMove

; Move right, step 11: the second spring frame
;
; Witness: L1 1091 (c1, gameover, menu, twoname, l x12, rzx00-rzx99).
RightStep11:
  LD A,(SpringArmed)
  CP $00
  CALL NZ,SpringStep2

; Move right, step 12: the tail only
;
; Witness: L1 2294 (c1, gameover, menu, twoname, l x12, rzx00-rzx99).
RightStep12:
  JP BallRightMove

; Move right, step 13: take the object
;
; Witness: L1 1203 (c1, gameover, menu, twoname, l x12, rzx00-rzx99).
RightStep13:
  CALL TakeObject
  JP BallRightMove

; Move right, step 14: the third spring frame
;
; Witness: L1 1203 (c1, gameover, menu, twoname, l x12, rzx00-rzx99).
RightStep14:
  LD A,(SpringArmed)
  CP $00
  CALL NZ,SpringStep3
  JP BallRightMove

; Move right, step 15: the last spring frame, then death on fire or spikes
;
; As LeftStep15 with the offsets $AFAF. Neither death ran in the recordings
; (known only from the code).
;
; Witness: L1 1203 (c1, gameover, menu, twoname, l x12, rzx00-rzx99).
RightStep15:
  LD A,(SpringArmed)
  CP $00
  CALL NZ,SpringStep4
  LD A,(CellPlatform)
  CP $08
  JR Z,RightFireDeath
  AND A
  CP $09
  JR Z,RightFireDeath
  AND A
  CP $0C
  JP Z,RightSpikeDeath
  AND A
  JP BallRightMove
RightSpikeDeath:
  CALL SfxSpikeDeath      ; the spike sound, never run
  JR RightDeath
RightFireDeath:
  CALL SfxFireDeath       ; the fire sound, never run
RightDeath:
  AND A
  LD IX,RightOffsets
  LD A,$04
  LD (SpriteWidth),A
  CALL BallStepMove
  JP BallBurstStart

; Jump, step 0: the jump sound, the bricks, then the handler of the platform
; left
;
; Unless $ABA7 is 4 (cleared), the jump sound $F3DF plays when the platform
; $AB1C is neither 0 nor bricks ($0A). On bricks $B8D1 counts a hit, which may
; turn the ball down: when BallState is no longer 3, the down handler $B064
; takes over. Then UpTakeoffTable[$AB1C] $C6DC.
;
; Witness: L1 2568 (c1, gameover, menu, twoname, l x12, rzx00-rzx77,
; rzx79-rzx99).
UpStep0:
  LD A,(ObjectFlag)
  CP $04
  JR Z,UpQuiet
  AND A
  LD A,(CellPlatform)
  PUSH AF
  CP $0A
  JR Z,UpNoSound
  CP $00
  CALL NZ,SfxHit
UpNoSound:
  AND A
  POP AF
UpBricks:
  CP $0A
  CALL Z,HitBrick
  LD A,(BallState)
  CP $03
  JP NZ,BallDown
  AND A
  LD A,(CellPlatform)
  RLA
  LD D,$00
  LD E,A
  LD IX,UpTakeoffTable
  ADD IX,DE
  LD D,(IX+$01)
  LD E,(IX+$00)
  PUSH DE
  POP IX
  JP (IX)
UpQuiet:
  LD A,$00
  LD (ObjectFlag),A
  LD A,(CellPlatform)
  AND A
  JR UpBricks

; Jump from a platform of type 1-5: the spring's release frame
;
; If SpringArmed, $BDC6. Then the up tail $AFD6.
;
; Witness: L1 1319 (c1, gameover, menu, twoname, l x12, rzx00-rzx77,
; rzx79-rzx99).
UpSpringRelease:
  LD A,(SpringArmed)
  CP $00
  CALL NZ,SpringStep5
  JP BallUpMove

; Jump from a type-2 platform: it starts crumbling
;
; Witness: L1 83 (menu, l10, l68, l98, rzx x40).
UpCrumble2:
  CALL StartWearTo3
  JP UpSpringRelease

; Jump from a type-3 platform
;
; Witness: L1 119 (l x10, rzx x49).
UpCrumble3:
  CALL StartWearTo4
  JP UpSpringRelease

; Jump from a type-4 platform
;
; Witness: L1 230 (l x10, rzx x71).
UpCrumble4:
  CALL StartFallAway
  JP UpSpringRelease

; Jump, step 1: the bricks check
;
; Every step of the jump calls $B8D1 when the platform is bricks and leaves for
; $B064 when that turned the ball down.
;
; Witness: L1 2516 (c1, gameover, menu, twoname, l x12, rzx00-rzx77,
; rzx79-rzx99).
UpStep1:
  LD A,(CellPlatform)
  CP $0A
  CALL Z,HitBrick
  LD A,(BallState)
  CP $03
  JP NZ,BallDown
  JP BallUpMove

; Jump, step 2: the bricks check
;
; Witness: L1 2463 (c1, gameover, menu, twoname, l x12, rzx00-rzx77,
; rzx79-rzx99).
UpStep2:
  LD A,(CellPlatform)
  CP $0A
  CALL Z,HitBrick
  LD A,(BallState)
  CP $03
  JP NZ,BallDown
  XOR A
  JP BallUpMove

; Jump, step 3: the spring frame, the bricks, start a pending crumble
;
; If SpringArmed, $BDCE; a pending crumble starts ($AA15 = $AA14) and $C19D
; plays two of its steps.
;
; Witness: L1 2412 (c1, gameover, menu, twoname, l x12, rzx00-rzx77,
; rzx79-rzx99).
UpStep3:
  AND A
  LD A,(SpringArmed)
  CP $00
  CALL NZ,SpringStep6
  LD A,(CellPlatform)
  CP $0A
  CALL Z,HitBrick
  LD A,(BallState)
  CP $03
  JP NZ,BallDown
  LD A,(CrumblePending)
  CP $00
  JP Z,BallUpMove
  LD (CrumbleActive),A
  CALL PlatformChangeStep
  CALL PlatformChangeStep
  AND A
  JP BallUpMove

; Jump, step 4: hit the platform above, or pass it
;
; On the top row ($AA44 < 6) the ball turns down ($B00F). Above an empty cell
; or a cell with bricks or the exit (10, 11) it goes on. Spikes (12) above
; kill: sound $F4B4, the burst state 6 at step 3 (UpSpikeDeath, 8 deaths in the
; recordings). Any other platform (1-9) above stops the jump: $B00F turns the
; ball down.
;
; Witness: L1 2361 (c1, gameover, menu, twoname, l x12, rzx00-rzx77,
; rzx79-rzx99).
UpStep4:
  LD A,(CellPlatform)
  CP $0A
  CALL Z,HitBrick
  LD A,(BallState)
  CP $03
  JP NZ,BallDown
  XOR A
  LD A,(CrumbleActive)
  CP $00
  CALL NZ,PlatformChangeStep
  AND A
  LD A,(BallCell)
  LD B,$06
  SUB B
  JP C,BallBumpCeiling
  LD D,$00
  LD E,A
  LD HL,CellPlatforms
  ADD HL,DE
  LD A,(HL)
  CP $00
  JP Z,BallUpMove
  CP $0C
  JR Z,UpSpikeDeath
  CP $0A
  JP NC,BallUpMove
  JP BallBumpCeiling
UpSpikeDeath:
  CALL SfxSpikeDeath      ; the spike sound, BallState 6, BallStep 3
  CALL DrawBallRound
  LD A,$06
  LD (BallState),A
  LD A,$03
  LD (BallStep),A
  JP MainLoop

; Jump, step 5: the ball enters the cell above
;
; $AA44 - 6, and $BB32 reads the new cell's platform and object.
;
; Witness: L1 2202 (c1, menu, l x12, rzx00-rzx77, rzx79-rzx99).
UpStep5:
  LD A,(BallCell)
  LD B,$06
  SUB B
  LD (BallCell),A
  CALL ReadCell
  LD A,(CellPlatform)
  CP $0A
  CALL Z,HitBrick
  LD A,(BallState)
  CP $03
  JP NZ,BallDown
  AND A
  JP BallUpMove

; Jump, step 6: take the object
;
; Witness: L1 2150 (c1, menu, l x12, rzx00-rzx77, rzx79-rzx99).
UpStep6:
  CALL TakeObject
  LD A,(CellPlatform)
  CP $0A
  CALL Z,HitBrick
  LD A,(BallState)
  CP $03
  JP NZ,BallDown
  AND A
  JP BallUpMove

; Jump, step 7: the bricks check; the tail then calls ChooseNextState
;
; Witness: L1 2099 (c1, menu, l x12, rzx00-rzx77, rzx79-rzx99).
UpStep7:
  LD A,(CellPlatform)
  CP $0A
  CALL Z,HitBrick
  LD A,(BallState)
  CP $03
  JP NZ,BallDown
  AND A
  JP BallUpMove

; Fall, step 0: put out a burning platform below with a water drop
;
; If the cell below ($AA44 + 6) has a platform of type 8 or 9 and Water $AAFD
; is not 0: Water - 1, $ABA7 = 4, FireOutDown starts at that cell. Then the
; down tail $B06B.
;
; Witness: L1 2222 (c1, menu, l x12, rzx00-rzx99).
DownStep0:
  AND A
  LD A,(BallCell)
  ADD A,$06
  LD D,$00
  LD E,A
  LD HL,CellPlatforms
  ADD HL,DE
  LD A,(HL)
  CP $08
  JR Z,DownPutOutFire
  AND A
  CP $09
  JR Z,DownPutOutFire
  AND A
  JP BallDownMove
DownPutOutFire:
  LD A,(Water)
  CP $00
  JP Z,BallDownMove
  DEC A
  LD (Water),A
  CALL WaterToHud
  LD A,$04
  LD (ObjectFlag),A
  AND A
  LD A,(BallCell)
  ADD A,$06
  RLA
  LD E,A
  LD D,$00
  LD IX,CellAddresses
  ADD IX,DE
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD (FireOutAddr),HL
  LD A,$01
  LD (FireOutActive),A
  LD HL,FireOutDown
  LD (FireOutSteps),HL
  LD A,$00
  LD (FireOutStep),A

; Fall, steps 1 and 2: the tail only
;
; Witness: L1 4615 (c1, menu, l x12, rzx00-rzx99).
DownStepIdle:
  JP BallDownMove

; Fall, step 3: the ball enters the cell below
;
; $AA44 + 6.
;
; Witness: L1 2376 (c1, menu, l x12, rzx00-rzx99).
DownStep3:
  LD A,(BallCell)
  ADD A,$06
  LD (BallCell),A
  JP BallDownMove

; Fall, step 4: the crumble, the cell, the spring
;
; Plays a step of a pending crumble ($C19D), sets $AB2D and $AB1C for the new
; cell ($BB05, $BB32), arms the spring as at BounceStep9 and draws two press
; frames ($BDA6, $BDAE).
;
; Witness: L1 2527 (c1, gameover, menu, twoname, l x12, rzx00-rzx99).
DownStep4:
  LD A,(CrumbleActive)
  CP $00
  CALL NZ,PlatformChangeStep
  CALL CellScreenAddr
  CALL ReadCell
  LD A,(DemoFlag)
  CP $00
  JR Z,DownArmByKey
  LD HL,(DemoInputPtr)
  INC HL
  LD A,(HL)
  CP $09
  CALL Z,LoadSpring
  JR DownSpringFrame
DownArmByKey:
  CALL TestUpOrFire
  CALL NZ,LoadSpring
DownSpringFrame:
  AND A
  LD A,(SpringArmed)
  CP $00
  CALL NZ,SpringStep1
  AND A
  LD A,(SpringArmed)
  CP $00
  CALL NZ,SpringStep2
  JP BallDownMove

; Fall, step 5: take the object
;
; Witness: L1 2575 (c1, gameover, menu, twoname, l x12, rzx00-rzx99).
DownStep5:
  CALL TakeObject

; Fall, step 6: the tail only
;
; Witness: L1 5201 (c1, gameover, menu, twoname, l x12, rzx00-rzx99).
DownStepIdle2:
  JP BallDownMove

; Fall, step 7: the last spring frames, then death on fire or spikes
;
; $BDB6 and $BDBE if SpringArmed. A platform of type 8 or 9 (no water left at
; step 0) kills with $F483 (never run from here: the fire recording falls in
; from the side); type 12 kills with $F4B4 (4 deaths): the ball drawn at $B10A,
; then the burst ($B0ED).
;
; Witness: L1 2677 (c1, gameover, menu, twoname, l x12, rzx00-rzx99).
DownStep7:
  AND A
  LD A,(SpringArmed)
  CP $00
  CALL NZ,SpringStep3
  AND A
  LD A,(SpringArmed)
  CP $00
  CALL NZ,SpringStep4
  LD A,(CellPlatform)
  CP $08
  JR Z,DownFireDeath
  AND A
  CP $09
  JR Z,DownFireDeath
  AND A
  CP $0C
  JP Z,DownSpikeDeath
  AND A
  JP BallDownMove
DownSpikeDeath:
  CALL SfxSpikeDeath      ; the spike sound
  JR DownDeath
DownFireDeath:
  CALL SfxFireDeath       ; the fire sound, never run
DownDeath:
  AND A
  LD IX,DownOffsets
  LD A,$04
  LD (SpriteWidth),A
  CALL BallStepMove
  JP BallBurstStart

  ORG $E1C1

; The value a brick counter must have at each step 0-7 of a jump for the bricks
; to break
;
; $B8D1 compares $AAD7[cell] with BrickSteps[BallStep]: 5, 4, 3, 2, 1, 8, 7, 6.
BrickSteps:
  INCBIN "res/tables/brick-steps.bin",$0000,8
