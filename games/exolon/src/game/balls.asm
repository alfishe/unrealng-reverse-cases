; --------------------------------------------------------------------------------------------------------------------
; balls.asm: The balls and their spawners
; --------------------------------------------------------------------------------------------------------------------

; Move every ball: a random walk with bounces off the walls and the screen's
; edges
;
; Main loop, every pass (c1: 3260, empty on screen 0; w clones: 151 496 balls
; moved on 50 screens). A record of BallList: X, Y, state (1 alive), dx (+1 /
; -1). For each live ball: frame 7 erased; dx reversed at X 0 or $7B, at random
; (1 in about 7: a random byte $DC or more), or at a wall in its way (ProbeLeft
; / ProbeRight); X + dx kept in C; a vertical step +1 or -1 at random, 0 when
; ProbeBelow / ProbeAbove find a wall; Y + step (Y 0 becomes 1); frame 7 drawn
; at the new place in bright red ($42).
;
; The eight balls of a spawner start on the same spot: their first erases there
; cancel in pairs (XOR).
MoveBalls:
  LD HL,BallList

; MoveBallsLoop
;
; Used by the routine at BallDraw.
MoveBallsLoop:
  LD E,(HL)               ; $FF: the end
  BIT 7,E
  RET NZ
  PUSH HL
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  OR A
  JR Z,BallNext           ; dead: the next
  INC HL
  LD A,$07                ; erase the ball
  CALL DrawSmallSprite
  LD A,E                  ; at an edge: turn
  OR A
  JR Z,BallTurn
  CP $7B
  JR Z,BallTurn
  CALL Random             ; at random: turn
  CP $DC
  JR NC,BallTurn
  LD A,(HL)               ; the wall on its side
  INC A
  JR NZ,BallWallRight
  CALL ProbeLeft
  JR BallWallTest
BallWallRight:
  CALL ProbeRight
BallWallTest:
  OR A
  JR Z,BallStepY
BallTurn:
  LD A,(HL)
  NEG
  LD (HL),A
BallStepY:
  LD A,(HL)               ; C = the new X; a random +1 / -1
  ADD A,E
  LD C,A
  CALL Random
  AND $01
  JR Z,BallStepSign
  INC A
BallStepSign:
  DEC A
  LD B,A
  CP $FF
  JR NZ,BallWallBelow
  CALL ProbeAbove         ; up: the wall above
  JR BallStepTest
BallWallBelow:
  CALL ProbeBelow         ; down: the wall below
BallStepTest:
  OR A
  JR Z,BallMoveY
  LD B,$00                ; blocked: no vertical step
BallMoveY:
  LD A,B                  ; Y + step
  ADD A,D
  LD D,A
  OR A
  JR NZ,BallDraw

; A ball that reached Y 0 is put on Y 1
;
; INC D. Data in the mechanical cut: no ball reached the top line in any
; recording.
BallTopRow:
  INC D

; Draw the ball at its new place and store it
;
; The tail of MoveBalls: frame 7 at (C, D), bright red, the record's X and Y
; written.
BallDraw:
  LD E,C
  LD A,$07
  CALL DrawSmallSprite
  LD C,$42
  CALL ColourCell
  POP HL
  LD (HL),E
  INC HL
  LD (HL),D
  DEC HL
  JR BallAdvance
; This entry point is used by the routine at MoveBallsLoop.
BallNext:
  POP HL                  ; the next record (4 bytes)
BallAdvance:
  LD DE,$0004
  ADD HL,DE
  JP MoveBallsLoop

; Up to 24 balls (X, Y, state, dx); $FF after the last
;
; Filled by SpawnBalls (8 balls for each of up to 3 spawners) at the screen
; build; cleared by ClearBalls.
BallList:
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $FF                ; the end mark

; Clear the ball list (96 bytes)
;
; Called by the screen builder $8494.
ClearBalls:
  LD HL,BallList
  LD DE,BallList+$0001
  LD BC,$005F
  LD (HL),B
  LDIR
  RET

; Eight balls at each ball spawner of the screen
;
; Called by the screen builder ($8517). For each (column, row) of BallSpawners:
; the position (4 column + 2, 8 row + 3), then eight records of BallList there,
; each alive with a random dx of +1 or -1, frame 4 XORed eight times (no net
; picture). IX = the next record, $FF written after each.
;
; The spawners are the scenery's hanging launchers (w030's screen 30: three of
; them, the red balls drifting below).
SpawnBalls:
  LD IX,BallList
  LD HL,BallSpawners
