; Written by tools/intro_mkpart.py from src/intro/title/title.ann; edit the .ann, not the .asm.

  DEVICE ZXSPECTRUM128
  ORG $9C40
  INCLUDE "titlepic.asm"  ; the title picture: a relocatable screen depacker and its packed screen

  SAVEBIN "title.bin",$9C40,$0D00
