; Enduro Racer, Activision 1987: tape block 4, the BASIC program "end2" (1770 bytes at PROG $5CCB, LINE 0),
; its variables area the first decoder Chain1 and the enciphered loader.
; Written by kit/mkgame.py from src/tape/basic2.ann and the recordings; edit basic2.ann, not the .asm.

  DEVICE ZXSPECTRUM48
  ORG $5CCB
  INCLUDE "basic2-module.asm"  ; The second BASIC: lines that aim the error return at VARS, and Chain1 in the variables area

  SAVEBIN "basic2.bin",$5CCB,$06EA
