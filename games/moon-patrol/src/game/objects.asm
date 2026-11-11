; --------------------------------------------------------------------------------------------------------------------
; objects.asm: The flying objects: the UFO saucers, the spinner, their bombs and the UFO retreat timer
;
; The course interpreter $9751 calls the handler word at the head of each object record of the object list $BEF8 with
; HL = the record + 2; the handler moves and draws its object and returns HL at the next record. An object changes
; state by writing a new handler word into its record: alive, exploding, gone (a handler that only steps HL over the
; record).
;
; One UFO record (20 bytes, made by the course commands $9821 / $9827 / $982D) holds a saucer or the spinner and its
; bomb: UfoHandler flies the UFO, UfoExplodeHandler plays its explosion, UfoBombHandler drops the bomb and carries on
; alone once the UFO is gone. The spinner's bomb makes a crater where it lands. UfoRetreatTimer (course command $98AA)
; sends every UFO off the screen when its wait runs out. Shooting scores: saucer 100, spinner 200, saucer bomb 5,
; spinner bomb 10, as the game's SCORE ADVANCE TABLE says.
; --------------------------------------------------------------------------------------------------------------------

; The UFO handler: waits, then flies a saucer or the spinner, turns at random,
; leaves on the retreat flag, explodes when shot
;
; HL = record +2 (the fields are in the notes: +2 wait, +3 sprite, +4 turn
; timer, +5 dy, +6 dx, +7 y, +8 x, +9 height, +10 width, +11 to +19 the bomb).
; While the wait +2 counts down it only steps HL to the next record
; (UfoRecordSkip). Then each pass: $B236 = $FF for the spinner (height +9 = 16)
; or 0 for a saucer; the first pass (turn timer $FF) gives a turn timer of
; 16-40 and clears the retreat flag $B237 and $B26D; later passes erase the old
; sprite at (y, x) (UfoSetColour, then the sprite drawer $A826, which draws by
; XOR).
;
; The move: when the turn timer runs out (reloaded with 16-72 from R) a UFO
; moving across starts moving up or down by 2, one moving up or down starts
; moving across by 2, the sign from bit 6 of R. x must stay below $F1 (else it
; turns to an up / down move), y in $18-$37 for a saucer, $18-$2F for the
; spinner (else it turns across). With the retreat flag $B237 set
; (UfoRetreatTimer) it moves 4 a pass towards the nearer side, and past it (x
; >= $F1) the record goes on as the bomb alone (UfoSaucerGone).
;
; Then the four upward shots ShotsUp $5B65 are tested against its box (y, x,
; height, width) with $A7FE. A hit marks the shot spent (its byte +2 = $FF),
; stops the UFO, sets the first explosion sprite ($26 saucer, $2E spinner),
; puts UfoExplodeHandler in the record and adds 100 (saucer) or 200 (spinner)
; to the score ($92D3, BC = $0100 + $0100 for the spinner), and clears $B267.
; Else the sprite steps on through its animation (saucer A 1-4, saucer B 5-10,
; spinner 11-14) and is drawn at the new place. Either way the bomb part
; (UfoBombHandler) runs after it in the same pass.
;
; Witness: game 44 runs, g1 / h1 204 (only the wait: no UFO reached the screen
; in those runs), i1 13 759 (8172 active, frames 1125-30 439), i2 11 528
; (445-33 813). UFOs shot: i1 37, i2 28 ($9C42). Turns: across to up / down i1
; 223, up / down to across i1 206. Retreat steps i1 462, i2 491.
UfoHandler:
  LD A,(HL)
  AND A
  JR Z,UfoActive
  DEC A
  LD (HL),A
  JP UfoRecordSkip
UfoActive:
  PUSH HL                 ; the wait is over
  INC HL
  PUSH HL
  LD DE,$0006
  ADD HL,DE
  LD A,(HL)
  POP HL
  CP $10
  LD A,$00
  JR NZ,UfoKindSet
  DEC A
