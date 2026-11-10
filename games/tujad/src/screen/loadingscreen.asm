; --------------------------------------------------------------------------------------------------------------------
; loadingscreen.asm: The loading screen: 6144 bytes of pixels and 768 attributes
;
; The first 6912 bytes of the CODE block land on the screen while it loads (c1, before frame 2908, when StubLoad is
; entered); the editable form is src/res/screen/LoadingScreen.png (the picture, ink and paper) with
; src/res/screen/LoadingScreenAttributes.txt (the attributes), tools/res_formats.py. The game never reads it: Setup
; clears the screen at the menu (ClearScreen $7A9F).
; --------------------------------------------------------------------------------------------------------------------

; The loading screen: the display file (6144 bytes) and the attributes (768)
;
; Shown from the moment the CODE block loads (c1, before frame 2908) until the
; game clears the screen for its menu (ClearScreen $7A9F, called by Setup in c1
; frame 13580). No code of the game reads it. Its picture:
; docs/img/play/loading.png.
LoadingScreen:
  INCBIN "res/screen/LoadingScreen.bin",$0000,6144
LoadingAttributes:
  INCBIN "res/screen/LoadingScreen.bin",$1800,768
