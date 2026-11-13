; Rick Dangerous 2, Micro Style 1990 (Core Design): the game $7080-$A7FF, side A block 6's bytes $1080-$47FF as the
; loader leaves them (the bit-reversed block put back in order by tools/image.py); the music before it and level 1
; after it are parts of their own (src/music, src/levels).
; Written by kit/mkgame.py from src/game/game.ann and the recordings; edit game.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; The variables past the loaded image (game.ann @equ)
Screen         EQU $4000  ; the screen bitmap; row 0 is the HUD, rows 1-23 the view
ScreenAttrs    EQU $5800  ; the screen attributes
SpareCells     EQU $5DE8  ; the composed cells: spare cell n at SpareCells + 8 x (n + 1), n = 2... (SpareCount $77B0)
MusicImage     EQU $6000  ; the AY music as loaded, copied to RAM 1 at $C000 on a 128K
MirrorTable    EQU $6500  ; the 256 bytes bit-reversed: a mirrored sprite's bytes go through it
DirtyMap       EQU $6600  ; a byte per view cell, 32 x 40, row 8 = screen row 0: 0 nothing to do, 1 restore the level cell, n >= 2 show spare cell n; $6A00 = $FF ends the scan
ViewCells      EQU $6B00  ; the view's cell numbers, 32 x 44 (the map builder), row 8 = screen row 0; DirtyMap + $500
CellFlags      EQU $A800  ; a flag byte per cell (bit 1 solid, bit 2 floor, bit 5 deadly to the bomb; bit 7 the composer)
CellGraphics   EQU $A900  ; 256 cells of 8 bytes
CellAttrs      EQU $B100  ; a cell's attribute
Blocks         EQU $B200  ; 256 blocks of 4 x 4 cell numbers
PageC000       EQU $C000  ; the first byte of the $C000 page: the 128K test byte, the music's destination in RAM 1
LevelHeader    EQU $C200  ; +0 the address of the level's object kind table (11-byte records), +2 the section table's, +4 the maps' base
LevelHookA     EQU $C206  ; level 5: JP $F7E6, run in place of the map entry scan while LevelHookOn is set
LevelHookB     EQU $C209  ; level 5: JP $F8D0
LevelNumber    EQU $C20C  ; the level in memory, 1-5
SpriteFrameMap EQU $C20E  ; a byte per animation frame 1-$7F: the sprite number, bit 7 mirrored, $7F none
Sprites        EQU $C26D  ; the level's sprites, 128 bytes each (sprites 0-24 Rick, his shots and the blast in every level)
Im2Table       EQU $FD00  ; the IM 2 vector table, every byte $FE
Im2Handler     EQU $FEFE  ; the IM 2 handler, copied from Im2HandlerSource

; Addresses in other RAM banks (@bank)
MusicPlaying   EQU $C9CF  ; bank 1: a tune runs
MusicStartTune EQU $CA27  ; bank 1: start tune A
MusicFrame     EQU $CAAF  ; bank 1: the player, once a frame
MusicEffect    EQU $CCC8  ; bank 1: start effect A
  ORG $7080
  INCLUDE "hud.asm"  ; The HUD and the glyphs: score, detonators, ammunition, lives
  INCLUDE "controls.asm"  ; The controls: the keyboard, Kempston, cursor and Sinclair joysticks, pause, quit and the cheat keys
  INCLUDE "render.asm"  ; The renderer: the sprite composer, the cell drawers, the scroll and the attributes
  INCLUDE "interrupt.asm"  ; The frame counter and wait, the RAM 1 calls (the music and its effects)
  INCLUDE "sound.asm"  ; The 48K beeper effects
  INCLUDE "setup.asm"  ; The entry code: the 128K test, the music copy to RAM 1, the IM 2 set-up, the mirror table
  INCLUDE "mainloop.asm"  ; The new game, the level start, the main loop and GAME OVER
  INCLUDE "ending.asm"  ; GAME OVER's text
  INCLUDE "score.asm"  ; The score: the points records, the score digits, AddScore
  INCLUDE "menu.asm"  ; The control and level menus, the cheat flags, the falling letters
  INCLUDE "level.asm"  ; The sections' objects reset at a new game
  INCLUDE "objects.asm"  ; The two object tables over the entry code
  INCLUDE "levelload.asm"  ; The tape level loader
  INCLUDE "enemies.asm"  ; The enemy's hit test
  INCLUDE "collision.asm"  ; Hit tests: points and boxes against boxes, the bullet's wall probe, the bomb's ground probe
  INCLUDE "rick.asm"  ; Rick: the body box tests, walk, jump, crawl, climb, the ride, the special surfaces, death
  INCLUDE "weapons.asm"  ; The gun and its bullet, the detonator and its blast, the punch
  INCLUDE "traps.asm"  ; The traps and pickups: paths, animations, the deadly touch, triggers, the three pickups

  SAVEBIN "game.bin",$7080,$3780
