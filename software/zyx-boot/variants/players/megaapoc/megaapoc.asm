; ZYX boot variants: the Mega Apocalypse game player of zyxdimob (tools/variants_music.py).
; Written by kit/mkgame.py from variants/players/megaapoc/megaapoc.ann; edit megaapoc.ann, not the .asm.

  DEVICE ZXSPECTRUM48
  ORG $E505
  INCLUDE "megaapoc-module.asm"  ; The Mega Apocalypse game player: three channels of order lists and patterns, plus one sound effect on channel C

  SAVEBIN "megaapoc.bin",$E505,$045B
