; Zynaps GS (ZX-Masters 1997, from Zynaps, Hewson Consultants 1987): the game as Trush block 4 carries it, at its
; run addresses ($5C00-$FFFF; $C800-$DFFF not carried, zero), entry $8000. tools/game_image.py; block4.asm takes
; its three parts.
; Written by kit/mkgame.py from src/game/game.ann and the recordings; edit game.ann, not the .asm.

  DEVICE ZXSPECTRUM48
  ORG $5C00
  INCLUDE "tilecopy.asm"  ; The tile set and the sprite glyphs at $5C00-$67FF, where the 48K start-up copies them
  INCLUDE "leveldata.asm"  ; The level data: enemy paths, waves, kinds, the level table and scripts, the scenery
  INCLUDE "effectdata.asm"  ; The sound effects and the sprite descriptors of the ship, the shots and the explosions
  INCLUDE "gamevars.asm"  ; The game variables: the play passes, the scroll, the sound, the current player
  INCLUDE "playerdata.asm"  ; The two player records and the score scratch
  INCLUDE "gameentry.asm"  ; The entry point the loader jumps to
  INCLUDE "systemvars.asm"  ; The level order, the scenery coroutine, the wave launcher and the print variables
  INCLUDE "handlertables.asm"  ; The jump tables of the object kinds, the weapons and the path interpreter, the sine table
  INCLUDE "controldata.asm"  ; The controls, the key names, the life marks, the event table and the level script's state
  INCLUDE "scoredata.asm"  ; The points, the high-score table and the menu colour lists
  INCLUDE "texts.asm"  ; The messages
  INCLUDE "system.asm"  ; Interrupt set-up, random numbers, screen clear and fades
  INCLUDE "playfield.asm"  ; The playfield renderer: attributes, glyph spans, sprite strips and stars, row by row
  INCLUDE "stars.asm"  ; The star field: one star per playfield row
  INCLUDE "scroll.asm"  ; Scrolling: glyph allocation, the column builder and the scroll step
  INCLUDE "levels.asm"  ; The level set-up: the playfield model, the map ring and the per-level counters
  INCLUDE "scenery.asm"  ; The scenery scripts: a coroutine that writes the level's tiles into the map ring
  INCLUDE "sprites.asm"  ; Sprite builders and the per-row sprite strips of the objects
  INCLUDE "objgrid.asm"  ; the free-slot search, the collision grid and the jump-table dispatch
  INCLUDE "waves.asm"  ; the wave launcher and the sprite cache
  INCLUDE "movers.asm"  ; the frame's object loop, the path interpreter and its movement commands
  INCLUDE "objutil.asm"  ; the end of an enemy, the wave bonus, the scenery tests and the playfield clamps
  INCLUDE "player.asm"  ; the player's ship: movement, fuel, fire, hit and death
  INCLUDE "weapons.asm"  ; the side weapons, the pod actions, the sight, the laser shot, the plasma, the missile, the seeker
  INCLUDE "enemies.asm"  ; the enemy handlers: the common enemy, the lockable enemy, the big enemy
  INCLUDE "objects.asm"  ; Enemy fire, explosions, weapon pods and enemy shots
  INCLUDE "print.asm"  ; Print codes, strings, messages and numbers
  INCLUDE "score.asm"  ; Score and lives on the panel
  INCLUDE "menu.asm"  ; Menu screens: the raster colours, the key definition
  INCLUDE "input.asm"  ; The controls: keys, Kempston and Sinclair or cursor joystick
  INCLUDE "options.asm"  ; The selections: one or two players
  INCLUDE "hiscore.asm"  ; The high-score table: rank and initials
  INCLUDE "panel.asm"  ; Panel spinners, saving the panel
  INCLUDE "interrupts.asm"  ; The interrupts: the title, the play passes and their scheduler
  INCLUDE "hud.asm"  ; the frame work of the panel: colour cycles, the speed bar, the fuel gauge
  INCLUDE "events.asm"  ; the event scheduler: one request bit a job, the sprite builds, the pod icon, the score, the effects
  INCLUDE "wavescript.asm"  ; the wave script VM: the level's timeline of waves, scroll stops and checkpoints
  INCLUDE "rounds.asm"  ; the level start, the player records, the title pages
  INCLUDE "mainloop.asm"  ; the game's top loop, the play loop, the end of a life or level, the object set-up
  INCLUDE "effects.asm"  ; the sound effects: requests by priority, a beeper player inside the scheduler
  INCLUDE "tune.asm"  ; the title tune: two detuned square waves, the interrupts off
  INCLUDE "icons.asm"  ; the five icons of the pod selector
  INCLUDE "font.asm"  ; the game's own glyphs for the print codes $80-$B5
  INCLUDE "start.asm"  ; the start-up from the loader
  INCLUDE "buffers.asm"  ; The map ring, the start-up copy's source and the glyph cache
  INCLUDE "graphics.asm"  ; Sprite images
  INCLUDE "records.asm"  ; The row records, the object records and their strip buffers
  INCLUDE "tables.asm"  ; The span node pool, the bit reverse table, the hit grid, the script stack and the interrupt vectors
  INCLUDE "tunedata.asm"  ; the title tune's notes: the periods, the order, the four patterns
  INCLUDE "topcells.asm"  ; the developer switch and the work cells over the ROM font's leftover

  SAVEBIN "game.bin",$5C00,$A400
