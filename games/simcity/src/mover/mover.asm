; SimCity, Infogrames 1990: the mover, the last 32 bytes of tape block 7 (code2, loaded to $4000-$501F):
; it copies code2's 4096 bytes from $4000 to $5B00 and enters the game. tools/tape.py appends it to code2.
; Written by kit/mkgame.py from src/mover/mover.ann and the recordings; edit mover.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
Screen         EQU $4000  ; the display file, where block 7 loads
GameStart      EQU $5B00  ; code2's run address, the game's first byte (src/game KeyRows)
GameEntry      EQU $5B1B  ; the game's entry point (src/game Entry)
  ORG Screen+4096
  INCLUDE "mover-module.asm"  ; The mover: code2 from the screen to $5B00, then the game's entry

  SAVEBIN "mover.bin",$5000,$0020
