; Myth: History in the Making, System 3 Software 1989: the main block (TZX block 37), 15 360 bytes at $6C3F: the logo, the credits, the menu.
; Written by kit/mkgame.py from src/front/front.ann and the recordings; edit front.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (stage1.ann @equ)
Screen         EQU $4000  ; the display file
Attributes     EQU $5800  ; the screen attributes
TextBuffer     EQU $5B00  ; PrintText's buffer: 8 lines of 32 bytes (the printer buffer), lines 0-6 used
Im2Handler     EQU $F9B3  ; resident: the IM 2 handler (EXX, AyFrame, RETI)
ScreenLineTable EQU $FB00  ; resident: the screen address of each of the 192 pixel lines, a word each
KeyUp          EQU $FC90  ; resident: the UP key reader (CALL, LD BC,port at +3, IN, XOR (KeyXorMask), BIT n,A at +12, RET)
KeyDown        EQU $FC9F  ; resident: the DOWN key reader
KeyLeft        EQU $FCAE  ; resident: the LEFT key reader
KeyRight       EQU $FCBD  ; resident: the RIGHT key reader
KeyFire        EQU $FCCC  ; resident: the FIRE key reader
KeyXorMask     EQU $FCFA  ; resident: XORed with every reader's IN: 0 for keys (active low), $FF for a Kempston (active high)
SavedIm2Jump   EQU $FE01  ; the three bytes at Im2Jump before FrontColdEntry's SetIm2Front (never run)
SavedStack     EQU $FE04  ; FrontColdEntry's SP (never run)
SavedReturn    EQU $FE06  ; FrontColdEntry's return address (never run)
ShimmerCount   EQU $FE1D  ; the frame shimmer's phase, counted down by ShimmerFrame
ReaderBitOp    EQU $FE4C  ; SELECT JOYSTICK: the BIT n,A opcode byte the Patch*Reader routines write
ReaderPort     EQU $FE4D  ; SELECT JOYSTICK: the port word the Patch*Reader routines write
Im2Jump        EQU $FEFE  ; the IM 2 vector's JP (the table $FD00-$FE00 is all $FE)
  ORG $6C3F
  INCLUDE "workspace.asm"  ; The zero-filled space of the block and the glyph rows buffer
  INCLUDE "entry.asm"  ; The hand-over from the resident and the sequence: logo, credits, menu
  INCLUDE "logo.asm"  ; The logo over a starfield, the box's shimmer and colours, the box wiped by dissolving
  INCLUDE "leftovers.asm"  ; Code and texts of an earlier build that nothing calls or reads
  INCLUDE "credits.asm"  ; The credits: seven pages printed and wiped in a loop until SPACE
  INCLUDE "definekeys.asm"  ; DEFINE KEYS: a prompt for each of UP, DOWN, LEFT, RIGHT, FIRE, the key scanned, the resident's reader patched
  INCLUDE "joystick.asm"  ; SELECT JOYSTICK: KEMPSTON, CURSOR KEYS, SINCLAIR, LEAVE THIS MENU; the readers patched for each
  INCLUDE "menu.asm"  ; The menu: PRESS SPACE TO SELECT, three lines, the moving highlight, SPACE takes the line
  INCLUDE "print.asm"  ; Waits, attribute boxes and PrintText: the strip of seven pixel lines revealed by a dissolve
  INCLUDE "data.asm"  ; The two fonts and PrintText's variables

  SAVEBIN "front.bin",$6C3F,$3C00
