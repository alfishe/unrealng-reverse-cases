; MASK III: VENOM Strikes Back, Gremlin Graphics 1988: TZX block 7, the AY music (Ben Daglish's player and its
; tunes), 4000 bytes that LoaderMain loads into RAM 4 at $C000 on a 128K; the game's interrupt pages it in.
; Written by kit/mkgame.py from src/music/music.ann and the recordings; edit music.ann, not the .asm.

  DEVICE ZXSPECTRUM128
  SLOT 3
  PAGE 4
  ORG $C000
  INCLUDE "music-module.asm"  ; The AY player and its tunes (RAM 4, 128K only)

  SAVEBIN "music.bin",$C000,$0FA0
