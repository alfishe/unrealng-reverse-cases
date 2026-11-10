; --------------------------------------------------------------------------------------------------------------------
; screen-module.asm: The loading screen: the Probe / Infogrames title picture by Simon Butler
;
; One resource, src/res/screen/LoadingScreen.png (tools/res_formats.py: the 256 x 192 picture in the Spectrum's
; colours, ink and paper kept apart). The game never reads it: code2 loads over its pixels ($4000-$501F) and the
; game's first drawing clears the rest.
; --------------------------------------------------------------------------------------------------------------------

; The loading screen: 6144 bytes of pixels, then 768 attributes
;
; The Probe / Infogrames title picture, signed "SIMON" (Simon Butler). c1:
; LoadBlock stores it at frames 1259-3561; the stored bytes equal
; tools/decrypt_tape.py's decryption of tape block 5 (docs/03 3.3).
LoadingScreen:
  INCBIN "res/screen/LoadingScreen.bin",$0000,6912
