; MASK III: VENOM Strikes Back, Gremlin Graphics 1988: TZX block 5, the loading screen, loaded at $4000 by LoaderMain $5E00.
; Written by kit/mkgame.py from src/screen/screen.ann; edit screen.ann, not the .asm.

  DEVICE ZXSPECTRUM48
  ORG $4000
  INCLUDE "screen-module.asm"  ; The loading screen

  SAVEBIN "screen.bin",$4000,$1B00
