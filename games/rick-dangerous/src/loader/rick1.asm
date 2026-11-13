; Rick Dangerous, Firebird 1989 (Bleepload): TZX block 4, Rick1: the first loader stage, which the ROM loads at $CD00 (512 bytes).
; Written by kit/mkgame.py from src/loader/rick1.ann and the recordings; edit rick1.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; The variables past the loaded image (game.ann @equ)
ChanOpen       EQU $1601  ; the ROM's CHAN-OPEN: A = the stream
DfSz           EQU $5C6B  ; DF_SZ: the lines of the lower screen
BlockBuffer    EQU $FE00  ; every block loads here: its marker first ($64 for group 1)
BlockPayload   EQU $FE01  ; the block's 256 bytes of payload
BlockNumber    EQU $FF01  ; the block's number in its group
BlockDest      EQU $FF02  ; where the payload goes
BlockFiller    EQU $FF04  ; N, the filler's length; then N bytes, the tail's JP and the checksum
NextFiller     EQU $FF15  ; N of the next block: set from each block's checksum (8 for the first)
  ORG $CD00
  INCLUDE "rick1-module.asm"  ; Rick1: the first loader stage, which loads tape group 1

  SAVEBIN "rick1.bin",$CD00,$0200
