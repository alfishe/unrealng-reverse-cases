; ZYX boot variants: David Whittaker's music driver from Stormbringer (zyxboot-11) at $C000 (tools/variants_music.py).
; Written by kit/mkgame.py from variants/players/whittaker-storm/whittaker-storm.ann; edit whittaker-storm.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (main.ann @equ)
SongTable      EQU $C4EE  ; the tune: 7 bytes a tune (tempo, three order lists)
  ORG $C000
  INCLUDE "whittaker-storm-module.asm"  ; David Whittaker's driver (Stormbringer): init, play, the pattern reader, envelopes, ornaments

  SAVEBIN "whittaker-storm.bin",$C000,$04EE
