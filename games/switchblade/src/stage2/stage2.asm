; Switchblade, Gremlin Graphics 1991: TZX block 3, the loader's second stage, loaded to $609C by the loader the
; BASIC copied to $FF00, run from $609C: it loads blocks 4, 5 and (on a 128K) 6, then jumps to the bootstrap.
; Written by kit/mkgame.py from src/stage2/stage2.ann and the recordings; edit stage2.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; The variables past the loaded image (game.ann @equ)
Bootstrap      EQU $4000  ; block 5's load address: the bootstrap (src/boot) starts there, the rest of the screen holds the game's resident bytes
BootIs128K     EQU $4052  ; the operand of the bootstrap's LD A,$01 at $4051: 1 on a 128K, 0 on a 48K
ScreenMiddle   EQU $4800  ; the middle third of the screen
Attributes     EQU $5800  ; the screen attributes
ToolStep       EQU $5FA9  ; a routine of the tape tool TapeWriter belongs to (not in this block; A = 1)
HeaderTemplate EQU $68A8  ; a tape header (type, name, length, two parameters) just past this block
HeaderData     EQU $68B9  ; the data saved after HeaderTemplate (its parameter 2 bytes)
Block4         EQU $6B5C  ; block 4's load address (the game, src/game)
Block6Buffer   EQU $8000  ; block 6 is loaded here and swapped into bank 4 at $C000
BankWindow     EQU $C000  ; the paged bank's address
ToolInit       EQU $FE00  ; the tape tool's set-up (not in this block)
ToolRead       EQU $FE4D  ; the tape tool's block routine of the first pass: IX = the address, DE = the length
ToolSaveBlock  EQU $FECC  ; the tape tool's save with flag $FF (two bytes before ToolSaBytes, like LoadBlock / LdBytes)
ToolSaBytes    EQU $FECE  ; the tape tool's save: A = the flag, IX = the address, DE = the length
LoadBlock      EQU $FF00  ; the tape loader's block load, flag $FF (src/tape)
  ORG $609C
  INCLUDE "stage2-module.asm"  ; The loader's second stage: the title scroll, the load of blocks 4-6, the 128K test

  SAVEBIN "stage2.bin",$609C,$080C
