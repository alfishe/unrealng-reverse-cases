; Rex, Martech Games 1988 (The Light): part 1 (REX 1), $6018-$FFF9 as the ROM loader leaves it
; (tools/parts.py: side 1 blocks 4 and 6 of orig/Rex.tzx.zip); entry $947A.
; Written by kit/mkgame.py from src/game/game.ann and the recordings; edit game.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; Names that cannot be labels (@alias)
ShadowOffset   EQU $E4FF-$5800  ; the distance from a screen attribute to its cell in the attribute shadow $E4FF (PowerBar adds it); not an address in the sprites
  ORG $6018
  INCLUDE "graphics.asm"  ; The graphics and the level data: the font, the characters, the blocks, the room maps and the sprites
  INCLUDE "entry.asm"  ; The entry, a new game, the waits for fire
  INCLUDE "mainloop.asm"  ; The main loop: one pass a frame of play, the keys
  INCLUDE "rex.asm"  ; Rex: the shield, his state and his picture
  INCLUDE "bomb.asm"  ; The smart bomb
  INCLUDE "score.asm"  ; The kills, the score, the lives and the shield figure
  INCLUDE "death.asm"  ; Rex's death, the life lost, the game over, the restart points, the sparkle
  INCLUDE "cells.asm"  ; The cells under Rex: ladders, restart markers, the shield recharger, the weapon stations
  INCLUDE "variables.asm"  ; The game's variables
  INCLUDE "hud.asm"  ; The HUD, the text printer, the numbers
  INCLUDE "controls.asm"  ; The controls: the self-modified key readers, the pause
  INCLUDE "grid.asm"  ; The room grid, the animated cells, the drones
  INCLUDE "weapons.asm"  ; The weapons: firing, the bullets, the power level
  INCLUDE "codepanel.asm"  ; The end of part 1: the access code for part 2
  INCLUDE "tables.asm"  ; The tables: bullet paths, key names, the scripted spawn, the shards, the texts, the screen lines, the mirror and shift tables, the rooms' objects and exits
  INCLUDE "render.asm"  ; The renderer: the back buffer, the sprites, the animated cells
  INCLUDE "objects.asm"  ; The objects: the enemies, the pods, their moves, their shots, the explosions
  INCLUDE "rooms.asm"  ; The rooms: drawing a room, the exits, the objects made, the spawners
  INCLUDE "panels.asm"  ; The panels: the framed box, the attribute shadow
  INCLUDE "rexmove.asm"  ; Rex's moves: walk, jump, fall, the edges of the room
  INCLUDE "collisions.asm"  ; The collisions: shots and objects against Rex, Rex's shots against objects, the pods
  INCLUDE "sound.asm"  ; The sound: the AY effects
  INCLUDE "menu.asm"  ; The title, the menu, DEFINE KEYS, the roll call

  SAVEBIN "game.bin",$6018,$9FE2
