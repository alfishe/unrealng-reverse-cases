; ZYX boot, variant zyxtvmbt: ReadCatalogueSafe in the menu's spare bytes at $6FE0.
; Written by kit/mkgame.py from variants/zyxtvmbt/parts/safe.ann; edit safe.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
TrdosMotorOff  EQU $02B9  ; a routine of the TR-DOS ROM the variant runs through TrdosRet ($02B9, entered with A the drive's system byte)
TrdosEntry     EQU $3D13  ; the TR-DOS ROM's entry for machine code: C = 5 reads B sectors from track D, sector E to HL
TrdosRet       EQU $3D30  ; the TR-DOS ROM's RET at $3D30: a JP there runs the address on the stack inside the TR-DOS ROM
ErrNr          EQU $5C3A  ; ERR_NR
ErrSP          EQU $5C3D  ; ERR_SP: where BASIC's error handler returns
TrdosErrorFlags EQU $5D0F  ; TR-DOS: the two bytes cleared before the read
TrdosSystemByte EQU $5D16  ; TR-DOS: the last byte written to the drive's system port $FF
Catalogue      EQU $9D00  ; the menu's catalogue buffer (src/game)
  ORG $6FE0
  INCLUDE "safe-module.asm"  ; Read the catalogue with an error trap, then stop the drive

  SAVEBIN "safe.bin",$6FE0,$0038
