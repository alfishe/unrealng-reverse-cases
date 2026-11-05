; --------------------------------------------------------------------------------------------------------------------
; start.asm: the start-up, the new game set-up and the play loop
;
; The game's top level, entered from the loader's JP $A600 (neart022 on the disk, neart0222 on the tape, src/disk and
; src/tape) and again from every restart (abort key I, the end of a game, a tape loading error). Start builds the IM 2
; table, seeds the random generator and calls MainMenu; NewGameSetup clears the game state and builds the map;
; EnterPlay draws the play screen and switches to PlayInterrupt; PlayLoop runs one game turn a pass, forever.
;
; The routines in calling order: Start ($A600) -> MainMenu (mainmenu.asm) -> NewGameSetup ($A62D, skipped for a loaded
; game) -> EnterPlay ($A68E) -> PlayLoop ($A69A). Each falls into the next; nothing here returns.
;
; The IM 2 trick: 257 bytes of $FD at $FE00-$FF00 with I = $FE make the vector $FDFD whatever the data bus holds; a JP
; sits at $FDFD and its operand Handler ($FDFE) is the only thing the game changes to switch the interrupt's work
; (StartInterrupt in the menus, PlayInterrupt in play). nether-earth/docs/02-architecture.md 2.3 and 2.4.
;
; PlayLoop is the game's state machine in one loop (nether-earth/docs/04-game-loop.md 4.1-4.3): WaitKey, MoveShip,
; WorldTurn, DrawView, GameTurn; then what lies under the ship decides whether a menu opens: our robot with the ship
; on its top opens RobotMenu (robotmenu.asm), the pad of our warbase at altitude 15 with a free door opens
; ConstructionMenu (construction.asm), and PlayLoop writes the new robot's start state after it. Last the game keys I
; (abort) and 5 (save).
;
; The module owns no data; NewGameSetup zeroes the robot records ($DA00), the variables ($FD04-$FDFC), Buildings and
; Shots. The bug of the full robot table (the new-robot writes land on enemy slot 24): nether-earth/docs/10-gameplay-
; logic.md 10.12.
; --------------------------------------------------------------------------------------------------------------------

; the entry from the loader: the IM 2 table, the start-up, the menu
;
; The IM 2 table $FE00-$FF00 (257 x $FD), JP at $FDFD, Handler =
; StartInterrupt, I = $FE, IM 2; the random seed $FD00-$FD03 = $39,$30,$39,$30;
; then MainMenu (Z: start a new game, NZ: a saved game was loaded). Reached
; again at the end of a game ($AEFD), by key I in play ($A712) and after a tape
; loading error ($C28A).
Start:
  DI                      ; no interrupts while the vector table is built
  LD SP,$0000             ; SP = 0: the stack grows down from $FFFF
  LD HL,ImTable           ; the IM 2 table: 257 bytes of $FD at $FE00-$FF00
  LD BC,$00FD             ; B = 0: 256 bytes, C = $FD the byte stored
FillVectorTable:
  LD (HL),C               ; 256 bytes, then the 257th below
  INC HL                  ; the next vector byte
  DJNZ FillVectorTable    ; 256 times
  LD (HL),C               ; the 257th byte, $FF00: the vector $FEFF (bus byte
                          ; $FF) reads its high byte here
  LD A,$C3                ; JP at $FDFD: every vector lands on Handler
  LD (ImJump),A           ; the JP opcode at $FDFD, its operand Handler at
                          ; $FDFE
  LD HL,StartInterrupt    ; StartInterrupt (EI; RET) while the menu runs
  LD (ImJump+$0001),HL    ; Handler = StartInterrupt
  LD A,$FE                ; I = $FE: the vector table's page
  LD I,A                  ; I points at $FE00
  IM 2                    ; IM 2: the interrupt jumps through ($FE00 + the bus
                          ; byte) = $FDFD
  EI                      ; interrupts on from here
  LD HL,$3039             ; the random seed $FD00-$FD03 = $39,$30,$39,$30
                          ; (12345 twice)
  LD (Variables),HL       ; $FD00-$FD01 = $39,$30
  LD (Variables+$0002),HL ; $FD02-$FD03 = $39,$30: the same seed at every
                          ; start, so each game begins the same
  CALL MainMenu           ; the title menu: Z = START GAME, NZ = a saved game
                          ; was loaded

