; Rick Dangerous 2, Micro Style 1990: side A block 5, the loading screen, read by the loader to $4000.
; Written by kit/mkgame.py from src/screen/screen.ann; edit screen.ann, not the .asm.

  DEVICE ZXSPECTRUM128
  ORG $4000
  INCLUDE "screen-module.asm"  ; The loading screen

  SAVEBIN "screen.bin",$4000,$1B00
