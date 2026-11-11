; --------------------------------------------------------------------------------------------------------------------
; boot.asm: the boot: the loading screen, the sound banks, the game block, the options menu
;
; BootLoader (src/disk/basic.asm) reads these two sectors to $5D3B and returns into Start. Every block is read with
; ReadSectors from where the last read stopped (TR-DOS's TRDOS_SECTOR): the disk is one run of sectors in the order
; Start reads them, then the level data the loader finds by the record table (src/disk/loader.ann).
;
; The sound data the card gets at the game start goes to the 128's banks 1, 3, 4 and 6 first (bank 1 from $D3CB; the
; GS driver will be put below it at $C000). Banks 1, 4 and 6 come as Trush blocks (src/disk/trush.asm) that unpack
; themselves at their load address and return; bank 3 is read as it is. Bank 7 keeps a copy of the loading screen for
; the loader to show while a level's music loads.
;
; Holding ENTER while the disk boots selects the boot's own sector reader (FastRead): TR-DOS's read routines without
; its function 5's checks, a track at a time. Without ENTER every block is read with TR-DOS's function 5.
; --------------------------------------------------------------------------------------------------------------------

; the boot: screen black, the loading screen, the sound banks, block 4, the
; menu, the installer
;
; Entered by RET from BootLoader with the two sectors in place. SP goes below
; block 4's load address. The order on the disk is the order here: block 0 (13
; sectors, the loading screen), block 1 (40, bank 1), bank 3 (64 sectors, raw),
; block 2 (58, bank 4), block 3 (49, bank 6), block 4 (94: the installer, the
; GS driver file, the options menu and Zynaps).
;
; After the fade the options menu runs in place (OptionsMenu, inside block 4's
; driver file) and sets its choices into the not yet installed code; then JP
; Install.
Start:
  DI
  CALL ClearScreen
  LD (ERR_SP_HIGH),A            ; A = 0 (ClearScreen)
  LD (BORDCR),A
  LD (ATTR_P),A
  LD IY,ERR_NR
  LD SP,$607B             ; the stack below block 4
  LD HL,Block0             ; block 0: 13 sectors to $7E2C, run (it unpacks the
                          ; loading screen and returns)
  LD BC,13*256+PAGE_BANK7
  CALL ReadAndRun
  LD HL,LoadingScreen             ; the loading screen to bank 7 (paged by the read)
                          ; for the loader's level breaks
  LD DE,Bank
  LD BC,$1B00
  LDIR
  CALL ShowLoadingScreen              ; the loading screen's fade-in
  LD HL,Block1             ; block 1: 40 sectors to $D29F in bank 1: bank 1's
                          ; sound data from $D3CB
  LD BC,40*256+PAGE_BANK1
  CALL ReadAndRun
  LD HL,Bank             ; bank 3: 64 sectors as they are
  LD BC,64*256+PAGE_BANK3
  CALL ReadSectors
  LD BC,58*256+PAGE_BANK4      ; block 2: 58 sectors to $BED4 in bank 4
  CALL ReadPackedAt
  LD BC,49*256+PAGE_BANK6      ; block 3: 49 sectors to $BED4 in bank 6
  CALL ReadPackedAt
  LD HL,Block4             ; block 4: 94 sectors to $607C with the 48 ROM and
                          ; bank 0: $61A8-$FFFF
  LD BC,94*256+PAGE_ROM48
  CALL ReadAndRun
  CALL FadeOut            ; the loading screen fades out
  CALL OptionsMenu              ; the options menu (it returns with bank 0 paged)
  JP Install

; B sectors to PackedAt ($BED4) in the bank C pages, then run them (a Trush
; block)
;
; Used by the routine at Start.
ReadPackedAt:
  LD HL,PackedAt

; B sectors to HL with port $7FFD = C, then JP (HL): the block unpacks itself
; and returns to the caller
;
; Used by the routine at Start.
ReadAndRun:
  PUSH HL
  CALL ReadSectors
  POP HL
  JP (HL)

; the screen's attributes darkened in 7 steps of 8 frames, then the screen
; cleared (ClearScreen)
;
; Each step takes 1 from every cell's ink and paper (down to 0) and keeps
; BRIGHT; FLASH is dropped. The loop falls into ClearScreen.
FadeOut:
  EI
  LD B,$07
  LD L,$00
  LD DE,$3807
l_5DA7:
  LD H,$58
l_5DA9:
  LD C,$00
  LD A,(HL)
  AND D
  JR Z,l_5DB2
  SUB $08
  LD C,A
