; ZYX boot variants: the game player of zyxfp3bt (tools/variants_music.py).
; Written by kit/mkgame.py from variants/players/fp3bt/fp3bt.ann; edit fp3bt.ann, not the .asm.

  DEVICE ZXSPECTRUM48
  ORG $C000
  INCLUDE "fp3bt-module.asm"  ; A game's stream player: numbered streams of two-byte items, called like subroutines, on three channels; volume, pitch and global shapes

  SAVEBIN "fp3bt.bin",$C000,$0518
