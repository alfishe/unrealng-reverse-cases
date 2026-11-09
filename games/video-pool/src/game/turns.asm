; --------------------------------------------------------------------------------------------------------------------
; turns.asm: The FRAME banner, the next frame, the shots per frame, the turn swap, the last-shot beep, the messages task
; --------------------------------------------------------------------------------------------------------------------

; Print "FRAME n" double width at row 9 (row 11 under a PLAYER n banner), wait
; 75 frames, blank rows 9 and 11
;
; Called by Rack $9F6F at each rack (game 1 at frame 6190, w1 4, p2 2). Two
; players: the cell row 9, col 8 is tested for pixels (PlayerBanner printed):
; then row 11. The column: 9, 8 for a frame >= 10. FrameBanner $9B8E is patched
; (row, column), printed, the number after it (PrintNumber $9E13, attr $E0);
; then FrameBannerBlank $9B98 printed at row 9 and row 11 (its row byte
; patched).
ShowFrameBanner:
  LD A,(Players)
  DEC A
  LD C,$09
  JR Z,FrameBannerRow
  LD HL,$0908
  CALL CellAddress
  LD BC,$080B
FrameBannerTestCell:
  LD A,(HL)
  OR A
  JR NZ,FrameBannerRow
  INC H
  DJNZ FrameBannerTestCell
  LD C,$09
FrameBannerRow:
  LD A,C
  LD (FrameBannerRowByte),A
  LD A,(FrameNumber)
  CP $0A
  LD A,$09
  JR C,FrameBannerColumn
  DEC A
FrameBannerColumn:
  LD (FrameBanner+$0001),A
  LD HL,FrameBanner
  CALL PrintText
  EX DE,HL
  LD C,$E0
  LD HL,(FrameNumber)
  LD H,$00
  LD B,H
  CALL PrintNumber
  LD B,$4B
FrameBannerWait:
  HALT
  DJNZ FrameBannerWait
  LD A,$09
  LD (FrameBannerBlank),A
  LD HL,FrameBannerBlank
  CALL PrintText
  LD A,$0B
  LD (FrameBannerBlank),A
  LD HL,FrameBannerBlank
  JP PrintText

; The FRAME banner and the blank line that wipes it (PrintText records; the row
; and column bytes are patched)
;
; Written by ShowFrameBanner ($9B51, $9B5E, $9B7A, $9B85) and NextTurn ($9808);
; read by PrintText. In the image $9B8E = row 11, col 9.
FrameBanner:
FrameBannerRowByte:
  INCBIN "res/text/FrameBanner.bin",$0000,10
FrameBannerBlank:
  INCBIN "res/text/FrameBanner.bin",$000A,32

; Frame cleared: frame + 1 (up to 99), the pocket multipliers turn one place,
; the shots refilled, power reset
;
; From the end-of-shot task $8357 and NextTurn $97CD: w1 3 times (frames
; 4023-10196, frames 2, 3 and 4). Frame $9F4B + 1, printed (PrintHudNumber 4);
; the pocket turn (PlayerVars $9F43) - 1 (0 wraps to 5), the marks redrawn
; (DrawPocketMarks $9D6B); ShotsLeft = ShotsForFrame, printed (PrintHudNumber
; 3); tail call $8539 (erase the power bar, power 0).
NextFrame:
  LD A,(FrameNumber)
  INC A
  CP $64
  JR C,NextFrameStore
  DEC A
NextFrameStore:
  LD (FrameNumber),A
  LD A,$04
  CALL PrintHudNumber
  LD A,(PocketTurn)
  DEC A
  JP P,NextFrameTurn
  LD A,$05
NextFrameTurn:
  LD (PocketTurn),A
  CALL DrawPocketMarks
  CALL ShotsForFrame
  LD (ShotsLeft),A
  LD A,$03
  CALL PrintHudNumber
  JP AimPowerReset

; A = the shots for this frame: ShotsPerFrame[frame], 2 from frame 10; plus
; variation + 1 in a variation
;
; Frame $9F4B; the variation $B8C3 (0 standard, 1 numeric order, 2 own pockets;
; the menu). Standard: frames 1-2 five shots, 3-5 four, 6-9 three, then two.
; Variation 2 on frame 1: 5 + 3 = 8 (v1, WALKTHROUGH 6.0). game 4, w1 24.
ShotsForFrame:
  LD A,(FrameNumber)
  CP $0A
  JR C,ShotsFromTable
  LD L,$02
  JR ShotsVariation
