; Elite, Firebird / Torus 1985: the Lenslok check, $C000-$C7FF as the decryptor leaves it (the kickoff copies the game over it after the check; docs/lenslok.md)
; Written by kit/mkgame.py from src/lenslok/lenslok.ann and the recordings; edit lenslok.ann, not the .asm.

  DEVICE ZXSPECTRUM48
  ORG $C000
  INCLUDE "check.asm"  ; The Lenslok check: the size screen, the scrambled code, the answer

  SAVEBIN "lenslok.bin",$C000,$0800
