; R-Type, Electric Dreams Software 1988: the BASIC's enciphered tail in its plain view, $EC00-$FEE7: the layers of the
; decryption chain as each one runs, then the SpeedLock 7 reader as the last layer leaves it.
; tools/speedlock7.py masters these bytes back into the tape's (src/tape/basic.asm INCBINs the result).
; Written by kit/mkgame.py from src/loader/chain.ann and the recordings; edit chain.ann, not the .asm.

  DEVICE ZXSPECTRUM48
  ORG $EC00
  INCLUDE "chain-module.asm"  ; The decryption chain and the SpeedLock 7 reader

  SAVEBIN "chain.bin",$EC00,$12E8
