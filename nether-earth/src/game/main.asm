; the entry from N1: the IM 2 table, the start-up, the menu
;
; Used by the routines at PlayLoop, GameOverWait and LoadError.
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

; landing on a robot of ours: DIRECT CONTROL, GIVE ORDERS, COMBAT MODE, LEAVE
; ROBOT; the order to +$0B
;
; Used by the routine at PlayLoop.
RobotMenu:
  PUSH IY                 ; IX = the robot record (from FindRobot)
  POP IX
  LD (IX+$0A),$01         ; +$0A = 1: the player sits on it; the robot stops
                          ; (UpdateRobot skips it)
  LD A,$04                ; MenuCursor = 4: LEAVE ROBOT highlighted first
  LD (MenuCursor),A
  LD A,$01                ; $FD39 = 1: the panel shows the menu,
                          ; UpdateStatusPanel keeps off it
  LD (PanelBusy),A

; Robot menu: draw the four items, the current order and the strength, then
; choose
;
; Clears the side panel (ClearPanel) and prints DIRECT CONTROL, GIVE ORDERS,
; COMBAT MODE, LEAVE ROBOT at (4,23), every 3 rows, attribute $4D, and the
; title -ORDERS- at (17,23). Falls into ShowOrder, ShowOrderMiles and
; RobotMenuChoose. Every submenu comes back here when it is done ($A93E, $AA09,
; $AACC, $ABFD, the combat menu at $AC8B).
RobotMenuShow:
  CALL ClearPanel         ; clear the side panel
  CALL PrintInline        ; the four items and -ORDERS-

; The robot menu: DIRECT CONTROL, GIVE ORDERS, COMBAT MODE, LEAVE ROBOT,
; -ORDERS-
;
; A PrintInline string: (4,23) attribute $4D, each item two lines of 8 with an
; empty line between (code 3 = the next line, same column), then (17,23)
; attribute $46 "-ORDERS-".
RobotMenuText:
  DEFM $01,$04,$17,$02,"MDIRECT  ",$03," CONTROL",$03,$03,"GIVE    ",$03,"  ORDERS",$03,$03,"COMBAT  ",$03,"    MODE",$03,$03,"LEA"
  DEFM "VE   ",$03,"   ROBOT",$01,$11,$17,$02,"F-ORDERS-",$00

; Robot menu: print the name of the robot's order
;
; Copies the 27-byte name of order +$0B from OrderNames ($A848 + 27 x order)
; into OrderLine, the string printed right after the CALL at $A7AA: three lines
; at (18,23), attribute $45.
ShowOrder:
  LD B,(IX+$0B)           ; B = order + 1
  INC B
  LD HL,StrengthText+$000D ; OrderNames - 27
  LD DE,$001B
OrderNameIndex:
  ADD HL,DE               ; HL += 27, order + 1 times
  DJNZ OrderNameIndex
  LD DE,OrderLine         ; into the string after the next CALL
  LD BC,$001B
  LDIR
  CALL PrintInline        ; print the order's name

; The order line: (18,23), attribute $45, then the copied name
OrderLineHead:
  DEFM $01,$12,$17,$02,"E"

; The order's name, 27 bytes copied from OrderNames (zero in the image)
;
; Filled by ShowOrder before each print; the copied name brings its own end
; byte 0.
OrderLine:
  DEFS $1B

; Robot menu: for ADVANCE and RETREAT, the miles under the order's name
;
; Orders 1 and 2 only: prints at (19,25) the distance +$0E / 2 with two digits
; (PrintNumber2), between "ADVANCE" and "MILES" of the order's name. The
; recordings never gave these orders, so the printing code after the string
; ($A7DC) is still data in game.ctl; on the own instance an ADVANCE of 10 miles
; showed "10" there.
ShowOrderMiles:
  LD A,(IX+$0B)           ; order 1 or 2?
  DEC A
  CP $02
  JR NC,RobotMenuChoose
  CALL PrintInline        ; the position for the number

; (19,25), the position of the miles
MilesPos:
  DEFM $01,$13,$19,$00

; Code the recordings never ran: LD A,(IX+$0E); SRL A; CALL $D3E5
;
; The miles, stored doubled in +$0E, printed with two digits and a leading
; space. Runs for orders 1 and 2 (seen on the own instance), then falls into
; RobotMenuChoose.
ShowMilesCode:
  LD A,(IX+$0E)
  SRL A
  CALL PrintNumber2

; Robot menu: choose an item and run it; LEAVE ROBOT closes the menu
;
; Prints the strength, runs ListMenu on the four items (HL = $5837, the
; attribute of row 1 column 23, E = 5, A = MenuCursor) and keeps the choice in
; MenuCursor, so the menu reopens on it. 1 DIRECT CONTROL ($A93B), 2 GIVE
; ORDERS (OrdersMenu), 3 COMBAT MODE (CombatMenu $AC00), 4 LEAVE ROBOT: a beep,
; +$06 = 0, +$0A = 0 (the robot carries on with its order), the auto-climb
; $FD30 = 5 turns so the ship rises off the robot and the menu does not reopen,
; then CloseRobotMenu.
;
; CloseRobotMenu ($A812) clears the panel, sets $FD39 = 0 and redraws the
; status panel (ShowStatusPanel); ListMenu also jumps there when the robot is
; destroyed while its menu is open (seen: freeing +$01 under the open menu
; closed it).
RobotMenuChoose:
  CALL ShowStrength       ; the strength
  LD HL,$5837             ; item 1 at row 4, column 23
  LD E,$05                ; four items
  LD A,(MenuCursor)            ; highlight the last choice
  CALL ListMenu
  LD (MenuCursor),A
  DEC A                   ; 1: DIRECT CONTROL
  JP Z,DirectControlItem
  DEC A                   ; 2: GIVE ORDERS
  JP Z,OrdersMenu
  DEC A                   ; 3: COMBAT MODE
  JP Z,CombatMenu
LeaveRobot:
  LD A,$78                ; 4: LEAVE ROBOT
  CALL Beep
  XOR A                   ; +$06 = 0
  LD (IX+$06),A
  LD (IX+$0A),A           ; +$0A = 0: no longer held by the player
  LD A,$05                ; climb for 5 turns
  LD (ClimbTurns),A
; This entry point is used by the routines at DistanceSelect, CombatMenuCode
; and ListMenu.
CloseRobotMenu:
  CALL ClearPanel         ; clear the panel and give it back to the status
                          ; display
  XOR A
  LD (PanelBusy),A
  CALL ShowStatusPanel    ; the status panel
  RET

; Robot menus: print STRENGTH and the robot's strength in %
;
; Prints "STRENGTH" at (22,23) and the value of +$0C at (23,25), three digits
; with leading spaces and "%" (a robot is born with 100). A negative +$0C (a
; dying robot, UpdateRobot counts it up) shows as 0 % (poked $80: "0%"). Called
; once a turn by every robot menu loop. IX = the robot record.
ShowStrength:
  CALL PrintInline        ; "STRENGTH", then the position of the value

; "STRENGTH" at (22,23) attribute $46, then (23,25) attribute $47
StrengthText:
  DEFM $01,$16,$17,$02,"FSTRENGTH",$01,$17,$19,$02,"G",$00

; Print the strength +$0C as "nnn%"
;
; The tail of ShowStrength after its inline string: a negative strength is
; shown as 0; PrintNumber3 prints HL with three digits, E = $20 makes the
; leading zeros spaces; the "%" goes out through PrintCharKeep.
ShowStrengthValue:
  LD A,(IX+$0C)
  OR A                    ; negative: a dying robot
  JP P,l_A83B
  XOR A
l_A83B:
  LD L,A                  ; HL = the strength
  LD H,$00
  LD E,$20                ; leading zeros as spaces
  CALL PrintNumber3
  LD A,$25                ; "%"
  JP PrintCharKeep

; The names of the orders, 27 bytes each (order 0: STOP AND DEFEND)
;
; Nine records of 27 bytes, indexed by +$0B: three lines of 8 joined by code 3,
; ended by 0. ShowOrder copies one into OrderLine. Order 0 is "  STOP  ", " AND
; ", " DEFEND ".
OrderNames:
  DEFM "  STOP  ",$03,"  AND   ",$03," DEFEND ",$00

; Order 1: ADVANCE (the miles are printed into the blank middle line)
OrderName1:
  DEFM "ADVANCE ",$03,"        ",$03," MILES  ",$00

; Order 2: RETREAT (the miles in the middle line)
OrderName2:
  DEFM "RETREAT ",$03,"        ",$03," MILES  ",$00

; Order 3: DESTROY ENEMY ROBOTS
OrderName3:
  DEFM "DESTROY ",$03," ENEMY  ",$03," ROBOTS ",$00

; Order 4: DESTROY ENEMY FACTORYS
OrderName4:
  DEFM "DESTROY ",$03," ENEMY  ",$03,"FACTORYS",$00

; Order 5: DESTROY ENEMY WARBASES
OrderName5:
  DEFM "DESTROY ",$03," ENEMY  ",$03,"WARBASES",$00

; Order 6: CAPTURE NEUTRAL FACTORYS
OrderName6:
  DEFM "CAPTURE ",$03,"NEUTRAL ",$03,"FACTORYS",$00

; Order 7: CAPTURE ENEMY FACTORYS
OrderName7:
  DEFM "CAPTURE ",$03," ENEMY  ",$03,"FACTORYS",$00

; Order 8: CAPTURE ENEMY WARBASES
OrderName8:
  DEFM "CAPTURE ",$03," ENEMY  ",$03,"WARBASES",$00

; Robot menu item 1: direct control, then the robot menu again
;
; Not run in the recordings; run on the own instance.
DirectControlItem:
  CALL DirectControl
  JP RobotMenuShow

; Drive the robot with the controls until fire
;
; +$0A = 2 and +$05 = 0, then a loop of game turns without the ship's own move:
; WorldTurn moves the robot from Input ($B184 -> $B450) and calls MoveShip from
; there ($B4A8), so the ship travels on the robot; DrawView draws the view,
; MenuRadarTick blinks the ship on the radar, GameTurn, ShowStrength. Fire
; gives the robot back (+$0A = 1, a beep) and returns. Returns at once (Z) when
; the robot is destroyed (+$01 = 0).
;
; Used by the robot menu (item 1) and by the combat menu (MOVE ROBOT, $AC93).
; Not run in the recordings. On the own instance: +$0A went to 2, holding right
; turned the robot (+$08 4 -> 1) and moved it one column, the ship's ShipX
; followed (22 -> 23); fire set +$0A back to 1.
DirectControl:
  LD (IX+$0A),$02         ; +$0A = 2: the robot follows Input
  LD (IX+$05),$00
  CALL WaitRelease        ; the fire that chose the item must go first
DirectControlLoop:
  CALL WorldTurn          ; a game turn with the robot driven
  CALL DrawView
  CALL MenuRadarTick      ; the ship's radar blink
  CALL GameTurn
  CALL ShowStrength
  LD A,(IX+$01)           ; destroyed: back
  OR A
  RET Z
  CALL WaitKey            ; the controls
  AND $10                 ; fire: give the robot back
  JR Z,DirectControlLoop
  LD (IX+$0A),$01         ; +$0A = 1: held, not driven
  LD A,$78
  CALL Beep
  RET

; GIVE ORDERS: the five orders
;
; Clears the panel and prints SELECT ORDERS at (4,24) and the five items from
; (7,23): STOP AND DEFEND, ADVANCE ?? MILES, RETREAT ?? MILES, SEARCH &
; DESTROY, SEARCH & CAPTURE. Falls into OrdersMenuChoose.
OrdersMenu:
  CALL ClearPanel
  CALL PrintInline

; GIVE ORDERS: SELECT ORDERS and the five items
OrdersMenuText:
  DEFM $01,$04,$18,$02,"GSELECT",$03,"ORDERS",$02,"M",$01,$07,$17,"STOP AND",$03,"  DEFEND",$03,$03,"ADVANCE ",$03,"?? MILES",$03,$03,"RETR"
  DEFM "EAT ",$03,"?? MILES",$03,$03,"SEARCH &",$03," DESTROY",$03,$03,"SEARCH &",$03," CAPTURE",$00

; GIVE ORDERS: choose; stop at once, advance / retreat ask the miles, search
; asks the target
;
; ListMenu at HL = $5897 (row 4: item 1 at row 7), E = 6, A = 1. Item 1 sets
; order 0 (stop and defend) and returns to the robot menu. Items 2 and 3 set
; order 1 (advance) or 2 (retreat) and go on to the distance menu
; (DistanceMenu, $AA19 on). Items 4 and 5 go to TargetMenu with the flags of CP
; 3 (Z = SEARCH & DESTROY).
OrdersMenuChoose:
  CALL ShowStrength
  LD HL,$5897
  LD E,$06
  LD A,$01
  CALL ListMenu           ; the item, 1-5
  PUSH AF
  CALL WaitRelease        ; the fire must go
  POP AF
  DEC A                   ; 1: STOP AND DEFEND
  JR NZ,OrderMove
  LD (IX+$0B),A           ; order 0
  LD A,$78
  CALL Beep
  JP RobotMenuShow
OrderMove:
  CP $03                  ; 2 ADVANCE (A = 1), 3 RETREAT (A = 2); 4, 5 the
                          ; searches
  JP NC,TargetMenu
  LD (IX+$0B),A           ; order 1 or 2
  PUSH AF
  CALL ClearPanel         ; clear the panel for the distance menu
  POP AF
  DEC A
  JR NZ,RetreatTitle
  CALL PrintInline        ; ADVANCE: its title, then the distance menu

; "ADVANCE " at (5,23), attribute $4F
AdvanceTitle:
  DEFM $01,$05,$17,$02,"OADVANCE ",$00

; Code the recordings never ran: JR $AA40, past the RETREAT title
AdvanceJump:
  JR DistanceMenu

; GIVE ORDERS, RETREAT: the title of the distance menu
;
; Prints "RETREAT " at (5,23), attribute $4F. The bytes after the string
; ($AA40-$AACE) are the distance menu, code that no recording ran and game.ctl
; still holds as data (next entries).
RetreatTitle:
  CALL PrintInline

; "RETREAT " at (5,23), attribute $4F
RetreatTitleText:
  DEFM $01,$05,$17,$02,"ORETREAT ",$00

; Code the recordings never ran: CALL PrintInline, the distance menu's texts
;
; The distance menu of ADVANCE and RETREAT (run on the own instance: up 3
; times, down once, fire = 10 miles, +$0E = 20, +$0B = 1). The texts: "??
; MILES" under the title, SELECT DISTANCE at (9,23), "0 MILES" at (13,24).
DistanceMenu:
  CALL PrintInline

; The distance menu: ?? MILES, SELECT DISTANCE, 0 MILES
DistanceText:
  DEFM $03,"?? MILES",$01,$09,$17,$02,"E SELECT",$03,"DISTANCE",$01,$0D,$18,$02,"F0 MILES",$00

; Code the recordings never ran: choose the miles, 0-50 by 5
;
; D = the miles, from 0. A loop of game turns (ShowStrength, WorldTurn,
; DrawView, MenuRadarTick, GameTurn; a destroyed robot closes the menu, JP
; $A812). Up adds 5, down takes 5 (the value must stay 0-50: CP $33), each
; change reprinted at (13,23) attribute $46 with a beep $14.
;
; Fire ($AAB8): +$0E = miles x 2; 0 miles turns the order back into 0 (stop); a
; beep, WaitRelease, back to the robot menu. Layout: $AA6E LD D,0; $AA70 the
; turn; $AA88 WaitKey, BIT 4; $AA8F the step: (Input >> 2) AND 3, down 1 -> -5,
; up 2 -> +5; $AAA4 PrintInline (13,23) $46; $AAAD the number (PrintNumber2);
; $AAB8 the end.
DistanceSelect:
  LD D,$00
l_AA70:
  PUSH DE
  CALL ShowStrength
  CALL WorldTurn
  CALL DrawView
  CALL MenuRadarTick
  CALL GameTurn
  POP DE
  LD A,(IX+$01)
  OR A
  JP Z,CloseRobotMenu
  CALL WaitKey
  BIT 4,A
  JR NZ,l_AAB8
  LD C,D
  RRCA
  RRCA
  AND $03
  JR Z,l_AA70
  AND $02
  LD B,A
  ADD A,A
  ADD A,A
  ADD A,B
  SUB $05
  ADD A,C
  CP $33
  JR NC,l_AA70
  LD D,A
  CALL PrintInline

; data_AAA7
data_AAA7:
  DEFB $01,$0D,$17,$02,$46,$00,$7A,$CD
  DEFB $E5,$D3,$3E,$14,$CD,$AC,$CC,$18
  DEFB $B8

; l_AAB8
;
; Used by the routine at DistanceSelect.
l_AAB8:
  LD A,D
  RLCA
  LD (IX+$0E),A
  OR A
  JR NZ,l_AAC4
  LD (IX+$0B),$00
l_AAC4:
  LD A,$78
  CALL Beep
  CALL WaitRelease
  JP RobotMenuShow

; SEARCH & DESTROY or SEARCH & CAPTURE: the three targets
;
; Z (the destroy item): clears the panel and prints SEARCH & DESTROY, SELECT
; TARGET and ENEMY ROBOTS / ENEMY FACTORYS / ENEMY WARBASES; NZ goes to
; CaptureMenu.
TargetMenu:
  JP NZ,CaptureMenu       ; SEARCH & CAPTURE
  CALL ClearPanel
  CALL PrintInline

; SEARCH & DESTROY: SELECT TARGET, ENEMY ROBOTS, FACTORYS, WARBASES
DestroyMenuText:
  DEFM $01,$04,$17,$02,"OSEARCH &",$03," DESTROY",$01,$08,$18,$02,"ESELECT",$03,"TARGET",$01,$0C,$17,$02,"MENEMY   ",$03,"  ROBOTS",$03,$03,"E"
  DEFM "NEMY   ",$03,"FACTORYS",$03,$03,"ENEMY   ",$03,"WARBASES",$00

; SEARCH & DESTROY: choose the target, orders 3-5
;
; ListMenu at HL = $5937 (item 1 at row 12), E = 4, A = 1; the item + 2 is the
; order (3 robots, 4 factories, 5 warbases) for SetOrder.
DestroyMenuChoose:
  CALL ShowStrength
  LD HL,$5937
  LD A,$01
  LD E,$04
  CALL ListMenu
  ADD A,$02               ; order 3-5
  JR SetOrder

; SEARCH & CAPTURE: the three targets
;
; Prints SEARCH & CAPTURE, SELECT TARGET and NEUTRAL FACTORYS / ENEMY FACTORYS
; / ENEMY WARBASES.
CaptureMenu:
  CALL ClearPanel
  CALL PrintInline

; SEARCH & CAPTURE: SELECT TARGET, NEUTRAL FACTORYS, ENEMY FACTORYS, ENEMY
; WARBASES
CaptureMenuText:
  DEFM $01,$04,$17,$02,"OSEARCH &",$03," CAPTURE",$01,$08,$18,$02,"ESELECT",$03,"TARGET",$01,$0C,$17,$02,"MNEUTRAL ",$03,"FACTORYS",$03,$03,"E"
  DEFM "NEMY   ",$03,"FACTORYS",$03,$03,"ENEMY   ",$03,"WARBASES",$00

; SEARCH & CAPTURE: choose the target, orders 6-8
;
; The same list as DestroyMenuChoose; the item + 5 is the order (6 neutral
; factories, 7 enemy factories, 8 enemy warbases).
CaptureMenuChoose:
  CALL ShowStrength
  LD HL,$5937
  LD A,$01
  LD E,$04
  CALL ListMenu
  ADD A,$05               ; order 6-8

; Store a search order, look for its first target, or fall back to stop
;
; A = the order (3-8) into +$0B. Orders 4 and 5 (destroy factories, warbases)
; need the nuclear bomb (+$07 bit 6); without it the order becomes 0. Otherwise
; $FD51 = 0 (our side), +$0E = $FF and FindTargetBuilding looks for a target of
; the order from the robot's X (+$02/+$03): D, the index it found, goes to
; +$0E; no target (Z) makes the order 0. A beep, WaitRelease, back to the robot
; menu. Ran 7 times in the recording (destroy robots, capture neutral and enemy
; factories).
;
; CombatMenu ($AC00) follows in the same block: the robot menu's item 3.
SetOrder:
  LD (IX+$0B),A
  CP $04                  ; orders 4 and 5 need the bomb
  JR C,FindOrderTarget
  CP $06
  JR NC,FindOrderTarget
  BIT 6,(IX+$07)
  JR Z,OrderRefused
FindOrderTarget:
  LD L,(IX+$02)           ; HL = the robot's X
  LD H,(IX+$03)
  PUSH AF
  XOR A
  LD (Side),A            ; $FD51 = 0: the search runs for our side
  POP AF
  LD (IX+$0E),$FF         ; no target yet
  CALL FindTargetBuilding ; Z: nothing to go for
  LD (IX+$0E),D           ; the target found
  JR NZ,OrderSet
OrderRefused:
  LD (IX+$0B),$00         ; order 0: stop and defend
OrderSet:
  LD A,$78                ; the beep of a choice
  CALL Beep
  CALL WaitRelease
  JP RobotMenuShow
; This entry point is used by the routine at RobotMenuChoose.
CombatMenu:
  CALL ClearPanel         ; COMBAT MODE: the six items, then the code at $AC7C
  CALL PrintInline

; COMBAT MODE: NUCLEAR BOMB, FIRE PHASERS, FIRE MISSILES, FIRE CANNON, MOVE
; ROBOT, STOP COMBAT
;
; Printed at (4,23), attribute $4D, an item every 3 rows like the robot menu.
CombatMenuText:
  DEFM $01,$04,$17,$02,"MNUCLEAR ",$03,"    BOMB",$03,$03,"FIRE    ",$03," PHASERS",$03,$03,"FIRE    ",$03,"MISSILES",$03,$03,"FIR"
  DEFM "E    ",$03,"  CANNON",$03,$03,"MOVE    ",$03,"   ROBOT",$03,$03,"STOP    ",$03,"  COMBAT",$00

; Code the recordings never ran: the combat menu
;
; No recording entered COMBAT MODE, so these 91 bytes are still data. ListMenu
; on the six items (HL = $5837, E = 7), STOP COMBAT highlighted first ($AC7F A
; = 6); the strength printed first.
;
; 6 STOP COMBAT: back to the robot menu. 5 MOVE ROBOT: DirectControl, then the
; menu again on that item. 1-4 need the weapon: +$07 rotated left item + 1
; times leaves in carry bit 6 (nuclear), 5 (phasers), 4 (missiles) or 3
; (cannon); without it a low buzz ($FA) and the menu again.
;
; 1 NUCLEAR BOMB: IY = IX, NuclearBlast (the blast), then the menu closes (JP
; $A812). 2-4: shot record 0 at $D7D3; if it is free (+$01 = 0) A = 5 - item (3
; phasers, 2 missiles, 1 cannon) and FireShot launches it from the robot along
; its facing (+$08), then a view redraw and a game turn; a busy shot slot
; buzzes.
;
; Seen on the own instance: FIRE CANNON on a bipod + cannon robot wrote +$05 =
; 4 (the robot's facing), +$06 = 5, +$07 = 1, +$08 = $0A into $D7D3; FIRE
; MISSILES without missiles changed nothing. Layout: $AC7C the strength; $AC81
; the list; $AC93 MOVE ROBOT; $AC99 the weapon test; $ACA9 the bomb; $ACB4 the
; shot slot; $ACCE the buzz.
CombatMenuCode:
  CALL ShowStrength
  LD A,$06
l_AC81:
  LD HL,$5837
  LD E,$07
  CALL ListMenu
  CP $06
  JP Z,RobotMenuShow
  PUSH AF
  CP $05
  JR NZ,l_AC99
  CALL DirectControl
  POP AF
  JR l_AC81
l_AC99:
  LD C,A
  LD B,A
  INC B
  LD A,(IX+$07)
l_AC9F:
  RLCA
  DJNZ l_AC9F
  JR NC,l_ACCE
  POP AF
  CP $01
  JR NZ,l_ACB3
  PUSH IX
  POP IY
  CALL NuclearBlast
  JP CloseRobotMenu
l_ACB3:
  PUSH AF
  LD IY,Shots
  LD A,(IY+$01)
  OR A
  JR NZ,l_ACCE
  LD A,$05
  SUB C
  CALL FireShot
  CALL DrawView
  CALL GameTurn
  POP AF
  JP l_AC81
l_ACCE:
  LD A,$FA
  CALL Beep
  POP AF
  JP l_AC81

; a list menu: HL the attribute of item 0 (an item every 3 rows), E the items +
; 1, A the first highlighted; down / up move, fire returns A
;
; Used by the routines at RobotMenuChoose, OrdersMenuChoose, DestroyMenuChoose,
; CaptureMenuChoose and CombatMenuCode.
ListMenu:
  PUSH AF                 ; the fire or move that opened the menu must go first
  CALL WaitRelease
  POP AF
  LD D,A                  ; D = the highlighted item
  LD C,$4E                ; $4E: highlighted
  CALL PaintMenuItem
ListMenuLoop:
  LD A,(IX+$01)           ; the robot destroyed (+$01 = 0)?
  OR A
  JR NZ,ListMenuKey
  POP HL                  ; drop our return: close the robot menu
  JP CloseRobotMenu
ListMenuKey:
  PUSH HL                 ; the controls
  CALL WaitKey
  POP HL
  LD C,D
  LD A,(Input)
  BIT 4,A                 ; fire: chosen
  JR NZ,ListMenuChosen
  RRCA                    ; bit 2 down / bit 3 up, now bits 1 / 2
  AND $06
  JR Z,ListMenuTurn
  AND $02                 ; A = 2 for down, 0 for up
  DEC C                   ; item - 1, then + 2 for down
  ADD A,C
  JR Z,ListMenuTurn       ; item 0 does not exist
  CP E                    ; past the last item
  JR NC,ListMenuTurn
  PUSH AF
  LD A,D
  LD C,$4D                ; $4D: the old item back to normal
  CALL PaintMenuItem
  POP AF
  LD D,A
  LD C,$4E                ; highlight the new one
  CALL PaintMenuItem
  LD A,$14                ; the click of a move
  CALL Beep
ListMenuTurn:
  PUSH DE                 ; a game turn while the menu waits
  PUSH HL
  CALL WorldTurn
  CALL DrawView
  CALL MenuRadarTick
  CALL GameTurn
  CALL ShowStrength       ; the strength
  POP HL
  POP DE
  JR ListMenuLoop
ListMenuChosen:
  LD A,D                  ; $4F: the chosen item
  LD C,$4F
  CALL PaintMenuItem
  LD A,$64                ; the beep of a choice
  CALL Beep
  LD A,D                  ; A = the item
  RET

; Colour list item A: 2 rows of 8 attributes with C
;
; HL = the attribute of item 0; item A starts $60 bytes (3 rows) further per
; item. Fills 8 attributes, moves down a row ($18 more) and fills 8 more with C
; ($4D normal, $4E highlighted, $4F chosen). A must be 1 or more. Keeps DE and
; HL.
PaintMenuItem:
  LD B,A
  PUSH DE
  PUSH HL
  LD DE,$0060             ; 3 attribute rows an item
l_AD42:
  ADD HL,DE
  DJNZ l_AD42
  LD B,$08                ; the item's top row
  CALL FillAttributes
  LD A,$18                ; the next row, same column
  CALL AddAToHL
  LD B,$08                ; its bottom row
  CALL FillAttributes
  POP HL
  POP DE
  RET

; wait until no control is held
;
; Used by the routines at DirectControl, OrdersMenuChoose, l_AAB8, SetOrder,
; ListMenu and GameOverWait.
WaitRelease:
  PUSH BC
  PUSH HL
WaitReleaseLoop:
  CALL WaitKey            ; until Input is 0
  OR A
  JR NZ,WaitReleaseLoop
  POP HL
  POP BC
  RET

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
  JR NZ,l_AD85
  LD (HL),$00             ; an hour
  INC HL
  INC (HL)
  LD A,(HL)
  CP $18
  JR NZ,l_AD85
  LD (HL),$00             ; a day
  LD HL,(Clock+2)
  INC HL
  LD (Clock+2),HL
  CALL DailyProduction    ; the day's production of both sides
l_AD85:
  CALL PrintInline        ; position, setting 0, attribute $57

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
  JR Z,l_AE04
  POP BC
  INC C                   ; one more capture
  PUSH BC
  LD A,$1C                ; A = the point's index
  SUB B
  CP $04                  ; 0-3: a warbase
  JR NC,l_ADFE
  LD B,E
  CALL GiveWarbase        ; the warbase changes side
  JR l_AE04
l_ADFE:
  SUB $04                 ; 4-27: factory A - 4
  LD B,E
  CALL GiveFactory
l_AE04:
  POP BC
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
l_AE58:
  INC HL
  INC DE
  LD A,(DE)               ; 2 x the factories of the kind
  ADD A,A
  CALL AddCapped
  DJNZ l_AE58
  RET

; (HL) += A, at most 99
;
; Used by the routine at ProduceSide.
AddCapped:
  ADD A,(HL)
  CP $64
  JR C,l_AE69
  LD A,$63
l_AE69:
  LD (HL),A               ; store
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
l_AEF1:
  HALT
  DJNZ l_AEF1
  CALL WaitRelease
l_AEF7:
  CALL WaitKey
  OR A
  JR Z,l_AEF7
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

; the ship's move from Input: X by right / left, Y by down / up, each refused
; by CheckShipMove
;
; Used by the routines at PlayLoop and TurnOrStep.
MoveShip:
  CALL LiftShipFromMap    ; clear the ship's mark (map bit 7) and its radar
                          ; blip
  LD A,(Input)            ; up or down held?
  AND $0C
  JR Z,MoveShipX
  LD A,(ClimbTurns)            ; the auto-climb runs out twice as fast
  OR A
  JR Z,MoveShipX
  DEC A
  LD (ClimbTurns),A
MoveShipX:
  LD A,(Input)            ; right / left, not both
  AND $03
  JR Z,MoveShipY
  CP $03
  JR Z,MoveShipY
  LD HL,(ShipX)
  RRCA                    ; carry: right
  JR C,l_AF42
  LD A,H                  ; left: not past column $0E
  OR A
  JR NZ,l_AF3F
  LD A,L
  CP $0E
  JR Z,MoveShipY
l_AF3F:
  DEC HL                  ; one column left
  JR l_AF4C
l_AF42:
  LD A,H                  ; right: not past column $1F5
  OR A
  JR Z,l_AF4B
  LD A,L
  CP $F5
  JR Z,MoveShipY
l_AF4B:
  INC HL                  ; one column right
l_AF4C:
  LD A,(ShipY)            ; refused where the ship would be lower than what
                          ; stands there
  CALL CheckShipMove
  JR C,FollowView
  LD (ShipX),HL
FollowView:
  LD HL,(ShipX)           ; the view keeps the ship between its columns 13 and
                          ; 22
  LD DE,(ViewX)
  XOR A
  SBC HL,DE
  LD A,L
  CP $0D
  JR NZ,l_AF67            ; at 13: the view one column left
  DEC DE
l_AF67:
  CP $16
  JR NZ,l_AF6C            ; at 22: one column right
  INC DE
l_AF6C:
  LD (ViewX),DE
  LD HL,Map               ; MapView = $DD00 + ViewX
  ADD HL,DE
  LD (MapView),HL
MoveShipY:
  LD A,(ShipY)            ; down / up, not both
  LD C,A
  LD A,(Input)
  RRCA
  RRCA
  AND $03
  JR Z,AutoClimb
  CP $03
  JR Z,AutoClimb
  RRCA                    ; down: Y + 1
  JR NC,l_AF8C
  INC C
l_AF8C:
  RRCA                    ; up: Y - 1
  JR NC,l_AF90
  DEC C
l_AF90:
  LD A,C                  ; Y 0 (or 16) is off the map
  AND $0F
  JR Z,AutoClimb
  LD HL,(ShipX)
  LD B,A
  CALL CheckShipMove      ; refused where the ship would be too low
  JR C,AutoClimb
  LD A,B
  LD (ShipY),A
AutoClimb:
  LD A,(ClimbTurns)            ; $FD30 > 0: climb whatever fire says
  OR A
  JR Z,l_AFAE
  DEC A
  LD (ClimbTurns),A
  JR Climb
l_AFAE:
  LD A,(Input)            ; fire: climb
  AND $10
  JR Z,Sink
Climb:
  LD A,(Altitude)            ; 2 a turn up to $30
  CP $30
  JR NC,MoveShipDone
  ADD A,$02
  LD (Altitude),A
  JR MoveShipDone
Sink:
  LD A,(Altitude)            ; 1 a turn, not below 0
  DEC A
  JP M,MoveShipDone
  LD B,A                  ; C = the height under the ship
  LD A,(ShipY)
  LD HL,(ShipX)
  CALL CheckShipMove
  LD A,B
  CP C                    ; not below what is under it
  JR C,MoveShipDone
  LD (Altitude),A
MoveShipDone:
  CALL ScrollRadar        ; the radar window follows the ship
  LD HL,RadarBlink             ; the radar blink
  INC (HL)
  CALL PutShipOnMap       ; the ship's mark and blip at the new place
  RET

; Move the radar window by 64 columns when the ship nears its edge
;
; The radar shows 128 map columns: from column $FD1B x 8 ($FD1C = the same as a
; column, 16 bits). With A = ShipX / 8 - $FD1B: below 2 (the ship within 16
; columns of the left edge) the window moves 8 units left, unless it is at 0;
; 14 and more moves it 8 units right, at most to $30 (columns 384-511). A move
; sets $FD52 = 1: the radar bitmap is rebuilt from the map by BuildRadar at the
; ship's next mark ($B029). Called by MoveShip every turn (3332 times).
ScrollRadar:
  LD HL,(ShipX)
  LD A,(RadarLeft)            ; C = the window's left edge, in units of 8 columns
  LD C,A
  LD A,L                  ; A = ShipX / 8
  RR H
  RRA
  SRL A
  SRL A
  SUB C                   ; the ship's place in the window, 0-15
  CP $02
  JR C,l_AFFF
  CP $0E
  JR NC,RadarScrollRight
  RET
l_AFFF:
  LD A,C                  ; left by 8 units
  SUB $08                 ; the window would move 8 columns left
  RET M                   ; already at the left end: stay
  JR RadarSetWindow
RadarScrollRight:
  LD A,C                  ; the ship is 14 or more units right of the window's
                          ; left edge: 8 units right
  ADD A,$08
  CP $38                  ; $38 would pass the map's end: stay at $30 (columns
                          ; $180-$1FF)
  RET Z
RadarSetWindow:
  LD (RadarLeft),A            ; RadarLeft ($FD1B) = A (in 8-column units)
  ADD A,A                 ; RadarColumn ($FD1C) = A * 8, the first map column
                          ; the radar shows
  ADD A,A
  LD L,A
  LD H,$00
  ADD HL,HL
  LD (RadarColumn),HL
  LD A,$01                ; the radar must be rebuilt (PutShipOnMap does it)
  LD (RadarDirty),A
  RET

; clear the ship's occupant bit in its map cell, toggle its radar dot
;
; Called by MoveShip first thing each game turn, before the ship moves: the
; cell under the ship (ShipCell: $DD00 + $200 * ShipY + ShipX) loses bit 7, the
; occupant bit robots test (FreeDirections) when the ship hangs lower than
; their top, and the ship's dot on the radar is toggled off when it is on
; (BlinkShipDot). PutShipOnMap undoes both after the move.
LiftShipFromMap:
  CALL ShipCell           ; HL = the ship's map cell
  RES 7,(HL)              ; the ship is no longer in this cell
  JR BlinkShipDot         ; and the dot goes (when the tick is odd)

; set the ship's occupant bit in its new map cell, rebuild the radar if the
; window moved, toggle the ship's dot
;
; Called at the end of MoveShip (and by BuildMap). Sets bit 7 of the ship's
; cell, then goes on into RefreshRadar. Recording: 3333 calls, once a game
; turn.
PutShipOnMap:
  CALL ShipCell           ; HL = the ship's map cell
  SET 7,(HL)              ; the ship occupies it

