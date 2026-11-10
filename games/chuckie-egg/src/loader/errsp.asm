; Chuckie Egg, A'n'F Software 1983 (Nigel Alderton): tape block 3, the headerless two bytes `01 00` that the
; loader $5EF3 loads into the ROM's ERR_SP $5C3D.
; Written by kit/mkgame.py from src/loader/errsp.ann and the recordings; edit errsp.ann, not the .asm.

  DEVICE ZXSPECTRUM48
  ORG $5C3D
  INCLUDE "errsptext.asm"  ; ERR_SP's new value

  SAVEBIN "errsp.bin",$5C3D,$0002
