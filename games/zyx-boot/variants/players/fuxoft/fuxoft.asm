; ZYX boot variants: Fuxoft's music player at $EB50 (tools/variants_music.py).
; Written by kit/mkgame.py from variants/players/fuxoft/fuxoft.ann; edit fuxoft.ann, not the .asm.

  DEVICE ZXSPECTRUM48
  ORG $EB50
  INCLUDE "fuxoft-module.asm"  ; Fuxoft's player: three entry vectors, the channel streams with calls and loops, instruments, ornaments

  SAVEBIN "fuxoft.bin",$EB50,$04E5
