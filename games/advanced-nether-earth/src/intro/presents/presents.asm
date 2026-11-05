; Written by tools/intro_mkpart.py from src/intro/presents/presents.ann; edit the .ann, not the .asm.

  DEVICE ZXSPECTRUM128

; The variables past the loaded image (game.ann @equ)
PresentsShowLines EQU $D4A4  ; the copy routine PresentsBuildShow writes ($D4A4-$E266), entered by falling out of PresentsShow
  ORG $6600
  INCLUDE "presentsmain.asm"  ; "Presents": the word spins and grows in the middle of the screen

  SAVEBIN "presents.bin",$6600,$6EA4
