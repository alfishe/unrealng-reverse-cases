; --------------------------------------------------------------------------------------------------------------------
; font.asm: the game's Cyrillic font and the free bytes round it
;
; GameFont holds the 64 glyphs of codes $20-$5F, 8 bytes each from the top line; PrintChar and PrintBigChar read glyph
; code at $C400 + 8 x code (GameFont - $100). The game's letters are Russian drawn over the Latin codes
; (tools/game_text.py: a look-alike where there is one, a free code for the rest; $33 is both 3 and З).
;
; Resource: src/res/game/gfx/font.png (16 glyphs a row). Before the font, $C4A8-$C4FF, and after it, $C700-$C848, are
; unused bytes up to ConstructionMenu: the $FE at $C4A8 and zeros.
; --------------------------------------------------------------------------------------------------------------------

; 88 bytes, never used: a $FE, then zeros
FontSpare1:
  DEFB $FE,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; The font: 64 glyphs of 8 bytes, codes $20-$5F, the Russian letters over the
; Latin ones
;
; Read by PrintChar ($D4B7) and PrintBigChar ($D4E0) only. Zero-based on code
; $20, the space.
GameFont:
  INCBIN "res/game/gfx/font.bin",$0000,512

; 329 bytes, never used, up to ConstructionMenu
FontSpare2:
  DEFS $0149
