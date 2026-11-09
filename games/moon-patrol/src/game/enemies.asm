; --------------------------------------------------------------------------------------------------------------------
; enemies.asm: The ground enemies: the tank and its shell, the low flyer from behind, the boulders and the green plant
;
; The object handlers of the tank (course command $98BE), the low flyer that comes from behind ($98F3), the boulders
; of three sizes ($9917 / $991C / $9921) and the green plant ($9955), with the same record protocol as the UFOs
; (module objects): the handler gets HL = record +2 and returns HL at the next record, and changes its record's
; handler word to explode or end.
;
; Each one scrolls left with the ground ($B235, while the buggy lives), is tested against the buggy (the kill $A7DD)
; and the forward shot $5B60 (only the UFOs and their bombs meet the upward shots), and scores when shot or when the
; buggy passes over it (its x AND $FC equal to the object's x). The scores are the SCORE ADVANCE TABLE's, except the
; green plant's jump: the code gives 200, the table says 250.
;
; The immune clone of i1 / i2 makes the kill a RET, so there the object that touches the buggy explodes and scores as
; if shot: most of the explosions of the low flyer, the shell and the plant in i2 are touches, not shots (the notes
; count them).
; --------------------------------------------------------------------------------------------------------------------

; The tank: rolls in from the right with the ground, fires its shell, 250 when
; shot, 200 when jumped
;
; Record (14 bytes): +2 wait, +3 sprite $13, +4 y $8F, +5 x $E7, +6 height $11,
; +7 width $14, +8 to +13 the shell (TankShellHandler). After the wait, each
; pass: erases the sprite (not on the first pass, x = $E7), x - the scroll step
; $B235 while the buggy lives (off the left side: TankGone), then the tests:
; the buggy (the kill $A7DD) or the forward shot ShotForward $5B60 (spent) both
; explode the tank: sprite $32, TankExplodeHandler in the record, 250 points
; ($92D3, BC = $0250), $B270 cleared. Else 200 when the buggy's x AND $FC, less
; 1, equals the tank's x, and the sprite is drawn at x + the band's scroll step
; ($AF74). Then the shell part runs (TankShellHandler).
;
; Witness: i1 912 runs (frames 23 663-28 206, Beginner V W Y), i2 2503 (2241-28
; 706, Champion B E I M N S T W Y). Shot i1 9, i2 19 ($9F07); touched i2 6
; ($9EF3). The jump score $9F32 was not executed in any recording (game, a1,
; g1, t1, p2, h1, i1, i2, h2): known only from the code.
TankHandler:
  LD A,(HL)
  AND A
  JR Z,TankActive
  DEC A
  LD (HL),A
  JP TankRecordSkip
TankActive:
  PUSH HL
  INC HL
  LD C,(HL)
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD A,D
  CP $E7
  JR Z,TankScroll
  LD A,C
  EX DE,HL
  CALL DrawSprite
  EX DE,HL
TankScroll:
  LD A,(DeathStep)        ; x - the scroll step while the buggy lives; off the
                          ; left side: gone
  INC A
  JR NZ,TankHitTests
  LD A,(GroundSpeed)
  NEG
  ADD A,(HL)
  LD (HL),A
  JP NC,TankGone
TankHitTests:
  DEC HL                  ; the buggy
  EXX
  LD HL,BuggyY
  EXX
  CALL BoxOverlap
  JR C,TankShotTest
  CALL BuggyKill
  JR TankHit
TankShotTest:
  DEC HL                  ; the forward shot
  DEC HL
  DEC HL
  EXX
  LD HL,ShotForward
  EXX
  CALL BoxOverlap
  JR C,TankJumpTest
  LD A,$FF
  LD (ShotForward+2),A
TankHit:
  LD DE,-$0004            ; explosion sprite $32, TankExplodeHandler, 250
                          ; points
  ADD HL,DE
  LD (HL),$32
  DEC HL
  DEC HL
  LD DE,TankExplodeHandler
  LD (HL),D
  DEC HL
  LD (HL),E
  LD DE,$0000
  LD BC,$0250
  CALL ScoreAdd
  XOR A
  LD (TankSeen),A
  JR TankHitDone
TankJumpTest:
  DEC HL                  ; the buggy over the tank: 200
  DEC HL
  LD A,(BuggyX)
  AND $FC
  DEC A
  CP (HL)
  JR NZ,TankDraw
  LD DE,$0000
  LD BC,$0200
  PUSH HL
  CALL ScoreAdd
  POP HL
TankDraw:
  LD D,(HL)
  DEC HL
  LD E,(HL)
  DEC HL
  EX DE,HL
  CALL ScrollAdjustIfAlive
  LD A,(DE)
  CALL DrawSprite
  JR TankShellPart
TankHitDone:
  POP HL

; The tank's explosion: five frames drawn 3 rows up, then the record goes on as
; the shell alone
;
; A shell still waiting to be fired (wait +8 not 0) is cancelled ($FF). Erases
; the last frame (not the first, $32), scrolls x with the ground while the
; buggy lives, steps the sprite +3 and draws it at (y - 3, x + the band's
; step): $32-$36. At $37: TankGone. Falls into TankShellHandler. Witness: i1 45
; passes (frames 24 668-28 241), i2 125.
TankExplodeHandler:
  PUSH HL
  PUSH HL
  LD BC,$0006
  ADD HL,BC
  LD A,(HL)
  AND A
  JR Z,TankExplodeErase
  LD (HL),$FF
TankExplodeErase:
  POP HL
  INC HL
  LD A,(HL)
  INC HL
  LD E,(HL)
  INC HL
  CP $32
  JR Z,TankExplodeScroll
  LD D,(HL)
  EX DE,HL
  DEC L
  DEC L
  DEC L
  CALL DrawSprite
  EX DE,HL
TankExplodeScroll:
  LD A,(DeathStep)
  INC A
  JR NZ,TankExplodeDraw
  LD A,(GroundSpeed)
  NEG
  ADD A,(HL)
  LD (HL),A
TankExplodeDraw:
  LD D,(HL)
  DEC HL
  LD E,(HL)
  DEC HL
  EX DE,HL
  CALL ScrollAdjustIfAlive
  LD A,(DE)
  INC A
  LD (DE),A
  CP $37
  JP NC,TankGone
  DEC L
  DEC L
  DEC L
  CALL DrawSprite

; TankShellPart
;
; Used by the routine at TankHandler.
TankShellPart:
  POP HL                  ; the shell part runs after the tank

; The tank's shell: fired 8 passes after the tank appears, flies left, 20 when
; shot, 15 when jumped
;
; Shell fields: +8 wait (8 from the course command; 0 in flight, $FF done), +9
; sprite (0 not yet fired, then $3B), +10 y $93, +11 x $C1, +12 height 3, +13
; width 7. HL = record +2 on entry, back at the next record (+12) on return. In
; flight it is erased, moves left by 2 + the scroll step ($B235 masked by $B216
; rotated left 3: the whole step while the buggy lives), and past the left side
; ends (+8 = $FF).
;
; Tests: the buggy (the kill) or the forward shot (spent): 20 points ($0020),
; the shell ends. Else 15 ($0015) when the buggy's x AND $FC, less 1, equals
; its x, and it is drawn at x + the band's step.
;
; Witness: i1 2961 runs (as the record's handler from frame 24 476), i2 5612.
; Fired i1 7, i2 24 ($9FB1); on the buggy i1 6, i2 19 ($9FD3; every 20 of the
; runs came from a touch: the shot path $9FE7 was not executed in any
; recording); jumped i1 1, i2 4 ($A000).
TankShellHandler:
  LD BC,$0006
  ADD HL,BC
  LD A,(HL)
  CP $FF
  JP Z,TankShellNext
  AND A
  JR Z,TankShellActive
  DEC A
  LD (HL),A
  JR TankShellNext
TankShellActive:
  PUSH HL
  INC HL
  LD A,(HL)
  AND A
  JR Z,TankShellFire
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  CALL DrawSprite
  EX DE,HL
  JR TankShellMove
TankShellFire:
  LD (HL),$3B             ; first pass: sprite $3B
  INC HL
  INC HL
TankShellMove:
  LD A,(GroundSpeed)      ; x - (2 + the scroll step)
  LD C,A
  LD A,(DeathStep)
  RLCA
  RLCA
  RLCA
  AND C
  ADD A,$02
  NEG
  ADD A,(HL)
  LD (HL),A
  JR NC,TankShellEnd
  DEC HL
  EXX
  LD HL,BuggyY
  EXX
  CALL BoxOverlap
  JR C,TankShellShotTest
  CALL BuggyKill
  JR TankShellHit
TankShellShotTest:
  DEC HL
  DEC HL
  DEC HL
  EXX
  LD HL,ShotForward
  EXX
  CALL BoxOverlap
  JR C,TankShellJumpTest
  LD A,$FF
  LD (ShotForward+2),A
TankShellHit:
  LD DE,$0000             ; 20 points, the shell ends
  LD BC,$0020
  CALL ScoreAdd
  JR TankShellEnd
TankShellJumpTest:
  DEC HL                  ; the buggy over the shell: 15
  DEC HL
  LD A,(BuggyX)
  AND $FC
  DEC A
  CP (HL)
  JR NZ,TankShellDraw
  LD DE,$0000
  LD BC,$0015
  PUSH HL
  CALL ScoreAdd
  POP HL
TankShellDraw:
  LD D,(HL)
  DEC HL
  LD E,(HL)
  DEC HL
  EX DE,HL
  CALL ScrollAdjustIfAlive
  LD A,(DE)
  CALL DrawSprite
  POP HL
TankShellNext:
  LD BC,$0006             ; the next record: 12 bytes on
  ADD HL,BC
  RET
TankShellEnd:
  POP HL                  ; the shell is done: +8 = $FF
  LD (HL),$FF
  JR TankShellNext

; The tank has left or exploded: the record's handler becomes TankShellHandler,
; which runs at once
;
; Entered by a JP with the record +2 on the stack, from TankHandler (off the
; left side) and TankExplodeHandler (the last frame). The wait +2 is always 0
; here, so the other choice, TankRecordSkip ($A02A), was not executed in any
; recording: known only from the code. Witness: i1 9, i2 25.
TankGone:
  POP HL
  LD A,(HL)
  AND A
  LD DE,TankShellHandler
  JR Z,TankGoneSet
  LD DE,TankRecordSkip
TankGoneSet:
  DEC HL
  LD (HL),D
  DEC HL
  LD (HL),E
  INC HL
  INC HL
  JP TankShellHandler

; A tank record still waiting: steps HL 12 bytes to the next record
;
; Reached from TankHandler while the wait +2 counts down. Witness: i1 781, i2
; 1932.
TankRecordSkip:
  LD BC,$000C
  ADD HL,BC
  RET

; The low flyer from behind: creeps in from the left, pauses, crosses the
; screen, 300 / 500 / 800 when shot, 125 when jumped
;
; Record (9 bytes): +2 wait, +3 sprite $14, +4 pause count, +5 y $91, +6 x 0,
; +7 height 8, +8 width $0C. Drawn in the ink of the current colour set (byte
; +3 of the set at $B230, in E'). Each pass after the wait: erases the sprite
; (not while x = 0), then the pace: x + 1 up to $10; at $0F a pause of 16-23
; passes (FRAMES XOR R) and it waits at $10; then x + 4 a pass; at $88 a pause
; of 4-11 and it waits at $8C; then x + 4 to $F0, where it is gone
; (LowFlyerGone). While the buggy is not alive ($B216 not $FF) x also moves by
; the scroll step.
;
; Tests: the buggy (the kill) or the forward shot (spent): sprite $36,
; LowFlyerExplodeHandler, a random score of 300, 500 or 800 (FRAMES XOR R AND
; 3, not 0, picks a bit of $C0 rotated: BC = $0300 / $0500 / $0800), $B26C
; cleared: the ??? of the SCORE ADVANCE TABLE. Else 125 ($0125) when the
; buggy's x AND $FC equals its x, and it is drawn at x + the band's step
; ($AF74).
;
; Champion only. Witness: i2 430 runs (frames 1353-29 538; the command $98F3 at
; Champion A and Z). Exploded i2 4, all on the buggy ($A0C4); the shot path
; $A0D8 was not executed in any recording; jumped i2 1 ($A116).
LowFlyerHandler:
  LD A,(HL)
  AND A
  JR Z,LowFlyerActive
  DEC A
  LD (HL),A
  JP LowFlyerRecordSkip
LowFlyerActive:
  PUSH HL
  INC HL
  LD C,(HL)
  INC HL
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD A,D
  AND A
  JR Z,LowFlyerPace
  LD A,C
  EX DE,HL
  EXX
  LD IX,(ColourScheme)
  LD E,(IX+$03)
  EXX
  CALL DrawSprite
  EX DE,HL
LowFlyerPace:
  LD A,(HL)               ; x = $0F: a pause of 16-23
  CP $0F
  JR NZ,LowFlyerPaceTest
  DEC HL
  DEC HL
  EX AF,AF'
  LD A,(FRAMES)
  LD B,A
  LD A,R
  XOR B
  AND $07
  ADD A,$10
  LD (HL),A
  EX AF,AF'
  INC HL
  INC HL
LowFlyerPaceTest:
  CP $10                  ; below $10: x + 1; at $10: wait
  JR Z,LowFlyerWait
  JR NC,LowFlyerPastEdge
  INC (HL)
  JR LowFlyerScroll
LowFlyerPastEdge:
  CP $88                  ; x = $88: a pause of 4-11
  JR NZ,LowFlyerAtStop
  DEC HL
  DEC HL
  EX AF,AF'
  LD A,(FRAMES)
  LD B,A
  LD A,R
  XOR B
  AND $07
  ADD A,$04
  LD (HL),A
  INC HL
  INC HL
  EX AF,AF'
LowFlyerAtStop:
  CP $8C                  ; x = $8C: wait
  JR NZ,LowFlyerAdvance
LowFlyerWait:
  DEC HL                  ; count the pause down, then go on
  DEC HL
  DEC (HL)
  INC HL
  INC HL
  JR NZ,LowFlyerScroll
LowFlyerAdvance:
  LD A,(HL)               ; x + 4; at $F0 gone
  ADD A,$04
  CP $F0
  JP Z,LowFlyerGone
  LD (HL),A
LowFlyerScroll:
  LD A,(DeathStep)        ; only while the buggy is not alive
  INC A
  JR Z,LowFlyerHitTests
  LD A,(GroundSpeed)
  ADD A,(HL)
  LD (HL),A
  CP $F0
  JP Z,LowFlyerGone
LowFlyerHitTests:
  DEC HL                  ; the buggy
  EXX
  LD HL,BuggyY
  EXX
  CALL BoxOverlap
  JR C,LowFlyerShotTest
  CALL BuggyKill
  JR LowFlyerHit
LowFlyerShotTest:
  DEC HL                  ; the forward shot
  DEC HL
  DEC HL
  EXX
  LD HL,ShotForward
  EXX
  CALL BoxOverlap
  JR C,LowFlyerJumpTest
  LD A,$FF
  LD (ShotForward+2),A
LowFlyerHit:
  LD DE,-$0005            ; explosion sprite $36, LowFlyerExplodeHandler
  ADD HL,DE
  LD (HL),$36
  DEC HL
  DEC HL
  LD DE,LowFlyerExplodeHandler
  LD (HL),D
  DEC HL
  LD (HL),E
LowFlyerScoreRandom:
  LD A,(FRAMES)            ; 1-3 from FRAMES XOR R
  LD B,A
  LD A,R
  XOR B
  AND $03
  JR Z,LowFlyerScoreRandom
  LD B,A
  LD A,$C0
LowFlyerScoreRotate:
  RLCA                    ; $C0 rotated 1-3 times AND 7, + 2: 3, 5 or 8 hundred
  DJNZ LowFlyerScoreRotate
  AND $07
  ADD A,$02
  LD DE,$0000
  LD B,A
  LD C,E
  CALL ScoreAdd
  XOR A
  LD (FlyerSeen),A
  JR LowFlyerHitDone
LowFlyerJumpTest:
  DEC HL                  ; the buggy under it: 125
  DEC HL
  LD A,(BuggyX)
  AND $FC
  CP (HL)
  JR NZ,LowFlyerDraw
  LD DE,$0000
  LD BC,$0125
  PUSH HL
  CALL ScoreAdd
  POP HL
LowFlyerDraw:
  LD D,(HL)
  DEC HL
  LD E,(HL)
  DEC HL
  DEC HL
  EX DE,HL
  CALL ScrollAdjustIfAlive
  LD A,(DE)
  EXX
  LD IX,(ColourScheme)
  LD E,(IX+$03)
  EXX
  CALL DrawSprite
  JR LowFlyerDone
LowFlyerHitDone:
  POP HL

; The low flyer's explosion: frames $36-$3A in place, then the record is spent
;
; Erases the last frame (not the first, $36), steps the sprite and draws it at
; (y, x + the band's step) in the colour set's ink. At $3B: LowFlyerGone.
; Witness: i2 20 passes (frames 2100-29 565).
LowFlyerExplodeHandler:
  PUSH HL
  INC HL
  LD A,(HL)
  INC HL
  INC HL
  LD E,(HL)
  INC HL
  CP $36
  JR Z,LowFlyerExplodeNext
  LD D,(HL)
  EX DE,HL
  EXX
  LD IX,(ColourScheme)
  LD E,(IX+$03)
  EXX
  CALL DrawSprite
  EX DE,HL
LowFlyerExplodeNext:
  LD D,(HL)
  DEC HL
  LD E,(HL)
  DEC HL
  DEC HL
  EX DE,HL
  CALL ScrollAdjustIfAlive
  LD A,(DE)
  INC A
  LD (DE),A
  CP $3B
  JR NC,LowFlyerGone
  EXX
  LD IX,(ColourScheme)
  LD E,(IX+$03)
  EXX
  CALL DrawSprite

; LowFlyerDone
;
; Used by the routine at LowFlyerHandler.
LowFlyerDone:
  POP HL

; LowFlyerRecordSkip
;
; Used by the routine at LowFlyerHandler.
LowFlyerRecordSkip:
  LD BC,$0007             ; the next record: 7 bytes on
  ADD HL,BC
  RET
; This entry point is used by the routines at LowFlyerHandler and
; LowFlyerExplodeHandler.
LowFlyerGone:
  POP HL                  ; the record's handler: LowFlyerRecordSkip
  DEC HL
  LD DE,LowFlyerRecordSkip
  LD (HL),D
  DEC HL
  LD (HL),E
  INC HL
  INC HL
  JR LowFlyerRecordSkip

; A print string for $FFD0 that ends at its first byte: under it the build date
; 03:40 30/10/84, never printed
;
; The life start prints it at $9126 (LD HL,$A182, CALL $FFD0). $FFD0 stops at
; $1F, the first byte, so nothing is printed: only $A182 is read (game 20, a1
; 4, g1 4, p2 8, h1 4, i1 6, i2 6, once a life start); $A183-$A195 are never
; read in any recording. A leftover of the build, like the date 03:35 30/10/84
; at $7F05 five minutes earlier.
LifeStartDateText:
  DEFB $1F                ; the end code $1F: the string ends here
  DEFB $00,$29,$1A,$02    ; print codes of $FFD0 ($00, $29, $1A $02), never
                          ; read
  DEFB $30,$33,$3A,$34,$30 ; "03:40 30/10/84", the build date
  DEFB $20,$33,$30,$2F,$31
  DEFB $30,$2F,$38,$34
  DEFB $1F                ; the end code $1F

; A boulder: one of three sizes rolls in with the ground, 100 / 150 / 200 when
; shot, 50 / 100 / 150 when jumped
;
; Record (8 bytes, commands $9917 / $991C / $9921): +2 wait, +3 sprite ($40
; small, $44 medium, $4C large), +4 y = $A0 - size, +5 x = 256 - size, +6
; height, +7 width = the size (8, 12, 16). Each pass after the wait: erases the
; sprite (not on the first pass, x + size = 0), x - the scroll step while the
; buggy lives (at x = 0: BoulderGone).
;
; Tests: the buggy (the kill) or the forward shot (spent): the explosion sprite
; ($7F small, $57 medium, $5F large), BoulderExplodeHandler, 100 / 150 / 200
; points by the sprite (below $44, below $4C, else), $B26E cleared. Else 50 /
; 100 / 150 when the buggy's x AND $FC equals its x. Then, while the buggy
; lives, it rolls: the sprite steps through small $40-$43, medium $44-$4B,
; large $4C-$57; drawn at x + the band's step.
;
; Champion only. Witness: i2 3448 runs (frames 3118-29 354, Champion C G M W
; Y). Exploded i2 26 (small 4, medium 10, large 12; 22 of them touches $A1CD, 4
; shots $A1E1); jumped i2 9 (small 3, medium 3, large 3).
BoulderHandler:
  LD A,(HL)
  AND A
  JR Z,BoulderActive
  DEC A
  LD (HL),A
  JP BoulderRecordSkip
BoulderActive:
  PUSH HL
  INC HL
  LD C,(HL)
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD A,D
  INC HL
  ADD A,(HL)
  DEC HL
  JR Z,BoulderScroll
  LD A,C
  EX DE,HL
  CALL DrawSprite
  EX DE,HL
BoulderScroll:
  LD A,(DeathStep)        ; x - the scroll step; at 0 gone
  INC A
  JR NZ,BoulderHitTests
  LD A,(GroundSpeed)
  NEG
  ADD A,(HL)
  LD (HL),A
  JP Z,BoulderGone
BoulderHitTests:
  DEC HL                  ; the buggy
  EXX
  LD HL,BuggyY
  EXX
  CALL BoxOverlap
  JR C,BoulderShotTest
  CALL BuggyKill
  JR BoulderHit
BoulderShotTest:
  DEC HL                  ; the forward shot
  DEC HL
  DEC HL
  EXX
  LD HL,ShotForward
  EXX
  CALL BoxOverlap
  JR C,BoulderJumpTest
  LD A,$FF
  LD (ShotForward+2),A
BoulderHit:
  LD DE,-$0004            ; by size: explosion sprite and 100 / 150 / 200
  ADD HL,DE
  LD A,(HL)
  PUSH HL
  LD H,$7F
  LD BC,$0100
  CP $44
  JR C,BoulderExplodeSet
  LD H,$57
  LD BC,$0150
  CP $4C
  JR C,BoulderExplodeSet
  LD H,$5F
  LD BC,$0200
BoulderExplodeSet:
  LD A,H
  POP HL
  LD (HL),A
  DEC HL
  DEC HL
  LD DE,BoulderExplodeHandler
  LD (HL),D
  DEC HL
  LD (HL),E
  LD DE,$0000
  CALL ScoreAdd
  XOR A
  LD (BoulderSeen),A
  JP BoulderHitDone
BoulderJumpTest:
  DEC HL                  ; the buggy over it: 50 / 100 / 150
  DEC HL
  LD A,(BuggyX)
  AND $FC
  CP (HL)
  JR NZ,BoulderRoll
  PUSH HL
  DEC HL
  DEC HL
  LD A,(HL)
  LD BC,$0050
  CP $44
  JR C,BoulderJumpScore
  LD BC,$0100
  CP $4C
  JR C,BoulderJumpScore
  LD BC,$0150
BoulderJumpScore:
  LD DE,$0000
  CALL ScoreAdd
  POP HL
BoulderRoll:
  LD D,(HL)               ; the next frame of its size while the buggy lives
  DEC HL
  LD E,(HL)
  DEC HL
  EX DE,HL
  CALL ScrollAdjustIfAlive
  LD A,(DeathStep)
  INC A
  LD A,(DE)
  JR NZ,BoulderDraw
  INC A
  CP $44
  JR NZ,BoulderRollMedium
  LD A,$40
BoulderRollMedium:
  CP $4C
  JR NZ,BoulderRollLarge
  LD A,$44
BoulderRollLarge:
  CP $58
  JR NZ,BoulderDraw
  LD A,$4C
BoulderDraw:
  LD (DE),A
  CALL DrawSprite
  JR BoulderDone
BoulderHitDone:
  POP HL

; A boulder's explosion: five frames of its size, then the record is spent
;
; Frames small $7F-$83, medium $57-$5B, large $5F-$63; the frames $60-$63 and
; $7C-$7F are drawn one row higher. Erases the last frame (not the first:
; sprite AND $D7 = $57), scrolls x while the buggy lives, steps the sprite and
; draws it; when (sprite - $5C) AND $D7 = 0 ($5C, $64, $84): BoulderGone.
; Witness: i2 130 passes (frames 3411-29 144).
BoulderExplodeHandler:
  PUSH HL
  INC HL
  LD A,(HL)
  INC HL
  LD E,(HL)
  INC HL
  LD D,A
  AND $D7
  CP $57
  JR Z,BoulderExplodeScroll
  LD A,D
  AND $FC
  ADD A,$80
  CP $E0
  LD A,E
  ADC A,$FF
  LD E,A
  LD A,D
  LD D,(HL)
  EX DE,HL
  CALL DrawSprite
  EX DE,HL
BoulderExplodeScroll:
  LD A,(DeathStep)
  INC A
  JR NZ,BoulderExplodeDraw
  LD A,(GroundSpeed)
  NEG
  ADD A,(HL)
  LD (HL),A
BoulderExplodeDraw:
  LD D,(HL)
  DEC HL
  LD E,(HL)
  DEC HL
  EX DE,HL
  CALL ScrollAdjustIfAlive
  LD A,(DE)
  INC A
  LD (DE),A
  SUB $5C
  AND $D7
  JR Z,BoulderGone
  LD A,(DE)
  AND $FC
  ADD A,$80
  CP $E0
  LD A,L
  ADC A,$FF
  LD L,A
  LD A,(DE)
  CALL DrawSprite

; BoulderDone
;
; Used by the routine at BoulderHandler.
BoulderDone:
  POP HL

; BoulderRecordSkip
;
; Used by the routines at BoulderHandler and BoulderGone.
BoulderRecordSkip:
  LD BC,$0006             ; the next record: 6 bytes on
  ADD HL,BC
  RET

; BoulderGone
;
; Used by the routines at BoulderHandler and BoulderExplodeHandler.
BoulderGone:
  POP HL                  ; the record's handler: BoulderRecordSkip
  DEC HL
  LD DE,BoulderRecordSkip
  LD (HL),D
  DEC HL
  LD (HL),E
  INC HL
  INC HL
  JR BoulderRecordSkip

; The green plant: grows and shrinks in a 15-frame cycle as it scrolls in, 500
; when shot, 200 when jumped
;
; Record (8 bytes, command $9955): +2 wait, +3 frame (0 before the first pass,
; then 1-15), +4 y $90, +5 x $E4, +6 / +7 the hit box's height and width (set
; each pass). The plant is two sprites: the stem $63 + frame at (y + 16, x),
; and in frames 5-11 the head $6F + frame at (y, x), with the head's attributes
; on rows 18-19 (PlantColourOn; PlantColourOff in the other frames).
;
; The first pass clears 28 pixels of the ground's top row $A0 from x $E4
; ($A7F4) and sets $B288 bit 3 (tested and cleared at $A994), then draws frame
; 1. Later passes erase the sprites, x - the scroll step while the buggy lives
; (at 0: PlantGone), then the hit box from PlantHitBoxes by the frame: (y + dy,
; x + dx, dy, dx).
;
; Tests: the buggy (the kill) or the forward shot (spent): frame $7A,
; PlantExplodeHandler, 500 points ($0500), $B26A cleared. Else 200 ($0200) when
; the buggy's x AND $FC equals its x (the SCORE ADVANCE TABLE says 250). Then
; the next frame (15 wraps to 1) is drawn at x + the band's step.
;
; Champion only. Witness: i2 1497 runs (frames 4013-29 106, Champion D F K Q V
; X Y). Exploded i2 8, all touches ($A358; the shot path $A36F was not executed
; in any recording); jumped i2 4 ($A3A8).
PlantHandler:
  LD A,(HL)
  AND A
  JR Z,PlantActive
  DEC A
  LD (HL),A
  JP PlantRecordSkip
PlantActive:
  PUSH HL
  INC HL
  LD C,(HL)
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD A,C
  AND A
  JR Z,PlantFirst
  EX DE,HL
  CP $05
  JR C,PlantHeadHidden
  CP $0C
  JR NC,PlantHeadHidden
  ADD A,$6F               ; frames 5-11: the head $6F + frame, with the head's
                          ; colours
  PUSH HL
  CALL PlantColourOn
  CALL DrawSprite
  POP HL
  JR PlantStemErase
PlantHeadHidden:
  CALL PlantColourOff     ; other frames: plain colours
PlantStemErase:
  LD A,L                  ; the stem $63 + frame, 16 rows lower
  ADD A,$10
  LD L,A
  LD A,C
  ADD A,$63
  CALL DrawSprite
  EX DE,HL
  JR PlantScroll
PlantFirst:
  PUSH HL                 ; first pass: 28 pixels of the ground's top row
                          ; cleared
  LD HL,$E4A0
  LD E,$1C
  CALL PlotRun
  LD HL,PlayerFlags
  SET 3,(HL)
  POP HL
  JP PlantGrow
PlantScroll:
  LD A,(DeathStep)        ; x - the scroll step; at 0 gone
  INC A
  JR NZ,PlantHitBox
  LD A,(GroundSpeed)
  NEG
  ADD A,(HL)
  LD (HL),A
  JR NZ,PlantHitBox
  DEC HL
  LD L,(HL)
  LD H,A
  JP PlantGone
PlantHitBox:
  DEC HL                  ; PlantHitBoxes[frame - 1]: y + dy, x + dx, height
                          ; dy, width dx
  DEC HL
  LD A,(HL)
  INC HL
  PUSH HL
  DEC A
  RLCA
  RLCA
  LD E,A
  LD D,$00
  LD HL,PlantHitBoxes
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  POP HL
  LD A,(HL)
  ADD A,E
  LD (HL),A
  INC HL
  LD A,(HL)
  ADD A,D
  LD (HL),A
  INC HL
  LD (HL),E
  INC HL
  LD (HL),D
  DEC HL
  DEC HL
  DEC HL
  EXX
  LD HL,BuggyY
  EXX
  PUSH DE
  CALL BoxOverlap
  POP DE
  JR C,PlantShotTest
  PUSH DE
  CALL BuggyKill
  POP DE
  JR PlantHit
PlantShotTest:
  DEC HL                  ; the forward shot
  DEC HL
  DEC HL
  EXX
  LD HL,ShotForward
  EXX
  PUSH DE
  CALL BoxOverlap
  POP DE
  JR C,PlantJumpTest
  LD A,$FF
  LD (ShotForward+2),A
PlantHit:
  DEC HL                  ; frame $7A, PlantExplodeHandler, 500 points
  DEC HL
  LD A,(HL)
  SUB D
  LD (HL),A
  DEC HL
  LD A,(HL)
  SUB E
  LD (HL),A
  DEC HL
  LD (HL),$7A
  DEC HL
  DEC HL
  LD DE,PlantExplodeHandler
  LD (HL),D
  DEC HL
  LD (HL),E
  LD DE,$0000
  LD BC,$0500
  CALL ScoreAdd
  XOR A
  LD (PlantSeen),A
  JP PlantHitDone
PlantJumpTest:
  DEC HL                  ; the buggy over it: 200
  DEC HL
  LD A,(HL)
  SUB D
  LD (HL),A
  DEC HL
  LD A,(HL)
  SUB E
  LD (HL),A
  INC HL
  LD A,(BuggyX)
  AND $FC
  CP (HL)
  JR NZ,PlantGrow
  LD DE,$0000
  LD BC,$0200
  PUSH HL
  CALL ScoreAdd
  POP HL
PlantGrow:
  LD D,(HL)               ; the next frame, 15 wraps to 1
  DEC HL
  LD E,(HL)
  DEC HL
  EX DE,HL
  LD A,(DE)
  INC A
  CP $10
  JR C,PlantFrameSet
  LD A,$01
PlantFrameSet:
  LD (DE),A
  LD C,A
  CP $05
  JR C,PlantHeadless
  CP $0C
  JR NC,PlantHeadless
  PUSH HL
  CALL ScrollAdjustIfAlive
  LD A,C
  ADD A,$6F
  CALL PlantColourOn
  CALL DrawSprite
  POP HL
  JR PlantDrawStem
PlantHeadless:
  CALL PlantColourOff
PlantDrawStem:
  LD A,L
  ADD A,$10
  LD L,A
  CALL ScrollAdjustIfAlive
  LD A,C
  ADD A,$63
  CALL DrawSprite
  JR PlantDone
PlantHitDone:
  POP HL

; The green plant's explosion: frames $7A-$7E at (y + 4, x + 8) over the head's
; colours, then the record is spent
;
; The first pass (frame $7A) draws sprite $73 at (y + 16, x) instead of
; erasing; later passes erase the last frame. Scrolls x while the buggy lives,
; steps the frame and draws it with PlantColourOn. At $7F: PlantGone puts the
; plain colours back. Witness: i2 40 passes (frames 4348-28 413).
PlantExplodeHandler:
  PUSH HL
  INC HL
  LD C,(HL)
  INC HL
  LD A,(HL)
  ADD A,$04
  LD E,A
  INC HL
  LD A,(HL)
  ADD A,$08
  LD D,A
  LD A,C
  CP $7A
  JR Z,PlantExplodeFirst
  EX DE,HL
  CALL PlantColourOn
  CALL DrawSprite
  EX DE,HL
  JR PlantExplodeScroll
PlantExplodeFirst:
  LD A,E                  ; the first pass: sprite $73 at (y + 16, x)
  ADD A,$0C
  LD E,A
  LD A,D
  SUB $08
  LD D,A
  EX DE,HL
  CALL ScrollAdjustIfAlive
  LD A,$73
  CALL DrawSprite
  EX DE,HL
PlantExplodeScroll:
  LD A,(DeathStep)
  INC A
  JR NZ,PlantExplodeDraw
  LD A,(GroundSpeed)
  NEG
  ADD A,(HL)
  LD (HL),A
PlantExplodeDraw:
  LD A,(HL)
  ADD A,$08
  LD D,A
  DEC HL
  LD A,(HL)
  ADD A,$04
  LD E,A
  DEC HL
  EX DE,HL
  CALL ScrollAdjustIfAlive
  LD A,(DE)
  INC A
  LD (DE),A
  CP $7F
  JR NC,PlantGone
  CALL PlantColourOn
  CALL DrawSprite

; PlantDone
;
; Used by the routine at PlantHandler.
PlantDone:
  POP HL

; PlantRecordSkip
;
; Used by the routines at PlantHandler and PlantGone.
PlantRecordSkip:
  LD BC,$0006             ; the next record: 6 bytes on
  ADD HL,BC
  RET

; PlantGone
;
; Used by the routines at PlantHandler and PlantExplodeHandler.
PlantGone:
  CALL PlantColourOff     ; plain colours back; the record's handler:
                          ; PlantRecordSkip
  POP HL
  DEC HL
  LD DE,PlantRecordSkip
  LD (HL),D
  DEC HL
  LD (HL),E
  INC HL
  INC HL
  JR PlantRecordSkip

; Colours the plant's head: 3 or 4 cells of rows 18 and 19 at the plant's
; column
;
; HL = (L y, H x). PlantAttrAddress gives the cell and the count; each cell of
; rows 18 and 19 gets the paper of the colour set's byte +3 with the colour
; set's byte +4 paper as ink ($B230 the set), the next cell gets byte +3, and
; AttrRow20 $5A80 (row 20, column 0) gets byte +4. Keeps A (in A'), DE and HL.
; Witness: i2 546 (frames 4112-29 099).
PlantColourOn:
  EX AF,AF'
  PUSH DE
  PUSH HL
  CALL PlantAttrAddress
  LD IX,(ColourScheme)
  LD A,(IX+$03)
  AND $F8
  LD E,A
  LD A,(IX+$04)
  AND $38
  RRCA
  RRCA
  RRCA
  OR E
  LD DE,$0020

; PlantColourLoop
;
; Used by the routine at PlantColourOff.
PlantColourLoop:
  LD (HL),A               ; rows 18 and 19, B cells
  ADD HL,DE
  LD (HL),A
  AND A
  SBC HL,DE
  INC HL
  DJNZ PlantColourLoop
  LD A,(IX+$03)
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  LD A,(IX+$04)
  LD (AttrRow20),A
  POP HL
  POP DE
  EX AF,AF'
  RET

; Puts the plain colour (the colour set's byte +3) back on the plant's cells of
; rows 18 and 19
;
; As PlantColourOn, with the one colour for every cell. Witness: i2 564 (frames
; 4083-29 106).
PlantColourOff:
  EX AF,AF'
  PUSH DE
  PUSH HL
  CALL PlantAttrAddress
  LD IX,(ColourScheme)
  LD A,(IX+$03)
  LD DE,$0020
  JR PlantColourLoop

; HL = the attribute cell of row 18 under x, B = 3 cells, or 4 when x is not on
; a cell boundary
;
; In: H = x. HL = AttrRow18 $5A40 + x / 8; B = 3, + 1 when bit 2 of x is set.
; Witness: i2 1110 (frames 4083-29 106).
PlantAttrAddress:
  LD A,H
  AND $FC
  RRA
  RRA
  RRA
  LD E,A
  LD D,$00
  LD A,$03
  ADC A,$00
  LD B,A
  LD HL,AttrRow18
  ADD HL,DE
  RET

; The green plant's hit box by frame 1-15: dy, dx, then two bytes the code
; loads and never uses
;
; PlantHandler reads row frame - 1 into E, D, C, B; only E (dy) and D (dx) are
; used, as the box's offset and as its height and width. Bytes 3-4 look like
; the intended height and width (dy + byte 3 = 16 in every row, byte 4 the
; width), but C and B are overwritten by $A7FE: known only from the code. Read
; i2 28-40 times a row.
PlantHitBoxes:
  DEFB $10,$00,$00,$00    ; frames 1-4: the stem only
  DEFB $10,$00,$00,$00
  DEFB $10,$00,$00,$00
  DEFB $10,$00,$00,$00
  DEFB $0C,$08,$04,$08    ; frames 5-11: the head up and down
  DEFB $08,$05,$08,$0E
  DEFB $04,$01,$0C,$16
  DEFB $03,$02,$0D,$14
  DEFB $04,$01,$0C,$16
  DEFB $08,$05,$08,$0E
  DEFB $0C,$08,$04,$08
  DEFB $10,$00,$00,$00    ; frames 12-15: the stem only
  DEFB $10,$00,$00,$00
  DEFB $10,$00,$00,$00
  DEFB $10,$00,$00,$00