ShotsFromTable:
  LD HL,ShotsPerFrame-$0001
  ADD A,L
  LD L,A
  JR NC,ShotsTableRead
  INC H
ShotsTableRead:
  LD L,(HL)
ShotsVariation:
  LD A,(Variation)
  OR A
  LD A,L
  RET Z
  LD A,(Variation)
  INC A
  ADD A,L
  RET

; The shots of frames 1-9: 5, 5, 4, 4, 4, 3, 3, 3, 3
;
; Read by ShotsForFrame $9BE6 (index frame - 1). Frames 1-4 read (w1 reached
; frame 4); $9C0A-$9C0E (frames 5-9) read by no build.
ShotsPerFrame:
  INCBIN "res/tables/ShotsPerFrame.bin",$0000,9

; Run TurnSwap with the tasks stopped (WaitFrame $80DE)
;
; Used by the routine at NextTurn.
TurnSwapStart:
  LD HL,TurnSwap
  JP WaitFrameNoTasks

; After a life lost: with two players and the other still alive, swap
; everything to the other player; then the frame, shots, pocket marks, PLAYER n
;
; Run by TurnSwapStart (game 3, w1 3, f1 3, p2 1 at frame 1738, v1 3). Two
; players (p2 only): wait 40 frames, ClearTableForTurn $947D, DrawLives (XOR:
; erases the lives), then unless the other's lives $9F4F are negative:
; CurrentPlayer 1 <-> 2, and the pairs pocket turn (PlayerVars $9F43) / $9F44,
; LivesLeft $9F4E / $9F4F, FrameNumber $9F4B / $9F4C swapped, the 98-byte ball
; sets $8A88 / $8AEA exchanged byte by byte.
;
; Then for one and two players: $8539 (power 0), PrintHudNumber 4 (frame),
; ShotsLeft = ShotsForFrame, PrintHudNumber 3, DrawPocketMarks, and falls into
; PlayerBanner.
TurnSwap:
  LD A,(Players)
  DEC A
  JR Z,TurnSwapHud
  LD B,$28
TurnSwapWait:
  HALT
  DJNZ TurnSwapWait
  CALL ClearTableForTurn
  CALL DrawLives
  LD HL,(LivesLeft)
  LD A,H
  OR A
  JP M,TurnSwapHud
  LD A,(CurrentPlayer)
  AND $01
  INC A
  LD (CurrentPlayer),A
  LD HL,(PocketTurn)
  LD A,H
  LD H,L
  LD L,A
  LD (PocketTurn),HL
  LD HL,(LivesLeft)
  LD A,H
  LD H,L
  LD L,A
  LD (LivesLeft),HL
  LD HL,(FrameNumber)
  LD A,H
  LD H,L
  LD L,A
  LD (FrameNumber),HL
  LD HL,BallRecords
  LD D,H
  LD E,L
  LD BC,$0062
  ADD HL,BC
TurnSwapBalls:
  LD B,(HL)               ; exchange 98 bytes: $8A88-$8AE9 with $8AEA-$8B4B
  LD A,(DE)
  LD (HL),A
  LD A,B
  LD (DE),A
  INC HL
  INC DE
  DEC C
  JR NZ,TurnSwapBalls
TurnSwapHud:
  CALL AimPowerReset
  LD A,$04
  CALL PrintHudNumber
  CALL ShotsForFrame
  LD (ShotsLeft),A
  LD A,$03
  CALL PrintHudNumber
  CALL DrawPocketMarks

; Two players: print "PLAYER 1" / "PLAYER 2" double width at row 9, col 8
;
; From TurnSwap and the game start $8013. Returns at once with one player
; ($B8BB = 1). p2 2, v1 5 (entries).
PlayerBanner:
  LD A,(Players)
  DEC A
  RET Z
  LD A,(CurrentPlayer)
  LD HL,PlayerBannerTexts
  DEC A
  JR Z,PlayerBannerPrint
  LD HL,PlayerBanner2
PlayerBannerPrint:
  JP PrintText

; PLAYER 1 / PLAYER 2 (PrintText records)
;
; Read by PlayerBanner (p2). Wiped by ShowFrameBanner's blank of row 9.
PlayerBannerTexts:
PlayerBanner1:
  INCBIN "res/text/PlayerBannerTexts.bin",$0000,12
