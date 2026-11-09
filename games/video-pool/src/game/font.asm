; --------------------------------------------------------------------------------------------------------------------
; font.asm: The game's own font: a-z and 0-9
;
; The 36 glyphs of 8 x 8 pixels the print routine PrintChar $9E7C takes for the codes $61-$7A (a-z, Font + 8 (code -
; $61)) and $30-$39 (0-9, Font+208 + 8 (code - $30)); every other code comes from the ROM's CHAR_SET $3D00, $7F from
; CopyrightGlyph $9F2E. The editable source is src/res/fonts/Font.png, twelve glyphs a row.
; --------------------------------------------------------------------------------------------------------------------

; The font: 26 letters a-z, then 10 digits 0-9, 8 bytes each
;
; Read by PrintChar $9E7C and the hall of fame's name printers: every byte read
; in w1 (l1sum.py --reads DEF4-E013: 288 of 288 bytes; game, f1, p2, v1, m1, j1
; read the glyphs of their texts).
Font:
  INCBIN "res/fonts/Font.bin",$0000,208
FontDigits:
  INCBIN "res/fonts/Font.bin",$00D0,80
