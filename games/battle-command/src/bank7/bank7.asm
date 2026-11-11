; Battle Command, Ocean 1990: RAM bank 7, paged at $C000, as its tape block loads it.
; Written by kit/mkgame.py from src/bank7/bank7.ann and the recordings; edit bank7.ann, not the .asm.

  DEVICE ZXSPECTRUM128
  SLOT 3
  PAGE 7
  ORG $C000
  INCLUDE "pictures.asm"  ; Ten packed screens: the panels, frames and menu pictures
  INCLUDE "unpack.asm"  ; UnpackPicture: a packed screen from bank 7 onto the screen

  SAVEBIN "bank7.bin",$C000,$4000
