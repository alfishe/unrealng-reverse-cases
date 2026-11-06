; The page-4 sound engine of the 128K game
; Written by kit/mkgame.py from src/sound/engine.ann and the recordings; edit engine.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; The variables past the loaded image (game.ann @equ)
PeriodTable    EQU $DE48  ; the tone period of note 0-94, a word each (the data image, [periods])
EnvelopeTable  EQU $DF06  ; the envelope pointers, a word each (the data image, [envelopes])
SoundTable     EQU $DF4D  ; the sound pointers 0-35, a word each (the data image, [sounds]); CmdSwap swaps 0 and 1
  ORG $C968
  INCLUDE "engine-entries.asm"  ; the entries: the jump table, the effect entries, starting and stopping, the AY output
  INCLUDE "engine-play.asm"  ; the frame: the channels' commands, the notes, the envelopes
  INCLUDE "engine-state.asm"  ; the AY register image and the three channel records

  SAVEBIN "build/sound/engine-c968.bin",$C968,$03BB
