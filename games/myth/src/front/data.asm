; --------------------------------------------------------------------------------------------------------------------
; data.asm: The two fonts and PrintText's variables
;
; FontSmall $9ED2 (37 glyphs: A-Z, the space, 0-9) for the headings and the menu title, FontLarge $9FFA (27 glyphs:
; A-Z, the space) for the names and the menu lines. A glyph is 8 bytes: a width mask (its set bits, from bit 7, are
; the columns the glyph uses: AdvanceColumn steps the pen by their count + 1) and 7 pixel rows. PrintText's variables
; follow the large font.
; --------------------------------------------------------------------------------------------------------------------

; The small font: 37 glyphs of 8 bytes (width mask, 7 rows): A-Z, space, 0-9
;
; Read by PrintText $9D72 (FontBase for font 0). menu: the glyphs of its
; small-font texts read.
FontSmall:
  INCBIN "res/front/font-small.bin",$0000,296

; The large font: 27 glyphs of 8 bytes: A-Z, space
;
; Read by PrintText $9D72 (FontBase for font 1). Glyphs 27-36 (the digits)
; would be read from PixelShift $A0D2 on: the large font has none.
FontLarge:
  INCBIN "res/front/font-large.bin",$0000,216

; PrintText: the pen's pixel offset in its byte (0-7); the low byte of the ROM
; pointer of the dissolves
;
; PrintText $9D72 and AdvanceColumn $9E24 keep the pen's bit offset here.
; RevealStrip $9E4D and DissolveLogoBox $7889 use PixelShift and TextLine as
; one word: 0 at the start of each dissolve, then + 1 a byte, the address of
; the ROM byte that picks the mask (LD BC,($A0D2)). menu: read and written.
PixelShift:
  DEFB $00
TextLine:
  DEFB $00                ; PrintText: the screen line of the text (the high
                          ; byte of the ROM pointer word)
GlyphMask:
  DEFB $00                ; PrintText: the current glyph's width mask
RevealLines:
  DEFB $00                ; RevealStrip: ScreenLineTable + 2 x the line (a
  DEFB $00                ; word)
FontBase:
  DEFB $00                ; PrintText: FontSmall or FontLarge (a word)
  DEFB $00
