; Rex, Martech Games 1988: tape side 2 block 4, the loading screen of DEMO (6912 bytes at $4000).
; Written by kit/mkgame.py from src/screen/screen.ann; edit screen.ann, not the .asm.

  DEVICE ZXSPECTRUM128
  ORG $4000
  INCLUDE "screen-demo-module.asm"  ; DEMO's loading screen

  SAVEBIN "screen-demo.bin",$4000,$1B00
