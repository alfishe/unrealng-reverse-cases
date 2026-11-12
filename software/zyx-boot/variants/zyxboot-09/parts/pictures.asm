; ZYX boot, variant zyxboot-09: the two loading pictures at $C350.
; Written by kit/mkgame.py from variants/zyxboot-09/parts/pictures.ann; edit pictures.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (main.ann @equ)
RomRet         EQU $1792  ; a RET in the 48K ROM: CALL RomRet leaves the caller's address just below SP
Screen         EQU $4000  ; the screen
  ORG $C350
  INCLUDE "pictures-module.asm"  ; Two run-length packed screens, each with its own unpacker

  SAVEBIN "pictures.bin",$C350,$1500
