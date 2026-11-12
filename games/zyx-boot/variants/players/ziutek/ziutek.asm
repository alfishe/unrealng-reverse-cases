; ZYX boot variants: the Part V player of zyxfp4bt (tools/variants_music.py).
; Written by kit/mkgame.py from variants/players/ziutek/ziutek.ann; edit ziutek.ann, not the .asm.

  DEVICE ZXSPECTRUM48
  ORG $C780
  INCLUDE "ziutek-module.asm"  ; The Part V player: positions of patterns, three pattern streams, samples of 32 rows and ornaments of 32 notes

  SAVEBIN "ziutek.bin",$C780,$0303
