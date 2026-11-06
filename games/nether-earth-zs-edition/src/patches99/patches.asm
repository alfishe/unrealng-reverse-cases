; Nether Earth ZS Edition '99: the patches block as it unpacks, $D800-$DB6F (880 bytes).
; Eight pieces that stage 3 copies to their run addresses (two sets: TR-DOS + 128 K, tape / one page);
; each is assembled with DISP at the address it runs at, laid at its offset of the block. The tape and
; one-page pieces never ran in a recording: their code is the annotation's entries walked statically.
; Written by kit/mkgame.py from src/patches99/patches.ann and the recordings; edit patches.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; Addresses outside this image (@equ in the annotations)
KeyScan        EQU $028E  ; 48 ROM KEY-SCAN: E = the key's number ($FF none), D = the shift
LdBytesIn      EQU $0562  ; 48 ROM LD-BYTES past its set-up (after LD HL,SA/LD-RET; PUSH HL): the edges and bytes
TrDosReadSector EQU $2F1B  ; TR-DOS ROM: sector E + 1 into the sector register, read 256 bytes to HL
TrDosSeek      EQU $2F4D  ; TR-DOS ROM: A to the system register ($FF), seek track C
TrDosRestore   EQU $2F65  ; TR-DOS ROM: the RESTORE command, the head to track 0
RomLdirRet     EQU $33C3  ; 48 ROM: LDIR; RET (inside the calculator's stack moves)
TrDosEntry     EQU $3D2F  ; the TR-DOS ROM's RET at $3D2F: the trap pages the TR-DOS ROM in and returns to the address pushed
MenuStubRun    EQU $6700  ; menu128: where MenuStub runs (below the game block, under the stack top $6780)
Port7FFD       EQU $7FFD  ; the 128 K paging port
TextEntry      EQU $A56A  ; the text reader stage 3 installs: PagedText (128 K) or LoadText (one page, tape)
ReadBlock      EQU $A598  ; the reader stage 3 installs: DiskRead (TR-DOS) or TapeRead (ROM LD-BYTES)
Start          EQU $A600  ; game99: the entry; CALL $C100 (the start-up menu), then StartGame at $A603
MapGeneral     EQU $A684  ; game99: the operand of LD A,99 at $A683 (NewGameSetup: the player's general resource)
CapturePoints  EQU $ADB4  ; game99: the operand of LD B,n at $ADB3 (the capture tick: the capture points)
TargetWarbases EQU $B3E6  ; game99: the operand of LD B,n at $B3E5 (the warbases a robot may target)
SpawnWarbases  EQU $B817  ; game99: the operand of LD B,n at $B816 (the warbases the enemy builds at)
CountPoints    EQU $BB1F  ; game99: the operand of LD B,n at $BB1E (CountBuildings: the records counted)
SceneryWestList EQU $BC8A  ; game99: the operand of LD HL,nn at $BC89 (BuildMap: the west scenery list)
SceneryEastList EQU $BC92  ; game99: the operand of LD HL,nn at $BC91 (BuildMap: the east scenery list)
FirstFactory   EQU $BC9B  ; game99: the operand of LD IX,nn at $BC99 (BuildMap: the first factory record)
BaseWestList   EQU $BCA2  ; game99: the operand of LD HL,nn at $BCA1 (BuildMap: the west base list)
BaseEastList   EQU $BCAA  ; game99: the operand of LD HL,nn at $BCA9 (BuildMap: the east base list)
EnemyWarbases  EQU $BCB7  ; game99: the operand of LD B,n at $BCB6 (BuildMap: the enemy's warbases)
SceneryWest    EQU $BDA9  ; game99: the level area $BDA9-$BF9B (scenery and base lists) that a map file's first 499 bytes replace
LoadMap        EQU $C1FD  ; the LOAD MAP screen stage 3 installs: DiskLoadMap or TapeLoadMap
ClearScreen    EQU $D0B9  ; game99: pixels and attributes to 0, border black
PrintInline    EQU $D42D  ; game99: print the codes and characters after the CALL up to a 0
MenuCode       EQU $D800  ; menu99: the start-up menu's code (unpacked in page 1, copied into page 0 to run)
MenuFile       EQU $E800  ; menu99: the start-up menu's packed block as read (page 1 on 128 K), unpacking itself to $D800
LoadBuffer     EQU $F000  ; the catalogue (8 sectors) and then the map file (2 sectors) are read here, over the map's rows 9-14
FileList       EQU $F800  ; LOAD MAP's list of the N files: 16-byte catalogue entries, over the map's rows 13-14
PrintAddr      EQU $FD04  ; game99: the screen address of the next printed character

; diskread (disk set), 62 bytes: $D800-$D83D, run at $A598
  ORG $D800
  DISP $A598
  INCLUDE "diskread.asm"  ; The TR-DOS sector reader (the disk set), run at $A598
  ENT

; diskmap (disk set), 310 bytes: $D83E-$D973, run at $C1FD
  ORG $D83E
  DISP $C1FD
  INCLUDE "diskmap.asm"  ; LOAD MAP from disk (the disk set), run at $C1FD
  ENT

; taperead (tape set), 56 bytes: $D974-$D9AB, run at $A598
  ORG $D974
  DISP $A598
  INCLUDE "taperead.asm"  ; The tape block reader (the tape set), run at $A598
  ENT

; tapemap (tape set), 147 bytes: $D9AC-$DA3E, run at $C1FD
  ORG $D9AC
  DISP $C1FD
  INCLUDE "tapemap.asm"  ; LOAD MAP from tape (the tape set), run at $C1FD
  ENT

; paging128 (disk set), 41 bytes: $DA3F-$DA67, run at $A56A
  ORG $DA3F
  DISP $A56A
  INCLUDE "paging128.asm"  ; 128 K: the text copy from page 3 and the paging routine (the disk set), run at $A56A
  ENT

; menu128 (disk set), 127 bytes: $DA68-$DAE6, run at $C100
  ORG $DA68
  DISP $C100
  INCLUDE "menu128.asm"  ; 128 K: the start-up menu's entries in the game, the menu copy from page 1 (the disk set), run at $C100
  ENT

; textload48 (tape set), 46 bytes: $DAE7-$DB14, run at $A56A
  ORG $DAE7
  DISP $A56A
  INCLUDE "textload48.asm"  ; One page / tape: a text or the menu read from disk or tape (the tape set), run at $A56A
  ENT

; menu48 (tape set), 91 bytes: $DB15-$DB6F, run at $C100
  ORG $DB15
  DISP $C100
  INCLUDE "menu48.asm"  ; One page / tape: the start-up menu's entries in the game (the tape set), run at $C100
  ENT

  SAVEBIN "patches.bin",$D800,880
