; landing on a robot of ours: DIRECT CONTROL, GIVE ORDERS, COMBAT MODE, LEAVE
; ROBOT; the order to +$0B
;
; IX = IY (the record), +$0A = 1 (the robot stands: UpdateRobot returns at once
; for +$0A = 1), MenuCursor = 4 (LEAVE ROBOT first), PanelBusy = 1. Falls into
; RobotMenuShow. Called by PlayLoop when the ship rests exactly on the top of a
; robot of ours.
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
  JP P,ShowStrengthNumber
  XOR A
ShowStrengthNumber:
  LD L,A                  ; A = the strength (0 for a dying robot): three
                          ; digits, leading spaces, then "%"
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
  INCBIN "res/text/order-names.bin",$0000,27

; Order 1: ADVANCE (the miles are printed into the blank middle line)
OrderName1:
  INCBIN "res/text/order-names.bin",$001B,27

; Order 2: RETREAT (the miles in the middle line)
OrderName2:
  INCBIN "res/text/order-names.bin",$0036,27

; Order 3: DESTROY ENEMY ROBOTS
OrderName3:
  INCBIN "res/text/order-names.bin",$0051,27

; Order 4: DESTROY ENEMY FACTORYS
OrderName4:
  INCBIN "res/text/order-names.bin",$006C,27

; Order 5: DESTROY ENEMY WARBASES
OrderName5:
  INCBIN "res/text/order-names.bin",$0087,27

; Order 6: CAPTURE NEUTRAL FACTORYS
OrderName6:
  INCBIN "res/text/order-names.bin",$00A2,27

; Order 7: CAPTURE ENEMY FACTORYS
OrderName7:
  INCBIN "res/text/order-names.bin",$00BD,27

; Order 8: CAPTURE ENEMY WARBASES
OrderName8:
  INCBIN "res/text/order-names.bin",$00D8,27

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
; This entry point is used by the routine at DistanceShow.
DistanceLoop:
  PUSH DE                 ; a game turn under the open menu, then WaitKey: fire
                          ; sets, down / up step the miles
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
  JR NZ,DistanceFire
  LD C,D
  RRCA
  RRCA
  AND $03
  JR Z,DistanceLoop
  AND $02
  LD B,A
  ADD A,A
  ADD A,A
  ADD A,B
  SUB $05
  ADD A,C
  CP $33
  JR NC,DistanceLoop
  LD D,A
  CALL PrintInline

; PrintInline: (13,23), attribute $46, where the miles are printed
DistanceAtText:
  DEFM $01,$0D,$17,$02,"F",$00

; the miles in D printed (PrintNumber2), a click, back to the distance loop
DistanceShow:
  LD A,D
  CALL PrintNumber2
  LD A,$14
  CALL Beep
  JR DistanceLoop
; This entry point is used by the routine at DistanceSelect.
DistanceFire:
  LD A,D                  ; fire: +$0E = miles x 2; 0 miles turns the order
                          ; back into 0 (stop)
  RLCA
  LD (IX+$0E),A
  OR A
  JR NZ,DistanceDone
  LD (IX+$0B),$00
DistanceDone:
  LD A,$78                ; the beep, WaitRelease, back to the robot menu
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
CombatMenuLoop:
  LD HL,$5837             ; the combat list menu, A the highlighted item; 6
                          ; EXIT, 5 direct control, else a weapon
  LD E,$07
  CALL ListMenu
  CP $06
  JP Z,RobotMenuShow
  PUSH AF
  CP $05
  JR NZ,CombatWeapon
  CALL DirectControl
  POP AF
  JR CombatMenuLoop
CombatWeapon:
  LD C,A                  ; a weapon item: shift its part bit of +$07 into
                          ; carry
  LD B,A
  INC B
  LD A,(IX+$07)
CombatPartBit:
  RLCA                    ; rotate +$07 item + 1 times: carry = the robot has
                          ; the weapon
  DJNZ CombatPartBit
  JR NC,CombatRefused
  POP AF
  CP $01
  JR NZ,CombatFireShot
  PUSH IX
  POP IY
  CALL NuclearBlast
  JP CloseRobotMenu
CombatFireShot:
  PUSH AF                 ; cannon / missiles / phasers: fire only when shot
                          ; record 0 is free, then a turn
  LD IY,Shots
  LD A,(IY+$01)
  OR A
  JR NZ,CombatRefused
  LD A,$05
  SUB C
  CALL FireShot
  CALL DrawView
  CALL GameTurn
  POP AF
  JP CombatMenuLoop
CombatRefused:
  LD A,$FA                ; no such weapon or the shot still flies: the refusal
                          ; beep, back to the menu
  CALL Beep
  POP AF
  JP CombatMenuLoop

; a list menu: HL the attribute of item 0 (an item every 3 rows), E the items +
; 1, A the first highlighted; down / up move, fire returns A
;
; Each pass is one game turn (WorldTurn, DrawView, MenuRadarTick, GameTurn,
; ShowStrength): the game goes on while a menu waits. A destroyed robot (+$01 =
; 0) drops ListMenu's return address and closes the robot menu
; (CloseRobotMenu). Up / down move by one item (items 1 to E - 1) with a click
; $14; fire paints the item $4F, beeps $64 and returns A. Attributes: $4D
; normal, $4E highlighted, $4F chosen. Needs IX = a robot record.
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
PaintMenuItemRow:
  ADD HL,DE               ; HL += 3 attribute rows, A times: item A's top row
  DJNZ PaintMenuItemRow
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
; Keeps BC and HL. Uses WaitKey, so key 1 still pauses.
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
