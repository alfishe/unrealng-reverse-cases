; SimCity, Infogrames 1990: tape block 4, the loader "loader" (512 bytes at $FE00), as it stands after its own
; R-register decryption of $FE80-$FFFF (tools/tape.py encrypts the tail back for the tape).
; Written by kit/mkgame.py from src/loader/loader.ann and the recordings; edit loader.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
Screen         EQU $4000  ; the display file: the loading screen's block and code2 load here
Mover          EQU $5000  ; code2's last 32 bytes once loaded: the mover (src/mover)
Attributes     EQU $5800  ; the attributes, cleared before code2 loads into the pixels
LoaderStack    EQU $61A7  ; the loader's stack top, in RAM code2's copy fills only later
Code1          EQU $6B00  ; code1, the game from $6B00 to $FE00 (src/game)
  ORG $FE00
  INCLUDE "loader-module.asm"  ; The loader: the R decryption of its own tail, three encrypted blocks through a changed LD-BYTES

  SAVEBIN "loader.bin",$FE00,$0200