UfoKindSet:
  LD (UfoWave),A          ; $B236 = $FF: the spinner (height 16), 0: a saucer
                          ; (height 8)
  LD C,(HL)
  INC HL
  LD A,(HL)
  CP $FF
  JR NZ,UfoErase
  LD A,R                  ; the first pass: the UFO enters the screen
  AND $18
  ADD A,$10
  LD (HL),A
  XOR A
  LD (UfoWaveSeen),A      ; $B26D and the retreat flag $B237 cleared: a new UFO
                          ; cancels the retreat
  LD (UfosLeave),A
  LD BC,$0004
  ADD HL,BC
  JR UfoMove
UfoErase:
  INC HL                  ; erase the sprite at its old place (XOR draw)
  INC HL
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  LD A,C
  CALL UfoSetColour
  LD A,C
  CALL DrawSprite
  EX DE,HL
UfoMove:
  LD D,(HL)               ; D = x, E = y, B = dx, C = dy, HL = the turn timer
  DEC HL
  LD E,(HL)
  DEC HL
  LD B,(HL)
  DEC HL
  LD C,(HL)
  DEC HL
  LD A,(HL)
  DEC A
  LD (HL),A
  JR NZ,UfoStep
  LD A,R
  AND $38
  ADD A,$10
  LD (HL),A
  LD A,B
  AND A
  JR Z,UfoTurnAcross
UfoTurnVertical:
  LD B,$00                ; move up or down by 2, at random
  LD A,R
  BIT 6,A
  LD A,$02
  JR Z,UfoSetDy
  NEG
UfoSetDy:
  LD C,A
  JR UfoStep
UfoTurnAcross:
  LD C,$00                ; move across by 2, at random
  LD A,R
  BIT 6,A
  LD A,$02
  JR Z,UfoSetDx
  NEG
UfoSetDx:
  LD B,A
UfoStep:
  LD A,(UfosLeave)        ; the retreat flag set: 4 a pass to the nearer side
  AND A
  LD A,D
  JR Z,UfoStepX
  CP $80
  JR NC,UfoLeaveRight
  SUB $04
  JR UfoLeaveCheck
UfoLeaveRight:
  ADD A,$04
UfoLeaveCheck:
  CP $F1                  ; past the side: the UFO is gone, its bomb goes on
  JP NC,UfoSaucerGone
  LD D,A
  LD C,$00
  LD (HL),$FE
  JR UfoStepY
UfoStepX:
  LD A,D                  ; x + dx, turn at the sides
  ADD A,B
  CP $F1
  JR NC,UfoTurnVertical
  LD D,A
UfoStepY:
  LD A,E                  ; y + dy, kept in $18 .. $38 - (8 for the spinner)
  ADD A,C
  PUSH BC
  LD B,A
  LD A,(UfoWave)
  AND $08
  CPL
  ADD A,$39
  CP B
  LD A,B
  POP BC
  JR C,UfoTurnAcross
  CP $18
  JR C,UfoTurnAcross
  LD E,A
  INC HL
  LD (HL),C
  INC HL
  LD (HL),B
  INC HL
  LD (HL),E
  INC HL
  LD (HL),D
  DEC HL
  EXX
  LD HL,ShotsUp             ; the four upward shots
  LD B,$04
UfoShotLoop:
  PUSH BC
  CALL BoxOverlap
  POP BC
  JR NC,UfoShot
  INC HL
  EXX
  DEC HL
  DEC HL
  DEC HL
  EXX
  DJNZ UfoShotLoop
  EXX
  JR UfoAnimate
