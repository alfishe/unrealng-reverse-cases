; --------------------------------------------------------------------------------------------------------------------
; racking.asm: The player variables, the rack scripts and their interpreter
; --------------------------------------------------------------------------------------------------------------------

; HL = the sprite place of record IX: L = x - 7, H = y - 7 (whole parts +1, +3)
;
; Called by the ball redraw task $8297 and Rack $9F6F: game 905, w1 7580.
SpriteFromBall:
  LD A,(IX+$01)
  SUB $07
  LD L,A
  LD A,(IX+$03)
  SUB $07
  LD H,A
  RET

; The players' scores, frames, shots, lives, the message step and the six rack
; script states
;
; The pairs "current, other" ($9F43 / $9F44, $9F4B / $9F4C, $9F4E / $9F4F) are
; swapped by TurnSwap $9C15; the scores stay by player. Set by NewGameScreen
; $95DA; the hi score is 300 (shown 3000) in the image, kept across games.
PlayerVars:
PocketTurn:
  DEFB $00                ; the current player's pocket mark turn 0-5
                          ; (NextFrame - 1, DrawPocketMarks)
PocketTurnOther:
  DEFB $00                ; the other player's
ScorePlayer1:
  DEFB $00,$00            ; word, score / 10
ScorePlayer2:
  DEFB $00,$00            ; word
HiScore:
  DEFB $2C,$01            ; word, 300 in the image
FrameNumber:
  DEFB $00                ; the current player's frame 1-99
FrameOther:
  DEFB $00                ; the other player's frame
ShotsLeft:
  DEFB $00                ; set by ShotsForFrame; lowered by the end-of-shot
                          ; task $83EA
LivesLeft:
  DEFB $00                ; 3 at the start; negative = out
LivesOther:
  DEFB $00                ; the other player's lives
MessageStep:
  DEFB $00                ; MessagesTask step 0-$50 (zeroed at each shot by
                          ; $84CE)
RackScriptState:
  DEFB $00,$00,$00,$00    ; 6 x 4 bytes, balls 1-6: script pointer (word), wait
                          ; count, move count
  DEFB $00,$00,$00,$00    ; ball 2
  DEFB $00,$00,$00,$00    ; ball 3
  DEFB $00,$00,$00,$00    ; ball 4
  DEFB $00,$00,$00,$00    ; ball 5
  DEFB $00,$00,$00,$00    ; ball 6

; Rack the balls with the tasks stopped (WaitFrame $80DE with RackBalls)
;
; From the game start $8013, the end-of-shot task $8357 and NextTurn $97CD:
; game 1 (frame 6190), w1 4 (frames 630-10196), p2 2.
Rack:
  LD HL,RackBalls
  JP WaitFrameNoTasks

; FRAME banner, then roll balls 1-6 into the triangle by their scripts, one
; step a frame; then the cue ball to (40, 115)
;
; ShowFrameBanner $9B36; the rack set = RackSets[((frame - 1) / 2) mod 6]
; (frames 1-2 set 0, 3-4 set 1, ...); each ball's RackScriptState = (its
; script, 0, 0) and its record cleared (ClearBallMotion $A040).
;
; Each step: RackStep $A05E for balls 1-6 (B counts the scripts ended), the
; draw list $869E rebuilt ($8304), HALT, and every ball of the list with bit 4
; of +13 set (it moved) erased at +10/+11, placed at SpriteFromBall, drawn, bit
; 4 cleared (the list's cue entry, ball 0, is skipped). Until all six scripts
; ended: game 170 steps (frames 6266-6435).
;
; The cue ball: ClearBallMotion, x 40 / y 115 with a random fraction (R x 2
; into both), drawn (no erase before it).
RackBalls:
  CALL ShowFrameBanner
  LD A,(FrameNumber)
  DEC A
  SRL A
RackSetMod:
  CP $06
  JR C,RackSetPick
  SUB $06
  JR RackSetMod
RackSetPick:
  LD D,$00
  LD E,A
  LD HL,RackSets
  ADD HL,DE
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD HL,RackScriptState
  LD IX,BallRecords
  LD B,$06
RackInitBall:
  PUSH BC
  LD BC,$000E
  ADD IX,BC
  CALL ClearBallMotion
  LD A,(DE)
  LD (HL),A
  INC HL
  INC DE
  LD A,(DE)
  LD (HL),A
  INC HL
  INC DE
  LD (HL),$00
  INC HL
  LD (HL),$00
  INC HL
  POP BC
  DJNZ RackInitBall
RackStepAll:
  LD IX,BallRecords
  LD HL,RackScriptState
  LD A,$01
  LD B,$00
RackStepBall:
  LD DE,$000E
  ADD IX,DE
  PUSH HL
  PUSH AF
  CALL RackStep
  POP AF
  POP HL
  INC HL
  INC HL
  INC HL
  INC HL
  INC A
  CP $07
  JR NZ,RackStepBall
  PUSH BC
  CALL BuildDrawList
  HALT
  LD HL,DrawList
  LD B,$07
RackRedraw:
  PUSH BC
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
  OR A
  JR Z,RackRedrawNext
  BIT 4,(IX+$0D)
  JR Z,RackRedrawNext
  LD L,(IX+$0A)
  LD H,(IX+$0B)
  LD (SpritePos),HL
  PUSH AF
  CALL DrawBall
  CALL SpriteFromBall
  LD (SpritePos),HL
  LD (IX+$0A),L
  LD (IX+$0B),H
  RES 4,(IX+$0D)
  POP AF
  CALL DrawBall
RackRedrawNext:
  POP HL
  POP BC
  DJNZ RackRedraw
  POP AF
  CP $06
  JR NZ,RackStepAll
  LD IX,BallRecords
  CALL ClearBallMotion
  LD (IX+$01),$28
  LD (IX+$03),$73
  LD A,R
  ADD A,A
  LD (IX+$00),A
  LD (IX+$02),A
  CALL SpriteFromBall
  LD (SpritePos),HL
  LD (IX+$0A),L
  LD (IX+$0B),H
  XOR A
  CALL DrawBall
  RET

; Zero record IX's fractions (+0, +2), velocities (+4..+7), friction steps (+8,
; +9); flags +13 = $80
;
; Used by the routine at RackBalls.
ClearBallMotion:
  XOR A
  LD (IX+$00),A
  LD (IX+$02),A
  LD (IX+$04),A
  LD (IX+$05),A
  LD (IX+$06),A
  LD (IX+$07),A
  LD (IX+$08),A
  LD (IX+$09),A
  LD (IX+$0D),$80
  RET

