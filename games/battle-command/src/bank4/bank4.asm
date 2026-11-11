; Battle Command, Ocean 1990: RAM bank 4, paged at $C000, as its tape block loads it.
; Written by kit/mkgame.py from src/bank4/bank4.ann and the recordings; edit bank4.ann, not the .asm.

  DEVICE ZXSPECTRUM128
  SLOT 3
  PAGE 4
  ORG $C000
  INCLUDE "music.asm"  ; The AY music player: one tune (the title music), three channels, commands, instruments, ornaments

  SAVEBIN "bank4.bin",$C000,$0E00
