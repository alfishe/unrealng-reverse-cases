; --------------------------------------------------------------------------------------------------------------------
; cells.asm: The cells and the blocks: flags, pixels, attributes, 4 x 4 blocks
;
; A level is drawn from 256 cells of 8 x 8 pixels, each with a flag byte (what Rick and the objects meet there) and an
; attribute, and from 256 blocks of 4 x 4 cells; the sections' maps are rows of block numbers. All four tables are
; full size in every level; the editable form is one image of the cells and one of the blocks (the lead's converters).
; --------------------------------------------------------------------------------------------------------------------

; A flag byte per cell: solid, floor, ladder, deadly, in front of the sprites
;
; One byte per cell number 0-255. Bit 0 a special surface (feet row only; level
; 1 a weak jump, 2 ice, 3 a bounce, 4 mud, 5 a launch pad: $7EF1 decides), bit
; 1 solid, bit 2 a floor one can jump up through (feet row only), bit 3 a
; ladder, bit 4 a ladder's top (down starts a climb), bit 5 deadly (Rick dies,
; a detonator blows), bit 6 not used in the cells (the body test sets it for a
; platform object), bit 7 the cell is drawn in front of the sprites: the
; composer leaves it (ComposeCell $7755).
;
; Read by the body tests $8FF9 / $8F29 (through ViewCells), ProbePoint $8D0C
; (the bullet), ProbeGround $8E1C (the detonator), the enemies' probes and the
; composer.
CellFlags:
  INCBIN "res/level/cell-flags.bin",$0000,256

; The pixels of the 256 cells, 8 bytes each
;
; Cell n at CellGraphics + 8n: 8 bytes, the top pixel row first, bit 7 the left
; pixel. Drawn by the cell drawers through the base operands at $772F and $7776
; (the text screens point them at the font $7080 for a while).
CellGraphics:
  INCBIN "res/level/cell-graphics.bin",$0000,2048

; A screen attribute per cell
;
; Cell n's attribute (FLASH, BRIGHT, PAPER, INK) at CellAttrs + n, written by
; SetViewAttrs $783F and the scroll for every view cell drawn; the sprites
; never change attributes.
CellAttrs:
  INCBIN "res/level/cell-attrs.bin",$0000,256

; 256 blocks of 4 x 4 cell numbers
;
; Block n at Blocks + 16n: four rows of four cell numbers, the top row first.
; BuildView $88D4 copies a block as a 4 x 4 square into ViewCells (POP DE, two
; cells at a time). A map byte is a block number.
Blocks:
  INCBIN "res/level/blocks.bin",$0000,4096
