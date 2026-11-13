; --------------------------------------------------------------------------------------------------------------------
; render.asm: The renderer: the grid into characters, the buffers, the copies, the wipes, the printers
;
; The play area is a character map (CharMap $E000, 20 rows of 32 codes) drawn into a linear pixel buffer (PixelBuffer
; $E900: a character row is 256 bytes, eight lines of 32) and a colour buffer (ColourBuffer $E600), and copied to the
; screen only where a mark (DrawMarks $E300, one byte a character, laid out as the screen's character positions) asks:
; RenderGrid $8960 turns each cell into four characters through CellTable $8200, DrawMarkedChars $8A09 draws the
; marked ones, CopyPlayArea $8C10 copies the marked ones and counts each mark down.
;
; The marks are set by whoever changes a cell: BuildLevel (all, 1), the turning elements (1), the explosions and
; HighlightCell (2), the beam and the cursor code ($9xxx). The wipes $8C95 / $8CA2 bring a whole buffer onto the
; screen in a rectangle growing from a random corner; the print routines $8E3A / $8E47 draw text records into the
; full-screen buffer ($E500 / $E200) or the play buffers.
; --------------------------------------------------------------------------------------------------------------------

  ORG $8200

; The four characters of each cell code $00-$5C: top left, top right, bottom
; left, bottom right
;
; RenderGrid `$8960` (`$8975` and, for a turning element, `$89D4`) takes
; `$8200` + 4 x code (bit 7 cleared) and puts the four character codes into the
; character map `$E000`; DrawMarkedChars `$8A09` draws each character from
; CellGraphics `$D700` + 8 x character in the colour CellColours `$DF00` +
; character.
;
; Mirrors `$01-$10` use characters `$01-$30` (16 drawings sharing some
; quarters); polarisers `$11-$18` (cyan) and `$19-$20` (yellow) characters
; `$31-$70`, four of their own each; the walls `$21-$2F` (absorbing) and
; `$30-$3E` (reflecting) are built of one character, `$71` or `$72`, in the
; quarters the code names, `$00` elsewhere; cell `$40` `$74-$77`, mine `$41`
; `$78-$7B`, prism `$42` `$7C-$7F`; `$43-$46` `$80-$8F` (the four lasers drawn
; in cyan: no level holds these codes); lasers `$47-$4A` `$90-$9F`; receivers
; `$4B-$4E` `$A0-$AF`; the fibre-optic ends `$50-$57` `$B0-$BF` (a pair shares
; its four characters); the explosion frames `$58-$5C` `$C0-$D3`.
;
; Never read in the recordings: `$29`, `$2A` (the diagonal wall pairs), `$3F`
; (the cell's characters), `$43-$46`, `$4F` (four blanks): no level holds them.
; Editable form: tables/cell-table.csv.
CellTable:
  INCBIN "res/tables/cell-table.bin",$0000,372

  ORG $8960

; Each grid cell to four character codes in the character map; turning elements
; step on; then DrawMarkedChars
;
; For the 9 x 15 cells of LevelGrid `$FD23`, CharMapPointer runs from `$E021`
; (row 1, column 1: the cell (r, c) is the characters (2r+1, 2c+1) to (2r+2,
; 2c+2)); the cell code's four bytes in CellTable `$8200` + 4 x code are the
; top-left, top-right, bottom-left and bottom-right character codes.
;
; A code with bit 7 set is a turning element (RenderGridTurning): the code
; steps on once a pass, the mirrors `$01-$10` round 16 angles, the blocks
; `$11-$18` and `$19-$20` round their 8, and the cell's four DrawMarks are set
; to 1. Other codes with bit 7 (`$A1` up) draw as their low code without
; turning.
;
; Writes the map every pass but marks only the turning cells: a cell another
; routine changes is drawn because that routine marks it.
;
; Jumps to DrawMarkedChars. From MainLoop (`$8550`) every pass and from
; BuildLevel (falls in).
;
; Witness: L1 111344 (c1, c1g, cheat, controls, energy, energy-out, hof,
; kempston, menu, mine, overload, L x20, rzx x59).
RenderGrid:
  LD HL,CharMap+31
  LD (CharMapPointer),HL
  LD HL,LevelGrid+35             ; the grid, 9 rows of 15
  LD C,$09
RenderGridRow:
  LD B,$0F
RenderGridCell:
  PUSH BC
  PUSH HL
  LD A,(HL)
  BIT 7,A
  JP NZ,RenderGridTurning
RenderGridDraw:
  LD DE,CellTable         ; the cell's four codes from CellTable + 4 x code
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  EX DE,HL
  LD HL,(CharMapPointer)  ; two characters on, then the top row's two and the
                          ; bottom row's two
  INC HL
  INC HL
  LD (CharMapPointer),HL
  LD A,(DE)
  LD (HL),A
  INC E
  INC L
  LD A,(DE)
  LD (HL),A
  INC E
  LD BC,$001F
  ADD HL,BC
  LD A,(DE)
  LD (HL),A
  INC E
  INC L
  LD A,(DE)
  LD (HL),A
RenderGridNext:
  POP HL
  INC HL
  POP BC
  DJNZ RenderGridCell
  PUSH HL                 ; next row: the map pointer down two rows, the grid
                          ; past the two guards
  LD HL,(CharMapPointer)
  LD DE,$0022
  ADD HL,DE
  LD (CharMapPointer),HL
  POP HL
  INC HL
  INC HL
  DEC C
  JR NZ,RenderGridRow
  JP DrawMarkedChars      ; draw the marked characters
RenderGridTurning:
  RES 7,A                 ; bit 7: a turning element steps one angle
  CP $10
  JR C,RenderGridTurned
  JR NZ,RenderGridBlock
  XOR A                   ; mirror $10 back to $01
  JR RenderGridTurned
RenderGridBlock:
  CP $18
  JR C,RenderGridTurned
  JP NZ,RenderGridBlock2
  LD A,$10                ; block $18 back to $11
  JR RenderGridTurned
RenderGridBlock2:
  CP $20
  JR C,RenderGridTurned
  JP NZ,RenderGridDraw
  LD A,$18                ; block $20 back to $19
RenderGridTurned:
  INC A                   ; the new code with bit 7 into the grid, its
                          ; characters into the map
  LD (HL),A
  SET 7,(HL)
  LD DE,CellTable
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  EX DE,HL
  LD HL,(CharMapPointer)
  INC HL
  INC HL
  LD (CharMapPointer),HL
  LD A,(DE)
  LD (HL),A
  INC E
  INC L
  LD A,(DE)
  LD (HL),A
  INC E
  LD BC,$001F
  ADD HL,BC
  LD A,(DE)
  LD (HL),A
  INC E
  INC L
  LD A,(DE)
  LD (HL),A
  LD HL,(CharMapPointer)  ; its four DrawMarks set to 1
  INC H
  INC H
  INC H
  LD A,$01
  LD (HL),A
  INC L
  LD (HL),A
  ADD HL,BC
  LD (HL),A
  INC L
  LD (HL),A
  JP RenderGridNext

; Draw every marked character into the play buffers, the practice line, the
; frame round the play area
;
; For each of the 640 DrawMarks `$E300` with a nonzero mark: the character code
; at the same place in the character map (`$E000`), its colour `$DF00` + code
; (CellColours) to ColourBuffer `$E600`, its eight lines `$D700` + 8 x code
; (CellGraphics) to PixelBuffer `$E900` (row r, column c at `$E900` + 256 r +
; c, a line every 32 bytes). The marks are left as they are: CopyPlayArea
; counts them down.
;
; In practice (PracticeFlag) PrintPlay `$8E47` writes PracticeText on row 19.
; Then the frame: line 0 and line 159 of the pixel buffer all set, and the left
; pixel of column 0 and the right pixel of column 31 on lines 1-158.
;
; From RenderGrid. The practice line is known only from the code (`$8A6E` ran
; in no recording).
;
; Witness: L1 111334 (c1, c1g, cheat, controls, energy, energy-out, hof,
; kempston, menu, mine, overload, L x20, rzx x59).
DrawMarkedChars:
  LD HL,PixelBuffer
  LD DE,DrawMarks
DrawMarkedLoop:
  LD A,(DE)
  AND A
  JP Z,DrawMarkedNext
  PUSH DE                 ; a marked character: its code, colour and glyph
  PUSH HL
  LD B,H
  LD C,L
  DEC D
  DEC D
  DEC D
  LD A,(DE)
  LD H,$DF
  LD L,A
  LD A,D                  ; the colour to ColourBuffer ($E000 + $600)
  ADD A,$06
  LD D,A
  LD A,(HL)
  LD (DE),A
  LD H,$00                ; the glyph: CellGraphics + 8 x code
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,CellGraphics
  ADD HL,DE
  EX DE,HL
  LD H,B
  LD L,C
  LD BC,$0020             ; eight lines, 32 bytes apart
  LD A,(DE)
  LD (HL),A
  INC E
  SET 5,L
  LD A,(DE)
  LD (HL),A
  INC E
  ADD HL,BC
  LD A,(DE)
  LD (HL),A
  INC E
  SET 5,L
  LD A,(DE)
  LD (HL),A
  INC E
  ADD HL,BC
  LD A,(DE)
  LD (HL),A
  INC E
  SET 5,L
  LD A,(DE)
  LD (HL),A
  INC E
  ADD HL,BC
  LD A,(DE)
  LD (HL),A
  INC E
  SET 5,L
  LD A,(DE)
  LD (HL),A
  POP HL
  POP DE
DrawMarkedNext:
  INC DE
  INC L
  BIT 5,L
  JP Z,DrawMarkedLoop
  LD L,$00                ; the next character row: 256 bytes on
  INC H
  LD A,H
  CP $FD
  JP NZ,DrawMarkedLoop
  LD A,(PracticeFlag)     ; practice: the PRACTICE MODE line
  AND A
  JR Z,DrawMarkedFrame
  LD HL,PracticeText
  CALL PrintPlay
DrawMarkedFrame:
  LD HL,PixelBuffer             ; the frame: top and bottom lines
  LD DE,PixelBuffer+1
  LD (HL),$FF
  LD BC,$001F
  LDIR
  LD HL,PixelBuffer
  LD DE,PixelBuffer+5088
  LD BC,$0020
  LDIR
  LD HL,PixelBuffer+32             ; the side pixels, lines 1-158
  LD DE,$001F
  LD B,$9E
DrawMarkedFrameLoop:
  SET 7,(HL)
  ADD HL,DE
  SET 0,(HL)
  INC HL
  DJNZ DrawMarkedFrameLoop
  RET

; The practice line: a print record for PrintPlay, row 19 of the play area in
; bright magenta
;
; Record: the attribute `$43` with bit 7 set, column 0, row `$13`, then 32
; characters, then `$FF` (the end of the records). Printed by DrawMarkedChars
; in practice; known only from the code.
PracticeText:
  DEFB $C3,$00,$13
  DEFB $20,$50,$52,$41,$43,$54,$49,$43 ; " PRACTICE MODE . G AND U ABORTS "
  DEFB $45,$20,$4D,$4F,$44,$45,$20,$2E
  DEFB $20,$47,$20,$41,$4E,$44,$20,$55
  DEFB $20,$41,$42,$4F,$52,$54,$53,$20
  DEFB $FF                ; the end of the records

  ORG $8B9B

; Copy the full-screen buffer to the screen: pixels $E500 (24 rows of 256) and
; attributes $E200
;
; The linear buffer (`$E500` + 256 r + 32 l + c, character row r, line l) to
; the screen in its own layout, 24 rows x 8 lines x 32 `LDI`; then 767
; attributes from `$E200` to `$5800` (the last one, row 23 column 31, is not
; copied).
;
; From the ending (`$A8D4`) and `$9DD6` (the menu). Run twice, in `rzx-344752`
; (the ending); the menu's call ran in no recording.
;
; Witness: L1 4 (ending, hof, rzx344752).
CopyFullScreen:
  LD HL,DrawMarks+512
  LD DE,Screen
  LD A,$18
CopyFullScreenRow:
  EX AF,AF'
  LD A,$08
  PUSH DE
CopyFullScreenLine:
  PUSH DE                 ; 32 bytes of one line
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
  INC D
  DEC A
  JR NZ,CopyFullScreenLine
  POP DE                  ; the next character row on the screen (the third
                          ; carried)
  EX DE,HL
  RRC H
  RRC H
  RRC H
  LD BC,$0020
  ADD HL,BC
  RLC H
  RLC H
  RLC H
  EX DE,HL
  EX AF,AF'
  DEC A
  JR NZ,CopyFullScreenRow
  LD HL,CharMap+512             ; the attributes
  LD DE,Attributes
  LD BC,$02FF
  LDIR
  RET

; Copy the marked characters of the play area to the screen, counting each mark
; down; then all colours
;
; Walks DrawMarks backwards from `$E57F` (row 19, column 31) to `$E300`: a
; mark's low byte is the screen's low byte, its page (`$E3`-`$E5`) the screen
; third, so the character at the mark is the screen address B x 256 + E (B from
; `$57` down to `$47`, the third's last line). A nonzero mark is decremented
; and the character's eight lines (PixelBuffer, from line 7 up, 32 bytes apart)
; go to the screen.
;
; Then the 640 colours of ColourBuffer `$E600` to the attributes `$5800` (rows
; 0-19) in one `LDIR`.
;
; From MainLoop (`$85AB`), every pass. A mark of 2 (an explosion,
; HighlightCell) draws the character on two passes.
;
; Witness: L1 111060 (c1, c1g, cheat, controls, energy, energy-out, hof,
; kempston, menu, mine, overload, L x20, rzx x59).
CopyPlayArea:
  LD HL,PixelBuffer+5119
  LD E,$7F
  LD C,$E5
  LD B,$57

; The marks' page (a screen third) in C, the screen's page in B: on with the
; next character
;
; Part of CopyPlayArea. An entry of its own: the `mine` and `overload`
; recordings start inside the loop (CopyPlayAreaNext `$8C56` is their root),
; and the walk shares these jump targets with CopyPlayArea.
;
; Witness: L1 333179 (c1, c1g, cheat, controls, energy, energy-out, gameover,
; hof, kempston, menu, mine, overload, L x20, rzx x59).
CopyPlayAreaThird:
  LD D,C

; The next mark: zero, skip; else count it down and copy the character's eight
; lines
;
; Part of CopyPlayArea (see CopyPlayAreaThird).
;
; Witness: L1 71078071 (c1, c1g, cheat, controls, energy, energy-out, gameover,
; hof, kempston, menu, mine, overload, L x20, rzx x59).
CopyPlayAreaLoop:
  LD A,(DE)
  AND A
  JP Z,CopyPlayAreaSkip
  DEC A
  LD (DE),A
  LD D,B                  ; eight lines, from line 7 up
  LD A,(HL)
  LD (DE),A
  DEC D
  RES 5,L
  LD A,(HL)
  LD (DE),A
  DEC D
  LD A,$E0
  ADD A,L
  LD L,A
  LD A,(HL)
  LD (DE),A
  DEC D
  RES 5,L
  LD A,(HL)
  LD (DE),A
  DEC D
  LD A,$E0
  ADD A,L
  LD L,A
  LD A,(HL)
  LD (DE),A
  DEC D
  RES 5,L
  LD A,(HL)
  LD (DE),A
  DEC D
  LD A,$E0
  ADD A,L
  LD L,A
  LD A,(HL)
  LD (DE),A
  DEC D
  RES 5,L
  LD A,(HL)
  LD (DE),A
  LD A,$E0
  ADD A,L
  LD L,A
  LD D,C                  ; back to the marks' page
CopyPlayAreaSkip:
  DEC E                   ; the next mark and character to the left
  DEC L
  BIT 5,L

; Still in the row: the next character; else the row above, the third below at
; a page's end
;
; Part of CopyPlayArea. An entry of its own: the `gameover`, `mine` and
; `overload` recordings start from snapshots taken here, so their L1s mark a
; routine root.
;
; Witness: L1 71078068 (c1, c1g, cheat, controls, energy, energy-out, gameover,
; hof, kempston, menu, mine, overload, L x20, rzx x59).
CopyPlayAreaNext:
  JP NZ,CopyPlayAreaLoop
  LD L,$FF                ; the character row above
  DEC H
  LD A,E
  CP L
  JP NZ,CopyPlayAreaLoop
  LD A,$F8                ; a marks page done: the screen third above
  ADD A,B
  LD B,A
  DEC C
  LD A,C
  CP $E3
  JP NC,CopyPlayAreaThird
  LD HL,ColourBuffer             ; all 640 colours to the attributes
  LD DE,Attributes
  LD BC,$0280
  LDIR
  RET

; The wipe's state: four steps, four addresses, the size, the table, a copy of
; the addresses
;
; Filled by WipeIn `$8CAD` from a 16-byte record of PlayAreaWipes /
; ScreenWipes: the four steps (added each round) and the four start addresses:
; the screen pixels, the attributes, the buffer's pixels, the buffer's colours.
WipeSteps:
WipeStepScreen:
  DEFW $0000              ; the screen's step (in character positions)
WipeStepAttrs:
  DEFW $0000              ; the attributes' step
WipeStepPixels:
  DEFW $0000              ; the buffer pixels' step
WipeStepColours:
  DEFW $0000              ; the buffer colours' step
WipeScreen:
  DEFW $0000              ; the rectangle's top-left on the screen (line 0)
WipeAttrs:
  DEFW $0000              ; its attribute
WipePixels:
  DEFW $0000              ; the buffer's top-left pixel byte
WipeColours:
  DEFW $0000              ; the buffer's colour

; The rectangle's height in character rows, 1 up
WipeRows:
  DEFB $00

; The rectangle's width in bytes, from 13 or 9 up to 32 (read as BC: the high
; byte stays 0)
WipeWidth:
  DEFW $0000

; The record table of this wipe: PlayAreaWipes or ScreenWipes
WipeTable:
  DEFW $0000

; The four addresses at the start of a round (the rows move them)
WipeSaved:
  DEFW $0000,$0000,$0000,$0000

; Wipe the full-screen buffer ($E500 / $E200) onto the screen from a random
; corner
;
; WipeWidth = 9, WipeTable = ScreenWipes `$8DD5`; then WipeIn. From the menu
; (`$9CA3`, `$A758`).
;
; Witness: L1 12 (c1, c1g, controls, energy, energy-out, hof, kempston, menu,
; rzx344752).
WipeInScreen:
  LD A,$09
  LD (WipeWidth),A
  LD HL,ScreenWipes
  LD (WipeTable),HL
  JR WipeIn

; Wipe the play buffers ($E900 / $E600) onto the screen's rows 0-19 from a
; random corner
;
; WipeWidth = 13, WipeTable = PlayAreaWipes `$8D95`; falls into WipeIn. From
; SetUpLevel (`$8512`).
;
; Witness: L1 196 (c1, c1g, cheat, controls, energy, energy-out, hof, kempston,
; menu, mine, overload, L x20, rzx x59).
WipeInPlayArea:
  LD A,$0D
  LD (WipeWidth),A
  LD HL,PlayAreaWipes
  LD (WipeTable),HL

; Grow a rectangle of the buffer on the screen from a corner, one row and one
; column a round
;
; Random `$8E15`: L AND 3 picks one of the table's four records (a corner),
; copied to WipeSteps. WipeRows = 1. Each round: the four addresses saved;
; WipeRows character rows of WipeWidth bytes are copied (eight lines from the
; linear buffer, 32 bytes a line, to the screen; one attribute row from the
; colour buffer); a pause of (33 - WipeWidth) x 255 `DJNZ` (the rounds speed
; up); the addresses back, plus their steps; WipeRows + 1 and WipeWidth + 1
; until the width passes 32.
;
; The steps move the screen corner and the source corner so that the picture
; slides in: from the top-left the screen corner stays and the source runs from
; the buffer's bottom-right part to its top-left (`$FEFF` = up one row and left
; one byte); at the end the whole buffer is on the screen. The play area: 13 x
; 1 to 32 x 20 in 20 rounds; the full screen: 9 x 1 to 32 x 24 in 24.
;
; Witness: L1 208 (c1, c1g, cheat, controls, energy, energy-out, hof, kempston,
; menu, mine, overload, L x20, rzx x60).
WipeIn:
  CALL Random
  LD A,L
  AND $03
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  LD C,A
  LD B,$00
  LD HL,(WipeTable)
  ADD HL,BC
  LD DE,WipeSteps
  LD BC,$0010
  LDIR
  LD A,$01                ; one row to start
  LD (WipeRows),A
WipeInRound:
  LD HL,WipeScreen        ; save the four addresses
  LD DE,WipeSaved
  LD BC,$0008
  LDIR
  LD A,(WipeRows)
WipeInRow:
  LD HL,(WipePixels)      ; one character row of the rectangle
  LD DE,(WipeScreen)
  EX AF,AF'
  LD A,$08
  PUSH DE
WipeInLine:
  PUSH DE                 ; one line: WipeWidth bytes
  PUSH HL
  LD BC,(WipeWidth)
  LDIR
  POP HL
  POP DE
  LD BC,$0020
  ADD HL,BC
  INC D
  DEC A
  JR NZ,WipeInLine
  POP DE                  ; the next character row on the screen (the third
                          ; carried)
  EX DE,HL
  RRC H
  RRC H
  RRC H
  ADD HL,BC
  RLC H
  RLC H
  RLC H
  EX DE,HL
  LD (WipePixels),HL
  LD (WipeScreen),DE
  LD HL,(WipeColours)     ; the attribute row
  LD DE,(WipeAttrs)
  PUSH DE
  PUSH HL
  LD BC,(WipeWidth)
  LDIR
  POP HL
  POP DE
  LD BC,$0020
  ADD HL,BC
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  LD (WipeColours),HL
  LD (WipeAttrs),DE
  EX AF,AF'
  DEC A
  JR NZ,WipeInRow
  LD A,(WipeWidth)        ; a pause: (33 - width) x 255 DJNZ
  LD B,A
  LD A,$21
  SUB B
WipeInPause:
  LD B,$FF
WipeInPauseInner:
  DJNZ WipeInPauseInner
  DEC A
  JR NZ,WipeInPause
  LD HL,WipeSaved         ; the addresses back, plus the steps
  LD DE,WipeScreen
  LD BC,$0008
  LDIR
  LD HL,(WipeScreen)
  LD BC,(WipeStepScreen)
  RRC H
  RRC H
  RRC H
  ADD HL,BC
  RLC H
  RLC H
  RLC H
  LD (WipeScreen),HL
  LD HL,(WipeAttrs)
  LD BC,(WipeStepAttrs)
  ADD HL,BC
  LD (WipeAttrs),HL
  LD HL,(WipePixels)
  LD BC,(WipeStepPixels)
  ADD HL,BC
  LD (WipePixels),HL
  LD HL,(WipeColours)
  LD BC,(WipeStepColours)
  ADD HL,BC
  LD (WipeColours),HL
  LD A,(WipeRows)         ; one row and one column more
  INC A
  LD (WipeRows),A
  LD A,(WipeWidth)
  INC A
  LD (WipeWidth),A
  CP $21
  JP C,WipeInRound
  RET

; WipeInPlayArea's four corners: four steps then four start addresses each
; (screen, attributes, pixels, colours)
;
; The play area (20 rows, PixelBuffer `$E900`, ColourBuffer `$E600`) grows from
; the screen's top-left, top-right, bottom-left or bottom-right corner, the
; picture sliding in from that side. The first record was picked at 41 of the
; 164 set-ups in the builds other than `c1` (the reads of `$8D95`).
PlayAreaWipes:
  DEFW $0000,$0000,$FEFF,$FFDF,$4000,$5800,$FC13,$E873 ; top-left: the screen
                                                       ; corner stays at $4000,
                                                       ; the source runs
                                                       ; up-left from row 19,
                                                       ; column 19
  DEFW $FFFF,$FFFF,$FF00,$FFE0,$4013,$5813,$FC00,$E860 ; top-right: the screen
                                                       ; corner left from
                                                       ; column 19, the source
                                                       ; up from row 19, column
                                                       ; 0
  DEFW $FFE0,$FFE0,$FFFF,$FFFF,$5060,$5A60,$E913,$E613 ; bottom-left: the
                                                       ; screen corner up from
                                                       ; row 19, the source
                                                       ; left from row 0,
                                                       ; column 19
  DEFW $FFDF,$FFDF,$0000,$0000,$5073,$5A73,$E900,$E600 ; bottom-right: the
                                                       ; screen corner up-left
                                                       ; from row 19, column
                                                       ; 19, the source stays
                                                       ; at the buffer's
                                                       ; top-left

; WipeInScreen's four corners: as PlayAreaWipes, for the 24-row full-screen
; buffer ($E500 / $E200)
;
; The same four corners from column 23 and row 23. The first record was picked
; once of the 9 menu wipes (`menu`).
ScreenWipes:
  DEFW $0000,$0000,$FEFF,$FFDF,$4000,$5800,$FC17,$E4F7 ; top-left
  DEFW $FFFF,$FFFF,$FF00,$FFE0,$4017,$5817,$FC00,$E4E0 ; top-right
  DEFW $FFE0,$FFE0,$FFFF,$FFFF,$50E0,$5AE0,$E517,$E217 ; bottom-left
  DEFW $FFDF,$FFDF,$0000,$0000,$50F7,$5AF7,$E500,$E200 ; bottom-right

; The next random number: RandomSeed = 254 x (RandomSeed + 1) mod 65537 - 1; HL
; = the new seed
;
; H = E, L = `$FD`, then three subtractions with borrows: 256 x seed - 2 x seed
; + 253 taken modulo 65537 (`$10001`) and folded to 16 bits, the Lehmer
; generator of the Spectrum ROM's RND with 254 for its 75. Checked against that
; formula for all 65 536 seeds (work/ann/01-main/rnd_check.py); the period is
; 65 536.
;
; Callers: WipeIn (the corner), the grey grid (`$9014`, the scatter), the
; charging's scramble (`$A587`), the noise sound (`$A896`), the gremlins
; (`$ABED`, `$AC31`, `$AC53`). The options panel's key wait adds 1 to the seed
; on each of its loops (`$A7AB-$A7AF`), so the game's random numbers depend on
; how long the panel waited; `$ACA0` reads the seed's high byte.
;
; Witness: L1 799870 (c1, c1g, cheat, controls, energy, energy-out, hof,
; kempston, menu, mine, overload, L x20, rzx x60).
Random:
  LD DE,(RandomSeed)
  LD H,E
  LD L,$FD
  LD A,D
  OR A
  SBC HL,DE
  SBC A,$00
  SBC HL,DE
  SBC A,$00
  LD E,A
  LD D,$00
  SBC HL,DE
  JR NC,RandomStore
  INC HL
RandomStore:
  LD (RandomSeed),HL
  RET

; The random seed, $22B8 in the image
RandomSeed:
  DEFW $22B8

; The print routines' pixel address of the next character
PrintPixel:
  DEFW $0000
PrintColour:
  DEFW $0000              ; their colour address of the next character

; The pixel buffer's page: $E5 (PrintFull) or $E9 (PrintPlay)
PrintPixelPage:
  DEFB $00
PrintColourPage:
  DEFB $00                ; the colour buffer's page: $E2 or $E6

; Print the text records at HL into the full-screen buffer (pixels $E500,
; attributes $E200)
;
; PrintPixelPage = `$E5`, PrintColourPage = `$E2`; then PrintRecords (in
; PrintPlay). From the hall of fame (`$9F2B`-`$9F3D`) and the ending (`$A8D1`).
;
; Witness: L1 66 (c1, c1g, controls, ending, energy-out, gameover, hof,
; kempston, menu, mine, overload, rzx344752).
PrintFull:
  LD A,$E5
  LD (PrintPixelPage),A
  LD A,$E2
  LD (PrintColourPage),A
  LD A,(HL)
  JR PrintRecords

; Print the text records at HL into the play buffers (pixels $E900, colours
; $E600)
;
; PrintPixelPage = `$E9`, PrintColourPage = `$E6`, then the records. A record:
; the attribute with bit 7 set, the column, the character row (into the buffer:
; the pixels at page + row, the colour at page x 256 + 32 x row + column), then
; the characters (32 up, eight lines from Font: `$D200` + 8 x (code - 32), 32
; bytes apart) until a byte with bit 7: the next record, or `$FF`, the end.
;
; The colour is written for every character but `/` and `\` (`$2F`, `$5C`),
; which keep the colour under them.
;
; PrintPlay's own part runs only for PracticeText (DrawMarkedChars `$8A71`):
; known only from the code; PrintRecords runs only for PrintFull.
;
; Witness: L1 0 ().
PrintPlay:
  LD A,$E9
  LD (PrintPixelPage),A
  LD A,$E6
  LD (PrintColourPage),A
  LD A,(HL)
; This entry point is used by the routine at PrintFull.
PrintRecords:
  CP $FF                  ; $FF: the end; else the record's attribute
  RET Z
  RES 7,A
  EX AF,AF'
  INC HL                  ; the column (C) and the character row (B + the pixel
                          ; page)
  LD C,(HL)
  INC HL
  LD B,(HL)
  LD A,(PrintPixelPage)
  ADD A,B
  LD B,A
  LD (PrintPixel),BC
  LD A,(HL)               ; the colour address: the colour page + 32 x row +
                          ; column
  INC HL
  EX DE,HL
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,(PrintColourPage)
  LD B,A
  ADD HL,BC
  LD (PrintColour),HL
  EX DE,HL
PrintChar:
  LD A,(HL)               ; bit 7: the next record
  BIT 7,A
  JR NZ,PrintRecords
  PUSH HL                 ; the glyph: Font + 8 x (code - 32)
  SUB $20
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,Font
  ADD HL,BC
  LD B,$08
  LD DE,(PrintPixel)
PrintCharLine:
  LD A,(HL)               ; eight lines, 32 bytes apart
  LD (DE),A
  PUSH HL
  LD HL,$0020
  ADD HL,DE
  EX DE,HL
  POP HL
  INC HL
  DJNZ PrintCharLine
  LD DE,(PrintColour)     ; the colour, except under / and \
  POP HL
  LD A,(HL)
  CP $2F
  JR Z,PrintCharNext
  CP $5C
  JR Z,PrintCharNext
  EX AF,AF'
  LD (DE),A
  EX AF,AF'
PrintCharNext:
  INC E
  LD (PrintColour),DE
  LD DE,(PrintPixel)
  INC E
  LD (PrintPixel),DE
  INC HL
  JR PrintChar

  ORG $D200

; The text font: 96 characters 32-127, 8 bytes each (glyph = $D200 + 8 x (code
; - 32))
;
; Read by the printers PrintFull `$8E3A` / PrintPlay `$8E47` (`$8E87`, `LD
; BC,$D200`), the COMPUTER line and the menu line (`$A3B0`, `$A401`, `$A4DE`:
; `$D202` / `$D200`, glyph rows 2-6 scrolled), the score (`$9B1D`), the pause
; (`$9787`), and as the blank space glyph `$D200` (`$9CF9`, `$9D3B`, `$9DFA`,
; `$A82C`).
;
; Characters 32-90: the text (`,` a small ring, `.` a small diamond, `@` the
; copyright sign, `[`-`_` unused); characters `$61-$7A` with `(` and `)` are
; the 2 x 15 pieces of the DEFLEKTOR logo of the options screen (OptionsText
; `$9F59`: "(abcdefghijklm(" over ")nopqrstuvwxyz)"); `$7B-$7F` are blank.
; Characters no recording printed: 34-39, 42, 43, 47, 58-63, 81, 90-96, 123-127
; (the COMPUTER and menu lines read only rows 2-6 of a glyph). Editable form:
; graphics/font.png.
Font:
  INCBIN "res/graphics/font.bin",$0000,768

  ORG $D700

; The 212 characters of the cell elements, 8 bytes each, characters $00-$D3
; (CellTable's codes)
;
; DrawMarkedChars `$8A09` (`$8A2A`) draws a marked character from `$D700` + 8 x
; code, its colour from CellColours `$DF00` + code (`$8A1C`, `LD H,$DF`).
; Character 0 is the empty background (four dots); the beam's wipes (`$937C`,
; `$93C7`, `$95FA`, `$9645`) copy it over a glyph to erase it.
;
; Characters: `$01-$30` the mirrors' art, `$31-$50` the cyan polarisers',
; `$51-$70` the yellow ones', `$71` the absorbing wall quarter, `$72` the
; reflecting one, `$73` unused (zeros), `$74-$77` the cell, `$78-$7B` the mine,
; `$7C-$7F` the prism, `$80-$8F` the cyan lasers (codes `$43-$46`, unused),
; `$90-$9F` the lasers, `$A0-$AF` the receivers, `$B0-$BF` the four fibre-optic
; pictures, `$C0-$D3` the explosion's five frames. CellTable names no character
; above `$D3`. Editable form: graphics/cells.png, with CellColours.
CellGraphics:
  INCBIN "res/graphics/cell-graphics.bin",$0000,1696

; 352 bytes of 0: the graphics of characters $D4-$FF, which no cell code names
;
; CellTable's largest character is `$D3`, so `$D700` + 8 x `$D4` onwards
; (`$DDA0-$DEFF`) is never drawn; no recording reads it.
SpareCellGraphics:
  INCBIN "res/leftovers/cell-graphics-spare.bin",$0000,352

; The attribute of each character $00-$D3 of CellGraphics
;
; Read by DrawMarkedChars (`$8A1C`): `$43` (bright magenta on black) the
; background, the cell and the mine; `$04` the mirrors (green); `$0D` the cyan
; polarisers; `$16` the yellow ones and the reflecting wall quarter; `$42` the
; absorbing wall quarter; `$17` the prism; `$05` the cyan lasers; `$07` the
; lasers and receivers; `$38-$3B` the four fibre-optic pictures (black on
; white, blue, red, magenta); `$47`, `$46`, `$06`, `$42` the explosion's
; frames. Not read: `$DF73` (character `$73`, `$07`) and `$DF80-$DF8F` (the
; cyan lasers). Editable form: graphics/cells.png.
CellColours:
  INCBIN "res/graphics/cell-colours.bin",$0000,212

; 44 bytes of 0: the colours of characters $D4-$FF, never read
;
; As SpareCellGraphics: no character above `$D3` is drawn; no recording reads
; `$DFD4-$DFFF`.
SpareCellColours:
  INCBIN "res/leftovers/cell-colours-spare.bin",$0000,44
