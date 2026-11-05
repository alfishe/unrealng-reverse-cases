; Zynaps 2 in 1: the TRD's boot.B ($5D3B)
; Written by tools/part_mkasm.py from src/boot/boot.ann; edit the .ann, not the .asm.

  DEVICE ZXSPECTRUM128

; The variables past the loaded image (game.ann @equ)
TR_1FEB        EQU $1FEB  ; TR-DOS ROM routines DiskState runs through TrdosCall (their roles: docs/03-build-and-load.md 3.11)
TR_1FF3        EQU $1FF3
TR_2740        EQU $2740
TR_2A53        EQU $2A53
TR_2FC1        EQU $2FC1
ROM_FONT       EQU $3D00  ; the 48 BASIC ROM's character set (from the space)
TRDOS_ENTRY    EQU $3D13  ; the TR-DOS ROM's entry for machine code: C = 5 reads B sectors from track D sector E to HL
TRDOS_JUMP     EQU $3D30  ; the TR-DOS ROM's RET-to-the-stacked-address trick: a JP there runs the TR-DOS routine on the stack
Screen         EQU $4000
Attrs          EQU $5800
AttrsTitle     EQU $584B  ; the attributes of the frame's top-left corner (row 2, column 11)
AttrsList      EQU $586C  ; the list's window (row 3, column 12)
AttrsRows      EQU $58AC  ; row 5, column 12
AttrsCursor    EQU $596C  ; row 11, column 12: the cursor's bar
ERR_SP         EQU $5C3D  ; the system variable: the error return on the stack
TRDOS_HOOK     EQU $5CC2  ; TR-DOS's RAM hook, called on its errors
TRDOS_5CCD     EQU $5CCD  ; TR-DOS's variable whose bit 6 DiskState returns
TRDOS_ERR      EQU $5D0F  ; TR-DOS's error code (0: none)
Catalogue      EQU $80E8  ; track 0's first nine sectors, read here: the catalogue, then sector 8 (the disk's name at +$8F5)
DiskName       EQU $89DD  ; the disk's label in sector 8 of track 0: the frame's title
Blitter        EQU $8CA0  ; the unrolled copy MakeBlitter writes: 104 BlitLine copies, then JP BlitDone
ListBuffer     EQU $9AC0  ; the list as pixels, 8 bytes (64 pixels) wide, 64 bytes a file
ListStart      EQU $9C40  ; the first file's place: 6 files' room above it, so the first can sit in the window's middle
NameTable      EQU $C350  ; the BASIC files' names, 8 bytes each, in list order
LineTable      EQU $D6D8  ; the screen addresses of lines 40-143 at column 12, popped by the blitter
BoldFont       EQU $DAC0  ; the bold copy of the ROM font, indexed from code 0 (the space at $DBC0)
  ORG $5D3B
  INCLUDE "boot.asm"  ; boot.B: the TRD's boot, a scrolling list of the disk's BASIC files

  SAVEBIN "build/obj/boot-5d3b.bin",$5D3B,$03DC
