; Rex, Martech Games 1988: tape side 1 block 10, the loading screen of REX 2 (6912 bytes at $4000).
; Written by kit/mkgame.py from src/screen/screen.ann; edit screen.ann, not the .asm.

  DEVICE ZXSPECTRUM128
  ORG $4000
  INCLUDE "screen-rex2-module.asm"  ; REX 2's loading screen

  SAVEBIN "screen-rex2.bin",$4000,$1B00
