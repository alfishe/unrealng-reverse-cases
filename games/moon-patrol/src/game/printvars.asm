; --------------------------------------------------------------------------------------------------------------------
; printvars.asm: Print variables: the print position, colours, metrics and state, the code table and the font descriptors
;
; The print code at $FD80-$FFF3 addresses these through IX = $F000 (PrintChar $FDCC sets it). The loaded image holds
; the state the developer left: font 3 (the ROM font) selected and the shifted rows of a copyright sign in
; PrintShifted.
; --------------------------------------------------------------------------------------------------------------------

; The print position's pixel line (0-184), the top of the next glyph
;
; Set by AT ($FE8E) and by a new line ($FE21: + line step, less $B9 past the
; bottom); read at $FF2A. The menus read PrintY and PrintX as one word ($8B20,
; $8CE7).
PrintY:
  DEFB $00

; The print position's x in pixels
;
; Set by AT ($FE78), TAB ($FE9E) and a new line (the left margin, $FE15); moved
; on by each glyph ($FFCC).
PrintX:
  DEFB $00

; PrintX AND 7: the glyph's shift within its byte ($FF4B, read at $FF74)
PrintShift:
  DEFB $00

; The character being printed ($FEF7, read at $FF5F)
PrintCode:
  DEFB $7F

; The attribute of the cells a glyph touches: set by INK, PAPER, FLASH, BRIGHT
; ($FE33-$FE73); stored at $FFA0
PrintAttr:
  DEFB $0F

; The left margin a new line returns to (code $18, $FEAF)
PrintMargin:
  DEFB $00

; The right limit: a glyph that would pass it starts a new line (code $19,
; $FEC3; read at $FF20)
PrintLimit:
  DEFB $FF

; Bit 0 is set when a parameter is out of range ($FEBD, $FEEF); never read
PrintError:
  DEFB $00

; The current font's base: glyph = base + 8 x code (set by FONT, $FEE1; read at
; $FF65)
;
; Bit 2 of its high byte ($F009) tells PrintAttrCheck $F0F0 to leave the
; colours alone: set for FontPlain ($F600) and the ROM font ($3C00).
PrintFont:
  DEFW $3C00

; The handler of the next code: PrintCharNormal $FDE3, or a control code's
; parameter handler
;
; PrintChar $FDCC jumps through it ($FDD9). The control code handlers store
; themselves here ($FE0A) and put PrintCharNormal back when their parameter
; arrives ($FEE6).
PrintState:
  DEFW PrintCharNormal

; The current font's metrics, copied from its descriptor by FONT ($FED6): width
; of most characters
PrintWidth:
  DEFB $08
PrintWidthI:
  DEFB $08                ; width of "I" ($FF02)
PrintWidthMW:
  DEFB $08                ; width of "M" and "W" ($FF14)
PrintWidthSpace:
  DEFB $08                ; width of a space ($FF07)
PrintLineStep:
  DEFB $08                ; pixel lines from one text line to the next ($FE18)
PrintRows:
  DEFB $08                ; glyph rows drawn ($FF51, $FF71, $FFAF)

; The screen addresses of the glyph's rows (one word a row, up to 8), filled at
; $FF4E from ScreenLineTable plus the byte column
PrintLines:
  DEFW $4EA2,$4FA2
  DEFW $48C2,$49C2
  DEFW $4AC2,$4BC2
  DEFW $4CC2,$4DC2

; The glyph's rows shifted by PrintShift: two bytes a row, up to 8 rows
; ($FF6E), ORed onto the screen at $FFB2
PrintShifted:
  DEFB $3C,$00
  DEFB $42,$00
  DEFB $99,$00
  DEFB $A1,$00
  DEFB $A1,$00
  DEFB $99,$00
  DEFB $42,$00
  DEFB $3C,$00

; 78 zero bytes, never read or written
PrintSpare:
  DEFS $4E

; The handlers of the control codes $10-$1A, one word each, read at $FDFD
;
; In order: $10 INK $FE2E, $11 PAPER $FE3D, $12 FLASH $FE52, $13 BRIGHT $FE65,
; $14 / $15 $FE23, $16 AT $FE78, $17 TAB $FE92, $18 MARGIN $FEAA, $19 LIMIT
; $FEB3, $1A FONT $FEC7.
PrintCodeTable:
  DEFW PrintInk
  DEFW PrintPaper
  DEFW PrintFlash
  DEFW PrintBright
  DEFW PrintSwallow
  DEFW PrintSwallow
  DEFW PrintAtX
  DEFW PrintTab
  DEFW PrintMarginSet
  DEFW PrintLimitSet
  DEFW PrintFontSet

; Four font descriptors of 8 bytes: width, width of I, width of M/W, width of a
; space, line step, rows, base (word)
;
; FONT n copies descriptor n's six metrics to PrintWidth $F00C and its base to
; PrintFont $F008 ($FEC7). Font 0: 4 4 6 2, step 6, 5 rows, base $F000 (glyphs
; FontSmall $F100). Font 1: 6 5 6 5, step 9, 6 rows, base $F300 (FontBold
; $F400); the title sets its step to 8 ($800A LD ($F0A2),A). Font 2: 6 6 6 6,
; step 8, 6 rows, base $F600 (FontPlain $F700). Font 3: all 8, base $3C00, the
; ROM font; its descriptor is never read in the runs (no reads of $F0AE-$F0B5).
FontDescriptors:
  DEFB $04,$04,$06,$02,$06,$05,$00,$F0
  DEFB $06,$05,$06,$05,$09,$06,$00,$F3 ; font 1
  DEFB $06,$06,$06,$06,$08,$06,$00,$F6 ; font 2
  DEFB $08,$08,$08,$08,$08,$08,$00,$3C ; font 3

; 58 zero bytes, never read or written
PrintSpare2:
  DEFS $3A
