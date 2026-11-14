; Rick Dangerous, Firebird 1989 (Core Design): $5B00-$FFFF at the entry $AB4D, as the Bleepload loader leaves it
; (tools/image.py: SkoolKit's simulated load of the original TZX on a 128K; tools/bleepload.py check proves the tape's
; groups give $5E00-$FFFF).
; Written by kit/mkgame.py from src/game/game.ann and the recordings; edit game.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; Constants: addresses outside this image, ROM entries, ports (@const)
CellFlags          EQU $6C00  ; the cell flags: one byte per char cell of the map window, $6C00 + 32 x row + column

; Addresses in other RAM banks (@bank)
AyPlayTune     EQU $C3E4  ; bank 1: the tune start (A = the tune number); the image's $5E00 + $03E4
AyTick         EQU $C46C  ; bank 1: the frame tick; the image's $5E00 + $046C
AyPlayEffect   EQU $C685  ; bank 1: the effect start (A = the effect number); the image's $5E00 + $0685

; Names that cannot be labels (@alias)
AttrTableHigh  EQU DrawAllScan+$12  ; the LD D,n at $A852 inside DrawAllDirtyCells, whose operand LoadScreen sets
  ORG $5B00
  INCLUDE "loader.asm"  ; What the ROM and the loader leave below the game: system variables, the BASIC, the second stage, the AY player
  INCLUDE "screenwork.asm"  ; The end of the cell flags and a graphic slot: work space after the char map
  INCLUDE "charsets.asm"  ; The two char sets: 256 chars of 8 x 8 and their attributes each
  INCLUDE "interrupt.asm"  ; The IM 2 vector table
  INCLUDE "sprites.asm"  ; The 54 sprite frames: 24 x 21 pixels, a mask and pixels, 126 bytes each
  INCLUDE "font.asm"  ; The text font: 43 glyphs of 8 x 8
  INCLUDE "sound.asm"  ; The sound: effects and tunes on the AY player in RAM 1, the 48K beeper effects
  INCLUDE "setup.asm"  ; The start: the 128K test, the player's copy to RAM 1, the interrupt mode, the mirror table
  INCLUDE "controls.asm"  ; The keys and joysticks: the four control methods, the start, pause and quit keys
  INCLUDE "render.asm"  ; The playfield: the char map, the cell flags, the sprite composer and drawers, the redraws and the scrolls
  INCLUDE "hud.asm"  ; The HUD (score, dynamite, bullets, lives), the texts, the title's colours, the level's end
  INCLUDE "levels.asm"  ; The screens of a level: the exits, the load of a screen, the restart point, the map build
  INCLUDE "objects.asm"  ; The object table's scroll
  INCLUDE "leveldata.asm"  ; The level data: maps, tiles, object kinds, zones, exits, object lists, animations, scripts
  INCLUDE "menu.asm"  ; The menu, the control choice, the new game, quit and GAME OVER
  INCLUDE "mainloop.asm"  ; The main loop: one pass every 2 frames
  INCLUDE "text.asm"  ; The texts
  INCLUDE "rick.asm"  ; Rick's bullet and dynamite as objects
  INCLUDE "vars.asm"  ; Rick's state

  SAVEBIN "game.bin",$5B00,$A500
