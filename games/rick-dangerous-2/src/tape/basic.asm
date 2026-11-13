; Rick Dangerous 2, Micro Style 1990: side A block 2, the BASIC program "RICK-II" (75 bytes at PROG $5CCB,
; LINE 0): four lines that clear to 65279, load the loader at $FF00 and call it.
; Written by kit/mkgame.py from src/tape/basic.ann; edit basic.ann, not the .asm.

  DEVICE ZXSPECTRUM128
  ORG $5CCB
  INCLUDE "basic-module.asm"  ; The BASIC "RICK-II": black screen, CLEAR 65279, LOAD the loader, call it

  SAVEBIN "basic.bin",$5CCB,$004B
