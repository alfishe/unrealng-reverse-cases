; --------------------------------------------------------------------------------------------------------------------
; start.asm: the game's entry, the restart, the new game set-up and the play loop
;
; The game's top level. The game block is entered once at GameEntry, which runs bank 1's start-up and falls into
; Restart; every later restart comes back to Restart: the abort key I in play, and the paths no longer run (the tape
; load's error, the old end of a game, the unused tape code). Restart starts the tune from its beginning, builds the
; IM 2 table, seeds the random generator and calls MainMenu; NewGameSetup clears the game state and builds the map (a
; loaded game skips it); EnterPlay draws the play screen and switches to PlayInterrupt; PlayLoop runs one game turn a
; pass, forever.
;
; The routines in calling order: GameEntry ($A5DA) -> Restart ($A5EF) -> MainMenu (the mainmenu module) ->
; NewGameSetup ($A62D) -> EnterPlay ($A68E) -> PlayLoop ($A69A). Each falls into the next; nothing here returns.
;
; The interrupts: Restart writes ImTable ($6800-$6900) full of $69 with I = $68, so every vector is $6969, the JP
; ImJump, whose operand ImHandler ($696A) switches the handler: MusicInterrupt (the tune) in the menus, PlayInterrupt
; in play (the frame count, the radar, the sound effects and the tune).
;
; PlayLoop is the game's state machine in one loop: WaitKey, MoveShip, WorldTurn, DrawView, GameTurn; then what lies
; under the ship decides whether a menu opens: our robot with the ship on its top opens RobotMenu (robotmenu module),
; the pad of our warbase at altitude 15 with a free door opens ConstructionMenu (construction module), and PlayLoop
; writes the new robot's start state after it. Last the game keys: I abandons the game (Restart), 5 saves it to disk
; (SaveGameStage, then EnterPlay again).
;
; The module owns no data; NewGameSetup zeroes the robot records ($DA00), the variables ($FD04-$FDFC), Buildings and
; Shots. The bug of the full robot table (the new-robot writes land on enemy slot 24) is at PlayLoop.
; --------------------------------------------------------------------------------------------------------------------

; The game block's entry: bank 1's start-up, then Restart
;
; The block's depacker ends with JP $A5DA. Interrupts off, SP = 0; pages bank 1
; ($11) and calls MusicStart ($D8E1, bank 1's own start-up code), pages bank 0
; ($10) and falls into Restart. Runs once: GlueStack grows over these bytes
; later.
GameEntry:
  DI                      ; no interrupts until the IM 2 table is built
  LD SP,$0000             ; SP = 0: the stack grows down from $FFFF, in bank 0
  LD A,$11                ; bank 1
  LD BC,$7FFD
  OUT (C),A
  CALL MusicStart         ; bank 1's start-up
  LD A,$10                ; bank 0 again
  LD BC,$7FFD
  OUT (C),A

; Every restart: the tune from its start, the IM 2 table, the random seed, the
; main menu
;
; Entered from GameEntry and by JP from the abort key in play ($A712); the dead
; paths jump here too (LoadError $C28A, GameOverWait $AEFD, UnusedTapeCode's
; return address at $AE30). Interrupts off, SP = 0, bank 1's PlayerInit ($C000)
; restarts the tune, bank 0 again. Then ImTable: 257 bytes of $69 at
; $6800-$6900 (B = 0 runs the loop 256 times, the last byte after it), ImJump =
; $C3 (JP), ImHandler = MusicInterrupt, I = $68, IM 2, EI. RandomSeed =
; $39,$30,$39,$30. MainMenu returns Z for a new game and NewGameSetup follows;
; a load does not return here: LoadReturn jumps to NewGameSetup with NZ.
Restart:
  DI                      ; no interrupts while the table is built
  LD SP,$0000             ; SP = 0
  LD A,$11                ; bank 1
  LD BC,$7FFD
  OUT (C),A
  CALL PlayerInit         ; the player: the tune from its start
  LD A,$10                ; bank 0 again
  LD BC,$7FFD
  OUT (C),A
  LD HL,ImTable           ; the IM 2 table: 257 bytes of $69 at $6800-$6900
  LD BC,$0069
FillVectorTable:
  LD (HL),C               ; 256 bytes, then the 257th below
  INC HL
  DJNZ FillVectorTable
  LD (HL),C
  LD A,$C3                ; the JP at $6969: every vector lands on ImHandler
  LD (ImJump),A
  LD HL,MusicInterrupt    ; MusicInterrupt: the tune plays while the menu runs
  LD (ImHandler),HL
  LD A,$68                ; I = $68: the vectors are read from ImTable
  LD I,A
  IM 2
  EI
  LD HL,$3039             ; the random seed $FD00-$FD03 = $39,$30,$39,$30
                          ; (12345 twice)
  LD (RandomSeed),HL
  LD (RandomSeed+2),HL
  CALL MainMenu           ; the main menu: back with Z = СТАРТ ИГРЫ (start
                          ; game) (a load goes on from LoadReturn)

; New game: clear the robots, variables, buildings and shots, place the ship,
; build the map
;
; Two ways in, told apart by the zero flag: Restart falls in with Z after
; MainMenu (option 0, СТАРТ ИГРЫ (start game)), and LoadReturn jumps here with
; NZ after the disk module loaded a saved game (the robots, the map, the
; buildings, the shots and the variables), which skips straight to EnterPlay. Z
; sets a new game up.
;
; Zeroes the robot records $DA00-$DCFF (48 x 16), the variables $FD04-$FDFC
; (everything past the random seed), the building table $FF01-$FFC9 and the
; five shot records $D7D3-$D7FF (5 x 9). Then: MapView = $DD00, ViewX = 0,
; ShipX = $11, ShipY = 10, Altitude = 0, the auto-climb counter $FD30 = 3 (the
; ship rises to 6 on its own at the start), the general resource of both sides
; = 20 (Resources and $FD4A). BuildMap then clears the map $DD00-$FCFF and the
; radar buffer $D800 and builds the landscape, the warbases and the factories.
; Falls into EnterPlay.
NewGameSetup:
  JR NZ,EnterPlay         ; NZ: a loaded game, nothing to set up
  LD HL,Robots             ; the 48 robot records
  LD DE,Robots+1             ; LDIR copy: each byte the one before it, all 0
  LD BC,$02FF             ; $2FF more bytes: 48 x 16 = $300 in all
  LD (HL),$00             ; the first byte 0
  LDIR                    ; zero $DA00-$DCFF
  LD HL,PrintAddr             ; the variables past the seed
  LD DE,PrintAddr+1             ; the fill target one byte up
  LD BC,$00F8             ; $F8 more: $FD04-$FDFC in all
  LD (HL),$00             ; the first byte 0
  LDIR                    ; zero the variables (the seed kept)
  LD HL,Buildings             ; the 56 building records (and 33 bytes more)
  LD DE,Buildings+1             ; the fill target one byte up
  LD BC,$00C8             ; $C8 more: $FF01-$FFC9 in all
  LD (HL),$00             ; the first byte 0
  LDIR                    ; zero the building table
  LD HL,Shots             ; the 5 shot records
  LD DE,Shots+1             ; the fill target one byte up
  LD BC,$002C             ; $2C more: 45 bytes, 5 shot records x 9
  LD (HL),$00             ; the first byte 0
  LDIR                    ; zero the shots: all free (+$01 = 0)
  LD HL,Map             ; the view starts at the map's left edge
  LD (MapView),HL           ; MapView = $DD00: the view's top left map cell
  LD HL,$0000             ; column 0
  LD (ViewX),HL           ; ViewX = 0: the view's first column
  LD HL,$0011             ; the ship over column 17, row 10, on the ground
  LD (ShipX),HL           ; ShipX = 17
  LD A,$0A                ; row 10
  LD (ShipY),A            ; ShipY = 10
  XOR A                   ; altitude 0: the ship on the ground
  LD (Altitude),A            ; Altitude = 0
  LD A,$03                ; auto-climb for 3 turns
  LD (ClimbTurns),A            ; ClimbTurns = 3: the ship rises on its own at the
                          ; start
  LD A,$14                ; 20 general resource for each side
  LD (Resources),A            ; Resources+0, our general resource
  LD (EnemyResources),A            ; EnemyResources+0, the enemy's general resource
  CALL BuildMap           ; build the map

; Draw the play screen and switch to the play interrupt
;
; DrawViewBackground and DrawPlayScreen build the play screen (the view, its
; frame, the radar, the status panel); then ImHandler = PlayInterrupt, which
; counts the frames in $FD34 and draws the radar each frame. Falls into
; PlayLoop. Entered from NewGameSetup (a new game, or a loaded one on NZ) and
; from PlayRedraw ($A71D) after a game save (key 5).
EnterPlay:
  CALL DrawViewBackground ; clear the view buffer, paint the corners outside
                          ; the map
  CALL DrawPlayScreen     ; the whole play screen: view, frame, radar, status
                          ; panel
  LD HL,PlayInterrupt     ; PlayInterrupt from now on
  LD (ImHandler),HL       ; ImHandler: the frame count $FD34 and the radar each
                          ; frame

; The play loop: one game turn a pass (at least 10 frames)
;
; One pass: WaitKey (the controls into Input; key 1 pauses here), MoveShip,
; WorldTurn (every robot record and the five shots), DrawView (draw the view),
; GameTurn (the random step, the clock, captures, the end of the game; waits
; until 10 frames have passed since the previous turn).
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
; ConstructionMenu returns at once when all 24 of our slots are taken, with IY
; left on $DB80, the enemy's slot 24. The writes at $A6F3 then hit that enemy
; robot: its strength goes back to 100 and its order to 0, every turn the ship
; sits on the pad.
;
; Last, the game keys: Input bit 6 (key I in the default KeyTable) abandons the
; game (JP Restart), bit 5 (key 5) saves the game to disk (JP SaveGameStage;
; the disk module comes back through SaveReturn to PlayRedraw, which redraws
; the play screen with EnterPlay).
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
  JP NZ,Restart           ; abandon: the start-up and the title menu again
  BIT 5,A                 ; Input bit 5 (key 5): save the game
  JP Z,PlayLoop           ; neither key: the next turn
  JP SaveGameStage        ; the save: SaveGameStage, then the disk module

; PlayRedraw
;
; Used by the routine at SaveReturn.
PlayRedraw:
  JP EnterPlay            ; redraw the play screen (SaveReturn comes back here
                          ; after a save)
