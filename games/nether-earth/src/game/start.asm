; the entry from N1: the IM 2 table, the start-up, the menu
;
; The IM 2 table $FE00-$FF00 (257 x $FD), JP at $FDFD, Handler =
; StartInterrupt, I = $FE, IM 2; the random seed $FD00-$FD03 = $39,$30,$39,$30;
; then MainMenu (Z: start a new game, NZ: a saved game was loaded). Reached
; again at the end of a game ($AEFD), by key I in play ($A712) and after a tape
; loading error ($C28A).
Start:
  DI                      ; no interrupts while the vector table is built
  LD SP,$0000             ; SP = 0: the stack grows down from $FFFF
  LD HL,$FE00             ; the IM 2 table: 257 bytes of $FD at $FE00-$FF00
  LD BC,$00FD
FillVectorTable:
  LD (HL),C               ; 256 bytes, then the 257th below
  INC HL
  DJNZ FillVectorTable
  LD (HL),C
  LD A,$C3                ; JP at $FDFD: every vector lands on Handler
  LD ($FDFD),A
  LD HL,StartInterrupt    ; StartInterrupt (EI; RET) while the menu runs
  LD (Handler),HL
  LD A,$FE
  LD I,A
  IM 2
  EI
  LD HL,$3039             ; the random seed $FD00-$FD03 = $39,$30,$39,$30
                          ; (12345 twice)
  LD (RandomSeed),HL
  LD (RandomSeed+2),HL
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
  LD DE,Robots+$0001
  LD BC,$02FF
  LD (HL),$00
  LDIR
  LD HL,PrintAddr             ; the variables past the seed
  LD DE,PrintAddr+1
  LD BC,$00F8
  LD (HL),$00
  LDIR
  LD HL,Buildings             ; the 56 building records (and 33 bytes more)
  LD DE,Buildings+1
  LD BC,$00C8
  LD (HL),$00
  LDIR
  LD HL,Shots             ; the 5 shot records
  LD DE,Shots+$0001
  LD BC,$002C
  LD (HL),$00
  LDIR
  LD HL,Map               ; the view starts at the map's left edge
  LD (MapView),HL
  LD HL,$0000
  LD (ViewX),HL
  LD HL,$0011             ; the ship over column 17, row 10, on the ground
  LD (ShipX),HL
  LD A,$0A
  LD (ShipY),A
  XOR A
  LD (Altitude),A
  LD A,$03                ; auto-climb for 3 turns
  LD (ClimbTurns),A
  LD A,$14                ; 20 general resource for each side
  LD (Resources),A
  LD (EnemyResources),A
  CALL BuildMap           ; build the map

; Draw the play screen and switch to the play interrupt
;
; DrawViewBackground and DrawPlayScreen build the play screen (the view, its
; frame, the radar, the status panel); then Handler = PlayInterrupt, which
; counts the frames in $FD34 and draws the radar each frame. Falls into
; PlayLoop. Entered from NewGameSetup, from a loaded game, and again after a
; game save (key 5, SaveGame) at $A71D.
EnterPlay:
  CALL DrawViewBackground
  CALL DrawPlayScreen
  LD HL,PlayInterrupt     ; PlayInterrupt from now on
  LD (Handler),HL

; The play loop: one game turn a pass (at least 10 frames)
;
; One pass: WaitKey (the controls into Input; key 1 pauses here), MoveShip,
; WorldTurn (every robot record and the five shots), DrawView (draw the view),
; GameTurn (the random step, the clock, captures, the end of the game; waits
; until 10 frames have passed since the previous turn). The recording ran it
; 3332 times in 36046 frames: about 10.5 frames a turn, 5 turns a second.
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
; Bug (seen on the own instance): ConstructionMenu returns at once when all 24
; of our slots are taken, with IY left on $DB80, the enemy's slot 24. The
; writes at $A6F3 then hit that enemy robot: its strength goes back to 100 and
; its order to 0, every turn the ship sits on the pad.
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
  JR Z,CheckGameKeys
  CALL FindRobot          ; one of ours? B = 48 - slot
  JR NZ,CheckWarbasePad
  LD A,B
  CP $19                  ; slots 24-47 (B < 25) are the enemy's
  JR C,CheckGameKeys
  LD A,(Altitude)            ; the ship must rest exactly on the robot's top
  SUB (IY+$09)
  SUB (IY+$0D)
  CALL Z,RobotMenu        ; landed on our robot
  JR CheckGameKeys
CheckWarbasePad:
  CALL FindBuilding       ; not a robot: a building?
  JR NZ,CheckGameKeys
  LD A,(IY+$02)           ; type 0: the pad of our warbase
  OR A
  JR NZ,CheckGameKeys
  LD A,(Altitude)            ; the pad's top is 15
  CP $0F
  JR NZ,CheckGameKeys
  LD L,(IY+$00)           ; HL = the pad's cell + 4 rows: the door, where the
                          ; robot appears
  LD A,(IY+$01)
  ADD A,$08
  LD H,A
  LD A,(HL)
  INC H                   ; the door, the cell below it and its two neighbours
  INC H
  OR (HL)
  DEC HL
  OR (HL)
  INC HL
  INC HL
  OR (HL)
  AND $40                 ; any of them taken: no menu
  JR NZ,CheckGameKeys
  CALL ConstructionMenu   ; IY = the free robot slot it filled (or $DB80 when
                          ; none was free)
  LD (IY+$05),$04         ; the new robot's start state
  LD (IY+$06),$05
  LD (IY+$0B),$00         ; order 0: stop and defend
  LD (IY+$0C),$64         ; strength 100 %
  LD (IY+$0F),$01         ; +$0F = 1: its first step at once
  CALL CountRobots        ; recount the robots of both sides
  CALL UpdateStatusPanel  ; reprint the status values
CheckGameKeys:
  LD A,(Input)            ; Input bit 6 (key I): abandon the game
  BIT 6,A
  JP NZ,Start
  BIT 5,A                 ; Input bit 5 (key 5): save the game
  JP Z,PlayLoop
  CALL SaveGame           ; "PRESS RECORD AND PLAY", the tape save
  JP EnterPlay            ; redraw the play screen
