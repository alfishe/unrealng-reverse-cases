; ZYX boot variants: the Hydrofool game player of zyxalex (tools/variants_music.py).
; Written by kit/mkgame.py from variants/players/hydrofool/hydrofool.ann; edit hydrofool.ann, not the .asm.

  DEVICE ZXSPECTRUM48
  ORG $F424
  INCLUDE "hydrofool-module.asm"  ; The Hydrofool game player: three channels, each an order list of patterns; per frame the volume envelope, the arpeggio, vibrato and slides

  SAVEBIN "hydrofool.bin",$F424,$04CD
