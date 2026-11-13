; Rick Dangerous 2, Micro Style 1990: level 3, 21 760 bytes at $A800-$FCFF as the game plays it (the maps'
; last 768 bytes deciphered); tools/mktape.py enciphers them for side B.
; Written by kit/mkgame.py from src/levels/levels.ann and the recordings; edit levels.ann, not the .asm.

  DEVICE ZXSPECTRUM128
  ORG $A800
  INCLUDE "cells.asm"  ; The cells and the blocks: flags, pixels, attributes, 4 x 4 blocks
  INCLUDE "header.asm"  ; The level header, the level number and the sprite frame map
  INCLUDE "maps.asm"  ; The sections' maps: rows of 8 block numbers
  INCLUDE "sections.asm"  ; The section table, the exit lists and the map entry lists
  INCLUDE "kinds.asm"  ; The trap kinds: the kind table, the animation scripts, the paths and the kind records

  SAVEBIN "level3.bin",$A800,$5500
