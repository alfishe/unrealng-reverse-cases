; --------------------------------------------------------------------------------------------------------------------
; construction.asm: the construction menu, robot placement on the map, the beeper tone
;
; The screen the player gets by landing the ship on the pad of our warbase (NE's docs/05-controls.md 5.4, NE's
; docs/01-game-design.md 1.6, the rules in NE's docs/10-gameplay-logic.md 10.3). PlayLoop calls ConstructionMenu; it
; takes a free slot among our 24 robot records (IY) as the preview, builds the screen and runs its own key loop until
; START ROBOT or EXIT MENU; then the play screen is redrawn and PlayLoop gives the new robot its start state.
;
; In calling order: ConstructionMenu (find the slot, the part pictures, the text) -> ConstructionMenuSetup ->
; ConstructionMenuLoop (fire on a part: PartToggle, RefundPart; a direction: MoveMenuCursor) -> MenuPause after every
; press -> StartRobot (PlaceRobot) or LeaveConstructionMenu. Helpers: PaintMenuCursor and FillAttributes,
; PrintMenuResources (PrintMenuResource, PrintMenuTotal), ShowRobotDesign (the part colours and the preview robot
; drawn by DrawRobot through the view buffer).
;
; The data: MenuCursor = (L the column: 0 EXIT MENU, 1 START ROBOT, 2 the parts; H the part row 0 bipod ... 7
; electronics), MenuParts = the chosen parts, one bit a row (the new robot's +$07), MenuResources = the copy of
; Resources the menu spends, written back only by START ROBOT. PartCosts holds the eight costs and, 8 bytes on, the
; resource each part pays from first; the general resource pays the rest.
;
; The world stands still while the menu is open: the menu loop runs no game turns, and Handler is StartInterrupt (no
; frame count, no radar drawing over the menu screen). MenuPause is 10 HALTs after every press; a press inside it is
; lost. PrintMenuResource patches the row byte of its own inline position string ($CC11) before each print.
;
; The tail of the module is shared with the rest of the game: PlaceRobot puts any robot on the map (the robot step,
; the enemy spawn, START ROBOT), ShipCell / MapCell give the map cell of a column and row ($DD00 + $200 x row +
; column), Beep is the menus' beeper tone.
; --------------------------------------------------------------------------------------------------------------------

; landing on the warbase pad at altitude 15: choose the parts (MenuCursor,
; MenuParts), START ROBOT or EXIT MENU
;
; Called by PlayLoop when the ship rests on the pad of our warbase (Altitude
; 15) and the door below is free. First looks for a free record among our slots
; 0-23 ($DA00 + 16 x n, +$01 = 0); with none it returns at once (IY = $DB80,
; enemy slot 24: the bug of PlayLoop's writes, NE's docs/10-gameplay-logic.md
; 10.12).
;
; Otherwise IY = the free slot: the preview robot, and on START ROBOT the new
; one. Handler = StartInterrupt, so neither the frame count nor the radar runs;
; the menu loop runs no game turns, so the world stands still while the menu is
; open. ClearScreen, then the eight part pictures in column 16 from the bottom
; (bipod) to the top (electronics), each the second facing of the part's sprite
; cut to 24 lines and drawn upwards by DrawMaskedUp; the preview's frame
; attributes ($46, 4 x 9 cells from row 15, column 0); the texts (title, part
; names, EXIT / START, costs, the resource labels). Falls into
; ConstructionMenuSetup.
;
; Returns (after LeaveConstructionMenu) with IY = the slot; PlayLoop then
; writes the start state. On EXIT MENU the slot stays free (+$01 = 0,
; PlaceRobot not called), so those writes do no harm.
ConstructionMenu:
  LD IY,$DA00             ; the player's robot slots 0-23
  LD DE,$0010             ; 16 bytes a record
  LD B,$18                ; 24 slots
FindFreeRobotSlot:
  LD A,(IY+$01)           ; a slot whose cell address high byte is 0 is free
  OR A                    ; 0?
  JR Z,OpenConstructionMenu ; a free slot: open the menu
  ADD IY,DE               ; the next record
  DJNZ FindFreeRobotSlot  ; all 24 slots
  RET                     ; all 24 slots in use: no menu at all
OpenConstructionMenu:
  DI                      ; IY = the free slot: it becomes the preview robot
                          ; and, on START ROBOT, the new robot
  LD HL,StartInterrupt    ; the play interrupt off (StartInterrupt only
                          ; re-enables): the world stands still while the menu
                          ; is open
  LD (Handler),HL           ; Handler = StartInterrupt
  EI                      ; interrupts again
  CALL ClearScreen        ; clear the screen
  LD B,$08                ; the eight part pictures, bipod at the bottom
  LD DE,$57F0             ; the bottom pixel line of row 23, column 16
PartIconLoop:
  PUSH BC                 ; part k = 8 - B
  PUSH DE                 ; the screen address
  LD A,$08                ; the part's sprite number for the second facing:
                          ; $D6C8 + 4k + 1
  SUB B                   ; A = k
  ADD A,A                 ; 2k
  ADD A,A                 ; 4k: four facings a part
  INC A                   ; the second facing
  LD HL,PartSpriteTable   ; PartSpriteTable + 4k + 1
  CALL AddAToHL           ; HL = the entry
  LD A,(HL)               ; the second graphic of that sprite: the pointer at
                          ; $D740 + 4 * number + 2
  ADD A,A                 ; 2 x the number
  INC A                   ; + 1: its second graphic
  LD HL,SpriteTable+$0058 ; the part sprites' pointers (sprite id $16 on)
  CALL TableWord          ; HL = that graphic
  LD C,(HL)               ; C = the lines, B = the bytes a line
  INC HL                  ; to the width byte
  LD B,(HL)               ; B = the bytes a line
  INC HL                  ; HL = the first line
  LD A,B                  ; skip the graphic's first line of mask / pixel pairs
  ADD A,A                 ; 2 bytes (mask, pixels) a byte of width
  CALL AddAToHL           ; HL = the second line
  DEC C                   ; the lines after the first, at most 24 (3 rows)
  LD A,C                  ; the lines left
  CP $18                  ; more than 24?
  JR C,PartIconDraw       ; fits
  LD C,$18                ; cut to 24 lines, the part's 3 character rows
PartIconDraw:
  CALL DrawMaskedUp       ; draw upwards from DE, masked
  POP DE                  ; DE = the bottom line of this part's place
  POP BC                  ; B = the parts left
  LD A,E                  ; three character rows up
  SUB $60                 ; the low byte - 3 x 32
  LD E,A                  ; E = it
  JR NC,PartIconNext      ; no borrow: the same third of the screen
  LD A,D                  ; a borrow: the third above
  SUB $08                 ; D - 8: one screen third up
  LD D,A                  ; D = it
PartIconNext:
  DJNZ PartIconLoop       ; all eight parts, bottom to top
  LD BC,$0409             ; the preview's frame: 4 columns x 9 rows from row
                          ; 15, column 0
  LD HL,$59E0             ; the attribute of row 15, column 0
PreviewAttrRow:
  PUSH BC                 ; C = the rows left
PreviewAttrCell:
  LD (HL),$46             ; bright yellow
  INC HL                  ; the next cell
  DJNZ PreviewAttrCell    ; four cells
  LD A,$1C                ; to the next row: 4 + 28
  CALL AddAToHL           ; HL = the next row's column 0
  POP BC                  ; C = the rows left
  DEC C                   ; one row done
  JR NZ,PreviewAttrRow    ; nine rows
  CALL PrintInline        ; the menu's text

; PrintInline text: "ROBOT" (double size) at row 0, "CONSTRUCTION" (double
; height) at row 2
;
; Setting $22 = double height, double width; $21 = double height; $00 = normal
; (PrintInline code 4: high nibble the height, low nibble the width).
ConstructionTitleText:
  DEFM $04,"\"",$02,"G",$01,$00,$03,"ROBOT" ; size $22 (double size), $47
                                            ; (white): "ROBOT" at (0,3), rows
                                            ; 0-1
  DEFM $01,$02,$02,$04,"!CONSTRUCTION",$04,$00 ; "CONSTRUCTION" at (2,2), size
                                               ; $21 (tall), rows 2-3; then
                                               ; size 0

; PrintInline text: the part names at column 21, ELECTRONICS row 1 down to
; BIPOD row 22, every 3 rows
PartNamesText:
  DEFM $02,"E",$01,$01,$15,"ELECTRONICS" ; the part names in $45 (cyan), column
                                         ; 21: ELECTRONICS, row 1
  DEFM $01,$04,$15,"NUCLEAR" ; NUCLEAR, row 4
  DEFM $01,$07,$15,"PHASERS" ; PHASERS, row 7
  DEFM $01,$0A,$15,"MISSILES" ; MISSILES, row 10
  DEFM $01,$0D,$15,"CANNON" ; CANNON, row 13
  DEFM $01,$10,$15,"ANTI-GRAV" ; ANTI-GRAV, row 16
  DEFM $01,$13,$15,"TRACKS" ; TRACKS, row 19
  DEFM $01,$16,$15,"BIPOD" ; BIPOD, row 22

; PrintInline text: "EXIT START" / "MENU ROBOT" at rows 21-22, columns 5 and 10
ExitStartText:
  DEFM $01,$15,$05,"EXIT START",$03,"MENU ROBOT" ; the buttons EXIT MENU
                                                 ; (column 5) and START ROBOT
                                                 ; (column 10), rows 21-22

; PrintInline text: the costs under the names at column 22: 3 20 4 4 2 10 5 3
; (the same numbers as PartCosts)
PartCostsText:
  DEFM $02,"C",$01,$02,$16,"3" ; the costs in $43 (magenta), column 22:
                               ; electronics 3, row 2
  DEFM $01,$05,$16,"20"   ; nuclear 20, row 5
  DEFM $01,$08,$16,"4"    ; phasers 4, row 8
  DEFM $01,$0B,$16,"4"    ; missiles 4, row 11
  DEFM $01,$0E,$16,"2"    ; cannon 2, row 14
  DEFM $01,$11,$16,"10"   ; anti-grav 10, row 17
  DEFM $01,$14,$16,"5"    ; tracks 5, row 20
  DEFM $01,$17,$16,"3"    ; bipod 3, row 23

; PrintInline text: "-- RESOURCES --" / "-- AVAILABLE --", GENERAL row 9,
; ELECTRONICS-CHASSIS rows 11-16, TOTAL row 18
ResourceNamesText:
  DEFM $04,$00,$02,"F",$01,$06,$00,"-- RESOURCES --" ; size 0, $46 (yellow):
                                                     ; "-- RESOURCES --" at
                                                     ; (6,0)
  DEFM $03,"-- AVAILABLE --" ; "-- AVAILABLE --" at (7,0)
  DEFM $02,"D",$01,$09,$04,"GENERAL" ; the names in $44 (green), ending at
                                     ; column 10: GENERAL (9,4)
  DEFM $01,$0B,$00,"ELECTRONICS" ; ELECTRONICS (11,0)
  DEFM $01,$0C,$04,"NUCLEAR" ; NUCLEAR (12,4)
  DEFM $03,"PHASERS"      ; PHASERS (13,4)
  DEFM $01,$0E,$03,"MISSILES" ; MISSILES (14,3)
  DEFM $01,$0F,$05,"CANNON" ; CANNON (15,5)
  DEFM $01,$10,$04,"CHASSIS" ; CHASSIS (16,4)
  DEFM $01,$12,$06,"TOTAL",$00 ; TOTAL (18,6), then the end of the 297-byte
                               ; string

; reset the preview robot, copy the resources, cursor on BIPOD, nothing chosen
;
; Continues ConstructionMenu after its text. The free slot's +8 is set to 4 and
; +$0D to 0 (the built robot keeps +8 = 4: NE's work/deep frame 360, slot 0 =
; 16 EF 16 00 09 00 00 09 04 11 ...). Resources are copied to MenuResources,
; which the menu spends; MenuCursor = column 2 (the parts), row 0 (bipod);
; MenuParts = 0; ShowRobotDesign paints the part pictures (white when chosen)
; and draws the preview robot; the cursor is painted.
ConstructionMenuSetup:
  LD (IY+$08),$04         ; +$08 = 4: the preview faces down (the robot built
                          ; keeps it)
  LD (IY+$0D),$00         ; +$0D = 0: the preview stands on ground 0
  LD HL,Resources             ; the menu spends a copy
  LD DE,MenuResources             ; into MenuResources
  LD BC,$0007             ; general and the six part resources
  LDIR                    ; copy
  CALL PrintMenuResources ; print the copy
  LD HL,$0002             ; column 2 (the parts), row 0 (bipod)
  LD (MenuCursor),HL           ; MenuCursor = (2, 0)
  XOR A                   ; nothing chosen
  LD (MenuParts),A            ; MenuParts = 0
  CALL ShowRobotDesign    ; the part pictures and the preview robot
  LD C,$46                ; the cursor in $46
  CALL PaintMenuCursor    ; paint the cursor

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
  AND $1F                 ; bits 0-4: right, left, down, up, fire
  JR Z,ConstructionMenuLoop ; nothing (keys 5 and I do nothing here)
  LD HL,(MenuCursor)           ; L = the column, H = the part row
  LD A,(Input)            ; no fire: a move
  AND $10                 ; fire?
  JP Z,MoveMenuCursor     ; a direction: move the cursor
  LD A,L                  ; column 0: EXIT MENU
  OR A                    ; column 0?
  JP Z,LeaveConstructionMenu ; EXIT MENU
  DEC A                   ; column 1: START ROBOT
  JP Z,StartRobot         ; START ROBOT
PartToggle:
  LD A,H                  ; E = the part, D = its bit
  LD E,A                  ; E = the part row, 0-7
  LD B,A                  ; B = row + 1
  INC B                   ; B = row + 1 shifts
  XOR A                   ; A = 0
  SCF                     ; carry = 1: the bit to shift in
PartBitLoop:
  RLA                     ; shift it up
  DJNZ PartBitLoop        ; row + 1 times: A = 1 << row
  LD D,A                  ; D = the part's bit in MenuParts
  LD A,(MenuParts)            ; C = the parts chosen
  LD C,A                  ; C = MenuParts
  AND D                   ; chosen already: take it back
  JR NZ,PartTakeBack      ; refund and clear it
  LD A,E                  ; a chassis (rows 0-2) ...
  CP $03                  ; rows 0-2: bipod, tracks, anti-grav
  JR NC,CheckWeaponCount  ; a weapon or electronics: no chassis rule
  LD A,C                  ; ... and a chassis already chosen: refund that one
                          ; first
  AND $07                 ; the chassis bits 0-2
  JR Z,CheckWeaponCount   ; no chassis yet
  PUSH DE                 ; E = the chosen chassis' row
  LD E,$FF                ; E = -1, so the first INC gives 0
FindChosenChassis:
  INC E                   ; the next row
  RRCA                    ; the next bit into carry
  JR NC,FindChosenChassis ; until the set bit
  CALL RefundPart         ; its resources back
  LD A,C                  ; no chassis now
  AND $F8                 ; clear the chassis bits
  LD C,A                  ; C = the parts without a chassis
  LD (MenuParts),A            ; stored at once: the refund stays even if the new
                          ; chassis is refused
  POP DE                  ; E, D = the new part again
CheckWeaponCount:
  LD A,C                  ; cannon + missiles + phasers + nuclear all four:
                          ; refused
  OR D                    ; with the new part
  AND $78                 ; the weapon bits 3-6
  CP $78                  ; all four?
  JP Z,PartRefused        ; a fourth weapon: refused
  LD HL,PartCosts         ; B = the part's cost
  LD A,E                  ; the part
  CALL AddAToHL           ; HL = PartCosts + part
  LD B,(HL)               ; B = the cost
  LD HL,PartCosts+$0008   ; the resource it takes first
  LD A,E                  ; the part
  CALL AddAToHL           ; HL = PartCosts + 8 + part
  LD A,(HL)               ; A = the resource index (1-6)
  LD HL,MenuResources             ; the menu's resources
  CALL AddAToHL           ; HL = that resource
  LD A,(HL)               ; pay from the part's own resource
  SUB B                   ; minus the cost
  JP NC,PartPaid          ; enough: what is left
  NEG                     ; short by the rest: the general resource pays it
  LD B,A                  ; B = what the general resource must pay
  LD A,(MenuResources)            ; the general resource
  SUB B                   ; minus the rest
  JP C,PartRefused        ; not enough: refused
  LD (MenuResources),A            ; the general resource pays it
  XOR A                   ; the own resource is spent to 0
PartPaid:
  LD (HL),A               ; store what is left, choose the part
  LD A,C                  ; the parts
  OR D                    ; with the new one
  LD (MenuParts),A            ; MenuParts
  LD A,$64                ; the beep of a part accepted
  CALL Beep               ; beep
  CALL ShowRobotDesign    ; repaint the part pictures and the preview
  CALL PrintMenuResources ; reprint the resources
AcceptFireUp:
  CALL WaitKey            ; wait for fire up
  AND $10                 ; fire still held?
  JR NZ,AcceptFireUp      ; wait
  JP MenuPause            ; the 10-frame pause, then the loop
PartTakeBack:
  CALL RefundPart         ; refund and clear the part
  LD A,C                  ; the parts
  XOR D                   ; the part's bit off
  LD (MenuParts),A            ; MenuParts
PartRefused:
  LD A,$78                ; refused or taken back: the low beep
  CALL Beep               ; beep
  CALL ShowRobotDesign    ; repaint the part pictures and the preview
  CALL PrintMenuResources ; reprint the resources
RefuseFireUp:
  CALL WaitKey            ; wait for fire up
  AND $10                 ; fire still held?
  JR NZ,RefuseFireUp      ; wait
  JP MenuPause            ; the 10-frame pause, then the loop

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
  LD A,E                  ; the part
  CALL AddAToHL           ; HL = PartCosts + part
  LD B,(HL)               ; B = the cost
  LD HL,PartCosts+$0008   ; the resource it takes first
  LD A,E                  ; the part
  CALL AddAToHL           ; HL = PartCosts + 8 + part
  LD A,(HL)               ; A = the resource index
  LD HL,MenuResources             ; the menu's resources
  CALL AddAToHL           ; HL = that resource
  LD A,(HL)               ; A = its value
  ADD A,B                 ; refund it there
  LD (HL),A               ; stored
  PUSH HL                 ; B = the same resource when the menu opened
  LD A,L                  ; the same index in Resources:
  SUB $07                 ; 7 bytes below MenuResources (no page crossing:
                          ; $FD22-$FD2F)
  LD L,A                  ; HL = Resources + index
  LD B,(HL)               ; B = the value when the menu opened
  POP HL                  ; HL = the menu's resource
  LD A,(HL)               ; A = its value now
  CP B                    ; the same as at the opening?
  RET Z                   ; not above it: done
  RET C                   ; below it: done
  LD (HL),B               ; above: cap it, the rest goes back to general
  SUB B                   ; A = the excess: what general had paid
  LD B,A                  ; B = it
  LD A,(MenuResources)            ; the general resource
  ADD A,B                 ; plus the excess
  LD (MenuResources),A            ; back into the general resource
  RET                     ; done

; the parts' cost (bipod, tracks, anti-grav, cannon, missiles, phasers,
; nuclear, electronics), then the resource each takes first (an index into
; Resources)
;
; The second row is the resource index (6 chassis x3, 5 cannon, 4 missiles, 3
; phasers, 2 nuclear, 1 electronics); what the own resource lacks comes from
; general (index 0).
PartCosts:
  DEFB $03,$05,$0A,$02,$04,$04,$14,$03 ; the cost: bipod 3, tracks 5, anti-grav
                                       ; 10, cannon 2, missiles 4, phasers 4,
                                       ; nuclear 20, electronics 3
  DEFB $06,$06,$06,$05,$04,$03,$02,$01 ; the Resources index paid first:
                                       ; chassis 6 x3, cannon 5, missiles 4,
                                       ; phasers 3, nuclear 2, electronics 1
                                       ; (then general 0)

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
  AND $03                 ; bits 0 right, 1 left
  JR Z,CursorUpDown       ; neither: down / up
  LD C,A                  ; C = the two bits
  LD A,L                  ; A = the column
  RR C                    ; right: the next column
  JR NC,CursorLeft        ; not right
  INC A                   ; right: column + 1
CursorLeft:
  RR C                    ; left: the previous one
  JR NC,CursorColumnCheck ; not left
  DEC A                   ; left: column - 1 (both: no change)
CursorColumnCheck:
  CP $03                  ; 0-2 only ($FF too is refused)
  JR NC,MenuPause         ; out of range: no move, only the pause
  LD L,A                  ; L = the new column
  JP CursorMoved          ; repaint and click
CursorUpDown:
  LD A,(Input)            ; down / up, only in the parts column
  RRCA                    ; Input bits 2 down, 3 up
  RRCA                    ; now bits 0, 1
  LD C,A                  ; C = them
  LD A,L                  ; A = the column
  CP $02                  ; the parts column?
  JR NZ,MenuPause         ; columns 0, 1 have no rows
  LD A,H                  ; A = the part row
  RR C                    ; down: the row below (a lower part)
  JR NC,CursorUp          ; not down
  DEC A                   ; down: the part below
CursorUp:
  RR C                    ; up: the row above
  JR NC,CursorRowCheck    ; not up
  INC A                   ; up: the part above (both: no change)
CursorRowCheck:
  CP $08                  ; 0-7 only
  JR NC,MenuPause         ; out of range: no move
  LD H,A                  ; H = the new row
CursorMoved:
  PUSH HL                 ; the old item back to $45
  LD C,$45                ; attribute $45
  CALL PaintMenuCursor    ; the old item (MenuCursor still the old one)
  POP HL                  ; HL = the new cursor
  LD (MenuCursor),HL           ; the new cursor in $46
  LD C,$46                ; attribute $46
  CALL PaintMenuCursor    ; the new item
  LD A,$14                ; a click
  CALL Beep               ; beep

; 10 frames, then back to ConstructionMenuLoop
;
; The pause after every press (moves too); a shorter press falls into it and is
; lost, WALKTHROUGH 6.
MenuPause:
  LD B,$0A                ; 10 frames
MenuPauseLoop:
  HALT                    ; one frame (StartInterrupt: EI; RET)
  DJNZ MenuPauseLoop      ; 10 times
  JP ConstructionMenuLoop ; the next press

; START ROBOT: needs a chassis and a weapon; spend the resources, place the
; robot at the warbase's door, leave
;
; Refused (back to the menu after the pause) without a chassis (MenuParts bits
; 0-2) or without a weapon (bits 3-6); electronics alone count as neither.
; Otherwise MenuResources become Resources, the free slot becomes a robot of
; ours (+$0A = 0) at column ShipX, row ShipY + 4 (PlaceRobot writes +0 to +4
; and marks the map cell), +7 = MenuParts, and a rising chirp plays (Beep with
; $50 down to $14 by 5). Then LeaveConstructionMenu. In NE's work/deep the
; robot built at frame 356 sits at (22, 9): the pad at (22, 5) plus 4 rows. The
; '98's warbase door is (22,14), its pad (22,10).
StartRobot:
  LD A,(MenuParts)            ; the chosen parts
  LD C,A                  ; no chassis: refused
  AND $07                 ; bipod, tracks or anti-grav?
  JR Z,MenuPause          ; no chassis: no robot (no beep), the pause
  LD A,C                  ; no weapon: refused
  AND $78                 ; cannon, missiles, phasers or nuclear?
  JR Z,MenuPause          ; no weapon: no robot
  LD HL,MenuResources             ; the menu's spending becomes real
  LD DE,Resources             ; into Resources
  LD BC,$0007             ; general and the six part resources
  LDIR                    ; copy
  LD HL,(ShipX)           ; the robot stands 4 rows below the ship (the pad)
  LD A,(ShipY)            ; the ship's row
  ADD A,$04               ; + 4: the door below the pad
  LD B,A                  ; B = the row
  LD (IY+$0A),$00         ; not in the menu, not under direct control
  CALL PlaceRobot         ; place it on the map
  LD A,(MenuParts)            ; its parts
  LD (IY+$07),A           ; +$07 = the parts
  LD B,$50                ; the chirp: $50 down to $14, a shorter period each
                          ; beep
BuildChirp:
  LD A,B                  ; the period
  CALL Beep               ; beep
  LD A,B                  ; the period
  SUB $05                 ; 5 shorter: a higher tone
  LD B,A                  ; B = it
  CP $14                  ; down to $14?
  JR NC,BuildChirp        ; 13 tones in all
; This entry point is used by the routine at ConstructionMenuLoop.
LeaveConstructionMenu:
  LD A,$C8                ; a long low beep
  CALL Beep               ; beep
  LD A,$05                ; $FD30 = 5: the ship climbs 5 game turns on its own,
                          ; so it does not sink straight back into the menu
  LD (ClimbTurns),A            ; ClimbTurns = 5
  PUSH IY                 ; the play screen redrawn
  CALL ClearViewBuffer    ; empty view buffer
  CALL DrawPlayScreen     ; the whole play screen
  POP IY                  ; IY = the slot again, for PlayLoop's writes
  LD HL,PlayInterrupt     ; the play interrupt again
  LD (Handler),HL           ; Handler = PlayInterrupt
  RET                     ; back to PlayLoop

; paint the item under MenuCursor with attribute C ($46 the cursor, $45 the
; rest)
;
; Column 0 / 1: two rows of 5 cells, EXIT MENU at rows 21-22 columns 4-8, START
; ROBOT columns 10-14. Column 2: the part's name, 11 cells from column 21 of
; row 22 - 3 * row (BIPOD row 22 up to ELECTRONICS row 1). Called by
; ConstructionMenuSetup and MoveMenuCursor.
PaintMenuCursor:
  LD HL,(MenuCursor)           ; L = the column, H = the part row
  LD A,L                  ; the parts column?
  CP $02                  ; column 2?
  JR Z,PartNameCursor     ; the part's name
  ADD A,A                 ; $5AA4 + 6 * column: row 21
  ADD A,L                 ; 3 x column
  ADD A,A                 ; 6 x column
  ADD A,$A4               ; + $A4: row 21, column 4
  LD L,A                  ; L = it
  LD H,$5A                ; HL = $5AA4 + 6 x column
  LD B,$05                ; 5 cells
  CALL FillAttributes     ; row 21
  LD A,L                  ; the same columns on row 22
  ADD A,$1B               ; + 27: past the 5 cells, the next row
  LD L,A                  ; L = it (no carry: $5AC4 + 6 x column)
  LD B,$05                ; 5 cells
  JR FillAttributes       ; row 22, and return
PartNameCursor:
  LD A,H                  ; row 22 - 3 * part, column 21, 11 cells
  ADD A,A                 ; 2 x row
  ADD A,H                 ; 3 x row
  NEG                     ; - 3 x row
  ADD A,$16               ; 22 - 3 x row: the screen row of the name
  ADD A,A                 ; x2
  ADD A,A                 ; x4
  ADD A,A                 ; x8
  LD L,A                  ; L = row x 8
  LD H,$00                ; HL = row x 8
  ADD HL,HL               ; x16
  ADD HL,HL               ; x32: the row's attribute offset
  LD DE,$5815             ; the attributes' column 21
  ADD HL,DE               ; HL = the name's first attribute
  LD B,$0B                ; 11 cells (ELECTRONICS is 11 letters)

; write C into B bytes from HL
;
; Also used by PaintMenuItem.
FillAttributes:
  LD (HL),C               ; the attribute
  INC HL                  ; the next cell
  DJNZ FillAttributes     ; B cells
  RET                     ; done

; print MenuResources (two digits each) and their total
;
; The seven values at column 13: GENERAL row 9, ELECTRONICS-CHASSIS rows 11-16
; (PrintMenuResource, two digits: a value above 99 prints a wrong tens digit,
; e.g. 200 shows "D0"); the sum (HL) at row 18, column 12, three digits by
; PrintNumber3 (the tail $CC03).
PrintMenuResources:
  LD DE,MenuResources             ; HL = the total
  LD HL,$0000             ; the sum starts at 0
  LD C,$09                ; C = the row: 9 for GENERAL
  LD B,$07                ; seven values
PrintResourceLoop:
  LD A,(DE)               ; the value
  CALL AddAToHL           ; HL += it: the total
  LD A,(DE)               ; print the value at row C
  CALL PrintMenuResource  ; at (C,13), two digits
  INC DE                  ; the next value
  INC C                   ; the next row
  LD A,B                  ; a blank row after GENERAL
  CP $07                  ; just printed GENERAL?
  JR NZ,PrintResourceNext ; no
  INC C                   ; skip row 10
PrintResourceNext:
  DJNZ PrintResourceLoop  ; all seven
  CALL PrintInline        ; the total at row 18, column 12

; PrintInline text: AT 18,12
TotalPosition:
  DEFM $01,$12,$0C,$00    ; AT (18,12): where PrintMenuTotal prints the TOTAL
                          ; value

; Construction menu: print the total of the costs (the tail of $CBE0)
;
; The tail of PrintMenuResources after the inline position (18,12): E = $20
; (blank leading zeros) and PrintNumber3 prints HL, the sum of the seven
; MenuResources (the TOTAL line, not the costs). 29 runs in NE's deep
; recording, one per reprint of the resources.
PrintMenuTotal:
  LD E,$20                ; blank the leading zeros
  JP PrintNumber3         ; three digits of HL

; Construction menu: print one resource value A at row C, column 13
;
; Called by $CBE0 for each of the seven MenuResources (rows 9, 11-16). Patches
; the row byte of the position string after the CALL ($CC11), prints the
; position, then PrintMenuResourceValue prints A as two digits. Preserves BC,
; DE, HL (203 calls in NE's deep recording).
PrintMenuResource:
  PUSH AF                 ; the value
  LD A,C                  ; the row into the string below
  LD (MenuResourcePos+$0001),A ; Y of the string below
  CALL PrintInline        ; the position (C,13)

; Inline string: position (row patched, column 13)
;
; PrintInline bytes: 1 Y X with Y written by $CC0A, then 0 (end). The file
; holds Y = $10 (NE's tape 0): a value PrintMenuResource left when ZS saved the
; memory after a construction menu; every call writes it before the print.
MenuResourcePos:
  DEFB $01,$10,$0D,$00    ; AT (Y,13), Y patched by PrintMenuResource (0, then
                          ; one row per resource)

; Construction menu: print A as two digits, registers kept (the tail of $CC08)
PrintMenuResourceValue:
  POP AF                  ; the value back
  PUSH BC                 ; kept
  PUSH DE                 ; kept
  PUSH HL                 ; kept
  CALL PrintNumber2       ; two digits, blank leading zero
  POP HL                  ; HL back
  POP DE                  ; DE back
  POP BC                  ; BC back
  RET                     ; done

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
  LD A,(MenuParts)            ; the chosen parts
  LD C,A                  ; C = them, shifted out from bit 7 (electronics, the
                          ; top)
  LD B,$08                ; eight parts
PartRowLoop:
  LD E,$06                ; E = $06: not chosen
  RL C                    ; the next part bit into carry, highest first
  JR NC,PartRowPaint      ; not chosen
  LD E,$47                ; chosen: bright white
PartRowPaint:
  PUSH BC                 ; paint the part's 4 x 3 cells in attribute E
  LD BC,$0403             ; 4 cells by 3 rows
PartRowLine:
  PUSH BC                 ; one attribute row of the part's 4 cells
PartCellLoop:
  LD (HL),E               ; the attribute
  INC HL                  ; the next cell
  DJNZ PartCellLoop       ; four cells
  LD A,$1C                ; to the next attribute row (32 - 4)
  CALL AddAToHL           ; HL = the next row's column 16
  POP BC                  ; C = the rows left
  DEC C                   ; one row done
  JR NZ,PartRowLine       ; three rows a part
  POP BC                  ; B = the parts left
  DJNZ PartRowLoop        ; all eight
  CALL ClearViewBuffer    ; empty view buffer
  LD A,(MenuParts)            ; the chosen parts
  LD (IY+$07),A           ; the robot's parts
  LD DE,$0A07             ; row 10, column 7 of the view
  CALL DrawRobot          ; the parts from +$0D up, into the view buffer
  LD A,(DrawSprite+$0012) ; the stack's height after the last part
  LD (IY+$09),A           ; +$09: the robot's height (the landing test adds
                          ; +$0D)
  LD BC,$0448             ; 4 bytes, 72 lines
  LD DE,$6168             ; buffer row 82, column 0
  LD HL,$48E0             ; screen: character row 15, column 0
PreviewLineLoop:
  PUSH BC                 ; C = the lines left
  PUSH HL                 ; the line's screen address
PreviewByteLoop:
  LD A,(DE)               ; copy B bytes of the buffer row to the screen line
  LD (HL),A               ; onto the screen
  INC DE                  ; the next buffer byte
  INC HL                  ; the next screen byte
  DJNZ PreviewByteLoop    ; four bytes: columns 0-3
  LD A,E                  ; the next buffer row (20 bytes in all)
  ADD A,$10               ; + 16: with the 4 copied, a buffer row of 20
  LD E,A                  ; E = it
  LD A,D                  ; the carry
  ADC A,$00               ; into the high byte
  LD D,A                  ; DE = the next buffer row
  POP HL                  ; HL = the line's start
  CALL NextScreenLine     ; the next screen line
  POP BC                  ; C = the lines left
  DEC C                   ; one line done
  JR NZ,PreviewLineLoop   ; 72 lines
  RET                     ; done

; Put robot IY at map column HL, row B: record, map bit 6, radar dot
;
; Writes +$02/+$03 = HL (x), +$04 = B (y), +$00/+$01 = the map cell (MapCell)
; and sets the cell's bit 6 (an object to draw). Then toggles the robot's radar
; dot (ToggleRadarDot, side = bit 7 of +$0A: 0 the player's buffer $D800, 1 the
; enemy's $D900). The caller clears the old cell and toggles the old dot.
; Called by the robot step $B0FA (9652 times in NE's deep recording), the enemy
; spawn $B7F4 (22) and START ROBOT in $CB52 (7).
PlaceRobot:
  LD (IY+$02),L           ; +$02 = the column, low byte
  LD (IY+$03),H           ; +$03 = its high byte
  LD (IY+$04),B           ; +$04 = the row
  PUSH HL                 ; keep x for the radar
  LD A,B                  ; A = the row
  CALL MapCell            ; HL = $DD00 + $200*y + x
  LD (IY+$00),L           ; +$00 = the cell, low byte
  LD (IY+$01),H           ; +$01 = its high byte (not 0: the slot is in use)
  SET 6,(HL)              ; bit 6: draw an object here
  POP HL                  ; HL = the column
  LD C,(IY+$04)           ; C = y
  LD A,(IY+$0A)           ; B = side: +$0A bit 7 (enemy)
  RLCA                    ; bit 7 into bit 0
  AND $01                 ; 0 ours, 1 the enemy's
  LD B,A                  ; B = the radar picture
  JP ToggleRadarDot       ; XOR the 2x2 dot into the side's radar

; HL = the map cell under the ship (ShipX, ShipY)
;
; Falls into MapCell. Used by $A62D, $B01D (clear the ship's bit 7) and $B024
; (set it).
ShipCell:
  LD HL,(ShipX)           ; the ship's column
  LD A,(ShipY)            ; the ship's row

; HL = the map cell of column HL, row A: $DD00 + $200*A + HL
;
; H += 2*A + $DD. The map lookup of the whole game (127962 calls in NE's deep
; recording: the main loop $AD90, CheckShipMove, the robot code, PlaceRobot,
; DrawMover).
MapCell:
  ADD A,A                 ; 2 x row: $200 bytes a map row
  ADD A,$DD               ; + $DD: the map's page
  ADD A,H                 ; + the column's high byte
  LD H,A                  ; HL = the cell
  RET                     ; done

; Beeper tone: 256 half-periods, A = the half-period delay (bigger is lower)
;
; B = A is the DJNZ delay of each half-period, C = 0 counts 256 speaker toggles
; (bit 4 of port $FE, border black). BC is kept. Used for menu clicks and
; confirmations: ListMenu (83), $CB52 (98), $CB00 (42), $CA0F (22), the robot
; menu $A7CD, $ABC8.
Beep:
  PUSH BC                 ; kept
  LD B,A                  ; B = the half-period delay
  XOR A                   ; C = 0: 256 toggles
  LD C,A                  ; C = 0
BeepLoop:
  PUSH BC                 ; keep the delay and the count
  XOR $10                 ; flip the speaker bit
  OUT ($FE),A             ; the speaker (bit 4), border 0, MIC 0
BeepDelay:
  DJNZ BeepDelay          ; the half-period
  POP BC                  ; B = the delay, C = the count
  DEC C                   ; one toggle done
  JR NZ,BeepLoop          ; 256 toggles: 128 periods
  POP BC                  ; BC back
  RET                     ; done
