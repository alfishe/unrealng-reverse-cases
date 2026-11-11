; Earth Shaker, Your Sinclair 1990 (Michael Batty; the issue 63 covertape, March 1991): the game image $6D42-$FFFF as the ROM loader leaves it.
; Written by kit/mkgame.py from src/game/game.ann and the recordings; edit game.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
RomKeyScan     EQU $028E  ; the ROM's KEY-SCAN: E = the key, $FF when none
RomBeeper      EQU $03B5  ; the ROM's BEEPER: HL = the period, DE = the cycles
Screen         EQU $4000  ; the display file
Attributes     EQU $5800  ; the screen attributes
  ORG $6D42
  INCLUDE "hiscore.asm"  ; The high-score table, the name entry, the game-over screen and the scroller
  INCLUDE "music.asm"  ; The tune player and the tunes
  INCLUDE "effects.asm"  ; The beeper effects, the noise loops and the teleport's attribute flash
  INCLUDE "cells.asm"  ; The cell update: gravity, rolling, crushing, the switch, the animation codes
  INCLUDE "renderer.asm"  ; The cell table, the cell graphics and the cave window
  INCLUDE "mapscreen.asm"  ; The map screen (key F): the whole cave as 8 x 8 glyphs
  INCLUDE "main.asm"  ; The game flow: the game's start, the cave start, the play loop, the timer, the cave's ends
  INCLUDE "unpack.asm"  ; The cave unpacker and the cave's set-up
  INCLUDE "hud.asm"  ; The HUD, the score, the time bar, the digits and the texts
  INCLUDE "player.asm"  ; The player: the keys, the moves, digging, pushing, the special cells
  INCLUDE "menu.asm"  ; The menu, the title, the screen wipes
  INCLUDE "password.asm"  ; The password entry and the cave name table
  INCLUDE "keys.asm"  ; The keys: the key table, the redefinition, keyboard or joystick
  INCLUDE "cavedata.asm"  ; The 32 caves

  SAVEBIN "game.bin",$6D42,$92BE
