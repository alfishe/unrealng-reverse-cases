; --------------------------------------------------------------------------------------------------------------------
; boot.asm: boot.B: the TRD's boot, a scrolling list of the disk's BASIC files
;
; A generic TR-DOS boot, no author mark and no text of its own: line 0 is a REM holding the code, line 1 calls it and
; then runs the file picked through TR-DOS. The code reads the catalogue, draws a frame titled with the disk's name,
; and lists the BASIC files in a window 8 characters wide, in a bold copy of the ROM font. The list lives in a buffer
; as pixels and is copied to the screen each frame by an unrolled LDI blitter (built at $8CA0, with its own line table
; at $D6D8), so a cursor move scrolls the list smoothly over four frames. Q, A, 9 and 8 (and the keys sharing their
; bits) move, ENTER, SPACE or 0 runs the file under the bar; a change of the disk's state reads the catalogue again.
; --------------------------------------------------------------------------------------------------------------------

; line 0: the number 0, the length 925, REM
BootLine0:
  DEFB $00,$00,$9D,$03,$EA

; the tables, the font and the blitter; the catalogue, the frame, the list;
; then the menu loop
;
; Entered from line 1's RANDOMIZE USR VAL "23872". HL' (BASIC's) is kept on the
; stack until a file is picked (RunFile). Returns to BASIC through RunFile,
; with the picked name written into line 1's RUN.
BootStart:
  EXX
  PUSH HL
  CALL MakeLineTable
  CALL MakeBoldFont
  CALL MakeBlitter
BootMenu:
  CALL ClearScreen        ; (again after a disk change) the screen cleared, the
                          ; catalogue read, the frame and its title drawn
  CALL ReadCatalogue
  CALL ClearScreen
  CALL DrawFrame
  LD HL,AttrsList             ; the attributes: the window black, the frame's
                          ; corner, the title row, the list's rows, the
                          ; cursor's bar
  LD A,$00
  LD BC,$110A
  CALL FillAttrs
  LD HL,AttrsTitle
  LD A,$60
  LD BC,$110A
  CALL FillAttrs
  LD HL,AttrsList
  LD A,$46
  LD BC,$0108
  CALL FillAttrs
  LD HL,AttrsRows
  LD A,$07
  LD BC,$0D08
  CALL FillAttrs
  LD HL,AttrsCursor
  LD A,$38
  LD BC,$0108
  CALL FillAttrs
  XOR A                   ; the cursor on the first file, the buffer's window
                          ; from its top, no scroll in progress, the disk's
                          ; state now
  LD (CursorIndex+$0001),A
  LD HL,ListBuffer
  LD (BlitSource+$0001),HL
  LD (ScrollSteps+$0001),A
  LD HL,$0000
  LD (ScrollStep+$0001),HL
  CALL DiskState
  LD (DiskStateWas+$0001),A
MenuFrame:
  HALT                    ; a frame: the list buffer's window to the screen
                          ; through the blitter (SP on LineTable)
BlitSource:
  LD HL,$0000             ; HL = the buffer's window (the operand: moved by
                          ; Scroll)
  LD (BlitDone+$0001),SP
  LD SP,LineTable
  JP Blitter
; This entry point is used by the routine at BlitLine.
BlitDone:
  LD SP,$0000             ; the blitter's end: SP back (the operand written
                          ; above), the disk's state checked
  CALL DiskState
DiskStateWas:
  CP $00                  ; CP the state the menu began with (the operand):
                          ; another means a disk change
  JR NZ,BootMenu
ScrollSteps:
  LD A,$00                ; LD A,frames of scroll left (the operand)
  OR A
  JR Z,MenuKeys
  DEC A
  LD (ScrollSteps+$0001),A
Scroll:
  LD HL,(BlitSource+$0001) ; the window one step on: BlitSource + ScrollStep
