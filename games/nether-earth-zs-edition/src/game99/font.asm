; --------------------------------------------------------------------------------------------------------------------
; font.asm: The character set: 64 glyphs of 8 x 8 pixels, codes $20-$5F
;
; The game's font, every text on the screen (the start-up menu, panel, numbers, messages). Resource:
; src/res/game99/gfx/font.png (128 x 32, 16 glyphs a row, in code order), built into gfx/font.bin by
; tools/game99_res.py.
;
; Format: 8 bytes a glyph, the top line first, bit 7 the leftmost pixel, 1 = ink. Readers: PrintChar ($D4B1) and
; PrintBigChar ($D4DA) at $6680 + 8 x code (written ViewBuffer+$0B80), so the font must stay right after the 3200-byte
; view buffer. Never written.
; --------------------------------------------------------------------------------------------------------------------

; Font: 64 glyphs of 8 bytes, codes $20-$5F
;
; Glyph = $6680 + code * 8, top line first, 1 = ink. Codes $20-$5F: space,
; punctuation, digits, "@" (an at sign), A-Z, then "[", "\", "]" and an up
; arrow at $5B-$5E, $5F an underline. Not Nether Earth's font: the letters and
; digits are 6 pixels wide on 6 lines, their left stroke doubled in the lower
; half; ten glyphs are Nether Earth's (space, #, *, +, -, ., =, ], the arrow,
; the underline). Read by PrintChar ($D4C2: 8 lines straight to the screen, one
; attribute from $FD13 to the cell at ($FD14)) and PrintBigChar ($D4F5: each
; line repeated $FD16 times; with $FD17 >= 2 ($D50C) each pixel doubled to 16
; pixels wide). Every text of the game goes through them (PrintInline and the
; number printers). Image: d1-img/6780-Font.png.
Font:
  INCBIN "res/gfx/font.bin",$0000,512
