; --------------------------------------------------------------------------------------------------------------------
; introfont.asm: the scroller's font and the bytes after it
; --------------------------------------------------------------------------------------------------------------------

; the scroller's font: 96 glyphs from code $20 (src/res/intro98/font.png)
;
; 8 x 8 glyphs for $20-$7F: digits and signs as ASCII, $40-$5F upper-case and
; $60-$7F lower-case Cyrillic in the KOI-7 N2 order
; (ЮАБЦДЕФГХИЙКЛМНОПЯРСТУЖВЬЫЗШЭЩЧЪ). ScrollStep's font until the text switches
; to the ROM's ($3D00) and back; glyph = IntroFont - 256 + code * 8.
IntroFont:
  INCBIN "res/intro98/font.bin",$0000,768

; 52 bytes after the font that nothing reads
; (src/res/intro98/font-tail-leftover.bin)
;
; The end of the block's last sector after the font: no code reads them (no
; read in the window) and nothing addresses them. Kept as a leftover resource;
; what they were is not known (they look like a table of 3-byte records: 3 7 0
; / 3 7 0 ... 4 7 0 ...).
FontTailLeftover:
  INCBIN "res/intro98/font-tail-leftover.bin",$0000,52
