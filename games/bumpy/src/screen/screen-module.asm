; --------------------------------------------------------------------------------------------------------------------
; screen-module.asm: The loading screen
;
; Tape block 4: the 6912-byte screen "BUMPY.SCR" (its header says start 32768; LOAD "" SCREEN$ puts it at $4000 all
; the same). The game never reads it: GameStart clears the screen.
; --------------------------------------------------------------------------------------------------------------------

; The loading screen: 6144 bytes of pixels, 768 of attributes
;
; Witness: c1 loads it at $4000 (work/stage1/c1/screens/001182-loading-2.png);
; it stays on screen through the load of the code block.
LoadingScreen:
  INCBIN "res/screens/loading.bin",$0000,6912
