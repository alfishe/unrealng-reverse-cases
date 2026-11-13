; Rick Dangerous, Firebird 1989: TZX block 2, the BASIC program "Rick" (181 bytes at PROG $5CCB, LINE 10): it
; clears to 50000, prints the title and loads and runs Rick1 at $CD00.
; Written by kit/mkgame.py from src/tape/basic.ann and the recordings; edit basic.ann, not the .asm.

  DEVICE ZXSPECTRUM128
  ORG $5CCB
  INCLUDE "basic-module.asm"  ; The BASIC "Rick": the title, then LOAD "Rick1" CODE 52480 and RANDOMIZE USR 52480

  SAVEBIN "basic.bin",$5CCB,$00B5
