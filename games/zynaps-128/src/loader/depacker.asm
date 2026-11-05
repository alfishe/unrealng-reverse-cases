; Zynaps 2 in 1: ZYNAPS.B sector 1, the Hrust 1 depacker ($5B00)
; Written by tools/part_mkasm.py from src/loader/depacker.ann; edit the .ann, not the .asm.

  DEVICE ZXSPECTRUM128

; The variables past the loaded image (game.ann @equ)
ROM_HL_ALT     EQU $2758  ; the value the 48 BASIC ROM keeps in HL' (the calculator's): restored before the return
  ORG $5B00
  INCLUDE "depack.asm"  ; the Hrust 1 depacker (Dmitry Pyankov's HR format), unpacking in place

  SAVEBIN "build/obj/depacker.bin",$5B00,$0100
