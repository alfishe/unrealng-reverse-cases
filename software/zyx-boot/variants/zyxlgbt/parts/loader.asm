; ZYX boot, variant zyxlgbt: the Lotus Group boot's loader (decrypted; the build encrypts it).
; Written by kit/mkgame.py from variants/zyxlgbt/parts/loader.ann; edit loader.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (main.ann @equ)
RomWdCommand   EQU $2A53  ; the TR-DOS ROM's OUT (C),A / RET: a command to the disk controller (C = $1F)
RomLdirRet     EQU $33C3  ; the 48K ROM's LDIR / RET
TrdosEntry     EQU $3D13  ; the TR-DOS ROM's entry for machine code: C = 5 reads B sectors from track D, sector E to HL; C = 2 moves the head to track A
TrdosRet       EQU $3D2F  ; the TR-DOS ROM's RET at $3D2F: a JP there runs the address on the stack inside the TR-DOS ROM
RomReadData    EQU $3FD5  ; the TR-DOS ROM's INI loop: reads the controller's data port (C = $7F) to HL until the command ends
KeyStack       EQU $404C  ; the stack while the loop runs: SP is part of the key
SavedSP        EQU $4650  ; the BASIC stack, kept in the screen
Attributes     EQU $5800  ; the screen's attributes, cleared to black
TrackBuffer    EQU $C000  ; the raw track 0 the controller's Read Track command returns
DecoyBuffer    EQU $C524  ; four sectors read before the track read overwrites them
TrackTail      EQU $D782  ; where the search for the gap bytes starts (the track's offset $1782)
TrackGapByte   EQU $D7B6  ; the track's byte at offset $17B6: the end of the track's last gap
Stage2         EQU $FDE8  ; track 5 sector 0: the second stage (variants/zyxlgbt/parts/stage2.ann)
TrackKey       EQU $FFFF  ; the gap byte found: the key the second stage's file decryption starts R with
  ORG $9C40
  INCLUDE "loader-module.asm"  ; Decrypt itself, read track 0 raw and look for its gap bytes, then load the second stage and run it

  SAVEBIN "loader.bin",$9C40,$0100
