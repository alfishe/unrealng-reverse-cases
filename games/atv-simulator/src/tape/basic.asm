; ATV Simulator, Code Masters 1987: tape block 1, the BASIC loader "ATV" (44 bytes at PROG $5CCB, LINE 10).
; Written by kit/mkgame.py from src/tape/basic.ann and the recordings; edit basic.ann, not the .asm.

  DEVICE ZXSPECTRUM48
  ORG $5CCB
  INCLUDE "basic-module.asm"  ; The BASIC loader: CLEAR, LOAD ""CODE, RANDOMIZE USR into the machine-code loader

  SAVEBIN "basic.bin",$5CCB,$002C