ScrollStep:
  LD DE,$0000             ; LD DE,the step (the operand): +16 down, -16 up, 4
                          ; steps a file (64 bytes)
  ADD HL,DE
  LD (BlitSource+$0001),HL
  JR MenuFrame
MenuKeys:
  LD A,$2F                ; the keys: rows $EF, $BF, $7F read together; then A
                          ; ($FD row) and Q ($FB row)
  IN A,($FE)
  BIT 0,A                 ; bit 0 (0, ENTER, SPACE): run the file
  JR Z,RunFile
  BIT 2,A                 ; bit 2 (8, K, M): down
  JR Z,CursorDown
  BIT 1,A                 ; bit 1 (9, L, SYMBOL SHIFT): up
  JR Z,CursorUp
  LD A,$FD                ; A: down
  IN A,($FE)
  BIT 0,A
  JR Z,CursorDown
  LD A,$FB                ; Q: up; no key: the next frame
  IN A,($FE)
  BIT 0,A
  JR NZ,MenuFrame
CursorUp:
  LD A,(CursorIndex+$0001) ; up: not past the first file
  OR A
  JR Z,MenuFrame
  LD HL,$FFF0
  DEC A
MoveCursor:
  LD (CursorIndex+$0001),A ; the cursor kept, a scroll of 4 frames (this one
                           ; and 3 more) of HL bytes each
  LD A,$03
  LD (ScrollSteps+$0001),A
  LD (ScrollStep+$0001),HL
  JR Scroll
CursorDown:
  LD A,(CursorIndex+$0001) ; down: not past the last file (FileCount)
  INC A
  LD B,A
  LD A,(FileCount)
  OR A
  JR Z,MenuFrame
  CP B
  JR Z,MenuFrame
  LD HL,$0010
  LD A,B
  JR MoveCursor
RunFile:
  LD A,(FileCount)        ; the file under the bar: its name into line 1's RUN,
                          ; the screen cleared, back to BASIC
  OR A
  JR Z,MenuFrame
  POP HL                  ; HL' back (BASIC's)
  EXX
CursorIndex:
  LD HL,$0000             ; LD HL,the cursor's file (the operand), * 8 +
                          ; NameTable
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,NameTable
  ADD HL,DE
  LD DE,RunName
  LD BC,$0008
  LDIR

; the border blue, the pixels 0, every attribute $08 (blue paper, black ink)
;
; Used by the routine at BootStart.
ClearScreen:
  LD A,$01
  OUT ($FE),A
  LD HL,Screen
  LD DE,Screen+1
  LD BC,$1800
  LD (HL),L
  LDIR
  LD (HL),$08
  LD BC,$02FF
  LDIR
  RET

; B rows of C attributes A from HL, 32 bytes a row
;
; Input: HL = the first attribute, A = the value, B = the rows, C = the width
; (2 or more: LDIR copies C - 1).
FillAttrs:
  PUSH BC
  PUSH HL
  LD D,H
  LD E,L
  INC DE
  LD B,$00
  LD (HL),A
  DEC C
  LDIR
  POP HL
  LD DE,$0020
  ADD HL,DE
  POP BC
  DJNZ FillAttrs
  RET

; the ROM's 96 characters to BoldFont + $100: the top four lines as they are,
; the bottom four bold
;
; Each of the lower four lines is ORed with itself shifted left (RL A, OR
; (HL)): the strokes a pixel wider.
MakeBoldFont:
  LD HL,ROM_FONT
  LD DE,BoldFont+256
  LD C,$60
MakeBoldChar:
  PUSH BC
  LDI
  LDI
  LDI
  LDI
  POP BC
  LD B,$04
MakeBoldLine:
  LD A,(HL)
  OR A
  RL A
  OR (HL)
  LD (DE),A
  INC HL
  INC DE
  DJNZ MakeBoldLine
  DEC C
  JR NZ,MakeBoldChar
  RET

; the BASIC files listed (0-128)
FileCount:
  DEFB $00

