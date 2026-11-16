; Enduro Racer, Activision 1987: the game image at its entry $8000 (c1, frame 11646 T 14544), after SpeedLock 2 and its mover.
; Written by kit/mkgame.py from src/game/game.ann and the recordings; edit game.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; Names that cannot be labels (@alias)
RowList        EQU Mover  ; the road's row list $5B00-$5B7F, written over Mover in play
KeyItem        EQU Start  ; after the start: the item MenuSelect is on (also DEFINE KEYS' key being set)
MenuItem       EQU Start+1  ; after the start: the main menu's item
WaitCount      EQU Start+2  ; after the start: WaitKey's count (two bytes, over $8003)
LineBuffer     EQU Start  ; after the start: the sprite routines' line buffer $8000-$80B7
KeyNamesBase   EQU KeyNames-3  ; PrintKeyName's base: KeyNames + 3 * (code - 1)
  ORG $5B00
  INCLUDE "entry.asm"  ; Mover, the entry, the IM 2 table and the 128K test
  INCLUDE "interrupt.asm"  ; The IM 2 handler: its own stack, the repair of the two bytes its push wrote, the sound
  INCLUDE "sound.asm"  ; Sound: the AY tunes, the effects, the engine on the beeper or the AY
  INCLUDE "graphics.asm"  ; The graphics and tables: sprites, the font, the perspective and edge tables, the big digits, the hill profiles, the horizons, the track tables
  INCLUDE "menu.asm"  ; The attract loop, the main menu, the control methods, DEFINE KEYS, the text printer, the keys
  INCLUDE "flow.asm"  ; A game: the players' blocks and turns, a turn's screen, game over, the records, the lap table, the high scores and the name entry
  INCLUDE "render.asm"  ; The back buffer, RowTable, the sprite blitters, the copy to the screen
  INCLUDE "objects.asm"  ; The roadside objects, the riders, the splash and the dust
  INCLUDE "bike.asm"  ; The bike: the controls, the lean and the steering, wheelies, jumps, falls and getting up, the collisions, off the road
  INCLUDE "horizon.asm"  ; The horizons: the stage's picture above the road, rotated sideways on the curves
  INCLUDE "road.asm"  ; The road: its rows from the hills and curves, the drawing of the edges, the ground's dots, the hill table
  INCLUDE "race.asm"  ; A stage: the start, the pass loop, the countdown, the collisions, the HUD, the timer, the stage's end and the finish

  SAVEBIN "game.bin",$5B00,$A500
