; Rex, Martech Games 1988 (The Light): part 2 (REX 2), $61A8-$FFF9 as the ROM loader leaves it
; (tools/parts.py: side 1 blocks 10 and 12 of orig/Rex.tzx.zip); entry $9470.
; Written by kit/mkgame.py from src/rex2/rex2.ann and the recordings; edit rex2.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; Names that cannot be labels (@alias)
ShadowOffset   EQU $E4FF-$5800  ; the distance from a screen attribute to its cell in the attribute shadow $E4FF (PowerBar adds it); not an address in the sprites
  ORG $61A8
  INCLUDE "graphics.asm"  ; The development link, the graphics and the level data: the font, the characters, the blocks, the room maps and the sprites
  INCLUDE "entry.asm"  ; The entry, a new game, the waits for fire
  INCLUDE "mainloop.asm"  ; The main loop: one pass a frame of play, the keys
  INCLUDE "rex.asm"  ; Rex: the shield, his state and his picture
  INCLUDE "bomb.asm"  ; The smart bomb
  INCLUDE "score.asm"  ; The kills, the score, the lives and the shield figure; the big squidgy thing's explosion and the ending
  INCLUDE "death.asm"  ; Rex's death, the life lost, the game over, the restart points, the sparkle, the objects' dissolve
  INCLUDE "cells.asm"  ; The cells under Rex: ladders, restart markers, the shield recharger, the weapon stations
  INCLUDE "variables.asm"  ; The game's variables
  INCLUDE "hud.asm"  ; The HUD, the text printer, the numbers
  INCLUDE "controls.asm"  ; The controls: the self-modified key readers, the pause
  INCLUDE "grid.asm"  ; The room grid, the animated cells, the drones
  INCLUDE "weapons.asm"  ; The weapons: firing, the bullets, the power level
  INCLUDE "attract.asm"  ; Building a room and the attract mode
  INCLUDE "tables.asm"  ; The tables: the lobbed shot's paths, the shards, the texts, the screen lines, the keys, the mirror and shift tables, the rooms' objects and exits
  INCLUDE "render.asm"  ; The renderer: the back buffer, the sprites, the animated cells
  INCLUDE "panels.asm"  ; The panels: the framed box, the attribute shadow
  INCLUDE "objects.asm"  ; The objects: the enemies, the pods, their moves, their shots, the explosions
  INCLUDE "rooms.asm"  ; The rooms: drawing a room, the exits, the objects made, the spawners
  INCLUDE "rexmove.asm"  ; Rex's moves: walk, jump, fall, the edges of the room
  INCLUDE "collisions.asm"  ; The collisions: shots and objects against Rex, Rex's shots against objects, the pods
  INCLUDE "sound.asm"  ; The sound: the AY effects
  INCLUDE "menu.asm"  ; The title, the menu, the code from part 1, DEFINE KEYS

  SAVEBIN "rex2.bin",$61A8,$9E52
