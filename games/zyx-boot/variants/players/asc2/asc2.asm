; ZYX boot variants: the ASC Sound Master player of zyxboot-14..18 (tools/variants_music.py).
; Written by kit/mkgame.py from variants/players/asc2/asc2.ann; edit asc2.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
Module         EQU $C4A7  ; the tune's module right after the player (tools/variants_music.py)
  ORG $C000
  INCLUDE "asc2-module.asm"  ; The ASC Sound Master player (later command set): init, frame, pattern reader, samples, ornaments, AY

  SAVEBIN "asc2.bin",$C000,$04A7
