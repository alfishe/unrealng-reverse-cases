; --------------------------------------------------------------------------------------------------------------------
; start.asm: The start at $FF00: the loader copies itself to $5E00
;
; USR 65280 enters here. The game's block loads at $6000-$FDFF and the music block at $C000 of RAM 4, so the loader
; cannot stay at $FF00 on a 48K (the game's load stops short of it, but the stack the ROM uses lies there) nor in the
; paged top 16 K on a 128K: it moves to $5E00, in the room CLEAR 24570 left between the BASIC and the game.
; --------------------------------------------------------------------------------------------------------------------

; Copy the block's bytes from $FF0F on to $5E00 and run them there
;
; DI, then LDIR of 512 bytes from LoaderMain's place in the block ($FF0F) to
; LoaderMain $5E00, and JP $5E00. The copy is longer than the block: it runs on
; past $FFFF into the ROM at $0000-$010E, whose bytes land at $5EF1-$5FFF and
; are never run. The 121 bytes of code end at $5E78.
;
; Witness: L1 1 (c1).
LoaderStart:
  DI
  LD HL,$FF0F
  LD DE,LoaderMain
  LD BC,512
  LDIR
  JP LoaderMain
