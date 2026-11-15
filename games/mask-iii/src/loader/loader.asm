; MASK III: VENOM Strikes Back, Gremlin Graphics 1988: TZX block 4, the loader (256 bytes at $FF00). Its first
; 15 bytes copy the rest to $5E00 and jump there; the copy loads the screen, tests for 128K paging, loads the game
; and on a 128K the music into RAM 4. The block's last 74 bytes are what the stack held when it was saved.
; Written by kit/mkgame.py from src/loader/loader.ann and the recordings; edit loader.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; Addresses outside this image (@equ in the annotations)
RomReset       EQU $0000  ; the ROM's reset: a load error restarts the machine
LdBytes        EQU $0556  ; the ROM's LD-BYTES: IX = address, DE = length, A = flag, carry set = load; carry clear on return = an error
Screen         EQU $4000  ; the screen, where tape block 5 loads
GameBlock      EQU $6000  ; the game's block (tape block 6, src/game) and the loader's stack top
GameEntry      EQU $9100  ; the game's entry (src/game/game.ann)
PagedRam       EQU $C000  ; the top 16 K, where port $7FFD pages RAM 0 or RAM 4 on a 128K (src/music in RAM 4)

; the start at $FF00: $FF00-$FF0E
  ORG $FF00
  INCLUDE "loader/start.asm"  ; The start at $FF00: the loader copies itself to $5E00

; the loader as copied to $5E00: $FF0F-$FF87, run at $5E00
  ORG $FF0F
  DISP $5E00
  INCLUDE "loader/loader.asm"  ; The loader at $5E00: the screen, the 128K test, the game, the music
  ENT

; the block's tail: $FF88-$FFFF
  ORG $FF88
  INCLUDE "loader/tail.asm"  ; The block's tail: zeros, then what the stack held when the block was saved

  SAVEBIN "loader.bin",$FF00,256
