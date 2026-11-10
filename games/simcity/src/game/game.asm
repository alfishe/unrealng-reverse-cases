; SimCity, Infogrames 1990 (Probe Software: A. R. Lill, S. Butler; a licence of Maxis' SimCity):
; the game image $5B00-$FE00 at the entry `$5B1B`, as the tape's loader leaves it (tools/image.py): code2 $5B00-$6AFF
; (tape block 7, moved from $4000 by src/mover) and code1 $6B00-$FE00 (tape block 6).
; Written by kit/mkgame.py from src/game/game.ann and the recordings; edit game.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; Constants: addresses outside this image, ROM entries, ports (@const)
RomFont            EQU $3C00  ; the ROM's character set less 256 (character n at RomFont + 8 n)

; The variables past the loaded image (game.ann @equ)
RomSaBytesOut  EQU $04C6  ; the ROM's SA-BYTES after its header choice (the pilot, $04C6), used by the save
RomLdBytesIn   EQU $0562  ; the ROM's LD-BYTES after its border set-up (LD-BYTES + 12), used by the save and load
Screen         EQU $4000  ; the display file
Attributes     EQU $5800  ; the attributes
  ORG $5B00
  INCLUDE "entry.asm"  ; The keyboard rows and the entry
  INCLUDE "beeper.asm"  ; The two beeper routines: the disaster noise and the refusal tone
  INCLUDE "input.asm"  ; The Kempston flag and the key scans
  INCLUDE "screen.asm"  ; Screen addresses, icon drawing and clearing
  INCLUDE "random.asm"  ; The random generator
  INCLUDE "cursor.asm"  ; The pointer and the map box
  INCLUDE "print.asm"  ; Printing: characters, inline codes, numbers, frames, the status panel and the texts
  INCLUDE "clicks.asm"  ; The pointer's movement and the clicks
  INCLUDE "renderer.asm"  ; The map view renderer
  INCLUDE "arith.asm"  ; The number printers and the arithmetic
  INCLUDE "menus.asm"  ; The menus and dialogs engine
  INCLUDE "landscape.asm"  ; The landscape generator
  INCLUDE "tools.asm"  ; The tools: palette, prices, sites, networks, bridges, the bulldozer and the buildings
  INCLUDE "cityaccess.asm"  ; The city's arrays and cell helpers
  INCLUDE "movers.asm"  ; The moving objects: the train, the plane, the tornado; the meltdown
  INCLUDE "joysticks.asm"  ; The Kempston and Sinclair joysticks, the shift scroll
  INCLUDE "maps.asm"  ; The maps window
  INCLUDE "simulation.asm"  ; The simulation task: power, coverage, pollution, traffic, land value, crime, demand and the growth of every zone
  INCLUDE "uitask.asm"  ; The UI task
  INCLUDE "disasters.asm"  ; The disasters
  INCLUDE "budget.asm"  ; The budget
  INCLUDE "evaluation.asm"  ; The evaluation and the advice
  INCLUDE "overview.asm"  ; The maps window's overview
  INCLUDE "saveload.asm"  ; Save and load
  INCLUDE "dialogs.asm"  ; The menus' descriptions and actions, the line editor
  INCLUDE "workspace.asm"  ; The movers' sprites and the work space
  INCLUDE "graphics.asm"  ; The tiles and their attributes
  INCLUDE "tasks.asm"  ; The task switcher
  INCLUDE "system.asm"  ; Printing glyphs, the input read, the tape, the UI stack and the IM 2 vector

  SAVEBIN "game.bin",$5B00,$A301
