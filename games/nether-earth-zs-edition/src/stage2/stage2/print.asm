; --------------------------------------------------------------------------------------------------------------------
; print.asm: the 64-column print routine and its variables
;
; A print routine of 4-pixel-wide characters, 64 columns by 24 rows, with its own control codes; the glyphs come from
; a font of 256 characters stored row by row (PrintFont + character + 256 x row), each glyph in both nibbles of its
; bytes, so that a mask ($F0 for even columns, $0F for odd) cuts the half for the column. It writes into the screen
; through the ROM's CL-ADDR; rows from 24 on are not drawn.
; --------------------------------------------------------------------------------------------------------------------

; Print BC bytes from DE
;
; Input: DE = the bytes, BC = their count. Each through PrintChar. Output: DE
; past them, BC = $FFFF.
PrintChars:
  LD A,B
  OR C
  DEC BC
  RET Z
  LD A,(DE)
  INC DE
  CALL PrintChar
  JR PrintChars

; Print the character or control code A at PrintCol, PrintRow
;
; Codes: $20-$FF a glyph from PrintFont (the bits under PrintMask of the 8
; glyph rows replace the screen's; then the next column, past 63 the next row's
; column 0); $0A the next row; $0D column 0; $09 the next column that is a
; multiple of 8; $08 one column back (meant to stop at 0, but DEC A sets no
; carry, so the RET C never returns and column 0 becomes 255; the text has no
; $08); $16 col row: AT (two bytes follow: the column, then the row); $17 lo
; hi: the font address (the two bytes into PrintFont); others ignored. A row of
; 24 or more is counted but not drawn. 568 calls (r99 frames 746-1287). A, F,
; the alternate set (glyphs) changed.
PrintChar:
  LD (PrintCurrent),A
  LD A,(PrintArgsLeft)
  OR A
  JR NZ,PrintArgument
  LD A,(PrintCurrent)
  CP $20
  JR C,PrintControl
  EXX                     ; a glyph: HL' = PrintFont + the character
  LD HL,(PrintFont)
  LD E,A
  LD D,$00
  ADD HL,DE
  LD A,(PrintRow)         ; rows 24 and on are not drawn
  CP $18
  JR NC,PrintCharDone
  PUSH HL
  CALL RomClAddr          ; HL = the row's screen address + column / 2
  LD A,(PrintCol)
  LD C,A
  RRA
  OR L
  LD L,A
  BIT 0,C                 ; even column: the left nibble ($F0), odd: the right
                          ; ($0F)
  LD A,$0F
  JR NZ,PrintMaskSet
  LD A,$F0
PrintMaskSet:
  LD (PrintMask),A
  POP DE
  LD B,$08
PrintGlyphRow:
  LD A,(DE)               ; 8 rows: the glyph's bits under the mask into the
                          ; screen byte
  LD C,A
  LD A,(PrintMask)
  AND C
  LD C,A
  LD A,(PrintMask)
  CPL
  AND (HL)
  OR C
  LD (HL),A
  INC H
  INC D
  DJNZ PrintGlyphRow
  LD A,(PrintCol)         ; the next column; at 64 the next row
  INC A
  BIT 6,A
  PUSH AF
  CALL NZ,PrintNewRow
  POP AF
  AND $3F
  LD (PrintCol),A
  LD A,(PrintMask)
  CPL
  LD (PrintMask),A
PrintCharDone:
  EXX
  RET
PrintArgument:
  LD A,(PrintCode)        ; a byte after a $16 or a $17: AT's column, row, or
                          ; the font address
  CP $16
  JR NZ,PrintArgumentFont
  LD HL,PrintArgsLeft     ; $16: the column into PrintCol, then the row into
                          ; PrintRow
; This entry point is used by the routine at PrintFontArgument.
PrintArgumentStore:
  LD A,(PrintArgsLeft)    ; HL = the slot: PrintArgsLeft bytes below HL
  LD B,A
PrintArgumentSlot:
  DEC HL
  DJNZ PrintArgumentSlot
  LD A,(PrintCurrent)
  LD (HL),A
  JR PrintArgumentDone
PrintArgumentFont:
  CP $17                  ; $17: the two bytes into PrintFont
  JR NZ,PrintArgumentDone

; $17's bytes: low into PrintFont, high into PrintFont+1 (not reached: the text
; has no $17)
;
; HL = PrintFont + 2, back into PrintArgument's store: the first byte (2 left)
; goes to PrintFont, the second to PrintFont+1. Known only from the code.
PrintFontArgument:
  LD HL,PrintFont+2
  JR PrintArgumentStore

; One argument byte less to come
;
; Used by the routine at PrintChar.
PrintArgumentDone:
  LD A,(PrintArgsLeft)
  DEC A
  LD (PrintArgsLeft),A
  RET

; A control code below $20: LF here, the others in PrintControlRest
;
; Used by the routine at PrintChar.
PrintControl:
  CP $0A
  JR NZ,PrintControlRest

; LF: the next print row (also after column 63)
;
; Used by the routine at PrintChar.
PrintNewRow:
  LD A,(PrintRow)
  INC A
  LD (PrintRow),A
  RET

; CR, AT, TAB, back, $17; any other code is ignored
;
; Part of PrintChar's control codes (PrintControl falls here past LF); each
; sets PrintCol, the argument count or returns.
PrintControlRest:
  CP $0D                  ; CR: column 0
  JR NZ,PrintAt
  XOR A
PrintSetCol:
  LD (PrintCol),A
  RET
PrintAt:
  CP $16                  ; $16 AT: two arguments to come
  JR NZ,PrintTab
PrintArgs:
  LD (PrintCode),A
  LD A,$02
  LD (PrintArgsLeft),A
  RET
PrintTab:
  CP $09                  ; $09: the next multiple of 8
  JR NZ,PrintBack
  LD A,(PrintCol)
  ADD A,$08
  AND $F8
  JR PrintSetCol
PrintBack:
  CP $08                  ; $08: one column back
  JR NZ,PrintFontCode
  LD A,(PrintCol)
  DEC A
  RET C                   ; the carry is CP $08's (clear): never returns here
  JR PrintSetCol
PrintFontCode:
  CP $17                  ; $17: two arguments (the font address)
  JR NZ,PrintIgnore
  JR PrintArgs
PrintIgnore:
  RET                     ; any other code below $20

; The print column, 0-63
PrintCol:
  DEFB $00
PrintRow:
  DEFB $00                ; the print row, 0-23 (more: not drawn)
PrintArgsLeft:
  DEFB $00                ; the argument bytes still to come after $16 or $17
PrintCode:
  DEFB $00                ; the control code waiting for its arguments ($16 or
                          ; $17)
PrintCurrent:
  DEFB $00                ; the byte being printed
PrintMask:
  DEFB $F0                ; $F0 (even column) or $0F (odd)

; The font: glyph row r of character c at PrintFont + c + 256 x r (Font64 once
; IntroMain set it; on the disk $3C00, the ROM's font, which is not in this
; layout)
PrintFont:
  DEFW $3C00
