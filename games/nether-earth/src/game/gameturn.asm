; One game turn: the random step, the clock, the daily production, the clock
; print
;
; Called once a pass by PlayLoop and by every robot menu loop (3414 times in
; the recording). Random steps the random generator $FD00-$FD03. Clock ($FD35
; minutes, $FD36 hours, $FD37-$FD38 days) gains 5 minutes a turn: 60 minutes
; make an hour, 24 hours a day, and a new day runs DailyProduction. Then the
; clock print: days at (0,27), five digits with leading spaces; "HH.MM" on the
; next line. Goes on in GameTurnEnd.
GameTurn:
  CALL Random             ; the random generator
  LD HL,Clock             ; 5 minutes a turn
  LD A,(HL)
  ADD A,$05
  LD (HL),A
  CP $3C
  JR NZ,ClockPrint
  LD (HL),$00             ; an hour
  INC HL
  INC (HL)
  LD A,(HL)
  CP $18
  JR NZ,ClockPrint
  LD (HL),$00             ; a day
  LD HL,(Clock+2)
  INC HL
  LD (Clock+2),HL
  CALL DailyProduction    ; the day's production of both sides
ClockPrint:
  CALL PrintInline        ; print the clock (also when no minute wrapped)

; The clock: (0,27), setting 0, attribute $57
ClockPos:
  DEFM $01,$00,$1B,$04,$00,$02,"W",$00

; Game turn, second half: the clock print, the game end, captures, the frame
; pacing
;
; Prints days (PrintNumber5) and, a line down (PrintNewline), hours "." minutes
; (PrintNumber2Zero, two digits with zeros). CheckGameEnd.
;
; Captures: the 28 capture points at $FD70 (5 bytes each: X 2 bytes, Y, owner
; and type, count; points 0-3 the warbases, 4-27 the factories) are checked
; each turn. While map bit 6 is set on a point's cell (a robot stands on the
; building's door) its count goes up; when it reaches 144 ($90) FindRobot takes
; the robot there and its side (+$0A bit 7) captures the building: GiveWarbase
; for a warbase, GiveFactory (point - 4) for a factory. An empty door resets
; the count. The recording shows every capture after a count of 121-143 at the
; 250-frame samples. Any robot captures, whatever its order. After a capture
; CountBases recounts the buildings and UpdateStatusPanel reprints the status.
;
; Last, the pacing: waits until PlayInterrupt has counted 10 frames in $FD34
; since the last turn, then clears it. A turn is at least 10 frames: an hour
; 120, a game day 2880 (about 58 s).
GameTurnEnd:
  LD HL,(Clock+2)
  CALL PrintNumber5       ; days, five digits
  CALL PrintNewline       ; the next line
  LD A,(Clock+1)            ; hours, two digits with zeros
  CALL PrintNumber2Zero
  LD A,$2E                ; "."
  CALL PrintCharKeep
  LD A,(Clock)            ; minutes
  CALL PrintNumber2Zero
  CALL CheckGameEnd       ; won or lost?
  PUSH IY
  LD IY,Warbases             ; the capture points
  LD B,$1C                ; 28: 4 warbases, 24 factories
  LD C,$00                ; C = captures this turn
CaptureLoop:
  LD L,(IY+$00)           ; the point's door cell
  LD H,(IY+$01)
  LD A,(IY+$02)
  CALL MapCell
  BIT 6,(HL)              ; a robot on it?
  JR NZ,CaptureCount
  LD (IY+$04),$00         ; empty: the count starts again
  JR CaptureNext
CaptureCount:
  INC (IY+$04)            ; one more turn on the door
  LD A,(IY+$04)
  CP $90                  ; 144 turns: taken
  JR C,CaptureNext
  LD (IY+$04),$00
  PUSH BC
  PUSH IY
  CALL FindRobot          ; the robot standing there
  LD A,(IY+$0A)           ; E = its side: 0 ours, 1 the enemy's
  RLCA
  AND $01
  LD E,A
  POP IY
  LD A,B                  ; no robot found
  OR A
  JR Z,CapturePointDone
  POP BC
  INC C                   ; one more capture
  PUSH BC
  LD A,$1C                ; A = the point's index
  SUB B
  CP $04                  ; 0-3: a warbase
  JR NC,CaptureFactory
  LD B,E
  CALL GiveWarbase        ; the warbase changes side
  JR CapturePointDone
CaptureFactory:
  SUB $04                 ; a point 4-27: factory A - 4 changes side
  LD B,E
  CALL GiveFactory
CapturePointDone:
  POP BC                  ; restore the capture count, on to the next point
CaptureNext:
  INC IY                  ; 5 bytes a point
  INC IY
  INC IY
  INC IY
  INC IY
  DJNZ CaptureLoop
  POP IY
  LD A,C                  ; any capture?
  OR A
  JR Z,TurnPace
  CALL CountBases         ; recount the buildings of both sides
  CALL UpdateStatusPanel  ; reprint the status values
TurnPace:
  LD A,(TurnFrames)            ; at least 10 frames a turn
  CP $0A
  JR C,TurnPace
  XOR A                   ; the next turn's frames
  LD (TurnFrames),A
  RET

