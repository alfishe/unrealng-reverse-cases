; Enduro Racer, Activision 1987: tape block 2, the BASIC program "enduro" (205 bytes at PROG $5CCB, LINE 0).
; Written by kit/mkgame.py from src/tape/basic1.ann and the recordings; edit basic1.ann, not the .asm.

  DEVICE ZXSPECTRUM48
  ORG $5CCB
  INCLUDE "basic1-module.asm"  ; The first BASIC: colours, USR into Stage0, LOAD ""

  SAVEBIN "basic1.bin",$5CCB,$00CD
