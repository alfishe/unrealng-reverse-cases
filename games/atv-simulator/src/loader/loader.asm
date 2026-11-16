; ATV Simulator, Code Masters 1987: tape block 3, the machine-code loader (34 bytes at $FFDC).
; Written by kit/mkgame.py from src/loader/loader.ann and the recordings; edit loader.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
LdBytes        EQU $0556  ; the ROM's LD-BYTES: IX the address, DE the length, A the flag, carry set to load; carry clear on return when the block failed
Screen         EQU $4000  ; the screen
GameStart      EQU $6338  ; the game's first byte (src/game)
GameEntry      EQU $D6B0  ; the game's entry (src/game/entry.asm)
  ORG $FFDC
  INCLUDE "loader-module.asm"  ; The machine-code loader: the screen and the game by LD-BYTES, the headers before them skipped

  SAVEBIN "loader.bin",$FFDC,$0022