PlayerBanner2:
  INCBIN "res/text/PlayerBannerTexts.bin",$000C,12

; With one shot left: a short beep (BEEPER HL 500, DE 10, so 11 cycles: 825 Hz,
; 12.7 ms; f1 measured 825.7 Hz, 13 beeps, docs/09-sound.md 9.4), then DI (it
; runs in the interrupt)
;
; A task added by StartAim $8425 with period 25, removed by $8506 at the shot.
; 58 runs in game, w1 179 (none beeped: no aim of w1 had one shot left), f1 13
; beeps. BEEPER ends with EI; the DI keeps the interrupt handler closed.
LastShotBeepTask:
  LD A,(ShotsLeft)
  DEC A
  RET NZ
  LD HL,$01F4
  LD DE,$000A
  CALL BEEPER
  DI
  RET

; Step through the foul message: clear, print, hold about 75 steps, clear,
; redraw the potted row
;
; MessageStep $9F50: 0: start (step 1) only when the foul code $8E80 is set; 1:
; ClearMessageRows; 2: the text by $8E80 (1 FOUL SHOT!, 2 WRONG ORDER!, 3 WRONG
; POCKET!); 3-$4D: wait; $4E: ClearMessageRows; $4F: DrawPottedRow; $50: stays.
; Each step but the last adds 1 (MessageNextStep pushed as the return address).
; A task of the balls-moving list $84BA (period 0) and called by $8457 once a
; frame after the balls stop until step $50. game 606 runs (320 steps); the
; texts: game 4, w1 4, f1 3, p2 1, v1 3 (WRONG ORDER / WRONG POCKET in v1 at
; frames 1471 / 3100).
MessagesTask:
  LD A,(MessageStep)
  OR A
  JR Z,MessageIdle
  LD HL,MessageNextStep
  PUSH HL
  CP $01
  JP Z,ClearMessageRows
  CP $02
  JR NZ,MessageLaterSteps
  LD A,(FoulCode)
  LD HL,FoulTexts
  CP $01
  JR Z,MessagePrint
  LD HL,WrongOrderText
  CP $02
  JR Z,MessagePrint
  LD HL,WrongPocketText
MessagePrint:
  JP PrintText
MessageLaterSteps:
  CP $4E
  RET C
  CP $4E
  JP Z,ClearMessageRows
  CP $4F
  JP Z,DrawPottedRow
  POP HL
  RET
MessageIdle:
  LD A,(FoulCode)
  OR A
  RET Z
MessageNextStep:
  LD A,(MessageStep)      ; MessageStep + 1
  INC A
  LD (MessageStep),A
  RET

; The three foul messages (PrintText records, double width, attr $38, row 3,
; centred)
;
; Read by MessagesTask $9CB7 step 2.
FoulTexts:
FoulShotText:
  INCBIN "res/text/FoulTexts.bin",$0000,14
WrongOrderText:
  INCBIN "res/text/FoulTexts.bin",$000E,16
WrongPocketText:
  INCBIN "res/text/FoulTexts.bin",$001E,17

; Put the seven balls of the current set at their rack positions
; (StartPositions), on the table
;
; x / y whole parts from StartPositions, fractions 0, +10/+11 = x - 7 / y - 7,
; flags +13 = $80; velocities untouched; nothing drawn. Called by the entry
; $8000 (every build, frame 0 / 5556) and the editor ($C042, $C532).
ResetBallPositions:
  LD IX,BallRecords
  LD DE,$000E
  LD HL,StartPositions
  LD B,$07
ResetBallLoop:
  LD A,(HL)
  LD (IX+$01),A
  LD (IX+$00),$00
  SUB $07
  LD (IX+$0A),A
  INC HL
  LD A,(HL)
  LD (IX+$03),A
  LD (IX+$02),$00
  SUB $07
  LD (IX+$0B),A
  INC HL
  LD (IX+$0D),$80
  ADD IX,DE
  DJNZ ResetBallLoop
  RET

; The rack: x, y of the cue ball and balls 1-6
;
; (40, 115), (190, 115), (205, 106), (205, 124), (221, 98), (221, 115), (221,
; 132): a triangle of six with its point at ball 1. Read by ResetBallPositions;
; the rack scripts end on the same points (RackScripts0).
StartPositions:
  INCBIN "res/tables/StartPositions.bin",$0000,14