UfoShot:
  DEC HL                  ; hit: the shot spent, the UFO stopped, the explosion
                          ; set
  LD (HL),$FF
  EXX
  LD BC,-4
  ADD HL,BC
  LD (HL),$00
  DEC HL
  LD (HL),$00
  DEC HL
  LD (HL),$FE
  DEC HL
  LD A,(UfoWave)
  AND $08
  ADD A,$26
  LD (HL),A
  DEC HL
  DEC HL
  LD DE,UfoExplodeHandler ; the record's handler: UfoExplodeHandler
  LD (HL),D
  DEC HL
  LD (HL),E
  PUSH HL                 ; 100 for a saucer, 200 for the spinner
  LD DE,$0000
  LD BC,$0100
  LD A,(UfoWave)
  AND $01
  ADD A,B
  LD B,A
  CALL ScoreAdd
  POP HL
  XOR A
  LD (UfoSeen),A
  JR UfoShotDone
UfoAnimate:
  LD E,(HL)               ; no hit: the next animation frame, drawn at the new
                          ; place
  INC HL
  LD D,(HL)
  LD BC,-5
  ADD HL,BC
  LD A,(HL)
  CALL UfoSetColour
  LD A,(HL)
  INC A
  CP $05
  JR Z,UfoWrapSaucerA
  CP $0B
  JR Z,UfoWrapSaucerB
  CP $0F
  JR NZ,UfoDraw
  LD A,$0B
  JR UfoDraw
UfoWrapSaucerB:
  LD A,$05                ; saucer B: frames 5-10
  JR UfoDraw
UfoWrapSaucerA:
  LD A,$01                ; saucer A: frames 1-4
UfoDraw:
  LD (HL),A
  EX DE,HL
  CALL DrawSprite
  JR UfoBombPart
UfoShotDone:
  POP HL

; The UFO's explosion: five frames in place, then the record goes on as its
; bomb alone
;
; HL = record +2. Erases the last frame (not on the first pass, sprite $26 or
; $2E), steps the sprite +3 and draws it at (y, x): saucer $26-$2A, spinner
; $2E-$32. At $2B / $33 the record becomes UfoBombHandler (UfoSaucerGone).
; Falls into UfoBombHandler: a bomb already falling falls on.
;
; Put in the record by UfoHandler at a hit. Witness: i1 185 passes (frames
; 2236-30 297), i2 140 (994-33 311).
UfoExplodeHandler:
  PUSH HL
  INC HL
  LD A,(HL)
  LD DE,$0005
  ADD HL,DE
  LD C,A
  AND $F7
  CP $26
  JR Z,UfoExplodeNext
  DEC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  PUSH HL
  EX DE,HL
  LD A,C
  CALL UfoSetColour
  LD A,C
  CALL DrawSprite
  EX DE,HL
  POP HL
UfoExplodeNext:
  LD D,(HL)               ; the next frame: past the last one the UFO is gone
  DEC HL
  LD E,(HL)
  LD BC,-4
  ADD HL,BC
  LD A,(HL)
  INC A
  LD (HL),A
  CP $2B
  JP Z,UfoSaucerGone
  CP $33
  JP Z,UfoSaucerGone
  CALL UfoSetColour
  LD A,(HL)
  EX DE,HL
  CALL DrawSprite

; UfoBombPart
;
; Used by the routine at UfoHandler.
UfoBombPart:
  POP HL                  ; the bomb part runs after the UFO

