; --------------------------------------------------------------------------------------------------------------------
; screen.asm: The menu's screen, the pages and the cursor
;
; DrawScreen $6510 draws the static screen once: the four rhombi (phase 0), the ZYX logo (Logo $A900 at columns 6-25,
; rows 0-4, with LogoAttributes $AC20), the corner gradients (ColourCorners $6CBF), the help lines (MenuHelp $6AFD,
; rows 19-21) and saves it to ScreenCopy $E000. ShowCatalogue $6586 then puts that screen back, clears rows 6-17 and
; lists a page: up to 12 files in one column (names at column 14), 13-24 in two (columns 6 and 22), 24 a page when
; there are more (SYMBOL SHIFT for the next page, CAPS SHIFT for the first). Each line is "X>  name": the letter that
; runs it, in bright cyan, the name green (a BASIC program) or yellow (a 192-sector CODE file).
;
; The cursor is the attribute of its name's 8 cells: every 4th interrupt Interrupt $6757 writes CursorAttr $B3BF there
; and steps it through inks 1-7 (alternately plain and bright); when it moves, the old cells get back CursorSavedAttr
; $B3CB.
; --------------------------------------------------------------------------------------------------------------------

  ORG $6510

; Draw the static screen, save it to ScreenCopy and fall into ShowCatalogue
;
; The rhombi at $4000, $401B, $5060, $507B (RombSource), the logo's four
; sprites at $4006, $400B, $4010, $4015, its attributes (5 rows of 20 from
; LogoAttributes $AC20 to $5806), ColourCorners $6CBF, Chars $5C36 = Font -
; 256, MenuHelp through PrintString $6720; copies the screen to ScreenCopy
; $E000.
;
; Witness: L1 4 (c1-c4).
DrawScreen:
  LD DE,RombSource
  PUSH DE
  PUSH DE
  PUSH DE
  LD HL,Screen
  CALL PrintSprite
  LD HL,Screen+27
  POP DE
  CALL PrintSprite
  LD HL,Screen+4192
  POP DE
  CALL PrintSprite
  LD HL,Screen+4219
  POP DE
  CALL PrintSprite
  LD DE,Logo
  LD HL,Screen+6
  CALL PrintSprite
  LD DE,LogoPart2
  LD HL,Screen+11
  CALL PrintSprite
  LD DE,LogoPart3
  LD HL,Screen+16
  CALL PrintSprite
  LD DE,LogoPart4
  LD HL,Screen+21
  CALL PrintSprite
  LD DE,Attributes+6
  LD HL,LogoAttributes
  LD B,$05
DrawLogoAttrRow:
  PUSH BC
  LD BC,$0014
  LDIR
  LD BC,$000C
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  POP BC
  DJNZ DrawLogoAttrRow
  CALL ColourCorners
  LD HL,FontBase
  LD (Chars),HL
  LD HL,MenuHelp
  CALL PrintString
  LD HL,Screen
  LD DE,ScreenCopy
  LD BC,$1B00
  LDIR

; Show a catalogue page: the clean screen, the file list, the cursor; save the
; screen
;
; SoundOff $6E41; ScreenCopy back to the screen; ClearFilesArea $6930;
; CursorAttr = 1; ListCatalogue $65C7 from the entry at the operand of the LD
; IX at $659C (ShowCatalogueAt: Catalogue $9D00, or the next page's for SYMBOL
; SHIFT); CursorSavedAttr = the attribute under the cursor; PagePointer $B3C1 =
; the page's first entry; Frames $5C78 and TwinkleClock $DEAC = 0; the screen
; to ScreenCopy again (now with the list); SampleStars $645E.
;
; Called from DrawScreen (falling in), ReadKeyboard for CAPS SHIFT, SYMBOL
; SHIFT and SPACE.
;
; Witness: L1 8 (c1-c4).
ShowCatalogue:
  CALL SoundOff
  LD HL,ScreenCopy
  LD DE,Screen
  LD BC,$1B00
  LDIR
  CALL ClearFilesArea
  LD A,$01
  LD (CursorAttr),A
ShowCatalogueAt:
  LD IX,Catalogue         ; LD IX,nn: the page's first catalogue entry
  CALL ListCatalogue
  CALL CursorAttrAddr
  LD A,(HL)
  LD (CursorSavedAttr),A
  LD (PagePointer),IX
  LD HL,$0000
  LD (Frames),HL
  XOR A
  LD (TwinkleClock),A
  LD HL,Screen
  LD DE,ScreenCopy
  LD BC,$1B00
  LDIR
  CALL SampleStars
  RET

