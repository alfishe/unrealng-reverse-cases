; Elite, Firebird / Torus 1985 (Side A, Krait): the game image as the Softlock loader and the kickoff at $D07F leave it ($5B00-$FFA7, entry $70E0).
; Written by kit/mkgame.py from src/game/game.ann and the recordings; edit game.ann, not the .asm.

  DEVICE ZXSPECTRUM48
  ORG $5B00
  INCLUDE "lowdata.asm"  ; The low data: the scanner and dashboard save areas, the font, the ship slots and the ship blueprints
  INCLUDE "startup.asm"  ; The vectors, the flight variables, the start, the pause menu and the title
  INCLUDE "flightloop.asm"  ; The flight loop, the sun and the planet on screen, the division
  INCLUDE "stardust.asm"  ; The stardust: 16 moving dots in the space views, and the in-system jump
  INCLUDE "backbuffer.asm"  ; The back buffer, the dashboard save and restore, the choice of view or screen
  INCLUDE "dashboard.asm"  ; The dashboard: the distances to the sun and the planet, the compass, the bars
  INCLUDE "circles.asm"  ; The circles: the sun filled, the planet outlined, the chart's range circle, the hit flashes
  INCLUDE "tunnel.asm"  ; The ring tunnel of the launch, the dock and the hyperspace jump; the launch and dock sequences
  INCLUDE "sound.asm"  ; The beeper: the effects of the scenes, the background requests and the three generators
  INCLUDE "scanner.asm"  ; The scanner, the condition light, the energy and the shields, the missile
  INCLUDE "shipmotion.asm"  ; The escape pod, the vectors, the ship loop and the motion: rotation, movement, tidying
  INCLUDE "tactics.asm"  ; The title's ship and the ships' tactics: energy, launches, fleeing, the missile's homing, steering and firing
  INCLUDE "drawships.asm"  ; Drawing a ship: the view's axes, the dot of a far ship, the vertices projected, the visible edges, the laser beams
  INCLUDE "linedraw.asm"  ; Lines in the 3D view: clipping to the 256 x 128 window, the octant, and four patched Bresenham loops
  INCLUDE "combat.asm"  ; Collisions and scooping, the player's laser and the gunsight, the ECM, the ship actions and spawning, face visibility
  INCLUDE "squaretable.asm"  ; The table of squares and the back buffer
  INCLUDE "gamestate.asm"  ; The screen table and the vectors, the commander record, the dashboard messages, the full-page messages, cash, legal status and cargo
  INCLUDE "textprint.asm"  ; Numbers, cash, the two token sets, the character printer, rules and bars, the random synonyms
  INCLUDE "commander.asm"  ; The commander menu (load and save on tape, the security number), the view names and the message line
  INCLUDE "hyperspace.asm"  ; The jump keys, the countdown, the arrival in a new system or in witch space, the galactic jump, the three missions' triggers
  INCLUDE "galaxy.asm"  ; The galaxy's 256 systems from three seed words: the twist, the nearest system, the distance, the names, the system data and the market
  INCLUDE "menuhelpers.asm"  ; The screens' helpers: the click, the key waits, the cursor moves, the market rows, the units, the line editor and the planet name prompt
  INCLUDE "chartcursor.asm"  ; The charts' crosses: the cursor's cross placed and drawn with XOR, the cursor keys' moves
  INCLUDE "market.asm"  ; Buying and selling cargo and equipment: the quantity editor, the checks and the undo, the nova's refugees
  INCLUDE "dockedscreens.asm"  ; The docked screens of ScreenTable: the galactic and the short range charts, the data on a system, the market prices, the status and the inventory
  INCLUDE "keyboard.asm"  ; The text tables, the key bytes, the keyboard scan, the joysticks, the steering accumulators and the IM2 interrupt

  SAVEBIN "game.bin",$5B00,$A4A8
