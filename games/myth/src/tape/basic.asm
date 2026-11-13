; Myth: History in the Making, System 3 Software 1989: tape block 2, the BASIC program "MYTH" (4514 bytes at PROG $5CCB, LINE 0).
; Written by kit/mkgame.py from src/tape/basic.ann and the recordings; edit basic.ann, not the .asm.

  DEVICE ZXSPECTRUM48
  ORG $5CCB
  INCLUDE "basic-module.asm"  ; The BASIC: one line whose USR enters the machine code after it, and the enciphered chain

  SAVEBIN "basic.bin",$5CCB,$11A2
