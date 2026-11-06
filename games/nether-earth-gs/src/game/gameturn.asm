; --------------------------------------------------------------------------------------------------------------------
; gameturn.asm: the game turn: the clock, daily production, capture, the game end and the turn pacing
;
; The second half of every pass of the play loop and of every robot menu loop (nether-earth/docs/10-gameplay-logic.md
; 10.1, nether-earth/docs/04-game-loop.md 4.3 and 4.5): WorldTurn moves the robots and shots, GameTurn then keeps the
; time and the rules that are not a robot's.
;
; In calling order: GameTurn steps Random and the clock (+5 minutes a turn; a new day runs DailyProduction, which runs
; ProduceSide and AddCapped for both sides); PrintInline prints the clock position and GameTurnEnd prints the days and
; HH.MM; CheckGameEnd ends the game when a side has no warbase (GameWon or the lost message, then GameStop and
; GameOverWait back to Start); CaptureLoop counts the turns a robot stands on each of the 28 base doors and hands a
; base over at 144 (GiveWarbase / GiveFactory, then CountBases and UpdateStatusPanel); TurnPace waits until a turn has
; lasted 10 frames.
;
; Data it owns or keeps: Clock ($FD35: minutes, hours, the 16-bit day count), TurnFrames ($FD34, counted up by
; PlayInterrupt), the capture counters (+4 of each 5-byte record in Warbases $FD70 / Factories $FD84), the resources
; of both sides (Resources, EnemyResources) through the building counts PlayerBuildings / EnemyBuildings (nether-earth
; docs 10.2, 10.7, 10.10).
;
; Tricks: PrintInline reads the print codes after the CALL (ClockPos, LostText, WonText) and returns past them, so the
; code goes on behind the text. The lost path (LostJump: JR GameOverWait) and the won path meet in GameOverWait;
; neither ran in a recording (of Nether Earth or of this case) (both verified by poking the counts). UnusedTapeCode is
; never-run dead code between the routines.
; --------------------------------------------------------------------------------------------------------------------

; One game turn: the random step, the clock, the daily production, the clock
; print
;
; Called once a pass by PlayLoop and by every robot menu loop (3414 times in
; Nether Earth's recording). Random steps the random generator $FD00-$FD03.
; Clock ($FD35 minutes, $FD36 hours, $FD37-$FD38 days) gains 5 minutes a turn:
; 60 minutes make an hour, 24 hours a day, and a new day runs DailyProduction.
; Then the clock print: days at (0,27), five digits with leading spaces;
; "HH.MM" on the next line. Goes on in GameTurnEnd.
GameTurn:
  CALL Random             ; the random generator
  LD HL,Clock             ; 5 minutes a turn
  LD A,(HL)               ; the minutes
  ADD A,$05               ; + 5
  LD (HL),A               ; store
  CP $3C                  ; 60 minutes?
  JR NZ,ClockPrint        ; not yet: print
  LD (HL),$00             ; an hour
  INC HL                  ; HL = the hours
  INC (HL)                ; one hour more
  LD A,(HL)               ; the hours:
  CP $18                  ; 24?
  JR NZ,ClockPrint        ; not yet: print
  LD (HL),$00             ; a day
  LD HL,(Clock+$0002)     ; the day count, 16 bits
  INC HL                  ; one day more
  LD (Clock+$0002),HL     ; store it
  CALL DailyProduction    ; the day's production of both sides
ClockPrint:
  CALL PrintInline        ; print the clock (also when no minute wrapped)

; The clock: (0,27), setting 0, attribute $57
ClockPos:
  DEFM $01,$00,$1B,$04,$00,$02,"W",$00 ; AT (0,27), size 0, attribute $57
                                       ; (white on red): where the clock's day
                                       ; and time go

; Game turn, second half: the clock print, the game end, captures, the frame
; pacing
;
; The second half of GameTurn, reached after the PrintInline of ClockPos
; (setting the print position (0,27) and attribute $57). Prints the days
; (PrintNumber5, five digits with leading spaces) and, a line down
; (PrintNewline), the hours "." the minutes (PrintNumber2Zero, two digits with
; zeros). Then CheckGameEnd: a side with no warbase ends the game here.
;
; Captures: the 28 capture points at $FD70 (5 bytes each: X 2 bytes, Y, owner
; and type, count; points 0-3 the warbases, 4-27 the factories) are checked
; each turn. While map bit 6 is set on a point's door cell (an anchor stands
; there) its count +4 goes up; at 144 ($90) FindRobot takes the robot there and
; its side (+$0A bit 7) captures the building: GiveWarbase for a warbase,
; GiveFactory (point - 4) for a factory. A door anchor that is no robot
; (probably a flying shot) captures nothing; the count still starts again. An
; empty door resets the count. Nether Earth's deep recording shows every
; capture after a count of 121-143 at the 250-frame samples. Any robot
; captures, whatever its order. After a capture CountBases recounts the
; buildings and UpdateStatusPanel reprints the status.
;
; Last, the pacing (TurnPace): waits until PlayInterrupt has counted 10 frames
; in TurnFrames ($FD34) since the last turn, then clears it. A turn is at least
; 10 frames: an hour 120, a game day 2880 (about 58 s). Keeps IY (pushed around
; the loop); A, BC, DE, HL lost.
GameTurnEnd:
  LD HL,(Clock+$0002)     ; HL = the day count
  CALL PrintNumber5       ; days, five digits
  CALL PrintNewline       ; the next line
  LD A,(Clock+$0001)      ; hours, two digits with zeros
  CALL PrintNumber2Zero   ; "HH" with a leading zero
  LD A,$2E                ; "."
  CALL PrintCharKeep      ; print it, the registers kept
  LD A,(Clock)            ; minutes
  CALL PrintNumber2Zero   ; "MM" with a leading zero
  CALL CheckGameEnd       ; won or lost?
  PUSH IY                 ; keep the caller's IY (a robot record in the menus)
  LD IY,Warbases          ; the capture points
  LD B,$1C                ; 28: 4 warbases, 24 factories
  LD C,$00                ; C = captures this turn
