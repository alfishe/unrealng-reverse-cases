; --------------------------------------------------------------------------------------------------------------------
; robotmenu.asm: the robot menu and its submenus: orders, distance, targets, combat, direct control
;
; The menus the player gets by landing the ship on top of a robot of ours. They all draw in the right panel (PanelBusy
; = 1 keeps UpdateStatusPanel off it) and work on IX = the robot record; the record fields are: +$0A the control (1
; the player sits on it, 2 direct control), +$0B the order, +$0E the order's target or miles x 2, +$07 the parts, +$0C
; the strength.
;
; In calling order: RobotMenu (from PlayLoop) -> RobotMenuShow (draw) -> ShowOrder, ShowOrderMiles -> RobotMenuChoose.
; Its items: 1 DirectControlItem -> DirectControl; 2 OrdersMenu -> OrdersMenuChoose -> the distance menu (AdvanceTitle
; / RetreatTitle, DistanceMenu, DistanceSelect, DistanceShow, DistanceFire) or TargetMenu / CaptureMenu ->
; DestroyMenuChoose / CaptureMenuChoose -> SetOrder; 3 CombatMenu -> CombatMenuCode; 4 LeaveRobot -> CloseRobotMenu.
; Every submenu ends in a JP to RobotMenuShow, LEAVE ROBOT and a destroyed robot in CloseRobotMenu.
;
; The shared parts: ListMenu runs every list (an item every 3 character rows, 2 rows x 8 attributes, $4D normal, $4E
; highlighted, $4F chosen; PaintMenuItem colours one) and plays one game turn per pass, so the world goes on while a
; menu waits; ShowStrength prints the robot's strength every pass; WaitRelease waits for all controls up.
;
; The texts are PrintInline strings right after the CALL (code 1 Y X a position, 2 A an attribute, 3 the next line in
; the same column, 0 the end). ShowOrder copies the order's 27-byte name from OrderNames into OrderLine, the string
; after its own PrintInline call. The order numbers the menus give: 0 stop, 1 advance, 2 retreat, 3-5 destroy robots /
; factories / warbases, 6-8 capture neutral factories / enemy factories / enemy warbases.
; --------------------------------------------------------------------------------------------------------------------

; landing on a robot of ours: DIRECT CONTROL, GIVE ORDERS, COMBAT MODE, LEAVE
; ROBOT; the order to +$0B
;
; IX = IY (the record), +$0A = 1 (the robot stands: UpdateRobot returns at once
; for +$0A = 1), MenuCursor = 4 (LEAVE ROBOT first), PanelBusy = 1. Falls into
; RobotMenuShow. Called by PlayLoop when the ship rests exactly on the top of a
; robot of ours.
RobotMenu:
  PUSH IY                 ; IX = the robot record (from FindRobot)
  POP IX                  ; IX = IY
  LD (IX+$0A),$01         ; +$0A = 1: the player sits on it; the robot stops
                          ; (UpdateRobot skips it)
  LD A,$04                ; MenuCursor = 4: LEAVE ROBOT highlighted first
  LD (MenuCursor),A            ; the robot menu uses only the low byte of MenuCursor
  LD A,$01                ; $FD39 = 1: the panel shows the menu,
                          ; UpdateStatusPanel keeps off it
  LD (PanelBusy),A            ; PanelBusy = 1

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
  DEFM $01,$04,$17,$02,"M" ; AT (4,23), attribute $4D (cyan on blue, the list
                           ; menu's normal colour): the four items
  DEFM "DIRECT  ",$03," CONTROL",$03,$03 ; item 1 DIRECT CONTROL, rows 4-5
  DEFM "GIVE    ",$03,"  ORDERS",$03,$03 ; item 2 GIVE ORDERS, rows 7-8
  DEFM "COMBAT  ",$03,"    MODE",$03,$03 ; item 3 COMBAT MODE, rows 10-11
  DEFM "LEAVE   ",$03,"   ROBOT" ; item 4 LEAVE ROBOT, rows 13-14
  DEFM $01,$11,$17,$02,"F-ORDERS-",$00 ; -ORDERS- at (17,23) in $46 (yellow):
                                       ; the heading over the current order

; Robot menu: print the name of the robot's order
;
; Copies the 27-byte name of order +$0B from OrderNames ($A848 + 27 x order)
; into OrderLine, the string printed right after the CALL at $A7AA: three lines
; at (18,23), attribute $45.
ShowOrder:
  LD B,(IX+$0B)           ; B = order + 1
  INC B                   ; one more: the loop below adds 27 before the first
                          ; name
  LD HL,StrengthText+$000D ; OrderNames - 27
  LD DE,$001B             ; 27 bytes a name
OrderNameIndex:
  ADD HL,DE               ; HL += 27, order + 1 times
  DJNZ OrderNameIndex     ; order + 1 times: HL = OrderNames + 27 x order
  LD DE,OrderLine         ; into the string after the next CALL
  LD BC,$001B             ; the 27 bytes of the name, its end byte 0 included
  LDIR                    ; copy it into OrderLine
  CALL PrintInline        ; print the order's name

; The order line: (18,23), attribute $45, then the copied name
OrderLineHead:
  DEFM $01,$12,$17,$02,"E" ; AT (18,23), attribute $45 (cyan): then ShowOrder
                           ; prints OrderLine

; The order's name, 27 bytes copied from OrderNames: the image holds STOP AND
; DEFEND
;
; Filled by ShowOrder before each print; the copied name brings its own end
; byte 0. The block was saved from a running game, so the buffer holds the last
; name copied into it, order 0's "  STOP  ", "  AND   ", " DEFEND " (code 3
; between the lines), the same bytes as the first name of OrderNames.
OrderLine:
  DEFM "  STOP  ",$03,"  AND   ",$03," DEFEND ",$00 ; the order's three
                                                    ; 8-character lines and the
                                                    ; end 0, copied from
                                                    ; OrderNames by ShowOrder

