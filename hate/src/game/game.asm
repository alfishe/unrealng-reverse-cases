; H.A.T.E. (Hostile All Terrain Encounter), Vortex Software 1989: the game image $5FB4-$FFFF as the depacker
; leaves it. Written by tools/mkgame.py from src/game/game.ann and the recordings; edit game.ann, not the .asm.
; sjasmplus -I<src> game.asm gives game.bin, byte for byte the original (tools/build.sh packs it into the tape).
; The resources (INCBIN "res/...") are the files of src/res, listed in src/res/README.md.

  DEVICE ZXSPECTRUM48
  ORG $5FB4
  INCLUDE "buffers.asm"
  INCLUDE "titleplayer.asm"
  INCLUDE "startup.asm"
  INCLUDE "gamedata.asm"
  INCLUDE "course.asm"
  INCLUDE "mainloop.asm"
  INCLUDE "roundsetup.asm"
  INCLUDE "scroller.asm"
  INCLUDE "sprites.asm"
  INCLUDE "shadows.asm"
  INCLUDE "mover.asm"
  INCLUDE "player.asm"
  INCLUDE "statics.asm"
  INCLUDE "hits.asm"
  INCLUDE "hud.asm"
  INCLUDE "objview.asm"
  INCLUDE "menu.asm"
  INCLUDE "coursedata.asm"

  SAVEBIN "game.bin",$5FB4,$A04C