; rebuild the radar when RadarDirty is set, then blink the ship's dot
;
; RadarDirty ($FD52) is set when the window moved ($B017) and by other code
; that changes the map (the start, a loaded game). BuildRadar then redraws both
; radar layers $D800 / $D900 from the map (a pixel for every cell of type $0F
; or more, the high ground) and plots every live robot's dot; the flag is
; cleared. Falls into BlinkShipDot. Also reached from MenuRadarTick.
RefreshRadar:
  LD A,(RadarDirty)
  OR A
  JR Z,BlinkShipDot
  CALL BuildRadar         ; terrain bitmap of the 128-column window and all
                          ; robots' dots
  XOR A                   ; done until the window moves again
  LD (RadarDirty),A

; on odd ticks toggle the ship's 2x2 dot on the radar's player layer
;
; RadarBlink ($FD1E) counts the game turns (MoveShip increments it between
; LiftShipFromMap and PutShipOnMap, MenuRadarTick in the menus). When it is
; odd, ToggleRadarDot XORs a 2x2 dot at (ShipX, ShipY) into the layer B = 0
; ($D800, shown with attribute $4D by PlayInterrupt in alternate frames).
; Off-window positions draw nothing (RadarDotAddress). The pairs of toggles
; around each move leave the dot on every other turn: the ship's dot blinks.
BlinkShipDot:
  LD A,(RadarBlink)
  AND $01
  RET Z                   ; even tick: no change
  LD HL,(ShipX)
  LD A,(ShipY)
  LD C,A
  LD B,$00                ; B = 0: the player's layer $D800
  JP ToggleRadarDot       ; XOR the dot, return from there

; one blink step of the ship's dot while a menu is open
;
; Called by the robot menu loop (DirectControl) and ListMenu each pass, so the
; world goes on and the ship's dot keeps blinking while the player sits in a
; menu: toggles the dot (BlinkShipDot), advances RadarBlink, rebuilds the radar
; if needed and toggles again on the new tick (RefreshRadar). 83 calls in the
; deep recording.
MenuRadarTick:
  CALL BlinkShipDot
  LD HL,RadarBlink
  INC (HL)                ; the next tick
  JP RefreshRadar         ; rebuild if dirty, toggle on the new tick

; carry: the ship may not stand at HL (X), A (Y)
;
; Used by the routine at MoveShip.
CheckShipMove:
  PUSH HL                 ; keep X for MoveShip
  CALL MapCell            ; HL = the cell (X, Y)
  EX DE,HL
  LD C,$00                ; C = the highest top found so far
  CALL CellTop            ; the 2x2 footprint, terrain and objects: (X, Y)
  INC DE
  CALL CellTop            ; (X+1, Y)
  DEC D
  DEC D
  CALL CellTop            ; (X+1, Y-1)
  DEC DE
  CALL CellTop            ; (X, Y-1)
  DEC DE
  CALL ObjectTop          ; objects only, the anchors whose footprint overlaps
                          ; ours: (X-1, Y-1)
  INC D
  INC D
  CALL ObjectTop          ; (X-1, Y)
  INC D
  INC D
  LD A,D                  ; the row Y+1 only inside the map
  CP $FD
  JR NC,l_B084
  CALL ObjectTop          ; (X-1, Y+1), (X, Y+1), (X+1, Y+1)
  INC DE
  CALL ObjectTop
  INC DE
  CALL ObjectTop
l_B084:
  LD A,(Altitude)            ; carry when the ship is lower than the highest top:
                          ; C stays for MoveShip's sinking
  CP C
  POP HL
  RET

; C = max(C, the ground height of the terrain type at DE)
;
; DE a map cell. The cell's type (bits 0-4) indexes the ground height table
; TerrainHeights $D7BC (00 00 02 02 02 02 03 03 06 06 06 06 00 00 00 07 0F 07
; 0F ...: types 2-5 height 2, 6-7 (the wreck a destroyed robot leaves) 3, 8-$0B
; 6, $0F/$11 7, $10/$12 15). Keeps the higher of it and C (KeepHigher). Used by
; CheckShipMove (through CellTop) and GroundUnderFootprint; 39396 calls.
TerrainTop:
  LD A,(DE)
  AND $1F
  LD HL,TerrainHeights    ; TerrainHeights
  CALL AddAToHL
  LD A,(HL)
  JR KeepHigher           ; keep the higher one

; C = max(C, the ground and the object on cell DE)
;
; TerrainTop, then falls into ObjectTop: the highest point of a cell, used for
; the 2x2 footprint in CheckShipMove.
CellTop:
  CALL TerrainTop

; C = max(C, the top of a robot or a building anchored at cell DE)
;
; When the cell has bit 6 (an object anchored there): a robot (FindRobot)
; counts with its body height +$09 plus the ground under it +$0D; else a
; building (FindBuilding) with its height from BuildingTops by type. A cell
; with bit 6 that is neither (a shot) counts nothing. B and C are kept.
ObjectTop:
  LD H,D
  LD L,E
  BIT 6,(HL)              ; no object anchored here
  RET Z
  PUSH BC
  CALL FindRobot          ; a robot on this cell?
  JR NZ,ObjectTopBuilding
  POP BC
  LD A,(IY+$09)           ; its top: the body height plus the ground it stands
                          ; on
  ADD A,(IY+$0D)

; C = max(C, A)
;
; The common tail of TerrainTop and ObjectTop.
KeepHigher:
  CP C
  JR C,l_B0AF
  LD C,A
l_B0AF:
  RET
; This entry point is used by the routine at ObjectTop.
ObjectTopBuilding:
  CALL FindBuilding       ; not a robot: a building?
  POP BC
  RET NZ                  ; neither: a shot, nothing to count
  LD A,(IY+$02)           ; the building's type
  LD HL,BuildingTops
  CALL AddAToHL
  LD A,(HL)
  JR KeepHigher

; The heights of the building types 0-8 for the ship and the robots
;
; Read by ObjectTop with the type byte of the Buildings record: type 0 (the
; warbase pad) $0F, the factory types 1-6 $16, $15, $15, $16, $16, $16, types 7
; and 8 $19. The pad's 15 is the altitude the ship sinks to on it, where
; ConstructionMenu opens.
BuildingTops:
  DEFB $0F,$16,$15,$15,$16,$16,$16,$19,$19

; one game turn of the world: the enemy commander, every robot, every shot
;
; Called once a game turn by the play loop (PlayLoop) and by the menus
; (DirectControl, ListMenu), so robots fight and walk on while the player
; chooses: 3415 calls in 36046 frames, a turn is about 10 frames. First
; EnemyCommander (one enemy slot built or re-ordered), then UpdateRobot for
; each of the 48 robot records $DA00 whose +$01 is not 0, then UpdateShot for
; each of the 5 shot records of 9 bytes at $D7D3 whose +$01 is not 0. Robots
; and shots are taken in slot order, the player's slots 0-23 first. Shot record
; 0 ($D7D3) is the one the player fires from the robot menu's COMBAT MODE
; (DirectControl -> FireShot); the robots use records 1-4 (FindFreeShot).
WorldTurn:
  CALL EnemyCommander
  LD B,$30                ; the 48 robot records
  LD IY,Robots
WorldTurnRobotLoop:
  PUSH BC                 ; a live robot (+$01 = the high byte of its cell, 0 =
                          ; free)
  LD A,(IY+$01)
  OR A
  CALL NZ,UpdateRobot
  LD DE,$0010
  ADD IY,DE
  POP BC
  DJNZ WorldTurnRobotLoop
  LD IY,Shots             ; the 5 shot records
  LD B,$05
WorldTurnShotLoop:
  PUSH BC                 ; a live shot
  LD A,(IY+$01)
  OR A
  CALL NZ,UpdateShot
  LD DE,$0009
  ADD IY,DE
  POP BC
  DJNZ WorldTurnShotLoop
  RET

