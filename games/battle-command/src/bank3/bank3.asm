; Battle Command, Ocean 1990: RAM bank 3, paged at $C000, as its tape block loads it.
; Written by kit/mkgame.py from src/bank3/bank3.ann and the recordings; edit bank3.ann, not the .asm.

  DEVICE ZXSPECTRUM128
  SLOT 3
  PAGE 3
  ORG $C000
  INCLUDE "raster3.asm"  ; Bank 3: the polygon clip and span filler, the line drawer, the shared 3D models
  INCLUDE "debris.asm"  ; Eight flying fragments: an exploded object's pieces, moved and drawn every frame

  SAVEBIN "bank3.bin",$C000,$1400
