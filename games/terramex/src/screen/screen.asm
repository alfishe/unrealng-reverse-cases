; Terramex, Grandslam 1987: TZX block 3, the loading screen, loaded by the loader's LD-BYTES at $4000.
; Written by kit/mkgame.py from src/screen/screen.ann; edit screen.ann, not the .asm.

  DEVICE ZXSPECTRUM128
  ORG $4000
  INCLUDE "screen-module.asm"  ; The loading screen

  SAVEBIN "screen.bin",$4000,$1B00
