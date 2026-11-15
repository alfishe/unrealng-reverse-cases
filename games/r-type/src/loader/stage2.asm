; R-Type, Electric Dreams Software 1988: the SpeedLock reader's second stage at $FEE8-$FFCF, tape block 7.
; Written by kit/mkgame.py from src/loader/stage2.ann and the recordings; edit stage2.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
SL7Start       EQU $FB7E
SL7WipeTrap    EQU $FBCB
SL7LoadBlock   EQU $FCF6
SL7StorePtr    EQU $FDB1  ; the store hook's address in the reader's bit loop
SL7StoreHook   EQU $FDB3
SL7Pattern     EQU $FEB3
  ORG $FEE8
  INCLUDE "stage2-module.asm"  ; The second stage

  SAVEBIN "stage2.bin",$FEE8,$00E8
