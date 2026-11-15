; Rex, Martech Games 1988: tape side 1 block 4, the loading screen of REX 1 (6912 bytes at $4000).
; Written by kit/mkgame.py from src/screen/screen.ann; edit screen.ann, not the .asm.

  DEVICE ZXSPECTRUM128
  ORG $4000
  INCLUDE "screen-rex1-module.asm"  ; REX 1's loading screen

  SAVEBIN "screen-rex1.bin",$4000,$1B00
