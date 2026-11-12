; ZYX boot, variant zyxermbt: the loading picture at $7530 (zyxermbt.scl, file boot).
; Written by kit/mkgame.py from variants/zyxermbt/parts/intro.ann; edit intro.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (main.ann @equ)
RomRet         EQU $0052  ; a RET in the 48K ROM: CALL RomRet leaves the caller's address just below SP
Screen         EQU $4000  ; the screen
  ORG $7530
  INCLUDE "intro-module.asm"  ; Unpack a picture onto the screen while the menu loads

  SAVEBIN "intro.bin",$7530,$0300
