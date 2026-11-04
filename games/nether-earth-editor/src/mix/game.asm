; nee.mix, Nether Earth Editor (V.O.software 1996): the 2244 bytes the loader puts at $C350 (50000), called by nee.bas.
; Written by kit/mkgame.py from src/game/game.ann and the recordings; edit game.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
SA_BYTES       EQU $04C2  ; ROM: save a block
LD_BLOCK       EQU $0802  ; ROM: LD-BYTES, then "R Tape loading error" if it failed
TEMPS          EQU $0D4D  ; ROM: the permanent colours to the temporary ones
CHAN_OPEN      EQU $1601  ; ROM: open the stream in A
COLOUR_PERM    EQU $1CAD  ; ROM: the temporary colours made permanent (the end of the colour statements)
PR_STRING      EQU $203C  ; ROM: print BC characters from DE
HL_MULT        EQU $30A9  ; ROM: HL = HL x DE
CHARS          EQU $5C36  ; ROM system variable: the font address - 256
ATTR_P         EQU $5C8D  ; ROM system variable: the permanent colours
Checksum       EQU $9858  ; the checksum block's word (game $5B00); CLEAR 38999 puts RAMTOP just below it
GameBlock      EQU $9C40  ; the game block, 9425 bytes to $C110 (game $D92B, SaveShots)
EdSaveBuildings EQU $9C6D  ; the block's SaveBuildings: 56 records of 3 (game $D958)
  ORG $C350
  INCLUDE "mix.asm"  ; nee.mix: tape I/O for the saved game, its checksum, the map drawer, the tiles and the font

  SAVEBIN "game.bin",$C350,$08C4