; Robot menu: for ADVANCE and RETREAT, the miles under the order's name
;
; Orders 1 and 2 only: prints at (19,25) the distance +$0E / 2 with two digits
; (PrintNumber2), into the blank middle line of the order's name ("ADVANCE",
; "nn", "MILES"). Other orders jump straight to RobotMenuChoose. IX = the robot
; record.
;
; The printing tail after the inline position is ShowMilesCode ($A7DC).
ShowOrderMiles:
  LD A,(IX+$0B)           ; order 1 or 2?
  DEC A                   ; order - 1: 0 advance, 1 retreat
  CP $02                  ; anything else (stop: $FF, searches: 2-7)
  JR NC,RobotMenuChoose   ; no miles to print
  CALL PrintInline        ; the position for the number

; (19,25), the position of the miles
MilesPos:
  DEFM $01,$13,$19,$00    ; AT (19,25): the miles of ADVANCE / RETREAT, printed
                          ; into the order's blank middle line

; LD A,(IX+$0E); SRL A; CALL $D3E5
;
; The tail of ShowOrderMiles after its inline position: A = +$0E / 2 (the
; miles, stored doubled), printed with two digits and a leading space by
; PrintNumber2. Falls into RobotMenuChoose.
ShowMilesCode:
  LD A,(IX+$0E)           ; the miles, stored doubled in +$0E
  SRL A                   ; halved
  CALL PrintNumber2       ; two digits, a leading space; then falls into
                          ; RobotMenuChoose

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
; status panel (ShowStatusPanel; ListMenu also jumps there when the robot is
; destroyed while its menu is open (seen: freeing +$01 under the open menu
; closed it).
RobotMenuChoose:
  CALL ShowStrength       ; the strength
  LD HL,$5837             ; item 1 at row 4, column 23
  LD E,$05                ; four items
  LD A,(MenuCursor)            ; highlight the last choice
  CALL ListMenu           ; A = the item chosen, 1-4
  LD (MenuCursor),A            ; remembered: the menu reopens on it
  DEC A                   ; 1: DIRECT CONTROL
  JP Z,DirectControlItem  ; drive the robot, then this menu again
  DEC A                   ; 2: GIVE ORDERS
  JP Z,OrdersMenu         ; the five orders
  DEC A                   ; 3: COMBAT MODE
  JP Z,CombatMenu         ; the six combat items
LeaveRobot:
  LD A,$78                ; 4: LEAVE ROBOT
  CALL Beep               ; the beep of a choice
  XOR A                   ; +$06 = 0
  LD (IX+$06),A           ; +$06 = 0: no steps left on its course, so it picks
                          ; a new one
  LD (IX+$0A),A           ; +$0A = 0: no longer held by the player
  LD A,$05                ; climb for 5 turns
  LD (ClimbTurns),A            ; ClimbTurns = 5: the ship lifts off before the menu
                          ; could reopen
; This entry point is used by the routines at DistanceSelect, CombatMenuCode
; and ListMenu.
CloseRobotMenu:
  CALL ClearPanel         ; clear the panel and give it back to the status
                          ; display
  XOR A                   ; PanelBusy = 0: the status panel may print again
  LD (PanelBusy),A            ; PanelBusy = 0
  CALL ShowStatusPanel    ; the status panel
  RET                     ; back to PlayLoop, after its CALL Z,RobotMenu

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
  DEFM $01,$16,$17,$02,"FSTRENGTH" ; "STRENGTH" at (22,23) in $46 (yellow)
  DEFM $01,$17,$19,$02,"G",$00 ; then AT (23,25) in $47 (white): where
                               ; ShowStrength prints the value

; Print the strength +$0C as "nnn%"
;
; The tail of ShowStrength after its inline string: a negative strength is
; shown as 0; PrintNumber3 prints HL with three digits, E = $20 makes the
; leading zeros spaces; the "%" goes out through PrintCharKeep.
ShowStrengthValue:
  LD A,(IX+$0C)           ; the strength +$0C
  OR A                    ; negative: a dying robot
  JP P,l_A83B             ; 0 or more: print it
  XOR A                   ; negative (dying): print 0
l_A83B:
  LD L,A                  ; HL = the strength
  LD H,$00                ; HL = the strength, 0-127
  LD E,$20                ; leading zeros as spaces
  CALL PrintNumber3       ; three digits at (23,25)
  LD A,$25                ; "%"
  JP PrintCharKeep        ; "%" and return

; The names of the orders, 27 bytes each (order 0: STOP AND DEFEND)
;
; Nine records of 27 bytes, indexed by +$0B: three lines of 8 joined by code 3,
; ended by 0. ShowOrder copies one into OrderLine. Order 0 is " STOP ", " AND
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
; Calls DirectControl (drive the robot until fire, or until it is destroyed)
; and redraws the robot menu with RobotMenuShow. MenuCursor still holds 1, so
; the menu reopens on DIRECT CONTROL. A robot destroyed while driven:
; DirectControl returns, RobotMenuShow redraws, and ListMenu then sees +$01 = 0
; and closes the menu.
DirectControlItem:
  CALL DirectControl      ; until fire (or the robot is destroyed)
  JP RobotMenuShow        ; redraw the robot menu

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
; fire set +$0A back to 1.
DirectControl:
  LD (IX+$0A),$02         ; +$0A = 2: the robot follows Input
  LD (IX+$05),$00         ; +$05 = 0: no course of its own
  CALL WaitRelease        ; the fire that chose the item must go first
DirectControlLoop:
  CALL WorldTurn          ; a game turn with the robot driven
  CALL DrawView           ; the view
  CALL MenuRadarTick      ; the ship's radar blink
  CALL GameTurn           ; the clock and the turn pacing
  CALL ShowStrength       ; the strength
  LD A,(IX+$01)           ; destroyed: back
  OR A                    ; +$01 = 0: the slot was freed
  RET Z                   ; Z: the robot is gone, return at once
  CALL WaitKey            ; the controls
  AND $10                 ; fire: give the robot back
  JR Z,DirectControlLoop  ; no fire: the next turn
  LD (IX+$0A),$01         ; +$0A = 1: held, not driven
  LD A,$78                ; the beep of a choice
  CALL Beep               ; beep
  RET                     ; back to the menu that called it

; GIVE ORDERS: the five orders
;
; Clears the panel and prints SELECT ORDERS at (4,24) and the five items from
; (7,23): STOP AND DEFEND, ADVANCE ?? MILES, RETREAT ?? MILES, SEARCH &
; DESTROY, SEARCH & CAPTURE. Falls into OrdersMenuChoose.
OrdersMenu:
  CALL ClearPanel         ; clear the right panel
  CALL PrintInline        ; SELECT ORDERS and the five items

; GIVE ORDERS: SELECT ORDERS and the five items
OrdersMenuText:
  DEFM $01,$04,$18,$02,"GSELECT",$03,"ORDERS" ; the heading SELECT / ORDERS at
                                              ; (4,24) in $47 (white)
  DEFM $02,"M",$01,$07,$17 ; the items in $4D (cyan on blue) from (7,23), two
                           ; rows each
  DEFM "STOP AND",$03,"  DEFEND",$03,$03 ; item 1 STOP AND DEFEND, rows 7-8
  DEFM "ADVANCE ",$03,"?? MILES",$03,$03 ; item 2 ADVANCE ?? MILES, rows 10-11
  DEFM "RETREAT ",$03,"?? MILES",$03,$03 ; item 3 RETREAT ?? MILES, rows 13-14
  DEFM "SEARCH &",$03," DESTROY",$03,$03 ; item 4 SEARCH & DESTROY, rows 16-17
  DEFM "SEARCH &",$03," CAPTURE",$00 ; item 5 SEARCH & CAPTURE, rows 19-20

; GIVE ORDERS: choose; stop at once, advance / retreat ask the miles, search
; asks the target
;
; ListMenu at HL = $5897 (row 4: item 1 at row 7), E = 6, A = 1. Item 1 sets
; order 0 (stop and defend) and returns to the robot menu. Items 2 and 3 set
; order 1 (advance) or 2 (retreat) and go on to the distance menu
; (DistanceMenu, $AA19 on). Items 4 and 5 go to TargetMenu with the flags of CP
; 3 (Z = SEARCH & DESTROY).
OrdersMenuChoose:
  CALL ShowStrength       ; the strength
  LD HL,$5897             ; the attribute of item 0: row 4, column 23 (item 1
                          ; at row 7)
  LD E,$06                ; five items
  LD A,$01                ; STOP AND DEFEND highlighted first
  CALL ListMenu           ; the item, 1-5
  PUSH AF                 ; keep the item
  CALL WaitRelease        ; the fire must go
  POP AF                  ; the item back
  DEC A                   ; 1: STOP AND DEFEND
  JR NZ,OrderMove         ; not item 1
  LD (IX+$0B),A           ; order 0
  LD A,$78                ; the beep of a choice
  CALL Beep               ; beep
  JP RobotMenuShow        ; back to the robot menu, which shows the new order
OrderMove:
  CP $03                  ; 2 ADVANCE (A = 1), 3 RETREAT (A = 2; 4, 5 the
                          ; searches
  JP NC,TargetMenu        ; 3, 4 (SEARCH & DESTROY, & CAPTURE): the target
                          ; menu, Z for destroy
  LD (IX+$0B),A           ; order 1 or 2
  PUSH AF                 ; keep the order
  CALL ClearPanel         ; clear the panel for the distance menu
  POP AF                  ; the order back
  DEC A                   ; 1 advance -> 0, 2 retreat -> 1
  JR NZ,RetreatTitle      ; retreat: its own title
  CALL PrintInline        ; ADVANCE: its title, then the distance menu

; "ADVANCE " at (5,23), attribute $4F
AdvanceTitle:
  DEFM $01,$05,$17,$02,"OADVANCE ",$00 ; "ADVANCE " at (5,23) in $4F (white on
                                       ; blue): the distance menu's title

; JR $AA40, past the RETREAT title
;
; The last instruction of the ADVANCE branch of OrdersMenuChoose: after the
; "ADVANCE " title it jumps over RetreatTitle into DistanceMenu, the part both
; orders share.
AdvanceJump:
  JR DistanceMenu         ; past the RETREAT title to the shared distance menu

; GIVE ORDERS, RETREAT: the title of the distance menu
;
; The RETREAT branch of OrdersMenuChoose: prints "RETREAT " at (5,23),
; attribute $4F, then falls into DistanceMenu. The order (+$0B = 2) is already
; stored.
RetreatTitle:
  CALL PrintInline        ; the RETREAT title, then into DistanceMenu

; "RETREAT " at (5,23), attribute $4F
RetreatTitleText:
  DEFM $01,$05,$17,$02,"ORETREAT ",$00 ; "RETREAT " at (5,23) in $4F: the
                                       ; distance menu's title

; CALL PrintInline, the distance menu's texts
;
; The distance menu of ADVANCE and RETREAT, shared by both: its texts "??
; MILES" (the next line under the title), SELECT DISTANCE at (9,23), "0 MILES"
; at (13,24; then falls into DistanceSelect.
DistanceMenu:
  CALL PrintInline        ; the distance menu's texts

; The distance menu: ?? MILES, SELECT DISTANCE, 0 MILES
DistanceText:
  DEFM $03,"?? MILES"     ; "?? MILES" on the next row (6,23), under ADVANCE /
                          ; RETREAT
  DEFM $01,$09,$17,$02,"E SELECT",$03,"DISTANCE" ; " SELECT" / "DISTANCE" at
                                                 ; (9,23)-(10,23) in $45 (cyan)
  DEFM $01,$0D,$18,$02,"F0 MILES",$00 ; "0 MILES" at (13,24) in $46 (yellow):
                                      ; the first value, then DistanceAtText
                                      ; reprints it

; choose the miles, 0-50 by 5
;
; D = the miles, from 0. Each pass of DistanceLoop is one game turn
; (ShowStrength, WorldTurn, DrawView, MenuRadarTick, GameTurn; a destroyed
; robot (+$01 = 0) closes the whole menu (JP CloseRobotMenu). Then WaitKey:
; fire goes to DistanceFire; up adds 5, down takes 5 (up wins when both are
; held; a value out of 0-50 (CP $33, a negative one wraps above it) is refused.
; A change is printed at (13,23), attribute $46, by DistanceShow with the click
; $14. No release wait: a held key steps once a game turn.
;
; DistanceFire: +$0E = miles x 2; 0 miles turns the order back into 0 (stop and
; defend; the beep $78, WaitRelease, back to the robot menu.
DistanceSelect:
  LD D,$00                ; D = the miles: start at 0
; This entry point is used by the routine at DistanceShow.
l_AA70:
  PUSH DE
  CALL ShowStrength       ; the strength
  CALL WorldTurn          ; the robots and the shots go on
  CALL DrawView           ; the view
  CALL MenuRadarTick      ; the ship's radar blink
  CALL GameTurn           ; the clock and the turn pacing
  POP DE                  ; D = the miles back
  LD A,(IX+$01)           ; the robot's +$01
  OR A                    ; destroyed?
  JP Z,CloseRobotMenu     ; destroyed: close the whole menu
  CALL WaitKey            ; A = Input
  BIT 4,A                 ; fire?
  JR NZ,l_AAB8            ; fire: store the miles
  LD C,D                  ; C = the old miles
  RRCA                    ; Input bit 2 (down) and bit 3 (up)
  RRCA                    ; now in bits 0 and 1
  AND $03                 ; 1 down, 2 up, 3 both
  JR Z,l_AA70             ; neither: the next turn
  AND $02                 ; B = 0 down, 2 up (both: up)
  LD B,A                  ; B = 0 or 2
  ADD A,A                 ; x2
  ADD A,A                 ; x4
  ADD A,B                 ; x5: 0 or 10
  SUB $05                 ; -5 or +5
  ADD A,C                 ; A = the old miles +- 5
  CP $33                  ; past 50 miles?
  JR NC,l_AA70            ; past 50 or below 0 (wrapped to $FB): keep the old
                          ; value
  LD D,A                  ; D = the new miles
  CALL PrintInline        ; the position of the number

; PrintInline: (13,23), attribute $46, where the miles are printed
DistanceAtText:
  DEFM $01,$0D,$17,$02,"F",$00 ; AT (13,23), attribute $46: where DistanceShow
                               ; prints the miles as they change

; the miles in D printed (PrintNumber2), a click, back to the distance loop
;
; The tail of DistanceSelect after the inline position (13,23): prints D, the
; miles, with two digits (PrintNumber2), clicks (Beep $14) and goes back to
; DistanceLoop for the next game turn. DistanceFire ($AAB8) follows: the end of
; the distance menu.
DistanceShow:
  LD A,D                  ; the miles
  CALL PrintNumber2       ; two digits, a leading space
  LD A,$14                ; the click of a change
  CALL Beep               ; beep
  JR l_AA70               ; held keys step again after one game turn
; This entry point is used by the routine at DistanceSelect.
l_AAB8:
  LD A,D
  RLCA                    ; x2: +$0E counts map columns, 2 a mile
  LD (IX+$0E),A           ; +$0E: the distance to go
  OR A                    ; 0 miles?
  JR NZ,l_AAC4            ; not 0: the order stands
  LD (IX+$0B),$00         ; 0 miles: order 0, stop and defend
l_AAC4:
  LD A,$78
  CALL Beep               ; beep
  CALL WaitRelease        ; fire up first
  JP RobotMenuShow        ; back to the robot menu

; SEARCH & DESTROY or SEARCH & CAPTURE: the three targets
;
; Z (the destroy item): clears the panel and prints SEARCH & DESTROY, SELECT
; TARGET and ENEMY ROBOTS / ENEMY FACTORYS / ENEMY WARBASES; NZ goes to
; CaptureMenu.
TargetMenu:
  JP NZ,CaptureMenu       ; SEARCH & CAPTURE
  CALL ClearPanel         ; clear the right panel
  CALL PrintInline        ; SEARCH & DESTROY and its three targets

; SEARCH & DESTROY: SELECT TARGET, ENEMY ROBOTS, FACTORYS, WARBASES
DestroyMenuText:
  DEFM $01,$04,$17,$02,"OSEARCH &",$03," DESTROY" ; the title SEARCH & /
                                                  ; DESTROY at (4,23)-(5,23) in
                                                  ; $4F (white on blue)
  DEFM $01,$08,$18,$02,"ESELECT",$03,"TARGET" ; SELECT / TARGET at
                                              ; (8,24)-(9,24) in $45 (cyan)
  DEFM $01,$0C,$17,$02,"M" ; the items in $4D from (12,23), two rows each
  DEFM "ENEMY   ",$03,"  ROBOTS",$03,$03 ; item 1 ENEMY ROBOTS (order 3), rows
                                         ; 12-13
  DEFM "ENEMY   ",$03,"FACTORYS",$03,$03 ; item 2 ENEMY FACTORYS (order 4),
                                         ; rows 15-16
  DEFM "ENEMY   ",$03,"WARBASES",$00 ; item 3 ENEMY WARBASES (order 5), rows
                                     ; 18-19

; SEARCH & DESTROY: choose the target, orders 3-5
;
; ListMenu at HL = $5937 (item 1 at row 12), E = 4, A = 1; the item + 2 is the
; order (3 robots, 4 factories, 5 warbases) for SetOrder.
DestroyMenuChoose:
  CALL ShowStrength       ; the strength
  LD HL,$5937             ; the attribute of item 0: row 9, column 23 (item 1
                          ; at row 12)
  LD A,$01                ; ENEMY ROBOTS highlighted first
  LD E,$04                ; three items
  CALL ListMenu           ; A = the target, 1-3
  ADD A,$02               ; order 3-5
  JR SetOrder             ; store it, find the target

; SEARCH & CAPTURE: the three targets
;
; Prints SEARCH & CAPTURE, SELECT TARGET and NEUTRAL FACTORYS / ENEMY FACTORYS
; / ENEMY WARBASES.
CaptureMenu:
  CALL ClearPanel         ; clear the right panel
  CALL PrintInline        ; SEARCH & CAPTURE and its three targets

; SEARCH & CAPTURE: SELECT TARGET, NEUTRAL FACTORYS, ENEMY FACTORYS, ENEMY
; WARBASES
CaptureMenuText:
  DEFM $01,$04,$17,$02,"OSEARCH &",$03," CAPTURE" ; the title SEARCH & /
                                                  ; CAPTURE at (4,23)-(5,23) in
                                                  ; $4F (white on blue)
  DEFM $01,$08,$18,$02,"ESELECT",$03,"TARGET" ; SELECT / TARGET at
                                              ; (8,24)-(9,24) in $45 (cyan)
  DEFM $01,$0C,$17,$02,"M" ; the items in $4D from (12,23), two rows each
  DEFM "NEUTRAL ",$03,"FACTORYS",$03,$03 ; item 1 NEUTRAL FACTORYS (order 6),
                                         ; rows 12-13
  DEFM "ENEMY   ",$03,"FACTORYS",$03,$03 ; item 2 ENEMY FACTORYS (order 7),
                                         ; rows 15-16
  DEFM "ENEMY   ",$03,"WARBASES",$00 ; item 3 ENEMY WARBASES (order 8), rows
                                     ; 18-19

; SEARCH & CAPTURE: choose the target, orders 6-8
;
; The same list as DestroyMenuChoose; the item + 5 is the order (6 neutral
; factories, 7 enemy factories, 8 enemy warbases).
CaptureMenuChoose:
  CALL ShowStrength       ; the strength
  LD HL,$5937             ; the attribute of item 0: row 9, column 23
  LD A,$01                ; NEUTRAL FACTORYS highlighted first
  LD E,$04                ; three items
  CALL ListMenu           ; A = the target, 1-3
  ADD A,$05               ; order 6-8

; Store a search order, look for its first target, or fall back to stop
;
; A = the order (3-8) into +$0B. Orders 4 and 5 (destroy factories, warbases)
; need the nuclear bomb (+$07 bit 6; without it the order becomes 0. Otherwise
; $FD51 = 0 (our side), +$0E = $FF and FindTargetBuilding looks for a target of
; the order from the robot's X (+$02/+$03): D, the index it found, goes to
; +$0E; no target (Z) makes the order 0. A beep, WaitRelease, back to the robot
; menu.
;
; CombatMenu ($AC00) follows in the same block: the robot menu's item 3.
SetOrder:
  LD (IX+$0B),A           ; +$0B = the order
  CP $04                  ; orders 4 and 5 need the bomb
  JR C,FindOrderTarget    ; 3: destroy robots, no bomb needed
  CP $06                  ; 6-8: the captures
  JR NC,FindOrderTarget   ; no bomb needed
  BIT 6,(IX+$07)          ; the nuclear part, +$07 bit 6?
  JR Z,OrderRefused       ; no bomb: buildings cannot be destroyed
FindOrderTarget:
  LD L,(IX+$02)           ; HL = the robot's X
  LD H,(IX+$03)           ; the column's high byte (0-511)
  PUSH AF                 ; keep the order
  XOR A                   ; side 0
  LD (Side),A            ; $FD51 = 0: the search runs for our side
  POP AF                  ; A = the order for the search
  LD (IX+$0E),$FF         ; no target yet
  CALL FindTargetBuilding ; Z: nothing to go for
  LD (IX+$0E),D           ; the target found
  JR NZ,OrderSet          ; found: keep the order
OrderRefused:
  LD (IX+$0B),$00         ; order 0: stop and defend
OrderSet:
  LD A,$78                ; the beep of a choice
  CALL Beep               ; beep
  CALL WaitRelease        ; fire up first
  JP RobotMenuShow        ; back to the robot menu, which shows the order
; This entry point is used by the routine at RobotMenuChoose.
CombatMenu:
  CALL ClearPanel         ; COMBAT MODE: the six items, then the code at $AC7C
  CALL PrintInline        ; the six combat items, then the code at $AC7C

; COMBAT MODE: NUCLEAR BOMB, FIRE PHASERS, FIRE MISSILES, FIRE CANNON, MOVE
; ROBOT, STOP COMBAT
;
; Printed at (4,23), attribute $4D, an item every 3 rows like the robot menu.
CombatMenuText:
  DEFM $01,$04,$17,$02,"M" ; AT (4,23) in $4D (cyan on blue), two rows an item
  DEFM "NUCLEAR ",$03,"    BOMB",$03,$03 ; item 1 NUCLEAR BOMB (part bit 6 of
                                         ; +$07), rows 4-5
  DEFM "FIRE    ",$03," PHASERS",$03,$03 ; item 2 FIRE PHASERS (bit 5), rows
                                         ; 7-8
  DEFM "FIRE    ",$03,"MISSILES",$03,$03 ; item 3 FIRE MISSILES (bit 4), rows
                                         ; 10-11
  DEFM "FIRE    ",$03,"  CANNON",$03,$03 ; item 4 FIRE CANNON (bit 3), rows
                                         ; 13-14
  DEFM "MOVE    ",$03,"   ROBOT",$03,$03 ; item 5 MOVE ROBOT (DirectControl),
                                         ; rows 16-17
  DEFM "STOP    ",$03,"  COMBAT",$00 ; item 6 STOP COMBAT (back to the robot
                                     ; menu), rows 19-20

; the combat menu
;
; The code after CombatMenuText: the strength, then ListMenu on the six items
; (HL = $5837, E = 7), STOP COMBAT highlighted first. Each choice comes back to
; CombatMenuLoop with A = the item, so the menu reopens on it.
;
; 6 STOP COMBAT: back to the robot menu. 5 MOVE ROBOT: DirectControl, then the
; menu again. 1-4 need the weapon: +$07 rotated left item + 1 times leaves in
; carry bit 6 (nuclear), 5 (phasers), 4 (missiles) or 3 (cannon; without it the
; low buzz ($FA) and the menu again.
;
; 1 NUCLEAR BOMB: IY = IX, NuclearBlast, then the menu closes (JP
; CloseRobotMenu): the bomb destroys the robot carrying it. 2-4: shot record 0
; at $D7D3 (Shots; if it is free (+$01 = 0), A = 5 - item (3 phasers, 2
; missiles, 1 cannon) and FireShot launches it from the robot along its facing
; (+$08), then DrawView and GameTurn; a shot of record 0 still flying buzzes.
;
; FIRE MISSILES without missiles changed nothing.
CombatMenuCode:
  CALL ShowStrength       ; the strength
  LD A,$06                ; STOP COMBAT highlighted first
l_AC81:
  LD HL,$5837
  LD E,$07                ; six items
  CALL ListMenu           ; A = the item, 1-6
  CP $06                  ; 6: STOP COMBAT
  JP Z,RobotMenuShow      ; back to the robot menu
  PUSH AF                 ; keep the item
  CP $05                  ; 5: MOVE ROBOT?
  JR NZ,l_AC99            ; 1-4: a weapon
  CALL DirectControl      ; drive the robot until fire
  POP AF                  ; A = 5: the menu reopens on MOVE ROBOT
  JR l_AC81               ; the combat list again
l_AC99:
  LD C,A
  LD B,A                  ; B = item + 1 rotations
  INC B                   ; B = item + 1
  LD A,(IX+$07)           ; the robot's parts
l_AC9F:
  RLCA
  DJNZ l_AC9F             ; item 1 bit 6 nuclear, 2 bit 5 phasers, 3 bit 4
                          ; missiles, 4 bit 3 cannon
  JR NC,l_ACCE            ; no such part: the buzz
  POP AF                  ; the item back (the stack clean)
  CP $01                  ; 1: NUCLEAR BOMB?
  JR NZ,l_ACB3            ; 2-4: a shot
  PUSH IX                 ; IY = the robot: the blast's centre
  POP IY                  ; IY = IX
  CALL NuclearBlast       ; a base in reach, every robot in 9 x 9 cells and
                          ; this robot destroyed
  JP CloseRobotMenu       ; the robot is gone with it: close the menu
l_ACB3:
  PUSH AF
  LD IY,Shots             ; shot record 0 (Shots), the only one COMBAT MODE
                          ; uses
  LD A,(IY+$01)           ; its +$01
  OR A                    ; flying?
  JR NZ,l_ACCE            ; still in the air: the buzz
  LD A,$05                ; A = 5 - item: 3 phasers, 2 missiles, 1 cannon
  SUB C                   ; the weapon number of the shot
  CALL FireShot           ; launch it from IX along its facing +$08
  CALL DrawView           ; the view with the shot
  CALL GameTurn           ; the turn's clock and pacing
  POP AF                  ; the item back
  JP l_AC81               ; the menu again on the same weapon
l_ACCE:
  LD A,$FA
  CALL Beep               ; the low buzz
  POP AF                  ; the item back
  JP l_AC81               ; the menu again on that item

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
  CALL WaitRelease        ; all controls up
  POP AF                  ; A = the first item
  LD D,A                  ; D = the highlighted item
  LD C,$4E                ; $4E: highlighted
  CALL PaintMenuItem      ; paint it highlighted
ListMenuLoop:
  LD A,(IX+$01)           ; the robot destroyed (+$01 = 0)?
  OR A                    ; +$01 = 0: the slot was freed
  JR NZ,ListMenuKey       ; alive: read the controls
  POP HL                  ; drop our return: close the robot menu
  JP CloseRobotMenu       ; the whole robot menu closed, back to PlayLoop
ListMenuKey:
  PUSH HL                 ; the controls
  CALL WaitKey            ; the controls into Input (key 1 pauses)
  POP HL                  ; HL = the attribute of item 0 again
  LD C,D                  ; C = the highlighted item
  LD A,(Input)            ; Input: bit 2 down, bit 3 up, bit 4 fire
  BIT 4,A                 ; fire: chosen
  JR NZ,ListMenuChosen    ; fire: the item is chosen
  RRCA                    ; bit 2 down / bit 3 up, now bits 1 / 2
  AND $06                 ; down or up?
  JR Z,ListMenuTurn       ; neither: one game turn and read again
  AND $02                 ; A = 2 for down, 0 for up
  DEC C                   ; item - 1, then + 2 for down
  ADD A,C                 ; A = the new item
  JR Z,ListMenuTurn       ; item 0 does not exist
  CP E                    ; past the last item
  JR NC,ListMenuTurn      ; no move: one game turn
  PUSH AF                 ; keep the new item
  LD A,D                  ; the old item
  LD C,$4D                ; $4D: the old item back to normal
  CALL PaintMenuItem      ; back to normal
  POP AF                  ; A = the new item
  LD D,A                  ; D = the new item
  LD C,$4E                ; highlight the new one
  CALL PaintMenuItem      ; in $4E
  LD A,$14                ; the click of a move
  CALL Beep               ; beep
ListMenuTurn:
  PUSH DE                 ; a game turn while the menu waits
  PUSH HL                 ; and the attribute address
  CALL WorldTurn          ; the robots and the shots go on
  CALL DrawView           ; the view
  CALL MenuRadarTick      ; the ship's radar blink
  CALL GameTurn           ; the clock and the turn pacing (at least 10 frames a
                          ; pass)
  CALL ShowStrength       ; the strength
  POP HL                  ; HL = the attribute of item 0
  POP DE                  ; D = the item, E = the items + 1
  JR ListMenuLoop         ; check the robot, the next key
ListMenuChosen:
  LD A,D                  ; $4F: the chosen item
  LD C,$4F                ; attribute $4F
  CALL PaintMenuItem      ; paint the chosen item
  LD A,$64                ; the beep of a choice
  CALL Beep               ; beep
  LD A,D                  ; A = the item
  RET                     ; A = the item chosen

; Colour list item A: 2 rows of 8 attributes with C
;
; HL = the attribute of item 0; item A starts $60 bytes (3 rows) further per
; item. Fills 8 attributes, moves down a row ($18 more) and fills 8 more with C
; ($4D normal, $4E highlighted, $4F chosen). A must be 1 or more. Keeps DE and
; HL.
PaintMenuItem:
  LD B,A                  ; B = the item: the row loop count
  PUSH DE                 ; kept for the caller
  PUSH HL                 ; kept: the attribute of item 0
  LD DE,$0060             ; 3 attribute rows an item
l_AD42:
  ADD HL,DE
  DJNZ l_AD42             ; A times
  LD B,$08                ; the item's top row
  CALL FillAttributes     ; 8 cells in C
  LD A,$18                ; the next row, same column
  CALL AddAToHL           ; HL += $18: 8 cells already passed, so the next
                          ; row's same column
  LD B,$08                ; its bottom row
  CALL FillAttributes     ; 8 cells in C
  POP HL                  ; the attribute of item 0 back
  POP DE                  ; DE back
  RET                     ; done

; wait until no control is held
;
; Calls WaitKey until Input is 0: every control up. Used by every menu before
; it reads a new press, so the fire that chose an item does not choose again.
; Keeps BC and HL; A = 0 on return. Uses WaitKey, so key 1 still pauses.
WaitRelease:
  PUSH BC                 ; kept
  PUSH HL                 ; kept
WaitReleaseLoop:
  CALL WaitKey            ; until Input is 0
  OR A                    ; anything held?
  JR NZ,WaitReleaseLoop   ; still held: read again
  POP HL                  ; HL back
  POP BC                  ; BC back
  RET                     ; all up
