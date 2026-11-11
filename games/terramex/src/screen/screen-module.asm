; --------------------------------------------------------------------------------------------------------------------
; screen-module.asm: The loading screen
;
; TZX block 3: the 6912-byte screen the loader reads straight to $4000 with LD-BYTES before block 4.
; --------------------------------------------------------------------------------------------------------------------

; The loading screen: 6144 bytes of pixels, 768 of attributes
;
; Witness: c1 loads it at $4000 (the loader's first LD-BYTES); it stays on
; screen through the load of blocks 4 and 5.
LoadingScreen:
  INCBIN "res/screens/loading.bin",$0000,6912
