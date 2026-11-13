; Rick Dangerous 2, Micro Style 1990: side A block 4, the loader, 256 bytes at $FF00, as it runs once its first
; loop has deciphered $FF0B-$FFFF (XOR $5C); tools/mktape.py enciphers it for the tape.
; Written by kit/mkgame.py from src/loader/loader.ann and the recordings; edit loader.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; The variables past the loaded image (game.ann @equ)
Reset          EQU $0000  ; the ROM's start: a load error resets the machine
Screen         EQU $4000  ; the display file and attributes: the loading screen's block goes here
TapeCode       EQU $6000  ; side A block 6's load address: the music ($6000-$707F), the game, level 1
GameEntry      EQU $7B8F  ; the game's entry code (src/game)
  ORG $FF00
  INCLUDE "loader-module.asm"  ; The loader: decipher itself, read the screen and the game with a bit-reversed LD-BYTES, enter the game

  SAVEBIN "loader.bin",$FF00,$0100