; New game: clear the robots, variables, buildings and shots, place the ship,
; build the map
;
; Entered from Start with the flags of the title menu MainMenu: NZ (option 5
; loaded a saved game, which brings the robots, the map, the buildings, the
; shots and $FD00-$FDFB from tape) skips straight to EnterPlay; Z (option 0,
; START GAME) sets a new game up.
;
; Zeroes the robot records $DA00-$DCFF (48 x 16), the variables $FD04-$FDFC
; (everything past the random seed, below the JP of the IM 2 vector), the
; building table $FF01-$FFC9 and the five shot records $D7D3-$D7FF (5 x 9).
; Then: MapView = $DD00, ViewX = 0, ShipX = $11, ShipY = 10, Altitude = 0, the
; auto-climb counter $FD30 = 3 (the ship rises to 6 on its own at the start),
; the general resource of both sides = 20 (Resources and $FD4A). BuildMap then
; clears the map $DD00-$FCFF and the radar buffer $D800 and builds the
; landscape, the warbases and the factories. Falls into EnterPlay.
NewGameSetup:
  JR NZ,EnterPlay         ; NZ: a loaded game, nothing to set up
  LD HL,Robots            ; the 48 robot records
  LD DE,Robots+$0001      ; LDIR copy: each byte the one before it, all 0
  LD BC,$02FF             ; $2FF more bytes: 48 x 16 = $300 in all
  LD (HL),$00             ; the first byte 0
  LDIR                    ; zero $DA00-$DCFF
  LD HL,PrintAddr         ; the variables past the seed
  LD DE,PrintAddr+$0001   ; the fill target one byte up
  LD BC,$00F8             ; $F8 more: $FD04-$FDFC in all
  LD (HL),$00             ; the first byte 0
  LDIR                    ; zero the variables (the seed and the JP at $FDFD
                          ; kept)
  LD HL,Buildings         ; the 56 building records (and 33 bytes more)
  LD DE,Buildings+$0001   ; the fill target one byte up
  LD BC,$00C8             ; $C8 more: $FF01-$FFC9 in all
  LD (HL),$00             ; the first byte 0
  LDIR                    ; zero the building table
  LD HL,Shots             ; the 5 shot records
  LD DE,Shots+$0001       ; the fill target one byte up
  LD BC,$002C             ; $2C more: 45 bytes, 5 shot records x 9
  LD (HL),$00             ; the first byte 0
  LDIR                    ; zero the shots: all free (+$01 = 0)
  LD HL,Map               ; the view starts at the map's left edge
  LD (MapView),HL         ; MapView = $DD00: the view's top left map cell
  LD HL,$0000             ; column 0
  LD (ViewX),HL           ; ViewX = 0: the view's first column
  LD HL,$0011             ; the ship over column 17, row 10, on the ground
  LD (ShipX),HL           ; ShipX = 17
  LD A,$0A                ; row 10
  LD (ShipY),A            ; ShipY = 10
  XOR A                   ; altitude 0: the ship on the ground
  LD (Altitude),A         ; Altitude = 0
  LD A,$03                ; auto-climb for 3 turns
  LD (ClimbTurns),A       ; ClimbTurns = 3: the ship rises on its own at the
                          ; start
  LD A,$14                ; 20 general resource for each side
  LD (Resources),A        ; Resources+0, our general resource
  LD (EnemyResources),A   ; EnemyResources+0, the enemy's general resource
  CALL BuildMap           ; build the map

; Draw the play screen and switch to the play interrupt
;
; DrawViewBackground and DrawPlayScreen build the play screen (the view, its
; frame, the radar, the status panel); then Handler = PlayInterrupt, which
; counts the frames in $FD34 and draws the radar each frame. Falls into
; PlayLoop. Entered from NewGameSetup, from a loaded game, and again after a
; game save (key 5, SaveGame) at $A71D.
EnterPlay:
  CALL DrawViewBackground ; clear the view buffer, paint the corners outside
                          ; the map
  CALL DrawPlayScreen     ; the whole play screen: view, frame, radar, status
                          ; panel
  LD HL,PlayInterrupt     ; PlayInterrupt from now on
  LD (ImJump+$0001),HL    ; Handler: the frame count $FD34 and the radar each
                          ; frame

