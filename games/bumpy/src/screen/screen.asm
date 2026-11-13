; Bumpy, Loriciels 1989: tape block 4, the loading screen BUMPY.SCR, loaded by the BASIC's LOAD "" SCREEN$ at $4000.
; Written by kit/mkgame.py from src/screen/screen.ann; edit screen.ann, not the .asm.

  DEVICE ZXSPECTRUM48
  ORG $4000
  INCLUDE "screen-module.asm"  ; The loading screen

  SAVEBIN "screen.bin",$4000,$1B00
