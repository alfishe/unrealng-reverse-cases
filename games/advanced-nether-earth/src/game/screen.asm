; --------------------------------------------------------------------------------------------------------------------
; screen.asm: the play screen: its frame and colours, the status panel, screen-line steps, Random
;
; The fixed parts of the play screen and the helpers every module uses. DrawPlayScreen draws it all once (at EnterPlay
; and after the construction menu): ClearScreen, DrawView, the frame of the view (22 x 22 characters from (0,0),
; double lines), the attributes ($07 all, $78 the frame, $70 the view, $71 / $41 the blue corner past the map's south
; edge) and PlayScreenText (ДЕНЬ:, ЧАС:, the tall РАДАР:).
;
; The right panel, columns 22-31: ShowStatusPanel = ClearPanel + StatusPanelText (the labels); UpdateStatusPanel
; reprints the numbers (the Resources, both sides' building counts and robots) through PrintResourceValues,
; PrintInsgCounts, PrintHumnCounts and PrintHumnRobots, each the tail after an inline position string. PanelBusy = 1
; (a robot menu prints there) stops it.
;
; Helpers: DrawMaskedUp (masked pictures straight onto the screen, the construction menu), NextScreenLine /
; PrevScreenLine (the screen's line order), TableWord and AddAToHL (table lookups), and Random, the game's only random
; source (a 32-bit shift register in RandomSeed $FD00).
;
; Inline data: every string here follows a CALL PrintInline (control codes 1 position, 2 attribute, 3 newline, 4 size,
; 0 end; see the print module), and the code goes on after its 0. The operand of LD (HL),A at $D371 (Random+$19) is
; self-modified: the index of the last byte Random returned.
; --------------------------------------------------------------------------------------------------------------------

; Clear the screen (pixels and attributes to 0) and make the border black
;
; Clears the 6912 bytes of pixels and attributes from $4000 and sets the border
; black (and the speaker off) with OUT ($FE),0. Called by DrawPlayScreen,
; MainMenu $C100, RedefineKeys $C34A and OpenConstructionMenu $C865. Changes A,
; BC, DE, HL.
ClearScreen:
  XOR A                   ; border 0, black; the speaker off
  OUT ($FE),A             ; to port $FE
  LD HL,$4000             ; the screen
  LD DE,$4001             ; the LDIR copies the zero along
  LD BC,$1AFF             ; 6911 more: all pixels and attributes
  LD (HL),$00             ; the first zero

; ClearScreen's LDIR
ClearScreenFill:
  LDIR                    ; $4000-$5AFF to 0
  RET                     ; the screen is black

; Draw the whole play screen: the view, its frame, the colours, DAY / TIME /
; RADAR
;
; ClearScreen and DrawView, then the frame of the view (22 x 22 characters from
; (0,0): double lines at the top and bottom, $81 lines at the sides), the
; attributes: $07 everywhere, $78 on the frame, $70 (yellow paper) in the view,
; $71 and $41 (blue) in its bottom right corner, the area past the map's edge.
; Prints PlayScreenText. Called at the start of play ($A68E) and after the
; construction menu ($CB52).
;
; PlayScreenText ends the code: PrintInline returns into ShowStatusPanel, so
; the panel's labels come with every play screen; the numbers come with the
; next UpdateStatusPanel. The radar appears at the next frame's PlayInterrupt.
DrawPlayScreen:
  CALL ClearScreen        ; the whole screen black
  CALL DrawView           ; the view into character rows 1-20, columns 1-20
  LD HL,$4000             ; the frame's top line
  LD DE,$4001             ; (the next byte)
  LD BC,$0015             ; 21 more: columns 0-21
  LD (HL),$FF             ; full line
  LDIR                    ; line 0 of row 0
  LD HL,$4701             ; the inner top line
  LD DE,$4702             ; (the next byte)
  LD BC,$0013             ; 19 more: columns 1-20
  LD (HL),$FF             ; full line
  LDIR                    ; line 7 of row 0
  LD HL,$50A1             ; the inner bottom line
  LD DE,$50A2             ; (the next byte)
  LD BC,$0013             ; 19 more: columns 1-20
  LD (HL),$FF             ; full line
  LDIR                    ; line 0 of row 21
  LD HL,$57A0             ; the frame's bottom line
  LD DE,$57A1             ; (the next byte)
  LD BC,$0015             ; 21 more: columns 0-21
  LD (HL),$FF             ; full line
  LDIR                    ; line 7 of row 21
  LD HL,$4100             ; the corners of the double lines
  LD B,$06                ; lines 1-6 of row 0, column 0
FrameCornerTopLeft:
  LD (HL),$80             ; $80 down 6 lines at $4100: the top left corner of
                          ; the double lines
  INC H                   ; the next pixel line of the character cell
  DJNZ FrameCornerTopLeft ; 6 lines
  LD HL,$4115             ; row 0, column 21
  LD B,$06                ; lines 1-6
FrameCornerTopRight:
  LD (HL),$01             ; $01 down 6 lines at $4115
  INC H                   ; the next pixel line
  DJNZ FrameCornerTopRight ; 6 lines
  LD HL,$50A0             ; row 21, column 0
  LD B,$07                ; lines 0-6
FrameCornerBottomLeft:
  LD (HL),$80             ; $80 down 7 lines at $50A0
  INC H                   ; the next pixel line
  DJNZ FrameCornerBottomLeft ; 7 lines
  LD HL,$50B5             ; row 21, column 21
  LD B,$07                ; lines 0-6
FrameCornerBottomRight:
  LD (HL),$01             ; $01 down 7 lines at $50B5
  INC H                   ; the next pixel line
  DJNZ FrameCornerBottomRight ; 7 lines
  LD HL,$4700             ; the left side, 162 lines
  LD B,$A2                ; from line 7 of row 0 to line 0 of row 21
FrameSideLeft:
  LD (HL),$81             ; $81 down 162 lines at column 0
  CALL NextScreenLine     ; the next screen line
  DJNZ FrameSideLeft      ; 162 lines
  LD HL,$4715             ; the right side
  LD B,$A2                ; 162 lines
FrameSideRight:
  LD (HL),$81             ; $81 down 162 lines at column 21
  CALL NextScreenLine     ; the next screen line
  DJNZ FrameSideRight     ; 162 lines
  LD HL,$5800             ; all attributes $07
  LD DE,$5801             ; (the next cell)
  LD BC,$02FF             ; 767 more: all 768 cells
  LD (HL),$07             ; white ink on black
  LDIR                    ; fill
  LD HL,$5800             ; the frame's top row $78
  LD DE,$5801             ; (the next cell)
  LD BC,$0015             ; 21 more: columns 0-21
  LD (HL),$78             ; bright, black ink on white
  LDIR                    ; row 0
  LD HL,$5AA0             ; the frame's bottom row
  LD DE,$5AA1             ; (the next cell)
  LD BC,$0015             ; 21 more: columns 0-21
  LD (HL),$78             ; bright, black ink on white
  LDIR                    ; row 21
  LD HL,$5820             ; the frame's left and right columns
  LD B,$14                ; rows 1-20
FrameAttrSides:
  LD (HL),$78             ; attribute $78 at columns 0 and 21 of 20 rows
  LD A,$15                ; 21: to column 21
  CALL AddAToHL           ; HL = column 21
  LD (HL),$78             ; the right side
  LD A,$0B                ; 11: to column 0 of the next row
  CALL AddAToHL           ; HL = column 0
  DJNZ FrameAttrSides     ; the next row
  LD HL,$5821             ; the view: 20 x 20 cells of $70
  LD BC,$1414             ; B = 20 cells a row, C = 20 rows
ViewAttrRow:
  PUSH BC                 ; a row of 20 view cells
ViewAttrCell:
  LD (HL),$70             ; attribute $70
  INC HL                  ; the next cell
  DJNZ ViewAttrCell       ; 20 cells
  POP BC                  ; the counts back
  LD A,$0C                ; 12: to column 1 of the next row
  CALL AddAToHL           ; HL = column 1
  DEC C                   ; one row less
  JR NZ,ViewAttrRow       ; the next row
  LD B,$04                ; the bottom right corner: blue past the map's edge
  LD HL,$5A33             ; row 17, column 19: the diagonal edge's cells,
                          ; bright blue ink on yellow
BlueCornerLoop:
  LD (HL),$71             ; 2 cells of $71 a row, 4 rows from $5A33
  INC HL                  ; the next column
  LD (HL),$71             ; 2 cells
  LD A,$1D                ; 29: two columns further left in the next row, along
                          ; the edge
  CALL AddAToHL           ; rows 17, 18, 19, 20 at columns 19, 17, 15, 13
  DJNZ BlueCornerLoop     ; the next row
  LD HL,$5A53             ; row 18, columns 19-20: past the edge, bright blue
                          ; ink on black
  LD (HL),$41             ; (row 18, column 19)
  INC HL                  ; the next column
  LD (HL),$41             ; column 20
  LD HL,$5A71             ; row 19, columns 17-20
  LD B,$04                ; 4 cells
BlueEdgeRow1:
  LD (HL),$41             ; 4 cells of $41 at $5A71
  INC HL                  ; the next column
  DJNZ BlueEdgeRow1       ; 4 cells
  LD HL,$5A8F             ; row 20, columns 15-20
  LD B,$06                ; 6 cells
BlueEdgeRow2:
  LD (HL),$41             ; 6 cells of $41 at $5A8F
  INC HL                  ; the next column
  DJNZ BlueEdgeRow2       ; 6 cells
  CALL PrintInline        ; ДЕНЬ:, ЧАС:, РАДАР:

; "ДЕНЬ:" (day) and "ЧАС:" (hour) at (0,22), the tall "РАДАР:" at (22,0)
;
; PrintInline bytes: attribute $57, position (0,22), size 0, "ДЕНЬ:", newline,
; " ЧАС:", position (22,0), size $21 (2 rows high, 1 byte wide), attribute $45,
; "РАДАР:", 0. Bright white on red for the clock labels, bright cyan on black
; for РАДАР:. PrintInline returns past the 0 into ShowStatusPanel:
; DrawPlayScreen has no RET of its own.
PlayScreenText:
  INCBIN "res/game/text/play-screen.bin",$0000,32

; Clear the right panel and print the status labels
;
; ClearPanel, then StatusPanelText. Called when the robot menu ends
; (CloseRobotMenu $A819) and at the game's end (GameStop $AF07). DrawPlayScreen
; falls into it after its own string, so every play screen gets the labels. The
; numbers come from UpdateStatusPanel.
ShowStatusPanel:
  CALL ClearPanel         ; the panel blank first
  CALL PrintInline        ; the labels

; The right panel's labels: СТАТУС, ИНОП. ЛЮДИ (aliens, people), БАЗЫ ...
; РОБОТЫ, РЕСУРСЫ ОБЩИЕ ... ШАССИ
;
; "  СТАТУС" at (3,22) attribute $46, "ИНОП. ЛЮДИ" (aliens, the enemy; people,
; the player), then from (6,23) attribute $45 the rows БАЗЫ, ЭЛЕКТР., А-БОМБЫ,
; ФАЗОРЫ, РАКЕТЫ, ПУШКИ, ШАССИ, РОБОТЫ (warbases, electronics, nuclear,
; phasers, missiles, cannon, chassis, robots); " РЕСУРСЫ " at (15,23) attribute
; $46 and from row 17 attribute $44 ОБЩИЕ, ЭЛЕКТР., АТОМН., ФАЗОРЫ, РАКЕТЫ,
; ПУШКИ, ШАССИ: the order of Resources.
StatusPanelText:
  INCBIN "res/game/text/status-panel.bin",$0000,168

; Print the panel's numbers: resources, then both sides' buildings and robots
;
; Skipped while PanelBusy ($FD39) is not 0 (the robot menu owns the panel).
; Prints the seven Resources at (17-23, 30) as two digits, attribute $4E; the
; enemy's building counts EnemyBuildings $FD42 (by type 0-6) at (6-12, 22) and
; robots EnemyRobotCount $FD49 at (13,22); the player's counts PlayerBuildings
; $FD3A at (6-12, 31) and robots PlayerRobotCount $FD41 at (13,30), attribute
; $47. Called after the counts change (a capture $AE1A, the day's production
; $AE4A, a robot removed $B150, an enemy robot built $B91C, the blast $BA84)
; and from CheckWarbasePad ($A70A) after a robot is built.
;
; The four parts are each a CALL PrintInline with a position string and the
; code after it (the entries below). PrintNewline comes before each resource,
; so the first lands on row 17.
UpdateStatusPanel:
  LD A,(PanelBusy)            ; a robot menu in the panel?
  OR A                    ; (PanelBusy not 0)
  RET NZ                  ; then leave the panel alone
  CALL PrintInline        ; position (16,30), attribute $4E, size 0

; Inline string: position (16,30), attribute $4E, size 0
;
; The bytes 1 $10 $1E (position (16,30)), 2 $4E (attribute bright yellow on
; blue), 4 0 (normal size), 0. Row 16: PrintResourceValues starts with a
; newline.
ResourceValuesPos:
  DEFB $01,$10,$1E,$02,$4E,$04,$00,$00 ; AT (16,30), $4E (yellow on blue), size
                                       ; 0: one newline later the first
                                       ; resource value

; The seven resource values, each on the next line (the tail of $D293)
;
; Seven lines from Resources ($FD22: general, electronics, nuclear, phasers,
; missiles, cannon, chassis), each PrintNewline then PrintNumber2: rows 17-23,
; column 30, blank leading zero. Falls into the next position string.
PrintResourceValues:
  LD HL,Resources             ; the player's seven resources
  LD B,$07                ; 7 values
ResourceValueLoop:
  PUSH BC                 ; keep the count
  PUSH HL                 ; and the pointer (PrintNewline changes BC and HL)
  CALL PrintNewline       ; the next line first
  POP HL                  ; the pointer back
  LD A,(HL)               ; the resource, 0-99
  INC HL                  ; the next
  PUSH HL                 ; keep it
  CALL PrintNumber2       ; two digits, blank leading zero
  POP HL                  ; the pointer back
  POP BC                  ; the count back
  DJNZ ResourceValueLoop  ; the next resource
  CALL PrintInline        ; the enemy's column

; Inline string: position (6,22), attribute $47
;
; The bytes 1 6 $16 (position (6,22)), 2 $47 (bright white on black), 0.
InsgCountsPos:
  DEFB $01,$06,$16,$02,$47,$00 ; AT (6,22), $47 (white): the enemy's (INSG)
                               ; base counts

; The enemy's building counts and its robots (the tail of $D293)
;
; The enemy's seven building counts EnemyBuildings ($FD42: warbases, then the
; six factory kinds) as single digits down column 22, rows 6-12; then its
; robots EnemyRobotCount ($FD49, the byte after them) at (13,22) with a leading
; zero, over the space before ROBOTS. Falls into the player's position string.
PrintInsgCounts:
  LD HL,EnemyBuildings             ; the enemy's counts by type
  CALL PrintDigitColumn   ; seven single digits, one a line
  LD A,(HL)               ; $FD49: the enemy's robots, two digits
  CALL PrintNumber2Zero   ; two digits with a leading zero
  CALL PrintInline        ; the player's column

; Inline string: position (6,31)
;
; The bytes 1 6 $1F (position (6,31)), 0; the attribute stays $47.
HumnCountsPos:
  DEFB $01,$06,$1F,$00    ; AT (6,31): our (HUMN) base counts, still in $47

; The player's building counts (the tail of $D293)
;
; The player's seven building counts PlayerBuildings ($FD3A) down column 31,
; rows 6-12. HL ends at PlayerRobotCount. Falls into the next position string.
PrintHumnCounts:
  LD HL,PlayerBuildings             ; the player's counts by type
  CALL PrintDigitColumn   ; rows 6-12, column 31
  CALL PrintInline        ; the player's robot count's place

; Inline string: position (13,30)
;
; The bytes 1 $0D $1E (position (13,30)), 0.
HumnRobotsPos:
  DEFB $01,$0D,$1E,$00    ; AT (13,30): our robot count

; The player's robots $FD41, two digits (the tail of $D293)
;
; PlayerRobotCount ($FD41, HL from PrintHumnCounts) as two digits with a
; leading zero; the JP returns from UpdateStatusPanel.
PrintHumnRobots:
  LD A,(HL)               ; HL = PlayerRobotCount, right after the seven counts
  JP PrintNumber2Zero     ; two digits at (13,30); its RET ends
                          ; UpdateStatusPanel

; Print seven bytes from HL as single digits, one under the other
;
; Each byte as "0" + n (a count of 10 or more would print ":" and the
; characters after it; never seen, a side has at most 4 warbases), then
; PrintNewline: the same column one row down. HL ends past the seventh byte
; (the robot count that follows). Used by PrintInsgCounts and PrintHumnCounts.
PrintDigitColumn:
  LD B,$07                ; 7 counts
DigitColumnLoop:
  PUSH BC                 ; keep the count
  LD A,(HL)               ; the count
  INC HL                  ; the next
  ADD A,$30               ; as a digit
  CALL PrintCharKeep      ; print it (BC, DE, HL kept)
  PUSH HL                 ; keep the pointer
  CALL PrintNewline       ; the next row, the same column
  POP HL                  ; the pointer back
  POP BC                  ; the count back
  DJNZ DigitColumnLoop    ; the next count
  RET                     ; HL = the byte after the seven

; Blank the right panel: 22 lines of 10 spaces from (2,22) in attribute 0
;
; Called by ShowStatusPanel and by the robot menus (RobotMenuShow $A732,
; CloseRobotMenu $A812, OrdersMenu $A971, OrderMove $AA15, TargetMenu $AAD2,
; CaptureMenu $AB4E, CombatMenu $AC00) and GameStop ($AF04) before they print.
; Attribute 0 (black on black) hides the area at once; rows 22-23 of the panel
; (STRENGTH) are cleared too.
ClearPanel:
  CALL PrintInline        ; the panel's top left, size 0, attribute 0

; Inline string: position (2,22), size 0, attribute 0
;
; The bytes 1 2 $16 (position (2,22)), 4 0 (normal size), 2 0 (attribute 0), 0.
ClearPanelPos:
  DEFB $01,$02,$16,$04,$00,$02,$00,$00 ; AT (2,22), size 0, attribute 0 (black
                                       ; on black): ClearPanel's start

; 22 lines (the tail of ClearPanel)
;
; B = 22: rows 2-23. B survives each PrintInline: it works in the alternate
; registers.
ClearPanelLines:
  LD B,$16                ; 22 rows: 2-23

; Print 10 spaces and a newline
;
; One CALL PrintInline with PanelBlankLine; the code goes on at ClearPanelNext.
ClearPanelLine:
  CALL PrintInline        ; 10 spaces, the next row

; 10 spaces, a new line
;
; 10 spaces (columns 22-31), 3 (the next row, the same column), 0.
PanelBlankLine:
  INCBIN "res/game/text/panel-blank-line.bin",$0000,12

; The next of the 22 lines
;
; DJNZ back to ClearPanelLine for the 22 rows, then the return from ClearPanel.
ClearPanelNext:
  DJNZ ClearPanelLine     ; the next row
  RET                     ; the panel is blank

; Draw a masked image on the screen: C lines of B (mask, pixel) pairs from HL
; to DE, going up
;
; Each line ANDs the mask and ORs the pixels; DE moves one screen line up
; (PrevScreenLine) after each. Out: HL past the picture. No clipping.
DrawMaskedUp:
  PUSH BC                 ; keep the width and the line count
  PUSH DE                 ; and the line's screen address
MaskedByteLoop:
  LD A,(DE)               ; the screen byte
  AND (HL)                ; the mask keeps what is around the picture
  INC HL                  ; to the pixels
  OR (HL)                 ; the picture's ink
  LD (DE),A               ; back to the screen
  INC HL                  ; the next pair
  INC DE                  ; the byte to the right
  DJNZ MaskedByteLoop     ; each byte of the line
  POP DE                  ; the line's start
  POP BC                  ; the counts back
  CALL PrevScreenLine     ; one screen line up
  DEC C                   ; one line less
  JP NZ,DrawMaskedUp      ; the next line up
  RET                     ; the picture is drawn

; HL = the screen address one pixel line down
;
; The Spectrum's screen order: the line inside a character row is bits 0-2 of
; H, the character row bits 5-7 of L, the third bits 3-4 of H. Keeps everything
; but A and the flags. Used by ShowRadar, the frame of DrawPlayScreen, the big
; characters of PrintBigChar and ShowRobotDesign's copy ($CC74).
NextScreenLine:
  INC H                   ; the next pixel line inside the character row
  LD A,$07                ; the line number ...
  AND H                   ; ... bits 0-2 of H
  RET NZ                  ; not 0: still in the same character row
  LD A,L                  ; past line 7: the next character row
  ADD A,$20               ; + 32
  LD L,A                  ; (the low byte)
  RET C                   ; carry: the next third, which H (+8 from the lines)
                          ; already is
  LD A,H                  ; the same third ...
  SUB $08                 ; ... H back by 8
  LD H,A                  ; (line 0 of the next character row)
  RET                     ; HL = one line down

; DE = the screen address one pixel line up
;
; The reverse of NextScreenLine on DE: used only by DrawMaskedUp, which draws
; from the bottom line up. Keeps everything but A and the flags.
PrevScreenLine:
  LD A,D                  ; the old line number in bits 0-2
  DEC D                   ; one pixel line up
  AND $07                 ; was it line 0?
  RET NZ                  ; no: still the same character row
  LD A,E                  ; line 0: the character row above
  SUB $20                 ; - 32
  LD E,A                  ; (the low byte)
  RET C                   ; borrow: the third above, where D (-1: its line 7)
                          ; already is
  LD A,D                  ; the same third ...
  ADD A,$08               ; ... D up by 8: line 7 of the row above
  LD D,A                  ; (D)
  RET                     ; DE = one line up

; HL = the word at HL + 2*A
;
; The sprite table lookup of DrawSprite, also ConstructionMenu (PartIconLoop
; $C881) and DrawShape ($BD67). A is an index 0-127 (A*2 must fit a byte).
; Changes A.
TableWord:
  ADD A,A                 ; two bytes an entry
  CALL AddAToHL           ; HL = the entry
  LD A,(HL)               ; the low byte
  INC HL                  ; the high byte's place
  LD H,(HL)               ; H = the high byte
  LD L,A                  ; HL = the word
  RET                     ; done

; HL += A
;
; A changed to the new H; BC, DE kept. Used everywhere a table is indexed by a
; byte (about 50 call sites).
AddAToHL:
  ADD A,L                 ; the low byte
  LD L,A                  ; (L)
  LD A,H                  ; the carry ...
  ADC A,$00               ; ... into H
  LD H,A                  ; (H)
  RET                     ; done

; A = a pseudo-random byte
;
; A 32-bit shift register at RandomSeed $FD00-$FD03 (big end first, seeded
; $39,$30,$39,$30 by Restart): shifted left once, the new bit = bit 3 XOR bit 6
; of $FD00. Then the byte at the index the previous call used (kept in the
; operand $D371) gives, by its low 2 bits, the new index, and A = the byte
; there. HL is kept;
Random:
  PUSH HL                 ; HL kept
  LD HL,RandomSeed             ; the four bytes, the top first
  LD A,(HL)               ; the top byte
  AND $48                 ; bits 6 and 3
  ADD A,$38               ; bit 6 of the sum = bit 6 XOR bit 3
  RLCA                    ; carry = the feedback bit
  RLCA                    ; (two rotations: bit 6 of the sum reaches the carry)
  LD L,$03                ; shift $FD03..$FD00 left
  RL (HL)                 ; $FD03 gets the feedback bit
  DEC L                   ; (the next byte up)
  RL (HL)                 ; $FD02
  DEC L                   ; (the next byte up)
  RL (HL)                 ; $FD01
  DEC L                   ; (the next byte up)
  RL (HL)                 ; $FD00, the top; its bit 7 drops out
  LD L,$00                ; the index from the last call: the operand $D371
  LD A,(HL)               ; that byte, after the shift
  AND $03                 ; the next index
  LD L,A                  ; L = the index
  LD (Random+$0019),A     ; kept for the next call
  LD A,(HL)               ; A = the byte at that index
  POP HL                  ; HL back
  RET                     ; A = a random byte
