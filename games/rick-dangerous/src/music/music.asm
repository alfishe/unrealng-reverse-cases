; Rick Dangerous, Firebird 1989: the AY music and effects player and its tunes, $0DA4 bytes, assembled at $C000 in RAM 1
; where the entry's CopyMusicToRam1 puts them on a 128K; the game image holds the same bytes at $5E00.
; Written by kit/mkgame.py from src/music/music.ann and the recordings; edit music.ann, not the .asm.

  DEVICE ZXSPECTRUM128
  SLOT 3
  PAGE 1
  ORG $C000
  INCLUDE "player.asm"  ; The AY player: periods, the three channels' state, note start, volume envelopes, the AY output
  INCLUDE "sequencer.asm"  ; The tune sequencer: three tracks of order lists and patterns, started by AyPlayTune, stepped by AyTick
  INCLUDE "effects.asm"  ; The sound effects: AyPlayEffect and the table of the 12 effects
  INCLUDE "tunes.asm"  ; The tunes: 55 patterns, the tune table, the 24 order lists, the pattern pointers and the 8 instruments

  SAVEBIN "music.bin",$C000,$0DA4
