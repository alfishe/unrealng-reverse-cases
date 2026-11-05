; Nether Earth ZS Edition'99: the music block, $C000-$CCFF: NEZSEd99.B sectors 32-44, not packed, read by stage 2
; to $C000: a Sound Tracker compiled player and its module.
; Written by tools/front99_mkgame.py from the annotations (src/music99/music.ann) and the recordings; edit the annotations,
; not the .asm.

  DEVICE ZXSPECTRUM48

; the music block: $C000-$CCFF
  ORG $C000
  INCLUDE "music/player.asm"  ; the Sound Tracker 1.x compiled player

  SAVEBIN "music-c000.bin",$C000,3328
