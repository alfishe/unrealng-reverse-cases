; ZYX boot, variant zyxlgbt: the Lotus Group boot's stage2 (decrypted; the build encrypts it).
; Written by kit/mkgame.py from variants/zyxlgbt/parts/stage2.ann; edit stage2.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
RomStart       EQU $0063  ; the 48K ROM's $0063: a RET the program's run returns through
RomClAll       EQU $0DAF  ; the 48K ROM's CL-ALL: clear the screen
RomLineRun     EQU $1B8A  ; the 48K ROM's LINE-RUN: run the edit line
TrdosEntry     EQU $3D13  ; the TR-DOS ROM's entry for machine code: C = 5 reads B sectors from track D, sector E to HL; C = $13 copies a 16-byte descriptor from HL; C = $0E loads the file it names
ErrSP          EQU $5C3D  ; ERR_SP
ELine          EQU $5C59  ; E_LINE: the edit line
ScrCt          EQU $5C8C  ; SCR_CT: the scroll count
TrdosHook      EQU $5CC2  ; TR-DOS's hook, set to RET
TrdosDescriptor EQU $5CDD  ; TR-DOS: the current file's name, type, start, length
TrdosType      EQU $5CE5  ; TR-DOS: the file's type, set to "B"
TrdosLength    EQU $5CE6  ; TR-DOS: the file's length
TrdosNextSector EQU $5CF4  ; TR-DOS: the sector after the last one read
TrdosError     EQU $5D10  ; TR-DOS: the error flag
Prog           EQU $5D3B  ; the BASIC program
LaunchName     EQU $5D4E  ; the BASIC's line 1: the descriptor of the file the menu chose
MenuStart      EQU $61A8  ; the menu (src/game: Start)
MenuGraphics   EQU $A600  ; the menu's font and graphics (src/res)
Music          EQU $C0B7  ; the music piece (compiled Sound Tracker)
TrackKey       EQU $FFFF  ; the gap byte the loader found on track 0
  ORG $FDE8
  INCLUDE "stage2-module.asm"  ; Decrypt itself, load and run the menu, then load the chosen program and decrypt it with the track's gap byte

  SAVEBIN "stage2.bin",$FDE8,$0100
