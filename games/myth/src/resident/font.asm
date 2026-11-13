; --------------------------------------------------------------------------------------------------------------------
; font.asm: The print font
; --------------------------------------------------------------------------------------------------------------------

  ORG $F880

; 37 glyphs, 8 bytes each: the width mask, then 7 rows; A-Z, the space, 0-9
;
; Read by TextToBuffer (every title screen). The mask's lowest set bit marks
; the glyph's width (Advance).
PrintFont:
  INCBIN "res/resident/print-font.bin",$0000,296

  ORG $FF84

; A copy of the ROM font $3E34-$3EAF (the end of F to U) and $27: no code reads
; it
;
; A leftover of the mastering: no operand names $FF84-$FFFF and the tape's
; image holds the ROM's bytes. The stack (SP = $FFFF) writes over its end in
; play. Known only from the code.
RomFontLeftover:
  INCBIN "res/resident/rom-font-leftover.bin",$0000,124
