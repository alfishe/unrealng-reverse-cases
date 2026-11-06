; Nether Earth GS, Tron Z 2002 (tape: Hood 2017): the game in play, banks 5, 2 and 0 as the CPU sees them. The
; file neart001 is $6590-$FFFF; entry Start $A600. The GS driver lives in another RAM page at $C000 (GsDriver):
; bank 1 on the disk (src/disk/driver.asm), bank 6 on Hood's tape (src/tape/driver.asm).
;
; One source, two targets: assembled as is it gives the disk's neart001; with -DHOOD_TAPE it gives the tape's,
; which differs in the driver's page and in the ROM entry of the game's tape save (tools/build_game.sh).
  IFDEF HOOD_TAPE
DriverBank     EQU 6       ; Hood's tape: the driver in RAM bank 6
SaveBytesEntry EQU $04C2   ; ROM SA-BYTES from its start: the ROM's own pilot length and its SA/LD-RET exit
  ELSE
DriverBank     EQU 1       ; the disk: the driver in RAM bank 1
SaveBytesEntry EQU $04D0   ; ROM SA-BYTES past its pilot choice: the game's short pilot (HL) and no SA/LD-RET
  ENDIF
PageRom48      EQU $10     ; port $7FFD: bit 4 the 48 BASIC ROM, bits 0-2 the RAM bank at $C000
; Written by kit/mkgame.py from src/game/game.ann and the recordings; edit game.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; The variables past the loaded image (game.ann @equ)
ViewBuffer     EQU $5B00  ; the view's back buffer $5B00-$677F: its first 2704 bytes lie below the file (ViewBufferTail holds the rest); the loader neart022 at $61A8-$6508 is inside it and is wiped by the first ClearViewBuffer

; Addresses in other RAM banks (@bank)
GsDriver       EQU $C000  ; bank DriverBank: the GS driver: A = the game's sound id (src/disk/driver.asm, src/tape/driver.asm)

; Names that cannot be labels (@alias)
Handler        EQU ImJump+1  ; the interrupt handler: the operand of the JP at $FDFD, the IM 2 vector
  ORG $6590
  INCLUDE "viewbuffer.asm"  ; The tail of the view's back buffer, $6590-$677F: the first bytes of the file
  INCLUDE "font.asm"  ; The character set: 64 glyphs of 8 x 8 pixels, codes $20-$5F
  INCLUDE "sprites.asm"  ; The 89 sprite blocks: the ship, the map objects, the robot parts, the buildings' signs, the shots
  INCLUDE "gssound.asm"  ; The bridge to the General Sound driver: page the driver in, call it, page bank 0 back
  INCLUDE "start.asm"  ; the start-up, the new game set-up and the play loop
  INCLUDE "robotmenu.asm"  ; the robot menu and its submenus: orders, distance, targets, combat, direct control
  INCLUDE "gameturn.asm"  ; the game turn: the clock, daily production, capture, the game end and the turn pacing
  INCLUDE "ship.asm"  ; the player's ship: its move, altitude, view follow, radar window and map mark
  INCLUDE "world.asm"  ; the world turn: each robot's step (sight, fire, steering by order, movement) and each shot's flight
  INCLUDE "enemy.asm"  ; the computer's side: the enemy commander, its robot builds and orders, and the nuclear blast
  INCLUDE "bases.asm"  ; the bases: counts, owners, buildings, destruction and the new game's map
  INCLUDE "level.asm"  ; The level: the scenery and base lists, the shape table and the 11 shapes BuildMap turns into the map
  INCLUDE "mainmenu.asm"  ; The main menu, the tape save and load of a game, the redefine-keys screen
  INCLUDE "music.asm"  ; The menu's silenced tune loop: Nether Earth's two-voice beeper loop with its OUTs gone, the drum and the note readers in the interrupt, the title colours
  INCLUDE "construction.asm"  ; the construction menu, robot placement on the map, the menus' sound call
  INCLUDE "view.asm"  ; the isometric view: the buffer, the painter's walk over the map, the masked sprites
  INCLUDE "screen.asm"  ; the play screen: its frame and colours, the status panel, screen-line steps, Random
  INCLUDE "controls.asm"  ; the controls: KeyTable and the joystick into Input, the pause
  INCLUDE "print.asm"  ; text: the inline print routine, the font characters, big characters, the numbers
  INCLUDE "interrupts.asm"  ; the frame interrupts of play, the radar, the shot sounds
  INCLUDE "tables.asm"  ; Lookup tables of the view and the robots: view edges, part sprites, sprite pointers, heights
  INCLUDE "worldstate.asm"  ; The moving things of a game: shots, the two radar pictures, the save staging, the robot slots
  INCLUDE "map.asm"  ; The map: 16 rows of 512 cells, built at each new game
  INCLUDE "workspace.asm"  ; The work space $FCE9-$FFFF: the variables, the IM 2 vector and table, the buildings, as the file holds them

  SAVEBIN "game.bin",$6590,$9A70
