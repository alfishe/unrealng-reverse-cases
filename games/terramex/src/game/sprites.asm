; --------------------------------------------------------------------------------------------------------------------
; sprites.asm: The sprite space past the explorer set: the creatures and the items
; --------------------------------------------------------------------------------------------------------------------

; The creatures' sprites: frames $40-$7E of the sprite space, 63 sprites of 24
; x 24
;
; The sprite space starts at ExplorerSet $6000: frame F lies at $6000 + 72 x F,
; frames $00-$3F the chosen explorer's set, $40-$7E these, $7F the blank frame
; BlankSprite $83B8, $80 + n item n (ItemSprites $8400). Each sprite is three
; columns of 24 bytes, left column first, top byte first, ink 1. The plotter
; $9C7E reads them through the frame number ($9FAA computes the address);
; RenderPass $9B22 draws them with a one-pixel outline from OutlineMasks $FF00,
; mirrored through BitReverse $FE00 when flags bit 7 is set (the stored
; graphics face left, so bit 7 set faces right).
;
; The frames: the professor and his poses, the snake, the crocodile, the bird,
; the frog, the stone faces, the treasure chest, the drops, the comet, the
; planets of the space scene (src/res/sprites/creatures.png).
;
; Witness: every play build reads $7200-$7D40, $7E18-$82E0; the frames at
; $7D41-$7E17 and $82E1-$83B7 are read in no play build (c1, explorers,
; gameover, rzx x31 byte counts; work/stage2/bytemap.py).
CreatureSprites:
  INCBIN "res/sprites/creatures.bin",$0000,4536

; Frame $7F: 72 zero bytes, the empty sprite
;
; Read in every play build (bytemap.py): a slot with nothing to show draws this
; frame.
BlankSprite:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; The 32 items' sprites, frames $80-$9F of the sprite space
;
; 72 bytes each in the creatures' layout. DrawItem $9DE3 draws item n from
; $8400 + 72 x n. The names are in src/res/sprites/README.md (SK's names,
; checked against the pictures).
;
; Witness: every byte read in play except $8BE1-$8C27, item $1C (Barrel Small)
; after its first byte: the item is never shown in the recordings.
ItemSprites:
  INCBIN "res/sprites/items.bin",$0000,2304
