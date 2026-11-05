; --------------------------------------------------------------------------------------------------------------------
; menuviewer.asm: The text viewer: 64 columns, 16 lines a page, Q / A / SPACE
;
; TextViewer shows TextBuffer from the line at ViewerTopLd's operand in rows 8-23 with a 4 x 8 font (ViewerFont, the
; same 2048 bytes as stage 2's Font64, src/res/stage2/font64.png), fading the rows out and in (attributes 7..1, 1..7,
; a frame each). The texts are CP866 with CR LF; TextStart in front of them (0, CR, LF) stops a page back at the
; start. Keys (ReadMenuKeys): Q 16 lines back, A 16 lines on (nothing at either end), SPACE back to the menu.
; Witnessed in the live exploration of r99 (work/stage2/menu99/live-r99): the top went $E6F4 -> $E980 -> $ECE6 ->
; $E980 -> $E6F4 with A A Q Q; in m99 DESCRIPTION was opened about frame 5000.
;
; ViewerPutChar takes controls like the ROM's print: $16 AT column, row (two parameters), $17 the font address (two
; parameters, low first), $0D column 0, $0A the next row, $09 the next multiple of 8, $08 one column back; other codes
; below 32 are ignored. A character in the font's layout: byte font + 256 * r + c is pixel row r of character c, drawn
; in both nibbles; the column's parity picks the half (mask $F0 or $0F).
; --------------------------------------------------------------------------------------------------------------------

; Print the header (row 8, the font), fade rows 8-23 out, clear them, print a
; page, fade in, keys
;
; The top line is the operand of LD HL at ViewerTopLd (TextShow sets it to
; TextBuffer). Prints until row 24 or a 0 byte. Returns on SPACE.
TextViewer:
  LD DE,ViewerHeader
  LD BC,$0006
  CALL PrintCount
  LD B,$08                ; fade out: attributes 7..1 over rows 8-23, one a
                          ; frame
FadeOutStep:
  PUSH BC
  LD HL,$5900
  DEC B
  LD (HL),B
  LD DE,$5901
  LD BC,$0200
  LDIR
  EI
  HALT
  POP BC
  DJNZ FadeOutStep
  LD HL,$4800             ; the pixels of rows 8-23 to 0
  LD DE,$4801
  LD BC,$0FFF
  LD (HL),$00
  LDIR
ViewerTopLd:
  LD HL,TextBuffer             ; the first line shown: this operand is the viewer's
                          ; position
PrintPage:
  LD A,(ViewerRow)        ; up to row 24 or the text's 0
  CP $18
  JR NC,FadeIn
  LD A,(HL)
  OR A
  JR Z,FadeIn
  PUSH HL
  CALL ViewerPutChar
  POP HL
  INC HL
  JR PrintPage
FadeIn:
  LD B,$07                ; attributes 1..7
FadeInStep:
  PUSH BC
  LD HL,$5900
  LD A,$08
  SUB B
  LD (HL),A
  LD DE,$5901
  LD BC,$0200
  LDIR
  HALT
  POP BC
  DJNZ FadeInStep
ViewerKeys:
  CALL TitleColourCycle              ; the title colours, a frame, the keys
  HALT
  CALL ReadMenuKeys
  BIT 2,A
  JR NZ,PageForward
  LD B,$10                ; Q: 16 lines back (a 0 before: the start, nothing)
  LD HL,(ViewerTopLd+$0001)
PageBackLine:
  DEC HL
  DEC HL
PageBackScan:
  LD A,(HL)
  DEC HL
  OR A
  JR Z,ViewerKeys
  CP $0A
  JR NZ,PageBackScan
  INC HL
  INC HL
  DJNZ PageBackLine
  LD (ViewerTopLd+$0001),HL
  JR TextViewer
PageForward:
  BIT 3,A                 ; A: 16 lines on (a 0 first: the end, nothing)
  JR NZ,ViewerSpace
  LD B,$10
  LD HL,(ViewerTopLd+$0001)
PageForwardScan:
  LD A,(HL)
  INC HL
  OR A
  JR Z,ViewerKeys
  CP $0D
  JR NZ,PageForwardScan
  INC HL
  DJNZ PageForwardScan
  LD (ViewerTopLd+$0001),HL
  JP TextViewer
ViewerSpace:
  AND $10                 ; SPACE: back to the menu
  JR NZ,ViewerKeys
  RET

; AT 0,8 then the font: $16 0 8, $17 ViewerFont
ViewerHeader:
  DEFB $16,$00,$08,$17,$F1,$DE

; Print BC bytes from DE through ViewerPutChar
;
; Used by the routine at TextViewer.
PrintCount:
  LD A,B
  OR C
  DEC BC
  RET Z
  LD A,(DE)
  INC DE
  CALL ViewerPutChar
  JR PrintCount

