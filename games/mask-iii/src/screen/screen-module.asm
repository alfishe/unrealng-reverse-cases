; --------------------------------------------------------------------------------------------------------------------
; screen-module.asm: The loading screen
;
; Tape block 5: a headerless block of 6912 bytes that LoaderMain ($5E00, src/loader) loads at $4000 with the ROM's LD-
; BYTES. It stays on the screen through the game's load; Menu $9723 wipes it (MenuWipe $984D, ClearScreen $992F) when
; the game starts.
; --------------------------------------------------------------------------------------------------------------------

; The loading screen: 6144 bytes of pixels, 768 of attributes
;
; Witness: c1 loads it at $4000 between the loader's start (frame 1094) and the
; game's entry (frame 15 019) at ROM speed; src/res/screens/loading.png and
; loading-attr.csv are the picture.
LoadingScreen:
  INCBIN "res/screens/loading.bin",$0000,6912
