; --------------------------------------------------------------------------------------------------------------------
; font.asm: The text font: 43 glyphs of 8 x 8
; --------------------------------------------------------------------------------------------------------------------

; 43 glyphs: 0-9, A-Z, three pictures, comma, full stop, question mark, space
;
; Glyph G at `$9E95` + 8G, top line first. The printers: `$A977` (the score and
; counters, digits 0-9 as numbers), `$A9E8`, `$AA0E` / `$AA25` (codes as glyph
; numbers) and `$AA8D` / `$AA9F` (ASCII: code - `$37`, so "A" = 10). The
; editable form is src/res/graphics/font.png.
Font:
FontDigits:
  INCBIN "res/graphics/font.bin",$0000,80
FontLetters:
  INCBIN "res/graphics/font.bin",$0050,208
FontIcons:
  INCBIN "res/graphics/font.bin",$0120,24
FontPunctuation:
  INCBIN "res/graphics/font.bin",$0138,32
