; R-Type, Electric Dreams Software 1988: the reader's second table over $FF49, tape block 23 (55 bytes).
; Written by kit/mkgame.py from src/loader/pieces.ann and the recordings; edit pieces.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
GameEntry      EQU $85FD  ; the game's entry (src/game: Entry)
SL7WipeTrap    EQU $FBCB
SL7Pattern     EQU $FEB3
  ORG $FF49
  INCLUDE "table2-module.asm"  ; The second block table (TZX block 23)

  SAVEBIN "table2.bin",$FF49,$0037
