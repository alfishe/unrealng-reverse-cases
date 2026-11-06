; Trush block 0's contents: the loading screen ($7F58-$9AFF)
; Written by kit/mkgame.py from src/disk/screen.ann and the recordings; edit screen.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; The variables past the loaded image (game.ann @equ)
Screen         EQU $4000  ; the screen's bitmap
Attrs          EQU $5800  ; the attribute file
FadeEnd        EQU $B000  ; one past the last darkened attribute copy (seven 768-byte copies from $9B00)
  ORG $7F58
  INCLUDE "screen.asm"  ; the loading screen and its fade-in

  SAVEBIN "build/disk/screen.bin",$7F58,$1BA8
