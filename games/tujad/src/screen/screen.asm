; Tujad, Orpheus Ltd / Ariolasoft UK 1986: tape block 4, the CODE block "TUJAD" (6944 bytes) as LOAD "" CODE 16384
; puts it at $4000: the loading screen and the stub at $5B00 that loads the game block.
; Written by kit/mkgame.py from src/screen/screen.ann and the recordings; edit screen.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; Constants: addresses outside this image, ROM entries, ports (@const)
GameLength         EQU $9D40  ; tape block 5's length, 40 256 bytes

; The variables past the loaded image (game.ann @equ)
SA_BYTES       EQU $04C2  ; the ROM's SA-BYTES: IX = start, DE = length, A = flag byte
LD_BYTES       EQU $0556  ; the ROM's LD-BYTES: IX = start, DE = length, A = flag byte, carry set = LOAD; carry out = success
GameBlock      EQU $60C0  ; the game block's first byte (tape block 5, $60C0-$FDFF; CellTable in src/game)
GameEntry      EQU $6300  ; the game's entry, Entry in src/game/start.asm (JP Setup)
  ORG $4000
  INCLUDE "loadingscreen.asm"  ; The loading screen: 6144 bytes of pixels and 768 attributes
  INCLUDE "stub.asm"  ; The stub at $5B00: it loads the game block and jumps in; a save routine for the same block follows

  SAVEBIN "screen.bin",$4000,$1B20
