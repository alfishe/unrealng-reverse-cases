; ZYX boot variants: the game player of zyxawbt (tools/variants_music.py).
; Written by kit/mkgame.py from variants/players/awbt/awbt.ann; edit awbt.ann, not the .asm.

  DEVICE ZXSPECTRUM48
  ORG $BFFB
  INCLUDE "awbt-module.asm"  ; A game's music and effects player: songs of sequence triples, sequences of voice numbers, voices of volume and pitch pairs

  SAVEBIN "awbt.bin",$BFFB,$04EE
