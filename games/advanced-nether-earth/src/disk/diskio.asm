; Advanced Nether Earth (Eternity Industry, 1998): the disk module, bank 4 $C000-$CD2B as the game starter
; unpacks it. The game's GameSave / GameLoad page bank 4 and jump to $C000 with IX = the entry: the set-up
; clears the screen, goes back to IM 1 and the ROM's state, copies $C065-$CD2B to $4000 and jumps to IX.
; Written by kit/mkgame.py from the annotations (src/disk/setup.ann, src/disk/module.ann) and the recordings; edit the annotations,
; not the .asm.

  DEVICE ZXSPECTRUM48

; Addresses outside this image (@equ in the annotations)
TrdosReadSector EQU $2090  ; TR-DOS ROM: READ SECTOR ($80) with the INI loop $3FE5 (B = 1: 256 bytes from $7F to HL), then the status and the sector list
TrdosSectorStatus EQU $2099  ; TR-DOS ROM: the status after a sector command, then the sector list
TrdosStatusSeek EQU $2740  ; TR-DOS ROM: IN A,($1F) to TrdosStatus, then a seek to track D
RomHLx         EQU $2758  ; the 48 K ROM's value for HL' (the calculator's return), as the IM 1 handler expects
TrdosOutC      EQU $2A53  ; TR-DOS ROM: OUT (C),A / RET
TrdosRet       EQU $3D2F  ; TR-DOS ROM: NOP / RET, the entry that pages the ROM in
TrdosWaitDone  EQU $3EF5  ; TR-DOS ROM: wait for INTRQ (port $FF bit 7), reading data on DRQ
TrdosWriteLoop EQU $3FCA  ; TR-DOS ROM: the OUTI loop (HL to port $7F on DRQ) until INTRQ
RomIY          EQU $5C3A  ; the ROM's IY: ERR_NR, the base of the system variables
TrdosHook      EQU $5CC2  ; TR-DOS's hook in the system variables: TR-DOS jumps there through a pushed return (a RET, $C9, after TR-DOS's own start-up)
TrdosStatus    EQU $5CCD  ; TR-DOS's variable: the WD1793 status $2740 read
TrdosSector    EQU $5CD6  ; TR-DOS's variable: the sector of the read or write going on; the ROM adds 1 to it when a sector fails
TrdosFlag      EQU $5CD8  ; TR-DOS's variable at $5CD8, set to 1 before $2740
SaveReturn     EQU $692B  ; the game's return after a save (IM 2 again, the play screen)
LoadReturn     EQU $A590  ; the game's return after a load (src/game: IM 2 again, $5B00 = $FFFF, JP NewGameSetup with NZ)
Restart        EQU $A5EF  ; the game's restart: the player, Start, the main menu
ModuleImage    EQU $C065  ; the module's bytes in bank 4 (the set-up's end): copied to $4000
SavedGame      EQU $D92B  ; the game's saved state, $D92B-$FFFF in bank 0 (NE's SaveShots on): the file's start
CatBuffer      EQU $F800  ; the sector buffer, $F800-$FFFF of bank 4: the catalogue (8 sectors) or one sector of it
CatFreeSector  EQU $F8E1  ; the disk information sector's first free sector and track
CatFiles       EQU $F8E4  ; the disk information sector's number of files
CatFreeSectors EQU $F8E5  ; the disk information sector's count of free sectors

; the set-up, run in bank 4: $C000-$C064
  ORG $C000
  INCLUDE "diskio/setup.asm"  ; the set-up, run in bank 4 at $C000

; the module, copied to and run at $4000 (the screen): $C065-$CD2B, run at $4000
  ORG $C065
  DISP $4000
  INCLUDE "diskio/diskmod.asm"  ; the disk module at $4000: the name prompt, the TR-DOS file load and save
  ENT

  SAVEBIN "disk-io-c000-bank4.bin",$C000,3372
