; SimCity, Infogrames 1990: tape block 2, the BASIC program "Simcity" (144 bytes at PROG $5CCB, LINE 0): a black
; screen, CLEAR 32767, LOAD "" CODE 65024, RANDOMIZE USR 65024, and three lines of the mastering left behind.
; Written by kit/mkgame.py from src/tape/basic.ann and the recordings; edit basic.ann, not the .asm.

  DEVICE ZXSPECTRUM48
  ORG $5CCB
  INCLUDE "basic-module.asm"  ; The BASIC: a black screen, CLEAR 32767, load the loader at $FE00 and call it; three mastering lines

  SAVEBIN "basic.bin",$5CCB,$0090