; One frame of the rack script of ball IX, state at HL: a wait, a repeated
; move, or the next command
;
; State: +0/+1 the script pointer, +2 the wait, +3 the moves left. A wait above
; 0: one less, return. Moves left: x + dx, y + dy (the pair at the pointer,
; whole pixels), bit 4 of +13 set; the pointer passes the pair when the count
; ends. Else the next command: 0 end (B + 1, the pointer stays: every later
; step ends again), 1 x y (put the ball at x, y), 2 n dx dy (move n times by
; dx, dy, one a frame; starts at once), 3 n (wait n frames).
;
; game 1040 calls (frames 6266-6435); command 1: 12, command 2: 20, command 3:
; 6.
RackStep:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  OR A
  JR Z,RackStepMove
  DEC (HL)
  RET
RackStepMove:
  INC HL
  LD A,(HL)
  OR A
  JR Z,RackStepCommand
  LD A,(DE)
  INC DE
  ADD A,(IX+$01)
  LD (IX+$01),A
  LD A,(DE)
  INC DE
  ADD A,(IX+$03)
  LD (IX+$03),A
  SET 4,(IX+$0D)
  DEC (HL)
  RET NZ
  DEC HL
  DEC HL
  LD (HL),D
  DEC HL
  LD (HL),E
  RET
RackStepCommand:
  LD A,(DE)
  INC DE
  CP $00
  JR Z,RackStepEnd
  CP $01
  JR Z,RackStepPlace
  CP $02
  JR Z,RackStepRun
  CP $03
  JR Z,RackStepWait
RackStepEnd:
  INC B                   ; command 0
  RET
RackStepPlace:
  LD A,(DE)               ; command 1
  INC DE
  LD (IX+$01),A
  LD A,(DE)
  INC DE
  LD (IX+$03),A
  DEC HL
  DEC HL
  LD (HL),D
  DEC HL
  LD (HL),E
  SET 4,(IX+$0D)
  RET
RackStepRun:
  LD A,(DE)               ; command 2
  INC DE
  LD (HL),A
  DEC HL
  DEC HL
  LD (HL),D
  DEC HL
  LD (HL),E
  JR RackStep
RackStepWait:
  LD A,(DE)               ; command 3
  INC DE
  DEC HL
  LD (HL),A
  DEC HL
  LD (HL),D
  DEC HL
  LD (HL),E
  RET

; The six rack sets: pointers to six script pointers each (balls 1-6)
;
; Read by RackBalls ($9F83): sets 0 and 1 read; $A0C8-$A0CF (sets 2-5, frames
; 5-12) read by no build. Set 1 $A162 and sets 2-5 ($A1E4, $A29C, $A38E, $A4F8)
; are past this fragment.
RackSets:
  INCBIN "res/racks/RackScripts.bin",$0000,12
  ASSERT {RackSets} == RackScripts0 && {RackSets+2} == RackSet1 && {RackSets+4} == RackSet2
  ASSERT {RackSets+6} == RackSet3 && {RackSets+8} == RackSet4 && {RackSets+10} == RackSet5

; Set 0 (frames 1-2): the scripts of balls 1-6
RackScripts0:
  INCBIN "res/racks/RackScripts.bin",$000C,12
  ASSERT {RackScripts0} == RackScript0Ball1 && {RackScripts0+2} == RackScript0Ball2
  ASSERT {RackScripts0+4} == RackScript0Ball3 && {RackScripts0+6} == RackScript0Ball4
  ASSERT {RackScripts0+8} == RackScript0Ball5 && {RackScripts0+10} == RackScript0Ball6

; Ball 1: wait 75; at (7, 175); 30 x (+2, -2); 61 x (+2, 0); at (190, 115); end
;
; The scripts of set 0 all start at a left corner pocket, (7, 175) or (7, 55),
; run diagonally to y 115, along the middle line, turn into their place and end
; exactly on StartPositions. Waits 75, 60, 45, 30, 15, 0: ball 6 rolls first.
RackScript0Ball1:
  INCBIN "res/racks/RackScripts.bin",$0018,17
RackScript0Ball2:
  INCBIN "res/racks/RackScripts.bin",$0029,25
RackScript0Ball3:
  INCBIN "res/racks/RackScripts.bin",$0042,25
RackScript0Ball4:
  INCBIN "res/racks/RackScripts.bin",$005B,25
RackScript0Ball5:
  INCBIN "res/racks/RackScripts.bin",$0074,17
RackScript0Ball6:
  INCBIN "res/racks/RackScripts.bin",$0085,25
