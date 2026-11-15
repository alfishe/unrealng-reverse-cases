; R-Type, Electric Dreams Software 1988: $7000-$FFFF as the SpeedLock loader leaves it at the entry $85FD
; (c1 frame 11700 T 1379, tools/ttd_dump.py -> work/stage1/images/entry.cpu.bin); level 1 not yet loaded.
; Written by kit/mkgame.py from src/game/game.ann and the recordings; edit game.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
EntryCopy      EQU $5B64  ; 414 bytes copied from EntryCopySource at the entry; the copy ends at $5D01, two bytes into BitReverse, which the entry built just before: $5D01 holds $00 instead of $80 (1 reversed)
BitReverse     EQU $5D00  ; each byte with its bits reversed, built at the entry: the mirrored metatiles and sprites, the cursor keys
ColumnBuffer   EQU $5E00  ; the column the scroll brings in at the right: 20 cells of 9 bytes, cut by the metatile drawers
ShipShots      EQU $5EB4  ; the ship's shots, 3 bytes each (kind, column, row): MoveShipShots
MissileA       EQU $5F00  ; missile record A (MoveMissileSet)
MissileB       EQU $5F34  ; missile record B (MoveMissileSet)
MissileC       EQU $5F68  ; missile record C (MoveMissileSet)
Explosions     EQU $5FC1  ; the explosions, 3 bytes each (frame and kind, column, row): DrawExplosions
  ORG $7000
  INCLUDE "texts.asm"  ; Texts and small tables in the pixel shadow's spare halves
  INCLUDE "titlestate.asm"  ; The star task's switches and the Kempston probe
  INCLUDE "screen.asm"  ; Screen helpers: the sides, the high-score table, the title colours
  INCLUDE "vars.asm"  ; The variables, the font and the high-score table
  INCLUDE "intro.asm"  ; The loading screen scroller
  INCLUDE "main.asm"  ; The entry, the main loop and the start of a life
  INCLUDE "scroll.asm"  ; The scroll: map, metatiles, the shadow and the column buffer
  INCLUDE "sprites.asm"  ; The sprite drawers and the cell map
  INCLUDE "tapeload.asm"  ; The level loader's tape reader
  INCLUDE "waves.asm"  ; The attack waves: the wave script, the enemy slots and their movers
  INCLUDE "ship.asm"  ; The ship, the Force, the bits, the pick-ups, the shots, the beam and the missiles
  INCLUDE "graphics.asm"  ; The game's graphics: sprites and the object table
  INCLUDE "interrupt.asm"  ; The interrupt and its task table, the stars, the keys and the control choice
  INCLUDE "util.asm"  ; Text, cells, the score and the boss
  INCLUDE "levelspace.asm"  ; The level space: what the loader left where each level is loaded
  INCLUDE "sound.asm"  ; The beeper sound: three channels run by the interrupt tasks
  INCLUDE "tail.asm"  ; The extra life, the waits and fills, the level loader, the first screen

  SAVEBIN "game.bin",$7000,$9000
