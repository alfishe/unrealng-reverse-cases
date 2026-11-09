; --------------------------------------------------------------------------------------------------------------------
; balldraw.asm: The ball sprites: the draw, the 3 x 16 XOR, the screen address, the cue ball's respot, clearing for a turn
;
; Every ball is a 15 x 15 sprite pre-shifted 8 times in BallSprites $D000: 56 sprites of 48 bytes (3 bytes x 16 lines,
; the 16th line empty), index = shift x 7 + ball, shift = x AND 7, ball 0 the cue ball, 1-6 the numbered balls.
; DrawBall $9548 XORs one at the screen position in SpritePos $95D8 (x, y of the sprite's top left, the ball's centre
; minus 7); drawing it again at the same place erases it, so every move is an erase at the old +10/+11 and a draw at
; the new.
; --------------------------------------------------------------------------------------------------------------------

; Put the cue ball back at (40, 115), or right of it until no ball is within 16
; pixels, and draw it
;
; Called by the end-of-shot task $8357 when the cue ball was potted, by
; NextTurn $97CD ($981F) and by the editor $C042. f1 ran it once (frame 1173,
; after the cue ball went down). Zeroes the cue ball's velocity and friction
; steps (+4..+9), flags +13 = $80 (on the table), x = 40 / y = 115 with zero
; fractions. For each object ball on the table with |dx| < 16 and |dy| < 16 it
; moves x one pixel right and starts again, up to x 200. Then SpritePos = (x-7,
; y-7) (also +10/+11) and DrawBall ball 0.
RespotCueBall:
  LD IX,BallRecords
  XOR A
  LD (IX+$04),A
  LD (IX+$05),A
  LD (IX+$06),A
  LD (IX+$07),A
  LD (IX+$08),A
  LD (IX+$09),A
  LD (IX+$0D),$80
  LD L,$28
  LD H,$73
RespotTry:
  LD IX,BallRecords
  LD A,L
  LD (IX+$01),A
  LD (IX+$00),$00
  SUB $07
  LD (IX+$0A),A
  LD A,H
  LD (IX+$03),A
  LD (IX+$02),$00
  SUB $07
  LD (IX+$0B),A
  LD IX,BallRecords
  LD DE,$000E
  LD B,$06
RespotCheckBall:
  ADD IX,DE
  BIT 7,(IX+$0D)
  JR Z,RespotNextBall
  LD A,(IX+$01)
  SUB L
  JR NC,RespotDy
  NEG
RespotDy:
  CP $10
  JR NC,RespotNextBall
  LD A,(IX+$03)
  SUB H
  JR NC,RespotNear
  NEG
RespotNear:
  CP $10
  JR NC,RespotNextBall
  LD A,L
  INC A
  LD L,A
  CP $C8
  JR C,RespotTry
RespotNextBall:
  DJNZ RespotCheckBall
  LD A,L
  SUB $07
  LD L,A
  LD A,H
  SUB $07
  LD H,A
  LD (SpritePos),HL
  XOR A
  JP DrawBall

; Before the turn passes: XOR off every ball outside the middle of the table,
; then clear the middle (x 16-239, y 64-167)
;
; Called by TurnSwap $9C15 (p2 once, frame 1778). Ball 0..6: a ball whose
; sprite lies inside x 16-223, y 64-150 (+10, +11) is left (the block clear
; wipes it); every other ball is XOR-erased at its +10/+11: the balls near the
; cushions and the potted row (bit 7 of +13 clear). The cue ball is skipped
; when it is off the table (it has no image then). Then 13 character rows x 28
; bytes from (y 64, x 16) are zeroed (pixels only; the attributes stay).
ClearTableForTurn:
  LD IX,BallRecords
  LD B,$00
  BIT 7,(IX+$0D)
  JR Z,ClearTurnNext
