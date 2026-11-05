; Written by tools/intro_mkpart.py from src/intro/scroller/scroller.ann; edit the .ann, not the .asm.

  DEVICE ZXSPECTRUM128

; The variables past the loaded image (game.ann @equ)
LoaderHook     EQU $618A  ; the three NOPs after CALL PlayerFrame in LoaderInterrupt (src/loader.asm): a CALL here runs every frame after the tune
  ORG $6600
  INCLUDE "star.asm"  ; the burning star: its points, its lines, the flames, the picture on the screen
  INCLUDE "text.asm"  ; the text: typed down the screen's right columns, held, wiped
  INCLUDE "tables.asm"  ; the tables and pictures the star and the text read
  INCLUDE "init.asm"  ; the tables built once at the start, in bank 0

  SAVEBIN "scroller.bin",$6600,$9A00
