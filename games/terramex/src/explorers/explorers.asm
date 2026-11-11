; Terramex, Grandslam 1987: TZX block 4 $9CF8-$F6F7, the five explorer data sets of $1200 bytes, which the
; selector copies to $6000-$71FF for the explorer chosen (on the 128K from RAM 4 and 3).
; Written by kit/mkgame.py from src/explorers/explorers.ann; edit explorers.ann, not the .asm.

  DEVICE ZXSPECTRUM128
  ORG $9CF8
  INCLUDE "explorers-module.asm"  ; The five explorers' sprite sets

  SAVEBIN "explorers.bin",$9CF8,$5A00
