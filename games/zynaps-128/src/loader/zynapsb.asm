; Zynaps 2 in 1: ZYNAPS.B sector 0, the BASIC with the REM loader ($5D3B)
; Written by tools/part_mkasm.py from src/loader/loader.ann; edit the .ann, not the .asm.

  DEVICE ZXSPECTRUM128

; The variables past the loaded image (game.ann @equ)
ROM_MAIN_4     EQU $1303  ; the 48 BASIC ROM's MAIN-4: the report and the return to the editor after a statement
ROM_CHANS_P    EQU $15BE  ; the ROM's initial channel data, channel P's two addresses (output $09F4, input $15C4)
ROM_STMT_RET   EQU $1B76  ; the ROM's STMT-RET: the next BASIC statement
TRDOS_ENTRY    EQU $3D13  ; the TR-DOS ROM's entry for machine code: C = 5 reads B sectors from track D sector E to HL
Depack         EQU $5B00  ; the Hrust 1 depacker (sector 1 of this file, src/loader/depacker.asm)
ERR_SP         EQU $5C3D  ; the system variable: the address of the error return on the machine stack
CHANS          EQU $5C4F  ; the system variable: the channel area
TRDOS_HOOK     EQU $5CC2  ; TR-DOS's RAM hook, called on its errors (a RET normally)
TRDOS_NEXT     EQU $5CF4  ; TR-DOS's track and sector after the last one read (E = the sector, D = the track)
BlockStart     EQU $6000  ; where both packed blocks are read and unpacked in place: the intro's and the game's entry
PagedSlot      EQU $C000  ; the top 16 K, the slot $7FFD pages
  ORG $5D3B
  INCLUDE "loader.asm"  ; ZYNAPS.B's BASIC: the REM loader and its RUN line

  SAVEBIN "build/obj/zynapsb-basic.bin",$5D3B,$00AC
