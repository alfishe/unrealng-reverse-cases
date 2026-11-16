; Enduro Racer, Activision 1987: the loader $FCA3-$FFBF as each byte runs (the plain view; tools/speedlock2.py tape
; enciphers it into the second BASIC's $5EFD-$6219).
; Written by kit/mkgame.py from src/loader/loader.ann and the recordings; edit loader.ann, not the .asm.

  DEVICE ZXSPECTRUM48
  ORG $FCA3
  INCLUDE "loader-module.asm"  ; The SpeedLock 2 loader: two more decoders, the edge loader, its block table

  SAVEBIN "loader.bin",$FCA3,$031D
