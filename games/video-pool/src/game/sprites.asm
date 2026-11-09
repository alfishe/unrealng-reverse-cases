; --------------------------------------------------------------------------------------------------------------------
; sprites.asm: The 56 pre-shifted ball sprites
;
; The sprite of ball b (0 the cue ball, 1-6 the object balls) drawn at a screen x is number 7 * (x AND 7) + b, 48
; bytes at $D000 + 48 * number (DrawBall $9548): 16 lines of 3 bytes, the left byte first, the 16th line zero, no
; mask; drawn with XOR so a second draw erases it. Each ball is a 15 x 15 disc with its centre at (7, 7) of the
; sprite, the object balls with their number cut out. The editable source is src/res/graphics/BallSprites.png, one row
; a shift, the seven balls left to right.
; --------------------------------------------------------------------------------------------------------------------

; The 56 ball sprites: 3 bytes x 16 lines, 7 balls x 8 shifts
;
; Read by DrawBall $9548 (through the XOR drawer): every byte read in game, w1,
; f1, p2, v1, m1, j1 (l1sum.py --reads D000-DA7F: 2688 of 2688 bytes).
BallSprites:
  INCBIN "res/graphics/BallSprites.bin",$0000,2688
