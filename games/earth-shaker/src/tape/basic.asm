; Earth Shaker, Your Sinclair 1990: TZX block 11 of the issue 63 covertape's Side 1, the BASIC program "EARTH"
; (107 bytes at PROG $5CCB, LINE 1): CLEAR 27000, LOAD "" CODE and RANDOMIZE USR 35616.
; Written by kit/mkgame.py from src/tape/basic.ann and the recordings; edit basic.ann, not the .asm.

  DEVICE ZXSPECTRUM48
  ORG $5CCB
  INCLUDE "basic-module.asm"  ; The BASIC: line 10, which sets the colours, clears RAMTOP below the game, prints the title, loads the CODE block and enters the menu

  SAVEBIN "basic.bin",$5CCB,$006B