; Unreferenced code: keys 6 and 7 together jump into the tape ROM
;
; 15 bytes of code nothing calls or jumps to: LD A,$EF; IN A,($FE); AND $18;
; RET NZ (unless 6 and 7 are both held); LD HL,$A600; PUSH HL; DI; JP $04B0.
; $04B0 is inside an instruction of the 48K ROM's SAVE code; with Start as the
; return address it looks like a debugging leftover (a memory dump to tape).
; Never runs.
UnusedTapeCode:
  LD A,$EF
  IN A,($FE)
  AND $18
  RET NZ
  LD HL,Start
  PUSH HL
  DI
  JP $04B0

; A new day: each side's buildings add to its resources
;
; Our side from $FD3A into Resources, the enemy from $FD42 into $FD4A
; (ProduceSide), then the panel reprint (UpdateStatusPanel). Ran 11 times in
; the recording, once a game day.
DailyProduction:
  LD HL,Resources             ; ours: counts $FD3A
  LD DE,PlayerBuildings
  CALL ProduceSide
  LD HL,EnemyResources             ; the enemy's: counts $FD42, resources $FD4A
  LD DE,EnemyBuildings
  CALL ProduceSide
  CALL UpdateStatusPanel
  RET

; One side's production: 5 general a warbase, 2 a factory of each kind
;
; DE = the side's building counts (warbases, then the factories of electronics,
; nuclear, phasers, missiles, cannon, chassis), HL = its 7 resources (general
; first, then the same order). General += 5 x warbases; each other resource +=
; 2 x the factories of its kind; every resource stops at 99. In the recording
; the general resource grew by 5 a day with one warbase, electronics by 2 with
; one factory.
ProduceSide:
  LD A,(DE)               ; 5 x warbases
  LD C,A
  ADD A,A
  ADD A,A
  ADD A,C
  CALL AddCapped          ; into the general resource
  LD B,$06                ; six factory kinds
ProduceFactoryLoop:
  INC HL                  ; each factory kind: 2 x its factories into its
                          ; resource
  INC DE
  LD A,(DE)               ; 2 x the factories of the kind
  ADD A,A
  CALL AddCapped
  DJNZ ProduceFactoryLoop
  RET

; (HL) += A, at most 99
;
; Used by the routine at ProduceSide.
AddCapped:
  ADD A,(HL)
  CP $64
  JR C,AddCappedStore
  LD A,$63
AddCappedStore:
  LD (HL),A               ; store the capped sum
  RET

; The end of the game: the enemy has no warbase (won) or we have none (lost)
;
; $FD42 (the enemy's warbases) = 0: GameWon. Else $FD3A (ours) = 0: GameStop,
; "YOU HAVE NO BASES LEFT / BETTER LUCK NEXT TIME!" at (22,0), then the common
; end at $AEEA. Both tested by poking the counts on the own instance (the
; messages showed, the handler became StartInterrupt, fire went back to the
; title menu).
CheckGameEnd:
  LD A,(EnemyBuildings)            ; the enemy's warbases
  OR A
  JR Z,GameWon
  LD A,(PlayerBuildings)            ; ours
  OR A
  RET NZ
  CALL GameStop           ; lost
  CALL PrintInline

; "YOU HAVE NO BASES LEFT", "BETTER LUCK NEXT TIME!" at (22,0), attribute $45
LostText:
  DEFM $01,$16,$00,$02,"EYOU HAVE NO BASES LEFT",$03,"BETTER LUCK NEXT TIME!",$00

; Code the recordings never ran: JR $AEEA, the common end
LostJump:
  JR GameOverWait

; The enemy has no warbase left: "INSIGNIANS DESTROYED / YOU HAVE WON !"
;
; Stops play (GameStop), prints the message at (22,0) and falls into the common
; end at $AEEA: a low buzz, 100 frames, WaitRelease, then the first control
; (Input not 0, the chosen keys or stick only) goes back to Start and the title
; menu.
GameWon:
  CALL GameStop
  CALL PrintInline

; " INSIGNIANS DESTROYED ", "    YOU HAVE WON !    " at (22,0), attribute $45
WonText:
  DEFM $01,$16,$00,$02,"E INSIGNIANS DESTROYED ",$03,"    YOU HAVE WON !    ",$00

; Code the recordings never ran: the end of a won or lost game
;
; LD A,$FA; CALL $CCAC (the buzz); LD B,100; HALT; DJNZ (2 s); CALL
; WaitRelease; CALL WaitKey until a control is held; JP Start.
GameOverWait:
  LD A,$FA
  CALL Beep
  LD B,$64
GameOverPause:
  HALT                    ; 100 frames of HALT before the key is read
  DJNZ GameOverPause
  CALL WaitRelease
GameOverKey:
  CALL WaitKey            ; wait for a key, then back to Start
  OR A
  JR Z,GameOverKey
  JP Start

; Stop play: give the panel back to the status and switch to the idle interrupt
;
; $FD39 = 0, clears the panel, prints the status panel (ShowStatusPanel),
; Handler = StartInterrupt (no frame count, no radar). Used by both ends of the
; game.
GameStop:
  XOR A
  LD (PanelBusy),A
  CALL ClearPanel
  CALL ShowStatusPanel
  LD HL,StartInterrupt
  LD (Handler),HL
  RET