; LineTable: the screen address of column 12 on each pixel line 40-143
; ($28-$8F)
;
; Used by the routine at BootStart.
MakeLineTable:
  LD A,$28
  LD HL,LineTable
MakeLineEntry:
  LD E,A
  PUSH AF
  AND $07
  LD D,A
  LD A,E
  RRCA
  RRCA
  RRCA
  AND $18
  OR D
  OR $40
  LD D,A
  LD A,E
  RLCA
  RLCA
  AND $E0
  OR $0C
  LD (HL),A
  INC HL
  LD (HL),D
  INC HL
  POP AF
  INC A
  CP $90
  JR NZ,MakeLineEntry
  RET

; track 0's sectors 0-8 to Catalogue through TR-DOS, errors caught
;
; ERR_SP is pointed at the stack so a TR-DOS error returns here; TRDOS_ERR = 0
; and ERR_NR (IY+0) = $FF before; TRDOS_HOOK = RET. Then TRDOS_ENTRY with C =
; 5, B = 9, DE = 0, HL = Catalogue.
ReadCatalogueSectors:
  LD (ERR_SP),SP
  XOR A
  LD (TRDOS_ERR),A
  LD (IY+$00),$FF
  LD HL,TRDOS_HOOK
  LD (HL),$C9
  LD HL,Catalogue
  LD DE,$0000
  LD BC,$0905
  CALL TRDOS_ENTRY
  RET

; ListBuffer cleared; the catalogue read until it reads without error; the
; BASIC files to the list
;
; Saves ERR_SP in SavedErrSp and restores it. Then for each of up to 128
; catalogue entries until a 0 (the end): a deleted entry (1) or a type other
; than 'B' is skipped; a BASIC file's name goes to NameTable (DE') and is drawn
; into the buffer at DE, 8 characters of BoldFont, one byte a line, 8 bytes a
; buffer line; FileCount + 1, DE on to the next file's 64 bytes.
ReadCatalogue:
  LD HL,ListBuffer
  LD DE,ListBuffer+1
  LD BC,$2300
  LD (HL),$00
  LDIR
  LD HL,(ERR_SP)
  LD (SavedErrSp+$0001),HL
ReadRetry:
  CALL ReadCatalogueSectors
  LD A,(TRDOS_ERR)
  OR A
  JR NZ,ReadRetry
  LD A,(IY+$00)
  INC A
  JR NZ,ReadRetry
SavedErrSp:
  LD HL,$0000             ; LD HL,ERR_SP's value (the operand written above)
  LD (ERR_SP),HL
  EXX
  LD DE,NameTable
  EXX
  LD IX,Catalogue
  LD DE,ListStart
  LD C,$00
  XOR A
  LD (FileCount),A
ListEntry:
  LD A,(IX+$00)
  OR A
  RET Z
  DEC A
  JR Z,ListSkip
  LD A,(IX+$08)
  CP $42
  JR NZ,ListSkip
  PUSH IX
  EXX
  POP HL
  LD BC,$0008
  LDIR
  EXX
  LD B,$08
ListChar:
  PUSH BC
  LD A,(IX+$00)
  INC IX
  PUSH DE
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,BoldFont
  ADD HL,BC
  LD B,$08
ListCharLine:
  LD A,(HL)
  LD (DE),A
  INC HL
  INC DE
  INC DE
  INC DE
  INC DE
  INC DE
  INC DE
  INC DE
  INC DE
  DJNZ ListCharLine
  POP DE
  INC DE
  POP BC
  DJNZ ListChar
  LD HL,$0038
  ADD HL,DE
  EX DE,HL
  LD HL,FileCount
  INC (HL)
  EXX
  LD BC,$0008
ListNext:
  ADD IX,BC
  EXX
  INC C
  BIT 7,C
  JR Z,ListEntry
  RET
ListSkip:
  EXX                     ; not listed: the next entry (16 bytes on)
  LD BC,$0010
  JR ListNext

