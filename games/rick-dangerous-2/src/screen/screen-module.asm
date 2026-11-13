; --------------------------------------------------------------------------------------------------------------------
; screen-module.asm: The loading screen
;
; The display file and the attributes as one resource, src/res/screens/loading.png (tools/res_formats.py). No code
; reads it: it is shown while the game block loads and overwritten by the game's first screen.
; --------------------------------------------------------------------------------------------------------------------

; The loading screen: 6144 bytes of pixels, then 768 attributes
;
; The Core Design logo and the Rick Dangerous 2 title picture. The game's entry
; clears the screen for the control menu (c1, frame 14 007 on).
LoadingScreen:
  INCBIN "res/screens/loading.bin",$0000,6912
