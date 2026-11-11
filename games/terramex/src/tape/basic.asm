; Terramex, Grandslam 1987: TZX block 2, the BASIC program "TERRAMEX" (302 bytes at PROG $5CCB, LINE 0, the
; program 58 bytes): line 0 and, in the variables area at VARS $5D05, the machine-code loader entered at $5D08.
; Written by kit/mkgame.py from src/tape/basic.ann and the recordings; edit basic.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; Constants: addresses outside this image, ROM entries, ports (@const)
SelectorSetup      EQU $7200  ; block 4's selector part as loaded: the 128K setup's entry (src/select)

; The variables past the loaded image (game.ann @equ)
LdBytes        EQU $0556  ; the ROM's LD-BYTES: IX = the address, DE = the length, A = the flag, carry set = load
ChanOpen       EQU $1601  ; the ROM's CHAN-OPEN: A = the stream
Screen         EQU $4000  ; the display file
Attributes     EQU $5800  ; the screen attributes
InfiniteLives  EQU $5B03  ; 1 when the byte at $8000 was $C9 before the load: GameEntry then patches the lives decrement
ErrNr          EQU $5C3A  ; system variable ERR_NR, the ROM's IY base
ErrSp          EQU $5C3D  ; system variable ERR_SP: where an error report returns
PagingStub     EQU $5FE6  ; the selector's paging stub; the loader's stack grows down from here
Has128K        EQU $5FFE  ; $11 on a 128K, 0 on a 48K; GameLoaded $5FFF after it
Block4         EQU $6000  ; TZX block 4's load address: the music player, the selector, the explorer sets
GameImage      EQU $7200  ; TZX block 5's load address: the game (src/game)
CheatByte      EQU $8000  ; tested for $C9 before the load
GameEntry      EQU $8F00  ; the game's entry (src/game)
  ORG $5CCB
  INCLUDE "basic-module.asm"  ; The BASIC: line 0, whose USR enters the loader hidden in the variables area

  SAVEBIN "basic.bin",$5CCB,$012E
