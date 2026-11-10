; Tujad, Orpheus Ltd / Ariolasoft UK 1986: tape block 2, the BASIC program "TUJAD" (88 bytes at PROG $5CCB, LINE 10):
; CLEAR 24767, a black screen, LOAD "" CODE 16384 and RANDOMIZE USR 23296.
; Written by kit/mkgame.py from src/tape/basic.ann and the recordings; edit basic.ann, not the .asm.

  DEVICE ZXSPECTRUM48
  ORG $5CCB
  INCLUDE "basic-module.asm"  ; The BASIC: line 10, which clears the screen black, loads the CODE block and calls its stub

  SAVEBIN "basic.bin",$5CCB,$0058
