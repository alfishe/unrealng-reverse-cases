; Deflektor, Gremlin Graphics 1987: the main block's own code (496 bytes), decrypted: BlockHead $5C00-$5C26,
; the chain $7B52-$7CFF and the mover $FD00-$FD1A; tools/cipher.py encrypts it with the game (src/head/keys.txt).
; Written by kit/mkgame.py from src/head/head.ann and the recordings; edit head.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; Addresses outside this image (@equ in the annotations)
MoveStub       EQU $5B00  ; the printer buffer: the loader's LDIR; RET, here a POP HL; JP (HL) that gives BlockHead its address
GameBase       EQU $6000  ; where the mover puts the game
GameEntry      EQU $8382  ; the game's entry (src/game/game.ann) once the mover has run

; the block's head: $5C00-$5C26
  ORG $5C00
  INCLUDE "head/head.asm"  ; The main block's head: where it is, and the chain moved up to $7B52

; the decryption chain: $5C27-$5DD4, run at $7B52
  ORG $5C27
  DISP $7B52
  INCLUDE "head/chain.asm"  ; D.G. Cooke's decryption chain: 30 layers keyed on sums of memory, then a 16-bit layer over the game
  ENT

; the mover: $5DD5-$5DEF, run at $FD00
  ORG $5DD5
  DISP $FD00
  INCLUDE "head/mover.asm"  ; The mover: the decrypted game down to $6000 and into it
  ENT

  SAVEBIN "head.bin",$5C00,496