ClearTurnBall:
  BIT 7,(IX+$0D)
  JR Z,ClearTurnErase
  LD A,(IX+$0A)
  CP $10
  JR C,ClearTurnErase
  CP $E0
  JR NC,ClearTurnErase
  LD A,(IX+$0B)
  CP $40
  JR C,ClearTurnErase
  CP $97
  JR NC,ClearTurnErase
  JR ClearTurnNext
ClearTurnErase:
  LD L,(IX+$0A)
  LD H,(IX+$0B)
  LD (SpritePos),HL
  PUSH IX
  PUSH BC
  LD A,B
  CALL DrawBall
  POP BC
  POP IX
ClearTurnNext:
  LD DE,$000E
  ADD IX,DE
  INC B
  LD A,B
  CP $07
  JR NZ,ClearTurnBall
  LD HL,Screen+16             ; y 64, x 16: a y/x pair for ScreenCell, not a screen
                          ; address
  LD B,$0D
ClearTurnRow:
  PUSH BC
  PUSH HL
  CALL ScreenCell
  LD B,$08
ClearTurnLine:
  PUSH BC
  PUSH HL
  LD D,H
  LD E,L
  INC DE
  LD BC,$001B
  LD (HL),$00
  LDIR
  POP HL
  INC H
  POP BC
  DJNZ ClearTurnLine
  POP HL
  LD A,$08
  ADD A,H
  LD H,A
  POP BC
  DJNZ ClearTurnRow
  RET

; Clear character rows 2-4 (y 16-39): pixels zero, attributes $39
;
; The message area under the HUD: the foul texts and the score tally print at
; row 3, and the potted row (balls at y 20-34) lies here too, so the caller
; redraws it after (DrawPottedRow $9AB5). Called by MessagesTask $9CB7 (steps 1
; and $4E) and ScoreTally $98FF: game 8, w1 43, f1 9, p2 6, v1 15.
ClearMessageRows:
  LD HL,$1000
  LD B,$03
ClearMessageRow:
  PUSH BC
  PUSH HL
  CALL ScreenCell
  PUSH HL
  CALL AttrFromScreen
  LD D,H
  LD E,L
  INC DE
  LD BC,$001F
  LD (HL),$39
  LDIR
  POP HL
  LD B,$08
ClearMessageLine:
  PUSH BC
  PUSH HL
  LD D,H
  LD E,L
  INC DE
  LD BC,$001F
  LD (HL),$00
  LDIR
  POP HL
  INC H
  POP BC
  DJNZ ClearMessageLine
  POP HL
  LD A,$08
  ADD A,H
  LD H,A
  POP BC
  DJNZ ClearMessageRow
  RET

; XOR every numbered ball at its +10/+11 and the cue ball when it is on the
; table
;
; Balls 1-6 are drawn whatever their flags (on the table, or in the potted
; row); the cue ball only with bit 7 of +13 set. Called at a new game ($8013),
; by NextTurn $97CD and the editor ($C042, $C532): game 1 at frame 6190, p2 2
; (690, 1780).
DrawAllBalls:
  LD IX,BallRecords
  XOR A
  BIT 7,(IX+$0D)
  JR Z,DrawAllBallsNext
DrawAllBallsLoop:
  LD L,(IX+$0A)
  LD H,(IX+$0B)
  LD (SpritePos),HL
  PUSH IX
  PUSH AF
  CALL DrawBall
  POP AF
  POP IX
DrawAllBallsNext:
  LD DE,$000E
  ADD IX,DE
  INC A
  CP $07
  JR NZ,DrawAllBallsLoop
  RET

