; Zynaps 2 in 1: the Kempston mouse driver ($FE00)
; Written by kit/mkgame.py from src/game/mouse.ann; edit mouse.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; Constants: addresses outside this image, ROM entries, ports (@const)
MOUSE_X            EQU $FB  ; IN A,($FBDF): the Kempston mouse's X counter (the high byte, A, before IN A,($DF))
MOUSE_Y            EQU $FF  ; IN A,($FFDF): the Y counter
MOUSE_B            EQU $FA  ; IN A,($FADF): the buttons, active low: bit 0 the right, bit 1 the left
MOUSE_PORT         EQU $DF  ; the low byte of the mouse's ports

; The variables past the loaded image (game.ann @equ)
LifeStart      EQU $B1B4  ; the game's routine the life start called (CALL $B1B4 at $B212, now CALL MouseReset)
ShipX          EQU $F36F  ; the ship's X in its object record: bits 5-7 of the low byte the pixel in the cell, the high byte the column + 16
ShipY          EQU $F371  ; the ship's Y: bits 4-7 of the low byte the line in the row, the high byte the character row
  ORG $FE00
  INCLUDE "mouse.asm"  ; the Kempston mouse driver (K-MOUSE): the ship follows the mouse, a button fires

  SAVEBIN "build/obj/mouse-fe00.bin",$FE00,$00DD
