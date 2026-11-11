; Battle Command, Ocean 1990: RAM bank 6, paged at $C000, as its tape block loads it.
; Written by kit/mkgame.py from src/bank6/bank6.ann and the recordings; edit bank6.ann, not the .asm.

  DEVICE ZXSPECTRUM128
  SLOT 3
  PAGE 6
  ORG $C000
  INCLUDE "pointer.asm"  ; The mouse pointer: its shapes, the saved background, the save, restore, shift and draw
  INCLUDE "catalogue.asm"  ; The mission catalogue screen: the list of the ten missions from the catalogue, the selection, the description
  INCLUDE "statusview.asm"  ; The Dragonfly title box and the grid position of the status view
  INCLUDE "stores.asm"  ; The stores screen: the weapons catalogue, the four launcher slots, the payload, the turning model
  INCLUDE "numbers.asm"  ; Numbers to decimal digits
  INCLUDE "title.asm"  ; The title menu: the title picture, the turning tank, the three choices
  INCLUDE "password.asm"  ; The level entry: the password screen, the line editor, the coding of the progress
  INCLUDE "briefing.asm"  ; The briefing screen: the notes folder, the mission's text, the map
  INCLUDE "results.asm"  ; The end of a mission, the mission status card and the score
  INCLUDE "panel.asm"  ; The panel jobs of the play views: messages, the damage colours, the attributes, the bars
  INCLUDE "map.asm"  ; The quit prompt and the maps of the status view and the briefing
  INCLUDE "models.asm"  ; The model scripts of the maps (RunScript $990F format) and the markers' points
  INCLUDE "graphics.asm"  ; The menu graphics and the panel icons drawn by CopyGraphic $6D7F and DrawIcon $73E8
  INCLUDE "font.asm"  ; The 8x8 font of PrintString and PrintRawString
  INCLUDE "options.asm"  ; The options screen: the choice of the control device

  SAVEBIN "bank6.bin",$C000,$3A00
