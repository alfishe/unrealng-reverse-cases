; --------------------------------------------------------------------------------------------------------------------
; cavedata.asm: The 32 caves
;
; Cave N (1-32) is the 314 bytes at CaveData + 314 x (N - 1), the first at $C000 (UnpackCave computes $BEC6 + 314N):
; 300 bytes of cells (two a byte, the low nibble first; 30 a row, 20 rows), then the 14 parameter bytes UnpackCave
; copies to CaveParams $FD9A.
; --------------------------------------------------------------------------------------------------------------------

  ORG $C000

; The 32 caves, 314 bytes each
CaveData:
  INCLUDE "res/caves/caves.inc"
