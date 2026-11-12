; ZYX boot variants: David Whittaker's music driver from Fantasy World Dizzy (zyxboot-10, zyxsiriu) at $BFFE (tools/variants_music.py).
; Written by kit/mkgame.py from variants/players/whittaker-dizzy/whittaker-dizzy.ann; edit whittaker-dizzy.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (main.ann @equ)
SongTable      EQU $C8DA  ; the tune: 7 bytes a tune (tempo, three order lists)
  ORG $BFFE
  INCLUDE "whittaker-dizzy-module.asm"  ; David Whittaker's driver (Fantasy World Dizzy): init, play, the pattern reader, envelopes, effects

  SAVEBIN "whittaker-dizzy.bin",$BFFE,$08DC
