; --------------------------------------------------------------------------------------------------------------------
; start.asm: the start-up, the new game set-up and the play loop
;
; The game's top level. Start ($A600) is entered from stage 3's last JP (`$631B` on 128 K, `$63C4` on the tape path),
; from the end of a game ($AEFD), from key I in play ($A712) and from LOAD MAP (`$C1FD` jumps here after a map is read
; or refused). Its first instruction calls the start-up menu through $C100, which stage 3 has filled with a piece of
; the patches block (src/patches99: menu128 or menu48); the menu returns to StartGame ($A603) when START is chosen.
; StartGame builds the IM 2 table, seeds the random generator and falls into NewGameSetup, which clears the game state
; and builds the map; EnterPlay draws the play screen and switches to PlayInterrupt; PlayLoop runs one game turn a
; pass, forever.
;
; The routines in calling order: Start ($A600) -> the start-up menu ($C100) -> StartGame ($A603) -> NewGameSetup
; ($A62D) -> EnterPlay ($A68E) -> PlayLoop ($A69A). Each falls into the next; nothing here returns. There is no saved
; game: the loaded-game skip at $A62D and the save key in PlayLoop ($A715) are gone, NOPs in their place.
;
; The IM 2 trick: 257 bytes of $FD at $FE00-$FF00 with I = $FE make the vector $FDFD whatever the data bus holds; a JP
; sits at $FDFD and its operand Handler ($FDFE) is the only thing the game changes to switch the interrupt's work
; (StartInterrupt while the world stands still, PlayInterrupt in play).
;
; PlayLoop is the game's state machine in one loop: WaitKey, MoveShip, WorldTurn, DrawView, GameTurn; then what lies
; under the ship decides whether a menu opens: our robot with the ship on its top opens RobotMenu (robotmenu.asm), the
; pad of our warbase at altitude 15 with a free door opens ConstructionMenu (construction.asm), and PlayLoop writes
; the new robot's start state after it. Last the abort key I.
;
; The module owns no data; NewGameSetup zeroes the robot records ($DA00), the variables ($FD04-$FDFC), Buildings and
; Shots. The bug of the full robot table (the new-robot writes land on enemy slot 24) is kept. MenuInterrupt ($C4FD),
; the handler of the beeper title music, is listed here; nothing installs it any more.
; --------------------------------------------------------------------------------------------------------------------

