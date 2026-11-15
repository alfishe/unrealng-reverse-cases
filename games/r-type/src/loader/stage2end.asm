; R-Type, Electric Dreams Software 1988: the second stage's new end at $FEFC, tape block 31 (49 bytes).
; Written by kit/mkgame.py from src/loader/pieces.ann and the recordings; edit pieces.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
GameEntry      EQU $85FD  ; the game's entry (src/game: Entry)
SL7WipeTrap    EQU $FBCB
SL7Pattern     EQU $FEB3
  ORG $FEFC
  INCLUDE "stage2end-module.asm"  ; Stage2End (TZX block 31)

  SAVEBIN "stage2end.bin",$FEFC,$0031
