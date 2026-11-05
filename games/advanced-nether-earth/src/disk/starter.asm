; Advanced Nether Earth (Eternity Industry, 1998): the game starter and its title picture, $9C40-$B78F: bank 7's first
; part, HRUM-packed at bank 7 $C000; the boot program's key 1 ($61C4) copies the block to $9C40 and calls it.
; Written by tools/disk_mkgame.py from the annotations (src/disk/starter.ann) and the recordings; edit the annotations,
; not the .asm.

  DEVICE ZXSPECTRUM48

; the starter's picture: $9C40-$B78F
  ORG $9C40
  INCLUDE "starter/starter.asm"  ; the game starter: the title picture shown in, then the game

  SAVEBIN "d07-9c40.bin",$9C40,6992