; Count the page's files from IX and print them in one or two columns, or NO
; EXE FILES !
;
; Counts the entries from IX to the catalogue's end (a first byte 0, or 128
; entries: the end of Catalogue at $A500) that the menu lists: type B except
; "boot    B" (IsBootFile $6737), and type C of exactly 192 sectors ($C0 at
; +13; a 48K snapshot saved as CODE, which TR-DOS runs with GO TO "name" CODE).
; Deleted entries (first byte 1) are skipped (SkipDeleted $674D).
;
; 0 files: NoFilesText at row 11, column 9, the cursor 14 cells wide on it.
; 1-12: one column (PrintColumn $668E at row 6, column 10, Columns = 1). 13-24:
; ListTwoColumns $6648. 25 or more: ListTwoColumns with 24, NextPagePointer
; $B3C3 = the entry after the 24th, MorePages $B3B9 = 1.
;
; Witness: L1 8 (c1-c4).
ListCatalogue:
  PUSH IX
  POP HL
  XOR A
  LD (Frames),A
  LD D,$00
CountNext:
  LD A,(HL)
  CALL SkipDeleted
  AND A
  JR Z,CountDone
  CALL IsBootFile
  LD A,(HL)
  AND E
  CP $42
  JR NZ,CountCode
  INC D
CountCode:
  CP $43
  PUSH AF
  LD BC,$0005
  ADD HL,BC
  POP AF
  JR NZ,CountSkip
  LD A,(HL)
  CP $C0                  ; exactly 192 sectors ($C0): a 48K Magic snapshot.
                          ; Vadim's comment reads 'length >= C000'; the test is
                          ; CP $C0 with JR NZ, equality only
  JR NZ,CountSkip
  INC D
CountSkip:
  INC HL
  INC HL
  INC HL
  LD A,H
  CP $A5
  JR NZ,CountNext
CountDone:
  LD A,D
  LD (FileCount),A
  LD HL,$0000
  LD (Columns),HL
  LD (ColumnsSpare),HL
  LD (ColumnTwoCount),HL
  AND A
  JR NZ,ListOneColumn
  LD HL,NoFilesText
  CALL PrintString
  LD HL,$090B
  LD (CursorRow),HL
  LD A,$0E
  LD (CursorLength),A
  RET
ListOneColumn:
  CP $0D                  ; 1-12 files: one column
  JR NC,ListTwoOrMore
  LD (ColumnOneCount),A
  LD HL,$0E06
  LD (CursorRow),HL
  LD A,$01
  LD (Columns),A
  LD (CursorIndex),A
  LD A,$08
  LD (CursorLength),A
  PUSH IX
  POP HL
  LD BC,$0A06
  LD E,$41
  CALL PrintColumn
  RET
ListTwoOrMore:
  CP $19
  JR NC,ListPaged

; Print A files (13-24) in two columns: half (rounded up) in column 1 at column
; 2, the rest at column 18
;
; ColumnOneCount $B3BB = A - A / 2, ColumnTwoCount $B3BC = A / 2; the cursor on
; the first file (row 6, column 6).
;
; Witness: L1 3 (c2, c3).
ListTwoColumns:
  AND A
  RRA
  LD (ColumnTwoCount),A
  ADC A,$00
  LD (ColumnOneCount),A
  LD HL,$0606
  LD (CursorRow),HL
  LD A,$02
  LD (Columns),A
  DEC A
  LD (CursorIndex),A
  LD A,$08
  LD (CursorLength),A
  PUSH IX
  POP HL
  LD BC,$0206
  LD E,$41
  LD A,(ColumnOneCount)
  LD D,A
  CALL PrintColumn
  LD BC,$1206
  LD A,(ColumnTwoCount)
  LD D,A
  CALL PrintColumn
  RET
; This entry point is used by the routine at ListCatalogue.
ListPaged:
  LD A,$18                ; 25 or more: 24 now, the rest on the next page
  CALL ListTwoColumns
  LD (NextPagePointer),HL
  LD A,$01
  LD (MorePages),A
  RET

