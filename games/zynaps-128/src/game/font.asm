; --------------------------------------------------------------------------------------------------------------------
; font.asm: the game's own glyphs for the print codes $80-$B5
;
; The print routine's characters above $7F: 54 glyphs, the title logo's pieces. Rows 1-4 of the PNG (codes $80-$A3)
; are the pieces of the ZYNAPS logo, rows 5-6 (codes $A4-$B5) the rest of the logo and the HEWSON name in its
; lettering (row 5). The editable form is src/res/fonts/glyphs.font.png (tools/res_font.py, 9 glyphs a row); the codes
; below $80 print with the ROM's character set.
; --------------------------------------------------------------------------------------------------------------------

; 54 glyphs of 8 x 8, the print codes $80-$B5
;
; The print routine ($A321) takes HL = code * 8 + $B14F, so code $80 is $B54F
; and $B5 the last ($B6F7). The editable form: src/res/fonts/glyphs.font.png
; (tools/res_font.py), 9 glyphs a row.
Glyphs:
  INCBIN "res/fonts/glyphs.bin",$0000,432
