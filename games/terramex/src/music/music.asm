; Terramex, Grandslam 1987: TZX block 4 $6000-$71FF, the AY music player and its tunes, which the 128K setup
; copies to RAM 6, where the IM 2 handler calls it at $C000 every frame.
; Written by kit/mkgame.py from src/music/music.ann and the recordings; edit music.ann, not the .asm.

  DEVICE ZXSPECTRUM128
  SLOT 3
  PAGE 6
  ORG $C000
  INCLUDE "player.asm"  ; The player's entry, the start and the end of a tune, the frame update
  INCLUDE "state.asm"  ; The player's state: the instruments, the instrument slots, the channel records
  INCLUDE "ay.asm"  ; The AY registers: the frame's write and the port access
  INCLUDE "channel.asm"  ; A channel's frame: the events of its order list and its patterns
  INCLUDE "effects.asm"  ; The per-frame effects: the gate, the rest, the envelope, the vibrato, the arpeggio and the slide
  INCLUDE "tunes.asm"  ; The tune data and the player's tables: periods, vibratos, arpeggios, tunes, order lists, patterns, envelope rates

  SAVEBIN "music.bin",$C000,$1200
