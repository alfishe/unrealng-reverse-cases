; Switchblade, Gremlin Graphics 1991 (Jeff Calder; graphics John Smyth, music Ben Daglish): the game as it runs,
; $5C00-$FFFF (tools/parts.py): TZX block 4 at $6B5C-$FDFC, and block 5's two stretches the bootstrap copies to
; $5C00-$6B4C and $FF01-$FFFE; src/tape/tape.txt cuts them back into the tape's blocks.
; Written by kit/mkgame.py from src/game/game.ann and the recordings; edit game.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; The variables past the loaded image (game.ann @equ)
Screen         EQU $4000  ; the screen's pixels
Attributes     EQU $5800  ; the screen's attributes
RoomObjectList EQU $5B01  ; the room's item records then its enemy records (2 bytes each), copied by SetupRoomObjects
ColumnValues   EQU $5B50  ; one picture column unpacked to 3-bit values (UnpackColumn $8BC5)
  ORG $5C00
  INCLUDE "setup.asm"  ; The start code, the entry, the start of play, a new game and a new life
  INCLUDE "menu.asm"  ; Title, menu, options, keys, the high-score table and its entry
  INCLUDE "vars.asm"  ; The actor pages, the globals, the buffers
  INCLUDE "rooms.asm"  ; The map lookup, the room decoder and builder, the room objects and zones
  INCLUDE "leftovers.asm"  ; Bytes no code reads
  INCLUDE "tables.asm"  ; Tables: room build, title scene, gates, actor scripts
  INCLUDE "graphics.asm"  ; Graphics: tiles, sprites, icons, pictures
  INCLUDE "text.asm"  ; Print routines, the font, the strings
  INCLUDE "mainloop.asm"  ; The main loop, the IM 2 handler and its tick, the input read, the actor dispatch
  INCLUDE "render.asm"  ; Screen drawing: the clears, the cell composer, sprites, the reveal of blocks
  INCLUDE "sound.asm"  ; The 48K effect player and its effect table
  INCLUDE "ending.asm"  ; Havok and the end
  INCLUDE "player.asm"  ; Hiro and the actors: movement, jump, fall, combat, pickups, weapons, Fireblade fragments
  INCLUDE "enemies.asm"  ; Enemies and hazards
  INCLUDE "panel.asm"  ; Energy, lives, score and the panel
  INCLUDE "roomdata.asm"  ; The packed rooms

  SAVEBIN "game.bin",$5C00,$A400