; The play loop: one game turn a pass (at least 10 frames)
;
; One pass: WaitKey (the controls into Input; key 1 pauses here), MoveShip,
; WorldTurn (every robot record and the five shots), DrawView (draw the view),
; GameTurn (the random step, the clock, captures, the end of the game; waits
; until 10 frames have passed since the previous turn). Nether Earth's deep
; recording ran it 3332 times in 36046 frames: about 10.5 frames a turn, 5
; turns a second.
;
; Then it looks under the ship (ShipCell: HL = the ship's map cell). Map bit 6
; means something stands there. A robot of ours (FindRobot, B = 48 - slot >=
; 25) with the ship resting exactly on its top (Altitude = +$09 + +$0D) opens
; RobotMenu. Otherwise a building of type 0 (the pad of our warbase) with
; Altitude = 15 (the pad's top, the ship cannot sink below it) opens
; ConstructionMenu, but only when the warbase's door cell 4 rows below the pad
; and the three cells below the door (row +5, columns -1, 0, +1) are free of
; bit 6: the new robot is placed on the door (ShipY + 4, $CB6A). After the menu
; the new record gets +$05 = 4, +$06 = 5, +$0B = 0 (stop), +$0C = 100
; (strength), +$0F = 1 (moves at once); CountRobots recounts the robots and
; UpdateStatusPanel reprints the panel.
;
; Bug (seen on an own instance (Nether Earth case) of the Nether Earth case):
; ConstructionMenu returns at once when all 24 of our slots are taken, with IY
; left on $DB80, the enemy's slot 24. The writes at $A6F3 then hit that enemy
; robot: its strength goes back to 100 and its order to 0, every turn the ship
; sits on the pad.
;
; Last, the game keys: Input bit 6 (key I in the default KeyTable) abandons the
; game (JP Start), bit 5 (key 5) saves the game to tape (SaveGame) and redraws
; the play screen (EnterPlay).
PlayLoop:
  CALL WaitKey            ; the controls; the pause while key 1 is held
  CALL MoveShip           ; the ship (unless a robot is under direct control)
  CALL WorldTurn          ; the robots and the shots
  CALL DrawView           ; the view
  CALL GameTurn           ; the turn: clock, captures, game end, frame pacing
  CALL ShipCell           ; HL = the map cell under the ship
  BIT 6,(HL)              ; bit 6: a robot or a building under the ship
  JR Z,CheckGameKeys      ; nothing there: only the game keys
  CALL FindRobot          ; one of ours? B = 48 - slot
  JR NZ,CheckWarbasePad   ; not a robot: try a building
  LD A,B                  ; B = 48 - the slot
  CP $19                  ; slots 24-47 (B < 25) are the enemy's
  JR C,CheckGameKeys      ; an enemy robot: no menu
  LD A,(Altitude)         ; the ship must rest exactly on the robot's top
  SUB (IY+$09)            ; minus the robot's height +$09 (its parts)
  SUB (IY+$0D)            ; minus its ground +$0D: 0 when the ship sits on its
                          ; top
  CALL Z,RobotMenu        ; landed on our robot
  JR CheckGameKeys        ; then the game keys
CheckWarbasePad:
  CALL FindBuilding       ; not a robot: a building?
  JR NZ,CheckGameKeys     ; neither robot nor building record here: the game
                          ; keys
  LD A,(IY+$02)           ; type 0: the pad of our warbase
  OR A                    ; building type +$02 = 0?
  JR NZ,CheckGameKeys     ; other buildings open nothing
  LD A,(Altitude)         ; the pad's top is 15
  CP $0F                  ; altitude 15?
  JR NZ,CheckGameKeys     ; the ship has not landed on the pad yet
  LD L,(IY+$00)           ; HL = the pad's cell + 4 rows: the door, where the
                          ; robot appears
  LD A,(IY+$01)           ; the cell's high byte
  ADD A,$08               ; + 8 = 4 map rows of $200 bytes down
  LD H,A                  ; HL = the door cell
  LD A,(HL)               ; the door's flags
  INC H                   ; the door, the cell below it and its two neighbours
  INC H                   ; $200 on: HL = the cell under the door
  OR (HL)                 ; its flags
  DEC HL                  ; its left neighbour
  OR (HL)                 ; its flags
  INC HL                  ; back to the cell under the door
  INC HL                  ; its right neighbour
  OR (HL)                 ; its flags: A = the four cells' bits ORed
  AND $40                 ; any of them taken: no menu
  JR NZ,CheckGameKeys     ; a robot or building in the way: the menu stays shut
  CALL ConstructionMenu   ; IY = the free robot slot it filled (or $DB80 when
                          ; none was free)
  LD (IY+$05),$04         ; the new robot's start state
  LD (IY+$06),$05         ; +$06 = 5 steps on that course
  LD (IY+$0B),$00         ; order 0: stop and defend
  LD (IY+$0C),$64         ; strength 100 %
  LD (IY+$0F),$01         ; +$0F = 1: its first step at once
  CALL CountRobots        ; recount the robots of both sides
  CALL UpdateStatusPanel  ; reprint the status values
CheckGameKeys:
  LD A,(Input)            ; Input bit 6 (key I): abandon the game
  BIT 6,A                 ; key I held?
  JP NZ,Start             ; abandon: the start-up and the title menu again
  BIT 5,A                 ; Input bit 5 (key 5): save the game
  JP Z,PlayLoop           ; neither key: the next turn
  CALL SaveGame           ; "PRESS RECORD AND PLAY", the tape save
  JP EnterPlay            ; redraw the play screen