SpawnBallsLoop:
  LD E,(HL)               ; $FF: the end
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  CALL CellToPixels
  INC E
  INC E
  INC D
  INC D
  INC D
  LD BC,$0004
  LD A,$08
SpawnBallLoop:
  EX AF,AF'               ; one ball
  LD (IX+$00),E
  LD (IX+$01),D
  LD A,$04
  CALL DrawSmallSprite
  LD (IX+$02),$01
  CALL Random             ; dx: -1 or +1
  AND $01
  OR A
  JR Z,SpawnBallDx
  INC A
SpawnBallDx:
  DEC A
  LD (IX+$03),A
  ADD IX,BC
  LD (IX+$00),$FF
  EX AF,AF'
  DEC A
  JR NZ,SpawnBallLoop
  JR SpawnBallsLoop

; Up to 3 ball spawners (column, row); $FF after the last (map value 9)
BallSpawners:
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $FF                ; the end mark

; The player's shots against the balls
;
; Called first by the player's shot routine $83DD (several times a pass). For
; each live ball, BallShot tests the shots; a hit kills the ball (BallHit).
ShotsHitBalls:
  LD HL,BallList
ShotsHitBallsLoop:
  LD E,(HL)
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  INC HL
  INC HL
  OR A
  JR Z,ShotsHitBallsLoop
  CALL BallShot
  OR A
  CALL NZ,BallHit
  JR ShotsHitBallsLoop

; Kill a ball: erase it, a puff, the sound $C155, 50 points
;
; In: E = X, D = Y of the ball, HL past its record. The state set to 0, AddPuff
; at the ball, $C155, 50 points ($AD97: "000050", AddScore $AD53). Callers:
; ShotsHitBalls, BallsTouchPlayer.
;
; w clones: 328 balls killed on 27 screens.
BallHit:
  LD A,$07
  CALL DrawSmallSprite
  DEC HL
  DEC HL
  LD (HL),$00
  INC HL
  INC HL
  CALL AddPuff
  CALL PlaySfxExplosion   ; the kill sound
  LD DE,Points50+$0005    ; 50 points
  JP AddScore

; Is one of the player's shots on this ball?
;
; In: E = X, D = Y of a ball (or a gun's shot: $9E37). Walks the shot list
; $845F (X, Y, direction; 0: free): a shot within X+2-4..X+1 and Y-1..Y+8 is
; erased ($82FC) and freed. Out: A = 1 for a hit, else 0. BC, DE, HL kept.
BallShot:
  PUSH BC
  PUSH DE
  PUSH HL
  INC E
  INC E
  LD HL,ShotList
BallShotLoop:
  XOR A
  LD C,(HL)
  BIT 7,C
  JR NZ,BallShotDone
  INC HL
  LD B,(HL)
  INC HL
  LD A,(HL)
  INC HL
  OR A
  JR Z,BallShotLoop
  LD A,C
  SUB E
  CP $FC
  JR C,BallShotLoop
  LD A,B
  SUB D
  SUB $09
  CP $F6
  JR C,BallShotLoop
  LD D,B                  ; hit: the shot erased and freed
  LD E,C
  CALL XorShot
  DEC HL
  LD (HL),$00
  LD A,$01
BallShotDone:
  POP HL
  POP DE
  POP BC
  RET

; A ball touching the player kills him (and itself)
;
; Main loop, every pass. PlayerContact with a box of 8 lines by 4 units for
; each live ball; a touch: BallHit, the sound $C155 again, then KillPlayer (no
; exoskeleton test: a ball kills through it).
;
; w030: 7 touches (immune clones).
BallsTouchPlayer:
  LD HL,BallList
BallsTouchPlayerLoop:
  LD E,(HL)
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  INC HL
  INC HL
  OR A
  JR Z,BallsTouchPlayerLoop
  LD BC,$0804
  CALL PlayerContact
  OR A
  JR Z,BallsTouchPlayerLoop
  CALL BallHit
  CALL PlaySfxExplosion
  JP KillPlayer
