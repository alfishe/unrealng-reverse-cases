; ZYX boot: sector 0 of the file boot (B, 180 bytes, 46 sectors), the BASIC program TR-DOS loads at PROG $5D3B.
; Line 4's REM holds the loader, entered at $5D80 by line 10's RANDOMIZE USR 23936.
; Written by kit/mkgame.py from src/basic/basic.ann and the recordings; edit basic.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; Constants: addresses outside this image, ROM entries, ports (@const)
MusicSectors       EQU 22  ; the music piece's sectors (a variant's music piece has its own count, variants/)

; The variables past the loaded image (game.ann @equ)
TrdosEntry     EQU $3D13  ; the TR-DOS ROM's entry point for machine code: C = 5 reads B sectors from track D, sector E to HL
TrdosNextSector EQU $5CF4  ; TR-DOS: the track and sector after the last one read
MenuStart      EQU $61A8  ; the menu's code (src/game: Start), 15 sectors
MenuGraphics   EQU $A600  ; the font and the graphics (src/game: Font), 8 sectors
MusicPiece     EQU $C000  ; the music (src/music), 22 sectors
  ORG $5D3B
  INCLUDE "basic-module.asm"  ; The BASIC program, its loader in line 4, the autostart mark and the sector's tail

  SAVEBIN "basic.bin",$5D3B,$0100
