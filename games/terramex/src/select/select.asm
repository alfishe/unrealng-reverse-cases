; Terramex, Grandslam 1987: TZX block 4 $7200-$9CF7, the 128K setup and the explorer selector, assembled at $C000
; as the setup's relocation pass leaves them in RAM 1; tools/mktape.py undoes the relocation for the tape.
; Written by kit/mkgame.py from src/select/select.ann and the recordings; edit select.ann, not the .asm.

  DEVICE ZXSPECTRUM128
  SLOT 3
  PAGE 1

; The variables past the loaded image (game.ann @equ)
ChanOpen       EQU $1601  ; the ROM's CHAN-OPEN: A = the stream
RomCharSet     EQU $3C00  ; the ROM character set less 256 (CHARS' usual value): glyph = $3C00 + 8 x code
Screen         EQU $4000  ; the display file
Attributes     EQU $5800  ; the screen attributes
Explorer       EQU $5B70  ; the explorer index: 0-4, $FE on the Help box, $FF elsewhere while the selector runs
DigitBuffer    EQU $5BA6  ; three ASCII digits for PrintNumber3 $C4D7 (never executed)
Chars          EQU $5C36  ; system variable CHARS
ErrNr          EQU $5C3A  ; system variable ERR_NR, the ROM's IY base
Last7FFD       EQU $5FE5  ; the last value written to port $7FFD (the IM 2 handler $9491 restores it)
PagingStub     EQU $5FE6  ; the copy of PagedReadStub $C4A6 the selector reads the banks through
Has128K        EQU $5FFE  ; $11 on a 128K, 0 on a 48K
GameLoaded     EQU $5FFF  ; 0 from the loader, 1 once GameEntry $8F00 has run
ExplorerSet    EQU $6000  ; the chosen explorer's data set in play
TapeExplorerSets EQU $9CF8  ; block 4's five explorer data sets as loaded, $1200 bytes each
  ORG $C000
  INCLUDE "setup.asm"  ; The 128K setup: the paging test, the copies to RAM 1, 3, 4 and 6
  INCLUDE "relocation.asm"  ; The relocation pass and its table
  INCLUDE "selector.asm"  ; The explorer selector: the picture, the hand cursor, the choice and the copy of the chosen set
  INCLUDE "input.asm"  ; The selector's input: the keyboard, Kempston and Sinclair joystick, polled together
  INCLUDE "paging.asm"  ; The paging stub
  INCLUDE "print.asm"  ; Glyph print and the disabled number read-out
  INCLUDE "help.asm"  ; Help: the 48K warning and the instructions, four text pages
  INCLUDE "leftovers.asm"  ; Bytes no code uses

  SAVEBIN "select.bin",$C000,$2AF8