; Print D catalogue lines from HL, the first at row C, column B, the letters
; from E
;
; Each listed entry: EntryLine $B3CE = AT row,col, BRIGHT 1, INK 5, letter,
; ">", two spaces, INK 4 (BASIC) or INK 6 (192-sector CODE), the 8 name
; characters (a byte below 32 or from 128 up shown as "."), $FF; PrintString
; $6720. Returns HL after the last entry printed.
;
; Witness: L1 8 (c2, c3).
PrintColumn:
  LD (EntryLine+1),BC
PrintColumnNext:
  PUSH DE
PrintColumnEntry:
  LD A,(HL)
  CALL SkipDeleted
  LD E,$FF
  CALL IsBootFile
  LD D,$06
  LD A,(HL)
  AND E
  CP $42
  JR Z,PrintColumnBasic
  CP $43
  PUSH AF
  LD BC,$0005
  ADD HL,BC
  POP AF
  JR NZ,PrintColumnSkip
  LD A,(HL)
  CP $C0                  ; exactly 192 sectors ($C0): a 48K Magic snapshot.
                          ; Vadim's comment reads 'length >= C000'; the test is
                          ; CP $C0 with JR Z, equality only
  JR Z,PrintColumnName
PrintColumnSkip:
  INC HL
  INC HL
  INC HL
  JR PrintColumnEntry
PrintColumnBasic:
  LD BC,$0005             ; a BASIC file: green
  ADD HL,BC
  LD D,$04
PrintColumnName:
  LD BC,$000D             ; the name: 8 characters, the unprintable ones as "."
  AND A
  SBC HL,BC
  LD A,D
  LD (EntryLine+12),A
  LD DE,EntryLine+13
  LD B,$08
PrintNameChar:
  LD A,(HL)
  CP $20
  JR NC,PrintNameHigh
  LD A,$2E
PrintNameHigh:
  CP $80
  JR C,PrintNameStore
  LD A,$2E
PrintNameStore:
  LD (DE),A
  INC DE
  INC HL
  DJNZ PrintNameChar
  LD A,$FF
  LD (DE),A
  POP DE
  PUSH HL
  LD L,E
  LD H,$3E
  LD (EntryLine+7),HL
  LD HL,$2020
  LD (EntryLine+9),HL
  LD A,$10
  LD (EntryLine+11),A
  LD A,$16
  LD (EntryLine),A
  LD HL,$0113
  LD (EntryLine+3),HL
  LD HL,$0510
  LD (EntryLine+5),HL
  PUSH DE
  LD HL,EntryLine
  CALL PrintString
  POP DE
  POP HL
  LD BC,$0008
  ADD HL,BC
  LD A,(EntryLine+1)
  INC A
  LD (EntryLine+1),A
  INC E
  DEC D
  JP NZ,PrintColumnNext
  RET

  ORG $6848

; HL = the attribute address of the row and column at the operand of the LD DE
; at $6848 (CursorRow normally)
;
; Also CursorAttrOffset $B3C9 = HL - $5800. RotateCursorName points the operand
; at RotateRow for one call.
;
; Witness: L1 3784 (c1-c4).
CursorAttrAddr:
  LD DE,(CursorRow)
  LD HL,$0000
  LD BC,$0020
AttrRowLoop:
  LD A,E
  AND A
  JR Z,AttrAddColumn
  ADD HL,BC
  DEC E
  JR AttrRowLoop
AttrAddColumn:
  LD C,D
  ADD HL,BC
  LD (CursorAttrOffset),HL
  LD BC,Attributes
  ADD HL,BC
  RET

  ORG $6930

; Clear the pixels of rows 6-17 and set their attributes to white on black
;
; Witness: L1 8 (c1-c4).
ClearFilesArea:
  LD HL,Screen+192
  LD C,$60
ClearRow:
  LD B,$20
ClearCell:
  LD (HL),$00
  INC L
  DJNZ ClearCell
  DEC C
  JR Z,ClearAttrs
  LD A,L
  SUB $20
  LD L,A
  INC H
  LD A,H
  AND $07
  JR NZ,ClearRow
  LD A,H
  SUB $08
  LD H,A
  LD A,L
  ADD A,$20
  LD L,A
  JR NZ,ClearRow
  LD A,H
  ADD A,$08
  LD H,A
  JR ClearRow
ClearAttrs:
  LD HL,Attributes+192
  LD DE,Attributes+193
  LD BC,$017F
  LD (HL),$07
  LDIR
  RET

