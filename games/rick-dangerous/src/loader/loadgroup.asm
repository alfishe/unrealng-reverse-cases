; Rick Dangerous, Firebird 1989 (Bleepload): group 1's blocks 44-45: LoadGroup at $FA00, the loader of groups 2 and 3 (512 bytes, deciphered).
; Written by kit/mkgame.py from src/loader/loadgroup.ann and the recordings; edit loadgroup.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; The variables past the loaded image (game.ann @equ)
ChanOpen       EQU $1601  ; the ROM's CHAN-OPEN: A = the stream
DfSz           EQU $5C6B  ; DF_SZ: the lines of the lower screen
BlockBuffer    EQU $FE00  ; every block loads here: its marker first ($34 group 2, $35 group 3)
BlockPayload   EQU $FE01  ; the block's 256 bytes, each XOR the high byte of its address
BlockNumber    EQU $FF01  ; the block's number in its group
BlockDest      EQU $FF02  ; where the payload goes
GroupEnd       EQU $FF05  ; the high byte after the group's last page
GroupGo        EQU $FF06  ; where to go after the last block: 0, return
  ORG $FA00
  INCLUDE "loadgroup-module.asm"  ; LoadGroup: the loader of groups 2 and 3

  SAVEBIN "loadgroup.bin",$FA00,$0200
