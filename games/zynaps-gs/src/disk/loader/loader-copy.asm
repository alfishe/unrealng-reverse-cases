; The level loader (bank 1 $C44A, run at $61A8)
; Written by kit/mkgame.py from src/disk/loader.ann and the recordings; edit loader.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; Constants: addresses outside this image, ROM entries, ports (@const)
GS_DATA            EQU $B3  ; the GS ports: data ...
GS_CMD             EQU $BB  ; ... and command / status (bit 0 command busy, bit 7 data busy)
PAGE_BANK1         EQU $11  ; port $7FFD values (the 48 ROM): bank 1 ...
PAGE_BANK7         EQU $17  ; ... bank 7

; The variables past the loaded image (game.ann @equ)
TRDOS_READ_SECTOR EQU $2090  ; TR-DOS ROM: the read-sector command ($80) to the FDC and its data loop (BC = $017F: port $7F)
TRDOS_OUT_C    EQU $2A53  ; TR-DOS ROM: OUT (C),A; RET
TRDOS_WAIT_INTRQ EQU $2F59  ; TR-DOS ROM: wait for the FDC's INTRQ (port $FF bit 7)
TRDOS_ENTRY    EQU $3D13  ; the TR-DOS ROM's entry for machine code: C = the function (5: read B sectors from D:E to HL)
TRDOS_CALL     EQU $3D2F  ; a RET in the TR-DOS ROM: the address pushed before the JP here runs with TR-DOS paged in
Screen         EQU $4000  ; the screen
BANKM          EQU $5B5C  ; the 128 system variable: the last value written to port $7FFD
ERR_NR         EQU $5C3A  ; IY's base for the ROM's system variables
TRDOS_ERRORS   EQU $5CD6  ; TR-DOS: the count the ROM's read routine raises on a failed sector
TRDOS_5D10     EQU $5D10  ; a TR-DOS work byte zeroed before each read
TRDOS_SYSREG   EQU $5D16  ; TR-DOS's copy of the system register (port $FF)
ModuleVolume   EQU $B460  ; the installer's variables at $B446 (src/disk/install.asm): the level's module volume ...
Level          EQU $B461  ; ... the level whose sound is loaded (1-13)
LoadKind       EQU $B463  ; ... 0 a level, 1 the game start, 2 the title (module 13)
OptionSaturns  EQU $B464  ; ... the menu's SATURNS: 0 = NO
EffectsOnly    EQU $B486  ; the operand of CallDriverFx's LD A,n: 1 effects only
PackedAt       EQU $BED4  ; where every record is read: a Trush block there unpacks itself to $C000 (bank 7)
Bank           EQU $C000  ; the paged bank
PlayFx         EQU $C23C  ; the driver (bank 1): FX L at note H in channel C
ModuleHandle   EQU $C340  ; the driver: the operand of PlayModule's LD A,1 (the module's handle for #31)
StartFxData    EQU $D3CB  ; bank 1: the start jingle (the boot's Trush block 1)
InGameFxData   EQU $FAA5  ; bank 1: the 10 in-game FX, on through banks 3, 4 and 6
  ORG $61A8
  INCLUDE "loader.asm"  ; the level loader: the FX in the banks, the disk FX and the modules sent to the card

  SAVEBIN "build/disk/loader.bin",$61A8,$0419
