; Advanced Nether Earth (Eternity Industry, 1998): bank 7 as its HRUM block unpacks it at the boot ($C000-$FFFF).
; $C000-$CE08 is the game starter's own HRUM block (src/disk/starter.asm, packed by src/sfx/blocks.asm with
; INNER, put in by src/images.asm): zero here. $CE09-$FFFF is the boot menu's digitised sample.
; Written by tools/disk_mkgame.py from the annotations (src/disk/bank7.ann) and the recordings; edit the annotations,
; not the .asm.

  DEVICE ZXSPECTRUM48

; the sample: $CE09-$FFFF
  ORG $CE09
  INCLUDE "bank7/sample.asm"  ; the boot menu's digitised sample

  SAVEBIN "d06-c000-bank7.bin",$C000,16384