CaptureLoop:
  LD L,(IY+$00)           ; the point's door cell
  LD H,(IY+$01)           ; the door's column, high byte
  LD A,(IY+$02)           ; A = the door's row
  CALL MapCell            ; HL = the door's map cell
  BIT 6,(HL)              ; a robot on it?
  JR NZ,CaptureCount      ; an anchor on the door: count
  LD (IY+$04),$00         ; empty: the count starts again
  JR CaptureNext          ; on to the next point
CaptureCount:
  INC (IY+$04)            ; one more turn on the door
  LD A,(IY+$04)           ; the turns so far
  CP $90                  ; 144 turns: taken
  JR C,CaptureNext        ; not yet: next point
  LD (IY+$04),$00         ; the count starts again for the new owner
  PUSH BC                 ; keep the loop counter B and the captures C
  PUSH IY                 ; keep the point's record
  CALL FindRobot          ; the robot standing there
  LD A,(IY+$0A)           ; E = its side: 0 ours, 1 the enemy's
  RLCA                    ; bit 7 (the enemy's $80) ...
  AND $01                 ; ... to bit 0:
  LD E,A                  ; E = the side, the B of GiveWarbase / GiveFactory
  POP IY                  ; IY = the point's record again
  LD A,B                  ; no robot found
  OR A                    ; B = 0: FindRobot found none (a building or a shot
                          ; on the door)
  JR Z,CapturePointDone   ; no capture
  POP BC                  ; the counters back:
  INC C                   ; one more capture
  PUSH BC                 ; and kept again for the hand-over
  LD A,$1C                ; A = the point's index
  SUB B                   ; 28 - the points left
  CP $04                  ; 0-3: a warbase
  JR NC,CaptureFactory    ; 4-27: a factory
  LD B,E                  ; B = the new owner's side
  CALL GiveWarbase        ; the warbase changes side
  JR CapturePointDone     ; done with this point
CaptureFactory:
  SUB $04                 ; a point 4-27: factory A - 4 changes side
  LD B,E                  ; B = the new owner's side
  CALL GiveFactory        ; the factory changes side, its flag moves
CapturePointDone:
  POP BC                  ; restore the capture count, on to the next point
CaptureNext:
  INC IY                  ; 5 bytes a point
  INC IY                  ; ...
  INC IY                  ; ...
  INC IY                  ; ...
  INC IY                  ; ... IY + 5: the next point's record
  DJNZ CaptureLoop        ; all 28 points
  POP IY                  ; the caller's IY back
  LD A,C                  ; any capture?
  OR A                    ; C = 0:
  JR Z,TurnPace           ; nothing changed hands
  CALL CountBases         ; recount the buildings of both sides
  CALL UpdateStatusPanel  ; reprint the status values
TurnPace:
  LD A,(TurnFrames)       ; at least 10 frames a turn
  CP $0A                  ; 10 frames since the last turn?
  JR C,TurnPace           ; not yet: wait (the interrupt counts on)
  XOR A                   ; the next turn's frames
  LD (TurnFrames),A       ; TurnFrames = 0
  RET                     ; the turn is over

; Unreferenced code: keys 6 and 7 together jump into the tape ROM
;
; 15 bytes of code nothing calls or jumps to: LD A,$EF; IN A,($FE); AND $18;
; RET NZ (unless 6 and 7 are both held); LD HL,$A600; PUSH HL; DI; JP $04B0.
; $04B0 is inside an instruction of the 48K ROM's SAVE code; with Start as the
; return address it looks like a debugging leftover (a memory dump to tape).
; Never runs.
UnusedTapeCode:
  LD A,$EF                ; the keyboard half-row 6-0
  IN A,($FE)              ; read it
  AND $18                 ; bits 3-4: keys 7 and 6 (0 = held)
  RET NZ                  ; not both held: back
  LD HL,Start             ; Start as the return address ...
  PUSH HL                 ; ... on the stack
  DI                      ; no interrupts
  JP $04B0                ; into the 48K ROM's SAVE code

; A new day: each side's buildings add to its resources
;
; Our side from $FD3A into Resources, the enemy from $FD42 into $FD4A
; (ProduceSide), then the panel reprint (UpdateStatusPanel). Ran 11 times in
; Nether Earth's recording, once a game day.
DailyProduction:
  LD HL,Resources         ; ours: counts $FD3A
  LD DE,PlayerBuildings   ; our building counts
  CALL ProduceSide        ; our day's income
  LD HL,EnemyResources    ; the enemy's: counts $FD42, resources $FD4A
  LD DE,EnemyBuildings    ; the enemy's building counts
  CALL ProduceSide        ; the enemy's day's income
  CALL UpdateStatusPanel  ; the new resources on the panel
  RET                     ; the day is paid

; One side's production: 5 general a warbase, 2 a factory of each kind
;
; DE = the side's building counts (warbases, then the factories of electronics,
; nuclear, phasers, missiles, cannon, chassis), HL = its 7 resources (general
; first, then the same order). General += 5 x warbases; each other resource +=
; 2 x the factories of its kind; every resource stops at 99. In Nether Earth's
; deep recording the general resource grew by 5 a day with one warbase,
; electronics by 2 with one factory.
ProduceSide:
  LD A,(DE)               ; 5 x warbases
  LD C,A                  ; C = the warbases
  ADD A,A                 ; * 2
  ADD A,A                 ; * 4
  ADD A,C                 ; + 1: * 5
  CALL AddCapped          ; into the general resource
  LD B,$06                ; six factory kinds
