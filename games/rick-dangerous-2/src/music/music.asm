; Rick Dangerous 2, Micro Style 1990: side A block 6's first 4224 bytes ($6000-$707F on the tape), the AY music
; player, its tunes and effects, which the entry code copies to RAM 1 at $C000 on a 128K.
; Written by kit/mkgame.py from src/music/music.ann and the recordings; edit music.ann, not the .asm.

  DEVICE ZXSPECTRUM128
  SLOT 3
  PAGE 1
  ORG $C000
  INCLUDE "tunes.asm"  ; The tunes: patterns, the tune table, the order lists, the pattern addresses, ornaments, instruments
  INCLUDE "effects.asm"  ; The sound effects: the table, the start, the choice of a voice
  INCLUDE "player.asm"  ; The voices: the period table, the voice records, the envelopes and sweeps, the AY registers
  INCLUDE "sequencer.asm"  ; The tune sequencer: order lists, patterns, ornaments

  SAVEBIN "music.bin",$C000,$1080
