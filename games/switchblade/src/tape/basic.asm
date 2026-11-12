; Switchblade, Gremlin Graphics 1991: TZX block 2, the BASIC program "( Switch )" (361 bytes at PROG $5CCB,
; LINE 0): line 0 at $5CCB-$5D06, the code it enters at $5D07, and the loader $5D37-$5E33, which runs at $FF00.
; Written by kit/mkgame.py from src/tape/basic.ann and the recordings; edit basic.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; Addresses outside this image (@equ in the annotations)
RomRet         EQU $0555  ; a RET in the 48K BASIC ROM (the end of SA/LD-RET, the byte before LD-BYTES $0556)
Screen         EQU $4000  ; the display file
Attributes     EQU $5800  ; the screen attributes

; line 0 and its code: $5CCB-$5D36
  ORG $5CCB
  INCLUDE "basic/basic.asm"  ; The BASIC: line 0, whose USR enters the code that ends the line

; the tape loader: $5D37-$5E33, run at $FF00
  ORG $5D37
  DISP $FF00
  INCLUDE "basic/loader.asm"  ; The tape loader at $FF00: the ROM's LD-BYTES with red stripes and its own end
  ENT

  SAVEBIN "basic.bin",$5CCB,361
