; ZYX boot variants: the Sound Tracker player (assembled at each variant's MusicPiece by tools/variants_music.py).
; Written by kit/mkgame.py from variants/players/stc/stc.ann; edit stc.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
Module         EQU $C4B4  ; the STC module right after the player (tools/variants_music.py sets it to the variant's address)
  ORG $C078
  INCLUDE "stc-module.asm"  ; The Sound Tracker player: init, play, the pattern reader, the samples and ornaments, the AY write

  SAVEBIN "stc.bin",$C078,$043C
