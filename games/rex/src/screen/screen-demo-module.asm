; --------------------------------------------------------------------------------------------------------------------
; screen-demo-module.asm: DEMO's loading screen
;
; Side 2 block 4: REX 2's picture with 96 bytes changed (97 of the tape block), saved as Bytes "ds", start 40000,
; loaded at $4000.
; --------------------------------------------------------------------------------------------------------------------

; DEMO's loading screen: 6144 bytes of pixels, 768 of attributes
;
; Witness: d1 loads it at $4000 (work/stage1/d1/screens).
LoadingScreenDemo:
  INCBIN "res/screens/demo.bin",$0000,6912
