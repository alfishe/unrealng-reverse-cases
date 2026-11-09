; Moon Patrol, Atarisoft (UK) 1984 (never released, recovered): the game image $60F8-$FFFF as the tape loads it.
; Written by kit/mkgame.py from src/game/game.ann and the recordings; edit game.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
KEY_SCAN       EQU $028E  ; the ROM's KEY-SCAN: E = the key value ($FF none), NZ for more than two keys
BEEPER         EQU $03B5  ; the ROM's BEEPER: HL = the period, DE = the cycles; DI on entry, EI before its RET
SA_BYTES       EQU $04C2  ; the ROM's SA-BYTES: IX = start, DE = length, A = flag byte
LD_BYTES       EQU $0556  ; the ROM's LD-BYTES: IX, DE, A = flag byte; carry set = load, clear = verify; carry out = success
RomBlipLengths EQU $0B16  ; 15 ROM bytes used as the lengths of the time-bonus blip's half-cycles
Screen         EQU $4000  ; the display file
ScreenRow162   EQU $5280  ; the screen line of pixel row 162 (two rows under the ground's top row $A0)
ScreenRow159   EQU $5760  ; the screen line of pixel row 159 (the row over the ground's top row $A0)
Attributes     EQU $5800  ; the screen attributes
AttrRow18      EQU $5A40  ; the attribute line of character row 18 (the green plant's head)
AttrRow20      EQU $5A80  ; the attribute line of character row 20
FeedMountains  EQU $5B00  ; printer buffer: the next 8 columns of the mountains, one byte a line (lines 64-95)
FeedHills      EQU $5B20  ; printer buffer: the next 8 columns of the hills, one byte a line (lines 96-127)
FeedRoad       EQU $5B40  ; printer buffer: the next 8 columns of the road, one byte a line (lines 160-191)
ShotForward    EQU $5B60  ; printer buffer: the forward shot: y ($FF free), x, height (3; $FF = hit), width, end x
ShotsUp        EQU $5B65  ; the buggy's four upward shots, 4 bytes each: y, x, height, width (+2 = $FF: spent)
LAST_K         EQU $5C08  ; the ROM's last key, filled by the IM 1 keyboard scan
FLAGS          EQU $5C3B  ; the ROM's flags (bit 3: L mode)
ERR_SP         EQU $5C3D  ; the ROM's error stack pointer: the word there is where an error report returns to
MODE           EQU $5C41  ; the ROM's keyboard mode (0 = K/L/C)
BORDCR         EQU $5C48  ; system variable: the border colour in bits 3-5
FLAGS2         EQU $5C6A  ; the ROM's flags 2 (bit 3: CAPS LOCK)
FRAMES         EQU $5C78  ; the ROM's frame counter, counted by Im2Handler in play
  ORG $60F8
  INCLUDE "leftover.asm"  ; Build leftovers below graphics A: bytes no code reads, with a copy of the tape header
  INCLUDE "graphicsa.asm"  ; Graphics A: the title logo, the buggy's wreck, the explosions and bursts, one build-date string
  INCLUDE "interrupt.asm"  ; The IM 2 interrupt handler: FRAMES, the tune player and the play clock
  INCLUDE "menus.asm"  ; The entry, the title, the options page, the score advance table, the demo, the hi-score page, the tape
  INCLUDE "hiscores.asm"  ; The hi-score tables, their page, the hi-score entry after GAME OVER
  INCLUDE "gamestart.asm"  ; The game start, the lives and the players, GAME OVER, the life start and the HUD
  INCLUDE "course.asm"  ; The main loop, the course interpreter, the course commands and the first object handlers
  INCLUDE "objects.asm"  ; The flying objects: the UFO saucers, the spinner, their bombs and the UFO retreat timer
  INCLUDE "enemies.asm"  ; The ground enemies: the tank and its shell, the low flyer from behind, the boulders and the green plant
  INCLUDE "bonus.asm"  ; The sector bonus screen at each sector end, with the best sector time kept in the course script
  INCLUDE "play.asm"  ; The play code: interrupt modes, the buggy, its jump, shots and death, the scrolling, the controls, the hold and the tune keys
  INCLUDE "sprites.asm"  ; The block copy and the pre-shifted XOR sprite drawers of the sprite table
  INCLUDE "variables.asm"  ; Variables: the buggy, the scrolling layers, the course state, the menus and the two player records
  INCLUDE "tables.asm"  ; Tables: a build-date string, the sprite table and the tune
  INCLUDE "courses.asm"  ; Courses: the Beginner and Champion course scripts and the two course switches
  INCLUDE "objectlist.asm"  ; The object list, free space and the stack: zero in the loaded image
  INCLUDE "graphicsb.asm"  ; Graphics B: the enemies, the obstacles, the buggy and the three scenery strips
  INCLUDE "printvars.asm"  ; Print variables: the print position, colours, metrics and state, the code table and the font descriptors
  INCLUDE "printing.asm"  ; Printing: the three fonts, the pixel and line tables, and the print code

  SAVEBIN "game.bin",$60F8,$9F08
