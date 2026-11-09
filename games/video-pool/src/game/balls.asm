; --------------------------------------------------------------------------------------------------------------------
; balls.asm: The ball records, the other player's records, the physics counters
;
; Fourteen 14-byte records: the seven balls of the player at the table (cue ball first, then balls 1-6) and the same
; seven of the other player in a two-player game, swapped as one 98-byte block on the turn change (the swap loop $9C5B
; in $9C0F, p2 98 bytes once). Then two counters of the physics task.
; --------------------------------------------------------------------------------------------------------------------

; The seven ball records of the player at the table: cue ball, balls 1-6
;
; 14 bytes a ball: +0/+1 x and +2/+3 y, 8.8 fixed point in screen pixels,
; fraction first, the centre of the ball; +4/+5 vx and +6/+7 vy, 8.8 two's
; complement in pixels a tick; +8 / +9 the friction steps x / y, signed bytes
; in 1/256 pixel a tick (FrictionSteps $90F5, negated by the bounces $8DCB /
; $8DFF, swapped by $8D7D); +10/+11 the screen x / y of the sprite as last
; drawn (x - 7, y - 7: the corner of the 16 x 16 ball); +12 the pocket the ball
; fell into (1 top left, 2 top middle, 3 top right, 4 bottom right, 5 bottom
; middle, 6 bottom left, written by PocketStore $8BE3, 0 = none, cleared at
; each shot by $84C7); +13 flags.
;
; +13: bit 7 on the table, bit 6 moving, bit 5 potted (fallen, waiting for the
; redraw $8297 to move it to the row of potted balls and clear the byte), bit 4
; to be redrawn. $80 at rest, $D0 rolling (moving and redrawn), $90 = on the
; table and to be redrawn.
;
; Positions from $9D5D by $9D2C. Read by every build; the cue ball's x pixel
; $8A89 most (w1 28 930 reads). +12 of balls 1-6 read 29-42 times in w1 (the
; end-of-shot test $83DC and the wrong-pocket test $8C37), +12 of the cue ball
; once in p2 (the turn swap).
BallRecords:
  DEFB $00,$00            ; the cue ball: +0/+1 x
  DEFB $00,$00            ; +2/+3 y
  DEFB $00,$00            ; +4/+5 vx
  DEFB $00,$00            ; +6/+7 vy
  DEFB $00,$00            ; +8 / +9 friction step x / y
  DEFB $00,$00            ; +10 / +11 sprite screen x / y
  DEFB $00,$00            ; +12 pocket, +13 flags
BallOne:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; ball 1
BallTwo:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; ball 2
BallThree:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; ball 3
BallFour:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; ball 4
BallFive:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; ball 5
BallSix:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; ball 6

; The other player's seven ball records, same format, swapped with BallRecords
; on the turn change
;
; Zero in the image. Every byte read once in p2 only (the swap $9C0F at frame
; 1738, two players), and +13 of each of the seven read once in every build
; (game, w1, f1, p2, v1, m1; reader not identified, see the notes). At w1 frame
; 1060 balls 1-6 here have +10 = 0, 24, ... 120 and +11 = 20: the sprite
; corners of the row of potted balls ($82CC puts a potted ball at x 24 (n - 1)
; + 7, y 27). Stage 1 read this as the potted row itself: it is the second
; player's set.
OtherPlayerBalls:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; The ball whose friction steps are recomputed this tick, 0..6
;
; Advanced mod 7 by PhysicsTask $86C1, compared by MoveBall $8701 with B - 1 (6
; - the ball number), cleared at the shot's start ($84C7). Read game 576, w1
; 8504.
FrictionTurn:
  DEFB $00

; Bounces and contacts in this pass of PhysicsTask: cushion +1, ball +2; 7 or
; more repeats the pass
;
; Cleared by PhysicsTask $86C1, raised by ReflectDiagonal $8D7D, ReflectX
; $8DCB, ReflectY $8DFF (+1) and BallContacts $87EF (+2). Never reached 7 in a
; recording (the repeat at $86FB not taken).
EventCount:
  DEFB $00
