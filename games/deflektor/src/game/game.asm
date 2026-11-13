; Deflektor, Gremlin Graphics 1987 (Vortex Software: Costa Panayi): the game $6000-$DFFF as it runs from its entry
; $8382, after the turbo loader, the decryption chain at $7B52 and the mover at $FD00 (src/head, tools/mktape.py).
; Written by kit/mkgame.py from src/game/game.ann and the recordings; edit game.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
Screen         EQU $4000  ; the display file
Attributes     EQU $5800  ; the screen attributes
CharMap        EQU $E000  ; the play area's character map: 20 rows of 32 character codes
MenuAttrs      EQU $E200  ; the options screen's attributes, built over CharMap's end and DrawMarks
DrawMarks      EQU $E300  ; which characters to redraw, laid out like the attributes (2: two passes)
MenuPixels     EQU $E500  ; the options screen's pixels, built over the play buffers
ColourBuffer   EQU $E600  ; the play area's attributes, 20 rows of 32
PixelBuffer    EQU $E900  ; the play area's pixels, 160 rows of 32 bytes
LevelGrid      EQU $FD00  ; the level's cells: 17 bytes a row (15 cells and two guards), the grid proper from $FD23
Im2Jump        EQU $FDFD  ; JP InterruptHandler, where the IM 2 table points
Im2Table       EQU $FE00  ; the IM 2 vector table, 257 bytes of $FD
  ORG $6000
  INCLUDE "menu.asm"  ; The title screen, the options panel, the demo, the practice levels
  INCLUDE "panel.asm"  ; The panel, the score, the COMPUTER messages
  INCLUDE "beam.asm"  ; The beam: the laser, the receiver, the trace
  INCLUDE "mainloop.asm"  ; The main loop: the level's set-up and the pass
  INCLUDE "sound.asm"  ; Sound: the beeper effects, the title tune
  INCLUDE "controls.asm"  ; The controls: keys, joysticks, pause, quit
  INCLUDE "render.asm"  ; The renderer: the grid into characters, the buffers, the copies, the wipes, the printers
  INCLUDE "entry.asm"  ; The entry, the title loop, a new game
  INCLUDE "levels.asm"  ; The level builder
  INCLUDE "elements.asm"  ; The elements: cells, mines, prisms, gremlins, the energy and the overload
  INCLUDE "hiscore.asm"  ; The hall of fame: the rank of a score, the name entry
  INCLUDE "interrupt.asm"  ; The IM 2 set-up and the interrupt handler: the ticks, the COMPUTER line, the beeper effects
  INCLUDE "ending.asm"  ; The ending after level 60

  SAVEBIN "game.bin",$6000,$8000
