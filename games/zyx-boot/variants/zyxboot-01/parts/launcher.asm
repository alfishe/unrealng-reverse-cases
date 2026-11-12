; ZYX boot, variant zyxboot-01: the launcher sector at $FF14 (zyxboot.scl, file ZYX-1).
; Written by kit/mkgame.py from variants/zyxboot-01/parts/launcher.ann; edit launcher.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
TrdosRet       EQU $3D2F  ; the TR-DOS ROM's RET at $3D2F: a JP there runs the address on the stack inside the TR-DOS ROM
ErrNr          EQU $5C3A  ; ERR_NR
ErrSP          EQU $5C3D  ; ERR_SP: the BASIC error return address on the stack
TrdosFileType  EQU $5CD6  ; TR-DOS: a work byte the launcher clears
TrdosDescriptor EQU $5CDD  ; TR-DOS: the current file's name and type (9 bytes of its catalogue entry)
TrdosStartHigh EQU $5CE5  ; TR-DOS: the file type byte the launcher sets to "B"
TrdosStart     EQU $5CE6  ; TR-DOS: the file's start (parameter 1)
TrdosLength    EQU $5CE8  ; TR-DOS: the file's length (parameter 2)
TrdosSectors   EQU $5CEA  ; TR-DOS: the file's sectors
TrdosSector    EQU $5CEB  ; TR-DOS: the file's first sector
TrdosTrack     EQU $5CEC  ; TR-DOS: the file's track
TrdosFlag10    EQU $5D10  ; TR-DOS: the error flag
TrdosFlag15    EQU $5D15  ; TR-DOS: a work byte set to $FF
TrdosWord1A    EQU $5D1A  ; TR-DOS: set to $0201
TrdosSaveSP    EQU $5D1C  ; TR-DOS: the stack pointer it returns to
TrdosFlag1F    EQU $5D1F  ; TR-DOS: a work byte set to $FF
LaunchName     EQU $5D4E  ; the BASIC's line 1: the chosen file's name the menu wrote
MenuStart      EQU $61A8  ; the menu (src/game: Start)
Catalogue      EQU $9D00  ; the menu's copy of the catalogue (src/game)
  ORG $FF14
  INCLUDE "launcher-module.asm"  ; The launcher: the flag the menu tests, then find the chosen file in the catalogue and run it through the TR-DOS ROM

  SAVEBIN "launcher.bin",$FF14,$00EC