; the entry: the start-up menu, then StartGame
;
; CALL $C100: the start-up menu, which stage 3 has placed there (the patches
; block's menu128 or menu48 piece: on 128 K it copies the menu from page 1 to
; $D800 in page 0 and runs it there). The piece keeps SP for the menu, so the
; menu's START returns through this CALL to StartGame at $A603, after the
; level's routine (`$DA8E`) has written the level's code and operands into this
; block.
;
; The block's own bytes of the menu at $C100 are zeros (mainmenu.asm); without
; stage 3 the CALL would run them as NOPs into whatever follows.
Start:
  CALL MenuPieceRoom      ; the start-up menu (stage 3's piece at $C100); START
                          ; returns here

; After START: the IM 2 table, Handler = StartInterrupt, the random seed, then
; a new game
;
; Reached when the start-up menu returns (START). DI, SP = 0; the IM 2 table
; $FE00-$FF00 (257 x $FD), JP at $FDFD, Handler = StartInterrupt, I = $FE, IM
; 2, EI; the random seed $FD00-$FD03 = $39,$30,$39,$30. Falls into
; NewGameSetup: every game is a new one.
StartGame:
  DI                      ; no interrupts while the vector table is built
  LD SP,$0000             ; SP = 0: the stack grows down from $FFFF
  LD HL,$FE00             ; the IM 2 table: 257 bytes of $FD at $FE00-$FF00
  LD BC,$00FD             ; B = 0: 256 bytes, C = $FD the byte stored
FillVectorTable:
  LD (HL),C               ; one vector byte
  INC HL                  ; the next
  DJNZ FillVectorTable    ; 256 times
  LD (HL),C               ; the 257th byte, $FF00: the vector $FEFF (bus byte
                          ; $FF) reads its high byte here
  LD A,$C3                ; the JP opcode
  LD ($FDFD),A            ; at $FDFD: every vector lands on Handler
  LD HL,StartInterrupt    ; StartInterrupt (EI; RET) until EnterPlay
  LD (Handler),HL           ; Handler = StartInterrupt
  LD A,$FE                ; I = $FE: the vector table's page
  LD I,A                  ; I points at $FE00
  IM 2                    ; IM 2: the interrupt jumps through ($FE00 + the bus
                          ; byte) = $FDFD
  EI                      ; interrupts on from here
  LD HL,$3039             ; the random seed $39,$30 (12345)
  LD (RandomSeed),HL           ; $FD00-$FD01
  LD (RandomSeed+2),HL           ; $FD02-$FD03: the same seed at every start, so each
                          ; game begins the same

; New game: clear the robots, variables, buildings and shots, place the ship,
; the resources, build the map
;
; Entered from StartGame. The two NOPs at $A62D take the place of NE's skip for
; a loaded game: here every game is a new one.
;
; Zeroes the robot records $DA00-$DCFF (48 x 16), the variables $FD04-$FDFC
; (everything past the random seed, below the JP of the IM 2 vector), the
; building table $FF01-$FFC9 and the five shot records $D7D3-$D7FF (5 x 9).
; Then: MapView = $DD00, ViewX = 0, ShipX = $11, ShipY = 14, Altitude = 0,
; ClimbTurns = 3 (the ship rises to 6 on its own at the start).
;
; The resources: our general resource = 99, the operand at $A684 (LOAD MAP
; writes a map's own value there, the NELEV file's last byte; every one of the
; 12 maps keeps 99), the others 0. FillEnemyResources then gives the enemy 99
; of all seven resources (it also writes $63 into Side, which BuildMap does not
; read). BuildMap then clears the map $DD00-$FCFF and the radar buffer $D800
; and builds the landscape, the warbases and the factories from the level's
; lists (the built-in one or a loaded map). Falls into EnterPlay.
NewGameSetup:
  NOP                     ; two NOPs: no loaded game to skip to
  NOP
  LD HL,Robots
  LD DE,Robots+1
  LD BC,$02FF
  LD (HL),$00
  LDIR
  LD HL,PrintAddr
  LD DE,PrintAddr+1
  LD BC,$00F8
  LD (HL),$00
  LDIR
  LD HL,Buildings
  LD DE,Buildings+1
  LD BC,$00C8
  LD (HL),$00
  LDIR
  LD HL,Shots
  LD DE,Shots+1
  LD BC,$002C
  LD (HL),$00
  LDIR
  LD HL,Map
  LD (MapView),HL
  LD HL,$0000
  LD (ViewX),HL
  LD HL,$0011
  LD (ShipX),HL
  LD A,$0E                ; row 14
  LD (ShipY),A            ; ShipY = 14
  XOR A
  LD (Altitude),A
  LD A,$03
  LD (ClimbTurns),A
  LD A,$63                ; 99 of the general resource for us: the operand at
                          ; $A684 is the map's (LOAD MAP)
  LD (Resources),A            ; Resources+0, our general resource
  CALL FillEnemyResources ; the enemy's seven resources = 99 each
  CALL BuildMap

; Draw the play screen and switch to the play interrupt
;
; DrawViewBackground and DrawPlayScreen build the play screen (the view, its
; frame, the radar, the status panel; then Handler = PlayInterrupt, which
; counts the frames in $FD34 and draws the radar each frame. Falls into
; PlayLoop. Entered from NewGameSetup, from a loaded game, and again after a
; game save (key 5, SaveGame) at $A71D.
EnterPlay:
  CALL DrawViewBackground ; clear the view buffer, paint the corners outside
                          ; the map
  CALL DrawPlayScreen     ; the whole play screen: view, frame, radar, status
                          ; panel
  LD HL,PlayInterrupt     ; PlayInterrupt from now on
  LD (Handler),HL           ; Handler: the frame count $FD34 and the radar each
                          ; frame

; The play loop: one game turn a pass (at least 10 frames)
;
; One pass: WaitKey (the controls into Input; key 1 pauses here), MoveShip,
; WorldTurn (every robot record and the five shots), DrawView (draw the view),
; GameTurn (the random step, the clock, captures, the end of the game; waits
; until 10 frames have passed since the previous turn).5 frames a turn, 5 turns
; a second.
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
; (strength), +$0F = 1 (moves at once; CountRobots recounts the robots and
; UpdateStatusPanel reprints the panel.
;
; The writes at $A6F3 then hit that enemy robot: its strength goes back to 100
; and its order to 0, every turn the ship sits on the pad.
;
; Last, the abort key: Input bit 6 (key I in the default KeyTable) abandons the
; game (JP Start: the start-up menu again). NE's save key (bit 5, key 5:
; SaveGame, then EnterPlay) is gone: $A715 jumps straight back to the loop's
; head and the eight bytes after it, $A718-$A71F, are NOPs that never run.
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
  LD A,(Altitude)            ; the ship must rest exactly on the robot's top
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
  LD A,(Altitude)            ; the pad's top is 15
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
  JP NZ,Start             ; abandon: Start, the start-up menu again
  JP PlayLoop             ; the next turn (NE tested the save key here)

; data_A718
data_A718:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; eight NOPs, NE's save call and
                                       ; EnterPlay jump: never run
