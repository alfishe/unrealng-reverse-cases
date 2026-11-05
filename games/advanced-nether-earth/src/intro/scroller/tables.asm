; --------------------------------------------------------------------------------------------------------------------
; tables.asm: the tables and pictures the star and the text read
;
; The font, the text's row addresses, the dither levels and the patterns built from them, the screen at the start and
; the heat grid over its end. Most of $7800-$BFFF is zero in the image and built or cleared at run time (ScrollerInit,
; ScrollerStart).
; --------------------------------------------------------------------------------------------------------------------

; 50 zero bytes
ScrollerSpare:
  DEFS $32

; the 24 rows' screen addresses (ScrollerInit), and the font's base
;
; ScrollerInit writes 24 words here: the screen address of character row r at
; column 31 ($401F, then 8 lines down each). TypeChar also takes the glyph of
; code c at TextRows + 8 c: codes $20-$5F lie in ScrollerFont, codes 0-$1F
; would be this page. Zero in the image.
TextRows:
  DEFS $0100

; the glyphs of codes $20-$5F, 8 bytes each, turned a quarter clockwise
;
; Built from src/res/intro/scroller/font.png.
ScrollerFont:
  INCBIN "res/scroller/font.bin",$0000,512

; zero
ScrollerSpare2:
  DEFS $0100

; the patterns of the 256 pairs of heat levels (ScrollerInit): page $7C + line,
; pair index
;
; Built by ScrollerInit from DitherLevels: for the pair index (a, b) = a x 16 +
; b, line n of the byte is the left nibble of level a and the right nibble of
; level b, both swapped (RLCA x 4). Zero in the image.
DitherPatterns:
  DEFS $0400

; the 16 heat levels as 4 lines of a dither pattern
;
; Read once by ScrollerInit; then ScrollerInit's PairIndex overwrites it. Built
; from src/res/intro/scroller/dither.png.
DitherLevels:
  INCBIN "res/scroller/dither.bin",$0000,64

; zero; at run time PairIndex: (page $80 + right cell, left cell) = right x 16
; + left
;
; ScrollerInit fills $8000-$800F, $8100-$810F, ... $8F00-$8F0F with 0-255 in
; order: StarShow looks a pair of cells up there (H = $80 + the right cell's
; heat, L = the left cell's).
PairIndex:
  DEFS $04C0

; the screen at the start: the logo "ETERNITY INDUSTRY 1998 Presents", the rest
; black
;
; Copied to $4000 by ScrollerStart, then its bytes serve as work space:
; StarRows (written by ScrollerInit) and StarBuffer (cleared) lie over its end.
; Built from src/res/intro/scroller/screen.png.
ScrollerScreen:
  INCBIN "res/scroller/screen.bin",$0000,2576
StarRows:
  INCBIN "res/scroller/screen.bin",$0A10,2288
StarBuffer:
  INCBIN "res/scroller/screen.bin",$1300,2048

; the heat grid's rows past ScrollerScreen: zero
StarBufferRest:
  DEFS $2000
