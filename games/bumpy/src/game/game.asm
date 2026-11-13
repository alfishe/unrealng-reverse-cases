; Bumpy, Loriciels 1989 (Spectrum conversion: Luis Jorge Garcia and J250): TAP block 5, BUMPY.CDE,
; 38700 bytes at $61A8-$F8D3, as the ROM's LD-BYTES leaves it.
; Written by kit/mkgame.py from src/game/game.ann and the recordings; edit game.ann, not the .asm.

  DEVICE ZXSPECTRUM48
  ORG $61A8
  INCLUDE "graphics.asm"  ; The graphics: the CPC mode-1 pictures of the play screen, the ball, the objects and the cells
  INCLUDE "levels.asm"  ; The level data, the cells and the level builder
  INCLUDE "vars.asm"  ; The game's variables: the ball, the cells of the level, the player, the animations
  INCLUDE "setup.asm"  ; Start-up and the start of a game and of each life: players, records, the cheat, the "ready?" screen
  INCLUDE "mainloop.asm"  ; The main loop, the state dispatcher and the keys
  INCLUDE "ball.asm"  ; The ball: the sprite routines, the move states, landing, the burst, falling out and the level end
  INCLUDE "menu.asm"  ; The menu's choice and the controls: the keyboard and the Kempston stick
  INCLUDE "render.asm"  ; The screen: attributes, the side panels, the play area and the CPC-to-Spectrum line table
  INCLUDE "hud.asm"  ; The timer, lives, score, HUD, game over and hall of fame
  INCLUDE "hiscore.asm"  ; Game over, the hall of fame and the return to the menu
  INCLUDE "objects.asm"  ; The objects: hammers, keys, water, bottles and prizes; the score and the exit
  INCLUDE "sprites.asm"  ; The sprite blitters: CPC mode-1 graphics drawn on the Spectrum screen, and their colour cells
  INCLUDE "text.asm"  ; The text printer: control codes, single and double height, the font
  INCLUDE "sound.asm"  ; The sound: beeper effects, their primitives, and the unused 128K and interrupt code

  SAVEBIN "game.bin",$61A8,$972C
