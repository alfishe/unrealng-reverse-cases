; Nether Earth GS, TRD file boot: the boot menu's menu part
; Written by tools/trd_mkasm.py from src/trd/boot/menu.ann; edit the .ann, not the .asm.

  DEVICE ZXSPECTRUM128

; Constants: addresses outside this image, ROM entries, ports (@const)
PRINT64_IMAGE      EQU $68CC  ; where the 64-column printer's bytes follow this part in the unpacked block (print64.asm, assembled for $8156)
PRINT64_COPY       EQU $08E1  ; the bytes Start copies: the printer's 2272 and one more (the first byte past the unpacked block)

; The variables past the loaded image (game.ann @equ)
PR_STRING      EQU $203C  ; the 48 BASIC ROM's PR-STRING: BC characters from DE to the current channel
TRDOS_ENTRY    EQU $3D13  ; the TR-DOS ROM's entry for machine code: C = the function (5 reads B sectors from D:E to HL)
TRDOS_CALL     EQU $3D2F  ; a RET in the TR-DOS ROM: a routine address pushed before JP here runs with TR-DOS paged in
TRDOS_CALL1    EQU $3D30  ; the same trick one byte on (the address pushed is entered through the RET at $3D2F's neighbour)
Screen         EQU $4000  ; the screen's first third: here a 2 K scratch buffer for the catalogue's names
Attrs          EQU $5800  ; the attribute file
ClearStackTop  EQU $5B00  ; the stack ClearScreen sets: PUSHes from here down clear the screen
REPDEL         EQU $5C09  ; the keyboard's repeat delay (system variable)
REPPER         EQU $5C0A  ; the keyboard's repeat period
BORDCR         EQU $5C48  ; the border colour and the lower screen's attribute
ATTR_P         EQU $5C8D  ; the permanent attribute
TRDOS_HOOK     EQU $5CC2  ; TR-DOS's error hook: a RET ($C9) normally; DriveCall writes JP DriveTrap there
TRDOS_5CD8     EQU $5CD8  ; a TR-DOS work byte the drive reset sets to $FF (the error flag of the next call)
RunName        EQU $5DDD  ; the 8 spaces of boot's line 3 RUN "        ": the menu writes the chosen file's name there
PrintInit      EQU $8156  ; the 64-column printer's set-up (print64.asm, copied there by Start)
PrintColumn    EQU $8461  ; the 64-column printer's column (0-63)
PrintRow       EQU $8462  ; its row (0-23)
SortedCatalogue EQU $C350  ; the names sorted by their first character, 8 bytes each
Catalogue      EQU $EA60  ; the disk's catalogue: 9 sectors of track 0 (8 sectors of 16-byte entries and the disk's sector 9)
  ORG $61A8
  INCLUDE "menu.asm"  ; Work Loader v1.2 (TRON 1999): the boot program's catalogue menu

  SAVEBIN "build/trd/obj/boot-menu.bin",$61A8,$0724