; one robot's game turn: dying, destroyed or a step of its AI
;
; IY = the robot record. Strength +$0C decides: positive, the robot acts
; (RobotStep); negative, the robot is dying: +$0C counts up from $FC (set by
; MoveShot's hit) and the object bit 6 of its cell is toggled each turn
; (cleared on even values, set on odd), so for four turns other robots and
; shots see it only every other turn; 0, the robot is destroyed
; (RobotDestroyed). 49165 calls.
UpdateRobot:
  LD A,(IY+$0C)
  OR A
  JR Z,RobotDestroyed     ; strength 0: destroyed
  JP P,RobotStep          ; strength positive: alive
  INC (IY+$0C)            ; dying: one turn closer to 0
  LD L,(IY+$00)
  LD H,(IY+$01)
  AND $01                 ; the old value's bit 0: the object bit flickers
  JR NZ,RobotDyingShow
  RES 6,(HL)
  RET
RobotDyingShow:
  SET 6,(HL)              ; odd: the object is there
  RET
RobotDestroyed:
  LD L,(IY+$00)           ; remove the robot: a wreck on bare ground, the dot,
                          ; the slot, the counts
  LD H,(IY+$01)
  RES 6,(HL)              ; no object on its cell any more
  LD A,(HL)               ; OR of the four footprint cells (X, Y), (X+1, Y),
                          ; (X+1, Y-1), (X, Y-1)
  INC HL
  OR (HL)
  DEC H
  DEC H
  OR (HL)
  DEC HL
  OR (HL)
  INC H
  INC H
  AND $3F                 ; bits 0-5: anything but bare type-0 ground?
  JR NZ,RobotRemove
  CALL Random             ; bare ground: a wreck, terrain type 6 or 7 at random
  AND $01
  ADD A,$06
  CALL PutBlock           ; PutBlock: a 2x2 terrain feature of type A at HL
                          ; (the anchor A, the other three cells A + $20)
RobotRemove:
  LD L,(IY+$02)           ; erase its radar dot: layer B = +$0A bit 7 (0 ours,
                          ; 1 the enemy's)
  LD H,(IY+$03)
  LD C,(IY+$04)
  LD A,(IY+$0A)
  RLCA
  AND $01
  LD B,A
  CALL ToggleRadarDot
  LD (IY+$01),$00         ; the slot is free
  CALL CountRobots        ; recount: OurRobots $FD41, EnemyRobots $FD49
  CALL UpdateStatusPanel  ; and the status panel
  RET

; a live robot: wait for its step delay, then look, fire, steer and move one
; step
;
; Entered from UpdateRobot with strength > 0 (JP P). A robot the player sits on
; (+$0A = 1, the robot menu is open) does nothing. Side ($FD51) = 0 ours / 1
; the enemy's (+$0A bit 7), read by the target searches. The step delay +$0F
; counts the turns down; at 0 the robot leaves its cell (bit 6 cleared, radar
; dot erased) and FreeDirections gives C, the directions it can step to (bit 0
; right, 1 left, 2 down, 3 up, the Input order).
;
; Direct control (+$0A = 2): the stick decides (RobotDirectControl). Otherwise
; SpotEnemies gives E, the directions with a live opponent in sight. An
; opponent ahead (E AND the facing +$08): the robot moves on if it can and
; fires when a shot record of its side is free and its weapons allow
; (FindFreeShot, FireShot; a shot stops it for this step). An opponent to a
; side: it turns to it (+$05 = that direction, one picked at random among
; several, +$06 = 2). No opponent: it keeps its direction +$05 for +$06 more
; steps while that direction stays free, else it takes a new course for 3-6
; steps from SteerByOrder (RobotNewCourse). RobotMove then turns or steps,
; reloads the delay (SetStepDelay) and puts the robot back on the map
; (PlaceRobot: the record's x/y/cell, bit 6, the dot).
;
; Recording: 9652 steps; the shot records and strengths at frames 18680-18850
; match FireShot and MoveShot (robot 2 hit twice by an enemy missile, 100 -> 70
; -> 40; robot 25 hit by our cannon, 100 -> 80 -> 60 -> 40).
RobotStep:
  LD A,(IY+$0A)
  CP $01                  ; the player sits on it: frozen while the robot menu
                          ; is open
  RET Z
  RLCA                    ; Side: 0 ours, 1 the enemy's
  AND $01
  LD (Side),A
  DEC (IY+$0F)            ; the step delay
  RET NZ
  LD L,(IY+$00)           ; time to step: off the map
  LD H,(IY+$01)
  RES 6,(HL)
  PUSH HL
  LD L,(IY+$02)           ; erase its radar dot
  LD H,(IY+$03)
  LD C,(IY+$04)
  LD A,(IY+$0A)
  RLCA
  AND $01
  LD B,A
  CALL ToggleRadarDot
  POP HL
  CALL FreeDirections     ; C = the free directions from this cell
  LD A,(IY+$0A)
  CP $02                  ; under direct control?
  JP Z,RobotDirectControl
  PUSH BC
  CALL SpotEnemies        ; E = the directions with an opponent in sight
  POP BC
  LD A,E
  OR A
  JR Z,RobotNoEnemy       ; nobody in sight
  AND (IY+$08)            ; an opponent straight ahead?
  JR Z,RobotTurnToEnemy
  AND C                   ; move on ahead if free (else stand)
  LD (IY+$05),A
  PUSH IX
  PUSH IY
  PUSH IY                 ; IX = the shooter, IY = the free shot record
  POP IX
  CALL FindFreeShot
  JR NZ,RobotNoShot       ; both of our side's shots are flying
  CALL Random             ; each weapon (bits 3 cannon, 4 missiles, 5 phasers)
                          ; fires this turn at even odds
  AND $38
  AND (IX+$07)
  JR Z,RobotNoShot        ; no weapon chosen this turn
  LD C,$06                ; the highest chosen weapon: phasers 3, missiles 2,
                          ; cannon 1
RobotWeaponPick:
  DEC C                   ; count the rotations until the weapon bit leaves
  RLCA
  JR NC,RobotWeaponPick
  LD A,C
  CALL FireShot           ; launch the shot
  POP IY
  POP IX
  LD (IY+$05),$00         ; the shot costs the step: stand, decide again next
                          ; step
  LD (IY+$06),$01
  JR RobotMove
RobotNoShot:
  POP IY                  ; no shot: walk on ahead
  POP IX
  LD (IY+$06),$01
  JR RobotMove
RobotTurnToEnemy:
  LD C,E                  ; opponents to a side: face one of them
  LD B,C
  CALL CountDirections    ; several: one at random
  CALL NZ,PickOneDirection
  LD (IY+$05),C
  LD (IY+$06),$02
  JP RobotMove
RobotNoEnemy:
  DEC (IY+$06)            ; nobody in sight: keep the course while it lasts and
                          ; is free
  JP M,RobotNewCourse
  LD A,(IY+$05)
  AND C
  JR NZ,RobotMove
RobotNewCourse:
  CALL Random             ; a new course for 3-6 steps
  AND $03
  ADD A,$03
  LD (IY+$06),A
  CALL CountDirections    ; at least one free direction: ask the order
  CALL NC,SteerByOrder
  LD A,(IY+$01)           ; the robot blew itself up (a nuclear charge,
                          ; NuclearBlast)
  OR A
  RET Z
  LD (IY+$05),C
; This entry point is used by the routine at FindNearestOpponent.
RobotMove:
  LD A,(IY+$05)           ; turn or step in +$05, the new delay, back on the
                          ; map
  LD L,(IY+$02)
  LD H,(IY+$03)
  LD B,(IY+$04)
  CALL TurnOrStep
  CALL SetStepDelay
  JP PlaceRobot           ; PlaceRobot: store x / y / the cell, set bit 6, plot
                          ; the dot

; C = the direction the robot's order wants, chosen among the free ones in C
;
; IY the robot, C the free directions (FreeDirections); out C a single
; direction bit, or 0 to stand. B keeps the free set. By the order +$0B:
;
; 0 stop: C = 0. 1 advance / 2 retreat: right / left (RobotLeanTo, a 3/4 chance
; to take that direction when free, else a random free one other than the
; opposite); RobotStepPos counts the distance +$0E.
;
; 3 destroy robots: the target is the opponent robot of index +$0E
; (TargetRobotRecord). It is kept while it lives and is less than 50 columns
; away; else the nearest live opponent by column distance is taken
; (FindNearestOpponent), none: a random free direction.
;
; 4-8 the building orders: the target is record +$0E of the factory table $FD84
; or the warbase table $FD70 (TargetBuildingTable). It is kept while its owner
; bits are still the ones the order looks for; else the nearest such building
; nobody of the side is already after is taken (FindTargetBuilding). None: the
; robot stands, and an enemy robot falls back to destroy robots.
;
; The aim (RobotAim): D = the directions toward the target, horizontal from the
; sign of the column difference, vertical from the row difference; for a
; building, while the columns differ, the row aimed at is 3 below the
; building's row. More than 7 columns away the robot leans horizontally like an
; advance (RobotLeanTo); closer, one of the free wanted directions at random, a
; horizontal one kept for |dx| - 1 steps (+$06). On the target (D = 0): the
; destroy orders 4-5 go to the nuclear charge at NuclearBlast (outside this
; range); the others turn the robot to face down and stand.
;
; Bug (experiment, breakpoint at $B2B8 after poking the target factory's
; owner): FindTargetBuilding leaves HL past the table, not on the new target,
; so the step right after a new building target aims at the bytes below $FDFF
; (the JP at $FDFD and Handler: row $66, column $C300): one step of a wrong
; course, corrected on the next decision.
SteerByOrder:
  LD B,C
  LD A,(IY+$0B)           ; the order
  OR A
  JR NZ,l_B22B
  LD C,A                  ; 0 stop: stand
  RET
l_B22B:
  CP $03                  ; 1-2: advance / retreat
  JP C,RobotLeanTo
  JR NZ,SteerBuildingOrder ; 4-8: the building orders
  LD A,(IY+$0E)           ; 3 destroy robots: a target already?
  OR A
  JP M,SteerNewRobotTarget
  CALL TargetRobotRecord  ; HL = the target robot's record
  INC HL
  LD A,(HL)               ; dead (its +$01 = 0)?
  OR A
  JR Z,SteerNewRobotTarget
  INC HL
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD E,(IY+$02)
  LD D,(IY+$03)
  CALL ColumnDistance     ; HL = |its column - ours|
  LD A,H
  OR A
  JR NZ,SteerNewRobotTarget
  LD A,L
  CP $32                  ; less than 50 columns: chase it
  JR C,SteerAtRobot
SteerNewRobotTarget:
  LD L,(IY+$02)           ; find the nearest live opponent
  LD H,(IY+$03)
  LD (IY+$0E),$FF
  PUSH BC
  CALL FindNearestOpponent
  POP BC
  LD (IY+$0E),D           ; +$0E = its index, $FF none
  JP Z,PickOneDirection   ; nobody: wander
SteerAtRobot:
  CALL TargetRobotRecord  ; DE = the target's column, B = our row - its row
  INC HL
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD A,(IY+$04)
  SUB (HL)
  LD B,A
  LD L,(IY+$02)
  LD H,(IY+$03)
  XOR A
  SBC HL,DE               ; HL = our column - its column
  LD D,A
  JR Z,RobotAimVertical
  JR RobotAim
SteerBuildingOrder:
  CALL TargetBuildingTable ; HL = the owner byte of the first record, E = the
                           ; owner the order wants
  LD A,(IY+$0E)           ; HL = the target record's owner byte (5 bytes a
                          ; record)
  LD B,A
  ADD A,A
  ADD A,A
  ADD A,B
  CALL AddAToHL
  LD A,(HL)
  AND $E0
  CP E                    ; still a building we want?
  JR Z,SteerAtBuilding
  LD A,(IY+$0B)           ; no: find another
  PUSH BC
  LD L,(IY+$02)
  LD H,(IY+$03)
  CALL FindTargetBuilding
  POP BC
  JR NZ,l_B2B8            ; found one
  LD C,$00                ; none left: stand
  BIT 7,(IY+$0A)          ; ours: stand and wait
  RET Z
  LD (IY+$0B),$03         ; the enemy's: hunt robots instead
  RET
l_B2B8:
  LD (IY+$0E),D           ; the new target (HL is not on it: the bug above)
SteerAtBuilding:
  DEC HL                  ; B = our row - the building's row, DE = its column
  LD A,(IY+$04)
  SUB (HL)
  LD B,A
  DEC HL
  LD D,(HL)
  DEC HL
  LD E,(HL)
  LD L,(IY+$02)
  LD H,(IY+$03)
  XOR A
  SBC HL,DE               ; HL = our column - its column
  LD D,A
  JR Z,RobotAimVertical
  LD A,B                  ; columns differ: aim at the row 3 below it
  SUB $03
  LD B,A
RobotAim:
  LD A,H                  ; horizontal: 2 left when we are right of it, 1 right
                          ; when left
  RRCA
  AND $03
  XOR $02
  LD D,A
RobotAimVertical:
  LD A,B                  ; vertical: 8 up when we are below it, 4 down when
                          ; above
  OR A
  JR Z,l_B2E8
  RRCA
  RRCA
  AND $0C
  XOR $08
  OR D
  LD D,A
l_B2E8:
  LD A,D                  ; D = the wanted directions
  OR A
  JR NZ,l_B306
  LD C,A                  ; on the target: stand
  LD A,(IY+$0B)
  CP $04
  JR C,l_B2F9
  CP $06                  ; destroy factories / warbases: the nuclear charge
  JP C,NuclearBlast
l_B2F9:
  LD A,(IY+$08)           ; already facing down: stand
  CP $04
  RET Z
  LD C,$04                ; else turn down and stay so
  LD (IY+$06),$FF
  RET
l_B306:
  LD A,L                  ; L = |the column difference| (low byte)
  OR A
  JP P,l_B30E
  NEG
  LD L,A
l_B30E:
  CP $08                  ; 8 or more columns: lean horizontally
  LD B,C
  LD A,D
  JR NC,RobotLeanTo
  AND C                   ; the wanted directions that are free
  JR Z,PickOneDirection   ; none: any free direction
  LD B,A
  AND $03                 ; only vertical ones: pick one
  JR Z,PickOneDirection
  LD A,L                  ; the columns agree: pick one
  OR A
  JR Z,PickOneDirection
  DEC A                   ; keep a horizontal course for |dx| - 1 steps
  LD (IY+$06),A
  JR PickOneDirection
RobotLeanTo:
  AND $03                 ; D = the horizontal part (1 right, 2 left), E = all
                          ; but the opposite one
  LD D,A
  XOR $FC
  LD E,A
  LD A,C
  AND D                   ; wanted direction blocked: any free one
  JR Z,PickOneDirection
  LD C,D                  ; C = the wanted direction
  CALL Random             ; taken with a 3/4 chance (two random bits)
  AND D
  RET NZ
  CALL Random
  AND D
  RET NZ
  LD A,B                  ; else: among the free ones but the opposite
  AND E
  LD B,A

; C = one direction bit picked at random from the set in B
;
; Masks C with random bytes until exactly one bit is left (CountDirections);
; when nothing is left it starts again from B. B must not be 0. The common exit
; of SteerByOrder's branches and used by RobotTurnToEnemy for several
; opponents.
PickOneDirection:
  LD C,B
PickOneLoop:
  CALL Random             ; C AND a random byte
  AND C
  LD C,A
  CALL CountDirections
  RET Z                   ; exactly one: done
  JR NC,PickOneLoop       ; still several: narrow on
  LD C,B                  ; none left: from the whole set again
  JR PickOneLoop

; D = the nearest building the order wants and no teammate is after; Z when
; none
;
; A = the order (3 goes to FindNearestOpponent), HL = the robot's column, IY
; the robot, Side set. The order picks the table and owner
; (TargetBuildingTable); every record with those owner bits is offered to
; ConsiderBuilding, which skips it when a robot of our side with the same order
; already has it as its +$0E, and keeps the nearest by column distance
; (KeepNearest). Out D = the record's index (or $FF), A = D + 1 (Z: none). HL
; is left past the table: the cause of the bug noted at SteerByOrder.
; Recording: 112 calls (also from the enemy's order choice at $B989 and
; SetOrder).
FindTargetBuilding:
  CP $03
  JP Z,FindNearestOpponent
  PUSH AF
  EX AF,AF'               ; A' = the order, for ConsiderBuilding
  POP AF
  CALL InitNearestSearch  ; the search: DE' = our column, BC' = the best
                          ; distance ($2000), C = the index, D = $FF
  CALL TargetBuildingTable ; HL = the first record's owner byte, B = the
                           ; records, E = the owner wanted
FindTargetLoop:
  LD A,(HL)               ; owner bits 5-7 the ones wanted?
  AND $E0
  CP E
  CALL Z,ConsiderBuilding
  LD A,L                  ; next record (L only: the tables sit inside page
                          ; $FD)
  ADD A,$05
  LD L,A
  INC C
  DJNZ FindTargetLoop
  LD A,D                  ; A = the index + 1: Z when none was found
  INC A
  RET

; offer building C to KeepNearest unless a teammate with the same order already
; targets it
;
; HL = the record's owner byte (+$03), C its index, A' the order. Scans the 24
; records of our side ($DA00 ours, $DB80 the enemy's by Side) for a live robot
; whose order +$0B is A' and whose target +$0E is C. None: the record's column
; (+$00/+$01) goes to KeepNearest. The robot that asks is in the list too; its
; +$0E holds its old target (or $FF).
ConsiderBuilding:
  PUSH IY
  PUSH BC
  PUSH DE
  EX AF,AF'
  LD E,A                  ; E = the order
  EX AF,AF'
  LD IY,Robots            ; our side's robots
  LD A,(Side)
  OR A
  JR Z,l_B381
  LD IY,EnemyRobots
l_B381:
  LD B,$18
ConsiderBuildingLoop:
  LD A,(IY+$01)           ; a live robot ...
  OR A
  JR Z,l_B395
  LD A,(IY+$0B)           ; ... with the same order ...
  CP E
  JR NZ,l_B395
  LD A,(IY+$0E)           ; ... after the same building?
  CP C
  JR Z,ConsiderBuildingTaken
l_B395:
  PUSH DE
  LD DE,$0010
  ADD IY,DE
  POP DE
  DJNZ ConsiderBuildingLoop
  POP DE
  POP BC
  POP IY
  PUSH HL                 ; nobody: HL = the building's column
  DEC HL
  DEC HL
  LD A,(HL)
  DEC HL
  LD L,(HL)
  LD H,A
  CALL KeepNearest
  POP HL
  RET
ConsiderBuildingTaken:
  POP DE                  ; taken: skip it
  POP BC
  POP IY
  RET

; keep candidate C when the column HL is nearer to DE' than the best BC'
;
; The comparison step of the nearest searches (InitNearestSearch sets it up):
; HL' = |HL - DE'|, and when it is below BC' it becomes the best and D = C.
; Only the column distance counts; rows are ignored.
KeepNearest:
  PUSH HL
  EXX
  POP HL
  CALL ColumnDistance     ; the distance
  LD A,H
  CP B
  JR C,l_B3C3
  JR NZ,l_B3C8
  LD A,L
  CP C
  JR NC,l_B3C8
l_B3C3:
  LD B,H                  ; nearer: the new best, D = its index
  LD C,L
  EXX
  LD D,C
  RET
l_B3C8:
  EXX
  RET

; HL = |HL - DE|
;
; A 16-bit absolute difference (the sign of the 16-bit result decides); A = 0
; on the negative path.
ColumnDistance:
  XOR A
  SBC HL,DE
  RET P
  SUB L                   ; negative: 0 - HL
  LD L,A
  LD A,$00
  SBC A,H
  LD H,A
  RET

; HL, B, E = the building table, its size and the owner a building order wants
;
; A = the order. Orders 5 and 8 (destroy / capture warbases): HL = $FD73, the
; owner byte of the first of the 4 warbase records (Warbases $FD70, 5 bytes
; each), B = 4; the others: HL = $FD87, the owner byte of the first of 24
; factory records (Factories $FD84), B = 24. E = the owner bits sought: $20
; (the computer's) for our robots, $40 (ours) for the enemy's (Side = 1), 0
; (neutral) for order 6, capture neutral factories.
TargetBuildingTable:
  LD HL,Factories+3
  LD B,$18
  CP $05
  JR Z,l_B3E2
  CP $08
  JR NZ,l_B3E7
l_B3E2:
  LD HL,Warbases+3             ; warbases
  LD B,$04
l_B3E7:
  LD E,$20                ; the opponent's mark: $20 for us ...
  PUSH AF
  LD A,(Side)
  OR A
  JR Z,l_B3F2
  RLC E                   ; ... $40 for the enemy
l_B3F2:
  POP AF
  CP $06
  RET NZ
  LD E,$00                ; capture neutral: owner bits 0
  RET

; HL = the opponent robot record of index +$0E
;
; HL = $DB80 + 16 * (+$0E) for our robots, $DA00 + 16 * (+$0E) for the enemy's
; (Side). Used by SteerByOrder's destroy-robots branch.
TargetRobotRecord:
  LD DE,Robots
  LD A,(Side)            ; the enemy's robots for us, ours for the enemy
  OR A
  JR NZ,l_B405
  LD DE,EnemyRobots
l_B405:
  LD A,(IY+$0E)
  ADD A,A
  ADD A,A
  ADD A,A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,DE
  RET

; start a nearest-by-column search from column HL
;
; DE' = HL (our column), BC' = $2000 (no candidate yet), C = 0 (the first
; index), D = $FF (the result: none). Used by FindTargetBuilding and
; FindNearestOpponent with KeepNearest.
InitNearestSearch:
  PUSH HL
  EXX
  POP DE
  LD BC,$2000
  EXX
  LD C,$00
  LD D,$FF
  RET

; D = the index of the nearest live opponent robot by column; Z when none
;
; HL = our column, IY the robot, Side set. Runs KeepNearest over the 24
; opponent records ($DB80 the enemy's for us, $DA00 ours for the enemy) whose
; +$01 is not 0 (a dying robot counts). Out D = the slot within the side (or
; $FF), A = D + 1 (Z: none). 426 calls.
;
; Reached from RobotStep for +$0A = 2 (not run in the deep recording;
; experiment below).
FindNearestOpponent:
  CALL InitNearestSearch
  PUSH IY
  LD IY,Robots            ; the opponent's records
  LD A,(Side)
  OR A
  JR NZ,l_B430
  LD IY,EnemyRobots
l_B430:
  LD B,$18
FindOpponentLoop:
  LD A,(IY+$01)           ; a live record: compare its column
  OR A
  JR Z,l_B441
  LD L,(IY+$02)
  LD H,(IY+$03)
  CALL KeepNearest
l_B441:
  PUSH DE
  LD DE,$0010
  ADD IY,DE
  POP DE
  INC C
  DJNZ FindOpponentLoop
  POP IY
  LD A,D                  ; A = the index + 1: Z when none
  INC A
  RET
; This entry point is used by the routine at RobotStep.
RobotDirectControl:
  PUSH BC                 ; direct control: the stick steers the robot
  CALL WaitKey            ; Input, with the pause on key 1
  POP BC
  LD B,C                  ; B = the free directions
  CP (IY+$08)             ; pushing the way it faces: go only if free (a turn
                          ; needs no free cell)
  JR NZ,l_B45C
  AND C
l_B45C:
  LD C,A
  CALL CountDirections    ; exactly one direction?
  JR Z,l_B467
  LD A,(IY+$05)           ; none or several: go on the way it went, if still
                          ; free
  AND B
  LD C,A
l_B467:
  LD (IY+$05),C
  LD A,C
  LD (Input),A            ; Input = the step, so MoveShip carries the ship
                          ; along (TurnOrStep)
  JP RobotMove

; turn the robot toward direction A, or step one cell when it faces it
;
; IY the robot, HL its column, B its row, A a direction bit (0: nothing).
; Facing +$08 not A: the robot turns, never by 180 degrees in one go (right <->
; left goes through down / up, down <-> up through right / left), and +$06 is
; incremented so the turn does not shorten the course. Facing A: StepPosition
; moves HL/B, GroundUnderFootprint sets +$0D, and under direct control (+$0A =
; 2) MoveShip moves the ship by the same Input and the ship sits on the robot's
; top (Altitude = +$09 + +$0D).
;
; Experiment (DIRECT CONTROL on a new bipod + cannon robot at (22,14)): holding
; right the robot turned from facing down (4) to right (1) in one step and
; moved one column a step (6 turns, about 60 frames); after the release it went
; on one more step in the same direction; the ship moved with it and Altitude
; stayed 17 (bipod 11 + cannon 6, ground 0).
TurnOrStep:
  OR A
  RET Z
  CP (IY+$08)             ; already facing it: step
  JR Z,TurnOrStepStep
  LD C,A                  ; C = the new facing
  OR (IY+$08)
  CP $03                  ; right <-> left: turn down / up first
  JR NZ,l_B486
  RLC C
  RLC C
  JR l_B48E
l_B486:
  CP $0C                  ; down <-> up: turn right / left first
  JR NZ,l_B48E
  RRC C
  RRC C
l_B48E:
  LD (IY+$08),C           ; face it; the turn does not count as a course step
  INC (IY+$06)
  RET
TurnOrStepStep:
  CALL StepPosition       ; step: the new column / row in HL / B
  CALL GroundUnderFootprint ; the highest ground under the new footprint
  LD (IY+$0D),A
  LD A,(IY+$0A)           ; direct control?
  CP $02
  RET NZ
  PUSH BC
  PUSH HL
  PUSH IY
  CALL Z,MoveShip         ; the ship moves by the same Input
  POP IY
  POP HL
  POP BC
  LD A,(IY+$09)           ; and sits on the robot's top
  ADD A,(IY+$0D)
  LD (Altitude),A
  RET

; move HL (column) / B (row) one cell in direction A; advance / retreat count
; their distance
;
; A bit 0 right (HL+1), 1 left (HL-1), 2 down (B+1), 3 up (B-1). For the orders
; 1 advance and 2 retreat (not under direct control) +$0E is the distance still
; to go: a column in the order's direction (right for advance, left for
; retreat) takes one off and at 0 the order becomes 0 stop (+$06 = 0); a column
; the other way adds one, up to $63.
;
; Experiment: ADVANCE with 5 MILES (the robot menu stores miles * 2 into +$0E =
; 10): the robot went 4 columns right (+$0E 10 -> 6), 5 rows up round an
; obstacle (+$0E unchanged), 6 more columns right and then stood with order 0
; and +$0E = 0.
StepPosition:
  RRCA
  JR NC,l_B4C7
  INC HL
  LD A,(IY+$0B)
  DEC A
  JR Z,OrderDistanceDown
  DEC A
  JR Z,OrderDistanceUp
  RET
l_B4C7:
  RRCA                    ; not right
  JR NC,l_B4D5
  DEC HL
  LD A,(IY+$0B)
  DEC A
  JR Z,OrderDistanceUp
  DEC A
  JR Z,OrderDistanceDown
  RET
l_B4D5:
  RRCA                    ; not left: down?
  JR NC,l_B4DA
  INC B
  RET
l_B4DA:
  RRCA                    ; up?
  RET NC
  DEC B
  RET
OrderDistanceUp:
  LD A,(IY+$0A)           ; a column away from the order's aim: one more to go
                          ; (max 99)
  CP $02
  RET Z
  INC (IY+$0E)
  LD A,(IY+$0E)
  CP $64
  RET C
  LD (IY+$0E),$63
  RET
OrderDistanceDown:
  LD A,(IY+$0A)           ; a column toward it: one less; there: stop
  CP $02
  RET Z
  DEC (IY+$0E)
  RET NZ
  LD (IY+$0B),$00         ; arrived: the order becomes stop
  LD (IY+$06),$00
  RET

; flags of (the number of set bits in C's low nibble) - 1
;
; Z: exactly one direction; carry: none; neither: two or more. Counts bits 0-3
; of C, keeps BC.
CountDirections:
  PUSH BC
  LD B,$04
  XOR A
CountDirectionsLoop:
  RR C                    ; add each bit
  ADC A,$00
  DJNZ CountDirectionsLoop
  POP BC
  CP $01
  RET

; C = the directions the robot at cell HL may step to
;
; IY the robot, HL its anchor cell. A robot covers 2x2 cells: its anchor (X, Y)
; carries the object bit 6, plus (X+1, Y), (X, Y-1), (X+1, Y-1). D = the first
; terrain type it cannot enter, by its locomotion: bipod 8 (types 0-7, ground
; heights 0-3), tracks $0C (also 8-$0B, height 6), anti-grav $0F (also $0C-$0E,
; height 0 in TerrainHeights); the types from $0F (heights 7 and 15) stop all.
; E = the bits that block: 6 (objects) always, 7 (the ship's cell) when the
; ship hangs lower than the robot's top. One probe a direction (CanMoveRight,
; CanMoveLeft, CanMoveDown, CanMoveUp); bit 0 right, 1 left, 2 down, 3 up. 9652
; calls.
FreeDirections:
  LD C,$00
  LD A,(Altitude)            ; the ship lower than our top?
  SUB (IY+$09)
  SUB (IY+$0D)
  AND $80                 ; then bit 7 (the ship's cell) blocks too
  OR $40                  ; objects always block
  LD E,A
  LD A,(IY+$07)
  LD D,$08                ; bipod: types below 8
  RRCA
  JR C,l_B532
  LD D,$0C                ; tracks: types below $0C
  RRCA
  JR C,l_B532
  LD D,$0F                ; anti-grav: types below $0F
l_B532:
  PUSH HL                 ; right free?
  CALL CanMoveRight
  POP HL
  JR NZ,l_B53B
  SET 0,C
l_B53B:
  PUSH HL                 ; left free?
  CALL CanMoveLeft
  POP HL
  JR NZ,l_B544
  SET 1,C
l_B544:
  PUSH HL                 ; down free?
  CALL CanMoveDown
  POP HL
  JR NZ,l_B54D
  SET 2,C
l_B54D:
  PUSH HL                 ; up free?
  CALL CanMoveUp
  POP HL
  JR NZ,l_B556
  SET 3,C
l_B556:
  RET

; Z when the robot at HL can step right
;
; Terrain and objects at the column it enters, (X+2, Y-1) and (X+2, Y); an
; object anchored at (X+2, Y+1) (its footprint would overlap) when that row
; exists.
CanMoveRight:
  INC HL
  INC HL
  DEC H
  DEC H
  CALL TestCell
  RET NZ
  INC H
  INC H
  CALL TestCell
  RET NZ
  INC H
  INC H
  LD A,H                  ; the row below only inside the map
  CP $FD
  JR NC,CellOffMapFree
  LD A,(HL)
  AND E
  RET

; Z when the robot at HL can step left
;
; Terrain and objects at (X-1, Y-1) and (X-1, Y); objects anchored at (X-2,
; Y-1), (X-2, Y) and (X-2, Y+1).
CanMoveLeft:
  DEC H
  DEC H
  DEC HL
  CALL TestCell
  RET NZ
  DEC HL
  LD A,(HL)
  AND E
  RET NZ
  INC H
  INC H
  LD A,(HL)
  AND E
  RET NZ
  INC HL
  CALL TestCell
  RET NZ
  DEC HL
  INC H
  INC H
  LD A,H                  ; the row below only inside the map
  CP $FD
  JR NC,CellOffMapFree
  LD A,(HL)
  AND E
  RET

; Z when the robot at HL can step down
;
; Blocked at the bottom row; terrain and objects at (X, Y+1) and (X+1, Y+1);
; objects anchored at (X+1, Y+2), (X, Y+2) and (X-1, Y+2) when that row exists.
CanMoveDown:
  INC H
  INC H
  LD A,H                  ; the bottom row: blocked
  CP $FD
  JR NC,CellBlocked
  CALL TestCell
  RET NZ
  INC HL
  CALL TestCell
  RET NZ
  INC H
  INC H
  LD A,H                  ; the row below only inside the map
  CP $FD
  JR NC,CellOffMapFree
  LD A,(HL)
  AND E
  RET NZ
  DEC HL
  LD A,(HL)
  AND E
  RET NZ
  DEC HL
  LD A,(HL)
  AND E
  RET

; Z when the robot at HL can step up
;
; Blocked when Y-2 is above the map (the footprint already covers Y-1); an
; object anchored at (X-1, Y-2), terrain and objects at (X, Y-2) and (X+1,
; Y-2).
CanMoveUp:
  DEC H
  DEC H
  DEC H
  DEC H
  LD A,H                  ; Y-2 off the map: blocked
  CP $DD
  JR C,CellBlocked
  DEC HL
  LD A,(HL)
  AND E
  RET NZ
  INC HL
  CALL TestCell
  RET NZ
  INC HL
  CALL TestCell
  RET

; Z: a probe that runs past the bottom row finds the way free
;
; The shared exit of the probes for rows below the map.
CellOffMapFree:
  XOR A
  RET

; NZ: the way is blocked
;
; The shared exit for an unpassable terrain type or a map edge.
CellBlocked:
  OR $01
  RET

; Z when cell HL is passable: type below D and none of the bits E
;
; 67380 calls.
TestCell:
  LD A,(HL)
  AND $1F
  CP D
  JR NC,CellBlocked
  LD A,(HL)               ; an object (or the low ship) in it?
  AND E
  RET

; A = the highest ground under the 2x2 footprint anchored at (HL, B)
;
; HL a column, B a row. TerrainTop over (X, Y), (X+1, Y), (X+1, Y-1), (X, Y-1);
; HL and BC are kept. The robots' +$0D (the ground they stand on, added to
; their height for the ship) and the shots' wall test (MoveShot).
GroundUnderFootprint:
  PUSH HL
  PUSH BC
  LD A,B
  CALL MapCell
  EX DE,HL
  LD C,$00
  CALL TerrainTop
  INC DE
  CALL TerrainTop
  DEC D
  DEC D
  CALL TerrainTop
  DEC DE
  CALL TerrainTop
  LD A,C
  POP BC
  POP HL
  RET

; +$0F = the turns until the robot's next step, by the ground and its
; locomotion
;
; The ground class from +$0D: 0 flat, 1-3 low, 4 and more high; the column from
; the lowest set part bit of +$07: 0 bipod, 1 tracks, 2 anti-grav. StepDelays
; gives the turns. The recorded records agree (robot 0, a bipod on flat ground,
; counts 6 down).
SetStepDelay:
  PUSH BC
  PUSH HL
  LD A,(IY+$0D)
  LD C,$00
  OR A
  JR Z,l_B605
  LD C,$03                ; low ground
  CP $04
  JR C,l_B605
  LD C,$06                ; high ground
l_B605:
  LD A,(IY+$07)
  LD D,$FF
SetStepDelayPart:
  INC D                   ; D = the locomotion: the index of the first set part
                          ; bit
  RRCA
  JR NC,SetStepDelayPart
  LD A,C
  ADD A,D
  LD HL,StepDelays
  CALL AddAToHL
  LD A,(HL)
  LD (IY+$0F),A
  POP HL
  POP BC
  RET

; Game turns a robot step takes: rows flat, low, high ground; columns bipod,
; tracks, anti-grav
;
; 6 4 3 / 8 6 3 / 9 7 4. Read by SetStepDelay; a game turn is about 10 frames,
; so a bipod on flat ground steps every 60 frames.
StepDelays:
  DEFB $06,$04,$03
  DEFB $08,$06,$03
  DEFB $09,$07,$04

; E = the directions in which a live opponent robot is in sight
;
; IY the robot. For each direction (up, down, left, right: E's bits 3, 2, 1, 0
; as in Input) ScanLane looks from the robot's anchor up to 8 cells; in the
; facing direction +$08 the range is 10, 12 with electronics (+$07 bit 7), and
; three parallel lanes are scanned (the columns X-1, X, X+1 for up / down, the
; rows Y-1, Y, Y+1 for left / right). 9652 calls.
SpotEnemies:
  LD E,$00
  LD D,$08                ; D = the direction scanned: up first
SpotEnemiesLoop:
  RLC E                   ; the next result bit
  LD L,(IY+$00)
  LD H,(IY+$01)
  LD B,$08                ; the range: 8 cells
  LD A,D
  CP (IY+$08)             ; the facing direction ...
  JR NZ,SpotEnemiesLane
  LD B,$0A                ; ... sees 10 cells ...
  BIT 7,(IY+$07)
  JR Z,l_B644
  LD B,$0C                ; ... 12 with electronics ...
l_B644:
  LD A,D                  ; ... in three lanes
  AND $03
  JR NZ,SpotEnemiesRows
  LD C,B                  ; up / down: the columns X-1, X, X+1
  DEC HL
  CALL ScanLane
  LD B,C
  INC HL
  CALL ScanLane
  LD B,C
  INC HL
  JR SpotEnemiesLane
SpotEnemiesRows:
  LD C,B                  ; left / right: the rows Y-1, Y, Y+1
  DEC H
  DEC H
  CALL ScanLane
  LD B,C
  INC H
  INC H
  CALL ScanLane
  LD B,C
  INC H
  INC H
SpotEnemiesLane:
  CALL ScanLane           ; the (last) lane
  RRC D                   ; the next direction: down, left, right
  JR NC,SpotEnemiesLoop
  RET

; set E bit 0 when a live opponent's anchor lies within B cells from HL in
; direction D
;
; The step comes from LaneSteps by D's bit. The scan stops at the map's top or
; bottom edge and at the first cell with an object (bit 6): only a robot of the
; other side (+$0A bit 7 differs) with strength above 0 sets the bit.
; Buildings, shots and friends block the view. HL, DE are kept apart from E's
; bit 0.
ScanLane:
  PUSH HL
  PUSH DE
  PUSH HL
  LD HL,ScanLaneDone+$0001 ; LaneSteps - 2
  LD A,D
ScanLaneStep:
  INC HL                  ; the step word for D's bit
  INC HL
  RRCA
  JR NC,ScanLaneStep
  LD E,(HL)
  INC HL
  LD D,(HL)
  POP HL
ScanLaneLoop:
  ADD HL,DE               ; one cell on
  LD A,H                  ; off the map's rows: stop
  SUB $DD
  CP $20
  JR NC,ScanLaneDone
  BIT 6,(HL)              ; the first object stops the view
  JR NZ,ScanLaneObject
  DJNZ ScanLaneLoop
  JR ScanLaneDone
ScanLaneObject:
  PUSH IY                 ; a robot?
  CALL FindRobot
  LD A,(IY+$0A)
  LD B,(IY+$0C)
  POP IY
  JR NZ,ScanLaneDone
  XOR (IY+$0A)            ; same side: no
  JP P,ScanLaneDone
  DEC B                   ; dead or dying: no
  JP M,ScanLaneDone
  POP DE                  ; an opponent in sight
  LD A,E
  OR $01
  LD E,A
  PUSH DE
ScanLaneDone:
  POP DE                  ; back with E
  POP HL
  RET

; The map steps of the four directions: right +1, left -1, down +$200, up -$200
;
; Read by ScanLane (from LD HL,$B6AE and two INC HL a bit of D), in the Input
; bit order.
LaneSteps:
  DEFW $0001,$FFFF,$0200,$FE00

; IY = a free shot record of the shooter IX's side; Z when one is free
;
; Each side has two shot records of 9 bytes: ours $D7DC and $D7E5, the enemy's
; $D7EE and $D7F7 (by IX +$0A bit 7). Z with IY on the first one whose +$01 is
; 0; NZ when both fly. Record 0 ($D7D3) is not handed out here: it is the
; player's COMBAT MODE shot, launched from the robot menu (DirectControl, not
; in the recording).
FindFreeShot:
  LD IY,Shots+$0009
  BIT 7,(IX+$0A)
  JR Z,l_B6C7
  LD DE,$0012             ; the enemy's records
  ADD IY,DE
l_B6C7:
  LD A,(IY+$01)
  OR A
  RET Z
  LD DE,$0009             ; the second record
  ADD IY,DE
  LD A,(IY+$01)
  OR A
  RET

; launch shot IY of weapon A from robot IX in its facing direction
;
; Called by RobotStep and by COMBAT MODE in the robot menu (DirectControl, IX =
; IY = the robot, record 0). Shot record (9 bytes): +$00/+$01 the map cell,
; +$02/+$03 the column, +$04 the row, +$05 the direction, +$06 the steps left,
; +$07 the weapon (1 cannon, 2 missiles, 3 phasers), +$08 the ground height
; that stops it ($0A). The range is 5 steps (7 for missiles), one more with
; electronics; each step goes 2 cells. The first step is taken at once
; (MoveShot); when the shot survives it, SoundFx ($FD53) = 1, the firing sound.
; Recording: an enemy missile at frame 18680, D7EE: 7B F3 7B 00 0B 08 06 02 0A
; (column $7B, row 11, up, 6 steps left after the first turn, missiles).
FireShot:
  LD (IY+$07),A
  LD C,$05
  CP $02                  ; missiles fly further
  JR NZ,l_B6E1
  LD C,$07
l_B6E1:
  BIT 7,(IX+$07)          ; electronics: one step more
  JR Z,l_B6E8
  INC C
l_B6E8:
  LD (IY+$06),C
  LD A,(IX+$08)           ; the robot's facing
  LD (IY+$05),A
  LD (IY+$08),$0A         ; ground of height 10 or more stops it
                          ; (TerrainHeights 15)
  LD L,(IX+$02)
  LD H,(IX+$03)
  LD B,(IX+$04)
  CALL MoveShot           ; the first step
  LD A,(IY+$01)
  OR A
  JR Z,l_B70C
  LD A,$01                ; it flies: the firing sound
  LD (SoundFx),A
l_B70C:
  RET

; one game turn of shot IY: off its cell, count its range, a step
;
; Clears the object bit of the shot's cell, counts +$06 down (0: the shot is
; gone, ShotGone) and goes on into MoveShot from its column / row. 90 calls in
; the deep recording.
UpdateShot:
  LD L,(IY+$00)
  LD H,(IY+$01)
  RES 6,(HL)              ; the shot leaves its cell
  DEC (IY+$06)            ; out of range: gone
  JP Z,ShotGone
  LD L,(IY+$02)
  LD H,(IY+$03)
  LD B,(IY+$04)

; move shot IY 2 cells, then hit a wall, an object or fly on
;
; HL the column, B the row. Off the rows 0-15, or ground of height +$08 ($0A)
; or more under its 2x2 footprint (only the types $10 / $12, height 15; heights
; up to 7 let it pass): gone. Then the 3x3 cells around the new cell are tested
; for an object (bit 6); none: the shot marks its own cell with bit 6 and flies
; on. An object that is a live robot (either side: friendly fire is possible)
; takes damage ((60 - its top) / 4) * (weapon + 1), the top being +$09 + +$0D,
; so tall robots on high ground take less: strength 0 or below makes it $FC
; (dying, UpdateRobot) with SoundFx $C8, else SoundFx $FA. Any other object (a
; building, another shot, a dying robot) just ends the shot (SoundFx $FC). The
; recorded hits agree: a missile (2) into a 19 high robot takes 10 * 3 = 30, a
; cannon shell 10 * 2 = 20.
MoveShot:
  LD A,(IY+$05)
  RRCA                    ; right: 2 columns
  JR NC,l_B72E
  INC HL
  INC HL
  JR MoveShotStore
l_B72E:
  RRCA                    ; left
  JR NC,l_B735
  DEC HL
  DEC HL
  JR MoveShotStore
l_B735:
  RRCA                    ; down: 2 rows
  JR NC,l_B73C
  INC B
  INC B
  JR l_B741
l_B73C:
  RRCA                    ; up
  JR NC,MoveShotStore
  DEC B
  DEC B
l_B741:
  LD A,B                  ; off the map's rows: gone
  CP $10
  JP NC,ShotGone
MoveShotStore:
  LD (IY+$02),L           ; the new position
  LD (IY+$03),H
  LD (IY+$04),B
  CALL GroundUnderFootprint ; the ground under it
  CP (IY+$08)             ; too high: it hits the wall
  JP NC,ShotGone
  LD A,B
  CALL MapCell            ; the new cell
  LD (IY+$00),L
  LD (IY+$01),H
  PUSH HL                 ; the row above: Y-1, columns X-1 to X+1 (when inside
                          ; the map)
  DEC HL
  DEC H
  DEC H
  LD A,H
  CP $DD
  JR C,MoveShotRow
  BIT 6,(HL)
  JR NZ,MoveShotHit
  INC HL
  BIT 6,(HL)
  JR NZ,MoveShotHit
  INC HL
  BIT 6,(HL)
  JR NZ,MoveShotHit
  DEC HL
  DEC HL
MoveShotRow:
  INC H                   ; the shot's row
  INC H
  BIT 6,(HL)
  JR NZ,MoveShotHit
  INC HL
  BIT 6,(HL)
  JR NZ,MoveShotHit
  INC HL
  BIT 6,(HL)
  JR NZ,MoveShotHit
  DEC HL
  DEC HL
  INC H                   ; the row below (when inside the map)
  INC H
  LD A,H
  CP $FD
  JR NC,MoveShotFlies
  BIT 6,(HL)
  JR NZ,MoveShotHit
  INC HL
  BIT 6,(HL)
  JR NZ,MoveShotHit
  INC HL
  BIT 6,(HL)
  JR NZ,MoveShotHit
MoveShotFlies:
  POP HL                  ; nothing near: the shot occupies its cell
  SET 6,(HL)
  RET
MoveShotHit:
  PUSH IY                 ; hit: E = the weapon, C = the sound for a miss
  LD E,(IY+$07)
  LD C,$FC
  CALL FindRobot          ; a robot anchored at the cell hit?
  JR NZ,MoveShotGone
  LD A,(IY+$0C)           ; alive?
  DEC A
  JP M,MoveShotGone
  LD A,$3C                ; (60 - its top) / 4 ...
  SUB (IY+$09)
  SUB (IY+$0D)
  SRL A
  SRL A
  LD D,A
  LD B,E                  ; ... times the weapon + 1
MoveShotDamage:
  ADD A,D                 ; one more multiple
  DJNZ MoveShotDamage
  LD B,A
  LD C,$FA                ; the hit sound
  LD A,(IY+$0C)
  SUB B                   ; the strength left
  JR Z,l_B7D7
  JP P,l_B7DB
l_B7D7:
  LD A,$FC                ; destroyed: dying for 4 turns, the explosion sound
  LD C,$C8
l_B7DB:
  LD (IY+$0C),A
MoveShotGone:
  POP IY                  ; the shot is gone
  POP HL
  LD (IY+$01),$00
  LD A,C
  LD (SoundFx),A
  RET

; ShotGone
;
; Used by the routines at UpdateShot and MoveShot.
ShotGone:
  LD (IY+$01),$00         ; out of range or off the map: the shot is gone with
                          ; the short sound
  LD A,$FC
  LD (SoundFx),A
  RET

; once a game turn the computer looks at one of its 24 robot slots: builds a
; robot in a free one or re-thinks a robot's order
;
; Called first by WorldTurn. A random number 0-31 picks the slot; 24-31 (a
; quarter of the turns) do nothing. Side = 1. The slot's record is $DB80 + 16 *
; n. A live robot goes to EnemyReplan (outside this range): one with order 0 at
; once, any other with a 1/32 chance a turn, gets a new order (a nuclear robot
; destroy factories or warbases, the others one of the capture orders; destroy
; robots when the order finds no target). A free slot tries a build at a random
; enemy warbase (owner $20 in the Warbases table): random parts (exactly one
; locomotion, at least one and not all four of the weapon / nuclear parts, at
; least 1, 2 or 3 of those parts while the computer has 0-7, 8-15 or 16-23
; robots, EnemyRobots $FD49), paid from EnemyResources ($FD4A, through
; MenuResources and PartCosts like the player's), the shortfall of the other
; resources taken from the general one, at most half of it (at least 11); the
; robot is set up facing down, order stop, strength $64, +$0A = $80, height
; +$09 the sum of the part heights $D7B4 (bipod 11, tracks 7, anti-grav 8,
; cannon 6, missiles 6, phasers 7, nuclear 7, electronics 7). 3415 calls.
EnemyCommander:
  CALL Random             ; a random slot ...
  AND $1F
  CP $18                  ; ... of the computer's 24, or none this turn
  RET NC
  ADD A,A                 ; * 16: the record's offset from $DB80
  ADD A,A
  ADD A,A
  LD L,A
  LD H,$00                ; HL = slot * 16 (A = slot * 8)
  ADD HL,HL
  LD DE,EnemyRobots       ; the enemy's records begin at slot 24, $DB80
  ADD HL,DE
  PUSH HL
  POP IY
  LD A,$01                ; ActingSide = 1: the target searches ($B3D5, $B36C)
                          ; look from the enemy's side
  LD (Side),A
  LD A,(IY+$01)           ; a live robot in the slot: re-plan its order instead
  OR A
  JP NZ,EnemyReplan
  LD B,$04                ; a free slot: try to build a robot, four tries over
                          ; the four warbases
  LD HL,Warbases+3             ; the owner byte (+3) of warbase 0 in the bases table
                          ; $FD70
SpawnPickBase:
  CALL Random             ; each warbase in turn is taken with chance 1/2
  AND $01
  JR Z,SpawnNextBase
  LD A,(HL)               ; and only if its +3 is $20 exactly: the enemy's, not
                          ; destroyed
  CP $20
  JR Z,SpawnAtBase
SpawnNextBase:
  LD A,$05                ; the next 5-byte base record
  CALL AddAToHL
  DJNZ SpawnPickBase
  RET                     ; no warbase taken: no robot this turn
SpawnAtBase:
  DEC HL                  ; B = the warbase's y, HL = its x: the door cell the
                          ; robot appears on
  LD B,(HL)
  DEC HL
  LD A,(HL)
  DEC HL
  LD L,(HL)
  LD H,A
  LD A,B
  PUSH HL                 ; x to HL' and y to B' for the placing at $B8D9
  EXX
  POP HL
  LD B,A
  EXX
  CALL MapCell            ; HL = the door's map cell
  PUSH HL                 ; the door and the three cells in front of it (row
                          ; y+1, x-1 to x+1) must hold no robot or building
                          ; (bit 6)
  LD A,(HL)
  INC H
  INC H
  OR (HL)
  DEC HL
  OR (HL)
  INC HL
  INC HL
  OR (HL)
  AND $40
  POP HL
  RET NZ                  ; blocked: wait for another turn
  CALL Random             ; the parts: a random mask (the second of two draws)
  CALL Random
  LD C,A
  LD (IY+$07),A
  AND $07                 ; the chassis bits 0-2: exactly one of bipod, tracks,
                          ; anti-grav
  CP $01
  JR Z,SpawnCheckWeapons
  CP $02
  JR Z,SpawnCheckWeapons
  CP $04
  RET NZ                  ; none or two chassis: no robot
SpawnCheckWeapons:
  LD A,C                  ; C = the weapons, bits 3-6 (cannon, missiles,
                          ; phasers, nuclear)
  RRCA
  RRCA
  RRCA
  AND $0F
  RET Z                   ; no weapon: no robot
  CP $0F
  RET Z                   ; all four weapons: no robot
  LD C,A
  LD A,(EnemyRobotCount)            ; B = EnemyRobots / 8 + 1: 1 below 8 robots, 2 from
                          ; 8, 3 from 16
  RRCA
  RRCA
  RRCA
  INC A
  AND $03
  LD B,A
  CALL CountDirections    ; A = the number of weapons ($B505)
  CP B
  RET C                   ; fewer weapons than B: no robot (a bigger army
                          ; builds only better-armed robots)
  LD HL,EnemyResources             ; spend on a copy: the enemy's resources into
                          ; MenuResources
  LD DE,MenuResources
  LD BC,$0007
  LDIR
  LD C,(IY+$07)           ; D: the shortfall the general resource has to cover
  LD D,$00
  LD B,$08
SpawnPayPart:
  RRC C                   ; for each part in the mask, bipod first
  JR NC,SpawnNextPart
  LD A,$08                ; A = the part's index 0-7
  SUB B
  PUSH AF
  LD HL,PartCosts         ; E = its cost (PartCosts)
  CALL AddAToHL
  LD E,(HL)
  POP AF
  LD HL,PartCosts+$0008   ; the resource it takes first (PartCosts + 8)
  CALL AddAToHL
  LD A,(HL)
  LD HL,MenuResources
  CALL AddAToHL
  LD A,(HL)
  SUB E                   ; pay from that resource
  JP P,SpawnStoreResource
  NEG                     ; not enough: the rest joins the shortfall, the
                          ; resource drops to 0
  ADD A,D
  LD D,A
  XOR A
SpawnStoreResource:
  LD (HL),A               ; the resource's new value
SpawnNextPart:
  DJNZ SpawnPayPart
  LD HL,MenuResources             ; the general resource may cover a shortfall up to
                          ; max(general / 2, 11)
  LD A,(HL)
  SRL A
  CP $0B
  JR NC,SpawnCheckGeneral
  LD A,$0B
SpawnCheckGeneral:
  CP D
  RET C                   ; the shortfall is too big: no robot, nothing spent
  LD A,(HL)
  SUB D
  RET M                   ; the general resource cannot pay it: no robot
  LD (HL),A
  LD DE,EnemyResources             ; commit: the copy back to the enemy's resources
                          ; $FD4A
  LD BC,$0007
  LDIR
  LD (IY+$0A),$80         ; +$0A = $80: an enemy robot
  EXX
  CALL PlaceRobot         ; place it on the door (x in HL', y in B'): +2 to +4,
                          ; the cell +0/+1, map bit 6, the radar dot
  EXX
  LD (IY+$05),$04         ; the start values; the player's robots get the same
                          ; at $A6F3, except +6 = 5 there
  LD (IY+$08),$04
  LD (IY+$06),$03
  LD (IY+$0D),$00
  LD (IY+$0B),$00         ; order 0: the next visit of this slot chooses one
  LD (IY+$0F),$01
  LD (IY+$0C),$64         ; +$0C = 100 (the strength a new robot starts with)
  LD (IY+$0E),$FF         ; no target yet
  LD C,(IY+$07)           ; the height +9: the sum of the parts' heights
  LD B,$08
  LD D,$00
SpawnHeightLoop:
  RRC C
  JR NC,SpawnHeightNext
  LD A,$08
  SUB B
  LD HL,PartHeights       ; the part heights at $D7B4: bipod 11, tracks 7,
                          ; anti-grav 8, cannon 6, missiles 6, phasers 7,
                          ; nuclear 7, electronics 7
  CALL AddAToHL
  LD A,(HL)
  ADD A,D
  LD D,A
SpawnHeightNext:
  DJNZ SpawnHeightLoop
  LD (IY+$09),D
  CALL CountRobots        ; recount the robots, redraw the status panel
  CALL UpdateStatusPanel
  RET
EnemyReplan:
  LD A,(IY+$0B)           ; a live enemy robot: order 0 is replaced at once
  OR A
  JR Z,EnemyChooseOrder
  LD B,A
  CALL Random             ; any other order is reconsidered once in 32 turns
  AND $1F
  RET NZ
  LD A,B
  CP $04                  ; orders 1-3 (advance, retreat, destroy robots):
                          ; choose anew
  JR C,EnemyChooseOrder
  LD A,(IY+$0B)           ; orders 4-8: HL = the target table's +3 bytes, E =
                          ; the owner bits the order looks for ($B3D5)
  CALL TargetBuildingTable
  LD A,(IY+$0E)           ; HL = the target's +3 byte (+$0E = the target's
                          ; index)
  LD B,A
  ADD A,A
  ADD A,A
  ADD A,B
  CALL AddAToHL
  LD A,(HL)               ; the target still has the owner the order looks for:
                          ; choose anew (again the nearest)
  AND $E0
  CP E
  JR Z,EnemyChooseOrder
  DEC HL                  ; the target changed hands (or was destroyed): keep
                          ; the order only while the robot stands on its door
  LD A,(IY+$04)
  SUB (HL)
  JR NZ,EnemyChooseOrder
  DEC HL
  LD D,(HL)
  DEC HL
  LD E,(HL)
  LD L,(IY+$02)
  LD H,(IY+$03)
  XOR A
  SBC HL,DE
  RET Z                   ; on the target's door: keep the order
EnemyChooseOrder:
  LD (IY+$0B),$03         ; 3 (destroy robots) unless a target is found below
  BIT 6,(IY+$07)          ; with nuclear: a demolition order
  JR Z,EnemyCaptureOrder
  CALL Random             ; 5 (destroy warbases) with chance 3/4 (bit 0 or bit
                          ; 7 set), else 4 (destroy factories)
  LD B,A
  RLCA
  OR B
  AND $01
  ADD A,$04
  LD (IY+$0B),A
  JR EnemyFindTarget
EnemyCaptureOrder:
  LD C,$00                ; without nuclear: a capture order
  CALL Random
  RRCA                    ; bit 0: 6 (capture neutral factories, 1/2), bit 1: 7
                          ; (the player's factories, 1/4), else 8 (the player's
                          ; warbases, 1/4)
  JR C,EnemySetCapture
  INC C
  RRCA
  JR C,EnemySetCapture
  INC C
EnemySetCapture:
  LD A,C
  ADD A,$06
  LD (IY+$0B),A
EnemyFindTarget:
  LD L,(IY+$02)           ; the nearest target of the order from the robot's x
                          ; ($B34D): D its index, $FF none
  LD H,(IY+$03)
  LD (IY+$0E),$FF
  CALL FindTargetBuilding
  LD (IY+$0E),D
  RET NZ                  ; found: keep the order
  LD (IY+$0B),$03         ; no such target: destroy robots
  RET

; NuclearBlast
;
; Used by the routines at CombatMenuCode and SteerByOrder.
NuclearBlast:
  LD HL,Warbases+3             ; a robot with order 4 or 5 has reached its target
                          ; (no step left): it detonates. IY = the robot
  LD C,$00                ; C = the base index 0-27 (0-3 warbases); D = the
                          ; reach in rows and in columns, E = in rows +
                          ; columns: 7, 10
  LD DE,$070A
BlastBaseLoop:
  PUSH HL
  BIT 7,(HL)              ; a destroyed base (bit 7) is skipped
  JR NZ,BlastNextBase
  DEC HL
  LD A,C
  CP $04
  LD A,(IY+$04)           ; A = the robot's y, + 4 for a warbase
  JR NC,BlastRowDistance
  ADD A,$04
BlastRowDistance:
  INC A                   ; dy = |robot y + 5 - y| for a warbase, |robot y + 1
                          ; - y| for a factory
  SUB (HL)
  JP P,BlastCheckRow
  NEG
BlastCheckRow:
  LD B,A
  CP D
  JR NC,BlastNextBase     ; dy out of reach
  PUSH DE
  DEC HL
  LD D,(HL)
  DEC HL
  LD E,(HL)
  LD L,(IY+$02)
  LD H,(IY+$03)
  CALL ColumnDistance     ; HL = dx = |robot x - base x| ($B3CA)
  POP DE
  LD A,H
  OR A
  JR NZ,BlastNextBase     ; dx of 256 or more
  LD A,L
  CP D
  JR NC,BlastNextBase     ; dx out of reach
  ADD A,B                 ; dx + dy
  CP E
  JR C,BlastHitBase       ; inside: the first base found in reach goes
BlastNextBase:
  POP HL
  LD A,$05
  CALL AddAToHL
  INC C
  LD A,C
  CP $04
  JR C,BlastBaseLoop
  LD DE,$0507             ; from base 4 on, the factories: reach 5, sum 7
  CP $1C
  JR C,BlastBaseLoop
  JR BlastArea            ; no base in reach: only the area around is hit
BlastHitBase:
  POP HL
  LD A,C
  CP $04
  JR NC,BlastHitFactory
  CALL DestroyWarbase     ; a warbase: its buildings removed, its blocks turned
                          ; to debris
  JR BlastArea
BlastHitFactory:
  SUB $04                 ; the factory's index 0-23
  CALL DestroyFactory
BlastArea:
  LD L,(IY+$00)           ; a round area of 9 x 9 cells centred on the robot
  LD H,(IY+$01)
  PUSH IY
  LD DE,Map+$1AFC         ; HL = the robot's cell 4 rows up and 4 columns left
  ADD HL,DE
  LD BC,$0909             ; C = 9 rows, B = 9 cells a row
BlastRow:
  PUSH BC
  PUSH HL
  LD A,H                  ; only rows 1-15 (H $DF-$FC): row 0 and rows off the
                          ; map are skipped
  CP $DF
  JR C,BlastNextRow
  CP $FD
  JR NC,BlastNextRow
  LD A,C                  ; round the corners: the first and last rows skip 2
                          ; cells at each side (5 cells), the second and eighth
                          ; skip 1 (7 cells)
  CP $01
  JR Z,BlastSkip2
  CP $02
  JR Z,BlastSkip1
  CP $08
  JR Z,BlastSkip1
  CP $09
  JR NZ,BlastCell
BlastSkip2:
  INC HL
  DEC B
  DEC B
BlastSkip1:
  INC HL
  DEC B
  DEC B
BlastCell:
  PUSH BC
  LD A,(HL)
  BIT 6,A                 ; bit 6 and a robot on the cell: the robot is
                          ; destroyed (record freed, bit 6 cleared); a
                          ; building's bit 6 stays
  JR Z,BlastScenery
  CALL FindRobot
  JR NZ,BlastScenery
  LD (IY+$01),$00
  RES 6,(HL)
BlastScenery:
  LD A,(HL)               ; the first cell (bit 5 clear) of a block of tiles
                          ; $11-$14 ...
  BIT 5,A
  JR NZ,BlastNextCell
  AND $1F
  CP $11
  JR C,BlastNextCell
  CP $15
  JR NC,BlastNextCell
  CALL Random             ; ... becomes a block of debris, tile 6 or 7 at
                          ; random
  AND $01
  ADD A,$06
  CALL PutBlock
BlastNextCell:
  POP BC
  INC HL
  DJNZ BlastCell
BlastNextRow:
  POP HL                  ; the row below
  INC H
  INC H
  POP BC
  DEC C
  JR NZ,BlastRow
  CALL ShipCell           ; the ship's cell keeps its bit 7 (the debris blocks
                          ; may have cleared it)
  SET 7,(HL)
  CALL DrawView           ; redraw the view
  POP IY
  LD (IY+$01),$00         ; the robot itself is gone
  CALL NuclearFlash       ; flash the view with the rumble
  LD A,$01                ; the radar map must be rebuilt
  LD (RadarDirty),A
  CALL CountRobots        ; recount the robots and the bases, redraw the status
                          ; panel
  CALL CountBases
  JP UpdateStatusPanel

; The nuclear blast's flash: the view's paper flickers through random colours
; with a fading rumble
;
; Called only by the blast ($BA76). Saves the 20 x 20 attributes of the view
; (from $5821, row 1 column 1) to $5B00-$5C8F, then 61 times: a burst of noise
; ($BAEE, 244 samples first, 4 fewer and a longer delay each time) and a new
; random paper colour (2-7, never the previous one) on every attribute of the
; view whose paper is not black. Restores the saved attributes at the end. The
; noise takes about 3.3 s of beeper time in total; the game stands still
; meanwhile.
;
; Verified by an experiment (own instance, PC set to $B99F with a poked nuclear
; robot): the run passes here after the bases and robots are hit. $5B00 is free
; scratch at that time (the printer buffer and above, also the save checksum of
; $C2E8).
NuclearFlash:
  LD DE,ViewBuffer        ; copy the view's attributes to $5B00
  LD HL,$5821
  LD BC,$1414
FlashSaveRow:
  PUSH BC
FlashSaveCell:
  LDI                     ; LDI counts BC down: INC C keeps B the column
                          ; counter
  INC C
  DJNZ FlashSaveCell
  LD A,$0C                ; the next attribute row: 32 - 20
  CALL AddAToHL
  POP BC
  DEC C
  JR NZ,FlashSaveRow
  LD BC,$F401             ; B = 244 samples, C = 1: the noise's length and
                          ; delay
FlashLoop:
  CALL NuclearRumble      ; one flash: noise, then the colours
  PUSH BC
  LD HL,$5821
  LD BC,$1414
FlashPickPaper:
  CALL Random             ; a random paper (bits 3-5) of colour 2 or more, not
                          ; the previous one (E)
  AND $38
  CP $10
  JR C,FlashPickPaper
  CP E
  JR Z,FlashPickPaper
  LD E,A
FlashRow:
  PUSH BC
FlashCell:
  LD A,(HL)               ; repaint the paper of every attribute whose paper is
                          ; not black
  AND $38
  JR Z,FlashNextCell
  LD A,(HL)
  AND $C7
  OR E
  LD (HL),A
FlashNextCell:
  INC HL
  DJNZ FlashCell
  LD A,$0C
  CALL AddAToHL
  POP BC
  DEC C
  JR NZ,FlashRow
  POP BC
  DJNZ FlashLoop          ; B fell by 3 in $BAEE and 1 here: 61 flashes
  LD HL,ViewBuffer        ; put the attributes back
  LD DE,$5821
  LD BC,$1414
RestoreRow:
  PUSH BC
RestoreCell:
  LDI
  INC C
  DJNZ RestoreCell
  LD A,$0C
  ADD A,E
  LD E,A
  JR NC,RestoreNextRow
  INC D
RestoreNextRow:
  POP BC
  DEC C
  JR NZ,RestoreRow
  RET

; One burst of the blast's noise: B samples of ROM bytes to the speaker, C the
; delay between
;
; Plays B samples: bit 4 (the speaker) of the ROM bytes from $0090 on, the
; border black, with a delay loop of C x 24 T-states after each. Returns B - 3
; and C + 3, so the next burst of NuclearFlash is shorter and lower: a dying
; rumble. Only NuclearFlash calls it.
NuclearRumble:
  PUSH BC
  LD HL,$0090             ; the ROM bytes as noise
RumbleSample:
  PUSH BC                 ; bit 4 to the speaker, border 0
  LD A,(HL)
  AND $10
  OUT ($FE),A
  INC HL
RumbleDelay:
  DEC C
  NOP
  NOP
  JR NZ,RumbleDelay
  POP BC
  DJNZ RumbleSample
  POP BC                  ; the next burst: 3 samples fewer, a longer delay
  DEC B
  DEC B
  DEC B
  INC C
  INC C
  INC C
  RET

; Count each side's bases: warbases and the factories of each type
;
; Clears PlayerBases ($FD3A, 7) and EnemyBases ($FD42, 7) and goes through the
; 28 base records ($FD70, 5 bytes): a base whose +3 has bit 6 counts for the
; player, bit 5 for the enemy, at index +3 bits 0-2 (0 warbases, 1-6 the
; factories of type 1-6: electronics, nuclear, phasers, missiles, cannon,
; chassis, the resource each makes); neutral and destroyed (bit 7) bases do not
; count. The status panel shows these counts ($D2C1); the daily production
; ($AE38) adds 5 general per warbase and 2 per factory to its resource; a side
; with no warbase loses ($AE6B).
;
; Called after every change of owner (the capture tick $AE17), after the blast
; ($BA81), and by the map builder ($BCCA). Ran 18 times in the deep recording.
CountBases:
  LD HL,PlayerBuildings             ; the player's counts
  LD B,$07
ClearPlayerCounts:
  LD (HL),$00
  INC HL
  DJNZ ClearPlayerCounts
  INC HL                  ; skip PlayerRobots ($FD41)
  LD B,$07
ClearEnemyCounts:
  LD (HL),$00
  INC HL
  DJNZ ClearEnemyCounts
  LD DE,Warbases+3             ; the +3 byte of base 0, 28 bases
  LD B,$1C
CountBaseLoop:
  LD A,(DE)
  OR A
  JP M,CountNextBase      ; destroyed: not counted
  LD HL,PlayerBuildings
  BIT 6,A
  JR NZ,CountBaseType
  LD HL,EnemyBuildings             ; not the player's: the enemy's?
  BIT 5,A
  JR Z,CountNextBase      ; neutral: not counted
CountBaseType:
  AND $07                 ; count[type] += 1
  CALL AddAToHL
  INC (HL)
CountNextBase:
  LD A,E                  ; the next record (all inside page $FD)
  ADD A,$05
  LD E,A
  DJNZ CountBaseLoop
  RET

; PlayerRobots ($FD41) and EnemyRobots ($FD49): the live records of each side
;
; Counts the robot records whose +1 (the map cell's high byte) is not 0: slots
; 0-23 into PlayerRobots, slots 24-47 into EnemyRobots. The status panel shows
; them (the ROBOTS line); the enemy's factory ($B86F) builds better-armed
; robots as its count grows. Called after each birth and death of a robot.
CountRobots:
  LD HL,Robots+$0001      ; the +1 byte of slot 0
  CALL CountLiveRobots
  LD (PlayerRobotCount),A
  CALL CountLiveRobots
  LD (EnemyRobotCount),A
  RET

; A = the live records among 24 robot records from HL (+1 not 0); HL moves past
; them
;
; Used by the routine at CountRobots.
CountLiveRobots:
  LD B,$18
  LD C,$00
  LD DE,$0010
CountLiveLoop:
  LD A,(HL)
  OR A
  JR Z,CountLiveNext
  INC C
CountLiveNext:
  ADD HL,DE
  DJNZ CountLiveLoop
  LD A,C
  RET

; Factory A (0-23) changes hands: to the player (B = 0) or the enemy (B = 1);
; its flag moves
;
; Sets the factory's owner bits ($BBB9), removes the flag buildings at both
; sides of its roof (the cells x-2 and x+2 of row y-2) and puts the new owner's
; flag: type 7 (the player's) at x-2, type 8 (the enemy's) at x+2. The
; factory's own building (type 1-6 at x, y-2) stays.
;
; Called by the capture tick ($AE01) when a robot has stood on the factory's
; door for 144 ticks. Ran 17 times in the deep recording (captures by both
; sides).
GiveFactory:
  LD HL,Factories+3             ; the factories' +3 bytes
  CALL SetBaseOwner
  DEC H                   ; HL = the roof row y-2, x+2
  DEC H
  DEC H
  DEC H
  INC HL
  INC HL
  CALL RemoveBuilding     ; no flag at x+2
  DEC HL
  DEC HL
  DEC HL
  DEC HL
  CALL RemoveBuilding     ; no flag at x-2
  LD A,B
  OR A
  JR Z,GiveFactoryFlag    ; the player's flag at x-2
  INC HL                  ; the enemy's at x+2
  INC HL
  INC HL
  INC HL
GiveFactoryFlag:
  ADD A,$07               ; type 7 or 8
  LD C,A
  CALL AddBuilding        ; add the flag building
  RET

; Warbase A (0-3) changes hands: to the player (B = 0) or the enemy (B = 1)
;
; Sets the owner bits ($BBB9) and rebuilds the warbase's buildings on its pad
; row y-4: removes those at x-4, x and x+4, then for the player puts the
; landing pad (type 0, x) and the player's flag (type 7, x-4); for the enemy
; only its flag (type 8, x+4). So a captured warbase gives the player a second
; pad where the construction menu opens.
;
; Called by the map builder ($BCB3-$BCC7: warbase 0 the player's, 1-3 the
; enemy's) and by the capture tick ($ADF9). In the deep recording only the four
; set-up calls ran.
GiveWarbase:
  LD HL,Warbases+3             ; the warbases' +3 bytes
  CALL SetBaseOwner
  LD A,H                  ; HL = the pad row y-4, column x
  SUB $08
  LD H,A
  CALL RemoveBuilding     ; the pad
  DEC L
  DEC L
  DEC L
  DEC L
  CALL RemoveBuilding     ; the player's flag place
  LD A,L
  ADD A,$08
  LD L,A
  CALL RemoveBuilding     ; the enemy's flag place
  LD C,$08
  LD A,B
  OR A
  JP NZ,AddBuilding       ; the enemy: its flag (type 8) at x+4
  DEC L
  DEC L
  DEC L
  DEC L
  LD C,A                  ; the player: the pad (type 0) at x
  CALL AddBuilding
  DEC L
  DEC L
  DEC L
  DEC L
  LD C,$07                ; and the flag (type 7) at x-4
  JP AddBuilding

; Base record A (HL = the table's +3 bytes): owner = the player (B = 0) or the
; enemy; HL = its door cell
;
; HL is $FD73 (warbases) or $FD87 (factories). Replaces bits 5-7 of the base's
; +3 with $40 (the player) or $20 (the enemy), which also clears the destroyed
; bit 7. Falls into BaseCell: HL = the map cell of the base's (x, y), its door.
SetBaseOwner:
  LD C,A
  ADD A,A
  ADD A,A
  ADD A,C
  CALL AddAToHL
  LD A,B
  OR A
  LD A,$40                ; the player's bit 6 ...
  JR Z,l_BBC7
  RRCA                    ; ... or the enemy's bit 5
l_BBC7:
  LD C,A                  ; keep the type, set the owner
  LD A,(HL)
  AND $1F
  OR C
  LD (HL),A
; This entry point is used by the routine at MarkBaseDestroyed.
BaseCell:
  DEC HL                  ; HL at a base's +3: HL = the map cell of its x
                          ; (+0/+1), y (+2)
  LD C,(HL)
  DEC HL
  LD A,(HL)
  DEC HL
  LD L,(HL)
  LD H,A
  LD A,C
  JP MapCell

; Factory A (0-23) destroyed by a nuclear blast: buildings removed, blocks
; turned to debris
;
; Marks the factory destroyed ($BC1C), removes its three buildings on the roof
; row y-2 (the flags at x+2 and x-2 and the factory at x) and draws the
; factory's shape (ShapeFactory) again in debris: every block a random tile 6
; or 7. Verified by an experiment: factory 0 at (39,6) became $80, its building
; at (39,4) went and its blocks became tiles 6 / 7.
DestroyFactory:
  LD HL,Factories+3
  CALL MarkBaseDestroyed
  PUSH HL                 ; keep the door cell
  DEC H                   ; the roof row y-2, x+2
  DEC H
  DEC H
  DEC H
  INC HL
  INC HL
  CALL RemoveBuilding
  DEC HL
  DEC HL
  CALL RemoveBuilding
  DEC HL
  DEC HL
  CALL RemoveBuilding
  POP HL                  ; the shape from the door
  LD DE,ShapeFactory      ; ShapeFactory
  JP DrawRuins

; Warbase A (0-3) destroyed by a nuclear blast: buildings removed, blocks
; turned to debris
;
; Marks the warbase destroyed ($BC1C), removes the buildings at x-4, x and x+4
; of its pad row y-4 and redraws ShapeWarbase in debris (tiles 6 / 7). Verified
; by an experiment: warbase 1 at (261,8) became $80, its flag building at
; (265,4) went, the enemy's warbase count fell from 3 to 2 and its walls became
; debris.
DestroyWarbase:
  LD HL,Warbases+3
  CALL MarkBaseDestroyed
  PUSH HL                 ; keep the door cell
  LD A,H                  ; the pad row y-4, x
  SUB $08
  LD H,A
  CALL RemoveBuilding
  DEC L
  DEC L
  DEC L
  DEC L
  CALL RemoveBuilding
  LD A,L
  ADD A,$08
  LD L,A
  CALL RemoveBuilding
  POP HL
  LD DE,ShapeWarbase      ; ShapeWarbase
  JP DrawRuins

; Base A of the table HL (+3 bytes): +3 = $80 (destroyed, no owner); HL = its
; door cell
;
; Used by the routines at DestroyFactory and DestroyWarbase.
MarkBaseDestroyed:
  LD C,A
  ADD A,A
  ADD A,A
  ADD A,C
  CALL AddAToHL
  LD (HL),$80             ; destroyed: no owner, no type
  JR BaseCell
; This entry point is used by the routines at DestroyFactory and
; DestroyWarbase.
DrawRuins:
  LD A,(DE)               ; draw the shape DE at cell HL with every block a
                          ; random debris tile (6 or 7)
  OR A
  JR Z,DrawRuinsStep
  CALL Random             ; any tile: debris
  AND $01
  ADD A,$06
  CALL PutBlock
DrawRuinsStep:
  INC DE                  ; the shape's next step: columns C, rows B; (0,0)
                          ; ends
  LD A,(DE)
  LD C,A
  INC DE
  LD A,(DE)
  LD B,A
  INC DE
  OR C
  RET Z
  CALL StepCell           ; HL to the next block
  JR DrawRuins

; Add a building: map cell HL, type C (0 pad, 1-6 factory, 7 the player's flag,
; 8 the enemy's flag)
;
; Takes the first free record of Buildings (56 x 3 bytes: the cell, the type; a
; high byte 0 = free), writes the cell and the type, and sets bit 6 of the map
; cell. With all 56 records taken it does nothing. The buildings are what the
; ship stands on (their heights by type at $B0C1: pad 15, factories 21-22,
; flags 25) and where landing opens the construction menu (type 0).
AddBuilding:
  LD DE,Buildings+1             ; the high bytes of the cells
  LD B,$38
AddBuildingFind:
  LD A,(DE)
  OR A
  JR Z,AddBuildingStore
  INC DE
  INC DE
  INC DE
  DJNZ AddBuildingFind
  RET
AddBuildingStore:
  DEC DE                  ; the cell's bit 6: something to find here
  SET 6,(HL)
  EX DE,HL
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (HL),C
  EX DE,HL
  RET

; Remove the building on map cell HL, if any: its record freed, bit 6 of the
; cell cleared
;
; Keeps IY and BC. Uses FindBuilding.
RemoveBuilding:
  PUSH IY
  PUSH BC
  CALL FindBuilding
  JR NZ,l_BC6B
  LD (IY+$01),$00
  RES 6,(HL)
l_BC6B:
  POP BC
  POP IY
  RET

; A new game's map: clear it, place the scenery and the 28 bases, give the
; warbases their owners
;
; Called once by the new game set-up ($A68B). Clears the map $DD00-$FCFF and
; the radar bitmap $D800-$D8FF, places the scenery lists SceneryWest (columns
; 0-255) and SceneryEast (256-511), then the bases BaseListWest and
; BaseListEast (records into $FD70: 4 warbases, 24 factories, all neutral),
; gives warbase 0 to the player and warbases 1-3 to the enemy, counts the
; bases, marks the radar for a rebuild and puts the ship on the map ($B024).
;
; The resulting map: the player's warbase at (22,9), the enemy's at (261,8),
; (369,8), (494,8); 24 factories, four of each type; read back from the live
; instance after a new game.
BuildMap:
  LD HL,Map               ; the map: 16 rows of 512 cells
  LD D,H
  LD E,L
  INC DE
  LD BC,$1FFF
  LD (HL),$00
  LDIR
  LD HL,RadarOwn          ; the radar bitmap
  LD D,H
  LD E,L
  INC DE
  LD BC,$00FF
  LD (HL),$00
  LDIR
  LD HL,SceneryWest       ; the scenery, columns 0-255
  LD D,$00
  CALL PlaceScenery
  LD HL,SceneryEast       ; the scenery, columns 256-511
  LD D,$01
  CALL PlaceScenery
  LD IY,Factories             ; the factories' records from $FD84, the warbases'
                          ; from $FD70
  LD IX,Warbases
  LD HL,BaseListWest
  LD D,$00
  CALL PlaceBases
  LD HL,BaseListEast
  LD D,$01
  CALL PlaceBases
  XOR A                   ; warbase 0: the player's
  LD B,A
  CALL GiveWarbase
  LD A,$01                ; warbases 1-3: the enemy's
  LD B,A
  CALL GiveWarbase
  LD A,$02
  LD B,$01
  CALL GiveWarbase
  LD A,$03
  LD B,$01
  CALL GiveWarbase
  CALL CountBases
  LD A,$01                ; rebuild the radar map
  LD (RadarDirty),A
  CALL PutShipOnMap       ; the ship's cell bit 7, the ship's radar dot
  RET

; Place a scenery list at HL (3-byte records: tile or shape, x low, y; 0 ends),
; D = x high byte
;
; A record with bit 7 clear is one 2 x 2 block of that tile ($BD91), with bit 7
; set the shape of that index ($BD61). The cell is $DD00 + $200 * y + D * 256 +
; x.
PlaceScenery:
  LD A,(HL)
  OR A
  RET Z
  LD C,A
  INC HL
  LD E,(HL)
  INC HL
  LD A,(HL)
  INC HL
  PUSH HL
  PUSH DE
  LD HL,Map               ; HL = the cell: $DD00 + 2 * y pages + DE
  ADD A,A
  ADD A,H
  LD H,A
  ADD HL,DE
  LD A,C
  OR A
  JP M,PlaceSceneryShape  ; bit 7: a shape
  CALL PutBlock
  JR PlaceSceneryNext
PlaceSceneryShape:
  CALL DrawShape
PlaceSceneryNext:
  POP DE
  POP HL
  JR PlaceScenery

; Place a bases list at HL (3-byte records: type, x low, y; $FF ends), D = x
; high byte
;
; Type 0: a warbase. Its record goes to IX (the warbases' table) and
; ShapeWarbase is drawn from the cell. Type 1-6: a factory of that type. Its
; record goes to IY (the factories' table), ShapeFactory is drawn and the
; factory's building (that type) is added two rows up, at (x, y-2). A record:
; +0/+1 x, +2 y, +3 the type (the owner bits come later), +4 0 (the capture
; counter).
PlaceBases:
  LD A,(HL)
  OR A
  RET M
  LD C,A
  INC HL
  LD E,(HL)
  INC HL
  LD A,(HL)
  LD B,A
  INC HL
  PUSH HL
  PUSH DE
  LD HL,Map
  ADD A,A
  ADD A,H
  LD H,A
  ADD HL,DE
  LD A,C
  OR A
  JR Z,PlaceWarbase       ; type 0: a warbase
  LD (IY+$00),E           ; a factory's record
  LD (IY+$01),D
  LD (IY+$02),B
  LD (IY+$03),C
  LD (IY+$04),$00
  INC IY
  INC IY
  INC IY
  INC IY
  INC IY
  PUSH BC
  PUSH HL
  LD A,$81                ; shape 1, ShapeFactory
  CALL DrawShape
  POP HL
  POP BC
  DEC H                   ; the factory's building at (x, y-2), its type
  DEC H
  DEC H
  DEC H
  CALL AddBuilding
  POP DE
  POP HL
  JR PlaceBases
PlaceWarbase:
  LD (IX+$00),E           ; a warbase's record
  LD (IX+$01),D
  LD (IX+$02),B
  LD (IX+$03),C
  LD (IX+$04),$00
  INC IX
  INC IX
  INC IX
  INC IX
  INC IX
  LD A,$80                ; shape 0, ShapeWarbase
  CALL DrawShape
  POP DE
  POP HL
  JR PlaceBases

; Draw shape A (bit 7 ignored, the index into ShapeTable) from map cell HL
;
; A shape is a list of 3-byte steps: a tile (0 = none) drawn as a 2 x 2 block
; at the current cell, then the move to the next cell: columns (signed), rows
; (signed); a move of (0,0) ends after its tile. DrawRuins ($BC27) walks the
; same lists with debris tiles.
DrawShape:
  PUSH HL
  LD HL,ShapeTable
  AND $7F
  CALL TableWord
  EX DE,HL
  POP HL
DrawShapeStep:
  LD A,(DE)
  OR A
  CALL NZ,PutBlock        ; a 2 x 2 block of the tile
  INC DE
  LD A,(DE)
  LD C,A
  INC DE
  LD A,(DE)
  LD B,A
  INC DE
  OR C
  RET Z                   ; the move (0,0) ends the shape
  CALL StepCell
  JR DrawShapeStep

; HL += C columns (signed) and B rows (signed: H += 2 * B); DE kept
;
; Used by the routines at MarkBaseDestroyed and DrawShape.
StepCell:
  PUSH DE
  LD E,C
  LD D,$00
  LD A,C
  OR A
  JP P,StepCellAdd
  LD D,$FF
StepCellAdd:
  ADD HL,DE
  LD A,H
  ADD A,B
  ADD A,B
  LD H,A
  POP DE
  RET

; A 2 x 2 block of tile A with its bottom left at map cell HL
;
; Writes the cells (x, y), (x+1, y), (x, y-1), (x+1, y-1): the first with the
; tile as it is, the other three with bit 5 set (the other parts of a block;
; the drawing and the blast take only the cell with bit 5 clear). Keeps HL and
; DE; BC is lost. Used by the map builder, the ruins, the blast and a dead
; robot's wreck ($B133).
PutBlock:
  PUSH DE
  LD E,A
  LD BC,$0202             ; 2 rows of 2 cells
  PUSH HL
PutBlockRow:
  PUSH BC
  PUSH HL
PutBlockCell:
  LD (HL),E               ; the first cell plain, the rest with bit 5
  SET 5,E
  INC HL
  DJNZ PutBlockCell
  POP HL
  POP BC
  DEC H                   ; the row above
  DEC H
  DEC C
  JR NZ,PutBlockRow
  POP HL
  POP DE
  RET

; The scenery of columns 0-255: 69 records (tile or shape, x, y) and the 0 that
; ends them
;
; Read by BuildMap through PlaceScenery with D = 0. Bit 7 clear: a 2 x 2 block
; of that tile; bit 7 set: shape (byte & $7F) of ShapeTable. Tiles used:
; $02-$09 and $0D (low features), $11 and $12 (free-standing blocks, height 7
; and 15: the ones a nuclear blast turns to debris). Shapes 2-10. The tile
; heights the ship and the robots meet are the table $D7BC.
SceneryWest:
  DEFB $86,$0C,$01
  DEFB $86,$0C,$09
  DEFB $11,$10,$0E
  DEFB $11,$20,$03
  DEFB $82,$22,$0A
  DEFB $05,$20,$0C
  DEFB $04,$2A,$0A
  DEFB $07,$2A,$0C
  DEFB $06,$2A,$0E
  DEFB $03,$2C,$0A
  DEFB $09,$2C,$0C
  DEFB $07,$2C,$0E
  DEFB $83,$2E,$0A
  DEFB $03,$30,$08
  DEFB $04,$32,$08
  DEFB $02,$36,$0C
  DEFB $06,$36,$0E
  DEFB $03,$38,$0E
  DEFB $12,$3F,$02
  DEFB $12,$41,$02
  DEFB $12,$46,$01
  DEFB $11,$46,$0F
  DEFB $11,$48,$0F
  DEFB $87,$48,$02
  DEFB $87,$53,$08
  DEFB $06,$53,$02
  DEFB $05,$53,$04
  DEFB $83,$55,$02
  DEFB $02,$55,$06
  DEFB $04,$5B,$06
  DEFB $07,$5D,$02
  DEFB $03,$5D,$04
  DEFB $85,$5E,$0F
  DEFB $88,$68,$09
  DEFB $88,$6E,$09
  DEFB $0D,$6E,$09
  DEFB $85,$6A,$04
  DEFB $85,$6C,$0D
  DEFB $84,$79,$09
  DEFB $11,$7F,$0C
  DEFB $11,$81,$07
  DEFB $85,$86,$04
  DEFB $12,$85,$0B
  DEFB $12,$85,$0D
  DEFB $87,$97,$06
  DEFB $82,$A5,$02
  DEFB $83,$A7,$06
  DEFB $83,$AD,$08
  DEFB $83,$B3,$0A
  DEFB $12,$BF,$08
  DEFB $89,$BF,$03
  DEFB $89,$C1,$08
  DEFB $89,$BF,$0D
  DEFB $89,$C7,$03
  DEFB $89,$C7,$0D
  DEFB $89,$CF,$03
  DEFB $89,$C9,$08
  DEFB $89,$CF,$0D
  DEFB $12,$D1,$08
  DEFB $89,$D7,$0D
  DEFB $89,$DF,$0D
  DEFB $11,$E5,$0B
  DEFB $84,$E9,$09
  DEFB $12,$E9,$07
  DEFB $82,$EB,$0A
  DEFB $82,$F3,$0A
  DEFB $02,$FB,$0C
  DEFB $04,$FB,$0E
  DEFB $03,$FD,$0E
  DEFB $00

; The scenery of columns 256-511: 68 records and the 0 that ends them
;
; Read by BuildMap through PlaceScenery with D = 1.
SceneryEast:
  DEFB $83,$0E,$02
  DEFB $83,$0C,$0A
  DEFB $83,$10,$0A
  DEFB $08,$08,$0E
  DEFB $09,$0A,$0C
  DEFB $0A,$0A,$0E
  DEFB $08,$18,$0C
  DEFB $0B,$18,$0E
  DEFB $12,$21,$03
  DEFB $11,$2B,$09
  DEFB $12,$33,$0D
  DEFB $11,$40,$0A
  DEFB $11,$42,$0C
  DEFB $11,$44,$0E
  DEFB $12,$49,$0C
  DEFB $85,$50,$05
  DEFB $85,$50,$09
  DEFB $85,$58,$05
  DEFB $85,$58,$09
  DEFB $84,$60,$09
  DEFB $12,$5E,$01
  DEFB $12,$5E,$03
  DEFB $11,$58,$01
  DEFB $11,$52,$03
  DEFB $11,$52,$0D
  DEFB $11,$56,$0D
  DEFB $11,$56,$0F
  DEFB $11,$58,$0F
  DEFB $11,$5A,$0F
  DEFB $11,$5A,$0B
  DEFB $8A,$64,$05
  DEFB $11,$7B,$04
  DEFB $03,$7B,$0E
  DEFB $04,$7D,$0C
  DEFB $02,$7D,$0E
  DEFB $82,$7F,$0A
  DEFB $05,$87,$0C
  DEFB $02,$87,$0E
  DEFB $04,$89,$0E
  DEFB $12,$8A,$01
  DEFB $11,$91,$0F
  DEFB $12,$99,$01
  DEFB $88,$96,$05
  DEFB $88,$99,$09
  DEFB $88,$99,$0D
  DEFB $87,$A4,$08
  DEFB $87,$A8,$02
  DEFB $87,$AC,$08
  DEFB $87,$B0,$02
  DEFB $09,$B4,$0E
  DEFB $83,$B6,$0A
  DEFB $83,$BC,$0A
  DEFB $04,$C0,$0A
  DEFB $03,$C2,$0A
  DEFB $02,$C2,$0C
  DEFB $88,$C5,$03
  DEFB $11,$D0,$0A
  DEFB $11,$D3,$0D
  DEFB $8A,$DE,$01
  DEFB $8A,$DC,$03
  DEFB $8A,$DA,$05
  DEFB $8A,$DA,$09
  DEFB $8A,$DC,$0B
  DEFB $8A,$DE,$0D
  DEFB $8A,$E0,$0F
  DEFB $8A,$E0,$05
  DEFB $86,$F7,$01
  DEFB $86,$F7,$09
  DEFB $00

; The bases of columns 0-255: 13 records (type, x, y), $FF ends
;
; Type 0 a warbase, 1-6 a factory making resource 1-6 (electronics, nuclear,
; phasers, missiles, cannon, chassis). Here: the player's warbase at (22,9) and
; the factories (39,6) type 4, (53,3) 6, (62,10) 1, (79,3) 5, (97,3) 3, (125,3)
; 2, (140,11) 6, (160,5) 1, (180,3) 3, (217,3) 4, (227,9) 5, (241,3) 6. The (x,
; y) is the base's door: the cell a robot stands on to capture it (the capture
; tick $AD90) and where the enemy's new robots appear (warbases).
BaseListWest:
  DEFB $00,$16,$09
  DEFB $04,$27,$06
  DEFB $06,$35,$03
  DEFB $01,$3E,$0A
  DEFB $05,$4F,$03
  DEFB $03,$61,$03
  DEFB $02,$7D,$03
  DEFB $06,$8C,$0B
  DEFB $01,$A0,$05
  DEFB $03,$B4,$03
  DEFB $04,$D9,$03
  DEFB $05,$E3,$09
  DEFB $06,$F1,$03
  DEFB $FF

; The bases of columns 256-511: 15 records (type, x, y), $FF ends
;
; The enemy's three warbases at (261,8), (369,8), (494,8) (given to the enemy
; by BuildMap) and twelve factories. With BaseListWest: 4 warbases and 24
; factories, four of each type, the order of the bases table $FD70.
BaseListEast:
  DEFB $00,$05,$08
  DEFB $03,$1A,$03
  DEFB $01,$20,$0D
  DEFB $02,$28,$03
  DEFB $04,$37,$07
  DEFB $06,$42,$03
  DEFB $00,$71,$08
  DEFB $03,$82,$03
  DEFB $05,$91,$07
  DEFB $01,$A0,$03
  DEFB $02,$B4,$05
  DEFB $04,$BE,$03
  DEFB $05,$C8,$0A
  DEFB $06,$D2,$03
  DEFB $00,$EE,$08
  DEFB $FF

; The shapes' addresses, index 0-10 (DrawShape)
;
; 0 the warbase, 1 the factory (both drawn by PlaceBases), 2-10 the scenery
; shapes (a scenery record $82-$8A).
ShapeTable:
  DEFW ShapeWarbase,ShapeFactory,ShapeLowTiles,ShapeMidTiles,ShapeTallWallV,ShapeTallWallH,ShapeEdgeFence,ShapeFlatLineV,ShapeFlatLineH,ShapeLowWallH,ShapeMixedWallH

; Shape 0: the warbase, 15 blocks of tiles $0F (height 7) and $10 (height 15)
; around the door
;
; Steps (tile, columns, rows): a first move of (-4,-4), then blocks reaching 4
; columns either side and up to 8 rows above the door. The pad, the block above
; the door at (x, y-4), is a tile $10 block: altitude 15 over it is the landing
; height of ConstructionMenu.
ShapeWarbase:
  DEFB $00,$FC,$FC
  DEFB $10,$00,$FE
  DEFB $10,$02,$05
  DEFB $0F,$00,$FE
  DEFB $0F,$00,$FE
  DEFB $0F,$00,$FE
  DEFB $10,$02,$05
  DEFB $0F,$00,$FE
  DEFB $10,$00,$FE
  DEFB $10,$02,$05
  DEFB $0F,$00,$FE
  DEFB $0F,$00,$FE
  DEFB $0F,$00,$FE
  DEFB $10,$02,$03
  DEFB $10,$00,$FE
  DEFB $10,$00,$00

; Shape 1: the factory, tiles $0F at (x-2, y) and (x+2, y), $10 on the roof row
; y-2 at x-2, x, x+2
;
; The door (x, y) stays free between the two low blocks.
ShapeFactory:
  DEFB $00,$FE,$00
  DEFB $0F,$00,$FE
  DEFB $10,$02,$00
  DEFB $10,$02,$00
  DEFB $10,$00,$02
  DEFB $0F,$00,$00

; Shape 2: 4 x 3 blocks of tiles $02-$05 (height 2)
ShapeLowTiles:
  DEFB $02,$02,$00
  DEFB $03,$02,$00
  DEFB $04,$02,$00
  DEFB $05,$FA,$02
  DEFB $04,$02,$00
  DEFB $05,$02,$00
  DEFB $02,$02,$00
  DEFB $03,$FA,$02
  DEFB $03,$02,$00
  DEFB $02,$02,$00
  DEFB $05,$02,$00
  DEFB $04,$00,$00

; Shape 3: 4 x 3 blocks of tiles $08-$0B (height 6)
ShapeMidTiles:
  DEFB $08,$02,$00
  DEFB $09,$02,$00
  DEFB $0A,$02,$00
  DEFB $0B,$FA,$02
  DEFB $0A,$02,$00
  DEFB $0B,$02,$00
  DEFB $08,$02,$00
  DEFB $09,$FA,$02
  DEFB $09,$02,$00
  DEFB $08,$02,$00
  DEFB $0B,$02,$00
  DEFB $0A,$00,$00

; Shape 4: four blocks of tile $12 (height 15) in a column
ShapeTallWallV:
  DEFB $12,$00,$02
  DEFB $12,$00,$02
  DEFB $12,$00,$02
  DEFB $12,$00,$00

; Shape 5: four blocks of tile $12 in a row
ShapeTallWallH:
  DEFB $12,$02,$00
  DEFB $12,$02,$00
  DEFB $12,$02,$00
  DEFB $12,$00,$00

; Shape 6: four blocks of tile $15 (height 99, impassable) in a column: the
; fences at both ends of the map
;
; Placed at (12,1), (12,9), (503,1), (503,9): the row of posts at the map's
; left and right edges.
ShapeEdgeFence:
  DEFB $15,$00,$02
  DEFB $15,$00,$02
  DEFB $15,$00,$02
  DEFB $15,$00,$00

; Shape 7: tiles $0C, $0D, $0D, $0E (height 0) in a column
ShapeFlatLineV:
  DEFB $0C,$00,$02
  DEFB $0D,$00,$02
  DEFB $0D,$00,$02
  DEFB $0E,$00,$00

; Shape 8: tiles $0C, $0D, $0D, $0E in a row
ShapeFlatLineH:
  DEFB $0C,$02,$00
  DEFB $0D,$02,$00
  DEFB $0D,$02,$00
  DEFB $0E,$00,$00

; Shape 9: four blocks of tile $11 (height 7) in a row
ShapeLowWallH:
  DEFB $11,$02,$00
  DEFB $11,$02,$00
  DEFB $11,$02,$00
  DEFB $11,$00,$00

; Shape 10: tiles $11, $12, $11 in a row
ShapeMixedWallH:
  DEFB $11,$02,$00
  DEFB $12,$02,$00
  DEFB $11,$00,$00

; Unused: zero to $C0FF
MapTablesSpare:
  DEFS $73

; The main menu: clear the screen, the title, the options; Z = start a new
; game, NZ = a game was loaded
;
; Called by Start ($A62A); Start goes on to the new game set-up on Z and
; straight to play on NZ ($A62D). Prints the title (PrintTitle) and the options
; 0-5; the current controls (Controls, $D3E4) show in cyan, the others in
; yellow ($C336). Then MainMenuKeys. Keys 1-3 choose the controls and redraw
; the options, 4 redefines the keys and redraws the whole menu, 5 loads a saved
; game, 0 starts.
;
; Verified on the own instance: the menu reads 0..START GAME, 1..KEYBOARD
; (cyan), 2..KEMPSTON J/S, 3..INTERFACE 2, 4..REDEFINE KEYS, 5..LOAD SAVED
; GAME.
MainMenu:
  CALL ClearScreen

; The main menu without the clearing: the title, then the options
MainMenuTitle:
  CALL PrintTitle

; The main menu's options (re-entered after keys 1-3)
;
; Used by the routine at MainMenuKeys.
MainMenuOptions:
  CALL PrintInline

; "0..START GAME" at (11,8) in double height, yellow
;
; PrintInline codes: attribute $46, setting $21 (double height), position row
; 11 column 8, the text, setting $00.
MenuStartText:
  DEFM $02,"F",$04,"!",$01,$0B,$08,"0..START GAME",$04,$00,$00

; Option 1, KEYBOARD, in the colour of Controls 1
MenuKeyboardOption:
  LD C,$01
  CALL ControlsOptionAttr
  CALL PrintInline

; Two new lines and "1..KEYBOARD"
MenuKeyboardText:
  DEFM $03,$03,$03,"1..KEYBOARD",$00

; Option 2, KEMPSTON J/S, in the colour of Controls 2
MenuKempstonOption:
  LD C,$02
  CALL ControlsOptionAttr
  CALL PrintInline

; Two new lines and "2..KEMPSTON J/S"
MenuKempstonText:
  DEFM $03,$03,"2..KEMPSTON J/S",$00

; Option 3, INTERFACE 2, in the colour of Controls 3; then options 4 and 5
MenuInterface2Option:
  LD C,$03
  CALL ControlsOptionAttr
  CALL PrintInline

; "3..INTERFACE 2", then in yellow "4..REDEFINE KEYS", "5..LOAD SAVED GAME"
MenuMoreText:
  DEFM $03,$03,"3..INTERFACE 2",$03,$03,$02,"F4..REDEFINE KEYS",$03,$03,"5..LOAD SAVED GAME",$00

; The main menu's keys: the title music until a key, then 0-5
;
; Waits until no key is held (each frame cycling the title's colours, $C820),
; plays the title music until a key ($C4A7), waits for a key (KEY-SCAN $028E,
; the character from the ROM's key table $0205): 0 returns Z, 1-3 set Controls
; and redraw the options, 4 RedefineKeys then the whole menu, 5 the load. Any
; other key is ignored.
MainMenuKeys:
  HALT                    ; wait until no key is held
  CALL TitleColourCycle
  CALL $028E
  LD A,E
  OR A
  JP P,MainMenuKeys
  CALL MenuMusic          ; the title music, until a key
MenuWaitKey:
  HALT
  CALL TitleColourCycle
  CALL $028E
  LD A,E
  OR A
  JP M,MenuWaitKey
  LD HL,$0205             ; the key's character from the ROM's main key table
  ADD A,L
  LD L,A
  LD A,(HL)
  CP $35
  JR Z,LoadGame           ; 5: load a saved game
  CP $30
  JR Z,MenuStart          ; 0: start
  CP $31
  JR Z,MenuKeyboard
  CP $32
  JR Z,MenuKempston
  CP $33
  JR Z,MenuInterface2
  CP $34
  JR NZ,MenuWaitKey
  CALL RedefineKeys       ; 4: redefine the keys, then the whole menu again
  JP MainMenu
MenuStart:
  XOR A                   ; Z: a new game
  RET
MenuKeyboard:
  LD A,$01                ; 1: keyboard
  JR MenuSetControls
MenuKempston:
  LD A,$02                ; 2: Kempston
  JR MenuSetControls
MenuInterface2:
  LD A,$03                ; 3: Interface 2
MenuSetControls:
  LD (KeyTable+$0018),A   ; Controls, then the options again
  JP MainMenuOptions

; "NETHER" and "EARTH" in big white letters at the top
;
; Used by the routines at MainMenuTitle and PrintTitleEnd.
PrintTitle:
  CALL PrintInline

; "NETHER" at (1,10) and "EARTH" at (5,11), attribute $47, setting $32 (triple
; height, double width)
TitleText:
  DEFM $01,$01,$0A,$02,"G",$04,"2NETHER",$01,$05,$0B,"EARTH",$00

; PrintTitle's return; then the load option
PrintTitleEnd:
  RET
; This entry point is used by the routine at MainMenuKeys.
LoadGame:
  CALL PrintTitle         ; key 5: the title again, PRESS PLAY ON TAPE
  CALL PrintInline

; "PRESS PLAY ON TAPE" at (22,7), cyan, double height
PlayTapeText:
  DEFM $01,$16,$07,$02,"E",$04,"!PRESS PLAY ON TAPE ",$00

; Load a saved game: the checksum block, the game block; NZ when it is good
;
; Red border. Loads two headerless blocks (flag $00) through the ROM's LD-BYTES
; past its border set-up ($0562, the INC D / EX AF,AF' / DEC D / DI before it
; done here): 2 bytes to $5B00 (the checksum), then $24D1 bytes to $D92B-$FDFB.
; If SaveChecksum of the block matches, the first 45 bytes go back to $D7D3
; (the 5 records of 9 bytes $B0E3 walks) and the next 168 to Buildings; returns
; NZ (MainMenu's caller skips the new game set-up). A mismatch prints LOADING
; ERROR!, beeps, waits for a key and restarts (Start).
;
; Not run in any recording; read from the code and the ROM's entry points. The
; block holds the robots ($DA00), the map ($DD00-$FCFF) and the variables
; $FD00-$FDFB (resources, clock, bases), so a load restores the whole game.
LoadGameBlocks:
  LD A,$02                ; red border while it loads
  OUT ($FE),A
  LD IX,ViewBuffer        ; 2 bytes: the checksum
  LD DE,$0002
  XOR A                   ; flag $00, carry set: load
  SCF
  INC D
  EX AF,AF'
  DEC D
  DI
  CALL $0562
  LD IX,SaveShots         ; the game block
  LD DE,$24D1
  XOR A
  SCF
  INC D
  EX AF,AF'
  DEC D
  DI
  CALL $0562
  XOR A
  OUT ($FE),A
  CALL SaveChecksum       ; DE = the block's sum
  LD HL,(ViewBuffer)      ; the saved sum
  AND A
  SBC HL,DE
  LD A,H
  OR L
  JR NZ,LoadBad
  LD HL,SaveShots         ; good: the staged tables back to their places
  LD DE,Shots             ; the 5 records of 9 bytes at $D7D3
  LD BC,$002D
  LDIR
  LD DE,Buildings             ; the buildings
  LD BC,$00A8
  LDIR
  EI
  OR $01                  ; NZ: a game was loaded
  RET
LoadBad:
  CALL PrintInline        ; LOADING ERROR!

; "LOADING ERROR!" at (22,2), white, double size
LoadErrorText:
  DEFM $01,$16,$02,$02,"G",$04,"\"LOADING ERROR!",$00

; After LOADING ERROR!: a beep, a key, then the start again (Start)
LoadError:
  LD A,$FA
  CALL Beep
  CALL WaitAnyKey
  JP Start

; Save the game to tape: the prompt, a key, the checksum block and the game
; block
;
; Called from the game loop when the SAVE key (Input bit 5, KeyTable record 2)
; is held ($A71A); the loop then redraws the screen and returns to play
; ($A68E). Installs StartInterrupt as the handler, prints PRESS RECORD AND PLAY
; / THEN ANY KEY at row 22, waits for a key, copies the 45 bytes at $D7D3 and
; Buildings to $D92B-$D9FF so that $D92B-$FDFB is one block, sums it into $5B00
; and saves the 2 bytes and the block (flag $00) through the ROM's SA-BYTES
; past its pilot choice ($04D0) with a short pilot (HL = $0900).
;
; Not run in any recording; read from the code and the ROM's entry points.
; LoadGameBlocks reads the same two blocks.
SaveGame:
  LD HL,StartInterrupt    ; the start-up's handler: the play handler's work
                          ; stops
  LD (Handler),HL
  CALL PrintInline

; "PRESS RECORD AND PLAY ", a new line, "     THEN ANY KEY     " at (22,0),
; cyan
RecordText:
  DEFM $01,$16,$00,$02,"EPRESS RECORD AND PLAY ",$03,"     THEN ANY KEY     ",$00

; After the prompt: a key, the staging, the checksum, the two blocks
SaveGameBlocks:
  CALL WaitAnyKey
  LD A,$01                ; the radar map is rebuilt afterwards
  LD (RadarDirty),A
  LD HL,Shots             ; stage the 5 records of 9 bytes at $D7D3 ...
  LD DE,SaveShots
  LD BC,$002D
  LDIR
  LD HL,Buildings             ; ... and the buildings at $D958
  LD BC,$00A8
  LDIR
  DI
  CALL SaveChecksum       ; the checksum
  LD (ViewBuffer),DE
  LD HL,$0900             ; a short pilot
  LD IX,ViewBuffer        ; the 2 checksum bytes, flag $00
  LD DE,$0002
  XOR A
  SCF
  CALL $04D0
  LD HL,$0900             ; the game block $D92B-$FDFB
  LD IX,SaveShots
  LD DE,$24D1
  XOR A
  SCF
  CALL $04D0
  XOR A
  OUT ($FE),A
  EI
  RET

; DE = the 16-bit sum of the $24D1 bytes at $D92B (the saved game block)
;
; Used by the routines at LoadGameBlocks and SaveGameBlocks.
SaveChecksum:
  LD HL,SaveShots
  LD BC,$24D1
  LD DE,$0000
ChecksumLoop:
  LD A,(HL)
  INC HL
  ADD A,E
  LD E,A
  JR NC,l_C31F
  INC D
l_C31F:
  DEC BC
  LD A,B
  OR C
  JR NZ,ChecksumLoop
  RET

; Wait until no key is held, then until one is (all half rows of port $FE)
;
; Used by the routines at LoadError and SaveGameBlocks.
WaitAnyKey:
  XOR A
  IN A,($FE)
  CPL
  AND $1F
  JR NZ,WaitAnyKey
WaitAnyKeyDown:
  XOR A
  IN A,($FE)
  CPL
  AND $1F
  JR Z,WaitAnyKeyDown
  RET

; The attribute for menu option C: cyan ($45) when it is the current Controls,
; else yellow ($46)
;
; Used by the routines at MenuKeyboardOption, MenuKempstonOption and
; MenuInterface2Option.
ControlsOptionAttr:
  LD A,($D3E4)
  CP C
  JR Z,ControlsOptionMarked
  CALL PrintInline

; PrintInline: attribute $46
OptionAttrPlain:
  DEFB $02,$46,$00

; ControlsOptionAttr's return, the option not chosen
ControlsOptionPlain:
  RET
; This entry point is used by the routine at ControlsOptionAttr.
ControlsOptionMarked:
  CALL PrintInline        ; the option chosen

; PrintInline: attribute $45
OptionAttrChosen:
  DEFB $02,$45,$00

; ControlsOptionAttr's return, the option chosen
ControlsOptionChosen:
  RET

; Redefine the eight keys: UP, DOWN, LEFT, RIGHT, FIRE, PAUSE, ABORT, SAVE
;
; Key 4 of the main menu. Clears the screen, prints REDEFINE KEYS, waits until
; no key is held, clears KeyTable and asks for each key in turn: PrintKeyPrompt
; prints "PRESS KEY FOR " and the name that follows the CALL, DefineKey waits
; for a key not yet taken and fills the KeyTable record whose third byte HL
; points at (the port's high byte, the bit mask, the key code) and prints the
; key. KeyTable's records 0-7 are PAUSE, ABORT, SAVE, FIRE, UP, DOWN, LEFT,
; RIGHT: Input bits 7 to 0. Waits for the last key's release and about 0.5 s,
; then back to the menu.
;
; Verified on the own instance: keys Q A O P M H B S gave KeyTable bf 10 48 /
; 7f 10 42 / fd 02 53 / 7f 04 4d / fb 01 51 / fd 01 41 / df 02 4f / df 01 50,
; the screen showed PRESS KEY FOR UP .. PAUSE with each key's letter, and the
; menu came back.
RedefineKeys:
  CALL ClearScreen
  CALL PrintInline

; "REDEFINE KEYS" at (2,9), white, double height, then position (5,3) and
; normal size
RedefineTitleText:
  DEFM $01,$02,$09,$02,"G",$04,"!REDEFINE KEYS",$01,$05,$03,$04,$00,$00

; Wait for no key, clear KeyTable, ask for UP
RedefineKeysBody:
  CALL $028E              ; wait until no key is held
  LD A,E
  OR A
  JP P,RedefineKeysBody
  LD HL,KeyTable          ; KeyTable: 24 bytes of 0
  LD DE,KeyTable+$0001
  LD BC,$0017
  LD (HL),$00
  LDIR
  CALL PrintKeyPrompt     ; "PRESS KEY FOR" and the name below

; "   UP"
KeyNameUp:
  DEFM "   UP",$00

; The key for UP (KeyTable record 4), then ask for DOWN
ReadUpKey:
  LD HL,KeyTable+$000E
  CALL DefineKey
  CALL PrintKeyPrompt

; " DOWN"
KeyNameDown:
  DEFM " DOWN",$00

; The key for DOWN (record 5), then ask for LEFT
ReadDownKey:
  LD HL,KeyTable+$0011
  CALL DefineKey
  CALL PrintKeyPrompt

; " LEFT"
KeyNameLeft:
  DEFM " LEFT",$00

; The key for LEFT (record 6), then ask for RIGHT
ReadLeftKey:
  LD HL,KeyTable+$0014
  CALL DefineKey
  CALL PrintKeyPrompt

; "RIGHT"
KeyNameRight:
  DEFM "RIGHT",$00

; The key for RIGHT (record 7), then ask for FIRE
ReadRightKey:
  LD HL,KeyTable+$0017
  CALL DefineKey
  CALL PrintKeyPrompt

; " FIRE"
KeyNameFire:
  DEFM " FIRE",$00

; The key for FIRE (record 3), a blank line, then ask for PAUSE
ReadFireKey:
  LD HL,KeyTable+$000B
  CALL DefineKey
  CALL PrintNewline
  CALL PrintKeyPrompt

; "PAUSE"
KeyNamePause:
  DEFM "PAUSE",$00

; The key for PAUSE (record 0), then ask for ABORT
ReadPauseKey:
  LD HL,KeyTable+$0002
  CALL DefineKey
  CALL PrintKeyPrompt

; "ABORT"
KeyNameAbort:
  DEFM "ABORT",$00

; The key for ABORT (record 1), then ask for SAVE
ReadAbortKey:
  LD HL,KeyTable+$0005
  CALL DefineKey
  CALL PrintKeyPrompt

; " SAVE"
KeyNameSave:
  DEFM " SAVE",$00

; The key for SAVE (record 2), wait for its release and a pause, back to the
; menu
ReadSaveKey:
  LD HL,KeyTable+$0008
  CALL DefineKey
RedefineWaitRelease:
  CALL $028E              ; until the SAVE key is let go
  LD A,E
  OR A
  JP P,RedefineWaitRelease
  LD BC,$0000             ; all keys up: a fixed pause of 65536 turns of the
                          ; loop below (about 2 million T, 0.56 s) before the
                          ; menu
RedefineKeysPause:
  DEC BC                  ; count BC down from $0000 through all 65536 values
RedefineKeysPauseNop:
  NOP                     ; a pad (the label is a false entry of the static
                          ; walk: the string bytes before it read as JR
                          ; NZ,$C406)
  LD A,C
  OR B
  JR NZ,RedefineKeysPause
  RET                     ; back to the caller of $C34A, which restarts the
                          ; main menu ($C1CE)

; "PRESS KEY FOR " and then the key's name that follows the caller's CALL
;
; Called by the redefine-keys screen ($C37F, $C38E, ... $C3EB) once for each of
; the eight keys, with the key's name (UP, DOWN, LEFT, RIGHT, FIRE, PAUSE,
; ABORT, SAVE) as an inline string after the CALL. It prints its own inline
; text (two new lines, attribute $46, "PRESS KEY FOR ", attribute $45), then
; jumps (not calls) to PrintInline at $C424: the return address on the stack is
; then the caller's, so PrintInline prints the caller's name string and returns
; past it. One prompt takes two screen rows.
PrintKeyPrompt:
  CALL PrintInline        ; our own text first

; PrintInline text: new line, new line, attribute $46, "PRESS KEY FOR ",
; attribute $45
PressKeyForText:
  DEFM $03,$03,$02,"FPRESS KEY FOR ",$02,"E",$00

; print the caller's inline key name and return past it
;
; The tail of PrintKeyPrompt: a JP to PrintInline with the caller's return
; address on top of the stack, so the bytes after the caller's CALL $C40C (the
; name of the key to press) are printed and skipped.
PrintKeyPromptName:
  JP PrintInline          ; the caller's string, and back past it

; wait for a free key, store its port, mask and code into a KeyTable entry,
; print its name
;
; HL = the code byte (the third byte) of a KeyTable entry; the redefine screen
; passes the entries in the order UP (+$0E), DOWN (+$11), LEFT (+$14), RIGHT
; (+$17), FIRE (+$0B), PAUSE (+$02), ABORT (+$05), SAVE (+$08), so the entries
; map to the Input bits 3, 2, 1, 0, 4, 7, 6, 5 (ReadControls shifts entry 0
; into bit 7). The screen cleared the whole table before the first key, so only
; keys already defined in this pass count as taken.
;
; It prints two spaces and sets attribute $46, then waits with the ROM KEY-SCAN
; ($028E) for a key; the key value E (0-39, row index 0-7 in bits 0-2, bit
; position from bit 4 down in bits 3-5) is turned into a code through the ROM
; key table $0205 (CAPS SHIFT gives $E3, the first byte past the table). A key
; whose code is already in one of the eight entries is refused and the wait
; goes on. Then it writes the code, the bit mask $20 >> (E/8 + 1) and the port
; high byte ($7F for row 0 down to $FE for row 7) backwards into the entry, and
; prints the key's name: SYM SH, ENTER, CAPS SH, SPACE, or the code as a
; character.
;
; Experiment: key 4 at the menu, then Q, Q, A, O, P, SPACE, ENTER, CAPS SHIFT,
; SYMBOL SHIFT left KeyTable = FB 01 51 / FD 01 41 / DF 02 4F / DF 01 50 for UP
; / DOWN / LEFT / RIGHT, 7F 01 20 for FIRE, BF 01 0D, FE 01 E3, 7F 02 0E for
; PAUSE / ABORT / SAVE; the second Q was refused.
DefineKey:
  PUSH HL                 ; keep the entry's address
  CALL PrintInline        ; two spaces, then the attribute of the name

; PrintInline text: two spaces, attribute $46
DefineKeyBlank:
  DEFM "  ",$02,"F",$00

; wait for a key that no entry holds yet
;
; Continues DefineKey after its inline text. On exit the entry is filled and
; the name printed (the RET is the one after each name string, or the one in
; PrintCharKeep's path for a plain character).
DefineKeyScan:
  CALL $028E              ; ROM KEY-SCAN: E = the key value, $FF none
  LD A,E
  OR A
  JP M,DefineKeyScan      ; no key yet
  LD HL,$0205             ; the ROM's key table: E -> the key's code
  ADD A,L
  LD L,A
  LD A,(HL)
  LD D,A                  ; D = the code
  LD HL,KeyTable+$0002    ; the code bytes of the eight entries
  LD B,$08
KeyTakenLoop:
  CP (HL)                 ; a code already used is refused: wait again
  JR Z,DefineKeyScan
  INC HL
  INC HL
  INC HL
  DJNZ KeyTakenLoop
  POP HL                  ; HL = the entry's code byte
  LD (HL),A               ; store the code
  LD A,E                  ; C = the row index (0 = port $7FFE ... 7 = port
                          ; $FEFE)
  AND $07
  LD C,A
  SRL E                   ; E / 8 = the key's place in its half-row, counted
                          ; from bit 4
  SRL E
  SRL E
  LD B,E
  INC B
  LD A,$20                ; the mask: $20 rotated right E/8 + 1 times
KeyMaskShift:
  RRCA
  DJNZ KeyMaskShift
  DEC HL                  ; the entry's mask byte
  LD (HL),A
  LD B,C                  ; the port high byte: $FF shifted right row + 1 times
                          ; with 0 coming in
  INC B
  XOR A
  DEC A
KeyPortShift:
  RRA
  DJNZ KeyPortShift
  DEC HL                  ; the entry's port byte
  LD (HL),A
  LD A,D                  ; the code decides the name
  CP $0E                  ; SYMBOL SHIFT
  JR NZ,CheckEnterKey
  CALL PrintInline        ; its name, and the RET after the string

; PrintInline text: "SYM SH"
KeyNameSymShift:
  DEFM "SYM SH",$00

; a RET ($C9): PrintInline returns here and the routine ends
KeyNameSymShiftEnd:
  RET

; DefineKey: is the new key ENTER?
;
; Part of DefineKey ($C427): code $0D prints "ENTER" and returns through the
; RET placed after the string.
CheckEnterKey:
  CP $0D                  ; ENTER
  JR NZ,CheckCapsShiftKey
  CALL PrintInline        ; its name, and the RET after the string

; PrintInline text: "ENTER"
KeyNameEnter:
  DEFM "ENTER",$00

; a RET ($C9) after the string
KeyNameEnterEnd:
  RET

; DefineKey: is the new key CAPS SHIFT?
;
; Part of DefineKey ($C427): code $E3 (the byte after the ROM's key table, what
; CAPS SHIFT alone looks up) prints "CAPS SH".
CheckCapsShiftKey:
  CP $E3                  ; CAPS SHIFT
  JR NZ,CheckSpaceKey
  CALL PrintInline        ; its name, and the RET after the string

; PrintInline text: "CAPS SH"
KeyNameCapsShift:
  DEFM "CAPS SH",$00

; a RET ($C9) after the string
KeyNameCapsShiftEnd:
  RET

; DefineKey: SPACE prints its name, any other key prints its own character
;
; Part of DefineKey ($C427). A code other than $20 goes to PrintCharKeep (print
; the character A) and returns from there.
CheckSpaceKey:
  CP $20                  ; SPACE
  JP NZ,PrintCharKeep     ; any other key: print its code as a character and
                          ; return
  CALL PrintInline        ; "SPACE"

; PrintInline text: "SPACE"
KeyNameSpace:
  DEFM "SPACE",$00

; RET: the end of DefineKey; also the target of the music's command 0
;
; The RET after the SPACE name. The two command tables of the menu music
; ($C553, $C572) point their command 0 here; command 0 never occurs in the
; tune, and it would not work: the dispatch leaves the voice pointer pushed, so
; this RET would return into the tune data.
DefineKeyDone:
  RET

; play the menu tune until a number key is pressed
;
; Called once by the main menu ($C19E) after all keys are up. Saves SP in
; $FD08, installs MenuInterrupt as Handler and sets the music state: the bass
; voice reads the track $C678 through HL' (frames left C'), the lead voice the
; track $C702 through DE' (frames left B'), the drum the track $C665 through HL
; (frames left C); C' = B' = C = 1, so the first interrupt reads the first
; event of each. Then it runs the tone loop for ever: the main set's D and E
; count each voice's period down.
;
; The tone loop never returns: MenuInterrupt ends it by loading SP from $FD08
; when a number key is down, so the RET of the interrupt returns from MenuMusic
; to the menu ($C1A1), which then reads the key. Ran 144 frames in work/play
; (12666-12814). The tune is 5120 frames (102.4 s) long in each voice and loops
; (experiment: both voices jumped back at frame 5099 of a menu left alone);
; docs: r4.md.
MenuMusic:
  DI                      ; no interrupt while the state is set
  LD (SavedSP),SP           ; the stack for the exit from MenuInterrupt
  LD HL,MenuInterrupt
  LD (Handler),HL
  LD HL,BassTrack         ; HL' = the bass track
  LD DE,LeadTrack         ; DE' = the lead track
  LD BC,$0101             ; B' = C' = 1: read both voices at the first
                          ; interrupt
  EXX
  LD HL,DrumTrackSteady   ; HL = the drum track, C = 1: read it at the first
                          ; interrupt
  EI
  LD C,$01
  HALT                    ; start on an interrupt

; tone loop: the time of a bass step without an edge
;
; The tone loop runs LeadStep and BassStep in turn, about 122 T a turn. A step
; whose counter has not run out takes this pad (PUSH AF, read Input and write
; it back unchanged, POP AF: 61 T with the DEC / JP) so both paths take about
; the same time, the pitch stays steady whatever the other voice does.
BassIdlePad:
  PUSH AF                 ; a pad: Input is written back unchanged, only the
                          ; time counts
  LD A,(Input)
  LD (Input),A
  POP AF

; tone loop: count the lead period down, at 0 a pulse
;
; D counts the lead voice's period in loop turns. At 0 it reloads D with the
; note's period (the operand $C4D0), sets the beeper (EAR and MIC, $18, or 0
; when the voice is off: the operand $C4D2) for a pulse of 14 * width T (the
; operand $C4D6 = period / 4, at most 63), then clears it. The voice's pitch is
; about 3.5 MHz / (122 + 3.5) / period: period $7C about 225 Hz, $29 about 680
; Hz.
LeadStep:
  DEC D                   ; the lead counter
  JP NZ,LeadIdlePad
  LD D,$00                ; reload: the note's period, written by LeadNextEvent
                          ; ($C540)
  LD A,$18                ; $18 voice on, 0 off: written by LeadOn / LeadOff
  OUT ($FE),A             ; the pulse's leading edge
  LD A,$00                ; the pulse width: period / 4, written by $C547
LeadPulse:
  DEC A                   ; hold the pulse
  JP NZ,LeadPulse
  OUT ($FE),A             ; A = 0: the trailing edge
  JP BassStep
LeadIdlePad:
  PUSH AF                 ; no edge: the same pad as BassIdlePad
  LD A,(Input)

; the rest of the lead pad (an entry only because work/deep starts its
; recording here)
;
; Write Input back and POP AF, then fall into BassStep. The recording of
; work/deep began inside the tone loop at this instruction, so its L1 lists the
; address as a root.
LeadIdlePadTail:
  LD (Input),A
  POP AF

; tone loop: count the bass period down, at 0 a pulse
;
; The bass voice's twin of LeadStep: E is its counter, the operands $C4ED
; (period), $C4EF (on / off) and $C4F3 (pulse width) are written by
; BassNextEvent, BassOn and BassOff.
BassStep:
  DEC E                   ; the bass counter
  JP NZ,BassIdlePad
  LD E,$00                ; reload: the note's period, written by BassNextEvent
                          ; ($C52D)
  LD A,$18                ; $18 voice on, 0 off: written by BassOn / BassOff
  OUT ($FE),A
  LD A,$00                ; the pulse width: period / 4, written by $C534
BassPulse:
  DEC A                   ; hold the pulse
  JP NZ,BassPulse
  OUT ($FE),A
  JP LeadStep             ; next turn: the lead voice

; the interrupt handler of the menu
MenuInterrupt:
  PUSH AF
  DEC C                   ; the drum's frames run out: play the next drum
                          ; record (inside the interrupt, the tone loop waits)
  CALL Z,DrumStep
  EXX                     ; the voices' registers
  DEC C                   ; the bass note's frames run out: the next bass event
  CALL Z,BassNextEvent
  DEC B                   ; the lead note's frames run out: the next lead event
  CALL Z,LeadNextEvent
  CALL TitleColourCycle   ; the title's colours
  LD A,$E7                ; half-rows 1-5 and 6-0: a number key, any menu
                          ; choice
  IN A,($FE)
  CPL
  AND $1F
  JR NZ,MenuMusicExit
  EXX                     ; none: back to the tone loop
  POP AF
  EI
  RET
MenuMusicExit:
  DI                      ; a number key: drop the tone loop, return from
                          ; MenuMusic to the menu
  LD SP,(SavedSP)           ; SP as MenuMusic left it: the next RET returns to
                          ; $C1A1
  LD HL,StartInterrupt
  LD (Handler),HL
  EI
  RET

; read the bass voice's next event: a note, or a command
;
; HL' = the bass track position. A byte of 9 or more is a note: the byte is the
; period (written into $C4ED, and period / 4 into the pulse width $C4F3) and
; the next byte its length in frames (C'). A byte below 9 is a command
; (BassCommand). Called by MenuInterrupt when C' runs out, and jumped to again
; by every command handler, so commands take no time.
BassNextEvent:
  LD A,(HL)               ; the event byte
  CP $09
  JR C,BassCommand        ; below 9: a command
  LD (BassStep+$0005),A   ; the period into LD E,n
  RRCA                    ; the pulse width: period / 4
  RRCA
  AND $3F
  LD (BassStep+$000B),A
  INC HL                  ; C' = the note's frames
  LD C,(HL)
  INC HL
  RET

; read the lead voice's next event: a note, or a command
;
; The lead twin of BassNextEvent: DE' = the position, the note goes into $C4D0
; / $C4D6 and its frames into B'.
LeadNextEvent:
  LD A,(DE)               ; the event byte
  CP $09
  JR C,LeadCommand        ; below 9: a command
  LD (LeadStep+$0005),A   ; the period into LD D,n
  RRCA                    ; the pulse width: period / 4
  RRCA
  AND $3F
  LD (LeadStep+$000B),A
  INC DE
  LD A,(DE)               ; B' = the note's frames
  LD B,A
  INC DE
  RET
; This entry point is used by the routine at BassNextEvent.
BassCommand:
  PUSH HL                 ; command A of the bass track: jump to entry A of the
                          ; table after the CALL
  CALL MusicDispatch      ; MusicDispatch pops the table address
BassCommandTable:
  JP DefineKeyDone        ; entry 0: JP $C4A6 (never used, it would RET into
                          ; the pushed HL)

; bass command 1: JP BassGoto ($C5A7), the 3-byte entry 1
BassCmd1:
  DEFB $C3,$A7,$C5

; bass command 2 (entry): JP BassCall
;
; A table entry of BassCommandTable: command 2 calls a pattern.
BassCmd2:
  JP BassCall

; bass command 3 (entry): JP SetDrumTrack
;
; A table entry: command 3 starts another drum track.
BassCmd3:
  JP SetDrumTrack

; bass command 4 (entry): JP BassOn
;
; A table entry: command 4 turns the bass voice on.
BassCmd4:
  JP BassOn

; bass command 5 (entry): JP BassOff
;
; A table entry: command 5 turns the bass voice off (its notes keep their time,
; silent).
BassCmd5:
  JP BassOff

; bass command 6 (entry): JP BassReturn
;
; A table entry: command 6 ends a pattern.
BassCmd6:
  JP BassReturn

; bass commands 7 and 8: JP SetDrumTrack twice (unused, the same as command 3)
BassCmd7:
  DEFB $C3,$CC,$C5
  DEFB $C3,$CC,$C5

; command A of the lead track: jump to entry A of the table after the CALL
;
; The lead twin of BassCommand. HL' (the bass position) is pushed so the
; handlers can pop it back.
LeadCommand:
  PUSH HL
  CALL MusicDispatch      ; MusicDispatch pops the table address
LeadCommandTable:
  JP DefineKeyDone        ; entry 0: JP $C4A6 (never used)

; lead command 1: JP LeadGoto ($C5B0)
LeadCmd1:
  DEFB $C3,$B0,$C5

; lead command 2 (entry): JP LeadCall
;
; A table entry of LeadCommandTable: command 2 calls a pattern.
LeadCmd2:
  JP LeadCall

; lead command 3: JP SetDrumTrack, a bass-only handler (it reads HL', the bass
; track): unusable from the lead track and unused
LeadCmd3:
  DEFB $C3,$CC,$C5

; lead command 4 (entry): JP LeadOn
;
; A table entry: command 4 turns the lead voice on.
LeadCmd4:
  JP LeadOn

; lead command 5 (entry): JP LeadOff
;
; A table entry: command 5 turns the lead voice off.
LeadCmd5:
  JP LeadOff

; lead command 6 (entry): JP LeadReturn
;
; A table entry: command 6 ends a pattern.
LeadCmd6:
  JP LeadReturn

; lead commands 7 and 8: JP SetDrumTrack twice (unused)
LeadCmd7:
  DEFB $C3,$CC,$C5
  DEFB $C3,$CC,$C5

; bass command 2 aa: play the pattern at aa, then go on after the command
;
; One level only: the return position (the address operand's high byte) is kept
; in $FD54; BassReturn resumes one byte past it.
BassCall:
  POP HL                  ; HL' = the bass position again
  INC HL
  LD A,(HL)
  INC HL
  LD (BassReturnPos),HL           ; the return point
  LD H,(HL)               ; HL' = the pattern
  LD L,A
  JP BassNextEvent

; lead command 2 aa: play the pattern at aa, then go on after the command
;
; The return position is kept in $FD56.
LeadCall:
  POP HL                  ; HL' back (the bass position); DE' is the lead
                          ; position
  EX DE,HL
  INC HL
  LD A,(HL)
  INC HL
  LD (LeadReturnPos),HL           ; the return point
  LD H,(HL)
  LD L,A
  EX DE,HL                ; DE' = the pattern
  JP LeadNextEvent

; bass command 1 aa: continue the track at aa (code: POP HL, read the word, JP
; BassNextEvent)
;
; Code that runs when the tune loops (frame 5099 of a menu left alone): the
; recordings never stayed in the menu that long, so the cut keeps it as data.
; POP HL; INC HL; LD A,(HL); INC HL; LD H,(HL); LD L,A; JP $C528. The bass
; track ends with 1 $C678.
BassGoto:
  POP HL
  INC HL
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  JP BassNextEvent

; lead command 1 aa: continue the track at aa (code, run only when the tune
; loops)
;
; POP HL; EX DE,HL; INC HL; LD A,(HL); INC HL; LD H,(HL); LD L,A; EX DE,HL; JP
; $C53B. The lead track ends with 1 $C702.
LeadGoto:
  POP HL
  EX DE,HL
  INC HL
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  EX DE,HL
  JP LeadNextEvent

; bass command 6: back from the pattern to the bass track
;
; Used by the routine at BassCmd6.
BassReturn:
  POP HL
  LD HL,(BassReturnPos)           ; one past the call's address operand
  INC HL
  JP BassNextEvent

; lead command 6: back from the pattern to the lead track
;
; Used by the routine at LeadCmd6.
LeadReturn:
  POP HL
  LD DE,(LeadReturnPos)           ; one past the call's address operand
  INC DE
  JP LeadNextEvent

; bass command 3 aa: the drum plays the track at aa from its next record
;
; Writes aa into the main set's HL, the drum position (the frames left of the
; current drum record are kept). Read through the bass voice's HL', so only the
; bass track may use it.
SetDrumTrack:
  POP HL
  INC HL
  LD A,(HL)
  INC HL
  EXX                     ; low byte into the drum's HL
  LD L,A
  EXX
  LD A,(HL)
  INC HL
  EXX                     ; high byte into the drum's HL
  LD H,A
  EXX
  JP BassNextEvent

; play the next drum record (a short noise or sweep inside the interrupt)
;
; HL = the drum position, called by MenuInterrupt when the drum's frames (C)
; run out. A record is the frames until the next one and a kind: 0 a hiss (96
; bytes of ROM from $08xx sent to the beeper, about 1 ms), 2 p a falling tone
; (48 cycles: the low half starts at p - 1 and shortens by 1, the high half
; starts at p / 2 and lengthens by 4), any other kind a rasp (80 ROM bytes from
; $00xx with a gap that mostly grows). The byte 1 in place of the frames is a
; goto: 1 aa. The tone loop stands still while a drum plays. In the 5300-frame
; experiment kinds 1 and 2 ran 72 times each.
DrumStep:
  LD A,(HL)               ; the frames, or 1
  INC HL
  CP $01                  ; 1 aa: goto
  JR Z,DrumGoto
  LD C,A                  ; C = the frames to the next record
  LD A,(HL)               ; the kind
  INC HL
  CP $02
  JR Z,DrumSweep
  AND A
  JR Z,DrumHiss
DrumRasp:
  PUSH HL                 ; any other kind: 80 ROM bytes $00xx; the gap (~B &
                          ; $3F) grows $2F-$3F, once 256, then 1-$3E
  LD H,$00
  LD B,$50
DrumRaspLoop:
  LD A,(HL)               ; a ROM byte's EAR / MIC bits to the beeper
  AND $18
  OUT ($FE),A
  LD A,B
  CPL
  AND $3F
DrumRaspGap:
  DEC A
  JR NZ,DrumRaspGap
  INC HL
  DJNZ DrumRaspLoop
  POP HL
  RET
DrumGoto:
  LD A,(HL)               ; the record 1 aa: continue at aa
  INC HL
  LD H,(HL)
  LD L,A
  JP DrumStep
DrumHiss:
  PUSH HL                 ; kind 0: 96 ROM bytes $08xx straight to the beeper
  LD H,$08
  LD B,$60
DrumHissLoop:
  LD A,(HL)
  AND $18
  OUT ($FE),A
  DJNZ DrumHissLoop
  POP HL
  RET
DrumSweep:
  LD A,(HL)               ; kind 2 p: the falling tone
  INC HL
  PUSH HL
  LD B,$30
  LD L,A                  ; the low half
  RRCA                    ; the high half: p / 2
  LD H,A
DrumSweepLoop:
  XOR A                   ; the low half, one shorter each cycle
  OUT ($FE),A
  DEC L
  LD A,L
DrumSweepLow:
  DEC A
  JR NZ,DrumSweepLow
  LD A,$18                ; the high half, 4 longer each cycle
  OUT ($FE),A
  LD A,$04
  ADD A,H
  LD H,A
DrumSweepHigh:
  DEC A
  JR NZ,DrumSweepHigh
  DJNZ DrumSweepLoop
  POP HL
  RET

; bass command 4: the bass pulses sound again
;
; Used by the routine at BassCmd4.
BassOn:
  POP HL
  LD A,$18                ; EAR and MIC into the bass pulse ($C4EF)
  LD (BassStep+$0007),A
  INC HL
  JP BassNextEvent

; bass command 5: the bass pulses go silent (the notes still take their time)
;
; Used by the routine at BassCmd5.
BassOff:
  POP HL
  XOR A
  LD (BassStep+$0007),A
  INC HL
  JP BassNextEvent

; lead command 4: the lead pulses sound again
;
; Used by the routine at LeadCmd4.
LeadOn:
  POP HL
  LD A,$18                ; EAR and MIC into the lead pulse ($C4D2)
  LD (LeadStep+$0007),A
  INC DE
  JP LeadNextEvent

; lead command 5: the lead pulses go silent
;
; Used by the routine at LeadCmd5.
LeadOff:
  POP HL
  XOR A
  LD (LeadStep+$0007),A
  INC DE
  JP LeadNextEvent

; jump to entry A of the 3-byte JP table that follows the caller's CALL
;
; Called with A = the command (below 9) from BassCommand / LeadCommand; it pops
; its own return address (the table) and jumps to table + 3 * A, so the handler
; returns to nobody: each jumps back to the voice's reader.
MusicDispatch:
  LD L,A
  ADD A,A
  ADD A,L
  POP HL                  ; the table, after the CALL
  ADD A,L
  LD L,A
  JR NC,MusicDispatchJump
  INC H
MusicDispatchJump:
  JP (HL)                 ; to the command's JP

; drum track: a hiss every 32 frames (32 0, then 1 $C665)
;
; The drum tracks: records of (frames, kind[, p]) and gotos 1 aa; DrumStep.
; This one plays at the start and at the end of each pass of the tune; docs
; r4.md.
DrumTrackSteady:
  DEFB $20,$00,$01,$65,$C6

; a hiss record (32 0) that no goto reaches
DrumTrackUnused:
  DEFB $20,$00

; drum track: rasp 16, hiss 8, hiss 8, sweep $30 for 32 frames (64 frames),
; loops
;
; Started by the bass track's command 3 $C66C after the four intro riffs.
DrumTrackBeat:
  DEFB $10,$01,$08
  DEFB $00,$08,$00
  DEFB $20,$02,$30
  DEFB $01,$6C,$C6

; the bass track: commands of 3 bytes (drums, pattern calls, the goto back)
;
; 3 $C665, 4 x 2 $C6BD (the riff), 3 $C66C, 2 x 2 $C6CC, 8 x 2 $C6DD, 5 x 2
; $C6CC, 3 $C665, 1 $C678: 5120 frames.
BassTrack:
  DEFB $03,$65,$C6
  DEFB $02,$BD,$C6
  DEFB $02,$BD,$C6
  DEFB $02,$BD,$C6
  DEFB $02,$BD,$C6
  DEFB $03,$6C,$C6
  DEFB $02,$CC,$C6
  DEFB $02,$CC,$C6
  DEFB $02,$DD,$C6
  DEFB $02,$DD,$C6
  DEFB $02,$DD,$C6
  DEFB $02,$DD,$C6
  DEFB $02,$DD,$C6
  DEFB $02,$DD,$C6
  DEFB $02,$DD,$C6
  DEFB $02,$DD,$C6
  DEFB $02,$CC,$C6
  DEFB $02,$CC,$C6
  DEFB $02,$CC,$C6
  DEFB $02,$CC,$C6
  DEFB $02,$CC,$C6
  DEFB $03,$65,$C6
  DEFB $01,$78,$C6

; bass pattern: the 128-frame intro riff on $7C with rests, then $52
;
; Notes are (period, frames), commands 4 / 5 one byte: $7C 16, off, $7C 8, on,
; $7C 16, off, $7C 64, $52 24, on, return.
BassRiff:
  DEFB $7C,$10
  DEFB $05,$7C
  DEFB $08,$04
  DEFB $7C,$10
  DEFB $05,$7C
  DEFB $40,$52
  DEFB $18,$04
  DEFB $06

; bass pattern: $7C $6E $68 $5D twice, 64 frames each (512 frames)
BassWalk:
  DEFB $7C,$40
  DEFB $6E,$40
  DEFB $68,$40
  DEFB $5D,$40
  DEFB $7C,$40
  DEFB $6E,$40
  DEFB $68,$40
  DEFB $5D,$40
  DEFB $06

; bass pattern: $7C in eighths with rests, then the run $8B $93 $A5 $BA $A5 $93
; $8B $7C $8B $93 $A5 (128 frames)
BassRun:
  DEFB $7C,$08
  DEFB $05,$7C
  DEFB $08,$04
  DEFB $7C,$08
  DEFB $05,$7C
  DEFB $08,$04
  DEFB $7C,$08
  DEFB $8B,$08
  DEFB $93,$08
  DEFB $A5,$08
  DEFB $BA,$08
  DEFB $A5,$08
  DEFB $93,$08
  DEFB $8B,$08
  DEFB $7C,$08
  DEFB $8B,$08
  DEFB $93,$08
  DEFB $A5,$08
  DEFB $06

; the lead track: pattern calls, two long notes, the goto back
;
; 4 x riff $C789, 4 x phrase $C7AA, off, $C7AA, on, 5 x $C7C5, then $C7D2 /
; $C7C5 three times in turns, $3E 32, $37 32, 2 x $C7AA, 4 x the scale $C7DF, 4
; x $C789, 8 x $C7C5, 4 x $C789, 1 $C702: 5120 frames.
LeadTrack:
  DEFB $02,$89,$C7
  DEFB $02,$89,$C7
  DEFB $02,$89,$C7
  DEFB $02,$89,$C7
  DEFB $02,$AA,$C7
  DEFB $02,$AA,$C7
  DEFB $02,$AA,$C7
  DEFB $02,$AA,$C7
  DEFB $05,$02,$AA
  DEFB $C7,$04,$02
  DEFB $C5,$C7,$02
  DEFB $C5,$C7,$02
  DEFB $C5,$C7,$02
  DEFB $C5,$C7,$02
  DEFB $C5,$C7,$02
  DEFB $D2,$C7,$02
  DEFB $C5,$C7,$02
  DEFB $D2,$C7,$02
  DEFB $C5,$C7,$02
  DEFB $D2,$C7,$02
  DEFB $C5,$C7,$3E
  DEFB $20,$37,$20
  DEFB $02,$AA,$C7
  DEFB $02,$AA,$C7
  DEFB $02,$DF,$C7
  DEFB $02,$DF,$C7
  DEFB $02,$DF,$C7
  DEFB $02,$DF,$C7
  DEFB $02,$89,$C7
  DEFB $02,$89,$C7
  DEFB $02,$89,$C7
  DEFB $02,$89,$C7
  DEFB $02,$C5,$C7
  DEFB $02,$C5,$C7
  DEFB $02,$C5,$C7
  DEFB $02,$C5,$C7
  DEFB $02,$C5,$C7
  DEFB $02,$C5,$C7
  DEFB $02,$C5,$C7
  DEFB $02,$C5,$C7
  DEFB $02,$89,$C7
  DEFB $02,$89,$C7
  DEFB $02,$89,$C7
  DEFB $02,$89,$C7
  DEFB $01,$02,$C7

; lead pattern: $37 with rests, then trills $29 / $2E, $37, $3E (128 frames)
LeadRiff:
  DEFB $37,$10
  DEFB $05,$37
  DEFB $08,$04
  DEFB $37,$10
  DEFB $05,$37
  DEFB $08,$04
  DEFB $29,$08
  DEFB $2E,$08
  DEFB $29,$08
  DEFB $2E,$08
  DEFB $29,$08
  DEFB $2E,$08
  DEFB $29,$08
  DEFB $2E,$08
  DEFB $37,$08
  DEFB $3E,$08
  DEFB $06

; lead pattern: the tune's phrase $29 $2E $31 $37 $3E $49 $3E $45 $2E $29 $2E
; $34 $2E (256 frames)
LeadPhrase:
  DEFB $29,$10
  DEFB $2E,$10
  DEFB $31,$10
  DEFB $37,$10
  DEFB $3E,$20
  DEFB $49,$10
  DEFB $3E,$10
  DEFB $45,$20
  DEFB $2E,$20
  DEFB $29,$10
  DEFB $2E,$10
  DEFB $34,$10
  DEFB $2E,$10
  DEFB $06

; lead pattern: $3E $52 $7C twice (64 frames)
LeadArpeggioA:
  DEFB $3E,$10
  DEFB $52,$08
  DEFB $7C,$08
  DEFB $3E,$10
  DEFB $52,$08
  DEFB $7C,$08
  DEFB $06

; lead pattern: $45 $5D $8B twice (64 frames)
LeadArpeggioB:
  DEFB $45,$10
  DEFB $5D,$08
  DEFB $8B,$08
  DEFB $45,$10
  DEFB $5D,$08
  DEFB $8B,$08
  DEFB $06

; lead pattern: the 16-note scale $29 up to $BA (high to low) twice, 4 frames a
; note (128 frames)
LeadScale:
  DEFB $29,$04
  DEFB $2E,$04
  DEFB $34,$04
  DEFB $37,$04
  DEFB $3E,$04
  DEFB $45,$04
  DEFB $49,$04
  DEFB $52,$04
  DEFB $5D,$04
  DEFB $68,$04
  DEFB $6E,$04
  DEFB $7C,$04
  DEFB $8B,$04
  DEFB $93,$04
  DEFB $A5,$04
  DEFB $BA,$04
  DEFB $29,$04
  DEFB $2E,$04
  DEFB $34,$04
  DEFB $37,$04
  DEFB $3E,$04
  DEFB $45,$04
  DEFB $49,$04
  DEFB $52,$04
  DEFB $5D,$04
  DEFB $68,$04
  DEFB $6E,$04
  DEFB $7C,$04
  DEFB $8B,$04
  DEFB $93,$04
  DEFB $A5,$04
  DEFB $BA,$04
  DEFB $06

; cycle the ink of the NETHER EARTH title, one colour every 2 frames
;
; Counts $FD33 0-15 each call; on even counts it paints the attributes of rows
; 1-7, columns 10-21 (the big title printed by $C1E3) with BRIGHT, black paper
; and ink count / 2, so the ink runs through all 8 colours every 16 frames.
; Called every frame by the main menu's HALT loops ($C193, $C1A2) and by
; MenuInterrupt while the tune plays (26 calls over frames 0-26 of work/deep;
; it writes $582A-$58F5).
TitleColourCycle:
  PUSH BC
  PUSH HL
  LD HL,$582A             ; row 1, column 10
  LD A,(TitleColourPhase)            ; the phase, 0-15
  INC A
  AND $0F
  LD (TitleColourPhase),A
  RRCA                    ; odd: nothing this frame
  JR C,TitleColourDone
  OR $40                  ; BRIGHT, ink = phase / 2
  LD BC,$0C07             ; 12 columns, 7 rows
TitleColourRow:
  PUSH BC
TitleColourCell:
  LD (HL),A
  INC HL
  DJNZ TitleColourCell
  LD B,A                  ; to the next row: 12 + 20
  LD A,$14
  CALL AddAToHL
  LD A,B
  POP BC
  DEC C
  JR NZ,TitleColourRow
TitleColourDone:
  POP HL
  POP BC
  RET

; landing on the warbase pad at altitude 15: choose the parts (MenuCursor,
; MenuParts), START ROBOT or EXIT MENU
;
; Used by the routine at PlayLoop.
ConstructionMenu:
  LD IY,Robots            ; the player's robot slots 0-23
  LD DE,$0010
  LD B,$18
FindFreeRobotSlot:
  LD A,(IY+$01)           ; a slot whose cell address high byte is 0 is free
  OR A
  JR Z,OpenConstructionMenu
  ADD IY,DE
  DJNZ FindFreeRobotSlot
  RET                     ; all 24 slots in use: no menu at all
OpenConstructionMenu:
  DI                      ; IY = the free slot: it becomes the preview robot
                          ; and, on START ROBOT, the new robot
  LD HL,StartInterrupt    ; the play interrupt off (StartInterrupt only
                          ; re-enables): the world stands still while the menu
                          ; is open
  LD (Handler),HL
  EI
  CALL ClearScreen        ; clear the screen
  LD B,$08                ; the eight part pictures, bipod at the bottom
  LD DE,$57F0             ; the bottom pixel line of row 23, column 16
PartIconLoop:
  PUSH BC                 ; part k = 8 - B
  PUSH DE
  LD A,$08                ; the part's sprite number for the second facing:
                          ; $D6C8 + 4k + 1
  SUB B
  ADD A,A
  ADD A,A
  INC A
  LD HL,PartSpriteTable
  CALL AddAToHL
  LD A,(HL)               ; the second graphic of that sprite: the pointer at
                          ; $D740 + 4 * number + 2
  ADD A,A
  INC A
  LD HL,SpriteTable+$0058
  CALL TableWord
  LD C,(HL)               ; C = the lines, B = the bytes a line
  INC HL
  LD B,(HL)
  INC HL
  LD A,B                  ; skip the graphic's first line of mask / pixel pairs
  ADD A,A
  CALL AddAToHL
  DEC C                   ; the lines after the first, at most 24 (3 rows)
  LD A,C
  CP $18
  JR C,PartIconDraw
  LD C,$18
PartIconDraw:
  CALL DrawMaskedUp       ; draw upwards from DE, masked
  POP DE
  POP BC
  LD A,E                  ; three character rows up
  SUB $60
  LD E,A
  JR NC,PartIconNext
  LD A,D
  SUB $08
  LD D,A
PartIconNext:
  DJNZ PartIconLoop
  LD BC,$0409             ; the preview's frame: 4 columns x 9 rows from row
                          ; 15, column 0
  LD HL,$59E0
PreviewAttrRow:
  PUSH BC
PreviewAttrCell:
  LD (HL),$46             ; bright yellow
  INC HL
  DJNZ PreviewAttrCell
  LD A,$1C                ; to the next row: 4 + 28
  CALL AddAToHL
  POP BC
  DEC C
  JR NZ,PreviewAttrRow
  CALL PrintInline        ; the menu's text

; PrintInline text: "ROBOT" (double size) at row 0, "CONSTRUCTION" (double
; height) at row 2
;
; Setting $22 = double height, double width; $21 = double height; $00 = normal
; (PrintInline code 4: high nibble the height, low nibble the width).
ConstructionTitleText:
  DEFM $04,"\"",$02,"G",$01,$00,$03,"ROBOT",$01,$02,$02,$04,"!CONSTRUCTION",$04,$00

; PrintInline text: the part names at column 21, ELECTRONICS row 1 down to
; BIPOD row 22, every 3 rows
PartNamesText:
  DEFM $02,"E",$01,$01,$15,"ELECTRONICS",$01,$04,$15,"NUCLEAR",$01,$07,$15,"PHASERS",$01,$0A,$15,"MISSILES",$01,$0D,$15,"CANNON",$01,$10,$15,"ANTI-G"
  DEFM "RAV",$01,$13,$15,"TRACKS",$01,$16,$15,"BIPOD"

; PrintInline text: "EXIT START" / "MENU ROBOT" at rows 21-22, columns 5 and 10
ExitStartText:
  DEFM $01,$15,$05,"EXIT START",$03,"MENU ROBOT"

; PrintInline text: the costs under the names at column 22: 3 20 4 4 2 10 5 3
; (the same numbers as PartCosts)
PartCostsText:
  DEFM $02,"C",$01,$02,$16,"3",$01,$05,$16,"20",$01,$08,$16,"4",$01,$0B,$16,"4",$01,$0E,$16,"2",$01,$11,$16,"10",$01,$14,$16,"5",$01,$17,$16,"3"

; PrintInline text: "-- RESOURCES --" / "-- AVAILABLE --", GENERAL row 9,
; ELECTRONICS-CHASSIS rows 11-16, TOTAL row 18
ResourceNamesText:
  DEFM $04,$00,$02,"F",$01,$06,$00,"-- RESOURCES --",$03,"-- AVAILABLE --",$02,"D",$01,$09,$04,"GENERAL",$01,$0B,$00,"ELECTRONICS",$01
  DEFM $0C,$04,"NUCLEAR",$03,"PHASERS",$01,$0E,$03,"MISSILES",$01,$0F,$05,"CANNON",$01,$10,$04,"CHASSIS",$01,$12,$06,"TOTAL",$00

; reset the preview robot, copy the resources, cursor on BIPOD, nothing chosen
;
; Continues ConstructionMenu after its text. The free slot's +8 is set to 4 and
; +$0D to 0 (the built robot keeps +8 = 4: work/deep frame 360, slot 0 = 16 EF
; 16 00 09 00 00 09 04 11 ...). Resources are copied to MenuResources, which
; the menu spends; MenuCursor = column 2 (the parts), row 0 (bipod); MenuParts
; = 0; ShowRobotDesign paints the part pictures (white when chosen) and draws
; the preview robot; the cursor is painted.
ConstructionMenuSetup:
  LD (IY+$08),$04         ; the preview robot's +8
  LD (IY+$0D),$00
  LD HL,Resources             ; the menu spends a copy
  LD DE,MenuResources
  LD BC,$0007
  LDIR
  CALL PrintMenuResources ; print the copy
  LD HL,$0002             ; column 2 (the parts), row 0 (bipod)
  LD (MenuCursor),HL
  XOR A                   ; nothing chosen
  LD (MenuParts),A
  CALL ShowRobotDesign    ; the part pictures and the preview robot
  LD C,$46                ; the cursor in $46
  CALL PaintMenuCursor

; wait for a control; fire acts on the cursor's item, a direction moves the
; cursor
;
; WaitKey until one of Input bits 0-4. Without fire: MoveMenuCursor ($CB00).
; With fire: column 0 EXIT MENU ($CB8E), column 1 START ROBOT ($CB52), column 2
; toggles the part under the cursor.
;
; Choosing a part: a part already chosen is taken back (RefundPart) and
; cleared. A chassis (bipod, tracks, anti-grav: rows 0-2) replaces the chassis
; already chosen, which is refunded first. A fourth weapon is refused: of
; cannon, missiles, phasers and nuclear at most three ($78 never all set). The
; cost is paid from the part's own resource (PartCosts + 8) and what it lacks
; from the general resource; if the general one cannot pay the rest the part is
; refused (a replaced chassis stays refunded: the robot is left without one).
; Accepted: beep $64; refused or taken back: beep $78. Then it waits for fire
; up and pauses 10 frames.
;
; Experiment (general 10, electronics 1, chassis 2): bipod 3 -> chassis 0,
; general 9; tracks 5 -> bipod refunded, chassis 0, general 7; cannon 2 ->
; general 5; tracks again -> taken back, chassis 2, general 8. With 99 of
; everything: missiles, phasers, then nuclear refused (MenuParts $38).
ConstructionMenuLoop:
  CALL WaitKey            ; a direction or fire
  AND $1F
  JR Z,ConstructionMenuLoop
  LD HL,(MenuCursor)           ; L = the column, H = the part row
  LD A,(Input)            ; no fire: a move
  AND $10
  JP Z,MoveMenuCursor
  LD A,L                  ; column 0: EXIT MENU
  OR A
  JP Z,LeaveConstructionMenu
  DEC A                   ; column 1: START ROBOT
  JP Z,StartRobot
PartToggle:
  LD A,H                  ; E = the part, D = its bit
  LD E,A
  LD B,A
  INC B
  XOR A
  SCF
PartBitLoop:
  RLA
  DJNZ PartBitLoop
  LD D,A
  LD A,(MenuParts)            ; C = the parts chosen
  LD C,A
  AND D                   ; chosen already: take it back
  JR NZ,PartTakeBack
  LD A,E                  ; a chassis (rows 0-2) ...
  CP $03
  JR NC,CheckWeaponCount
  LD A,C                  ; ... and a chassis already chosen: refund that one
                          ; first
  AND $07
  JR Z,CheckWeaponCount
  PUSH DE                 ; E = the chosen chassis' row
  LD E,$FF
FindChosenChassis:
  INC E
  RRCA
  JR NC,FindChosenChassis
  CALL RefundPart         ; its resources back
  LD A,C                  ; no chassis now
  AND $F8
  LD C,A
  LD (MenuParts),A
  POP DE
CheckWeaponCount:
  LD A,C                  ; cannon + missiles + phasers + nuclear all four:
                          ; refused
  OR D
  AND $78
  CP $78
  JP Z,PartRefused
  LD HL,PartCosts         ; B = the part's cost
  LD A,E
  CALL AddAToHL
  LD B,(HL)
  LD HL,PartCosts+$0008   ; the resource it takes first
  LD A,E
  CALL AddAToHL
  LD A,(HL)
  LD HL,MenuResources
  CALL AddAToHL
  LD A,(HL)               ; pay from the part's own resource
  SUB B
  JP NC,PartPaid
  NEG                     ; short by the rest: the general resource pays it
  LD B,A
  LD A,(MenuResources)
  SUB B
  JP C,PartRefused        ; not enough: refused
  LD (MenuResources),A
  XOR A                   ; the own resource is spent to 0
PartPaid:
  LD (HL),A               ; store what is left, choose the part
  LD A,C
  OR D
  LD (MenuParts),A
  LD A,$64                ; the beep of a part accepted
  CALL Beep
  CALL ShowRobotDesign    ; repaint the part pictures and the preview
  CALL PrintMenuResources ; reprint the resources
AcceptFireUp:
  CALL WaitKey            ; wait for fire up
  AND $10
  JR NZ,AcceptFireUp
  JP MenuPause
PartTakeBack:
  CALL RefundPart         ; refund and clear the part
  LD A,C
  XOR D
  LD (MenuParts),A
PartRefused:
  LD A,$78                ; refused or taken back: the low beep
  CALL Beep
  CALL ShowRobotDesign
  CALL PrintMenuResources
RefuseFireUp:
  CALL WaitKey            ; wait for fire up
  AND $10
  JR NZ,RefuseFireUp
  JP MenuPause

; give back the cost of part E to MenuResources, the overflow to the general
; resource
;
; E = the part row. The cost goes back to the part's own resource; whatever
; lifts it above its value when the menu opened (Resources, 7 bytes below
; MenuResources) is what the general resource paid, so it is returned to the
; general one instead. Exact because each own resource has only one part in the
; menu at a time (one chassis, one of each weapon, electronics). Called by
; ConstructionMenuLoop ($CA4C, $CAA4).
RefundPart:
  LD HL,PartCosts         ; B = the part's cost
  LD A,E
  CALL AddAToHL
  LD B,(HL)
  LD HL,PartCosts+$0008   ; the resource it takes first
  LD A,E
  CALL AddAToHL
  LD A,(HL)
  LD HL,MenuResources
  CALL AddAToHL
  LD A,(HL)
  ADD A,B                 ; refund it there
  LD (HL),A
  PUSH HL                 ; B = the same resource when the menu opened
  LD A,L
  SUB $07
  LD L,A
  LD B,(HL)
  POP HL
  LD A,(HL)
  CP B
  RET Z                   ; not above it: done
  RET C
  LD (HL),B               ; above: cap it, the rest goes back to general
  SUB B
  LD B,A
  LD A,(MenuResources)            ; the general resource
  ADD A,B
  LD (MenuResources),A
  RET

; the parts' cost (bipod, tracks, anti-grav, cannon, missiles, phasers,
; nuclear, electronics), then the resource each takes first (an index into
; Resources)
PartCosts:
  DEFB $03,$05,$0A,$02,$04,$04,$14,$03
  DEFB $06,$06,$06,$05,$04,$03,$02,$01

; right / left change the column (0-2), down / up the part row (0-7) in column
; 2
;
; HL = MenuCursor (L the column, H the row), Input as WaitKey left it. Right
; adds 1 to the column, left subtracts 1; out of 0-2 nothing moves. Only
; without right / left: in the parts column up adds 1 to the row (towards
; ELECTRONICS, up the screen), down subtracts 1; out of 0-7 nothing moves. A
; move repaints the old item in $45, the new one in $46 and clicks (beep $14);
; every press ends in the 10-frame pause (MenuPause).
MoveMenuCursor:
  LD A,(Input)            ; right / left?
  AND $03
  JR Z,CursorUpDown
  LD C,A
  LD A,L
  RR C                    ; right: the next column
  JR NC,CursorLeft
  INC A
CursorLeft:
  RR C                    ; left: the previous one
  JR NC,CursorColumnCheck
  DEC A
CursorColumnCheck:
  CP $03                  ; 0-2 only ($FF too is refused)
  JR NC,MenuPause
  LD L,A
  JP CursorMoved
CursorUpDown:
  LD A,(Input)            ; down / up, only in the parts column
  RRCA
  RRCA
  LD C,A
  LD A,L
  CP $02
  JR NZ,MenuPause
  LD A,H
  RR C                    ; down: the row below (a lower part)
  JR NC,CursorUp
  DEC A
CursorUp:
  RR C                    ; up: the row above
  JR NC,CursorRowCheck
  INC A
CursorRowCheck:
  CP $08                  ; 0-7 only
  JR NC,MenuPause
  LD H,A
CursorMoved:
  PUSH HL                 ; the old item back to $45
  LD C,$45
  CALL PaintMenuCursor
  POP HL
  LD (MenuCursor),HL           ; the new cursor in $46
  LD C,$46
  CALL PaintMenuCursor
  LD A,$14                ; a click
  CALL Beep

; 10 frames, then back to ConstructionMenuLoop
;
; The pause after every press (moves too); a shorter press falls into it and is
; lost, WALKTHROUGH 6.
MenuPause:
  LD B,$0A
MenuPauseLoop:
  HALT
  DJNZ MenuPauseLoop
  JP ConstructionMenuLoop

; START ROBOT: needs a chassis and a weapon; spend the resources, place the
; robot at the warbase's door, leave
;
; Refused (back to the menu after the pause) without a chassis (MenuParts bits
; 0-2) or without a weapon (bits 3-6); electronics alone count as neither.
; Otherwise MenuResources become Resources, the free slot becomes a robot of
; ours (+$0A = 0) at column ShipX, row ShipY + 4 (PlaceRobot writes +0 to +4
; and marks the map cell), +7 = MenuParts, and a rising chirp plays (Beep with
; $50 down to $14 by 5). Then LeaveConstructionMenu. In work/deep the robot
; built at frame 356 sits at (22, 9): the pad at (22, 5) plus 4 rows.
StartRobot:
  LD A,(MenuParts)
  LD C,A                  ; no chassis: refused
  AND $07
  JR Z,MenuPause
  LD A,C                  ; no weapon: refused
  AND $78
  JR Z,MenuPause
  LD HL,MenuResources             ; the menu's spending becomes real
  LD DE,Resources
  LD BC,$0007
  LDIR
  LD HL,(ShipX)           ; the robot stands 4 rows below the ship (the pad)
  LD A,(ShipY)
  ADD A,$04
  LD B,A
  LD (IY+$0A),$00         ; not in the menu, not under direct control
  CALL PlaceRobot         ; place it on the map
  LD A,(MenuParts)            ; its parts
  LD (IY+$07),A
  LD B,$50                ; the chirp: $50 down to $14, a shorter period each
                          ; beep
BuildChirp:
  LD A,B
  CALL Beep
  LD A,B
  SUB $05
  LD B,A
  CP $14
  JR NC,BuildChirp
; This entry point is used by the routine at ConstructionMenuLoop.
LeaveConstructionMenu:
  LD A,$C8                ; a long low beep
  CALL Beep
  LD A,$05                ; $FD30 = 5: the ship climbs 5 game turns on its own,
                          ; so it does not sink straight back into the menu
  LD (ClimbTurns),A
  PUSH IY                 ; the play screen redrawn
  CALL ClearViewBuffer
  CALL DrawPlayScreen
  POP IY
  LD HL,PlayInterrupt     ; the play interrupt again
  LD (Handler),HL
  RET

; paint the item under MenuCursor with attribute C ($46 the cursor, $45 the
; rest)
;
; Column 0 / 1: two rows of 5 cells, EXIT MENU at rows 21-22 columns 4-8, START
; ROBOT columns 10-14. Column 2: the part's name, 11 cells from column 21 of
; row 22 - 3 * row (BIPOD row 22 up to ELECTRONICS row 1). Called by
; ConstructionMenuSetup and MoveMenuCursor.
PaintMenuCursor:
  LD HL,(MenuCursor)
  LD A,L                  ; the parts column?
  CP $02
  JR Z,PartNameCursor
  ADD A,A                 ; $5AA4 + 6 * column: row 21
  ADD A,L
  ADD A,A
  ADD A,$A4
  LD L,A
  LD H,$5A
  LD B,$05
  CALL FillAttributes
  LD A,L                  ; the same columns on row 22
  ADD A,$1B
  LD L,A
  LD B,$05
  JR FillAttributes
PartNameCursor:
  LD A,H                  ; row 22 - 3 * part, column 21, 11 cells
  ADD A,A
  ADD A,H
  NEG
  ADD A,$16
  ADD A,A
  ADD A,A
  ADD A,A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD DE,$5815
  ADD HL,DE
  LD B,$0B

; write C into B bytes from HL
;
; Also used by PaintMenuItem.
FillAttributes:
  LD (HL),C
  INC HL
  DJNZ FillAttributes
  RET

; print MenuResources (two digits each) and their total
;
; The seven values at column 13: GENERAL row 9, ELECTRONICS-CHASSIS rows 11-16
; (PrintMenuResource, two digits: a value above 99 prints a wrong tens digit,
; e.g. 200 shows "D0"); the sum (HL) at row 18, column 12, three digits by
; PrintNumber3 (the tail $CC03).
PrintMenuResources:
  LD DE,MenuResources             ; HL = the total
  LD HL,$0000
  LD C,$09                ; C = the row: 9 for GENERAL
  LD B,$07
PrintResourceLoop:
  LD A,(DE)
  CALL AddAToHL
  LD A,(DE)               ; print the value at row C
  CALL PrintMenuResource
  INC DE
  INC C
  LD A,B                  ; a blank row after GENERAL
  CP $07
  JR NZ,PrintResourceNext
  INC C
PrintResourceNext:
  DJNZ PrintResourceLoop
  CALL PrintInline        ; the total at row 18, column 12

; PrintInline text: AT 18,12
TotalPosition:
  DEFM $01,$12,$0C,$00

; Construction menu: print the total of the costs (the tail of $CBE0)
;
; Runs after the inline position string at $CBFF ((18,12)): E = $20 (blank
; leading zeros) and PrintNumber3 prints HL, the sum of the seven MenuResources
; that $CBE0 added up. 29 runs in the deep recording, one per menu redraw of
; the resource list.
PrintMenuTotal:
  LD E,$20                ; blank the leading zeros
  JP PrintNumber3         ; three digits of HL

; Construction menu: print one resource value A at row C, column 13
;
; Called by $CBE0 for each of the seven MenuResources (rows 9, 11-16). Patches
; the row byte of the position string after the CALL ($CC11), prints the
; position, then PrintMenuResourceValue prints A as two digits. Preserves BC,
; DE, HL (203 calls in the deep recording).
PrintMenuResource:
  PUSH AF
  LD A,C                  ; the row into the string below
  LD (MenuResourcePos+$0001),A
  CALL PrintInline

; Inline string: position (row patched, column 13)
;
; PrintInline bytes: 1 Y X with Y written by $CC0A, then 0 (end).
MenuResourcePos:
  DEFB $01,$00,$0D,$00

; Construction menu: print A as two digits, registers kept (the tail of $CC08)
PrintMenuResourceValue:
  POP AF
  PUSH BC
  PUSH DE
  PUSH HL
  CALL PrintNumber2       ; two digits, blank leading zero
  POP HL
  POP DE
  POP BC
  RET

; Construction menu: highlight the chosen parts and draw the robot preview
;
; IY = the robot record being designed. Paints the attributes of the parts list
; (columns 16-19, three rows a part, 24 rows from the top): $47 (bright white)
; for a part chosen in MenuParts, $06 (yellow) otherwise, bit 7 (electronics)
; at the top. Then clears the view buffer, writes MenuParts to +$07, draws the
; robot stack into the buffer at map position row 10, column 7 (DrawRobot, base
; height +$0D = 0) and stores the stack's total height (the sum of the part
; heights $D7B4) in +$09: the height the ship lands on. Finally copies 4 bytes
; x 72 lines of the buffer from $6168 (buffer row 82, column 0) to the screen
; at $48E0 (character row 15, column 0). Called from $C9E7 (7) and $CA0F (22)
; after each change of the parts.
ShowRobotDesign:
  LD HL,$5810             ; the attributes of part row 0 (electronics, bit 7)
  LD A,(MenuParts)
  LD C,A
  LD B,$08
PartRowLoop:
  LD E,$06                ; E = $06: not chosen
  RL C                    ; the next part bit into carry, highest first
  JR NC,l_CC30
  LD E,$47                ; chosen: bright white
l_CC30:
  PUSH BC
  LD BC,$0403             ; 4 cells by 3 rows
l_CC34:
  PUSH BC
PartCellLoop:
  LD (HL),E
  INC HL
  DJNZ PartCellLoop
  LD A,$1C                ; to the next attribute row (32 - 4)
  CALL AddAToHL
  POP BC
  DEC C
  JR NZ,l_CC34
  POP BC
  DJNZ PartRowLoop
  CALL ClearViewBuffer    ; empty view buffer
  LD A,(MenuParts)
  LD (IY+$07),A           ; the robot's parts
  LD DE,$0A07             ; row 10, column 7 of the view
  CALL DrawRobot
  LD A,($CF3F)            ; the stack's height after the last part
  LD (IY+$09),A           ; +$09: the robot's height (the landing test adds
                          ; +$0D)
  LD BC,$0448             ; 4 bytes, 72 lines
  LD DE,ViewBuffer+$0668  ; buffer row 82, column 0
  LD HL,$48E0             ; screen: character row 15, column 0
PreviewLineLoop:
  PUSH BC
  PUSH HL
l_CC65:
  LD A,(DE)
  LD (HL),A
  INC DE
  INC HL
  DJNZ l_CC65
  LD A,E                  ; the next buffer row (20 bytes in all)
  ADD A,$10
  LD E,A
  LD A,D
  ADC A,$00
  LD D,A
  POP HL
  CALL NextScreenLine     ; the next screen line
  POP BC
  DEC C
  JR NZ,PreviewLineLoop
  RET

; Put robot IY at map column HL, row B: record, map bit 6, radar dot
;
; Writes +$02/+$03 = HL (x), +$04 = B (y), +$00/+$01 = the map cell (MapCell)
; and sets the cell's bit 6 (an object to draw). Then toggles the robot's radar
; dot (ToggleRadarDot, side = bit 7 of +$0A: 0 the player's buffer $D800, 1 the
; enemy's $D900). The caller clears the old cell and toggles the old dot.
; Called by the robot step $B0FA (9652 times in the deep recording), the enemy
; spawn $B7F4 (22) and START ROBOT in $CB52 (7).
PlaceRobot:
  LD (IY+$02),L
  LD (IY+$03),H
  LD (IY+$04),B
  PUSH HL                 ; keep x for the radar
  LD A,B
  CALL MapCell            ; HL = $DD00 + $200*y + x
  LD (IY+$00),L
  LD (IY+$01),H
  SET 6,(HL)              ; bit 6: draw an object here
  POP HL
  LD C,(IY+$04)           ; C = y
  LD A,(IY+$0A)           ; B = side: +$0A bit 7 (enemy)
  RLCA
  AND $01
  LD B,A
  JP ToggleRadarDot       ; XOR the 2x2 dot into the side's radar

; HL = the map cell under the ship (ShipX, ShipY)
;
; Falls into MapCell. Used by $A62D, $B01D (clear the ship's bit 7) and $B024
; (set it).
ShipCell:
  LD HL,(ShipX)
  LD A,(ShipY)

; HL = the map cell of column HL, row A: $DD00 + $200*A + HL
;
; H += 2*A + $DD. The map lookup of the whole game (127962 calls in the deep
; recording: the main loop $AD90, CheckShipMove, the robot code, PlaceRobot,
; DrawMover).
MapCell:
  ADD A,A
  ADD A,$DD
  ADD A,H
  LD H,A
  RET

; Beeper tone: 256 half-periods, A = the half-period delay (bigger is lower)
;
; B = A is the DJNZ delay of each half-period, C = 0 counts 256 speaker toggles
; (bit 4 of port $FE, border black). BC is kept. Used for menu clicks and
; confirmations: ListMenu (83), $CB52 (98), $CB00 (42), $CA0F (22), the robot
; menu $A7CD, $ABC8.
Beep:
  PUSH BC
  LD B,A
  XOR A                   ; C = 0: 256 toggles
  LD C,A
BeepLoop:
  PUSH BC
  XOR $10                 ; flip the speaker bit
  OUT ($FE),A
BeepDelay:
  DJNZ BeepDelay
  POP BC
  DEC C
  JR NZ,BeepLoop
  POP BC
  RET

; Draw the isometric view: background, objects, copy to the screen
;
; DrawViewBackground clears the buffer $5B00 and paints the corners outside the
; map, DrawMapObjects draws every block, building, robot, shot and the ship,
; CopyViewToScreen puts the 160x160 buffer on the screen. Once per game turn:
; 3423 times in the 36046 frames of the deep recording (the play loop waits for
; 10 frames a turn, $AE1D). About 578000 T-states a call, 8.3 frames: the
; reason a turn is 10 frames.
DrawView:
  CALL DrawViewBackground
  CALL DrawMapObjects
  JP CopyViewToScreen

; Draw the 32 x 16 cells of the view back to front into the view buffer
;
; Clears the deferred ship position $FD11 and draws the ship's shadow (sprite
; 1, height 0) at the ship's view column (ShipX - ViewX) and row ShipY. Then
; walks the visible part of the map along diagonals: the diagonal x - y = 31
; first down to x - y = -15, each from row 0 (x, y) to (x+15, y+15) or the
; right edge; cells left of the view (x < 0) and cells that are 0 are skipped,
; every other cell goes to DrawCell with HL = the cell, D = row, E = view
; column. The order is the painter's order of the projection (DrawSprite): a
; later cell is nearer the viewer. About 442000 T-states a call with the
; sprites it draws (1512 M in the deep recording), the heaviest part of the
; play.
DrawMapObjects:
  LD HL,$0000             ; no deferred ship yet
  LD (ShipDrawPos),HL
  XOR A                   ; height 0 for the shadow
  LD (DrawSprite+$0012),A
  LD HL,(ShipX)
  LD DE,(MapView)           ; DE = MapView with D reduced to its low bit: only
                          ; the low byte of the difference matters
  LD A,D
  AND $01
  LD D,A
  XOR A
  SBC HL,DE
  LD E,L                  ; E = the ship's column in the view
  LD A,(ShipY)
  LD D,A
  LD A,$01                ; sprite 1: the ship's shadow on the ground
  CALL DrawSprite
  LD HL,(MapView)           ; HL = the cell 32 columns right of the view's left
                          ; edge
  LD A,$20
  CALL AddAToHL
  LD DE,$0020             ; D = row 0, E = column 32
DiagonalLoop:
  DEC HL                  ; start the next diagonal one column further left
  DEC E
  PUSH HL
  PUSH DE
DiagonalCellLoop:
  LD A,E
  OR A
  JP M,l_CD01             ; left of the view: nothing to draw
  LD A,(HL)
  OR A
  CALL NZ,DrawCell        ; an occupied cell
l_CD01:
  INC H                   ; down the diagonal: row + 1, column + 1
  INC H
  INC HL
  INC D
  INC E
  LD A,D
  CP $10                  ; past row 15
  JR NC,DiagonalDone
  LD A,E
  CP $20                  ; past column 31
  JR NZ,DiagonalCellLoop
DiagonalDone:
  LD A,E
  POP DE
  POP HL
  CP $01                  ; the last diagonal ends at column 1 (it started at
                          ; column -15)
  JR NZ,DiagonalLoop
  RET

; Draw map cell HL (A = its byte) at view row D, column E
;
; Cell bits: 0-4 the block type, 5 the right half of a two-cell block (nothing
; drawn), 6 an object (building, robot or shot, or a robot / shot deferred to
; this cell), 7 the ship, or the ship deferred to this cell. A block (bit 5
; clear, type not 0) is drawn as sprite = type at height 0. Bit 6 calls
; DrawCellObject. Bit 7 handles the ship: on the first bit-7 cell ($FD11 = 0,
; the ship's own cell, set by $B024) it looks for the cell drawn last among the
; neighbouring blocks (FindLatestBlock) and the neighbouring objects
; (CheckObjectNeighbour at (x-1,y-1), (x-1,y), (x-1,y+1), (x,y+1), (x+1,y+1)).
; If that is the ship's cell the ship is drawn at once, otherwise bit 7 is set
; on that later cell and the ship's view position is kept in $FD11; when the
; walk reaches it, bit 7 is cleared again and the ship (sprite 0) is drawn at
; the kept position, at height Altitude. So the ship is never painted over by a
; neighbour. In the deep recording the ship was deferred in 2828 of the 3423
; view draws.
DrawCell:
  PUSH HL
  PUSH DE
  PUSH AF
  BIT 5,A                 ; bit 5: the right half of a block, no sprite of its
                          ; own
  JR NZ,l_CD2B
  AND $1F                 ; the block type is the sprite number
  JR Z,l_CD2B
  LD HL,DrawSprite+$0012  ; height 0
  LD (HL),$00
  CALL DrawSprite
l_CD2B:
  POP AF
  POP DE
  POP HL
  BIT 6,A                 ; bit 6: an object stands or is deferred here
  CALL NZ,DrawCellObject
  LD A,(HL)
  BIT 7,A                 ; bit 7: the ship
  RET Z
  LD BC,(ShipDrawPos)           ; already deferred?
  LD A,B
  OR C
  JR NZ,ShipDeferred
  PUSH DE                 ; DE = the latest cell found so far: this one
  LD D,H
  LD E,L
  CALL FindLatestBlock    ; the blocks around the ship's cell
  PUSH HL
  DEC HL                  ; (x-1, y-1)
  DEC H
  DEC H
  CALL CheckObjectNeighbour
  INC H                   ; (x-1, y)
  INC H
  CALL CheckObjectNeighbour
  INC H                   ; (x-1, y+1) unless past row 15
  INC H
  LD A,H
  CP $FD
  JR NC,l_CD63
  CALL CheckObjectNeighbour
  INC HL                  ; (x, y+1)
  CALL CheckObjectNeighbour
  INC HL                  ; (x+1, y+1)
  CALL CheckObjectNeighbour
l_CD63:
  POP HL                  ; nothing later than the ship's own cell?
  LD A,D
  CP H
  JR NZ,ShipDefer
  LD A,E
  CP L
  JR NZ,ShipDefer
  POP DE
  JR ShipDrawNow          ; draw the ship now
ShipDefer:
  EX DE,HL                ; mark the later cell with bit 7, keep the ship's
                          ; view position
  SET 7,(HL)
  EX DE,HL
  POP DE
  LD (ShipDrawPos),DE           ; $FD11 = column, $FD12 = row
  RET
ShipDeferred:
  RES 7,(HL)              ; the deferred cell: clear its mark and draw at the
                          ; kept position
  PUSH HL
  PUSH DE
  LD D,B
  LD E,C
  JR ShipDraw
ShipDrawNow:
  PUSH HL
  PUSH DE
ShipDraw:
  LD A,(Altitude)            ; sprite 0 at height Altitude
  LD (DrawSprite+$0012),A
  XOR A
  CALL DrawSprite
  POP DE
  POP HL
  RET

; Ship: an object at HL counts, and so do the blocks around it
;
; Used for the ship's neighbours: if HL has bit 6 it competes (KeepLaterCell)
; and then falls into FindLatestBlock for the blocks around that object.
CheckObjectNeighbour:
  BIT 6,(HL)
  RET Z
  CALL KeepLaterCell

; DE = the cell drawn last among DE and the blocks next to HL
;
; Checks the blocks (bit 5 clear, type not 0) at (x-1,y+1), (x,y+1) (both only
; when y+1 < 16), (x-1,y) and (x+1,y+1) (y+1 < 16) of cell HL with
; CheckBlockNeighbour; (x+1,y) is passed over (HL only goes through it). Those
; are the cells whose sprites can overlap a robot, a shot or the ship standing
; at HL. HL is kept. Used by DrawCell (the ship) and DrawMover (robots, shots).
FindLatestBlock:
  PUSH HL
  DEC HL                  ; (x-1, y+1)
  INC H
  INC H
  LD A,H                  ; row 16 is past the map ($DD00 + $200*16 = $FD00)
  CP $FD
  JR NC,l_CDA7
  CALL CheckBlockNeighbour
  INC HL                  ; (x, y+1)
  CALL CheckBlockNeighbour
  DEC HL
l_CDA7:
  DEC H                   ; (x-1, y)
  DEC H
  CALL CheckBlockNeighbour
  INC HL                  ; through (x+1, y) to (x+1, y+1), unless past row 15
  INC HL
  INC H
  INC H
  LD A,H
  CP $FD
  CALL C,CheckBlockNeighbour
  POP HL
  RET

; A block at HL competes for the latest cell
;
; Bit 5 set (the right half of a block) or type 0 (empty): nothing. Otherwise
; falls into KeepLaterCell.
CheckBlockNeighbour:
  BIT 5,(HL)
  RET NZ
  LD A,(HL)
  AND $1F
  RET Z

; DE = HL if map cell HL is drawn after cell DE
;
; The drawing order of DrawMapObjects: diagonals by falling x - y, along a
; diagonal by rising x. A = (yHL - yDE) + (xDE - xHL) (columns by the low
; bytes, rows from the high bytes: (H - $DD) / 2). A > 0: HL's diagonal is
; later; A = 0: same diagonal, later when xHL > xDE.
KeepLaterCell:
  LD A,E
  SUB L                   ; C = xDE - xHL
  LD C,A
  LD A,D                  ; B = yDE
  SUB $DD
  SRL A
  LD B,A
  LD A,H                  ; A = yHL - yDE + xDE - xHL
  SUB $DD
  SRL A
  SUB B
  ADD A,C
  RET M                   ; HL drawn earlier
  JR NZ,l_CDD5
  LD A,C                  ; same diagonal: the bigger column is later
  OR A
  RET P
l_CDD5:
  LD D,H                  ; HL is later: it becomes the latest cell
  LD E,L
  RET

; Z: IY the robot record standing on map cell HL, B = 48 - its slot (slots 0-23
; the player's)
;
; Used by the routines at PlayLoop, GameTurnEnd, ObjectTop, ScanLane, MoveShot,
; NuclearBlast and DrawCellObject.
FindRobot:
  LD IY,Robots
  LD B,$30
FindRobotLoop:
  LD A,(IY+$00)           ; compare +$00/+$01 with HL
  CP L
  JR NZ,l_CDE9
  LD A,(IY+$01)
  CP H
  RET Z
l_CDE9:
  PUSH DE                 ; the next 16-byte record
  LD DE,$0010
  ADD IY,DE
  POP DE
  DJNZ FindRobotLoop
  OR $01                  ; none: NZ
  RET

; Z: IY the building record (Buildings) on map cell HL
;
; Used by the routines at PlayLoop, KeepHigher, RemoveBuilding and
; DrawCellObject.
FindBuilding:
  LD IY,Buildings
  LD B,$38
FindBuildingLoop:
  LD A,(IY+$00)           ; compare the cell address with HL
  CP L
  JR NZ,l_CE06
  LD A,(IY+$01)
  CP H
  RET Z
l_CE06:
  PUSH DE                 ; the next 3-byte record
  LD DE,$0003
  ADD IY,DE
  POP DE
  DJNZ FindBuildingLoop
  OR $01                  ; none: NZ
  RET

; Draw the object of map cell HL (bit 6): a robot, a building or a shot
;
; A robot whose +$00/+$01 is HL goes to DrawMover. A building record goes to
; its sprite: BuildingSprites[type] at height BuildingHeights[type]. Otherwise
; the five shot records at $D7D3 (9 bytes: +$00/+$01 cell, +$02/+$03 x, +$04 y,
; +$05 direction, +$06 range, +$07 weapon 1-3, +$08 height) are searched; a
; match goes to DrawMover. Nothing found: nothing drawn. 8330 calls in the deep
; recording: 1485 robots, 6845 buildings, the shot search never ran (no shot
; stood in the view while it was drawn; the shot path is read from the code and
; from the shot records at frame 20000).
DrawCellObject:
  CALL FindRobot
  JR Z,DrawMover          ; a robot here
  CALL FindBuilding
  JR Z,DrawBuilding       ; a building here
  LD IY,Shots             ; the five shot records, 9 bytes each
  LD B,$05
ShotSearchLoop:
  LD A,(IY+$00)
  CP L
  JR NZ,l_CE2E
  LD A,(IY+$01)
  CP H
  JR Z,DrawMover          ; a shot here
l_CE2E:
  PUSH DE
  LD DE,$0009
  ADD IY,DE
  POP DE
  DJNZ ShotSearchLoop
  RET
DrawBuilding:
  PUSH HL                 ; building type C: sprite and height from the tables
                          ; below
  PUSH DE
  LD A,(IY+$02)
  LD C,A
  LD HL,BuildingHeights   ; the height of the type
  CALL AddAToHL
  LD A,(HL)
  LD (DrawSprite+$0012),A
  LD A,C
  LD HL,BuildingSprites   ; the sprite of the type
  CALL AddAToHL
  LD A,(HL)
  CALL DrawSprite
  POP DE
  POP HL
  RET

; The sprite of each building type
;
; Index = the Buildings type: 0 the player's warbase pad $2C (a crate),
; factories 1 electronics $28, 2 nuclear $25, 3 phasers $23, 4 missiles $20, 5
; cannon $1D, 6 chassis $17 (each the robot part of its product, facing down:
; $16 + the parts table $D6C8), 7 and 8 the flags $2A and $2B. In the deep
; recording at frame 20000 the type 7 / 8 records stand two columns left of a
; factory (four of the player's warbase pad): a factory's owner flag; 7 the
; player's, 8 the enemy's.
BuildingSprites:
  DEFB $2C,$28,$25,$23,$20,$1D,$17,$2A,$2B

; The height each building sprite is drawn at
;
; Type 0 at $13, the six factory signs at $0F (on the factory's roof blocks),
; the flags at $1A.
BuildingHeights:
  DEFB $13,$0F,$0F,$0F,$0F,$0F,$0F,$1A,$1A

; Draw robot or shot IY found at cell HL (view row D, column E), after the
; blocks that overlap it
;
; Robots and shots keep their real position in +$02/+$03 (x) and +$04 (y) and
; in +$00/+$01 the cell the walk draws them at. At the real cell
; FindLatestBlock looks for a later neighbouring block; if there is one, the
; object is moved there (bit 6 set on it, +$00/+$01 = it) and nothing is drawn
; yet. When the walk reaches the deferred cell, +$00/+$01 is set back to the
; real cell, the deferred cell's bit 6 is cleared and the view position is
; walked back from the deferred cell to the real one (x first, then y), and
; DrawMoverSprite draws the object there. So a robot is drawn after (over)
; every block whose sprite overlaps it. In the deep recording 1485 robot draws
; reached here; 18 were deferred (each drawn later at the walked-back
; position), 1449 drawn at once. No shot reached here: see DrawCellObject.
DrawMover:
  PUSH DE
  LD D,H
  LD E,L
  CALL FindLatestBlock    ; a later block next to it?
  LD A,D
  CP H
  JR NZ,MoverDefer
  LD A,E
  CP L
  JR Z,MoverDeferred
MoverDefer:
  EX DE,HL                ; defer: mark the later cell and point the record at
                          ; it
  SET 6,(HL)
  LD (IY+$00),L
  LD (IY+$01),H
  EX DE,HL
  POP DE
  RET
MoverDeferred:
  POP DE                  ; reached: the real cell from +$02-$04
  PUSH DE
  EX DE,HL
  LD L,(IY+$02)
  LD H,(IY+$03)
  LD A,(IY+$04)
  CALL MapCell
  LD A,D
  CP H
  JR NZ,l_CE9C
  LD A,E
  CP L
  JR NZ,l_CE9C
  POP DE                  ; this is the real cell: draw here
  JR DrawMoverSprite
l_CE9C:
  LD (IY+$00),L           ; back to the real cell; clear the deferred mark
  LD (IY+$01),H
  LD B,H
  LD C,L
  EX DE,HL
  POP DE
  PUSH DE
  PUSH HL
  RES 6,(HL)
  DEC HL                  ; the view column: from the deferred column - 1 up to
                          ; the real one
  DEC E
MoverColumnLoop:
  LD A,C
  CP L
  JR Z,MoverRowLoop
  INC HL
  INC E
  JR MoverColumnLoop
MoverRowLoop:
  LD A,B                  ; the view row: up to the real row
  CP H
  JR Z,l_CEBD
  DEC H
  DEC H
  DEC D
  JR MoverRowLoop
l_CEBD:
  CALL DrawMoverSprite    ; draw at the real position
  POP HL
  POP DE
  RET

; Draw IY: a robot record ($DA00 up) as a stack of parts, a shot as one sprite
;
; Records at $D800 and up are robots: DrawRobot. A shot (records at $D7D3) is
; sprite $2B + 2 * weapon (+$07: 1 cannon, 2 missiles, 3 phasers) + 1 when it
; flies down or up (+$05 = 4 or 8), at height +$08: $2D/$2E a cannon shell,
; $2F/$30 a missile trail, $31/$32 a phaser beam (the sprite pictures in
; start.bin). The shot branch did not run in the recordings.
DrawMoverSprite:
  PUSH IY                 ; IY's high byte tells robots from shots
  POP BC
  LD A,B
  CP $D8
  JP NC,DrawRobot
  PUSH HL
  PUSH DE
  LD C,(IY+$07)
  LD A,(IY+$05)
  CP $03                  ; carry: direction 4 or 8 (along the rows)
  CCF
  RL C                    ; C = 2 * weapon + axis
  LD A,(IY+$08)           ; the shot's height
  LD (DrawSprite+$0012),A
  LD A,$2B
  ADD A,C
  CALL DrawSprite
  POP DE
  POP HL
  RET

; Draw robot IY at view row D, column E: its parts bottom up
;
; Height starts at +$0D (the ground under the robot, 0 in the construction
; menu); for each bit of the parts mask +$07 from bit 0 (bipod, tracks,
; anti-grav, cannon, missiles, phasers, nuclear, electronics) DrawRobotPart
; draws the part and raises the height. Called by DrawMoverSprite and
; ShowRobotDesign.
DrawRobot:
  PUSH HL
  LD C,(IY+$07)
  LD B,$08
  LD A,(IY+$0D)           ; the base height
  LD (DrawSprite+$0012),A
RobotPartLoop:
  RR C
  CALL C,DrawRobotPart    ; this part fitted?
  DJNZ RobotPartLoop
  POP HL
  RET

; Draw part 8 - B of robot IY facing +$08, then raise the height
;
; Sprite = $16 + the parts table $D6C8[4 * part + direction], direction = the
; number of the lowest set bit of +$08 (0 right, 1 left, 2 down, 3 up, the
; Input bits). After drawing, the height ($CF3F) grows by the part's height
; $D7B4[part]: bipod 11, tracks 7, anti-grav 8, cannon 6, missiles 6, phasers
; 7, nuclear 7, electronics 7.
DrawRobotPart:
  PUSH BC
  PUSH DE
  LD A,$08                ; A = the part number
  SUB B
  PUSH AF
  LD C,(IY+$08)
  LD B,$FF                ; B = the direction number
DirectionLoop:
  INC B
  RR C
  JR NC,DirectionLoop
  ADD A,A                 ; 4 directions a part
  ADD A,A
  ADD A,B
  LD HL,PartSpriteTable
  CALL AddAToHL
  LD A,(HL)
  ADD A,$16               ; the part sprites start at $16
  CALL DrawSprite
  POP AF
  POP DE
  POP BC
  LD HL,PartHeights       ; the part's height
  CALL AddAToHL
  LD A,($CF3F)
  ADD A,(HL)
  LD (DrawSprite+$0012),A
  RET

; Draw sprite A at view row D, column E, height ($CF3F) into the view buffer
;
; The isometric projection: the half-byte column L = 2E + D - 24, the pixel row
; of the sprite's bottom line H = 8D + 100 - 4E - height. So a step along x
; moves 8 pixels right and 4 up, a step along y 4 right and 8 down. The sprite
; table $D6E8 holds two words a sprite (A*2 + 1 for an odd half-byte column:
; the image shifted by 4 pixels). A sprite: rows, width in bytes, then for each
; row bottom up (mask, pixels) byte pairs; drawn by AND mask, OR pixels into
; the 20-byte rows of the buffer $5B00, upwards. Clipping: right of column 19
; or a bottom line past row $E1: nothing; bottom lines $A0-$E1 skip the rows
; below the buffer; a negative column skips the left bytes of each row ($CFAF),
; a sprite past column 19 the right bytes; the top stops at $5B00. 116709
; calls, 978 M T-states in the deep recording.
DrawSprite:
  LD C,A
  RLC E                   ; E * 2
  LD A,E
  ADD A,D                 ; L = 2E + D - 24: the column in half bytes
  SUB $18
  LD L,A
  RLC E                   ; E * 4
  LD A,D                  ; H = 8D + 100 - 4E - height
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,$64
  SUB E
  SUB $00                 ; the height: the operand $CF3F, written by the
                          ; callers
  LD H,A
  LD A,C                  ; the sprite number, 0-$3F
  AND $3F
  SRA L                   ; byte column; carry = the odd half byte
  ADC A,A                 ; two images a sprite: 0 aligned, 1 shifted by 4
                          ; pixels
  PUSH HL
  LD HL,SpriteTable
  CALL TableWord          ; HL = the sprite
  LD C,(HL)               ; C = rows, B = bytes a row
  INC HL
  LD B,(HL)
  INC HL
  EX DE,HL
  POP HL
  XOR A                   ; no bytes clipped on the left yet
  LD (SpriteRowLoop+$0003),A
  LD A,L                  ; past the right edge?
  CP $14
  RET P
  LD A,H                  ; the bottom line below the buffer?
  CP $A0
  JR C,ClipLeft
  CP $E2                  ; entirely below
  RET NC
  SUB $9F                 ; rows below the buffer
  SUB C
  RET P
  NEG                     ; C = the rows that remain
  LD C,A
ClipBottomLoop:
  PUSH BC                 ; skip a row of the sprite
l_CF6C:
  INC DE
  INC DE
  DJNZ l_CF6C
  POP BC
  DEC H
  LD A,H
  CP $9F
  JR NZ,ClipBottomLoop
ClipLeft:
  LD A,L
  OR A
  JP P,ClipRight
  NEG                     ; bytes cut on the left
  LD (SpriteRowLoop+$0003),A
  LD L,$00
  CP B
  RET NC
ClipRight:
  LD A,L
  ADD A,B
  CP $15
  JR C,BufferAddress
  SUB $14                 ; bytes cut on the right
  LD (SpriteRowLoop+$0003),A
ClipRightLoop:
  DEC DE                  ; start that many pairs earlier: each row then leaves
                          ; out its last pairs
  DEC DE
  DEC A
  JR NZ,ClipRightLoop
BufferAddress:
  PUSH DE                 ; DE = $5B00 + 20*H + L
  LD A,L
  PUSH AF
  LD L,H
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD D,H
  LD E,L
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  POP AF
  CALL AddAToHL
  LD DE,ViewBuffer
  ADD HL,DE
  POP DE
  EX DE,HL
SpriteRowLoop:
  PUSH BC
  PUSH DE
  LD A,$00                ; bytes to skip on the left: the operand $CFAF
  OR A
  JP Z,SpriteByteLoop
SkipLeftLoop:
  INC HL
  INC HL
  DEC B
  DEC A
  JP NZ,SkipLeftLoop
SpriteByteLoop:
  LD A,(DE)               ; AND the mask, OR the pixels
  AND (HL)
  INC HL
  OR (HL)
  LD (DE),A
  INC HL
  INC DE
  DJNZ SpriteByteLoop
  POP DE
  POP BC
  LD A,$EC                ; one buffer row up
  ADD A,E
  LD E,A
  JP C,l_CFD2
  DEC D
  LD A,D
  CP $5A                  ; above $5B00: stop
  RET Z
l_CFD2:
  DEC C
  JP NZ,SpriteRowLoop
  RET

; Clear the view buffer and paint the corners outside the map
;
; ClearViewBuffer, FillViewCorner (the solid top left corner), then the
; diagonal edge strips from $D6A8: 6 strips down and left from buffer row 0,
; column 10 (the top left edge), 3 from row 136, column 18 and 4 of the other
; diagonal ($D6B8) from row 128, column 18 (the bottom right corner, the blue
; area that DrawPlayScreen colours $41 / $71). Called by DrawView and once by
; $A62D.
DrawViewBackground:
  CALL ClearViewBuffer
  CALL FillViewCorner
  LD HL,ViewEdgeA
  LD B,$06
  LD DE,ViewBuffer+$000A  ; row 0, column 10
  CALL DrawEdgeStrips
  LD HL,ViewEdgeA
  LD B,$03
  LD DE,ViewBuffer+$0AB2  ; row 136, column 18
  CALL DrawEdgeStrips
  LD HL,ViewEdgeB         ; the edge with the ink on the right
  LD B,$04
  LD DE,ViewBuffer+$0A12  ; row 128, column 18
  JP DrawEdgeStrips

; Zero the view buffer $5B00-$677F (20 bytes x 160 rows)
;
; Pushes HL = 0 with SP at $6780 (198 x 16 bytes, SP kept in $FD08), then
; clears the first 32 bytes with LDIR. Called by DrawViewBackground,
; ShowRobotDesign and $CB52.
ClearViewBuffer:
  LD (SavedSP),SP           ; keep SP
  LD SP,Font              ; the end of the buffer
  LD B,$C6                ; 198 x 8 words
  LD HL,$0000
ClearPushLoop:
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  DJNZ ClearPushLoop
  LD SP,(SavedSP)
  LD HL,ViewBuffer        ; the 32 bytes left at the start
  LD DE,ViewBuffer+$0001
  LD BC,$001F
  LD (HL),$00
  LDIR
  RET

; Fill the top left corner of the view buffer: a staircase of 5 bands
;
; 5 bands of 8 rows; the first fills 10 bytes of each row, each next band 2
; fewer (10, 8, 6, 4, 2). The fill and skip counts are the operands $D038 and
; $D041, reset to 10 at the start and moved by 2 after each band.
FillViewCorner:
  LD A,$0A
  LD (CornerRowLoop+$0002),A ; bytes filled a row
  LD (CornerByteLoop+$0006),A ; bytes skipped a row
  LD HL,ViewBuffer
  LD B,$05
BandLoop:
  PUSH BC
  LD B,$08
CornerRowLoop:
  PUSH BC
  LD B,$0A                ; the fill count: the operand $D038
  LD A,$FF
CornerByteLoop:
  LD (HL),A
  INC HL
  DJNZ CornerByteLoop
  POP BC
  LD A,$0A                ; the skip count: the operand $D041
  CALL AddAToHL
  DJNZ CornerRowLoop
  POP BC
  PUSH HL
  LD HL,CornerRowLoop+$0002 ; 2 bytes fewer, 2 more skipped
  DEC (HL)
  DEC (HL)
  LD HL,CornerByteLoop+$0006
  INC (HL)
  INC (HL)
  POP HL
  DJNZ BandLoop
  RET

; Copy B strips of 8 rows x 2 bytes (pattern HL) into the buffer, each 8 rows
; down and 2 bytes left
;
; The diagonal edge of the map in the view. The patterns are at $D6A8 (ink on
; the left: $FFFF, $FFFC, ..., $C000) and $D6B8 (ink on the right).
DrawEdgeStrips:
  PUSH BC
  PUSH HL
  LD BC,$08FF
StripRowLoop:
  LDI
  LDI
  LD A,$12                ; the next row: 20 bytes in all
  ADD A,E
  LD E,A
  LD A,D
  ADC A,$00
  LD D,A
  DJNZ StripRowLoop
  POP HL
  POP BC
  DEC DE                  ; 2 bytes left for the next strip
  DEC DE
  DJNZ DrawEdgeStrips
  RET

; Copy the view buffer to the screen at character row 1, column 1 (20 x 20
; characters)
;
; 160 lines of 20 bytes with unrolled LDI, the destination stepped through the
; screen's thirds. 256 M T-states in the deep recording.
CopyViewToScreen:
  LD HL,ViewBuffer
  LD DE,$4021             ; the screen: line 0 of character row 1, column 1
  LD C,$14                ; 20 character rows
CopyCharRowLoop:
  LD B,$08
CopyLineLoop:
  PUSH BC
  PUSH DE
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  POP DE
  POP BC
  INC D                   ; the next pixel line
  DJNZ CopyLineLoop
  LD A,E                  ; the next character row
  ADD A,$20
  LD E,A
  JR C,l_D0B4
  LD A,D
  SUB $08
  LD D,A
l_D0B4:
  DEC C
  JP NZ,CopyCharRowLoop
  RET

; Clear the screen (pixels and attributes to 0) and make the border black
;
; Called by DrawPlayScreen, ConstructionMenu and the menu screens $C100, $C34A.
ClearScreen:
  XOR A
  OUT ($FE),A
  LD HL,$4000
  LD DE,$4001
  LD BC,$1AFF
  LD (HL),$00

; ClearScreen's LDIR
;
; An entry only because the recording work/game started inside this LDIR; no
; code jumps here.
ClearScreenFill:
  LDIR
  RET

; Draw the whole play screen: the view, its frame, the colours, DAY / TIME /
; RADAR
;
; ClearScreen and DrawView, then the frame of the view (22 x 22 characters from
; (0,0): double lines at the top and bottom, $81 lines at the sides), the
; attributes: $07 everywhere, $78 on the frame, $70 (yellow paper) in the view,
; $71 and $41 (blue) in its bottom right corner, the area past the map's edge.
; Prints PlayScreenText. Called at the start of play ($A68E) and after the
; construction menu ($CB52).
DrawPlayScreen:
  CALL ClearScreen
  CALL DrawView
  LD HL,$4000             ; the frame's top line
  LD DE,$4001
  LD BC,$0015
  LD (HL),$FF
  LDIR
  LD HL,$4701             ; the inner top line
  LD DE,$4702
  LD BC,$0013
  LD (HL),$FF
  LDIR
  LD HL,$50A1             ; the inner bottom line
  LD DE,$50A2
  LD BC,$0013
  LD (HL),$FF
  LDIR
  LD HL,$57A0             ; the frame's bottom line
  LD DE,$57A1
  LD BC,$0015
  LD (HL),$FF
  LDIR
  LD HL,$4100             ; the corners of the double lines
  LD B,$06
l_D109:
  LD (HL),$80
  INC H
  DJNZ l_D109
  LD HL,$4115
  LD B,$06
l_D113:
  LD (HL),$01
  INC H
  DJNZ l_D113
  LD HL,$50A0
  LD B,$07
l_D11D:
  LD (HL),$80
  INC H
  DJNZ l_D11D
  LD HL,$50B5
  LD B,$07
l_D127:
  LD (HL),$01
  INC H
  DJNZ l_D127
  LD HL,$4700             ; the left side, 162 lines
  LD B,$A2
l_D131:
  LD (HL),$81
  CALL NextScreenLine
  DJNZ l_D131
  LD HL,$4715             ; the right side
  LD B,$A2
l_D13D:
  LD (HL),$81
  CALL NextScreenLine
  DJNZ l_D13D
  LD HL,$5800             ; all attributes $07
  LD DE,$5801
  LD BC,$02FF
  LD (HL),$07
  LDIR
  LD HL,$5800             ; the frame's top row $78
  LD DE,$5801
  LD BC,$0015
  LD (HL),$78
  LDIR
  LD HL,$5AA0             ; the frame's bottom row
  LD DE,$5AA1
  LD BC,$0015
  LD (HL),$78
  LDIR
  LD HL,$5820             ; the frame's left and right columns
  LD B,$14
l_D170:
  LD (HL),$78
  LD A,$15
  CALL AddAToHL
  LD (HL),$78
  LD A,$0B
  CALL AddAToHL
  DJNZ l_D170
  LD HL,$5821             ; the view: 20 x 20 cells of $70
  LD BC,$1414
l_D186:
  PUSH BC
l_D187:
  LD (HL),$70
  INC HL
  DJNZ l_D187
  POP BC
  LD A,$0C
  CALL AddAToHL
  DEC C
  JR NZ,l_D186
  LD B,$04                ; the bottom right corner: blue past the map's edge
  LD HL,$5A33
l_D19A:
  LD (HL),$71
  INC HL
  LD (HL),$71
  LD A,$1D
  CALL AddAToHL
  DJNZ l_D19A
  LD HL,$5A53
  LD (HL),$41
  INC HL
  LD (HL),$41
  LD HL,$5A71
  LD B,$04
l_D1B3:
  LD (HL),$41
  INC HL
  DJNZ l_D1B3
  LD HL,$5A8F
  LD B,$06
l_D1BD:
  LD (HL),$41
  INC HL
  DJNZ l_D1BD
  CALL PrintInline        ; DAY:, TIME:, RADAR:

; Inline string: " DAY:" and "TIME:" at (0,22), the tall "RADAR:" at (22,0)
;
; PrintInline bytes: attribute $57, position (0,22), size 0, " DAY:", newline,
; "TIME:", position (22,0), size $21 (2 rows high, 1 byte wide), attribute $45,
; "RADAR:".
PlayScreenText:
  DEFM $02,"W",$01,$00,$16,$04,$00," DAY:",$03,"TIME:",$01,$16,$00,$04,"!",$02,"ERADAR:",$00

; Clear the right panel and print the status labels
;
; ClearPanel, then StatusPanelText. Called when the robot menu ends ($A7CD) and
; by $AF00.
ShowStatusPanel:
  CALL ClearPanel
  CALL PrintInline

; Inline string: the STATUS and RESOURCES labels of the right panel
;
; "  STATUS" at (3,22) attribute $46, "INSG  HUMN" (Insignians, the enemy;
; Humans, the player), then from (6,23) attribute $45 the rows WARBASES,
; ELECTR'S, NUCLEAR, PHASERS, MISSILES, CANNON, CHASSIS, ROBOTS; "RESOURCES" at
; (15,23) attribute $46 and from row 17 attribute $44 GENERAL, ELECTR',
; NUCLEAR, PHASERS, MISSILE, CANNON, CHASSIS: the order of Resources.
StatusPanelText:
  DEFM $01,$03,$16,$02,"F  STATUS",$03,"INSG  HUMN",$01,$06,$17,$02,"EWARBASES",$03,"ELECTR'S",$03,"NUCLEAR",$03,"PHASERS",$03,"MI"
  DEFM "SSILES",$03," CANNON",$03,"CHASSIS",$03," ROBOTS",$01,$0F,$17,$02,"FRESOURCES",$03,$03,$02,"DGENERAL",$03,"ELECTR'",$03,"N"
  DEFM "UCLEAR",$03,"PHASERS",$03,"MISSILE",$03,"CANNON",$03,"CHASSIS",$00

; Print the panel's numbers: resources, then both sides' buildings and robots
;
; Skipped while $FD39 is not 0 (the robot menu owns the panel). Prints the
; seven Resources at (17-23, 30) as two digits, attribute $4E; the enemy's
; building counts $FD42 (by type 0-6) at (6-12, 22) and robots $FD49 at
; (13,22); the player's counts $FD3A at (6-12, 31) and robots $FD41 at (13,30),
; attribute $47. Called after the counts change ($AD90, $AE38, $B0FA, $B7F4)
; and on entering play ($A62D).
UpdateStatusPanel:
  LD A,(PanelBusy)
  OR A
  RET NZ
  CALL PrintInline        ; position (16,30), attribute $4E, size 0

; Inline string: position (16,30), attribute $4E, size 0
ResourceValuesPos:
  DEFB $01,$10,$1E,$02,$4E,$04,$00,$00

; The seven resource values, each on the next line (the tail of $D293)
PrintResourceValues:
  LD HL,Resources
  LD B,$07
ResourceValueLoop:
  PUSH BC
  PUSH HL
  CALL PrintNewline       ; the next line first
  POP HL
  LD A,(HL)
  INC HL
  PUSH HL
  CALL PrintNumber2       ; two digits, blank leading zero
  POP HL
  POP BC
  DJNZ ResourceValueLoop
  CALL PrintInline

; Inline string: position (6,22), attribute $47
InsgCountsPos:
  DEFB $01,$06,$16,$02,$47,$00

; The enemy's building counts and its robots (the tail of $D293)
PrintInsgCounts:
  LD HL,EnemyBuildings
  CALL PrintDigitColumn   ; seven single digits, one a line
  LD A,(HL)               ; $FD49: the enemy's robots, two digits
  CALL PrintNumber2Zero
  CALL PrintInline

; Inline string: position (6,31)
HumnCountsPos:
  DEFB $01,$06,$1F,$00

; The player's building counts (the tail of $D293)
PrintHumnCounts:
  LD HL,PlayerBuildings
  CALL PrintDigitColumn
  CALL PrintInline

; Inline string: position (13,30)
HumnRobotsPos:
  DEFB $01,$0D,$1E,$00

; The player's robots $FD41, two digits (the tail of $D293)
PrintHumnRobots:
  LD A,(HL)
  JP PrintNumber2Zero

; Print seven bytes from HL as single digits, one under the other
;
; HL ends past the seventh byte (the robot count that follows). Used by
; PrintInsgCounts and PrintHumnCounts.
PrintDigitColumn:
  LD B,$07
DigitColumnLoop:
  PUSH BC
  LD A,(HL)
  INC HL
  ADD A,$30
  CALL PrintCharKeep
  PUSH HL
  CALL PrintNewline
  POP HL
  POP BC
  DJNZ DigitColumnLoop
  RET

; Blank the right panel: 22 lines of 10 spaces from (2,22) in attribute 0
;
; Called by ShowStatusPanel and by the robot menus ($A732, $A7CD, $A971, $AACF,
; $AB4E, $ABC8, $AF00) before they print.
ClearPanel:
  CALL PrintInline

; Inline string: position (2,22), size 0, attribute 0
ClearPanelPos:
  DEFB $01,$02,$16,$04,$00,$02,$00,$00

; 22 lines (the tail of ClearPanel)
ClearPanelLines:
  LD B,$16

; Print 10 spaces and a newline
;
; Used by the routine at ClearPanelNext.
ClearPanelLine:
  CALL PrintInline

; Inline string: 10 spaces, newline
PanelBlankLine:
  DEFM "          ",$03,$00

; The next of the 22 lines
ClearPanelNext:
  DJNZ ClearPanelLine
  RET

; Draw a masked image on the screen: C lines of B (mask, pixel) pairs from HL
; to DE, going up
;
; Each line ANDs the mask and ORs the pixels; DE moves one screen line up
; (PrevScreenLine) after each. Used by ConstructionMenu for its pictures (56
; calls).
DrawMaskedUp:
  PUSH BC
  PUSH DE
MaskedByteLoop:
  LD A,(DE)
  AND (HL)
  INC HL
  OR (HL)
  LD (DE),A
  INC HL
  INC DE
  DJNZ MaskedByteLoop
  POP DE
  POP BC
  CALL PrevScreenLine     ; one screen line up
  DEC C
  JP NZ,DrawMaskedUp
  RET

; HL = the screen address one pixel line down
;
; Used by the routines at ShowRobotDesign, DrawPlayScreen, PrintBigChar and
; ShowRadar.
NextScreenLine:
  INC H
  LD A,$07
  AND H
  RET NZ
  LD A,L
  ADD A,$20
  LD L,A
  RET C
  LD A,H
  SUB $08
  LD H,A
  RET

; DE = the screen address one pixel line up
;
; Used by the routine at DrawMaskedUp.
PrevScreenLine:
  LD A,D
  DEC D
  AND $07
  RET NZ
  LD A,E
  SUB $20
  LD E,A
  RET C
  LD A,D
  ADD A,$08
  LD D,A
  RET

; HL = the word at HL + 2*A
;
; The sprite table lookup of DrawSprite, also ConstructionMenu and $BD61.
TableWord:
  ADD A,A
  CALL AddAToHL
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  RET

; HL += A
;
; Used by the routines at PaintMenuItem, TerrainTop, KeepHigher, SteerByOrder,
; SetStepDelay, EnemyCommander, NuclearBlast, NuclearFlash, CountBases,
; SetBaseOwner, MarkBaseDestroyed, TitleColourCycle, ConstructionMenu,
; ConstructionMenuLoop, RefundPart, PrintMenuResources, ShowRobotDesign,
; DrawMapObjects, DrawCellObject, DrawRobotPart, DrawSprite, FillViewCorner,
; DrawPlayScreen, TableWord and PrintBigChar.
AddAToHL:
  ADD A,L
  LD L,A
  LD A,H
  ADC A,$00
  LD H,A
  RET

; A = a pseudo-random byte
;
; A 32-bit shift register at $FD00-$FD03 (big end first): shifted left once,
; the new bit = bit 3 XOR bit 6 of $FD00. Then A = one of the four bytes,
; picked by the low 2 bits of the byte the previous call returned (kept in the
; operand $D371). HL is kept. 43256 calls in the deep recording: the robot AI
; ($B222, $B0FA), the enemy spawn $B7F4, the noise of SoundFx.
Random:
  PUSH HL
  LD HL,RandomSeed
  LD A,(HL)
  AND $48                 ; bits 6 and 3
  ADD A,$38               ; bit 6 of the sum = bit 6 XOR bit 3
  RLCA                    ; carry = the feedback bit
  RLCA
  LD L,$03                ; shift $FD03..$FD00 left
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  DEC L
  RL (HL)
  LD L,$00                ; the index from the last call: the operand $D371
  LD A,(HL)
  AND $03                 ; the next index
  LD L,A
  LD (Random+$0019),A
  LD A,(HL)               ; A = the byte at that index
  POP HL
  RET

; ReadControls; while key 1 (Input bit 7) is held, the pause: wait for another
; key
;
; Used by the routines at PlayLoop, DirectControl, DistanceSelect, ListMenu,
; WaitRelease, GameOverWait, FindNearestOpponent and ConstructionMenuLoop.
WaitKey:
  CALL ReadControls
  OR A
  RET P
PauseLoop:
  CALL ReadControls       ; key 1 held: wait for another control
  OR A
  JR Z,PauseLoop
  JP M,PauseLoop

; Input from the redefinable keys (KeyTable) or the joystick the menu chose
; (Controls)
;
; Used by the routine at WaitKey.
ReadControls:
  LD HL,KeyTable
  LD C,$01                ; C = 1: the end marker, shifted out after 8 keys
KeyLoop:
  LD A,(HL)               ; IN from the key's half row
  INC HL
  IN A,($FE)
  AND (HL)                ; Z: pressed
  INC HL
  INC HL
  JR NZ,l_D399
  CCF                     ; pressed: carry 1
l_D399:
  RL C                    ; the first key of the table ends in bit 7
  JR NC,KeyLoop
  LD A,($D3E4)            ; the joystick chosen in the menu
  CP $02
  JR Z,Kempston
  CP $03
  JR Z,Interface2
  XOR A                   ; keyboard only
  JR InputDone
Kempston:
  XOR A                   ; port $1F: fire, up, down, left, right in bits 4-0
  IN A,($1F)
  AND $1F
  JR InputDone
Interface2:
  LD A,$EF                ; keys 6-0 (port $EFFE) into the Kempston order
  IN A,($FE)
  CPL
  AND $1F
  LD B,A
  XOR A
  SRL B                   ; 0 (fire) to bit 4, 9 (up) to bit 3, 8 (down) to bit
                          ; 2
  RLA
  SRL B
  RLA
  SRL B
  RLA
  RLA
  RLA
  OR B                    ; 7 (right) to bit 0, 6 (left) to bit 1
InputDone:
  OR C                    ; plus the keys
  LD (Input),A
  RET

; the keys, eight of 3 bytes: the port high byte, the bit mask, the key code
; (shown by the redefine menu)
KeyTable:
  DEFB $F7,$01,$31
  DEFB $DF,$04,$49
  DEFB $F7,$10,$35
  DEFB $7F,$02,$82
  DEFB $FB,$01,$51
  DEFB $FD,$01,$41
  DEFB $DF,$02,$4F
  DEFB $DF,$01,$50
  DEFB $01

; Print A (0-99) as two digits, a leading zero blank
;
; Used by the routines at ShowMilesCode, PrintMenuResourceValue and
; PrintResourceValues.
PrintNumber2:
  LD L,A
  LD H,$00
  LD E,$20
  JR PrintTensUnits

; Print A (0-99) as two digits with a leading zero
;
; The clock ($AD90, 6828 calls: "20.20") and the robot counts of the panel.
PrintNumber2Zero:
  LD L,A
  LD H,$00
  LD E,$00
  JR PrintTensUnits

; Print HL as five digits, leading zeros blank
;
; Used by $AD90 for the day number ("DAY:    4"). Falls into PrintNumber3.
PrintNumber5:
  LD BC,$D8F0             ; -10000
  LD E,$20
  CALL PrintDigit
  LD BC,$FC18             ; -1000
  CALL PrintDigit

; Print HL as three digits (E = $20: leading zeros blank, else printed)
;
; The operand $FF9C is -100 (main.asm shows it as Buildings+155: a false
; symbol). Used by PrintMenuTotal and $A833.
PrintNumber3:
  LD BC,-$0064            ; -100
  CALL PrintDigit

; Print the tens and the units of HL
;
; Used by the routines at PrintNumber2 and PrintNumber2Zero.
PrintTensUnits:
  LD BC,$FFF6             ; -10
  CALL PrintDigit
  LD A,L                  ; the units digit, always printed
  ADD A,$30
  JP PrintCharKeep

; Print the digit of HL for the power -BC; HL keeps the rest
;
; Counts how often BC (a negative power of 10) can be added. A zero while E =
; $20 prints a space and keeps E; any printed digit increments E, so later
; zeros print as 0.
PrintDigit:
  XOR A
DigitCountLoop:
  ADD HL,BC
  INC A
  JR C,DigitCountLoop
  SBC HL,BC               ; one too far: undo
  DEC A
  JR NZ,l_D424
  LD A,E                  ; a leading zero
  CP $20
  JP Z,PrintCharKeep      ; blank: E = $20 is the space
  XOR A
l_D424:
  INC E                   ; a digit: no more leading zeros
  ADD A,$30

; PrintChar A with BC, DE, HL kept (EXX around)
;
; Used by the routines at ShowStrengthValue, GameTurnEnd, CheckSpaceKey,
; PrintDigitColumn, PrintTensUnits and PrintDigit.
PrintCharKeep:
  EXX
  CALL PrintChar
  EXX
  RET

; print the text after the CALL: 0 ends, 1 Y X a position, 2 A an attribute, 3
; the next line, 4 N a setting, else a character
;
; Used by the routines at RobotMenuShow, ShowOrder, ShowOrderMiles,
; ShowStrength, OrdersMenu, OrdersMenuChoose, RetreatTitle, DistanceMenu,
; DistanceSelect, TargetMenu, CaptureMenu, SetOrder, GameTurn, CheckGameEnd,
; GameWon, MainMenuOptions, MenuKeyboardOption, MenuKempstonOption,
; MenuInterface2Option, PrintTitle, PrintTitleEnd, LoadGameBlocks, SaveGame,
; ControlsOptionAttr, ControlsOptionPlain, RedefineKeys, PrintKeyPrompt,
; PrintKeyPromptName, DefineKey, DefineKeyScan, CheckEnterKey,
; CheckCapsShiftKey, CheckSpaceKey, ConstructionMenu, PrintMenuResources,
; PrintMenuResource, DrawPlayScreen, ShowStatusPanel, UpdateStatusPanel,
; PrintResourceValues, PrintInsgCounts, PrintHumnCounts, ClearPanel and
; ClearPanelLine.
PrintInline:
  EXX
PrintInlineLoop:
  POP HL                  ; the next byte after the CALL: the return address
                          ; moves with it
  LD A,(HL)
  INC HL
  PUSH HL
  OR A
  JR Z,l_D43A
  CALL PrintControl       ; a control code or a character
  JR PrintInlineLoop
l_D43A:
  EXX                     ; 0: return past the string
  RET

; PrintInline's byte A: control codes 1-4 or a character
;
; 1 Y X: the position (row Y, column X, kept in $FD32/$FD31). 2 A: the
; attribute $FD13. 3: newline (the next row, the same column). 4 N: the size,
; high nibble the height in character rows ($FD16), low nibble the width in
; bytes ($FD17); 0 = normal. A character goes to PrintChar for size 0, else to
; PrintBigChar. The operands are read through the caller's return address on
; the stack, two levels up.
PrintControl:
  CP $01
  JR Z,SetPosition
  CP $02
  JR Z,SetAttr
  CP $03
  JR Z,PrintNewline
  CP $04
  JR Z,SetSize
  LD C,A                  ; a character
  LD A,(PrintWidth)
  OR A
  LD A,C
  JR Z,PrintChar          ; size 0: normal
  JP PrintBigChar
SetAttr:
  POP DE                  ; 2 A
  POP HL
  LD A,(HL)
  INC HL
  PUSH HL
  PUSH DE
  LD (PrintAttr),A
  RET
SetPosition:
  POP DE                  ; 1 Y X
  POP HL
  LD B,(HL)
  INC HL
  LD C,(HL)
  LD (PrintColumn),BC
  INC HL
  PUSH HL
  PUSH DE
  JP SetPrintPos

; The next print row, the same column
;
; Used by the routines at GameTurnEnd, ReadFireKey, PrintResourceValues,
; PrintDigitColumn and PrintControl.
PrintNewline:
  LD BC,(PrintColumn)
  INC B
  LD (PrintColumn),BC
  JP SetPrintPos
; This entry point is used by the routine at PrintControl.
SetSize:
  POP DE                  ; 4 N: height nibble, width nibble
  POP HL
  LD A,(HL)
  INC HL
  PUSH HL
  PUSH DE
  LD C,A
  RRCA
  RRCA
  RRCA
  RRCA
  AND $0F
  LD (PrintHeight),A
  LD A,C
  AND $0F
  LD (PrintWidth),A
  RET

; Print position: B = row, C = column -> $FD04 the screen address, $FD14 the
; attribute address
;
; Used by the routines at PrintControl and PrintNewline.
SetPrintPos:
  LD A,B
  AND $F8
  ADD A,$40
  LD H,A
  LD A,B
  AND $07
  RRCA
  RRCA
  RRCA
  ADD A,C
  LD L,A
  LD (PrintAddr),HL
  LD A,H
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  LD (PrintAttrAddr),HL
  RET

; Print character A at the print position in the print attribute, advance one
; column
;
; The font is at $6680 + 8*code ($6780 for the space, right after the view
; buffer). 8 lines into ($FD04), the attribute ($FD13) into ($FD14), both
; advanced.
PrintChar:
  LD H,$00
  LD L,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,ViewBuffer+$0B80  ; the font
  ADD HL,DE
  LD DE,(PrintAddr)
  PUSH DE
  LD B,$08
GlyphLineLoop:
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  DJNZ GlyphLineLoop
  POP DE
  INC DE
  LD (PrintAddr),DE
  LD HL,(PrintAttrAddr)
  LD A,(PrintAttr)
  LD (HL),A
  INC HL
  LD (PrintAttrAddr),HL
  RET

; Print character A scaled: each line repeated $FD16 times, width 1 or 2 bytes
; ($FD17)
;
; Width 1: each glyph line written $FD16 times (2: a character two rows high,
; "RADAR:"). Width 2: each glyph byte doubled to 16 bits. Then the screen
; address moves on by the width and a block of width x height attribute cells
; gets $FD13. 180 calls in the deep recording.
PrintBigChar:
  LD H,$00
  LD L,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,ViewBuffer+$0B80
  ADD HL,DE
  LD A,(PrintWidth)
  CP $02                  ; width 2: doubled pixels
  JR NC,WideChar
  EX DE,HL
  LD HL,(PrintAddr)
  LD C,$08
TallLineLoop:
  LD A,(PrintHeight)
  LD B,A
TallRepeatLoop:
  LD A,(DE)
  LD (HL),A
  CALL NextScreenLine
  DJNZ TallRepeatLoop
  INC DE
  DEC C
  JR NZ,TallLineLoop
  JR BigCharAttrs
WideChar:
  PUSH IX
  PUSH HL
  POP IX
  LD HL,(PrintAddr)
  LD C,$08
WideLineLoop:
  LD A,(IX+$00)
  LD B,$08
WideBitLoop:
  RLCA                    ; each bit twice into DE
  PUSH AF
  RL E
  RL D
  POP AF
  RL E
  RL D
  DJNZ WideBitLoop
  LD A,(PrintHeight)
  LD B,A
WideRepeatLoop:
  LD (HL),D
  INC L
  LD (HL),E
  DEC L
  CALL NextScreenLine
  DJNZ WideRepeatLoop
  INC IX
  DEC C
  JR NZ,WideLineLoop
  POP IX
BigCharAttrs:
  LD HL,(PrintAddr)           ; advance, then the attribute block
  LD A,(PrintWidth)
  CALL AddAToHL
  LD (PrintAddr),HL
  LD HL,(PrintAttrAddr)
  PUSH HL
  LD BC,(PrintHeight)
  LD A,(PrintAttr)
  LD E,A
BigAttrRowLoop:
  PUSH HL
  PUSH BC
BigAttrCellLoop:
  LD (HL),E
  INC HL
  DJNZ BigAttrCellLoop
  POP BC
  POP HL
  LD A,L
  ADD A,$20
  LD L,A
  LD A,H
  ADC A,$00
  LD H,A
  DEC C
  JR NZ,BigAttrRowLoop
  POP HL
  LD A,B
  CALL AddAToHL
  LD (PrintAttrAddr),HL
  RET

; the interrupt handler of play, one a frame
PlayInterrupt:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  LD HL,TurnFrames             ; the frame counter: the play loop waits for 10
                          ; ($AE1D)
  INC (HL)
  LD HL,RadarOwn          ; the player's radar picture, cyan
  LD C,$4D
  LD A,(RadarPhase)            ; the other picture each frame
  XOR $01
  LD (RadarPhase),A
  JR Z,l_D582
  LD HL,RadarEnemy        ; the enemy's radar picture, yellow
  LD C,$4E
l_D582:
  CALL ShowRadar          ; show it
  LD A,(SoundFx)            ; a sound effect running?
  OR A
  JR Z,l_D598
  INC A                   ; counts up each frame; $80 ends a rising one, 0 a
                          ; falling one
  CP $80
  JR NZ,l_D591
  XOR A
l_D591:
  LD (SoundFx),A
  OR A                    ; the flags of A: M noise, P the falling tone
  CALL NZ,SoundEffect
l_D598:
  POP HL
  POP DE
  POP BC
  POP AF

; the interrupt handler while the start-up runs
StartInterrupt:
  EI
  RET

; Show radar picture HL (16 lines x 16 bytes) at (22,6) in attribute C
;
; The interrupt alternates the two pictures $D800 (terrain + the player's
; robots, attribute $4D) and $D900 (terrain + the enemy's robots, $4E) every
; frame, so the terrain stays and each side's robots blink in their colour. The
; attributes are rows 22 and 23, columns 6-21.
ShowRadar:
  PUSH BC
  LD B,$10
  LD DE,$50C6             ; screen line 0 of character row 22, column 6
RadarLineLoop:
  PUSH BC
  PUSH DE
  LD BC,$0010
  LDIR
  POP DE
  EX DE,HL
  CALL NextScreenLine
  EX DE,HL
  POP BC
  DJNZ RadarLineLoop
  POP BC
  LD HL,$5AC6             ; the attributes of row 22
  CALL FillAttr16
  LD L,$E6                ; row 23

; Write C into 16 bytes from HL
;
; Used by the routine at ShowRadar.
FillAttr16:
  LD B,$10
FillAttrLoop:
  LD (HL),C
  INC HL
  DJNZ FillAttrLoop
  RET

; The interrupt's sound: A = $FD53 (1-$7F a falling tone, $FD-$FF noise)
;
; A positive: a tone of ~500 / (A+2) pulses with a delay of A between them, the
; levels taken from bit 4 of the ROM bytes from $0000 (a rough noise), so the
; pitch falls as A counts up each frame. $FD53 = 1 when a shot is fired
; ($B709). A negative: 30 random speaker levels (Random): the crackle of a hit.
; The shot code sets $FC (a miss: 3 frames), $FA (a hit: 5 frames) or $C8 (a
; robot destroyed: 55 frames). Seen in the deep recording at frames
; 18680-18712: 1, 2, ... $16, then $FA-$FF.
SoundEffect:
  JP M,NoiseSound
  LD B,A                  ; B = the delay between pulses
  INC A
  INC A
  LD HL,$01F4             ; C = about 500 / (A + 2) pulses
  LD E,A
  LD D,$00
  LD C,$00
  XOR A
PulseCountLoop:
  INC C
  SBC HL,DE
  JR NC,PulseCountLoop
  LD HL,$0000             ; the ROM as noise
PulseLoop:
  PUSH BC
  LD A,(HL)
  INC HL
  AND $10
  OUT ($FE),A
PulseDelay:
  DJNZ PulseDelay
  POP BC
  DEC C
  JR NZ,PulseLoop
  XOR A                   ; speaker off
  OUT ($FE),A
  RET
NoiseSound:
  LD B,$1E
NoiseLoop:
  CALL Random
  AND $10
  OUT ($FE),A
  DJNZ NoiseLoop
  RET

; Build both radar pictures for the 128 columns from $FD1C
;
; Each map cell of the window is one pixel: set when its block type is $0F or
; more (the tall blocks). Copies the terrain picture to $D900, then puts the
; dot of every robot in play (+$01 not 0, except the one under direct control,
; +$0A = 2) into its side's picture (ToggleRadarDot). Called by $B029 when the
; ship moves the window ($FD52); once in the deep recording, at frame 35.
BuildRadar:
  LD HL,RadarOwn
  LD DE,(RadarColumn)
  LD A,D
  ADD A,$DD
  LD D,A
  LD BC,$1010             ; 16 rows of 16 bytes
RadarRowLoop:
  PUSH BC
  PUSH DE
RadarByteLoop:
  PUSH BC
  LD B,$08
RadarBitLoop:
  LD A,(DE)
  INC DE
  AND $1F
  CP $0F                  ; carry: the type is $0F or more
  CCF
  RL (HL)
  DJNZ RadarBitLoop
  INC HL
  POP BC
  DJNZ RadarByteLoop
  POP DE
  POP BC
  INC D                   ; the next map row
  INC D
  DEC C
  JR NZ,RadarRowLoop
  LD HL,RadarOwn          ; the same terrain for the enemy's picture
  LD DE,RadarEnemy
  LD BC,$0100
  LDIR
  LD IY,Robots            ; the robots
  LD B,$30
RadarRobotLoop:
  PUSH BC
  LD A,(IY+$01)
  OR A
  JR Z,l_D651
  LD L,(IY+$02)
  LD H,(IY+$03)
  LD C,(IY+$04)
  LD A,(IY+$0A)
  RLCA
  AND $01
  LD B,A
  LD A,(IY+$0A)           ; not the robot under direct control (the ship's dot
                          ; stands for it)
  CP $02
  CALL NZ,ToggleRadarDot
l_D651:
  LD DE,$0010
  ADD IY,DE
  POP BC
  DJNZ RadarRobotLoop
  RET

; XOR a 2x2 dot at map column HL, row C into radar picture B (0 player, 1
; enemy)
;
; The dot covers (x, y), (x+1, y) and the line above. Nothing outside the
; window (RadarDotAddress returns past this routine). XOR: the same call
; removes the dot again, so the robot code toggles the old position before
; PlaceRobot toggles the new one.
ToggleRadarDot:
  CALL RadarDotAddress
  LD C,A                  ; C = the pixel mask
  PUSH HL
  LD A,(HL)
  XOR C
  LD (HL),A
  RRC C                   ; the next pixel, maybe in the next byte
  JR NC,l_D667
  INC HL
l_D667:
  LD A,(HL)
  XOR C
  LD (HL),A
  POP HL
  LD A,L                  ; the line above
  SUB $10
  LD L,A
  RLC C
  LD A,(HL)
  XOR C
  LD (HL),A
  RRC C
  JR NC,l_D679
  INC HL
l_D679:
  LD A,(HL)
  XOR C
  LD (HL),A
  RET

; HL = the radar byte of column HL, row C in picture B, A = the pixel mask
;
; Column x - $FD1C must be 0-126, else it pops the return address and returns
; from ToggleRadarDot. Address = $D800 + $100*B + 16*y + (x-$FD1C)/8, mask =
; $80 >> ((x-$FD1C) AND 7).
RadarDotAddress:
  LD DE,(RadarColumn)
  XOR A
  SBC HL,DE
  LD A,H
  OR A
  JR NZ,l_D6A6
  LD A,L
  CP $7F
  JR NC,l_D6A6
  LD A,$D8                ; $D800 or $D900
  ADD A,B
  LD H,A
  LD A,L
  AND $07
  INC A
  LD B,A
  LD A,L                  ; L = 16*y + x/8
  RLCA
  AND $F0
  OR C
  RLCA
  RLCA
  RLCA
  RLCA
  LD L,A
  XOR A                   ; the mask: $80 shifted right x AND 7 times
  SCF
l_D6A2:
  RRA
  DJNZ l_D6A2
  RET
l_D6A6:
  POP HL                  ; outside the window: return from the caller too
  RET

; View edge, black on the left: 8 lines of 2 bytes
;
; $FFFF, $FFFC, $FFF0 ... $C000: a staircase 2 pixels a line.
; DrawViewBackground copies it with DrawEdgeStrips (2 bytes a line, 8 lines,
; then 2 bytes left) 6 times from $5B0A, the lower edge of the black triangle
; above the map, and 3 times from $5FB2. Image: d1-img/D6A8-ViewEdges.png.
ViewEdgeA:
  DEFB $FF,$FF
  DEFB $FF,$FC
  DEFB $FF,$F0
  DEFB $FF,$C0
  DEFB $FF,$00
  DEFB $FC,$00
  DEFB $F0,$00
  DEFB $C0,$00

; View edge, black on the right: 8 lines of 2 bytes
;
; $0003, $000F ... $FFFF; DrawViewBackground copies it 4 times from $6512: with
; the 3 copies of ViewEdgeA at $5FB2 it makes the black band along the map's
; front edge, bottom right of the view.
ViewEdgeB:
  DEFB $00,$03
  DEFB $00,$0F
  DEFB $00,$3F
  DEFB $00,$FF
  DEFB $03,$FF
  DEFB $0F,$FF
  DEFB $3F,$FF
  DEFB $FF,$FF

; Robot part sprites: 8 parts x 4 directions, sprite id - $16
;
; Row = part (bipod, tracks, anti-grav, cannon, missiles, phasers, nuclear,
; electronics), column = direction (the number of the lowest set bit of robot
; +$08: 0 X+, 1 X-, 2 Y+, 3 Y-). Read by DirectionLoop ($CF16; sprite id = byte
; + $16, then DrawSprite) for robots in the view and by ConstructionMenu
; ($C87B; column 1, the odd-column sprite via SpriteTable+$58) for the part
; icons. Bipod, tracks and missiles have one picture per axis, anti-grav and
; nuclear one for all four.
PartSpriteTable:
  DEFB $02,$02,$03,$03
  DEFB $00,$00,$01,$01
  DEFB $04,$04,$04,$04
  DEFB $05,$06,$07,$08
  DEFB $09,$09,$0A,$0A
  DEFB $0B,$0C,$0D,$0E
  DEFB $0F,$0F,$0F,$0F
  DEFB $10,$11,$12,$13

; Sprite pointers: 51 sprite ids x (even column, odd column)
;
; Word = the sprite block for index id x 2 + parity (DrawSprite: AND $3F, SRA L
; / ADC A,A, then TableWord). Ids 0 ship, 1 shadow, 2-18 and 21 map types (2-5
; stones, 6-7 boulders, 8-11 rocks, 12-14 trench, 15-18 blocks, 21 post), 19-20
; unused (they point at the ship), 22-41 robot parts (PartSpriteTable), 42 the
; player's flag, 43 the enemy's flag, 44 the warbase sign, 45-50 shots (cannon,
; missile, phaser; X then Y). ConstructionMenu reads from SpriteTable+$58 (id
; 22 on). Read by TableWord ($D34C/$D34E).
SpriteTable:
  DEFW SprShip,SprShipOdd
  DEFW SprShadow,SprShadowOdd
  DEFW SprStonesA,SprStonesA
  DEFW SprStonesB,SprStonesB
  DEFW SprStonesC,SprStonesC
  DEFW SprStonesD,SprStonesD
  DEFW SprBouldersA,SprBouldersAOdd
  DEFW SprBouldersB,SprBouldersBOdd
  DEFW SprRocksA,SprRocksA
  DEFW SprRocksB,SprRocksB
  DEFW SprRocksC,SprRocksC
  DEFW SprRocksD,SprRocksD
  DEFW SprTrenchStartY,SprTrenchStartX
  DEFW SprTrenchMiddleY,SprTrenchMiddleX
  DEFW SprTrenchEndY,SprTrenchEndX
  DEFW SprBlockLow,SprBlockLowOdd
  DEFW SprBlockTall,SprBlockTallOdd
  DEFW SprBlockDoor,SprBlockWindow
  DEFW SprBlockGrid,SprBlockDotted
  DEFW SprShip,SprShip
  DEFW SprShip,SprShip
  DEFW SprPost,SprPost
  DEFW SprTracksX,SprTracksXOdd
  DEFW SprTracksY,SprTracksYOdd
  DEFW SprBipodX,SprBipodXOdd
  DEFW SprBipodY,SprBipodYOdd
  DEFW SprAntiGrav,SprAntiGravOdd
  DEFW SprCannonXp,SprCannonXpOdd
  DEFW SprCannonXm,SprCannonXmOdd
  DEFW SprCannonYp,SprCannonYpOdd
  DEFW SprCannonYm,SprCannonYmOdd
  DEFW SprMissilesX,SprMissilesXOdd
  DEFW SprMissilesY,SprMissilesYOdd
  DEFW SprPhasersXp,SprPhasersXpOdd
  DEFW SprPhasersXm,SprPhasersXmOdd
  DEFW SprPhasersYp,SprPhasersYpOdd
  DEFW SprPhasersYm,SprPhasersYmOdd
  DEFW SprNuclear,SprNuclearOdd
  DEFW SprElectronicsXp,SprElectronicsXpOdd
  DEFW SprElectronicsXm,SprElectronicsXmOdd
  DEFW SprElectronicsYp,SprElectronicsYpOdd
  DEFW SprElectronicsYm,SprElectronicsYmOdd
  DEFW SprFlagPlayer,SprFlagPlayerOdd
  DEFW SprFlagEnemy,SprFlagEnemyOdd
  DEFW SprWarbaseSign,SprWarbaseSignOdd
  DEFW SprShotCannonX,SprShotCannonXOdd
  DEFW SprShotCannonY,SprShotCannonYOdd
  DEFW SprShotMissileX,SprShotMissileXOdd
  DEFW SprShotMissileY,SprShotMissileYOdd
  DEFW SprShotPhaserX,SprShotPhaserXOdd
  DEFW SprShotPhaserY,SprShotPhaserYOdd

; Height of each robot part in units (bipod $0B, tracks 7, anti-grav 8, cannon
; 6, missiles 6, phasers 7, nuclear 7, electronics 7)
;
; Indexed by the part number. DirectionLoop ($CF28) adds it to the draw height
; after each part, so the parts stack; SpawnHeightLoop ($B911) sums it over
; robot +$07 into +$09, the robot's height, when a robot is made.
PartHeights:
  DEFB $0B,$07,$08,$06,$06,$07,$07,$07

; Height of each map cell type (0-22)
;
; Indexed by cell AND $1F: 0-1 0, stones 2-5 2, boulders 6-7 3, rocks 8-11 6,
; trench 12-14 0, blocks 15 7, 16 15, 17 7, 18 15, 19-20 0, the post 21 99 (no
; flight over it), 22 0. Read only by TerrainTop ($B093), the height under a
; cell for CheckShipMove (CellTop) and for shots and robots
; (GroundUnderFootprint).
TerrainHeights:
  DEFB $00,$00,$02,$02,$02,$02,$03,$03
  DEFB $06,$06,$06,$06,$00,$00,$00,$07
  DEFB $0F,$07,$0F,$00,$00,$63,$00

; Shots in flight: 5 records of 9 bytes
;
; +0/+1 the map cell (+1 = 0: free), +2/+3 X, +4 Y, +5 the direction (bit 0
; X+2, 1 X-2, 2 Y+2, 3 Y-2), +6 steps left (5, 7 for missiles, 1 more with
; electronics), +7 the weapon (1 cannon, 2 missiles, 3 phasers: a random one of
; the robot's weapon bits 3-5), +8 the flight height ($0A: a cell at least that
; high stops it). FindFreeShot gives a robot a free slot of two: the player's
; at $D7DC / $D7E5, the enemy's at $D7EE / $D7F7; no code fills the first
; record $D7D3, it is only cleared, saved and walked. FireShot fires,
; UpdateShot (from WorldTurn, every turn) moves and hits, DrawCellObject /
; DrawMoverSprite draw. Cleared by the start-up ($A661), saved and loaded
; through SaveShots.
Shots:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00

; Radar bitmap with the player's robots: 16 lines of 16 bytes
;
; One pixel line per map row, one bit per map column, 128 columns from the
; radar's left edge ($FD1C, moved by 64 columns at a time). BuildRadar builds
; it (a bit is set where cell AND $1F >= $0F: blocks and posts), copies it to
; RadarEnemy, then ToggleRadarDot XORs a 2-line marker for every robot into the
; player's or the enemy's copy by the side bit of +$0A (also when a robot
; moves, PlaceRobot / RobotStep). PlayInterrupt shows the two copies on
; alternate frames ($FD1A) with ShowRadar at $50C6 (16 lines, 16 bytes) and
; attributes $4D / $4E in rows 22-23, so each side's robots blink in their own
; colour. Cleared with the map by BuildMap ($BC87).
RadarOwn:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Radar bitmap with the enemy's robots: 16 lines of 16 bytes
;
; The copy of RadarOwn the enemy's markers are XORed into; shown with attribute
; $4E. The save stages its last 213 bytes ($D92B-$D9FF) as SaveShots and
; SaveBuildings: the radar is rebuilt afterwards.
RadarEnemy:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Save / load staging: the 5 Shots records
;
; SaveGameBlocks (save) copies Shots here and Buildings after it, then writes
; two headerless tape blocks with the ROM's SA-BYTES: the 2-byte sum of the
; second (at ViewBuffer) and $24D1 bytes from here to $FDFB (staging, robots,
; map, the variables $FD00-$FDFB). LoadGameBlocks loads both, checks the sum
; (SaveChecksum) and copies the records back, else LOADING ERROR. Shares the
; bytes of RadarEnemy.
SaveShots:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00

; Save / load staging: the 56 Buildings records
;
; 168 bytes, copied from and back to Buildings ($FF01) by SaveGameBlocks /
; LoadGameBlocks.
SaveBuildings:
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00

; The player's robots: slots 0-23, 16 bytes a record
;
; +0/+1 the map cell (+1 = 0: a free slot), +2/+3 X, +4 Y, +5 the last move's
; direction (likely), +6 a counter (unverified), +7 parts (bit 0 bipod ... 7
; electronics), +8 direction (bit 0 X+, 1 X-, 2 Y+, 3 Y-), +9 height (the sum
; of PartHeights), +$0A side / menu flags (1 the ship sits on it, 2 direct
; control, bit 7 enemy), +$0B order, +$0C strength ($64 at birth), +$0D the
; height its parts are drawn from (0, 2, 6 seen), +$0E target slot / distance,
; +$0F the move timer (RobotStep DEC, acts at 0). Walked by WorldTurn (every
; turn: UpdateRobot), FindRobot, BuildRadar, ConstructionMenu (a free slot of
; 0-23), the AI (ConsiderBuilding, TargetRobotRecord, FindNearestOpponent: the
; other side's array). Cleared by the start-up ($A63A, 768 bytes with
; EnemyRobots).
Robots:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; The enemy's robots: slots 24-47, the same records
;
; +$0A has bit 7 set. EnemyCommander makes one (slot = an index x 16 from
; here); ConsiderBuilding, TargetRobotRecord and FindNearestOpponent search
; this array or Robots by the side in $FD51.
EnemyRobots:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; The map: 16 rows of 512 cells, cell = $DD00 + $200 x Y + X
;
; A cell: bits 0-4 the type (0 empty; 2-18 and 21 terrain and blocks, drawn
; through SpriteTable; TerrainHeights), bit 5 a covered cell of a 2 x 2 object
; (PutBlock writes the type at the anchor and type + $20 at the other 3:
; DrawCell draws only the anchor), bit 6 a robot, a building or a shot stands
; here (FindRobot / FindBuilding look it up), bit 7 the ship is over this cell
; (set where the ship moves, ShipCell; DrawCell draws the ship in the depth
; order of this cell, $FD11). Zero in the image: BuildMap clears it ($BC7A) and
; builds it from the level description at SceneryWest (objects of 2 x 2 tiles
; through the shape table at SceneryWest+$1F3). The view reads 16 rows x 32
; columns from MapView (DrawMapObjects; one map row is 16 lines of 32 here);
; BuildRadar reads 128 columns for the radar. The last row ends at $FCFF, 23
; bytes past the image.
Map:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; The map's last 15 image bytes: they load over the loader N1
;
; Row 15, columns 474-488. The game block ends here, laid over the first 15
; bytes of N1 ($FCDA-$FD8D, the relocated LD-BYTES that is loading it), code
; that has already run. Zero, part of the map. Columns 489-511 ($FCE9-$FCFF)
; lie past the image, over the rest of N1.
MapTail:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00