; XOR ball A's sprite (0 cue, 1-6) at SpritePos $95D8 (x, y of the sprite's top
; left)
;
; Input A = the ball 0-6, SpritePos = (x, y). Source = BallSprites $D000 + 48 x
; (7 x (x AND 7) + A): BC = 48A, HL = 336 (x AND 7), the sum plus $D000 into
; DE. Target: ScreenCell $95B3 of (y, x) plus y AND 7 lines. A screen character
; row holds 8 lines, so the 16 lines go in three parts through XorSpriteLines
; $959F: 8 - (y AND 7) lines, then 8 lines from the next character row (y + 8),
; then (y AND 7) - 1 lines from the row after (y + 16): 16 lines when y AND 7 =
; 0, else 15; the 16th line of every sprite is zero, so nothing is lost and a
; second draw always erases exactly.
;
; 1827 calls in game, w1 15290, f1 4407, p2 10210, v1 7119, m1 3193; callers:
; the ball redraw task $8297, $8357, RespotCueBall $93FF, ClearTableForTurn
; $947D, DrawAllBalls $9520, LoseLife $9754, EraseBallsUnderBanner $98B5,
; DrawPottedRow $9AB5, DrawLives $9AD9, Rack $9F6F, the editor $C20B.
DrawBall:
  LD D,$00
  LD B,D
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  LD C,A
  ADD A,A
  ADD A,C
  LD C,A
  RL B
  LD A,(SpritePos)
  AND $07
  LD H,A
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  LD L,A
  ADD A,A
  LD E,A
  ADD HL,DE
  ADD HL,DE
  ADD HL,BC
  LD DE,BallSprites
  ADD HL,DE
  EX DE,HL
  LD HL,(SpritePos)
  LD C,H
  CALL ScreenCell
  LD A,C
  AND $07
  ADD A,H
  LD H,A
  LD A,C
  CPL
  AND $07
  INC A
  LD B,A
  CALL XorSpriteLines
  LD HL,(SpritePos)
  LD A,$08
  ADD A,H
  LD H,A
  CALL ScreenCell
  LD B,$08
  CALL XorSpriteLines
  LD HL,(SpritePos)
  LD A,$10
  ADD A,H
  LD H,A
  CALL ScreenCell
  LD A,C
  AND $07
  RET Z
  DEC A
  RET Z
  LD B,A

; XOR B lines of 3 bytes from DE onto the screen at HL (INC H a line: within
; one character row)
;
; DE advances 3 bytes a line (the sprite is stored line by line, 3 bytes each);
; L goes +1, +1, -2, H + 1. 27602 calls in game (5230 DrawBall calls), w1
; 230986.
XorSpriteLines:
  LD A,(DE)
  INC DE
  XOR (HL)
  LD (HL),A
  INC L
  LD A,(DE)
  INC DE
  XOR (HL)
  LD (HL),A
  INC L
  LD A,(DE)
  INC DE
  XOR (HL)
  LD (HL),A
  DEC L
  DEC L
  INC H
  DJNZ XorSpriteLines
  RET

; HL = the display address of the character cell holding pixel (x L, y H): line
; 0 of that cell
;
; H = $40 + 8 x (y / 64), L = 32 x ((y / 8) AND 7) + x / 8. The caller adds y
; AND 7 to H for the exact line. Used by XorLine, DrawBall, ClearTableForTurn,
; ClearMessageRows and the hall of fame ($A9CC, $AA74, $AABD, $AB7B, $ABC3) and
; $B118: game 9793 calls.
ScreenCell:
  LD A,H
  ADD A,A
  ADD A,A
  AND $E0
  SRL L
  SRL L
  SRL L
  ADD A,L
  LD L,A
  LD A,H
  SRL A
  SRL A
  SRL A
  AND $F8
  OR $40
  LD H,A
  RET

; HL = the attribute address of the display cell address HL (line 0 of the
; cell)
;
; H = $58 + (H - $40) / 8. Used by ClearMessageRows $94EB only (game 24 calls).
AttrFromScreen:
  SRL H
  SRL H
  SRL H
  SET 6,H
  SET 4,H
  RET

; The sprite's screen position for DrawBall $9548: +0 x, +1 y of the top left
; (the ball's centre minus 7)
;
; Written before every DrawBall (from a record's +10/+11, from $9F36, or
; computed for the potted row and the lives); read by DrawBall at $9555 / $956A
; / $957F / $958E and by DrawLives $9AFA.
SpritePos:
  DEFB $00,$00