; One byte to the 64-column screen: a control, a parameter or a character
;
; A = the byte. Keeps BC, DE, HL (the character's work in the alternate set).
; Columns 0-63, rows 0-23; a character in row 24 or more is not drawn; column
; 64 is the next row.
ViewerPutChar:
  LD (ViewerChar),A
  LD A,(ViewerParams)
  OR A
  JR NZ,ViewerParam
  LD A,(ViewerChar)
  CP $20
  JR C,ViewerControl
  EXX                     ; HL = the font + the code
  LD HL,(ViewerFontPtr)
  LD E,A
  LD D,$00
  ADD HL,DE
  LD A,(ViewerRow)        ; row 24 on: not drawn
  CP $18
  JR NC,PutCharDone
  PUSH HL
  CALL RomClAddr              ; HL = the row's pixel address + column / 2
  LD A,(ViewerCol)
  LD C,A
  RRA
  OR L
  LD L,A
  BIT 0,C                 ; the half: column even $F0, odd $0F
  LD A,$0F
  JR NZ,SetViewerMask
  LD A,$F0
SetViewerMask:
  LD (ViewerMask),A
  POP DE
  LD B,$08
PutCharRow:
  LD A,(DE)               ; eight pixel rows, the font's planes 256 bytes apart
  LD C,A
  LD A,(ViewerMask)
  AND C
  LD C,A
  LD A,(ViewerMask)
  CPL
  AND (HL)
  OR C
  LD (HL),A
  INC H
  INC D
  DJNZ PutCharRow
  LD A,(ViewerCol)        ; the next column; 64 = the next row
  INC A
  BIT 6,A
  PUSH AF
  CALL NZ,ViewerNewLine
  POP AF
  AND $3F
  LD (ViewerCol),A
  LD A,(ViewerMask)
  CPL
  LD (ViewerMask),A
PutCharDone:
  EXX
  RET
ViewerParam:
  LD A,(ViewerCode)       ; a parameter of $16 or $17: stored backwards from
                          ; ViewerParams (AT: column, row) or ViewerFontPtr + 2
                          ; (font)
  CP $16
  JR NZ,ViewerParamFont
  LD HL,ViewerParams
ViewerParamStore:
  LD A,(ViewerParams)
  LD B,A
ParamBack:
  DEC HL
  DJNZ ParamBack
  LD A,(ViewerChar)
  LD (HL),A
  JR ViewerParamDone
ViewerParamFont:
  CP $17
  JR NZ,ViewerParamDone
  LD HL,ViewerFontPtr+$0002
  JR ViewerParamStore
ViewerParamDone:
  LD A,(ViewerParams)
  DEC A
  LD (ViewerParams),A
  RET
ViewerControl:
  CP $0A                  ; a control: $0A, $0D, $16, $09, $08, $17
  JR NZ,ViewerControlCr

; The next row (the column is not changed)
;
; Used by the routine at ViewerPutChar.
ViewerNewLine:
  LD A,(ViewerRow)
  INC A
  LD (ViewerRow),A
  RET
; This entry point is used by the routine at ViewerPutChar.
ViewerControlCr:
  CP $0D
  JR NZ,ViewerControlAt
  XOR A
ViewerSetCol:
  LD (ViewerCol),A
  RET
ViewerControlAt:
  CP $16
  JR NZ,ViewerControlTab
ViewerTwoParams:
  LD (ViewerCode),A
  LD A,$02
  LD (ViewerParams),A
  RET
ViewerControlTab:
  CP $09
  JR NZ,ViewerControlBack
  LD A,(ViewerCol)
  ADD A,$08
  AND $F8
  JR ViewerSetCol
ViewerControlBack:
  CP $08
  JR NZ,ViewerControlFont
  LD A,(ViewerCol)
  DEC A                   ; RET C never returns (DEC keeps the carry of CP $08,
                          ; clear): at column 0 the column becomes $FF
  RET C
  JR ViewerSetCol
ViewerControlFont:
  CP $17
  JR NZ,ViewerIgnore
  JR ViewerTwoParams
ViewerIgnore:
  RET

; the column 0-63
ViewerCol:
  DEFB $00

; the row 0-23 (24: the page is full)
ViewerRow:
  DEFB $00

; parameters still to come
ViewerParams:
  DEFB $00

; the control they belong to
ViewerCode:
  DEFB $00

; the byte being printed
ViewerChar:
  DEFB $00

; the half of the cell: $F0 or $0F
ViewerMask:
  DEFB $F0

; the font ($3C00 in the image; the header sets ViewerFont)
ViewerFontPtr:
  DEFW $3C00
