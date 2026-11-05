; The boot code (disk sectors 1:1-1:2, run at $5D3B)
; Written by tools/part_mkasm.py from src/disk/boot.ann; edit the .ann, not the .asm.

  DEVICE ZXSPECTRUM128

; Constants: addresses outside this image, ROM entries, ports (@const)
PAGE_ROM48         EQU $10  ; port $7FFD values: bit 4 the 48 BASIC ROM, bits 0-2 the bank at $C000 (here bank 0)
PAGE_BANK1         EQU $11
PAGE_BANK3         EQU $13
PAGE_BANK4         EQU $14
PAGE_BANK6         EQU $16
PAGE_BANK7         EQU $17

; The variables past the loaded image (game.ann @equ)
TRDOS_READ_SECTOR EQU $2090  ; TR-DOS ROM: the read-sector command ($80) to the FDC and its data loop (BC = $017F: port $7F)
TRDOS_OUT_C    EQU $2A53  ; TR-DOS ROM: OUT (C),A; RET, the gadget for writing an FDC or system register
TRDOS_WAIT_INTRQ EQU $2F59  ; TR-DOS ROM: wait for the FDC's INTRQ (port $FF bit 7), the end of a command
TRDOS_ENTRY    EQU $3D13  ; the TR-DOS ROM's entry for machine code: C = the function (5: read B sectors from D:E to HL)
TRDOS_CALL     EQU $3D2F  ; a RET in the TR-DOS ROM: the address pushed before the JP here runs with TR-DOS paged in
Attrs          EQU $5800  ; the attribute file
BANKM          EQU $5B5C  ; the 128 system variable: the last value written to port $7FFD
ERR_NR         EQU $5C3A  ; IY's base for the ROM's system variables
ERR_SP_HIGH    EQU $5C3E  ; the high byte of ERR_SP
BORDCR         EQU $5C48  ; the border colour and the lower screen's attribute
ATTR_P         EQU $5C8D  ; the permanent attribute
TRDOS_ERRORS   EQU $5CD6  ; TR-DOS: the count the ROM's read routine raises on a failed sector (compared around each read)
TRDOS_SECTOR   EQU $5CF4  ; TR-DOS: the sector and track after the last one read
TRDOS_5D10     EQU $5D10  ; a TR-DOS work byte zeroed before each read (as basic.asm's loader does)
TRDOS_SYSREG   EQU $5D16  ; TR-DOS's copy of the system register (port $FF: drive, side, density)
Block4         EQU $607C  ; Trush block 4's load address: it unpacks the installer, the GS driver file and Zynaps to $61A8-$FFFF
Install        EQU $61A8  ; the installer (src/disk/install.asm): the stubs, the patches, the driver to bank 1, Zynaps started
OptionsMenu    EQU $6D60  ; the options menu, run in place inside the unpacked driver file (src/disk/menu.ann)
Block0         EQU $7E2C  ; Trush block 0's load address: it unpacks the loading screen and its fade to $7F58-$9AFF
ShowLoadingScreen EQU $7F58  ; the loading screen's fade-in (src/disk/screen.ann)
LoadingScreen  EQU $8000  ; the loading screen as block 0 unpacks it
PackedAt       EQU $BED4  ; where the Trush blocks of banks 4 and 6 load: base $BED4, unpacked to $C000-$FFFF
Bank           EQU $C000  ; the paged bank
Block1         EQU $D29F  ; Trush block 1's load address: it unpacks bank 1's sound data to $D3CB-$FFFF
  ORG $5D3B
  INCLUDE "boot.asm"  ; the boot: the loading screen, the sound banks, the game block, the options menu

  SAVEBIN "build/disk/boot.bin",$5D3B,$0200
