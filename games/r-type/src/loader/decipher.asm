; R-Type, Electric Dreams Software 1988: Decipher at $FE40 and the bytes after it, tape block 29 (115 bytes).
; Written by kit/mkgame.py from src/loader/pieces.ann and the recordings; edit pieces.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
GameEntry      EQU $85FD  ; the game's entry (src/game: Entry)
SL7WipeTrap    EQU $FBCB
SL7Pattern     EQU $FEB3
  ORG $FE40
  INCLUDE "decipher-module.asm"  ; Decipher (TZX block 29)

  SAVEBIN "decipher.bin",$FE40,$0073
