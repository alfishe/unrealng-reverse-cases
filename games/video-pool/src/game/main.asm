; --------------------------------------------------------------------------------------------------------------------
; main.asm: The entry, the restart, the foreground sound loop, task lists, the frame wait, the interrupt handler
;
; The game is entered at GameStart $8000 (the turbo loader's JP). After the presents page it builds the IM 2 table and
; the jump at $FCFC, runs the menu, sets up a game and the aim, and falls into the foreground loop SoundLoop: from
; then on all the work of play runs in the interrupt as tasks (scheduler $9155); the foreground only plays the beeper
; sound a task requests in SoundRequest $827D and watches for BREAK in InputState $827C.
;
; BREAK (CAPS SHIFT + SPACE, InputState bit 5) goes to BreakRestart: the tasks are cleared, the stack reset and the
; game restarts at the menu (GameRestart). The game never returns to BASIC.
; --------------------------------------------------------------------------------------------------------------------

; The game's entry: the stack, the ball records, the presents page
;
; Entered once by the turbo loader's JP $8000 (every build: game frame 5556,
; each play recording at its start). LD SP,$D000 (the stack below BallSprites),
; $9D2C resets the ball records, EI (still IM 1, the ROM's handler), $BD0B = 0,
; the presents page and attract sequence $B8C5 (returns on a key), $BD0B = $FF
; (so a later attract run is shorter), then falls into GameRestart.
GameStart:
  LD SP,StackTop
  CALL ResetBallPositions
  EI
  XOR A
  LD (PresentsDone),A     ; the presents-done flag $BD0B = 0: the first
                          ; presents page plays in full
  CALL PresentsPage
  LD A,$FF
  LD (PresentsDone),A     ; $BD0B = $FF after it

; IM 2 on, the menu, a new game, the first aim; falls into SoundLoop
;
; Entered from GameStart and from BreakRestart (game 2 entries at frames 6060
; and 9091; w1 2; m1 3). DI, I = $FE, IM 2; fills Im2Table $FE00-$FF00 with $FC
; and writes EI, JP Im2Handler at Im2Jump $FCFC, so every interrupt runs
; Im2Handler whatever the data bus holds (c1 stage 6, frame 6061). EI, then the
; menu $B22E (returns when "begin" is chosen), the table $95DA, A = 4 / 3 for
; $9DC3, the shots left $9F4D from $9BE6, $9D6B, $9B30 = 1, $9520, $9AD9,
; $9C7B, the racking $9F69 and the first aim StartAim. Then SoundRequest = 0
; and EI, into SoundLoop.
GameRestart:
  DI
  LD A,$FE
  LD I,A
  IM 2
  LD HL,Im2Table
  LD DE,Im2Table+$0001
  LD BC,$0100
  LD (HL),$FC
  LDIR
  LD HL,Im2Jump
  LD (HL),$FB
  INC HL
  LD (HL),$C3
  INC HL
  LD DE,Im2Handler
  LD (HL),E
  INC HL
  LD (HL),D
  EI
  CALL MainMenu           ; the menu, until "begin"
  CALL NewGameScreen
  LD A,$04
  CALL PrintHudNumber
  CALL ShotsForFrame
  LD (ShotsLeft),A
  LD A,$03
  CALL PrintHudNumber
  CALL DrawPocketMarks
  LD A,$01
  LD (CurrentPlayer),A
  CALL DrawAllBalls
  CALL DrawLives
  CALL PlayerBanner
  CALL Rack
  CALL StartAim           ; the aim tasks, the cursor and the power bar
  XOR A
  LD (SoundRequest),A
  EI

; The foreground: wait for BREAK or a sound request, play it on the beeper
;
; The whole foreground of play (w1 6 290 430 passes, frames 877-11 615). Loops
; reading InputState $827C (bit 5 BREAK: BreakRestart) and SoundRequest $827D
; (0: none). A request 1, 2 or 3 picks B = the half period in passes of
; SoundDelay (37 T a pass) and C = the number of cycles: 1 = 20 / 20 (a ball
; against a ball, written at $8993), 2 = 30 / 12 (a cushion, $8DC0 / $8DF4 /
; $8E28), 3 = 250 / 6 (a pocket, $8C17). Each cycle is OUT ($FE) $17 (speaker
; bit 4 on, border 7), the delay, OUT $07 (off), the delay. At the end it
; clears SoundRequest itself.
;
; The tone stops at once when a task sets SoundRequest to 0 while it plays
; (SoundAbort: border back to 7): StopShotTasks $8483 and ShotReset $84C7 clear
; it. A new non-zero request during a tone does not restart it; the tone runs
; on and its final clear drops the new request. The interrupt stays on while it
; plays, so each half period also holds the time of any task run in it. w1:
; 1962 cycles played; SoundAbort taken 4 times.
;
; A request written while a tone plays is lost (SoundDelay tests only for zero;
; the tone's end clears it); of two writes in one tick the last wins. w1: 178
; requests, 141 tones, 21 lost, 16 replaced (docs 9.3).
SoundLoop:
  LD A,(InputState)
SoundTestBreak:
  AND $20                 ; BREAK?
  JP NZ,BreakRestart
SoundWait:
  LD A,(SoundRequest)     ; no request: loop
  OR A
  JR Z,SoundLoop
  LD BC,$1414             ; request 1: B = 20, C = 20
  DEC A
  JR Z,SoundCycle
  LD BC,$1E0C             ; request 2: B = 30, C = 12
  DEC A
  JR Z,SoundCycle
  LD BC,$FA06             ; request 3: B = 250, C = 6
SoundCycle:
  LD A,$17                ; one cycle: speaker on, delay, off, delay
  OUT ($FE),A
  CALL SoundDelay
  LD A,$07
  OUT ($FE),A
  CALL SoundDelay
  DEC C
  JR NZ,SoundCycle
  XOR A
  LD (SoundRequest),A     ; the tone is done: clear the request
  JR SoundLoop

; Half a period: B passes of 37 T, aborted when the request goes to 0
;
; Input B (saved). Each pass reads SoundRequest; at 0 it drops its own return
; address and SoundLoop's (POP BC twice), sets the border/speaker to $07 and
; jumps back to SoundLoop. w1: 3922 calls (two per cycle).
SoundDelay:
  PUSH BC
SoundDelayLoop:
  LD A,(SoundRequest)
  OR A
  JR Z,SoundAbort
  DJNZ SoundDelayLoop
  POP BC
  RET
SoundAbort:
  POP BC                  ; the request was cleared: speaker off, back to the
                          ; loop
  POP BC
  LD A,$07
  OUT ($FE),A
  JR SoundLoop

; BREAK: clear the tasks, reset the stack, back to the menu
;
; Jumped to from SoundLoop when InputState bit 5 is set (game frame 9091, w1 14
; 233, f1 5196, p2 4239, v1 2133; m1 at 6830 and 7998). ClearTasks $91CF, SP =
; $D000, JP GameRestart.
BreakRestart:
  CALL ClearTasks
  LD SP,StackTop
  JP GameRestart

; Add every task of a list: (period, routine) triples, $FF ends
;
; DE = the list (AimTasks $84AA, MovingTasks $84BA, the editor's $C518). For
; each triple: C = the period, HL = the routine, AddTask $9188. Returns at the
; $FF. w1: 42 lists installed (231 triples read).
InstallTasks:
  LD A,(DE)
  CP $FF
  RET Z
  LD C,A
  INC DE
  LD A,(DE)
  LD L,A
  INC DE
  LD A,(DE)
  LD H,A
  INC DE
  PUSH DE
  CALL AddTask
  POP DE
  JR InstallTasks

; Remove every task of a list by its routine's address
;
; DE = the list as for InstallTasks; RemoveTask $91AD for each routine (the
; period is skipped). w1: 42 lists removed.
RemoveTasks:
  LD A,(DE)
  CP $FF
  RET Z
  INC DE
  LD A,(DE)
  LD L,A
  INC DE
  LD A,(DE)
  LD H,A
  INC DE
  PUSH DE
  CALL RemoveTask
  POP DE
  JR RemoveTasks

; Run HL with the tasks stopped, then wait for one interrupt
;
; Writes RET ($C9) over the JP at Im2Jump+1 ($FCFD): the interrupt is then EI;
; RET, so the scheduler does not run. EI, calls the routine in HL
; (WaitFrameCall), HALTs for the next interrupt, DI and puts the JP ($C3) back.
; Callers: the shot end WaitMessages $8451 and $9C0F, the racking $9F69 (w1 58
; calls). The routine may HALT by itself (WaitMessagesLoop does, once a frame):
; every interrupt it waits for is a plain EI; RET. That is why Im2Jump ran 3503
; times in c1 against 2577 for Im2Handler (stage 1).
WaitFrameNoTasks:
  LD A,$C9
  LD (Im2Jump+1),A
  EI
  CALL WaitFrameCall
  HALT                    ; one more interrupt, then the JP back
  DI
  LD A,$C3
  LD (Im2Jump+1),A
  RET

; JP (HL)
;
; The CALL target of WaitFrameNoTasks: jumps to the routine in HL, which
; returns to $80E7.
WaitFrameCall:
  JP (HL)

; The interrupt: save every register, run the scheduler
;
; Reached through Im2Jump $FCFC (EI; JP Im2Handler) on every interrupt while
; the JP is in place (w1 9536 entries, frames 501-16 377). DI, pushes AF, BC,
; DE, HL, IX, IY, calls the scheduler $9155, pops them, EI, RET. The alternate
; registers are not saved: no task uses them.
Im2Handler:
  DI
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  PUSH IX
  PUSH IY
  CALL RunTasks
  POP IY                  ; back from the tasks
  POP IX
  POP HL
  POP DE
  POP BC
  POP AF
  EI
  RET
