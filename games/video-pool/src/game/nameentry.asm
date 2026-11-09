; --------------------------------------------------------------------------------------------------------------------
; nameentry.asm: The name entry: the "congratulations" page, the character grid, the cursor, the 7-character name
;
; NameEntryPage $ACEF clears the screen to black on yellow, prints the title ("congratulations!", or with "player 1" /
; "player 2" in a two-player game, by $9B30) and the eight lines of HofTextList $AD3D, then NameEntry $AE92 draws the
; grid CharacterGrid $B167 (a-n, o-z space ".", 0-9 "rub" "end": 3 rows of 14 cells, 16 pixels apart), the name line
; of seven "_" and the cursor box, and polls the input dispatcher $8106 once a frame (screen w1 frame 12500).
;
; Input bits of $827C ($8106): right ($01) or down ($08) moves the cursor forward, left ($02) or up ($04) back, with
; auto-repeat (RepeatDelay $B226: the first step at once, then after 7, 6, 5, 4, 3 and 2 frames, then every 2 frames);
; fire ($10) picks the cell: a character is stored at the name cursor (the 7th cell is overwritten while the name is
; full), "rub" steps back and writes "_", "end" turns the "_" into spaces, centres the name in its 7 characters and
; returns from the page to GameOverHallOfFame. Each step clicks (BEEPER, HL $03E8 DE $14), each pick a lower click (HL
; $04B0, DE $16). w1 typed "vp" and "end" (frames 12025-13368).
; --------------------------------------------------------------------------------------------------------------------

; The "congratulations" page, then the name entry
;
; Clears the pixels, attributes $30 (black on yellow), border 6 and BORDCR $30.
; The title: HofTitle $AD4F when Players $B8BB = 1, else HofTitleP1 $AD63 or
; HofTitleP2 $AD81 by $9B30; then each text record of HofTextList $AD3D
; ($9E65), then a jump to NameEntry $AE92 (its RET goes back to
; GameOverHallOfFame).
;
; Witness: w1 1, frames 12018-12023 (the title HofTitle; HofTitleP1/P2 read by
; no recording, l1sum.py --reads AD63-AD9E).
NameEntryPage:
  LD HL,Screen
  LD DE,Screen+1
  LD BC,$17FF
  LD (HL),$00
  LDIR
  INC HL
  INC DE
  LD BC,$02FF
  LD (HL),$30
  LDIR
  LD A,$06
  OUT ($FE),A
  LD A,$30
  AND $38
  LD (BORDCR),A
  LD HL,HofTitle
  LD A,(Players)
  DEC A
  JR Z,PrintHofTexts
  LD HL,HofTitleP1
  LD A,(CurrentPlayer)
  DEC A
  JR Z,PrintHofTexts
  LD HL,HofTitleP2
PrintHofTexts:
  CALL PrintText
  LD DE,HofTextList
PrintHofTextLoop:
  LD A,(DE)
  LD L,A
  INC DE
  LD A,(DE)
  LD H,A
  INC DE
  LD A,H
  OR L
  JP Z,NameEntry
  PUSH DE
  CALL PrintText
  POP DE
  JR PrintHofTextLoop

; The eight text records of the name page, then a zero word
;
; Read by NameEntryPage (w1 18 reads).
HofTextList:
  DEFW HofText1,HofText2,HofText3,HofText4,HofText5,HofText6,HofText7,HofText8,$0000

; "congratulations!" (row 0, column 8, attribute $30, 16 characters)
;
; The text records of the page (format: MenuTexts $B464), all attribute $30,
; read by NameEntryPage in w1 (the "player" titles by none).
HofTitle:
  INCBIN "res/text/HofTitle.bin",$0000,20
HofTitleP1:
  INCBIN "res/text/HofTitle.bin",$0014,30
HofTitleP2:
  INCBIN "res/text/HofTitle.bin",$0032,30
HofText1:
  INCBIN "res/text/HofTitle.bin",$0050,36
HofText2:
  INCBIN "res/text/HofTitle.bin",$0074,34
