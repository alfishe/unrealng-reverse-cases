; landing on the warbase pad at altitude 15: choose the parts (MenuCursor,
; MenuParts), START ROBOT or EXIT MENU
;
; Returns at once when all 24 player slots are used; the free slot is the
; preview and then the new robot; the world stands still (StartInterrupt) while
; it is open.
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
;
; The second row is the resource index (6 chassis x3, 5 cannon, 4 missiles, 3
; phasers, 2 nuclear, 1 electronics); what the own resource lacks comes from
; general (index 0).
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
  JR NC,PartRowPaint
  LD E,$47                ; chosen: bright white
PartRowPaint:
  PUSH BC                 ; paint the part's 4 x 3 cells in attribute E
  LD BC,$0403             ; 4 cells by 3 rows
PartRowLine:
  PUSH BC                 ; one attribute row of the part's 4 cells
PartCellLoop:
  LD (HL),E
  INC HL
  DJNZ PartCellLoop
  LD A,$1C                ; to the next attribute row (32 - 4)
  CALL AddAToHL
  POP BC
  DEC C
  JR NZ,PartRowLine
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
PreviewByteLoop:
  LD A,(DE)               ; copy B bytes of the buffer row to the screen line
  LD (HL),A
  INC DE
  INC HL
  DJNZ PreviewByteLoop
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
