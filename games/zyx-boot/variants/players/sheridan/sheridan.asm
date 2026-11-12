; ZYX boot variants: Ian Sheridan's music driver (zyxboot-12) at $C000 (tools/variants_music.py).
; Written by kit/mkgame.py from variants/players/sheridan/sheridan.ann; edit sheridan.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
DurationTables EQU $C7E0  ; the tune: rows of 8 frame counts
Instruments    EQU $C821  ; 35-byte instrument records
PatternTable   EQU $C97F  ; the patterns' addresses
SongTable      EQU $C997  ; 6 bytes a song: the three sequences
  ORG $C000
  INCLUDE "sheridan-module.asm"  ; Ian Sheridan's driver: init, play, the sequences and patterns, the ADSR envelope, arpeggio, vibrato, fades

  SAVEBIN "sheridan.bin",$C000,$07E0
