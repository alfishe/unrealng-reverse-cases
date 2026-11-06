; The STarKos player and the intro tune SK10
; Written by kit/mkgame.py from src/sound/starkos.ann and the recordings; edit starkos.ann, not the .asm.

  DEVICE ZXSPECTRUM128
  ORG $8000
  INCLUDE "starkos-play.asm"  ; the entries and the line: speed, patterns, the special track, the three tracks
  INCLUDE "starkos-frame.asm"  ; every frame: the three instruments, the track and instrument line formats
  INCLUDE "starkos-output.asm"  ; the period table, sending the registers, Stop, Init
  INCLUDE "starkos-song.asm"  ; the song SK10

  SAVEBIN "build/sound/starkos-8000.bin",$8000,$10C5
