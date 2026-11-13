; --------------------------------------------------------------------------------------------------------------------
; workspace.asm: The zero-filled space of the block and the glyph rows buffer
;
; The block's first 3009 bytes ($6C3F-$77FF) and its last 1662 ($A1C1-$A83E) are zeros on the tape. The front uses
; only GlyphRows $7600 there (PrintText's shifted glyph). Stage 1, loaded over the whole block later, keeps its
; variables and tables at $6D00-$77FF (docs/02-architecture.md 2.2).
; --------------------------------------------------------------------------------------------------------------------

; Zeros: no code of the front reads or writes $6C3F-$75FF
;
; Zeros on the tape. The menu recording reads and writes none of it; the
; front's code names no address there (known only from the code, every operand
; of the part checked).
FrontLowSpace:
  DEFS $09C1

; PrintText's glyph: 7 rows of two bytes (the glyph's row, shifted right by
; PixelShift into the second byte)
;
; Written and read by PrintText $9D72 for every character (menu: all 14 bytes
; read and written).
GlyphRows:
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00

; Zeros up to the code at $7800
;
; Zeros on the tape; no access in the menu recording.
FrontMidSpace:
  DEFS $01F2

  ORG $A1C1

; Zeros to the block's end ($A1C1-$A83E)
;
; Zeros on the tape; the front's code names no address there and the menu
; recording reads none of it.
FrontHighSpace:
  DEFS $067E
