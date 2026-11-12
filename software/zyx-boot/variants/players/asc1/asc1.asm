; ZYX boot variants: the ASC Sound Master 1.x player of zyxboot-01 (tools/variants_music.py).
; Written by kit/mkgame.py from variants/players/asc1/asc1.ann; edit asc1.ann, not the .asm.

  DEVICE ZXSPECTRUM48
  ORG $C000
  INCLUDE "asc1-module.asm"  ; The relocatable ASC Sound Master 1.x player: relocation, init, frame, rows with the 1.x commands, samples, ornaments

  SAVEBIN "asc1.bin",$C000,$0671