; Blitter: 104 copies of BlitLine, then BlitLine's last 3 bytes (JP BlitDone)
;
; Used by the routine at BootStart.
MakeBlitter:
  LD A,$00
  LD DE,Blitter
MakeBlitterLine:
  LD HL,BlitLine
  LD BC,$0011
  LDIR
  INC A
  CP $68
  JR NZ,MakeBlitterLine
  LD BC,$0003
  LDIR
  RET

; the blitter's line (copied, not run here): POP DE (the screen line), 8 LDI
; from the buffer
;
; Run as the copies at Blitter, with SP on LineTable and HL on the buffer's
; window: each copy pops one screen address and copies the next 8 buffer bytes
; there. The JP BlitDone after the eighth LDI is copied once, after the 104th.
BlitLine:
  POP DE
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  JP BlitDone             ; the end of the blitter (copied once)

; A = the drive's state bit (TRDOS_5CCD AND $40), from a row of TR-DOS ROM
; routines run through TrdosCall
;
; TRDOS_HOOK is made JP DiskRecover, so an error inside a routine resumes at
; DiskRecover with the stack it had (the operand at DiskRecover, written before
; the third call). Then RET at TRDOS_HOOK again. The menu compares the result
; each frame (DiskStateWas in MenuFrame) and reads the catalogue again on a
; change: a new disk in the drive.
DiskState:
  LD A,$C3
  LD (TRDOS_HOOK),A
  LD HL,DiskRecover
  LD (TRDOS_HOOK+1),HL
  LD IX,TR_2FC1
  CALL TrdosCall
  LD A,$08
  LD BC,$001F
  LD IX,TR_2A53
  CALL TrdosCall
  LD (DiskRecover+$0001),SP
  LD DE,$0000
  LD IX,TR_2740
  CALL TrdosCall
DiskRecover:
  LD SP,$0000             ; LD SP,the stack before TR_2740 (the operand): the
                          ; error hook's target
  LD IX,TR_1FF3
  CALL TrdosCall
  LD IX,TR_1FEB
  CALL TrdosCall
  LD IX,TR_2FC1
  CALL TrdosCall
  LD A,$C9
  LD (TRDOS_HOOK),A
  LD A,(TRDOS_5CCD)
  AND $40
  RET

; the TR-DOS ROM routine at IX: PUSH IX, JP TRDOS_JUMP
;
; Used by the routine at DiskState.
TrdosCall:
  PUSH IX
  JP TRDOS_JUMP

; the frame (10 glyphs wide: top, 13 middle rows, bottom) at row 2 column 11,
; the disk's name in it
;
; DrawGlyphs with FrameGlyphs: FrameTop (its three rows: the top, the title
; row, the line under it), FrameMiddle 13 times, FrameBottom. Then the 8
; characters of DiskName in BoldFont at row 3 column 1 of the frame; the font
; pointer set back to FrameGlyphs.
DrawFrame:
  LD A,$02
  LD (Row),A
  XOR A
  LD (Column),A
  LD HL,FrameTop
  LD C,$1E
  CALL DrawGlyphs
  LD B,$0D
DrawFrameRow:
  LD HL,FrameMiddle
  LD C,$0A
  CALL DrawGlyphs
  DJNZ DrawFrameRow
  LD HL,FrameBottom
  LD C,$0A
  CALL DrawGlyphs
  LD A,$03
  LD (Row),A
  LD A,$01
  LD (Column),A
  LD HL,BoldFont
  LD (DrawGlyphFont+$0001),HL
  LD HL,DiskName
  LD C,$08
  CALL DrawGlyphs
  LD HL,FrameGlyphs
  LD (DrawGlyphFont+$0001),HL
  RET

