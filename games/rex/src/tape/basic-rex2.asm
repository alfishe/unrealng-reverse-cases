; Rex, Martech Games 1988: tape side 1 block 8, the BASIC program "REX 2" (PROG $5CCB, LINE 1).
; Written by kit/mkgame.py from src/tape/basic.ann; edit basic.ann, not the .asm.

  DEVICE ZXSPECTRUM128
  ORG $5CCB
  INCLUDE "basic-rex2-module.asm"  ; The BASIC "REX 2": clears the screen, sets RAMTOP, loads the screen and the code and calls the game

  SAVEBIN "basic-rex2.bin",$5CCB,$0097
