; --------------------------------------------------------------------------------------------------------------------
; screen-rex1-module.asm: REX 1's loading screen
;
; Side 1 block 4: the 6912-byte screen saved as Bytes "ds" (its header says start 40000; `LOAD "" SCREEN$` puts it at
; $4000 all the same). The game's entry clears the screen; no code reads the picture.
; --------------------------------------------------------------------------------------------------------------------

; REX 1's loading screen: 6144 bytes of pixels, 768 of attributes
;
; Witness: c1 loads it at $4000 (work/stage1/c1/screens); it stays on the
; screen while the code block loads.
LoadingScreenRex1:
  INCBIN "res/screens/rex1.bin",$0000,6912
