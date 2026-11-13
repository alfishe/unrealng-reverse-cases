; --------------------------------------------------------------------------------------------------------------------
; cells.asm: Picture cells, the control-code table and the load parameters
;
; PictureCell draws a $0F picture's cells, one a step; ControlTable holds the handlers of the codes below 32;
; LoadParams are LoadFiles' addresses and lengths.
; --------------------------------------------------------------------------------------------------------------------

; Draw a picture's next cell from the script: an attribute and 8 pixel bytes;
; the picture's end clears LoadFlags bit 3
;
; Called by ScriptStep while LoadFlags bit 3 is set. The cell is PictureAt +
; RepeatCount (the column); the attribute byte goes there, the 8 pixel bytes
; down the cell (the attribute address turned into the pixel address as in
; PrintGlyph). ScriptPtr + 9. RepeatCount + 1; at PictureWidth, 0 again,
; PictureAt + 32 and PictureRows - 1; at 0 the picture is done.
;
; c1: 474 cells (work/ann/04-loader/reader.py counted the calls).
;
; Witness: L1 474 (c1).
PictureCell:
  EX DE,HL
  LD HL,(PictureAt)
  LD A,(RepeatCount)
  LD C,A
  LD B,$00
  ADD HL,BC
  LD A,(DE)               ; the attribute, then 8 pixel rows
  INC DE
  LD (HL),A
  LD A,H
  ADD A,A
  ADD A,A
  ADD A,A
  AND $78
  LD H,A
  LD B,$08
PictureCellRow:
  LD A,(DE)
  LD (HL),A
  INC DE
  INC H
  DJNZ PictureCellRow
  LD (ScriptPtr),DE           ; the next cell; at the row's end the next row
  INC C
  LD A,C
  LD (RepeatCount),A
  LD A,(PictureWidth)
  SUB C
  RET NZ
  LD (RepeatCount),A
  LD HL,(PictureAt)
  LD C,$20
  ADD HL,BC
  LD (PictureAt),HL
  LD HL,PictureRows             ; the last row: the picture is done
  DEC (HL)
  RET NZ
  LD HL,LoadFlags
  RES 3,(HL)
  RET

; The handlers of control codes $00-$1F, a word each ($0C, $0E and $1D are
; ControlCode's own)
;
; ControlCode jumps to the word at ControlTable + 2 x code. IgnoreCode
; (`$B8DC`) and IgnoreCode28 (`$BA09`) are a `RET`: the code does nothing and
; takes no argument.
ControlTable:
  DEFW IgnoreCode         ; $00-$02 nothing
  DEFW IgnoreCode
  DEFW IgnoreCode
  DEFW CodePause          ; $03 PAUSE n
  DEFW IgnoreCode         ; $04 nothing (the end: ScriptStep never dispatches
                          ; it)
  DEFW CodeFill           ; $05 FILL c
  DEFW IgnoreCode         ; $06, $07 nothing
  DEFW IgnoreCode
  DEFW CodeLeft           ; $08 LEFT
  DEFW CodeRight          ; $09 RIGHT
  DEFW CodeDown           ; $0A DOWN
  DEFW CodeUp             ; $0B UP
  DEFW IgnoreCode         ; $0C CLS (ControlCode's own, never read)
  DEFW CodeReturn         ; $0D CR
  DEFW IgnoreCode         ; $0E REPEAT n (ControlCode's own, never read)
  DEFW CodePicture        ; $0F PICTURE row col rows cols
  DEFW CodeInk            ; $10 INK n
  DEFW CodePaper          ; $11 PAPER n
  DEFW CodeFlash          ; $12 FLASH n
  DEFW CodeBright         ; $13 BRIGHT n
  DEFW IgnoreCode         ; $14, $15 nothing
  DEFW IgnoreCode
  DEFW CodeAt             ; $16 AT row col
  DEFW IgnoreCode         ; $17 nothing
  DEFW CodeSwap           ; $18 SWAP
  DEFW CodeGlyph          ; $19 GLYPH c and 8 bytes
  DEFW CodeWindow         ; $1A WINDOW left right top bottom
  DEFW IgnoreCode         ; $1B nothing
  DEFW IgnoreCode28       ; $1C nothing
  DEFW IgnoreCode         ; $1D TABFILL n (ControlCode's own, never read)
  DEFW CodeBorder         ; $1E BORDER n
  DEFW IgnoreCode         ; $1F nothing

; LoadFiles' parameters: the glyphs' and the script's address and length
;
; GlyphsAddr `$B326`, GlyphsLen `$01D8` (59 characters, 32-90); ScriptAddr
; `$998E`, ScriptLen `$1998`.
LoadParams:
GlyphsAddr:
  DEFW $B326
GlyphsLen:
  DEFW $01D8
ScriptAddr:
  DEFW $998E
ScriptLen:
  DEFW $1998

; Hooks before the script's first step: 230 (about 11.4 s)
ScriptDelay:
  DEFB $E6

; The main block's address, $5C00 (LoadFiles returns there), and its length
; MainLen, $81F0
MainAddr:
  DEFW $5C00
MainLen:
  DEFW $81F0
