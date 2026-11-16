; Enduro Racer, Activision 1987: $FF63-$FF86 as tape blocks 12 and 14 load it over the loader's own end.
; Written by kit/mkgame.py from src/loader/tail.ann and the recordings; edit tail.ann, not the .asm.

  DEVICE ZXSPECTRUM48
  ORG $FF63
  INCLUDE "tail-module.asm"  ; The loader's new end: start the game through Mover

  SAVEBIN "tail.bin",$FF63,$0024
