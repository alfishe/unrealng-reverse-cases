; MASK III: VENOM Strikes Back, Gremlin Graphics 1988: TZX block 2, the BASIC program "MASK3" (36 bytes at PROG
; $5CCB, LINE 0): CLEAR 24570, LOAD "" CODE (the loader at $FF00) and RANDOMIZE USR 65280.
; Written by kit/mkgame.py from src/tape/basic.ann; edit basic.ann, not the .asm.

  DEVICE ZXSPECTRUM48
  ORG $5CCB
  INCLUDE "basic-module.asm"  ; The BASIC: line 10, CLEAR 24570, load the loader, run it

  SAVEBIN "basic.bin",$5CCB,$0024