l_5DB2:
  LD A,(HL)
  AND E
  JR Z,l_5DB7
  DEC A
l_5DB7:
  OR C
  LD C,A
  LD A,(HL)
  AND $40
  OR C
  LD (HL),A
  INC L
  JR NZ,l_5DA9
  INC H
  LD A,H
  CP $5B
  JR NZ,l_5DA9
  LD H,$08
l_5DC9:
  HALT                    ; 8 frames
  DEC H
  JR NZ,l_5DC9
  DJNZ l_5DA7

; border black, the bitmap and the attributes zeroed (LDDR down from $5AFF), A
; = 0
;
; Used by the routine at Start.
ClearScreen:
  XOR A
  OUT ($FE),A
  LD HL,Attrs+767
  LD DE,Attrs+766
  LD BC,$1AFF
  LD (HL),A
  LDDR
  RET

; B sectors from TRDOS_SECTOR to HL, with C written to port $7FFD (and BANKM)
; first
;
; Port $7FFD is written before the read, so the sectors go to the bank C
; selects when HL is at $C000 or above. With ENTER up (port $BFFE bit 0 set)
; the read is TR-DOS's function 5 through TRDOS_ENTRY, which returns to the
; caller; with ENTER held the boot reads the sectors itself (FastRead) and
; keeps TRDOS_SECTOR up to date as function 5 does.
ReadSectors:
  LD D,B
  LD A,C
  LD BC,$7FFD
  LD (BANKM),A
  OUT (C),A
  LD B,D
  LD DE,(TRDOS_SECTOR)
  XOR A
  LD (TRDOS_5D10),A
  LD C,$05
  PUSH BC
  LD BC,$BFFE             ; ENTER?
  IN A,(C)
  POP BC
  RRCA
  JP C,TRDOS_ENTRY

; ENTER held: B sectors from D:E with TR-DOS's own FDC routines, each retried
; until it reads without error
;
; SeekTrack selects the side and steps to track D >> 1 (bit 0 of D is the
; side). Each sector: ReadSector, and TRDOS_ERRORS compared with its value
; before the read; a change means the read failed and it is read again. Past
; sector 15 the next track is sought. The position after the last sector goes
; back to TRDOS_SECTOR.
FastRead:
  PUSH IY
  PUSH IX
  CALL SeekTrack
  LD IX,TRDOS_WAIT_INTRQ
  CALL RomCall
l_5E0D:
  LD A,(TRDOS_ERRORS)            ; one sector: TRDOS_ERRORS before
  PUSH HL
  PUSH BC
  EX AF,AF'
  CALL ReadSector
  DI
  EX AF,AF'
  LD HL,TRDOS_ERRORS
  CP (HL)
  JP Z,l_5E23
  POP BC
  POP HL
  JR l_5E0D
l_5E23:
  POP BC                  ; read: the next sector, the next track after 16
  POP HL
  INC E
  BIT 4,E
  JP Z,l_5E31
  LD E,$00
  INC D
  CALL SeekTrack
l_5E31:
  INC H                   ; 256 bytes on
  DJNZ l_5E0D
  POP IX
  POP IY
  LD (TRDOS_SECTOR),DE
  RET

; sector E + 1 to the FDC's sector register, then TR-DOS's read-sector code
; with BC = $017F (data port)
;
; The LD BC pushes this routine's own address before the jumps into the ROM: a
; word the ROM code takes from the stack on its way out.
ReadSector:
  LD BC,ReadSector
  PUSH BC
  LD A,E
  INC A
  LD C,$5F
  CALL WriteFdc
  LD BC,$017F
  LD IX,TRDOS_READ_SECTOR
  JR RomCall

; drive side from D bit 0 (system register), track D >> 1 to the data register,
; the seek command ($18)
;
; Used by the routine at FastRead.
SeekTrack:
  LD A,(TRDOS_SYSREG)
  OR $3C
  BIT 0,D
  JR Z,l_5E5C
  RES 4,A
l_5E5C:
  LD C,$FF
  CALL WriteFdc
  LD A,D
  AND A
  RRA
  LD C,$7F
  CALL WriteFdc
  LD A,$18
  LD C,$1F

; A to the port C through TRDOS_OUT_C
;
; Used by the routines at ReadSector and SeekTrack.
WriteFdc:
  LD IX,TRDOS_OUT_C

; IX run inside the TR-DOS ROM (PUSH IX; JP TRDOS_CALL)
;
; Used by the routines at FastRead and ReadSector.
RomCall:
  PUSH IX
  JP TRDOS_CALL

; zeros to the end of the second sector
Spare:
  DEFS $C5
