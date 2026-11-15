; Rex, Martech Games 1988: tape side 2 block 2, the BASIC program "DEMO" (PROG $5CCB, LINE 1).
; Written by kit/mkgame.py from src/tape/basic.ann; edit basic.ann, not the .asm.

  DEVICE ZXSPECTRUM128
  ORG $5CCB
  INCLUDE "basic-demo-module.asm"  ; The BASIC "DEMO": clears the screen, sets RAMTOP, loads the screen and the code and calls the game

  SAVEBIN "basic-demo.bin",$5CCB,$0096