ProduceFactoryLoop:
  INC HL                  ; each factory kind: 2 x its factories into its
                          ; resource
  INC DE                  ; DE = the next count: electronics, nuclear, phasers,
                          ; missiles, cannon, chassis
  LD A,(DE)               ; 2 x the factories of the kind
  ADD A,A                 ; * 2
  CALL AddCapped          ; into the resource of the kind
  DJNZ ProduceFactoryLoop ; all six kinds
  RET                     ; the side is paid

; (HL) += A, at most 99
;
; (HL) += A, at most 99: the resource store of ProduceSide. HL is kept, so
; ProduceSide walks the 7 resources with INC HL. A = the new value. Used only
; by ProduceSide.
AddCapped:
  ADD A,(HL)              ; the resource + the income
  CP $64                  ; 100 or more?
  JR C,AddCappedStore     ; no: as it is
  LD A,$63                ; yes: 99, the most a resource holds
AddCappedStore:
  LD (HL),A               ; store the capped sum
  RET                     ; HL kept for the next resource

; The end of the game: the enemy has no warbase (won) or we have none (lost)
;
; $FD42 (the enemy's warbases) = 0: GameWon. Else $FD3A (ours) = 0: GameStop,
; "YOU HAVE NO BASES LEFT / BETTER LUCK NEXT TIME!" at (22,0), then the common
; end at $AEEA. Both tested by poking the counts on an own instance (Nether
; Earth case) of the Nether Earth case (the messages showed, the handler became
; StartInterrupt, fire went back to the title menu).
CheckGameEnd:
  LD A,(EnemyBuildings)   ; the enemy's warbases
  OR A                    ; none left?
  JR Z,GameWon            ; the player has won
  LD A,(PlayerBuildings)  ; ours
  OR A                    ; any left?
  RET NZ                  ; yes: the game goes on
  CALL GameStop           ; lost
  CALL PrintInline        ; print the lost message that follows

; "YOU HAVE NO BASES LEFT", "BETTER LUCK NEXT TIME!" at (22,0), attribute $45
LostText:
  DEFM $01,$16,$00,$02,"EYOU HAVE NO BASES LEFT" ; AT (22,0) in $45 (cyan),
                                                 ; over the radar: the lost
                                                 ; game's first line
  DEFM $03,"BETTER LUCK NEXT TIME!",$00 ; the next row (23,0): the second line

; Code Nether Earth's recordings never ran: JR $AEEA, the common end
;
; Code Nether Earth's recordings never ran: the lost path goes on here after
; PrintInline has printed LostText: JR GameOverWait, the end shared with
; GameWon.
LostJump:
  JR GameOverWait         ; to the common end

; The enemy has no warbase left: "INSIGNIANS DESTROYED / YOU HAVE WON !"
;
; Stops play (GameStop), prints the message at (22,0) and falls into the common
; end at $AEEA: a low buzz, 100 frames, WaitRelease, then the first control
; (Input not 0, the chosen keys or stick only) goes back to Start and the title
; menu.
GameWon:
  CALL GameStop           ; stop play: the status panel, the idle interrupt
  CALL PrintInline        ; print the won message that follows

; " INSIGNIANS DESTROYED ", "    YOU HAVE WON !    " at (22,0), attribute $45
WonText:
  DEFM $01,$16,$00,$02,"E INSIGNIANS DESTROYED " ; AT (22,0) in $45 (cyan),
                                                 ; over the radar: the won
                                                 ; game's first line
  DEFM $03,"    YOU HAVE WON !    ",$00 ; the next row (23,0): the second line

; Code Nether Earth's recordings never ran: the end of a won or lost game
;
; LD A,$FA; CALL $CCAC (Nether Earth's buzz, silent here: the driver has no
; $FA); LD B,100; HALT; DJNZ (2 s); CALL WaitRelease; CALL WaitKey until a
; control is held; JP Start.
GameOverWait:
  LD A,$FA                ; Beep $FA: Nether Earth's low tone, silent on the GS
  CALL Beep               ; the buzz
  LD B,$64                ; 100 frames, 2 s
GameOverPause:
  HALT                    ; 100 frames of HALT before the key is read
  DJNZ GameOverPause      ; until 100 frames went
  CALL WaitRelease        ; let go of any control first
GameOverKey:
  CALL WaitKey            ; wait for a key, then back to Start
  OR A                    ; a control held?
  JR Z,GameOverKey        ; not yet: wait
  JP Start                ; the title menu

; Stop play: give the panel back to the status and switch to the idle interrupt
;
; $FD39 = 0, clears the panel, prints the status panel (ShowStatusPanel),
; Handler = StartInterrupt (no frame count, no radar). Used by both ends of the
; game.
GameStop:
  XOR A                   ; 0:
  LD (PanelBusy),A        ; PanelBusy = 0: no robot menu owns the panel
  CALL ClearPanel         ; clear the right panel
  CALL ShowStatusPanel    ; and print the status panel
  LD HL,StartInterrupt    ; the idle handler: no frame count, no radar
  LD (ImJump+$0001),HL    ; Handler = StartInterrupt
  RET                     ; play is stopped
