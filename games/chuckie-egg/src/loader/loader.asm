; Chuckie Egg, A'n'F Software 1983 (Nigel Alderton): tape block 2, the BASIC program "CHUCKIE" (1624 bytes at PROG
; $5CCB, LINE 10): line 10 RANDOMIZE USR 24307 and the character array a$(1600) that carries the loading picture's
; graphics, the loader $5EF3 and the picture's text.
; Written by kit/mkgame.py from src/loader/loader.ann and the recordings; edit loader.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; Constants: addresses outside this image, ROM entries, ports (@const)
GameLength         EQU $49D4  ; tape block 4's length, 18 900 bytes

; The variables past the loaded image (game.ann @equ)
LD_BYTES       EQU $0556  ; the ROM's LD-BYTES: IX = start, DE = length, A = flag byte; carry set = load; carry out = success
RomFont        EQU $3C00  ; the ROM's character set less 32 characters: code x 8 + $3C00 is the glyph of codes $20-$7F
Screen         EQU $4000  ; the display file
Attributes     EQU $5800  ; the screen attributes
AttributesEnd  EQU $5AFF  ; the last attribute byte
ERR_SP         EQU $5C3D  ; the ROM's error stack pointer: tape block 3 loads its two bytes here
BORDCR         EQU $5C48  ; the ROM's border colour (bits 3-5) and the lower screen's attribute
STKBOT         EQU $5C63  ; the ROM's calculator stack bottom
STKEND         EQU $5C65  ; the ROM's calculator stack end
GameBlock      EQU $8214  ; the game image's first byte: tape block 4 loads here ($8214-$CBE7)
GameStart      EQU $A410  ; the game's entry, Start in src/game/menu.asm
  ORG $5CCB
  INCLUDE "basic.asm"  ; The BASIC: line 10 and the header of the array a$ that carries the rest of the block
  INCLUDE "picturegraphics.asm"  ; The loading picture's character graphics
  INCLUDE "tapeloader.asm"  ; The loader: the loading picture, tape blocks 3 and 4, the jump to the game
  INCLUDE "picturetext.asm"  ; The loading picture's character codes and the array's padding

  SAVEBIN "loader.bin",$5CCB,$0658
