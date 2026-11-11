; Battle Command, Ocean 1990: the SpeedLock loader's last piece at $BE5D, the timing check, tape block 37.
; Written by kit/mkgame.py from src/loader/final-be5d.ann and the recordings; edit final-be5d.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; The variables past the loaded image (game.ann @equ)
Bank5Code      EQU $5B00  ; the game's $5B00-$7FFF, loaded XORed with $AD
Bootstrap      EQU $8000  ; the bootstrap (src/game), the last block of the tape
TimeFailed     EQU $BED0  ; non-zero when the timing check failed
  ORG $BE5D
  INCLUDE "final.asm"  ; The loader's end: un-XOR the bank-5 block, jump to the bootstrap

  SAVEBIN "final-be5d.bin",$BE5D,$0073
