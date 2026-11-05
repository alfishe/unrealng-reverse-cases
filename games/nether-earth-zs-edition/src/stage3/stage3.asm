; Nether Earth ZS Edition '99, stage 3: "System checking", the memory test, the loads ($61A8-$67EB).
; Unpacked by the block of sectors 45-50 (read to $8000); entered at Stage3Entry $61A8.
; Written by kit/mkgame.py from src/stage3/stage3.ann (tools/menu99_mkgame.py stage3) and the recordings; edit stage3.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
TrdosVersionRom EQU $0365  ; TR-DOS ROM: "TR-DOS Ver 5.03 " in 5.03 and 5.04T (data/rom of unreal-ng)
RomLdBytesIn   EQU $0562  ; ROM LD-BYTES past its set-up (no SA/LD-RET pushed: returns to the caller as it ends)
RomChanOpen    EQU $1601  ; ROM CHAN-OPEN: A = the stream
TrdosLdir      EQU $180D  ; TR-DOS ROM: LDIR, RET (copies with the TR-DOS ROM paged in)
RomPrString    EQU $203C  ; ROM PR-STRING: BC bytes from DE to the open channel
TrdosOut       EQU $2A53  ; TR-DOS ROM: OUT (C),A, RET (an OUT the ATM decodes only with the TR-DOS ROM in)
RomStackBc     EQU $2D2B  ; ROM STACK-BC: BC onto the calculator stack
RomPrintFp     EQU $2DE3  ; ROM PRINT-FP: print the top of the calculator stack
TrdosCommand   EQU $3D13  ; TR-DOS: the command in C (5 = read B sectors from track/sector DE to HL)
TrdosRet       EQU $3D2F  ; TR-DOS ROM: NOP, RET (pages the TR-DOS ROM in and returns to the address pushed)
SysProg        EQU $5C53  ; PROG: $5D3B when TR-DOS has made its variables, lower without it
SysDfSz        EQU $5C6B  ; DF SZ: the lower screen's lines
TrdosNextSector EQU $5CF4  ; TR-DOS: the track / sector after the last one read (the next file on the disk)
TrdosVersion   EQU $67EC  ; the TR-DOS ROM's version text (16 bytes from ROM $0365) + $FF, past the image
TextLoader     EQU $A56A  ; patches block: a text into the buffer (the copied variant)
PagedSelect    EQU $A58A  ; patches block: OUT $7FFD,A OR $10 (128 K route only)
BlockReader    EQU $A598  ; patches block: the disk sector reader / tape block reader (the copied variant)
Start          EQU $A600  ; the game's entry (NE's Start)
MainMenu       EQU $C100  ; NE's MainMenu, replaced by the patches block's jump table
OneMenuPos     EQU $C116  ; one-page table: LD DE operand, the menu block's track / sector
OneMenuCount   EQU $C11A  ; one-page table: B of LD BC, the menu block's sectors
DescPos        EQU $C125  ; LD DE operand of the description loader ($C124): disk position / page-3 address
DescLen        EQU $C128  ; LD BC operand of the description loader (paged table): the length
DescCount      EQU $C129  ; B of that LD BC (one-page table): the sectors
AdvicePos      EQU $C130  ; LD DE operand of the advices loader ($C12F)
AdviceLen      EQU $C133  ; LD BC operand of the advices loader ($C132)
GreetsPos      EQU $C13B  ; LD DE operand of the greets loader ($C13A)
GreetsLen      EQU $C13E  ; LD BC operand of the greets loader ($C13D): C, the low byte
GreetsCount    EQU $C13F  ; its B
AboutPos       EQU $C146  ; LD DE operand of the about loader ($C145)
AboutLen       EQU $C149  ; LD BC operand of the about loader ($C148): C
AboutCount     EQU $C14A  ; its B
LoadMap        EQU $C1FD  ; patches block: LOAD MAP (disk or tape variant)
PageDesc       EQU $CF00  ; page 3: the description text
PatchDiskReader EQU $D800  ; unpacked patches block: the disk sector reader (62 bytes)
PatchDiskLoadMap EQU $D83E  ; the disk LOAD MAP (310 bytes)
PatchTapeReader EQU $D974  ; the tape block reader (56 bytes)
PatchTapeLoadMap EQU $D9AC  ; the tape LOAD MAP (147 bytes)
PatchPagedLoader EQU $DA3F  ; 128 K: the text copy from page 3 and PagedSelect (41 bytes)
PatchPagedMenu EQU $DA68  ; 128 K: the jump table, the menu copy from page 1 (127 bytes)
PatchOneLoader EQU $DAE7  ; one page: the text read from disk or tape (46 bytes)
PatchOneMenu   EQU $DB15  ; one page: the jump table (91 bytes)
PatchesPacked  EQU $DC00  ; the patches block as read (sectors 119-122), its depacker at the start
PageGreets     EQU $E500  ; page 3: the greets text
PageAdvices    EQU $E700  ; page 3: the advices text
MenuPacked     EQU $E800  ; the menu block as read into page 1 (sectors 123-132), its depacker at the start
  ORG $61A8
  INCLUDE "s3main.asm"  ; "System checking": the machine, the memory, the loads, the patches, the 128 K route, the tape path
  INCLUDE "s3util.asm"  ; TR-DOS and tape loading, the string helpers
  INCLUDE "s3memtest.asm"  ; MemoryTest: the paging scheme, the page count, the page select
  INCLUDE "s3data.asm"  ; The page list, the saved bytes, the strings

  SAVEBIN "stage3-61a8.bin",$61A8,$0644
