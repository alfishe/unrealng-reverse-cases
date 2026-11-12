; ZYX boot: the music piece at $C000, an ASC Sound Master compilation (player and tune) the menu calls at
; $C00B (init) and from its interrupt at $C00E (play).
; Written by kit/mkgame.py from src/music/music.ann and the recordings; edit music.ann, not the .asm.

  DEVICE ZXSPECTRUM48
  ORG $C000
  INCLUDE "player.asm"  ; The ASC Sound Master player: the entry vectors, the set-up, the frame, the pattern reader, the samples and ornaments, the AY write
  INCLUDE "tune.asm"  ; The tune: the ASC Sound Master module "Disco music" by Ant P

  SAVEBIN "music.bin",$C000,$1600
