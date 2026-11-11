; Battle Command, Ocean 1990: the SpeedLock loader's last piece at $BF21, the stage's new end, tape block 39.
; Written by kit/mkgame.py from src/loader/final.ann and the recordings; edit final.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; The variables past the loaded image (game.ann @equ)
Bank5Code      EQU $5B00  ; the game's $5B00-$7FFF, loaded XORed with $AD
Bootstrap      EQU $8000  ; the bootstrap (src/game), the last block of the tape
TimeFailed     EQU $BED0  ; non-zero when the timing check failed
  ORG $BF21
  INCLUDE "timeend.asm"  ; The stage's new end at $BF21

  SAVEBIN "final-bf21.bin",$BF21,$000F
