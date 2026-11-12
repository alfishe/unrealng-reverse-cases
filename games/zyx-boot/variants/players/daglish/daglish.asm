; ZYX boot variants: Ben Daglish's music driver (zyxrover) at $BFFE (tools/variants_music.py).
; Written by kit/mkgame.py from variants/players/daglish/daglish.ann; edit daglish.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
PatternLow     EQU $CB83  ; the patterns' addresses, low bytes (the tune)
PatternHigh    EQU $CBB7  ; the patterns' addresses, high bytes
SongTable      EQU $CBEB  ; 6 bytes a song: the three sequences
Instruments    EQU $CD72  ; 10-byte instrument records; a channel's slots hold offsets from here
EffectRecords  EQU $CE4A  ; 13-byte sound effect records: an instrument, a period, a duration
  ORG $BFFE
  INCLUDE "daglish-module.asm"  ; Ben Daglish's driver: init, play, sequences and patterns, instruments (ADSR, vibrato), pitch tables

  SAVEBIN "daglish.bin",$BFFE,$06D1