HofText3:
  INCBIN "res/text/HofTitle.bin",$0096,9
HofText4:
  INCBIN "res/text/HofTitle.bin",$009F,36
HofText5:
  INCBIN "res/text/HofTitle.bin",$00C3,35
HofText6:
  INCBIN "res/text/HofTitle.bin",$00E6,35
HofText7:
  INCBIN "res/text/HofTitle.bin",$0109,33
HofText8:
  INCBIN "res/text/HofTitle.bin",$012A,25

; Draw the grid and the empty name, then move the cursor and pick characters
; until "end"
;
; DrawCharacterGrid $B0C7, NameBuffer $B227 = seven "_" ($5F), the cursor at
; row 0 column 0 (D, E; XorCursorBox $B047), RepeatDelay $B226 = $70, HL = the
; name cursor = NameBuffer, DrawName $B0A8. Then the loop NameEntryLoop $AEB3,
; a frame each: HALT, $8106, with $AEB3 pushed as the return address of every
; branch. Nothing held: RepeatDelay = $70. Fire: PickCell. A direction:
; auto-repeat, click, NameCursorForward $AFFE or NameCursorBack $B023.
;
; Witness: w1 1 (frame 12023); NameEntryLoop 1230 frames, 12025-13368; 51
; cursor steps ($AF00), 3 picks ($AF26: v, p, end).
NameEntry:
  CALL DrawCharacterGrid
  LD HL,NameBuffer
  LD DE,NameBuffer+$0001
  LD (HL),$5F
  LD BC,$0006
  LDIR
  LD DE,$0000
  CALL XorCursorBox
  LD A,$70
  LD (RepeatDelay),A
  LD HL,NameBuffer
  CALL DrawName
NameEntryLoop:
  HALT                    ; HL = the name cursor, D/E = the cursor's row/column
  PUSH HL
  PUSH DE
  CALL ReadInput
  POP DE
  POP HL
  LD BC,NameEntryLoop
  PUSH BC
  LD A,(InputState)
  CP $00
  JR NZ,NameEntryDirection
  LD A,$70
  LD (RepeatDelay),A
  RET
NameEntryDirection:
  LD A,(InputState)
  AND $01
  JR NZ,NameEntryRepeat
  LD A,(InputState)
  AND $08
  JR NZ,NameEntryRepeat
  LD A,(InputState)
  AND $02
  JR NZ,NameEntryRepeat
  LD A,(InputState)
  AND $04
  JR Z,NameEntryFire
NameEntryRepeat:
  LD C,A                  ; RepeatDelay - 1; a step only when its low nibble
                          ; wraps to $F
  LD A,(RepeatDelay)
  DEC A
  LD (RepeatDelay),A
  AND $0F
  CP $0F
  RET NZ
  LD A,(RepeatDelay)
  AND $F0
  CP $10
  JR NC,NameEntryStep
  LD A,$10
NameEntryStep:
  LD B,A                  ; the next delay: high nibble - 1 (at least 1) in
                          ; both nibbles; click; $01/$08 forward, else back
  RRCA
  RRCA
  RRCA
  RRCA
  ADD A,B
  LD (RepeatDelay),A
  PUSH HL
  PUSH BC
  PUSH DE
  LD HL,$03E8
  LD DE,$0014
  CALL BEEPER
  POP DE
  POP BC
  POP HL
  LD A,C
  CP $01
  JP Z,NameCursorForward
  CP $08
  JP Z,NameCursorForward
  JP NameCursorBack
NameEntryFire:
  LD A,(InputState)       ; fire: a lower click, PickCell, then wait until no
                          ; input
  AND $10
  RET Z
  PUSH HL
  PUSH BC
  PUSH DE
  LD HL,$04B0
  LD DE,$0016
  CALL BEEPER
  POP DE
  POP BC
  POP HL
  CALL PickCell
NameEntryRelease:
  HALT
  PUSH HL
  PUSH DE
  CALL ReadInput
  POP DE
  POP HL
  LD A,(InputState)
  CP $00
  JR NZ,NameEntryRelease
  RET

