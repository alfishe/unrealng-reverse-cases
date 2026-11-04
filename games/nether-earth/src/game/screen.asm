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
FrameCornerTopLeft:
  LD (HL),$80             ; $80 down 6 lines at $4100: the top left corner of
                          ; the double lines
  INC H
  DJNZ FrameCornerTopLeft
  LD HL,$4115
  LD B,$06
FrameCornerTopRight:
  LD (HL),$01             ; $01 down 6 lines at $4115
  INC H
  DJNZ FrameCornerTopRight
  LD HL,$50A0
  LD B,$07
FrameCornerBottomLeft:
  LD (HL),$80             ; $80 down 7 lines at $50A0
  INC H
  DJNZ FrameCornerBottomLeft
  LD HL,$50B5
  LD B,$07
FrameCornerBottomRight:
  LD (HL),$01             ; $01 down 7 lines at $50B5
  INC H
  DJNZ FrameCornerBottomRight
  LD HL,$4700             ; the left side, 162 lines
  LD B,$A2
FrameSideLeft:
  LD (HL),$81             ; $81 down 162 lines at column 0
  CALL NextScreenLine
  DJNZ FrameSideLeft
  LD HL,$4715             ; the right side
  LD B,$A2
FrameSideRight:
  LD (HL),$81             ; $81 down 162 lines at column 21
  CALL NextScreenLine
  DJNZ FrameSideRight
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
FrameAttrSides:
  LD (HL),$78             ; attribute $78 at columns 0 and 21 of 20 rows
  LD A,$15
  CALL AddAToHL
  LD (HL),$78
  LD A,$0B
  CALL AddAToHL
  DJNZ FrameAttrSides
  LD HL,$5821             ; the view: 20 x 20 cells of $70
  LD BC,$1414
ViewAttrRow:
  PUSH BC                 ; a row of 20 view cells
ViewAttrCell:
  LD (HL),$70             ; attribute $70
  INC HL
  DJNZ ViewAttrCell
  POP BC
  LD A,$0C
  CALL AddAToHL
  DEC C
  JR NZ,ViewAttrRow
  LD B,$04                ; the bottom right corner: blue past the map's edge
  LD HL,$5A33
BlueCornerLoop:
  LD (HL),$71             ; 2 cells of $71 a row, 4 rows from $5A33
  INC HL
  LD (HL),$71
  LD A,$1D
  CALL AddAToHL
  DJNZ BlueCornerLoop
  LD HL,$5A53
  LD (HL),$41
  INC HL
  LD (HL),$41
  LD HL,$5A71
  LD B,$04
BlueEdgeRow1:
  LD (HL),$41             ; 4 cells of $41 at $5A71
  INC HL
  DJNZ BlueEdgeRow1
  LD HL,$5A8F
  LD B,$06
BlueEdgeRow2:
  LD (HL),$41             ; 6 cells of $41 at $5A8F
  INC HL
  DJNZ BlueEdgeRow2
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
