; --------------------------------------------------------------------------------------------------------------------
; screen-rex2-module.asm: REX 2's loading screen
;
; Side 1 block 10: REX 1's picture with 141 bytes changed, the first at $4862 (offset 2146; 142 bytes of the tape
; block, checksum included) (docs/03-build-and-load.md 3.1), saved as Bytes "ds", start 40000, loaded at $4000.
; --------------------------------------------------------------------------------------------------------------------

; REX 2's loading screen: 6144 bytes of pixels, 768 of attributes
;
; Witness: c2 loads it at $4000 (work/stage1/c2/screens).
LoadingScreenRex2:
  INCBIN "res/screens/rex2.bin",$0000,6912
