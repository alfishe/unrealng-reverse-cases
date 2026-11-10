; Tujad, Orpheus Ltd / Ariolasoft UK 1986 (Andy Green, Jeff Philips, Stuart J. Ruecroft): the game image $60C0-$FDFF as the stub at $5B00 leaves it.
; Written by kit/mkgame.py from src/game/game.ann and the recordings; edit game.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
KEYBOARD       EQU $02BF  ; the ROM's keyboard scan (LAST_K, FRAMES), called by the interrupt handler
Screen         EQU $4000  ; the display file
Attributes     EQU $5800  ; the screen attributes
ImJump         EQU $5B5B  ; the JP Interrupt the IM 2 table's vector $5B5B jumps through (SetupIM2 writes it)
Im2Table       EQU $FE00  ; the IM 2 vector table: 257 bytes of $5B (SetupIM2), so every vector is $5B5B
SpriteList     EQU $FF01  ; the sprite list: 8-byte records (graphic, flag pointer, width, rows, screen address), a zero word ends it
  ORG $60C0
  INCLUDE "cells.asm"  ; The cell table: one byte for each character cell of the play area
  INCLUDE "start.asm"  ; The entry point and the work space
  INCLUDE "messages.asm"  ; The scroller's messages
  INCLUDE "buffers.asm"  ; The exhaust, the blank graphic, the ED flags and the sprite save buffers
  INCLUDE "droidtables.asm"  ; The droid's frame tables and the animation tables of the sprites
  INCLUDE "main.asm"  ; The start, the main loop, the hazard, the win and the life lost
  INCLUDE "rooms.asm"  ; The room: its record, its drawing, its items and objects
  INCLUDE "input.asm"  ; Reading the controls
  INCLUDE "droid.asm"  ; The droid: moving, the exits, the touch test, the pickups, the teleporter, the turn-round
  INCLUDE "hud.asm"  ; The timers, the pause, the frame wait, the weapons, a new game, the HUD
  INCLUDE "world.asm"  ; The alien map: the room records, dealing the items, resetting the world
  INCLUDE "cellmath.asm"  ; Screen and cell addresses, the wall tests, the attribute and cell fills, the random number
  INCLUDE "steps.asm"  ; One step of an enemy or an object, and the shifts of their graphics
  INCLUDE "sound.asm"  ; The beeper: the sweeps, the pass tick, the teleport
  INCLUDE "objects.asm"  ; The room's objects
  INCLUDE "weapons.asm"  ; The shot of each weapon, and firing
  INCLUDE "menu.asm"  ; The menu, the blits, the text printer and the HUD
  INCLUDE "exhaust.asm"  ; The droid's exhaust flicker
  INCLUDE "progress.asm"  ; The progress screen: the ED picture
  INCLUDE "enemies.asm"  ; The four enemies
  INCLUDE "patrollers.asm"  ; The three patrollers: guards that walk a row through several rooms
  INCLUDE "interrupt.asm"  ; The IM 2 set-up and the interrupt handler: the sprites, the controls, the scroller
  INCLUDE "bitreverse.asm"  ; The bit-reverse table and the unused zero fills around it
  INCLUDE "sprites.asm"  ; The sprite graphics: the droid, the enemies, the weapon-3 probe, the objects, the patrollers, the menu frame
  INCLUDE "roomdata.asm"  ; The world: the room layouts and the alien map

  SAVEBIN "game.bin",$60C0,$9D40
