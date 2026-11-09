; Video Pool, Oxford Computer Publishing 1985 (James Hutchby): the turbo loader $F000-$F0FF, tape block 4
; (Bytes "VIDEO POOL" 61440, 256 bytes), run by the BASIC's RANDOMIZE USR 61440.
; Written by kit/mkgame.py from src/turbo/turbo.ann and the recordings; edit turbo.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
SaLdRet        EQU $053F  ; the ROM's SA/LD-RET: restores the border, tests BREAK, EI, RET
LdEdgeTail     EQU $05EC  ; the ROM's LD-EDGE-1 after its delay loop: AND A, then LD-SAMPLE $05ED (the edge loop)
ErrSp          EQU $5C3D  ; ERR_SP, the address of the BASIC error return on the machine stack
GameEntry      EQU $8000  ; the game's first instruction (block 5's first byte)
  ORG $F000
  INCLUDE "loader.asm"  ; The turbo loader: a copy of the ROM's LD-BYTES with its own timings, a 16-bit sum, the jump to the game

  SAVEBIN "turbo.bin",$F000,$0100
