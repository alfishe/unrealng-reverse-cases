; ZYX boot variants: David Whittaker's sound driver from Platoon (zyxboot-05, zyxboot-08) at $C000 (tools/variants_music.py).
; Written by kit/mkgame.py from variants/players/whittaker-platoon/whittaker-platoon.ann; edit whittaker-platoon.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
SongTable      EQU $C8ED  ; the tune: 7 bytes a tune (tempo, three order lists)
  ORG $C000
  INCLUDE "whittaker-platoon-module.asm"  ; David Whittaker's driver (Platoon): init, play, the pattern reader, envelopes, ornaments, effects

  SAVEBIN "whittaker-platoon.bin",$C000,$08ED
