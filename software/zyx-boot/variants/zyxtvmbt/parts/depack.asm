; ZYX boot, variant zyxtvmbt: the LZ depacker head at $C000.
; Written by kit/mkgame.py from variants/zyxtvmbt/parts/depack.ann; edit depack.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (main.ann @equ)
RomRet         EQU $0052  ; a RET in the 48K ROM (the end of MASK_INT): the head leaves through it to its caller
DepackRun      EQU $5B8D  ; the printer buffer: the depacker's 100 bytes run here, out of the way of the output
  ORG $C000
  INCLUDE "depack-module.asm"  ; Move the packed stream to the top, unpack it to its place, return

  SAVEBIN "depack.bin",$C000,$0082