; 1, 2, 6, 7: move the cursor to the other column (two columns only)
;
; From column 1 to column 2 the cursor keeps its row, but from column 1's last
; file, when column 2 is one shorter (13-23 files odd), it goes to column 1's
; first (CursorIndex 1, row 6, the column unchanged); from column 2 to column 1
; it keeps the row.
;
; Witness: L1 2 (c2).
ColumnKey:
  PUSH AF
  LD A,(ColumnTwoCount)
  AND A
  JR NZ,SwapColumn

; Pop the caller's AF and return: the key had nothing to do
;
; Witness: L1 1 (c4).
KeyDone:
  POP AF
  RET
; This entry point is used by the routine at ColumnKey.
SwapColumn:
  CALL CursorAttrAddr
  LD A,(CursorLength)
  LD B,A
  LD A,(CursorSavedAttr)
SwapRestoreAttr:
  LD (HL),A
  INC HL
  DJNZ SwapRestoreAttr
  LD A,(ColumnOneCount)
  LD B,A
  LD A,(CursorIndex)
  LD C,A
  DEC A
  SUB B
  JR NC,ToColumnOne
  CP $FF
  JR NZ,ToColumnTwo
  LD HL,(ColumnOneCount)
  LD A,H
  CP L
  JR Z,ToColumnTwo
  LD A,$01
  LD (CursorIndex),A
  LD A,$06
  LD (CursorRow),A
  JR CursorMoved
ToColumnTwo:
  LD A,C
  ADD A,B
  LD (CursorIndex),A
  LD A,$16
  LD (CursorColumn),A
  JR CursorMoved
ToColumnOne:
  LD A,C
  SUB B
  LD (CursorIndex),A
  LD A,$06
  LD (CursorColumn),A

; CursorSavedAttr = the attribute at the cursor's new place; pop AF, return
;
; Witness: L1 8 (c2).
CursorMoved:
  CALL CursorAttrAddr
  LD A,(HL)
  LD (CursorSavedAttr),A
  POP AF
  RET

; 3, 8: the cursor down one file (B = 0), wrapping from the column's last file
; to its first
;
; Witness: L1 4 (c2).
DownKey:
  PUSH AF
  LD B,$00

; Move the cursor down (B = 0) or up (B = 1), wrapping within its column;
; nothing with a single file
;
; Puts back the old cells' attribute first. The positions run down column 1
; (CursorIndex 1 to ColumnOneCount) and on down column 2.
;
; Witness: L1 6 (c2).
MoveCursor:
  LD A,(ColumnTwoCount)
  AND A
  JR NZ,MoveCursorGo
  LD A,(ColumnOneCount)
  AND A
  JR Z,KeyDone
  DEC A
  JR Z,KeyDone
MoveCursorGo:
  PUSH BC
  CALL CursorAttrAddr
  LD A,(CursorLength)
  LD B,A
  LD A,(CursorSavedAttr)
MoveRestoreAttr:
  LD (HL),A
  INC HL
  DJNZ MoveRestoreAttr
  POP BC
  LD A,(CursorIndex)
  LD C,A
  LD DE,(ColumnOneCount)
  LD A,(CursorRow)
  LD L,A
  LD A,(CursorColumn)
  CP $16
  JR Z,MoveColumnTwo
  LD A,B
  AND A
  JR NZ,MoveUpColumnOne
  LD A,C
  CP E
  LD A,$06
  LD H,$01
  JR Z,MoveSetRow
MoveDownOne:
  LD H,C
  INC H
  LD A,L
  INC A
  JR MoveSetRow
MoveUpColumnOne:
  LD A,C
  CP $01
  JR NZ,MoveUpOne
  LD H,E
  LD A,E
  JR MoveToLast
MoveUpOne:
  LD H,C
  DEC H
  LD A,L
  DEC A
  JR MoveSetRow
MoveColumnTwo:
  LD A,B
  AND A
  JR NZ,MoveUpColumnTwo
  LD A,E
  ADD A,D
  CP C
  JR NZ,MoveDownOne
  LD H,E
  INC H
  LD A,$06
  JR MoveSetRow
MoveUpColumnTwo:
  LD A,E
  INC A
  CP C
  JR NZ,MoveUpOne
  LD A,E
  ADD A,D
  LD H,A
  LD A,D
MoveToLast:
  ADD A,$05
MoveSetRow:
  LD (CursorRow),A
  LD A,H
  LD (CursorIndex),A
  JP CursorMoved

; 4, 9: the cursor up one file
;
; Witness: L1 2 (c2).
UpKey:
  LD B,$01
  PUSH AF
  JR MoveCursor