; Fire on the cell at row D column E: store the character, rub out, or end
;
; The cell's byte is CharacterGrid[14 D + E]. A character: stored at HL (at the
; 7th position the last character is overwritten), HL + 1, DrawName (a jump).
; $0C "rub": HL - 1 (not before the start), "_" there, DrawName. $0D "end":
; drops the two return addresses (NameEntryFire's and $AEB3) so its RET leaves
; the name entry; turns "_" into spaces, counts the leading (D) and trailing
; (E) spaces and shifts the name by (D - E) / 2 to centre it.
;
; Witness: w1 3 (frames 13102-13368): two characters ($AF76 2), one "end"
; ($AF8C 1, shifted right: $AFDE). Rub ($AF7B) and the left shift ($AFD1) were
; not run.
PickCell:
  LD A,D
  ADD A,A
  LD B,A
  ADD A,A
  ADD A,A
  ADD A,A
  SUB B
  ADD A,E
  LD BC,CharacterGrid
  ADD A,C
  LD C,A
  JR NC,PickCellByte
  INC B
PickCellByte:
  LD A,(BC)
  CP $0C
  JR Z,PickRub
  CP $0D
  JR Z,PickEnd
  PUSH AF
  LD BC,NameBuffer
  XOR A
  SBC HL,BC
  LD A,L
  ADD HL,BC
  POP BC
  CP $07
  JR NZ,PickStore
  DEC HL
PickStore:
  LD (HL),B
  INC HL
  JP DrawName
PickRub:
  LD BC,NameBuffer
  XOR A
  SBC HL,BC
  LD A,L
  ADD HL,BC
  OR A
  JR Z,PickRubMark
  DEC HL
PickRubMark:
  LD (HL),$5F
  JP DrawName
PickEnd:
  POP BC
  POP BC
  LD HL,NameBuffer
  LD B,$07
EndBlankLoop:
  LD A,(HL)
  CP $5F
  JR NZ,EndBlankNext
  LD (HL),$20
EndBlankNext:
  INC HL
  DJNZ EndBlankLoop
  LD D,$00
  LD HL,NameBuffer
  LD B,$07
CountLeadLoop:
  LD A,(HL)
  CP $20
  JR NZ,CountTrail
  INC D
  INC HL
  DJNZ CountLeadLoop
CountTrail:
  LD E,$00
  LD HL,NameBuffer+$0006
  LD B,$07
CountTrailLoop:
  LD A,(HL)
  CP $20
  JR NZ,CentreName
  INC E
  DEC HL
  DJNZ CountTrailLoop
CentreName:
  LD A,D
  SUB E
  RET Z
  JR C,CentreRight
  INC A
  SRL A
  PUSH AF
  LD DE,NameBuffer
  LD HL,NameBuffer
  ADD A,L
  LD L,A
  JR NC,CentreLeft
  INC H
CentreLeft:
  LD BC,$0007             ; more leading spaces: copy the name left
  LDIR
  POP BC
  LD A,$20
CentreLeftFill:
  DEC DE
  LD (DE),A
  DJNZ CentreLeftFill
  RET
CentreRight:
  NEG                     ; more trailing spaces: copy it right (LDDR)
  SRL A
  RET Z
  PUSH AF
  LD DE,NameBuffer+$0006
  LD HL,NameBuffer+$0006
  NEG
  ADD A,L
  LD L,A
  JR C,CentreRightCopy
  DEC H
CentreRightCopy:
  LD BC,$0007
  LDDR
  POP BC
  LD A,$20
CentreRightFill:
  INC DE
  LD (DE),A
  DJNZ CentreRightFill
  RET

; Move the cursor box one cell forward (row 2: column 10 "rub" to 12 "end", 12
; back to the start)
;
; XorCursorBox off, the next cell (column 14 wraps to the next row),
; XorCursorBox on (a jump). Columns 11 and 13 of row 2 are never reached (the
; rub and end cells are two wide). Witness: w1 45, frames 12933-13359.
NameCursorForward:
  CALL XorCursorBox
  LD A,D
  CP $02
  JR NZ,ForwardNext
  LD A,E
  CP $0A
  JR NZ,ForwardFromRub
  LD E,$0C
  JR XorCursorBox
ForwardFromRub:
  CP $0C
  JR NZ,ForwardNext
  LD DE,$0000
  JR XorCursorBox
ForwardNext:
  INC E
  LD A,E
  CP $0E
  JR NZ,XorCursorBox
  LD E,$00
  INC D
  JR XorCursorBox

; Move the cursor box one cell back (row 2: 12 to 10; before row 0 column 0:
; "end")
;
; Witness: w1 6, frames 13114-13154.
NameCursorBack:
  CALL XorCursorBox
  LD A,D
  CP $02
  JR NZ,BackPrevious
  LD A,E
  CP $0C
  JR NZ,BackPrevious
  LD E,$0A
  JR XorCursorBox
BackPrevious:
  DEC E
  LD A,E
  CP $FF
  JR NZ,XorCursorBox
  LD E,$0D
  DEC D
  LD A,D
  CP $FF
  JR NZ,XorCursorBox
  LD DE,$020C
  JR XorCursorBox

; XOR the cursor box round the cell at row D, column E
;
; Cell (D, E) at pixel x = 16 E + $14, y = 16 D + $70; a box 12 pixels wide (28
; for rub and end: row 2, column >= 10), its corners drawn as XorLine $93B3
; lines. Drawing twice erases. Witness: w1 103, frames 12024-13359.
XorCursorBox:
  PUSH HL
  PUSH DE
  LD C,$0C
  LD A,D
  CP $02
  JR C,CursorBoxDraw
  LD A,E
  CP $0A
  JR C,CursorBoxDraw
  LD C,$1C
CursorBoxDraw:
  LD A,E
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,$14
  LD E,A
  LD A,D
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,$70
  LD D,A
  DEC D
  DEC D
  DEC D
  DEC E
  DEC E
  LD B,C
  CALL XorLine
  LD B,$01
  INC D
  CALL XorLine
  INC D
  CALL XorLine
  LD A,D
  ADD A,$08
  LD D,A
  INC D
  CALL XorLine
  INC D
  CALL XorLine
  INC D
  LD B,C
  CALL XorLine
  LD A,E
  ADD A,C
  DEC A
  LD E,A
  LD B,$01
  DEC D
  CALL XorLine
  DEC D
  CALL XorLine
  LD A,D
  ADD A,$F8
  LD D,A
  DEC D
  CALL XorLine
  DEC D
  CALL XorLine
  POP DE
  POP HL
  RET

; Draw NameBuffer's 7 characters at y $B0, x $48 + 16 n
;
; DrawCharAt $B118 for each. Witness: w1 3, frames 12024-13163.
DrawName:
  PUSH HL
  PUSH DE
  LD B,$07
  LD DE,NameBuffer
  LD H,$B0
  LD L,$48
DrawNameLoop:
  PUSH BC
  PUSH HL
  PUSH DE
  LD A,(DE)
  CALL DrawCharAt
  POP DE
  INC DE
  POP HL
  LD A,L
  ADD A,$10
  LD L,A
  POP BC
  DJNZ DrawNameLoop
  POP DE
  POP HL
  RET

; Draw the 42 cells of CharacterGrid (3 rows of 14 at x $10 + 16 n, y $70 + 16
; row), then "rub" and "end"
;
; The $0C / $0D cells print as spaces; the words "rub" and "end" are drawn as
; line lists (DrawLineList $B101 with RubLines $B191 at x $B7, y $90 and
; EndLines $B1DA at x $D7, y $90). Witness: w1 1, frame 12023.
DrawCharacterGrid:
  LD B,$03
  LD DE,CharacterGrid
  LD HL,$7010
GridRowLoop:
  PUSH BC
  PUSH HL
  LD B,$0E
GridCellLoop:
  PUSH BC
  PUSH HL
  PUSH DE
  LD A,(DE)
  CALL DrawCharAt
  POP DE
  INC DE
  POP HL
  LD A,L
  ADD A,$10
  LD L,A
  POP BC
  DJNZ GridCellLoop
  POP HL
  LD A,H
  ADD A,$10
  LD H,A
  POP BC
  DJNZ GridRowLoop
  LD D,$90
  LD E,$B7
  LD HL,RubLines
  CALL DrawLineList
  LD D,$90
  LD E,$D7
  LD HL,EndLines
  CALL DrawLineList
  RET

; XOR a list of horizontal lines (dx, dy, length; $FF ends) from the origin E =
; x, D = y
;
; Witness: w1 2 entries (rub, end), 51 lines.
DrawLineList:
  LD A,(HL)
  CP $FF
  RET Z
  PUSH DE
  LD A,(HL)
  INC HL
  ADD A,E
  LD E,A
  LD A,(HL)
  INC HL
  ADD A,D
  LD D,A
  LD B,(HL)
  INC HL
  PUSH HL
  CALL XorLine
  POP HL
  POP DE
  JR DrawLineList

; Draw character A at pixel (L, H) with a 4-pixel offset (two half bytes a
; line)
;
; Below $20: a space. a-z from Font, digits from Font+$D0, others from
; CHAR_SET. Writes (not XOR) the glyph's left and right nibbles into two bytes,
; so a cell 16 pixels wide shows the glyph centred. Witness: w1 63, frames
; 12023-13163.
DrawCharAt:
  CP $20
  JR NC,DrawCharLetter
  LD A,$20
DrawCharLetter:
  CP $61
  JR C,DrawCharDigit
  CP $7B
  JR NC,DrawCharDigit
  SUB $61
  LD DE,Font
  JR DrawCharGlyph
DrawCharDigit:
  CP $30
  JR C,DrawCharRom
  CP $3A
  JR NC,DrawCharRom
  SUB $30
  LD DE,FontDigits
  JR DrawCharGlyph
DrawCharRom:
  SUB $20
  LD DE,CHAR_SET
DrawCharGlyph:
  PUSH HL
  LD H,$00
  LD L,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  EX DE,HL
  POP HL
  CALL ScreenCell
  LD B,$08
DrawCharLines:
  LD A,(DE)
  RRCA
  RRCA
  RRCA
  RRCA
  AND $0F
  LD (HL),A
  INC HL
  LD A,(DE)
  RRCA
  RRCA
  RRCA
  RRCA
  AND $F0
  LD (HL),A
  DEC HL
  INC H
  INC DE
  DJNZ DrawCharLines
  RET

; The name-entry grid: 3 rows of 14 cells
;
; Read by DrawCharacterGrid and PickCell (w1 45 reads). Row 0 a-n, row 1 o-z,
; space, "."; row 2 0-9, $0C $0C ("rub", two cells), $0D $0D ("end").
CharacterGrid:
  INCBIN "res/text/CharacterGrid.bin",$0000,42

; The word "rub": lines (dx, dy, length) from (x $B7, y $90), $FF ends
;
; Read by DrawLineList (w1 97 reads).
RubLines:
  INCBIN "res/graphics/RubLines.bin",$0000,73

; The word "end": lines (dx, dy, length) from (x $D7, y $90), $FF ends
;
; Read by DrawLineList (w1 102 reads).
EndLines:
  INCBIN "res/graphics/EndLines.bin",$0000,76

; The name entry's auto-repeat counter: two nibbles, high = the delay, low =
; the countdown ($70 at rest)
;
; Written and read by NameEntry (w1 103 reads).
RepeatDelay:
  DEFB $00

; The name being typed: 7 characters ("_" = empty)
;
; Written by NameEntry and PickCell, read by DrawName and copied to
; NewEntryName1 / NewEntryName2 by GameOverHallOfFame (w1 53 reads).
NameBuffer:
  DEFM $00,$00,$00,$00,$00,$00,$00
