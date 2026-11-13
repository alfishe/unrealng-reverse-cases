; Deflektor, Gremlin Graphics 1987: TZX block 1, the BASIC "DEFLEKTOR" (384 bytes at PROG $5CCB, LINE 0):
; line 0 and its code at $5D05, and the loader's first stage $5D17-$5E4A, which runs at $B626.
; Written by kit/mkgame.py from src/tape/basic.ann and the recordings; edit basic.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; Addresses outside this image (@equ in the annotations)
RomFont        EQU $3D00  ; the 48K ROM's character set, characters 32-127, 8 bytes each
Attributes     EQU $5800  ; the screen attributes
Stage2         EQU $B75A  ; the loader's second stage (src/loader): the first load, and the hook's work at $B75A
LoadRest       EQU $B856  ; stage 2's entry: the load of its last two pieces (src/loader)

; line 0 and its code: $5CCB-$5D16
  ORG $5CCB
  INCLUDE "basic/basic.asm"  ; The BASIC: line 0, whose USR enters the code after the program

; the loader's first stage: $5D17-$5E4A, run at $B626
  ORG $5D17
  DISP $B626
  INCLUDE "basic/loader1.asm"  ; The loader's first stage at $B626: its variables, the pilot search, the turbo byte and block loads
  ENT

  SAVEBIN "basic.bin",$5CCB,384