; C glyphs from HL (one byte each, the glyph's number) at Column, Row, 10 a row
;
; Each glyph is 8 bytes of the font at the operand of DrawGlyphFont
; (self-modifying: FrameGlyphs, or BoldFont for the title). The screen address
; is built from Row (the character row) and Column + 11.
DrawGlyphs:
  PUSH BC
DrawGlyph:
  LD A,(HL)
  INC HL
  PUSH HL
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
DrawGlyphFont:
  LD DE,FrameGlyphs       ; LD DE,the font (the operand)
  ADD HL,DE
  LD A,(Row)
  LD E,A
  AND $18
  OR $40
  LD D,A
  LD A,E
  RRCA
  RRCA
  RRCA
  AND $E0
  OR $0B
  LD E,A
  LD A,(Column)
  ADD A,E
  LD E,A
  LD B,$08
DrawGlyphLine:
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  DJNZ DrawGlyphLine
  LD A,(Column)
  INC A
  CP $0A
  JR NZ,DrawGlyphNext
  LD HL,Row
  INC (HL)
  XOR A
DrawGlyphNext:
  LD (Column),A
  POP HL
  DEC C
  JR NZ,DrawGlyph
  POP BC
  RET

; the next glyph's column in the frame (0-9)
Column:
  DEFB $00

; its character row
Row:
  DEFB $00

; the frame's top row, its title row and the row under the title: glyph
; numbers, 30 bytes
FrameTop:
  DEFB $04,$01,$01,$01,$01,$01,$01,$01,$01,$05
FrameMiddle:
  DEFB $00,$08,$08,$08,$08,$08,$08,$08,$08,$00 ; the title row, reused as the
                                               ; middle rows: a side, 8 blanks,
                                               ; a side
  DEFB $06,$01,$01,$01,$01,$01,$01,$01,$01,$07 ; the row under the title

; the frame's bottom row
FrameBottom:
  DEFB $02,$01,$01,$01,$01,$01,$01,$01,$01,$03

; the frame's 9 glyphs, 8 bytes each, in a stippled pattern: 0 the sides, 1 the
; top and bottom edges, 2-7 the corners and the title row's joins, 8 blank
FrameGlyphs:
  DEFB $EB,$57,$6E,$5E,$7A,$76,$EA,$D7
  DEFB $83,$FF,$AE,$5D,$BA,$75,$FF,$C1
  DEFB $EB,$57,$6E,$5D,$7A,$75,$FF,$C1
  DEFB $EB,$D7,$AE,$5E,$BA,$76,$FF,$C3
  DEFB $C3,$FF,$6E,$5D,$7A,$75,$EB,$D6
  DEFB $83,$FF,$AE,$5E,$BA,$76,$EA,$D7
  DEFB $EB,$57,$6E,$5D,$7A,$75,$EB,$D6
  DEFB $6B,$D7,$AE,$5E,$BA,$76,$EA,$D7
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; line 0's ENTER, then line 1: number 1, length 55
Line0End:
  DEFB $0D
  DEFB $00,$01,$37,$00    ; line 1: the number (big-endian), the length
  DEFB $FD,$B0,$22,$32,$39,$39,$39,$39 ; CLEAR VAL "29999": RANDOMIZE USR VAL
  DEFB $22,$3A,$F9,$C0,$B0,$22,$32,$33 ; "23872": the boot's code at $5D40
  DEFB $38,$37,$32,$22,$3A
  DEFB $FD,$B0,$22,$36,$34,$65,$33,$22 ; : CLEAR VAL "64e3": RANDOMIZE USR VAL
  DEFB $3A,$F9,$C0,$B0,$22,$31,$35,$36 ; "15619": REM : RUN: TR-DOS runs the
  DEFB $31,$39,$22,$3A,$EA,$3A,$F7,$22 ; statement after the REM
RunName:
  DEFB $20,$20,$20,$20,$20,$20,$20,$20 ; the 8 characters of the name RunFile
  DEFB $22                             ; writes, in quotes
  DEFB $0D                ; ENTER
