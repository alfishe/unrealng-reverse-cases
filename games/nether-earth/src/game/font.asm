; Font: 64 glyphs of 8 bytes, codes $20-$5F
;
; Glyph = $6680 + code * 8, top line first, 1 = ink. Codes $20-$5F: space,
; punctuation, digits, "@" is the (c) sign, A-Z, then "[", "\", "]" and an up
; arrow at $5B-$5E, $5F blank. Read by PrintChar ($D4C2: 8 lines straight to
; the screen, one attribute from $FD13 to the cell at ($FD14)) and PrintBigChar
; ($D4F5: each line repeated $FD16 times; with $FD17 >= 2 ($D50C) each pixel
; doubled to 16 pixels wide). Every text of the game goes through them
; (PrintInline and the number printers). Image: d1-img/6780-Font.png.
Font:
  INCBIN "res/gfx/font.bin",$0000,512
