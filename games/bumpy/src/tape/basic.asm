; Bumpy, Loriciels 1989: tape block 2, the BASIC program "BUMPY" (191 bytes at PROG $5CCB, LINE 10):
; hides the tape messages, CLEAR 24999, LOAD "" SCREEN$, LOAD "" CODE 25000 and RANDOMIZE USR 43900.
; Written by kit/mkgame.py from src/tape/basic.ann and the recordings; edit basic.ann, not the .asm.

  DEVICE ZXSPECTRUM48
  ORG $5CCB
  INCLUDE "basic-module.asm"  ; The BASIC: line 10, which hides the tape messages, loads the screen and the code and calls the game

  SAVEBIN "basic.bin",$5CCB,$00BF
