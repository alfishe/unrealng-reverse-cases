; R-Type, Electric Dreams Software 1988: the tail at $61A8 (blocks 33 and 35), tape block 33 (47 bytes).
; Written by kit/mkgame.py from src/loader/pieces.ann and the recordings; edit pieces.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
GameEntry      EQU $85FD  ; the game's entry (src/game: Entry)
SL7WipeTrap    EQU $FBCB
SL7Pattern     EQU $FEB3
  ORG $61A8
  INCLUDE "tail-module.asm"  ; The tail (TZX blocks 33 and 35)

  SAVEBIN "tail.bin",$61A8,$002F
