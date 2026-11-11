; Battle Command, Ocean 1990: the SpeedLock loader's second stage, tape block 7, run at $BF0D.
; Written by kit/mkgame.py from src/loader/stage2.ann and the recordings; edit stage2.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; The variables past the loaded image (game.ann @equ)
Screen         EQU $4000  ; the bitmap, block 13 loads straight into it
AttrFlag       EQU $82FF  ; zeroed here: the reveal task tests it
WaitTask       EQU $BBF4  ; the edge loop's task
LoadBlocks     EQU $BD13  ; the block reader (src/loader/chain.asm)
LastStoreJump  EQU $BDCE  ; the operand of LoadBlocks' JP after the bytes: where the last byte goes
StoreLast      EQU $BDD0  ; the last-byte store
TimeFailed     EQU $BED0  ; non-zero when the timing check failed
  ORG $BF0D
  INCLUDE "stage2-module.asm"  ; The second stage: the screen, the keys, the table, the banks

  SAVEBIN "stage2.bin",$BF0D,$00C3