; The UFO's bomb: dropped under the UFO, falls, explodes into a crater for the
; spinner, scores 5 / 10 when shot
;
; HL = record +2. The bomb's own wait +11 (16-47 from R) counts down first. Not
; dropped yet (+13 = $FF): when the UFO is gone too (the record's handler is
; UfoBombHandler) the record is spent (UfoRecordSkip from now on); else the
; bomb starts under the UFO, y + 8 (saucer) or y + 16 (spinner), x + 16, with
; sprite $1D and a timer of 8 (no drop when the UFO's x >= $E7). A bomb in
; flight is erased first.
;
; It moves by dx 4, dy 4 for 8 passes, then falls straight down by 4 with
; sprite $1E (also at x >= $F7). At the ground (y >= $A0): a saucer's bomb
; ends; the spinner's bomb tests five places 4 apart from x - 5 on the screen
; rows 159 and 162 ($5760, $5280, the pixel masks from the table $7D00) and,
; when they are all clear, appends a crater record ($9A92, wait 0, x AND $FC)
; at the end of the object list ($B261) before the end marker $975E, clears 16
; pixels of the ground's top row $A0 ($A7F4) and draws the crater sprite $10.
;
; In flight it is tested against the four upward shots ShotsUp $5B65, then the
; forward shot ShotForward $5B60: a hit spends the shot and adds 5 (saucer
; bomb) or 10 (spinner bomb), BC = 5 + ($B236 AND 5). Then against the buggy
; (the box at $B212): a touch calls the kill $A7DD. Else it is drawn at (y, x +
; the band's scroll step, $AF74).
;
; When the bomb ends: if the UFO is gone the record is spent, else the bomb is
; reloaded (wait 16-47, sprite $1D, not dropped) for the next drop.
;
; Witness: i1 9546 passes (8319 as the record's handler, frames 1560-30 439),
; i2 8334 (771-33 813). Drops i1 143, i2 131; craters made i1 15, i2 16
; ($9DAD); bombs shot i1 12, i2 18; bombs on the buggy i1 16, i2 17 ($9E28, the
; kill a RET in the immune clone).
UfoBombHandler:
  LD DE,$0009
  ADD HL,DE
  LD A,(HL)
  AND A
  JR Z,UfoBombActive
  DEC A
  LD (HL),A
  JP UfoBombNext
UfoBombActive:
  PUSH HL                 ; the bomb's wait is over
  DEC HL
  DEC HL
  LD A,(HL)
  INC HL
  INC HL
  CP $10
  LD A,$00
  JR NZ,UfoBombKindSet
  DEC A
UfoBombKindSet:
  LD (UfoWave),A          ; $B236 = $FF for the spinner's bomb
  INC HL
  LD C,(HL)
  INC HL
  LD A,(HL)
  CP $FF
  JR NZ,UfoBombErase
  LD (HL),$08             ; not dropped yet: drop it now
  PUSH HL
  PUSH BC
  LD BC,-12               ; the record's handler word: is the UFO gone?
  ADD HL,BC
  POP BC
  LD D,(HL)
  DEC HL
  LD E,(HL)
  LD HL,UfoBombHandler
  AND A
  SBC HL,DE
  POP HL
  JR NZ,UfoBombDrop
  POP HL
  LD BC,-10               ; UFO and bomb both gone: the record is spent
  JP UfoRecordSpent
UfoBombDrop:
  PUSH BC                 ; under the UFO: y + 8 / + 16, x + 16
  LD BC,-5
  ADD HL,BC
  LD D,(HL)
  DEC HL
  LD E,(HL)
  LD BC,$0009
  ADD HL,BC
  POP BC
  LD A,(UfoWave)
  AND $08
  ADD A,$08
  ADD A,E
  AND $FC
  LD (HL),A
  INC HL
  LD A,D
  CP $E7
  JP NC,UfoBombEnd
  ADD A,$10
  LD (HL),A
  JR UfoBombMove
UfoBombErase:
  INC HL                  ; a bomb in flight: erase it
  INC HL
  INC HL
  INC HL
  LD A,C
  LD D,(HL)
  DEC HL
  LD E,(HL)
  INC HL
  EX DE,HL
  CALL DrawSprite
  EX DE,HL
UfoBombMove:
  LD D,(HL)               ; D = x, E = y, B = dx, C = dy, HL = the timer
  DEC HL
  LD E,(HL)
  DEC HL
  LD B,(HL)
  DEC HL
  LD C,(HL)
  DEC HL
  LD A,(HL)
  DEC A
  LD (HL),A
  JR NZ,UfoBombStep
UfoBombFall:
  DEC HL                  ; straight down by 4, sprite $1E
  LD (HL),$1E
  INC HL
  LD BC,$0004
  LD (HL),$FE
UfoBombStep:
  LD A,D
  ADD A,B
  CP $F7
  JR NC,UfoBombFall
  LD D,A
  LD A,E
  ADD A,C
  CP $A0                  ; the ground: a saucer's bomb ends, the spinner's
                          ; makes a crater
  JR C,UfoBombStore
  LD A,(UfoWave)
  AND A
  JP Z,UfoBombEnd
  LD A,D
  SUB $05
  LD D,A
  LD E,$A0
  PUSH DE
  LD B,$05
UfoCraterTest:
  LD H,$7D                ; five places 4 apart must be clear on rows 162 and
                          ; 159
  LD L,A
  SLA L
  RL H
  LD D,$00
  LD E,(HL)
  INC HL
  EX AF,AF'
  LD A,(HL)
  LD C,A
  LD HL,ScreenRow162
  ADD HL,DE
  AND (HL)
  JR Z,UfoCraterTestLow
UfoCraterRefused:
  POP DE
  JP UfoBombEnd
UfoCraterTestLow:
  LD HL,ScreenRow159
  ADD HL,DE
  LD A,C
  AND (HL)
  JR NZ,UfoCraterRefused
  EX AF,AF'
  ADD A,$04
  DJNZ UfoCraterTest
  POP DE
  LD HL,(ObjectWrite)     ; a crater record ($9A92) at the end of the list,
                          ; then the end marker $975E
  LD BC,ObjCrater
  LD (HL),C
  INC HL
  LD (HL),B
  INC HL
  LD (HL),$00
  INC HL
  LD A,D
  AND $FC
  LD (HL),A
  INC HL
  LD BC,ListStop
  LD (HL),C
  INC HL
  LD (HL),B
  DEC HL
  LD (ObjectWrite),HL
  EX DE,HL
  PUSH HL
  LD E,$10                ; 16 pixels of the ground's top row cleared, the
                          ; crater sprite $10 drawn
  CALL UnplotRun
  POP HL
  LD A,$10
  CALL DrawSprite
  JP UfoBombEnd
UfoBombStore:
  LD E,A                  ; store dy, dx, y, x; then the hit tests
  INC HL
  LD (HL),C
  INC HL
  LD (HL),B
  INC HL
  LD (HL),E
  INC HL
  LD (HL),D
  DEC HL
  EXX
  LD HL,ShotsUp             ; the four upward shots
  LD B,$04
UfoBombShotLoop:
  PUSH BC
  CALL BoxOverlap
  POP BC
  JR NC,UfoBombShot
  INC HL
  EXX
  DEC HL
  DEC HL
  DEC HL
  EXX
  DJNZ UfoBombShotLoop
  EXX
  JR UfoBombHitTests
UfoBombShot:
  DEC HL                  ; shot: 5 for a saucer's bomb, 10 for the spinner's
  LD (HL),$FF
  EXX
  LD DE,$0000
  LD BC,$0005
  LD A,(UfoWave)
  AND $05
  ADD A,C
  LD C,A
  CALL ScoreAdd
  JR UfoBombEnd
UfoBombHitTests:
  EXX                     ; the forward shot, then the buggy
  LD HL,ShotForward
  CALL BoxOverlap
  JR NC,UfoBombShot
  EXX
  DEC HL
  DEC HL
  DEC HL
  EXX
  LD HL,BuggyY
  EXX
  CALL BoxOverlap
  JR C,UfoBombDraw
  CALL BuggyKill          ; on the buggy: the kill
  JR UfoBombEnd
UfoBombDraw:
  DEC HL
  DEC HL
  LD D,(HL)
  DEC HL
  LD E,(HL)
  LD BC,-4
  ADD HL,BC
  EX DE,HL
  CALL ScrollAdjustIfAlive
  LD A,(DE)
  CALL DrawSprite
  POP HL
UfoBombNext:
  LD BC,$0009
  ADD HL,BC
  RET
UfoBombEnd:
  POP HL                  ; the bomb ended: is the UFO gone too?
  LD BC,-10
  PUSH HL
  ADD HL,BC
  LD D,(HL)
  DEC HL
  LD E,(HL)
  LD HL,UfoBombHandler
  AND A
  SBC HL,DE
  POP HL
  JR NZ,UfoBombReload
UfoRecordSpent:
  ADD HL,BC               ; the record's handler: UfoRecordSkip
  LD DE,UfoRecordSkip
  LD (HL),D
  DEC HL
  LD (HL),E
  INC HL
  INC HL

; UfoRecordSkip
;
; Used by the routine at UfoHandler.
UfoRecordSkip:
  LD BC,$0012             ; the next record: 18 bytes on
  ADD HL,BC
  RET
; This entry point is used by the routine at UfoBombHandler.
UfoBombReload:
  LD A,R                  ; the UFO lives: a new bomb, wait 16-47
  AND $1F
  ADD A,$10
  LD (HL),A
  INC HL
  LD (HL),$1D
  INC HL
  LD (HL),$FF
  INC HL
  LD (HL),$04
  INC HL
  LD (HL),$04
  INC HL
  INC HL
  INC HL
  LD (HL),$05
  INC HL
  LD (HL),$05
  INC HL
  RET

; The UFO has left or exploded: the record's handler becomes UfoBombHandler,
; which runs at once
;
; Entered by a JP with the record +2 on the stack, from UfoHandler (the retreat
; past the side) and UfoExplodeHandler (the last frame). Witness: i1 72, i2 63
; (frames 2266-30 297 in i1).
UfoSaucerGone:
  POP HL
  DEC HL
  LD DE,UfoBombHandler
  LD (HL),D
  DEC HL
  LD (HL),E
  INC HL
  INC HL
  JP UfoBombHandler

; Picks the drawing colour of a UFO sprite into E' for the sprite drawer
;
; A = the sprite: below 5 (saucer A) $44 bright green, below 11 (saucer B) $06
; yellow, below 15 (the spinner) $05 cyan, else $07 white (the bombs $1D / $1E
; and the explosions). Keeps the main registers. Called before each draw and
; erase of UfoHandler and UfoExplodeHandler: i1 16 491, i2 14 805; white i1
; 296.
UfoSetColour:
  EXX
  LD E,$44
  CP $05
  JR C,UfoColourSet
  LD E,$06
  CP $0B
  JR C,UfoColourSet
  LD E,$05
  CP $0F
  JR C,UfoColourSet
  LD E,$07
UfoColourSet:
  EXX
  RET

; The UFO retreat timer: after its wait sets the retreat flag $B237, and the
; UFOs fly off the screen
;
; The record (3 bytes, course command $98AA): the handler and a wait. When the
; wait runs out it sets $B237 = $FF (UfoHandler then moves every UFO 4 a pass
; off the nearer side) and the record becomes UfoRetreatSkip. The flag is
; cleared by the life start ($90F4) and by the next UFO to enter the screen.
;
; This is the unmatched handler of stage 1. Witness: the flag set i1 8 times,
; i2 10 ($9EAD): one per $98AA record, at the course points C E H I P U Y Z of
; Beginner and A E G H J P T U Y Z of Champion (course-commands.txt); handler
; runs i1 167 (frames 2937-28 403), i2 198.
UfoRetreatTimer:
  LD A,(HL)
  AND A
  JR Z,UfoRetreatStart
  DEC A
  LD (HL),A
  JR UfoRetreatSkip
UfoRetreatStart:
  LD A,$FF                ; the wait is over: the UFOs retreat
  LD (UfosLeave),A
  LD BC,UfoRetreatSkip
  DEC HL
  LD (HL),B
  DEC HL
  LD (HL),C
  INC HL
  INC HL

; UfoRetreatSkip
;
; Used by the routine at UfoRetreatTimer.
UfoRetreatSkip:
  INC HL                  ; the next record: 1 byte on
  RET
