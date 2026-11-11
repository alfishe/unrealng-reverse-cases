; --------------------------------------------------------------------------------------------------------------------
; font.asm: The 8x8 font of PrintString and PrintRawString
;
; 98 glyphs for the characters $20-$81, 8 bytes each, the top row first. PrintChar ($6FF0, through GlyphAddress $6ED7)
; and PrintRawString $C6FC address glyph c at $F5E4 + 8 (c - $20). $80 and $81 are the map legend's road and river
; patterns. The small-font texts (code 7) use SmallFont $7C59 instead, where ":" is the space and "[" the full stop.
; --------------------------------------------------------------------------------------------------------------------

; The 8x8 font: characters $20-$81
;
; Read by PrintString's PrintChar (`$6EE1`) and by PrintRawString (`$C707`,
; `$C716`).
Font8x8:
  INCBIN "res/fonts/font8x8.bin",$0000,784
