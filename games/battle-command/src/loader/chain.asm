; Battle Command, Ocean 1990: the BASIC's enciphered tail in its plain view, $AC38-$BF0C. The 104 layers of
; the decryption chain as each one runs, then the SpeedLock 7 loader as the last layer leaves it.
; tools/speedlock.py masters these bytes back into the tape's (src/tape/basic.asm INCBINs the result).
; Written by kit/mkgame.py from src/loader/chain.ann and the recordings; edit chain.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; The variables past the loaded image (game.ann @equ)
Attributes     EQU $5800  ; the attributes
AttrBuffer     EQU $8000  ; the loading screen's attributes as block 15 loads them, copied to the screen in steps
TimeBuffer     EQU $9000  ; the edge counts TimeCheck measures
Stage2         EQU $BF0D  ; the loader's second stage (src/loader/stage2.asm)
BlockTable     EQU $BF30  ; the block table, five bytes a row (src/loader/stage2.asm)
  ORG $AC38
  INCLUDE "chain-module.asm"  ; The decryption chain: 103 layers, each rewriting the rest and running into it
  INCLUDE "loader.asm"  ; The SpeedLock 7 loader: the notice, the block reader, the stage at $BF0D

  SAVEBIN "chain.bin",$AC38,$12D5
