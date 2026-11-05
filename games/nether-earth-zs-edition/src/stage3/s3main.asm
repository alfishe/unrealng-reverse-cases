; --------------------------------------------------------------------------------------------------------------------
; s3main.asm: "System checking": the machine, the memory, the loads, the patches, the 128 K route, the tape path
;
; Stage 2 unpacks this block to $61A8 and jumps to it (r99 frame 2194). It fades the screen out, prints the title and
; "System checking...", runs MemoryTest and prints the machine's name and the memory size, then loads the rest of the
; release from the disk (TR-DOS, from the sector after stage 3's file, TrdosNextSector) or, when no TR-DOS variables
; exist, from tape: the game block to $6780 (68 sectors, unpacked in place by its own CALL), the patches block to
; $DC00 (4 sectors, unpacked to $D800), whose pieces it copies into the game (BlockReader, LoadMap, TextLoader, the
; MainMenu jump table at $C100); then, on more than one page of memory, the menu block into page 1 and the four texts
; ("RAM-Disk") into page 3, and the paged jump table. It ends at the game's Start ($A600).
;
; What each machine gets (witnessed): Pentagon 128 (r99 frame 2300): scheme $01, count 5, "Computer Spectrum", "Memory
; 128Kb". Scorpion ZS-256 (s99 frame 2000): scheme $83 (bits 7, 1, 0), count $0D, "Computer Scorpion", "Memory 256Kb".
; Pentagon locked in 48 K BASIC (r99-48 frame 5300): scheme 0, count 0, "Computer Spectrum", "Memory 56Kb", and the
; 128 K route (count is not 1): the menu and the texts are read over the game's $C000-$FFFF, Start's CALL MainMenu
; runs text bytes and the ROM resets the machine (see Stage3Paged). A real 48 K + Beta 128 is the same case (no
; paging: count 0); the one-page route (count = 1) is reached by no machine (see MemoryTest).
; --------------------------------------------------------------------------------------------------------------------

; Fade the screen out, clear it, print the title, test the memory, print what
; was found
;
; Entered from stage 2 (r99 frame 2194). Eight steps (B = 8..1): border B-1,
; every attribute (B-1) * 8 (the paper colour), two HALTs; then the pixels and
; attributes $4000-$5BFF to 0, stream 2 open (RomChanOpen), SysDfSz = 0 (the
; whole screen for printing), the title (TitleText). Then MemoryTest and the
; line "Computer <name>": the name is NameDefault ("Spectrum") when the scheme
; ($5CB0) is 0, else the string for its highest set bit (FirstSetBit,
; SkipStrings over MachineNames).
Stage3Entry:
  LD B,$08

; One fade step (B = 8..1): border B-1, all attributes paper B-1
;
; Part of Stage3Entry; an entry because the recording window r99-s3a starts
; inside the fade (frame 2194).
FadeStep:
  PUSH BC
  LD A,B
  DEC A
  OUT ($FE),A
  LD HL,$5800
  LD DE,$5801
  LD BC,$02FF
  RLA                     ; paper = B-1
  RLA
  RLA
  LD (HL),A
  LDIR

; Two frames a step, the next step; then the clear, the title, MemoryTest, the
; machine name
FadeWait:
  HALT
  HALT
  POP BC
  DJNZ FadeStep
  LD HL,$4000             ; the whole screen and its attributes to 0
  LD DE,$4001
  LD BC,$1C00
  LD (HL),$00
  LDIR
  LD A,$02                ; stream 2: the upper screen
  CALL RomChanOpen
  XOR A                   ; DF SZ = 0: PR-STRING may print on lines 22 and 23
  LD (SysDfSz),A
  LD DE,TitleText         ; "NETHER  EARTH", "ZS Edition'99", "System
                          ; checking...", "Computer "
  CALL PrintFF
  CALL MemoryTest         ; $5CB0 = the scheme bits, $5CB1 = the page count
  LD DE,NameDefault       ; no scheme bit: "Spectrum"
  LD A,(IY+$76)
  OR A
  JR Z,PrintMemory
  CALL FirstSetBit        ; B = 1 + the number of clear bits above the highest
                          ; set one
  LD DE,MachineNames      ; the B-th string after the $FF at $67B0
  CALL SkipStrings
PrintMemory:
  CALL PrintFF            ; the machine's name, "Memory "
  LD DE,MemoryText
  CALL PrintFF
  LD BC,$0030             ; BC = 48 when the count is 1
  LD A,(IY+$77)
  DEC A                   ; count - 1 + 4 = count + 3, with the carry out of
                          ; the ADD when the count is 0
  JR Z,PrintMemSize
  ADD A,$04
  LD B,$00
  LD C,A
  RL C                    ; BC = (A:carry) * 16: (count + 3) * 16, or (3 + 4) *
                          ; 8 = 56 for count 0
  RL B
  RL C
  RL B
  RL C
  RL B
  RL C
  RL B
PrintMemSize:
  CALL RomStackBc              ; the number, then "Kb", "Using "
  CALL RomPrintFp
  LD DE,KbText
  CALL PrintFF
  LD HL,(SysProg)           ; PROG below $5D3B: no TR-DOS variables, the tape
                          ; path
  LD DE,$5D3B
  AND A
  SBC HL,DE
  LD DE,TapeRecorderText
  JP C,TapePath
  CALL ReadTrdosVersion   ; the TR-DOS ROM's version text
  LD A,$FF                ; its $FF end
  LD (DE),A
  LD DE,TrdosVersion             ; "TR-DOS Ver 5.03 " as the ROM holds it
  CALL PrintFF
  LD DE,LoadingText       ; "Loading...", "Game... "
  CALL PrintFF
  LD B,$44                ; the game block: 68 sectors to $6780, over these
                          ; strings from $6780 on
  LD HL,GameBlock
  CALL ReadSectors

; CALL the game block: it unpacks itself in place (game99's part); then the
; patches block
;
; An entry because the recording window r99-s3b starts here (frame 2299).
RunGameBlock:
  CALL GameBlock
  LD DE,DriversText       ; "Drivers... "
  CALL PrintFF
  LD B,$04                ; the patches block: 4 sectors to $DC00
  LD HL,PatchesPacked
  CALL ReadSectors

; Unpack the patches block, copy the disk reader and LOAD MAP, set the one-page
; table, branch by the count
InstallPatches:
  CALL PatchesPacked
  LD HL,PatchDiskReader             ; the disk sector reader to $A598
  LD DE,BlockReader
  LD BC,$003E
  LDIR
  LD HL,PatchDiskLoadMap             ; the disk LOAD MAP to $C1FD
  LD DE,LoadMap
  LD BC,$0136
  LDIR
  CALL InstallOnePage     ; the one-page TextLoader and jump table first
  LD HL,(TrdosNextSector)           ; the files after the patches block, in disk order:
                          ; menu 10 sectors, about 15, description 22, greets
                          ; 2, advices 22
  LD (OneMenuPos),HL
  LD A,$0A
  LD (OneMenuCount),A
  CALL AdvanceSectors
  LD (AboutPos),HL
  LD A,$0F
  LD (AboutCount),A
  CALL AdvanceSectors
  LD (DescPos),HL
  LD A,$16
  LD (DescCount),A
  CALL AdvanceSectors
  LD (GreetsPos),HL
  LD A,$02
  LD (GreetsCount),A
  CALL AdvanceSectors     ; the advices position
  LD (AdvicePos),HL
  LD A,$16                ; bug: B of the advices' LD BC is AdviceLen+1
                          ; ($C134); $C133 is C. The one-page table never runs
                          ; (see MemoryTest)
  LD (AdviceLen),A
  LD A,(IY+$77)           ; count 1: the one-page game (no machine gets here)
  DEC A
  JP Z,Start
  CALL InstallPaged       ; more than one page: the paged TextLoader and jump
                          ; table over the one-page ones
  LD DE,MenusText
  CALL PrintFF
  LD A,$01                ; page 1: the menu block to $E800, unpacked to
                          ; $D800-$E6F3 of page 1
  CALL PagedSelect
  LD B,$0A
  LD HL,MenuPacked
  CALL ReadSectors
  CALL MenuPacked
  LD DE,RamDiskText       ; "RAM-Disk... "
  CALL PrintFF
  LD A,$03                ; page 3: the next 64 sectors (the four texts) to
                          ; $C000-$FFFF
  CALL PagedSelect
  LD B,$40
  LD HL,$C000
  CALL ReadSectors

; Page 0 back, the paged jump table's text addresses and lengths, into the game
;
; The end of both 128 K routes (disk, and the tape path's JP). Page 0 at $C000
; (PagedSelect), then the four LD DE / LD BC operands of the paged MainMenu
; table ($C124-$C150, patches $DA68): about $C000 + $0EB3 bytes, description
; $CF00 + $155D, greets $E500 + $0139, advices $E700 + $15C4, all in page 3;
; then JP Start. Run in r99 (frame about 2660) and s99. On a machine with one
; 16 K page at $C000 (the Pentagon locked in 48 K mode, r99-48; the lead's
; 48K-BETA128 run) PagedSelect changes nothing: the menu block was read to
; $E800 and unpacked to $D800, the 64 "RAM-Disk" sectors to $C000-$FFFF over
; the game's $C000-$D7D2 (MainMenu, the patched jump table) and over the menu;
; Start CALLs MainMenu at $C100 (r99-48 frame 5647), which now holds the about
; text's bytes $100 on (CP866 Russian text): they run as code (CALL PE,$A0AD,
; then $EF = RST $28 into the ROM calculator, frames 5647-5664), the
; calculator's literal stream ends in USR-NO ($34B3, frame 5664), which jumps
; to $0001: the ROM's NEW from $11CB, and the copyright message (r99-48 frame
; 5760). The "0 OK" later in r99-48 (frame 7200) is after a key in the BASIC
; editor, not this run's end.
Stage3Paged:
  XOR A
  CALL PagedSelect
  LD HL,$C000             ; about: page 3 $C000, 3763 bytes
  LD (AboutPos),HL
  LD HL,$0EB3
  LD (AboutLen),HL
  LD HL,PageDesc             ; description: $CF00, 5469 bytes
  LD (DescPos),HL
  LD HL,$155D
  LD (DescLen),HL
  LD HL,PageGreets             ; greets: $E500, 313 bytes
  LD (GreetsPos),HL
  LD HL,$0139
  LD (GreetsLen),HL
  LD HL,PageAdvices             ; advices: $E700, 5572 bytes
  LD (AdvicePos),HL
  LD HL,$15C4
  LD (AdviceLen),HL
  JP Start

; Copy the one-page TextLoader ($A56A) and MainMenu jump table ($C100) from the
; patches block
;
; PatchOneLoader (46 bytes) to TextLoader and PatchOneMenu (91 bytes) to
; MainMenu. Called on both paths (disk $627A, tape $63A5): the 128 K route then
; overwrites both (InstallPaged).
InstallOnePage:
  LD HL,PatchOneLoader
  LD DE,TextLoader
  LD BC,$002E
  LDIR
  LD HL,PatchOneMenu
  LD DE,MainMenu
  LD BC,$005B
  LDIR
  RET

; Copy the 128 K TextLoader ($A56A) and MainMenu jump table ($C100) from the
; patches block
;
; PatchPagedLoader (41 bytes, ends with PagedSelect at $A58A) and
; PatchPagedMenu (127 bytes). Called when the count is not 1 (r99 frame about
; 2300, r99-48, s99).
InstallPaged:
  LD HL,PatchPagedLoader
  LD DE,TextLoader
  LD BC,$0029
  LDIR
  LD HL,PatchPagedMenu
  LD DE,MainMenu
  LD BC,$007F
  LDIR
  RET

; HL = the TR-DOS track/sector HL advanced by A sectors (16 a track)
;
; HL = track (H) / sector (L) as in TrdosNextSector, A = sectors (below 16 +
; 240). Out: HL the position A sectors on (L kept below 16, the overflow added
; to H). BC is changed.
AdvanceSectors:
  LD B,$00
  LD C,A
  ADD HL,BC
  LD A,L
  CP $10
  RET C
  LD B,A
  AND $0F
  LD L,A
  LD A,B
  RRA
  RRA
  RRA
  RRA
  AND $0F
  ADD A,H
  LD H,A
  RET

; The tape version of the loads (PROG below $5D3B): game, patches, menu, texts
; from tape blocks
;
; Known only from the code: no recording ran it (every recording booted the
; disk, PROG = $5D3B). "TAPE RECORDER", then the blocks through LoadBlock (flag
; in A, IX the address, DE the length): game $FF ($440E bytes to $6780),
; patches $FE ($033B to $DC00), the tape BlockReader / LoadMap pieces,
; InstallOnePage, then the one-page lengths into the table; on more than one
; page the menu (flag 0, $095F bytes to $E800 in page 1) and the four texts
; into page 3 (flags $FD-$FA), then Stage3Paged. Bugs: (1) the description,
; greets and advices loads set BC, not DE: LoadBlock gets DE as it is after the
; previous load (LD-BYTES counts it down to 0 on success); (2) the one-page
; lengths go to AboutPos (the about loader's LD DE) for the about text but to
; the LD BC operands for the other three, while the tape BlockReader ($D974)
; takes the length from BC.
TapePath:
  CALL PrintFF
  LD DE,LoadingText       ; "Loading...", "Game... "
  CALL PrintFF
  LD A,$FF                ; the game block, flag $FF
  LD IX,GameBlock
  LD DE,$440E
  CALL LoadBlock
  CALL GameBlock
  LD DE,DriversText
  CALL PrintFF
  LD A,$FE                ; the patches block, flag $FE
  LD IX,PatchesPacked
  LD DE,$033B
  CALL LoadBlock
  CALL PatchesPacked
  LD HL,PatchTapeReader             ; the tape block reader to $A598
  LD DE,BlockReader
  LD BC,$0038
  LDIR
  LD HL,PatchTapeLoadMap             ; the tape LOAD MAP to $C1FD
  LD DE,LoadMap
  LD BC,$0093
  LDIR
  CALL InstallOnePage
  LD HL,$0EB3             ; the one-page lengths: about into the LD DE operand
                          ; (bug), the rest into LD BC
  LD (AboutPos),HL
  LD HL,$155D
  LD (DescLen),HL
  LD HL,$0139
  LD (GreetsLen),HL
  LD HL,$15C4
  LD (AdviceLen),HL
  LD A,(IY+$77)
  DEC A
  JP Z,Start
  CALL InstallPaged
  LD DE,MenusText
  CALL PrintFF
  LD A,$01
  CALL PagedSelect
  XOR A                   ; the menu block, flag 0
  LD IX,MenuPacked
  LD DE,$095F
  CALL LoadBlock
  CALL MenuPacked
  LD DE,RamDiskText
  CALL PrintFF
  LD A,$03
  CALL PagedSelect
  LD A,$FD                ; about, flag $FD
  LD IX,$C000
  LD DE,$0EB3
  CALL LoadBlock
  LD A,$FC                ; description, flag $FC: length in BC (bug)
  LD IX,PageDesc
  LD BC,$155D
  CALL LoadBlock
  LD A,$FB                ; greets, flag $FB: BC (bug)
  LD IX,PageGreets
  LD BC,$0139
  CALL LoadBlock
  LD A,$FA                ; advices, flag $FA: BC (bug)
  LD IX,PageAdvices
  LD BC,$15C4
  CALL LoadBlock
  JP Stage3Paged
